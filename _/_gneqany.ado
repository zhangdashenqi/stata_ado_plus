*! 1.0.1 NJC 23 March 1999 STB-50 dm70
program define _gneqany
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
                gen byte `g' = 0  /* ignore user-supplied `type' */
                local i = 1
                while `i' <= `nvars' {
                        local j = 1
                        while `j' <= `nnum' {
                                local nj : word `j' of `nlist'
                                replace `g' = `g' + 1 /*
                                 */ if ``i'' == `nj' & `touse'
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
