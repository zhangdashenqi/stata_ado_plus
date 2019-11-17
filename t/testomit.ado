*! 1.1.0  08dec1999
* Jeroen Weesie/ICS {
program define testomit, rclass
	version 6.0

	local db *  /* set db to * to switch debug-mode off */

	if "`e(cmd)'" == "" {
		error 301
	}
	if "`e(cmd)'" == "cox" {
		di in re "sorry - cox/stcox not supported in this version"
		exit 198
	}

	/* =====================================================================
		split 0 into omit1,omit2,.. and options
		nomit is number of "omit specifications"
		=====================================================================
	*/

	local nomit 0
	gettoken tok : 0, parse(" (,")
	if `"`tok'"' == "(" {
		while `"`tok'"' == "(" {
			local nomit = `nomit' + 1
			gettoken tok 0 : 0, parse(" (,") match(paren)
			local omit`nomit' `"`tok'"'
			gettoken tok : 0, parse(" (,")
		}
		if `"`tok'"' != "," & `"`tok'"' != "" {
			error 198
		}
	}
	else {
		gettoken tok 0 : 0, parse(" ,")
		while `"`tok'"' != "" & `"`tok'"' != "," {
			local nomit 1
			local eqn `eqn' `tok'
			gettoken tok 0 : 0, parse(" ,")
		}
		if `nomit' == 1 {
			local omit1 `"`eqn'"'
		}
		local eqn
		local 0 `", `0'"'
	}

	`db'	local i 1
	`db'	while `i' <= `nomit' {
	`db'	 	di "omit`i' : `omit`i''"
	`db'		local i = `i' + 1
	`db'	}

	syntax , [ SCore(varlist) TOLscore(real 1E-6) Factor(varlist) /*
		*/ SQrhs Irhs noUnivariate ADJust(str) ]

	if "`score'" == "" & "`e(cmd)'" != "regress" {
		di in re "score() is required"
		di in re "estimate the `e(cmd)' model again with the score() option"
		exit 198
	}

	if `nomit' == 0 & "`sqrhs'`irhs'" == "" & "`factor'" == "" {
		di in bl "no tests specified"
		exit 0
	}

	enumopt "`adjust'" ". Bonferroni Holm Sidak" "adjust"
	local adjust `r(option)'

	* global settings
	local Gsqrhs  `sqrhs'
	local Girhs   `irhs'
	local Gfactor `factor'

	/* =====================================================================
		extract from e(b) the following locals:

		eq                  list of equation names
		neq                 number of equations
		eq1,eq2,..          name of equation 1,2,..
		veq1,veq2,..        variables in eq1, eq2, .. (excl _cons)
		vceq1,vceq2,..      variables in eq1, eq2, .. (incl _cons)
		cons1,cons2...      set to nocons if eqi has no constant
		=====================================================================
	*/

	tempname b bi
	mat `b' = e(b)

	if "`e(cmd)'" == "ologit" | "`e(cmd)'" == "oprobit" {
		FixOrder `b'
	}
	if "`e(cmd)'" == "regress" {
		tempvar score1 score2
		FixRegr `b' `score1' `score2'
		local score "`score1' `score2'"
	}

	local eqq : coleq `b'
	DropDup eq : "`eqq'"
	local neq : word count `eq'
	if (`neq' == 0) | (`neq' == 1 & trim("`eq'") == "_") {
		local eq lp
		local neq 1
		mat coleq `b' = lp
	}
	`db'	di "eq: `eq'"

	local nscore : word count `score'
	if `neq' != `nscore' {
		di in re "nmb of score variables unequal nmb of equations in e(b)"
		di in re "scores expected for `neq' equations (`eq')"
		di in re "scores received `score'"
		exit 198
	}

	local i 1
	while `i' <= `neq' {
		local eq`i' : word `i' of `eq'
		mat `bi' = `b'[1,"`eq`i'':"]
		local vceq`i' : colnames(`bi')
		local veq`i'  : subinstr local vceq`i' "_cons" "", /*
			*/ all word count(local nc)
		if `nc' == 0 {
			local cons`i' "nocons"
		}
		local i = `i' + 1
	}

	/* =====================================================================
		evaluate omit1,omit2,.. to the following locals:

		nEQ1,nEQ2,..        number of terms to be added to eq1,eq2,..
		vEQ1,vEQ2,..        variables to be added to eq1,eq2,..
		ti_j                name of term j in vEQi
		vi_j                variable(s) in term j of vEQi
		=====================================================================
	*/

	if `nomit' == 0 {
		local nomit 1
	}

	local i 1
	while `i' <= `neq' {
		local nEQ`i' 0
		local i = `i' + 1
	}

	* weights used by -summ- to create centered quadratics and interactions
	if "`w(wtype)'" == "fweight" | "`w(wtype)'" == "aweight" {
		local sumwght `"[`e(wtype)'`e(wexp)']"'
	}
	else if "`w(type)'" == "pweight" | "`w(type)'" == "iweight" {
		* there is a problem with negative weights!
		* They are allowed with iweight, but not with aweight
		local sumwght `"[aweight`e(wexp)']"'
	}

	local maxlen 1 /* max char-length of terms */
	local i 1
	while `i' <= `nomit' {
		local touse `"`omit`i''"'

		gettoken eqname touse : touse, parse(" :,") match(paren)
		gettoken colon  touse : touse, parse(" :,") match(paren)
		if "`colon'" == ":" {
			Index "`eq'" "`eqname'"
			local ieq `r(index)'
			if `ieq' == 0 {
				di in re "equation name `eqname' not found"
				di in re "valid equation names are `eq'"
				exit 198
			}
			if `nEQ`ieq'' > 0 {
				di in re "more than one specification for `eqname'"
				exit 198
			}
		}
		else if `i' > 1 | `nomit' > 1 {
			di in re "equation name required"
			exit 198
		}
		else {
			* put back; not eqname after all
			local touse `"`eqname' `colon' `touse'"'
			local eqname `eq1'
			local ieq 1
		}

		local nterm 0
		gettoken term touse : touse, parse(" ,") match(paren)
		while `"`term'"' != "" & `"`term'"' != "," {
			local nterm = `nterm'+ 1
			local term`nterm' `"`term'"'
			gettoken term touse : touse, parse(" ,") match(paren)
		}

		local 0 `", `touse'"'
		local sqrhs
		local irhs
		syntax [, SQrhs Irhs Factor(varlist)]

		/*
			evaluate terms: variables, expressions, factors
		*/

		capt drop _F*

		local facn 0
		local j 1
		while `j' <= `nterm' {
			local term `term`j''
			capt confirm numeric var `term'
			if _rc {
				tempvar varlist
				capt gen double `varlist' = `term' if e(sample)
				if _rc {
					di in re `"error in evaluating `term'"'
					exit 198
				}
				NoMiss "`varlist'" `"`term'"'
			}
			else {
				NoMiss "`term'" `"`term'"'
				IsFactor "`term'" "`factor' `Gfactor'"
				if r(factor)==0 {
					local varlist `term'
				}
				else {
					local facn = `facn' + 1
					quietly tab `term' if e(sample), gen(_F`facn'_)
					local term "`term' (as factor)"
					unab varlist : _F`facn'_*
				}
			}

			RmColl "`veq`ieq''" "`varlist'" "`cons`ieq''"
			if "`r(varlist)'" != "" {
				local nEQ`ieq' = `nEQ`ieq'' + 1
				local t`ieq'_`nEQ`ieq'' `term'
				local v`ieq'_`nEQ`ieq'' `r(varlist)'
				local maxlen = max(`maxlen',length(`"`term'"'))
			}

			local j = `j'+1
		}

		/*
			evaluate quadratic terms in rhs variables
			for factors, a set of dummies is included
		*/

		if "`sqrhs'`Gsqrhs'" != "" {
			tokenize "`veq`ieq''"
			local j 1
			while "``j''" != "" {

				IsFactor "``j''" "`factor' `Gfactor'"
				local isfac`j' = r(factor)

				if `isfac`j'' == 0 {
					tempvar t
					tempname mean`j'
					qui summ ``j'' if e(sample) `sumwght' , meanonly
					scalar `mean`j'' = r(mean)

					qui gen double `t' = (``j'' - `mean`j'')^2

					local term    "``j''^2"
					local varlist `t'
				}
				else {
					local facn = `facn' + 1
					quietly tab ``j'' if e(sample), gen(_F`facn'_)
					local term "``j'' (as factor)"
					unab varlist : _F`facn'_*
				}

				RmColl "`veq`ieq''" "`varlist'" "`cons`ieq''"
				if "`r(varlist)'" != "" {
					local nEQ`ieq' = `nEQ`ieq'' + 1
					local t`ieq'_`nEQ`ieq''  "`term'"
					local v`ieq'_`nEQ`ieq''  "`r(varlist)'"
					local maxlen = max(`maxlen', length(`"`term'"'))
				}

				local j = `j' + 1
			}
		}

		/*
			evaluate interactions in rhs variables
		*/

		if "`irhs'`Girhs'" != "" {
			tokenize "`veq`ieq''"
			local nn : word count `veq`ieq''
			local h 1
			while `h' <= `nn' {

				if "`sqrhs'`Gsqrhs'" == "" {
					IsFactor "``h''" "`factor' `Gfactor'"
					local isfac`h' = r(factor)
					if `isfac`h'' == 0 {
						tempname mean`h'
						qui summ ``h'' if e(sample) `sumwght' , meanonly
						scalar `mean`h'' = r(mean)
					}
				}

				local j 1
				while `j' < `h' {

					if `isfac`j'' + `isfac`h'' == 0 {         /* variate x variate */
						tempvar t
						qui gen double `t' = (``j''-`mean`j'') * (``h''-`mean`h'')
						local term    "``h'' x ``j''"
						local varlist `t'
					}

					else if `isfac`j'' + `isfac`h'' == 1 {    /* variate x factor */
						if `isfac`j'' == 1 {
							local v ``h''
							local f ``j''
						}
						else {
							local f ``h''
							local v ``j''
						}
						local facn = `facn' + 1
						quietly tab `f' if e(sample), gen(_F`facn'_)
						MultVar `v' _F`facn'_*

						local term "`v' (variate) x `f' (factor)"
						unab varlist : _F`facn'_*
					}

					else {                                   /* factor x factor */
						tempvar t
						sort ``h'' ``j''
						qui by ``h'' ``j'' : gen `t' = _n==1
						qui replace `t' = sum(`t')
						local facn = `facn' + 1
						quietly tab `t' if e(sample), gen(_F`facn'_)
						drop `t'
						local term "``h'' x ``j'' (as factors)"
						unab varlist : _F`facn'_*
					}

					RmColl "`veq`ieq''" "`varlist'" "`cons`ieq''"
					if "`r(varlist)'" != "" {
						local nEQ`ieq' = `nEQ`ieq'' + 1
						local t`ieq'_`nEQ`ieq''  "`term'"
						local v`ieq'_`nEQ`ieq''  "`r(varlist)'"
						local maxlen = max(`maxlen',length(`"`term'"'))
					}

					local j = `j' + 1
				}
				local h = `h' + 1
			}
		}

		* build vEQieq
		local j 1
		while `j' <= `nEQ`ieq'' {
			local vEQ`ieq' `"`vEQ`ieq'' `v`ieq'_`j''"'
			local j = `j' + 1
		}

		local i = `i' + 1
	}

	/* =====================================================================
		table of terms of omitted variables per equation
		=====================================================================
	*/

	`db'	local i 1
	`db'	while `i' <= `neq' {
	`db'		di _n in gr "equation: " in ye "`eq`i''"
	`db'		di in gr "vars in eq: " in ye "`veq`i''"
	`db'		di in gr "number of terms: " in ye "`nEQ`i''"
	`db'		local j 1
	`db'		while `j' <= `nEQ`i'' {
	`db'			di in gr "  term `j': " in ye `"`t`i'_`j''"' in gr " in var " in ye "`v`i'_`j''"
	`db'			local j = `j' + 1
	`db'		}
	`db'		local i = `i' + 1
	`db'	}
	`db'	display

	/* =====================================================================
		produce outer product estimator V = GG' for fully expanded model
		=====================================================================
	*/

	if "`e(clustvar)'" != "" {
		local cluster "cluster(`e(clustvar)')"
	}
	if "`w(wtype)'" != "" {
		local wght `"[`e(wtype)'`e(wexp)']"'
	}

	tempname chi2 IV11 norm sc sct S SV12 SV22 test utest V V11 V12 V22
	tempvar cons

	tokenize `score'
	local i 1
	local nterm 0
	while `i' <= `neq' {
		if `nEQ`i'' > 0 {
			local nterm = `nterm' + `nEQ`i''
			local omits `omits' ``i''       /* scores equations "omitted vars" */
			local omitv `omitv' `vEQ`i''    /* varlist of "omitted vars" */
			* names for equations of "omitted variables"
			local j 1
			while `j' <= `nEQ`i'' {
				local omiteq `omiteq' EQ`i'_OMT
				local j = `j' + 1
			}
		}
		local i = `i' + 1
	}

	gen `cons' = 1
	local beq : coleq(`b')
	local bv  : colnames(`b')
	local bv  : subinstr local bv "_cons" "`cons'", word all

	local nb : word count `bv'
	local nomit : word count `omitv'
	if `nomit' == 0 { exit }
	local nV = `nb' + `nomit'
	mat `V' = I(`nV')
	mat colnames `V' = `bv'  `omitv'
	mat coleq    `V' = `beq' `omiteq'
	mat rownames `V' = `bv'  `omitv'
	mat roweq    `V' = `beq' `omiteq'

	_robust `score' `omits' if e(sample) `wght' , var(`V') `cluster'

	/* =====================================================================
		verify that sum of scores of included equations are approx 0
		=====================================================================
	*/

	local i 1
	while `i' <= `neq' {
		local si : word `i' of `score'
		local vlist : subinstr local vceq`i' "_cons" "`cons'", word all
		mat vecacc `sct' = `si' `vlist' if e(sample) `wght', nocons
		mat `norm' = `sct' * `sct''
		if abs(`norm'[1,1]) > `tolscore' {
			if "`diwarn'" == "" {
				di in bl "The norms of one or more scores are not approx zero"
				di in bl "This may mean that convergence in `e(cmd)' was not achieved"
				di in bl "Alternatively, the data may have been altered"
			}
			di in bl "norm of score for `eq`i'' is " `norm'[1,1]
			local diwarn 1
		}
		local i = `i' + 1
	}

	/* =====================================================================
		scores of omitted variables
		=====================================================================
	*/

	local i 1
	while `i' <= `neq' {
		if `nEQ`i'' > 0 {
			local si : word `i' of `score'
			mat vecacc `sct' = `si' `vEQ`i'' if e(sample) `wght', nocons
			mat `sc' = nullmat(`sc') , `sct'
		}
		local i = `i' + 1
	}

	/* =====================================================================
		compute multivariate score test
		=====================================================================
	*/

	local nbp1 = `nb' + 1
	mat `V11'  = `V'[1..`nb',1..`nb']
	mat `V12'  = `V'[`nbp1'...,1..`nb']
	mat `V22'  = `V'[`nbp1'...,`nbp1'...]

	mat `IV11' = syminv(`V11')
	*matginv `V11', ginv(`IV11') nodisplay

	*mat `S' = syminv(`V22' - `V12' * `IV11' * `V12'')
	mat `S' = `V22' - `V12' * `IV11' * `V12''
	mat `S' = syminv(0.5*(`S'+`S''))
	*matginv 0.5*(`S'+`S''), ginv(`S') nodisplay
	matrix `test' = `sc' * `S' * `sc''
	scalar `chi2' = `test'[1,1]

	return local chi2typ "score test"
	return scalar chi2 = `chi2'
	return scalar df   = colsof(`S') - diag0cnt(`S')
	return scalar p    = chiprob(return(df), return(chi2))

	/* =====================================================================
		compute univariate score tests, i.e., tests per term.
		Results are stored in ntest*3 matrix utest:
		  utest[.,1] = test statistic
		  utest[.,2] = df
		  utest[.,3] = p (optionally modified for simulatenous testing)
		               -1 if df == 0
		=====================================================================
	*/

	if "`univariate'" == "" & `nterm' > 1 {
		matrix `utest' = J(`nterm',3,0)

		local i 1
		local it 1
		local iv1 1
		while `i' <= `neq' {
			local j 1
			while `j' <= `nEQ`i'' {
				* variables iv1..iv2 are involved in term j of eq i
				local nvij : word count `v`i'_`j''
				local iv2 = `iv1' + `nvij' - 1

				mat `SV12' = `V12'[`iv1'..`iv2', 1..`nb']
				mat `SV22' = `V22'[`iv1'..`iv2', `iv1'..`iv2']
				mat `sct'  = `sc'[1,`iv1'..`iv2']

				mat `S' = `SV22' - `SV12' * `IV11' * `SV12''
				mat `S' = syminv(0.5*(`S'+`S''))
				*matginv 0.5*(`S'+`S'') , ginv(`S') nodisplay

				mat `utest'[`it',1] = `sct' * `S' * `sct''
				mat `utest'[`it',2] = colsof(`S') - diag0cnt(`S')
				mat `utest'[`it',3] = cond(`utest'[`it',2] > 0, /*
					*/ chiprob(`utest'[`it',2],`utest'[`it',1]), -1  )

				local it = `it' + 1
				local iv1 = `iv2' + 1
				local j = `j' + 1
			}
			local i = `i' + 1
		}

		* Adjusments of p-levels (Bonferroni, Sidak, Holm)
		if "`adjust'" == "bonferroni" {
			Bonferr `utest'
		}
		else if "`adjust'" == "sidak" {
			Sidak `utest'
		}
		else if "`adjust'" == "holm" {
			Holm `utest'
		}
	}

	/* =====================================================================
		display output
		=====================================================================
	*/

	local title `e(cmd)'
	if "`e(cmd2)'" != "" {
		local title `e(cmd2)'
	}

	if "`univariate'" == "" & `nterm' > 1 {
		local len = min(max(20,`maxlen'+1),50)

		di _n in gr "`title': score tests for omitted variables" _n

		di in gr "Term" _col(`len') "  |    score  df     p"
		di in gr _dup(`len') "-" "-+" _dup(22) "-"

		local it 1
		local i 1
		while `i' <= `neq' {
			if `nEQ`i'' > 0 {
				if `neq' > 1 {
					di in ye "`eq`i''" _col(`len') in gr "  |"
				}
				local j 1
				while `j' <= `nEQ`i'' {
					local lab = substr(`"`t`i'_`j''"', 1, `len'-1)
					di in gr %`len's `" `lab'"' " | " in ye /*
						*/ %8.2f `utest'[`it',1]             /*
						*/ %4.0f `utest'[`it',2]             /*
						*/ %9.4f cond(`utest'[`it',3]!=-1,   /*
						*/            `utest'[`it',3], .)
					local it = `it' + 1
					local j = `j' + 1
				}
				di in gr _dup(`len') "-" "-+" _dup(22) "-"
			}
			local i = `i' + 1
		}
		di in gr %`len's "simultaneous test" " | " in ye /*
			*/ %8.2f return(chi2) %4.0f return(df) %9.4f return(p)
		di in gr _dup(`len') "-" "-+" _dup(22) "-"

		local ll = `len' + 24
		if "`e(clustvar)'" != "" {
			di in gr %`ll's "adjusted for clustering on `e(clustvar)'"
		}
		if "`adjust'" != "" {
			local tadjust = upper(substr("`adjust'",1,1)) /*
				*/ + substr("`adjust'",2,.)
			di in gr %`ll's "`tadjust' adjusted p-values"
		}

		* save results multivariate tests
		return matrix utest  `utest'
		return local  adjust `adjust'
	}

	else {
		* multivariate test only

		di _n in gr "`title' score test for omitted variables" /*
			*/ _col(45) "Score Test     = " in ye %9.2f return(chi2)
		if "`e(clustvar)'" != "" {
			di in gr "adjusted for clustering on " /*
				*/ in ye "`e(clustvar)'" _col(45) _c
		}
		else	di _col(45) _c
		di in gr "Prob > chi2(" in ye return(df) in gr ")" /*
			*/ _col(16) "= " in ye %9.4f return(p)
	}
end

/* ===========================================================================
   subroutines
   ===========================================================================
*/


/* DropDup newlist : list
   drops all duplicate tokens from list -- copied from hausman.ado
*/
program define DropDup
	args newlist	/*  name of macro to store new list
	*/  colon	/*  ":"
	*/  list	/*  list with possible duplicates */

	gettoken token list : list
	while "`token'" != "" {
		local fixlist `fixlist' `token'
		local list : subinstr local list "`token'" "", word all
		gettoken token list : list
	}

	c_local `newlist' `fixlist'
end


/* Index list word
   returns in r(index) the (first) index of word in list, 0 if not found
*/
program define Index, rclass
	args list word

	tokenize "`list'"
	local i 1
	local j 0
	while "``i''" != "" & `j' == 0 {
		
		if `"``i''"' == `"`word'"' {
			local j `i'
		}
		else	local i = `i' + 1
	}
	return local index `j'
end


/* IsFactor vname varlist
   returns in r(factor) whether
     - vname occurs in varlist, or
     - vname is a 0-1 dummy
*/
program define IsFactor, rclass
	args vname varlist

	local tmp : subinstr local varlist "`vname'" "" , word count(local nc)
	if `nc' == 0 {
		capt assert `vname'==. | `vname'==0 | `vname'==1
		local nc = !_rc
	}
	return scalar factor = `nc'
end


/* NoMiss varname term
   displays a warning if varname contains missing values in e(sample) 
   (describing term)
*/
program define NoMiss
	args varname term

	capt assert `varname' != . if e(sample)
	if _rc {
		di in re `"`term' produces missing values in the estimation sample"'
		exit 198
	}
end


/* MultVar varlist
   multiplies the second--last vars in varlist by the first var in varlist
*/
program define MultVar
	syntax varlist(min=2)

	tokenize `varlist'
	local v `1'
	mac shift
	while "`1'" != "" {
		qui replace `1' = `1' * `v'
		mac shift
	}
end


/* RmColl varlist1 varlist2 nocons
   returns in r(varlist) the non-collinear variables in varlist2,
	conditional on varlist1 and cons
*/
program define RmColl, rclass
	args vlist1 vlist2 cons

	* di "vlist1: `vlist1'"
	* di "vlist2: `vlist2'"
	* di "cons:   `cons'"
	* list `vlist1' `vlist2' in 1/10

	tempname est
	tempvar touse
	gen byte `touse' = e(sample)
	*
	* _rmcoll accidentally clears e()
	* thus we have -estimate hold/unhold-
	*
	est hold `est'
	qui _rmcoll `vlist1' `vlist2' if `touse' , `cons'
	local varlist `r(varlist)'
	tokenize "`vlist1'"
	while "`1'" != "" {
		local varlist : subinstr local varlist "`1'" "", word all
		mac shift
	}
	* di "RmColl varlist: `varlist'"
	return local varlist `varlist'
	est unhold `est'
end


/* FixOrder b
   modifies the coefficient b of oprobit and ologit. 
     - adds equation name LP to the linear predictor, 
     - renames the cutpoints to cutx:_cons, x=1,2,..
*/
program define FixOrder
	args b
	local names : colnames `b'
	tokenize `names'
	while "`1'" ~= "" {
		if substr("`1'",1,4) ~= "_cut" {
			local nnames `nnames' LP:`1'
		}
		else {
			local 1 = substr("`1'",2,.)
			local nnames `nnames' `1':_cons
		}
		mac shift
	}
	mat colnames `b' = `nnames'
end


/* FixRegr b score1 score2
   Modifies the results returned by regress
     - adds equation name "mean" to b 
     - adds an equation "lnvar" for the log(variance), 
     - returns the scores for the equations mean and lnvar.
*/
program define FixRegr
	args b score1 score2

	quietly {
		tempname b0
		tempvar res res2 var

		predict double `res' if e(sample), res
		gen double `res2' = `res'^2
		summ `res2', meanonly
		scalar `var' = r(mean)

		mat coleq `b' = mean
		mat `b0' = log(`var')
		mat coln `b0' = lnvar:_cons
		mat `b' = `b', `b0'

		gen double `score1' = `res' / sqrt(`var')
		gen double `score2' = 0.5*(`res2' / `var' - 1)
	}
end


/* Bonferroni utest
   Bonferroni adjustment for simultaneous testing
*/
program define Bonferr
	args utest

	local n = rowsof(`utest')
	local i 1
	while `i' <= `n' {
		if `utest'[`i',3] != -1 {
			mat `utest'[`i',3] = min(1, `n' * `utest'[`i',3])
		}
		local i = `i' + 1
	}
end


/* Holm utest
   adjustment for simultaneous testing
   Problem: We don't deal with -ties- in p-values.
*/
program define Holm
	args utest

	local n = rowsof(`utest')
	local i 1
	while `i' <= `n' {
		local p = `utest'[`i',3]
		local pvals "`pvals' `p'"
		local i = `i'+1
	}

	qsortidx "`pvals'" "*", asc

	tokenize `s(slist2)'
	local i 1
	while `i' <= `n' {
		mat `utest'[``i'',3] = min(1,(`n'-`i'+1)*`utest'[``i'',3])
		local i = `i'+1
	}
end


/* Sidak utest
   Sidak adjustment for simultaneous testing
*/
program define Sidak
	args utest

	local n = rowsof(`utest')
	local i 1
	while `i' <= `n' {
		if `utest'[`i',3] != -1 {
			mat `utest'[`i',3] = 1 - (1-`utest'[`i',3])^(`n')
		}
		local i = `i' + 1
	}
end

exit
}

Layout of testomit (multivariate test only)
------------------

e(cmd) score test for omitted variables       xxxxxx
(modified for clustering on ....)             Prob > chi2 =  0.000


Layout of testomit (if univariate tests)
------------------

Variable/expression                    |   score     df     p
---------------------------------------+-----------------------
eq                                     |
                               varname | 123456.89  123  0.0000
                 expression-in-varname | 123456.89  123  0.0000
---------------------------------------+-----------------------
multivariate                           | 123456.89  123  0.0000
                       p-valued adjusted clustering on clustvar
                                  adjust_name adjusted p-values

Algorithm notes
---------------

To faciliate univariate score tests, we generate a VCE in the
following format

  VCE  eq1 eq2 ... eqn aeq1 aeq2 .. aeqn

where aeq1..aeqn involve the variables omitted to equations eq1 .. eqn.
Note that some of the aeq's may be empty.

The score statistic sc is "ordered in the same way". The scores
associated with eq1..eqn should be 0; a warning is displayed if
abs(sci)>1E-6, and sci is set to 0.

To compute score statistics, denote

         (  V  W )           ( 0 )
   VCE = (  W' Z )   score = ( S )

where the partioning is in terms of eq1..eqn versus aeq1..aeqn.

Then

   test = score' * inv(vce) * score

        = S ' * inv(Z - W'*inv(V)*W) * S

Note that this involves inverting V once once, and that each score
test involves inverting a matrix of size the number of restrictions
in the score test. For univariate tests, this involves inverting a
1x1 matrix, task at which Stata excels.

Features to be added
--------------------

for some of the common commands, including ml/d2 methods I could
compute scores here, rather than bother the user with transferring
them. In this case I could also implement the Information based
versions of the score test in which var(U) is estimated via the
(the expected value of the) second order derivatives of the
log-likelihood instead of via the OPG-estimator.

