*! version 1.1.0  23oct2001
*! Written by: Jeff Pitblado
program define hist2, rclass
	version 7
	syntax varname [fw aw iw pw] [if] [in] /*
		*/ [, /*
		*/ AT(numlist max=1) /*
		*/ Bin(numlist integer max=1 >0) /*
		*/ BWidth(numlist max=1 >0) /*
		*/ * /*
		*/ ] /*
		*/
	local x `varlist'

	marksample touse `if' `in'
	tempvar xc

	if "`weight'" != "" {
		if "`weight'" == "pweight" | "`weight'" == "iweight" {
			local weight aweight
		}
		local wgt [ `weight'`exp' ]
	}

	if "`at'`bin'`bwidth'" == "" {
		qui sum `x' if `touse', mean
		local at = r(min)
		local xmax = r(max)
		local bin = 5
		local bwidth = (`xmax'-`at')/`bin'
		graph `x' `wgt' if `touse', bin(`bin') `options'
	}
	else {
		qui sum `x' if `touse', mean
		local xmax = r(max)
		if "`at'" == "" {
			local at = r(min)
		}
		if "`bin'`bwidth'" == "" {
			local bin 5
		}
		else if "`bwidth'" == "" & "`bin'" != ""{
			local bwidth = (`xmax'-`at')/`bin'
		}
		else if "`bin'" == "" & "`bwidth'" != ""{
			local xmax = `xmax'+.5*`bwidth'
			local bin = int((`xmax'-`at')/`bwidth')
		}
		else {
			local xmax = `at'+`bin'*`bwidth'
		}
		qui egen `xc' = cut(`x') if `touse', /*
			*/ at(`at'(`bwidth')`xmax')
		local lbl : variable label `x'
		if "`lbl'" == "" {
			local lbl `x'
		}
		label var `xc' `"`lbl'"'
		graph `xc' `wgt' if `touse', /*
			*/ bin(`bin') /*
			*/ xlab(`at'(`bwidth')`xmax') /*
			*/ `options' /*
			*/
	}
	return local bwidth `bwidth'
	return local bin `bin'
	return local at `at'
end

exit

------------------------------------------------------------------------------
NOTES
------------------------------------------------------------------------------

*?	- unclear what to do
*c	- yet to be checked
*r	- remove later

<end>
