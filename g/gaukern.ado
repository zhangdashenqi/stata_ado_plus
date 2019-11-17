program define gaukern, rclass sortpreserve
	version 9
	syntax varlist(min=2 max=2) [if] [in] [fw aw], 		///
		 	GENerate(string) AT(string) 			///
			[b(varlist min=1 max=1) PREDictor(varlist min=1) 	///
			GRADName(string) HESSName(string) ]	

	* Select Dependent and Independent Variables
		tokenize `varlist'
		local varnum : word count `varlist'
		if `varnum'==2 {
			local iy `1'
			local ix `2'
		}
		else {
			di "One dependent and one independent variable must be specified"
			exit
		} 
		
	* Mark sample	
		marksample use
		qui count if `use'
		if r(N)==0 error 2000 


	if "`gradname'"!=""  {		// Gradient and Hessian options

		local pred `"`predictor'"'		// Predictor Option
		tokenize `pred'
		local numpred : word count `pred'
		local s 1
		while `s'<=`numpred' {
			tempvar xs`s' mxs`s'
			qui gen double `xs`s''=``s'' 	if `use'
			qui gen double `mxs`s''=``s'' if `use'
			local s=`s'+1
		}

		local namefder `"`gradname'"'		// Gradient name option
		tokenize `namefder'
		local numfder : word count `namefder'
		if `numfder'==`numpred' {
			local s 1
			while `s'<=`numfder' {
				capture confirm new var ``s''
				local dp_`s'  "``s''"
				local s=`s'+1
			}
		}
		else {
			di in red "Number of derivatives must be equal to the number of predictors"
			exit
		}

		if "`hessname'"!=""  {				//Hessian name option
			local namesder `"`hessname'"'
			tokenize `namesder'
			local numsder : word count `namesder'
			if `numsder'==(`numpred'*(`numpred'+1)/2) {
				local j 1
				local s 1
				while `s'<=`numfder' {
					local t 1
					while `t'<=`s' {
						capture confirm new var ``j''
						local d2p_`s'_`t'  "``j''"
						local t=`t'+1
						local j=`j'+1
					}
					local s=`s'+1
				}
			}
			else {
				di in red "Number of derivatives must be equal to k*(k+1)/2"
				exit
			}
		}
	}

	* Generate option
		local gen `"`generate'"'
		tokenize `gen'
		local wc : word count `gen'
		if `wc' { 
			if `wc' == 1  {
				capture confirm new var ``1''
				local p  "`1'"
			}
			else error 198
		}
		else {
			di in bl `"did not request results be saved; no action taken"'
			exit
		}

	* Evaluation points
		tokenize `at'
		tempvar m1
		qui gen double `m1'=`1' if `use'
		qui count if `m1' 
		local nobs = r(N)

	* Inizialization
		tempvar  z1 num den numerator denominator 
		qui gen double `z1'		=.
		qui gen double `num'		=.
		qui gen double `den'		=.
		qui gen double `numerator'	=.
		qui gen double `denominator'	=.
		if "`numfder'"!="" {
			local s 1
			while `s'<=`numfder' {
				tempvar xd_`s' a1_`s' anum_`s' b1_`s' bnum_`s' 
				qui gen double `xd_`s''	=.
				qui gen double `a1_`s''	=.
				qui gen double `anum_`s''=.
				qui gen double `b1_`s''	=.
				qui gen double `bnum_`s''=.
				if "`numsder'"!="" {
					local t 1
					while `t'<=`s' {
						tempvar c2_`s'_`t' cnum_`s'_`t' d2_`s'_`t' dnum_`s'_`t'
						qui gen double `c2_`s'_`t''=.
						qui gen double `cnum_`s'_`t''=.
						qui gen double `d2_`s'_`t''=.
						qui gen double `dnum_`s'_`t''=.
						local t=`t'+1
					}				
				}
				local s=`s'+1
			}
		}

	* Estimation
	gsort -`use'
	local i 1
	while `i'<=`nobs' {
			qui replace `z1'=((`m1'[`i']-`ix')/`b') if `use' & _n!=`i'

			qui replace `den'=normden(`z1')
			qui summ `den'
			qui replace `denominator'=(r(mean)*r(N)) in `i'

	 		qui replace `num'=`iy'*(`den')
			qui summ `num'
			qui replace `numerator'=(r(mean)*r(N)) in `i'

			if "`numfder'"!="" {
				local s 1
				while `s'<=`numpred' {
					* compute dpi(b)/dbs 
					qui replace `xd_`s''=((`mxs`s''[`i']-`xs`s'')/`b') 	if `use' & _n!=`i'

					qui replace `a1_`s''=`z1'*normden(`z1')*`xd_`s''
					qui sum `a1_`s''
					qui replace `anum_`s''=(r(mean)*r(N)) 			in `i'

					qui replace `b1_`s''=`iy'*`z1'*normden(`z1')*`xd_`s''
					qui sum `b1_`s''
					qui replace `bnum_`s''=(r(mean)*r(N)) 			in `i'
					
					if "`numsder'"!="" {
						local t 1
						while `t'<=`s' {
						
							qui replace `c2_`s'_`t''=`xd_`s''*`xd_`t''*(1-`z1'^2)*normden(`z1')
							qui sum `c2_`s'_`t''
							qui replace `cnum_`s'_`t''=(r(mean)*r(N)) 			in `i'

							qui replace `d2_`s'_`t''=`iy'*`xd_`s''*`xd_`t''*(1-`z1'^2)*normden(`z1')
							qui sum `d2_`s'_`t''
							qui replace `dnum_`s'_`t''=(r(mean)*r(N)) 			in `i'

							local t=`t'+1
						}
					}
					local s=`s'+1
				}
			}
			qui replace `z1'=.
			local i = `i'+1
	}

	qui gen double `p'=`numerator'/`denominator' if `use'
	if "`numfder'"!="" {
		local s 1
		while `s'<=`numpred' {
			qui gen double `dp_`s''=`p'*(`anum_`s''/`denominator')-(`bnum_`s''/`denominator') if `use'
			if "`numsder'"!="" {
				local t 1
				while `t'<=`s' {
					qui gen double `d2p_`s'_`t''=`p'*(`cnum_`s'_`t''/`denominator')	///
							   +`dp_`t'' * (`anum_`s''/`denominator')			///
							   +`dp_`s'' * (`anum_`t''/`denominator')			///
							   -(`dnum_`s'_`t''/`denominator') 				if `use'
					local t=`t'+1
				}
			}
			local s=`s'+1
		}
	}
end	


