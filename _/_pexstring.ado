*! version 0.2.1 2005Jun20 - fix for long string jf
*  version 0.2.0 2005-02-03

//  change values in PE_in to string x(a=1 b=2..)

capture program drop _pexstring
program _pexstring, rclass
    version 8
    local cols = colsof(PE_in)
    local xnames : colnames PE_in
    local xis ""
    foreach c of numlist  1/`cols'  {
        local xnm : word `c' of `xnames'
        local xval = PE_in[1,`c']
        local xis "`xis' `xnm'=`xval'"
    }
    return local xis "`xis'"
end
