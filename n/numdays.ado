*! numdays -- Number of days in month/year
*! version 1.0     Sean Becketti     June 1994          STB-20: dm20
program define numdays
	version 3.1
	local m `1'
	mac shift
	local y `1'
	mac shift
/*
	Check for comma attached to token #2
*/
	local j = index("`y'",",")
	if `j' {
		local s = substr("`y'",`j',.)
		local 1 "`s' `1'"
		local j = `j' - 1
		if `j'<=0 { error 99 }
		local y = substr("`y'",1,`j')
	}
	local options "Generate(str)"
	parse "`*'"
	if "`generat'"=="" {	/* Immediate form */
	        conf integer n `m'
        	conf integer n `y'
		if `m'<1 | `m'>12 {
			di in re "month out of range: `m'"
			global S_1 .
			error 99
		}
		if `m'==2 {
			local leap = (4*int(`y'/4)==`y') & ((100*int(`y'/100)!=`y') | (400*int(`y'/400)==`y'))
		        local ndays = cond(`leap',29,28)
		}
		else if (`m'==4) | (`m'==6) | (`m'==9) | (`m'==11) { local ndays 30 }
		else { local ndays 31 }
		global S_1 `ndays'
	}
	else {			/* Read vars, gen vars */
		local 1 `m'
		local 2 `y'
		local varlist "req ex min(2) max(2)"
		parse "`*'"
		local m : word 1 of `varlist'
		local mtype : type `m'
		if substr("`mtype'",1,3)=="str" { 
			di in re "month must be numeric"
			error 99
		}
		local y : word 2 of `varlist'
		conf new variable `generat'
		local ndays `generat'
		tempvar leap
		gen byte `leap' = (4*int(`y'/4)==`y') & ((100*int(`y'/100)!=`y') | (400*int(`y'/400)==`y'))
		gen int `ndays' = cond((`m'<1)|(`m'>12),.,cond(`m'==2,cond(`leap',29,28),cond(((`m'==4)|(`m'==6)|(`m'==9)|(`m'==11)),30,31)))
	}
end
