


************
* logit_cc *
************




program define logit_cc 
	version 8
	di "Logit with two continuous variables interacted"

	#delimit ;
	preserve;
		quietly {;
			tempvar  _ieltst logit_cc _ielse x12 phat xbeta phi linear 
					   b1b4x2 b2b4x1 deriv11 deriv22 deriv44 d2F d3F derivc deriv;
			tempname sum mat123 VAR var lo_ie1 lo_t1 figure1 figure2;
			args touse savedata savegraph1 savegraph2 y x1 x2 x1x2;
			keep if `touse';

			predict `phat' ;
			predict `xbeta' , xb;
			gen `phi'=`phat'*(1-`phat');
			gen `linear'=_b[`x1x2']*`phi';
			gen `logit_cc'=_b[`x1x2']*`phi' + 
	            		  (_b[`x1']+_b[`x1x2']*`x2')*(_b[`x2']+
				    	   _b[`x1x2']*`x1')*`phi'*(1-(2*`phat'));

			local _lgt_cc="_logit_ie";
			rename `logit_cc' `_lgt_cc';
		
			gen `d2F'=`phat'*(1-`phat')*(1-2*`phat');
			gen `d3F'=`phat'*(1-`phat')*(1 - 6*`phat' + 6*`phat'^2);
			gen `b1b4x2' = _b[`x1']+_b[`x1x2']*`x2';
			gen `b2b4x1' = _b[`x2']+_b[`x1x2']*`x1';

			gen `deriv11'= _b[`x1x2']*`d2F'*`x1' + `b2b4x1'*`d2F' 
			               + `b1b4x2'*`b2b4x1'*`x1'*`d3F';
			gen `deriv22'= _b[`x1x2']*`d2F'*`x2' + `b1b4x2'*`d2F' 
			               + `b1b4x2'*`b2b4x1'*`x2'*`d3F';
			gen `deriv44'= `phi' + _b[`x1x2']*`d2F'*`x1'*`x2' + 	
						   `x2'*`b2b4x1'*`d2F' + `x1'*`b1b4x2'*`d2F' + 
						   `b1b4x2'*`b2b4x1'*`x1'*`x2'*`d3F';
			gen `derivc' = _b[`x1x2']*`d2F' +  `b1b4x2'*`b2b4x1'*`d3F';

			** Derivatives of other covariates ; 
			macro shift 8;
			local nn=101;
			while "`1'"~="" {;
				tempvar `nn';
				gen ``nn''=_b[`x1x2']*`d2F'*`1' + `b1b4x2'*`b2b4x1'*`1'*`d3F';
				local nn =`nn'+1;
				macro shift;
			};
			local nn = `nn'-1;
			gen `_ielse' = 0;
			local n 1;
			while `n'<=_N {;
				mkmat `deriv11' `deriv22' `deriv44' `101'-``nn'' 
						`derivc' if _n==`n', matrix(`mat123'); 
				matrix `VAR' = `mat123'*e(V)*`mat123'';
				scalar `var' = `VAR'[1,1];
				replace `_ielse' = sqrt(`var') if _n==`n';
				local n = `n'+1;
			};
			gen `_ieltst' = `_lgt_cc'/`_ielse';

			local logit_se = "_logit_se";
			rename `_ielse' `logit_se';
			local logit_tst = "_logit_z";
			rename `_ieltst' `logit_tst';

		      local logit_phat = "_logit_phat";
      		rename `phat' `logit_phat';
	      	local logit_linear = "_logit_linear";
		      rename `linear' `logit_linear';

	            keep `logit_phat' `logit_linear' `_lgt_cc' `logit_se' `logit_tst';
           	** End "quietly" **;
       	};

		** Save options **;
	      if `"`savedata'"'!="no_savedata" {;
		      save `savedata';
	      };
	      if `"`savegraph1'"'!="no_savegraph1"{;
			twoway scatter `_lgt_cc' `logit_linear' `logit_phat', 
				sort msymbol(o i) connect(. l) yline(0) 
				ylabel(, angle(horizontal))
				title("Interaction Effects after Logit")
				ytitle("Interaction Effect (percentage points)")
				xtitle("Predicted Probability that y = 1")
	      legend( label(1 "Correct interaction effect") label(2 "Incorrect marginal effect") )
			      saving(`savegraph1');
	      }; 
 	      if `"`savegraph1'"'=="no_savegraph1"{;
			twoway scatter `_lgt_cc' `logit_linear' `logit_phat', 
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

       	sum `_lgt_cc' `logit_se' `logit_tst';

       quietly restore;
       #delimit cr
end

