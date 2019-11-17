program define mylog2
version 12.1
syntax varlist(min=1 numeric) [if] [in], GENerate(string) [replace]
marksample touse
local nvar : word count `varlist'
tokenize `varlist'
forvalues i = 1 / `nvar' {
    cmpute double `generate'`i' = ln(``i'') if `touse', `replace' label("ln(``i'')")
}
end
