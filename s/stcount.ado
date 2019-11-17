*! 1.2.0  22mar1999  jw/ics
program define stcount, rclass
   version 6.0
   st_is 2 full
   
	syntax if [, noSHow by(str) markout(varlist) * ]

	if "`by'" ~= "" {
		di in re "stcount does not permit by(). It uses the subject-identifier."
		exit 198
	}
	
   if "`_dta[st_id]'" == "" { 
		di in re "stcount requires that id() was set"
		exit 198
	}		
   st_show `show'

	* take care of sample selection via _st! via -markout-

	capt assert _st==1
	if _rc {
		tempvar st
		qui gen byte `st' = 1 if _st
		local markout "markout(`markout' `st')"
	}

   countby `if' , by(`_dta[st_id]') namerec(episode) nameby(subject) `markout'
	return add	
end

