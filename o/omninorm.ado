*! Version 1.0.3   2328 cfb 
* Omnibus normality test, Doornik / Hansen 1994
* http://ideas.uqam.ca/ideas/data/Papers/wuknucowp9604.html
* from normtest.ox
* requires matmap (NJC) and _gstdn
* 1.0.3: correct df to 2*k

program define omninorm, rclass
	version 6
	syntax varlist(ts) [if] [in] 
	marksample touse
	qui count if `touse' 
    if r(N) == 0 { error 2000 } 
    local N = r(N)
    local Nm1 = r(N) - 1
	local oneN = 1.0/`N'
	tempname corr evec eval norm std iota skew kurt vy vy2 vys kurt2 lvy vz newskew newkurt omni omnia
	local count: word count `varlist'
* N01
	qui mat accum `corr' = `varlist' if `touse', noc d
	mat `corr' = `corr' / `Nm1'
	mat `corr' = corr(`corr') 
	mat symeigen `evec' `eval' = `corr'
	local nc = colsof(`eval')
	forv i=1/`nc' {
		if `eval'[1,`i']>1e-12 {
			mat `eval'[1,`i']=1.0/sqrt(`eval'[1,`i'])
			}
		else {
			mat `eval'[1,`i']=0 
			}
		}
	local i 0
	foreach var of varlist `varlist' {
		local i = `i'+1
		tempvar s`i'
		qui egen `s`i'' = stdn(`var') if `touse'
		local svl `svl' `s`i''
	}
	mkmat `svl' if `touse',mat(`norm')
	mat `std' = `norm'*`evec'*diag(`eval')*`evec''
* skew, kurt
	matmap `std' `skew',map(@^3)
	matmap `std' `kurt',map(@^4)
	mat `iota'=J(1,`N',`oneN')
	mat `skew'=`iota'*`skew'
	mat `kurt'=`iota'*`kurt'
	mat `iota' = J(1,`nc',1)
* skewsu
		local nsk = cond(`N'<8,8,`N')
		local nsk2 = `nsk'^2
		local beta = 3 * (`nsk2'+27*`nsk'-70)/((`nsk'-2)*(`nsk'+5)) * ((`nsk'+1)/(`nsk'+7)) * ((`nsk'+3)/(`nsk'+9))
		local w2 = -1 + sqrt(2*(`beta' - 1))
		local delta = 1 / sqrt(log(sqrt(`w2')))
		local alfa = sqrt(2/(`w2' - 1))
		mat `vy' = `skew' * sqrt((`nsk'+1)*(`nsk'+3)/(6*(`nsk'-2))) / `alfa'	
*		vy = delta * log(vy + sqrt(vy .^ 2 + 1))
		matmap `vy' `vy2',map(@^2)
		mat `vy2'=`vy2'+`iota'
		matmap `vy2' `vys',map(@^0.5)
		mat `vys' = `vy' + `vys'
		matmap `vys' `lvy',map(log(@))
		mat `newskew' = `lvy' * `delta'
* kurtgam
		local delta = ((`nsk'+5)/(`nsk'-3)) * ((`nsk'+7)/(`nsk'+1)) / (6*(`nsk2'+15*`nsk'-4))
		local a = (`nsk'-2) * (`nsk2'+27*`nsk'-70) * `delta'
    	local c = (`nsk'-7) * (`nsk2'+2*`nsk'-5) * `delta'
    	local k = (`nsk'*`nsk2'+37*`nsk2'+11*`nsk'-313) * `delta' / 2
    	local r = 1 + `c' / `k'
    	local p = 3 * (`nsk'-1)/(`nsk'+1) - `r' *6*(`nsk'-2)/((`nsk'+1)*(`nsk'+3))
	    matmap `skew' `vy2',map(@^2)
    	mat `vz' = `c'*`vy2' +`a'*`iota'
*      	kurt = (vKurt - 1 - vSkew .^ 2) * k * 2; 
	    mat `kurt2' = (`kurt' - `iota' - `vy2')*`k'*2
*    	for (i = 0; i < columns(kurt); ++i)      
*        	kurt[0][i] = ( ((kurt[0][i] / (2 * vz[0][i])) ^ (1/3)) - 1 +
*            1/(9*vz[0][i])) * sqrt(9*vz[0][i]);
		mat `newkurt' = `kurt'
        local i 0
    	while `i'<`nc' {
    	    local i = `i'+1
    		mat `newkurt'[1,`i'] = ((( `kurt2'[1,`i'] / (2 * `vz'[1,`i'])) ^ (1/3)) -1 + 1/(9*`vz'[1,`i']))*sqrt(9*`vz'[1,`i'])
    		}
    	mat `omni' = `newskew'*`newskew'' + `newkurt'*`newkurt''
   		mat `kurt' = `kurt' - 3*`iota'
		mat `omnia' = `N'/6 * `skew'*`skew'' + `N'/24 * `kurt'*`kurt''
	return scalar stat = `omni'[1,1]
	return scalar statasy = `omnia'[1,1]
	return scalar N = `N'
	return scalar k = `nc'
	return scalar df = 2*return(k)
	return scalar p = chiprob(return(df),return(stat))
	return scalar pasy = chiprob(return(df),return(statasy))
	di _n in gr "Omnibus normality statistic (",%2.0f return(k),"variables): " /*
	*/ _col(43) in ye %10.4f return(stat) /*
	*/ in gr " Prob > chi2(" in ye return(df) in gr ") = " in ye %6.4f return(p)
	di in gr "Asymptotic statistic: " /*
	*/ _col(46) in ye %10.4f return(statasy) in gr " Prob > chi2(" in ye return(df) in gr ") = " in ye %6.4f return(pasy)
end
exit
