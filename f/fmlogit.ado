*! 1.0.2 MLB 24 Jul 2009

/*------------------------------------------------ playback request */
program fmlogit, eclass byable(onecall)
	version 8.2
	if replay() {
		if "`e(cmd)'" != "fmlogit" {
			di as err "results for fmlogit not found"
			exit 301
		}
		if _by() error 190 
		Display `0'
		exit `rc'
	}
	syntax varlist [if] [in] [fw pw], *
	if _by() by `_byvars'`_byrc0': Estimate `0'
	else Estimate `0'
end

/*------------------------------------------------ estimation */
program Estimate, eclass byable(recall)
	syntax varlist [if] [in] [fw pw] [,  ///
		ETAvar(varlist numeric)  ///
		Baseoutcome(varname) ///
		Cluster(varname) Level(integer $S_level) noLOG * ]

	local k : word count `varlist'
			
	if !`: list baseoutcome in varlist' {
		di as err "varlist must contain baseoutcome"
		exit 198
	}
	
	marksample touse 
	markout `touse' `varlist' `etavar' `cluster'
	
	foreach var of varlist `varlist' {
		local test "`test' | `var' < 0 | `var' > 1"
	}
	tempvar tot
	
	qui gen double `tot' = 0 if `touse'
	qui foreach v of local varlist {
		replace `tot' = `tot' + cond(missing(`v'),0,`v') if `touse'
	}
	qui count if (`tot' < .99 | `tot' > 1.01 `test') & `touse'
	if r(N) {
		noi di " "
		noi di as txt ///
		"{p}warning: {res:`varlist'} has `r(N)' values < 0 or > 1" 
		noi di as txt ///
		" or rowtotal(`varlist') != 1; not used in calculations{p_end}"
	}
	qui replace `touse' = 0 if `tot' < .99 | `tot' > 1.01 `test' 

	qui count if `touse' 
	if r(N) == 0 error 2000 

	local title "ML fit of fractional multinomial logit"
	
	local wtype `weight'
	local wtexp `"`exp'"'
	if "`weight'" != "" local wgt `"[`weight'`exp']"'  
	
	if "`cluster'" != "" { 
		local clopt "cluster(`cluster')" 
	}

	if "`level'" != "" local level "level(`level')"
        local log = cond("`log'" == "", "noisily", "quietly") 
	
	mlopts mlopts, `options'
		
	if "baseoutcome" != "" {
		local varlist2 "`baseoutcome'"
		foreach var of local varlist {
			if "`var'" != "`baseoutcome'" local varlist2 = "`varlist2' `var'"
		}
		local varlist "`varlist2'"
	}
		
	tokenize `varlist'
	global S_ref "`1'"
	global S_depvars = "`varlist'"
	
	forvalues i = 2/`k' {
		if `i' == 2 {
			local eta "(eta_``i'': `varlist' = `etavar')"
		}
		else {
			local eta "`eta' (eta_``i'': `etavar')"
		}
	}

	`log' ml model lf fmlogit_lf `eta'                 ///
		`wgt' if `touse' , maximize 				 ///
		collinear title(`title') robust       		 ///
		search(on) `clopt' `level' `mlopts' `stdopts' `modopts' ///
		waldtest(`=`k'-1')

	eret local cmd "fmlogit"
	eret local depvars "`varlist'"
	ereturn local predict "fmlogit_p"

        Display, `level' `diopts'
end

program Display
	syntax [, Level(int $S_level) *]
	local diopts "`options'"
	if `level' < 10 | `level' > 99 local level = 95
	ml display, level(`level') `diopts'
end


