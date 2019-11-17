*! NJC 1.0.1  2 September 1998 STB-50 dm70
* proportions of total
program define _gprop
        version 5.0
        local varlist "req new max(1)"
        local exp "req nopre"
        local if "opt"
        local in "opt"
        local options "by(string)"
        parse "`*'"
        tempvar touse
        quietly {
                gen byte `touse' = 1 `if' `in'
                sort `touse' `by'
                by `touse' `by': replace `varlist' = sum(`exp') if `touse'==1
                by `touse' `by': replace `varlist' = `exp'/`varlist'[_N]
        }
end
