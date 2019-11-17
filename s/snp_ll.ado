*! Version 1 (12/06/2006)
*! De Luca Giuseppe
program define snp_ll
	version 9
	args lnf xb
	local y "$ML_y1" 

	* Identify g_{i,j} parameters
		macro shift 2
		tempname g_0
		scalar `g_0' = 1
		forvalues i=1(1)${K} {
			tempname g_`i'
			qui sum `1'
			scalar `g_`i''=r(max)
			macro shift
		}

	* Identify intercept parameters
		tempname con 
		scalar `con'=${Con}

	* Central moments of the standardized Gaussian distribution
		local K2 = 2*${K}
		tempname mu0 mu1
		scalar `mu0' = 1
		scalar `mu1' = 0
		forvalues i=2(1)`K2' {
			local i2=`i'-2
			tempname mu`i'
			scalar `mu`i'' = (`i'-1)*`mu`i2''
		}

	* Compute tau^{*}_{i} coefficients and normalization factor 
		tempname theta
		scalar `theta' = 0
		forvalues i=0(1)`K2' {						
			local ai=max(0,`i'-${K})
			local bi=min(`i',${K})
			tempname gs_`i' 
			scalar `gs_`i''=0
			forvalues is=`ai'(1)`bi' {
				local iis = `i'-`is'
				scalar `gs_`i''=`gs_`i''+ (`g_`is'' * `g_`iis'')
			}
			scalar `theta'=`theta' + `gs_`i'' * `mu`i'' 
		}

	* Compute the A1 factor 
		tempvar Au AuL1 AuL2 A1 
		gen double `A1' = `gs_1'
		gen double `Au' = 0
		gen double `AuL1' = 1
		gen double `AuL2' = 0
		forvalues i=2(1)`K2' {
			quietly replace `Au' = ((`i'-1)*`AuL2') + ((-`con'-`xb')^(`i'-1)) 
			quietly replace `AuL2' = `AuL1' 
			quietly replace `AuL1' = `Au' 
			quietly replace `A1' = `A1' + (`gs_`i''*`Au')
		}

	* Compute cdf
		tempvar Fu 
		qui gen double `Fu' = norm(-`con'-`xb') - `A1' * normden(-`con'-`xb')/`theta'   
 
	* Compute log-likelihood
		qui replace `lnf' = ln(1-`Fu') 	if `y'==1 
		qui replace `lnf' = ln(`Fu')  	if `y'==0
end
