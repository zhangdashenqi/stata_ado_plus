*! NJC 2.0.1 3 April 2009
* NJC 2.0.0 11 October 2007
* NJC 1.0.1 21 October 2004
* NJC 1.0.0 2 April 2003
program rhetplot, sortpreserve 
	// residual heteroscedasticity plot 
	version 8
	syntax [varname(def=none numeric)]                             ///
	[, Anscombe Deviance Likelihood Pearson Residuals              ///
	RESPonse RSTAndard RSTUdent Score Working VARiance             ///
	BY(varlist) AT(numlist min=1 sort) Group(numlist int >0 max=1) ///
	LOWESS(str asis) LOWESS2 RCSPLINE(str asis) RCSPLINE2          /// 
	plot(str asis) addplot(str asis) * ]

	if `"`rcspline'`rcspline2'"' != "" { 
		if c(stata_version) < 10 { 
			di as err "rcspline not implemented in Stata " ///
			c(stata_version) 
			exit 198 
		}
	} 

	// -by()- | varlist 
	if "`varlist'" != "" & "`by'" != "" { 
		di as err "may not specify by() and varname"
		exit 198 
	}

	// -by()- | -at()- | -group()- 
	local nopts = ("`by'" != "") + ("`at'" != "") + ("`group'" != "") 
	if `nopts' != 1 { 
		di as err "must specify one of by(), group(), at() options"
		exit 198 
	}

	// choice of type of residual 
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

	// calculation of residual and fitted | varlist 
	// define groups and calculate sd(residual), mean(fitted | varlist)  
	tempvar resid sd tag  
	quietly {
		predict `resid' if e(sample), `opts'
	
		if "`varlist'" == "" { 
			tempvar what 
			predict `what' if e(sample)
		}
		else local what "`varlist'" 
	
		if "`group'" != "" { 
			tempvar g 
			egen `g' = cut(`what') if e(sample), gr(`group') label
		} 
		else if "`at'" != "" { 
			tempvar g 
			egen `g' = cut(`what') if e(sample), at(`at') label 
		} 
		else if "`by'" != "" { 
			if `: word count `by'' == 1 local g "`by'" 
			else { 
				tempvar g 
				egen `g' = group(`by'), label
			}	
		}
		
		bysort `g' : egen `sd' = sd(`resid') if e(sample)
		if "`variance'" != "" replace `sd' = `sd'^2 
		
		if "`by'" != "" local mean "`g'" 
		else { 
			tempvar mean 
			by `g': egen `mean' = mean(`what') if e(sample)
		}
		
		egen `tag' = tag(`g') if e(sample) 
	} 	
		
	// label variables  
	if "`opts'" == "rstudent"       local opt "Studentized"
	else if "`opts'" == "rstandard" local opt "Standardized" 
	else local opt = upper(substr("`opts'",1,1)) + substr("`opts'",2,.)
		
	local sdlbl = cond("`variance'" != "", "variances", "SDs") 
	if "`opt'" != "Residuals" label var `sd' "`sdlbl' of `opt' residuals" 
	else label var `sd' "`sdlbl' of `opt'" 

	if "`by'" != "" { 
		* variable labels should be OK 
	} 
	else if "`varlist'" != "" { 
		local lbl : variable label `varlist' 
		if `"`lbl'"' == "" local lbl "`varlist'" 
		label var `mean' `"means of `lbl'"' 
	} 	
	else label var `mean' "means of Fitted values"

	local l = 1 

	if `"`lowess'`lowess2'"' != "" { 
		local lowessplot lowess `sd' `mean' if `tag', `lowess' 
		local ++l 
		local lgnd `l' "lowess" 
	} 

	qui if `"`rcspline'`rcspline2'"' != "" { 	
		local 0 , `rcspline' 
		local scatter `options' 
		syntax [, NKnots(passthru) Knots(passthru) DIsplayknots *]
		tempname stub safe
		mkspline `stub' = `mean' if `tag'          ///
		, cubic `nknots' `knots' `displayknots' 
		_estimates hold `safe' 
		regress `sd' `stub'*             
		tempvar pred 
		predict `pred' 
		_estimates unhold `safe' 
		local rcsplineplot mspline `pred' `mean', bands(200) `options'  
		local ++l 
		local lgnd `lgnd' `l' "spline" 
		local options `scatter' 
	}

	twoway scatter `sd' `mean',    ///
	legend(order(`lgnd')) `options' ///
	|| `lowessplot'                 /// 
	|| `rcsplineplot'               /// 
	|| `plot'			///
	|| `addplot'			///
        // blank
end
