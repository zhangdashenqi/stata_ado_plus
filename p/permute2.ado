*! version 1.1.2  27jun2001
* $Id: permute2.ado,v 1.3 2001/06/27 20:45:10 jsp Exp $
program define permute2, rclass
	version 7

	gettoken prog 0: 0, parse(" ,")
	if `"`prog'"'=="" | substr(`"`prog'"',1,1)=="," {
		di as err `"program name required"'
		exit 198
	}

	capture which `prog'
	if _rc {
		di as err "program `prog' not found"
		exit 198
	}

	syntax [varlist] [, BY(varlist) LEft RIght Reps(integer 100) /*
		*/ DIsplay(integer 10) EPS(real 1e-7) noProb POST(string) /*
		*/ DOuble EVery(string) REPLACE qui leavemore ]
	gettoken x varlist: varlist
  
	if "`by'"!="" {
		local byby "by `by':"
	}

	if `eps' < 0 {
		di as err "eps() must be greater than or equal to zero"
		exit 198
	}
	if "`left'"!="" & "`right'"!="" {
		di as err "only one of left or right can be specified"
		exit 198
	}
	if "`left'"!="" {
		*local ho "Test of Ho: T = 0 vs. Ha: T < 0 (one-sided)"
		local ho "p is an estimate of Pr(T <= T(obs))"
		local rel "<="
		local eps = -`eps'
	}
	else if "`right'"!="" {
		*local ho "Test of Ho: T = 0 vs. Ha: T > 0 (one-sided)"
		local ho "p is an estimate of Pr(T >= T(obs))"
		local rel ">="
	}
	else {
		*local ho "Test of Ho: T = 0 vs. Ha: T sim= 0 (two-sided)"
		local ho "p is an estimate of Pr(|T| >= |T(obs)|)"
		local rel ">="
		local abs "abs"
	}
	if "`post'"=="" & "`double'"!="" {
		di as err "double can only be specified when using post()"
		exit 198
	}
	if "`post'"=="" & "`every'"!="" {
		di as err "every() can only be specified when using post()"
		exit 198
	}
	if "`post'"=="" & "`replace'"!="" {
		di as err "replace can only be specified when using post()"
		exit 198
	}
  
/* Get value of test statistic(s) for unpermuted data. */

	preserve
	global S_1 "first"
	global S_2

	if "`prob'"=="" | "`post'"!="" {
		capture noisily `prog' `x' `varlist'
		if _rc {
			di as err _n "`prog' returned error:"
			error _rc
		}
		if "$S_1"=="first" | "S_1"=="" {
			di as err "`prog' does not set global macro S_1"
			exit 7
		}
		capture confirm number $S_1
		if _rc {
			di as err `"`prog' returned $S_1 where number "' /*
			*/ "expected"
			exit 7
		}

		capture confirm exist $S_2
		if _rc==0 {
			* check that S_2 returns the number of statistics
			capture confirm integer number $S_2
			if _rc==7 {
di as err "`prog' returned $S_2 in global S_2 instead of integer or nothing"
				exit 7
			}
		}
		else {
			* note that S_2 is empty, implying 1
			local empty "*"
			global S_2 1
		}
	}
	local nstats = $S_2
	`empty' capture noisily `prog' `x' `varlist'
	if _rc {
		di as err _n "`prog' returned error:"
		error _rc
	}

/* Initialize postfile. */

	if "`post'"!="" {
		tempname postnam
		if "`every'"!="" {
			confirm integer number `every'
			local every "every(`every')"
		}
		* generate list of stat names for post
		local stats stat
		forvalues j = 2/`nstats' {
			local stats `stats' stat`j'
		}
		postfile `postnam' `stats' using `post', /*
		*/ `replace' `double' `every' 
	}
	else local po "*"

/* Display observed test statistic and Ho. */

	if `"`leavemore'"' == "" { 
		set more off
	}
	di as txt "(obs=" _N ")"

	if "`prob'"=="" {
		tempname comp
		local tobs "$S_1"
		scalar `comp' = `abs'($S_1) - `eps'
		local dicont "_c"
		local c 0
		di _n as txt "Observed test statistic = " /*
		*/ %3s "T" "(obs) = " as res %9.0g `tobs'
		forvalues j = 2/`nstats' {
			tempname comp`j'
			local tobs`j' "${S_`j'}"
			scalar `comp`j'' = `abs'(${S_`j'}) - `eps'
			local dicont`j' "_c`j'"
			local c`j' 0
			di as txt "Observed test statistic = " /*
			*/ %3s "T`j'" "(obs) = " as res %9.0g `tobs`j''
		}
		di as txt _n "`ho'"
	}
	else local so "*"

/* Sort by `by' if necessary. */
  
	if "`by'"!="" { sort `by'}

/* Check if `x' is a single dichotomous variable. */

	quietly {
		tempvar k
		summarize `x'
		capture assert r(N)==_N /*
		*/ & (`x'==r(min) | `x'==r(max))
		if _rc==0 {
			tempname min max
			scalar `min' = r(min)
			scalar `max' = r(max)

			`byby' gen long `k' = sum(`x'==`max')
			`byby' replace `k' = `k'[_N]

			local oo "*"
		}
		else {
			gen long `k' = _n
			local do "*"
		}
	}

/* Do permutations. */

	`qui' di
	`qui' TableHead "Intermediate Results"
	local i 1
	while `i' <= `reps' {
		`oo' PermVars "`by'" `k' `x'

		`do' PermDiV "`by'" `k' `min' `max' `x'

		`prog' `x' `varlist'
		local stats ($S_1)
		`so' local c = `c' + (`abs'($S_1) `rel' `comp')
		forvalues j = 2/`nstats' {
			local stats `stats' (${S_`j'})
			`so' local c`j' = `c`j'' + /*
			*/(`abs'(${S_`j'}) `rel' `comp`j'')
		}
		`po' post `postnam' `stats'

		if `display' > 0 & mod(`i',`display')==0 {
			`qui' TableFoot, plus
			`qui' TableEntry "stat" `c' `i' /*
			*/ `c'/`i' sqrt((`i'-`c')*`c'/`i')/`i'
			forvalues j = 2/`nstats' {
				`qui' TableEntry "stat`j'" `c`j'' `i' /*
				*/ `c`j''/`i' sqrt((`i'-`c`j'')*`c`j''/`i')/`i'
			}
		}
		local i = `i' + 1
	}
	`qui' TableFoot
	
	di
	TableHead "Final Results"
	TableFoot, plus
	TableEntry "stat" `c' `reps' /*
	*/ `c'/`reps' sqrt((`reps'-`c')*`c'/`reps')/`reps'
	forvalues j = 2/`nstats' {
		TableEntry "stat`j'" `c`j'' `reps' /*
		*/ `c`j''/`reps' sqrt((`reps'-`c`j'')*`c`j''/`reps')/`reps'
	}
	TableFoot
  
	if "`post'"!="" { postclose `postnam'}

	return scalar reps = `reps'
	`so' return scalar c = `c'
	if "`prob'"=="" {
		return scalar tobs = `tobs'
	}

/* Double save. */
 
	global S_1 "`reps'"
	global S_2 "`c'"
	global S_3 "`tobs'"
	if `"`leavemore'"' == "" { 
		set more on
	}
end

program define PermVars /* "byvars" k var */
	version 7
	local by "`1'"
	local k "`2'"
	local x "`3'"
	tempvar r y
	quietly {
		if "`by'"!="" {
			by `by': gen double `r' = uniform()
		}
		else gen double `r' = uniform()

		sort `by' `r'
		local type : type `x'
		gen `type' `y' = `x'[`k']
		drop `x'
		rename `y' `x'
	}
end

program define PermDiV /* "byvars" k min max var */
	version 7
	local by "`1'"
	local k "`2'"
	local min "`3'"
	local max "`4'"
	local x "`5'"
	tempvar y
	if "`by'"!="" {
		sort `by'
		local byby "by `by':"
	}
	quietly {
		gen byte `y' = . in 1
		`byby' replace `y' = uniform()<(`k'-sum(`y'[_n-1]))/(_N-_n+1)
		replace `x' = cond(`y',`max',`min')
	}
end


program define TableHead
	args title
	di in smcl as txt `"`title'"'
	di in smcl as txt %-12s "Statistic" " {c |}" _s(2)/*
		*/ %8s  "c"     _s(2) /*
		*/ %8s  "n"     _s(2) /*
		*/ %9s  "p=c/n" _s(2) /*
		*/ %9s  "SE(p)" _s(2)
end

program define TableEntry
	args name c n p sep
	di in smcl as txt %-12s "`name'" " {c |}" _s(2) as result /*
		*/ %8.0g  `c'     _s(2) /*
		*/ %8.0g  `n'     _s(2) /*
		*/ %9.5f  `p'     _s(2) /*
		*/ %9.5f  `sep'   _s(2)
end

program define TableFoot
	syntax [, plus]
	if "`plus'"=="" {
		local plus BT
	}
	else local plus +
	di in smcl as text "{hline 13}{c `plus'}{hline 42}"
end
exit

