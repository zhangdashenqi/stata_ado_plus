*!  version 1.0.0 \ scott long 2007-08-05

//  task:       tabulate only missing values
//  project:    workflow chapter 4
//  author:     scott long \ 2007-08-05

//  based on tab1.ado version 2.2.4 29sep2004 by StataCorp

program define mvtab1, byable(recall)
    version 6, missing
    syntax varlist [if] [in] [fweight] [, *]
    tokenize `varlist'
    local stop : word count `varlist'
    local i 1
    tempvar touse
    mark `touse' `if' `in' [`weight'`exp']

    local weight "[`weight'`exp']"
    capture {
        while `i' <= `stop' {
            noisily di _n `"-> tabulation of ``i'' `if' `in'"'
            *                                  VVVVVVVV                      VVVV
            cap noisily tab ``i'' if `touse' & ``i''>=. `weight' , `options' miss
            if _rc!=0 & _rc!=1001 { exit _rc }
            local i = `i' + 1
        }
    }
    error _rc
end
exit
