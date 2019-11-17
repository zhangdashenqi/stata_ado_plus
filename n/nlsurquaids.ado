*! version 1.0.1  08may2008
program nlsurquaids

	version 10
	
	syntax varlist(min=8 max=8) if, at(name)
	
	tokenize `varlist'
	args w1 w2 w3 lnp1 lnp2 lnp3 lnp4 lnm
	
	// With four goods, there are 15 parameters that can be 
	// estimated, after eliminating one of the goods and 
	// imposing adding up, symmetry, and homogeneity
	// constraints, in the QUAIDS model
	// Here, we extract those parameters from the `at'
	// vector, and impose constraints as we go along

	tempname a1 a2 a3 a4
	scalar `a1' = `at'[1,1]	
	scalar `a2' = `at'[1,2]	
	scalar `a3' = `at'[1,3]	
	scalar `a4' = 1 - `a1' - `a2' - `a3'
	
	tempname b1 b2 b3 b4
	scalar `b1' = `at'[1,4]
	scalar `b2' = `at'[1,5]
	scalar `b3' = `at'[1,6]
	scalar `b4' = -`b1' - `b2' - `b3'

	tempname g11 g12 g13 g14
	tempname g21 g22 g23 g24
	tempname g31 g32 g33 g34
	tempname g41 g42 g43 g44
	scalar `g11' = `at'[1,7]
	scalar `g12' = `at'[1,8]
	scalar `g13' = `at'[1,9]
	scalar `g14' = -`g11' - `g12' - `g13'

	scalar `g21' = `g12'
	scalar `g22' = `at'[1,10]
	scalar `g23' = `at'[1,11]
	scalar `g24' = -`g21' - `g22' - `g23'

	scalar `g31' = `g13'
	scalar `g32' = `g23'
	scalar `g33' = `at'[1,12]
	scalar `g34' = -`g31' - `g32' - `g33'

	scalar `g41' = `g14'
	scalar `g42' = `g24'
	scalar `g43' = `g34'
	scalar `g44' = -`g41' - `g42' - `g43'
	
	tempname l1 l2 l3 l4
	scalar `l1' = `at'[1,13]
	scalar `l2' = `at'[1,14]
	scalar `l3' = `at'[1,15]
	scalar `l4' = -`l1' - `l2' - `l3'
	
	// Okay, now that we have all the parameters, we can 
	// calculate the expenditure shares.	
	quietly {
		// First get the price index
		// I set a_0 = 5
		tempvar lnpindex
		gen double `lnpindex' = 5 + `a1'*`lnp1' + `a2'*`lnp2'	///
					  + `a3'*`lnp3' + `a4'*`lnp4'
		forvalues i = 1/4 {
			forvalues j = 1/4 {
				replace `lnpindex' = `lnpindex' + 	///
					0.5*`g`i'`j''*`lnp`i''*`lnp`j''
			}
		}
		// The b(p) term in the QUAIDS model:
		tempvar bofp
		gen double `bofp' = 0
		forvalues i = 1/4 {
			replace `bofp' = `bofp' + `lnp`i''*`b`i''
		}
		replace `bofp' = exp(`bofp')
		// Finally, the expenditure shares for 3 of the 4
		// goods (the fourth is dropped to avoid singularity)
		replace `w1' = `a1' + `g11'*`lnp1' + `g12'*`lnp2' +	///
				      `g13'*`lnp3' + `g14'*`lnp4' +	///
				      `b1'*(`lnm' - `lnpindex') +	///
				      `l1'/`bofp'*(`lnm' - `lnpindex')^2
		replace `w2' = `a2' + `g21'*`lnp1' + `g22'*`lnp2' +	///
				      `g23'*`lnp3' + `g24'*`lnp4' +	///
				      `b2'*(`lnm' - `lnpindex') +	///
				      `l2'/`bofp'*(`lnm' - `lnpindex')^2
		replace `w3' = `a3' + `g31'*`lnp1' + `g32'*`lnp2' +	///
				      `g33'*`lnp3' + `g34'*`lnp4' +	///
				      `b3'*(`lnm' - `lnpindex') +	///
				      `l3'/`bofp'*(`lnm' - `lnpindex')^2
				      
	}
	
end

