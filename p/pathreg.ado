*! version 2.0 -- 11/8/01 9/3/09 -- pbe -- updated for stata 11
program define pathreg
  version 8
   tempvar touse
   local totvar "`0'"
   local totexp "`0'"
   local totvar = subinstr("`totvar'", "(", " ",.)
   local totvar = subinstr("`totvar'", ")", " ",.)
   mark `touse'
   markout `touse' `totvar'
   display

  while "`totexp'" ~= "" {
    
    gettoken open totexp : totexp, parse("(") 
	if `"`open'"' != "(" {
		error 198
	}
	gettoken next totexp : totexp, parse(")")
	while `"`next'"' != ")" {
		if `"`next'"'=="" { 
			error 198
		}
	  local list `next'
	  gettoken next totexp : totexp, parse(")")
	}
	
	tokenize `list', parse(" :")
	if "`2'"==":" {
		local name "`1'"
		mac shift 2
	}
	/* local totexp `*' */
    local vl1 `varlist'
    regress `list' if `touse', beta noheader
    display _skip(17) in green "n = "  in yellow e(N) in green "  R2 = " in yellow %6.4f e(r2) in green "  sqrt(1 - R2) = " in yellow %6.4f sqrt(1-e(r2))
    display
 }
end

