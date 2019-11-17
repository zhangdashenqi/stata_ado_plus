*! 1.0.0 NJC 3 February 1999 STB-50 dm70
program define _ghead
        version 6.0

        gettoken type 0 : 0
        gettoken g    0 : 0
        gettoken eqs  0 : 0

        syntax varlist(max=1 string) [if] [in], [Punct(str) Trim ]
        marksample touse, strok
        local type "str1" /* ignores type passed from -egen- */
        if `"`punct'"' == `""' { local punct " " }

        quietly {
                tempvar index
                gen `type' `g' = ""
                gen byte `index' = index(`varlist',`"`punct'"')
                replace `g' = `varlist' if `index' == 0 & `touse'
                replace `g' = /*
                 */ substr(`varlist', 1, `index' - 1) if `index' & `touse'
                if "`trim'" != "" { replace `g' = trim(`g') }
        }
end
