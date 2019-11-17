*  version 6.0.0	29dec1998	(www.stata.com/users/becketti/tslib)
*! findlag -- estimate lag length of dependent variable
*! Sean Becketti, April 1991.
*  lags synonym for nlags added by SRB 6/16/92
program define findlag
	version 3.0
	local varlist "req ex min(1)"
        local weight "aweight fweight"
	local options "noCons Detail Lags(int 0) Nlags(int 4) Robust Zero *"
	parse "`*'"
	local lags=cond(`lags',`lags',`nlags')	/* SRB, 6/16/92 */
        if (`lags'<=0) {
                di in red "lags must be positive"
                findlag
                exit
        }
	local ifcons = "`cons'"==""	/* is there a constant?	*/
/*
        Save the input data set, then drop the unwanted observations.
        This procedure guarantees that unwanted observations do not
        creep into the lags.
*/
	tempfile tmpfile
        local dsn "$S_FN"
        quietly save `tmpfile', replace
	capture {
		if "`weight'"!="" {
			tempvar wgt 
			gen float `wgt' `exp'
			local weight "[`weight'=`wgt']"
			keep `varlist' `wgt'
		}
		else	keep `varlist'
	/*
		Create the lags and drop the observations where the longest lag 
		is a missing value.  This ensures that each regression uses the 
		same number of observations.
	*/
		parse "`varlist'", parse(" ")
        	local yvar "`1'"
        	lag `lags' `yvar', s(y)
        	drop if L`lags'_y == .
	/*      
        	Run a regression to obtain the number of observations.
	*/
        	reg `varlist' `weight', `options' `cons'
		if _result(1)==0 | _result(1)==. { error 2000 }
        	local nobs = _result(1)
		noisily {
        		if "`detail'"~="" {
                		di _n in gr "(obs=`nobs')"
                		di in gr /*
*/ "Lags   nvars    RMSE       AIC         PC         SC      P(all)   P(last)"
                		di in gr _dup(74) "-"
        		}
			else {
                		di _n in gr /*
*/ "RMSE   AIC   PC    SC     (obs=`nobs')"
                		di in gr "---------------------"
        		}
        		_ts_flag `varlist' `weight', reg(regress) /*
			*/ lags(`lags') /*
			*/ ifcons(`ifcons') `detail' `zero' `options' `cons'
			if "`robust'"!="" {
        			di _n in gr "Biweight estimates"
        			if "`detail'"~="" {
                			di in gr /*
*/ "Lags   nvars    RMSE       AIC         PC         SC      P(all)   P(last)"
					di in gr _dup(74) "-"
        			}
				else {
                			di in gr /*
*/ "RMSE   AIC   PC    SC     (obs=`nobs')"
                			di in gr "---------------------"
        			}
        			_ts_flag `varlist', reg(rreg) lags(`lags') /*
				*/ ifcons(`ifcons') `detail' `zero' /*
				*/ `options' `cons'
			}
		}
	}
	local rc=_rc
        qui use `tmpfile', clear
        mac def S_FN "`dsn'"
        cap erase `tmpfile'
	error `rc'
end
