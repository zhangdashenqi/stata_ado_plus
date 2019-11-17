*! csunits -- set or display the variables that identify cross-sectional units
*  version 1.0     Sean Becketti     September 1994     STB-21: sts7.4
program define csunits
	version 3.1
	local csvars "`*'"
	local j = index("`1'",",")
	while !`j' & "`1'"!="" {	/* drop up to comma */
		mac shift
		local j = index("`1'",",")
	}
	if `j' {			/* comma present, parse options */
		local 1 = substr("`1'",`j',.)
		local options "Clear"
		parse "`*'"
	}
	if "`clear'"!="" {		/* clear old definition */
		global S_X_unit
		global S_1
		exit
	}
	else if "`csvars'"=="" {	/* query, what is the definition? */
		if "$S_X_unit"=="" { di in gr "No cross-sectional units defined" }
		else { di "$S_X_unit" }
	}
	else { 				/* new definition */
		cap _parsevl `csvars'
		if !_rc { local csvars "$S_1" }
		else { conf new variable `csvars' }
	}
	global S_X_unit "`csvars'"
	parse "$S_X_unit", parse(" ")
	local i 1
	while "``i''"!="" {
		global S_`i' ``i''
		local i = `i' + 1
	}
end



