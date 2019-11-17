*! 1.2.0 revised for Stata Journal Submission
program geocode
	version 8.2
	syntax, [address(string) city(string) state(string) zip(string) fulladdr(string)]
		
	quietly {
		tempfile temp_all_files txtfile 
		tempvar blank work mergetest  
		g `blank' = ""
		
		if "`address'" == "" local address `blank'
		if "`city'" == ""    local city    `blank'
		if "`state'" == ""   local state   `blank'
		if "`zip'" == ""     local zip     `blank'
			
		if "`fulladdr'" == "" {	
			g `work' = `address' + ", " + `city' + ", " + `state' + " " + `zip'
		}
		else g `work' = `fulladdr'
		drop `blank' 			
		
  	g long geoid = _n		

		replace `work' = " " + `work'
		replace `work' = upper(`work')
		replace `work' = subinstr(`work',"&","%26",.)
		replace `work' = subinstr(`work',"#","",.)
		replace `work' = subinstr(`work'," 01ST"," 1ST",.)
		replace `work' = subinstr(`work'," 02ND"," 2ND",.)
		replace `work' = subinstr(`work'," 03RD"," 3RD",.)
		replace `work' = subinstr(`work'," 04TH"," 4TH",.)
		replace `work' = subinstr(`work'," 05TH"," 5TH",.)
		replace `work' = subinstr(`work'," 06TH"," 6TH",.)
		replace `work' = subinstr(`work'," 07TH"," 7TH",.)
		replace `work' = subinstr(`work'," 08TH"," 8TH",.)
		replace `work' = subinstr(`work'," 09TH"," 9TH",.)
		replace `work' = trim(`work')
		replace `work' = subinstr(`work'," ","+",.)
		replace `work' = subinstr(`work',`"""'," ",.)
  	replace `work' = itrim(trim(`work'))
		replace `work' = subinstr(`work'," ","+",.)


		local cnt = _N 
		forval i = 1/`cnt' { 
			tempfile dtafile`i'
			preserve
			local addr = `work'[`i'] 
			noisily di as text "Geocoding `i' of `cnt'" 
			capture: copy "http://maps.google.com/maps/geo?q=`addr'&output=csv" "`txtfile'", replace
			while _rc == 2 {
				noi: di "Connection error, retrying observation #"`i'
				local ++connection_error
				capture: copy "http://maps.google.com/maps/geo?q=`addr'&output=csv" "tempfile123456`i'.txt", replace
			}
			insheet geocode geoscore latitude longitude using `txtfile', clear comma
			g long geoid = `i'
			sort geoid
			save `dtafile`i'', replace
			restore
		}

		preserve 

		use `dtafile1', clear
		forval i = 2/`cnt' {
			append using `dtafile`i''
		}
		
		sort geoid
		save `temp_all_files', replace
		restore
		sort geoid
		merge geoid using `temp_all_files', _merge(`mergetest')		
		drop geoid `mergetest' 
	}
end
		

