*! version 1.0, 14th November 2002                              (SJ4-1: st0057)

program define xcolnames, rclass 
	version 7
	
	tokenize "`0'", parse(,)
	local com `1'
	local head `3'
	tokenize "`com'"
	tokenize "`head'", parse("()")
	local eqhead `3'
	mat h = `com'
	local names : colnames(h)
	local i : word count `names'
	local j = 1
	while `j' <= `i' {
			gettoken v`j' names : names
			local v`j' `eqhead':`v`j''
			local j = `j'+1
			}
	local j = 2
	local names2 `v1'
	while `j' <= `i' {
			 local names2 "`names2' `v`j''"
			 local j = `j' +1
			 }
	mat colnames `com' = `names2'
	mat drop h
end
exit
