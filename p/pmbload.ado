*! v 1.0.0 PR 24feb2003
program define pmbload, rclass
version 6
syntax varlist(min=1 max=1)
quietly {
	keep if `varlist'!=.
	sort `varlist'
	tempvar freq
	by `varlist': gen long `freq'=_N
	by `varlist': drop if _n<_N
	local i 1
	while `i'<=_N {
		local v=`varlist'[`i']
		local values `values' `v'
		local f=`freq'[`i']
		local freqs `freqs' `f'
		local i=`i'+1
	}
	return local values `values'
	return local freq `freqs'
	return scalar uniq=_N
}
end
