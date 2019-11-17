*! version 1.0 September 8, 2015 @ 11:12:29
*! Nested nonlinear probability models with khb-correction
*! Support: ukohler@uni-potsdam.de

// Caller Program
// ==============

program khbtab, rclass
local caller = c(version)

version 13
	
	// Low level parsing
	// -----------------
	
	syntax [anything] [if] [in] [aweight fweight pweight] 		/// 
	  [using] [, vce(passthru) esttab prefix(string)  ///
	  Tableoptions(string) nopreserve ape outcome(string) * Verbose ]

	if "`preserve'" == "" {
		preserve
	}
	
	gettoken model anything:anything
	gettoken Y anything:anything
	gettoken X Z0: anything, parse("||")

	local i 1
	while "`Z0'" != "" {
		local Z0: subinstr local Z0 "||" ""
		gettoken Z`i' Z0: Z0, parse("||")
		local Z `Z' `Z`i++''
	}
	local nmodels = `i'-1

	if "`weight'"!="" {
		local wexp [`weight'`exp']
	}

	if "`verbose'" != "" local noi noisily
	if `"`stats'"' == `""' local stats stats(N)

	if "`prefix'" != "" local prefix `prefix':
	if strpos("`prefix'","svy") {
		svyset
		if "`r(wexp)'" != "" local khbwexp [`r(wtype)'`r(wexp)']
		if "`wexp'" != "" {
			di "{err} Weights set with -svyset-; do not specifiy weights"
			exit 101
		}
	}
	else local khbwexp `wexp'
	
	quietly {
		`noi' khb `model' `Y' `X' || `Z' `khbwexp' ///
		  , concomitant(`concomitant') `vce' `ape' keep `options'
		
		unab residuals : _khb_res*
		
		if "`outcome'" != "" {
			local predict predict(outcome(`outcome'))
		}
		else local predict predict(outcome(1))

		`noi' `prefix' `model' `Y' `X' `residuals' `wexp', `vce'

		if "`ape'"=="ape" `noi' margins, dydx(*) post  ///
		  `continuous' `predict'

		estimates store _khb_0
		
		forv i = 1/`nmodels' {
			local Zqueue `Zqueue' `Z`i'' 
			local k: word count `Z`i''
			forv j = 1/`k' {
				gettoken first residuals: residuals
				
			}
			`noi' `prefix' `model' `Y'  `X' `Zqueue' `residuals'  `wexp', `vce'

			// Option APE
			if "`ape'"=="ape" `noi' margins, dydx(*) post  ///
			  `continuous' `predict'
			
			estimates store _khb_`i'
		}
	}
	
	khb_tab _khb_* `using' , `tableoptions'   ///
	  x(`X') z(`Z') y(`Y') `esttab' `droplist'

	return local names  `r(names)'
	matrix coefs = r(coefs)
	return matrix coefs = coefs

	if "`esttab'" != "" {
		return scalar nmodels = r(nmodels)
		return scalar ccols = r(ccols)
		return local m1_depname  `r(m1_depname)'
		return local cmdline  `r(cmdline)'
		matrix stats = r(stats)
		return matrix stats = stats
	}
	
end

program khb_tab, rclass
	syntax anything [using] ///
	  , x(string) z(string) y(string)  ///
	  [ c(string) esttab keep(string) stats(passthru) drop(string) * ]

	unab residuals: _khb_*
	local droplist drop(`residuals' `drop')

	if `"`keep'"' == "" local keep keep(`x' `z' `c') 
	if `"`stats'"' == "" local stats stats(N) 
	
	local cmd = cond("`esttab'"=="","estimates table","esttab")
	
	`cmd' _khb_* `using',  `droplist' `stats' `options' 

	return local names  `r(names)'
	matrix coefs = r(coefs)
	return matrix coefs = coefs

	if "`cmd'" == "esttab" {
		return scalar nmodels = r(nmodels)
		return scalar ccols = r(ccols)
		return local m1_depname  `r(m1_depname)'
		return local cmdline  `r(cmdline)'
		matrix stats = r(stats)
		return matrix stats = stats
	}
end

exit
	
	
