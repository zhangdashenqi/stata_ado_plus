*! version 1.2.1  11nov2003                     (SJ3-4: st0049, st0050, st0051)
program define simexploti
	version 8.0

	if "`e(cmd)'" != "simex" {
		error 301
	}

	syntax name [, * ]

	_get_gropts , graphopts(`options')		///
		getallowed(textboxopts legend)		///
		// blank
	local options `"`s(graphopts)'"'
	if `"`s(textboxopts)'"' == "" {
		local textboxopts place(ne)
	}
	else	local textboxopts `"`s(textboxopts)'"'
	if `"`s(legend)'"' == "" {
		local legend legend(off)
	}
	else	local legend legend(`s(legend)')

	local vars `namelist'

	quietly {
		preserve
		drop _all

		mat k=e(theta)
		local more `c(more)'
		set more off
		svmat k, names(eqcol)
		set more `more'

		noi confirm var _`vars'

		sort _theta

		summarize _theta
		local lmax = r(max)

		tempvar v1 v2
		gen `v1' = _`vars'
		gen `v2' = _`vars'
		replace `v1' = . in 1/1
		replace `v2' = . in 2/l
		label var `v1' "Naive Estimate"
		label var `v2' "Simex Estimate"


		local p0: display %9.0g _`vars'[2] 
				/* theta = 0  (native estimate) */
		local p1: display %9.0g _`vars'[1] 
				/* theta = -1 (SIMEX estimate) */
		local p0 = trim("`p0'")
		local p1 = trim("`p1'")

		if ("`e(method)'" == "Quadratic") {
			twoway (qfit `v1' _theta, range(-1 `lmax')) /*
			*/ (scatter `v1' _theta) /*
			*/ (scatter `v2' _theta, msymbol(x) /*
				*/ mcolor(maroon) msize(vlarge)), /*
			*/ title("Simulation Extrapolation: `vars'") /*
			*/ sub("Extrapolant: `e(method)'  Type: `e(type)'") /*
			*/ ytitle("Coefficient") /*
			*/ xtitle("Lambda")  /*
			*/ text(`p0'  0 "Naive Estimate", `textboxopts') /*
			*/ text(`p1' -1 "SIMEX Estimate", `textboxopts') /*
			*/ `legend' /*
			*/ note("Naive: `p0'    SIMEX: `p1'") /*
			*/ `options'

		}
		else if "`e(method)'" == "Rational" {
			twoway (scatter `v1' _theta) /*
			*/ (scatter `v2' _theta, msymbol(x) /*
				*/mcolor(maroon) msize(vlarge)), /*
			*/ title("Simulation Extrapolation: `vars'") /*
			*/ sub("Extrapolant: `e(method)'  Type: `e(type)'") /*
			*/ ytitle("Coefficient") /*
			*/ xtitle("Lambda")  /*
			*/ text(`p0'  0 "Naive Estimate", `textboxopts') /*
			*/ text(`p1' -1 "SIMEX Estimate", `textboxopts') /*
			*/ `legend' /*
			*/ note("Naive: `p0'    SIMEX: `p1'") /*
			*/ `options'
		}
		else {
			twoway (lfit `v1' _theta, range(-1 `lmax')) /*
			*/ (scatter `v1' _theta) /*
			*/ (scatter `v2' _theta, msymbol(x) /*
				*/ mcolor(maroon) msize(vlarge)), /*
			*/ title("Simulation Extrapolation: `vars'") /*
			*/ sub("Extrapolant: `e(method)'  Type: `e(type)'") /*
			*/ ytitle("Coefficient") /*
			*/ xtitle("Lambda")  /*
			*/ text(`p0'  0 "Naive Estimate", `textboxopts') /*
			*/ text(`p1' -1 "SIMEX Estimate", `textboxopts') /*
			*/ `legend' /*
			*/ note("Naive: `p0'    SIMEX: `p1'") /*
			*/ `options'

		}
		restore
	}
end
