#delim ;

cap program drop oheckm_p;
program define oheckm_p;
	version 8;
	syntax anything   [if] [in] [, XBSel mills PSel(numlist max=1) millsif(numlist max=1) xbif(numlist max=1) yif(numlist max=1)];

	marksample touse;

	syntax newvarname [if] [in] [, XBSel mills PSel(numlist max=1) millsif(numlist max=1) xbif(numlist max=1) yif(numlist max=1)];

	if ("`e(cmd)'" ~= "oheckman") error 301;
	local check="`xbsel' `mills' `psel' `millsif' `xbif' `yif'";
	
	if (wordcount("`check'")>1)  {; disp as error "Only one statistic is allowed." ;  exit 198;};
	if (wordcount("`check'")==0) {;
		local nooptions = 1;
		noisily display as text "(Option xbsel assumed; estimation of latent selection variable)";
	};
	else local nooptions = 0;

	quietly {;

	local J = $OHECKMAN_NEQ - 1;
	local Jminus1 = `J' - 1;
      local y_sel0 = e(y_sel);
      local y_reg0 = e(y_reg);

	// xbsel: xb in selection equation
	tempvar zhat;
	_predict double `zhat' `if' `in', xb eq(`y_sel0');
	if ("`xbsel'"~="") | `nooptions' {;
		gen double `varlist' = `zhat';
		exit;
	};

	tempname cutoffs cat;
	matrix `cutoffs' = e(cutoffs);
	tempname cutoff0 cutoff$OHECKMAN_NEQ;
	scalar `cutoff0' = -1e10;
	scalar `cutoff$OHECKMAN_NEQ' = 1e10;
	forvalues i = 1/`J' {;
		tempname cutoff`i';
		scalar `cutoff`i'' = `cutoffs'[1,`i'];
	};

      // Create variable with values 0,1,...,neq-1.
	// Follow the key rather than using -egen group- in case data has changed since estimation.
	matrix `cat' = e(cat);
      tempvar y_sel;
	generate `y_sel' = .;
	forvalues i = 0/`J' {;	
		replace `y_sel' = `i' if `y_sel0' == `cat'[`i'+1,1] & `touse';
	};

	// mills: E[u], expected value of error term in selection equation
	if ~missing("`mills'`yif'") {;
		tempvar lambda;
		gen double `lambda' = .;
		forvalues i = 0/`J' {;
			local nexti = `i'+1;
			replace `lambda' = (normden(`cutoff`i''-`zhat') - normden(`cutoff`nexti''-`zhat')) / (norm(`zhat'-`cutoff`i'') - norm(`zhat'-`cutoff`nexti''))
		        if `y_sel' == `i' & (`zhat' - `cutoff`i'' < 0) & `touse';
			replace `lambda' = (normden(`cutoff`i''-`zhat') - normden(`cutoff`nexti''-`zhat')) / (norm(`cutoff`nexti''-`zhat') - norm(`cutoff`i''-`zhat'))
		        if `y_sel' == `i' & (`zhat' - `cutoff`i'' >= 0) & `touse';
		};
	};
	if ~missing("`mills'") {;
		gen double `varlist' = `lambda';
		exit;
	};

	// For psel and yif options, need to find the desired equation.
	forvalues i = 0/`J' {;
		if `cat'[`i'+1,1] == `psel'`millsif'`xbif'`yif' {;
			local eq = `i';
		};
	};
	if missing("`eq'") {;
		disp as error "Invalid selection value specified.";
		exit 303;
	};

	// psel: probability that selection variable is equal to the value specified
	if ~missing("`psel'") {;
		local nexti = `eq'+1;
		gen double `varlist' = norm(`zhat' - `cutoff`eq'') - norm(`zhat' - `cutoff`nexti'')
	        if (`zhat' - `cutoff`eq'' < 0) & `touse';
		replace `varlist' = norm(`cutoff`nexti'' - `zhat') - norm(`cutoff`eq'' - `zhat')
	        if (`zhat' - `cutoff`eq'' >= 0) & `touse';
		exit;
	};

	if ~missing("`millsif'") {;
		local nexti = `eq'+1;
		gen double `varlist' = (normden(`cutoff`eq''-`zhat') - normden(`cutoff`nexti''-`zhat')) / (norm(`zhat'-`cutoff`eq'') - norm(`zhat'-`cutoff`nexti''))
	        if (`zhat' - `cutoff`eq'' < 0) & `touse';
		replace `varlist' = (normden(`cutoff`eq''-`zhat') - normden(`cutoff`nexti''-`zhat')) / (norm(`cutoff`nexti''-`zhat') - norm(`cutoff`eq''-`zhat'))
	        if (`zhat' - `cutoff`eq'' >= 0) & `touse';
		exit;
	};

	// xbif: predicted value of xb if everyone switched to the specified equation
	tempvar xb;
	gen double _lambda = 0;	// this isn't good style
	cap _predict double `xb' `if' `in', xb eq(`y_reg0'`xbif'`yif');
	drop _lambda;		// need to capture previous line to ensure _lambda always dropped
	if _rc == 303 {;
		disp in red "equation `y_reg0'`xbif'`yif' not found";
		exit 303;
	};
	if ~missing("`xbif'") {;
		gen double `varlist' = `xb';
		exit;
	};

	// yif: predicted value of y if everyone switched to the specified equation
	if ~missing("`yif'") {;
		tempname rho sigma rhoi sigmai;
		matrix `rho' = e(rho);
		matrix `rhoi' = `rho'[1,"rho`yif'"];
		matrix `sigma' = e(sigma);
		matrix `sigmai' = `sigma'[1,"sigma`yif'"];
		gen double `varlist' = `xb' + `rhoi'[1,1] * `sigmai'[1,1] * `lambda' if `touse';
		exit;
	};

      }; // end quietly
end; // end oheckm_p
