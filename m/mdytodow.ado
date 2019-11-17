*! mdytodow -- day of week from month day year
*! version 1.0     Sean Becketti     June 1994          STB-20: dm20
program define mdytodow
        version 3.1
        local m `1'
	mac shift
        local d `1'
	mac shift
        local y `1'
	mac shift
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
                if `m'<1 | `m'>12 {
			di in re "illegal month: `m'"
			exit 99
		}
		if `d'<1 | `d'>31 {
			di in re "illegal day: `d'"
			exit 99
		}
	        local Exp "int(((`m')-14)/12)"
		local e	= (`d') - 2469010 + int(1461*((`y')+4800+`Exp')/4) + int(367*((`m')-2-`Exp'*12)/12) - int(3*int(((`y')+4900+`Exp')/100)/4)
		local dow = cond((`e')+5==0,0,cond((`e')>=0,mod((`e')+5,7),6-mod(abs(`e')+8,7)))
		qui downame `dow'
		global S_4 $S_3
		global S_3 $S_2
		global S_2 $S_1
		global S_1 `dow'
		di in ye "$S_2"
	}
	else {			/* Read vars, gen vars */
		tempname evar
		mdytoe `m' `d' `y', gen(`evar')
		etodow `evar', gen(`generat')
	}
end


