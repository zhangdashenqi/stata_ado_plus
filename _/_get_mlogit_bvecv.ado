*! version 1.0.0 2009-10-21 jsl
*    - based on _get_mlogit_bv but leave b as vector

*  get stata e(b) and e(V) from -mlogit- and reshape
*  to the format used by SPost based on Stata 9

capture program drop _get_mlogit_bvecv
capture program drop _remove_baseeq
program _get_mlogit_bvecv
    version 9
    args b v
    if `"`b'"'=="" | `"`v'"'=="" {
        di as err "_get_mlogit_bv: names for b and v must be specified"
        exit 198
    }
    if `"`e(cmd)'"'!="mlogit" {
        di as err "_get_mlogit_bv: model not mlogit"
        exit 498
    }

    // get copy of e(b) and e(V)
    matrix `b' = e(b)
    matrix `v' = e(V)

    // remove base eq if mlogit v11
    _remove_baseeq `b' `v'

/*
    // reshape b to (ncat-1) rows by (nvars + 1) columns
    // this is the stata 5 format used in SPost
    local eqs: coleq `b', quoted
    local eqs: list uniq eqs
    tempname tmp bnew
    local r 0
    foreach eq of local eqs {
        local ++r
        mat `tmp' = `b'[1, `"`eq':"']
        mat rown `tmp' = y`r'
        mat `bnew' = nullmat(`bnew') \ `tmp'
    }
    mat coleq `bnew' = :
    mat drop `b'
    mat rename `bnew' `b'
*/    
end

program _remove_baseeq
    args b v
    if `"`b'"'=="" | `"`v'"'=="" {
        di as err "_remove_baseeq: b and v must be specified"
        exit 198
    }
    if c(stata_version) < 11    exit        // Stata 11 (or newer) only
    if `"`e(cmd)'"'!="mlogit"   exit        // mlogit only
    local ibase = e(k_eq_base)              // get base equation number
    capt confirm integer number `ibase'     // check validity of ibase
    if _rc exit
    if `ibase'>=. | `ibase'<1   exit
    _ms_eq_info, matrix(`b')                // get equations info
    local l = 0                             // determine subscripts to
    forv i = 1/`r(k_eq)' {                  // remove base equation:
        if `i' == `ibase' continue, break   //   l = last element before
        local l = `l' + r(k`i')             //       base eq, or 0
    }                                       //   r = first element after
    local i = `l'                           //       base eq, or .
    while (`++i' <= r(k`ibase')) {          // make sure that base eq is,
        if `b'[1,`i']!=0        exit        // in fact, a base eq (all 0)
    }
    local r = cond(`ibase' >= r(k_eq), ., `l' + r(k`ibase') + 1)
    if `l' > 0 & `r' < . {                  // base eq within
        mat `b' = `b'[1..., 1..`l'] , `b'[1..., `r'...]
        mat `v' = `v'[1..., 1..`l'] , `v'[1..., `r'...]
        mat `v' = `v'[1..`l', 1...] \ `v'[`r'..., 1...]
    }
    else if `r' < . {                       // base eq at beginning
        mat `b' = `b'[1..., `r'...]
        mat `v' = `v'[1..., `r'...]
        mat `v' = `v'[`r'..., 1...]
    }
    else if `l' > 0 {                       // base eq at end
        mat `b' = `b'[1..., 1..`l']
        mat `v' = `v'[1..., 1..`l']
        mat `v' = `v'[1..`l', 1...]
    }
end
