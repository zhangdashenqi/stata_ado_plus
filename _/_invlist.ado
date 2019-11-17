*! _invlist -- does this varname appear in this varlist?
*! version 1.0.0     Sean Becketti     June 1992                STB-15: sts4
program define _invlist
	version 3.0
	local name "`1'"
	mac shift
	if ("`1'"=="") {
		mac def S_1=0
		exit
	}
	local list "`*'"
	parse "`name'", parse(" ")	/* Parse the name */
	local varlist "opt ex"
	cap parse "`*'"
	if (!_rc) {local name "`varlist'"}
	else {conf new v `name'}
	parse "`list'", parse(" ")	/* Parse the list */
	local varlist "req ex"
	cap parse "`*'"
	if (_rc) {
		local varlist "`list'"
		conf new v `varlist'
	}
	_inlist "`name'" "`varlist'"
end
