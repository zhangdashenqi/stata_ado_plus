*! quandt -- Calculate Quandt's breakpoint statistic
*! version 1.0.0     Sean Becketti     January 1994
program define quandt
quietly {
	version 3.1
	local varlist "req ex"
	local if "opt pre"
	local in "opt pre"
	local options "noCOnstant Current(str) Generate(str) Lags(str) Preserve Static(str) *"
	parse "`*'"
	global S_1
	global S_2
/*
	Can we generate lambda (if requested)?
*/
	if ("`generat'"!="" & "`preserv'"!="") {
		noi di in re "Cannot generate AND preserve"
		error 99
	}
	if ("`generat'"!="") {
		parse "`generat'", parse(" ")
		local lambda "`1'"
		mac shift
		if ("`1'"!="") {error 103}
		conf new variable `lambda'
	}
	else {tempvar lambda}
	gen double `lambda' = .
	if "`preserv'"!="" { cap preserve }
/*
	Parse time series options and create lags.
*/
	if "`current'"!="" { local c "current(`current')" }
	if "`lags'"!=""    { local l "lags(`lags')" }
	if "`static'"!=""  { local s "static(`static')" }
	if ("`c'"!="") | ("`l'"!="") | ("`s'"!="") {
		_ts_meqn `varlist', `constan' `c' `l' `s'
		local varlist "$S_1"
	}
/*
        Delimit the sample.
*/
	local minobs = 10	/* Magic number */
	tempvar touse
	mark `touse' `if' `in'
	markout `touse' `varlist'
	_crcnuse `touse'
	local T $S_1
	local gaps $S_2
	local first $S_3
	local last $S_4
	local if
	local early "_n<=\`i'"
	local late  "_n>\`i'"
	if `gaps' { 
		local if "if `touse'" 
		local early "`touse' & _n<=\`i'"
		local late  "`touse' & _n>\`i'"
		}
	local in "in `first'/`last'"
/*
	Run the overall regression.
*/
	local breakpt = .
	local lammin = .
	reg `varlist' `if' `in', `constan' `options'
	local K = `T' - _result(5)
	if (`T'-`K'<`minobs') { error 2001 }
	local S = sqrt(_result(9)*((`T'-`K')/`T'))
	local i = `K' + `minobs' + `first'
	local imax = `last' - `K' - `minobs' - 1
	while (`i' < `imax') {
		local i = `i' + 1
		if (`touse'[`i']) {
			reg `varlist' if `early' `in', `constan' `options'
			local T1 = _result(1)
			local K1 = `T1' - _result(5)
			local S1 = sqrt(_result(9)*((`T1'-`K1')/`T1'))
			reg `varlist' if `late' `in', `constan' `options'
			local T2 = _result(1)
			local K2 = `T2' - _result(5)
			local S2 = sqrt(_result(9)*((`T2'-`K2')/`T2'))
			replace `lambda' = exp( (`T1'*log(`S1') + `T2'*log(`S2')) / (`T'*log(`S')) ) in `i'
			if (`lambda'[`i']<`lammin') {
				local breakpt = `i'
				local lammin = `lambda'[`i']
			}
		}
	}
	global S_1 = `breakpt'
	global S_2 = `lammin'
}
end
