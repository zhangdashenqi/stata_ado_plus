*! 1.0.1 NJC 7 June 1999 STB-50 dm70
program define _glast
        version 6.0

        gettoken type 0 : 0
        gettoken g    0 : 0
        gettoken eqs  0 : 0

        syntax varlist(max=1 string) [if] [in] [, Punct(str) Trim]
        marksample touse, strok
        local type "str1" /* ignores type passed from -egen- */
        if `"`punct'"' == `""' { local punct " " }
        local plen = length(`"`punct'"')

        quietly {
                tempvar index after next
                gen byte `index' = `touse' * index(`varlist', `"`punct'"')
                gen str1 `after' = ""
                gen byte `next' = 0
                local goon 1
                while `goon' {
                        replace `after' = substr(`varlist',`index' + `plen',.)
                        replace `next' = `touse' * index(`after', `"`punct'"')
                        capture assert `next' == 0
                        if _rc == 9 {
                                replace `index' = /*
                                */ `index' + `plen' + `next' - 1 if `next'
                        }
                        else local goon 0
                }
                gen `type' `g' = ""
                replace `g' = `varlist' if `touse'
                replace `g' = substr(`varlist', `index' + `plen',.) if `index'
                compress `g'
        }
end
