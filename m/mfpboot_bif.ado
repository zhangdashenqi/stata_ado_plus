*! v 1.0.1 PR 12sep2009
program define mfpboot_bif
	version 10
/*
	Displays inclusion fractions for each variable in a mfpboot output file,
	ignoring the first row, which contains paramaters for the original data
*/
	syntax [, Term(int 1) Generate]
	local vl: char _dta[pmb_vl]
	tokenize `vl'
	while "`1'"!="" {
		cap confirm var `1'p`term'
		if c(rc) {
			di as err "variable `1'p`term' not found"
		}
		else {
			qui count if !missing(`1'p`term') & (i > 0)
			di as txt %12s abbrev("`1'", 12) ":" as res %7.0f r(N) %7.2f 100 * r(N) / (_N - 1)
			if "`generate'" != "" {
				cap drop `1'i`term'
				qui gen byte `1'i`term' = !missing(`1'p`term') & (i > 0)
			}
		}
		mac shift
	}
end
