*! version 1.0.0 PR 09Feb2001.  (TSJ-1: st0001)
program define bhcalc
version 6
syntax newvarname =/exp [if] [in] [, STrata(varname) Time(varname) Dead(varname) Fill ]
if "`fill'"!="" {
	di in red "fill option not yet available"
	exit 198
}
local stis 0
if "`time'`dead'"=="" {
	st_is 2 analysis
	local stis 1
}
if "`time'"=="" {local time _t }
if "`dead'"=="" { local dead _d }
local H `exp'
local by `strata'
confirm var `time'
confirm var `dead'
tempvar touse tie h
quietly {
	mark `touse' `if' `in'
	markout `touse' `time' `dead' `H' `strata'
	if `stis' {
		replace `touse'=0 if _st==0
	}
	sort `touse' `by' `dead' `time'
/*
	Calculate tie lengths
*/
	by `touse' `by' `dead' `time': gen long `tie'=_n if `touse'
/*
	Calc baseline hazard function.
	Data are sorted in order of deaths then unique failure times.
*/
	sort `touse' `by' `dead' `tie' `time'
	by `touse' `by' `dead' `tie':gen `h'=cond(_n==1,`H'/`time', /*
	 */ (`H'-`H'[_n-1])/(`time'-`time'[_n-1])) /*
	 */ if `touse' & `dead'==1 & `tie'==1
/*
	Fill in missing hazard values within sets of tied times
*/
	sort `touse' `by' `dead' `time' `tie'
	by `touse' `by' `dead' `time': replace `h'=`h'[1] /*
	 */ if `touse' & `dead'==1 & `tie'>1
	rename `h' `varlist'
}
end
