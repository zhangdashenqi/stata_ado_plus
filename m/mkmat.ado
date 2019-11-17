*! mkmat--create vectors from variables
*! version 1.0.0     Ken Heinecke     STB-20: ip6
*	MKMAT.ado	Program to take a Data series and
*			create a vector from it.
*		Written by Ken Heinecke
*			5/26/94
*			6/10/94  Added option for if and in statements
*			6/16/94  Addressed missing value problem
*			7/1/94   Changes by arr:  Made code robust to
*				 possible errors.  Added generate option
*				 to create matrix from vectors.
program def mkmat
	version 3.1
	local varlist "req ex"
	local in "opt"
	local if "opt"
	local options "MATrix(string)"
	parse "`*'"

	local dogen 0
	if "`matrix'"!="" {
		local matname = "`matrix'"
		local dogen 1
	}
	tempvar touse
	mark `touse' `if' `in'
	preserve
	qui keep if `touse'
	if _N==0 {
		di "no observations"
		error 2000
	}
	parse "`varlist'", parse(" ")
	local i 1
	while "``i''"!="" {
		qui count if ``i'' == .
		if _result(1)>0 {
			di in red "matrix ``i'' would have missing values"
			exit 504
		}
		local i = `i' + 1
	}
	local nvar = `i' - 1
	local nobs = _N
	if `dogen' {
		matrix `matname'=J(`nobs',`nvar',0) /* check matsize before  */
		mat drop `matname'		    /* we create any vectors */
	}
	while "`1'"!="" {
		mat `1'=J(`nobs',1,0)
		local i 1
		while (`i' <= `nobs') {
			mat `1'[`i',1] = `1'[`i']
			mat colnames `1' = `1'
			local i = `i' + 1
		}
		if `dogen' {
			matrix `matname'=`matname',`1'
		}
		mac shift
	}
	restore
end
