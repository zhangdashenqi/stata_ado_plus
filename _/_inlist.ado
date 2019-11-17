*! _inlist -- does this token appear in this token list?
*! version 1.0.0     Sean Becketti     June 1992                STB-15: sts4
program define _inlist
	version 3.0
	local token "`1'"
	local toklist "`2'"
	mac def S_1=0
	local match=0
	parse "`toklist'", parse(" ")
	while ("`1'"!="" & !`match') {
		local match=`match' | ("`token'"=="`1'")
		mac def S_1=$S_1 + 1
		mac shift
	}
	if (!`match') {mac def S_1=0}
end
