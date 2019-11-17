*! version 2.0.1
*! Christoph Thewes - thewes@uni-potsdam.de - 26.11.2012

* 1.0.0: 10.05.2011: Initial release 
* 2.0.0: 09.11.2012: added suport for different versions and formats of QoG
* 2.0.1: 26.11.2012: fix for syntax bugs: varlist & if/in



program qoguse

version 11.0
	
	// SOLVE IF/IN BUG
	// ---------------

	// get if/in-position
	local ifpos = strpos(`"`0'"'," if ")
	local inpos = strpos(`"`0'"'," in ")
	
	// check if "in" is specified before "if"
	if `ifpos' > `inpos' & `inpos' > 0 {
		local ifpos = `inpos'		
	}

	if `ifpos' > 0 {
		// get range to cut out = lenght cmd - rev(comma-position) - if-position
		// reverse() because of a possible comma in if-exp
		local range = length(`"`0'"') - strpos(reverse(`"`0'"'),",") - `ifpos'	
		
		// create if/in to paste into use-command
		local ifin = substr(`"`0'"',`ifpos',`range'+1)				
		
		// replace original if/in with blank
		local 0 = subinstr(`"`0'"',`"`ifin'"',"",1)					
	}
	
	// SYNTAX
	// ------

	syntax [anything], Version(string) Format(string) [Years(numlist) clear]

	global q__source "http://www.qogdata.pol.gu.se/data"


	// CHECK FOR WRONG SPECIFIED OPTIONS
	// ---------------------------------
	
	if "`version'"=="bas" | "`version'"=="std" {
		if "`format'"!="cs" & "`format'"!="ts" {
			di as err "You have to specify" as inp " format(cs) " as err "or" as inp " format(ts)" as err " for BASIC or STANDARD dataset."
			exit
		}
	}

	if "`version'"=="soc" {
		if "`format'"!="cs" & "`format'"!="tsl" & "`format'"!="tsw" {
			di as err "You have to specify" as inp " format(cs)" as err "," as inp " format(tsl)" as err " or" as inp " format(tsw)" as err " for SOCIAL POLICY dataset."
			exit
		}
	}

	if "`version'"=="exp" {
		if "`format'"!="ctry" & "`format'"!="ind" {
			di as err "You have to specify" as inp " format(ctry) " as err "or" as inp " format(ind)" as err " for EXPERT SURVEY dataset."
			exit
		}
	}


	if "`format'"=="cs" | "`format'"=="tsw" | "`format'"=="ctry" {
		if "`years'" != "" {
			di as err "Option years() is not allowed and will be ignored."
			local years ""
		}
	}



	// LOAD DATA
	// ---------

	if "`format'"=="tsw" & "`clear'"=="clear" {		// TSL-dataset contains 5000+ variables 
		clear
		set maxvar 7000
	}
	
	use `anything' `ifin' using $q__source/qog_`version'_`format'.dta, `clear'


	
	// KEEP ONLY SPECIFIED YEARS
	// -------------------------
	if "`years'"!="" {	
		tempvar touse
		local i 1
		foreach num of numlist `years'  {
			if `i'== 1 local exp year == `num'
			else local exp `exp' | year == `num'
			local i = `i' + 1
		}
		gen byte `touse' = `exp'
		keep if `touse'
	}
	
	
end
exit

