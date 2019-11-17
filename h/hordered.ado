*! 1.0.1  03apr1999  jw/ics
program define hordered, eclass
	version 6.0

	if "`e(cmd)'" ~= "ologit" & "`e(cmd)'" ~= "oprobit" {
		di in re "hordered is valid only after ologit and oprobit"
		exit 198
	}

	syntax [, drop(numlist) join(numlist)]

	if ("`drop'" ~= "" & "`join'" ~= "") | ("`drop'`join'" == "") {
		di in re "drop() or join() should be specified"
		exit 198
	}

	tempname est b
	tempvar touse y

	/*
		extract information from last estimation
	*/

	gen byte `touse' = e(sample)

	local cmd `e(cmd)'
	if "`e(wtype)'" ~= "" {
		local wght "[`e(wtype)'`e(wexp)']"
	}
	if "`e(offset)'" ~= "" {
		local offset "offset(`e(offset)')"
	}
	if "`e(clustvar)'" ~= "" {
		local cluster "cluster(`e(clustvar)')"
	}
	if "`e(vcetype)'" == "Robust" {
		local robust "robust"
	}

	Rhs
	local rhs `r(rhs)'

	* depvar for constrained analysis
	qui gen `y' = `e(depvar)'
	if "`drop'" ~= "" {
		tokenize `drop'
		while "`1'" ~= "" {
			quietly count if `y' == `1'
			if r(N) == 0 {
				local notfnd  "`notfnd' `1'"
			}
			else {
				quietly replace `y' = . if `y' == `1'
			}
			mac shift
		}
		local ctxt "cat dropped"
	}
	else {
		tokenize `join'
		local f `1'
		while "`1'" ~= "" {
			quietly count if `y' == `1'
			if r(N) == 0 {
				local notfnd  "`notfnd' `1'"
			}
			else {
				quietly replace `y' = `f' if `y' == `1'
			}
			mac shift
		}
		local ctxt "cat joined"
	}
	if "`notfnd'" ~= "" {
		di in bl "categories not found: `notfnd'"
	}

	/*
		estimate constrained model and invoke hausman
	*/

	return clear

	tempname b V

	mat `b' = e(b)
	mat `V' = e(V)
	DropCut `b' `V'
	estimates hold `est'
	estimates post `b' `V'
	estimates local cmd `cmd'
	hausman, save

	quietly `cmd' `y' `rhs' if `touse' `wght', `robust' `cluster' `offset'

	mat `b' = e(b)
	mat `V' = e(V)
	DropCut `b' `V'
	estimates post `b' `V'
	estimates local cmd `cmd'
	hausman, less prior("full model") current("`ctxt'")

	estimates unhold `est'
end


program define Rhs, rclass
	tempname b
	mat `b' = e(b)
	local names: colnames `b'
	tokenize `names'
	while "`1'" ~= "" & "`cfound'" ~= "1" {
		if substr("`1'", 1, 4) == "_cut" {
			local cfound 1
		}
		else {
			local rhs "`rhs' `1'"
			mac shift
		}
	}
	return local rhs `rhs'
end

* DropCut removes _cutX parameter estimates from (b,V) from ologit/oprobit
program define DropCut, eclass
	args b V
	local names: colnames `b'
	tokenize `names'
	local i 1
	while `i' <= colsof(`b') & "`cfound'" ~= "1" {
		if substr("``i''", 1, 4) == "_cut" {
			local i = `i'-1
			local cfound 1
		}
		else {
			local i = `i'+1
		}
	}
	mat `b' = `b'[1,1..`i']
	mat `V' = `V'[1..`i',1..`i']
end

