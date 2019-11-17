*! 1.0.1 NJC 29 January 1999 STB-50 dm70
* 1.0.0 17 March 1997
program define _gmdev
        version 5.0
        local varlist "req new max(1)"
        local exp "req nopre"
        local if "opt"
        local in "opt"
        local options "*"
        parse "`*'"
        tempvar mean mdev
        quietly {
                egen double `mean' = mean(`exp') `if' `in', `options'
                egen double `mdev' = mean(abs(`exp' - `mean')), `options'
                replace `varlist' = `mdev'
        }
end
