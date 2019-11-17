*! cusum -- Graph the cusum and cusum2 charts.
*! version 1.0.0     Sean Becketti     November 1993
*
*	Still needs current(), lags(), and static() options.  These would
*	just be passed to _getrres.
*
program define cusum
	version 3.0
	local varlist "req ex min(1)"
	local options "noConstant CS(str) CS2(str) Date(str) Lw(str) LWW(str) noPlot Sqline(str) Uw(str) UWW(str) *"
	local if "opt pre"
	local in "opt pre"
	parse "`*'"
	if ("`cs'"!="") { confirm new var `cs' }
	else { tempvar cs }
	if ("`cs2'"!="") { confirm new var `cs2' }
	else { tempvar cs2 }
	if ("`lw'"!="") { confirm new var `lw' }
	else { tempvar lw }
	if ("`lww'"!="") { confirm new var `lww' }
	else { tempvar lww }
	if ("`sqline'"!="") { confirm new var `sqline' }
	else { tempvar sqline }
	if ("`uw'"!="") { confirm new var `uw' }
	else { tempvar uw }
	if ("`uww'"!="") { confirm new var `uww' }
	else { tempvar uww }
	tempvar touse
	mark `touse' `if' `in'
	markout `touse' `varlist'
	_crcnuse `touse'
	local gaps $S_2
	local first $S_3
	local last $S_4
	local in "in `first'/`last'"
	local if
	if `gaps' { local if "if `touse'" }
/*
	Calculate the CUSUM and CUSUMSQ series (Harvey 1990, p.153).
*/
	quietly {
		tempvar v
		_getrres `varlist' `if' in `first'/`last', rresid(`v') `constan'
		local T = $S_1
		local K = $S_2
		local first = `first' + `K'
		replace `touse' = . if _n < `first'
		local in  "in `first'/`last'"
		sum `v' `if' `in'
		local TK = _result(1)
		local vsd = sqrt(_result(4))
		gen float `cs' = sum(`v')/`vsd' `if' `in'
		lab var `cs' "CUSUM"
		gen float `cs2' = sum(`v'*`v') `if' `in'
		replace `cs2' = `cs2'/`cs2'[`last']
		lab var `cs2' "CUSUM squared"
/*
	Display the CUSUM graphs.
*/
		local critval = 0.948		/* 5% critical value */
		local step = 2*`critval'/sqrt(`TK')
		gen float `uw' = `critval'*sqrt(`TK') + sum(cond(`touse',`step',0)) `in'
		gen float `lw' = -`uw'
		_cu_c0 `T' `K'
		local critval = $S_1		/* 5% critical value */
		gen float `sqline' = 0 `in'
		local step = 1/(`TK'-1)
		local fp1 = `first' + 1
		replace `sqline' = sum(cond(`touse',`step',0)) in `fp1'/`last'
		gen float `uww' = `sqline' + `critval' `in'
		gen float `lww' = `sqline' - `critval' `in'
		global S_1 = `T'
		global S_2 = `K'
		global S_3 = `critval'
		if "`plot'"!="" { exit }
		if ("`date'"!="") { confirm var `date' }
		else {
			tempvar date
			gen int `date' = _n
			lab var `date' "Observation"
		}
		gr `cs' `lw' `uw' `date', yline(0) ylab(0) rlab(0) c(lll) s(oii) pen(344) `options'
		gr `cs2' `lww' `uww' `sqline' `date', ylab(0) rlab(1) c(llll) s(oiii) pen(3441) `options'
	}	/* end quietly */
end
