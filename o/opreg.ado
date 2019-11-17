*! version 2.0.0  23nov2010

*A routine to estimate, via the Olley and Pakes (1996) method, the production function
*in the presence of selection bias and simultaneity.

*Olley, G. Steven, & Pakes, Ariel. (1996). The Dynamics of Productivity in the Telecommunications 
*Equipment Industry. Econometrica, 64(6), 1263-1297.

*Authors: 
*Mahmut Yasar, Department of Economics, University of Texas, Arlington
*Rafal Raciborski, StataCorp, College Station, TX
*Brian Poi, Moody's Analytics, West Chester, PA.

program opreg, eclass sortpreserve

	version 9.2

	syntax [anything(equalok)] [if] [in], 			///
		[ proxy(varlist min=1 max=1)				///
		  state(varlist min=1)						///
		  vce(string) bootcall Level(cilevel) * ]
	
	
	local polyvars `proxy' `state'
	local junk : subinstr local polyvars "_" "", all count(local hasus)
	if (`hasus') {
		di as err "proxy and state varnames cannot contain an underscore"
		exit 498
	}
	
	// Must use nonstandard replay check
	if `"`options'`vce'"' == "" {
		di _n
		qui tsset
		local i `r(panelvar)'
		local t `r(timevar)'
		
		di as text "Olley-Pakes productivity estimator" _continue
		di _col(49) as text "Number of obs      = " 		///
				as result %9.0f e(N)
		di as text "Group variable (i): `i'" _continue
		di _col(49) as text "Number of groups   = " 		///
				as result %9.0f e(N_clust)
		di as text "Time variable (t): `t'"
		di _col(49) as text "Obs per group: min = " 		///
				as result %9.0f e(p_min)
		di _col(49) as text "               avg = " 		///
				as result %9.1f e(p_mean)
		di _col(49) as text "               max = " 		///
				as result %9.0f e(p_max)
		di
		                                                            
		_coef_table, level(`level') neq(1)
		// footnote variables used
		di as text "{p 0 15 2}State:{space 9}`e(state)'{p_end}"
		di as text "{p 0 15 2}Free:{space 10}`e(free)'{p_end}"
		di as text "{p 0 15 2}Control:{space 7}`e(cvars)'{p_end}"
		di as text "{p 0 15 2}Proxy:{space 9}`e(proxy)'{p_end}"
		exit
	} 
	
	if "`bootcall'" == "" {
		if "`vce'" == "" {
			local vce "bootstrap, reps(50)"
		}
		else {
			gettoken vcetype vcerest : vce , parse(", ")
			local lsub = length("`vcetype'")
			if "`vcetype'" != ///
			    substr("bootstrap", 1, max(4, `lsub')) {
				di as error "vcetype 'vcetype' not allowed"
				exit 198
			}
		}
		qui count `if' `in'
		local total = r(N)
		tempvar zeroprox
		qui gen byte `zeroprox' = 0
				// assume proxy is in logs
		qui replace `zeroprox' = 1 if `proxy' >= .
		qui count if `zeroprox' == 1
		if r(N) > 0 {
			di as text ///
"Note: ignoring `r(N)' observations with missing value for proxy variable"
			di
			if `"`if'"' == "" {
				local if if `zeroprox' == 0
			}
			else {
				local if `if' & `zeroprox' == 0
			}
		}
		
		local vars proxy(`proxy') state(`state')
		local moreopt vce(`vce') bootcall level(`level')
		local 0 `anything' `if' `in', `vars' `options' `moreopt'
		_vce_parserun opreg , noeqlist paneldata : `0'
		exit
	}

	Estimate `0'
	
end

program Estimate, sortpreserve eclass

	version 9.2

	syntax varlist (min=1 max=1) [if] [in], 	///
		exit(varlist min=1 max=1) 				///
		state(varlist min=1)					///
		proxy(varname)							///
		free(varlist)							///
		[ cvars(varlist) 						///
		  second								///
		  i(varname) t(varname) bootcall ]
	
	qui tsset `i' `t'
	
	marksample touse
	
	global DV_STAGE1 `exit'
	global DV_STAGE2 `varlist'
	
	local nstate : word count `state'
	
	/* CREATE THIRD ORDER POLYNOMIAL TERMS */
	
//==============================================================================
//
// Given variables x, y, z, polynomial terms are created in alphabetical order,
// for example, x_x_y, rather than x_y_x.  Elements in each term are separated
// by an underscore, thus proxy and state variables provided by the user cannot
// contain underscores, which is checked in the caller.
//
//==============================================================================

	local polyvars `proxy' `state'
	
	// get second order terms
	
	local tmp `polyvars'
	foreach x of local polyvars {
		foreach y of local tmp {
			if ("`x'" < "`y'") {
				local secondorder `secondorder' `x'_`y'
				local secondop `secondop' `x'*`y'
			}
			else {
				local secondorder `secondorder' `y'_`x'
				local secondop `secondop' `y'*`x'
			}
		}
		gettoken junk tmp : tmp
	}
	
	local polylen : word count `secondorder'
	forvalues i=1/`polylen' {
		local var : word `i' of `secondorder'
		local op : word `i' of `secondop'
		tempvar `var'
		qui gen double ``var'' = `op'	
		local polylist `polylist' ``var''
	}
	
	// get third order terms
	
	if "`second'" == "" {
	
		foreach x of local polyvars {
			forvalues i=1/`polylen' {
				local lbl : word `i' of `secondorder'
				local y : word `i' of `polylist'
				
				if ("`x'" <= "`lbl'") {
					local tmp `x'_`lbl'
				}
				else local tmp `lbl'_`x'
				
				// check if poly term is already in list
				
				local tmp : subinstr local tmp "_" " ", all
				local srt : list sort tmp
				local tmp : subinstr local srt " " "_", all			
				local in : list tmp in thirdorder
				if (`in'==0) {
					local thirdorder `thirdorder' `tmp'
					local thirdop `thirdop' `x'*`y'
				}
			}
		}
		
		local polylen : word count `thirdorder'
		forvalues i=1/`polylen' {
			local var : word `i' of `thirdorder'
			local op : word `i' of `thirdop'
			tempvar `var'
			qui gen double ``var'' = `op'
			local polylist `polylist' ``var''
		}
	}
	
	local polyterms `secondorder' `thirdorder'
	local polylen : word count `polyterms'
	
quietly {
	
	/* FIRST STAGE -- sic, this is second stage in OP */
	
	tempname bprobit
	
	noi probit $DV_STAGE1 L.(`proxy' `state' `polylist' `cvars') if `touse'
	
	local Nprobit = e(N)
	mat `bprobit' = e(b)
	local names : colnames `bprobit'
	forvalues i=1/`polylen' {
		local from : word `i' of `polylist'		
		local to : word `i' of `polyterms'
		local names : subinstr local names "`from'" "`to'"
	}
	mat colnames `bprobit' = `names'
	tempvar phat phat2
	predict `phat' if e(sample)
	gen double `phat2' = `phat'^2
	
	/* SECOND STAGE -- sic, this is first stage in OP */
	
	tempname bfinal
	
	noi di as txt "Linear regression"
	noi reg $DV_STAGE2 `state' `free' `cvars' `proxy' `polylist' if `touse'
	
	// save stuff from eret list to report after nl step
	
	tempname dfm_reg dfr_reg F_reg r2_reg r2_a_reg rmse_reg
	local Nreg = e(N)
	scalar `dfm_reg' = e(df_m)
	scalar `dfr_reg' = e(df_r)
	scalar `F_reg' = e(F)
	scalar `r2_reg' = e(r2)
	scalar `r2_a_reg' = e(r2_a)
	scalar `rmse_reg' = e(rmse)
	
	// extract coefficients and standard errors for constant, cvars and free vars
	// in other words, all but state vars
	// in fact, it is easier to take the whole matrices now, and then to replace
	// state var entries with entries from nl
	
	tempname breg dfreg kreg
	mat `breg' = e(b)
	local names : colnames `breg'
	forvalues i=1/`polylen' {
		local from : word `i' of `polylist'		
		local to : word `i' of `polyterms'
		local names : subinstr local names "`from'" "`to'"
	}
	mat colnames `breg' = `names'

	scalar `dfreg' = e(df_r)
	//scalar `kreg' = e(df_m)

	tempvar xb res phi L1phi h hsq
	tempvar reshelp

	// regular residuals
	predict `xb'
	
	// residuals with state vars, proxy, products & cross-products omitted
	// in other words, purge the effects of variables that have already been
	// estimated: control variables (cvars) and freely variable inputs (free)

	generate double `reshelp' = 0
	foreach x of varlist `cvars' `free' {
		replace `reshelp' = `reshelp' + _b[`x']*`x'
	}
	
	gen double `res' = $DV_STAGE2 - (_b[_cons] + `reshelp')
	gen double `phi' = `xb' - (_b[_cons] + `reshelp')			
	gen double `L1phi' = L1.`phi'
		
	forval i = 1/`nstate' {
		local state`i' : word `i' of `state'
		tempvar L1state`i'
		gen double `L1state`i'' = L.`state`i''
		local statelist `statelist' `L1state`i''
	}
	
	/* LAST STAGE - SERIES ESTIMATOR WITH NON-LINEAR LEAST SQUARES */
	
//==============================================================================
//
// Label `res' "output" - this is your dependent var of interest.
// nl produces unbiased estimates for state vars; estimates for other vars come
// from regress above (except for proxy, do not show estimates for this one).
// Could show nl estimates for other vars but not really of importance.
//
//==============================================================================
		
	tempvar useme
	gen byte `useme' = 1
	foreach x of varlist `res' `state' `L1phi' `statelist' `phat' {
		replace `useme' = 0 if `x' >= .
	}	
	
	local nstate : word count `state'
		
	forval i = 1/`nstate' {
		local state`i' : word `i' of `state'
		local stateeq `stateeq' {STATE`i'=0}*`state`i'' +
		local bheq `bheq' - {STATE`i'}*`L1state`i''
	}
		
	noi di
	noi di "nl estimation"
	noi di
	noi nl (`res' = `stateeq' {bh=0}*(`L1phi' `bheq') +	///
		{bhsq=0}*(`L1phi' `bheq')^2 + {bp=0}*`phat' + ///
		{bpsq=0}*`phat2' + {bph}*`phat'*(`L1phi' `bheq') + {bcons} ) ///
		if `useme', eps(1e-4)
	
	tempname bnl 
	mat `bnl' = e(b)
	loc Nnl = e(N)
	// because the bootstrap does not produce e(df_r), calculate d.f. manually
	local DF = `e(N)' - `e(df_m)' - 1

	// state vars are saved first so explicit subscripting is ok
	mat `bfinal' = `breg'
	forval i = 1/`nstate' {
		mat `bfinal'[1,`i'] = `bnl'[1,`i']
	}
	local k : word count `state' `free' `cvars'
	mat `bfinal' = `bfinal'[1, 1..`k']
	local names : colnames `bfinal'
 
	local colsb = colsof(`bfinal')
	local namesb : colnames(`bfinal')
	loc nstate : word count `namesb'
	forvalues i = 1/`nstate' {
		local w`i' : word `i' of `namesb'
	}
	
	// final processing
	
	tempname Nmat
	mat `Nmat' = (`Nprobit', `Nreg', `Nnl')
	mat colnames `Nmat' = probit partlin nl
	mat coleq `Nmat' = N:
	mat coleq `bprobit' = PROBIT:
	mat coleq `breg' = PARTLIN:
	local k : coleq `bnl'
	mat colnames `bnl' = `k'
	mat coleq `bnl' = NL:
	mat coleq `bfinal' = $DV_STAGE2
	mat `bfinal' = `bfinal', `bprobit', `breg', `bnl', `Nmat'
	
	tempname Vfinal
	mat `Vfinal' = I(colsof(`bfinal'))
	local k : colfullnames `bfinal'
	mat rownames `Vfinal' = `k'
	mat colnames `Vfinal' = `k'

	qui xtdes if `touse', i(`i') t(`t')
	eret post `bfinal' `Vfinal', esample(`touse')

	//scalars
	ereturn scalar p_min = r(min)
	ereturn scalar p_max = r(max)
	ereturn scalar p_mean = r(mean)
	ereturn scalar Nprobit = `Nprobit'
	ereturn scalar Nreg = `Nreg'
	ereturn scalar Nnl = `Nnl'
	
	//macros
	ereturn local predict "opreg_p"
	ereturn local state "`state'"
	ereturn local proxy "`proxy'"
	ereturn local cvars "`cvars'"
	ereturn local free "`free'"
	ereturn local dv2 "$DV_STAGE2"
	ereturn local dv1 "$DV_STAGE1"
	ereturn local cmd "opreg"
	ereturn local title "Olley-Pakes regression"
      
} // end of quietly block

end

exit

===============
Version history
===============

version 1.3.3  original submission to SJ
version 1.3.4  31mar2008 minor bug fix
version 2.0.0  23nov2010
	added support for unlimited state variables (but see Note below)
	replaced second order polynomials with third order (option -second- tells
	  -opreg- to revert to the old behavior)
	added support for predict

Note: In practice, the number of state variables will be limted by sample size
and available memory.  The number of tempvars needed for the polynomial terms
grows exponentially with the number of state variables so sooner or later
users will exceed a matsize limit or run out of memory or have more variables
than observations.

     +----------------------------------------------+
     | statevars   2nd order   3rd order      total |
     |----------------------------------------------|
  1. |         1           3           4          7 |
  2. |         2           6          10         16 |
  3. |         3          10          20         30 |
  4. |         4          15          35         50 |
  5. |         5          21          56         77 |
     |----------------------------------------------|
  6. |         6          28          84        112 |
  7. |         7          36         120        156 |
  8. |         8          45         165        210 |
  9. |         9          55         220        275 |
 10. |        10          66         286        352 |
     |----------------------------------------------|
 11. |        11          78         364        442 |
 12. |        12          91         455        546 |
 13. |        13         105         560        665 |
 14. |        14         120         680        800 |
 15. |        15         136         816        952 |
     +----------------------------------------------+
