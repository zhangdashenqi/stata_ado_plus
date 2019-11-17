*! v1.0.0 26/8/02 ARB
*! Count unique records in multi-record data
*! (c) Sealed Envelope Ltd, 2002
program define xcount, rclass sortpreserve byable(recall)
	version 7
	syntax [if] [in] [, I(varname)]
	xt_iis `i'
	local ivar "`s(ivar)'"
	marksample touse, novarlist
	markout `touse' `ivar'
	preserve
	tempvar flag N uniq svar
	qui {
	sort `ivar' `touse'
	by `ivar' `touse': gen byte `uniq' = (_n==1 & `touse')
	summ `uniq', meanonly
	local Ntot = r(sum)
	}	/* end quietly */
	* Output
	disp "{res}" %5.0f `Ntot'
end
