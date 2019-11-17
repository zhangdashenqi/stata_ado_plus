*! version 1.0.0 May 7, 2002 @ 09:38:50
*! pushes a new head onto a double-quoted, space delimited list, returns the list
program define _push , sclass
version 7
	sreturn clear

	local head "`1'"
	mac shift

	local list `"`"`head'"'"'

	local cnt 1
	while `"``cnt''"'!="" {
		local list `"`list' `"``cnt''"'"'
		local cnt = `cnt' + 1
		}

	sreturn local list `"`list'"'
end
