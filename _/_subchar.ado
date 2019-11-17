*! _subchar -- replace one character with another in a string
*! version 1.0.0     Sean Becketti     July 1992                STB-15: sts4
*  Warning: This program will not handle macro expansion characters correctly.
program define _subchar
	version 3.0
	mac def S_1
	if (length("`1'")!=1 | length("`2'")!=1) {error 99}
	local oldchar "`1'"
	local newchar "`2'"
	local instr "`3'"
	local len=length("`instr'")
	local i=0
	while (`i'<`len') {
		local i=`i'+1
		local char=substr("`instr'",`i',1)
		if ("`char'"=="`oldchar'") {local char "`newchar'"}
		local outstr="`outstr'"+"`char'"
/*
	Handle the anomalous way macro define handles blanks.
*/
		if (length("`char'")==0) {local outstr "`outstr' "}
	}
	mac def S_1 "`outstr'"
end
