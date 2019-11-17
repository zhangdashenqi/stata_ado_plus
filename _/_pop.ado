*! version 1.0.0 May 7, 2002 @ 09:58:30
*! pops the head off a double-quoted, space delimited list, returns head and tail
program define _pop , sclass
version 7
	sreturn clear
	local theList `"`*'"'

	local head `"`1'"'
	sreturn local head `"`head'"'

	if `"`2'"' !="" {
		mac shift
		local tail `"`"`1'"'"'
		local cnt 2
		while "``cnt''"!="" {
			local tail `"`tail' `"``cnt''"'"'
			local cnt = `cnt' + 1
			}
		sreturn local tail `"`tail'"'
		}
	
end
