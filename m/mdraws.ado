*! version 1.3.0  30march2006 Add option to create antithetic draws; make rclass
*! version 1.2.0  24march2006 Fix vble names for M >= 10 case
*! version 1.1.0  26jan2006  Cappellari & Jenkins 
*! Create Halton and pseudo-random std uniform draws 
*!  for use in maximum simulated likelihood estimation
*!  Code for Halton draws based on do file code 
*!  from Arne Uhlendorff which in turn uses a program
*!  posted on Statalist by Nick Cox in August 2004
*!  http://www.stata.com/statalist/archive/2004-08/msg00222.html

program define mdraws, sortpreserve rclass

        version 8
	syntax [if] [in], DRaws(integer) Neq(integer) PREfix(string)  ///
		[ PRImes(name) Burn(integer 0)  ///
		RAndom SEed(integer 123456789) REPLACE ///
		SHuffle HRandom ANtithetics ] 

	local D "`draws'"
	local M "`neq'"
	
	if "`random'" == ""  local type halton

	if "`type'" == "halton" & "`primes'" != ""  {
		tempname ps
		matrix `ps' = `primes'
		local m = colsof(`ps')
		if `m' == 1 { 
			matrix `ps' = `ps'' //transpose to ensure row vector
			local m = colsof(`ps')
		}

		if "`m'" != "`M'" {
			di as error "primes vector must be 1 x `M' or `M' x 1"
			exit 198
		}

				// rudimentary check that vector contains only primes
		forvalues m = 1/`M' {

			local pr  "2 3 5 7 11 13 17 19 23"
			local pr "`pr' 29 31 37 41 43 47 53 59"
			local pr "`pr' 61 67 71 73 79 83 89 97"
			foreach p of local pr {
				if ( mod(`ps'[1,`m'], `p' ) == 0 ///
			        	& `ps'[1,`m'] != `p' )  {
		    local badn = `ps'[1,`m']		 
		    di as error "{p 0 0 4}primes vector must contain primes:"
		    di as error "`badn' is not a prime number{p_end}"
		    exit 198
				}
			}  		                 
			forvalues n = 2/`M' {
				if `ps'[1,`m'] == `ps'[1,`n'] ///
			           & (`m' != `n')  {
					di as error "{p 0 0 4}primes vector "
					di as error "elements must be "
					di as error "distinct{p_end}"
					exit 198
				}
			}
		}
	}

	if "`type'" == "halton" & "`primes'" == ""  {
		if `M' <= 20 {
			tempname primes
   mat `primes' = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71)

	tempname ps
	mat `ps' = `primes'[1,1..`M']
		}
		else {
			di as error "{p 0 0 4}Number of equations > 20. Cannot use "
			di as error "default vector of primes. Specify your own.{p_end}"
			exit 198
		}
	}

	forvalues m = 1/`M'  {
		forvalues d = 1/`D' {
			if "`replace'" == "" confirm new var `prefix'`m'_`d'
			else cap drop `prefix'`m'_`d'
		}
	}
			

quietly {

	marksample touse

        count if `touse' 
	local nobs = r(N)
        if `nobs' == 0 { 
                di as error "no valid observations"
                error 2000
	}


// Halton sequence

if "`type'" == "halton" {

	tempvar id
	ge long `id' = _n if `touse'

	tempvar mtouse
	ge byte `mtouse' = -`touse'
	sort `mtouse'

	sort `mtouse' `id' 
	tempfile temp
	save `temp'

	keep if `touse'
	keep `id' `mtouse'

	count 
	local nobs = r(N)

	expand `draws' 

	tempvar id2
	sort `id'
	gen long `id2' = _n

	expand 2 if `id2' == _N  	// last one later dropped

		// first `burn' obs later dropped; no change if `burn'==0
	expand = (`burn' + 1)  if `id2' == 1   
	sort `id' `id2'
	replace `id2' = _n

	if ("`hrandom'" != "")|("`shuffle'" != "") set seed `seed'

		// create Halton sequence(s) using NJC's Statalist program
		//                                 as extended by SPJ

	forvalues m = 1/`M'  {
		local prime = `ps'[1, `m']
		tempvar v`m'
		mdraws_h, gen(`v`m'') q(`prime') `shuffle' 
	}

		// beware: sort order permuted if shuffle used

	drop if _n == _N
	if `burn' > 0 drop in 1/`burn'

	bysort `mtouse' `id': replace `id2' = _n

	forvalues m = 1/`M'  {
		local vars "`vars' `v`m''"
	}

		// data created have same shape as balanced panel, so ...
	reshape wide "`vars'" , i(`id') j(`id2')

	forvalues d = 1/`D'  {
		forvalues m = 1/`M' {
			rename `v`m''`d'   `prefix'`m'_`d' 
			lab var `prefix'`m'_`d' "Halton var, eq. `m', draw `d'"
		}
	}

	tempfile junk
	sort `mtouse' `id'
	save `junk'
	use `temp', clear
	sort `mtouse' `id'
	merge `mtouse' `id' using `junk'
	drop _merge

	// randomized Halton draws (a la Bhat, as described by Train, p. 234)
	if "`hrandom'" != "" {
		forvalues d = 1/`D'  {
			tempname u
			scalar `u' = uniform()
			forvalues m = 1/`M' {
				replace `prefix'`m'_`d' = ///
					cond(`prefix'`m'_`d' + `u' > 1, ///
					     `prefix'`m'_`d' + `u' - 1, ///
					     `prefix'`m'_`d' + `u', .)
			}
		}
	}

	if "`shuffle'" != "" local s " Shuffled "
	if "`hrandom'" != "" local r " Randomized"

	noi di as txt "{p 0 0 4}Created " as res `D' as txt "`s' `r' Halton draws per " 
	noi di "equation for " as res `M' as txt " dimensions. Number of initial "
	noi di as txt "draws dropped per dimension  = " as res `burn'
	noi di as txt ". Primes used:{p_end}"
	noi mat list `ps', noheader nonames


}  // end of halton block


// pseudo-random sequence

if "`random'" != "" {

	set seed `seed'

	forval d = 1/`D' {
		forval m = 1/`M' {
			ge double `prefix'`m'_`d' = uniform() if `touse'
			lab var `prefix'`m'_`d' "Pseudo-random var, eq. `m', dr. `d'"
		}
	}


	noi di as txt "{p 0 0 4}Created " as res `D' 
	noi di as txt " pseudo-random draws per " 
	noi di "equation for " as res `M' as txt " equations. Seed = " 
	noi di as res %15.0g `seed' "{p_end}"


} // end of pseudo-random block


	// optionally create antithetic draws in addition

	if "`antithetics'" != "" {	
		forvalues d = 1/`D' {
			forvalues m =  1/`M'   {
	      if "`replace'" == "" confirm new var `prefix'`m'_`=`D'+`d''
	      else cap drop `prefix'`m'_`=`D'+`d''
	      gen double `prefix'`m'_`=`D'+`d'' = 1 - `prefix'`m'_`d'
	      lab var `prefix'`m'_`=`D'+`d'' "Antithetic var, eq. `m', draw `=`D'+`d''"
			}
		}

	noi di as txt "{p 0 0 4}Also created " as res `D' 
	noi di as txt "antithetic draws per dimension" 
	noi di as txt "for " as res `M' as txt " dimensions."
	noi di as txt "Note: there are now " as res 2*`D' "
	noi di as txt " draws per equation{p_end}" 

	}

if "`type'" == "halton" {
	return local type halton
	return matrix primes = `ps', copy
	if "`burn'" != "" return scalar n_burn = `burn'
	if "`shuffle'" != "" return local shuffled shuffled
	if "`hrandom'" != "" return local randomized randomized
	

}

if "`random'" != "" {
	return local type random
	return local seed `c(seed)'
}

return local antithetics no
return local prefix `prefix'
return scalar n_draws = `D'
return scalar n_dimensions = `M'
if "`antithetics'" != "" {
	return local antithetics yes 
	return scalar n_draws = 2*`D'
}


}  // end of -quietly- block

end


