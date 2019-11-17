*! version 1.0  18dec2001        (SJ2-3: st0017)
/* by Florian Heiss: heiss@econ.uni-maannheim.de */
/* based on nlogit, version 7.0.7 */

program define nlogitrum, eclass byable(onecall)
	version 7.0
	
	if replay() {
		if "`e(cmd)'" != "nlogitrum" { error 301 }
		if _by() { error 190 }
		Replay `0'
		exit
	}
	if _by() {
		by `_byvars' `_byrc0': Estimate `0'
	}	
	Estimate `0'
	mac drop nlog_*
end

program define Estimate, eclass byable(recall) sort 

							/* BEGIN parse */
	syntax varlist [if] [in] [fw iw], group(varname) nests(varlist) [noTRee noLABel CLOgit   /*
		*/ Level(passthru) MLOpts(string) noLOg  Robust  d1	   /*
		*/ IVConstraints(string) CONSTraints(string)		  /* 
		*/ technique(passthru) * ] 

gettoken dep xvars : varlist

/* check dep */
	unab dep :  `dep'  /*`dep'*/
	tempvar dep1
	qui gen `dep1' = `dep'	
	qui replace `dep1' = 1 if `dep1' != 0
	qui tab `dep1'
	if r(r) != 2 {
		dis as err "outcome does not vary in any group"
		exit 2000
	}


/* check idepv */
	local i = 0
	foreach idepvar in `xvars' {
	local i = `i' + 1	
	unab ind`i' : `idepvar'
	local indvars `indvars' `ind`i''
	}

/* check nests */
	local k = 0
	foreach nestvar in `nests' {
	local k = `k' + 1	
	unab level`k' : `nestvar'
	local levels `levels' `level`k''
	}


						/* END parse */

	if ("`tree'" == "") & (`k' >= 2) {	/* BEGIN display tree */
	 	nlogittree `levels', `label'
	}	
	else qui nlogittree `levels'
						/* END display tree */




						/* mark sample */
	marksample touse		                  /*new 0/1 var from in, if, by*/
	markout `touse' `deps' `indvars' `group'     /* any missings to 0 */
	tempvar junk newgp
	qui gen double `newgp' = `group' if `touse'
	qui bysort `newgp': gen `junk' = sum(`touse')
	qui by `newgp' : replace `touse' = 0 if `junk'[_N] < _N 	/* other rows to 0 */
	ChkDta `level1' `newgp'	`touse'		/* check data balance */
	qui count if `touse'
	local n0 = r(N)


					/* assert 1 positive outcome
					   per group. markout otherwise */

	qui bysort `newgp': replace `junk' = sum(`dep1')	
	qui by `newgp' :  replace `touse' = 0 if `junk'[_N] != 1
	qui count if `touse'
	local n1 = r(N)
	local ndrop = `n0' - r(N) 
	qui tab `level1' if `touse'
	local ngroup = `n1'/`r(r)' 
	if `ndrop' > 0 {
		local dgroup = `ndrop'/`r(r)'
		dis as txt "note: `dgroup' groups (`ndrop' obs) dropped due to no positive outcome"
		dis as txt "      or multiple positive outcomes per group"
	}
	
	local wtype `weight'
	local wtexp `"`exp'"'
						/* check weight */
	if "`weight'" != "" {
		tempvar chkwght 
		qui gen `chkwght' `exp' 
		cap bysort id: assert `chkwght' == `chkwght'[1] if `touse'
		if _rc {
			dis as err /*
		*/ "weights must be the same for all observations in a group"
			exit 407
		} 
	 	local wgt `"[`weight'`exp']"' 
	}

				/* model checking 
				1. drop ind if it has no within-group variance 
				2. exit if ind is not a characteristic of
				   the corresponding utility */  

	local inds
	foreach ind of local indvars {
		cap bysort `newgp' : assert `ind' == `ind'[1] if `touse'
		if !_rc {
			dis as txt "note: `ind' omitted due to no" /*
			*/ " within-group variance"
		}
		else local inds `inds' `ind'
			cap bysort `newgp' `level1': assert `ind' == `ind'[1] if `touse'
		if _rc {
			dis as err "`ind' is not a characteristic of"/*
			*/ " `level`i'', model is unidentified."
			exit 459
		}
	}
	if "`inds'" == "" {
		dis as err /*
		*/ "no independent variables"
		exit 102
	}
	_rmcoll `inds' if `touse'	/* remove collinearity */
	local ind1 `r(varlist)'  
	local inda `inds'
	mlopts mlopts, `options'	
	forvalues i=1/`k' { 
		qui tab `level`i''
		if r(r) == 1 {
			dis as err "choice of `level`i'' does not vary"
			exit 459
		}
		tempvar temp`i'
		qui egen `temp`i'' = group(`level`i'') if `touse'
	}
	if `k' < 2 {
	dis as txt "note: nonnested model, results are the same as -clogit-"
	}


					/* BEGIN getting initial values 
					         setting up ml model */
	local bylist 
	local i `k' 
	local deps 
	while `i' > 1 {	
 		local bylist `bylist' `level`i''
		tempvar dep`i'			/* dep for level i */
		qui tab `level`i'' if `touse'
		local m = r(r)			
		local tn  `m' `tn'
		local j 1
		while `j' <= `m' {		/* taus for level i */
			local lab : label (`level`i'') `j'
			if "`lab'" == "`j'" {
				local lab `level`i''`j'
			}
			local tau`i'`j' `lab'
			local tau`i' `tau`i'' /`tau`i'`j''
			local j = `j' + 1
		}	
		local tau `tau`i'' `tau'       /* taus for ml */
		qui sort `newgp' `bylist'	
		qui by `newgp' `bylist' : gen `dep`i'' = sum(`dep1') 
		qui by `newgp' `bylist' : /*
		*/ replace `dep`i'' = `dep`i''[_N] 
		local deps `dep`i'' `temp`i'' `deps'  
		local i = `i' - 1

	}

	local maineq (`level1': `dep1' `temp1' `deps' = `ind1', nocons)  
	qui clogit `dep' `ind1' if `touse', group(`newgp')
	tempname b0 V0 s0
	mat `b0' = e(b)
	mat coleq `b0' = `level1'
	mat `V0' = e(V)
	mat `s0' = vecdiag(`V0')
					/* get ll_0 constant only 
					   and ll_clogit */
	local ll_c = e(ll)	
	local ll_0 = e(ll_0)
	local df_mc = e(df_m)	

	local rname : colfullnames `b0'
	mat rownames `V0' = `rname'
	mat colnames `V0' = `rname'
	tempname b
	mat `b' = `b0'

	local t : word count `tau'
	local name : subinstr local tau "/" "", all

	if "`ivconstraints'" != "" { Ivset "`name'" "`ivconstraints'" }
	if `"`constraints'"' != "" | "`s(ivlist)'" != "" { 
		local constr "constraints(`constraints' `s(ivlist)')" 
	}

	est post `b' `V0'
	if "`clogit'" != "" {
		dis _n
		dis as txt "Initial values obtained using clogit" _c
		dis as txt _col(14) "Dependent variable = " _c
		dis as res %8s abbrev("`dep'",8)
		est display
	}
	if `k' > 1 { 
		tempname T
		mat `T' = J(1,`t',1)
		mat colnames `T' = `name'
		mat `b0' = `b0',`T'	
	}

	tempname TN
	global nlog_l = `k'		/* # of levels */
	global nlog_t = `t'		/* # of taus */
	global nlog_T nlog_T 	
	mat input `TN' = (`tn')      /* # of taus in levels*/
	mat $nlog_T = `TN'
	global nlog_id `group'


	/*matrix of altsnests*/
	tempname TM 
	local nestno altno
	global nlog_AN nlog_AN 
	qui tab `level1', matrow($nlog_AN)
	local noalt = r(r)
	local altvals
	forvalues i=1/`noalt' { 
		local thisval = $nlog_AN[`i',1]
		local altvals `altvals' `thisval'
	}
	forvalues i=2/`k' { 
		qui tab `level1' `level`i'', matcell(TM)
		mat $nlog_AN = $nlog_AN , TM
		local numnest = r(c)
		local l = `i' - 1
		forvalues j=1/`numnest' {
			local nestno `nestno' N`l'`j'
		}
	}
	matrix colnames $nlog_AN = `nestno'
	matrix rownames $nlog_AN = `altvals'

					/* END getting initial values
					       setting up ML eqs */
	if "`constr'" != "" {
		di
		dis as txt "User defined constraint(s): "
		constraint list `constraints' `s(ivlist)'
	}


					/* BEGIN calling ml model */



		ml model d0 nlog_rum `maineq' `tau' `wgt' if `touse',  /*
		*/ `constr' init(`b0',copy) search(off) /*
		*/ max miss `mlopts' `log' title("Nested logit, RUM consistent")



	local chi2 = -2*(`ll_0'- e(ll) )
	local chi2_c = -2 * (`ll_c' - e(ll))
	est scalar N_g = `ngroup'
	est scalar levels = `k'
	est scalar ll_0 = `ll_0'
	est scalar ll_c = `ll_c'
	est scalar df_m = e(rank)
	est scalar df_mc = `df_mc'
	est scalar chi2 = `chi2' 
	est scalar chi2_c = `chi2_c' 
	est scalar p = chiprob(e(rank), `chi2')
	est scalar p_c = chiprob(e(rank)-`df_mc', `chi2_c')
	est local k
	est local k_dv
	est local predict "nlogitrum_p"
	est local cmd "nlogitrum"
	est local group "`group'"
	est local chi2type "LR"
	est local iv_names "`name'"
	forvalues i = 1/`k' {
		local j = `k' - `i' + 1
		est local level`j' "`level`i''"
	}	
	est local depvar "`dep'"
	est matrix n_alters  $nlog_T	
	Replay, `level' 
end

program define ChkDta
	args dep group touse
	qui tab `dep' if `touse'
	local r  r(r)
	tempvar junk 
	qui bysort `group': gen `junk' = _N
	cap by `group': assert `junk'[1] == `r' if `touse'	
	if _rc { 
		dis as err "unbalanced data"
		exit 459
	}
end	
		
program define Ivset, sclass
	args name content 
	local i 1000
	gettoken first rest : content, parse(" =,")
	while "`first'" != "" {
		local junk : subinstr local name "`first'" "`first'", /*
		*/ all count(local t)
		if ! `t' { 
			dis as err "`first' not found"	
			exit 198
		}
		gettoken eq rest : rest, parse(" =,")
		if "`eq'" != "=" {
			dis as err "`eq' is found well = is expected"
			exit 198
		}
		gettoken second rest: rest, parse(" =,")
		cap confirm number `second'
		if _rc {
			local junk: subinstr local name "`second'"   /*
			*/ "`second'",	all count(local t)
			if !`t' {
				dis as err "`second'" not found"
				exit 198
			}
			qui constraint define `i'  /*
			*/ [`first']_cons=[`second']_cons 
		}
		else qui constraint define `i'  [`first']_cons = `second'	
		local ivlist `ivlist' `i'
		local i = `i' - 1		
		gettoken first rest : rest, parse(" =,")
		if "`first'" == "," {
			gettoken first rest : rest, parse(" =,")
		}
	}
	sret local ivlist `ivlist'
end

program define Replay
	syntax [, level(passthru)]
	#delimit ;
	di as txt _n "`e(title)'";
	di as txt "Levels             = " as res %10.0f e(levels) 
		as txt _col(49) "Number of obs" 
		as txt _col(68) "="
		as res _col(70) %9.0g e(N) ;
	di as txt "Dependent variable =   "
		as res %8s abbrev("`e(depvar)'", 8)  
		as txt _col(49) "`e(chi2type)' chi2(" as res e(df_m) as txt ")"
			as txt _col(68) "="
			as res _col(70) %9.0g e(chi2) ;
	di as txt "Log likelihood     = " as res %10.0g e(ll)
		as txt _col(49) "Prob > chi2"
                as txt _col(68) "="
                as res _col(73) %6.4f chiprob(e(df_m),e(chi2)) _n ;
	#delimit cr
	local k = e(levels)
*	estimates display, `level' neq(`k') plus 
*	estimates display, `level' first plus 
	estimates display, `level' neq(1) plus 
	dis as txt "IV params:" as txt _col(14) "{c |}"
*	dis as txt _col(14) "{c |}"
	local i = `k' - 1 
	if `i' == 0 {
		dis as txt %12s "(none)" as txt " {c |}" 
	}
	tempname nalt 
	mat `nalt' = e(n_alters)
	local name "`e(iv_names)'"
	tokenize `name'
	local point = 1
	while `i' > = 1 {
		local varname "`e(level`i')'"
		dis as res abbrev("`varname'", 12) as txt _col(14) "{c |}"
		local j = `k' - `i' 
		local s = `nalt'[1,`j']
		local h = 1
		while `h' <= `s' {
			_diparm ``point'', `level'
			local h = `h' + 1
			local point = `point' + 1	
		}	
		local i = `i' - 1
	}
	
	di in smcl as txt "{hline 13}{c BT}{hline 64}"

	#delimit ;
	di as txt "LR test of homoskedasticity (iv = 1):" 
		 _col(39) "chi2(" as res e(df_m)-e(df_mc) as txt ")=" 
		 as res %8.2f e(chi2_c)			      
		 _col(59) as txt "Prob > chi2 = " as res %6.4f e(p_c);
	di as txt "{hline 78}" ;
	#delimit cr
end

exit


