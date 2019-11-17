*! Version 9 (06/06/2006)
*! De Luca Giuseppe
*! Semi-nonparametric estimation of sequential binary choice model

program define snp2s, eclass
	version 9.0
	if replay() {
		if "`e(cmd)'" ~= "snp2s" error 301
		Replay `0'
	}
	else Estimate `0'
end

program define Estimate, eclass

	* Identify variable 
		gettoken depvar 0 : 0 , parse(" =,[")
		gettoken equals rest : 0 , parse(" =")
		if "`equals'" == "=" local 0 `"`rest'"'
		local depvarn : subinstr local depvar "." "_"

	* Syntax
		syntax varlist(min=1) [pw fw iw] [if] [in] , SELect(string)						///
			[noCONstant OFFset(varname numeric) order1(integer 3) order2(integer 3) 		///
			Robust From(string) dplot(string) Level(passthru) noLOg * ]

	* Identify Selection equation 
		Select seldep selind selnc seloff : `"`select'"'
		local selname : subinstr local seldep "." "_"

	* Options
		local nc `constant'
		local snc `selnc'
		if "`seloff'"  != "" local soff "offset(`seloff')" 
		if "`offset'"  != "" local off "offset(`offset')" 
		if "`weight'" != "" local wgt [`weight'`exp']
		mlopts mlopts, `options'
		di in gr "`mlopts'"

	* Estimation sample 
		marksample touse, novarlist
		markout `touse' `seldep' `selind' `seloff' `cluster', strok
		marksample touse2
		markout `touse2' `depvar' `varlist' `offset'
		qui replace `touse' = 0 if `seldep' & !`touse2'

	* Check estimation sample 
		qui count if `touse' 
		if r(N)==0 error 2000 
		qui count if `touse2' 
		if r(N)==0 error 2000 

	* Check order of the SNP polynomial 
		global K1=`order1'
		global K2=`order2'
		if $K1<=0 | $K2<=0 {
			di _n "Order R1 and R2 of SNP polynomial must be a positive integer"
			exit
		}
		di in gr "Order of SNP polynomial - (R1,R2)=(" in ye ${K1} in gr "," in ye ${K2} in gr ")" 

	* Starting values 
		local vareq2 `"`varlist'"'
		tokenize `vareq2'
		local k2: word count `vareq2'
		local vareq1 `"`selind'"'
		tokenize `vareq1'
		local k1: word count `vareq1'
		local j=`k2'+2
		local k=`k2'+`k1'+1
		cap heckprob `depvar' `varlist' `wgt' if `touse', 	///
			sel(`seldep'=`selind' , `snc' `soff') `nc' `off'
		if "`snc'"=="" global Con1=_b[`selname':_cons]
		else global Con1=0
		if "`nc'"=="" global Con2=_b[`depvarn':_cons]
		else {
			global Con2=0
			local j=`j'-1
			local k=`k'-1
		}
		tempname b00 b0 b1 b2 llh0 lrstat
		matrix `b00' = e(b)
		matrix `b1' = `b00'[1..1,1..`k2']
		matrix `b2' = `b00'[1..1,`j'..`k']
		matrix `b0' = (`b1' , `b2')

		local gpar ""
		local gmatn ""
		local freepar=0
		forvalues i=1(1)$K1 {
			forvalues j=1(1)$K2 {
				local freepar=`freepar'+1
				local gpar "`gpar' (g_`i'_`j':)"
				local gmatn "`gmatn' g_`i'_`j':_cons"
			}
		}

	* Estimation with default starting values
		if "`from'" == "" {
			tempname g0 start
			mat def `g0' = J(1,`freepar',0)
			matrix colnames `g0' = `gmatn'
			mat def `start' = (`b0',`g0')
			ml model lf snp2s_ll (`depvarn':`depvar'=`varlist', noconst `off') 			///
				(`selname':`seldep'=`selind', noconst `soff') `gpar' `wgt' if `touse' , 	///
				max miss nopreserve difficult `robust' init(`start') search(off) 			///
				title("SNP Estimation of Sequential Bivariate Model") `log'  `mlopts' 
		}

	* Estimation with specified starting values
		else {
			ml model lf snp2s_ll (`depvarn':`depvar'=`varlist', noconst) 			///
				(`selname':`seldep'=`selind', noconst) `gpar' `wgt' if `touse' , 		///
				max miss nopreserve difficult `robust' init(`from') search(off) 		///
				title("SNP Estimation of Sequential Bivariate Model") `log'  `mlopts' 
		}

	* Get SNP parameters (tau_{i,j})
		tempname allpar snppar
		matrix `allpar' = e(b)
		local numpar = colsof(`allpar')
		mat `snppar' = `allpar'[1,(`numpar'-`freepar'+1)..colsof(`allpar')]
		local g_0_0 = 1
		local temp = 1
		forvalues i=1(1)${K1} {
			tempname g_`i'_0
			scalar  `g_`i'_0' = 0
			forvalues j=1(1)${K2} {
				if `i'==1 {
					tempname g_0_`j' 
					scalar `g_0_`j'' = 0
				}
				tempname g_`i'_`j'
				scalar `g_`i'_`j'' =`snppar'[1,`temp']
				local temp=`temp'+1
			}
		}
	
	* Central moments of the standardized Gaussian distribution
		local Kmax = 2*max(${K1},${K2})+4
		local K12 = 2*${K1}
		local K22 = 2*${K2}
		tempname mu0 mu1 
		scalar `mu0' = 1
		scalar `mu1' = 0
		forvalues i=2(1)`Kmax' {
			local i2=`i'-2
			tempname mu`i'
			scalar `mu`i'' = (`i'-1)*`mu`i2''
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

	* Compute uncentered moments
		forvalues i=1(1)4 {
			tempname mom_u1_`i' mom_u2_`i'
			scalar `mom_u1_`i''=0
			scalar `mom_u2_`i''=0
		}
		tempname mom_u1_u2
		scalar `mom_u1_u2'=0
		forvalues i=0(1)`K12' {
			forvalues j=0(1)`K22' {
				local h1=`i'+1
				local h2=`j'+1
				scalar `mom_u1_u2' = `mom_u1_u2' + (`gs_`i'_`j''*`mu`h1''*`mu`h2'')
				forvalues t=1(1)4 {
					local h3=`i'+`t'
					local h4=`j'+`t'
					scalar `mom_u1_`t'' = `mom_u1_`t'' + (`gs_`i'_`j''*`mu`h3''*`mu`j'')
					scalar `mom_u2_`t'' = `mom_u2_`t'' + (`gs_`i'_`j''*`mu`i''*`mu`h4'')
				}
			}
		}
		scalar `mom_u1_u2'=`mom_u1_u2'/`theta'
		forvalues t=1(1)4 {
			scalar `mom_u1_`t'' = `mom_u1_`t''/`theta'
			scalar `mom_u2_`t'' = `mom_u2_`t''/`theta'
		}

	* Estimation return
		ereturn local cmd "snp2"
		ereturn scalar R1=$K1
		ereturn scalar R2=$K2
		ereturn scalar mean1=`mom_u1_1'
		ereturn scalar var1=`mom_u1_2'-(`mom_u1_1')^2
		ereturn scalar sd1= sqrt(e(var1))
		ereturn scalar ske1= (`mom_u1_3'+2*(`mom_u1_1'^3)-3*`mom_u1_1'*`mom_u1_2')/(e(sd1)^3)
		ereturn scalar kurt1= (`mom_u1_4'+6*(`mom_u1_1'^2)*`mom_u1_2'-4*`mom_u1_1'*`mom_u1_3'-3*(`mom_u1_1'^4))/(e(var1)^2)
		ereturn scalar mean2=`mom_u2_1'
		ereturn scalar var2=`mom_u2_2'-(`mom_u2_1')^2
		ereturn scalar sd2= sqrt(e(var2))
		ereturn scalar ske2= (`mom_u2_3'+2*(`mom_u2_1'^3)-3*`mom_u2_1'*`mom_u2_2')/(e(sd2)^3)
		ereturn scalar kurt2= (`mom_u2_4'+6*(`mom_u2_1'^2)*`mom_u2_2'-4*`mom_u2_1'*`mom_u2_3'-3*(`mom_u2_1'^4))/(e(var2)^2)
		ereturn scalar rho=(`mom_u1_u2'-`mom_u1_1'*`mom_u2_1')/(e(sd1)*e(sd2)) 
	
	* Display estimates
		Replay, `level' 

	* Density plots 
		if "`dplot'"!="" {
			local name: word 1 of `dplot'

			local pol1 ""
			forvalues i=0(1)`K12' {
				local gam_`i'=0
				forvalues j=0(1)`K22' {	
					local gam_`i'=`gam_`i''+`gs_`i'_`j''*`mu`j''
				}
				if `i'< `K12' local pol1 "`pol1' `gam_`i''* x^(`i') + "
				else local pol1 "`pol1' `gam_`i''*x^(`i') "
			}

			local pol2 ""
			forvalues j=0(1)`K22' {
				local del_`j'=0
				forvalues i=0(1)`K12' {	
					local del_`j'=`del_`j''+`gs_`i'_`j''*`mu`i''
				}
				if `j'<`K22' local pol2 "`pol2' `del_`j''*x^(`j') +"
				else local pol2 "`pol2' `del_`j''*x^(`j')"
			}

			qui twoway 													///
				(function SNP=[1/`theta']*[normd(x)]* [`pol1'] , range(-5 5)) 			///
				(function Normal=exp(-(x-e(mean1))^2/(2*e(sd1)^2))/(sqrt(2*c(pi))*e(sd1))	///
					, range(-5 5) lp(dash_dot) lc(red))							///
				, xtitle("Sel. eq.") ytitle(Density) xlabel(-5(1)5) ylabel(0(.1).4)		///
				legend(off) graphr(c(white))									///
				name(`name'_1, replace) saving(`name'_1, replace)		

			qui twoway 													///
				(function SNP=[1/`theta']*[normd(x)]* [`pol2'] , range(-5 5)) 			///
				(function Normal=exp(-(x-e(mean2))^2/(2*e(sd2)^2))/(sqrt(2*c(pi))*e(sd2))	///
					, range(-5 5) lp(dash_dot) lc(red))							///
				, xtitle("Main Eq.") ytitle(Density) xlabel(-5(1)5) ylabel(0(.1).4)		///
				legend(off) graphr(c(white))									///
				name(`name'_2, replace) saving(`name'_2, replace)	

			qui gr combine `name'_2 `name'_1, name(`name', replace) saving(`name', replace) graphr(c(white))	
		}
end


program define Select
	args seldep selind selnc seloff colon sel_eqn

	gettoken dep rest : sel_eqn, parse(" =")
	gettoken equal rest : rest, parse(" =")

	if "`equal'" == "=" { 
		tsunab dep : `dep'
		c_local `seldep' `dep' 
	}
	else	local rest `"`sel_eqn'"'
	
	local 0 `"`rest'"'
	syntax [varlist(numeric default=none)] 	/*
		*/ [, noCONstant OFFset(varname numeric) ]

	if "`varlist'" == "" {
		di in red "no variables specified for selection equation"
		exit 198
	}

	c_local `selind' `varlist'
	c_local `selnc' `constant'
	c_local `seloff' `offset'
end



program define Replay
	syntax [, Level(int $S_level)]
	ml di, level(`level') neq(2) plus
	DispC 
	DispSNP `level'
	DispMOM
end 


program define DispC
	di  in gr "Intercepts:  {c |}"										///
	  _n _column(7) "_cons1 {c |}  " _column(17) in ye %9.0g $Con1 _column(32) in gr "Fixed"	///
	  _n  _column(7) "_cons2 {c |}  " _column(17) in ye %9.0g $Con2 _column(32) in gr "Fixed"	///
	  _n in gr "{hline 13}{c +}{hline 64}"
end

program define DispSNP
	local level = `1'
	di in gr "SNP coefs:   {c |}"
	forvalues i=1(1)${K1} {
		forvalues j=1(1)${K2} {
			_diparm g_`i'_`j', level(`level') label("       g_`i'_`j'")
		}
	}
	di in gr "{hline 13}{c BT}{hline 64}"
end

program define DispMOM
	di "Estimated moments of errors distribution" 								///
		_n _column(5) "Main equation" 									///
		_column(39) _column(45) "Selection equation" 							///
		_n _column(5) in gr "Standard Deviation =" _column(25) in ye %9.0g e(sd2)		///
		_column(39) _column(45) in gr "Standard Deviation =" _column(65) in ye %9.0g e(sd1)	///
		_n _column(5) in gr "Variance = " _column(25) in ye %9.0g e(var2)				///
		_column(39) _column(45) in gr "Variance = " _column(65) in ye %9.0g e(var1)		///
		_n _column(5) in gr "Skewness = " _column(25) in ye %9.0g e(ske2) 			///
		_column(39) _column(45) in gr "Skewness = " _column(65) in ye %9.0g e(ske1)		///
		_n _column(5) in gr "Kurtosis = " _column(25) in ye %9.0g e(kurt2) 			///
		_column(39) _column(45) in gr "Kurtosis = " _column(65) in ye %9.0g e(kurt1)		///
		_n in gr "{hline 78}"											///
		_n in gr "Estimated correlation coefficient"							///
		_n _column(5) in gr "rho = " _column(25) in ye %9.0g e(rho)					///
		_n in gr "{hline 78}"
end

