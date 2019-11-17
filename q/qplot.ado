*! 2.3.0 NJC 8 November 2010 
* 2.2.2 NJC 13 August 2010 
* 2.2.1 NJC 25 February 2010 
* 2.2.0 NJC 5 November 2006 
* 2.1.1 NJC 12 January 2006 
* 2.1.0 NJC 22 August 2005 
* 2.0.0 NJC 12 November 2003 
* developed from quantil2 
* 1.3.1 NJC 21 February 2002 ranks option  
* 1.3.0 NJC 22 February 2001 (STB-61: gr42.1)
* 1.2.0 NJC 10 August 1999 
* 1.1.0 NJC 24 March 1999
* 1.0.1 NJC 17 March 1998
* 1.0.0 NJC 15 March 1998 
program qplot, sort 
	version 8.0
	
	syntax varlist [if] [in] [, a(real 0.5) over(varname)  /// 
	sort MISSing REVerse RANKs TRSCale(str asis) MSymbol(str asis) ///
	YTItle(str asis) ADDPLOT(str asis) PLOT(str asis) ///
	Xvariable(varname) by(str asis) * ]
	
	tokenize `varlist'
	local nvars : word count `varlist'
	local first "`1'" 

	if "`trscale'" != "" { 
		if !index("`trscale'","@") { 
			di as err "trscale() does not contain @" 
			exit 198 
		}
	}	

	if "`over'" != "" & `nvars' > 1 {
		di as err "too many variables specified"
		exit 103
	}
	
	if `"`by'"' != "" { 
		gettoken byvar byopts : by, parse(",") 
		local BY by(`byvar') 
		local byby by(`by') 
	}	

	marksample touse  
		
	if "`missing'" == "" {
		if "`over'" != "" markout `touse' `over', strok
		if `"`by'"' != "" markout `touse' `byvar', strok 
	}
	
	qui count if `touse' 
	if r(N) == 0 error 2000 

	qui if "`over'" == "" { /* no `over' option */
		tempvar pp order
		if "`ranks'" != "" { 
			egen `pp' = rank(`first') if `touse', unique `BY' 
			label var `pp' "rank" 
		}
		else if "`xvariable'" != "" {
			local x "`xvariable'" 
			gen `pp' = `x' if `touse'
			replace `touse' = 0 if missing(`x')
			if `"`: var label `x''"' != "" { 
				label var `pp' `"`: var label `x''"' 
			}
			else label var `pp' "`x'"
		}
		else { 
			tempvar count 
			egen `pp' = rank(`first') if `touse', unique `BY' 
			egen `count' = count(`first') if `touse', `BY' 
			replace `pp' = (`pp' - `a') / (`count' - 2 * `a' + 1)
			label var `pp' "fraction of the data"
			drop `count' 
		}

		sort `touse' `byvar' `pp' 
		gen long `order' = _n

		foreach v of local varlist {
			tempvar y
			sort `touse' `byvar' `v'
			gen `y' = `v'[`order']
			local lbl : variable label `v' 
			if `"`lbl'"' != "" label var `y' `"`lbl'"' 
			else label var `y' "`v'"
			local ylist "`ylist'`y' "
			local Ylist "`Ylist'`v' "
		}
		if `"`ytitle'"' == "" {
			if `nvars' == 1 { 
				local ytitle : variable label `varlist' 
				if `"`ytitle'"' == "" local ytitle "`varlist'" 
				if !index(lower(`"`ytitle'"'), "quantile") { 
					local ytitle `"quantiles of `ytitle'"'
				}
			}		
			else local ytitle "quantiles"
		}
	}

	else qui { /* over() */
		tempvar pp group
		if "`ranks'" != "" { 
			egen `pp' = rank(`varlist') if `touse', by(`byvar' `over') unique
			label var `pp' "rank" 
		}   
		else if "`xvariable'" != "" {
			local x "`xvariable'" 
			gen `pp' = `x' if `touse'
			replace `touse' = 0 if missing(`x')
			if `"`: var label `x''"' != "" { 
				label var `pp' `"`: var label `x''"' 
			}
			else label var `pp' "`x'"
		}
		else { 
			tempvar count 
			egen `pp' = rank(`first') if `touse', unique `BY' 
			egen `count' = count(`first') if `touse', `BY' 
			replace `pp' = (`pp' - `a') / (`count' - 2 * `a' + 1)
			label var `pp' "fraction of the data"
			drop `count' 
		} 

		bysort `touse' `over' : gen byte `group' = _n == 1 if `touse'
		replace `group' = sum(`group')
		local max = `group'[_N]
		local overlab : value label `over'
		local type : type `varlist'
		local vallab : value label `varlist'

		count if !`touse'
		local j = 1 + r(N)
		forval i = 1 / `max' {
			tempvar y`i'
			gen `type' `y`i'' = `varlist' if `group' == `i'
			compress `y`i''
			local ylist "`ylist' `y`i''"
			local overval = `over'[`j']
			if `"`overlab'"' != "" local overval : label `overlab' `overval'
			label var `y`i'' `"`overval'"'
			if `"`vallab'"' != "" label val `y`i'' `vallab' 
			count if `group' == `i'
			local j = `j' + r(N)
		}

		if `"`ytitle'"' == "" {
			local ytitle : variable label `varlist'
			if `"`ytitle'"' == "" local ytitle "`varlist'" 
			if !index(lower(`"`ytitle'"'), "quantile") { 
				local ytitle `"quantiles of `ytitle'"'
			}
		}
	}

	qui if "`reverse'" != "" { 
		if "`ranks'" != "" { 
			bysort `touse' `byvar' `over' (`pp') : ///
			replace `pp' = _N + 1 - `pp'
		} 
		else replace `pp' = 1 - `pp' 
	}
	
	if "`msymbol'" == "" local msymbol "oh dh th sh smplus x O D T S + X"
	
	qui if "`trscale'" != "" { 
		local newpp : subinstr local trscale "@" "`pp'", all 
		replace `pp' = `newpp' 
		local what = cond("`ranks'" != "", "rank", "P") 
		local xtitle : subinstr local trscale "@" "`what'", all
		local xti `"xti("`xtitle'")"' 
	}	

	twoway scatter `ylist' `pp' if `touse', yti(`ytitle') `xti' ///
	sort ms(`msymbol') `byby' `options' ///
	|| `addplot'                        ///  
	|| `plot' 
	// blank 

end

