*! simulation for consistency and coverage rate for single threshold model, no bootstrap
program define xthcov, rclass
syntax, [ n(integer 50) t(integer 5) grid(integer 300) ]
tempvar id tn u x1 x2 q e r y
tempname b1 b21 b22 gamma gam gamma_hat gamma_L gamma_U Fres pr
scalar `b1'=1
scalar `b21'=1
scalar `b22'=2
scalar `gamma'=1
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
	gen double `y' = 1 + `b1'*`x1' + `r'*`b21'*`x2' + (1-`r')*`b22'*`x2' + `u' + `e'
	xthreg `y' `x1', rx(`x2') qx(`q') thnum(1)  grid(`grid') bs(0) nobslog noreg
}
matrix `gam' = e(Thrss)
local gamma_hat =  `gam'[1,1]
local gamma_L   =  `gam'[1,4]
local gamma_U   =  `gam'[1,5]
return scalar gamma_hat = `gamma_hat'
return scalar gamma_L = `gamma_L'
return scalar gamma_U = `gamma_U'
end
