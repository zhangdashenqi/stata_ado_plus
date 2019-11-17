program define xthsig, rclass
syntax, [ n(integer 50) t(integer 5) thnum(integer 1) grid(integer 300) ]
tempvar id tn u x1 x2 q e r y
tempname b1 b21 b22 gamma gam gamma_hat gamma_L gamma_U Fres pr
scalar `b1'=1
scalar `b21'=1
scalar `b22'=2
scalar `gamma'=1

* significance level: DGP under Ho,  estimate both models under Ho and Ha, bootstrap
qui {
	clear
	set obs `n'
	gen `id' = _n
	expand `t'
	sort `id' 
	by `id': gen `tn' = _n
	xtset `id' `tn'
	gen double `u' = rchi2(1) - 1  // individual effect
	by `id': replace `u' = `u'[1]
	gen double `x1' = rchi2(1)
	gen double `x2' = rchi2(1)
	gen double `q' = rchi2(1) 
	gen double `e' = rnormal(0,1)  // random error
	gen `r' = (`q'>=`gamma')
	if `thnum'==1 {  // * Ho: linear model; Ha: single threshold model
		gen double `y' = 1 + `b1'*`x1' + `b21'*`x2' + `u' + `e'
		xthreg `y' `x1', rx(`x2') qx(`q') thnum(`thnum')  grid(`grid') bs(300) nobslog noreg
		matrix `Fres' = e(Fstat)
		scalar `pr' = `Fres'[1,4]
	}
	else if `thnum'==2 { // Ho: single model; Ha: double threshold model
		gen double `y' = 1 + `b1'*`x1' + `r'*`b21'*`x2' + (1-`r')*`b22'*`x2' + `u' + `e'
		xthreg `y' `x1', rx(`x2') qx(`q') thnum(`thnum')  grid(`grid') bs(200 200) nobslog noreg
		matrix `Fres' = e(Fstat)
		scalar `pr' = `Fres'[2,4]
	}
}
return scalar pr = `pr'
end
