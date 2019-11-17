*! version 1.0.0  20mar2003
program define histoflogx
	version 8.0
	syntax varname [fw] [if] [in], LABels(numlist) [ * ]

	if "`weight'" != "" {
		local weight [`weight'`exp']
	}

	tempvar logx
	quietly gen double `logx' = log(`varlist')
	foreach num of local labels {
		local ll = log(`num')
		local loglabels `"`loglabels' `ll' "`num'""'
	}
	local xttl : var label `varlist'
	if `"`xttl'"' == "" {
		local xttl `varlist'
	}
	histogram `logx' `weight' `if' `in',	///
		xtitle("`xttl'")		///
		xlabels(`loglabels')		///
		`options'
end
