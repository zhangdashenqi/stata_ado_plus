*! 3.1.0 NJC 8 October 2007 
* 3.0.1 NJC 4 November 2004 
* 3.0.0 NJC 26 Feb 2003 
* 2.0.0 NJC 19 Sept 2001 
* 1.0.0 NJC 18 May 1998
program ovfplot 
	// observed vs. fitted 
	version 8 
	syntax [fweight] [ , SOrt YTItle(str asis) XTItle(str asis) ///
	CLPattern(str asis) CLSTYle(str) CLWidth(str) CLColor(str) ///
	PLOT(str asis) ADDPLOT(str asis) ///
	LOWESS(str asis) LOWESS2 RCSPLINE(str asis) RCSPLINE2 * ]

	if `"`rcspline'`rcspline2'"' != "" { 
		if c(stata_version) < 10 { 
			di as err "rcspline not implemented in Stata " ///
			c(stata_version) 
			exit 198 
		}
	} 

	// initial checking and picking up what -regress- type command 
	// leaves behind
	
	if "`e(depvar)'" == "" { 
		di as err "estimates not found" 
		exit 301 
	} 

	if `: word count `e(depvar)'' > 1 { 
		di as err "ovfplot not allowed after `e(cmd)'" 
		exit 498 
	} 
	
	local y "`e(depvar)'" 

	// get fit 
        tempvar touse fit
	gen byte `touse' = e(sample) 
	qui predict `fit' if `touse'

	// set up graph defaults 
	if `"`clpattern'"' == "" local clpattern `""-""'
	
	if `"`ytitle'"' == "" { 
		local what : variable label `y'
		if `"`what'"' == ""  local what "`y'"  
		local ytitle `""`what'""'  
	} 
	
	if `"`xtitle'"' == "" local xtitle : variable label `fit'
		
	foreach o in clstyle clwidth clcolor { 
		if "``o''" != "" local clopts "`clopts' `o'(``o'')"
	} 	

	local lgnd 1 "observed = fitted" 
	local l = 2 

	if `"`lowess'`lowess2'"' != "" { 
		local lowessplot lowess `y' `fit', `lowess' 
		local ++l 
		local lgnd `lgnd' `l' "lowess" 
	} 

	qui if `"`rcspline'`rcspline2'"' != "" { 	
		local 0 , `rcspline' 
		local wexp `weight' `exp' 
		local scatter `options' 
		syntax [, NKnots(passthru) Knots(passthru) DIsplayknots *]
		tempname stub safe
		_estimates hold `safe' 
		mkspline `stub' = `fit' if `touse' [`wexp'] ///
		, cubic `nknots' `knots' `displayknots' 
		regress `y' `stub'* [`wexp'] 
		tempvar pred 
		predict `pred' 
		_estimates unhold `safe' 
		local rcsplineplot mspline `pred' `fit', bands(200) `options'  
		local ++l 
		local lgnd `lgnd' `l' "spline" 
		local options `scatter' 
	}

	// graph
	twoway function y = x, clp(`clpattern') `clopts' range(`fit') || /// 
	scatter `y' `fit' if `touse'                                     /// 
	, ytitle(`ytitle') xtitle(`"`xtitle'"')                          ///
	legend(order(`lgnd')) `options'                                  ///
	|| `lowessplot'                                                  ///
	|| `rcsplineplot'                                                /// 
	|| `plot'                                                        ///
	|| `addplot'                                                     ///
	// blank
end

