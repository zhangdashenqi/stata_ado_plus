*!  hpfilter -- Hodrick-Prescott filter for time series smoothing
*!  version 1.0.0     November 1993     Timothy J. Schmidt, STB-17: sts5
program define hpfilter
	version 3.1
	local varlist "req ex min(1) max(1)"
	local if "opt"
	local in "opt"
	local options "Lambda(int 1600) Suffix(str)"
	parse "`*'"

cap {
	tempvar touse
	mark `touse' `if' `in'
	markout `touse' `varlist'
	_crcnuse `touse'
	local nobs  $S_1
	local gaps  $S_2
	local first $S_3
	local last  $S_4

	if (`nobs' < 6) {
		noi di in red "not enough usable observations"
		error 99
	} 
	if (`gaps') {
		noi di in red "there are gaps in the data"
		error 99
	}

	if ("`suffix'" == "") {
		local suffix = "`varlist'"
	}

/*
Put series to be smoothed into a column vector (`nobs' x 1 matrix)
*/

	tempname ts

	cap mat `ts' = J(`nobs',1,0)
	if (_rc == 908) {
		set matsize 200
		mat `ts' = J(`nobs',1,0)
	}
	local j = 1
	local i = `first'
	while (`i' <= `last') {
		mat `ts'[`j',1] = `varlist'[`i']
		local j = `j' + 1
		local i = `i' + 1
	}

/*
Assign nonzero elements of conversion matrix to local macros
*/

	local a1 = 1 +     `lambda'
	local a2 =    -2 * `lambda'
	local a3 =         `lambda'
	local a4 = 1 + 5 * `lambda'
	local a5 =    -4 * `lambda'
	local a6 = 1 + 6 * `lambda'

/*
Create square matrix of proper size (`nobs' x `nobs') and fill main diagonal
*/

	tempname A maindi Ainv HP

	mat `maindi' = J(`nobs',1,`a6')
	mat `A' = diag(`maindi')

/*
Fill secondary diagonals of conversion matrix
*/

	local i = 1
	while (`i' <= `nobs'-2) {
		local ip1 = `i' + 1
		local ip2 = `i' + 2
		mat `A'[ `i' ,`ip1'] = `a5'
		mat `A'[`ip1', `i' ] = `a5'
		mat `A'[ `i' ,`ip2'] = `a3'
		mat `A'[`ip2', `i' ] = `a3'
		local i = `i' + 1
	}
	local nm1 = `nobs'-1
	mat `A'[   1  ,  1   ] = `a1'
	mat `A'[`nobs',`nobs'] = `a1'
	mat `A'[   2  ,  1   ] = `a2'
	mat `A'[   1  ,  2   ] = `a2'
	mat `A'[`nobs', `nm1'] = `a2'
	mat `A'[`nm1' ,`nobs'] = `a2'
	mat `A'[   2  ,  2   ] = `a4'
	mat `A'[`nm1' , `nm1'] = `a4'

/*
Compute smoothed series using inverse of conversion matrix
*/

	mat `Ainv' = inv(`A')
	mat `HP' = `Ainv' * `ts'

	_addop `suffix' H
	gen $S_1 = .
	local j = 1
	local i = `first' 
	while (`i' <= `last') {
		replace $S_1 = `HP'[`j',1] in `i'
		local j = `j' +1
		local i = `i' + 1
	}
}

end
