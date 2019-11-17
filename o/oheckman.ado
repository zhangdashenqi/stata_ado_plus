#delim ;

cap program drop oheckman;
program define oheckman, sortpreserve;
	version 8;
	if replay() {;
		if ("`e(cmd)'" ~= "oheckman") error 301;
		if ("`e(method)'" == "two-step") oheckman_display2 `0';
		else oheckman_display `0';
	};
	else oheckman_mx `0';
end; // end program oheckman

cap program drop oheckman_display;
program define oheckman_display;
	syntax [, Level(cilevel)];

	local J = $OHECKMAN_NEQ - 1;

	tempname cat;
	matrix `cat' = e(cat);

	local cutoff1dispopt `"diparm(cutoff1, f(@) d(1) lab("cutoff1"))"';

	if `J' <= 9 {;	// due to 9-variable limit of -diparm-
		forvalues i = 2/`J' {;
			local cutoffdispopt `"`cutoffdispopt' diparm(cutoff1"';
			forvalues i2 = 2/`i' {;
				local cutoffdispopt `"`cutoffdispopt' lndelta`i2'"';
			};
			local cutoffdispopt `"`cutoffdispopt', f(@1"';
			forvalues i2 = 2/`i' {;
				local cutoffdispopt `"`cutoffdispopt'+exp(@`i2')"';
			};
			local cutoffdispopt `"`cutoffdispopt') d(1"';
			forvalues i2 = 2/`i' {;
				local cutoffdispopt `"`cutoffdispopt' exp(@`i2')"';
			};
			local cutoffdispopt `"`cutoffdispopt') lab("cutoff`i'"))"';
		};
	};

	forvalues i = 0/`J' {;
		if real(substr("$OHECKMAN_HASY",`i'+1, 1)) {;
			local selvalue = `cat'[`i'+1,1];
			local rhodispopt `"`rhodispopt' diparm(athrho`selvalue',tanh lab("rho`selvalue'"))"';
			local sigmadispopt `"`sigmadispopt' diparm(lnsigma`selvalue',exp lab("sigma`selvalue'"))"';
		};
	};

	ml display, level(`level') `cutoff1dispopt' `cutoffdispopt' `rhodispopt' `sigmadispopt';

	display in green e(chi2_ct) " test of indep. eqns. (rho = 0):"
		_col(38) "chi2(" in yellow e(numeq) in green ") = "
		in yellow %8.2f e(chi2_c) _col(59)
		in green  "Prob > chi2 = "
		in yellow %6.4f e(p_c);
	display in smcl in green "{hline 78}";
end; // end program oheckman_display

cap program drop oheckman_display2;
program define oheckman_display2;
	syntax [, Level(cilevel) ];

	tempname rho sigma;
	matrix `rho' = e(rho);
	matrix `sigma' = e(sigma);
	local len = colsof(`rho');

	di in gr _n "`e(title)'" _col(51) "Number of obs"  in gr _col(67) "=" in ye _col(69) %10.0g e(N);
      di in gr "`e(title2)'";
	ereturn display, level(`level') plus;

	local names : colnames `rho';
	forvalues i = 1/`len' {;
		local name : word `i' of `names';
		di in smcl in gr %19s "`name' {c |} " in ye %10.5f `rho'[1,`i'];
	};

	local names : colnames `sigma';
	forvalues i = 1/`len' {;
		local name : word `i' of `names';
		di in smcl in gr %19s "`name' {c |} " in ye %10.0g `sigma'[1,`i'];
	};

	di in smcl in gr "{hline 13}{c BT}{hline 64}";
	_prefix_footnote;
end; // end program oheckman_display2;

cap program drop oheckman_mx;
program define oheckman_mx, eclass;

	syntax 	anything(id="equation id" equalok) [pweight iweight fweight] [if] [in] ,
	       	SELect(string) [TWOstep Robust CLuster(varname) Level(cilevel)] [*];
	mlopts mlopts, `options';

	marksample touse;
	markout `touse' `cluster', strok;

	quietly {;

	if ~missing("`weight'") {;
		tempvar wvar;
		generate double `wvar' `exp' if `touse';
		local wgt "[`weight'=`wvar']";
	};
	if "`weight'" == "pweight" | "`cluster'" != "" {;
		local robust robust;
	};
	if ~missing("`cluster'") local clopt cluster(`cluster');

	// read vector of parameters
	tokenize "`anything'", parse("=");
	if ("`2'"!="=") {;
		tokenize "`anything'";
		local y_reg0 `1';
		macro shift;
		local x_reg `*';
	};
	else {;
		if ("`4'"=="=") {;
			display as error "Too many =.";
			exit 198;
		};
	       	local y_reg0 `1';
		local x_reg `3';
	};
	unab x_reg : `x_reg', min(0);

	tokenize "`select'", parse("=");         // define vars for regression equation
	if ("`2'"!="=") {;
		tokenize "`select'";
		local y_sel0 `1';
		macro shift;
		local x_sel `*';
	};
	else {;
		local y_sel0 `1';
		local x_sel `3';
	};

	// Ignore samples in which the selection variable or any x variable is missing.
	markout `touse' `y_sel0' `x_sel' `x_reg';

	tempname cat;
	tabulate `y_sel0', matrow(`cat');
	global OHECKMAN_NEQ = r(r);
	if $OHECKMAN_NEQ == 1 {
		display as error "Selection variable is constant;";
            display as error "model would simplify to OLS regression.";
		exit 498;
	};
	local J = $OHECKMAN_NEQ - 1;

	tempvar y_sel y_reg;
	egen `y_sel' = group(`y_sel0');
	replace `y_sel'=`y_sel'-1;      // create variable with values 0,1,...,neq-1.

	unab x_sel : `x_sel';
	noisily _rmcoll `x_sel' `wgt' if `touse';
	local x_sel_c `r(varlist)';
	local n_selvars : word count `x_sel_c';
	local n_selvarsplus1 = `n_selvars' + 1;

	// Figure out which selection values have corresponding y values.
	global OHECKMAN_HASY = "";
	local numyeq = 0;
	gen `y_reg' = `y_reg0';
	forvalues i = 0/`J' {;
		count if `y_sel' == `i' & !missing(`y_reg');
		global OHECKMAN_HASY = ("$OHECKMAN_HASY" + string(r(N) > 0));
		if r(N) == 0 {;
			//replace `y_reg' = 0 if `y_sel' == `i';
		};
		else {;
			local numyeq = `numyeq' + 1;
		};
	};

	// HECKMAN TWO-STEP PROCEDURE (used as initial values for -ml-)
	tempvar zhat lower upper denom lambda dlambda;
	tempname tmp b_sel cutoffs bi b dlambdabar rhoi rho sigmai sigma init;

	// First step: ordered probit
	oprobit `y_sel' `x_sel_c' `wgt' if `touse';
	matrix `b_sel' = e(b);
	matrix `b_sel' = `b_sel'[1, 1..`n_selvars'];
	tempname cutoff0 cutoff$OHECKMAN_NEQ;
	scalar `cutoff0' = -1e10;
	scalar `cutoff$OHECKMAN_NEQ' = 1e10;
	forvalues i = 1/`J' {;
		tempname cutoff`i';
		scalar `cutoff`i'' = _b[_cut`i'];
		matrix `cutoffs' = (nullmat(`cutoffs'), `cutoff`i'');
	};

	predict double `zhat', xb;
	gen double `lower' = .;
	gen double `upper' = .;
	gen double `denom' = .;
	gen double `lambda' = .;
	gen double `dlambda' = .;
	forvalues i = 0/`J' {;
		local nexti = `i'+1;
		replace `lower' = `cutoff`i'' - `zhat' if `y_sel' == `i' & `touse';
		replace `upper' = `cutoff`nexti'' - `zhat' if `y_sel' == `i' & `touse';
		replace `denom' = norm( `upper') - norm( `lower') if `lower' <= 0 & `y_sel' == `i' & `touse';
		replace `denom' = norm(-`lower') - norm(-`upper') if `lower' >  0 & `y_sel' == `i' & `touse';
		replace `lambda' = (normden(`lower') - normden(`upper')) / `denom' if `y_sel' == `i' & `touse';
		replace `dlambda' = -`lambda'^2 + (`lower' * normden(`lower') - `upper' * normden(`upper')) / `denom'
		  if `y_sel' == `i' & `touse';
	};

	if missing("`twostep'") {;
		// If ML requested, compute likelihood ll_0 under assumption of
		// independent equations (rho == 0).
		tempname ll_0;
		scalar `ll_0' = e(ll);
		forvalues i = 0/`J' {;
			if real(substr("$OHECKMAN_HASY",`i'+1, 1)) {;
				regress `y_reg' `x_reg' `wgt' if `y_sel' == `i' & `touse';	// Second stage assuming rho_i == 0.
				scalar `ll_0' = `ll_0' - 0.5 * e(N) * (ln(2*_pi) + ln(e(rss)/e(N)) + 1);
			};
		};
	};
	else {;
		if "`robust'`cluster'`weight'" != "" {;
			di in red "weights, robust, and cluster() not allowed with the twostep option.";
			exit 198;
		};
		tempvar dcut;
		tempname Voprb XpX1 F Fcol VBi V;
		matrix `Voprb' = get(VCE);
		matrix `V' = `Voprb';
		gen double `dcut' = .;
	};

	// Second step: regression with lambda as extra regressor
	forvalues i = 0/`J' {;
		if real(substr("$OHECKMAN_HASY",`i'+1, 1)) {;
			mean `dlambda' `wgt' if `y_sel' == `i' & `touse';	// -heckman- neglects to use weights here!
			scalar `dlambdabar' = _b[`dlambda'];
			regress `y_reg' `lambda' `x_reg' `wgt' if `y_sel' == `i' & `touse';
			matrix `bi' = e(b);
			local selvalue = `cat'[`i'+1,1];
			matrix coleq `bi' = `y_reg0'`selvalue';
			scalar `sigmai' = sqrt(e(rss)/e(N) - _b[`lambda']^2 * `dlambdabar');
			scalar `rhoi' = _b[`lambda'] / `sigmai';
			if missing("`twostep'") {;
				// Following -heckman-, we truncate extreme values of rho to +/-.85
				// before passing them as initial values to -ml-.
				if abs(`rhoi') > .85 {;
					noi disp in blue
					"Warning: Two-step initial estimate of rho`selvalue' = " `rhoi' " truncated to +/-.85.";
				};
				scalar `rhoi' = max(min(`rhoi',.85), -.85);
				//scalar `sigmai' = _b[`lambda'] / `rhoi';

				matrix `b' = (nullmat(`b'), `bi'[1, 2...]);
			};
			else {;
				if abs(`rhoi') > 1 {;
					noi disp in red
					"Warning: Estimate of rho`selvalue' = " `rhoi' " is outside feasible interval [-1, 1].";
				};
				local names : colnames `bi';
				local names : subinstr local names "`lambda'" "_lambda";
				matrix colnames `bi' = `names';
				matrix `b' = (nullmat(`b'), `bi');

				// Estimate covariance matrix for second step
				matrix accum `F' = `x_sel_c' `lambda' `x_reg' [iw=`dlambda'] if `y_sel' == `i' & `touse';
				matrix `F' = `F'[`n_selvarsplus1'..., 1..`n_selvars'];
				forvalues j = 1/`J' {;
					if `j' == `i' {;
						replace `dcut' = (`lambda' - `lower') * normden(`lower') / `denom' if `y_sel' == `i' & `touse';
						matrix accum `Fcol' = `dcut' `lambda' `x_reg' if `y_sel' == `i' & `touse';
						matrix `F' = (`F', `Fcol'[2..., 1]);
					};
					else if `j' == `i'+1 {;
						replace `dcut' = (`upper' - `lambda') * normden(`upper') / `denom' if `y_sel' == `i' & `touse';
						matrix accum `Fcol' = `dcut' `lambda' `x_reg' if `y_sel' == `i' & `touse';
						matrix `F' = (`F', `Fcol'[2..., 1]);
					};
					else {;
						matrix `F' = (`F', J(rowsof(`F'),1,0));  // add a column of zeros
					};
				};

				replace `dcut' = 1 + `rhoi'^2 * `dlambda' if `touse'; // ignore the name dcut // PLUS SIGN CORRECTS BUG IN LIMDEP VERSION
				matrix accum `VBi' = `lambda' `x_reg' [iw=`dcut'] if `y_sel' == `i' & `touse';
				matrix `XpX1' = get(VCE) / e(rmse)^2;	// (X'X) inverse
				matrix `VBi' = `sigmai'^2 * `XpX1' * (`VBi' + `rhoi'^2*`F'*`Voprb'*`F'') * `XpX1';

				oheckman_buildblockdiag `V' `VBi';
			};
			matrix `rho' = (nullmat(`rho'), `rhoi');
			matrix `sigma' = (nullmat(`sigma'), `sigmai');
		};
	};

	oheckman_labelmatrix `cutoffs' "cutoff" `cat' 1;
	oheckman_labelmatrix `rho' "rho" `cat' 0;
	oheckman_labelmatrix `sigma' "sigma" `cat' 0;
	matrix coleq `b_sel' = `y_sel0';
	matrix coleq `cutoffs' = "cutoffs";

	if ~missing("`twostep'") {;
		tempname bfull;
		matrix `bfull' = (`b_sel', `cutoffs', `b');
		local names : colfullnames `bfull';
		matrix colnames `V' = `names';
		matrix rownames `V' = `names';

		count if `touse';	// store #obs in r(N).
		capture ereturn post `bfull' `V', obs(`r(N)');
		if _rc {;
			if _rc == 506 {;
				noi disp in red "Estimate of rho outside the interval [-1, 1] has led";
				noi disp in red "to a covariance matrix that is not positive definite.";
				local i = rowsof(`Voprb') + 1;
				matrix `V'[`i', `i'] = 0*`V'[`i'..., `i'...];
			};
			ereturn post `bfull' `V', obs(`r(N)');
		};
		matrix `V' = e(V);
		if trace(`V') == 0 noi disp in red "Warning:  Variance matrix is highly singular.";

		ereturn local title "Ordered probit selection model";
		ereturn local title2 "(two-step estimates)";
		ereturn local method "two-step";
	};
	else {;
		// Construct arguments to -ml-.
		oheckman_converttoml `cutoffs' `rho' `sigma';
		local cutargs "/cutoff1";
		forvalues i = 0/`J' {;
			if real(substr("$OHECKMAN_HASY",`i'+1, 1)) {;
				local selvalue = `cat'[`i'+1,1];
				local mleqs `mleqs' (`y_reg0'`selvalue': `x_reg');
				local athrhoargs `athrhoargs' /athrho`selvalue';
				local lnsigmaargs `lnsigmaargs' /lnsigma`selvalue';
				local athrhonames `athrhonames' athrho`selvalue':_cons;
				local lnsigmanames `lnsigmanames' lnsigma`selvalue':_cons;
				local rhonames "`rhonames' :rho`selvalue'";
				local sigmanames "`sigmanames' :sigma`selvalue'";
				local teststring `teststring' [athrho`selvalue']_b[_cons];
			};
		};
		local cutnames cutoff1:_cons;
		forvalues i = 2/`J' {;
			local cutargs `cutargs' /lndelta`i';
			local cutnames `cutnames' lndelta`i':_cons;
		};

		matrix colnames `cutoffs' = `cutnames';
		matrix colnames `rho'     = `athrhonames';
		matrix colnames `sigma'   = `lnsigmanames';
		matrix `init' = (`b_sel', `b', `cutoffs', `rho', `sigma');
		local init_cond init(`init', skip);
		//noi disp "Two-step estimates and initial values for ML:";
		//noi matrix list `init', noblank noheader;

		// ML
		//gen touseo = `touse';
		noi ml model d2 oheckman_d2
			(`y_sel0': `y_sel' `y_reg' = `x_sel_c', noconstant)
			`mleqs'
			`cutargs'
			`athrhoargs'
			`lnsigmaargs'
			`wgt'
			if `touse'
			,
			title("Ordered probit selection model")
			search(off)
			`init_cond'
			maximize
			missing
			nopreserve
			`clopt'
			`robust'
			`mlopts'
			;

		oheckman_convertfromml `cutoffs' `rho' `sigma' `cat';
		matrix colnames `rho'     = `rhonames';
		matrix colnames `sigma'   = `sigmanames';

		ereturn scalar ll_0 = `ll_0';			// loglikelihood for non-correlated case
		ereturn scalar k_aux = 2*`numyeq'+`J';	// identify ancillary parameters
		ereturn local method "ml";

		// Compute test of independent equations (rho == 0).
		if missing("`robust'") {;
			ereturn local chi2_ct "LR";
			ereturn scalar chi2_c = 2 * (e(ll) - `ll_0');
		};
		else {;
			ereturn local chi2_ct "Wald";
			test `teststring';
			ereturn scalar chi2_c = r(chi2);
		};
		ereturn scalar p_c = chiprob(`numyeq', e(chi2_c));
	};

      ereturn local cmd "oheckman";
	ereturn local predict "oheckm_p";
	ereturn local y_reg `y_reg0';
	ereturn local y_sel `y_sel0';
	ereturn local x_reg `x_reg';
	ereturn local x_sel `x_sel_c';
	ereturn scalar numeq = `numyeq';
	ereturn matrix sigma = `sigma';
	ereturn matrix rho = `rho';
	ereturn matrix cutoffs = `cutoffs';
	ereturn matrix cat = `cat';

	}; // end quietly

	if missing("`twostep'") {;
		oheckman_display, level(`level');
	};
	else {;
		oheckman_display2, level(`level');
	};
end; // end program oheckman_mx

cap program drop oheckman_labelmatrix;
program define oheckman_labelmatrix;
	args m lbl cat iscutoff;

	local J = $OHECKMAN_NEQ - 1;
	if `iscutoff' {;
		forvalues i = 1/`J' {;
			local names `"`names' `lbl'`i'"';
		};
	};
	else {;
		forvalues i = 0/`J' {;
			if real(substr("$OHECKMAN_HASY",`i'+1, 1)) {;
				local selvalue = `cat'[`i'+1,1];
				local names = `"`names' `lbl'`selvalue'"';
			};
		};
	};

	matrix colnames `m' = `names';
end; // end program oheckman_labelmatrix

cap program drop oheckman_converttoml;
program define oheckman_converttoml;
	args cutoffs rho sigma;

	local J = $OHECKMAN_NEQ - 1;
	forvalues i = 2/`J' {;
		local previ = `i'-1;
		matrix `cutoffs'[1,`i'] = ln(`cutoffs'[1,`i'] - `cutoffs'[1,`previ']);
	};
	local len = colsof(`rho');
	forvalues i = 1/`len' {;
		matrix `rho'[1,`i'] = atanh(`rho'[1,`i']);
		matrix `sigma'[1,`i'] = ln(`sigma'[1,`i']);
	};
end; // end program oheckman_converttoml

cap program drop oheckman_convertfromml;
program define oheckman_convertfromml;
	args cutoffs rho sigma cat;

	local J = $OHECKMAN_NEQ - 1;
	matrix `cutoffs'[1,1] = _b[/cutoff1];
	forvalues i = 2/`J' {;
		local previ = `i'-1;
		matrix `cutoffs'[1,`i'] = `cutoffs'[1,`previ'] + exp(_b[/lndelta`i']);
	};
	local mati = 0;
	forvalues i = 0/`J' {;
		if real(substr("$OHECKMAN_HASY",`i'+1, 1)) {;
			local selvalue = `cat'[`i'+1,1];
			matrix `rho'[1,`++mati'] = tanh(_b[/athrho`selvalue']);
			matrix `sigma'[1,`mati'] = exp(_b[/lnsigma`selvalue']);
		};
	};
end; // end program oheckman_convertfromml

*** oheckman_buildblockdiag m1 m2
*** Replaces m1 with the block-diagonal matrix (m1, 0 \ 0, m2).
*** m1 and m2 must be square.
cap program drop oheckman_buildblockdiag;
program define oheckman_buildblockdiag;
	args m1 m2;
	tempname z;
	matrix `z' = J(rowsof(`m1'), rowsof(`m2'), 0);
	matrix `m1' = (`m1', `z' \ `z'', `m2');
end; // end program oheckman_buildblockdiag
