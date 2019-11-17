*! 1.0.0 NJC 30 April 2011 
*! avplot 3.4.2  07mar2005
program favplot, rclass
	version 9  

	_isfit cons
	syntax varname [,  ///
	bformat(str)       /// 
	tformat(str)       ///  
	VARtitle(str)      ///
	TBtitle(str)  * ]

	_get_gropts , graphopts(`options') getallowed(RLOPts plot addplot)
	local options `"`s(graphopts)'"'
	local rlopts `"`s(rlopts)'"'
	local plot `"`s(plot)'"'
	local addplot `"`s(addplot)'"'
	_check4gropts rlopts, opt(`rlopts')

	local v `varlist'
	local wgt "[`e(wtype)' `e(wexp)']"
	tempvar touse resid lest evx hat

			/* determine if v in original varlist	*/
	if "`e(depvar)'" == "`v'" { 
		di as err "cannot include dependent variable"
		exit 398
	}
	local lhs "`e(depvar)'"
	_getrhs rhs
	gen byte `touse' = e(sample)
	if "`e(clustvar)'" != "" {
		tempname myest
		local cluster "cluster(`e(clustvar)')"
		estimates hold `myest'
		qui regress `lhs' `rhs' if `touse', `robust'
		local ddof = e(df_r)
		estimates unhold `myest'
	}
	else local ddof= e(df_r)
	
	tokenize `rhs'
	local i 1
	while "``i''" != "" & "`inorig'" == "" { 
		if "``i''" == "`v'" { 
			local inorig "true"
			local `i' " "		/* zap it */
		}
		local ++i
	}

	quietly _predict `resid' if `touse', resid
	
	if "`inorig'" == "" { 		/* not originally in	*/
		capture assert `v' < . if `touse'
		if _rc { 
			di as err "`v' has missing values" _n ///
		        "you must reestimate including `v'"
			exit 398
		}
		estimates store `lest'
		capture { 
			regress `v' `rhs' `wgt' if `touse',		///
				`robust' `cluster'
			_predict `evx' if `touse', resid
			regress `resid' `evx' `wgt' if `touse',		///
				`robust' `cluster'
			ret scalar coef = _b[`evx']
			_predict `hat' if `touse'
			regress `lhs' `v' `rhs' `wgt' if `touse',	///
				`robust' `cluster'
			ret scalar se = _se[`v']
		}
		local rc = _rc
	}
	else {				/* originally in	*/
		drop `resid'
		if _b[`v'] == 0 { 
			di as txt "(`v' was dropped from model)"
			exit 399
		}
		estimates store `lest'
		capture { 
			regress `lhs' `*' `wgt' if `touse',	///
				`robust' `cluster'
			_predict double `resid' if `touse', resid
			regress `v' `*' `wgt' if `touse',	///
				`robust' `cluster'
			_predict double `evx' if `touse', resid
			regress `resid' `evx' `wgt' if `touse',	///
				`robust' `cluster'
			ret scalar coef = _b[`evx']
			local seevx = _se[`evx']
			_predict double `hat' if `touse'
			regress `lhs' `rhs' `wgt' if `touse',	///
				`robust' `cluster'
			ret scalar se = _se[`v']
		}
		local rc = _rc
	}
	qui estimates restore `lest'
	if `rc' error `rc' 

	if "`tformat'" == "" local tformat %3.2f 
	if "`bformat'" == "" local bformat %6.0g 
	local tval : di `tformat' return(coef)/return(se)
	local bval : di `bformat' return(coef)
	local bval = trim("`bval'") 
	local note "b = `bval'     t = `tval'" 

	label var `resid' "residual for `lhs' | other X"
	local yttl : var label `resid'
	label var `evx' "residual for `v' | other X"           
	local xttl : var label `evx'
	local vtitle : var label `v'  
	if `"`vtitle'"' == "" local vtitle `v' 

	if `"`plot'`addplot'"' == "" {
		local legend legend(nodraw)
	}
	if `"`vartitle'"' != "" { 
		local vartitle title(, `vartitle')
	}  
	if `"`tbtitle'"' != "" { 
		local tbtitle subtitle(, `tbtitle')
	}  

	graph twoway			///
	(scatter `resid' `evx'		///
		if `touse',		///
		sort			///
		ytitle(`"`yttl'"')	///
		xtitle(`"`xttl'"')	///
		title(`"`vtitle'"', size(medium)) `vartitle' ///
		subtitle(`"`note'"') `tbtitle' ///
		`legend'		///
		`options'		///
	)				///
	(line `hat' `evx',		///
		sort			///
		lstyle(refline)		///
		`rlopts'		///
	)				///
	|| `plot' || `addplot'		///
	// blank
end

