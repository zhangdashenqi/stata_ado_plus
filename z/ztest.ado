*! $Revision: 1.4 $
*! $Date: 2001/05/15 05:23:09 $
*! Written by: Jeff Pitblado

program define ztest, rclass byable(recall)
	version 6
	syntax varname [=/exp] [if] [in] [, /*
	*/ BY(varname) UNPaired Level(int $S_level) ]

	tempvar touse
	mark `touse' `if' `in'

	checkBin `varlist' `touse'

	if `"`exp'"'!="" {
		if "`by'"!="" {
			di in red "may not combine = and option by()"
			exit 198
		}

		if "`unpaire'"!="" { /* do two-sample (unpaired) test */

			checkBin `exp' `touse'

			summ `varlist' if `touse', meanonly
			local N1 = r(N)
			local succ1 = r(sum)
			summ `exp' if `touse', meanonly
			local N2 = r(N)
			local succ2 = r(sum)
			ztesti `N1' `succ1' `N2' `succ2', /*
				*/ level(`level') xname(`varlist') yname(`exp')
			ret add
			exit
		}

		/* If here, we do one-sample test. */

		capture confirm number `exp'
		if _rc==0 {
			if `exp'<=0 | 1<=`exp' {
				di in smcl as error /*
				*/ "{it:#p} must be contained in (0,1)"
				exit 198
			}
			summ `varlist' if `touse', meanonly
			local N1 = r(N)
			local succ1 = r(sum)
			ztesti `N1' `succ1' `exp', /*
				*/ level(`level') xname(`varlist')
			ret add
			exit
		}

		/* If here, we do two-sample paired (McNemar) test. */
		checkBin `exp' `touse'

		qui count if `varlist'>`exp' & `touse'
		local b = r(N)
		qui count if `varlist'<`exp' & `touse'
		local c = r(N)
		ztesti `b' `c', level(`level') xname(`varlist') yname(`exp')
		ret add
		exit
	}

	/* If here, do two-sample (unpaired) test with by(). */

	if "`by'"=="" {
                di in red "by() option required"
                exit 100
        }

	checkBin `by' `touse'
	summ `varlist' if `by'==0 & `touse', meanonly
	local N1 = r(N)
	local succ1 = r(sum)
	summ `varlist' if `by'==1 & `touse', meanonly
	local N2 = r(N)
	local succ2 = r(sum)
	ztesti `N1' `succ1' `N2' `succ2', level(`level') xname(`varlist')

	ret add
end

program define checkBin
	args x touse
	confirm numeric variable `touse'
	confirm numeric variable `x'

	summ `x' if `touse', meanonly
	capture assert `x'==r(max) | `x'==r(min) if `touse'
	if _rc {
		di as error "`x' is not binary {0, 1}"
		exit 198
	}
end

exit

------------------------------------------------------------------------------
NOTES
------------------------------------------------------------------------------

<end>
