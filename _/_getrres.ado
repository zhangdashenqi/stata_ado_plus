*! _getrres -- construct recursive residuals for regression model
*! version 1.0.0     Sean Becketti     November 1993
*
*	This program is currently called only by cusum, although regdiag
*	may wish to call it in the future.  I still need to add the
*	current(), lags(), and static() options.  Also, I should check
*	with Bill to see if there is a quicker way to do this.
*
program define _getrres
	version 3.1
	local varlist "req ex min(1)"
	local options "Fill Rresid(str) noConstant"
	local if "opt pre"
	local in "opt pre"
	parse "`*'"
	conf ex `rresid'
	conf new var `rresid'
	qui gen double `rresid' = .
	lab var `rresid' "Recursive residuals"
	tempvar resid hat touse tosave
	quietly {
		mark `touse' `if' `in'
		markout `touse' `varlist'
		_crcnuse `touse'
		local gaps $S_2
		local first $S_3
		local last $S_4
		local if
		if `gaps' { local if "if `touse'" }
		gen byte `tosave' = `touse'
		if "`fill'"!="" { replace `tosave' = 1 in `first'/`last' }
		reg `varlist' `if' `in', `constan'
		local T = _result(1)
		local K = `T' - _result(5)
		local i = `first' + `K' - 1
		while (`i'<`last') {
			local j = `i' + 1
			if `tosave'[`i'] {
				reg `varlist' `if' in `first'/`i', `constan'
				predict `resid', resid
				predict `hat', hat
				replace `rresid' = `resid'/sqrt(1+`hat') in `j'
				drop `resid' `hat'
			}
			local i = `j'
		}
	}
	global S_1 `T'
	global S_2 `K'
end
