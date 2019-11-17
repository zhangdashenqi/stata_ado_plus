*! NJC 1.4.0 17 November 2009       (SJ9-4: sg113_2) 
* NJC 1.3.0 13 May 2003            (SJ3-2: sg113_1)
* NJC 1.2.0 15 June 1999 
* NJC 1.1.2 23 December 1998
* NJC 1.1.1 29 October 1998
program modes, sort 
        version 8.0
        syntax varname [if] [in] [fweight aweight/] ///
	[ , Min(int 0) Nmodes(int 0) GENerate(str) ]

	if "`generate'" != "" { 
		capture confirm new variable `generate' 
		if _rc { 
			di as err "generate() requires new variable name"
			exit _rc 
		}
	} 

	if `min' & `nmodes' { 
		di as err "may not specify both min() and nmodes()"
		exit 198
	}
	
	quietly { 
		marksample touse, strok
		count if `touse' 
		if r(N) == 0 error 2000 
		
		tempvar freq 
		if "`exp'" == "" local exp = 1 
		bysort `touse' `varlist' : ///
			gen double `freq' = sum(`exp') * `touse'
		by `touse' `varlist' : ///
			replace `freq' = (_n == _N) * `freq'[_N] 
		label var `freq' "Freq."

		if `min' > 0 { 
			local which "`freq' >= `min'" 
		}	
		else if `nmodes' > 0 { 
			sort `touse' `freq' `varlist' 
			count if `freq' 
			local nmodes = min(`nmodes', r(N)) 
			local which "`freq' >= `freq'[_N - `nmodes' + 1]"
		} 	
		else {
			su `freq', meanonly
			local max = r(max)
			local which "`freq' == `max'" 
		}	
		
		count if `which'
		if r(N) == 0 {
			di as err "no such modes in data"
			exit 498
		}
	}

	tabdisp `varlist' if `which', c(`freq')

	quietly if "`generate'" != "" { 
		gen byte `generate' = `which' if `touse' 
		bysort `touse' `varlist' (`generate') : ///
		replace `generate' = `generate'[_N]  
	} 		
	
end

