*! version 1.6.0 2/7/99

capture program drop _peife
program define _peife, rclass
    version 6.0
    syntax [if/] [,All]

    * Case 1: no if and no all
    if "`if'"=="" & "`all'"!="all" { local ifis "if e(sample)" }
    else {

        * Case 2: if and no all
        if "`all'"!="all" { local ifis "if e(sample) & `if'" }

        if "`all'"=="all" {

            * Case 3: if and all
            if "`if'"!="" { local ifis "if `if'" }

            * Case 4: no if and all
            if "`if'"=="" { local ifis "" }
        }
    }
    return local if "`ifis'"
end
