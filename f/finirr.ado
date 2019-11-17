*! version 1.0.1  29may2002
program define finirr , byable(recall) rclass
	version 7

	syntax varname [if] [in] [, Cash0(integer 0) FROM(string) 	/*
		*/ LOG * ]
	
	if "`log'" == "" {
		local logopt nolog
	}

	if "`from'" != "" {
		local init init(`from')
	}

	mlopts mlopts, `options'	

	marksample touse				/* set sample */
	_ts timevar panvar if `touse', sort onepanel
	qui tsset
	local unit1 `r(unit1)'
	local unit `r(unit)'
	local tmin `r(tmin)'
	markout `touse' `timevar'

	tempvar t b0 					/* balloons */
	gen double `b0' = `cash0'

	gen long `t' = `timevar' - `tmin' + (`cash0'!=0)

	ml model d0 finirr_d0 (`varlist' `t' `b0' = ) if `touse' ,	/*
		*/ `mlopts' `logopt' `init' nopreserve collinear 	/*
		*/ search(off) missing maximize

	tempname b
	mat `b' = e(b)

	Period p : `unit1'

	return scalar irr   = `b'[1,1]
	return scalar irr_s = return(irr) * `p'
	return scalar irr_c = (1 + return(irr))^`p' - 1

	di
	di in gr "IRR, Internal rate of return  = " in ye %8.3g return(irr)

	if `p' == 1 {
		exit
	}

	di in gr "     simple annualized rate   = " 			/*
		*/ in ye %8.3g return(irr_s) in gr "  (from `unit')"
	di in gr "     compound annualized rate = " in ye %8.3g		/*
		*/ in ye %8.3g return(irr_c) in gr "  (from `unit')"


end

program define Period
	args pmac colon unit

	local y 1
	local h 2
	local q 4
	local m 12
	local w 52
	local d 365

	local p ``unit''

	if "`p'" == "" {
		local p = 1
	}

	c_local `pmac' `p'
end

