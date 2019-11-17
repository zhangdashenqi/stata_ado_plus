*! version 1.0.1 2014-06-19 | long freeze | v 11.2
* version 1.0.0 2014-02-14 | long freeze | spost13 release

//  after estimation, return the base of a factor variable
//      -- thanks to Jeff Pitblado

program _rm_get_base, rclass
    *version 13
    version 11.2
    syntax varname
    _ms_dydx_parse `varlist'
    local list `"`r(varlist)'"'
    local dim : list sizeof list
    local base "."
    forval i = 1/`dim' {
        gettoken x list : list
        _ms_parse_parts `x'
        if r(base) == 1 {
            local base = r(level)
            continue, break
        }
    }
    return scalar base = `base'
end
