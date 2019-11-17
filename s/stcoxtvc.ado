*! 2.0.0  10mar2000  Jeroen Weesie/ICS
program define stcoxtvc
	version 6.0

	st_is 2 full

	if `"`_dta[st_id]'"' == "" {
		di in red /*
		*/ "stcoxtvc requires you have previously stset an id() variable"
		exit 198
	}

	syntax [newvarname] [if] [in] [ , List noPreserve STrata(varlist) ]

	if "`preserv'" == "" {
		preserve
		local Done "restore, not"
	}

	qui count if _st==0
	if r(N) > 0 {
		di in bl r(N) " records with _st==0 are dropped"
		qui keep if _st
	}

	if `"`if'"' != "" | "`in'" != "" {
		local n = _N
		qui keep `if' `in'
		if `n' < _N {
			di in bl =`n'-_N `" records dropped via if/in clauses"'
		}
	}

	if `"`strata'"' != "" {
		tempvar touse
		mark `touse'
		markout `touse' `strata', strok
		qui count if `touse' == 0
		if r(N) > 0 {
			di in bl /*
			*/ r(N) " records dropped with missings in strata (`strata')"
			qui keep if `touse'
		}
		drop `touse'
		local Strata "by(`strata')"
	}

	tempvar event
	local n = _N

	Expand `event' , `list' `Strata'

	if _N > `n' {
		di _n in gr "number of episodes increased from " in ye `n' in gr " to " in ye _N
	}
	else {
		di _n in bl "no episodes generated - likely stcoxtvc was already invoked"
	}

	if "`varlist'" != "" {
		gen `typlist' `varlist' = `event'
	}
	`Done'
end

/* ===========================================================================
   subroutines
   ===========================================================================
*/


/* Expand newvar [, List by(varlist)]
   splits the epsiodes at all time points at which a failure occurs.
   some code suggestions taken from st_rpool: version 1.1.0 15jan1999
*/
program define Expand
	syntax newvarname [, List by(varlist) ]
	local event `varlist'

	* determine the failure times T()
   * leave data in order so that the failure times T[1]<T[2]<..T[nevent]
   * are in the first nevent observations
	quietly {
		if "`by'" != "" {
			local nby : word count `by'
			if `nby' > 1 {
				tempvar s
				egen `s' = group(`by'), missing
				compress `s'
				local by `s'
			}
		}

		sort `by' _t _d
		by `by' _t : gen `event' = cond(_n==_N & _d!=0, -1, .)
		sort `event' `by' _t
		count if `event' == -1
		local nevent = _result(1)
		local nobs = _N
		tempvar T
		gen `T' = _t
	}

	di in gr "`nevent' failure times"
	if "`list'" != "" {
		local lsize : set display linesize
		local ncol = int((`lsize'-1)/9)
		local ev 1
		while `ev' <= `nevent' {
			di %9.0g _t[`ev'] _c
			local ev = `ev' + 1
			if mod(`ev'-1,`ncol')==0 { di }
		}
		if mod(`ev'-1,`ncol')!=1 { di }
	}

	quiet {
		* perform episode at failure time, from latest to earliest
		* failure time.
		tempvar sp
		local ev = `nevent'
		while `ev'  > 0 {
			local nobs1 = _N + 1
			if "`by'" == "" {
				gen byte `sp' = _t0 < `T'[`ev'] & _t > `T'[`ev'] in 1/`nobs'
			}
			else {
				* resist temptation to use macro fiddling to optionally add
				* by() - clause in last expression
				gen byte `sp' = _t0 < `T'[`ev'] & _t > `T'[`ev'] /*
					*/ & `by'==`by'[`ev'] in 1/`nobs'
			}

			count if `sp'==1
			if r(N) > 0 {
				expand 2 if `sp'==1
				replace `event' = `ev' in `nobs1'/l
				* newly created (censored) epsiodes are marked by _d==-1
				replace _d      = -1 if `sp'==1 in 1/`nobs'
				replace _t      = `T'[`ev'] if `sp'==1 in 1/`nobs'
				replace _t0     = `T'[`ev'] in `nobs1'/l
			}
			drop `sp'
			local ev = `ev' - 1
		}

		* adjust user variables
		IsVar `_dta[st_bd]'
		if `s(exists)' {
			replace `_dta[st_bd]' = . if _d==-1
		}
		* reset _d in newly created censored episodes
		replace _d = 0 if _d == -1
		IsVar `_dta[st_bt]'
		if `s(exists)' {
			replace `_dta[st_bt]' = _t * `_dta[st_s]' + `_dta[st_o]'
		}
		IsVar `_dta[st_bt0]'
		if `s(exists)' {
			replace `_dta[st_bt0]' = _t0 * `_dta[st_s]' + `_dta[st_o]'
		}
	}
end


/* IsVar vname
   returns in s(exist) whether vname is an existing variable
	copied from stsplit (1.0.3)
*/
program define IsVar, sclass
	nobreak {
		capture confirm new var `1'
		if _rc {
			capture confirm var `1'
			if _rc==0 {
				sret local exists 1
				exit
			}
		}
	}
	sret local exists 0
end
exit


/* Expand newvar [, List ]
   splits the epsiodes at all time points at which a failure occurs.
   some code suggestions taken from st_rpool: version 1.1.0 15jan1999
*/
program define Expand
	syntax newvarname [, List]
	local event `varlist'

	* determine the failure times T()
   * leave data in order so that the failure times T[1]<T[2]<..T[nevent]
   * are in the first nevent observations
	quietly {
		sort _t _d
		by _t : gen `event' = cond(_n==_N & _d!=0, -1, .)
		sort `event' _t
		count if `event' == -1
		local nevent = _result(1)
		local nobs = _N
		tempvar _T
		gen `T' = _t
	}

	if "`list'" != "" {
		di in gr "failure times "
		local lsize : set display linesize
		local ncol = int((`lsize'-1)/9)
		local ev 1
		while `ev' <= `nevent' {
			di %9.0g _t[`ev'] _c
			local ev = `ev' + 1
			if mod(`ev'-1,`ncol')==0 { di }
		}
		if mod(`ev'-1,`ncol')!=1 { di }
	}

	quiet {
		* perform episode at failure time, from latest to earliest failure time
		tempvar sp
		local ev = `nevent'
		while `ev'  > 0 {
			local nobs1 = _N + 1
			gen byte `sp' = _t0 < `T'[`ev'] & _t > `T'[`ev'] in 1/`nobs'
			count if `sp'==1
			if r(N) > 0 {
				expand 2 if `sp'==1
				replace `event' = `ev' in `nobs1'/l
				* newly created (censored) epsiodes are marked by _d==-1
				replace _d      = -1 if `sp'==1 in 1/`nobs'
				replace _t      = `T'[`ev'] if `sp'==1 in 1/`nobs'
				replace _t0     = `T'[`ev'] in `nobs1'/l
			}
			drop `sp'
			local ev = `ev' - 1
		}

		* adjust user variables
		IsVar `_dta[st_bd]'
		if `s(exists)' {
			replace `_dta[st_bd]' = . if _d==-1
		}
		* reset _d in newly created censored episodes
		replace _d = 0 if _d == -1
		IsVar `_dta[st_bt]'
		if `s(exists)' {
			replace `_dta[st_bt]' = _t * `_dta[st_s]' + `_dta[st_o]'
		}
		IsVar `_dta[st_bt0]'
		if `s(exists)' {
			replace `_dta[st_bt0]' = _t0 * `_dta[st_s]' + `_dta[st_o]'
		}
	}
end

/* Expand newtype newvar stratavars
   risk-set expansion, with stratification on stratavars
*/
program define Expands
	args evtype event
	mac shift 2
	local by "`*'"

	local n : word count `by'
	if `n' > 1 {
		tempvar s
		quietly {
			egen `s' = group(`by'), missing
			compress `s'
		}
		local by "`s'"
	}

	sort `by' _t _d
	by `by' _t : gen `evtype' `event' = cond(_n==_N & _d!=0, -1, .)
	sort `event' `by' _t
	count if `event' == -1
	local nevent = _result(1)
	local nobs = _N
	local ev 1
	while `ev' <= `nevent' {
		local nobs1 = _N + 1
		expand 2 if _t0<_t[`ev'] & _t>=_t[`ev'] & /*
			*/ `by'==`by'[`ev'] in 1/`nobs'
		replace `event' = `ev' in `nobs1'/l
		replace _d = 0 if _t>_t[`ev'] in `nobs1'/l
		local ev = `ev' + 1
	}
	drop if `event'==-1 | `event'==.
end

