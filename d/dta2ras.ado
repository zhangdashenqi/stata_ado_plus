*! version 1.3, 17dec2004: integration of varying grid szize
* 23sep2003: including NJC' hints & suggestions
* version 1.2, 01jun2003: update to -version 8-;
* version 1.1, 10oct2002:  -syntax-; requires -tostring- from SSC!
* version 1.0, 11july2002: -args-; diretory path; one file per call only; 
*! suggestions & complaints to Daniel (danielix@gmx.net)

prog dta2ras, sortpreserve
	version 8.0
	syntax [varlist(default=none num)] , [ HEADer(str) ]	///
	[ Xcoord(numlist int) Ycoord(numlist int) 			///
	CELLsize(real 1) XLLcorner(real 1) YLLcorner(real 1)	///
	MISSing(int -9999) IDCell(str) IDFile(str) EXPand		///
	SAVing(str) NORESTore REPLACE ]

	tempvar idfin tstr
	tempfile spathead rest
		
// check syntax
	loc nvars : word count `varlist'
	loc nsave : word count `saving'

	if (`nsave' != 0) & (`nvars' != `nsave') {
		di "{error}number of variables does not match saving()"
		exit 198		
	}
	if "`header'" == "" {
		cap qui assert `xcoord' < . & `ycoord' < . & `cellsize' < .
		if _rc {
			di "{p}{error}no header information; specify a " ///
			"header file or the number of {it:X} and {it:Y} " ///
			"coordinates{p_end}"
			exit 198
		}
	}
	else {
		cap conf fi `header'.dta
		if _rc {
			di "{error}header() requires {it:`header'.dta}"
			exit 198
		}
		loc h_file = "`header'"
	}
	if "`expand'" != "" {
		if ("`idcell'" == "" & "`idfile'" == "") ///
		 | ("`idcell'" != "" & "`idfile'" != "") {
				di "{p}{error}expand requires either " ///
				"{it:idcell()} or {it:idfile()}{p_end}"
				exit 198
		}
	}
	if "`norestore'" == "" {
		qui save `"`rest'"'
	}

// create header
	if "`header'" == "" {
		qui cou
		loc nobs = `xcoord' * `ycoord' 
		if `nobs' != `r(N)' {
			di "{error}observations in grid:" as res %11.0gc `nobs'	///
				"{error} -- observations in *.dta:" as res %8.0gc r(N)
			di "{p}{error}number of observations not equal to "		///
				"number of rows ({it:Y}) times number of "			///
				"columns ({it:X}); check numbers of rows and "		///
				"columns or specify {it:expand()}{p_end}"	
			exit 198
		}
		qui {
			preserve
			tempvar hdr
			clear
			set obs 12
			gen hdr     = "ncols"        in 1
			replace hdr = "`xcoord'"     in 2
			replace hdr = "nrows"        in 3
			replace hdr = "`ycoord'"     in 4
			replace hdr = "xllcorner"    in 5
			replace hdr = "`xllcorner'"  in 6
			replace hdr = "yllcorner"    in 7
			replace hdr = "`yllcorner'"  in 8
			replace hdr = "cellsize"     in 9
			replace hdr = "`cellsize'"   in 10
			replace hdr = "NODATA_value" in 11
			replace hdr = "-9999"        in 12
			save `"`spathead'"' 
			restore
		}
	}

// merge data with header
	loc i = 1 
	foreach var of loc varlist {

// expand to total number of cells
		if "`expand'" != "" {
			if "`idfile'" != "" {
				loc idcell = "`idcell'"
				joinby `idcell' using `idfile', unm(u)
				drop _merge
			}
			else {
				preserve
				clear
				if "`header'" != "" {
			  		qui use "`h_file'"
					loc xcoord = hdr[2]
					loc ycoord = hdr[4]
			  	}
				tempfile jbfile
				loc cellno = `xcoord' * `ycoord'
				qui {
					set obs `cellno'
					gen `idcell' = _n
					save "`jbfile'"
				}
				restore
				joinby `idcell' using "`jbfile'", unm(u)
				drop _merge
			}
			qui replace `var' = `missing' if `var' == .
		}
		preserve 
		qui tostring `var', gen("`tstr'") u force

		loc where = cond(`"`h_file'"' == "", `"`spathead'"', `"`h_file'"') 
		append using `"`where'"'
		
		gen long `idfin' = cond((_N - _n) < 12, _n - _N, _n)		
		sort `idfin'
		qui {
			replace `tstr' = hdr if `idfin' <= 0
			drop hdr
			replace `tstr' = "`missing'" if `tstr' == ""
		}

// export
		if "`saving'" == "" {
			outfile `tstr' using "`var'_o.asc", runtogether `replace'
			di "{text}`var' saved as " as res "-`var'_o.asc-" 
		}
		else {
			loc save : word `i++' of `saving'
			outfile `tstr' using "`save'.asc", runtogether `replace'
			di "{text}`var' saved as " as res "-`var'.asc-" 
		}
		restore
	}
	if "`norestore'" == "" {
		use `"`rest'"', clear
	}
end
