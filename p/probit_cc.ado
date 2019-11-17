
*************
* probit_cc *
*************


program define probit_cc 
  	version 8
	di "Probit with two continuous variables interacted"

	#delimit ;
  	preserve;
  		tempvar  _ieptst probit_cc _iepse x12 phat xbeta phi linear b1b4x2 
			b2b4x1 deriv11 deriv22 deriv44 d2F d3F derivc deriv;
  		tempname sum mat123 VAR var pr_ie pr_t;
  		args touse savedata savegraph1 savegraph2 y x1 x2 x1x2;
  		keep if `touse';

  		quietly {;
    			predict `phat';
    			predict `xbeta', xb;
    			gen `phi'= normd(`xbeta');
    			gen `linear'=_b[`x1x2']*`phi';
    			gen `probit_cc'= (_b[`x1x2']- (_b[`x1'] 
                    +_b[`x1x2']*`x2')*(_b[`x2']+_b[`x1x2']*`x1')*`xbeta')*`phi';

  			local _pbt_cc="_probit_ie";
  			rename `probit_cc' `_pbt_cc';
  			
    			gen `d2F'= -`xbeta'*`phi';
    			gen `d3F'= (`xbeta'^2-1)*`phi';
    			gen `b1b4x2' = _b[`x1']+_b[`x1x2']*`x2';
    			gen `b2b4x1' = _b[`x2']+_b[`x1x2']*`x1';
    			gen `deriv11'= _b[`x1x2']*`d2F'*`x1' + `b2b4x1'*`d2F' 
                  	 + `b1b4x2'*`b2b4x1'*`x1'*`d3F';
    			gen `deriv22'= _b[`x1x2']*`d2F'*`x2' + `b1b4x2'*`d2F' 
    	               + `b1b4x2'*`b2b4x1'*`x2'*`d3F';
    			gen `deriv44'= `phi' + _b[`x1x2']*`d2F'*`x1'*`x2' + 
						`x2'*`b2b4x1'*`d2F'+ `x1'*`b1b4x2'*`d2F' +  
                   	`b1b4x2'*`b2b4x1'*`x1'*`x2'*`d3F';
    			gen `derivc' = _b[`x1x2']*`d2F' + `b1b4x2'*`b2b4x1'*`d3F';

    			* Derivatives of other covariates; 
    			macro shift 8;
    			local nn=101;
    			while "`1'"~="" {;
      			tempvar `nn';
      			gen ``nn''=_b[`x1x2']*`d2F'*`1' + `b1b4x2'*`b2b4x1'*`1'*`d3F';
      			local nn = `nn'+1;
      			macro shift 1;
    			};

    			local nn = `nn'-1;
    			gen `_iepse' = 0;
    			local n 1;
    			while `n'<=_N {;
      			mkmat `deriv11' `deriv22' `deriv44' `101'-``nn'' `derivc' 
                    		if _n==`n', matrix(`mat123'); 
      			matrix `VAR'=`mat123'*e(V)*`mat123'';
      			scalar `var'=`VAR'[1,1];
      			quietly replace `_iepse'=sqrt(`var') if _n==`n';
      			local n=`n'+1;
    			};

    			gen `_ieptst'=`_pbt_cc'/`_iepse';
  			local probit_se = "_probit_se";
  			rename `_iepse' `probit_se';
  			local probit_tst = "_probit_z";
  			rename `_ieptst' `probit_tst';

        
  			local probit_phat = "_probit_phat";
  			rename `phat' `probit_phat';
  			local probit_linear = "_probit_linear";
  			rename `linear' `probit_linear';
    			keep `probit_phat' `probit_linear' `_pbt_cc' `probit_se' `probit_tst' ;

		* End "quietly" *;
		};

		** Save options **;
	      if `"`savedata'"'!="no_savedata" {;
		      save `savedata';
	      };
	      if `"`savegraph1'"'!="no_savegraph1"{;
			twoway scatter `_pbt_cc' `probit_linear' `probit_phat', 
				sort msymbol(o i) connect(. l) yline(0) 
				ylabel(, angle(horizontal))
				title("Interaction Effects after Probit")
				ytitle("Interaction Effect (percentage points)")
				xtitle("Predicted Probability that y = 1")
	      legend( label(1 "Correct interaction effect") label(2 "Incorrect marginal effect") )
			      saving(`savegraph1');
	      }; 
 	      if `"`savegraph1'"'=="no_savegraph1"{;
			twoway scatter `_pbt_cc' `probit_linear' `probit_phat', 
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

       	sum `_pbt_cc' `probit_se' `probit_tst';

       quietly restore;
       #delimit cr
end
