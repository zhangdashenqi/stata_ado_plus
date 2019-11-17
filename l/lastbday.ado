*! lastbday -- given month and year, returns last business day
*! version 1.0     Sean Becketti     June 1994          STB-20: dm20
program define lastbday
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
		qui lastday `m' `y'
		local d $S_1
		qui mdytodow `m' `d' `y'
		local dow $S_1
		local d = cond(`dow'==0,`d'-2,cond(`dow'==6,`d'-1,`d'))
		qui mnthname `m'
		local mn $S_1
		qui mdytodow `m' `d' `y'
		local dow $S_2		
		global S_1 `d'
		di in ye "`dow', `mn' `d', `y'"
	}
	else {			/* Read vars, gen vars */
		local 1 `m'
		local 2 `y'
		local varlist "req ex min(2) max(2)"
		parse "`*'"
		local m : word 1 of `varlist'
		local y : word 2 of `varlist'
		conf new variable `generat'
		parse "`generat'", parse(" ")
		local d `1'
		if "`2'"!="" { error 198 }
		local mtype : type `m'
		if substr("`mtype'",1,3)=="str" { 
			di in re "month must be numeric"
			error 99
		}
       		qui lastday `m' `y', gen(`d')
		tempvar dow
		qui mdytodow `m' `d' `y', gen(`dow')
		qui replace `d' = cond(`dow'==0,`d'-2,cond(`dow'==6,`d'-1,`d'))
	}
end



