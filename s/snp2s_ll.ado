*! Version 8 (02/06/2006)
*! De Luca Giuseppe
program define snp2s_ll
	version 9
	args lnf xb2 xb1
	local y2 "$ML_y1" 
	local y1 "$ML_y2" 

	* Identify intercept parameters
		tempname con1 con2
		scalar `con1'=${Con1}
		scalar `con2'=${Con2}

	* Central moments of the standardized Gaussian distribution
		local Kmax = 2*max(${K1},${K2})
		local K12 = 2*${K1}
		local K22 = 2*${K2}
		local upto=`Kmax'+1
		tempname mu0 mu1 mu`upto'
		scalar `mu0' = 1
		scalar `mu1' = 0
		scalar `mu`upto'' = 0
		forvalues i=2(1)`Kmax' {
			local i2=`i'-2
			tempname mu`i'
			scalar `mu`i'' = (`i'-1)*`mu`i2''
		}

	* Identify g_{i,j} parameters
		macro shift 3
		tempname g_0_0
		scalar `g_0_0' = 1
		forvalues i=1(1)${K1} {
			tempname g_`i'_0
			scalar `g_`i'_0' = 0
			forvalues j=1(1)${K2} {
				if `i'==1 {
					tempname g_0_`j' 
					scalar `g_0_`j'' = 0
				}
				tempname g_`i'_`j' 
				qui sum `1'
				scalar `g_`i'_`j''=r(max)
				macro shift
			}
		}

	* Compute tau^{*}_{i,j} coefficients and normalization factor 
		tempname theta
		scalar `theta' = 0
		forvalues i=0(1)`K12' {						
			local ai=max(0,`i'-${K1})
			local bi=min(`i',${K1})
			forvalues j=0(1)`K22' {						
				local aj=max(0,`j'-${K2})
				local bj=min(`j',${K2})
				tempname gs_`i'_`j' 
				scalar `gs_`i'_`j''=0
				forvalues is=`ai'(1)`bi' {
					forvalues js=`aj'(1)`bj' {
						local iis = `i'-`is'
						local jjs = `j'-`js'
						scalar `gs_`i'_`j''=`gs_`i'_`j''+ (`g_`is'_`js'' * `g_`iis'_`jjs'')
					}
				}
				scalar `theta'=`theta' + `gs_`i'_`j'' * `mu`i'' * `mu`j'' 
			}
		}

	* Compute factors that are relevant for the probabilities 
		tempvar Au1 Au1L1 Au1L2 Au2 Au2L1 Au2L2 A1 A2 A3
		qui gen double `Au1' = 1
		qui gen double `Au1L1' = 1
		qui gen double `Au1L2' = 0
		qui gen double `Au2' = 1   if `y1'==1
		qui gen double `Au2L1' = 1 if `y1'==1
		qui gen double `Au2L2' = 0 if `y1'==1
		qui gen double `A1' = 0
		qui gen double `A2' = 0
		qui gen double `A3' = 0
		forvalues i=1(1)`K12' {
			if `i'>1 {	

				qui replace `Au1'=(`i'-1) * `Au1L2' + ((-`con1'-`xb1')^(`i'-1))	
				if `i'<`K12' {
					qui replace `Au1L2' = `Au1L1' 						
					qui replace `Au1L1' = `Au1' 							
				}
				qui replace `Au2' = 1    if `y1'==1
				qui replace `Au2L1' = 1  if `y1'==1
				qui replace `Au2L2' = 0  if `y1'==1
			}
			forvalues j=1(1)`K22' {
				if `j'>1 {
					qui replace `Au2'=(`j'-1) * `Au2L2' + ((-`con2'-`xb2')^(`j'-1))
					if `j' < `K22' {
						qui replace `Au2L2' = `Au2L1' 						
						qui replace `Au2L1' = `Au2' 
					}
				}
				if (`i'!=1 | `j'<=${K2}) & (`j'!=1 | `i'<=${K1}) {
					qui replace `A1'=`A1' + `gs_`i'_`j'' * `Au1' * `Au2'
					local temp_i=2*int(`i'/2)
					local temp_j=2*int(`j'/2)
					if `temp_i'==`i' {
						qui replace `A2'=`A2' + `gs_`i'_`j'' * `mu`i'' * `Au2' 
					}
					if `temp_j'==`j' {
						qui replace `A3'=`A3' + `gs_`i'_`j'' * `Au1' * `mu`j'' 
					}
				}
			}
		}	

	* Compute cdf
		tempvar Fu1 Fu2 Fu1u2
		qui gen double `Fu1u2' = norm(-`con1'-`xb1') * norm(-`con2'-`xb2')	 		 	+ 	/*
					    */ `A1' * normden(-`con1'-`xb1') * normden(-`con2'-`xb2')/`theta' 	-	/*
					    */ `A2' * norm(-`con1'-`xb1')    * normden(-`con2'-`xb2')/`theta' 	-   	/*
					    */ `A3' * normden(-`con1'-`xb1') * norm(-`con2'-`xb2')   /`theta'   
		qui gen double `Fu1' = norm(-`con1'-`xb1') - `A3' * normden(-`con1'-`xb1')/`theta'   
		qui gen double `Fu2' = norm(-`con2'-`xb2') - `A2' * normden(-`con2'-`xb2')/`theta' 
 
	* Compute log-likelihood
		qui replace `lnf' = ln(1-`Fu1'-`Fu2'+`Fu1u2') 	if `y1'==1 & `y2'==1
		qui replace `lnf' = ln(`Fu1')  			if `y1'==0
		qui replace `lnf' = ln(`Fu2'-`Fu1u2') 		if `y1'==1 & `y2'==0

end
