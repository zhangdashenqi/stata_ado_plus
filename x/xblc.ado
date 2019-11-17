*! N.Orsini v.1.0.0 19apr10 
 
capture program drop xblc
program xblc
version 9
syntax varlist(min=1) , Covname(string)  at(numlist) [ Reference(string)  Level(int $S_level) ///
Format(string) Symbol(string) pr eform GENerate(namelist max=4) EQuation(string) ]

   local cilevel = `level' * 0.005 + 0.50

	if "`format'" == "" 	local fmt = "%3.2fc"
	else local fmt = "`format'" 

	if `level' <10 | `level'>99 { 
			di in red "level() invalid"
			exit 198
	}   

	if "`symbol'" == "" {
			local mys = `"-"'
	}
  	else {
			local mys = `"`symbol'"'
	}

	local nc : word count `varlist' 
	
	// Get equation name
	
	if "`equation'" == "" local eq ""
	else local eq "`equation'"

	// Covariate values at the reference X

	if "`pr'" == "" & "`reference'" != "" {

		local i 1

		foreach v of local varlist  {
				qui su `v' if `covname' == float(`reference'), meanonly
				scalar _ref`i' = r(mean)			
				local i = `i' + 1
		}
	}

	if "`eform'" != ""  di _n _col(1) "`covname'"   _col(15) "exp(xb)" _col(26) "(`level'% CI)"
				   else di _n _col(1) "`covname'"   _col(15) "xb" 	   _col(26) "(`level'% CI)"

	tempvar x xb lb ub 
	qui gen `x' = .
	qui gen `xb' = .
	qui gen `lb' = .
	qui gen `ub' = .

	local c 1

	foreach z of numlist `at' {

		local i 1

		qui replace `x' = `z' in `c'			

	      foreach v of local varlist  {

				qui su `v' if `covname' == float(`z'), meanonly

				if r(mean) == . {
								di as err "value `z' of `covname' not observed"
								exit 198
				}

			scalar _nref`i' = r(mean)
	
	if "`equation'" == "" {
	
			if "`pr'" == "" & "`reference'" != ""  {
					if `i' != `nc' local lp = "`lp' _b[`v']*(_nref`i'-_ref`i')+"
		    				else local lp = "`lp' _b[`v']*(_nref`i'-_ref`i')"
			}
			
			if "`pr'" != "" | "`reference'" == "" {
					if `i' != `nc' local lp = "`lp' _b[`v']*(_nref`i')+"
						else local lp = "`lp' _b[`v']*(_nref`i')"
			}
	}
	else {
			if "`pr'" == "" & "`reference'" != ""  {
					if `i' != `nc' local lp = "`lp' [`eq']_b[`v']*(_nref`i'-_ref`i')+"
		    				else local lp = "`lp' [`eq']_b[`v']*(_nref`i'-_ref`i')"
			}
			
			if "`pr'" != "" | "`reference'" == "" {
					if `i' != `nc' local lp = "`lp' [`eq']_b[`v']*(_nref`i')+"
						else local lp = "`lp' [`eq']_b[`v']*(_nref`i')"
			}
	}
	
			local i = `i' + 1
		}
	
  if "`equation'" == "" {
	
	 if "`pr'" != "" | "`reference'" == ""  qui lincom _b[_cons] + `lp'   
				      		else qui lincom `lp' 
	}
	else {

		 if "`pr'" != "" | "`reference'" == ""  qui lincom [`eq']_b[_cons] + `lp'   
				      		else qui lincom `lp' 
	}
 	
	 local est = r(estimate)
	 local se = r(se)

	// r(estimate) provided by lincom after logistic regression is automatically in exp form so there is no need to exponentiate again if eform is specified.
	
	if e(cmd) == "logistic" local eform ""
	
	if "`eform'" != "" {
    	 	di as text _col(1)  `z' _col(15) `fmt' exp(`est') _col(25) " (" `fmt' exp(`est'-invnorm(`cilevel')*`se') "`mys'"  `fmt' exp(`est'+invnorm(`cilevel')*`se') ")"

	 	qui replace `xb' = exp(`est') in `c'			
	 	qui replace `lb' = exp(`est'-invnorm(`cilevel')*`se') in `c'			
	 	qui replace `ub' = exp(`est'+invnorm(`cilevel')*`se') in `c'			
	}
	else {
     	 	di as text _col(1)  `z' _col(15) `fmt' `est' _col(25) " (" `fmt' `est'-invnorm(`cilevel')*`se' "`mys'" `fmt' `est'+invnorm(`cilevel')*`se' ")"

	 	qui replace `xb' = `est' in `c'			
	 	qui replace `lb' = `est'-invnorm(`cilevel')*`se' in `c'			
	 	qui replace `ub' = `est'+invnorm(`cilevel')*`se' in `c'			
	}

	 local lp ""	
	 local c = `c' + 1
	}

// Save new variables containing the displayed results

	if "`generate'" != "" {

		local listvarnames "`x' `xb' `lb' `ub'" 
		local nnv : word count `generate' 
		tokenize `generate'

		forv i = 1/`nnv' {	
				qui gen ``i'' = `: word `i' of `listvarnames''
		}
	}

end
