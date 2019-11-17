*! ystrday -- m/d/y of yesterday from m/d/y of today
*! version 1.0     Sean Becketti     June 1994          STB-20: dm20
program define ystrday
        version 3.1
	if "`1'"=="" {
		qui today
		local m $S_1
		local d $S_2
		local y $S_3
	}
	else {
        	local m `1'
		mac shift
        	local d `1'
		mac shift
        	local y `1'
		mac shift
	}
/*
	Check for comma attached to token #3
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
        	conf integer n `d'
        	conf integer n `y'
		if `d'==1 {
			local m = `m' - 1
			if `m'==0 {
				local m 12
				local d 31
				local y = `y' - 1
			}
			else {
				qui lastday `m' `y'
				local d $S_1
			}
	        }
		else { local d = `d' - 1 }
		qui mnthname `m'
		local mname $S_1
		global S_1 `m'
		global S_2 `d'
		global S_3 `y'
		di in ye "`mname' `d', `y'"
	}
	else {			/* Read vars, gen vars */
		local 1 `m'
		local 2 `d'
		local 3 `y'
		local varlist "req ex min(3) max(3)"
		parse "`*'"
		local m : word 1 of `varlist'
		local d : word 2 of `varlist'
		local y : word 3 of `varlist'
		conf new variable `generat'
		local ym : word 1 of `generat'
		local yd : word 2 of `generat'
		local yy : word 3 of `generat'
		local mtype : type `m'
		if substr("`mtype'",1,3)=="str" { 
			di in re "month must be numeric"
			error 99
		}
		local dtype : type `d'
		local ytype : type `y'
		gen `mtype' `ym' = `m'
		gen `ytype' `yy' = `y'
       		gen `dtype' `yd' = `d' - 1
		qui replace `ym' = cond(`ym'==1,12,`ym'-1) if `yd'==0
		qui replace `yy' = `yy' - 1 if `yd'==0 & `ym'==12
		tempvar ndays
		lastday `ym' `yy', gen(`ndays')
		qui replace `yd' = `ndays' if `yd'==0
	}
end


