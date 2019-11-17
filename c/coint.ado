*! version 3.0.0  
*! coint -- perform single-equation cointegration tests
*! Sean Becketti, April 1991.
*  modified by SRB 6/17/92
*    lags synonym added, nlags replaced
*    dickey replaced with unitroot
*    findlag and detail options ignored

program define coint
	version 3.0
	local varlist "req ex min(2)"
	local options "Lags(int 0) Nlags(int 4) noFindlag Detail Trend Vector *"
	parse "`*'"
	local lags=cond(`lags',`lags',`nlags')		/* SRB, 6/16/92 */
        if (`lags'<0) {
                di in red "lags() must be >= 0"
                exit 198
        }
/*
	Estimate the cointegrating regression, grab the residuals, and
	run the Dickey-Fuller test on them.
*/
	if "`trend'"!="" {
		tempvar trend
		qui gen long `trend' = _n
	}
	qui reg `varlist' `trend'
	if "`vector'"!="" {noi reg}	/* Echo the cointegrating vector */
	tempvar resid
	qui predict `resid', resid
	unitroot `resid', lags(`lags') 
end
