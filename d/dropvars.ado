*! 1.0.1  14mar2000  jw/ics
program define dropvars
	version 6

	while "`1'" != "" {
		capture drop `1'
		if _rc { 
			local nodropv "`nodropv' `1'"
		}       
		mac shift
	}
	if "`nodropv'" != "" {
		di in gr "Unable to drop" in ye "`nodropv'"
	}                
end
