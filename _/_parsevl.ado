*! __parsevl -- parse a varlist to replace abbreviations
*! version 1.0.0     Sean Becketti     July 1989                STB-15: sts4
program define _parsevl
	version 3.0
        local varlist "opt ex"
	parse "`*'"
        mac def S_1 "`varlist'"
end
