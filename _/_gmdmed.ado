*! version 3.0.0  10/15/91      sg31: STB-23
program define _gmdmed
        version 3.0
        local varlist "req new max(1)"
        local exp "req nopre"
        local if "opt"
        local in "opt"
        local options "by(string)"
        parse "`*'"
        tempvar touse
        quietly {
                gen byte `touse'=1 `if' `in'
                sort `touse' `by'
su `exp', d
local med=_result(10)
                by `touse' `by': replace `varlist' = /*
                */ (sum(abs((`exp')-`med'))/(sum((`exp')!=.))) /*
                */ if `touse'==1 & sum(`exp'!=.)
                by `touse' `by': replace `varlist' = `varlist'[_N]
        }
end
