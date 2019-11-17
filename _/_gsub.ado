*! 1.1.3 NJC 16 March 1999 STB-50 dm70
* Vince Wiggins provided stimulation
program define _gsub
    version 6.0

    gettoken type 0 : 0
    gettoken g    0 : 0
    gettoken eqs  0 : 0

    syntax varlist(max=1 string) [if] [in], Find(str) [ Replace(str) Word All ]

    marksample touse, strok
    local type "str1" /* ignores type passed from -egen- */

    quietly {
        tempvar slen
        gen byte `slen' = length(`varlist')
        gen `type' `g' = ""
        replace `g' = `varlist'
        local i = 1
        while `i' <= _N  {
            if `touse'[`i'] {
                local value = `g'[`i']
                local vlen = length(`"`value'"')
                if `vlen' < `slen'[`i'] {
                    local nsp = `slen'[`i'] - `vlen'
                    local spaces : di _dup(`nsp') " "
                    local value `"`spaces'`value'"'
                }
                local value : /*
                */ subinstr local value `"`find'"' `"`replace'"', `all' `word'
                replace `g' = `"`value'"' in `i'
            }
            local i = `i' + 1
        }
        compress `g'
    }
end

/*

1. `replace' not specified => delete

2.

leading spaces get chopped by

local value = `g'[`i']

so we work out how many there were and put them back again

*/
