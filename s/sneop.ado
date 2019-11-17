*! Version 1.3.3 June 19 2003 Mark Stewart                    (SJ4-1: st0056)
*! Semi-nonparametric estimation of extended ordered probit model

program define sneop, eclass
	version 7
	syntax varlist [if] [in] [fweight pweight iweight] [ , /*
	*/  order(integer 3) Robust From(string)]
	tempname b0 llh0 lrstat b00 b1
	marksample touse
	tokenize `varlist'
	local lhs "`1'"
	mac shift
	local rhs "`*'"
	markout `touse' `lhs' `rhs'
	quietly count if `touse' 
	if r(N) == 0 { error 2000 }
	if "`weight'" != "" { local wgt [`weight'`exp'] }
	global K=`order'
	if $K<=0 {
		di _n "Order of SNP polynomial must be a positive integer"
		}
	else if $K==1 | $K==2 {
		di _n "Order = " $K " gives model equivalent to Ordered Probit:"
		oprobit `lhs' `rhs' if `touse'
		}
else {
	di _n in green "Order of SNP polynomial = " in yellow $K
	quietly oprobit `lhs' `rhs' `wgt' if `touse'
	matrix `b0' = e(b)
	scalar `llh0'=e(ll)
	global Ncat=e(k_cat)
	global Cut1=_b[_cut1]
	local k=e(df_m)
	di in green "Number of categories = " in yellow $Ncat /*
	*/ in green ", `lhs' assumed coded 1,...," $Ncat
	quietly su `lhs' if `touse'
	if r(min)~=1 {
		di in red "but `lhs' has minimum of " r(min) " instead of 1"
		exit 459
	}
	else if r(max)~=$Ncat {
		di in red "but `lhs' has maximum of " r(max) " instead of " $Ncat
		exit 459
	}
	di in green "1st threshold set to Ordered Probit estimate = " in yellow $Cut1
	if $Ncat>=3 {
		mat `b00'=`b0'[1,(colsof(`b0')+3-$Ncat)..colsof(`b0')]
		mat `b0'=`b0'[1,1..`k']
		mat `b0'=`b0',`b00'
		}
	else {
		mat `b0'=`b0'[1,1..`k']
		}
	local n = $Ncat-1
	local ths ""
	local bnam ""
	local bst "b1:_cons"
	forvalues i=2(1)`n' {
		local ths "`ths' (cut`i':)"
		local bnam "`bnam' cut`i':_cons"
	}
	mat coleq `b0' = eq1	
	matrix colnames `b0' = `rhs' `bnam'
	local start "b1:_cons=0.0"
	local param "(b1:)"
	forvalues i=2(1) $K {
		local start "`start' b`i':_cons=0.0"
		local param "`param' (b`i':)"
		local bst "`bst' b`i':_cons"
	}
	mat def `b00' = J(1,$K,0)
	matrix colnames `b00' = `bst'
	mat def `b1' = `b0',`b00'
	ml model lf sneopll (`lhs'=`rhs', nocons) `ths' `param' if `touse' `wgt', /*
		*/ miss nopreserve /*
		*/ `robust' title("SNP Estimation of Extended Ordered Probit Model")
	if "`from'"=="" {ml init `b1'}
	else {ml init `from'}
	ml maximize, difficult noout
	ml di, first plus
	di "Thresholds 1 {c |}  " _column(17) in yellow %9.0g $Cut1 _column(32) in gr "Fixed"
	forvalues j=2(1)`n' {
		_diparm cut`j', label("           `j'")
	}
	di in gr "{hline 13}{c +}{hline 64}"
	_diparm b1, label("SNP coefs: 1")
	forvalues j=2(1)$K {
		_diparm b`j', label("           `j'")
	}
	di in gr "{hline 13}{c BT}{hline 64}"
	scalar `lrstat'=2*(e(ll)-`llh0')
	est local cmd "sneop"
	di "Likelihood ratio test of OP model against SNP extended model:" /*
	*/ _n "Chi2(" $K-2 ") statistic = " _column(25) in yellow %9.0g `lrstat' _column(40) /*
	*/ in gr "(p-value = " in yellow %9.0g chiprob($K-2,`lrstat') in gr ")" _n "{hline 78}"
	mat `b0' = e(b)
	mat `b00' = `b0'[1,(`k'+$Ncat-1)..colsof(`b0')]
	forvalues i=1(1)$K {
		tempname bx`i'
		scalar `bx`i''=`b00'[1,`i']
	}
	tempname theta mu0 mu1 bx0 cm3 cm4 v sd 
	scalar `bx0' = 1
	scalar `theta' = 0
	local K2 = $K*2
	scalar `mu0' = 1
	scalar `mu1' = 0
	forvalues j=0(1)`K2' {
		local j2 = `j'-2
		tempname c`j'
		scalar `c`j'' = 0
		local ulim = min($K,`j')
		local llim = max(`j'-$K,0)
		forvalues i=`llim'(1)`ulim' {
			local ji = `j'-`i'
			scalar `c`j'' = `c`j'' + (`bx`i''*`bx`ji'')
		}
		if `j'>1 {
			tempname mu`j'
			scalar `mu`j'' = (`j'-1)*`mu`j2''
		}
		scalar `theta' = `theta' + (`c`j''*`mu`j'')
	}
	forvalues j=1(1)4 {
		local jj = `K2'+`j'
		local jj2 = `jj'-2
		tempname mu`jj'
		scalar `mu`jj'' = (`jj'-1)*`mu`jj2''
	}
	forvalues i=1(1)4 {
		tempname mom`i'
		scalar `mom`i''=0
	}
	forvalues j=0(1)`K2' {
		forvalues i=1(1)4 {
			local jpi = `j'+`i'
			scalar `mom`i'' = `mom`i'' + (`c`j''*`mu`jpi'')
		}
	}
	forvalues i=1(1)4 {
		scalar `mom`i'' = `mom`i''/`theta'
	}
	scalar `cm3' = `mom3' + (2*(`mom1'^3)) - (3*`mom1'*`mom2')
	scalar `cm4' = `mom4' + (6*(`mom1'^2)*`mom2') - (4*`mom1'*`mom3') - (3*(`mom1'^4))
	scalar `v' = `mom2'-(`mom1'^2)
	scalar `sd' = sqrt(`v')
	di "Estimated moments of error distribution:" _n "Variance = " _column(25) in yellow %9.0g `v' /*
	*/ _column(40) in gr "Standard Deviation = " _column(65) in yellow %9.0g `sd' /*
	*/ _n in gr "3rd moment = " _column(25) in yellow %9.0g `cm3' /*
	*/ _column(40) in gr "Skewness = " _column(65) in yellow %9.0g (`cm3'/(`sd'^3)) _n /*
	*/ in gr "4th moment = " _column(25) in yellow %9.0g `cm4' _column(40) in gr "Kurtosis = " /*
	*/ _column(65) in yellow %9.0g (`cm4'/(`v'^2)) _n in gr "{hline 78}"
}
end
