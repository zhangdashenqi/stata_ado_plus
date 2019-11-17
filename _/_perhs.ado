*! version 1.6.6 2010-06-30 parse out o. names
* version 1.6.5 13Apr2005
*  version 1.6.4 2005-01-23 fix with zip and nocon

*   determine rhs variables

capture program drop _perhs
program define _perhs, rclass
    version 6.0
    * if name is passed as option it will parse these names
    local beta "`1'"
    if "`beta'" == "" {
        tempname beta
        matrix `beta' = e(b)
    }
    local varnms : colnames(`beta')


* 1.6 6 - strip out omitted coefficients with names o.
    local no_o ""
    foreach v in `varnms' {
        local iso = substr("`v'",1,2)
        if "`iso'"!="o." {
            local no_o "`no_o' `v'"
        }
    }
    local varnms `no_o'

    tokenize "`varnms'", parse(" ")

    local iszi = 0 /* is it a zip model? */
    if "`e(cmd)'"=="zip" | "`e(cmd)'"=="zinb" {
        _penocon /* check if there is a constant */
        local ncon = 1 - `r(nocon)' /* 1 if constant, else 0 */
        local iszi = 1 /* it is a zip */
    }

    * strip off _cons, _cut & _se
    local rhsnm ""

    *050123 only for nonzip
    if `iszi'==0 {
        local hascon "no"
        local i 1
        while "``i''" != "" {
            * version 1.6.3 2004-12-22 - wrong rhs names if mlogit, nocon
            * When it finds the same variable a second time, program sets
            * local hascon to yes even though there is not a constant.
            * without this it would repeat all variables ncat-1 times.
            if "`i'"=="1" {
                local nm1 "``i''"
            }
            else if "`nm1'" == "``i''" {
                local hascon "yes"
            }

            if "``i''" == "_cons" & "`hascon'"=="no" {
                local hascon "yes"
                local start2 = `i' + 1
            }
            if "``i''" != "_cons" /*
                */ & "``i''" != "_se" /*
                */ & substr("``i''",1,4) != "_cut" /*
                */ & "`hascon'"=="no" {
                local rhsnm "`rhsnm' ``i''"
            }
            local i = `i' + 1
        }
        local nvar : word count `rhsnm'
    } /* 050123 not zip */

    *050123 if zip, have to count differently for case with no constant
    if `iszi'==1 {
        local nvar = e(df_m) /* # vars in count model */
        local i = 1
        while `i'<=`nvar' {
            local rhsnm "`rhsnm' ``i''"
            local ++i
        }
        local i = `i' + `ncon' /* if constant, skip it */
        local rhsnm2 ""
        local nvar2 = e(df_c) - 1 /* # vars in inf model */
        while `i'<=`nvar'+`nvar2'+`ncon' {
            local rhsnm2 "`rhsnm2' ``i''"
            local ++i
        }
    } /* end of case for zip/zinb */

    * specail case for mlogit
    if "`e(cmd)'"=="mlogit" {
        parse "`rhsnm'", parse(" ")
        local rhsnm2 ""
        local i 1
        while `i' <= `nvar' {
            local rhsnm2 "`rhsnm2' ``i''"
            local i = `i' + 1
        }
        local rhsnm "`rhsnm2'"
        local rhsnm2 ""
    }

    return local rhsnms  "`rhsnm'"
    return local nrhs    "`nvar'"
    return local rhsnms2  "`rhsnm2'"
    return local nrhs2    "`nvar2'"

end
