*! _ts_pars -- parse a time series equation into useful macros
*! version 1.0.0     Sean Becketti     September 1993           STB-15: sts4
program define _ts_pars
	version 3.1
	mac def S_1
	mac def S_2
	mac def S_3
	mac def S_4
	local varlist "req ex"
	local options "Current(str) Lags(str) Static(str) *"
	parse "`*'"
	if ("`static'"!="") {
		_parsevl `static'
		local static "$S_1"
	}
/*
	How many variables are there?
*/
	parse "`varlist'", parse(" ")
	local nx = -1
	while ("`1'"!="") {
		local nx=`nx'+1
		mac shift
	}
/*
	Store the lags for each time series.
*/
	_subchar "," " " "`lags'"
	local lags "$S_1"
	parse "`lags'", parse(" ")
	local maxlag=0
	local i=-1
	local prevlag=0
	while (`i'<`nx') {
		local i=`i'+1
		local j=`i'+1
		local lag`i' "``j''"
		if ("`lag`i''"=="") {local lag`i'=`prevlag'}
		cap conf integer n `lag`i''
		local rc=_rc
		if (!`rc') {local rc=`lag`i''<0}
		if (`rc') {
			di in re "lags must be non-negative integers"
			error 99
		}
		local maxlag = max(`maxlag',`lag`i'')
		local prevlag=`lag`i''
	}
/*
	Loop through the time series (including the LHS variable) and
	construct the appropriate macros.  Also, count the number of
	RHS time series.  Note that x0 is the LHS variable and its
	lags.
*/
	parse "`varlist'", parse(" ")
	local lhs "`1'"
	local i=-1
	while (`i'<`nx') {
		local i=`i'+1
		local j=`i'+1
		local vname "``j''"
/*
	If there are no lags, the RHS time series variables are dropped.
*/
		_invlist "`vname'" "`current'"
/*
	Previously, we ran a static regression if all lags were zero, i.e.,
	we used the following logic.

		local contval=$S_1 | `maxlag'==0

*/
		local contval=$S_1
/*
        Old logic for including LHS varname at front of list.  This logic
        repeated the current value of the LHS variable if the LHS variable
        was repeated, i.e. "tsfit y x1 y x2".  This new logic still fails
        if the user insists on placing the LHS varname in the current() list.

                local iflhs="`vname'"=="`lhs'"
		if (`contval' | `iflhs') {local reglist "`reglist' `vname'"}
*/
		if (`contval' | (`i'==0)) {local reglist "`reglist' `vname'"}
		if (`contval') {local x`i' "`vname'"}
		local l = 0
		while (`l'<`lag`i'') {
			local l=`l'+1
			_addl `vname'
			local vname "$S_1"
			local reglist "`reglist' `vname'"
			local x`i' "`x`i'' `vname'"
			if (`l'==`lag`i'') {local lastlag "`lastlag' `vname'"}
		}
	}
/*
	Store the macros in the S_# macros for return to the calling program.
*/
	mac def S_1 "`reglist' `static'"
	mac def S_2 = `nx'
	mac def S_3 = `maxlag'
	mac def S_4 "`lastlag'"
	local i=-1
	while (`i'<`nx') {
		local i = `i'+1
		local j = `i'+5
		local k = `i'+6+`nx'
		mac def S_`j' "`x`i''"
		mac def S_`k' = `lag`i''
	}
end
