*! v1.0.0 08/07/2002 ARB
program define xfill, sortpreserve
	version 7
	syntax varlist [if] [in] [, I(varname)]
	xt_iis `i'
	local ivar "`s(ivar)'"
	marksample touse, novarlist strok
	qui {
	count if `touse'== 1
	if r(N)==0 {
		disp "{error}no observations"
		exit 2000
	}
        tempvar miss ok
        foreach xvar of local varlist {
		gen byte `miss'=missing(`xvar')
                sort `ivar' `miss'
                by `ivar' `miss': gen byte `ok'=`xvar'[_n]==`xvar'[_n-1] if _n>1
                recode `ok' .=1
                cap assert `ok'==1 if `touse'
                if _rc {
                        nois disp "{txt}`xvar' is not constant within `ivar' -> fill not performed"
                }
                else {
                        by `ivar': replace `xvar'=`xvar'[1] if `touse'
                }
                drop `miss' `ok'
        }
end
