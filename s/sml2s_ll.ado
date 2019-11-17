* Likelihood Evaluator for Bivariate SML without local smoothing
program define sml2s_ll
      version 9.0
	args todo b lnf 

	tempvar lni xb1 xb2 p11 p1
	local y2 "$ML_y1" 
	local y1 "$ML_y2" 

	* Generate indexes
		mleval `xb2'=`b', eq(1)
		mleval `xb1'=`b', eq(2)

	* Kernel regressions
		tempvar bw_1 bw_2
		qui gen double `bw_1'=${bw1}
		qui gen double `bw_2'=${bw2}
		cap gaukern_biv `y1' `xb1'  	  	if $ML_samp			, gen(`p1')  at(`xb1') 		b1(`bw_1')
		cap gaukern_biv `y2' `xb1' `xb2'   	if $ML_samp & `y1'==1	, gen(`p11') at(`xb1' `xb2') 	b1(`bw_2') b2(`bw_2') 

	* Likelihood function 
		qui gen double `lni'= ln(1-`p1') 			if `y1'==0 
		qui replace    `lni'= ln(`p1'*`p11') 		if `y2'==1 & `y1'==1
		qui replace    `lni'= ln(`p1'*(1-`p11')) 		if `y2'==0 & `y1'==1
		mlsum `lnf'=`lni'						if $ML_samp
end
