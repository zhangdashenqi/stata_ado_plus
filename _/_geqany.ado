*! 2.1.2 NJC 8 June 1999 STB-50 dm70
* 2.0.0 NJC 1 February 1999
* 1.1.0 NJC 30 Sept 1998
program define _geqany
        version 6.0
        gettoken type 0 : 0
        gettoken g 0 : 0
        gettoken eqs 0 : 0
        syntax varlist(min=1 numeric) [if] [in], Values(numlist int)
	tempvar touse 
        mark `touse' `if' `in' 
	tokenize `varlist' 
	local nvars : word count `varlist' 
        numlist "`values'", int
        local nlist "`r(numlist)'"
        local nnum : word count `r(numlist)'
        quietly {
                gen byte `g' = 0    /* ignore user-supplied `type' */
                local i = 1
                while `i' <= `nvars' {
			local j = 1 
			while `j' <= `nnum' { 
				local nj : word `j' of `nlist' 
        	                replace `g' = 1 if ``i'' == `nj' & `touse'
				local j = `j' + 1 
			}	
                        local i = `i' + 1
                }
        }
        if length("`varlist' == `values'") > 80 {
                note `g' : `varlist' == `values'
                label var `g' "`varlist': see notes"
        }
        else label var `g' "`varlist' == `values'"
end
