*! _gmtr -- calculate marginal tax rates for egen       (sss1.1: STB-22)
*! version 1.1.0     September 1994     Timothy J. Schmidt
program define _gmtr
	version 3.1
/*
	Grab the variables before parsing "if" and "in".
*/
	local type `1'
	mac shift
	local mtr `1'
	mac shift
	mac shift			/* the "=" */
	if "`1'"!="(" { exit 198 }
	mac shift			/* the "(" */
	local i = index("`1'",",") 
	if `i' {			/* user typed "mtr(year,income)" */
		if `i'==1 { exit 198 }		/* no year before "," */
		local year = substr("`1'",1,`i'-1)
		local 1 = substr("`1'",`i'+1,.)
	}
	else {				/* user typed "mtr(year income)" */
		local year `1'
		mac shift
	}
	local i = index("`1'",")")
	if !`i' { exit 198 } 		/* no ")" */
	if `i'<2 { exit 198 } 	/* no income */
	local inc = substr("`1'",1,`i'-1)
	mac shift
/*
	Parse the "if" and "in".
*/
	local if "opt pre"
	local in "opt pre"
	parse "`*'"
	quietly {
		tempvar touse
		mark `touse' `if' `in'
/*
	Is year a variable or a constant?
*/
		cap conf var `year'
		if !_rc { local yname `year' }
/*
	Is (income == 0)?  If so, make it one dollar.
*/
		cap conf var `inc'
		if !_rc { local inctype : type `inc' }
		tempvar income
		gen `inctype' `income' = cond(`inc',`inc',1)
		markout `touse' `yname' `income'
		_crcnuse `touse'
		local N $S_1
		local first=$S_3
		local last=$S_4
		local in "in `first'/`last'"
		local ifgaps=$S_2
		if `ifgaps' { local if "if `touse'" }
		else { local if }
		global S_1 `mtr'
		global S_2 `year'
		global S_3 `income'
		global S_4 `if'
		global S_5 `in'
		gen `type' `mtr' = . $S_4 $S_5
		_tx_mtr1
		_tx_mtr2
		_tx_mtr3
		_tx_mtr4
		_tx_mtr5
	}
end

