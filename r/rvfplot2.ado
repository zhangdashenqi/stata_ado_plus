*! NJC 2.2.0 8 October 2007
* NJC 2.1.2 6 December 2004
* NJC 2.1.1 21 October 2004
* NJC 2.1.0 25 Feb 2004
* NJC 2.0.0 27 Feb 2003
* NJC 1.2.0 8 Oct 2002
* NJC 1.1.0 7 Aug 2002
* NJC 1.0.0 15 Oct 2001
program rvfplot2	/* residual vs. fitted */
	version 8
	syntax [fweight] [, Anscombe Deviance Likelihood Pearson Residuals ///
	RESPonse RSTAndard RSTUdent Score Working                ///
	STAndardized STUdentized MODified ADJusted               /// 
	plot(str asis) addplot(str asis)                         ///
	FSCale(str) RSCale(str) LOWESS(str asis) LOWESS2         ///
	RCSPLINE(str asis) RCSPLINE2 YTItle(str asis) * ] 

	if `"`rcspline'`rcspline2'"' != "" { 
		if c(stata_version) < 10 { 
			di as err "rcspline not implemented in Stata " ///
			c(stata_version) 
			exit 198 
		}
	} 

	if "`rscale'" != "" & !index("`rscale'","X") { 
		di as err "rscale() does not contain X"
		exit 198 
	} 	
	
	if "`fscale'" != "" & !index("`fscale'","X") { 
		di as err "fscale() does not contain X"
		exit 198 
	} 	

	local opts "`anscombe' `deviance' `likelihood' `pearson'"  
	local opts "`opts' `residuals' `response' `rstandard' `rstudent'"
	local opts "`opts' `score' `working'" 
	local opts = trim("`opts'") 
	
	local nopts : word count `opts' 
	if `nopts' > 1 { 
		di as err "must specify at most one type of residual" 
		exit 198 
	}
	else if `nopts' == 0 {
		if "`e(cmd)'" == "glm" local opts "response" 
		else local opts "residuals" 
	}	

	local mod `standardized' `studentized' `modified' `adjusted'  

	tempvar resid hat
	quietly predict `resid' if e(sample), `opts' `mod' 
	quietly predict `hat' if e(sample)
	
	if "`opts'" == "rstudent"       local opt "Studentized"
	else if "`opts'" == "rstandard" local opt "Standardized" 
	else if "`mod'" != ""  	        local opt "`=proper("`mod'")' `opts'"
	else                            local opt "`=proper("`opts'")'" 
		
	if "`opts'" != "residuals" label var `resid' "`opt' residuals" 
	label var `hat' "Fitted values"
	
	qui if "`rscale'" != "" {
		local lbl : variable label `resid' 
		local lbl : subinstr local rscale "X" `"`lbl'"', all 
		label var `resid' `"`lbl'"' 
		local rscale : subinstr local rscale "X" "`resid'", all  
		replace `resid' = `rscale' 
	}
	
	if `"`ytitle'"' == "" { 
		if `"`lbl'"' != "" local ytitle `"`lbl'"' 
		else local ytitle : variable label `resid' 
	}	
	
	qui if "`fscale'" != "" {
		local lbl : variable label `hat' 
		local lbl : subinstr local fscale "X" `"`lbl'"', all
		label var `hat' `"`lbl'"' 
		local fscale : subinstr local fscale "X" "`hat'", all  
		replace `hat' = `fscale' 
	}	

	local l = 1 

	if `"`lowess'`lowess2'"' != "" { 
		local lowessplot lowess `resid' `hat', `lowess' 
		local ++l 
		local lgnd `l' "lowess" 
	} 

	qui if `"`rcspline'`rcspline2'"' != "" { 	
		local 0 , `rcspline' 
		local wexp `weight' `exp' 
		local scatter `options' 
		syntax [, NKnots(passthru) Knots(passthru) DIsplayknots *]
		tempname stub safe
		mkspline `stub' = `hat' if e(sample) [`wexp'] ///
		, cubic `nknots' `knots' `displayknots' 
		_estimates hold `safe' 
		regress `resid' `stub'* [`wexp'] 
		tempvar pred 
		predict `pred' 
		_estimates unhold `safe' 
		local rcsplineplot mspline `pred' `hat', bands(200) `options'  
		local ++l 
		local lgnd `lgnd' `l' "spline" 
		local options `scatter' 
	}

	twoway scatter `resid' `hat',    ///
	legend(order(`lgnd')) yti(`ytitle') `options' ///
	|| `lowessplot'               /// 
	|| `rcsplineplot'               /// 
	|| `plot'			///
	|| `addplot'			///
        // blank
end
