program sort_vector, rclass

version 11
	syntax name(id="matrix" )

	capture local r = rowsof(`namelist')
	if "`r'" != "1" {
		di "The matrix `namelist' must have a single row"
		exit
	}

	tempname r s idx
	matrix `s' = `namelist'
	local names : colnames `namelist'
	local len   : word count `names'

	matrix `r' = `namelist''
	matrix `idx' = (1)
	
	matrix list `r'
	matrix list `idx'
	
	mata: vector_order("`r'", "`idx'")

	matrix `r' = r(sorted)'
  //	matrix list `r'

	local snames
	foreach i of numlist 1/`len' {
		local j = el(`r', 1, `i')
		local tname : word `j' of `names'
		local snames `tname' `snames' 
		matrix `s'[1, `len' - `i' + 1] = el(`namelist', 1, `j')
	}
	matrix colnames `s' = `snames'
	return matrix sorted = `s'

end

