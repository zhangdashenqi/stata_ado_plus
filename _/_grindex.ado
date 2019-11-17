*! 1.0.0 NJC 10 March 1999 STB-50 dm70
program define _grindex
        version 6.0

        gettoken type 0 : 0
        gettoken g    0 : 0
        gettoken eqs  0 : 0

        syntax varlist(max=1 string) [if] [in], SUBstr(str)
        marksample touse, strok
        local type "byte" /* ignores type passed from -egen- */

        quietly {
                tempvar after next
                gen str1 `after' = ""
                gen byte `next' = 0
                local sslen = length(`"`substr'"')
                gen `type' `g' = index(`varlist', `"`substr'"') if `touse'
                local goon 1
                while `goon' {
                        replace `after' = substr(`varlist',`g' + `sslen',.)
                        replace `next' = index(`after', `"`substr'"')
                        capture assert `next' == 0
                        if _rc == 9 {
                                replace `g' = `g' + `sslen' + `next' - 1 if `next'
                        }
                        else local goon 0
                }
        }
end
