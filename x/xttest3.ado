*! version 1.0.7  1925  CFBaum  (TSJ-1: st0004)
* from xttest0 v1.3.0 and xtreg
* following Greene, 2000, p. 598
* mod 1.0.4 to allow use after xtgls,homo
* mod 1.0.5 to allow any xtgls
* mod 1.0.6 renamed xttest3 to avoid conflict with STB61 
* mod 1.0.7 to correct variance calc in numerator of Wald (per wwg)

program define xttest3, rclass
	version 6.0
	
	if "`e(cmd)'"=="xtreg" { local est 1 }
	if "`e(cmd)'"=="xtgls" { local est 2 }
	if "`est'" ==""	{ error 301 }
	if "`e(model)'" != "fe" & "`est'"=="1" {
		di in red "last estimates not xtreg, fe"
		exit 301
	}
	
*	if "`e(vt)'" != "homoscedastic" & "`est'"=="2" {
*		di in red "last estimates not xtgls, homoscedastic"
*		exit 301
*	}

	if "`*'"!="" { error 198 }
	tempvar touse e e2 si siS esig v iota wald xb

	qui gen byte `touse' = e(sample)
	preserve
	qui drop if `touse'==0
* cross-section indicator
	local ivar "`e(ivar)'"
* number of cross sections
	local ng "`e(N_g)'"
* compute fixed effect e(i,t) and its square
	if "`est'"   == "1" {
		qui predict double `e' if `touse', e
	}
	else {
		qui predict double `xb' if `touse'
		qui gen double `e' = `e(depvar)'-`xb'
	}
	qui gen double `e2'=`e'*`e'
	sort `ivar'
* compute ML variance for each unit 
	qui by `ivar': gen double `si'=sum(`e2')/_n
	qui by `ivar': replace `si'=`si'[_N]
* compute squared deviation of each squared residual from unit variance
	qui gen double `esig'=(`e2'-`si')^2
* allow for unbalanced panel by dividing by T(i) (do not sum twice!)
	qui by `ivar': gen double `v'=sum(`esig')/_n
	qui by `ivar': gen `iota'=_n 
* denominator of modified Wald statistic
 	qui by `ivar': replace `v' = cond(_n==_N,`v'/(`iota'-1),.)
	qui summ `e'
* numerator of modified Wald statistic
* squared deviation of unit variance from overall variance
	qui by `ivar': gen double `siS' = cond(_n==_N,(`si'-r(Var)*(r(N)-1)/r(N))^2,.)
	qui gen double `wald'=`siS'/`v'
* W' is sum over units
	summ `wald',meanonly
	local waldval = `r(sum)'
	
	dis _n in gr "Modified Wald test for groupwise heteroskedasticity" 
	if "`est'"   == "1" {
		dis in gr "in fixed effect regression model" _n
		}
	else {
		dis in gr "in cross-sectional time-series FGLS regression model" _n
	}
	dis "H0: sigma(i)^2 = sigma^2 for all i" _n
	dis in gr "chi2 (`ng')  =" in ye _col(16) %8.2f `waldval'  
	dis in gr "Prob>chi2 = " in ye _col(16) %8.4f chiprob(`ng',`waldval') _n
	return scalar wald = `waldval'
	return scalar df = `ng'
	return scalar p = chiprob(`ng',`waldval')
	
end
exit
