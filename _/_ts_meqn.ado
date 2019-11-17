*! _ts_meqn -- parse time series regression and generate lags
*! version 1.0.0     Sean Becketti     June 1992                STB-15: sts4
program define _ts_meqn
	version 3.0
	local varlist "req ex"
	local options "Current(str) Lags(str) Static(str)"
	parse "`*'"
/*
	Parse the equation, retrieve the specification, and create the lags.
*/
	if ("`current'"!="") {local c "c(`current')"}
	if ("`lags'"!="") {local l "l(`lags')"}
	if ("`static'"!="") {local s "s(`static')"}
	_ts_pars `varlist', `c' `l' `s'
	local reglist "$S_1"
	local nx=$S_2
	local maxlag=$S_3
	parse "`varlist'", parse(" ")
	local i=0
	while (`i'<=`nx') {
		local i=`i'+1
		local j=`i'+`nx'+5
		lag ${S_`j'} ``i''
	}
/*
	Restore reglist, nx, and maxlag.
*/
	mac def S_1 "`reglist'"
	mac def S_2=`nx'
	mac def S_3=`maxlag'
end
