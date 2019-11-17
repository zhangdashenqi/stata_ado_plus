*! 1.1.1  24mar2000  Jeroen Weesie/ICS
* code was modeled after -rank- in Matlab 4.0
program define matrank, rclass
	version 6.0

	* scratch
	tempname A U w V wmax

	* parse input
	gettoken A0 0: 0, parse(",")
	mat `A' = `A0' /* may trigger error msg */
	local nrA = rowsof(`A')
	local ncA = colsof(`A')

	syntax [, Display Rank(str) Tol(str) ]

	* Stata's "mat svd" requires #rows >= #cols  !!!!
	if `nrA' < `ncA' {
		mat `A' = `A''
	}
	mat svd `U' `w' `V' = `A'
	local nc = colsof(`w')

	* tolerance for small singular values (see Matlab 4., rank.m)
	if "`tol'" == "" {
		tempname tol
		scalar `wmax' = 0
		local i 1
		while `i' <= `nc' {
			if (`w'[1,`i'] > `wmax') {
				scalar `wmax' = `w'[1,`i']
			}
			local i = `i' + 1
		}
		scalar `tol' = `wmax' * `nc' * (2.22E-16)
	}
	else confirm number `tol'

	* rank = # sv's > tol
	local r 0
	local i 1
	while `i' <= `nc' {
		if `w'[1,`i'] > `tol' {
			local r = `r' + 1
		}
		local i = `i' + 1
	}

	* output
	if "`display'" != "" | "`rank'" == "" {
		di in gr "rank `A0' [`nrA',`ncA'] = " in ye `r'
	}
	else scalar `rank' = `r'

   * return values
   return scalar rank = `r'
	return matrix singval `w'
end
