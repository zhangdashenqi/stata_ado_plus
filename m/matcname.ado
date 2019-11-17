*! 1.0.0 NJC 20 July 1998  STB-50 dm69
program def matcname
* matcname A B gives A the row and column names of B
    version 5.0
    if "`1'" == "" | "`2'" == "" | "`3'" != "" {
        di in r "invalid syntax"
        exit 198
    }
    matchk `1'
    matchk `2'
    matcfa `1' `2'
    local rn : rownames(`2')
    local cn : colnames(`2')
    mat rownames `1' = `rn'
    mat colnames `1' = `cn'
end
