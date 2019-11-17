*! namemnth -- Map month name to code
*! version 1.0     Sean Becketti     June 1994          STB-20: dm20
program define namemnth
	version 3.1
	local mname `1'
	mac shift
        if "`mname'"=="" { exit 198 }
	local mn = substr(lower("`mname'"),1,3)
/*
	Check for comma attached to token #2
*/
	local j = index("`mname'",",")
	if `j' {
		local s = substr("`mname'",`j',.)
		local 1 "`s' `1'"
		local j = `j' - 1
		if `j'<=0 { error 99 }
		local mname = substr("`mname'",1,`j')
	}
	local options "Generate(str)"
	parse "`*'"
      	if "`generat'"=="" {	/* Immediate form */
		local mn = substr(lower("`mname'"),1,3)
		if      "`mn'"=="jan" { local m =  1 }
		else if "`mn'"=="feb" { local m =  2 }
		else if "`mn'"=="mar" { local m =  3 }
		else if "`mn'"=="apr" { local m =  4 }
		else if "`mn'"=="may" { local m =  5 }
		else if "`mn'"=="jun" { local m =  6 }
		else if "`mn'"=="jul" { local m =  7 }
		else if "`mn'"=="aug" { local m =  8 }
		else if "`mn'"=="sep" { local m =  9 }
		else if "`mn'"=="oct" { local m = 10 }
		else if "`mn'"=="nov" { local m = 11 }
		else if "`mn'"=="dec" { local m = 12 }
		else {
			di in re "unknown month: `mname'"
			exit 99
		}
		global S_1 `m'
	}
	else {			/* Read var, gen var */
		conf string v `mname'
		parse "`generat'", parse(" ")
		local month "`1'"
		if "`2'"!="" { error 198 }
		conf new v `month'
		tempvar m
		qui gen str3 `m' = lower(`mname')
		gen int `month' = cond(`m'=="jan",1,cond(`m'=="feb",2,cond(`m'=="mar",3,cond(`m'=="apr",4,cond(`m'=="may",5,cond(`m'=="jun",6,cond(`m'=="jul",7,cond(`m'=="aug",8,cond(`m'=="sep",9,cond(`m'=="oct",10,cond(`m'=="nov",11,cond(`m'=="dec",12,.))))))))))))
end




