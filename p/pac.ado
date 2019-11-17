*! version 3.0.0  
*! pac -- display partial autocorrelations
*! Sean Becketti, August 1989, updated April 1991.
*  lags synonym for nlags added by SRB 6/16/92
program define pac
	version 3.0
	local varlist "req ex max(1)"
	local options "noConstant Lags(int 0) Nlags(int 20) Symbol(str) TItle(str) *" 
	parse "`*'"
	local lags=cond(`lags',`lags',`nlags')		/* SRB 6/16/92 */
	if `lags'<=0 {
		di in re "lags() must be positive"
		exit 198
	}
	local lags = min(`lags',_N-5)
	local S_FN "$S_FN"
	local x "`varlist'"
	tempvar lag pac pacse mpacse
	tempfile tmpfile
	qui save `tmpfile'
	capture {
		keep `x'
		lag `lags' `x', s(x)
		gen long `lag' = _n
		lab var `lag' "Lag"
		gen float `pac' = .
		lab var `pac' "Partial autocorrelations"
		local l 0
		while (`l' < `lags') {
			local l = `l' + 1
			if (`l'==1) {
				reg `x' L.x, `constan'
				replace `pac' = _b[L.x] in `l'
			}
			else {
				reg `x' L.x-L`l'.x, `constan'
				replace `pac' = _b[L`l'.x] in `l'
			}
		}
		count if `x'~=.
		gen float `pacse' = sqrt(1/_result(1)) in f/`lags'
		lab var `pacse' "SE band"
		gen float `mpacse' = -`pacse'
		lab var `mpacse' " "
		local xlab : variable label `x'
		if "`xlab'"=="" {
			local xlab "`x'"
		} 
		if ("`title'"!="") {
			if ("`title'"!=".") {
				local title "title(`title')"
			}
			else	local title
		}
		else local title "title(Partial autocorrelations of `xlab')"
		if "`symbol'"=="" { local symbol o }
		gr `pac' `pacse' `mpacse' `lag', yline(0) border c(lll) /*
			*/ s(`symbol'.i) pen(277) /*
			*/ ylab(-1,-.5,0,.5,1) rlab(-1,-.5,0,.5,1) xlab /*
			*/ `title' `options'
	}
	local rc=_rc
	qui use `tmpfile', clear
	erase `tmpfile'
	mac def S_FN "`S_FN'"
	error `rc'
end
