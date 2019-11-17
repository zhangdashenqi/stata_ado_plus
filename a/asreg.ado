*! Attaullah Shah 1.1.0 4May2017
*! Email: attaullah.shah@imsciences.edu.pk
*! Support website: www.OpenDoors.Pk
* A fix to the following problem has been added: Previous version was leaving behind blank variables if the program was stopped in the middle


cap prog drop asreg
prog asreg, byable(onecall) sortpreserve

	version 11
	syntax                 ///
	varlist(numeric)      ///
	[in] [if],           ///
	[Window(string)     ///
	MINimum(real 0)   ///
	by(varlist)      ///
	FITted          ///
	SE             ///
	RECursive	  ///
	] 
	preserve
	marksample touse
		local nwindow : word count `window'
	if `nwindow'>2{
		dis in red "The rolling window accepts maximum two arguments. You have entered " `nwindow'
	exit
	}

	if "`recursive'"~=""{
		local recursive = 100000
	}
	else{
		local recursive = 0 
	}

	if `nwindow'==2 {
		tokenize `window'
		gettoken    rangevar window : window
		gettoken  rollwindow window : window
		local rollwindow = `rollwindow' + `recursive'
		
	}
	else if "`window'"!=""{ 
		local rollwindow =`window' + `recursive'
	}
	else {
		local rollwindow ""
	}
	
	tempvar GByVars dup first n  dif
	tokenize `varlist'
	local lhsvar "`1'"
	macro shift 1
	local rhsvars "`*'"

	qui {
		gen  _Nobs 	= .
		label var _Nobs "No of observatons"
		gen double _R2 	= .
		label var _R2 "R-squared"
		gen double _adjR2	= .
		label var _adjR2 "Adjusted R-squared"
		gen double _b_cons = .
		label var _b_cons "Constant of the regression"

		foreach i of varlist `rhsvars'{
			gen double _b_`i'=.
			label var _b_`i' "Coefficient of `i'"
			local b_rvsvars "`b_rvsvars' _b_`i'"

		}
		if "`se'"!=""{
			gen _se_cons=.
			label var _se_cons "Standard error of constant"
			foreach i of varlist `rhsvars'{
				gen _se_`i'=.
				label var _se_`i' "Standard error of `i'"
				local _se_rvsvars "`_se_rvsvars' _se_`i'"
			}
		local _se_rvsvars "_se_cons `_se_rvsvars'"
		}

	local ResultsVars "_Nobs _R2 _adjR2 `b_rvsvars' _b_cons  `_se_rvsvars'"
	}
	if "`se'"!=""{
		local se "YES"
	}
	else{
		local se "NO"
	}
	if "`fitted'"!=""{
		local fitted "YES"
	}
	else{
		local fitted "NO"
	}

	if "`_byvars'"!="" {
		local by "`_byvars'"
	}

	if "`by'"!="" {
		if "`rangevar'"=="" & "`rollwindow'"!="" { 
			if "`_dta[_TStvar]'"!=""{	
				local rangevar "`_dta[_TStvar]'"
			}
			else {
				dis as error "You have specified the option window with a length of `rollwindow'. However, the data is {break} not declared as panel or time series data"
				dis as text "You can specify range variable {break} in the option {cmd: window} as a first argument. For example, {cmd: window(year 50)} where {break} {cmd: year} is the range variable and {cmd: 50} is length of the rolling window."
				cap drop `ResultsVars'
				exit
			}
		}
		
		gen `n'=_n
		bysort `by' (`rangevar' `n'): gen  `first' = _n == 1
		qui gen `GByVars'=sum(`first')
		qui by `by' : gen `dif'=`rangevar'-`rangevar'[_n-1]

		mata: asreghk("`GByVars'", "`dif'")
		if `DataType' ==1 & "`rollwindow'"!="" {
			qui tsf, panel(`GByVars') timevar(`rangevar')
		}
		qui drop `n' `first' `dif'
	}
	else if "`by'"=="" & "`rollwindow'"!=""{
		if "`rangevar'"=="" {
			if "`_dta[_TStvar]'"!=""{	
				local rangevar "`_dta[_TStvar]'"
			}
			else {
				dis as error "You have specified the option window with a length of `rollwindow'. However, the data is {break} not declared as panel or time series data"
				dis as text "You can specify range variable {break} in the option {cmd: window} as a first argument. For example, {cmd: window(year `rollwindow')} where {break} {cmd: year} is the range variable and {cmd: `rollwindow'} is length of the rolling window."
				cap drop `ResultsVars'
				exit
			}
		}
		qui gen `GByVars'=1
		qui bys `GByVars' (`rangevar'): gen `dif'=`rangevar'-`rangevar'[_n-1]

		mata: asreghk("`GByVars'", "`dif'")
		if `DataType' ==1 {
			qui tsf, panel(`GByVars') timevar(`rangevar')
		}
		qui drop `dif'
	}
	else {
		qui gen `GByVars'=1 
	}

	if "`rollwindow'"!=""{
		mata: asregw("`varlist'", ///
		"`GByVars'" ,	   		 ///
		"`ResultsVars'" ,  		///
		`rollwindow',     	   /// 
		`minimum', 	     	  ///
		"`rangevar'",   	 /// 
		`DataType',   		///
		"`se'",       	   ///
		"`fitted'",  	  /// 
		"`touse'"   	 ///
		)
	}
	else {
		mata: asregnw(       ///
		"`varlist'",     	///
		"`GByVars'" ,	   ///
		"`ResultsVars'" , ///
		"`se'", 		 ///
		"`fitted'",		///
		`minimum',     ///
		"`touse'"     ///
		)
	}
	if "`by'"!=""{
		if `DataType' == 1 & "`rollwindow'"!="" {
			qui cap drop if TimeDiff==. 
			cap drop TimeDiff
		}
	}
restore, not
end

cap prog drop tsf
program define tsf, rclass
	syntax , timevar(varlist) [panel(varlist)] 
	if "`panel'" != ""   {
		local bypfx "qui by `panel': "
	}
	else  local bypfx "qui "  
		tempvar numreps TimeDiff
		noi cap `bypfx' gen double TimeDiff = `timevar'[_n+1] - `timevar'
	if _rc {
		sort `panel' `timevar'
		cap `bypfx' gen double TimeDiff = `timevar'[_n+1] - `timevar'
	}
	`bypfx' replace TimeDiff =  0 if _n == _N
	`bypfx' gen double `numreps' = TimeDiff 
	qui replace `numreps' = 0 if `numreps' == .
	local orign = _N
	qui count if  `numreps'  > 1
	local addns `r(N)'
	if `addns' > 0 {
		local newobs = `orign' + `addns'
		qui replace `numreps' = - `numreps'
		sort `numreps'
		qui replace `numreps' = - `numreps'
		qui set obs `newobs'
		local orign1 = `orign' + 1
		qui replace `numreps' = `numreps'[_n-`orign']  in `orign1'/l
		qui replace `timevar' = `timevar'[_n-`orign']  in `orign1'/l
		if "`panel'" != "" {
			qui replace `panel' = `panel'[_n-`orign']  in `orign1'/l
		}
		qui replace `numreps' = 0  in 1/`orign'
		qui replace `numreps' = `numreps' - 1  if `numreps'
		qui expand `numreps'
		sort `panel' `timevar' `numreps'
		qui by `panel' `timevar': replace `timevar' = `timevar' + /*
		*/ 1 * (`numreps' - _n + 2)  if `numreps' > 0
		drop  `numreps'
		sort `panel' `timevar'
	}

end
