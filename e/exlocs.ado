program define exlocs
	version 6.0
	syntax [if/] [in], n(integer) [EXLocnum(string) Origline(string) NEXlocs(string) DROPEXs]
	if `n' < 0 {
		display in red "Error: The n() parameter to exlocs must be nonnegative."
		exit 999
	}
	else if `n' > 0 {
		/* Check that the extra lat & lon variables exist. */
		local i = 1
		while `i' <= `n' {
			* Cause an error if missing a variable.
			capture confirm numeric variable exlat`i' exlon`i'
			if _rc ~= 0 {
				if `i' == `n' {
					display in red "Error: The exlocs command requires that variables exlat`i' and exlon`i' exist, but exlat`i' and exlon`i' do not exist or are not numeric variables."
				}
				else {
					display in red "Error: The exlocs command requires that variables exlat`i' and exlon`i' up to exlat`n' and exlon`n' exist, but exlat`i' and exlon`i' do not exist or are not numeric variables."
				}
				exit _rc
			}
			local i = `i' + 1
		}

		/* Check that any new variables to be created do not exist. */
		if "`exlocnu'" == "" {tempvar exlocnu}
		if "`origlin'" == "" {tempvar origlin}
		if "`nexlocs'" == "" {tempvar nexlocs}
		capture confirm new variable `exlocnu' `origlin' `nexlocs'
		if _rc ~= 0 {
			display in red "Error: At least one of the following variables existed before calling exlocs, or the variable name is invalid: (1) `exlocnu', (2) `origlin', (3) `nexlocs'."
			exit _rc
		}

		* Prepare to use if condition.
		if "`if'" ~= "" {
			local andif = "& (`if')"
			local if = "if `if'"
		}

		* Generate variable exlocnum, zero for original data points.
		quietly gen int `exlocnu' = 0

		* Determine number of extra locations for each line of data.
		quietly gen int `nexlocs' = cond(exlat`n' == 999 | exlat`n' == ., `n' - 1, `n') `if' `in'
		quietly replace `nexlocs' = 0 if `nexlocs' == . /* Cases not satisfying the if/in conditions. */
		local i = `n' - 1
		while `i' > 0 {
			quietly replace `nexlocs' = `i' - 1 if (exlat`i' == 999 | exlat`i' == .) `andif' `in'
			local i = `i' - 1
		}

		* Expand the data.
		gen int `origlin' = _n
		quietly expand `nexlocs' + 1 `if' `in'
		sort `origlin'
		quietly by `origlin': replace `exlocnu' = _n - 1
		local i = 1
		while `i' <= `n' {
			* Replace latitudes & longitudes w/ extra location lats & lons, for added lines.
			quietly replace lat = exlat`i' if `exlocnu' == `i'
			quietly replace lon = exlon`i' if `exlocnu' == `i'
			local i = `i' + 1
		}
		
		* If requested, drop the original extra lat & lon variables.
		if "`dropexs'" == "dropexs" {
			local i = 1
			while `i' <= `n' {
				drop exlat`i' exlon`i'
				local i = `i' + 1
			}
		}

	}
end
