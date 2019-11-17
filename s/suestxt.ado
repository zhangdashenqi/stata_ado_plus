*! version 3.5.2  29oct2015 - FB - compatibility with xtreg
*! version 3.5.1  21feb2015
*! rename to suestxt by Arlion (arlionn@163.com)

program suestxt, sortpreserve
	version 9
	if _caller() < 9 {
		suest_8 `0'
		exit
	}

	if replay() {
		if "`e(cmd)'" != "suest" {
			di as err "estimation results for suest not found"
			exit 301
		}
		Display `0'
	}
	else	Estimate `0'
end


program Estimate, eclass
	version 9

	syntax [anything] [,		///
		CLuster(passthru)	///
		VCE(passthru)		///
		minus(passthru)		///
		regressml 		///
		SVY			///
		Level(passthru)		/// Display options
		Dir			///
		EForm(passthru)		///
		Robust			///
		*			///
	]
	_get_diopts diopts, `options'
	local diopts `diopts' `level' `dir' `eform'

	_vce_parse, argopt(CLuster) opt(Robust) old :, `vce' `cluster' ///
		`robust'
	local cluster `r(cluster)'
	est_expand `"`anything'"', min(1) default(.)
	// code doesn't allow duplicates
	local names `"`r(names)'"'
	local names : list uniq names
	local nnames : word count `names'

	// I may later have to add a cluster() spec -- eg clogit
	local cluster_var `cluster'

	tempvar touse subuse esamplei esample
	tempname hcurrent rank IVi V Vi b bi

	_est hold `hcurrent' , restore nullok estsystem

	if `"`svy'"' == "" {
		local usesvy 0
	}
	else	local usesvy 1
	capture svyset
	if !c(rc) {
		local posts "`r(poststrata)'"
		local postw "`r(postweight)'"
	}
	scalar `rank' = 0
	local i 0
	// extract information for selected models in -names-
	foreach name of local names {
		local ++i

nobreak {

		if "`name'" != "." {
			est_unhold `name' `esample'
		}
		else {
			_est unhold `hcurrent'
		}

capture noisily break {

		local cmdi	`e(cmd)'
		local cmd2i	`e(cmd2)'
		local is_svy	= "`e(prefix)'" == "svy"
		local usesvy	= `usesvy' | `is_svy'
		local clustvari	`e(clustvar)'
		local vcei	`e(vce)'
		local vcetypei	`e(vcetype)'
		local wtypei	`e(wtype)'
		local wexpi	`"`e(wexp)'"'
		local postsi	`"`e(poststrata)'"'
		local postwi	`"`e(postweight)'"'
		if "`postsi'" == "" {
			local nonpost `name'
		}

		if `usesvy' & "`cluster_var'" != "" {
			di as err ///
			"option cluster() is not allowed with svy results"
			exit 198
		}

		if `usesvy' & "`postsi'`postwi'" != "`posts'`postw'" {
			if "`posts'" == "" {
				di as err ///
"poststratification is present in '`name'', but not in svyset"
			}
			else if "`postsi'" == "" {
				di as err ///
"poststratification has been svyset, but is not present in '`name''"
			}
			else {
				di as err ///
"poststratification information differs between svyset and '`name''"
			}
			exit 322
		}
		if `usesvy' & "`posts'`postsi'" != "" & "`nonpost'" != "" {
			di as err ///
"poststratification has been specified, but is not present in '`nonpost''"
			exit 322
		}

		GetMat `name' `bi' `Vi'
		capture drop `esamplei'
		gen byte `esamplei' = e(sample)

		NotSupported "`cmdi'" "`cmd2i'"

		capture assert `esamplei' == 0
		if !_rc {
			di as err ///
"estimation sample of the model saved under `name' could not be restored"
			exit 198
		}
		if bsubstr("`cmdi'",1,3) == "svy" {
			di as err "`cmdi' is not supported by suest"
			exit 322
		}
		if "`clustvari'" != "" {
			di as err ///
		"`name' was estimated with cluster(`clustvari'). " _n ///
		"re-estimate without the cluster() option, and " _n ///
		"specify the cluster() option with suest."
			exit 322
		}
		if !`is_svy' & "`wtypei'" == "pweight" {
			di as err ///
			"model `name' was estimated with pweights, " ///
			"you should re-estimate using iweights"
			exit 322
		}
		if !`usesvy' & ///
		 (!inlist(`"`vcei'"', "", "oim", "ols", "standard","conventional") ///
		 | !inlist(`"`vcetypei'"', "", "OIM") ///
		 ) {
		 	local vce = cond("`vcei'"!="", "`vcei'", "`vcetypei'")
			di as err ///
		"`name' was estimated with a nonstandard vce (`vce')"
			exit 322
		}

		if inlist("`cmdi'","regress","anova","xtreg") & !`is_svy' {
			// fix some irregularities in -regress- (and -anova-)
			tempvar sc`i'_1 sc`i'_2
			if "`cmdi'"!="xtreg" quietly Fix_regress `bi' `Vi' "`regressml'" /*
				*/ `sc`i'_1' `sc`i'_2'
			else quietly Fix_xtregress  `bi' `Vi' "`regressml'" /*
				*/ `sc`i'_1' `sc`i'_2'
			local scoresi  `sc`i'_1'  `sc`i'_2'
		}
		else if "`cmdi'" == "clogit" {
			// NOTE: what about svy:clogit
			tempvar scoresi
			quietly Fix_clogit `scoresi' `cluster_var'
			local cluster_var `r(cluster_var)'
		}
		else {
			if `is_svy' {
				capture drop `subuse'
				_svy_setup `esamplei' `subuse', ///
					svy subpop(`e(subpop)')
				local esamp `subuse'
			}
			else	local esamp e(sample)
			tempvar sci
			capture predict double `sci'* if `esamp', score
			if c(rc) {
				di as err ///
"unable to generate scores for model `name'" _n ///
"{help suest##|_new:suest} requires that {help predict##|_new:predict} " ///
"allow the {opt score} option"
				exit 322
			}
			unab scoresi : `sci'*
			if `is_svy' {
				foreach v of local scoresi {
					qui replace `v' = 0 if missing(`v')
				}
			}
		}

} // capture noisily break

		local rc = _rc

		if "`name'" != "." {
			est_hold `name' `esample'
		}
		else {
			_est hold `hcurrent' , restore nullok estsystem
		}

} // nobreak

		if (`rc') exit `rc'

		// modifies equation names into name_eq or name#
		if `nnames' > 1 {
			FixEquationNames   `name' `bi' `Vi'
		}
		else {
			NoFixEquationNames `name' `bi' `Vi'
		}

		local neq`i' `r(neq)'
		local eqnames`i' `"`r(eqnames)'"'
		local newfullnames `"`newfullnames' `:colfullnames `bi''"'

		// check score vars
		local nscoresi : word count `scoresi'
		if `neq`i'' != `nscoresi' {
			di as err ///
			"number of score variables does not match " ///
			"number of equations in model `name'"
			exit 198
		}
		foreach v of local scoresi {
			// scores should not be missing in e(sample)
			capture assert !missing(`v') if `esamplei'
			if _rc {
				if `: word count `scoresi'' > 1 {
					local s1 s
				}
				else	local s2 s
				di as err ///
				"score variable`s1' for model `name' " ///
				"contain`s2' missing values"
				exit 322
			}
			// set out of sample values scores to zero
			qui replace `v' = 0 if missing(`v')
		}

		// store-append  b/V/weight

		// necessary if Vi was constrained estimator
		matrix `IVi' = syminv(`Vi')
		scalar `rank' = `rank' + (colsof(`Vi') - diag0cnt(`IVi'))

		if `i' == 1 {
			gen byte `touse' = `esamplei'
			local wtype `wtypei'
			local wexp  `"`wexpi'"'
			matrix `b' = `bi'
			matrix `V' = `Vi'
		}
		else {
			// union of samples of models
			qui replace `touse' = `touse' | `esamplei'
			// the weights in e() should be the same as in model 1
			CheckWeight "`wtype'" "`wexp'" "`wtypei'" "`wexpi'"
			// append the bi and Vi
			matrix `b' = `b' , `bi'
			local nv  = colsof(`V')
			local nvi = colsof(`Vi')
			matrix `V' = (`V', J(`nv',`nvi',0) \ ///
				J(`nvi',`nv',0), `Vi')
		}

		// score vars all models
		local scores `scores' `scoresi'

	} // loop over models

	if "`cluster_var'" != "" {
		quietly count if `touse'
		local N0 = r(N)
		markout `touse' `cluster_var', strok
		quietly count if `touse'
		if r(N) < `N0' {
			di as err	///
"{p 0 0 2}"				///
"cluster variable {bf:`cluster_var'}"	///
" is not allowed to be missing"	///
" within the estimation sample"	///
"{p_end}"
			exit 459
		}
	}

	version 11: matrix colnames `b' = `newfullnames'
	version 11: matrix colnames `V' = `newfullnames'
	version 11: matrix rownames `V' = `newfullnames'

	if `usesvy' {
		capture drop `subuse'
		_svy_setup `touse' `subuse', svy
		if !inlist("`wtype'","","pweight","iweight") {
			di as err ///
		"`wtype' is not a valid weight type for survey data analysis"
			exit 322
		}
		if "`wexp'" != "`r(wexp)'" {
			di as err "weighting expression differs between models"
			exit 322
		}
	}
	else if "`wtype'" != "" {
		local wt `"[`wtype'`wexp']"'
	}

	if "`cluster_var'" != "" {
		local clopt `"cluster(`cluster_var')"'
	}

	if `usesvy' {
		// _robust2 is the work horse for svy suest
		capture noisily quietly _robust2 `scores' if `touse', ///
			svy v(`V') `minus'
		local rc = _rc
		if `rc' {
			if `rc' == 1 {
				error 1
			}
			di as err ///
"_robust2 failed to compute cross model variance estimate" _n ///
"likely an internal error in suest"
			exit `rc'
		}
		local Nobs = r(N)
	}
	else {
		// _robust is the work horse for non-svy suest
		capture noi _robust2 `scores'  if `touse' `wt', ///
			var(`V') `clopt' `minus'
		local rc = _rc
		if `rc' {
			if `rc' == 1 {
				error 1
			}
			di as err ///
"_robust failed to compute cross model variance estimate" _n ///
"likely an internal error in suest"
			exit `rc'
		}
		if "`clopt'" != "" {
			local Ncl = r(N_clust)
		}
		qui count if `touse'
		local Nobs = r(N)
	}

	// post results
	ereturn post `b' `V' [`wtype'`wexp'], esample(`touse') obs(`Nobs') ///
		buildfvinfo noHmat
	if `usesvy' {
		_r2e
		ereturn scalar N_psu = e(N_clust)
		ereturn local N_clust
		ereturn scalar N_pop = e(sum_w)
		ereturn local sum_w
		ereturn local sum_wsub
		ereturn local prefix svy
		ereturn local vce linearized
		ereturn local vcetype Linearized
	}
	else {
		if "`cluster_var'" != "" {
			ereturn local clustvar  `cluster_var'
			ereturn scalar N_clust = `Ncl'
			ereturn local vce cluster
		}
		else	ereturn local vce robust
		ereturn local vcetype   Robust
		ereturn local wtype  `wtype'
		ereturn local wexp   `"`wexp'"'
	}

	ereturn scalar rank  = `rank'
	ereturn local names  `names'
	forvalues ieq = `nnames'(-1)1 {
		ereturn local eqnames`ieq' `eqnames`ieq''
	}
	ereturn local cmd suest

	_est unhold `hcurrent', not

	Display , `diopts'
end


// ============================================================================
// display routines
// ============================================================================

program Display
	syntax [, Level(passthru) Dir EForm(passthru) *]

	_get_diopts diopts, `options'
	local nnames : word count `e(names)'
	est_clickable "`e(names)'"  "replay"  ", "
	local clicktxt "`r(clicktxt)'"

	if "`e(prefix)'" == "svy" {
		if `nnames' > 1 {
			local title "Simultaneous survey results for `clicktxt'"
		}
		else {
			local title "Survey results for `clicktxt'"
		}
	}
	else if "`e(clustvar)'" != "" & `nnames' == 1 {
		local title "Cluster adjusted results for `clicktxt'"
	}
	else {
		if `nnames' > 1 {
			local title "Simultaneous results for `clicktxt'"
		}
		else {
			local title "Robust results for `clicktxt'"
		}
	}
	_coef_table_header, title(`title') nocluster

	if "`dir'" != "" {
		estimates dir `e(names)' , width(78)
	}

	di
	ereturn display, `level' `eform' `diopts'

end


// ============================================================================
// fix routines for specific estimators
// ============================================================================

/* Fix_regress  b V  est_ml sc1 sc2

   - adds equation name "mean" to existing coefficients
   - adds an equation named "lnvar" for the log(variance)
   - returns in the two vars sc1 and sc2 the score variables

   if the argument ml_est is defined, in addition estimation results are
   adjusted from REML to ML. This makes results identical to ml commands
   such as intreg and lnormal.
*/
program Fix_regress
	args  b V ml_est sc1 sc2

	confirm matrix `b'
	confirm matrix `V'

	tempname b0 var

	if "`ml_est'" != "" {
		// ML estimate of variance
		scalar `var' = e(rss)/e(N)
		matrix `V' = (`var' / e(rmse)^2) * `V'
	}
	else {
		// REML estimate of variance
		scalar `var' = e(rmse)^2
	}
	matrix `b0' = log(`var')
	matrix coln `b0' = lnvar:_cons

	local n = colsof(`b')
	matrix coleq `b' = mean
	matrix `b'  = `b', `b0'

	local names : colfullnames `b'
	matrix `V' = (`V', J(`n',1,0) \ J(1,`n',0) , 2/e(N))
	version 11: matrix colnames `V' = `names'
	version 11: matrix rownames `V' = `names'

	tempvar res
	predict double `res' if e(sample), res
	gen double `sc1' = `res' / `var'		if e(sample)
	gen double `sc2' = 0.5*(`res'*`sc1' - 1)	if e(sample)
end

program Fix_xtregress
	args  b V ml_est sc1 sc2

	confirm matrix `b'
	confirm matrix `V'

	tempname b0 var

	if "`ml_est'" != "" {
		// ML estimate of variance
		scalar `var' = e(rss)/e(N)
		matrix `V' = (`var' / e(rmse)^2) * `V'
	}
	else {
		// REML estimate of variance
		scalar `var' = e(rmse)^2
	}
	matrix `b0' = log(`var')
	matrix coln `b0' = lnvar:_cons

	local n = colsof(`b')
	matrix coleq `b' = mean
	matrix `b'  = `b', `b0'

	local names : colfullnames `b'
	matrix `V' = (`V', J(`n',1,0) \ J(1,`n',0) , 2/e(N))
	version 11: matrix colnames `V' = `names'
	version 11: matrix rownames `V' = `names'

	tempvar res
	predict double `res' if e(sample), e
	gen double `sc1' = `res' / `var'		if e(sample)
	gen double `sc2' = 0.5*(`res'*`sc1' - 1)	if e(sample)
end

program Fix_clogit, rclass sort
	args score_var cluster_var

	// get score variable
	quietly predict double `score_var' if e(sample), score

	if "`cluster_var'" == "" {
		return local cluster_var `e(group)'
	}
	else {
		// DON'T RESTRICT TO SAMPLE -- it may change later

		// check that -e(group)- does not cross -clvar- boundaries
		assert `: word count `e(group)'' == 1
		assert `: word count `cluster_var'' == 1
		sort `e(group)', stable
		capture by `e(group)' : assert `cluster_var' == `cluster_var'[1]
		if _rc {
			di as err "clogit was estimated with invalid group()"
			exit 498
		}
		return local cluster_var `cluster_var'
	}
end


// ============================================================================
// utility subroutines
// ============================================================================

/* CheckWeight wtype wexp wtypei wexpi

   verifies that the weighting of model i (wtypei wexpi) is identical to the
   stored weighting scheme (wtype wexp).

   The check is not foolproof; we store weighting expression, not the
   actual weights.
*/
program CheckWeight
	args wtype wexp wtypei wexpi

	if "`wtype'" != "`wtypei'" {
		if !inlist("`wtype'",  "pweight", "iweight") ///
		 | !inlist("`wtypei'", "pweight", "iweight") {
			di as err "inconsistent weighting types"
			exit 322
		}
	}
	if "`wtype'" == "" {
		exit
	}

	tempvar exp expi
	qui gen double `exp'   `wexp'
	qui gen double `expi'  `wexpi'

	// NOT restricted to e(sample) --
	//   sample may change when adding more models
	capture assert reldif(`exp',`expi') < 1e-6
	if _rc {
		di as err "weighting expression differs between models"
		exit 322
	}
end


/* FixEquationNames name b V

   rename the equations to "name" in case of 1/0 equation, otherwise it
   prefixes "name" to equations if this yields unique equation names,
   and numbers the equations "name"_nnn otherwise.
*/
program FixEquationNames, rclass
	args name b V

	if "`name'" == "." {
		local name _LAST
	}

	local qeq : coleq `b', quote
	local qeq : list clean qeq
	local eqnames : coleq `b'
	if `:length local qeq' != `:length local eqnames' {
		foreach el of local qeq {
			local new : subinstr local el " " "_", all
			local new : subinstr local new "." ",", all
			local neweq `"`neweq' `new'"'
		}
		matrix coleq `b' = `neweq'
		matrix coleq `V' = `neweq'
		matrix roweq `V' = `neweq'
		local eqnames `"`neweq'"'
	}
	local eq : list uniq eqnames
	local neq : word count `eq'
	if "`eq'" == "_" {
		local eqnames `name'
	}
	else {
		// modify equation names
		foreach e of local eq {
			local newname = usubstr("`name'_`e'",1,32)
			local meq `meq' `newname'
		}

		local eqmod : list uniq meq
		local neqmod : word count `eqmod'
		if `neq' == `neqmod' {
			// modified equation names are unique
			forvalues i = 1/`neq' {
				local oldname : word `i' of `eq'
				local newname : word `i' of `eqmod'
				local eqnames : subinstr local eqnames ///
					  "`oldname'" "`newname'", word all
			}
		}
		else {
			// truncated modified equations not unique
			// use name_1, name_2, ...
			tokenize `eq'
			forvalues i = 1/`neq' {
				local eqnames : subinstr local eqnames ///
					  "``i''" "`name'_`i'", word all
			}
		}
	}

	matrix coleq `b' = `eqnames'
	matrix roweq `V' = `eqnames'
	matrix coleq `V' = `eqnames'
	return local neq `neq'
	return local eqnames	`eq'
	return local neweqnames `eqmod'
end


program NoFixEquationNames, rclass
	args name b V

	local qeq : coleq `b', quote
	local qeq : list clean qeq
	local eqnames : coleq `b'
	if `:length local qeq' != `:length local eqnames' {
		foreach el of local qeq {
			local new : subinstr local el " " "_", all
			local neweq `"`neweq' `new'"'
		}
		matrix coleq `b' = `neweq'
		matrix coleq `V' = `neweq'
		matrix roweq `V' = `neweq'
		local eqnames `"`neweq'"'
	}
	local eq : list uniq eqnames

	return local neq	 `: word count `eq''
	return local eqnames	 `eq'
	return local neweqnames  `eq'
end


program GetMat
	args name b V

	if "`e(prefix)'" == "svy" {
		local ev e(V_modelbased)
	}
	else	local ev e(V)
	capture {
		confirm matrix e(b)
		confirm matrix `ev'
		matrix `b' = e(b)
		matrix `V' = `ev'
	}
	if _rc {
		dis as err ///
		"impossible to retrieve e(b) and e(V) in `name'"
		exit 198
	}
	if "`e(cmd)'" == "cnsreg" {
		if !missing(e(rmse)) & e(rmse) != 0 {
			matrix `V' = `V'/(e(rmse)*e(rmse))
		}
	}
end


// NotSupported cmd cmd2
program NotSupported
	local cmdlist cox xtgee ivreg ivregress areg sem xtmixed mixed
	local cmdlist `cmdlist' xtmepoisson mepoisson xtmelogit melogit meglm
	local cmdlist `cmdlist' gsem gmm ivpoisson reg3 sureg
	local cmd : list 0 & cmdlist
	if `"`cmd'"' != "" {
		di as err "`:word 1 of `cmd'' is not supported by suest"
		exit 322
	}
	if "`e(cmd)'" == "regress" & "`e(model)'" == "iv" {
		di as err ///
		"regression models with instruments are not supported by suest"
		exit 322
	}
	if "`e(cmd)'" == "anova" {
		if 0`e(version)' < 2 {
			di as err ///
			  "anova run with version < 11 not supported by suest"
			exit 322
		}
	}
end

exit
