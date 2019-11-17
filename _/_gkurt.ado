*! 1.1.1 NJC 29 January 1999 STB-50 dm70
* 1.1.0  NJC 8 April 1998
program define _gkurt
        version 5.0
        local varlist "req new max(1)"
        local exp "req nopre"
        local if "opt"
        local in "opt"
        local options "BY(string)"
        parse "`*'"

        quietly {
                tempvar touse group
                mark `touse' `if' `in'
                sort `touse' `by'
                by `touse' `by' : gen `group' = _n == 1 if `touse'
                replace `group' = sum(`group')
                local max = `group'[_N]
                local i 1
                while `i' <= `max' {
                        su `exp' if `group' == `i', detail
                        replace `varlist' = _result(15) if `group' == `i'
                        local i = `i' + 1
                }
        }
end
