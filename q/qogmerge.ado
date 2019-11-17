*! version 2.0.0
*! Christoph Thewes - thewes@uni-potsdam.de - 09.11.2012

* 1.0.0: 10.05.2011: Initial release 
* 1.1.0: 16.11.2011: added "from()"-option, varname-bugfix (year)
* 2.0.0: 09.11.2012: added suport for different versions and formats of QOG

program qogmerge
	version 11.0
	syntax anything , Version(string) Format(string) [keep(string) from(string) * ]


	global q__source "http://www.qogdata.pol.gu.se/data"

	local temp1: word 1 of `anything'		//countryvar
	local temp2: word 2 of `anything'		//timevar


	
	// check format
	// ------------

	if "`format'" == "ind" {
		di as err "-Individual Expert Survey- can`t be merged." _newline ///
		"It contains personal infortmation: Web survey by country experts." _newline ///
		"Variables do not uniquely identify observations in the using data."
		exit 459
	}

	if inlist("`format'","cs","ctry") local base c
	if inlist("`format'","ts","tsl") local base cy
	
	if "`base'"=="cy" & "`temp2'" == "" {
		di as err "no TIME-variable spcified"
		exit 
	}

	if "`base'"=="c" & "`temp2'" != "" {
		di as err _col(5) "Note: Format" as inp " cs " as err "and" as inp " ctry " as err "can not be merged with TIME variable."
		di as err _col(5) "-" as inp "`temp2'" as err "- will be ignored"
	}
	

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
			di as err "You have to specify" as inp " format(ctry) " as err " for EXPERT SURVEY dataset."
			exit
		}
	}
	


	// check if time or country is invariable
	// --------------------------------------
	capture confirm variable `temp1'
	if _rc {						// >>> temp1 is not a variable
		tempvar countryvar
		capture confirm integer number `temp1'
		if !_rc {					// temp1 is integer
			gen `countryvar' = `temp1'
			local cformat num
		}
		if _rc {					// temp1 is string
			gen `countryvar' = "`temp1'"
			local cformat name
		}
	}
	
	else {							// >>> temp1 is a variable
		capture confirm string variable `temp1'
		if !_rc {					// temp1 is string
			local countryvar "`temp1'"
			local cformat name
		}
		if _rc {					// temp1 is integer
			local countryvar `temp1'
			local cformat num
		}
		capture assert !mi(`countryvar')
		if _rc== 9 {
			di as smcl as res _col(5) "Note: COUNTRY variable contains missings"
		}

	}
		
	
	if "`base'" == "cy" {
		capture confirm variable `temp2'
		if _rc {						// >>> temp2 is not a variable
			tempvar timevar
			gen `timevar' = `temp2'
		}
		
		else {							// >>> temp2 is a variable
			local timevar `temp2'
			confirm numeric variable `timevar'
		
			capture assert !mi(`timevar')
			if _rc== 9 {
				di as smcl as res _col(5) "Note: TIME variable contains missings"
			}
		}
	
	// general checks
	// --------------

		capture assert mod(`timevar',1)==0 | mi(`timevar')
		if _rc!= 0 {
			di as error "TIME variable contains noninteger values"
			exit 9
		}
		
		
		capture assert inrange(`timevar',1000,9999) | mi(`timevar')	
		if _rc!= 0 {
			di as error "TIME variable should be 4 digit"
			exit 9
		}
	}
	
	
	
	if "`keep'" == "" local keep "keep(1 3)"
	else local keep "keep(`keep')"



	if "`from'" == "" local from "$q__source/qog_`version'_`format'.dta"
	else local from "`from'"




	// generate
	
	if "`cformat'" == "name" {
		capture gen cname = `countryvar' 
		if _rc == 110 {
			display as error "cname already defined"
			exit 110
		}
		local var1 cname
	}
	
	
	if "`cformat'" == "num" {
		capture gen ccode = `countryvar' 
		if _rc == 110 {
			display as error "ccode already defined"
			exit 110
		}
		local var1 ccode
	}


	if "`base'" == "cy" {
		if "`timevar'" != "year" {
			capture confirm var year
			if _rc != 111 {					// = var "year" is in original data
				ren year qogtempyear
				gen int year = `timevar'
				local markyear "yes"
			}
			else {
				gen int year = `timevar'
				local markyear "no"
			}
		}	
		local var2 year
	}



	//  merge
	// =======

	if "`base'" == "cy" merge m:1 `var1' `var2' using `from', `keep' `options'
	if "`base'" == "c" merge m:1 `var1' using `from', `keep' `options'


	// undo country and year identifier renaming
	// -----------------------------------------

	if "`timevar'" != "year" & "`base'" == "cy" {
		if "`markyear'" == "yes" {
			drop `var1' `var2'
			ren qogtempyear year
		}
		else {
			drop `var1' `var2'
		}
	}
	
	else {
		drop `var1' 
	}

	

end
exit
