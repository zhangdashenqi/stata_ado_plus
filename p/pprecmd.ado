*! Version 1.0.0  07Jan1999  Jeroen Weesie/ICS  (STB-52 sg121)
program define pprecmd
	version 6.0

	* parse off names of return macros
	gettoken a 0 : 0, parse(" :")
	gettoken b 0 : 0, parse(" :")
	gettoken colon 0 : 0, parse(" :")
	if `"`colon'"' != ":" { error 198 }

	* parse input 0 into  pcmd : cmd
	gettoken token cmd : 0, parse(" :") quotes
	while `"`token'"' ~= ":" & `"`token'"' ~= "" {
		local pcmd `"`pcmd'`token' "'
		gettoken token cmd : cmd, parse(" :") quotes
	}
	*di `"pcmd |`pcmd'|"'
	*di `"cmd  |`cmd'|"'

	* return results in locals of calling command
	* this is a dangerous construct!
	c_local `a' `pcmd'
	c_local `b' `cmd'
end
exit

pprecmd pre_c post_c: input

splits the string input into part (returned in local macro pre_c) before the colon
and after the colon (returned in the local macro post_c). If the input does not
contain a colon (or colon's are embedded in quotes) all input is returned in pre_c.

Bill Gould looked through the code, and "gave his blessings", apart from a sour
note on my use of c_local, which he, rightly, described as a "loaded gun".


