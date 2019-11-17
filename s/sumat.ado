*! Part of package matrixtools v. 0.2
*! Support: Niels Henrik Bruun, nhbr@ph.au.dk
*! 2016-08-24 >	Option hide added
* TOTEST labels as option
* TODO colby
* TODO proportion ci ?
* TODO meta data statistics - integer booleans?

program define sumat, rclass
	version 12.1
	syntax varlist [if] [in] [using], /*
		*/STATistics(string)/*
		*/[/*
			*/coleq(string)/*
			*/roweq(string)/*
			*/Ppct(integer 95)/*
			*/ROWby(varname)/*
			*/Total /*
			*/Full /*
			*/noLabel /*
			*/Hide(integer 0)/*
			*/Verbose /*
			matprint options
			*/Style(passthru)/*
			*/Decimals(passthru)/*
			*/TItle(passthru)/*
			*/TOp(passthru)/*
			*/Undertop(passthru)/*
			*/Bottom(passthru)/*
			*/Replace(passthru)/*
		*/]

	if `hide' < 0 {
		display "{error:hide must have a non-negative integer argument. Is set to 0}"
		local `hide' 0
	}

	capture drop __if_in
	mark __if_in `if' `in'
	quietly summarize __if_in
	local __N `=r(sum)'
	
	mata: __add_quietly = !(__verbose=("`verbose'" != ""))

	quietly capture matrix drop __out __tmp
	if "`rowby'" != "" {
		if "`full'" == "full" quietly levelsof `rowby', local(__levels)
		else quietly levelsof `rowby' `if' `in', local(__levels)
		foreach val in `__levels' {
			foreach var of varlist `varlist' {
				mata: __row = nhb_sae_summary_row("`var'", "`statistics'", "__tmp", ///
						"if __if_in & `rowby' == `val'", "", `ppct', `__N', `hide', ///
						"`label'" != "", __verbose, __add_quietly)
				if "`label'" == "" {
					local valuelbl "`:value label `rowby''"
					if "`valuelbl'" != "" {
						matrix roweq __tmp = `"`rowby'(`:label `valuelbl' `val'')"'
						if `c(version)' >= 13 {
							matrix rownames __tmp = `"`:variable label `var''"'
						}
						else {
							matrix rownames __tmp = `"`=subinstr(`"`:variable label `var''"', ".", "", .)'"'
						}
					}
					else {
						display `"{error: No value label for rowby variable "`rowby'"}"'
					}
				}
				else matrix roweq __tmp = "`rowby'(`val')"
				matrix __out = nullmat(__out) \ __tmp
			}
		}
	}
	if "`total'" == "total" | "`rowby'" == "" { 
		foreach var of varlist `varlist' {
			mata: __row = nhb_sae_summary_row("`var'", "`statistics'", "__tmp", ///
						"if __if_in", "", `ppct', `__N', `hide', "`label'" != "", ///
						__verbose, __add_quietly)
			if "`total'" == "total" matrix roweq __tmp = Total
			matrix __out = nullmat(__out) \ __tmp
		}
	}
	if "`coleq'" != "" matrix coleq __out = `"`coleq'"'
	if "`roweq'" != "" {
		mata: __rs = st_matrixrowstripe("__out")
		mata: __rs[., 2] = any(__rs[., 1] :!= "") ? (__rs[., 1] :+ ", " :+ __rs[., 2]) : __rs[., 2]
		mata: __rs[., 1] = J(rows(__rs), 1, "`roweq'")
		mata __rs = abbrev(__rs, 32)
		mata: st_matrixrowstripe("__out", __rs)
	}
	quietly capture matrix drop __tmp
	quietly capture mata drop __row
	
	*** matprint ***************************************************************
	matprint __out `using',	`style' `decimals' `title' `top' `undertop' `bottom' `replace'
	****************************************************************************

	return matrix sumat = __out
	capture drop __if_in
end
