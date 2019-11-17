
*************
* probit_cd *
*************



program define probit_cd 
  version 8
   di "Probit with one continuous and one dummy variable interacted"
quietly {

  #delimit;
  tempvar xbeta xbeta1 xbeta0 phat phat1 phat0 phi phi1 phi0 d2F_0 d2F_1 linear 
          phat11 phat10 phat01 phat00 probit_cd ie_1 ie_0
          _ieltst _ielse deriv1 deriv2 deriv3 deriv0;
  tempname sum mat123 VAR var lo_ie1 lo_t1;
  #delimit cr

  args touse savedata  savegraph1  savegraph2  y x1 x2 x1x2
  preserve   
  keep if `touse'

  predict `phat'
  predict `xbeta' , xb
  gen `phi' = normd(`xbeta')
  gen `linear' = _b[`x1x2']*`phi'

  replace `x2' = 1
  replace `x1x2' = `x1'*`x2'
  predict `xbeta1' , xb
  gen `phi1' = normd(`xbeta1')
  gen `ie_1' = (_b[`x1'] + _b[`x1x2'])*`phi1'

  replace `x2' = 0
  replace `x1x2' = `x1'*`x2'
  predict `xbeta0', xb
  gen `phi0' = normd(`xbeta0')
  gen `ie_0' = _b[`x1']*`phi0'
  gen `probit_cd' = `ie_1' - `ie_0'
   
  gen `d2F_1'=-`xbeta1'*`phi1'
  gen `d2F_0'=-`xbeta0'*`phi0'

  local _pbt_cd="_probit_ie"
  rename `probit_cd' `_pbt_cd'
 
  gen `deriv1'=`phi1'-`phi0'+_b[`x1']*`x1'*(`d2F_1'-`d2F_0')+_b[`x1x2']*`x1'*`d2F_1'
  gen `deriv2'=(_b[`x1']+_b[`x1x2'])*`d2F_1'
  gen `deriv3'=`phi1'+(_b[`x1']+_b[`x1x2'])*`d2F_1'*`x1'
  gen `deriv0'=(_b[`x1']+_b[`x1x2'])*`d2F_1'-_b[`x1']*`d2F_0'

  macro shift 8
  local nn=101
  while "`1'"~="" {
    tempvar `nn'
    gen ``nn''=((_b[`x1']+_b[`x1x2'])*`d2F_1'-_b[`x1']*`d2F_0')*`1'
    local nn=`nn'+1
    macro shift
  }   
  local nn= `nn'-1
  gen `_ielse'=0
  local n 1
  while `n'<=_N {
    mkmat `deriv1' `deriv2' `deriv3' `101'-``nn'' `deriv0' if _n==`n', matrix(`mat123')
    matrix `VAR'=`mat123'*e(V)*`mat123''
    scalar `var'=`VAR'[1,1]
    quietly replace `_ielse'=sqrt(`var') if _n==`n'
    local n=`n'+1
  }
  gen `_ieltst'=`_pbt_cd'/`_ielse'

  local probit_se="_probit_se"
  rename `_ielse' `probit_se'
  local probit_tst="_probit_z"
  rename `_ieltst' `probit_tst'

  local probit_phat="_probit_phat"
  rename `phat' `probit_phat'
  local probit_linear="_probit_linear"
  rename `linear' `probit_linear'

  keep `probit_phat' `probit_linear' `_pbt_cd' `probit_se' `probit_tst' 
** End "quietly" **
}


		#delimit ;
		** Save options **;
	      if `"`savedata'"'!="no_savedata" {;
		      save `savedata';
	      };
	      if `"`savegraph1'"'!="no_savegraph1"{;
			twoway scatter `_pbt_cd' `probit_linear' `probit_phat', 
				sort msymbol(o i) connect(. l) yline(0) 
				ylabel(, angle(horizontal))
				title("Interaction Effects after Probit")
				ytitle("Interaction Effect (percentage points)")
				xtitle("Predicted Probability that y = 1")
	      legend( label(1 "Correct interaction effect") label(2 "Incorrect marginal effect") )
			      saving(`savegraph1');
	      }; 
 	      if `"`savegraph1'"'=="no_savegraph1"{;
			twoway scatter `_pbt_cd' `probit_linear' `probit_phat', 
				sort msymbol(o i) connect(. l) yline(0) 
				ylabel(, angle(horizontal))
				title("Interaction Effects after Probit")
				ytitle("Interaction Effect (percentage points)")
				xtitle("Predicted Probability that y = 1")
	      legend( label(1 "Correct interaction effect") label(2 "Incorrect marginal effect") )
				;
	      }; 
	      if `"`savegraph2'"'!="no_savegraph2"{;
			twoway scatter `probit_tst' `probit_phat', 
				sort ms(o i) connect(. l) yline(-1.96 0 1.96) 
				ylabel(-5(5)10, angle(horizontal))
				title("z-statistics of Interaction Effects after Probit")
				ytitle("z-statistic")
				xtitle("Predicted Probability that y = 1")
			      legend( off )
			      saving(`savegraph2');
	      };  
	      if `"`savegraph2'"'=="no_savegraph2"{;
			twoway scatter `probit_tst' `probit_phat', 
				sort ms(o i) connect(. l) yline(-1.96 0 1.96) 
				ylabel(-5(5)10, angle(horizontal))
				title("z-statistics of Interaction Effects after Probit")
				ytitle("z-statistic")
				xtitle("Predicted Probability that y = 1")
			      legend( off )
				;
	      };  

		#delimit cr


sum `_pbt_cd' `probit_se' `probit_tst'
quietly restore

end
