*! 1.0.0 NJC 31 January 2013 
program trimplot, sort 
	version 8.2 
    	syntax varlist [if] [in] [ , over(varname) ///
	SUBtitle(str asis) YTItle(str asis) percent * ]

	local vlist "`varlist'" 	
	marksample touse 
       	if "`over'" != "" { 
		markout `touse' `over', strok 
        }
    
   	qui count if `touse'
	if r(N) == 0 error 2000
        	
 	local nvars : word count `varlist'

	if "`over'" != "" {
        	if `nvars' > 1 {
                	di as err "too many variables specified"
                	exit 103
        	}
        }

        qui if `nvars' > 1 {
        	preserve
		tokenize `varlist' 
		tempvar id 
		gen long `id' = _n 
        	tempname data lbl 
		forval i = 1 / `nvars' {
			local which : variable label ``i''
			if `"`which'"' == "" { 
				local which "``i''" 
			} 	
			label def `lbl' `i' `"`which'"', modify
			rename ``i'' `data'`i' 
        	}
        	reshape long `data', i(`id') 
	        local varlist "`data'"
        	label val _j `lbl'
	        local over "_j"
        }
	
        tempvar trmean depth   
	quietly {
		bysort `touse' `over' (`varlist'): ///
			gen `depth' = -min(_n, _N - _n  + 1)  if `touse'  

                bysort `touse' `over' (`depth') : gen double `trmean' = ///
			sum(`varlist') if `touse'  
		by `touse' `over' (`depth') : replace `trmean' = `trmean'/_n  
		by `touse' `over' `depth' : replace `trmean' = `trmean'[_N] 	
		label var `trmean' "trimmed mean"

		replace `depth' = -`depth'
		
		if "`percent'" != "" { 
			by `touse' `over': replace `depth' = 100 * (`depth' - 1)/_N
			label var `depth' "percent trimmed" 
		}		
		else label var `depth' "depth"
	}

	qui if "`over'" != "" {
		separate `trmean', by(`over') veryshortlabel 
		local trmean "`r(varlist)'" 
	} 	
 	
	if `"`subtitle'"' == "" {
		if `nvars' == 1 local w : variable label `varlist'
		if "`w'" == "" local w "`vlist'" 
		local subtitle `w', place(w)
	}

	if "`ytitle'" == "" local ytitle "trimmed mean" 
	
	if "`msymbol'" == "" { 
		local msymbol "oh dh th sh smplus x O D T S + X"
	}
	
	twoway scatter `trmean' `depth' if `touse', ///
	ytitle(`ytitle') subtitle(`subtitle') msymbol(`msymbol') `options' 
end
 
