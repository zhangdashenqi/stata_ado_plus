*! 1.1.3  24mar2000  Jeroen Weesie/ICS
program define matmin, rclass
	version 6.0

	* scratch
	tempname A

	* parse input
	gettoken A0 0: 0, parse(",")
	mat `A' = `A0'  /* may trigger error msg */
	local nr = rowsof(`A')
	local nc = colsof(`A')

	syntax [, All(str) Column(str) Display Format(passthru) Row(str)]

	* defaults
	if "`row'"=="" & "`column'"=="" & "`all'"=="" {
		local column "."
	}

	if "`row'" == "." {
		tempname Row
		local row "`Row'"
		local display "display"
	}

	if "`column'" == "." {
		tempname Col
		local column "`Col'"
		local display "display"
	}

	if "`all'" == "." {
		tempname All
		local all "`All'"
		local display "display"
	}

	* compute minima
	if "`row'" != "" {                  /* row minima as a column vector */
		mat `row' = `A'[1...,1]
		local j 2
		while `j' <= `nc' {
			local i 1
			while `i' <= `nr' {
				mat `row'[`i',1] = min(`row'[`i',1],`A'[`i',`j'])
				local i = `i' + 1
			}
			local j = `j' + 1
		}
		if "`display'" != "" {
			di in gr _n "row-wise minima of matrix `A0' [`nr',`nc']"
			mat list `row', noheader `format'
		}
	}

	if "`column'" != "" {               /* column minima as a row vector */
		mat `column' = `A'[1,1...]
		local i 2
		while `i' <= `nr' {
			local j 1
			while `j' <= `nc' {
				mat `column'[1,`j'] = min(`column'[1,`j'],`A'[`i',`j'])
				local j = `j' + 1
			}
			local i = `i' + 1
		}
		if "`display'" != "" {
			di in gr _n "column-wise minima of matrix `A0' [`nr',`nc']"
			mat list `column', noheader `format'
		}
	}

	if "`all'" != "" {                  /* minimum over all elements */
		mat `all' = `A'[1,1]
		local i 1
		while `i' <= `nr' {
			local j 1
			while `j' <= `nc' {
				mat `all'[1,1] = min(`all'[1,1],`A'[`i',`j'])
				local j = `j' + 1
			}
			local i = `i' + 1
		}
		if "`display'" != "" {
			if "`format'" == "" {
				local format %10.2g
			}
			di _n in gr "minimum of elements of `A0' [`nr',`nc'] = " /*
				*/ in ye `format' `all'[1,1]
		}
	}

   if "`row'" != ""    {
		tempname R
		mat `R' = `row'
		return matrix row_min `R'
	}

	if "`column'" != "" {
		tempname C
		mat `C' = `column'
		return matrix col_min `C'
	}

	if "`all'" != "" {
		return scalar all_min = `all'[1,1]
		scalar `all' = return(all_min)
	}
end
