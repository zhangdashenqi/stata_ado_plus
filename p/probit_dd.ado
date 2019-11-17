


*************
* probit_dd *
*************

program define probit_dd
  	version 8
  	di "Probit with two dummy variables interacted"

  	#delimit ;
  	preserve;
  		quietly {;
  			tempvar xbeta phat phi linear phat11 phat10 phat01 phat00 
					probit_dd xbeta00 xbeta01 xbeta10 xbeta11 _ieltst _ielse 
				deriv1 deriv2 deriv3 deriv0 phi_11 phi_10 phi_01 phi_00;
  			tempname sum mat123 VAR var lo_ie1 lo_t1;
	  		args touse savedata savegraph1 savegraph2 y x1 x2 x1x2;
  			keep if `touse';

    			predict `phat'; 
	    		predict `xbeta' , xb;
	    		gen `phi' = normd(`xbeta');
	    		gen `linear' = _b[`x1x2']*`phi';

    			replace `x1' = 1;
	    		replace `x2' = 1;
	    		replace `x1x2' = 1;
	    		predict `phat11'; 
	    		predict `xbeta11' ,xb;
	    		gen `phi_11' = normd(`xbeta11');
	
	    		replace `x2' = 0;
	    		replace `x1x2' = 0;
	    		predict `phat10';
	    		predict `xbeta10' ,xb;
	    		gen `phi_10' = normd(`xbeta10');

    			replace `x1' = 0;
	    		replace `x2' = 1;
	    		predict `phat01';
	    		predict `xbeta01',xb;
	    		gen `phi_01' = normd(`xbeta01');

	    		replace `x2' = 0;
	    		predict `phat00';
	    		predict `xbeta00' ,xb;
	    		gen `phi_00' = normd(`xbeta00');

    			gen `probit_dd' = (`phat11' - `phat10') - (`phat01' - `phat00');
	
  			local _pbt_dd="_probit_ie";
  			rename `probit_dd' `_pbt_dd';


	    		gen `deriv1'=`phi_11'-`phi_10'; 
    			gen `deriv2'=`phi_11'-`phi_01';
	    		gen `deriv3'=`phi_11';
    			gen `deriv0'=(`phi_11'-`phi_01')-(`phi_10'-`phi_00');
    			macro shift 8;
	    		local nn=101;
    			while "`1'"~="" {;
      			tempvar `nn';
      			gen ``nn''=((`phi_11'-`phi_01')-(`phi_10'- `phi_00'))*`1';
	      		local nn=`nn'+1;
      			macro shift;
    			};
	    		
			local nn= `nn'-1;
    			gen `_ielse'=0;
	    		local n 1;
	    		while `n'<=_N {;
      			mkmat `deriv1' `deriv2' `deriv3' `101'-``nn'' `deriv0' if _n==`n', matrix(`mat123');
	      		matrix `VAR'=`mat123'*e(V)*`mat123'';  
   			scalar `var'=`VAR'[1,1];
      			replace `_ielse'=sqrt(`var') if _n==`n';
      			local n=`n'+1;
	    		};
    			gen `_ieltst'=`_pbt_dd'/`_ielse';
	
  			local probit_se="_probit_se";
	  		rename `_ielse' `probit_se';
  			local probit_tst="_probit_z";
  			rename `_ieltst' `probit_tst';


  			local probit_phat="_probit_phat";
	  		rename `phat' `probit_phat';
	  		local probit_linear="_probit_linear";
	 		rename `linear' `probit_linear';

  			keep `probit_phat' `probit_linear' `_pbt_dd' `probit_se' `probit_tst' ;

		* End "quietly" *;
		};

		** Save options **;
	      if `"`savedata'"'!="no_savedata" {;
		      save `savedata';
	      };
	      if `"`savegraph1'"'!="no_savegraph1"{;
			twoway scatter `_pbt_dd' `probit_linear' `probit_phat', 
				sort msymbol(o i) connect(. l) yline(0) 
				ylabel(, angle(horizontal))
				title("Interaction Effects after Probit")
				ytitle("Interaction Effect (percentage points)")
				xtitle("Predicted Probability that y = 1")
	      legend( label(1 "Correct interaction effect") label(2 "Incorrect marginal effect") )
			      saving(`savegraph1');
	      }; 
 	      if `"`savegraph1'"'=="no_savegraph1"{;
			twoway scatter `_pbt_dd' `probit_linear' `probit_phat', 
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

       	sum `_pbt_dd' `probit_se' `probit_tst';

       quietly restore;
       #delimit cr
end
