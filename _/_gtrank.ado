*! version 2.0.0  07/24/91
*  modified 8/30/93 by SRB to obey `in' during sort
program define _gtrank
	version 3.1
	local varlist "req new max(1)"
	local exp "req nopre"
	local if "opt pre"
	local in "opt pre"
	parse "`*'"
	tempvar GRV GRr
	quietly {
		gen `GRV' = `exp' `if' `in'
		tempvar touse
		mark `touse' `if' `in'
		markout `touse' `GRV'
		_crcnuse `touse'
		local N $S_1
		local first=$S_3
		local last=$S_4
		local in "in `first'/`last'"
		local ifgaps=$S_2
		if `ifgaps' { local if "if `touse'" }
		else { local if }
		sort `GRV' `in'
		local jlast = `first' - 1 + `N'
		local jin "in `first'/`jlast'"
		gen long `GRr' = _n-`first'+1 `if' `jin'
		if `first'>1 {
			local fm1 = `first' - 1
			replace `GRr' = 0 in 1/`fm1'
		}
		if `jlast'<_N {
			local lp1 = `jlast' + 1
			replace `GRr' = `N' + 1 in `lp1'/l
		}
		replace `GRr' = `GRr'[_n-1] if `GRV'~=. & `GRV'==`GRV'[_n-1] `jin'
		sort `GRr'
		by `GRr': replace `varlist' = `GRr'+(_N-1)/2
		if (`first'>1) | (`jlast'<_N) {
			replace `varlist' = cond((_n<`first') | (`jlast'<_n),.,`varlist')
		}
		label var `varlist' "Rank of `exp'"
	}
end
