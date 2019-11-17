*! Version 1 (12/06/2006)
*! De Luca Giuseppe
*! Semi-nonparametric estimation of univariate binary-choice model


program define snp, eclass
	version 9.0
	if replay() {
		if "`e(cmd)'" ~= "snp" error 301
		Replay `0'
	}
	else Estimate `0'
end


program define Estimate, eclass

	syntax varlist [pw fw iw] [if] [in]  [ , 					///
		noCONstant OFFset(varname numeric) order(integer 3) Robust 	///
		From(string) dplot(string) Level(passthru) noLOg *]

	* Selection of the sample 
		marksample touse

	* Variables definition
		tokenize `varlist'
		local y "`1'"
		mac shift
		local x "`*'"
		markout `touse' `y' `x' `offset'
		quietly count if `touse' 

	* Check estimation sample
		if r(N) == 0 { 
			error 2000 
		}

	* Options 
		local nc `constant'
		if "`offset'" != "" local off "offset(`offset1')" 
		if "`weight'" != "" local wgt [`weight'`exp']
		mlopts mlopts, `options'
		di in gr "`mlopts'"

	* Order of the univariate Hermite polynomial expansion 
	global K=`order'
	if $K<=0 {
		di _n "Order of SNP polynomial must be a positive integer"
		exit
	}
	else {
	if $K==1 | $K==2 {
		di _n "Order = " $K " gives model equivalent to Probit:"
		probit `y' `x' `wgt' if `touse'
	}
	else {
		di _n in green "Order of SNP polynomial - R=" in yellow $K

		* From option and starting values 
			qui probit `y' `x' `wgt' if `touse', `nc' `off'
			if "`nc'"=="" global Con=_b[_cons]
			else global Con=0
			local ncov=e(df_m)
			tempname b00 b0 g0 llh0 lrstat 
			matrix `b00' = e(b)
			matrix `b0' = `b00'[1..1,1..`ncov']
			matrix coleq `b0' = `y':
			scalar `llh0'=e(ll)

			local param ""
			local bst ""
			forvalues i=1(1) $K {
				local param "`param' (g_`i':)"
				local bst "`bst' g_`i':_cons"
			}
			if "`from'" == "" {
				tempname g0 start
				mat def `g0' = J(1,$K,0)
				matrix colnames `g0' = `bst'
				mat def `start' = (`b0',`g0')

				* Estimation with default startting values
				ml model lf snp_ll (`y': `y'=`x', offset(`offset') nocons) `param' `wgt' if `touse' , 	///
					max nopreserve difficult `robust' init(`start') search(off) 				///
					title("SNP Estimation of Binary-Choice Model") `log'  `mlopts' 
			}
			else {
				* Estimation with specified startting values
				ml model lf snp_ll (`y': `y'=`x', offset(`offset') nocons) `param' `wgt' if `touse' , 	///
					max nopreserve difficult `robust' init(`from') search(off) 					///
					title("SNP Estimation of Binary-Choice Model") `log'  `mlopts' 
			}	
		
		* Compute and display LR statistics for testing Gaussianity 
			global lrstat=2*(e(ll)-`llh0')
	
		* Get SNP parameters (tau_{i,j})
			tempname allpar snppar
			matrix `allpar' = e(b)
			mat `snppar' = `allpar'[1,(`ncov'+1)..colsof(`allpar')]
			tempname g_0
			scalar `g_0' = 1
			local temp=1
			forvalues i=1(1)${K} {
				tempname g_`i'
				scalar `g_`i'' =`snppar'[1,`temp']
				local temp=`temp'+1
			}

		* Central moments of the standardized Gaussian distribution
			local K2 = 2*${K}
			local upto = `K2'+ 4
			tempname mu0 mu1
			scalar `mu0' = 1
			scalar `mu1' = 0
			forvalues i=2(1)`upto' {
				local i2=`i'-2
				tempname mu`i'
				scalar `mu`i'' = (`i'-1)*`mu`i2''
			}
	
		* Compute tau^{*}_{i} coefficients and normalization factor 
			tempname theta
			scalar `theta' = 0
			forvalues i=0(1)`K2' {		
				local ai=max(0,`i'-$K)
				local bi=min(`i',$K)
				tempname gs_`i' 
				scalar `gs_`i''=0
				forvalues is=`ai'(1)`bi' {
					local iis = `i'-`is'
					scalar `gs_`i''= `gs_`i'' + (`g_`is'' * `g_`iis'')
				}
				scalar `theta'=`theta' + `gs_`i'' * `mu`i'' 
			}
	
		* Compute uncentered moments
			forvalues j=1(1)4 {
				tempname mom_`j'
				scalar `mom_`j''=0
			}
			forvalues i=0(1)`K2' {
				forvalues j=1(1)4 {
					local ipj = `i'+`j'
					scalar `mom_`j'' = `mom_`j'' + (`gs_`i''*`mu`ipj'')
				}
			}
			forvalues j=1(1)4 {
				scalar `mom_`j'' = `mom_`j''/`theta'
			}

		* Estimation return
			ereturn local cmd "snp"
			ereturn scalar R=$K
			global cm_3 = `mom_3' + (2*(`mom_1'^3)) - (3*`mom_1'*`mom_2')
			global cm_4 = `mom_4' + (6*(`mom_1'^2)*`mom_2') - (4*`mom_1'*`mom_3') - (3*(`mom_1'^4))
			ereturn scalar mean= `mom_1'
			ereturn scalar var= `mom_2'-(`mom_1'^2)
			ereturn scalar sd= sqrt(e(var))
			ereturn scalar ske= ${cm_3}/(e(sd)^3)
			ereturn scalar kurt=${cm_4}/(e(sd)^4)
	
		* Display estimates
			Replay, `level' 

		* Density plots 
			if "`dplot'"!="" {
				local name: word 1 of `dplot'

				local pol ""
				forvalues i=0(1)`K2' {
					if `i'< `K2' local pol "`pol' `gs_`i''*x^`i'+"
					else local pol "`pol' `gs_`i''*x^`i'"
				}

				qui twoway 												///
					(function SNP=[1/`theta']*[normd(x)]* [`pol'] , range(-5 5)) 		///
					(function Normal=exp(-(x-e(mean))^2/(2*e(sd)^2))/(sqrt(2*c(pi))*e(sd))	///
						, range(-5 5) lp(dash_dot) lc(red))						///
					, xtitle(" ") ytitle(Density) xlabel(-5(1)5) ylabel(0(.1).4)		///
					legend(off) graphr(c(white))								///
					name(`name', replace) saving(`name', replace)		
			}

		}
	}

end

program define Replay
	syntax [, Level(int $S_level)]
	ml di, level(`level') neq(1) plus
	DispC 
	DispSNP `level'
	DispLRT
	DispMOM
end 

program define DispC
	di _column(8) "_cons {c |}  " _column(17) in yellow %9.0g $Con _column(32) in gr "Fixed"
	di in gr "{hline 13}{c +}{hline 64}"
end

program define DispSNP
	local level = `1'
	_diparm g_1, level(`level') label("SNP coefs: 1")
	forvalues i=2(1)$K {
		_diparm g_`i', level(`level') label("           `i'")
	}
	di in gr "{hline 13}{c BT}{hline 64}"
end

program define DispLRT
	di "Likelihood ratio test of Probit model against SNP model:" 				/*
	*/ _n "Chi2(" $K-2 ") statistic = " _column(25) in ye %9.0g $lrstat _column(40) 	/*
	*/ in gr "(p-value = " in ye %9.0g chiprob($K-2,$lrstat) in gr ")" 			/*
	*/ _n "{hline 78}"
end

program define DispMOM
			di "Estimated moments of error distribution:" 									/*
			*/ _n "Variance = " _column(25) in ye %9.0g e(var) 								/*
			*/ _column(40) in gr "Standard Deviation = " _column(65) in ye %9.0g e(sd) 				/*
			*/ _n in gr "3rd moment = " _column(25) in ye %9.0g ${cm_3} 						/*
			*/ _column(40) in gr "Skewness = " _column(65) in ye %9.0g e(ske) 					/*
			*/ _n in gr "4th moment = " _column(25) in ye %9.0g ${cm_4} _column(40) in gr "Kurtosis = " 	/*
			*/ _column(65) in ye %9.0g e(kurt) 										/*
			*/ _n in gr "{hline 78}"
end
