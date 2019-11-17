*! _gtma -- trailing moving average for egen           (STB-19: dm18)
*! version 1.0.0     Sean Becketti     March 1994
program define _gtma
	version 3.1
quietly {
	local varlist "req new max(1)"
	local exp "req nopre"
	local if "opt"
	local in "opt"
	local options "noMiss Span(integer 0) noTaper"
	parse "`*'"
	if `span'<0 {
		noi di in re "span must be positive"
		exit 412
	}
	else if `span'==0 {
		cap period
		if !_rc { local span $S_1 }
		else { local span 3 }
	}
	tempvar notmiss sumnm sumvar touse
	mark `touse' `if' `in'
	_crcnuse `touse'
	local N $S_1
	local gaps $S_2
	local first $S_3
	local last $S_4
	if !`gaps' { local if }
	else { local if "if `touse'" }
	local f = max(`first',`span')
	local in "in `f'/$S_4"
	local ifin "`if' `in'"
	gen byte `notmiss' = (`exp')!=.
	gen long `sumnm' = sum(`notmiss')
	gen double `sumvar' = sum(`exp')
	replace `varlist' = (`sumvar'-`sumvar'[_n-`span'])/(`sumnm'-`sumnm'[_n-`span']) `ifin'
	replace `varlist' = `sumvar'/`sumnm' in `span'
	if "`taper'"=="" {  /* Add tapered averages at beginning of series */
		local i 1
		while (`i'<`span') {
			replace `varlist' = `sumvar'/`sumnm' in `i' if `touse' & `sumnm'==`i'
			local i = `i' + 1
		}
	}
	if "`miss'"!="" { replace `varlist' = . if (`sumnm'-`sumnm'[_n-`span'])!=`span' `in'
}	/* end quietly */
end
