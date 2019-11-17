*! 2.0.1 NJC 29 Sept 2003 tscale -> trscale
*! 2.0.0 NJC 7 May 2003       
* 1.6.1 NJC 7 Apr 2003       
* 1.6.0 NJC 5 Dec 2002       
* 1.5.0 NJC 24 March 1999        [STB-51: gr41]
* 1.4.0 NJC 17 March 1998
* 1.0.0 NJC 5 March 1998
program distplot
	version 8.0

	// plot type   
	gettoken plottype 0 : 0 
	local plotlist "area bar connected dot dropline line scatter spike" 
	if !`: list plottype in plotlist' { 
		di ///
		"{p}{txt}syntax is {inp:distplot} {it:plottype varlist} " /// 
		"... e.g. {inp: distplot scatter mpg} ...{p_end}" 
		exit 198 
	}

	syntax varlist(numeric) [if] [in] [fweight aweight/] ///
	[ , BY(varname) FREQuency MIDpoint MISSing TRSCale(str) REVerse  ///
	MSymbol(str) PLOT(str asis) * ]
	tokenize `varlist'
	local nvars : word count `varlist'

	// error checks 
	marksample touse 
	
	if "`missing'" == "" {
		if "`by'" != "" markout `touse' `by', strok 
	}
	else {
		if "`by'" == "" di as txt "missing only applies with by()" 
	}

	qui count if `touse'
	if r(N) == 0 {
		di as err "no observations satisfy conditions"
		exit 2000
	}

	if "`exp'" == "" local exp "1" 
	else {
		capture assert `exp' >= 0 if `touse'
		if _rc {
			di as err "weight assumes negative values"
			exit 402
	        }    
	}

	if "`by'" != "" {
		if `nvars' > 1 {
			di as err "too many variables specified"
			exit 103
	    	}
	}
	
	if "`trscale'" != "" { 
		if !index("`trscale'","@") { 
			di as err "trscale() does not contain @" 
			exit 198 
		}
	} 

	if "`frequency'" != "" & "`midpoint'" != "" { 
		di as err "frequency and midpoint may not be combined"
		exit 198 
	}	
	
	// we're in business 
	tempvar wt id col P midP 
	qui gen `wt' = `exp'

	if `nvars' > 1 | "`midpoint'" != "" preserve

	if `nvars' > 1 { 
		gen long `id' = _n 
		tempname data datalbl 
		local i = 1 
		foreach v of var `varlist' {
			local lbl`i' : variable label `v' 
			if `"`lbl`i''"' == "" local lbl`i' "`v'" 
			rename `v' `data'`i++'
			local xlbl "`xlbl' `v'"
		} 
	        qui reshape long `data', i(`id') j(`col') 
	    	forval i = 1 / `nvars' {
			label def `datalbl' `i' `"`lbl`i''"', modify
	    	}
		label val `col' `datalbl' 
	        local varlist "`data'"
		label var `varlist' "`xlbl'"
		local by "`col'"
	}

	if "`reverse'" != "" {
		local ineq ">"
		local minus "-"
	}
	else local ineq "<=" 

	quietly {
		sort `touse' `by' `varlist'
		local by1 "by `touse' `by' :"
		local by2 "by `touse' `by' `varlist' :"
		
		if "`midpoint'" == "" { 
			`by1' gen `P' = sum(`wt') if `touse'
			if "`frequency'" == "" {
				`by1' replace `P' = `P' / `P'[_N]
			} 	
			if "`reverse'" != "" {
				`by1' replace `P' = `P'[_N] - `P'
			}
		} 
		else {
			`by2' gen `P' = sum(`wt') if `touse'
			`by2' replace `P' = `P'[_N] 
			`by2' keep if _n == _N 
			`by1' gen `midP' = 0.5 * `P' + sum(`P'[_n-1]) 
			`by1' replace `P' = sum(`P') 
			`by1' replace `P' = `midP' / `P'[_N] 
			if "`reverse'" != "" replace `P' = 1 - `P' 
 		} 
		
		local ylbl = cond("`xlbl'" != "", "value", "`varlist'") 
		
		if "`frequency'" == "" { 
			local ytitle "Probability `ineq' `ylbl'"
		} 	
		else local ytitle "Frequency `ineq' `ylbl'" 
		
		if "`by'" != "" {
			tempvar group
			`by1' gen byte `group' = _n == 1 if `touse'
			replace `group' = sum(`group')
			local bylab : value label `by'
			count if !`touse'
			local j = 1 + r(N)
			forval i = 1 / `= `group'[_N]' {
				tempvar P_i`i'
		 		gen `P_i`i'' = `P' if `group' == `i'
         		        local byval = `by'[`j']
		    		if "`bylab'" != "" { 
					local byval : label `bylab' `byval' 
				}
			        label var `P_i`i'' `"`byval'"'
				local Plist "`Plist' `P_i`i''"
				count if `group' == `i'
				local j = `j' + r(N)
			}
		}
		else local Plist "`P'"
	}

	qui if "`trscale'" != "" { 
		foreach v of var `Plist' { 
			local newv : subinstr local trscale "@" "`v'", all 
			replace `v' = `newv' 
		}
	} 	

	if "`msymbol'" == "" { 
		local msymbol "oh dh th sh smplus x O D T S + X"
	}

	twoway `plottype' `Plist' `varlist', ytitle("`ytitle'") /// 
	ms(`msymbol') `options' ///
	|| `plot' 
	// blank 
end

