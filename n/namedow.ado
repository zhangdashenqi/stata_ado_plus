*! namedow -- Map day name to code
*! version 1.0     Sean Becketti     June 1994          STB-20: dm20
program define namedow
	version 3.1
	local dname `1'
	mac shift
	if "`dname'"=="" { error 99 }
/*
	Check for comma attached to token #2
*/
	local j = index("`dname'",",")
	if `j' {
		local s = substr("`dname'",`j',.)
		local 1 "`s' `1'"
		local j = `j' - 1
		if `j'<=0 { error 99 }
		local dname = substr("`dname'",1,`j')
	}
	local options "Generate(str)"
	parse "`*'"
      	if "`generat'"=="" {	/* Immediate form */
		local dn = substr(lower("`dname'"),1,3)
		if      "`dn'"=="sun" { local d = 0 }
		else if "`dn'"=="mon" { local d = 1 }
		else if "`dn'"=="tue" { local d = 2 }
		else if "`dn'"=="wed" { local d = 3 }
		else if "`dn'"=="thu" { local d = 4 }
		else if "`dn'"=="fri" { local d = 5 }
		else if "`dn'"=="sat" { local d = 6 }
		else {
			di in re "unknown day: `dname'"
			exit 99
		}
		global S_1 `d'
	}
	else {			/* Read var, gen var */
		conf string v `dname'
		parse "`generat'", parse(" ")
		local day "`1'"
		if "`2'"!="" { error 198 }
		conf new v `day'
		tempvar d
		qui gen str3 `d' = lower(`dname')
		gen int `day' = cond(`d'=="sun",0,cond(`d'=="mon",1,cond(`d'=="tue",2,cond(`d'=="wed",3,cond(`d'=="thu",4,cond(`d'=="fri",5,cond(`d'=="sat",6,.)))))))
	}
end
