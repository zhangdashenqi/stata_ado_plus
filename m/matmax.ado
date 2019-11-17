*! 1.1.3  24mar2000  Jeroen Weesie/ICS
program define matmax, rclass
	version 6.0

	* scratch
	tempname A

	* parse input
	gettoken A0 0: 0, parse(" ,")
	mat `A' = `A0' /* may trigger error msg */
	local nr = rowsof(`A')
	local nc = colsof(`A')

	syntax [, All(str) Column(str) Display Format(passthru) Row(str)]

	* defaults
	if "`row'"=="" & "`column'"=="" & "`all'"=="" {
		local column "."
	}

	if "`row'"=="." {
		tempname Row
		local row "`Row'"
		local display "display"
	}

	if "`column'"=="." {
		tempname Col
		local column "`Col'"
		local display "display"
	}

	if "`all'"=="." {
		tempname All
		local all "`All'"
		local display "display"
	}

	* compute maxima
	if "`row'" != "" {                  /* row maxima as a column vector */
		mat `row' = `A'[1...,1]
		local j 2
		while `j' <= `nc' {
			local i = 1
			while `i' <= `nr' {
				mat `row'[`i',1] = max(`row'[`i',1],`A'[`i',`j'])
				local i = `i' + 1
			}
			local j = `j' + 1
		}
		if "`display'" != "" {
			di in gr _n "row-wise maxima of matrix `A0' [`nr',`nc']"
			mat list `row', noheader `format'
		}
	}

	if "`column'" != "" {               /* column maxima as a row vector */
		mat `column' = `A'[1,1...]
		local i 2
		while `i' <= `nr' {
			local j 1
			while `j' <= `nc' {
				mat `column'[1,`j'] = max(`column'[1,`j'],`A'[`i',`j'])
				local j = `j' + 1
			}
			local i = `i' + 1
		}
		if "`display'" != "" {
			di in gr _n "column-wise maxima of matrix `A0' [`nr',`nc']"
			mat list `column', noheader `format'
		}
	}

	if "`all'" != "" {                  /* maximum over all elements */
		mat `all' = `A'[1,1]
		local i 1
		while `i' <= `nr' {
			local j = 1
			while `j' <= `nc' {
				mat `all'[1,1] = max(`all'[1,1],`A'[`i',`j'])
				local j = `j' + 1
			}
			local i = `i' + 1
		}
		if "`display'" != "" {
			if "`format'" == "" {
				local format %10.2g
			}
			di _n in gr "maximum of elements of `A0' [`nr',`nc'] = " /*
				*/ in ye `format' `all'[1,1]
		}
	}

	if "`row'" != ""    {
		tempname R
		mat `R' = `row'
		return matrix row_max `R'
	}

	if "`column'" != "" {
		tempname C
		mat `C' = `column'
		return matrix col_max `C'
	}

	if "`all'" != "" {
		return scalar all_max = `all'[1,1]
		scalar `all' = return(all_max)
	}
end

