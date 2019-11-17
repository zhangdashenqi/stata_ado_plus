*! today -- Place today's month, day, and year (numeric) in S_1-S_3
*! version 1.0     Sean Becketti     June 1994          STB-20: dm20
program define today
        version 3.1

	local d  : word 1 of $S_DATE
	local mn : word 2 of $S_DATE
	local y  : word 3 of $S_DATE

	local options "Generate(str)"
	parse "`*'"
	if      "`mn'"=="Jan" { local m  1 }
	else if "`mn'"=="Feb" { local m  2 }
	else if "`mn'"=="Mar" { local m  3 }
	else if "`mn'"=="Apr" { local m  4 }
	else if "`mn'"=="May" { local m  5 }
	else if "`mn'"=="Jun" { local m  6 }
	else if "`mn'"=="Jul" { local m  7 }
	else if "`mn'"=="Aug" { local m  8 }
	else if "`mn'"=="Sep" { local m  9 }
	else if "`mn'"=="Oct" { local m 10 }
	else if "`mn'"=="Nov" { local m 11 }
	else if "`mn'"=="Dec" { local m 12 }
	qui mnthname `m'
	local mname $S_1
	global S_1 `m'
	global S_2 `d'
	global S_3 `y'
	if "`generat'"=="" {	/* Immediate form */
		di in ye "`mname' `d', `y'"
	}
	else {			/* Read vars, gen vars */
		local 1 `m'
		local 2 `d'
		local 3 `y'
		conf new variable `generat'
		local ym : word 1 of `generat'
		local yd : word 2 of `generat'
		local yy : word 3 of `generat'
		gen byte `ym' = `m'
		gen int `yy' = `y'
       		gen byte `yd' = `d'
	}
end


