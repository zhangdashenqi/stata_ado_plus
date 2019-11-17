program propwt, rclass byable(onecall)

*! $Revision: 1.6 $
*! Author:    Mark Lunt & Ariel Linden
*! Date:      October 8, 2009 @ 16:46:00

version 8.2

syntax varlist [if] [in], [IPT ATT ATC ALT SMR gen(string) noSCaled  ///
			LP ]

 local by "`_byvars'"

	tokenize `varlist'
	local treat `1'
	macro shift
	local prop `1'
	
	if "`ipt'`att'`atc'`alt'`smr'" == "" {
		local ipt ipt
	}
	
	if "`gen'" == "" {
		local gen _wt
	}

	marksample touse
	
	if "`lp'" ~= "" {
		tempvar p
		qui gen `p' = exp(`prop')/(1+exp(`prop')) if `touse'
		local prop `p'
	}

	tempvar p0 mult
	if "`scaled'" == "" {
		if "`by'" == "" {
			qui logit `treat' if `touse'
			qui predict `p0'
		  qui gen `mult' = `p0' if `touse'
		  qui replace `mult' = 1 - `p0' if `touse' & `treat' == 0
		}
		else {
			tempvar bygroup ptemp
			qui egen `bygroup' = group(`by')
			qui tab `bygroup'
			local groups = r(r)
			qui gen `p0'   = .
			qui gen `mult' = .
			foreach i of numlist 1/`groups' {
				capture drop `ptemp'
				qui logit `treat' if `touse' & `bygroup' == `i'
				qui predict `ptemp'
				replace `p0' = `ptemp' if `touse' & `bygroup' == `i'
				qui replace `mult' = `p0' if `touse' & `bygroup' == `i'
				qui replace `mult' = 1 - `p0' if `touse' & `bygroup' == `i' & `treat' == 0
			}
		}
	}

	else {
		qui gen `mult' = 1 if `touse'
	}

//	tab `treat' `mult'
// Check that given variables are sensible

//	qui tab `treat' if `touse'

	if "`ipt'" != "" {
		qui isvar ipt`gen'
		if "ipt`gen'" == "`r(varlist)'" {
			noi di in red "The variable ipt`gen' already exists: unable to proceed."
			exit 100
		}
		else {
			qui gen ipt`gen' = `mult'/`prop'  if `touse'
			qui replace ipt`gen' = `mult'/(1-`prop') if `treat' == 0 & `touse'
		}
	}

	if "`smr'" != "" {
		qui isvar smr`gen'
		if "smr`gen'" == "`r(varlist)'" {
			noi di in red "The variable smr`gen' already exists: unable to proceed."
			exit 100
		}
		else {
			qui gen smr`gen' = `mult'*`prop'/(1-`prop') if `touse'
			qui replace smr`gen' = `mult' if `treat' == 1 & `touse'
		}
	}

	if "`att'" != "" {
		qui isvar att`gen'
		if "att`gen'" == "`r(varlist)'" {
			noi di in red "The variable att`gen' already exists: unable to proceed."
			exit 100
		}
		else {
			qui gen att`gen' = `mult'*`prop'/(1-`prop') if `touse'
			qui replace att`gen' = `mult' if `treat' == 1 & `touse'
		}
	}

//* gen atc =cond(tr,(1- propscore)/ propscore,1)

	if "`atc'" != "" {
		qui isvar smr`gen'
		if "atc`gen'" == "`r(varlist)'" {
			noi di in red "The variable atc`gen' already exists: unable to proceed."
			exit 100
		}
		else {
			qui gen atc`gen' = `mult' if `touse'
			qui replace atc`gen' = (`mult'-`prop')/`prop' if `treat' == 1 & `touse'
		}
	}

//* gen alt =cond(tr,(1- propscore), propscore)

	if "`alt'" != "" {
		qui isvar fan`gen'
		if "fan`gen'" == "`r(varlist)'" {
			noi di in red "The variable alt`gen' already exists: unable to proceed."
			exit 100
		}
		else {
			qui gen alt`gen' = `mult'*`prop' if `touse'
			qui replace alt`gen' = `mult'-`prop' if `treat' == 1 & `touse'
		}
	}

	noi di as text _n "The following variables were generated:" _cont
	foreach wt in `smr' `ipt' `att' `atc' `alt' {
		noi di as result " `wt'`gen'" _cont
	}
	noi di as text "." _n

end
