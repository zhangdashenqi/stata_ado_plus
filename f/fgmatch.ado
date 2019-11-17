program fgmatch, rclass byable(onecall)
*! $Revision: 1.7 $
*! Author:  Mark Lunt
*! Date:    October 15, 2007 @ 12:37:07

	// TODO: Allow for 1-k matching, not just 1-1     DONE
  //       Allow non-integral steps                 DONE

version 9

	syntax varlist [if] [in] [,Set(namelist min=1 max=1)  ///
			                       Diff(namelist min=1 max=1) ///
			                       Pwt(namelist min=1 max=1)  ///
			                       suffix(string)             ///
                             start(real 5)              ///
                             stop(real 1)               ///
			                       step(real 1)               ///
			                       maxc(integer 1)            ///
			                       seed(integer 0)            ///
                             LP]       

	tokenize `varlist'
	local group `1'
	macro shift
	local prop  `1'
	marksample touse

	if `seed' > 0 {
		set seed `seed'
	}

	if "`set'" == "" {
		local set set`suffix'
	}

	qui isvar `set'
	if "`set'" == "`r(varlist)'" {
		noi di as error "The variable `set' already exists: unable to proceed."
		exit 100
	}

	if "`diff'" == "" {
		local diff diff`suffix'
	}

	qui isvar `diff'
	if "`diff'" == "`r(varlist)'" {
		noi di as error "The variable `diff' already exists: unable to proceed."
		exit 100
	}

	if "`pwt'" == "" {
		local pwt pwt`suffix'
	}

	qui isvar `pwt'
	if "`pwt'" == "`r(varlist)'" {
		noi di as error "The variable `pwt' already exists: unable to proceed."
		exit 100
	}

	if "`lp'" == "lp" {
		tempvar nprop
		qui  gen `nprop' = log(`prop'/(1-`prop')) if `touse'
		local prop `nprop'
	}

	tempvar orig_order touse_now
	gen `orig_order' = _n

	local sortvars : sortedby
	local byprefix
	tempvar bygrp
	if "`_byvars'" ~= "" {
		local byprefix by `_byvars':
	  egen `bygrp' = group(`_byvars')
	}
	else {
		gen `bygrp' = 0
	}

	// Expand treated if they can be reused
	// Usual  context has few treated, lots of potential matches, may
	// want to use more than one match per treated subject
	
	if `maxc' > 1 {
		tempvar expand
		gen `expand' = 1
		replace `expand' = `maxc' if `group' == 1
		expand `expand'
	}
	
	tempvar randnum sset
	// set seed 1234567 
	qui gen `randnum' = uniform()
	qui replace `randnum' = `prop' if `group' == 1
	qui gen str20 `sset' = ""

	tempvar nset nsetcount
	gen `nset' = 0
	gen `nsetcount' = 0
	quietly {
		tempvar rprop rpropgp
		local digits `start'
		while `digits' >= `stop' {
			noi di as text "Matching to `digits' digits: " _cont
			gen `rprop' = round(`prop',10^(-1*(`digits'))) if  ///
			    `sset' == "" & `touse'
			egen `rpropgp' = group(`rprop') if `sset' == "" & `touse'
			sort `_byvars' `rpropgp' `group' `randnum'
			by `_byvars' `rpropgp' `group' :  ///
					replace `sset' = string(`bygrp') + "_" + "`digits'" + "_" +  ///
					string(`rpropgp') + "_" + string(_n) if `sset' == "" & `touse'
			sort `_byvars' `sset'
			by `_byvars' `sset': replace `sset' = "" if _N == 1
			replace `nset' = `sset' != ""
			replace `nsetcount' = sum(`nset')
			local matches = `nsetcount'[_N] / 2
			noi di as result "`matches' " as text "matches found."
			drop `rprop' `rpropgp'
			local digits = `digits' - `step'
		}
		sort `_byvars' `sset' `group'
		by `_byvars' `sset': gen `diff' = abs(`prop'[1]-`prop'[2])  ///
		    if `sset' ~= "" & `group' == 0
		egen `set' = group(`sset') if `sset' ~= ""
	}

	// Reduce back to a single record per case, if necessary
	// Collapse all sets matched to that case to have a single id
	if `maxc' > 1 {
		tempvar caseid newset
		gen `caseid' = `orig_order' if `group' == 1
		gsort `set' -`group'
 		by `set': replace `caseid' = `caseid'[1] if `group' == 0 & `set' != .
		egen `newset' = group(`caseid') if `set' ~= .
		replace `set' = `newset'
		sort `orig_order' `newset'
		by `orig_order': keep if _n == 1
		sort `set' `group'
		by `set': gen `pwt' = _N - 1 if `set' != .
		by `set': replace `pwt' = 1 if `group' == 0 & `set' != .
		replace `pwt' = 1 if `group' == 0 & `set' != .
		replace `pwt' = 0 if `set' == . & `touse'
	}
	else {
		gen `pwt' = `set' != .
	}
	
	sort `sortvars' `orig_order'

end
