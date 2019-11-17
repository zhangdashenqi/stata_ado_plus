*! version 1.0.1  22nov2010

program define rcpoisson, eclass byable(onecall) prop(irr sw swml mi)
	version 11

	if _by() {
		local BY `"by `_byvars'`_byrc0':"'
	}
	`BY' _vce_parserun rcpoisson, mark(CLuster) : `0'
	if "`s(exit)'" != "" {
		version 10: ereturn local cmdline `"rcpoisson `0'"'
		exit
	}
	
	if replay() {
		if "`e(cmd)'"!="rcpoisson" {
			error 301
		}
		if _by() {
			error 190
		}
		Replay `0'
		error `e(rc)'
		exit
	}
	`BY' Estimate `0'
	version 10: ereturn local cmdline `"rcpoisson `0'"'
end

program Replay
	syntax [, Level(cilevel) IRr *]
	_get_diopts diopts, `options'
	_prefix_display `0' `eopt'
end


program Estimate, eclass byable(recall)

	syntax varlist(numeric fv ts) [fw pw iw/] [if] [in] [, /*
		*/ ULl(passthru)                    /*
		*/ ULe				    /*
		*/ Exposure(varname numeric ts)     /*
		*/ OFFset(varname numeric ts)       /*
		*/ CONSTraints(string)              /*
		*/ vce(string)                      /* 
		*/ IRr                              /*
		*/ Level(real 95)                   /*
		*/ noCNSReport                      /*
		*/ noCONstant                       /*
		*/ COEFlegend                       /*
		*/ eval(string)                     /* !! 80 columns not documented, for testing only
	        ----- MAXIMIZE OPTIONS - PROCESSED IN MATA EXCEPT FROM() -----
		*/ DIFFicult                        /*
		*/ TECHnique(string asis)           /*
		*/ ITERate(integer -1)		    /*
		*/ noLOg                            /*
		*/ TRace			    /*
		*/ GRADient 		            /*
		*/ showstep			    /*
		*/ HESSian			    /*
		*/ SHOWTOLerance		    /*
		*/ TOLerance(real 1e-6)		    /*
		*/ LTOLerance(real 1e-7)	    /*
		*/ NRTOLerance(real 1e-5)	    /*
		*/ NONRTOLerance 		    /*
		*/ from(string) * ]
		
	
	//default evaluator is e2
	if "`eval'"=="" local eval = "e2"
	
	_get_diopts diopts options, `options'
	
	marksample touse
	
	// +++++++++++++++++++++++++++++++++++++++++++++++++ check vce() option
	
	local nword : word count `vce'
	if `nword' > 2 {
		di as err "vce() must contain the name of only one variable"
		exit 198
	}
	
	gettoken w1 w2 : vce
	
	if "`w2'"=="" {
		if ("`w1'"=="" | "`w1'"=="oim") {
			local w1 = "oim"
		}
		else if "`w1'"=="robust" {
		}
		else {
			di as err "invalid vce() option"
			exit 198
		}
		local myvce vce(`w1')
	}
	else {
		if "`w1'" != "cluster" {
			di as error "invalid vce() option"
			exit 198
		}
		else {
			capture confirm var `w2'
			if !_rc {
				markout `touse' `w2', strok
				unab w2 : `w2'
			}
			else {
				di as err "invalid vce() option"
				exit 198
			}
		}
		local myvce vce(`w1' `w2')
	}
	if ("`weight'"=="pweight" & "`w1'"=="oim") local myvce vce(robust)
	
	// ++++++++++++++++++++++++++++++ check exposure() and offset() options
	
	if ("`offset'"!="" & "`exposure'"!="") {
		di as err "only one of offset() or exposure() can be specified"
		exit 198
	}
	
	if "`exposure'" != "" {
		capture assert `exposure' > 0 if `touse'
		if _rc {
			di as err "exposure() must be greater than zero"
			exit 459
		}
		local offpois exposure(`exposure')
	}
	
	if "`offset'" != "" {
		markout `touse' `offset'
		local offpois offset(`offset')
	}
		
	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++ check depvar
	gettoken y xvars : varlist
	_fv_check_depvar `y'
	tsunab y : `y'
	local yname : subinstr local y "." "_"
	
	
	// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ weights
	if "`weight'" != "" {
		local wgt [`weight'=`exp']
	}

	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++ other checks
	summ `y' if `touse', meanonly
	if r(N) == 0 { 
		error 2000
		exit
	}
	if r(N) == 1 { 
		error 2001
		exit
	}
	if r(min) < 0 {
		di in red "`y' must be greater than or equal to zero"
		exit 459
	}
	if r(min) == r(max) & r(min) == 0 {
		di as err "`y' is zero for all observations"
		exit 498
	}
	
	tempname mean nobs
	scalar `mean' = r(mean)
	scalar `nobs' = r(N) // #obs for checking #missings in calculations
	
	// check whether `y' is integer-valued
	
	if "`display'"=="" {
		capture assert `y' == int(`y') if `touse'
		if _rc {
			di as res "note: " as txt "you are responsible for " _c
			di "interpretation of noncount dependent variable"

// !! another way
//			di "{res}note:{txt} you are responsible for " 	///
//				"interpretation of noncount dependent variable"
		}
	}
	
	
	// ++++++++++++++++++++++++++++++++++++++++++++++++++ check ul() option
	
	if ("`ull'"=="" & "`ule'"=="") {
		di as err "You must specify the right-censoring limit"
		error 198
	}
	
	tempvar _UL
	if "`ule'" != "" { // +++++++++++++ use max value of dependent var as ul
		qui summ `y' if `touse'
		local ul `r(max)'
		qui gen double `_UL' = `ul'	
		
		qui count if `touse'
		local N = `r(N)'
		qui count if float(`y') >= float(`ul') & `touse'
		local Nrc = `r(N)'
		local Nunc = `N'-`Nrc'
	}
	else { // user specified varname or number
		tokenize `ull', parse("()")
		local ul `3'
		
		capture confirm numeric var `ul'
		if !_rc { // ++++++++++++++++++++++++++++++++ ul is a variable		
			capture assert `ul' >= 0 if `touse'
			if _rc {
				di as err "Error: there are negative " _c
				di "values in variable `ul'"
				exit
			}
			
			qui clonevar `_UL' = `ul'
			
			markout `touse' `_UL'
			
			qui count if `touse'
			local N = `r(N)'
			qui count if `y'>=`_UL' & `touse'
			local Nrc = `r(N)'
			local Nunc = `N'-`Nrc'
		}
		else { // +++++++++++++++++++++++++++++++++++ ul is a constant 
			if `ul' < 0 {
				di as err "Error: ul() must be greater " _c
				di "than or equal to zero"
				exit 198
			}
			qui gen double `_UL' = `ul'
			
			qui count if `touse'
			local N = `r(N)'
			qui count if `y'>=`ul' & `touse'
			local Nrc = `r(N)'
			local Nunc = `N'-`Nrc'
		}
	}
	
	capture assert `_UL' == round(`_UL') if `touse'
	if _rc {
		di as err "Error: Censoring limit contains non-integer values."
		exit 198
	}
	
	//make an indicator var =1 if censored
	tempvar censored yvar
	qui gen byte `censored' = `y'>=`_UL'
	qui gen `yvar' = min(`y',`_UL') if `touse'
	
	// ++++++++++++++++++++++++++++++++++++++++++++++++++ check constant 
	if "`constant'"!="" {
		local nvar : word count `varlist'
		if `nvar' == 1 {
			di as err "independent variables required " _c
			di "with noconstant option"
			exit 100
		}
	}
	else {
		tempvar consvar
		gen byte `consvar' = 1
		local cons "_cons"
	}
	
	// ++++++++++++++++++++++++++++++++++++++++++++ process constraints
	tempname bvec vmat
	
	fvexpand `xvars' if `touse'
	local xvars `"`r(varlist)'"'
	local numcols : word count `xvars' `cons'
	
	// ++++++++++++ create and post dummy matrices for mat makeCns
	mat `bvec' = J(1,`numcols',0)
	mat colnames `bvec'  = `xvars' `cons'
	mat `vmat' = J(`numcols',`numcols',0)
	mat colnames `vmat' = `xvars' `cons'
	mat rownames `vmat' = `xvars' `cons'
	ereturn post `bvec' `vmat'
	mat `vmat' = get(VCE)
	
	// ++++++++++++ create/access constraint matrices
	local constraints : subinstr local constraints "," " ", all
	makecns `constraints', nocnsnotes
	local ccc `e(Cns)'
	local k_autoCns = `r(k_autoCns)'
	
	if "`e(Cns)'"=="matrix" {
		tempname C
		matrix `C' = e(Cns)
		local k_autoCns = r(k_autoCns)
	}
	
	local cnspoiss constraints(`constraints')
	
	// ++++++++++++++++++++++++++++++++++++++++++++ remove collinearity
	_rmcoll `xvars' `wgt' if `touse', expand `constant' `coll'
	local xvars `r(varlist)'
	local names `r(varlist)'
	if "`constant'"=="" {
		local names `xvars' _cons
		local xvars `xvars' `consvar'
	}
	//di as err "xvars are: `xvars'"
	//di as err "names are: `names'"
	
	local skipinit = 0
	// +++++++++++++++++++ get ll_0 from constant only model with censoring
	if ("`constant'"=="") {
		local skipinit = 1
		if ("`exposure'" != "") {
			qui mata: ///
		_rcpoisson_main("`yvar'","`censored'","`consvar'","`exposure'")
		}
		else if ("`offset'" != "") {
			qui mata: ///
		_rcpoisson_main("`yvar'","`censored'","`consvar'","`offset'")
		}
		else {
			qui mata: ///
		_rcpoisson_main("`yvar'","`censored'","`consvar'")
		}
		local ll0 = ll
		local skipinit = 0
	}
	
	// +++++++++++++++++++++++++++++++++++++++ get initial values	
	if `"`from'"' != "" {
		//di as err "user-specified initb:"
		tempname initb
		_mkvec `initb', from(`from') error("from()")
		//mat list `initb'
		
		local names : colnames `initb'
		//di as err "names from from() are: `names'"
	}
	else {
		qui poisson `y' `xvars' `wgt' if `touse', /*
			*/ `offpois' `cnspoiss' `myvce' noconstant
		tempname initb
		mat `initb' = e(b)
		//di as err "initb from poisson:"
		//mat list `initb'
	}
	
	// ++++++++++++++++++++++++++++++++++++++++++++ run full model
	if ("`exposure'" != "") {
		mata:				///
	 	 _rcpoisson_main("`yvar'","`censored'","`xvars'","`exposure'")
	}
	else if ("`offset'" != "") {
		mata: 				///
	     _rcpoisson_main("`yvar'","`censored'","`xvars'","`offset'")
	}
	else {
		mata:				///
		 _rcpoisson_main("`yvar'","`censored'","`xvars'")
	}
	
	
	// ++++++++++++++++++++++++++++++++++++++++++++++++++++ LR or Wald test
	local one = "`constant'"==""
	if (`one'==0 | "`w1'"=="robust" | "`w1'"=="cluster") { // Wald test
		qui test `names'
		ereturn scalar k_eq_model = 1
		local chisq = `r(chi2)'
		local df = e(rank)
		ereturn local chi2type = "Wald"
	}
	else { // LR test
		local chisq = 2*(ll-`ll0')
		local r2 = 1-ll/`ll0'
		local df = e(rank) - `one'
		ereturn local chi2type = "LR"
	}
	
	local pval = chi2tail(`df',`chisq')
	
	ereturn local depvar = "`y'"
	ereturn scalar k_autoCns = `k_autoCns'
	ereturn scalar N_unc = `Nunc'
	ereturn scalar N_rc  = `Nrc'
	capture unab ul : `ul'
	ereturn local ulopt `ul'
	ereturn scalar df_m = `df'
	ereturn scalar ll = ll
	if "`constant'"=="" {
		ereturn scalar ll_0 = `ll0'
	}
	ereturn scalar chi2 = `chisq'
	ereturn scalar p = `pval'
	capture ereturn scalar r2_p = `r2'
	ereturn local predict "rcpoisson_p"
	ereturn local estat_cmd "rcpoisson_estat"
	ereturn local gof "rcpoisson_gof"
	ereturn local cmdline `0'
	ereturn local cmd "rcpoisson"
	ereturn local title "Right-censored Poisson regression"
	
	if "`irr'"!="" {
		local eopt "eform(IRR)"
	}
	Replay , `diopts' `irr' level(`level') `cnsreport' `coeflegend'
	
	my_footnote_ `Nunc' `Nrc'
	
end

program define my_footnote_
	args uncens rcens
	
	local perc = round(`rcens' / (`rcens'+`uncens') * 100,.1)
	di as txt  _col(3) "Observation summary:" _c
	di as res _col(23) %9.0f `rcens'  _c
	di as txt " right-censored observations " _c
	di as txt "(" as res `perc' as txt " percent)" 
	di as res _col(23) %9.0f `uncens' as txt "     uncensored observations"
end

exit
