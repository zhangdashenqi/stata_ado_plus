version 10.1
//version 1.0.0 20may2010
/*smoother takes generate() option

no extra grid points produced by smoother

LINear means that should have an MMP of the XB
PREDictors means should have an MMP for each predictor

LINear and varlist         ok
LINear and PREDictors      ok
PREDictors and varlist     nok

MEAN ->  specifies option that is supplied to predict to get mean function
that is estimated in regression

GENerate option: for each predictor variable x used in a marginal model plot
produces new variables x_model x_alt
if "linear" is specified, 
produces linform_model linform_alt
if any of these variables already exist the old versions are dropped
				
*/
program mmp 
	syntax, Mean(string) SMOother(string) [LINear] ///
[GENerate] [VARlist(varlist numeric)] [Predictors] [SMOOPTions(string asis)] ///
[INDGoptions(string asis)] [GOPTions(string asis)]
qui {
      if ("`goptions'" != "") {
		local goptions `", `goptions'  note("_ _ _ _ _ _  Model",color(red) size(small)) caption("_________ Alternative",color(blue) size(small))"'
      }
      else {
		local goptions `", note("_ _ _ _ _ _  Model",color(red) size(small)) caption("_________ Alternative",color(blue) size(small))"'
	} 


		//preserve estimates and data
	tempname presres
	capture estimates store `presres'
	tempvar order
	gen `order' = _n
	preserve
	keep if e(sample)
	capture assert "`varlist'" != "" | "`predictors'" != "" | ///
"`linear'" != ""
		//ensure mmp is being used after estimation command
	capture assert 	"`e(cmd)'" != ""
	if (_rc != 0) {
	        di as error "Must be used after Estimation command."
	        exit 198
	}
		//predictors trumps varlist
	if ("`predictors'" != "") {
		tempname preds
		matrix `preds' = e(b)
		matrix list `preds'
		capture di _b[_cons] 
		local varlist: colnames `preds'
		local varlist: subinstr local varlist "_cons" ""
	}

	        //will keep track of how many graphs mmp will produce.
	local graphnumber = 1

                 //temporary variable holding the predictions
     	tempvar yhat
	capture predict `yhat', `mean' 
	if (_rc != 0) {
		di as error "Mean prediction option is incorrectly specified."
		exit 198
	}
 
	if ("`linear'" != "") {
			//preserve state and create holders for plotting
			//generate XB linear form
		tempvar linpred
		gen `linpred' = 0
		tempname preds
		matrix `preds' = e(b)
		local lflist: colnames `preds'
		tokenize `lflist'
		local n = colsof(`preds')
		capture di _b[_cons]
		if (_rc == 0) {
			local n = `n' - 1
		}

		forvalues i = 1/`n' {
			replace `linpred' = `linpred' + _b[``i'']*``i''
		}

		capture di _b[_cons]
		if (_rc == 0) {
			replace `linpred' = `linpred' + _b[_cons]
		}
		tempvar modellinform alternativelinform
		tempname gfit

		`smoother' `e(depvar)' `linpred', nodraw ///
generate(`alternativelinform')  `smooptions'
		`smoother' `yhat' `linpred', nodraw generate(`modellinform') /// 
`smooptions'
		if("`generate'" != "") {
			capture drop linform_model
		 	capture drop linform_alt
		 	gen linform_model= `modellinform'
			label variable linform_model "MMP Linear Form Model Est."
		 	gen linform_alt = `alternativelinform'
			label variable linform_alt "MMP Linear Form Alternative Est."
		}
		scatter `e(depvar)' `linpred' || line `modellinform' ///
`linpred', sort lpattern("dash") lcolor("red") ///
|| line `alternativelinform' `linpred' , nodraw sort lpattern(solid) lcolor("blue") legend(off) ///
ytitle("`e(depvar)'") xtitle("Linear Form") name("`gfit'") `indgoptions'
	}
	foreach var of local varlist {
			//preserve state
		tempfile a
		qui save `a', replace 
		qui  bysort `var': keep if _n == 1
		if (_N <= 2) {
			use `a', clear
			continue
		}
			// predictor takes enough values to 
			// justify an mmp
			// restore state
		use `a', clear
		tempvar modellinform alternativelinform
		tempname g`graphnumber'
		`smoother' `e(depvar)' `var', ///
generate(`alternativelinform') `smooptions' nodraw
		`smoother' `yhat' `var', nodraw generate(`modellinform') ///
`smooptions'
		scatter `e(depvar)' `var' || line `modellinform' /// 
`var', sort lpattern("dash") lcolor("red") || line `alternativelinform' ///
`var' , nodraw sort lpattern(solid) lcolor("blue") legend(off) ///
ytitle("`e(depvar)'") xtitle("`var'") name("`g`graphnumber''") `indgoptions' 
		local graphnumber = `graphnumber' + 1
		
		if("`generate'" != "") {
			capture drop `var'_model
		 	capture drop `var'_alt
			gen `var'_model= `modellinform'
			label variable `var'_model "MMP `var' Model Est."
			gen `var'_alt = `alternativelinform'
			label variable `var'_alt "MMP `var' Alternative Est."
		}

	}

		//draw mmps
	local graph `"graph combine"'
	local graphnumber = `graphnumber'-1
	forvalues i = 1/`graphnumber' {
		local graph `"`graph' `g`i''"'
	}
	set graphics on
	`graph' `gfit' `goptions'



	forvalues i = 1/`graphnumber' {
		graph drop `g`i''
	}
	if ("`gfit'" != "") {
		graph drop `gfit'
	}
	if("`generate'" != "") {
		keep `order' *_model *_alt
		bysort `order': assert _n == 1
		tempfile a
		save `a', replace
		restore
		capture estimates restore `presres'
		sort `order'
		capture rename _m o_m
		merge `order' using `a'
		assert _m == 3 | _m == 1
		drop `order' _m 
		capture sum o_m
		if(_rc==0) {
		rename o_m _m
		}
	}
	else {
		restore
		drop `order'
		capture estimates restore `presres'
	}
}

end
