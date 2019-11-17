*! 1.1.3  24mar2000  Jeroen Weesie/ICS
program define matsum, rclass
	version 6.0

	* scratch
	tempname A OneC OneR

	* parse input
	gettoken A0 0: 0, parse(",")
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

	mat `OneC' = J(`nc',1,1)
	mat `OneR' = J(1,`nr',1)

	if "`row'" != "" {             /* compute row sums as a column vector */
 		mat `row' = `A' * `OneC'
		if "`display'" != "" {
			di in gr _n "row-wise sums of matrix `A0' [`nr',`nc']"
			mat list `row', noheader `format'
		}
	}

	if "`column'" != "" {         /* compute column sums as a row vector */
		mat `column' = `OneR' * `A'
		if "`display'" != "" {
			di in gr _n "column-wise sums of matrix `A0' [`nr',`nc']"
			mat list `column', noheader `format'
		}
	}

	if "`all'" != "" {            /* sum over all elements */
		if "`row'" != "" {
			mat `all' = `OneR' * `row'
		}
		else if "`column'" != "" {
			mat = `all' * `OneC'
		}
		else mat `all' = `OneR' * `A' * `OneC'

		if "`display'" != "" {
			if "`format'" == "" {
				local format %10.2g
			}
			di _n in gr "sum of elements of `A0' [`nr',`nc'] = " /*
				*/ in ye `format' `all'[1,1]
		}
	}

	if "`row'" != ""    {
		tempname R
		mat `R' = `row'
		return matrix row_sum `R'
	}

	if "`column'" != "" {
		tempname C
		mat `C' = `column'
		return matrix col_sum `C'
	}

	if "`all'" != "" {
		return scalar all_sum = `all'[1,1]
		scalar `all' = return(all_sum)
	}
end
