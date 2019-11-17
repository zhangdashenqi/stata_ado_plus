*! version 1.0.0  05/24/95
program define _gsrank
	version 3.0
	local varlist "req new max(1)"
	local exp "req nopre"
	local if "opt"
	local in "opt"
	local options "by(string)"
	parse "`*'"
	if "`by'"!="" { local bys "by `by':" }
	tempvar GRV GRr
	quietly {
		gen `GRV' = `exp' `if' `in'
		sort `by' `GRV'
		`bys' gen int `GRr' = _n if `GRV'~=.
		`bys' replace `GRr' = `GRr'[_n-1] if /*
			*/ `GRV'~=. & `GRV'==`GRV'[_n-1]
		by `by' `GRV': replace `varlist' = `GRr'+(_N-1)/2
		if "`by'"!="" { local bys "within `by'" }
		label var `varlist' "Rank of `exp' `bys'"
	}
end

