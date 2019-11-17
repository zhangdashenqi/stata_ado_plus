*! version 1.0.0 2014-02-14 | long freese | spost13 release

//  reshape e(b) and e(V) to square matrix

program _rm_mlogitbv

    version 11
    args b v
    if `"`b'"'=="" | `"`v'"'=="" {
        di as err "_rm_mlogitbv: names for b and v must be specified"
        exit
    }
    if `"`e(cmd)'"'!="mlogit" & `"`e(cmd)'"'!="mprobit" { // v301 add mprobit
        di as err "_rm_mlogitbv: model not mlogit or mprobit"
        exit
    }

    matrix `b' = e(b)
    matrix `v' = e(V)

    * remove omitted variables
    tempname noomit
    local coln : colfullnames `b'
    local cols = colsof(`b')
    _ms_omit_info `b' // names of o. columns
    matrix `noomit' = J(1,`cols',1) - r(omit)
    mata: noomit = st_matrix(st_local("noomit"))
    mata: newb = select(st_matrix(st_local("b")), noomit)
    mata: st_matrix(st_local("b"),newb)
    mata: newv = select(select(st_matrix(st_local("v")), noomit), noomit')
    mata: st_matrix(st_local("v"),newv)

    * reassign column names
    foreach var of local coln {
        _ms_parse_parts `var'
        if (!`r(omit)') local coln2 `coln2' `var'
    }
    matrix colnames `b' = `coln2'
    matrix colnames `v' = `coln2'
    matrix rownames `v' = `coln2'

    * reshape b to (ncat-1) rows by (nvars + 1) columns
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
    mat coleq `bnew' = ""
    mat drop `b'
    mat rename `bnew' `b'

end
exit
