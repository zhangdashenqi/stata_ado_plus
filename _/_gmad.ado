*! 1.0.1 NJC 29 January 1999 STB-50 dm70
* 1.0.0  17 March 1997
program define _gmad
        version 5.0
        local varlist "req new max(1)"
        local exp "req nopre"
        local if "opt"
        local in "opt"
        local options "*"
        parse "`*'"
        tempvar med mad
        quietly {
                egen double `med' = median(`exp') `if' `in', `options'
                egen double `mad' = median(abs(`exp' - `med')), `options'
                replace `varlist' = `mad'
        }
end
