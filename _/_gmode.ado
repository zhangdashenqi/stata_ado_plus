program def _gmode
*! 1.0.0 NJC 18 March 1999 STB-50 dm70
    version 6.0

    gettoken type 0 : 0
    gettoken g    0 : 0
    gettoken eqs  0 : 0

    syntax varlist(max=1) [if] [in], [ MISSing BY(varlist) MINmode UNIque ]

    if "`minmode'" != "" & "`unique'" != "" {
        di in r "minmode may not be combined with unique"
        exit 198
    }

    tempvar touse freq fmode uniq
    mark `touse' `if' `in'
    sort `touse' `by' `varlist'

    qui {
        by `touse' `by' `varlist' : gen `freq' = _N
        if "`missing'" == "" { replace `freq' = 0 if missing(`varlist') }

        if "`minmode'" == "" { sort `touse' `by' `freq' `varlist' }
        else gsort `touse' `by' `freq' - `varlist'

        gen byte `uniq' = 1
        if "`unique'" != "" {
            by `touse' `by' `freq' : gen `fmode' = _N
            by `touse' `by' : replace `uniq' = `freq'[_N] == `fmode'[_N]
        }

        local type : type `varlist' /* ignore `type' passed from -egen- */
        if substr("`type'",1,3) == "str" {
            gen `type' `g' = ""
        }
        else gen `type' `g' = .
        by `touse' `by' : replace `g' = `varlist'[_N] if `touse' & `uniq'
    }

end

