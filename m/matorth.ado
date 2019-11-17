*! 1.1.1  24mar2000  Jeroen Weesie/ICS
* code was modelled after -orth- in Matlab 4.0
program define matorth, rclass
	version 6.0

	* scratch
	tempname A At OrthA U Ui V W Wmax

	* parse input
	gettoken A0 0: 0, parse(",")
	mat `A' = `A0' /* may trigger error msg */
	local nrA = rowsof(`A')
	local ncA = colsof(`A')

	syntax [, Display Format(passthru) Orth(str) Rank(str) Tol(str) ]

	* Stata's singular value decomposition requires "long" matrices !?!
	if rowsof(`A') < colsof(`A') {
		mat `At' = `A''
		mat svd `V' `W' `U' = `At'
	}
	else    mat svd `U' `W' `V' = `A'

	* tolerance for deciding which elements of W are 0
	if "`tol'" == "" {
		* max of singular values
		local nc = colsof(`W')
		scalar `Wmax' = 0
		local i 1
		while `i' <= `nc' {
			if (`W'[1,`i'] > `Wmax') { scalar `Wmax' = `W'[1,`i'] }
			local i = `i' + 1
		}
		tempname tol
		scalar `tol' = `Wmax' * `nc' * (2.22E-16)
	}
	else confirm number `tol'

	* select columns of U with singular value W(i) > tol
	* note that Stata's SVD returns unsorted singular values
	local i 1
	local r 0
	while `i' <= `nc' {
		if `W'[1,`i'] > `tol' {
			local r = `r' + 1
			mat `Ui' = `U'[1...,`i']
			mat `OrthA' = nullmat(`OrthA') , `Ui'
		}
		local i = `i' + 1
	}

	* display
	if "`display'" != "" | "`orth'" == "" {
		di _n in gr "Column space (Image) of `A0' [`nrA',`ncA'] " _c
		if `r' == 0 {
			di in gr " = " in ye " { 0 } "
		}
		else {
			di in gr " has dimension " in ye `r' in gr " and ortho-basis"
         mat list `OrthA', noheader `format'
		}
	}

	* double save of return values
	return scalar rank = `r'
	return matrix singval `W'
   if "`rank'" != "" {
      scalar `rank' = `r'
   }
	if `r' > 0 {
		return matrix orth `OrthA'
		if "`orth'" != "" {
   		matrix `orth' = return(orth)
      }
	}
	else di in bl "`orth' is -empty- hence left undefined"
end


