*! Author:	Frederick J. Boehmke
*! Date: 	August 01, 2008
*! Filename:	plotfds.ado
*! Purpose:	Plot first differences after a regression command.
*! 
*! Version 1.0  2008-08-19 	Initial version.
*! Version 1.1  2008-12-16 	Add sortorder() option for graph.

version 9
#delimit;

program define plotfds;

  syntax [if] [in] [, CONTinuous(varlist) DISCrete(varlist) SORTorder(varlist) OUTCome(numlist) 
	CLEVel(real 95) NOSetx CHANGEXcont(string) LABel SAVEData(string) * ];

  	_get_gropts , graphopts(`options');
	local groptions `"`s(graphopts)'"';

  preserve;
  
  marksample touse;

  local vars_cont `continuous';
  local vars_disc `discrete';

  local level_lb = (100 - `clevel')/2;
  local level_ub = 100 - (100 - `clevel')/2;

  local model = e(cmd);
  
  capture drop fd_* fd;
  capture label drop fd_lab fd_var;

  quietly generat fd_var 	= "";
  quietly generat fd_disc 	= .;
  quietly generat fd_num 	= .;
  quietly generat fd       	= .;
  quietly generat fd_sd       	= .;
  quietly generat fd_ci_lo 	= .;
  quietly generat fd_ci_hi 	= .;

  if word("`model'",1) != "estsimp" {;
  
    display in red "Must run {cmd:estsimp} before {cmd:plotfds}.";
    exit 498;
    
    };
 
  else if "`model'" == "estsimp regress" | "`model'" == "estsimp poisson" 
	| "`model'" == "estsimp nbreg" | "`model'" == "estsimp weibull" {;

    if "`outcome'" == "" {;
  
	local fd_type exval;
    
	};
    
    else if "`outcome'" != "" {;
  
	local fd_type prval;
	local outcome = `outcome';

	};
    
    };
  
  else if "`model'" == "estsimp logit" | "`model'" == "estsimp probit" 
	| "`model'" == "estsimp ologit" | "`model'" == "estsimp oprobit"
	| "`model'" == "estsimp mlogit" {;
  
    if "`outcome'" == "" {;
  
	local fd_type prval;
	local outcome = 1;
    
	};
    
    else if "`outcome'" != "" {;
  
	local fd_type prval;
	local outcome = `outcome';

	};        
    };
  
  else {;
  
    display in red "Model `model' not supported by {cmd:plotfds}.";
    exit 498;
    
    };
    

		/* This section orders the first differences. */

  local vars_all `vars_cont' `vars_disc';
  
  local i = 1;

  foreach var of local vars_all {;

	quietly replace fd_var 	= "`var'" if _n==`i';

	local i = `i' + 1;

  	};

	local numvars = `i' - 1;

	
  local vars_order `sortorder' `vars_cont' `vars_disc';

  local i = `numvars';

  foreach var of local vars_order {;

	quietly replace fd_num 	= `i' if fd_var == "`var'" & fd_num == .;

	local i = `i' - 1;

  	};

  	sort fd_num;
	quietly replace fd_num = _n if fd_num != .;


  foreach var of local vars_cont {;

	quietly replace fd_disc = 0 if fd_var=="`var'" ;

  	};

  foreach var of local vars_disc {;

	quietly replace fd_disc = 1 if fd_var=="`var'" ;

  	};
  

  quietly summarize fd_num;
  

  forvalues i=1/`numvars' {;

    local var = fd_var[`i'];
  
    if fd_disc[`i'] == 0 {;

	quietly sum `var' if `touse';

	  local x_lo = r(mean) - r(sd);
	  local x_hi = r(mean) + r(sd);

	if "`nosetx'" == "" {;

	  if "`vars_disc'" ~= "" {;
	  	quietly setx (`vars_cont') mean (`vars_disc') p50;
	  	};	
	  else {;
	  	quietly setx (`vars_cont') mean;
	  	};	
	
	  };

	else if "`nosetx'" != "" {; 

	  };

	if "`fd_type'" == "prval" {;
	  
    	  if "`changexcont'" == "" {;
  
		quietly simqi, fd(prval(`outcome') genpr(fd_sims)) changex(`var' `x_lo' `x_hi');
    
		};
    
    	  else if "`changexcont'" != "" {;
  
		quietly simqi, fd(prval(`outcome') genpr(fd_sims)) changex(`var' `changexcont');

		};

	  };

	else if "`fd_type'" == "exval" {;

    	  if "`changexcont'" == "" {;
  
		quietly simqi, fd(ev genev(fd_sims)) changex(`var' `x_lo' `x_hi');
    
		};
    
    	  else if "`changexcont'" != "" {;
  
		quietly simqi, fd(ev genev(fd_sims)) changex(`var' `changexcont');

		};
	  };
	};

  else if fd_disc[`i'] == 1 {;

	if "`nosetx'" == "" {;

	  if "`vars_cont'" ~= "" {;
	  	quietly setx (`vars_cont') mean (`vars_disc') p50;
	  	};	
	  else {;
	  	quietly setx (`vars_disc') p50;
	  	};	
	
	  };	

	else if "`nosetx'" != "" {; 

	  };

	if "`fd_type'" == "prval" {;
	  
	  quietly simqi, fd(prval(`outcome') genpr(fd_sims)) 
	  changex(`var' 0 1);
		  
	  };

	else if "`fd_type'" == "exval" {;
	  
	  quietly simqi, fd(ev genev(fd_sims)) 
	  changex(`var' 0 1);
		  
	  };
	};
	  
	quietly summarize fd_sims;

	  local fd_mean : display %3.2f r(mean);
	  local fd_se   : display %3.2f r(sd);

	  quietly replace fd 	= r(mean) if _n==`i';
	  quietly replace fd_sd = r(sd) if _n==`i';

	quietly _pctile fd_sims, p(`level_lb',`level_ub');

	  local fd_lb : display %3.2f r(r1);
	  local fd_ub : display %3.2f r(r2);

	  quietly replace fd_ci_lo 	= r(r1) if _n==`i';
	  quietly replace fd_ci_hi 	= r(r2) if _n==`i';

	if fd_disc[`i'] == 0 {;

	  if "`label'" != "" {;

		local var_lab : variable label `var';
		quietly label define fd_var `i' "`var_lab'", add;

 	    };
	
	  else if "`label'" == "" {;

		quietly label define fd_var `i' "`var'", add;

		};
	  };
	  
	else if fd_disc[`i'] == 1 {;

	  if "`label'" != "" {;

		local var_lab : variable label `var';
		quietly label define fd_var `i' "`var_lab'*", add;

 	    };
	
	  else if "`label'" == "" {;

		quietly label define fd_var `i' "`var'*", add;

		};
	  };

	quietly label define fd_lab `i' "`fd_mean' [`fd_lb', `fd_ub']", add;

	local i = `i' + 1;

	drop fd_sims;

    };


	/* Now set it up to draw the graph. */
    
local aspect = 0.75-(1/(`numvars'+1));

if `numvars' <= 1 {;

  display in red "Graph option will not work without at least two variables.";
  
  };

else {;

  label values fd_num fd_var;

  quietly generat fd_lab = fd_num;

  label values fd_lab fd_lab;

  if "`fd_type'" == "prval" {;
  
	local title First Differences for Change in P(Y=`outcome'|X);
	
	};

  else if "`fd_type'" == "exval" {;
  
	local title First Differences for Change in E(Y|X);
	  
	};


  if "`changexcont'" == "" {;

	local notecont "First differences represent a change from 1 SD below the mean to 1 SD above it.";

	};

  else if "`changexcont'" != "" {;

	local notecont "User set first differences change as: `changexcont'.";

	};

  if "`vars_disc'" ~= "" {;

	local notedisc "Variables with a * are discrete - FD is a change from 0 to 1.";
	
	};
	

  twoway rcap fd_ci_lo fd_ci_hi fd_num, horiz
	lwidth(medthick)
  || scatter fd_lab fd, yaxis(2)
	msymbol(i)
  || scatter fd_num fd, 
	mcolor(cranberry) msize(medlarge)
	ytitle("", axis(1)) ylabel(1/`numvars', axis(1) valuelabel angle(0) 
	  labsize(medlarge)) 
	ytitle("", axis(2)) ylabel(1/`numvars', axis(2) valuelabel angle(0) 
	  labsize(small) noticks) 
	xtitle("") 
	title("`title'" "with `clevel'% Confidence Interval")
	legend(off)
	aspect(`aspect')
	note("`notecont'" 
	  "`notedisc'")
	`groptions';

  };

  if "`nosetx'" == "" {;

	display in green "";
	display in green "Independent variables set by {cmd:plotfds}.";
	setx;

	};

  else if "`nosetx'" != "" {;

	display in green "";
	display in green "Independent variables set by user in previous {cmd:setx} command.";
	setx;

	};


  if "`savedata'" ~= "" {;
	  
	quietly keep fd_var-fd_ci_hi;

	quietly keep if fd_var ~= "";

	quietly save `savedata';
	
	};


  restore;
	  
end;
