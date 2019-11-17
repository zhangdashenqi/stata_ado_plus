*! Version 1.0    (STB-52 sg121)
* version of clogit for -suest-
program define clogit2
	version 6

	syntax varlist [if] [in] [fweight iweight] , GRoup(varname) Score(string) /*
		*/ [ * ]

	confirm new var `score'

	tempvar p

	* ensure yvar(+) = 1 within groups (ignore if/in!)
	quietly {
		gettoken yvar xvar: varlist
		assert `yvar' == 0 | `yvar' == 1
		sort `group'
		by `group' : gen `p' = sum(`yvar')
		by `group' : assert `p'[_N] == 1
	}

	clogit `varlist' `if' `in' [`weight'`exp'] , group(`group') `options'

	drop `p'
	predict `p'
	gen `score' = `yvar' - `p' /* if e(sample) */

	di _n in bl "Warning: Specify cluster(`group') with -suest combine-"
end
