*! 1.0.0 NJC 4 March 1999 STB-50 dm70
program define _gtag
        version 6
        gettoken type 0 : 0 /* type will be ignored: byte more efficient */
        gettoken g 0 : 0
        gettoken eqs 0 : 0

        syntax varlist [if] [in] [, Missing]
        tempvar touse
        quietly {
                gen byte `touse' = 1 `if' `in'
                if "`missing'" == "" {
                        tokenize `varlist'
                        while "`1'" != "" {
                                replace `touse' = . if missing(`1')
                                mac shift
                        }
                }
                sort `touse' `varlist'
                by `touse' `varlist': gen byte `g' = _n == 1 & `touse' == 1
        }
        label var `g' "tag(`varlist')"
end

/*

note: to permit idioms such as -if tag- it is important that the result be 1 or 0,
and never missing

*/
