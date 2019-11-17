program dr, eclass 
*! Version: $Version$
*! Author:  Mark Lunt
*! Date:    April 24, 2008 @ 10:50:33

version 9 

	syntax varlist [if] [in] [,ovars(varlist) pvars(varlist)  ///
			Family(string) Link(string) vce(string)               ///
			genvars suffix(string) debug]

	local orig `0'
	tokenize `varlist'
	local outcome `1'
	macro shift
	local treatvar `1'
	macro shift
	local preds `*'
	
	// Give values to options that were not set
	if "`ovars'" == "" {
		local ovars `preds'
	}
	if "`pvars'" == "" {
		local pvars `preds'
	}
	if "`family'" == "" {
		local family gaussian
	}
	if "`link'" == "" {
		local link   identity
	}
	if "`vce'" == "" {
		local vce robust
	}


	di _n
	di as text "Doubly Robust Estimate of the effect of `treatvar' on `outcome'"
	_vce_parserun dr : `orig'
	if "`s(exit)'" != "" {
		exit
	}

	marksample touse
	
	quietly {
		// Fit propensity model
		
		if "`genvars'" != "" {
			local  ptreat  ptreat`suffix'
			local  iptwt  iptwt`suffix'
		}
		else {
			tempvar ptreat iptwt
		}
		if "`debug'" != "" {
			local  ipt_est  ipt_est`suffix'
		}
		else {
			tempvar ipt_est
		}

		tempvar troot treat
		tempname values
		tab `treatvar' if `touse', gen(`troot') matrow(`values')
		if rowsof(`values') != 2 {
			noi di as error "The treatment variable must only take 2 values in the sample."
			exit
		}
		
		local exp = el(`values',2,1)
		gen `treat' = `treatvar' == `exp'
		label var `treat' `treatvar'
		logit `treat' `pvars' if `touse'
		predict `ptreat' if `touse'
		gen     `iptwt'   = `treat'/`ptreat' + (1-`treat')/(1-`ptreat') if `touse'
		gen     `ipt_est' = (2*`treat'-1)*`outcome'*`iptwt' if `touse'
		
		// Fit outcome model
			
		if "`genvars'" != "" {
			local  mu1  mu1`suffix'
			local  mu0  mu0`suffix'
			local  mudiff  mudiff`suffix'
		}
		else {
			tempvar mu1 mu0 mudiff
		}
		
		glm `outcome' `ovars' if `treat' == 1 & `touse',        ///
				link(`link') family(`family')
		predict `mu1'
		glm `outcome' `ovars' if `treat' == 0 & `touse',        ///
				link(`link') family(`family')
		predict `mu0'
		gen `mudiff' = `mu1' - `mu0'
		
		// Combine into robust estimate
		
		if "`debug'" != "" {
			local  mdiff  mdiff`suffix'
			local  dr0  dr0`suffix'
			local  dr1  dr1`suffix'
			local  drdiff1  drdiff1`suffix'
			local  drdiff2  dr_diff`suffix'
		}
		else {
			tempvar mdiff dr0 dr1 drdiff1 drdiff2
		}
		
		gen `mdiff' = (-1*(`treat'-`ptreat')*`mu1'/`ptreat') -     ///
				((`treat' - `ptreat')*`mu0'/(1-`ptreat'))  ///
				if `touse'
		gen `drdiff1'   = `ipt_est' + `mdiff' if `touse'
		gen `dr1' = `treat' * `outcome' / `ptreat' -            ///
				(`treat'-`ptreat')*`mu1'/`ptreat'
		gen `dr0' = (1 - `treat') * `outcome' / (1 - `ptreat') +       ///
				(`treat'-`ptreat')*`mu0'/(1 - `ptreat')
		gen `drdiff2' = `dr1' - `dr0'
		summ `dr1' if `touse', meanonly
		local dr1m = r(mean)
		summ `dr0' if `touse', meanonly
		local dr0m = r(mean)
		summ `drdiff2' if `touse', meanonly
		local dr_est = r(mean)
		local n      = r(N)
		
		// Calculate Standard Error
		

			if "`debug'" != "" {
				local  I  I`suffix'
				local  I2  I2`suffix'
			}
			else {
				tempvar I I2
			}
			
			gen `I' = `dr1' - `dr0' - `dr_est' if `touse'
			gen `I2' = `I'^2
			summ `I2'
			local dr_var = r(mean) / `n'
 	}
	
	// Display results
	tempname b V
	matrix `b' = J(1,1,`dr_est')
	matrix `V' = J(1,1,`dr_var')
	matrix rownames `b' = "`treatvar'"
	matrix colnames `b' = "`treatvar'"
	matrix rownames `V' = "`treatvar'"
	matrix colnames `V' = "`treatvar'"
	
	drop `ipt_est' `mu_diff' `mdiff' `drdiff1'
	
	if "`vce'" == "robust" {
		di as text "Using sandwich estimator of SE"
	}
	else if "`vce'" == "bootstrap" {
		di as text "Using bootstrap estimator of SE"
	}
	di
	ereturn clear
	ereturn post `b' `V', esample(`touse')
	ereturn display
	ereturn scalar dr_est = `dr_est'
	ereturn scalar dr_var = `dr_var'
	ereturn scalar dr0 = `dr0m'
	ereturn scalar dr1 = `dr1m'


end
