*! version 1.0.1  12dec2013
* updated command so that it always retains a cells format when writing data
program tab2xl
	version 13.1
	syntax varname using/, row(integer) col(integer) [replace sheet(string)]

	if "`replace'" == "" {
			local replace = "modify"
	}

	qui tabulate `varlist', matcell(freq) matrow(names)
	local total = r(N)

	local var_lab : variable label `varlist'

	if "`var_lab'" != "" {
		local col1_header = "`var_lab'"
	}
	else {
		local col1_header = "`varname'"
	}

	local col1 = `col'
	local col2 = `col' + 1
	local col3 = `col' + 2
	local col4 = `col' + 3
	num2base26 `col'
	local col1_letter "`r(col_letter)'"
	num2base26 `col2'
	local col2_letter "`r(col_letter)'"
	num2base26 `col3'
	local col3_letter "`r(col_letter)'"
	num2base26 `col4'
	local col4_letter "`r(col_letter)'"

	putexcel set `"`using'"', sheet("`sheet'") `replace' keepcellformat
	
	qui putexcel	`col1_letter'`row'=("`col1_header'")		///
			`col2_letter'`row'=("Freq.")			///
			`col3_letter'`row'=("Percent")			///
			`col4_letter'`row'=("Cum.")


	local rows = rowsof(names)
	local row = `row' + 1
	local cum_percent = 0

	forvalues i = 1/`rows' {

		local val = names[`i',1]
		local val_lab : label (`varlist') `val'

		local freq_val = freq[`i',1]

		local percent_val = `freq_val'/`total'*100
		local percent_val : display %9.2f `percent_val'
		
		local cum_percent : display %9.2f (`cum_percent' + `percent_val')

		qui putexcel `col1_letter'`row'=("`val_lab'")		///
				`col2_letter'`row'=(`freq_val')		///
				`col3_letter'`row'=(`percent_val')	///
				`col4_letter'`row'=(`cum_percent')
		sleep 10
		local row = `row' + 1
	}

	sleep 10

	qui putexcel `col1_letter'`row'=("Total")		///
			`col2_letter'`row'=(`total') 		///
			`col3_letter'`row'=(100.00)
end

program num2base26, rclass
	args num

	mata: my_col = strtoreal(st_local("num"))
	mata: col = numtobase26(my_col)
	mata: st_local("col_let", col)
	return local col_letter = "`col_let'"
end

