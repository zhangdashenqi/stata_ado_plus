*! 1.1.1  24mar2000  Jeroen Weesie/ICS
program define matnull, rclass
	version 6.0

	* scratch
	tempname A B Evec Eval Tol

	* parse input
	gettoken A0 0: 0, parse(",")
	mat `A' = `A0' /* may trigger error msg */

	syntax [, Display Format(passthru) Null(str) Rank(str) Tol(str) ]

	* matrix to save result
	if "`null'" == "" {
		tempname Null
	}
	else local Null "`null'"

	* spectral decomposition
	mat `B' = `A'' * `A'
	mat symeigen `Evec' `Eval' = `B'
	local n = colsof(`Eval')

	* tolerance for deciding which elements of Eval are 0
	* note that eigenvalues are sorted by -symeigen-!
	if "`tol'" == "" {
		scalar `Tol' = sqrt(`Eval'[1,1] * `n' * (2.22E-16))
	}
	else {
		confirm number `tol'
		scalar `Tol' = sqrt(`tol')
	}

	* select columns with eigenvalue Eval(i) < tol^2.
	local r 0
	local i 1
	while `i' <= `n' {
		if `Eval'[1,`i'] > `Tol' {
			local r = `r'+1
		}
		local i = `i'+1
	}

	* Null space is columns r+1..n
	if `r' < `n' {
		local rp = `r'+1
		mat `Null' = `Evec'[1...,`rp'...]
	}

	* display
	if "`display'" != "" | "`null'" == "" {
		di in gr "Null space of `A0' [" rowsof(`A') "," colsof(`A') "]" _c
		if `r' == `n' {
			di in gr " = " in ye "{ 0 }"
		}
		else {
			di in gr " has dimension " in ye =(`n'-`r') in gr " and orthonormal basis"
			mat list `Null', noheader `format'
		}
	}

	* return values
	return scalar rank = `r'
	if "`rank'" != "" {
		scalar `rank' = `r'
	}
	if `r' < `n' {
		return matrix null `Null'
		if "`null'" ~= "" {
			matrix `null' = return(null)
		}
	}
	return matrix eigenval `Eval'
end
