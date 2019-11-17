* 9-22-11
* Version 7.1

* Same as Version 7.0, except I fixed a small glitch in the calculation of simulation-based forecast errors via Enders.



capture program drop dynsim
program define dynsim, rclass
syntax , ldv(varname) scen1(string) [scen2(string) scen3(string) scen4(string)] /*
*/	[n(integer 10) sig(cilevel) shock(varname) shock_data(string) shock_num(numlist) SAVing(string) FOREcast(string) MODify(varlist numeric min=1 max=4) INTer(varlist numeric min=1 max=4)]

preserve 

	*** If the name of the "saving" data set is not given, store the default name: "dynsim_results"
	if "`saving'" == "" {
		local saving dynsim_results
	}
	***

	*** Make sure both "modify" and "inter" are given, if necessary.
	if "`modify'" != "" {
		capture assert "`inter'" != ""
		if _rc != 0 {
			di as error "You must also specify the -inter- option if you specify -modify-"
			exit 198
		}
	}
	if "`inter'" != "" {
		capture assert "`modify'" != ""
		if _rc != 0 {
			di as error "You must also specify the -modify- option if you specify -inter-"
			exit 198
		}
	}
	***
	
	*** Get the number of modify and inter variables; verify that the number is the same.
	local nmodify : word count `modify'
	local ninter : word count `inter'
	capture assert `nmodify' == `ninter' 
	if _rc != 0 {
		di as error "The number of modify variables must be the same as the number of inter variables"
		exit 198
	}
	***

	*** Make sure that the user specifies at least one of the two shock options, but not both
	if "`shock'" != "" {
		capture assert ("`shock_data'"!="" | "`shock_num'"!="") & ("`shock_data'"!="" & "`shock_num'"=="") | ("`shock_data'"=="" & "`shock_num'"!="")
		if _rc != 0 {
			di as error "You must specify shock values via a dataset or a numlist, but not both"
			exit 198
		}
		if "`shock_num'" == "" {
			cap confirm file "`shock_data'"
			if _rc != 0 {
				cap confirm file `shock_data'.dta
				if _rc != 0 {
					di as error "Something wrong with shock data set: incorrect location, wrong type, etc"
					exit _rc
				}
			}
		}
	}
	***

	*** Error if number of iterations is <= 0 
	capture assert `n' > 0 
	if _rc !=0  {
		di as error "You must specify at least 1 iteration"
        exit 198
    }
	***

	*** Get the number of scenarios specified by the user
	cr_scen_miss, scen1(`scen1') scen2(`scen2') scen3(`scen3') scen4(`scen4')
	local numscen = r(numscen)
    ***  

	*** Get the necessary macros from the -estsimp- command
	_estsimpck
	local rhs `r(rhs)'
	local N_sims `r(N_sims)'
	***
	
	*** Create the variables where we will store the scenario values
	_xccreate, rhs(`rhs') numscen(`numscen')
	***
	
	*** Get the gamma and sigma^2 values 
	tokenize "`e(msn_1)'", parse("1")
	local stub `1'
	local k = e(N) - e(dfSigma) 
	foreach i of numlist 1(1)`k' {
		local vname : word `i' of `e(rhs_1)'
		if "`vname'" == "`ldv'" {
				local ldv_k = `i'
		}
	}
	qui sum `stub'`ldv_k', meanonly
	local gamma = r(mean)
	local gamma_sq = r(mean)^2
	qui sum `e(asn)', meanonly
	local sigma_sq = r(mean)	
	***
	
	*** Get the percentiles for statistical significance
	_ssget `sig'
	local lo = `r(lo)'
	local hi = `r(hi)'
	if "`forecast'" != "" {
		local df = e(dfSigma)
		local ss = `r(lo)'/100
	}
	***

	*** Predicted value for all scenarios at time t = 0.
	foreach ns of numlist 1(1)`numscen' {
		setx `scen`ns''
		if "`shock'" != "" {
			local sv = .
		}
		return matrix t0_s`ns' = mrt_xc, copy
		tempvar _x
		qui simqi, ev genev(`_x') listx
		qui sum `_x', meanonly
		local pv_`ns' = `r(mean)'
		local t = 0
		if "`forecast'" == "" {
			_pctile `_x', percentiles(`lo' `hi')
			local lower_`ns' = `r(r1)'
			local upper_`ns' = `r(r2)'
		}
		if "`forecast'" != "" {
			qui sum `e(asn)', meanonly
			local se_`ns' = sqrt(r(mean))
			local lower_`ns' = `pv_`ns'' - invttail(`df',`ss')*`se_`ns''
			local upper_`ns' = `pv_`ns'' + invttail(`df',`ss')*`se_`ns''		
		}
	***

	*** Create the matrices of shock values and interactions (if specified) of each scenario.
		if "`shock'" ~= "" {
			if "`shock_data'"!="" {
				if "`inter'"!="" {
					qui td, shock(`shock') shock_data(`shock_data') modify(`modify') inter(`inter') ninter(`ninter')
				}
				else {
					qui td, shock(`shock') shock_data(`shock_data')
				}
			}
			if "`shock_num'"!="" {
				if "`inter'"!="" {
					qui td, shock(`shock') shock_num(`shock_num') modify(`modify') inter(`inter') ninter(`ninter')		
				}
				else {
					qui td, shock(`shock') shock_num(`shock_num')
				}
			}	
			mat matshock_s`ns' = r(matshock)
			local nshock = r(nshock)
			_shockvalck, total_n(`n') shock_n(`nshock')
		}
	}	
	***
	
	*** Create the postfile
	tempname p
	if `numscen' == 1 {
		if "`shock'" != "" {
			postfile `p' t sv pv_1 lower_1 upper_1 using `saving', replace
		}
		else {
			postfile `p' t pv_1 lower_1 upper_1 using `saving', replace
		}
	}
	if `numscen' == 2 {
		if "`shock'" != "" {
			postfile `p' t sv pv_1 lower_1 upper_1 pv_2 lower_2 upper_2 using `saving', replace 
		}
		else {
			postfile `p' t pv_1 lower_1 upper_1 pv_2 lower_2 upper_2 using `saving', replace 
		}
	}
	if `numscen' == 3 {
		if "`shock'" != "" {
			postfile `p' t sv pv_1 lower_1 upper_1 pv_2 lower_2 upper_2 pv_3 lower_3 upper_3 using `saving', replace 
		}
		else {
			postfile `p' t pv_1 lower_1 upper_1 pv_2 lower_2 upper_2 pv_3 lower_3 upper_3 using `saving', replace
		}
	}
	if `numscen' == 4 {
		if "`shock'" != "" {
			postfile `p' t sv pv_1 lower_1 upper_1 pv_2 lower_2 upper_2 pv_3 lower_3 upper_3 pv_4 lower_4 upper_4 using `saving', replace
		}
		else {
			postfile `p' t pv_1 lower_1 upper_1 pv_2 lower_2 upper_2 pv_3 lower_3 upper_3 pv_4 lower_4 upper_4 using `saving', replace
		}
	}
	***

	*** Add the scenario values of t = 0 to the postfile
	if `numscen' == 1 {
		if "`shock'" != "" {
			post `p' (`t') (`sv') (`pv_1') (`lower_1') (`upper_1')
		}
		else {
			post `p' (`t') (`pv_1') (`lower_1') (`upper_1')
		}
	}
	if `numscen' == 2 {
		if "`shock'" != "" {
			post `p' (`t') (`sv') (`pv_1') (`lower_1') (`upper_1') (`pv_2') (`lower_2') (`upper_2')
		}
		else {
			post `p' (`t') (`pv_1') (`lower_1') (`upper_1') (`pv_2') (`lower_2') (`upper_2')
		}
	}
	if `numscen' == 3 {
		if "`shock'" != "" {
			post `p' (`t') (`sv') (`pv_1') (`lower_1') (`upper_1') (`pv_2') (`lower_2') (`upper_2') (`pv_3') (`lower_3') (`upper_3')
		}
		else {
			post `p' (`t') (`pv_1') (`lower_1') (`upper_1') (`pv_2') (`lower_2') (`upper_2') (`pv_3') (`lower_3') (`upper_3')
		}
	}
	if `numscen' == 4 {
		if "`shock'" != "" {
			post `p' (`t') (`sv') (`pv_1') (`lower_1') (`upper_1') (`pv_2') (`lower_2') (`upper_2') (`pv_3') (`lower_3') (`upper_3') (`pv_4') (`lower_4') (`upper_4')
		}
		else {
			post `p' (`t') (`pv_1') (`lower_1') (`upper_1') (`pv_2') (`lower_2') (`upper_2') (`pv_3') (`lower_3') (`upper_3') (`pv_4') (`lower_4') (`upper_4')
		}
	}

	*** Calculate the predicted values (and CIs) for each scenario, for each iteration.
	qui foreach i of numlist 1(1)`n' {
		foreach ns of numlist 1(1)`numscen' {
			tempvar _x`i'
			setx `scen`ns''
			setx `ldv' `pv_`ns''
			if "`shock'" ~= "" {
				if "`inter'" != "" {
					local xn = 1
					foreach x of varlist `inter' {
						local inter`xn' "`x'"
						local xn = `xn' + 1
					}	
					foreach ni of numlist 1(1)`ninter' {
						local col = (`ninter'+2)+(`ni'-1)
						local iv`ni' = matshock_s`ns'[`i',`col']						
					}
					local sv = matshock_s`ns'[`i',1]
					setx `shock' `sv' `inter1' `iv1' `inter2' `iv2' `inter3' `iv3' `inter4' `iv4'
					_xcreplace, rhs(`rhs') it(`i') scen(`ns') 
				}
				else {
					local sv = matshock_s`ns'[`i',1]
					setx `shock' `sv'
					_xcreplace, rhs(`rhs') it(`i') scen(`ns') 
				}
			}
			if "`shock'" == "" {
				_xcreplace, rhs(`rhs') it(`i') scen(`ns') 
			}
			qui simqi, ev genev(`_x`i'') listx

			qui sum `_x`i'', meanonly
			local pv_`ns' = `r(mean)'
			local t = `i' 
			if "`forecast'" == "" {
				_pctile `_x`i'', percentiles(`lo' `hi')
				local lower_`ns' = `r(r1)'
				local upper_`ns' = `r(r2)'
			}
			if "`forecast'" != "" {
				if "`forecast'" == "ag" {
					local iminusone = `i' - 1
					local se_`ns' = sqrt(`sigma_sq'*(1+`iminusone'*`sigma_sq'*`gamma_sq'))
					local lower_`ns' = `pv_`ns'' - invttail(`df',`ss')*`se_`ns''
					local upper_`ns' = `pv_`ns'' + invttail(`df',`ss')*`se_`ns''	
				}
				if "`forecast'" == "sg" {
					gen se_`i' = .
					foreach s of numlist 1(1)`N_sims' {
						local iminusone = `i' - 1
						qui sum `e(asn)' in `s', meanonly
						local sigma_sq = r(mean)
						qui sum `stub'`ldv_k' in `s', meanonly
						local gamma_sq = (r(mean))^2
						replace se_`i' = sqrt(`sigma_sq'*(1 + `iminusone'*`sigma_sq'*`gamma_sq')) in `s'
					}
					_pctile se_`i', percentiles(`lo',`hi')
					local lower_`ns' = `pv_`ns'' - invttail(`df',`ss')*`r(r1)'
					local upper_`ns' = `pv_`ns'' + invttail(`df',`ss')*`r(r2)'
					drop se_`i'
				}
				if "`forecast'" == "ae" {
					if `i' == 1 {
						local var_`ns' = `sigma_sq'
					}
					if `i' == 2 {
						local var_`ns' = `var_`ns''*(1 + `gamma'^(2*(`i'-1)))
					}
					if `i' > 2 {
						local var_`ns' = `var_`ns'' + (`sigma_sq'*`gamma'^(2*(`i'-1)))
					}
					local se_`ns' = sqrt(`var_`ns'')
					local lower_`ns' = `pv_`ns'' - invttail(`df',`ss')*`se_`ns''
					local upper_`ns' = `pv_`ns'' + invttail(`df',`ss')*`se_`ns''	
				}
				if "`forecast'" == "se" {
					gen se_`i' = .
					if `i' == 1 {
						gen __var_`ns' = .
						foreach s of numlist 1(1)`N_sims' {
							qui sum `e(asn)' in `s', meanonly
							local sigma_sq = r(mean)
							replace __var_`ns' = `sigma_sq' in `s'
							replace se_`i' = sqrt(`sigma_sq') in `s'
						}
					}
					if `i' == 2 {
						foreach s of numlist 1(1)`N_sims' {
							sum `e(asn)' in `s', meanonly
							local sigma_sq = r(mean)
							sum `stub'`ldv_k' in `s', meanonly
							local gamma_sq = (r(mean))^2
						local gamma = r(mean)
							replace __var_`ns' = `sigma_sq'*(1 + `gamma'^(2*(`i'-1))) in `s'
							sum __var_`ns' in `s'
							local val = r(mean)						
							replace se_`i' = sqrt(`val') in `s'	
						}
					}
					if `i' > 2 {
						foreach s of numlist 1(1)`N_sims' {
							sum `e(asn)' in `s', meanonly
							local sigma_sq = r(mean)
							sum `stub'`ldv_k' in `s', meanonly
							local gamma_sq = (r(mean))^2
						local gamma = r(mean)
							sum __var_`ns' in `s', meanonly
							local val = r(mean)
							replace __var_`ns' = `val' + (`sigma_sq'*`gamma'^(2*(`i'-1))) in `s'
							sum __var_`ns' in `s', meanonly
							local var_`ns' = r(mean)
							replace se_`i' = sqrt(`var_`ns'') in `s'
						}
					}
					qui sum se_`i', meanonly
					local se_`i' = r(mean)
					local lower_`ns' = `pv_`ns'' - invttail(`df',`ss')*`se_`i''
					local upper_`ns' = `pv_`ns'' + invttail(`df',`ss')*`se_`i''
					drop se_`i' 
					if `i' == `n' {
						drop __var_`ns'
					}
				}
			}
		}
		if `numscen' == 1 {
			if "`shock'" != "" {
				post `p' (`t') (`sv') (`pv_1') (`lower_1') (`upper_1')
			}
			else {
				post `p' (`t') (`pv_1') (`lower_1') (`upper_1')
			}
		}
		if `numscen' == 2 {
			if "`shock'" != "" {
				post `p' (`t') (`sv') (`pv_1') (`lower_1') (`upper_1') (`pv_2') (`lower_2') (`upper_2')
			}
			else {
				post `p' (`t') (`pv_1') (`lower_1') (`upper_1') (`pv_2') (`lower_2') (`upper_2')
			}
		}
		if `numscen' == 3 {
			if "`shock'" != "" {
				post `p' (`t') (`sv') (`pv_1') (`lower_1') (`upper_1') (`pv_2') (`lower_2') (`upper_2') (`pv_3') (`lower_3') (`upper_3')
			}
			else {
				post `p' (`t') (`pv_1') (`lower_1') (`upper_1') (`pv_2') (`lower_2') (`upper_2') (`pv_3') (`lower_3') (`upper_3')
			}
		}
		if `numscen' == 4 {
			if "`shock'" != "" {
				post `p' (`t') (`sv') (`pv_1') (`lower_1') (`upper_1') (`pv_2') (`lower_2') (`upper_2') (`pv_3') (`lower_3') (`upper_3') (`pv_4') (`lower_4') (`upper_4')
			}
			else {
				post `p' (`t') (`pv_1') (`lower_1') (`upper_1') (`pv_2') (`lower_2') (`upper_2') (`pv_3') (`lower_3') (`upper_3') (`pv_4') (`lower_4') (`upper_4')
			}
		}	
	}
	postclose `p'
	***	
	
	*** Return the matrices used to show the scenario values
	_xcreturn, n(`n') numscen(`numscen')
	foreach i of numlist 1(1)`numscen' {
		return matrix xc_s`i' xc_s`i', copy
	}
	***
	
restore	
end
*******************************************************

*******************************************************
*** Create the temporary variables to hold the values of the scenarios; this will eventually be saved as a matrix.
capture program drop _xccreate
program define _xccreate
	syntax, rhs(varlist) [ numscen(integer 1)]
	foreach x of local rhs {
		foreach s of numlist 1(1)`numscen' {
			qui gen `x'_s_`s' = .
		}
	}
end
*******************************************************

*******************************************************
*** Replace the values of the scenarios; this will eventually be saved as a matrix.
capture program drop _xcreplace
program define _xcreplace
	syntax, rhs(varlist) it(integer) [ scen(integer 1) ]
	local c = 1
	foreach x of local rhs {
		qui replace `x'_s_`scen' = mrt_xc[1,`c'] in `it'
		local c = `c' + 1
	}
end
*******************************************************

*******************************************************
*** Return the scenarios matrices
capture program drop _xcreturn
program define _xcreturn
	syntax, n(integer) [ numscen(integer 1) ]
	qui foreach i of numlist 1(1)`numscen' {
	preserve
		keep *_s_`i'
		keep in 1/`n'
		mkmat *_s_`i', matrix(xc_s`i')		
	restore
	}
end

*******************************************************


*******************************************************
* get value of modify and shock, create inter, create these macros.
capture program drop _mrt_xc
program define _mrt_xc, rclass
	syntax, [modify(string) ]
	local regressors: colnames mrt_xc
	local regnum = colsof(mrt_xc)
	local v = 1
	foreach i of numlist 1(1)`regnum' {
		local vname : word `i' of `regressors'
		foreach m in `modify' {
			if "`vname'" == "`m'" {
				local mv`v' = mrt_xc[1,`i']
				return local mv`v' = mrt_xc[1,`i']
				local v = `v' + 1
			}
		}
	}
end
*******************************************************

**************************************************************
*** Create the percentile values for statistical significance
capture program drop _ssget
program define _ssget, rclass
	args sig
	if `sig' == . {
		return local lo = (100-95)/2
		return local hi = 100-((100-95)/2)
	}
	else {
		return local lo = (100-`sig')/2
		return local hi = 100-((100-`sig')/2)
	}
end
**************************************************************


**************************************************************
*** Get the number of scenarios
capture program drop cr_scen_miss
program define cr_scen_miss, rclass
	syntax, scen1(string) [ scen2(string) scen3(string) scen4(string) ]
	tokenize "`scen1'"
	local scen_miss_1 `1'
	tokenize "`scen2'"
	local scen_miss_2 `1'
	tokenize "`scen3'"
	local scen_miss_3 `1'
	tokenize "`scen4'"
	local scen_miss_4 `1'
	if "`scen_miss_2'" == "" & "`scen_miss_3'" == "" & "`scen_miss_4'" == "" {
		local num = 1
	}
	if "`scen_miss_4'" == "" & "`scen_miss_3'" == "" & "`scen_miss_2'" ~= "" {
		local num = 2
	}
	if "`scen_miss_4'" == "" & "`scen_miss_3'" ~= "" {
		local num = 3
	}
	if "`scen4'" ~= "" {
		local num = 4
	}
	return local numscen `num'
end
**************************************************************


**************************************************************
*** Get the shock matrices.
capture program drop td
program define td, rclass
	syntax , [shock(varname) shock_data(string) shock_num(numlist) modify(varlist) inter(varlist) ninter(integer 1)]
	version 7.0
	if "`shock'"!="" {
		if "`shock_data'"!="" {
			preserve
				use "`shock_data'", clear
				if "`inter'" != "" {
					_mrt_xc, modify(`modify')
					capture drop modify* inter*
					foreach k of numlist 1(1)`ninter' {
						gen modify`k' = .
						gen inter`k' = .
						replace modify`k' = `r(mv`k')'
						replace inter`k' = modify`k' * `shock'
					}
					mkmat `shock' modify* inter*, matrix(matshock)
				}
				else {
					mkmat `shock', matrix(matshock)
				}
				return local nshock = rowsof(matshock)
				local nshock = rowsof(matshock)
				return matrix matshock matshock
			restore
		}
		if "`shock_num'"!="" {
			return local nshock : word count `shock_num'
			local nshock : word count `shock_num'
			preserve
				tokenize "`shock_num'"
				gen __`shock' = .
				foreach i of numlist 1(1)`nshock' {
					replace __`shock' = ``i'' in `i'
				}
				keep in 1/`nshock'
				if "`inter'" != "" {				
					_mrt_xc, modify(`modify')
					capture drop __modify* __inter*
					foreach k of numlist 1(1)`ninter' {
						gen __modify`k' = .
						gen __inter`k' = .
						replace __modify`k' = `r(mv`k')'
						replace __inter`k' = __modify`k' * __`shock'
					}
					mkmat __`shock' __modify* __inter*, matrix(matshock)
				}
				else {
					mkmat __`shock', matrix(matshock)
				}				
				return matrix matshock matshock
			restore
		}
	}
end		
**************************************************************



**************************************************************
*** Check to make sure that the number of simulations is not greater than the number of shock values.
capture program drop _shockvalck
program define _shockvalck
	syntax , total_n(real) shock_n(real)	
	capture assert `shock_n' > `total_n'
	if _rc != 0 {
		di as error "The number of shock values must be greater than the number of simulations"
		exit 198
	}
end

**************************************************************


**************************************************************
*** Get the necessary information from the -estsimp- command.
capture program drop _estsimpck
program define _estsimpck, rclass
	syntax 
	version 7.0
	capture assert "`e(cmd)'"=="estsimp regress"
	if _rc != 0 {
		di as error "You must run -estsimp regress- before -dynsim-  "
		exit 198
	}
	return local N_obs = `e(N)'
	return local N_sims = `e(sims)'
	return local cmd `e(cmd)'
	return local msn `e(msn_1)'
	return local rhs `e(rhs_1)'
	return local depvar `e(depvar)'
	return local ss `e(asn)'
	mat beta = e(b)
	mat VC = e(V)
	mat S = e(Sigma)
	return matrix beta beta
	return matrix VC VC
	return matrix S S
end

**************************************************************
