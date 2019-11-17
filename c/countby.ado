*! 1.0.0  09Mar1999  jw/ics
program define countby, rclass
	version 6.0

	syntax if/ , by(varlist) [ nameby(str) namerec(str) * ]

	* selection of records and by-groups
	tempvar touse
	markby `touse', by(`by') `options'

	tempname Nalways Never Nby Nnever Nrec 
	tempvar x y

	* evaluate condition only once
	gen byte `x' = ((`if') ~= 0)
	qui count if `x' & `touse'
	scalar `Nrec' = r(N)

	* # (selected) groups (i.e., by-group with >0 selected record)
	sort `by' `touse' `x'
	qui by `by' : gen byte `y' = (_n==_N) & `touse'
	qui count if `y'
	scalar `Nby' = r(N)
	drop `y'
	
   * # (selected) groups in which all (selected) records satisfy condition
	qui by `by' `touse': gen byte `y' = `x'[1] & `touse' & _n==_N
	qui count if `y'
	scalar `Nalways' = r(N)
	drop `y'
	
	qui by `by' `touse': gen byte `y' = `x'[_N] & `touse' & _n==_N
	qui count if `y'
	scalar `Never' = r(N)
	
	scalar `Nnever' = `Nby' - `Never'

	if "`nameby'"  == "" { local nameby  "by-group" }
	if "`namerec'" == "" { local namerec "record"   }

	local c "_col(46) in ye %5.0f"
	di
	di in gr "#`namerec's that satisfy condition"       `c' `Nrec'    " / " _N
	di in gr "#`nameby's that never satisfy condition"  `c' `Nnever'  " / " `Nby'	
	di in gr "#`nameby's that ever satisfy condition"   `c' `Never'   " / " `Nby'
	di in gr "#`nameby's that always satisfy condition" `c' `Nalways' " / " `Nby' 

	return scalar N_by   = `Nby'
	return scalar never  = `Nnever'
	return scalar ever   = `Never'
	return scalar always = `Nalways'
end
exit

problems to be addressed

  * sample selection
  * expressions with missing values
  
