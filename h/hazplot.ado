* Plot hazard rates using a kernel density type 
* smoothing method.  The data must be survival 
* data in panel form, with each record corresponding 
* to a time period of unit length.
program define hazplot
	version 6.0
	syntax [if] [in], [BY(varlist) K(integer 1) SIGma(real 1) BReakpt(real -999.9) Plot Overlay List SYmbol(string) Connect(string) TItle(string) GPHBrk GPHPrint COMPrisk(varname numeric) *]

	* 1. If neither plot nor list is specified, assume plot.
	if "`plot'" == "" & "`list'" == "" {local plot = "plot"}
	
	* 2. Get information about survival time data characteristics.
	local datatyp : char _dta[_dta]
	local stft : char _dta[st_t]
	local stfail : char _dta[st_d]
	local stw : char _dta[st_w]
	local stid : char _dta[st_id]
	local stt0 : char _dta[st_t0]
	if "`datatyp'" ~= "st" {
		display in red "Data must be stset before using hazplot."
		exit 109
	}
	tempvar prdlen1 prdlen2 prdlbad
	if "`stt0'" == "" {
		display in red "Data must have time0() declared in stset before using hazplot."
		exit 109
	}
	quietly egen `prdlen1' = max(`stft' - `stt0')
	quietly egen `prdlen2' = min(`stft' - `stt0')
	if `prdlen1'[1] ~= `prdlen2'[1] {
		display in red "Data must be panel data with equal time periods before using hazplot."
		exit 109
	}
	local prdlen = `prdlen1'[1]
	drop `prdlen1' `prdlen2'
	quietly gen byte `prdlbad' = sum(`stft' ~= int(`stft'))
	if `prdlbad'[_N] ~= 0 {
		display in red "Failure times must be integer before using hazplot."
		exit 109
	}
	drop `prdlbad'
	quietly gen byte `prdlbad' = sum(`stt0' ~= int(`stt0'))
	if `prdlbad'[_N] ~= 0 {
		display in red "Period start times must be integer before using hazplot."
		exit 109
	}
	drop `prdlbad'
	local n :word count `by'
	if `n' == 0 {
		tempvar one
		gen `one' = 1
		local by = "`one'"
	}
	if "`symbol'" == "" {local symbol = "iiiiiiii"}
	if "`connect'" == "" {local connect = "llllllll"}
	local ptitle = "`title'"
	if "`title'" == "" {local title = "Hazard smoothed, k = `k', sigma = `sigma'"}
	if `breakpt' ~= -999.9 {local title = "`title', break at `breakpt'"}
	if "`compris'" ~= "" & "`overlay'" ~= "" {
		display in red "The overlay option is not allowed when using competing risks.  The competing risks will always be overlayed, but by-groups cannot be overlayed at the same time."
		exit 109
	}

	* 3. Preserve the data before modification.
	preserve
	
	* 4. Get rid of data points and variables not to be used.
	tempvar keepdat
	mark `keepdat' `if' `in'
	quietly keep if `keepdat' & (`stft' ~= .)  /* Get rid of data points not to be used. */
	drop `keepdat'
	keep `by' `stft' `stfail' `stw' `stid' `stt0' `compris'
	
	* 5. If analyzing competing risks, prepare.
	if "`compris'" ~= "" {
		tempvar chkok
		gen int `chkok' = sum(`compris'==.)
		if `chkok'[_N] > 0 {
			display in red "The competing risks variable contains missing values; this is not allowable."
			exit 109
		}
		drop `chkok'
		getvals `compris'
		local ncr :word count $gv_Res
		if `ncr' == 0 {
			display in red "Either the competing risks contain non-integer values or no failures occur."
			exit 109
		}
		if `ncr' > 999 {
			display in red "Sorry, but hazplot cannot handle more than 999 competing types of risk, and your data exceed this limit."
			exit 109
		}
		if `ncr' > 8 & "`plot'" ~= "" {
			display in red "Sorry, but hazplot cannot plot more than 8 competing types of risk.  You may use the list option, but not plot."
			exit 109
		}
	}
	else {
		local ncr = 0	/* 0 for number of competing risks. */
	}

	* 6. Generate hazard estimates by cohort.
	* 6A. Determine min. & max. times in the dataset.
	tempvar mintv maxtv
	egen `mintv' = min(`stft')
	local mint = `mintv'[1]
	drop `mintv'
	egen `maxtv' = max(`stft')
	local maxt = `maxtv'[1]
	drop `maxtv'
	* 6B. Compute estimated hazard at each time for each by-group and type of risk.
	if `ncr' == 0 {
		/* Case without competing risks. */
		tempvar w wx wxsum wnsum h
		local allhnms "`h'"
		gen `h' = -999
		if "`stw'" == "" {local stw = 1}
		local t = `mint'
		while `t' <= `maxt' {
			quietly gen `w' = ( normd((`stft' - `t') / (`prdlen' * `sigma')) / normd(0) ) * (abs(`stft' - `t') <= `k') * `stw'
			if `breakpt' ~= -999.9 {
				if `t' >= `breakpt' {
					quietly replace `w' = 0 if `stft' < `breakpt'
				}
				else {
					quietly replace `w' = 0 if `stft' >= `breakpt'
				}
			}
			quietly gen `wx' = cond(`stfail' ~= 0, `w', 0)
			quietly egen `wxsum' = sum(`wx'), by(`by')
			quietly egen `wnsum' = sum(`w'), by(`by')
			drop `w' `wx'
			sort `by' `stft'
			quietly by `by': replace `h' = `wxsum' / (`wnsum' * `prdlen') if `stft' == `t'
			drop `wxsum' `wnsum'
			local t = `t' + `prdlen'
		}
	}
	else {
		/* Case with competing risks. */
		local allhnms ""
		tempvar w wx wxsum wnsum
		local i = 1
		while `i' <= `ncr' {
		local riskn :word `i' of $gv_Res  /* The code used for this risk. */
		local hnmref = "h`i'"	/* Name of the macro that will hold the name of the hazard variable. */
		tempvar `hnmref'
		local allhnms "`allhnms' ``hnmref''"
		gen ``hnmref'' = -999
		if "`stw'" == "" {local stw = 1}
		local t = `mint'
		while `t' <= `maxt' {
			quietly gen `w' = ( normd((`stft' - `t') / (`prdlen' * `sigma')) / normd(0) ) * (abs(`stft' - `t') <= `k') * `stw'
			if `breakpt' ~= -999.9 {
				if `t' >= `breakpt' {
					quietly replace `w' = 0 if `stft' < `breakpt'
				}
				else {
					quietly replace `w' = 0 if `stft' >= `breakpt'
				}
			}
			quietly gen `wx' = cond(`compris' == `riskn', `w', 0)
			quietly egen `wxsum' = sum(`wx'), by(`by')
			quietly replace `w' = `w' / 2 if `compris' ~= `riskn' & `compris' ~= 0  /* If the individual failed sometime during the time interval from another kind of risk, assume it was no longer at risk of failure from risk i as of half-way through the time interval. */
			quietly egen `wnsum' = sum(`w'), by(`by')
			drop `w' `wx'
			sort `by' `stft'
			quietly by `by': replace ``hnmref'' = `wxsum' / (`wnsum' * `prdlen') if `stft' == `t'
			drop `wxsum' `wnsum'
			local t = `t' + `prdlen'
		}
		local i = `i' + 1
		}
	}

	* 7. Construct graph.
	if "`plot'" == "plot" {
		sort `by' `stft'
		if "`overlay'" == "" {
			graph `allhnms' `stt0', symbol(`symbol') connect(`connect') t1title("Hazard smoothed") by(`by') `options'
		}
		else {
			/* Note: The overlay option is not allowable (and is ruled out above) if there are competing risks. */
			tempvar firstrb bynum
			quietly by `by': gen byte `firstrb' = _n == 1
			quietly gen `bynum' = sum(`firstrb')
			drop `firstrb'
			local maxbyn = `bynum'[_N]
			if `breakpt' ~= -999.9 & `maxbyn' > 4 & "`gphbrk'" == "gphbrk" {
				display in red "The overlay option allows only up to 4 by-groups with a graphed breakpoint."
				exit 109
			}
			else if `maxbyn' > 8 {
				display in red "The overlay option allows only up to 8 by-groups."
				exit 109
			}
			local i = 1
			while `i' <= `maxbyn' {
				if `breakpt' ~= -999.9 & "`gphbrk'" == "gphbrk" {
					local varnma = "by`i'a"
					local varnmb = "by`i'b"
					quietly gen `varnma' = `h' if (`bynum' == `i') & (`stft' < `breakpt')
					quietly gen `varnmb' = `h' if (`bynum' == `i') & (`stft' >= `breakpt')
					if `i' == 1 {local varnms = "`varnma' `varnmb'"}
					else {local varnms = "`varnms' `varnma' `varnmb'"}
				}
				else {
					local varname = "by`i'"
					quietly gen `varname' = `h' if `bynum' == `i'
					if `i' == 1 {local varnms = "`varname'"}
					else {local varnms = "`varnms' `varname'"}
				}
				local i = `i' + 1
			}
			drop `bynum'
			graph `varnms' `stt0', symbol(`symbol') connect(`connect') title(`title') `options'
			drop `varnms'
			if "`gphprin'" == "gphprint" {gphprint}
		}
	}

	* 8. Print out results.
	if "`list'" == "list" {
		display "Smoothed hazard plot results"
		display "title: `title'"
		display "k = `k', sigma = `sigma'"
		if `breakpt' ~= -999.9 {display "break at `breakpt'"}
		if `ncr' == 0 {
			/* Case with no competing risks. */
			display "List (by by-vars) of: timevar hazard samplesize
			tempvar firstr natrisk
			sort `by' `stft'
			if "`stw'" == "" {quietly egen long `natrisk' = count(`stft'), by(`by' `stft')}
			else {quietly egen long `natrisk' = sum( (`stft' ~= .) * `stw' ), by(`by' `stft')}
			sort `by' `stft'
			quietly by `by' `stft': gen byte `firstr' = _n == 1
			by `by': list `stft' `h' `natrisk' if `firstr'
			drop `firstr' `natrisk'
		}
		else {
			/* Case with competing risks. */
			local i = 1
			while `i' <= `ncr' {
				local riskn :word `i' of $gv_Res  /* The code used for this risk. */
				local hnmref = "h`i'"	/* Name of the macro that holds the name of the hazard variable. */
				display "FOR RISK = `riskn'"
				display "List (by by-vars) of: timevar hazard samplesize
				tempvar firstr natrisk
				sort `by' `stft'
				if "`stw'" == "" {quietly egen long `natrisk' = count(`stft'), by(`by' `stft')}
				else {quietly egen long `natrisk' = sum( (`stft' ~= .) * `stw' ), by(`by' `stft')}
				sort `by' `stft'
				quietly by `by' `stft': gen byte `firstr' = _n == 1
				by `by': list `stft' ``hnmref'' `natrisk' if `firstr'
				drop `firstr' `natrisk'
				local i = `i' + 1
		}
		display "end of smoothed hazard plot results, title: `title'"
	}
end

/* Get a list of all nonmissing, non-zero values of an integer variable. */
program define getvals
	version 6.0
	syntax varname
	global gv_Res ""
	tempvar testv notdone maxn
	quietly gen byte `testv' = sum(`varlist' ~= int(`varlist'))
	if `testv'[_N] ~= 0 {
		display in red "Competing risks must only be specified with integer values."
		exit
	}
	drop `testv'
	gen byte `notdone' = 1
	local i = 1
	while `i' > 0 {
		local n = `varlist'[`i']
		quietly replace `notdone' = 0 if `varlist'==`varlist'[`i']
		if `varlist'[`i'] ~= . & `varlist'[`i'] ~= 0 {
			/* Add this value of the variable to the list of values. */
			global gv_Res "$gv_Res `n'"
		}
		quietly egen int `maxn' = max(_n * `notdone')
		local i = `maxn'[_N]
		drop `maxn'
	}
end
