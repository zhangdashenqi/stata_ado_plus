*! version 1.0.2  25jun2001  (adapted from version 4.0 code)
program define permute, rclass
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
		*/ DOuble EVery(string) REPLACE leavemore ]

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
  
/* Get value of test statistic for unpermuted data. */

  	preserve
  	global S_1 "first"

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
      			di as err "`prog' returned `$S_1' where number " /*
      			*/ "expected"
      			exit 7
    		}
  	}

/* Initialize postfile. */

  	if "`post'"!="" {
    		tempname postnam
    		if "`every'"!="" {
      			confirm integer number `every'
      			local every "every(`every')"
    		}
    		postfile `postnam' stat using `post', /*
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
    		di _n as txt "Observed test statistic = T(obs) = " /*
    		*/ as res %9.0g `tobs' _n(2) as txt "`ho'" _n
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
 
  	local i 1
  	while `i' <= `reps' {
    		`oo' PermVars "`by'" `k' `x'

    		`do' PermDiV "`by'" `k' `min' `max' `x'

		`prog' `x' `varlist'
    		`so' local c = `c' + (`abs'($S_1) `rel' `comp')
    		`po' post `postnam' ($S_1)

    		if `display' > 0 & mod(`i',`display')==0 {
      			di as txt "n = " as res %5.0f `i' `dicont'
      			`so' noi di as txt " p = " /*
      			*/ as res %4.0f `c' "/" %5.0f `i' /*
      			*/ as txt " = " as res %7.5f `c'/`i' /*
      			*/ as txt " s.e.(p) = " as res %7.5f /*
      			*/ sqrt((`i'-`c')*`c'/`i')/`i'
    		}
    		local i = `i' + 1
  	}
  	if "`prob'"=="" {
    		if `display' > 0 {di}
    		di as txt "n = " as res %5.0f `reps' /*
    		*/ as txt " p = " as res %4.0f `c' "/" %5.0f `reps' /*
    		*/ as txt " = " as res %7.5f `c'/`reps' /*
    		*/ as txt " s.e.(p) = " as res %7.5f /*
    		*/ sqrt((`reps'-`c')*`c'/`reps')/`reps'
  	}
  
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
exit

