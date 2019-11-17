*! Version 1.2.0 CFB/NJC 8 October 1999  (STB-52 ip29)
* ARCHLIST: program to list net-aware modules on SSC-IDEAS archive
* 1.1.1 CFB/NJC 30 April 1999 
* w was missing from a-z 
* 1.1.0 CF Baum modified by NJC 21 April 1999 
* 1.0.0 CF Baum 9421 
program define archlist
	version 6.0
	
	local alpha = "abcdefghijklmnopqrstuvwxyz_"
	local ALPHA = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" 

	tokenize "`0'", parse(" ") 
	if length("`1'") == 1 & "`1'" != "," { 
		if index("`alpha'","`1'") { 
			local letter "`1'" 
			mac shift 
		}
		else if index("`ALPHA'","`1'") {
			local letter = lower("`1'") 
			di in bl "lower case letters preferred"
			mac shift 
		}	
		else error 198 
	}
	
	local 0 "`*'" 	
	syntax [ using/ ] [, REPLACE ] 

	if "`letter'" == "" {
		set more off 
		local logfile : log
		if "`logfile'" != "" {
        		di in bl _n /* 
			*/ "Note: log `logfile' suspended for -archlist-"
		        log close
		}

		if `"`using'"' == `""' { 
			local using "ssc-ideas.lst" 
			local default 1 
		}  
		else local default 0 

		log using `"`using'"', `replace' 
	}	

	dis "Net-aware modules in SSC-IDEAS Archive as of $S_DATE $S_TIME"

	if "`letter'" != "" {
		net from http://fmwww.bc.edu/RePEc/bocode/`letter'
		exit 0 
	}	
		
	local i = 1
	while `i' < 28 {
		local c = substr("`alpha'",`i',1)
		capture net from http://fmwww.bc.edu/RePEc/bocode/`c'
		if _rc==0 { net }
		local i = `i' + 1
	}

	log close

	if `default' { dis "Listing of modules written to ssc-ideas.lst" }

	if "`logfile'" != "" {
        	log using `logfile', append
	        di in bl _n "Note: log `logfile' resumed after -archlist-"
	}

	set more on
end
