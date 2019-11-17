program rmatch, rclass byable(onecall)
*! VersionMarch 28, 2007 @ 17:16:44
*! Author:  Mark Lunt
*! Date:    April 13, 2007 @ 14:21:21


version 8.2

	syntax varlist [if] [in] [,Set(namelist min=1 max=1)  ///
			pwt(namelist min=1 max=1)  ///
			Diff(namelist min=1 max=1) ///
			suffix(string)             ///
			Caliper(numlist max=1)     ///
			LP ]       

	tokenize `varlist'
	local treat `1'
	macro shift
	local prop `1'

	if "`caliper'" == "" {
		local caliper .
	}

	if "`set'" == "" {
		local set set`suffix'
	}

	qui isvar `set'
	if "`set'" == "`r(varlist)'" {
		noi di in red "The variable `set' already exists: unable to proceed."
		exit 100
	}
	
	if "`pwt'" == "" {
		local pwt pwt`suffix'
	}

	qui isvar `pwt'
	if  "`pwt'" == "`r(varlist)'" {
		noi di in red "The variable `pwt' already exists: unable to proceed."
		exit 100
	}

	if "`diff'" == "" {
		local diff diff`suffix'
	}

	qui isvar `diff'
	if  "`diff'" == "`r(varlist)'" {
		noi di in red "The variable `diff' already exists: unable to proceed."
		exit 100
	}

	if "`lp'" == "lp" {
		tempvar nprop
		qui  gen `nprop' = log(`prop'/(1-`prop'))
		local prop `nprop'
	}

	// select data to use
	marksample touse
	local sortvars : sortedby
	local byprefix
	if "`_byvars'" ~= "" {
		local byprefix by `_byvars':
	}
	tempvar orig_order
	gen `orig_order' = _n

	quietly {
		// stratify
		sort `_byvars' `touse' `prop'
		tempvar pless pmore diffl diffm pmatch cases controls tset
		gen `pless' = `prop' if `treat' == 0 & `touse'
		replace `pless' = `pless'[_n-1] if `pless' == . & `touse'
		gsort `_byvars' `touse' - `prop'
		gen `pmore' = `prop' if `treat' == 0 & `touse'
		replace `pmore' = `pmore'[_n-1] if `pmore' == . & `touse'
		`byprefix' gen `diffl'  = abs(`prop' - `pless')
		`byprefix' gen `diffm'  = abs(`prop' - `pmore')
		`byprefix' gen `pmatch' = `pless' if `diffl' < `diffm'
		`byprefix' replace `pmatch' = `pmore' if `pmatch' == .
		`byprefix' replace `pmatch' = . if `touse' & `treat' == 1 & ///
				abs(`prop' - `pmatch') > `caliper'
		egen `tset' = group(`_byvars' `pmatch') if `touse'
		sort `_byvars' `tset'
		by `_byvars' `tset': egen `cases' = sum(`treat') if `touse'
		by `_byvars' `tset': egen `controls' = sum(`treat' == 0)  if `touse'
		gen `pwt' = `cases' / `controls' if `touse'              
		replace `tset' = . if `pwt' == 0
		egen `set' = group(`_byvars' `pmatch') if `tset' ~= .
		gen `diff' = abs(`prop'-`pmatch') if `treat' == 1 & `set' ~= .
		replace `pwt' = 1 if `treat' == 1 & `touse' & `set' ~= .
		replace `pwt' = 0 if `treat' == 1 & `touse' & `set' == .
	}
	sort `orig_order'
	if "`sortvars'" != "" {
		sort `sortvars'
	}
end
