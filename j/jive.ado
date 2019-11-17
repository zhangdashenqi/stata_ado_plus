*! version 1.0.2  17apr2006
* Changelog at bottom

program define jive, byable(onecall)

	if _by() {
		local BY `"by `_byvars'`_byrc0':"'
	}
	
	if replay() {
		if `"`e(cmd)'"' != "jive" {
			error 301
		}
		else if _by {
				error 190
		}
		else {
			Display `0'
		}
	}
	
	`BY' Estimate `0'

end

program define Estimate, eclass byable(recall)
	
	// Portions of syntax parsing code are from ivreg.ado
	local n 0

	gettoken lhs 0 : 0, parse(" ,[") match(paren)
	IsStop `lhs'
	if `s(stop)' { 
		error 198 
	}  
	while `s(stop)'==0 {
		if "`paren'"=="(" {
			local n = `n' + 1
			if `n'>1 {
				capture noi error 198
di as error `"syntax is "(all instrumented variables = instrument variables)""'
				exit 198
			}
			gettoken p lhs : lhs, parse(" =")
			while "`p'"!="=" {
				if "`p'"=="" {
					capture noi error 198
di as error `"syntax is "(all instrumented variables = instrument variables)""'
di as error `"the equal sign "=" is required"'
					exit 198
				}
				local end`n' `end`n'' `p'
				gettoken p lhs : lhs, parse(" =")
			}
			tsunab end`n' : `end`n''
			tsunab exog`n' : `lhs'
		}
		else {
			local exog `exog' `lhs'
		}
		gettoken lhs 0 : 0, parse(" ,[") match(paren)
		IsStop `lhs'
	}
	local 0 `"`lhs' `0'"'

	tsunab exog : `exog'
	tokenize `exog'
	local lhs "`1'"
	local 1 " "
	local exog `*'
	
	// Eliminate vars from `exog1' that are in `exog'
	Subtract inst : "`exog1'" "`exog'"
	
	// `lhs' contains depvar, 
	// `exog' contains RHS exogenous variables, 
	// `end1' contains RHS endogenous variables, and
	// `inst' contains the additional instruments

	local lhsname `lhs'
	_find_tsops `lhs'
	if `r(tsops)' {
		qui tsset
		tsrevar `lhs'
		local lhs `r(varlist)'
	}

	local stop 0
	while (`stop' == 0) {
		local oldlist `end1' `exog' `inst'
		qui _rmcoll `oldlist'
		local goodlist `r(varlist)'
		local dropped : list oldlist - goodlist
		if `"`=trim("`dropped'")'"' == "" {
			local stop 1
		}
		foreach x of local dropped {
			di "note: `x' dropped due to collinearity"
			local ininst : list posof "`x'" in inst
			if `ininst' > 0 {
				local inst : subinstr local inst "`x'" ""
			}
			local inexog : list posof "`x'" in exog
			if `inexog' > 0 {
				local exog : subinstr local exog "`x'" ""
			}
			local inend1 : list posof "`x'" in end1
			if `inend1' > 0 {
				local end1 : subinstr local end1 "`x'" ""
			}
		}	
	}
	
	local end1cnt : word count `end1'
	local exogcnt : word count `exog'
	local instcnt : word count `inst'
	
	tsrevar `end1'
	local end1tsrv `r(varlist)'		
	tsrevar `exog'
	local exogtsrv `r(varlist)'		
	tsrevar `inst'
	local insttsrv `r(varlist)'		
	
	if `end1cnt' == 0 {
		di as error "no endogenous regressors"
		exit 198
	}
	CheckOrder `end1cnt' `instcnt'
	
	// Now parse remaining syntax
	syntax [if] [in] , [ Level(cilevel) UJIVE1 UJIVE2 JIVE1 JIVE2 Robust]
	marksample touse
	markout `touse' `lhs' `end1tsrv' `exogtsrv' `insttsrv'
	
	if `:word count `ujive1' `ujive2' `jive1' `jive2'' > 1 {
		di as error ///
"only one of ujive1, ujive2, jive1, or jive2 may be specified"
		exit 198
	}
	if "`ujive1'`ujive2'`jive1'`jive2'" == "" {
		local ujive1 "ujive1"		// Default is UJIVE
	}
	
	quietly {
		count if `touse'
		local N = r(N)
		// First stage
		local end1hat ""
		tempname fstat1 r21
		foreach z of varlist `end1tsrv' {
			cap reg `z' `exogtsrv' `insttsrv' if `touse'
			if _rc {
				noi di "A first stage regression failed"
				exit 498
			}
			tempvar `z'pi `z'hat
			predict double ``z'pi' if `touse'
			predict double ``z'hat' if `touse', hat
			if "`jive1'`ujive1'" != "" {
				replace ``z'pi' = ///
				   (``z'pi' - `z'*``z'hat') / (1 - ``z'hat') ///
				   if `touse'
			}
			else {
				replace ``z'pi' = ///
				(``z'pi' - `z'*``z'hat') / (1 - 1/`N') ///
				if `touse'
			}
			local end1hat `end1hat' ``z'pi'
			if `end1cnt' == 1 {
				cap test `insttsrv'
				scalar `fstat1' = r(F)
				local   fstat1n = r(df)
				local   fstat1d = r(df_r)
				scalar `r21'   = e(r2)
			}
		}
		
		tempname beta V sigsq
		if "`ujive1'`ujive2'" != "" {
			CalcUJIVE "`lhs'" "`exogtsrv'" "`end1tsrv'" 	/*
			       */ "`end1hat'" `touse' `beta' 	/*
			       */ `V' `sigsq' "`robust'"
		}
		else {
			CalcJIVE "`lhs'" "`exogtsrv'" "`end1tsrv'" 	/*
			      */ "`end1hat'" `touse' `beta' 	/*
			      */ `V' `sigsq' "`robust'"
		}
		matrix colnames `beta' = `end1' `exog' _cons
		matrix colnames `V' = `end1' `exog' _cons
		matrix rownames `V' = `end1' `exog' _cons
		local k `=`end1cnt'+`exogcnt'+1'
		eret post `beta' `V', dep(`lhsname') obs(`N') 	///
			esample(`touse') dof(`=`N'-`k'')
		eret local insts `exog' `inst'
		eret local instd `end1'
		eret local depvar `lhsname'
		eret local title "Jackknife instrumental variables regression"
		local model `=upper("`ujive1'`ujive2'`jive1'`jive2'")'
		eret local model `model'
		eret scalar rmse = sqrt(`sigsq')
		qui test `end1' `exog'
		eret scalar F = `=r(F)'
		eret scalar df_m = `=`k'-1'		// -1 for constant
		eret scalar df_r = `=`N'-`k''
		tempname rsq adjrsq
		qui sum `lhs'
		sca `rsq' = 1 - (`sigsq'*(`N'-`k') / (r(Var)*(`N'-1)))
		sca `adjrsq' = 1 - (1 - `rsq')*(`N'-1)/(`N'-`k')
		eret scalar r2 = `rsq'
		eret scalar r2_a = `adjrsq'
		if `end1cnt' == 1 {
			eret scalar F1      = `fstat1'
			eret scalar df_m_F1 = `fstat1n'
			eret scalar df_r_F1 = `fstat1d'
			eret scalar r2_1    = `r21'
		}
		eret local predict "regriv_p"
		eret local cmd "jive"
	}

	Display, level(`level')

end


program Display

	syntax , level(cilevel)

	di
	di as text "`e(title)'" " (`e(model)')"
	di
	
	tempname left right
	.`left' = {}
	.`right' = {}
	
	local C1 "_col(1)"
	local C2 "_col(17)"
	local C3 "_col(54)"
	local C4 "_col(70)"

	if `:word count `e(instd)'' == 1 {
		.`left'.Arrpush `C1' "First-stage summary"
		.`left'.Arrpush `C1' "{hline 25}"
		.`left'.Arrpush `C1' "F("			///
			as res %4.0f e(df_m_F1)	as text ","	///
			as res %6.0f e(df_r_F1) as text ")"	///
			`C2' "= " as res %7.2f e(F1)
		.`left'.Arrpush `C1' "Prob > F" `C2' "= " 	///
			as res %7.4f Ftail(e(df_m_F1), e(df_r_F1), e(F1))
		.`left'.Arrpush `C1' "R-squared" `C2' "= "	///
			as res %7.4f e(r2_1)
	}
	
	.`right'.Arrpush `C3' "Number of obs"		///
		`C4' "= " as res %7.0f e(N)
	.`right'.Arrpush `C3' "F("			///
		as res %4.0f e(df_m) as text ","	///
		as res %6.0f e(df_r) as text ")"	///
		`C4' "= " as res %7.2f e(F)
	.`right'.Arrpush `C3' "Prob > F" `C4' "= "	///
		as res %7.4f Ftail(e(df_m), e(df_r), e(F))
	.`right'.Arrpush `C3' "R-squared"		///
		`C4' "= " as res %7.4f e(r2)
	.`right'.Arrpush `C3' "Adj R-squared"		///
		`C4' "= " as res %7.4f e(r2_a)
	.`right'.Arrpush `C3' "Root MSE" 		///
		`C4' "= " as res %7.4f e(rmse)
		
	local nl = `.`left'.arrnels'
	local nr = `.`right'.arrnels'
	local k = max(`nl', `nr')
	forvalues i = 1/`k' {
		di as text `.`left'[`i']' as text `.`right'[`i']'
	}
	
	di
	eret di, level(`level')
	di as text "Instrumented:  " _c
	Disp `e(instd)'
	di as text "Instruments:   " _c
	Disp `e(insts)'
	di as text "{hline 78}"
	
end
	
program define CalcUJIVE

	args lhs exog end1 end1hat touse beta V sigsq robust
	
	tempvar one
	gen `one' = 1
	tempname all xtpx xtpxt xtpy xtpxi
	matrix accum `all' = ///
		`end1hat ' `exog' `one' `end1' `exog' `one' `lhs' ///
		if `touse',  nocons
	local end1cnt : word count `end1'
	local exogcnt : word count `exog'
	local i `=`: word count `end1'' + `: word count `exog'' + 1' 
							// 1 for constant
	matrix `xtpx' = `all'[1..`i', `=`i'+1'..`=2*`i'']
	matrix `xtpxt' = `all'[1..`i', 1..`i']
	matrix `xtpy' = `all'[1..`i', `=2*`i'+1']
	matrix `xtpxi' = inv(`xtpx')
	matrix `beta' = (`xtpxi'*`xtpy')'
	// Use endogenous vars for residuals, not the predicted vars
	matrix colnames `beta' = `end1' `exog' `one'
	tempvar resid
	matrix score double `resid' = `beta' if `touse'
	replace `resid' = `lhs' - `resid' if `touse'
	summ `resid' if `touse'
	tempname sigsqhat
	scalar `sigsq' = r(Var)*(r(N)-1) / (r(N) - `i')
	if "`robust'" == "robust" {
		matrix accum `xtpxt' = `end1hat' `exog' [iw = `resid'^2]
	}
	else {
		matrix `xtpxt' = `sigsq'*`xtpxt'
	}
	matrix `V' = `xtpxi' * `xtpxt' * `xtpxi''
	
end


program define CalcJIVE

	args lhs exog end1 end1hat touse beta V sigsq robust
	
	reg `lhs' `end1hat' `exog'
	
	matrix `beta' = e(b)
	// Use endogenous vars for residuals, not the predicted vars
	matrix colnames `beta' = `end1' `exog' `one'
	tempvar resid
	matrix score double `resid' = `beta' if `touse'
	replace `resid' = `lhs' - `resid' if `touse'
	summ `resid' if `touse'
	tempname sigsqhat
	local i `=`: word count `end1'' + `: word count `exog'' + 1' 
							// 1 for constant
	scalar `sigsq' = r(Var)*(r(N)-1) / (r(N) - `i')
	tempname xtpxt xtpxti
	matrix accum `xtpxt' = `end1hat' `exog'
	matrix `xtpxti' = inv(`xtpxt')
	if "`robust'" == "robust" {
		tempname M
		matrix accum `M' = `end1hat' `exog' [iw = `resid'^2]
		matrix `V' = `xtpxti' * `M' * `xtpxti'
	}
	else {
		matrix `V' = `sigsq' * `xtpxti'
	}
	
end



// Borrowed from ivreg.ado	
program define IsStop, sclass

	if `"`0'"' == "[" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "," {
		sret local stop 1
		exit
	}
	if `"`0'"' == "if" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "in" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "" {
		sret local stop 1
		exit
	}
	else {
		sret local stop 0
	}

end

// Borrowed from ivreg.ado	
program define Subtract   /* <cleaned> : <full> <dirt> */

	args        cleaned     /*  macro name to hold cleaned list
		*/  colon       /*  ":"
		*/  full        /*  list to be cleaned
		*/  dirt        /*  tokens to be cleaned from full */

	tokenize `dirt'
	local i 1
	while "``i''" != "" {
		local full : subinstr local full "``i''" "", word all
		local i = `i' + 1
	}

	tokenize `full'                 /* cleans up extra spaces */
	c_local `cleaned' `*'

end


// Borrowed from ivreg.ado
program define Disp
        local first ""
        local piece : piece 1 64 of `"`0'"'
        local i 1
        while "`piece'" != "" {
                di as text "`first'`piece'"
                local first "               "
                local i = `i' + 1
                local piece : piece `i' 64 of `"`0'"'
        }
        if `i'==1 { 
		di 
	}

end


// Collinearity checker
program define CheckVars, sclass

	args lhs exog end1 inst touse

	sret clear
        qui ivreg `lhs' `exog' (`end1' = `inst')
        if ( e(N) == 0 | e(N) >= . ) {
                exit 2000
        }
	local newinst `"`e(insts)'"'
        tempname b
        matrix `b' = e(b)
        qui replace `touse' = 0 if !(e(sample))
        local varlist : colnames(`b')
        tokenize `varlist'
        local i : word count `varlist'
        if `"``i''"' != "_cons" {
                di as error "may not drop constant"
                exit 399
        }
        local `i'               //   These two lines essentially
        local varlist `"`*'"'   //   remove _cons from varlist
        // If any of the endogenous variables were dropped, exit
        // with an r(498).
        tokenize `varlist'
        local i = 1
        foreach x of local end1 {
                if `"``i''"' != `"`x'"' {
                        di as error "may not drop an endogenous variable"
                        exit 498
                }
                local i = `i' + 1   
        }
        local exog : subinstr local varlist "`end1'" ""
        tokenize `exog'         // Clean up exog and remove
        local exog `"`*'"'      // extraneous white space
	foreach word of local exog {
		local newinst : subinstr local newinst "`word'" ""
	}
	tokenize `newinst'
	local newinst `"`*'"'
	sret local exog `"`exog'"'
	sret local inst `"`inst'"'
			
end

program define CheckOrder
	
	args end inst

        if `end' > `inst' {
                di as error "equation not identified; must have at " ///
                        "least as many instruments "
                di as error "not in the regression as there are "    ///
                        "instrumented variables"
                exit 481
        }

end
exit

* 20060216: First-stage df_m, df_r, r^2 now stored in 
*	    e(df_m_F1), e(df_r_F1), and e(r2_1) to match
*	    Stata conventions for saved results
* 20060417: Fixed a bug in which first-stage F test had
	    inadvertently included the exogenous regressors.
	    That F test is just on the extra instruments.
