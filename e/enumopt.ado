*! version 1.0.1  3okt1999  jw/ics  (STB-53: dm75)
program define enumopt, rclass
	version 6
	args input spec optname

	if `"`spec'"' == "" | `"`optname'"' == "" {
		exit 198
	}

	tokenize `"`spec'"'
	if `"`1'"' == "." {
		* defualt is empty
		mac shift
	}
	else {
		local dflt = lower(`"`1'"')
	}

	if `"`input'"' == "" {
		return local option `dflt'
		exit
	}

	local len = length(`"`input'"')
	while `"`1'"' != "" {
		local l1 = lower(`"`1'"')
		if `"`l1'"' == `"`1'"' {
			* all lower-case values should match fully
			local lf = length(`"`1'"')
		}
		else {
			FirstLow `"`1'"'
			local lf = `r(index)'-1
		}
		if `"`input'"' == substr(`"`l1'"', 1, max(`len',`lf')) {
			return local option `"`l1'"'
			exit
		}
		mac shift
	}
	di in re `"`input' invalid for `optname'(`spec')"'
	exit 198
end


/* FirstLow str
   returns in r(index) the index of the first lowercase char in str,
   or length(str)+1 otherwise
*/
program define FirstLow, rclass
	args str

	local i 1
	while `i' <= length(`"`str'"') {
		local c = substr(`"`str'"', `i', 1)
		if "`c'" == upper("`c'") {
			local i = `i'+1
		}
		else {
			return local index `i'
			exit
		}
	}
	return local index `i'
end
