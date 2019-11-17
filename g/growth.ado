*! growth -- calculate growth rate
*! version 6.0.0	23dec1988	(www.stata.com/users/becketti/tslib)
*
*  3.0.3     7/23/92    changed "p(#)" to "p[#]" in variable label, SRB
*  3.0.2     7/9/92     fixed label bug with "percent" option, SRB
*  3.0.1     7/2/92     fixed name collision bug, SRB
* 
program define growth
	version 3.0
	capture confirm integer number `1'
	local varlist "req ex min(1) max(1)"
	local options "noAnnual Log Ma(int 1) Percent PERIod(str) Suffix(str)"
	parse "`*'"
	if `ma'<1 {
		di in red "ma() must be positive"
		exit 198
	}

	_ts_peri `period'		/* obtain # of periods per "year" */
	local period=cond("`annual'"!="",1,$S_1)

	local f100=cond("`percent'"!="",100,1)
	local pwr=`period'/`ma'

	if ("`suffix'"=="") { local suffix "`varlist'" }
	local addper = index("`suffix'","_")==0
	local prefix "G"
	if (`addper') { local prefix "`prefix'_" }
	local name = substr("`prefix'`suffix'",1,8)

	local v `varlist'
	local lbl "`prefix'`v'"
	if `ma'!=1 { local lbl "`lbl' ma(`ma')" }
	if `period'!=1 { local lbl "`lbl' p[`period']" }
	if "`log'"!="" { local lbl "`lbl' log" }
	if "`percent'"!="" { local lbl "%``lbl'" }
/*
	Bug fix, 7/9/92, SRB

	The line above used to read:

	if "`percent'"!="" { local lbl "%`lbl'" }

	This used to eat up the "G" operator in the label.

*/

	tempvar res
	quietly { 
		if ("`log'"!="") {
			gen float `res'=`f100'*`pwr'* /* 
					*/ (ln(`v')-ln(`v'[_n-`ma']))
		}
		else {
			gen float `res' = `f100'*((`v'/`v'[_n-`ma'])^`pwr'-1)
		}
	}
	label var `res' "`lbl'"
/*
	Bug fix, 7/2/92, SRB

	The following two lines used to read:

		capture confirm var `name'
		if (_rc==0) {

	but this allowed for name collisions with abbreviation.
*/
	capture _parsevl `name'
	if (!_rc & "`name'"=="$S_1") {
		di in blu "(`name' replaced)"
		drop `name'
	}
	rename `res' `name'
end
