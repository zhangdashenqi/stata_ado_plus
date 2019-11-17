*! version 1.4 - 17dec2004: integration of review comments: allow for varying grid sizes
* version 1.3 - 15oct2004: bug fixes for Stata journal
* version 1.2 - 23sep2003: includes NJC suggestions on style
* version 1.1 - 18may2003: adaptation of ras2dta7 to Stata 8
* version 1.0 - 15may2002: 1st try...
*! suggestions & complaints to Daniel (danielix@gmx.net)

prog ras2dta
	version 8.0
	syntax , Files(str) [ IDCell(str) MISSing(int -9999)	///
		DROPmiss EXTension(str) HEADer 				/// 
		Xcoord(int -1) Ycoord(int -1)					///
		GENXcoord(str) GENYcoord(str)					///
		SAVing(str) REPLACE CLEAR ]

	loc nfile : word count `files'   /* returns no of tokens in str */
	loc nsave : word count `saving'

// Check that there are equal numbers:
	if (`nsave' != 0) & (`nfile' != `nsave') {
		di as err "number of files does not match saving()"
		exit 198
	}
// Check for syntax and header
	foreach f of loc files {
		if "`extension'" == "" {
			loc ext = "asc"
		}
		else {
			loc ext = "`extension'"
		}
		qui inf `f' using `f'.`ext' in 1, `clear'
		cap assert missing(`f'[1])
		if _rc == 0 {
			if "`header'" != "" {
				qui {
					inf str12 hdr using `f'.`ext' in 1/12, clear
					save h_`f', replace
				}
			}
		}
		else {
 			di as res "file -`f'- does not have header"
			cap ass (`xcoord' > 0) & (`ycoord' > 0)
			if _rc {
				di as err ///
	"{p}you don't have a header in `f'.`ext': " ///
	"specify number of {it:X} and {it:Y} coordinates " ///
	"in xcoord() & ycoord(){p_end}"
				exit 498 
			}
		}
	}
// loop over files
	clear
	loc i = 1 
	foreach f of loc files {
// 1. case WITH header
		tempvar head
		qui inf `head' using `f'.`ext' in 1, `clear'
		cap assert missing(`head'[1])
		if _rc == 0 {
			qui inf str12 des no using `f'.`ext' in 1/6, clear
			loc ncols = no[1]
			di ""
			di as txt "{hline 30}"
			di as txt "No of " as res "columns" as txt ": {col 20}" ///
				as res %11.0gc `ncols'
			loc nrows = no[2]
			di as txt "No of " as res "rows" as txt ": {col 20}" ///
				as res %11.0gc `nrows'
			loc miss = no[6]
			loc xy = `ncols' * `nrows'
			loc allobs = `xy' + 13
			di as txt "number of " as res "cells" as txt ": {col 20}" ///
				as res %11.0gc `xy'
			// data comes here
			qui inf `f' using `f'.`ext' in 13/`allobs', clear
			qui compress
			cap qui assert `f' < .
			if _rc {
				di as err "mistakes in reading raster data"
				exit 416
			}
			cap qui assert `xy' == _N
			if _rc {
				di as err ///
					"{p}number of observations not equal to ///
					number of raster cells; " ///
					"check the grid-file header{p_end}"
				exit 498 
			}
// generate idcell
			if "`idcell'" != "" {
				gen long `idcell' = _n
				order `idcell' `f'
			}
// generate coordinates (all start at 1) 
			if "`genxcoord'" != "" {
				egen `genxcoord' = seq(), to(`ncols')
			}
			if "`genycoord'" != "" {
				egen `genycoord' = seq(), to(`nrows') b(`ncols')
			}
// MV
			qui if "`dropmiss'" != "" drop if `f' == `miss'
			qui mvdecode `f', mv(`miss')
			qui cou if missing(`f')
// sort & save
			if ("`idcell'" != "" & "`genxcoord'" != "") ///
			 | ("`idcell'" != "" & "`genycoord'" != "") {
				sort `idcell' `genxcoord' `genycoord'
			}
			if "`saving'" == "" {
				save `f', `replace'
			}
			else {
				loc save : word `i' of `saving'
				save `save', `replace'
			}
		}
// 2. case WITHOUT header
		else {
			loc xy = `xcoord' * `ycoord'
			qui inf `f' using `f'.`ext', clear
			di as txt "{hline 10}" as res ///
			// " file name -`f'.`ext'- " as txt "{hline 10}"
			qui compress
			qui count 
			di as txt "No of " as res "cells" as txt ///
				": {col 20}" as res %11.0gc `r(N)'
			cap qui assert `f' < .
			if _rc {
				di as err "Mistakes in reading raster data"
				exit 416
			}
			cap qui assert `xy' == _N
			if _rc {
				di as err ///
	"{p}number of observations not equal to number of raster cells; " ///
	"check header in file and check xcoord() and ycoord() in syntax{p_end}"
				exit 498
			}
// generate var idcell
			if "`idcell'" != "" {
				gen long `idcell' = _n
				order `idcell' `f'
			}
// generate coordinates (all start at 1)
			if "`genxcoord'" != "" {
				egen `genxcoord' = seq(), to(`xcoord')
			}
			if "`genycoord'" != "" {
				egen `genycoord' = seq(), to(`ycoord') b(`xcoord')
			}			
// MV
			if "`missing'" == "" | `missing' == -9999 {
				loc miss -9999
				if "`dropmiss'" != "" drop if `f' == `miss'
				qui mvdecode `f', mv(`miss')
				qui count if missing(`f') 
			}
			else {
				di as txt "Missing values were coded " ///
					as res `missing'
				if "`dropmiss'" != "" drop if `f' == `missing'
				qui mvdecode `f', mv(`missing')
				qui count if missing(`f')
			}
// sort & save			
			if ("`idcell'" != "" & "`genxcoord'" != "") ///
			 | ("`idcell'" != "" & "`genycoord'" != "") {
				sort `idcell' `genxcoord' `genycoord'
			}
			if "`saving'" == "" {
				save `f', `replace'
			}
			else {
				loc save : word `i' of `saving'
				save `save', `replace'
			}
		}
		loc ++i 
	}
end
	
