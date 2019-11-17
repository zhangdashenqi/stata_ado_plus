* ado-file for censored quantile IV estimation
*
* Dec 21, 2012
* Sukjin Han / Amanda Kowalski
*
* 1.0.0: censored quantile IV, basic options, only continuous variables (so no logit), no btsp rep
* 2.0.0: other options (censoring points, dropping rate)
* 3.0.0: All debugged except matrix command part, basic ereturns,
* 	erase label in coefficients and taucount, simplify coding for coefficients variables(WRONG),
* 	use checkpoints
* 4.0.0: ereturn doesn't allow missing values so change coding to distinguish no s.e. and boot s.e.,
* 	bootstrap works, maybe you don't want to use "ereturn post" but just "ereturn"
* 5.0.0: mata failed in ver 4 so use different coding for matrix "robust"
* 6.0.0: local macro for entries of matrix "robust", basic ereturn matrix completed
* 7.0.0: incorporating cqr and qiv option,
* 	cqr: no first stage, drop ehat in the rest regressions,
* 	qiv: no censored depvar (or set the censored point to be the min value of depvar),
* 	deleted diagnosing above zero portion
* 	NO `regressor' in first stage!!!!
* 8.0.0: weighted bootstrap and cleanup, drop tabstat parts
* 9.0.0: ADD cqr
* 10.0.0: changed table label
* 11.0.0: USE "tempvar" and NO "gen" / drop "save tempresults" / use "quietly save",
* 	tempvar varname, and then, quietly gen `varname' = ~~~,
* 	drop generating variables to store coefficients part (and "gen" instead of "replace"),
* 	CAUTION USING "REPLACE" ONLY WITH TEMPVAR, otherwise use "gen",
* 	drop meaningless s.e. part
* 12.0.0: drop seed iter, display final tables, viewlog option, viewrobust option, top option,
* 	CAUTION: key tempvar's before iteration loop
* 13.0.0: first and second LDV options, weight and weight option, seedset option
* 14.0.0: drop "capture drop" of tempvar, option for step size of quantiles and thresholds in first stage estimation,
* 	change option names (use CI, norobust), dot for no CI case
* 15.0.0: apply weight option, CAUTION: force pweight in ldv models, iter and seed as tempvar
* 16.0.0: different options for quantiles and thresholds (CAUTION: no varname with `tau' since now it is not integer)
* 17.0.0: force aweight for qreg, and pweight for LDV, and multiplication of weights in weighted bootstrap (OLS has the user-specified weights)
* 18.0.0: weight for weightboot in front; bsample command alive CHECK THIS
* 19.0.0: change errors in replacement of 3rd step coefficients with 2nd step ones
* 20.0.0: incorporating marginal effects; in order to do so, switch variables `estimator'`var' and f`estimator'`var' to be local macros
* 21.0.0: corrected errors in bootstrap rep of ver.20
* 22.0.0: correct weighted bootstrap weight error, apply weightboot for ols, apply inverse normal in dist estimation
* 23.0.0: if nthresh <= 1600 do existing foreach loop, else do forvalues
* 24.0.0: all exogenous variables as IV
* 25.0.0: alternative option for top
* 26.0.0: exclude option: exclude exog variables in 1st stage
* 27.0.0: different use of capture command in ALL tau loop
* 28.0.0: use capture and _rc for estimations that are not converging
* 29.0.0: use capture and _rc for dropped variables
* 30.0.0: solve the problem of maxvar, by dropping unnecessary variables,
* 31.0.0: by changing tempvar to local
* 32.0.0: redefine outcome variables
* 33.0.0: correct missing value problem in c`tau' and deltan, correct the calculation of mean of coeff by adding "if `itervar'~=1"
* 34.0.0: data type, double, for fitted values; warnings for not converging run in bootstrap reps


* CAUTION: NO TAG MACRO IN ADO FILE
* CAUTION: NO COMMENTS ON THE SAME LINE WITH "*"; INSTEAD USE "/* */"
* CAUTION: There are places where you need to forcefully drop temporary variables
* CAUTION: For default values, need to be careful when writing error messages


* CQIV.ADO
program cqiv, eclass
version 10
#delimit;
syntax anything(name=0) [if] [in] [aweight pweight]
 [,
 Quantiles(numlist >0 <100 sort)
 Censorpt(real 0)
 Top
 Uncensored
 Exogenous
 Firststage(string)
 EXClude
 nquant(real 50)
 nthresh(real 50)
 ldv1(string)
 ldv2(string)
 drop1(real 10) drop2(real 3)
 COnfidence(string) Bootreps(real 20) Setseed(real 777)
 LEvel(real 95)
 CORner
 NOrobust
 VIEWLog
 ];
#delimit cr
	if "`quantiles'"==""{
		local quantiles "50"
	}
	
	* No firststage option in exogenous case
	if "`exogenous'"!="" & "`firststage'"!=""{
		di in red "No first stage estimation in exogenous case."
		exit
	}
	
	* No corner solution marginal effect option in uncensored case
	if "`corner'"!="" & "`uncensored'"!=""{
		di in red "No corner solution option in uncensored case."
		exit
	}
	
	if "`firststage'"==""{
		local firststage "quantile"	/* this is clever */
	}
	if "`confidence'"==""{
		local confidence "no"	/* this is clever, too */
	}
	if "`confidence'"=="no"{
		local reps "1"
	}
	if "`confidence'"=="boot" | "`confidence'"=="weightboot"{
		local reps=`bootreps'+1
		if "`confidence'"=="weightboot"{
		qui gen eweight=-ln(1-uniform())
		if "`weight'"!="" qui replace eweight `exp'*eweight
		}
	}


	
	* Weights
	if "`weight'"!="" {
		local ldvweight "pweight"
		local qregweight "aweight"
	}
	
	* Need to have distribution estimation for ldv1 option
	if "`firststage'"!="distribution" & "`ldv1'"!=""{
		di in red "ldv1 option only with distribution regression for the first stage estimation."
		exit
	}
	
	* Need to have correct estimation for these options (THIS IS WRONG, since numthresh and numquant always take default values)
	* if "`firststage'"!="distribution" & "`numthresh'"!=""{
	* 	di in red "Numthresh option only with distribution regression for the first stage estimation."
	* 	exit
	* }
	* if "`firststage'"!="quantile" & "`numquant'"!=""{
	* 	di in red "Numquant option only with quantile regression for the first stage estimation."
	* 	exit
	* }
	
	if "`ldv1'"==""{
		local ldv1 "probit"
	}
	if "`ldv2'"==""{
		local ldv2 "probit"
	}	
	
	
	gettoken depvar 0 : 0, parse("(")
	gettoken depvar regressor : depvar, parse(" ")
	gettoken weg 0 : 0, parse("(")
	gettoken 0 weg : 0, parse(")")
	gettoken weg empty : weg, parse(")")
	if "`empty'"!=""{
		dis as error "Syntax error: `empty' is not at the correct place."
		exit
	}
	gettoken endogvar 0 : 0, parse("=")
	gettoken weg 0 : 0, parse("=")
	local instrument="`0'"
	
	if "`exogenous'"=="" & ("`endogvar'"=="" | "`instrument'"=="") {
		dis as error "Endogenous variable and instrument must be provided"
		exit
	}
	if "`exogenous'"!="" & ("`endogvar'"!="" | "`instrument'"!=""){
		dis as error "No endogenous variable or instrument needs be provided in exogenous case."
		exit
	}
		
	* Check that there are one endogen
	tokenize `endogvar'
	local endogvar="`1'"
	if "`2'"!=""{
		di in red "Only one endogenous variable may be specified."
		exit
	}
	
	
		
	
	marksample touse
	markout `touse' `depvar' `endogvar' `instrument'
	
	quietly summarize `touse'
	local obs = r(sum)

	* Check the censoring point is reasonable
	
	if "`uncensored'"=="" {
		qui sum `depvar'
		if r(min)>`censorpt' | r(max)<`censorpt'{
			di in red "Unreasonable censoring point; reasonable amount of observations should have the value of the censoring point."
			exit
		}
	}
	
	* Incorporate top option (Also at the last part of the code)
	qui if "`top'"!="" {
		replace `depvar' = -`depvar'
		local censorpt = -`censorpt'
	}
	
	
	
	* Put quantiles in a matrix
	tempname quants
	tokenize "`quantiles'", parse(" ")
	local i=1
	while "`1'" != "" {
		matrix `quants'=nullmat(`quants')\(`1')
		mac shift 
		local i=`i'+1
	}
	


* Temporary Files
tempfile temporigin tempresults
quietly save "`temporigin'"


* Temporary Variables
if "`exogenous'"=="" tempvar ehat	/* tempvar for ehat here */
if "`exogenous'"!="" local ehat ""


local taurange "`quantiles'"
local rhs "`endogvar' `regressor' _cons `ehat'"


* Define variables to store coefficient, before bootstrap loop
qui foreach tau of numlist `taurange' {
	foreach var of local rhs {
		tempvar coeff`tau'`var'
	}
}


tempvar seedvar itervar


* BOOTSTRAP LOOP begins here
di in gr "(fitting base model)"	
foreach iter of num 1/`reps' {
if `iter'==2 {
	di in gr "(bootstrapping " _c
	}
	
	* LOAD DATA
	
	clear
	use "`temporigin'"

	* Other Primitive Local Variables
	local seed=`setseed'+`iter'
	set seed `seed'

	
	if `iter'~=1 bsample
	

	local prb = (50+`level'/2)/100
	local calc = invnormal(`prb')

	* Generate intermediate variables to store diagnostic test results
	global tablelist ""
	if "`uncensored'"=="" {
	if "`top'"=="" local opt "complete c pctj0 censorpt pctabovecensorpt deltan pctj1 pctj0inj1 inj1notj0 obj1v obj2v thirdbetter"
	else local opt "complete c pctj0 censorpt pctbelowcensorpt deltan pctj1 pctj0inj1 inj1notj0 obj1v obj2v thirdbetter"
	}
	
	
	foreach o of local opt {
		foreach tau of numlist `taurange' {
			local `o'`tau'=.
		}	
	}
	* Generate matrix to store the results
	if "`uncensored'"=="" & `iter'==1 matrix robust0 = J(1,12,.)
	

	* Estimation
quietly {
if "`viewlog'"!="" local viewlog "noisily"

	if "`exogenous'"==""{
		if "`exclude'"=="" local regressor1 "`regressor'"
		else local regressor1 ""
		
		****************************************
		* QUANTILE First Stage Regression
		****************************************
		
		qui if "`firststage'"=="quantile" {
			local ftau0 = (1/(`nquant'+1))*100
			local ftau1 = (`nquant'/(`nquant'+1))*100
			local ftaurange "`ftau0'(`ftau0')`ftau1'"
			local ftaucount=0
			tempvar lessthan
			gen `lessthan'=0
			foreach ftau of numlist `ftaurange' {
				if `iter'==1 `viewlog' qreg `endogvar' `instrument' `regressor1' if `touse' [`qregweight'`exp'], quantile(`ftau')
				if `iter'~=1 {
					if "`confidence'"=="boot"{
					`viewlog' qreg `endogvar' `instrument' `regressor1' if `touse' [`qregweight'`exp'], quantile(`ftau')
					}
					if "`confidence'"=="weightboot"{
					`viewlog' qreg `endogvar' `instrument' `regressor1' if `touse' [aweight=eweight], quantile(`ftau')
					}
				}
				tempvar pred`ftaucount'
				`viewlog' predict `pred`ftaucount''
				replace `lessthan'=`lessthan'+1 if `pred`ftaucount''<=`endogvar'
				local ftaucount=`ftaucount'+ 1
			}
			gen `ehat'=`lessthan'/`ftaucount'
			replace `ehat'=invnormal(`ehat')	/* CHECK */
			drop `lessthan' `pred`ftaucount''
		}
		
		
		qui if "`firststage'"=="distribution" {
			gen `ehat'=.
			local tot `=_N'
			local penult= `tot' - 1
			local fthresh0 = (1/(`nthresh'+1))*100
			local fthresh1 = (`nthresh'/(`nthresh'+1))*100
			local fthreshrange "`fthresh0'(`fthresh0')`fthresh1'"
			
			if `nthresh' <= 1600 {
			foreach obss of numlist `fthreshrange' {
				tempvar val yp
				egen `val' = pctile(`endogvar'), p(`obss')
				gen `yp'=(`endogvar'<=`val')
				if `iter'==1 `viewlog' `ldv1' `yp' `instrument' `regressor1' [`ldvweight'`exp']
				if `iter'~=1{
					if "`confidence'"=="boot"{
					`viewlog' `ldv1' `yp' `instrument' `regressor1' [`ldvweight'`exp']
					}
					if "`confidence'"=="weightboot"{
					`viewlog' `ldv1' `yp' `instrument' `regressor1' [pweight=eweight]
					}
				}
				tempvar yhat
				`viewlog' predict `yhat'
				replace `ehat'=`yhat' if (`endogvar'<=`val' & `ehat'==.)
				drop `val' `yp' `yhat'
			}
			}
			
			else {
			forvalues obss = `fthreshrange' {
				tempvar val yp
				egen `val' = pctile(`endogvar'), p(`obss')
				gen `yp'=(`endogvar'<=`val')
				if `iter'==1 `viewlog' `ldv1' `yp' `instrument' `regressor1' [`ldvweight'`exp']
				if `iter'~=1{
					if "`confidence'"=="boot"{
					`viewlog' `ldv1' `yp' `instrument' `regressor1' [`ldvweight'`exp']
					}
					if "`confidence'"=="weightboot"{
					`viewlog' `ldv1' `yp' `instrument' `regressor1' [pweight=eweight]
					}
				}
				tempvar yhat
				`viewlog' predict `yhat'
				replace `ehat'=`yhat' if (`endogvar'<=`val' & `ehat'==.)
				drop `val' `yp' `yhat'
			}
			}
			
			replace `ehat'=1 in `tot'
			replace `ehat'=invnormal(`ehat')
		}
		
		
		if "`firststage'"=="ols" {
			if `iter'==1 `viewlog' reg `endogvar' `instrument' `regressor1' if `touse' [`weight'`exp']
			if `iter'~=1{
					if "`confidence'"=="boot"{
					`viewlog' reg `endogvar' `instrument' `regressor1' if `touse' [`weight'`exp']
					}
					if "`confidence'"=="weightboot"{
					if "`weight'"=="" `viewlog' reg `endogvar' `instrument' `regressor1' if `touse' [weight=eweight]
					else `viewlog' reg `endogvar' `instrument' `regressor1' if `touse' [`weight'=eweight]
					}
				}	
			`viewlog' predict `ehat', residuals
		}
	}
	
	
	****************************************
	* CQIV control function approach
	****************************************	

	if "`uncensored'"=="" {
		local q "`drop1'"
		local q2 "`drop2'"
		tempvar uncensvar
		qui gen `uncensvar'=(`depvar'>`censorpt')	/* local `censorpt' instead of variable censorpt */
	}

	
	foreach tau of numlist `taurange' {
	
		local estimator "cqiv`tau'"
		
		if "`uncensored'"=="" {

			***************************************
			* CQR Step 1:  Probability Model to determine sample j0
			***************************************
			
			if `iter'==1 capture `viewlog' `ldv2' `uncensvar' `endogvar' `regressor' `ehat' if `touse' [`ldvweight'`exp']
        	if `iter'~=1{
				if "`confidence'"=="boot"{
				capture `viewlog' `ldv2' `uncensvar' `endogvar' `regressor' `ehat' if `touse' [`ldvweight'`exp']
				}
				if "`confidence'"=="weightboot"{
				capture `viewlog' `ldv2' `uncensvar' `endogvar' `regressor' `ehat' if `touse' [pweight=eweight]
				}
			}
			tempvar uncenhat
			if _rc==0 `viewlog' predict double `uncenhat'
			else `viewlog' gen `uncenhat'=.

			if _rc==0 local complete`tau'=3
						
			
			tempvar cutoffvar cutoff
			qui egen `cutoffvar'=pctile(`uncenhat') if `uncenhat'>(1-(`tau'/100)), p(`q')
			* noi sum `cutoffvar'
			* noi count if missing(`cutoffvar')
			qui egen `cutoff'=mean(`cutoffvar')
			* Report the value of c
			local c`tau'=`cutoff'-(1-(`tau'/100)) in 1

			
			* Keep in j0 if the predicted value is larger than the cutoff value
			tempvar j0
			qui gen `j0'=(`uncenhat'>`cutoffvar')
			* The mean is the percent of the observations that have been selected for j0 
			qui sum `j0'
			local pctj0`tau'=r(mean)*100     

			drop `cutoffvar' `cutoff'
			
			
			***************************************
			* CQR Step 2:   Run the quantile regression on sample j0
			***************************************
	        if `iter'==1 capture `viewlog' qreg `depvar' `endogvar' `regressor' `ehat' if `j0' & `touse' [`qregweight'`exp'], quantile(`tau')
	        if `iter'~=1{
				if "`confidence'"=="boot"{
				capture `viewlog' qreg `depvar' `endogvar' `regressor' `ehat' if `j0' & `touse' [`qregweight'`exp'], quantile(`tau')	
				}
				if "`confidence'"=="weightboot"{
				capture `viewlog' qreg `depvar' `endogvar' `regressor' `ehat' if `j0' & `touse' [aweight=eweight], quantile(`tau')
				}
			}
			tempvar yhat`tau'
		
			if _rc==0 {
				`viewlog' predict double `yhat`tau''	/* Missing values generated here */
				local complete`tau'=2
				qui foreach i of local rhs {
				capt local f`estimator'`i'=_b[`i']	/* cqiv`tau'varname */
				* if _rc!=0 local f`estimator'`i'=.
				}	
			}
			else {
				`viewlog' gen `yhat`tau''=.
				qui foreach i of local rhs {
				local f`estimator'`i'=.
				}
			}	 
		 
		 

		* What percent of observations are above (below) censorpt?
			
			qui count if `yhat`tau''>`censorpt'
			local pctabovecensorpt`tau'=(r(N)/_N)*100
			
			* I guarantee that fewer observations are thrown away than in the previous step by using q2<q1
			tempvar cutoffvar2 cutoff2
			qui egen `cutoffvar2'=pctile(`yhat`tau'') if `yhat`tau''>`censorpt', p(`q2')
			* Report the value of deltan - would be different if I hadn't transformed the data to be censored at zero
			qui egen `cutoff2'=mean(`cutoffvar2')	/* In order not to pick missing value */
			local deltan`tau' = `cutoff2' in 1
		  
		  
			* Keep in j1 if the predicted value is larger than cutoff2
			tempvar j1
			qui gen `j1'=(`yhat`tau''>`cutoffvar2')
			qui sum `j1'
			local pctj1`tau'=r(mean)*100

			drop `cutoffvar2' `cutoff2'
			
			* Check:  Is j0 a subset of j1?
				* What percent of observations in j0 are in j1
				qui count if `j0'
				local j0num=r(N)
				qui count if `j0' & `j1'
				local j1num=r(N)
				local pctj0inj1`tau'=(`j1num'/`j0num')*100
				* How many observations are in j1 but not j0
				qui count if `j1'==1 & `j0'==0
				local inj1notj0`tau'=r(N)

			* NEED TO CHANGE THIS FOR QIV
			* Compute the value of the CQR objective function after the first step
			tempvar cenresid cenresidpos objobs obj1var`tau'
			qui gen `cenresid'=`depvar'-`yhat`tau''
			qui replace `cenresid'=`depvar' - `censorpt' if `yhat`tau''<`censorpt'
			qui gen `cenresidpos'=(`cenresid'>0)
			qui gen `objobs'=( (1-(`tau'/100))*(1 - `cenresidpos') + (`tau'/100)*`cenresidpos' )*abs(`cenresid')
			qui egen `obj1var`tau''=total(`objobs')
			local obj1v`tau' = `obj1var`tau'' in 1
			drop `yhat`tau'' `cenresid' `cenresidpos' `objobs' `obj1var`tau''	/* CAUTION: you must drop this, cuz it is redefined below */
			
			
		}	/* Procedure for 'censored' quantile IV ends here */
		
			***************************************
			* CQR Step 3:   Run the quantile regression on sample j1
			***************************************
		if "`uncensored'"==""{
			if `iter'==1 capture `viewlog' qreg `depvar' `endogvar' `regressor' `ehat' if `j1' & `touse' [`qregweight'`exp'], quantile(`tau')
	        if `iter'~=1{
				if "`confidence'"=="boot"{
				capture `viewlog' qreg `depvar' `endogvar' `regressor' `ehat' if `j1' & `touse' [`qregweight'`exp'], quantile(`tau')	
				}
				if "`confidence'"=="weightboot"{
				capture `viewlog' qreg `depvar' `endogvar' `regressor' `ehat' if `j1' & `touse' [aweight=eweight], quantile(`tau')
				}
			}
		}
		if "`uncensored'"!=""{
			if `iter'==1 capture `viewlog' qreg `depvar' `endogvar' `regressor' `ehat' if `touse' [`qregweight'`exp'], quantile(`tau')
	        if `iter'~=1{
				if "`confidence'"=="boot"{
				capture `viewlog' qreg `depvar' `endogvar' `regressor' `ehat' if `touse' [`qregweight'`exp'], quantile(`tau')	
				}
				if "`confidence'"=="weightboot"{
				capture `viewlog' qreg `depvar' `endogvar' `regressor' `ehat' if `touse' [aweight=eweight], quantile(`tau')
				}
			}
		}
		/* CHECK: maybe you need this although tempvar is already defined but variable dropped */
		tempvar yhat`tau'	/* Need to use this */
		
		if _rc!=0 {
			`viewlog' gen `yhat`tau''=.
			qui foreach i of local rhs {
			local `estimator'`i'=.
			}
		}
		
		else {
			`viewlog' predict double `yhat`tau''	/* Missing values generated here */
			if "`uncensored'"=="" local complete`tau'=1
			qui foreach i of local rhs {
			capt local `estimator'`i'=_b[`i']	/* cqiv`tau'varname */
			 if _rc!=0 local `estimator'`i'=.
			}
		}
		
		
		capture drop `j0' `j1'	/* CAUTION: maybe need to drop b/c of iterations */
		
		
		qui if "`uncensored'"=="" {
		
			* Compute the value of the CQR objective function after the second step
			tempvar cenresid cenresidpos objobs obj2var`tau'
			gen `cenresid'=`depvar'-`yhat`tau''
			qui replace `cenresid'=`depvar' - `censorpt' if `yhat`tau''<`censorpt'
			gen `cenresidpos'=(`cenresid'>0)
			gen `objobs'=( (1-(`tau'/100))*(1 - `cenresidpos') + (`tau'/100)*`cenresidpos' )*abs(`cenresid')
			egen `obj2var`tau''=total(`objobs')
			local obj2v`tau' = `obj2var`tau'' in 1
			drop `yhat`tau'' `cenresid' `cenresidpos' `objobs' `obj2var`tau''
			
			
			* In terms of the objective function, was the third step an improvement?
			local thirdbetter`tau'=(`obj2v`tau''<`obj1v`tau'')
			
			
			* REPLACE COEFFICIENTS IF SECOND STEP IS BETTER
			qui foreach i of local rhs {
				if (1-`thirdbetter`tau'') local `estimator'`i'=`f`estimator'`i''
				}	
			
			
				* "AVERAGE" CORNER SOLUTION COEFFICIENT
			if "`corner'"!="" {
				tempvar predq`tau'
				local rhs1 "`endogvar' `regressor' `ehat'"
				capt di "``estimator'_cons'"			/* CAUTION: this is local macro NOT variable; you cannot summarize, so display */
				if _rc!=0 local `estimator'_cons=.
				gen `predq`tau''=``estimator'_cons'
				qui foreach j of local rhs1 {
				capt di "``estimator'`j''"			/* CAUTION: this is local macro NOT variable; you cannot summarize, so display */
				if _rc!=0 local `estimator'`j'=.
				capt replace `predq`tau'' = `predq`tau'' + ``estimator'`j''*`j'
				}		
				
				tempvar cornerindic`tau'
				gen `cornerindic`tau''=(`predq`tau''>=`censorpt')
				replace `cornerindic`tau''=. if `predq`tau''==.
				capt noi sum `cornerindic`tau''
				capt local cornerprob`tau' = `r(mean)'
				if _rc!=0 local cornerprob`tau'=.
				
				qui foreach i of local rhs {
				local `estimator'`i'= `cornerprob`tau''*``estimator'`i''
				}
				drop `cornerindic`tau'' `predq`tau''
				
			}

			
			
			if `iter'==1 {
			#delimit;
			matrix augm = [`complete`tau'', `c`tau'', `pctj0`tau'', `censorpt', `pctabovecensorpt`tau'',
			 `deltan`tau'', `pctj1`tau'', `pctj0inj1`tau'', `inj1notj0`tau'', `obj1v`tau'', `obj2v`tau'', `thirdbetter`tau''];
			matrix robust0 = robust0\augm;
			#delimit cr
			}
		
		}	
	
				
		* NOW assign coefficients values in the variables defined right before the bootstrap loop
		qui foreach i of local rhs {
		gen `coeff`tau'`i'' = ``estimator'`i'' in 1
		}
	
	
	}
	
	
}
	
		if "`uncensored'"=="" matrix robust = robust0[2...,1...]
	
	
	****************************************
	* Save results after each iteration
	****************************************
	* tempvar seedvar itervar (CAUTION: moved to the front)
	qui gen `seedvar'=`seed' in 1
	if `iter'==1 qui replace `seedvar'=0 in 1 
	qui gen `itervar'=`iter' in 1
	order `seedvar' `itervar'

	capture drop `ehat' `uncensvar'
	
	qui keep in 1
	* temp files inside the loop
	tempfile `tag'`seed' `tag'`seed'all
	qui save "``tag'`seed''"

	local prevseed = `seed'-1
	if `seed'~=(`setseed'+1) append using "``tag'`prevseed'all'"
	qui save "``tag'`seed'all'"

if `iter'>=2 di in gr "." _c
if `iter'>=2 & `iter'==`reps' di in gr ")"
}


quietly save "`tempresults'"


******************************************************
* Statistics on Bootstrap replications
******************************************************

sort `itervar'

local taunum=1	/* initial value for tau loop */
foreach tau of numlist `taurange' {
	capture quietly {
        local varnum=1	/* initial value for rhs variable loop */
        foreach var of local rhs { 	/* RECALL: local rhs "`endogvar' `regressor' _cons `ehat'" */
                * In practice, if there are 100 observations, this gives the 3rd and 98th percentile
		local `var'`tau'=`coeff`tau'`var'' in 1
				local leftprob=50-`level'/2
				local rightprob=50+`level'/2
				tempvar l`tau'`var'
                egen `l`tau'`var''=pctile(`coeff`tau'`var'') if `itervar'~=1, p(`leftprob') /* CAUTION: See "sum iter" to know what this means */
                if "`confidence'"=="boot" | "`confidence'"=="weightboot" local l`var'=`l`tau'`var'' in 2
                if "`confidence'"=="no" local l`var'=.	/* NO CI */
                replace `l`tau'`var''=`l`var''
                tempvar u`tau'`var'
                egen `u`tau'`var''=pctile(`coeff`tau'`var'') if `itervar'~=1, p(`rightprob')
                if "`confidence'"=="boot" | "`confidence'"=="weightboot" local u`var'=`u`tau'`var'' in 2
                if "`confidence'"=="no" local u`var'=.	/* NO CI */
                replace `u`tau'`var''=`u`var''
                * Also calculate the mean of the bootstrapped replications
                tempvar mean`var'
                if "`confidence'"=="boot" | "`confidence'"=="weightboot" {
					qui replace `coeff`tau'`var''=. in 1	/* calculate mean coefficient by only using bootstrap samples */
                	egen `mean`var''=mean(`coeff`tau'`var'') if `itervar'~=1
                	local mean`var'=`mean`var'' in 2
                	}
                if "`confidence'"=="no" {
                	gen `mean`var''=.
                	local mean`var'=`mean`var'' in 1
                	}
					matrix coeff`var' = [ ``var'`tau'' \ `mean`var'' \ `l`var'' \ `u`var'']
				if `varnum'==1 matrix all`tau'=[`tau' \ coeff`var']
				if `varnum'~=1 matrix all`tau'=[all`tau' \ coeff`var']
                local varnum = `varnum' + 1
        }

        if `taunum'==1 matrix all= [ all`tau']
        if `taunum'~=1 matrix all= [ all , all`tau']
        local taunum=`tau'+1

		count if missing(`coeff`tau'`endogvar'') & `itervar'~=1
		local bootreps = `reps'-1
		local convreps = `bootreps' - r(N)
		if "`bootreps'"!="`convreps'" {
		noi di "`tau' quantile: Confidence intervals calculated using `convreps' of `bootreps' bootstrap replications because remaining replications did not run to completion."
		}
	}
}


* Label row and column of matrices
local tablelabels ""
if "`exogenous'"=="" local rhs "`endogvar' `regressor' _cons ehat"	/* ehat instead `ehat' here */
else local rhs "`regressor' _cons"	/* endogvar and ehat disappear above but not here, so drop them */
	foreach var of local rhs {
		local tablelabels "`tablelabels' `var':_b `var':mean `var':lower `var':upper"
	}

matrix all = all[2...,1...]	/* drop the first row (tau's) */
matrix rownames all= `tablelabels'
matrix colnames all= `taurange'

if "`uncensored'"==""{
	numlist "`taurange'"
	matrix rownames robust= `r(numlist)'
	matrix colnames robust= `opt'
}	



* Incorporate top option (In line with the first part of the code)
qui if "`top'"!="" {
	matrix all = -all
	replace `depvar' = -`depvar'
	local censorpt = -`censorpt'
}





* SAVE RESULTS
tempfile `tag'final
qui save "``tag'final'"


* RETURNS IN ECLASS

	* LOCAL
	ereturn local command "cqiv"
	
	if "`uncensored'"=="" & "`exogenous'"==""{
	ereturn local regression "Censored quantile IV regression"
	}
	if "`uncensored'"!="" {
	ereturn local regression "Quantile IV regression (uncensored)"
	}
	if "`exogenous'"!=""{
	ereturn local regression "Censored quantile regression (exogenous)"
	}
	
	ereturn local depvar "`depvar'"
	if "`exogenous'"==""{
		ereturn local endogvar "`endogvar'"
		ereturn local instrument "`instrument'"
		ereturn local firststage "`firststage'"
		}
	ereturn local regressors "`regressor'" 

	if "`confidence'"=="no"{
		ereturn local confidence="No standard error"
		}
		else{
			if "`confidence'"=="boot"{
			ereturn local confidence="Bootstrap standard error"
			}
			else{
			ereturn local confidence="Weighted bootstrp standard error"
			}
		}

	* SCALAR	
	ereturn scalar obs=`obs'
	if "`uncensored'"=="" {
		ereturn scalar censorpt=`censorpt'
		ereturn scalar drop1=`drop1'
		ereturn scalar drop2=`drop2'
		}
	if "`confidence'"=="boot" | "`confidence'"=="weightboot" {
	ereturn scalar bootreps=`bootreps'
	}
	ereturn scalar level=`level'

	* MATRIX
	ereturn matrix results = all
	if "`uncensored'"=="" ereturn matrix robustcheck = robust
	matrix `quants'=`quants''
	ereturn matrix quantiles=`quants'


* DISPLAY
if "`uncensored'"=="" & "`exogenous'"==""{
	di _n in gr "Censored quantile IV regression" _col(54) _c
	}
if "`uncensored'"!="" {
	di _n in gr "Quantile IV regression (uncensored)" _col(54) _c
	}
if "`exogenous'"!=""{
	di _n in gr "Censored quantile regression (exogenous)" _col(54) _c
	}

di in gr "Number of obs =" in ye %10.0g e(obs)

if "`uncensored'"=="" {
	if "`top'"=="" di in gr "Censoring point = " in ye %6.0g e(censorpt)
	else di in gr "Censoring point = " in ye %6.0g e(censorpt) in gr " (Top)"
	}
if "`corner'"!="" {
di in gr "Estimates are (average) corner solution estimates"
	}
if "`exogenous'"==""{
	di in gr "Endogenous variable = " %10.0g e(endogvar)
	di in gr "Instrument(s) = " %10.0g e(instrument)
	di in gr "First stage estimation = " %10.0g e(firststage) " regression"
	}
if "`confidence'"=="no"{
	di in gr "No confidence intervals" _col(54)
	}
if "`confidence'"=="boot" {
	di in gr "Bootstrap(" in ye "`e(bootreps)'" in gr ") confidence intervals" _col(54) _c
	di in gr "Level (%)     = " in ye %9.0f e(level)
	}
if "`confidence'"=="weightboot" {
	di in gr "Weighted bootstrap(" in ye "`e(bootreps)'" in gr ") confidence intervals" _col(54) _c
	di in gr "Level (%)     = " in ye %9.0f e(level)
	}

matlist e(results), border(rows) rowtitle(`e(depvar)')		/* THIS IS FINAL TABLE OUTPUT */	

	
* Robust check only for CQIV
if "`uncensored'"!="" & "`norobust'"!=""{
	di in red "No robustness diagnostic test results to suppress for (uncensored) QIV."
	exit
}	
	
if "`norobust'"=="" & "`uncensored'"==""{
	di in gr ""
	if "`exogenous'"=="" di in gr "CQIV Robustness Diagnostic Test Results"
	else di in gr "CQR Robustness Diagnostic Test Results"
	matlist e(robustcheck), border(rows)
	}

	
* Reload data	
use "`temporigin'"
	
end
