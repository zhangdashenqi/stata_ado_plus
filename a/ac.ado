*! version 3.0.0  
*! ac -- display correlogram
*! Sean Becketti, August 1989, updated April 1991.
*  lags synonym for nlags added 6/16/92 by SRB.
program define ac
	version 3.0
	local varlist "req ex max(1)"
	local options "Lags(int 0) Nlags(int 20) Symbol(str) TItle(str) *" 
	parse "`*'"
	local lags=cond(`lags',`lags',`nlags')		/* SRB, 6/16/92 */
	if `lags'<=0 {
		di in re "lags must be positive"
		exit 198
	}
	local lags = min(`lags',_N-5)
	tempvar lag ac acse macse xlag
	local x "`varlist'"
	quietly {
		gen long `lag' = _n
		lab var `lag' "Lag"
		gen float `ac' = .
		lab var `ac' "Autocorrelations"
		gen float `acse' = .
		lab var `acse' "SE band"
		gen float `xlag' = .
		corr `x', cova 
		local C0 = (_result(1)-1)*_result(3)
		count if `x'~=. 
		local NN = _result(1)
		local l = 0
		while (`l' < `lags') {
			local l = `l' + 1
			replace `xlag' = `x'[_n-`l']
			corr `x' `xlag', cova
			local N = _result(1)
			replace `ac' = (_result(1)-1)*_result(4)/`C0' in `l'
			replace `xlag' = sum(`ac'^2) in f/`l'
			replace `acse' = cond(`l'>1, /*
				*/ sqrt((1+2*`xlag'[_n-1])/`NN'), /*
				*/ sqrt(1/`NN')) in `l'
		}
		gen float `macse' = -`acse'
		lab var `macse' " "
		local xlab : variable label `x'
		if "`xlab'"=="" {
			local xlab "`x'"
		} 
	}
	if ("`title'"!="") {
		if ("`title'"!=".") {
			local title "title(`title')"
		}
		else	local title
	}
	else local title "title(Autocorrelations of `xlab')"
	if "`symbol'"=="" { local symbol o }
	gr `ac' `acse' `macse' `lag', yline(0) border c(lll) /*
		*/ s(`symbol'.i) pen(277) /*
		*/ ylab(-1,-.5,0,.5,1) rlab(-1,-.5,0,.5,1) xlab /*
		*/ `title' `options'
end
