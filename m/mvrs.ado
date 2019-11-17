*! version 1.0.5 24jan2007
program define mvrs, eclass sortpreserve
version 8.2
if "`1'" == "" | "`1'"=="," {
	if "`e(fp_cmd2)'"!="mfp" error 301
	FracRep "regression spline" "  df  " "Knots"
	exit
}
gettoken cmd 0 : 0
frac_chk `cmd' 
if `s(bad)' {
	di as err "invalid or unrecognized command, `cmd'"
	exit 198
}
/*
	dist=0 (normal), 1 (binomial), 2 (poisson), 3 (cox), 4 (glm),
	5 (xtgee), 6(ereg/weibull), 7(streg,stcox).
*/
local dist `s(dist)'
local glm `s(isglm)'
local qreg `s(isqreg)'
local xtgee `s(isxtgee)'
local normal `s(isnorm)'

global MFpdist `dist'

// Disentangle
GetVL `0'
local 0 `s(nought)'

syntax [if] [in] [aw fw pw iw] , [ ADJust(string) ALpha(string) ALL DF(string) ///
 DFDefault(int 4) CYCles(int 20) DEAD(string) DEGree(int 3) noCONStant ///
 KNots(string) SELect(string) XOrder(string) noORTHog * ]
frac_cox "`dead'" `dist'

/*
	Process options
*/
local regopt `options' `constant'
if "`dead'"!="" local regopt "`regopt' dead(`dead')"
if `degree'==3 & "`orthog'"!="noorthog" local orthog orthog
if "`aic'"!="" { // aic selection for vars and functions
	if "`alpha'`select'"!="" {
		noi di as err "alpha() and select() invalid with aic"
		exit 198
	}
	local alpha -1
	local select -1
}
/*
	Check for missing values in lhs, rhs and model vars.
*/
tempvar touse
quietly {
	marksample touse
	markout `touse' $MFP_cur `dead'
	frac_wgt "`exp'" `touse' "`weight'"
	local wgt `r(wgt)'		// [`weight'`exp']
	count if `touse'
	local nobs = r(N)
}
/*
	Detect collinearity among covariates, and fail if found.
*/
local ncur: word count $MFP_cur
_rmcoll $MFP_cur `if' `in' [`weight' `exp'], `constant'
local ncur2: word count `r(varlist)'
if `ncur2'<`ncur' {
	local ncoll=`ncur'-`ncur2'
	if `ncoll'>1 local s ies
	else local s y
	di as err `ncoll' " collinearit`s' detected among covariates"
	exit 198
}
/*
	Rearrange order of variables in varlist
*/
if "`xorder'"=="" local xorder "+"
/*
	Apply fracord to get param estimates
*/
FracOrd `wgt' if `touse', order(`xorder') `regopt' cmd(`cmd')
local nx $MFP_n	/* number of clusters, <= number of predictors */
local lhs $MFP_dv
/*
	Store original order and reverse order
	of each RHS variable/variable set
*/
forvalues i=1/`nx' {
	local r`i' `s(ant`i')'
}
/*
	Initialisation.
*/
forvalues i=1/`nx' {
	local x ${MFP_`i'}
	local nx`i': word count `x'
	local alp`i' .05	/* default function selection level */
	local h`i' `x'		/* names of H(xvars) 	*/
	local n`i' `x'		/* names of xvars 	*/
	local po`i' 1 		/* to be final knot	*/
	local sel`i' 1		/* default var selection level */
/*
	Remove old I* variables
*/
	if `nx`i''==1 frac_mun `n`i'' purge
}
/*
	Adjustment
*/
FracAdj "`adjust'" `touse'
forvalues i=1/`nx' {
	if "`r(adj`i')'"!="" local adj`i' adjust(`r(adj`i')')
	local uniq`i'=r(uniq`i')
}
/*
	Set up degrees of freedom for each variable
*/
if "`df'"!="" {
	FracDis "`df'" df 1 .
	forvalues i=1/`nx' {
		if "${S_`i'}"!="" local df`i' ${S_`i'}
	}
}
/*
	Assign default df for vars not so far accounted for.
	Give 1 df if 2-3 distinct values, 2 df for 4-5 values,
	dfdefault df for >=6 values.
*/
forvalues i=1/`nx' {
	if `nx`i''>1 {
		// over-ride all suggestions that df>1 for grouped vars
		local df`i' 1
	}
	else {
		if "`df`i''"=="" {
			if `uniq`i''<=3 		local df`i' 1
			else if `uniq`i''<=5 	local df`i'=min(2,`dfdefault')
			else 					local df`i' `dfdefault'
		}
	}
}
/*
	Set up selection level (alpha) for each variable
*/
if "`alpha'"!="" {
	FracDis "`alpha'" alpha -1 1
	forvalues i=1/`nx' {
		if "${S_`i'}"!="" {
			local alp`i' ${S_`i'}
			if `alp`i''<0 local alp`i' -1  // AIC
		}
	}
}
/*
	Set up selection level for each variable
*/
if "`select'"!="" {
	FracDis "`select'" select -1 1
	forvalues i=1/`nx' {
		if "${S_`i'}"!="" {
			local sel`i' ${S_`i'}
			if `sel`i''<0 local sel`i' -1  // AIC
		}
	}
}
/*
	Rationalise select() and alpha() in cases of aic
*/
forvalues i=1/`nx' {
	if `sel`i''==-1 & `alp`i''!=1 local alp`i' -1
	if `alp`i''==-1 & `sel`i''!=1 local sel`i' -1
}
/*
	Set knots for predictors individually.
*/
if "`knots'"!="" {
	FracDis "`knots'" knots
	forvalues i=1/`nx' {
		if "${S_`i'}"!="" & `nx`i''==1 local xknot`i' ${S_`i'}
	}
}
/*
	Reserve names for H(predictors) by creating a dummy variable
	for each predictor which potentially needs transformation.
*/
forvalues i=1/`nx' {
	if `df`i''>1 {
		frac_mun `n`i''
		local stub`i' `s(name)'
		qui gen byte `stub`i''_1=.
	}
}
/*
	Build model.
	`r*' macros present predictors according to FracOrd ordering,
	e.g. i=1, r`i'=3 means most sig predictor is third in user's xvarlist.
*/
local it 0
local initial 1
local stable 0 // convergence flag
while !`stable' & `it'<=`cycles' {
	local ++it
	local pwrs
	local rhs1
	local stable 1 // later changed to 0 if any power or status changes
	local lastch 0 // becomes index of last var which changed status
	forvalues i=1/`nx' {
		local r `r`i''
		local ni `n`r''
		local dfi df(`df`r'')
/*
	Build up RHS2 from the i+1th var to the end 
*/
		local rhs2
		local j `i'
		while `j'<`nx' {
			local ++j
			local rhs2 `rhs2' `h`r`j'''
		}
		if `initial' {
			if "`rhs2'"!="" local fixed "base(`rhs2')"
			else local fixed
			qui splsel `cmd' `lhs' `ni' `wgt' if `touse', ///
			 df(1) `fixed' select(1) `regopt' `unique' deg(`degree')
			local dev=r(dev)
			di as text _n ///
			 "Deviance for model with all terms " ///
			 "untransformed = " as res %9.3f `dev' as text ", " ///
			 as res `nobs' as text " observations"
		}
		if "`rhs1'`rhs2'"!="" local fixed "base(`rhs1' `rhs2')"
		else local fixed
/*
	Vars with df(1) are straight-line
*/
		local pvalopt "alpha(`alp`r'') select(`sel`r'')"
		if `i'==1 di
		local kn
		if `df`r''!=1 & "`xknot`r''"!="" local kn "knot(`xknot`r'')"
		if `df`r''==1 & `sel`r''==1 {	// var is included anyway
			local rhs1 `rhs1' `h`r''
			di as text "[`ni' included with 1 df in model]" _n
		}
		else {
			if "`stub`r''"!="" local n name(`stub`r'')
			else local n
			splsel `cmd' `lhs' `ni' `wgt' if `touse', `dfi' `fixed' ///
			 `h' `regopt' `pvalopt' `unique' deg(`degree') `kn'
			local h`r' "`r(n)'"
			local dev=r(dev)
			local p "`r(knots)'"	/* final knots */
			if "`p'"!="`po`r''" {
				if `nx'>1 local stable 0
				local po`r' "`p'"
				local lastch `i'
			}
			if "`h`r''"!="" local rhs1 `rhs1' `h`r''
		}
		if `initial' {
			local h "nohead"
			local initial 0
		}
	}
	if `lastch'==1 local stable 1 // 1 change only, at i=1
	if !`stable' ///
		di as text "{hline 60}" _n "End of Cycle " as res `it' as text ///
		 ": deviance =   " as res %9.3f `dev' _n as text "{hline 60}"
}
if `nx'>1 {
	local s
	if `it'!=1 local s "s"
	if !`stable' di _n as err "No convergence" _cont
	else di _n as text ///
	 "Regression spline fitting algorithm converged" _cont
	di as text " after " as res `it' as text " cycle`s'."
}
if `stable' di _n as text "Transformations of covariates:" _n
/*
	Remove variables left behind
*/
forvalues i=1/`nx' {
	if "`stub`i''"!="" cap drop `stub`i''*
}
/*
	Store results
*/
if "`all'"!="" local restrict restrict(`touse')
else local ifuse if e(sample)
local finalvl	// predictors in final model
forvalues i=1/`nx' {
	local p=trim("`po`i''")
	local x `n`i''
	if "`p'"!="" & "`p'"!="." {
		if "`p'"=="1" & `df`i''==1 local p linear
		if "`p'"=="linear" | wordcount("`x'")>1 local finalvl `finalvl' `x'
		else {
			qui splinegen `x' `p' `ifuse', deg(`degree') `orthog' `restrict'
			local finalvl `finalvl' `r(names)'
		}
	}
}
/*
	Estimate final (model.
*/
quietly `cmd' `lhs' `finalvl' `wgt' if e(sample), `regopt'
global S_1 `finalvl'
global S_2 `dev'
local nx2 0	/* number of predictors after expansion of groups (if any) */
forvalues i=1/`nx' {
	local p `po`i''
	if "`p'"=="" | "`p'"=="." {
		local p .
		local fdf 0
	}
	else if "`p'"=="linear" local fdf 1
	else {
		local npars: word count `p'
		local fdf=`npars'+(`degree'>0)
	}
	ereturn scalar Fp_fd`i'=`fdf'		// final degrees of freedom
	ereturn scalar Fp_id`i'=`df`i''		// initial degrees of freedom
	ereturn scalar Fp_al`i'=`alp`i''	// FP selection level
	ereturn scalar Fp_se`i'=`sel`i''	// var selection level
	if `degree'==0 local k `p'
	else if `fdf'>0 {
		if `df`i''==1 | `fdf'==1 local k Linear
		else local k [lin] `p' 	// knots plus "K" to make string-length = df
	}
	else local k .
	ereturn local Fp_k`i' `k'

	tokenize `n`i''
	while "`1'"!="" {
		local ++nx2
		ereturn local fp_x`nx2' `1'		// name of ith predictor in user order
		ereturn local fp_k`nx2' `k'
		if "`catz`i''"!="" ereturn local fp_c`nx2' 1
		mac shift
	}
}
ereturn scalar fp_dist=`dist'
ereturn local fp_wgt `weight'
ereturn local fp_exp `exp'
ereturn local fp_depv `lhs'
if `dist'==7 ereturn local fp_depv _t
ereturn scalar fp_dev=`dev'
ereturn local fp_rhs	// deliberately blank for consistency with fracpoly
ereturn local fp_opts `regopt'
ereturn local fp_fvl `finalvl'
ereturn scalar fp_nx=`nx2'
ereturn local fp_t1t "Regression Spline"
FracRep "spline" "  df  " "Knot positions"
ereturn local fp_cmd "fracpoly"
ereturn local fp_cmd2 "mfp"

end

program define GetVL, sclass // varlist [if|in|,|[weight]]
macro drop MFP_*
if $MFpdist != 7 {
	gettoken tok 0 : 0
	unabbrev `tok'
	global MFP_dv "`s(varlist)'"
}

global MFP_cur		// MFP_cur will contain full term list
global MFP_n 0

gettoken tok : 0, parse(" ,[")
IfEndTrm "`tok'"
while `s(IsEndTrm)'==0 {
	gettoken tok 0 : 0, parse(" ,[")
	if substr("`tok'",1,1)=="(" {
		local list
		while substr("`tok'",-1,1)!=")" {
			if "`tok'"=="" {
				di as err "varlist invalid"
				exit 198
			}
			local list "`list' `tok'"
			gettoken tok 0 : 0, parse(" ,[")
		}
		local list "`list' `tok'"
		unabbrev `list'
		global MFP_n = $MFP_n + 1
		global MFP_$MFP_n "`s(varlist)'"
		global MFP_cur "$MFP_cur `s(varlist)'"
	}
	else {
		unabbrev `tok'
		local i 1
		local w : word 1 of `s(varlist)'
		while "`w'" != "" {
			global MFP_n = $MFP_n + 1
			global MFP_$MFP_n "`w'"
			local ++i
			local w : word `i' of `s(varlist)'
		}
		global MFP_cur "$MFP_cur `s(varlist)'"
	}
	gettoken tok : 0, parse(" ,[")
	IfEndTrm "`tok'"
}
sret local nought `0'
end

program define IfEndTrm, sclass
sret local IsEndTrm 1
if "`1'"=="," | "`1'"=="in" | "`1'"=="if" | ///
 "`1'"=="" | "`1'"=="[" exit
sret local IsEndTrm 0
end

program define FracOrd, sclass
version 8
sret clear
syntax [if] [in] [aw fw pw iw] [, CMd(string) ORDer(string) * ]
if "`cmd'"=="" local cmd "regress"
if "`order'"=="" {
	di as err "order() must be specified"
	exit 198
}
local order=substr("`order'",1,1)
if "`order'"!="+" &"`order'"!="-" &"`order'"!="r" &"`order'"!="n" {
	di as err "invalid order()"
	exit 198
}
quietly {
	local nx $MFP_n
	if "`order'"=="n" {
		// variable order as given
		forvalues i=1/`nx' {
			local r`i' `i'
		}
	}
	else {
		if "`order'"=="+" | "`order'"=="-" ///
		 `cmd' $MFP_dv $MFP_cur `if' `in' [`weight' `exp'], `options'
		tempvar c n
		tempname p dfnum dfres stat
		gen `c'=.
		gen int `n'=_n in 1/`nx'
		if "`order'"=="+" | "`order'"=="-" {
			forvalues i=1/`nx' {
				local n`i' ${MFP_`i'}
				capture test `n`i''	/* could comprise >1 variable */
				local rc=_rc
				if `rc'!=0 {
					noi di as err "could not test ${MFP_`i'}---collinearity?"
					exit 1001
				}
				scalar `p'=r(p)
				if "`order'"=="-" /* reducing P-value */ replace `c'=-`p' in `i'
				else replace `c'=`p' in `i'
			}
		}
		if "`order'"=="r" replace `c'=uniform() in 1/`nx'
		sort `c'
		forvalues i=1/`nx' {
/*
	Store positions of sorted predictors in user's list
*/
			forvalues j=1/`nx' {
				if `i'==`n'[`j'] {
					local r`j' `i'
					local j `nx'
					continue, break
				}
			}
		}
	}
}
/*
	Store original positions of variables in ant1, ant2, ...
*/
forvalues i=1/`nx' {
	sret local ant`i' `r`i''
}
sret local names `names'
end

program define FracAdj, rclass
version 8
/*
	Inputs: 1=macro `adjust', 2=case filter.
	Returns adjustment values in r(adj1),...
	Returns number of unique values in r(uniq1),...
*/

args adjust touse
if "`adjust'"=="" FracDis mean adjust
else FracDis "`adjust'" adjust
tempname u
forvalues i=1/$MFP_n {
	local x ${MFP_`i'}
	quietly inspect `x' if `touse'
	scalar `u'=r(N_unique)
	local nx: word count `x'
	if `nx'==1 {	// can only adjust if single predictor
		local a ${S_`i'}
		if "`a'"=="" | "`adjust'"=="" {	// identifies default cases
			if `u'==1 /* no adjustment */ local a
			else if `u'==2 {	// adjust to min value
				quietly summarize `x' if `touse', meanonly
				if r(min)==0 local a
				else local a=r(min)
			}
			else local a mean
		}
		else if "`a'"=="no" local a
		else if "`a'"!="mean" confirm num `a'
	}
	return local adj`i' `a'
	return scalar uniq`i'=`u'
}
end

program define FracDis
version 8
/*
	Disentangle varlist:string clusters---e.g. for DF.
	Returns values in $S_*.
	If `3' is null, lowest and highest value checking is disabled.
*/
local target "`1'"		/* string to be processed */
local tname "`2'"		/* name of option in calling program */
if "`3'"!="" {
	local low "`3'"		/* lowest permitted value */
	local high "`4'"	/* highest permitted value */
}
tokenize "`target'", parse(",")
local ncl 0 			/* # of comma-delimited clusters */
while "`1'"!="" {
	if "`1'"=="," mac shift
	local ++ncl
	local clust`ncl' "`1'"
	mac shift
}
if "`clust`ncl''"=="" local --ncl
if `ncl'>$MFP_n {
	di as err "too many `tname'() values specified"
	exit 198
}
/*
	Disentangle each varlist:string cluster
*/
forvalues i=1/`ncl' {
	tokenize "`clust`i''", parse("=:")
	if "`2'"!=":" & "`2'"!="=" {
		if `i'>1 {
			noi di as err "invalid `tname'() value `clust`i'', must be first item"
			exit 198
		}
		local 2 ":"
		local 3 `1'
		local j 0
		local 1
		while `j'<$MFP_n {
			local ++j
			local nxi: word count ${MFP_`j'}
			if `nxi'>1 local 1 `1' (${MFP_`j'})
			else local 1 `1' ${MFP_`j'}
		}
	}
	local arg3 `3'
	if "`low'"!="" & "`high'"!="" {
		cap confirm num `arg3'
		if _rc {
			di as err "invalid `tname'() value `arg3'"
			exit 198
		}
		if `arg3'<`low' | `arg3'>`high' {
			di as err "`tname'() value `arg3' out of allowed range"
			exit 198
		}
	}
	while "`1'"!="" {
		gettoken tok 1 : 1
		if substr("`tok'",1,1)=="(" {
			local list
			while substr("`tok'",-1,1)!=")" {
				if "`tok'"=="" {
					di as err "varlist invalid"
					exit 198
				}
				local list "`list' `tok'"
				gettoken tok 1 : 1
			}
			unabbrev `list' `tok'
			local w `s(varlist)'
			FracIn "`w'"
			local v`s(k)' `arg3'
		}
		else {
			unabbrev `tok'
			local tok `s(varlist)'
			local j 1
			local w : word 1 of `tok'
			while "`w'" != "" {
				FracIn `w'
				local v`s(k)' `arg3'
				local ++j
				local w : word `j' of `tok'
			}
		}
	}
}
forvalues j=1/$MFP_n {
	if "`v`j''"!="" global S_`j' `v`j''
	else global S_`j'
}
end

program define FracIn, sclass /* target varname/varlist */
version 8
* Returns s(k) = index # of target in MFP varlists.
args v
sret clear
sret local k 0
forvalues j=1/$MFP_n {
	if "`v'"=="${MFP_`j'}" {
		sret local k `j'
		continue, break
	}
}
if `s(k)'==0 {
   	di as err "`v' is not an xvar"
   	exit 198
}
end

program define FracRep
* 1=descriptor e.g. FRACTIONAL POLYNOMIAL
* 2=param descriptor e.g. df
* 3=param names e.g. powers
version 8
args desc param paramv
local l=length("`paramv'")
forvalues i=1/$MFP_n {
	local l=max(`l',length("`e(Fp_k`i')'"))
}
local l=min(`l'+48, 65)
local title "Final multivariable `desc' model for `e(fp_depv)'"
local lt=length("`title'")
di _n as text "`title'"
di as text "{hline 13}{c TT}{hline `l'}"
di as text _skip(4) "Variable {c |}" _col(19) "{hline 5}" _col(24) "Initial" ///
 _col(31) "{hline 5}" _col(46) "{hline 5}" _col(51) "Final" ///
 _col(56) "{hline 5}"
di as text _col(14) "{c |} `param'" ///
 _col(25) "Select" ///
 _col(34) "Alpha" ///
 _col(43) "Status" ///
 _col(51) "`param'" ///
 _col(59) "`paramv'"
di as text "{hline 13}{c +}{hline `l'}"
forvalues i=1/$MFP_n {
	local pars `e(Fp_k`i')'
	if "`pars'"=="" | "`pars'"=="." {
		local final 0
		local status out
		local pars
	}
	else {
		local status in
		local final=e(Fp_fd`i')
	}
	local name ${MFP_`i'}
	local skip=12-length("`name'")
	if `skip'<=0 {
		local name=substr("`name'",1,9)+"..."
		local skip 0
	}
	local select=e(Fp_se`i')
	local alpha=e(Fp_al`i')
	if `select'==-1 local select " A.I.C."
	else local select: di %7.4f `select'
	if `alpha'==-1 local alpha " A.I.C."
	else local alpha: di %7.4f `alpha'

	di as text _skip(`skip') "`name' {c |}" as res ///
	 _col(19) e(Fp_id`i') ///
	 _col(24) "`select'" ///
	 _col(33) "`alpha'" ///
	 _col(45) "`status'" ///
	 _col(53) "`final'" ///
	 _col(59) "`pars'"
}
di as text "{hline 13}{c BT}{hline `l'}"
if "`e(cmd2)'"=="stpm" ml display
else `e(cmd)'
di as text "Deviance:" as res %9.3f e(fp_dev) as text "."
end

program define splsel, rclass
version 8
gettoken cmd 0: 0
if $MFpdist != 7 local vv varlist(min=2) 
else local vv varlist(min=1)
syntax `vv' [if] [in] [aw fw pw iw] [, ///
 ALpha(real .05) SELect(real 1) noHEad DF(int 0) ///
 BAse(string) DEGree(int 3) UNIQUE * ]
local omit=(`select'<1)
if `df'<0 {
	di as err "invalid df"
	exit 198
}
if `df'==0 local df 4
if "`weight'"!="" local weight "[`weight'`exp']"
tokenize `varlist'
if $MFpdist != 7 {
	local lhs `1'
	local n `2'
	mac shift 2
}
else {
	local lhs
	local n `1'
	mac shift 1
}
local nn `*'
if "`head'"=="" {
	di as text "{hline 60}"
	di as text "Variable" _col(11) "Final" _col(18) "Deviance" ///
	 _col(29) "Dev.diff" _col(41) "P" ///
	 _col(47) "Final knot"
	di as text _col(14) "df" _col(29) "cf. null" _col(47) "positions"
	di as text "{hline 60}"
}
local vname `n' `nn'
if length("`vname'")>12 local vname=substr("`vname'",1,9)+"..."
if "`nn'"!="" | `df'==1 {
	// test linear for single or group of predictors, adjusting for base
	local pwrs2 .
	if "`base'"!="" local base base(`base')
	local n `n' `nn'
	local nnn: word count `n'	// no. of vars being tested
	qui TestVars `cmd' `lhs' `n' `if' `in' `weight', `base' `options'
	local P = r(P)
	local dev1 = r(dev1)
	local dev0 = r(dev0)
	local devdiff = r(devdif)
	local vs1 null
	local vs lin.
	local dfirst `dev0'
	local aic 0	// aic not implemented
	if `aic'==0 {
		if `P'<=`select' {
			local star *
			local dev `dev1'
			local dfx 1
			local knots linear
		}
		else {
			local star
			local n
			local dev `dev0'
			local dfx 0
			local knots
		}
	}
	else {	// !! select by AIC not implemented
		if (`dev1'+2*`nnn')<`dev0' {
			local star *
			local dev `dev1'
		}
		else {
			local star
			local n
			local dev `dev0'
		}
	}
	di as text "`vname'" as res _col(15) `dfx' ///
	 _col(17) %9.3f `dev' ///
	 _col(27) %9.3f `devdiff' ///
	 _col(38) %6.3f `P' ///
	 _col(47) "`knots'"
	return local dffinal `dfx'
	return scalar dev=`dev'
	return local n `n'
	return local knots `knots'
	exit
}
local vname `n'
qui uvrs `cmd' `lhs' `n' `base' `if' `in' `weight', linear ///
 df(`df') `unique' degree(`degree') alpha(`alpha') `options'
local n `e(fp_xp)'
local knots `e(fp_k1)'
local dev0=e(fp_d0)
local dev=e(fp_dev)
local devdiff=e(fp_dd)
local nonzero=(`degree'>0 & "$S_3"!="")
local linear=(`df'==1)
local dfx=e(fp_fdf)		// df of xvar in final model
local P=e(fp_Pful)		// P-value for testing full spline model against null
if `omit' & `P'>`select' {
/*
	`Dropping' RHS variable since 1 df test of beta=0 is non-sigficant
	at `select', the overall selection level.
*/
	local dev `dev0'
	local dfx 0
	local n
	local knots
}
di as text "`vname'" as res _col(15) `dfx' ///
 _col(17) %9.3f `dev' ///
 _col(27) %9.3f `devdiff' ///
 _col(38) %6.3f `P' ///
 _col(47) "`knots'"
return local dffinal `dfx'
return scalar dev=`dev'
return local n `n'
return local knots `knots'
end

*! version 1.0.0 PR 11Jul2002.
program define TestVars, rclass /* LR-blocktests variables in varlist, adj base */
	version 8
	gettoken cmd 0 : 0, parse(" ")
	frac_chk `cmd' 
	if `s(bad)' {
		di as err "invalid or unrecognised command, `cmd'"
		exit 198
	}
	local dist `s(dist)'
	local glm `s(isglm)'
	local qreg `s(isqreg)'
	local xtgee `s(isxtgee)'
	local normal `s(isnorm)'
	if $MFpdist != 7 local vv varlist(min=2) 
	else local vv varlist(min=1)
	syntax `vv' [if] [in] [aw fw pw iw], ///
	 [, DEAD(string) noCONStant BASE(varlist) * ]
	frac_cox "`dead'" `dist'
	if "`constant'"=="noconstant" {
		if "`cmd'"=="fit" | "`cmd'"=="cox" | $MFpdist==7 {
			di as err "noconstant invalid with `cmd'"
			exit 198
		}
		local options "`options' noconstant"
	}
	tokenize `varlist'
	if $MFpdist != 7 {
		local y `1'
		mac shift
	}
	local rhs `*'
	tempvar touse
	quietly {
		mark `touse' [`weight' `exp'] `if' `in'
		markout `touse' `rhs' `y' `base' `dead'
		if "`dead'"!="" {
			local options "`options' dead(`dead')"
		}
	/*
		Deal with weights.
	*/
		frac_wgt `"`exp'"' `touse' `"`weight'"'
		local mnlnwt = r(mnlnwt) /* mean log normalized weights */
		local wgt `r(wgt)'
		count if `touse'
		local nobs = r(N)
	}
	/*
		Calc deviance=-2(log likelihood) for regression on base covars only,
		allowing for possible weights.
	
		Note that for logit/clogit/logistic with nocons, must regress
		on zero, otherwise get r(102) error.
	*/
	if (`glm' | `dist'==1) & "`constant'"=="noconstant" {
		tempvar z0
		qui gen `z0'=0
	}
	qui `cmd' `y' `z0' `base' `wgt' if `touse', `options'
	if `xtgee' & "`base'"=="" {
		global S_E_chi2 0
	}
	if `glm' {
		// Note: with Stata 8 scale param is e(phi); was e(delta) in Stata 6
		// Also e(dispersp) has become e(dispers_p).
 		local scale 1
 		local small 1e-6
 		if abs(e(dispers_p)/e(phi)-1)>`small' & ///
		 abs(e(dispers)/e(phi)-1)>`small' ///
		 local scale = e(phi)
	}
	frac_dv `normal' "`wgt'" `nobs' `mnlnwt' `dist' `glm' `xtgee' `qreg' "`scale'"
	local dev0 = r(deviance)
	if `normal' local rsd0=e(rmse)
	/*
		Fit full model
	*/
	`cmd' `y' `rhs' `base' `wgt' if `touse', `options'
	frac_dv `normal' "`wgt'" `nobs' `mnlnwt' `dist' `glm' `xtgee' `qreg' "`scale'"
	local dev1 = r(deviance)
	if `normal' local rsd1=e(rmse)
	local df: word count `rhs'
	local bdf: word count `base'
	local df_r = `nobs'-`df'-`bdf'-("`constant'"!="noconstant")
	local d=`dev0'-`dev1'
	frac_pv `normal' "`wgt'" `nobs' `d' `df' `df_r'
	local P = r(P)
	di as text "Deviance 1:" as res %9.2g `dev1' as text ". " _cont
	di as text "Deviance 0:" as res %9.2g `dev0' as text ". "
	di as text "Deviance d:" as res %9.2g `d' as text ". P = " as res %8.4f `P'
	// store
	return scalar dev0 = `dev0'
	return scalar dev1 = `dev1'
	if `normal' {
		return scalar s0 = `rsd0'
		return scalar s1 = `rsd1'
	}
	return scalar df_m = `df'
	return scalar df_r = `df_r'
	return scalar devdif = `d'
	return scalar P=`P'
	return scalar N = `nobs'
end
