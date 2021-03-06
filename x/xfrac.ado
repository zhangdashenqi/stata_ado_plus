*! version 1.0.0 Stephen P. Jenkins, Dec 1998      STB-48 sg104
*! % of sample with incomes between specified fractions of a given
*!   income value (would typically be mean or median)

program define xfrac

	version 5.0

	local varlist "req ex max(1)"
	local if "opt"
	local in "opt"
	local options "CUToff(real -999) GP(string)"
	local weight "aweight fweight"
	parse "`*'"
	parse "`varlist'", parse (" ")
	local inc "`1'"

	if `cutoff' == -999 {
		di in red "Must give cutoff income"
		exit 198
	}

	tempvar wi touse badinc tinc

	if "`gp'" ~= "" {confirm new variable `gp' }
	else {tempvar gp}

	mark `touse' `if' `in'
	markout `touse' `varlist' 
	set more 1

	quietly {

	count if `inc' < 0 & `touse'
	local ct = _result(1)
	if `ct' > 0 {
		noi di " "
		noi di in blue "Warning: `inc' has `ct' values < 0." _c
		noi di in blue " Used in calculations"
		}
	count if `inc' == 0 & `touse'
	local ct = _result(1)
	if `ct' > 0 {
		noi di " "
		noi di in blue "Warning: `inc' has `ct' values = 0." _c
		noi di in blue " Used in calculations"
		}

	/* reinstate this bit if want to exclude 
	obs with `inc' <=0 from calculations */

	/*	ge `badinc' = 0
	replace `badinc' =. if `inc' <= 0
	markout `touse'  `badinc'
	*/

	ge `tinc' = .	
	replace `tinc' = 1 if `inc' < .1*`cutoff' & `touse'
	replace `tinc' = 2 if `inc' >= .1*`cutoff' & `inc' < .2*`cutoff' /*
	*/ & `touse'
	replace `tinc' = 3 if `inc' >= .2*`cutoff' & `inc' < .3*`cutoff' /*
	*/ & `touse'
	replace `tinc' = 4 if `inc' >= .3*`cutoff' & `inc' < .4*`cutoff' /*
	*/ & `touse'
	replace `tinc' = 5 if `inc' >= .4*`cutoff' & `inc' < .5*`cutoff' /*
	*/ & `touse'
	replace `tinc' = 6 if `inc' >= .5*`cutoff' & `inc' < .6*`cutoff' /*
	*/ & `touse'
	replace `tinc' = 7 if `inc' >= .6*`cutoff' & `inc' < .7*`cutoff' /*
	*/ & `touse'
	replace `tinc' = 8 if `inc' >= .7*`cutoff' & `inc' < .8*`cutoff' /*
	*/ & `touse'
	replace `tinc' = 9 if `inc' >= .8*`cutoff' & `inc' < .9*`cutoff' /*
	*/ & `touse'
	replace `tinc' =10 if `inc' >= .9*`cutoff' & `inc' <  1*`cutoff' /*
	*/ & `touse'
	replace `tinc' =11 if `inc' >= 1.0*`cutoff' & `inc' < 1.1*`cutoff' /*
	*/ & `touse'
	replace `tinc' =12 if `inc' >= 1.1*`cutoff' & `inc' < 1.2*`cutoff' /*
	*/ & `touse'
	replace `tinc' =13 if `inc' >= 1.2*`cutoff' & `inc' < 1.3*`cutoff' /*
	*/ & `touse'
	replace `tinc' =14 if `inc' >= 1.3*`cutoff' & `inc' < 1.4*`cutoff' /*
	*/ & `touse'
	replace `tinc' =15 if `inc' >= 1.4*`cutoff' & `inc' < 1.5*`cutoff' /*
	*/ & `touse'
	replace `tinc' =16 if `inc' >= 1.5*`cutoff' & `inc' < 1.75*`cutoff' /*
	*/ & `touse'
	replace `tinc' =17 if `inc' >= 1.75*`cutoff' & `inc' < 2.0*`cutoff' /*
	*/ & `touse'
	replace `tinc' =18 if `inc' >= 2.0*`cutoff' & `inc' <  2.5*`cutoff' /*
	*/ & `touse'
	replace `tinc' =19 if `inc' >= 2.5*`cutoff' & `inc' <  3.0*`cutoff' /*
	*/ & `touse'
	replace `tinc' =20 if `inc' >= 3.0*`cutoff' & `touse'
	lab var `tinc' "Fractions of cut-off"
	lab def `tinc' 1 "<.1 " 2 ".1-.2 " 3 ".2-.3 " 4 ".3-.4 " /*
	*/ 5 ".4-.5 " 6 ".5-.6 " 7 ".6-.7 " 8 ".7-.8 " /*
	*/ 9 ".8-.9 " 10 ".9-1.0" 11 "1.0-1.1" 12 "1.1-1.2" /*
	*/ 13 "1.2-1.3" 14 "1.3-1.4" 15 "1.4-1.5" 16 "1.5-1.75" /*
	*/ 17 "1.75-2.0" 18 "2.0-2.5" 19 "2.5-3.0" 20 ">=3.0" 

/*	lab def `tinc' 1 "<.1" 2 ">=.1,<.2" 3 ">=.2,<.3" 4 ">=.3,<.4" /*
	*/ 5 ">=.4,<.5" 6 ">=.5,<.6" 7 ">=.6,<.7" 8 ">=.7,<.8" /*
	*/ 9 ">=.8,<.9" 10 ">=.9,<1" 11 ">=1.0,<1.1" 12 ">=1.1,<1.2" /*
	*/ 13 ">=1.2,<1.3" 14 ">=1.3,<1.4" 15 ">=1.4,<1.5" 16 ">=1.5,<1.75" /*
	*/ 17 ">=1.75,<2.0" 18 ">=2.0,<2.5" 19 ">=2.5,<3.0" 20 ">=3.0" 
*/
	lab val `tinc' `tinc'

	noi di in gr "Proportions of the sample in subgroups defined "
	noi di in gr "by values of `inc' between specified fractions "
	noi di in gr "of a cut-off value = " in ye %9.5f `cutoff'

	if "`weight'" == "" {
		noi ta `tinc' if `touse'
	}
	else if "`weight'" == "fweight" {
		noi ta `tinc' [fw `exp'] if `touse'
	}
	else if "`weight'" == "aweight" {
		noi ta `tinc' [aw `exp'] if `touse'
	}

	if "`gp'" ~= "" {
		ge `gp' = `tinc'
		lab val `gp' `tinc'
	}

	}  /* end of quietly block */

end


