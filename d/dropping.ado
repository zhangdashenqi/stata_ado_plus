prog def dropping, rclass
 	version 9.0
	syntax [varlist] [if] [in]
	tempvar dropping

	* Mark sample	
	marksample touse, novarlist

	* Variables
	tokenize `varlist'
	local xnum : word count `varlist'

	local i 1
	qui gen `dropping'=0
	while `i'<=`xnum' {
		qui replace `dropping'=1 if ``i''==. & `touse'==1
		local i=`i'+1
	}	
	drop if `dropping'==1
end

