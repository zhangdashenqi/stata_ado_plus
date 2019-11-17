*Tests for Unbalanced Error Component Models Under Local Misspecification
*by Sosa Escudero, W. and Bera, A. (2007)
*XTTEST1

*This version 10/8/2006 by Walter Sosa Escudero and Anil Bera
*Updates the 2/14/2001 version, allowing for unbalanced panels.
*For further details on the old version of xttest1 see Sosa-Escudero, W. and Bera, A., 2001, 
*Specification tests for linear panel data models, Stata Technical Bulletin, STB-61, 18-21.


program define xttest1, rclass
	version 7      
	syntax , [UNADjusted]

	if "`e(cmd)'"!="xtreg" { error 301 }
	if "`e(model)'" != "re" {
		di in red "last estimates not xtreg, re"
		error 301
	}
	
	tempvar touse e sum Ti elag em nmis tmin tmax dt hole 
	tempname cur Tn T ee LM1 LM2 LM3 LM4 LM5 LM6 LM7
	tempname SD SD1 A1 B1 a m nn

	qui gen  byte `touse' =e(sample)
	
      _evlist
	local rhs "`s(varlist)'"
      sret clear
	local lhs "`e(depvar)'"
	local ivar "`e(ivar)'"
      qui tsset
	local time "`r(timevar)'"

	quietly	{
		mat b = e(b)
		loc w = colsof(b)-1
		mat b = b[1,1..`w']
		loc x : colfullnames(b)
		mat drop b
		
		tokenize `x'
		local nvars : word count `x'

		sort `e(ivar)' `time'
		egen `tmax' = max(`time'), by(`e(ivar)')
		egen `tmin' = min(`time'), by(`e(ivar)')

		egen `nmis'= rmiss(`x')	
		sum `nmis' if (`time'>`tmin' & `time'<`tmax') & `touse'
		loc maxnmis = r(max)
		if `maxnmis'>0 {
			di in red "missing values encountered"
			error 416
		}

		by `e(ivar)': gen `dt' = D.`time'
		gen `hole'= cond(`dt'==. & `time'>`tmin' & `time'<`tmax', 1, 0)
		sum `hole' if `touse'
		loc maxhole = r(max)
		if `maxhole'>0 {
			di in red "panel has gaps"
			error 498
		}
	}
	
	estimate hold `cur'
	capture {
		regress `lhs' `rhs' if `touse'
		predict double `e' if `touse', resid
	}
	if _rc {
		estimate unhold `cur'
		error _rc
	}
	estimate unhold `cur'
	preserve
	quietly {
            sort `e(ivar)' `time'
		by `e(ivar)': gen double `sum' = cond(_n==_N,sum(`e')^2,.) 
		replace `sum' = sum(`sum')
		scalar `A1' = `sum'[_N]
		replace `sum' = sum(`e'^2)
            	scalar `SD' = `sum'[_N]
            	scalar `A1' = 1-(`A1'/`SD')

		by `e(ivar)': gen `elag' = L.`e'
	       	by `e(ivar)': gen double `em' = `e'
        	by `e(ivar)': replace `em' = . if _n==1
		replace `sum' = sum(`em'^2)
		scalar `SD1' = `sum'[_N]
		replace `sum' = sum(`e'*`elag')
  	        scalar `B1' = `sum'[_N]/`SD1'

		by `e(ivar)': gen long `Ti' = cond(_n==_N,sum(`touse'),.)
		replace `sum'=sum(`Ti'^2)
		scalar `a' = `sum'[_N]
		scalar `m' = e(N)
		scalar `nn' = e(N_g)
	}
	scalar `LM1'=scalar( (0.5 * `m'^2 * `A1'^2 ) / (`a'-`m') )
        scalar `LM2'=scalar(`m'^2 * `B1'^2 / (`m'-`nn')  )
	scalar `LM3'=scalar( `m'^2 *(`A1'+2*`B1')^2 / (2*(`a'-3*`m'+2*`nn')))
	scalar `LM4'=scalar(`LM2'-`LM1' + `LM3')
        scalar `LM5'=scalar(`LM1'+`LM4')
        scalar `LM6'=scalar(- sqrt((0.5 * `m'^2) / (`a'-`m') )* `A1')
        scalar `LM7'=scalar(- sqrt(`m'^2 / (2*(`a'-3*`m'+2*`nn'))) * (`A1'+2*`B1'))
	
	if "`unadjusted'"!=""	{
		#delimit ;
		di _n in gr 
		"Tests for the error component model:" ;
		di _n in gr _col(9) 
			"$S_E_depv[$S_E_ivar,t] = Xb + u[$S_E_ivar] + v[$S_E_ivar,t]" _n
	              _col(12) "v[$S_E_ivar,t] = lambda v[$S_E_ivar,(t-1)] + e[$S_E_ivar,t]";

		di _n in smcl in gr _col(9) "Estimated results:" _n
			_col(26) "{c |}" _col(34) "Var" _col(42) "sd = sqrt(Var)" _n 
			_col(17) "{hline 9}{c +}{hline 29}" ;
			
		qui summ $S_E_depv if `touse' ;
		local skip = 9 - length("$S_E_depv") ;
		di _col(16) _skip(`skip') in gr "$S_E_depv {c |}  " in ye
			%9.0g _result(4) _skip(6) %9.0g sqrt(_result(4)) ;
		di _col(24) in gr "e {c |}  " in ye 
			%9.0g scalar(S_E_eit)^2 _skip(6) scalar(S_E_eit) ;
		di _col(24) in gr "u {c |}  "  in ye 
			%9.0g scalar(S_E_ui)^2 _skip(6) scalar(S_E_ui) ;

		di _n in gr _col(9) "Tests:" _n 
			_col(12) in blue "Random Effects, Two Sided:" _n in gr
			_col(12) "LM(Var(u)=0)          =" in ye %8.2f `LM1' in gr 
			_col(44) "Pr>chi2(1) = " in ye %7.4f 
			chiprob(1,`LM1') in gr _n

			_col(12) "ALM(Var(u)=0)         =" in ye %8.2f `LM3' in gr 
			_col(44) "Pr>chi2(1) = " in ye %7.4f 
			chiprob(1,`LM3') in gr _n _n
			
			_col(12) in blue "Random Effects, One Sided:" _n in gr
			_col(12) "LM(Var(u)=0)          =" in ye %8.2f `LM6' in gr 
			_col(44) "Pr>N(0,1)  = " in ye %7.4f 
			1-normprob(`LM6') in gr _n

			_col(12) "ALM(Var(u)=0)         =" in ye %8.2f `LM7' in gr 
			_col(44) "Pr>N(0,1)  = " in ye %7.4f 
			1-normprob(`LM7') in gr _n _n

			_col(12) in blue "Serial Correlation:" _n in gr
			_col(12) "LM(lambda=0)          =" in ye %8.2f `LM2' in gr 
			_col(44) "Pr>chi2(1) = " in ye %7.4f 
			chiprob(1,`LM2') in gr _n

			_col(12) "ALM(lambda=0)         =" in ye %8.2f `LM4' in gr 
			_col(44) "Pr>chi2(1) = " in ye %7.4f 
			chiprob(1,`LM4') in gr _n _n

			_col(12) in blue "Joint Test:" _n in gr
			_col(12) "LM(Var(u)=0,lambda=0) =" in ye %8.2f `LM5' in gr 
			_col(44) "Pr>chi2(2) = " in ye %7.4f 
			chiprob(2,`LM5') in gr _n;
		#delimit cr
		}

	else	{
		#delimit ;
		di _n in gr 
		"Tests for the error component model:" ;
		di _n in gr _col(9) 
			"$S_E_depv[$S_E_ivar,t] = Xb + u[$S_E_ivar] + v[$S_E_ivar,t]" _n
	              _col(12) "v[$S_E_ivar,t] = lambda v[$S_E_ivar,(t-1)] + e[$S_E_ivar,t]";

		di _n in smcl in gr _col(9) "Estimated results:" _n
			_col(26) "{c |}" _col(34) "Var" _col(42) "sd = sqrt(Var)" _n 
			_col(17) "{hline 9}{c +}{hline 29}" ;
			
		qui summ $S_E_depv if `touse' ;
		local skip = 9 - length("$S_E_depv") ;
		di _col(16) _skip(`skip') in gr "$S_E_depv {c |}  " in ye
			%9.0g _result(4) _skip(6) %9.0g sqrt(_result(4)) ;
		di _col(24) in gr "e {c |}  " in ye 
			%9.0g scalar(S_E_eit)^2 _skip(6) scalar(S_E_eit) ;
		di _col(24) in gr "u {c |}  "  in ye 
			%9.0g scalar(S_E_ui)^2 _skip(6) scalar(S_E_ui) ;

		di _n in gr _col(9) "Tests:" _n 
			_col(12) in blue "Random Effects, Two Sided:" _n in gr
			_col(12) "ALM(Var(u)=0)         =" in ye %8.2f `LM3' in gr 
			_col(44) "Pr>chi2(1) = " in ye %7.4f 
			chiprob(1,`LM3') in gr _n _n
			
			_col(12) in blue "Random Effects, One Sided:" _n in gr
			_col(12) "ALM(Var(u)=0)         =" in ye %8.2f `LM7' in gr 
			_col(44) "Pr>N(0,1)  = " in ye %7.4f 
			1-normprob(`LM7') in gr _n _n

			_col(12) in blue "Serial Correlation:" _n in gr
			_col(12) "ALM(lambda=0)         =" in ye %8.2f `LM4' in gr 
			_col(44) "Pr>chi2(1) = " in ye %7.4f 
			chiprob(1,`LM4') in gr _n _n

			_col(12) in blue "Joint Test:" _n in gr
			_col(12) "LM(Var(u)=0,lambda=0) =" in ye %8.2f `LM5' in gr 
			_col(44) "Pr>chi2(2) = " in ye %7.4f 
			chiprob(2,`LM5') in gr _n;
		#delimit cr
	}


	return scalar N		  = e(N)

	if "`unadjusted'"!=""	{
		return scalar jt_lm_df	  = 2
		return scalar jt_lm_p	  = chiprob(2,`LM5')
		return scalar jt_lm	  = `LM5'
	}

	return scalar sc_alm_df	  = 1
	return scalar sc_alm_p	  = chiprob(1,`LM4')
	return scalar sc_alm	  = `LM4'

	if "`unadjusted'"!=""	{
	return scalar sc_lm_df	  = 1
	return scalar sc_lm_p	  = chiprob(1,`LM2')
	return scalar sc_lm	  = `LM2'	
	}

	return scalar reos_alm_p  = 1-normprob(`LM7')
	return scalar reos_alm	  = `LM7'
	return scalar reos_lm_p   = 1-normprob(`LM6')
	return scalar reos_lm	  = `LM6'

	return scalar rets_alm_df = 1
	return scalar rets_alm_p  = chiprob(1,`LM3')
	return scalar rets_alm	  = `LM3'
	
	if "`unadjusted'"!=""	{
	return scalar rets_lm	  = 1
	return scalar rets_lm	  = chiprob(1,`LM1')
	return scalar rets_lm	  = `LM1'
	}
	
	restore
	
end
exit
