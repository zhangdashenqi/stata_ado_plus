*! 2.0.0 NJC 1 February 1999 STB-50 dm70
* 1.1.0 NJC 30 Sept 1998
program define _gany
        version 6.0
        gettoken type 0 : 0
        gettoken g 0 : 0
        gettoken eqs 0 : 0
        syntax varlist(max=1) [if] [in], Values(str)
        marksample touse
        numlist "`values'", int
        tokenize "`r(numlist)'"
        local nnum : word count `r(numlist)'
        quietly {
                gen `type' `g' = .
                local i = 1
                while `i' <= `nnum' {
                        replace `g' = `varlist' /*
                         */ if `varlist' == ``i'' & `touse'
                        local i = `i' + 1
                }
        }
        if length("`varlist' if `values'") > 80 {
                note `g' : `varlist' if `values'
                label var `g' "`varlist': see notes"
        }
        else label var `g' "`varlist' if `values'"
end

