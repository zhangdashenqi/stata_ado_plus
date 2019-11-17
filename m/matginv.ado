*! 1.1.1  24mar2000  Jeroen Weesie/ICS
*         code was modeled after -pinv- in Matlab 4.0
program define matginv, rclass
	version 6.0

	* scratch
	tempname A At InvA U W V Wmax

	* parse input
	gettoken A0 0 : 0, parse(",")
	mat `A' = `A0' /* may trigger error msg */
	local nrA = rowsof(`A')
	local ncA = colsof(`A')

	syntax [, Display Ginv(str) Rank(str) Tol(str) * ]

	* singular value decomposition requires "long" matrices !?!
	if rowsof(`A') < colsof(`A') {
		mat `At' = `A''
		mat svd `V' `W' `U' = `At'
	}
	else	mat svd `U' `W' `V' = `A'

	* tolerance for inverting the diagonal elements of W
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

	* invert the elements of W
	local i 1
	local rnk 0
	while `i' <= colsof(`W') {
		if `W'[1,`i'] > `tol' {
			mat `W'[1,`i'] = 1/(`W'[1,`i'])
			local rnk = `rnk' + 1
		}
		else	mat `W'[1,`i'] = 0
		local i = `i' + 1
	}

	* produce InvA
	if `rnk' == 0 {
		mat `InvA' = J(`ncA',`nrA',0)
	}
	else	mat `InvA' = `V' * diag(`W') * `U''

	* display results
	if "`ginv'" == "" | "`display'" ~= "" {
		di _n in gr "Moore-Penrose inverse of `A0'" /*
		*/ " [`nrA',`ncA'] with rank = " in ye `rnk'
		mat list `InvA', noheader `options'
	}

	* double save results
	if "`rank'" != "" {
		scalar `rank' = `rnk'
	}
	if "`ginv'" != "" {
		matrix `ginv' = `InvA'
	}

	* return values
	ret scalar rank = `rnk'
	ret matrix ginv `InvA'
end
exit

matginv A, [ ginv(Ai) rank(r) tol(#)]

computes the Moore-Penrose inverse Ai of A, i.e., the unqiue matrix
that satisfies the 4 conditions

 (1)  Ai*A*Ai = Ai
 (2)  A*Ai*A  = A
 (3)  Ai*Ai'  is a projection on the null space of A
 (4)  Ai'*Ai  is a projection on the image of A

if A is invertible, Ai = inverse(A)

if A is n by m, Ai = m by n

In accordance with Matlab, if A is a matrix of zeros, the MP-inverse
is all-zeroes also.
