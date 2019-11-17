*! 1.0.1  24mar2000  Jeroen Weesie/ICS
program define matexp, rclass
	version 6.0

	* scratch
	tempname A At ExpA U W V

	* parse input
	gettoken A0 0 : 0, parse(",")
	capt mat `A' = `A0'  /* may trigger error msg */
	local nrA = rowsof(`A')
	local ncA = colsof(`A')

	syntax [, Display Exp(str) * ]

	* singular value decomposition requires "long" matrices !?!
	if rowsof(`A') < colsof(`A') {
		mat `At' = `A''
		mat svd `V' `W' `U' = `At'
	}
	else	mat svd `U' `W' `V' = `A'

	* apply exponential-transform to the diagonal of W
	local i 1
	local rnk 0
	while `i' <= colsof(`W') {
		mat `W'[1,`i'] = exp(`W'[1,`i'])
		local i = `i' + 1
	}
	mat `ExpA' = `V' * diag(`W') * `U''

	* display results
	if "`exp'" == "" | "`display'" ~= "" {
		di _n in gr "matrix exponential of `A0' [`nrA',`ncA'] "
		mat list `ExpA', noheader `options'
	}

	* double save results
	if "`exp'" != "" {
		matrix `exp' = `ExpA'
	}
	ret matrix exp `ExpA'
end
exit
