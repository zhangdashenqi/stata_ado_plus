*! _ts_dsmp -- display sample coverage for estimation command
*! version 1.1.0     Sean Becketti     September 1993           STB-15: sts4
*       
program define _ts_dsmp
	version 3.1
	local varlist "opt ex"
	local if "opt pre"
	local in "opt pre"
	local weight "aweight fweight iweight pweight"
	local options "Date(str)"
	parse "`*'"
	if ("`varlist'"=="") {
		di in re "varlist required"
		error 99
	}
	if (_N==0) {
		di in re "no observations"
		error 99
	}
	if ("`date'"!="") { conf var `date' }
/*
	Determine the beginning and ending observation numbers.
*/
        tempvar touse
        mark `touse' `if' `in' `weight'`exp'
        markout `touse' `varlist'
        _crcnuse `touse'
        local nobs $S_1
        local gaps $S_2
        local first $S_3
        local last $S_4
/*
	Get the first and last dates and display them.
*/
	if `nobs'==0 {                  /* This loop added May 7, 1994 */
		mac def S_1 "."         /* to handle situations where  */
		mac def S_2 "."         /* there are no usable obs     */
		mac def S_3=.
		mac def S_4=.
		mac def S_5=0
		mac def S_6=.
		di in gr "no observations"
		exit
	}
	if ("`date'"!="") {local date "date(`date')"}
	_ts_gdat `first' , `date'
	local fdate "$S_1"
	_ts_gdat `last' , `date'
	local ldate "$S_1"
	qui period
	local prefix "$S_2"
	local prefix=upper(substr("`prefix'",1,1))+substr("`prefix'",2,.)
	di in ye "`prefix'" in gr " data:  " in ye "`fdate'" in gr " to " in ye "`ldate'" in gr "    (" in ye "`nobs'" in gr " obs)"
	if (`gaps') {
		local miss=1+`last'-`first'-`nobs'
		local wgap "gap"
		if (`gaps'>1) {local wgap "`wgap's"}
		di in bl "       Warning:  sample has " in ye "`gaps'" in bl " `wgap' with " in ye "`miss'" in bl " missing observations"
	}
	mac def S_1 "`fdate'"
	mac def S_2 "`ldate'"
	mac def S_3=`first'
	mac def S_4=`last'
	mac def S_5=`nobs'
	mac def S_6=`gaps'
end
