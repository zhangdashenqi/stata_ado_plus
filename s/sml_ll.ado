
* Likelihood Evaluator
program define sml_ll
      version 9.0
	args todo b lnf g negH
	tempvar lni xb1 p1

* Get index 
	mleval `xb1'=`b', eq(1) 					

* Get names of independent variables, first and second derivatives
	local rhs="$predictors"
	tokenize `rhs'
	local numpred : word count `rhs'
	local nameder ""
	local s 1
	while `s'<=`numpred' {
		tempvar dp_`s'
		local dp_`s' " `dp_`s''"
		local nameder "`nameder' `dp_`s''" 
		local t 1
		while `t'<=`s' {
			tempvar d2p_`s'_`t'
			local d2p_`s'_`t' " `d2p_`s'_`t''"
			local nameder2 "`nameder2' `d2p_`s'_`t''"
			local t=`t'+1
		}
		local s=`s'+1
	}

	
* Kernel Estimate
	tempvar bw
	qui gen double `bw'=$bwidth
	gaukern $ML_y1 `xb1'  if $ML_samp , gen(`p1') at(`xb1') 		///	
		  pred(`rhs') gradn(`nameder') hessn(`nameder2') b(`bw')	


* Computation of the Log-likelihood 
	qui gen double `lni'=ln(`p1') 		if $ML_y1==1
	qui replace    `lni'=ln(1-`p1') 		if $ML_y1==0
	mlsum `lnf'=`lni' 				if $ML_samp

* Computation of the Gradient 
	if `todo'==0 |`lnf'==. exit
	matrix define `g'=J(1,`numpred',0)
	local s 1
	while `s'<=`numpred' {
		tempvar gj`s'
		qui gen double `gj`s''=(`dp_`s''/`p1') 	if $ML_y1==1 & $ML_samp
		qui replace `gj`s''=-(`dp_`s''/(1-`p1')) 	if $ML_y1==0 & $ML_samp
		qui sum `gj`s'' 					if $ML_samp
		matrix `g'[1,`s']=r(mean)*r(N)
		local s=`s'+1
	}

* Computation of the negative Hessian Matrix 
	if `todo'==1 |`lnf'==. exit
	matrix define `negH'=J(`numpred',`numpred',0)
	local s 1
	while `s'<=`numpred' {
		local t 1
		while `t'<=`s' {
			tempvar h`s'`t'
			qui gen double `h`s'`t''=(1/`p1'^2)*(`dp_`t'')*(`dp_`s'')-(1/`p1')*(`d2p_`s'_`t'') 		if $ML_y1==1 & $ML_samp
			qui replace `h`s'`t''=(1/(1-`p1')^2)*(`dp_`t'')*(`dp_`s'')+(1/(1-`p1'))*(`d2p_`s'_`t'') 	if $ML_y1==0 & $ML_samp
			qui sum `h`s'`t''													if $ML_samp
			matrix `negH'[`s',`t']=r(mean)*r(N)
			if `s'!=`t' matrix `negH'[`t',`s']=r(mean)*r(N)
			local t=`t'+1
		}
		local s=`s'+1
	}	
end



