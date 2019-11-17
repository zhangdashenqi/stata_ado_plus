*! version 6.0.0	29dec1998	(www.stata.com/users/becketti/tslib)
*! dickey  -- perform Augmented Dickey-Fuller tests for a unit root.
*! Sean Becketti, April 1991.
*  lags synonym for nlags added 6/16/92 by SRB
*  nlags changed to lags in call to findlag, 6/17/92 by SRB
*  S_# macros defined, 6/17/92 by SRB
*  S_X_unit and S_D_date retained for new lag function., 10/11/94 by SRB
program define dickey
	version 3.0
	local varlist "req ex min(1) max(1)"
	local options "noCons Detail Findlag Lags(int 0) Nlags(int 4) Trend *"
	parse "`*'"
	local lags=cond(`lags',`lags',`nlags')		/* SRB, 6/16/92 */ 
        if (`lags'<0) {
                di in red "lags() must be >= 0"
                exit 198
        }
	local ifcons = "`cons'"==""	/* is there a constant?	*/

        local dsn "$S_FN"
	tempfile tmpfile
	quietly save `tmpfile'
	capture {
		keep `varlist' $S_X_unit $S_D_date	/* SRB, 10-11-94 */
        	if "`trend'"~="" {
			tempvar trend
                	gen long `trend' = _n
        	}
	/*
        	Lag the indicated variable, then difference it and generate
        	lags of the difference.
	*/
        	local y "`varlist'"
        	lag 1 `y', s(y)
        	dif 1 `y', s(y)
        	if `lags' {
                	lag `lags' D_y
        	}
	/*      
        	Run the Dickey-Fuller regressions.
	*/
        	reg D_y L_y `trend', `options'
        	local nobs = _result(1)
        	local ifc "constant"
        	if ~`ifcons' { local ifc "no constant" }
        	else local ifc "constant"
        	local ift "trend"
        	if "`trend'"=="" { local ift "no trend" }
        	else local ift "trend"
        	noi di in gr _n "(obs=`nobs', `ifc', `ift')"
        	noi di in gr "  Lags   tau"
        	noi di in gr "-------------"
        	local l = -1
        	while (`l'<`lags') {
                	local l = `l' + 1
                	if (`l'==0) {
                        	reg D_y L_y `trend', `options'
                	}
                	else if (`l'==1) {
                        	reg D_y L_y LD_y `trend', `options'
                	}
			else {
                        	reg D_y L_y LD_y-L`l'D_y `trend', `options'
                	}
                	local sign = sign(_b[L_y])
                	test L_y
                	local tau = `sign'*sqrt(_result(6))
                	noi di in ye %5.0g `l' _skip(3) %5.0g `tau'
/*	Next 2 lines, SRB 6/17/92	*/
			local j = `l'+1
			local tau`j' = `tau'
        	}
        	if "`findlag'"!="" {
                	noi findlag D_y L_y `trend', /*
				*/ z l(`lags') `detail' `options'
        	}
	}
	local rc=_rc
        quietly use `tmpfile', clear
	capture erase `tmpfile'
        mac def S_FN "`dsn'"
	error `rc'
/*	Rest of program, SRB 6/17/92	*/
	local j=0
	while (`j'<=`lags') {
		local j=`j'+1
		mac def S_`j' = `tau`j''
	}
end
