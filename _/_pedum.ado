*! version 1.6.0 2/27/99

capture program drop _pedum
program define _pedum, rclass
    version 6
    syntax varlist(max=1) [if] [in]
    capture assert `varlist' == 0 | `varlist' == 1 | `varlist' == . `if' `in'
    return scalar dummy = _rc==0
end
