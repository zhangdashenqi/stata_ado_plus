*! regdiag -- calculate and store diagnostics for the most recent regression
*! version 1.0.1     Sean Becketti     January 21, 1994         STB-15: sts4
*  version 1.0.0, August 1993
*  version 1.0.1, 1/21/94: changed _N to `last' in DW test to fix MV problem.
program define regdiag
	version 3.1
	local if "opt pre"
	local in "opt pre"
	local options "Aic AICC ALl ARch AR2 Dw Fpe H HQ Lags(int 0) LM *"
	parse "`*'"
	local star "`options'"
	local sif "`if'"
	local sin "`in'"
	local if
	local in
	local options "MDF(int 0) Mdl Normal Pc Q RBar2 Residual(str) R2 Sc Time"
	parse ",`star'"
	local if "`sif'"
	local in "`sin'"
	quietly {
/*
	Was the most recent estimation command one we are prepared to handle?
*/
	local cmd "$S_E_cmd"
	if !(("`cmd'"=="regress") | ("`cmd'"=="fit") | ("`cmd'"=="tsfit") | ("`cmd'"=="tsreg")) {
		if "`cmd'"=="" { di in re "no previous estimates" }
		else { di in re "cannot analyze results of estimation command: `cmd'" }
		error 98
	}
	local ifts = ("`cmd'"=="tsfit") | ("`cmd'"=="tsreg")
/*
	Restore the previous equation and calculate some of the quantities
	needed in many of the formulae.
*/
	`cmd'		/* reload the estimation results */
	if "`in'"=="" { local in "$S_E_in" }
	if "`if'"=="" { local if "$S_E_if" }
	tempname N K Rbar2 rmse R2 s2
	scalar `N' = _result(1)
	if `mdf'>0 { scalar `K' = `mdf' }
	else if `ifts' { scalar `K' = $S_E_K }
	else { scalar `K' = `N' - _result(5) }
	scalar `rmse' = _result(9)
	scalar `Rbar2' = _result(8)
	scalar `R2' = _result(7)
	scalar `s2' = `rmse'^2 * (`N'-`K')/`N'	/* ML estimate of sigma^2 */
/*
	Which diagnostics are requested?
*/
	local all = "`all'"!=""         /* all diagnostics             */
        local time = "`time'"!=""    /* standard set of TS diagnostics */
	local aic = "`aic'"!="" | `all' | `time'            /* standard */
	local aicc = "`aicc'"!="" | `all'
	local arch = "`arch'"!="" | `all' | `time'          /* standard */
	local dw = "`dw'"!="" | `all' | `time'              /* standard */
	local fpe = "`fpe'"!="" | `all'
	local h = "`h'"!="" | `all'
	local hq = "`hq'"!="" | `all'
	local lm = "`lm'"!="" | `all' | `time'              /* standard */
	local mdl = "`mdl'"!="" | `all'
	local normal = "`normal'"!="" | `all' | `time'      /* standard */
	local pc = "`pc'"!="" | `all'
	local q = "`q'"!="" | `all' | `time'                /* standard */
	local rbar2 = "`rbar2'"!="" | "`ar2'"!="" | `all'
	local r2 = "`r2'"!="" | `all'
	local sc = "`sc'"!="" | `all' | `time'              /* standard */
/*
	Either calculate residuals or store the user-supplied residuals.
*/
	local ifuser = "`residua'"!=""	/* Did the user supply the residuals? */
	if `ifuser' { 
		conf v `residua'
		local res "`residua'"
		sum `res' `if' `in'
		scalar `N' = _result(1)
		scalar `s2' = _result(4)*(`N'-1)/`N'
		scalar `rmse' = sqrt(_result(4)*(`N'-1)/(`N'-`K'))
	}
	else { 
		tempvar res
		predict double `res', resid	/* use ordinary residuals */
	}
	tempvar touse
	mark `touse' `if' `in'
	markout `touse' `res'
	_crcnuse `touse'
	local N $S_1
	local first=$S_3
	local last=$S_4
	local in "in `first'/`last'"
	local gaps=$S_2
/*
        Eliminate tests that can't tolerate gaps.
*/
	if `gaps' { 
                local if "if `touse'"
                local h 0
                local q 0
        }
	else { local if }
/*
	Calculate the model selection statistics.
*/
	if `aic' { 
		global S_E_AIC = log(`s2') + 2*`K'/`N'
		local x = round($S_E_AIC,.001)
		noi di _skip(15) in gr "AIC: " in ye "`x'"
	}
	if `aicc' { 
		global S_E_AICC = log(`s2') + (`N'+`K')/(`N'-`K'-2)
		local x = round($S_E_AICC,.001)
		noi di _skip(14) in gr "AICC: " in ye "`x'"
	}
	if `fpe' { 
		global S_E_FPE = `s2'*(`N'+`K')/(`N'-`K')
		local x = round($S_E_FPE,.001)
		noi di _skip(15) in gr "FPE: " in ye "`x'"
	}
	if `hq' { 
		global S_E_HQ = log(`s2') + 2*`K'*log(log(`N'))/`N' 
		local x = round($S_E_HQ,.001)
		noi di _skip(16) in gr "HQ: " in ye "`x'"
	}
	if `mdl' {
		parse "$S_E_vl", parse(" ")
		mac shift
		matrix accum xx = `*' `if' `in', $S_E_cons
		global S_E_MDL = log(`N'*`s2') + log(det(xx))/`N' 
		local x = round($S_E_MDL,.001)
		noi di _skip(15) in gr "MDL: " in ye "`x'"
	}
	if `pc' { 
		global S_E_PC = `rmse'^2 * (1 + `K'/`N')
		local x = round($S_E_PC,.001)
		noi di _skip(16) in gr "PC: " in ye "`x'"
	}
	if `rbar2' { 
		if `ifuser' { 
			noi di in re "Can't calculate R-squared from user-supplied residuals"
			error 98 
		}
		global S_E_aR2 = `Rbar2'
		local x = round($S_E_aR2,.01)
		noi di in gr "adjusted R-squared: " in ye "`x'"
	}
	if `r2' { 
		if `ifuser' { 
			noi di in re "Can't calculate R-squared from user-supplied residuals"
			error 98 
		}
		global S_E_R2 = `R2'
		local x = round($S_E_R2,.01)
		noi di _skip(9) in gr "R-squared: " in ye "`x'"
	}
	if `sc' { 
		global S_E_SC = log(`s2') + log(`N')*`K'/`N'
		local x = round($S_E_SC,.001)
		noi di in gr " Schwarz criterion: " in ye "`x'"
	}
/*
	Now calculate the diagnostics which are more complicated functions
	of the residuals.  First, calculate period and lags.
*/
	period
	local period "$S_1"
	local lags=`lags'
	if `lags'==0 { local lags=`period' }
	local nl = length("`lags'")
/*
	Allocate working space.
*/
	tempvar work
	gen double `work' = .
/*
	Store the results calculated so far to protect them from
	later calculations.
*/
	tempvar est
	est h `est'
/*
        Durbin-Watson test.
*/
	if `dw' {
                replace `work'= sum((`res'-`res'[_n-1])^2)/sum(`res'*`res') `if' `in'
                local DW = `work'[`last']
		local x = round(`DW',.001)
		noi di in gr "Durbin-Watson test: " in ye "`x'"
                if (`period'>1) {
                        local l = `period'
                        replace `work'= sum((`res'-`res'[_n-`l'])^2)/sum(`res'*`res') `if' `in'
                        local sDW = `work'[`last']
			local x = round(`sDW',.001)
			noi di in gr "  seasonal DW test: " in ye "`x'"
		}
	}
/*
        Q test.
*/
	if `q' {
                cap _ac `res' `if' `in', lags(`lags')
                local i = 1 + 3*`lags'
                local Q = chiprob(`lags',${S_`i'})
		local x = round(`Q',.01)
		local n = 10 - `nl'
		noi di _skip(`n') in gr "Q(" in ye "`lags'" in gr ") test: " in ye "`x'"
	}
/*
        LM, ARCH, and H tests.
*/
	if `arch' | `lm' {
		conf new v XyZzY
		local vname "XyZzY"
		local i = 0
		while `i'<`lags' {
			local i = `i' + 1
			_addl `vname'
			local vname "$S_1"
			local rhs "`rhs' `vname'"
		}
	}
	if `lm' {					/* LM */
		rename `res' XyZzY
                lag `lags' XyZzY
                reg XyZzY `rhs' `if' `in', nocon
                local LM = fprob(_result(3),_result(5),_result(6))
		drop `rhs'
		rename XyZzY `res'
		local x = round(`LM',.01)
		local n = 9 - `nl'
		noi di _skip(`n') in gr "LM(" in ye "`lags'" in gr ") test: " in ye "`x'"
	}
	if `arch' | `h' { gen double XyZzY = `res'*`res' `if' `in' }
	if `arch' {					/* ARCH */
		lag `lags' XyZzY
		reg XyZzY `rhs' `if' `in'
		local ARCH = fprob(_result(3),_result(5),_result(6))
		drop `rhs'
/*		local x = round(`ARCH',.01)     */
		local x : display %5.2f = `ARCH'
		local n = 7 - `nl'
		noi di _skip(`n') in gr "ARCH(" in ye "`lags'" in gr ") test: " in ye "`x'"
	}
	if `h' {					/* H */
		replace `work' = sum(XyZzY) `if' `in'
		local m = int(`N'/3)
		local h = `m'*(`work'[`last']-`work'[`last'-`m'])/`work'[`first'+`m'-1]
		local H = chiprob(`m',`h')
		local x = round(`H',.01)
		noi di _skip(12) in gr "H test: " in ye "`x'"
	}
	cap drop XyZzY
/*
	Test the normality of the residuals.
*/
	if `normal' {
                tempvar order
                gen long `order' = _n `in'
                if (`N' <= 5000) {
                        _sfran `res' `if' `in'
                        local NORM "$S_5"
                }
                else {
                        sktest `res' `if' `in'
                        local NORM "$S_4"
                }
		sort `order' `in'
		local x = round(`NORM',.01)
		noi di _skip(4) in gr "normality test: " in ye "`x'"
	}
/*
	Add the residual-based diagnostics to the other results.
*/
	est u `est'
	global S_E_norm "`NORM'"
	global S_E_DW   "`DW'"
	if ("`sDW'"!="") { global S_E_sDW  "`sDW'" }
	global S_E_Q    "`Q'"
	global S_E_lm   "`LM'"
	global S_E_arch "`ARCH'"
	global S_E_H    "`H'"
	} /* quietly */
end
