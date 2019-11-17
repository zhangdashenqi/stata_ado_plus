*! 1.0.1  24mar2000  Jeroen Weesie/ICS
program define matpower, rclass
	version 6.0

	* scratch
	tempname A At PowerA U W V Wmax

	* parse input
	gettoken A0 0 : 0, parse(",")
	mat `A' = `A0'  /* may triogger error msg */
	local nrA = rowsof(`A')
	local ncA = colsof(`A')

	syntax, k(real) [, Display Power(str) Rank(str) Tol(str) * ]

	* singular value decomposition requires "long" matrices !?!
	if rowsof(`A') < colsof(`A') {
		mat `At' = `A''
		mat svd `V' `W' `U' = `At'
	}
	else	mat svd `U' `W' `V' = `A'

	* tolerance for zero-elements of the diagonal elements of W
	if "`tol'" == "" {
		* max of singular values
		local nc = colsof(`W')
		scalar `Wmax' = 0
		local i 1
		while `i' <= `nc' {
			if (`W'[1,`i'] > `Wmax') {
				scalar `Wmax' = `W'[1,`i']
			}
			local i = `i' + 1
		}
		tempname tol
		scalar `tol' = `Wmax' * `nc' * (2.22E-16)
	}
	else	confirm number `tol'

	* apply power-transform to the diagonal of W
	local i 1
	local rnk 0
	while `i' <= colsof(`W') {
		if `W'[1,`i'] > `tol' {
			mat `W'[1,`i'] = (`W'[1,`i'])^(`k')
			local rnk = `rnk' + 1
		}
		else	mat `W'[1,`i'] = 0
		local i = `i' + 1
	}

	* produce Power
	if `rnk' == 0 {
		mat `PowerA' = J(`ncA',`nrA',0)
	}
	else	mat `PowerA' = `V' * diag(`W') * `U''

	* display results
	if "`power'" == "" | "`display'" ~= "" {
		di _n in gr "`A0'^`k'" /*
		*/ " [`nrA',`ncA'] with rank = " in ye `rnk'
		mat list `PowerA', noheader `options'
	}

	* double save results
	if "`rank'" != "" {
		scalar `rank' = `rnk'
	}
	if "`power'" != "" {
		matrix `power' = `PowerA'
	}

	* return values
	ret scalar rank = `rnk'
	ret matrix power `PowerA'
end
exit

code is a minor adoption of matginv
