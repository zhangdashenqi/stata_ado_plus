*! version 6.0.0  	23dec1988	(www.stata.com/users/becketti/tslib)
*! dif -- construct difference of existing variable
*! Sean Becketti, April 1991.
program define dif
	version 3.0
	capture confirm integer number `1'
	if _rc==0 { 
		local lags `1'
		mac shift
	}
	else	local lags 1
	local varlist "req ex min(1) max(1)"
	local options "Suffix(str)"
	parse "`*'"
	if (`lags'==0) { exit }
	if `lags'<0 { 
		di in red "`lags' < 0 invalid"
		exit 198
	}
	if "`suffix'"=="" { local suffix "`varlist'" } 

	local addper = index("`suffix'","_")==0
	local type : type `varlist'
	local prefix "D"
	if (`lags')!=1 { local prefix "`prefix'`lags'" }
	if (`addper') { local prefix "`prefix'_" }
	local name = substr("`prefix'`suffix'",1,8)

	tempvar tmp res
	quietly {
		gen `type' `res' = `varlist'
		gen `type' `tmp' = .
		local i 1
		while (`i'<=`lags') {
			replace `tmp'=`res'
			replace `res'=`tmp'-`tmp'[_n-1]
			local i=`i'+1
		}
	}
	capture confirm var `name' 
	if _rc==0 { 
		di in bl "(note:  `name' replaced)"
		drop `name'
	}
	rename `res' `name'
	label var `name' "`prefix'`varlist'"
end
