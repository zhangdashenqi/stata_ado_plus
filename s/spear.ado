*! spear -- Spearman correlation with p-value.     STB-13: sg5.1
*! version 1.0.0     Sean Becketti     April 17, 1993
*  This replaces Stata's spearman command which has problems with "if" and "in"
program define spear
	version 3.0
	local varlist "req ex min(2) max(2)"
	local if "opt"
	local in "opt"
	parse "`*'"
	local sfn "$S_FN"
	tempfile user
	quietly save `user'
	capture {
		mac def S_1
		mac def S_4
		mac def S_5
		cap keep `in'
		cap keep `if'
		keep `varlist'
		parse "`varlist'", parse(" ")
		keep if `1'!=. & `2'!=.
		if (_N<2) {
			noi di in re "Not enough observations"
			error 99
		}
		tempvar x y
		egen `x' = rank(`1')
		egen `y' = rank(`2')
		corr `x' `y'
		local r=_result(4)
		local p=tprob(_N-2,`r'*sqrt((_N-2)/(1-`r'^2)))
		mac def S_1=_N
		mac def S_4=`r'
		mac def S_5=`p'
		noi di in gr "(nobs=" in ye = _N in gr ")"
		noi di in gr "Spearman's r = " in ye %5.2f = `r'
		noi di in gr "Prob z > |r| = " in ye %5.2f = `p'
	}
	local rc = _rc
	quietly use `user', clear
	erase `user'
	mac def S_FN "`sfn'"
	error `rc'
end
