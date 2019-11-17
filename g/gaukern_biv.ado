program define gaukern_biv, rclass sortpreserve
	version 9
	syntax varlist(min=2 max=3) [if] [in] [fw aw], Generate(string) AT(string) ///
			[b1(varlist min=1 max=1) b2(varlist min=1 max=1)]	

	* Select Dependent and Independent Variables
	tokenize `varlist'
	local xnum : word count `varlist'
	local xnum=`xnum'-1
	local iy `1'
	local i 1
	while `i'<=`xnum' {
		local j=`i'+1
		local ix`i' ``j''
		local i=`i'+1
	}	

	* Mark sample	
	marksample use
	qui count if `use'
	local nnobs = r(N)
	if r(N)==0 error 2000 
	
	* Generate option
	local gen `"`generate'"'
	tokenize `gen'
	local wc : word count `gen'
	if `wc' { 
		if `wc' == 1  {
			capture confirm new var ``1''
			local yl  "`1'"
		}
		else {
			 error 198
		}
	}
	else {
			di in red "Did not request results be saved; no action taken"
			exit
	}


	* Evaluation points
	tempvar m1 m2
	qui gen double `m1'=.
	qui gen double `m2'=.
	tokenize `at'
	local atnum : word count `at'
	if `atnum' == `xnum' { 
		local i 1
		while `i'<=`atnum' {
			qui replace `m`i''=``i'' if `use'
			local i=`i'+1
		}	
		qui count if `m1'!=. 
		local n1 = r(N)
		qui count if `m2'!=. 
		local n2 = r(N)
	}
	else {
		di in red "The number of evaluation points and predictors must coincides"
		exit
	}

	* Estimation
	tempvar z1 z2 den num denominator numerator
	qui gen double `z1'=.
	qui gen double `z2'=.
	qui gen double `den'=.
	qui gen double `num'=.
	qui gen double `denominator'=.
	qui gen double `numerator'=.

	gsort -`use'
	local i 1
	if `n2'>0 {
		while `i'<=`n2' {
			qui replace `z1'=(`m1'[`i']-`ix1')/`b1' 		if `use' & _n!=`i'
			qui replace `z2'=(`m2'[`i']-`ix2')/`b2' 		if `use' & _n!=`i'
			
 			qui replace `den'=normden(`z1')*normden(`z2')/(`b1'*`b2')
			qui summ `den'
			qui replace `denominator'=r(mean) in `i'

			qui replace `num'=`iy'*normden(`z1')*normden(`z2')/(`b1'*`b2')
			qui summ `num'
			qui replace `numerator'=r(mean) in `i'

			qui replace `z1'=.
			qui replace `z2'=.
			qui replace `den'=.
			qui replace `num'=.
			local i = `i'+1
		}
	qui gen double `yl'=`numerator'/`denominator' if `use' & `m1'!=. & `m2'!=.
	}
	else {
		while `i'<=`n1' {
			qui replace `z1'=(`m1'[`i']-`ix1')/`b1' 		if `use' & _n!=`i'
			
			qui replace `den'=normden(`z1')/`b1'
			qui summ `den'
			qui replace `denominator'=r(mean) in `i'

			qui replace `num'=`iy'*normden(`z1')/`b1'
			qui summ `num'
			qui replace `numerator'=r(mean) in `i'

			qui replace `z1'=.
			qui replace `den'=.
			qui replace `num'=.
			local i = `i'+1
		}
	qui gen double `yl'=`numerator'/`denominator' if `use' & `m1'!=.
	}

end






