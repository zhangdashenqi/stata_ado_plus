*! version 1.6.0 3/29/01

capture program drop _peabbv
program define _peabbv
    cap version 7
    if _rc == 0 {
        local matnm "`1'"
        local nms : colnames `matnm'
        tokenize `nms'
        while "`1'"!="" {
            local x = abbrev("`1'", 12)
            local newnms "`newnms'`x' "
            macro shift
        }
        mat colnames `matnm' = `newnms'
    }
end
