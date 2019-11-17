*! version 1.6.1 1/18/03

capture program drop _peunvec
program define _peunvec, rclass
version 7
    tempname oldbeta newbeta newrow
    mat `oldbeta' = e(b)
    _perhs
    local cols = `r(nrhs)'+1
    local rows = colsof(`oldbeta')/`cols'
    local i = 1
    while `i' <= `rows' {
        local start = ((`i'-1) * `cols') + 1
        local end = `start' + `cols' - 1
        mat `newrow' = `oldbeta'[1, `start'..`end']
        mat `newbeta' = nullmat(`newbeta') \ `newrow'
        local i = `i' + 1
    }
    mat coleq `newbeta' = _
    mat list `newbeta'
    return matrix b `newbeta'
end
