*! version 3.0.0  10/15/91      sg31: STB-23
program define _gmdmean
        version 3.0
        local varlist "req new max(1)"
        local exp "req nopre"
        local if "opt"
        local in "opt"
        local options "by(string)"
        parse "`*'"
        tempvar touse mean
        quietly {
                gen byte `touse'=1 `if' `in'
                sort `touse' `by'
                by `touse' `by': gen double `mean' = /*
                        */ sum(`exp')/sum((`exp')!=.) if `touse'==1
                by `touse' `by': replace `varlist' = /*
                */ (sum(abs((`exp')-`mean'[_N]))/(sum((`exp')!=.))) /*
                */ if `touse'==1 & sum(`exp'!=.)
                by `touse' `by': replace `varlist' = `varlist'[_N]
        }
end
