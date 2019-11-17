*! 1.0.2 NJC 29 January 1999 STB-50 dm70
* 1.0.1  NJC 27 March 1998
* 1.0.0  NJC 19 June 1997
program define _grotate
        version 5.0
        local type "`1'"
        mac shift
        local g "`1'"
        mac shift
        mac shift                               /* discard = sign */
        local varlist "req ex max(1)"
        local if "opt"
        local in "opt"
        local options "Max(int 12) STart(int 1)"
        parse "`*'"

        #delimit ;
        qui gen `type' `g' =
         cond(`varlist' >= `start', `varlist' - `start' + 1,
         `varlist' + `max' - `start' + 1)
         `if' `in' ;
        #delimit cr
        qui replace `g' = `max' if `g' == 0

        local label : value label `varlist'
        if "`label'" != "" {
                local i = 1
                local m = `start'
                while `i' <= `max' {
                        local la : label `label' `m'
                        label define `g' `i' "`la'", modify
                        local i = `i' + 1
                        local m = cond(`m' == `max', 1, `m' + 1)
                }
                label val `g' `g'
        }
        local fmt : format `varlist'
        format `g' `fmt'
end
