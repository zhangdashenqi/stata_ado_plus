*! 1.2.0 NJC 9 June 1999 STB-50 dm70
* 1.1.0 NJC 2 February 1999
* 1.0.0 NJC 26 August 1998
program define _gconcat
        version 6.0

        gettoken type 0 : 0
        gettoken g    0 : 0
        gettoken eqs  0 : 0

        syntax varlist [if] [in], /* 
	*/ [Punct(str) Decode MAXLength(str) Format(str) ]

	if "`format'" != "" { local format `","`format'""' }
	local plen = length(`"`punct'"')
        local type "str1" /* ignores type passed from -egen- */
        if "`maxleng'" != "" {
                capture confirm integer n `maxleng'
                if _rc | `maxleng' < 1 | `maxleng' > 80 {
                        di in r "invalid maxlength( )"
                        exit 198
                }
                else local maxleng "maxl(`maxleng')"
        }
        local decode = "`decode'" == "decode"

        quietly {
                gen `type' `g' = "" 
                tokenize `varlist'
                while "`1'" != "" {
                        capture confirm string variable `1'
                        if _rc {
                                local decoded 0
                                if `decode' {
                                        tempvar dcdd
                                        capture decode `1', /*
                                        */ gen(`dcdd') `maxleng'
                                        if _rc == 0 {
						replace `dcdd' = string(`1'`format') /*
					*/ if `dcdd' == ""  
                                                replace `g' = /*
                                        */ `g' + `dcdd' + `"`punct'"' `if' `in'
                                                local decoded 1
                                        }
                                        capture drop `dcdd'
                                }
                                if !`decoded' {
                                        replace `g' = /*
                                */ `g' + string(`1'`format') + `"`punct'"'  `if' `in'
                                }
                        }
                        else {
                                replace `g' = /*
                        */ `g' + `1' + `"`punct'"' `if' `in'
                        }
                        mac shift
                }
                replace `g' = trim(substr(`g',1,length(`g') - `plen'))
        }
        local gtype : type `g'
        if "`gtype'" == "str80" {
                di in bl /*
        */ "(note: str80 variable created; truncated values possible)"
        }
end
