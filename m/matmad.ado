program def matmad, rclass 
* maximum absolute difference between matrices
* matmad A B -- for matrices A, B
*! 1.1.0 NJC 15 June 1999 STB-50 dm69
    version 6.0
    if "`1'" == "" | "`2'" == "" | "`3'" != "" {
        di in r "invalid syntax"
        exit 198
    }

    tempname D
    mat `D' = `1' - `2'

    local nr = rowsof(`D')
    local nc = colsof(`D')
    local mad = abs(`D'[1,1])
    local i 1
    while `i' <= `nr' {
        local j = 1
        while `j' <= `nc' {
            local mad = max(`mad',abs(`D'[`i',`j']))
            local j = `j' + 1
        }
        local i = `i' + 1
    }
    di `mad'
    return local mad `mad'
end
