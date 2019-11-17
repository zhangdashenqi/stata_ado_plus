*! v 1.0.2 PR 10sep2013
program define cmpute
version 8.0
gettoken type 0 : 0, parse("= ") bind
// Process putative type (copes with strL)
local typelist byte int long float double
if _caller() >= 13 {
	local typelist `typelist' strL
}
local ok 0
foreach t of local typelist {
	if "`t'" == "`type'" {
		local ok 1
		continue, break
	}
}
if !`ok' {
	if substr("`type'", 1, 3) == "str" {
		local strn = substr("`type'", 4, .)
		confirm integer number `strn'
		local ok 1
	}
}
if !`ok' {
	local newvar `type'
	local type
}
else gettoken newvar 0 : 0, parse("= ") bind
gettoken eqs 0 : 0, parse("= ")
if "`eqs'" != "=" {
	di "{p}{err}syntax is {cmd:cmpute [{it:type}] {it:existing_var}|{it:newvar} = {it:exp}}" ///
	 " [, {cmd:replace} {cmd:force} {cmd:label(}{it:label}{cmd:)}]{p_end}"
	 exit 198
}
gettoken Exp 0 : 0, parse(", ") bind
syntax [if] [in] [, replace LABel(string) force ]
if "`type'" != "" {
	local ok 0
	foreach t of local typelist {
		if "`t'" == "`type'" {
			local ok 1
			continue, break
		}
	}
	if !`ok' {
		if substr("`type'", 1, 3) == "str" {
			local strn = substr("`type'", 4, .)
			confirm integer number `strn'
			local ok 1
		}
	}
	if !`ok' {
		di as err "type `type' not recognized"
		exit 198
	}
}
capture confirm var `newvar', exact
local rc = c(rc)
if `rc' != 0 {
	// `newvar' does not exist; safe to create it from `Exp'
	generate `type' `newvar' = `Exp' `if' `in'
}
else {
	// `newvar' exists
	if "`replace'" != "" {
		// safe to recreate `newvar'
		replace `newvar' = `Exp' `if' `in'
		if "`type'" != "" {
			recast `type' `newvar', `force'
		}
	}
	else {
		di as err "`newvar' already defined"
		exit 110
	}
}
if "`label'" != "" {
	label var `newvar' "`label'"
}
end
