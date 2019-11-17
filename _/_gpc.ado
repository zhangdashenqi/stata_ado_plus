*! NJC 1.0.0 2 September 1998 STB-50 dm70
* percents of total
program define _gpc
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
                by `touse' `by': replace `varlist' = 100 * `exp'/`varlist'[_N]
        }
end
