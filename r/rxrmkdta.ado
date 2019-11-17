*! version 9510                                       (STB-28: sg45)
program define rxrmkdta
  version 3.1
*    version 4.0
    local matname "`1'"
    local rcolnam "`2'"
    local savedta "`3'"
    local nobs = rowsof(`matname')
    local vars : colnames(`matname')
    parse "`vars'", parse(" ")
    *
    drop _all
    set obs `nobs'
    local col = 0
    while "`1'"!="" {
        local col = `col' + 1
        local row = 0
        capture generate `1'=.
        while (`row' < `nobs' & _rc==0) {
            local row = `row' + 1
            quietly replace `1' = `matname'[`row',`col'] in `row'
        }
        mac shift
    }
    if "`rcolnam'"!="" {
        local rlabel : rownames(`matname')
        parse "`rlabel'", parse(" ")
        local row = 0
        generate str9 `rcolnam' = "         "
        while "`1'"!="" {
            local row = `row' + 1
            quietly replace `rcolnam' = "`1'" in `row'
            mac shift
        }
    }
    if "`savedta'"!="" {
        save `savedta', replace
    }
end
