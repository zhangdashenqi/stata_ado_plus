*! 1.0.0  NJC 25 November 1998 STB-50 dm70
program define _grmed
        version 5.0
        local type "`1'"
        mac shift
        local g "`1'"
        mac shift
        mac shift                               /* discard = sign */
        local varlist "req ex min(1)"
        local in "opt"
        local if "opt"
        parse "`*'"
        parse "`varlist'", parse(" ")
        local nvars : word count `varlist'

        if `nvars' > _N {
                di in r "number of variables > number of values: no go"
                exit 198
        }

        tempvar touse data
        mark `touse' `if' `in'

        quietly {
                gen `type' `g' = .
                gen `data' = .
                local i = 1
                while `i' <= _N {
                        local j = 1
                        while `j' <= `nvars' {
                                replace `data' = ``j''[`i'] in `j' if `touse'
                                local j = `j' + 1
                        }
                        su `data', detail
                        replace `g' = _result(10) in `i'
                        local i = `i' + 1
                }
        }
end
