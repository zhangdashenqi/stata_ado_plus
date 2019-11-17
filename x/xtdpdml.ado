*! xtdpdml.ado version 2.01 Richard Williams 10/17/2016
*
* 2.01 - Support for Stata 14.2 options skipcfatransform and
*        skipconditional added. Options are ignored in earlier 
*        versions of Stata. Some minor tweaks to help file.
* 2.00 - First official public release on SSC
* 1.87 - Minor tweaks to help file.
* 1.86 - Listwise option added for Mplus. Bollen and Brand
*        example & acknowledgments added to the help file.
* 1.85 - Improvement in the mplus command formatting and help.
*        Analysis and Output suboptions added to mplus.
*        Title option added.
* 1.81 - constinv, nocsd, and errorinv options now work in MPlus
* 1.80 - mplus option greatly improved. std and gof options added.
*        Help file modified accordingly.
* 1.70 - No changes in the program. Help file modified to discuss
*        postestimation commands like estat gof. fiml example added.
* 1.60 - Improved output for showcmd. semfile option lets you output
*        sem commands to a file.
* 1.55 - dryrun tweaked to ereturn e(semcmd) and other values the
*        user may want.
* 1.50 - Options dryrun and mplus added. Special topics section added 
*        to help. Discusses how to specify interactions with time
*        and offers suggestions for dealing with convergence problems.
*        Improved help for display options.
* 1.40 - Improved output for highlights. To get the old output back,
*        use the tsoff option. Only works when free options have not
*        been specified and lags do not exceed 9. (1.40 was never
*        officially released.)
* 1.30 - xtdpdml now issues warning messages and/or aborts when there
*        are problems with reshape wide. This would occur if, say,
*        the inv option was not specified correctly.
* 1.25 - Fixed a bug that resulted in fatal errors if a record had
*        missing on either panelvar or timevar. Such records now
*        get deleted, a warning message gets issued, and execution
*        continues.
* 1.20 - Improved the coding of covariance options. Instead of a
*        bunch of cov() options being generated, just one big one
*        is. This avoids a "Too many options" error.
*        Added evars option if you want the Es even when no vars
*        are prededermined. This may be needed to replicate some
*        earlier results
* 1.10 - More efficient coding if no predetermined vars,
*        i.e. we use e.y instead of Es
* 1.01 - Help file tweaks
* 1.00 - tfix option added. Help file tweaked
* 0.90 - Error checks for time variable. nocsd is
*       alias for constinv. Minor help file changes
* 0.80 - First version with help file
*
* Syntax:
* xtdpdml ystub xstub, inv(varlist) pre(prestub) other_options

program xtdpdml, eclass
	* version will be later reset to 13.1 unless v12 is specified 
	version 12.1
	
	* If wide, we must temporarily reshape and xtset first. Otherwise
	* lag notation does not work correctly. wide files must have been
	* created by a reshape wide command.
	syntax anything, [wide tfix *]
	preserve
	if "`wide'" != "" {
		reshape long
		xtset `_dta[_TSpanel]' `_dta[_TStvar]', delta(`_dta[_TSdelta]')
	}
	* By default data are assumed to be xtset in long format
	* with both panelid and timevar and delta already specifed.
	* wide option can be specified if data are already in wide format

	capture xtset
	if _rc {
		display as error "Data need to be in long format and xtset with " 
		display as error "both panelvar and timevar."
		display as error ///
		"If data are already in wide format use the wide option."
		display as error "Job is terminating."
		exit
	}

	local ivar = r(panelvar)
	local jvar = r(timevar)
	if "`ivar'" == "." | "`jvar'" =="." {
		display as error "Data must be xtset with both panelvar and timevar"
		exit
	}
	local delta = r(tdelta)

	
	* Check to make sure time is coded correctly. Abort if it isn't and tfix not specified
	if (r(tmin) != 1 | r(tdelta)!= 1) & "`tfix'" == "" {
		display as error "Time variable and/or delta is not coded correctly"
		display as error "Time variable must start with 1 and be coded 1, 2, ..., T"
		display as error "delta (the period between observations) must equal 1."
		display as error "Recode time variable or fix delta and rerun or else use tfix option"
		exit
	}
	
	* Recode time if tfix is specified
	tempvar timevar
	if "`tfix'" == "" {
		clonevar `timevar' = `jvar'
	}
	else {
		gen int `timevar' = 1 + (`jvar' - r(tmin))/r(tdelta)
		quietly xtset `ivar' `timevar', delta(1)
	}

	
	syntax varlist(ts min=1), /// 
	[T(integer -1)INV(varlist) PREdetermined(varlist ts ) ///
	wide STAYWide v12 ///
	YLAGs(numlist >=0 integer sort) ///
	NOLOG fiml  prefix(string) semopts(string) DRYrun  ///
	errorinv ALPHAFREE ALPHAFREE2(numlist >=1 <=2 integer max=1) ///
	ITERate(integer 250) TECHnique(string) tsoff ///
	addx(string) YFREE YFREE2(numlist) XFREE XFREE2(varlist ts) ///
	SHOWcmd MPlus(string) SEMFile(string) STD STD2(varlist) gof ///
	re CONSTraints(string) HILites DETAILs constinv NOCSD tfix evars ///
	SKIPCFAtransform SKIPCONDitional ///
	TItle(string) *]

	* version 13.1 is the default unless v12 is specified. v12 may
	* eventually become the default
	if "`v12'"=="" version 13.1
	gettoken y xstrictlyexog: varlist
	local xpredetermined `predetermined'
	local xtimeinvariant `inv'
	local xtimevarying `xstrictlyexog' `xpredetermined'
	* Determine which Xs & Ys, if any, are to have free parameters
	if "`xfree'" != "" { 
		local xfree `xstrictlyexog' `xpredetermined' `xtimeinvariant'
		}
	if "`xfree2'" != "" local xfree `xfree2'
	if "`ylags'" == "" local ylags 1
	if "`yfree'" != "" { 
		local yfree `ylags'
	}
	if "`yfree2'" != "" local yfree `yfree2'
	* Some other defaults
	if "`technique'" == "" local technique nr 25 bhhh 25
	if "`constraints'" != "" local constraints(`constraints')
	* nocsd and constinv are aliases
	if "`nocsd'" !="" local constinv constinv
	if "`title'" =="" {
		local title Dynamic Panel Data Model using ML for outcome variable `y'
	}

	* skipcfatransform and skipconditional options only work in Stata 14.2
	* and later. They are ignored if used in used in earlier versions of Stata
	if `c(stata_version)' < 14.2 {
		local skipcfatransform
		local skipconditional
	}
	
	/// Begin mplus code if mplus has been requested
	/// mplus implies dryrun. Some code added so defaults
	/// can be easily edited
	if "`mplus'" != "" {
		tempvar xout
		tempfile xback
		capture file close `xout'
		quietly file open `xout' using `xback', write text replace

	}	
	


	****** Determine maximum lag; vars to keep ******
	local xlagsmax = 0
	forval type = 1/2 {
		if `type' == 1 {
			local xtype `xstrictlyexog'
		}
		else {
			local xtype `xpredetermined'
		}
			foreach xvar of local xtype {
			local lag0 = strpos("`xvar'", ".")
			local lag1 = strpos("`xvar'", "L.")
			local lagn = substr("`xvar'", 2, 1)
			if `lag0' == 0 {
				* No lags
				local lag 0
				local varbase `xvar'
			}
			else if `lag1' != 0 {
				* Lag 1
				local lag 1
				local varbase = substr("`xvar'", 3, .)
			}
			else {
				* Lag > 1
				local dot = strpos("`xvar'", ".")
				local lengthnum = `dot' - 2
				local lag = substr("`xvar'", 2, `lengthnum')
				local varbase = substr("`xvar'", `dot'+1, .)
			}
			if `xlagsmax' < `lag' local xlagsmax = `lag'
			local baselabels `baselabels' `varbase'
			if `type' == 2  local prelabels `prelabels' `varbase'
		}
		local basenames: list uniq baselabels
		local prenames: list uniq prelabels
	}

		* default lags"

	local ylagsmax = word("`ylags'", wordcount("`ylags''"))
	local Tmin = 2 + max(`xlagsmax', `ylagsmax')	
	
	* default alphafree option
	if "`alphafree'" != "" local alphafree 2
	if "`alphafree2'" != "" local alphafree `alphafree2'

	

	if `t' != -1 & `t' < `Tmin' {
		display as error "T value is too small given the lags specified"
		display as error "For example if xlag = 2 then T must equal at least 4"
		display as error "Job is terminating."
		exit
	}
	
	if `t' >= `Tmin' local T `t'
	if "`fiml'" != "" local semopts `semopts' method(mlmv)
	// display and maximization options
	_get_diopts diopts options, `options'
	mlopts mlopts, `options'


	* Use T in data set unless user has overrided
	if "`T'" =="" local T = r(tmax)
	
	
	****** Get time and lags worked out ******

	if `T' < `Tmin' {
		display as error "T value is too small given the lags specified"
		display as error "For example if xlag = 2 then T must equal at least 4"
		exit
	}

	local Tstart = 1 + max(`xlagsmax', `ylagsmax')

	local Tmin3 = `T' - 3
	local Tmin2 = `T' - 2
	local Tmin1 = `T' - 1
	if "`addx'" !="" local addx (`addx')
	local scmd sem `addx'

	****** Generate Regression part of the command
	* Every equation has E, Alpha, and constant. So start with 3
	* and then add 1 for each variable in the equation
	local nvars = 0
	forval t = `Tstart'/`T' {
		local bnum = 0
		local ybn
		local xbn
		local yused
		local xused
		* get all the desired Y lags. If yfree is not specified Y coefficients
		* Will be constrained to be equal with lags; otherwise free.
		foreach lag of local ylags {
			if `lag' > 0 {
				local ylag = `t' - `lag'
				* Check to see if this should be a freed parameter
				local btag
				local mtag ^
				local yfreed 0
				if "`yfree'" != "" {
					local yfreed : list lag in yfree
				}
				if `yfreed' == 0 {
					local bnum = `bnum' + 1
					local btag @b`bnum'
					local mtag (`bnum')^
				}
				local ybn `ybn' `y'`ylag'`btag'
				local ymn `ymn' `y'`ylag' `mtag'
				local yused `yused' `y'`ylag'
				if `t' == `Tstart' local nvars = `nvars' + 1
			}


		}
		* Get all the desired x lags
		forval type = 1/2 {
			if `type' == 1 {
				local xtype `xstrictlyexog'
			}
			else {
				local xtype `xpredetermined'
			}
			foreach xvar of local xtype {
				local lag0 = strpos("`xvar'", ".")
				local lag1 = strpos("`xvar'", "L.")
				local lagn = substr("`xvar'", 2, 1)
				if `lag0' == 0 {
					* No lags
					local xlag = `t'
					local varbase `xvar'`xlag'
				}
				else if `lag1' != 0 {
					* Lag 1
					local xlag = `t' - 1
					local varbase = substr("`xvar'", 3, .)
					local varbase `varbase'`xlag'
				}
				else {
					* Lag > 1
					local dot = strpos("`xvar'", ".")
					local lengthnum = `dot' - 2
					local lagn = substr("`xvar'", 2, `lengthnum')
					local xlag = `t' - `lagn'
					local varbase = substr("`xvar'", `dot'+1, .)
					local varbase `varbase'`xlag'
				}
				* Create covariances between Es and later predetermined Xs
				* Create a covar for each E with a higher numbered X
				* Must place this later in command so other options
				* don't override it!
				* This code is NOT executed if there are no predetermined
				forval Enum = `Tstart'/`T' {
					if `type' == 2 & `xlag' > `Enum' {
						*local covarE `covarE' `varbase'*(E`Enum')
						local ElistX `ElistX' E`Enum'
						local mplistX `mplistX' `y'`Enum'
					}
				}
				if `type' == 2 & "`ElistX'" != "" {
					local covarE `covarE' `varbase'*(`ElistX')
					local covarM `covarM' `varbase' `mplistX';
					local ElistX
					local mplistX
				}
				
				* Check to see if this should be a freed parameter
				local btag
				local mtag ^
				local xfreed 0
				if "`xfree'" != "" {
					local xfreed : list xvar in xfree
				}
				if `xfreed' == 0 {
					local bnum = `bnum' + 1
					local btag @b`bnum'
					local mtag (`bnum')^
				}
				local xused `xused' `varbase'
				local varbasem `varbase'
				local varbase `varbase'`btag'
				local varbasem `varbasem' `mtag'
				/// ////
				local xbn `xbn' `varbase'
				local xmn `xmn' `varbasem'
				if `t' == `Tstart' local nvars = `nvars' + 1
				}

			}
			foreach xvar of local xtimeinvariant {
				* Check to see if this should be a freed parameter
				local btag
				local mtag ^
				local xfreed 0
				if "`xfree'" != "" {
					local xfreed : list xvar in xfree
				}
				if `xfreed' == 0 {
					local bnum = `bnum' + 1
					local btag @b`bnum'
					local mtag (`bnum')^
				}
				local xbn `xbn' `xvar'`btag'
				local xmn `xmn' `xvar' `mtag'
				local xused `xused' `xvar'
				if `t' == `Tstart' local nvars = `nvars' + 1
			}
		

		* Create the E values for all but the last Y
		* but only if there are predetermined vars -
		* otherwise just stick with e.y
		* unless evars also specified
		local E
		if "`predetermined'" != "" | "`evars'" != ""{
			if `t' != `T' {
				local E E`t'@1
				local Elist `Elist' E`t'
				* Set e.y variances to 0 whenever E has replaced it
				local variance `variance' e.`y'`t'@0
			}
		}

	* Make Alpha either free or constrained
	if "`alphafree'" == "" {
		* Do not constrain Alpha coefficients to be equal (default)
		* Normalize by fixing all coefficients at 1; leave var(Alpha) free
		local Alpha Alpha@1
		local Alphavar var(Alpha)
	}
	else if "`alphafree'" == "1" {
		* Normalize by fixing first coefficient at 1; leave var(Alpha) free
		local Alphavar var(Alpha)
		if "`t'" == "`Tstart'" {
			local Alpha Alpha@1
		}
		else {
			local Alpha Alpha
		}
	}
	else if "`alphafree'" == "2" {
		* Normalize by fixing var(Alpha) at 1; leave all coefficients free
		local Alpha Alpha
		local Alphavar var(Alpha@1)
	}
	* Constrain constants to be equal. Can cause convergence problems
	local constant
	if "`constinv'" != "" local constant _cons@a1
	* Create sem regression commands
	local scmd `scmd' (`y'`t' <- `ybn' `xbn' `Alpha' `E' `constant')
	local usedvars `usedvars' `y'`t' `yused' `xused'
	local endogvars `endogvars' `y'`t'

	/// Mplus - Write out model command
	if "`mplus'" != "" {
		file write `xout' "     `y'`t' on " _n
		local yandx `ymn' `xmn'
		while "`yandx'" != "" {
			gettoken nextvar yandx: yandx, parse("^")
			if "`nextvar'" !="^" file write `xout' "          `nextvar'"  _n
		}
		file write `xout' "          ;"  _n
	}
		local xmn
		local ymn
		local yandx
	}



	****** Create the variance and covariance matrices ******
	* If re (random effects) is specified, Alpha not correlated with Xs
	if "`re'" !="" {
		local covar `covar' Alpha*(_OEx)@0
	}
	* Otherwise set to 0 the covariance between Alpha and the time invariant predictors
	else if "`xtimeinvariant'" !="" {
		local covar `covar' Alpha*(`xtimeinvariant')@0
	}
	
	*** Next several commands only executed if E vars exist ***
	*
	* sets to 0 the covariances between the new error terms and all of 
	* the observed, exogenous variables ( _OEx).

	if "`Elist'" != "" {
		local variance var(`variance')
		local covar `covar' Alpha*(`Elist')@0
		local covar `covar' _OEx*(`Elist')@0
		* Set Error covariances at 0
		forval t = `Tstart'/ `Tmin2' {
			local Elater
			local tplus1 = `t' + 1
			forval tlater = `tplus1'/ `Tmin1' {
				local Elater `Elater' E`tlater'
			}
			local covar `covar' E`t'*(`Elater')@0
		}
	}
	
	****** Constrain error terms to be equal if so requested
	****** Approach taken depends on whether or not model has predet vars
	if "`errorinv'" != "" {
		if "`predetermined'" != "" | "`evars'" != ""{
			foreach E of local Elist {
				local equalerrors `equalerrors' `E'@v1
			}
			local equalerrors `equalerrors' e.`y'`T'@v1
			local equalerrors var(`equalerrors')
		}
		else {
			forval evar = `Tstart'/`T' {
				local equalerrors `equalerrors' e.`y'`evar'@v1
			}
			local equalerrors var(`equalerrors')
		}
	}

	****** Create the final covariance command, if there is one ******
	local covariances
	if "`covar'" != "" | "`covarE'" != "" local covariances cov(`covar' `covarE')
	
	****** Create the final sem command ******
	local scmd `prefix' `scmd', `variance' `Alphavar' `covariances' 
	local scmd `scmd' `semopts' `nolog' `mlopts' `diopts' 
	local scmd `scmd' `equalerrors' iterate(`iterate') technique(`technique')
	local scmd `scmd' noxconditional `constraints'
	local scmd `scmd' `skipcfatransform' `skipconditional'
	* Show the command and/or create a sem do file if requested
	if "`showcmd'" !="" | "`semfile'" != "" {
		semout, longcmd(`scmd') `showcmd' semfile(`semfile')
	}
		
	****** Get data into wide format; execute command

	* Standardize selected variables if requested. Won't work if data were
	* originally in wide format
	* Vars to be standardized while in long format. TS notation
	* is stripped out this way and each var is only included once.

	if "`std'" != "" {
		local allvars `y' `xstrictlyexog' `xpredetermined' `xtimeinvariant'
		tsrevar `allvars', list
		local std `=r(varlist)'
	}
	if "`std2'" != "" local std `std2'
	
	if "`std'" != "" & "`wide'" == "" {
		foreach var of local std {
			tempvar stdx
			quietly egen `stdx' = std(`var')
			quietly replace `var' = `stdx'
		}
	}
	if "`wide'" != "" {
		* Data were already wide, so restore
		restore
	}
	else {
		* Data are in long format; reshape to wide
		* First check for missing values on the xtset variables
		quietly count if missing(`ivar', `jvar')
		if r(N) > 0 {
			display
			display as error "Warning! " r(N) " records have missing values on `ivar' and/or `jvar'."
			display as error "Records with missing values on panelvar or timevar are deleted from the analysis."
			display as error "If you want them included you will need to first correct the missing values."
			display as error "Execution continues without the dropped records."
			display 
			quietly drop if missing(`ivar', `jvar')
			}
		keep `y' `basenames'  `xtimeinvariant' `ivar' `timevar'
		* reshape is done quietly but errors will still cause program to abort
		quietly reshape wide `y' `basenames', i(`ivar') j(`timevar')
	}
	
	****** Mplus (if requested)

	* See if mplus has been requested. If so run xstata2mplus to generate 
	* mplus files. Options replace and missing can be specified.
	* This generates the front end of the mplus code
	if "`mplus'" != "" {
		* Commas will be deleted from option
		local mplus = subinstr("`mplus'", ",", " ", .)
		gettoken mfilename moptions: mplus
		local mvarlist: list uniq usedvars
		local exogvars: list mvarlist - endogvars
		local alphacorr: list exogvars - xtimeinvariant
		xstata2mplus using `mfilename', use(`mvarlist') `moptions' title(`title')
	}

	* This will write out the rest of the mplus code and create a single inp file
	if "`mplus'" != "" {
		* This sets up Alpha to load on the Y variables
		file write `xout' _n
		if "`alphafree'" ! = "" {
			file write `xout' "     ! Alpha loadings free to vary across time" _n
		}
		else {
			file write `xout' "     ! Alpha loadings equal 1 for all times" _n
		}
		file write `xout' "     Alpha by " _n "          "
		local fixedalpha @1
		local len = 0
		foreach endogvar of local endogvars {
			if `len' > 60 {
				file write `xout' _n "          "
				local len = 0
			}
			file write `xout' "`endogvar'`fixedalpha' "
			local len = `len' + length(" `endogvar'`fixedalpha'")
			if "`alphafree'" != "" local fixedalpha *
		}
		file write `xout' ";" _n
		
		* Let Alpha load on exogenous vars, except time invariant.
		* If re option is specified alpha is uncorrelated with
		* exogenous vars. Time invariant vars also uncorrelated.
		* Otherwise free
		if "`re'" != "" {
			file write `xout' "     ! Random Effects Model - Alpha uncorrelated with Exogenous Vars" _n
		}
		else {
			file write `xout' "     ! Fixed Effects Model - Alpha correlated with Time-Varying Exogenous Vars" _n
		}
		file write `xout' "     Alpha with " _n "          "

		local len = 0
		foreach exogvar of local exogvars {
			local invvar: list exogvar & xtimeinvariant
			if "`re'" != "" {
				local corrfixed @0
			}
			else if "`invvar'" != "" {
				local corrfixed @0
			}
			else {
				local corrfixed *
			}
			
			if `len' > 60 {
				file write `xout' _n "          "
				local len = 0
			}
			file write `xout' "`exogvar'`corrfixed' "
			local len = `len' + length(" `exogvar'`corrfixed'")
		}
		file write `xout' ";" _n

		
		* Code for the correlations between Ys and predetermined vars
		if "`covarM'" != "" {
			file write `xout' "     ! Correlations between Ys and predetermined variables" _n
		}
		while "`covarM'" != "" {
			local len = 0
			gettoken nextpre covarM: covarM, parse(";")
			if "`nextpre'" != ";" {
				gettoken prevar nextpre: nextpre
				file write `xout' "     `prevar' with"  _n "         "
				foreach varwith of local nextpre {
					if `len' > 60 {
						file write `xout' _n "         "
						local len = 0
					}
					file write `xout' " `varwith'"
				local len = `len' + length(" `varwith'")
				}
			file write `xout' ";" _n
			}

		}
		
		* constinv/ nocsd option:
		if "`constinv'" != "" {
			file write `xout' "     ! Constants constrained to be equal across waves" _n
			local bnum = `bnum' + 1
			foreach endogvar of local endogvars {
				file write `xout' "     [`endogvar'] (`bnum')"  _n
			}
			file write `xout' "     ;" _n
		}
		
		* Error variances invariant
		if "`errorinv'" != "" {
			file write `xout' "     ! Error variances constrained to be equal across waves" _n
			local bnum = `bnum' + 1
			foreach endogvar of local endogvars {
				file write `xout' "     `endogvar' (`bnum')"  _n
			}
			file write `xout' "     ;" _n
		}
	

		* Close the back end
		file close `xout'

		* Combine the back end with the front end into a single file
		if "`c(os)'" == "Windows" {
			shell type `xback' >> `mfilename'.inp
		}
		else shell cat `xback' >> `mfilename'.inp
		
		display as text
		display as text "You can start mplus and open the file `mfilename'.inp." ///
			 " Some editing may be necessary." _n
	}
	
	****** End of Mplus code

	****** Execute command if requested

	* Check to see if this is a dryrun, i.e. nothing is actually supposed to
	* be estimated
	if "`dryrun'" !="" {
		// Keep data in wide format if requested
		if "`staywide'" !="" & "`wide'" == "" {
			restore, not
			display
			display "Warning: Data are in now in wide format"
		}
		display
		// ereturn values the user may want after a dryrun
		ereturn local semcmd `scmd'	
		ereturn scalar Tstart = `Tstart'
		ereturn scalar T = `T'
		ereturn local depvar `y'
		ereturn local title `title'
		display "Warning: dryrun was requested - no actual estimation was done"
	exit
	}
		
	* Finally! Execute command
	if "`details'" =="" {
		quietly `scmd'
	}
	else `scmd'
	ereturn local semcmd `scmd'	
	ereturn scalar Tstart = `Tstart'
	ereturn scalar T = `T'
	ereturn local depvar `y'
	ereturn local title `title'
	 
	* Hilites printout
	local free 0
	local anyfree `xfree' `yfree' `alphafree'
	if "`anyfree'" != "" local free 1
	hilites, nvars(`nvars') diopts(`diopts') free(`free') /// 
		y(`y') inv(`inv') `tsoff' title(`title')
	if "`gof'" !="" estat gof, stats(all)

	****** Final Cleanup ******
	* Restore data to long format unless staywide specified
	* or if dataset was already in wide format
	if "`staywide'" !="" & "`wide'" == "" {
		display "Warning: Data are in now in wide format"
		restore, not
	}
end

********************************************************************************

* Adapted from linewrap by Mead Over, Center for Global Development
* This routine formats the output from the sem command and/or
* creates a do file with the generated code
program semout
	syntax, longcmd(string) [showcmd semfile(string) ]
	local maxlength 60
	
	if "`semfile'" != "" {
		* Commas deleted
		local semfile = subinstr("`semfile'", ",", " ", .)
		gettoken semfile replace: semfile
		if "`replace'" == "r" local replace replace
		tempvar out
		capture file close `out'
		quietly file open `out' using `"`semfile'.do"', write text `replace'
		file write `out' "#delimit ;" _n
	}
	if "`showcmd'" !="" {
		display
		display as result "The generated sem command is"
		display
	}
	
	local line = 1
	local i = 0  // Character position in rest of the string
	local blnkpos = .  // Characters until next blank  
	local restofstr `longcmd'
	local lngthrest = length(`"`longcmd'"')  //  Total number of characters in the rest of the string
	while `i' < `lngthrest' & `blnkpos' > 0 {
		local blnkpos = strpos(substr(`"`restofstr'"',`i'+1,.)," ") 
		local i = `i' + `blnkpos'

		if `i' >= `maxlength' {
			if `i' - `blnkpos' > 0 {  
				local tmpstr = substr("`restofstr'", 1 ,`i' - `blnkpos' - 1)
				*return local line`line' = `"`tmpstr'"'

				if `line' > 1 local spaces "    "
				if "`showcmd'" != "" display "`spaces'" `"`tmpstr'"'
				if "`semfile'" != "" {
					file write `out' "`spaces'" `"`tmpstr'"' _n
				}
				local line = `line' + 1
				local restofstr = substr(`"`restofstr'"', `i' - `blnkpos' + 1 , .)
				local lngthrest = length("`restofstr'")  //  Number of characters left
				local blnkpos = strpos(substr(`"`restofstr'"',1,.)," ") 
				local i = 0
			}
			else {  // When a string of characters is longer than maxlength
				local tmpstr = substr("`restofstr'", 1 ,`blnkpos'-1)
				if "`showcmd'" != ""  {
					di as txt `ln'  as res `"`tmpstr'"'
				}
				if "`semfile'" != "" {
					file write `out' "`spaces'" `"`tmpstr'"' _n
				}
				local line = `line' + 1
				local restofstr = substr(`"`restofstr'"', `blnkpos' + 1 , .)
				local lngthrest = length("`restofstr'")  //  Number of characters left
				local blnkpos = strpos(substr(`"`restofstr'"',1,.)," ") 
				local i = 0				
			}
		}
	}
	else {  //  Rest of string fits in a single line
		local tmpstr `restofstr'
		*return local line`line' = `"`tmpstr'"'
		local spaces
		if `line' > 1 local spaces "    "
		if "`showcmd'" != "" {
			display "`spaces'" `"`tmpstr'"'
			display
		}
		if "`semfile'" != "" {
			file write `out' "`spaces'" `"`tmpstr'"' ";" _n
			file write `out' "#delimit cr" _n
			file close `out'
			display
			display "`semfile'.do contains the generated sem code"
			display
		}
		local nlines = `line'
	}
end

********************************************************************************

program hilites, eclass
	syntax , nvars(integer) free(integer) ///
		y(string) [diopts(string) inv(string) title(string) tsoff]
	// Get our matrices set up
	tempname bcopy vcopy b2 v2 hilites_b hilites_v
	mat `bcopy' = e(b)
	mat `vcopy' = e(V)
	local Tstart = e(Tstart)
	local T = e(T)
	local Nperiods = `T' - `Tstart' + 1
	if `free' == 1 local nvars = (`nvars' + 3) * `Nperiods' - 1
	matrix `hilites_b' = `bcopy'[1, 1..`nvars']
	matrix `hilites_v' = `vcopy'[1..`nvars', 1..`nvars']
	//matrix `hilites_b' = `b2'
	//matrix `hilites_v' = `v2'
	
	// Rename rows and columns for hilite purposes if necessary conditions met
	if `free' == 0 & `Tstart' <= 9 & "`tsoff'" == ""{
		local varnames: colnames(`hilites_b')
		local newname

		foreach vname of local varnames {
			// Time invariant vars keep their current names
			local invvar: list inv & vname
			if "`invvar'" != "" {
				local newname `y':`vname'
			}
			// Otherwise rename using lag notation if appropriate
			else {
				local wave = substr("`vname'", strlen("`vname'"), 1)
				local xname = substr("`vname'", 1 , strlen("`vname'")-1)
				local lag = `Tstart' - `wave'
				if `lag' == 0 {
					local newname `y':`xname'
				}
				else {
					local newname `y':L`lag'.`xname'
			}
		}
		local newnames `newnames' `newname'	
	}	
		matrix colnames `hilites_b' = `newnames'
		matrix rownames `hilites_b' = `y'
		matrix rownames `hilites_v' = `newnames'
		matrix colnames `hilites_v' = `newnames'
	}
	ereturn matrix hilites_b =  `hilites_b', copy
	ereturn matrix hilites_v = `hilites_v', copy

	
	local N = e(N)
	local converged = e(converged)
	local chi2_ms = e(chi2_ms)
	local df_ms = e(df_ms)
	local p_ms = e(p_ms)

	// Temporarily create new e(b), e(V)
	tempname results
	_estimates hold `results', restore
	ereturn post `hilites_b' `hilites_v', 
	quietly test [#1]
	if `free' != 0 {
		forval eqnum = 2/`Nperiods' {
			quietly test [#`eqnum'], a
		}
	}
	local chi2 = r(chi2)
	local df = r(df)
	local p = r(p)

	// Some display options work for sem but not hilites, so
	// delete them
	local illegaloptions nocnsreport
	local diopts: list diopts - illegaloptions

	// Display results
	display ""
	display as result "Highlights: `title'"

	ereturn display, `diopts'
	di "# of units = `N'. # of periods = `T'. " ///
		"First dependent variable is from period `Tstart'."
	if `chi2_ms' != . {
		di "LR test of model vs. saturated: " ///
			"chi2(`df_ms')  = " %10.2f `chi2_ms' ", Prob > chi2 = " %7.4f `p_ms'
	}
	di "Wald test of all coeff = 0: " ///
		"chi2(`df') = " %10.2f `chi2' ", Prob > chi2 = " %7.4f `p'
	if `converged' != 1 di as error "Warning: Convergence not achieved"

	// Restore original e(b), e(V), and add Gamma values
	_estimates unhold `results'

end

*********************************************************************************

/// Copied and modified from UCLA's stata2mplus program. Written by Michael 
/// Mitchell and adapted with permission.
program define xstata2mplus
  version 7
  syntax [varlist] using/ , [ MIssing(int -9999) use(varlist) Replace /// 
  	OUTput(string) Analysis(string) LISTWise TItle(string) ]

  preserve 
  
  * use "`using'" , `clear'

  if ("`varlist'" != "") {
    keep `varlist'
  }

  if ("`varlist'" == "") {
    unab varlist : *
  }

  * convert char to numeric
  foreach var of local varlist {
    local vartype : type `var' 
    if (substr("`vartype'",1,3)=="str") {
      display "encoding `var'"
      tempvar tempenc
      encode `var', generate(`tempenc')
      drop `var'
      rename `tempenc' `var'
    }
  }

  foreach var of local varlist {
    quietly replace `var' = `missing' if `var' >= .
  }

  outsheet using `"`using'.dat"' , comma nonames nolabel `replace'

  tempvar out
  capture file close `out'

  quietly file open `out' using `"`using'.inp"', write text `replace'

  file write `out' "Title: " _n

  file write `out' "  `title'" _n
  
  file write `out' "Data:" _n
  file write `out' "  File is `using'.dat ;" _n
  if "`listwise'" == "" {
  	file write `out' "  Listwise = OFF ;" _n
  }
  else {
    	file write `out' "  Listwise = ON ;" _n
    }

  	

  file write `out' "Variable:" _n 
  file write `out' "  Names are " _n "    " 
  local len = 0
  unab varlist : *
  foreach varname of local varlist {
    if `len' > 60 {
      file write `out' _n "    " 
      local len = 0
    }
    local len = `len' + length(" `varname'") 
    file write `out' " `varname'" 
  }
  file write `out' ";" _n
  

  file write `out' "  Missing are all (`missing') ; " _n

  if "`use'" != "" {
    file write `out' "  Usevariables are" _n "    "
    local len = 0
    unab usevarlist : `use'
    foreach varname of local usevarlist {
      if `len' > 60 {
        file write `out' _n "    " 
        local len = 0
      }
      local len = `len' + length(" `varname'") 
      file write `out' " `varname'" 
    }
    file write `out' ";" _n
  }
  
	// Analysis options
	if "`analysis'" == "" {
		file write `out' "Analysis:" _n
		file write `out' "     Iterations = 1000;" _n
		file write `out' "     Estimator = ML;" _n
	}
	else {
		file write `out' "Analysis:" _n
		while "`analysis'" != "" {
			gettoken aoption analysis: analysis, parse(";")
			if "`aoption'" !=";" {
				file write `out' "     `aoption';" _n
			}
		}	
	}


	// Output options
	if "`output'" == "" {
		file write `out' "Output:" _n
	}
	else {
		file write `out' "Output:" _n
		while "`output'" != "" {
			gettoken outoption output: output, parse(";")
			if "`outoption'" !=";" {
				file write `out' "     `outoption';" _n
			}
		}	
	}

	
	// Begin model command
	file write `out' "Model:" _n

  file close `out'



  restore

end

  
