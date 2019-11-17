*! version 1.1.0  22apr2003
program define xtserial, rclass
	version 8.0

	syntax varlist [if] [in], [ Output ]

	marksample touse
	qui tsset

	local ivar "`r(panelvar)'"

	if "`ivar'" == "" {
		di as err "panel variable not specified"
		exit 498
	}

	local tvar "`r(timevar)'"

	if "`tvar'" == "" {
		di as err "time variable not specified"
		exit 498
	}
	
	if "`output'" == "" {
		local qui quietly
	}

	`qui' regress d.(`varlist') if `touse', nocons cluster(`ivar')

	tempname df_r F df p corr
	tempvar res

	qui predict double `res' if `touse', residuals

	qui regress `res' l.`res' if `touse', nocons cluster(`ivar')

	qui test l.`res' == -.5
	
	
	scalar `corr' = _b[l.`res']
	scalar `df_r' = r(df_r)
	scalar `F'    = r(F)
	scalar `df'   = r(df)
	scalar `p'    = r(p)

	di
	di as txt "Wooldridge test for autocorrelation in panel data"
	di as txt "H0: no first order autocorrelation"
	di as txt _col(5) "F(" %3.0f `df' "," %8.0f `df_r' ") = " 	///
		as res %10.3f `F'
	di as txt _col(12) "Prob > F = " as res %11.4f `p'
	
	ret scalar corr = `corr'
	ret scalar df_r = `df_r'
	ret scalar F    = `F'
	ret scalar df   = `df'
	ret scalar p    = `p'

end

