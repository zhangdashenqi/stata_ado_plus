*! testsum -- test the sum of coefficients against a constant
*! version 1.0.0     Sean Becketti     5/7/92                   STB-15: sts4
program define testsum
	version 3.0
	if ("`*'"=="") {
		di in bl "-> testsum varlist, [Testval(#)]"
		exit
	}
	local varlist "req ex min(1)"
	local options "Testval(real 0)"
	parse "`*'"
	parse "`varlist'", parse(" ")
	local list "`1'"
	local blist "_b[`1']"
	mac shift
	while ("`1'"!="") {
		local list "`list' + `1'"
		local blist "`blist' + _b[`1']"
		mac shift
	}
	test `list' = `testval'
	mac def S_2 = _result(2)
	mac def S_3 = _result(3)
	mac def S_4 = _result(4)
	mac def S_5 = _result(5)
	mac def S_6 = _result(6)
	di "       Sum = " =`blist'
	mac def S_1 = `blist'
end
