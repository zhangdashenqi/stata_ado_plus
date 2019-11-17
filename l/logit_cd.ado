

************
* logit_cd *
************

program define logit_cd 
  version 8
  di "Logit with one continuous and one dummy variable interacted"

quietly {

  #delimit;
  tempvar xbeta phat phat1 phat0  phi phi1 phi0 d2F_1 d2F_0 linear phat11 phat10 phat01 phat00 logit_cd ie_1 ie_0
          _ieltst _ielse deriv1 deriv2 deriv3 deriv0;
  tempname sum mat123 VAR var lo_ie1 lo_t1;
  #delimit cr
  args touse savedata savegraph1 savegraph2 y x1 x2 x1x2
  preserve
  keep if `touse'

  predict `phat' 
  gen `phi' = `phat'*(1 - `phat')
  gen `linear' = _b[`x1x2']*`phi'

  replace `x2' = 1
  replace `x1x2' = `x1'*`x2'
  predict `phat1' 
  gen `phi1' = `phat1'*(1 - `phat1')
  gen `d2F_1'=`phi1'*(1-2*`phat1')
  gen `ie_1' = (_b[`x1'] + _b[`x1x2'])*`phi1'
    
  replace `x2' = 0
  replace `x1x2' = `x1'*`x2'
  predict `phat0' 
  gen `phi0' = `phat0'*(1-`phat0')
  gen `d2F_0'=`phi0'*(1-2*`phat0')
  gen `ie_0' = _b[`x1']*`phi0'
  gen `logit_cd' = `ie_1' - `ie_0'

  local _lgt_cd="_logit_ie"
  rename `logit_cd' `_lgt_cd'

  gen `deriv1'=`phi1'-`phi0'+_b[`x1']*`x1'*(`d2F_1'-`d2F_0')+_b[`x1x2']*`x1'*`d2F_1'
  gen `deriv2'=(_b[`x1']+_b[`x1x2'])*`d2F_1'
  gen `deriv3'=`phi1'+(_b[`x1']+_b[`x1x2'])*`d2F_1'*`x1'
  gen `deriv0'=(_b[`x1']+_b[`x1x2'])*`d2F_1'-_b[`x1']*`d2F_0'

  macro shift 8
  local nn=101
  while "`1'"~="" {
    tempvar `nn'
    gen ``nn''=((_b[`x1']+_b[`x1x2'])*`d2F_1'-_b[`x1']*`d2F_0')*`1'
    local nn=`nn' + 1
    macro shift
  }   
  local nn = `nn' - 1
  gen `_ielse'=0
  local n 1
  while `n'<=_N {
    mkmat `deriv1' `deriv2' `deriv3' `101'-``nn'' `deriv0' if _n==`n', matrix(`mat123')
    matrix `VAR'=`mat123'*e(V)*`mat123''
    scalar `var'=`VAR'[1,1]
    quietly replace `_ielse'=sqrt(`var') if _n==`n'
    local n=`n'+1
  }
  gen `_ieltst'=`_lgt_cd'/`_ielse'

  local logit_se="_logit_se"
  rename `_ielse' `logit_se'
  local logit_tst="_logit_z"
  rename `_ieltst' `logit_tst'


  local logit_phat="_logit_phat"
  rename `phat' `logit_phat'
  local logit_linear="_logit_linear"
  rename `linear' `logit_linear'

  keep `logit_phat' `logit_linear' `_lgt_cd' `logit_se' `logit_tst' 
}
		#delimit ;
		** Save options **;
	      if `"`savedata'"'!="no_savedata" {;
		      save `savedata';
	      };
	      if `"`savegraph1'"'!="no_savegraph1"{;
			twoway scatter `_lgt_cd' `logit_linear' `logit_phat', 
				sort msymbol(o i) connect(. l) yline(0) 
				ylabel(, angle(horizontal))
				title("Interaction Effects after Logit")
				ytitle("Interaction Effect (percentage points)")
				xtitle("Predicted Probability that y = 1")
	      legend( label(1 "Correct interaction effect") label(2 "Incorrect marginal effect") )
			      saving(`savegraph1');
	      }; 
 	      if `"`savegraph1'"'=="no_savegraph1"{;
			twoway scatter `_lgt_cd' `logit_linear' `logit_phat', 
				sort msymbol(o i) connect(. l) yline(0) 
				ylabel(, angle(horizontal))
				title("Interaction Effects after Logit")
				ytitle("Interaction Effect (percentage points)")
				xtitle("Predicted Probability that y = 1")
	      legend( label(1 "Correct interaction effect") label(2 "Incorrect marginal effect") )
				;
	      }; 

	      if `"`savegraph2'"'!="no_savegraph2"{;
			twoway scatter `logit_tst' `logit_phat', 
				sort ms(o i) connect(. l) yline(-1.96 0 1.96) 
				ylabel(-5(5)10, angle(horizontal))
				title("z-statistics of Interaction Effects after Logit")
				ytitle("z-statistic")
				xtitle("Predicted Probability that y = 1")
			      legend( off )
			      saving(`savegraph2');
	      };  
	      if `"`savegraph2'"'=="no_savegraph2"{;
			twoway scatter `logit_tst' `logit_phat', 
				sort ms(o i) connect(. l) yline(-1.96 0 1.96) 
				ylabel(-5(5)10, angle(horizontal))
				title("z-statistics of Interaction Effects after Logit")
				ytitle("z-statistic")
				xtitle("Predicted Probability that y = 1")
			      legend( off )
				;
	      };  

		#delimit cr
sum `_lgt_cd' `logit_se' `logit_tst'
quietly restore

end
