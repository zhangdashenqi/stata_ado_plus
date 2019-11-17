*! _ac -- calculate autocorrelations, std errors, and q-stats
*! version 1.0.0     Sean Becketti     August 1993              STB-15: sts4
program define _ac
version 3.1
	local varlist "req ex min(1) max(1)"
	local if "opt pre"
	local in "opt pre"
	local options "Lags(int 20)" 
	parse "%_*"
	if `lags'<=0 {
                di in re "lags must be positive"
                exit 2
        }
	quietly {
/*
	First "trim" the data set to just the desired observations.
*/
		local x "`varlist'"
		tempvar touse
		mark `touse' `if' `in'
		markout `touse' `x'
		_crcnuse `touse'
		local N $S_1
		local last=$S_4
		local in "in $S_3/`last'"
		if $S_2 { 
			di in re "missing values encountered"
			error 499
		}
		if (`N'<5) {
			di in re "not enough non-missing observations"
			error 499
		}
		local lags = min(`lags',`N'-5)
/*
	Calculate mean and variance of the series.
*/
		sum `x' `in' 
		local mean = _result(3)
        	local C0 = (`N'-1)*_result(4)
		global S_1 = `C0'/`N'
/*
	Now calculate the sequence of autocorrelations.
*/
        	tempvar work
		gen double `work' = . 
		local acsq = 0
		local q = 0
        	local l = 0
        	while (`l' < `lags') {
                	local l = `l' + 1
                	replace `work' = sum((`x'-`mean')*(`x'[_n-`l']-`mean')) `in'
                	local r = `work'[`last']/`C0'
			local r2 = `r'*`r'
			local se = sqrt((1+2*`acsq')/`N')
			local acsq = `acsq' + `r2'
			local q = `q' + `r2'/(`N'-`l')
			local i = 2 + 3*(`l'-1)
			local j = `i' + 1
			local k = `j' + 1
			global S_`i' = `r'
			global S_`j' = `se'
			global S_`k' = `N'*(`N'+2)*`q'
		}
	} /* quietly */
end
