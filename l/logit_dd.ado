
************
* logit_dd *
************


program define logit_dd
	version 8
	di "Logit with two dummy variables interacted"
	#delimit ;
	tempvar phat phi linear phat11 phat10 phat01 phat00 logit_dd 
      	  phi_11 phi_10 phi_01 phi_00 _ieltst _ielse
	        deriv1 deriv2 deriv3 deriv0 var6;
	tempname sum mat123 VAR var lo_ie1 lo_t1;

	args touse savedata savegraph1 savegraph2 y x1 x2 x1x2;
	preserve;
		keep if `touse'; 		quietly {;
			predict `phat';
			gen `phi' = `phat'*(1 - `phat');
			gen `linear' = _b[`x1x2']*`phi';

			replace `x1' = 1;
			replace `x2' = 1;
			replace `x1x2' = 1;
			predict `phat11' ;
			gen `phi_11'=`phat11'*(1-`phat11');
			replace `x2' = 0;
			replace `x1x2' = 0;
			predict `phat10'; 
			gen `phi_10'=`phat10'*(1-`phat10');
			replace `x1' = 0;
			replace `x2' = 1;
			predict `phat01' ;
			gen `phi_01'=`phat01'*(1-`phat01');
			replace `x2' = 0;
			predict `phat00' ;
			gen `phi_00'=`phat00'*(1-`phat00');
			gen `logit_dd' = (`phat11' - `phat10') - (`phat01' - `phat00');
	
			local _lgt_dd="_logit_ie";
			rename `logit_dd' `_lgt_dd';

 
			gen `deriv1'=`phi_11'-`phi_10';  
			gen `deriv2'=`phi_11'-`phi_01';
			gen `deriv3'=`phi_11';
			gen `deriv0'=(`phi_11'-`phi_01')-(`phi_10'-`phi_00');

			macro shift 8;
			local nn = 101;
			while "`1'"~="" {;
				tempvar `nn';
				gen ``nn'' = ((`phi_11'-`phi_01')-
					        (`phi_10'-`phi_00'))*`1';
				local nn = `nn'+1;
			      macro shift;
			};

			local nn = `nn'-1;
			gen `_ielse' = 0;
			local n 1;
			while `n'<=_N {;
				mkmat `deriv1' `deriv2' `deriv3' `101'-``nn'' `deriv0' if _n==`n', matrix(`mat123');
			      matrix `VAR'=`mat123'*e(V)*`mat123'';
			      scalar `var'=`VAR'[1,1];
			      quietly replace `_ielse' = sqrt(`var') if _n==`n';
			      local n = `n'+1;
			};

			gen `_ieltst' = `_lgt_dd'/`_ielse';
			local logit_se = "_logit_se";
			rename `_ielse' `logit_se';
			local logit_tst = "_logit_z";
			rename `_ieltst' `logit_tst';


			local logit_phat = "_logit_phat";
			rename `phat' `logit_phat';
			local logit_linear = "_logit_linear";
			rename `linear' `logit_linear';

			keep `logit_phat' `logit_linear' `_lgt_dd' `logit_se' `logit_tst';

		** End "quietly";
		};

		** Save options **;
	      if `"`savedata'"'!="no_savedata" {;
		      save `savedata';
	      };
	      if `"`savegraph1'"'!="no_savegraph1"{;
			twoway scatter `_lgt_dd' `logit_linear' `logit_phat', 
				sort msymbol(o i) connect(. l) yline(0) 
				ylabel(, angle(horizontal))
				title("Interaction Effects after Logit")
				ytitle("Interaction Effect (percentage points)")
				xtitle("Predicted Probability that y = 1")
	      legend( label(1 "Correct interaction effect") label(2 "Incorrect marginal effect") )
			      saving(`savegraph1');
	      }; 
 	      if `"`savegraph1'"'=="no_savegraph1"{;
			twoway scatter `_lgt_dd' `logit_linear' `logit_phat', 
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

       	sum `_lgt_dd' `logit_se' `logit_tst';

       quietly restore;
       #delimit cr
end
