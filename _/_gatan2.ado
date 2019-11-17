*! NJC 1.0.0 17 December 1998 STB-50 dm70
program define _gatan2
        version 5.0
        local type "`1'"
        mac shift
        local g "`1'"
        mac shift
        mac shift                               /* discard = sign */
        local varlist "req ex min(2) max(2)"
        local in "opt"
        local if "opt"
        local options "Radians"
        parse "`*'"
        parse "`varlist'", parse(" ")
        local sin "`1'"
        local cos "`2'"
        tempvar ss sc

        quietly {
                gen byte `ss' = sign(`sin') `if' `in'
                gen byte `sc' = sign(`cos') `if' `in'
                gen `type' `g' = atan(`sin' / `cos') /*
                 */ if (`ss' == 1 & `sc' == 1) | ((`ss' == 0) & `sc' == 1)
                replace `g' =  _pi / 2 if `ss' == 1 & `sc' == 0
                replace `g' = 3 * _pi / 2 if `ss' == -1 & `sc' == 0
                replace `g' = _pi + atan(`sin' / `cos') if `sc' ==  -1
                replace `g' = 2 * _pi + atan(`sin' / `cos') /*
                 */ if `ss' == -1 & `sc' == 1
                if "`radians'" == "" { replace `g' = `g' * (180 / _pi) }
        }
        label var `g' "atan(`sin'/`cos')"
end
