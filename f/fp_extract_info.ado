program define fp_extract_info, rclass
version 12
/*
	Extracts FP powers, scale and center info from a variable.
	This variable is the first FP variable, since info for other powers
	comes from the notes for the first variable.
*/
syntax varname
notes _count nn : `varlist'
if `nn' == 0 {
	// no notes found for `varlist'
	return scalar hasnotes = 0
	exit
}
local phr1 fp term 1
local phr2 Scaling was
local phr3 Centering was
forvalues n = 1/`nn' {
	notes _fetch thisnote : `varlist' `n'
	// `j' indexes types of phrase in the notes
	forvalues j = 1/3 {
		if strpos(`"`thisnote'"', "`phr`j''") > 0 {
			if `j' == 1 {
				// extract powers by matching on paren
				gettoken stuff thisnote : thisnote, parse("()") match(par)
				gettoken powers thisnote : thisnote, parse("()") match(par)
			}
			if `j' == 2 {
				// extract a and b
				tokenize `thisnote'
				while "`1'"!="" {
					if (substr("`1'", 1, 2) == "a=") local a = substr("`1'", 3, .)
					if (substr("`1'", 1, 2) == "b=") local b = substr("`1'", 3, .)
					mac shift
				}
			}
			if `j' == 3 {
				// extract centering (c) on original scale
				tokenize "`thisnote'", parse("=")
				while "`1'"!="" {
					if "`1'" == "=" {
						mac shift
						local c `1'
						// Trim trailing "." if present
						if "`c'"!="" & substr("`c'", -1, 1) == "." {
							local c = substr("`c'", 1, length("`c'")-1)
						}
					}
					mac shift
				}
			}
		}
	}
}
// If powers not found then notes are not relevant to -fp-
if "`powers'" == "" {
	return scalar hasnotes = 0
}
else {
	if ("`a'" == "") local a 0
	if ("`b'" == "") local b 1
	if ("`c'" == "") local c .
	return local powers `powers'
	return scalar a = `a'
	return scalar b = `b'
	return scalar c = `c'
	return scalar hasnotes = 1
}
end

