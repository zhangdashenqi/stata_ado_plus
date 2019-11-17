*! 1.1.0 NJC 11 November 2010 
* 1.0.0 NJC 20 August 2008 
* ideas from z_r   1.1.1 02Feb96 JRG
*            z_rci 1.1.1 02Feb96 JRG 
program corrci, rclass 
	version 8 
        syntax varlist(numeric ts min=2) [if] [in] [aweight fweight] ///
	[, Level(real `c(level)') Matrix FOrmat(str) Abbrev(int -1)  ///
	FIsher Jeffreys lee SAving(str asis)  ] 

	/// Lee option undocumented 

	if "`fisher'" != "" & "`jeffreys'" != "" { 
		di as err "must choose between Fisher and Jeffreys" 
		exit 498 
	} 

	marksample touse 
      	qui count if `touse'
	if r(N) < 5 error 2001 
	local n = r(N) 
	local I : word count `varlist' 

	/// checking format with -confirm- not introduced until Stata 10 
	if "`format'" != "" { 
		capture di `format' 0.12345 
		if _rc error 120 
	} 
	else local format %9.3f 
	local fmt `format' 

        if `level' <= 0 | `level' >= 100 { 
		di as err "invalid confidence level"
		error 499
	}

	if "`saving'" != "" { 
		gettoken filename options : saving, parse(",") 
		if !index("`options'", "replace") { 
			if !index("`filename'", ".dta") { 
				confirm new file "`filename'.dta" 
			}
			else confirm new file "`filename'" 
		} 
		local file = 1  
	}
	else local file = 0 

	local list = "`matrix'" == "" 

        if "`weight'" != "" local weight "[`weight'`exp']" 
	tempname r upper lower d z zz 

	di 
      	matrix accum `r' = `varlist' `weight' if `touse', dev nocon
	matrix `r' = corr(`r') 
      	matrix `upper' = `r' 
	matrix `lower' = `r' 
	matrix `z' = `r' 
	 
	if "`jeffreys'" != "" { 
		scalar `d' = invnorm(.5 + `level'/200) / sqrt(`n') 
	} 
	else if "`lee'" != "" { 
		// calculated dependent on r 
	} 
        else scalar `d' = invnorm(.5 + `level'/200) / sqrt(`n' - 3)

	forval i = 1/`I' { 
		matrix `z'[`i', `i'] = . 
		local J = `i' - 1 
        	forval j = 1/`J' { 
 			matrix `z'[`i', `j'] = atanh(`r'[`i',`j'])
 			matrix `z'[`j', `i'] = `z'[`i',`j']
			if "`jeffreys'`lee'" != "" { 
				matrix `z'[`i',`j'] = ///
				`z'[`i',`j'] - (5 * `r'[`i',`j']) / (2 * `n') 
			}
			if "`fisher'" != "" { 
				matrix `z'[`i',`j'] = ///
				`z'[`i',`j'] - 2 * `r'[`i',`j'] / (`n' - 1)
			} 
			scalar `zz' = `z'[`i',`j'] 
			if "`lee'" != "" { 
				scalar `d' = invnorm(.5 + `level'/200) / ///
				(`n' - (3/2) + (5/2) * (1 - `r'[`i',`j']^2)) 
			} 
			matrix `lower'[`i',`j'] = tanh(`zz' - `d') 
			matrix `lower'[`j',`i'] = tanh(`zz' - `d') 
			matrix `upper'[`i',`j'] = tanh(`zz' + `d') 
			matrix `upper'[`j',`i'] = tanh(`zz' + `d') 
         	}
	}

	if "`matrix'" != "" {
		local corr = cond(`I' == 2, "correlation", "correlations")  
	   	di _n as txt "sample `corr':" 
		matrix list `r', format(`fmt') noheader noblank

		di _n as txt "lower and upper `level'% confidence limits:"
		matrix list `lower', format(`fmt') noheader noblank
		di 
		matrix list `upper', format(`fmt') noheader noblank
	}

	if `list'|`file' { 
		if `abbrev' == -1 { 
			foreach v of local varlist {  
				local abbrev = max(`abbrev', length("`v'"))  
			}
		} 

		if `list' { 
			local pos2 = `abbrev' + 2
			local pos3 = 2 * `pos2' 
			local pos4 = `pos3' + (`I' == 2) 
			local corr = cond(`I' == 2, "correlation", "correlations")  
			di _n as txt _col(`pos4') "`corr' and `level'% limits"
		}
	
		if `file' { 
			tempname out 
			postfile `out' str`abbrev'(var1 var2) r lower upper ///
			using "`filename'" `options' 
		} 

		tokenize `varlist' 

		forval i = 1/`I' { 
			local J = `i' + 1 
       			forval j = `J'/`I' { 
				local var1 = abbrev("``i''", `abbrev') 
				local var2 = abbrev("``j''", `abbrev') 
	
				if `list' {
					di as txt "`var1'" _col(`pos2') "`var2'"  ///
					_col(`pos3') as res `fmt' `r'[`i',`j']    ///
					`fmt' `lower'[`i',`j']                    ///
				        `fmt' `upper'[`i',`j'] 
				}
				if `file' { 
					post `out' ///
					("`var1'") ("`var2'") (`r'[`i',`j']) ///
					(`lower'[`i',`j']) (`upper'[`i',`j']) 
				}
			}
		}
	
		if `file' { 
			postclose `out' 
		} 
	}

	return matrix z = `z' 
	return matrix ub = `upper' 
	return matrix lb = `lower' 
	return matrix corr = `r' 
end

