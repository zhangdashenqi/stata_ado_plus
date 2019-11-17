**************
* inteff.ado *
**************

program define inteff
  	             
********************************************************************************
* This main program checks to make sure that either a logit or probit was just 
* run and that the interaction term is the product of the first two independent * variables listed.  It also chooses which subprogram to run, depending on the 
* model and type of variables (continuous or dummy).
********************************************************************************
  	  version 8
	  syntax varlist(min=4) [if] [in] [, savedata(string) savegraph1(string) savegraph2(string)] 
	  marksample touse
	  tokenize `varlist'
	  args y x1 x2 x1x2
	  tempvar dm_1 dm_2 x12	
	  tempname sum m_dm1 m_dm2

	  preserve
		quietly {
			#delimit;
			** I. Check the previous command;
		      if "`e(cmd)'" ~= "logit" & "`e(cmd)'" ~= "probit" {;
				error 301;
                  };
	            ** II. Check the order of the arguments;
		      gen `x12' = sum(abs((`x1'*`x2' - `x1x2')/`x1x2'));
                  scalar `sum' = `x12'[_N];
		      if `sum'>0.001 {; 
				di "Error: The fourth argument is not the product of the 					second and third arguments." ;
		      };
		      if `sum'>0.001 error 9;
		      ** III. Check the type of interacted variable: 							  dummy/continuous;
                  gen `dm_1' = (`x1'==0 | `x1'==1) ;
				replace `dm_1' =. if `x1'==.;
                  gen `dm_2' = (`x2'==0 | `x2'==1) ;
				replace `dm_2' =. if `x2'==.;
                  sum `dm_1';
		      scalar `m_dm1' = r(mean);
		      sum `dm_2';
		      scalar `m_dm2' = r(mean);

			** Save options **;
			if `"`savedata'"' == ""{;
				local savedata "no_savedata";
			};
			if `"`savegraph1'"' == ""{;
				local savegraph1 "no_savegraph1";
			};
			if `"`savegraph2'"' == ""{;
				local savegraph2 "no_savegraph2";
			};

		** End "quietly" **;
		};
		
            ** Choose the appropriate sub-program **;
            if `m_dm1' == 1 & `m_dm2' == 1 & "`e(cmd)'" == "logit" {;
			logit_dd `touse' `"`savedata'"' `"`savegraph1'"' `"`savegraph2'"' `varlist';
	      };
            if `m_dm1' == 1 & `m_dm2' == 1 & "`e(cmd)'" == "probit" {;
           		probit_dd `touse' `"`savedata'"' `"`savegraph1'"' `"`savegraph2'"' `varlist';
            };
            if `m_dm1' < 1 & `m_dm2'==1 & "`e(cmd)'" == "logit" {;
           		logit_cd `touse' `"`savedata'"' `"`savegraph1'"' `"`savegraph2'"' `varlist';
            };
            if `m_dm1' == 1 & `m_dm2' < 1 & "`e(cmd)'" == "logit" {;
			di "Error. Correct syntax: inteff x1(continuous) x2(dummy)      				x1*x2 X(others)";
            };
            if `m_dm1' < 1 & `m_dm2'==1 & "`e(cmd)'" == "probit" {;
    		      probit_cd `touse' `"`savedata'"' `"`savegraph1'"' `"`savegraph2'"' `varlist';
            };
            if `m_dm1' == 1 & `m_dm2' < 1 & "`e(cmd)'" == "probit" {;
 			di "Error. Correct syntax: inteff y x1(continuous) x2(dummy) 				x1*x2 X(others)";
	      };
            if `m_dm1' < 1 & `m_dm2' < 1 & "`e(cmd)'" == "logit" {;
           		logit_cc `touse' `"`savedata'"' `"`savegraph1'"' `"`savegraph2'"' `varlist';
            };    
            if `m_dm1' < 1 & `m_dm2' < 1 & "`e(cmd)'" == "probit" {;
           		probit_cc `touse' `"`savedata'"' `"`savegraph1'"' `"`savegraph2'"' `varlist';
            };            
	restore;
	#delimit cr
end

