*! mim.ado v1.1.1 (JCG, JBC, PR)
* Note: read MIM Tools ado files with tab set equal to 6 spaces
* History
*   v1.1.1	- (JBC) changed nolrr option to lrr, so default does not use this; 
*		  made behaviour of -storebv- option consistent with this
*   v1.1.0	- Added rubin subcommand
*		- bug fix: made display of results default to using LRR covariance matrix and
*		  added undocumented nolrr option
*   v1.0.3	- (03aug2007) Removed seed option from -mim fit-
*   v1.0.2	- (27jul2007) Mark Lunt speed improvements to prediction
*   v1.0.1	- bug fix: fixed "ereturn local depvar" statement in case j>0 of fit_handlebv routine
*		- bug fix: replaced use of `from' with `first' in fit routine when capturing e() scalars and macros
*		- added undocumented noclear option to allow suppression of mim issuing -ereturn clear-
*		- changed method of replay of individual estimates to trying `cmd' first, and if this fails
*		  then using the generic -ereturn display- routines
*		- restricted use of storebv option to apply only when fitting/replaying combined estimates
*		  (previously this option would have been ignored when replaying individual estimates)
program define mim
	version 9
	set more off

	// FIRST CHECK FOR REPLAY OF LAST ESTIMATES
	capture _on_colon_parse `0'					// split command line at first colon
	local mimcmdline `"`s(before)'"'
	local statacmd `"`s(after)'"'
	if ( c(rc) | `"`s(after)'"' == "" ) {			// if no colon in cmd line, or no cmd after colon
		if ( `"`e(MIM_prefix2)'"' != "mim" ) error 301	// if last mim estimates not found
		local cmd `"`e(MIM_cmd)'"'
		local inbV `"`e(MIM_inbV)'"'				// -1 == none, 0 == combined, >1 == indivdual

		syntax [, ///
				j(integer -2) 	/// User must specify j>=1 to replay estimates for individual dataset
				STorebv 	/// MI estimates are placed in e(b), e(V); not valid with j option 
				CLearbv 	/// MI estimates are cleared from e(b), e(V); not valid with j option
				NOClear		/// Undocumented; instructs mim not to clear existing e() values prior
						/// to reposting e(b), e(V) etc. Not valid with clearbv option.
				LRR		/// Undocumented; instructs mim to use LRR method for constructing
						/// var/covar matrix
				* 		/// This is for reporting options
		]

		if ( `j' != -2 & `j' < 1 ) {
			display as error "j option must be positive"
			exit 198
		}
		if ( `"`noclear'"' != "" & `"`clearbv'"' != "" ) {
			display as error "noclear and clearbv options may not be combined"
			exit 198
		}
		if ( `"`clearbv'"' != "" & `"`storebv'"' != "" ) {
			display as error "clearbv and storebv options may not be combined"
			exit 198
		}
		if ( `"`clearbv'"' != "" & `j' >= 1 ) {
			display as error "clearbv and j options may not be combined"
			exit 198
		}
		if ( `"`storebv'"' != "" & `j' >= 1 ) {
			display as error "storebv and j options may not be combined"
			exit 198
		}
		if ( `"`clearbv'"' != "" ) local j = -1
		if ( `"`storebv'"' != "" ) local j = 0
		if ( "`lrr'" != "" ) local lrr "lrr"

		parsereportopts, cmd(`cmd') `options'
		local eformstr `"`s(eformstr)'"'
		local eformopt `"eformopt(`s(eformopt)')"'
		local level `"`s(level)'"'
		local options `"`s(options)'"'
		if ( `"`options'"' != "" ) {
			display as error `"`options' not allowed"'
			exit 198
		}

		// reshuffle mim results in e(), if necessary
		if ( `j' > -2 & (`j' != `inbV') ) {
			fit_handlebV, j(`j') `noclear'
			local inbV = `j'
		}

		// display results
		if ( `inbV' <= 0 ) fit_display, cmd(`cmd') `level' `eformstr' `lrr'
		else fit_display_indiv, j(`inbV') cmd(`cmd') `level' `eformstr' `eformopt'
		exit 0
	}

	// OTHERWISE INTERCEPT PREFIXES LYING BETWEEN MIM AND CMD
	local version "vers versi versio version"
	local allow "svy `version'"
	local disallow "cap capt captu captur capture"	
	local disallow "`disallow' qui quie quiet quietl quietly"
	local disallow "`disallow' n no noi nois noisi noisil noisily"
	local disallow "`disallow' by bys byso bysor bysort bootstrap jacknife jknife"
	local disallow "`disallow' nestreg permute rolling simulate stepwise sw statsby"
	local moreprefs "T"
	while ( "`moreprefs'" == "T" ) {
		gettoken pref rest : statacmd, parse(" :,")
		if ( `"`pref'"' == "xi" ) {
			display as error `"xi not supported after mim; run xi: mim: ... instead"
			exit 198
		}
		local pos : list posof `"`pref'"' in disallow	// check for unsupported prefixes
		if ( `pos' > 0 ) {
			display as error `"prefix `pref' not allowed after mim"'
			exit 198
		}
		local pos : list posof `"`pref'"' in allow	// check for supported prefixes
		if ( `pos' > 0 ) {
			capture _on_colon_parse `statacmd'		// split remaining command line at colon
			local nextpref `"`s(before)'"'
			local statacmd `"`s(after)'"'
			local prefixes `"`prefixes' `nextpref':"'
			if ( `"`pref'"' == "svy" ) local svy "svy"
			else local ver "version"
		}
		else local moreprefs "F"
	}
	local prefixes : list retokenize prefixes

	// THEN DETERMINE THE CATEGORY THAT CMD BELONGS TO
	gettoken cmd cmdl : statacmd, parse(" ,")
	local 0 `"`mimcmdline'"'
	syntax [, CATegory(string) NOIsily * ]
	local cat `"`category'"'
	if ( `"`noisily'"' != "" ) local detail "detail"
	local othermimopts `"`options'"'
	if ( `"`cat'"' != "" ) {
		if ( "`cat'"' != "fit" & `"`cat'"' != "manip" & `"`cat'"' != "desc" ) {
			display as error "invalid category `cat'"
			exit 198
		}
	}
	else {
		local regress "reg regr regre regres regress"
		local logit "logi logit"
		local ologit "olog ologi ologit"
		local mlogit "mlog mlogi mlogit"
		local probit "prob probi probit"
		local oprobit "oprob oprobi oprobit"
		local fitcmds "`regress' `logit' `ologit' `mlogit' `probit' `oprobit'"
		local fitcmds "`fitcmds' mean proportion ratio"
		local fitcmds "`fitcmds' cnreg mvreg rreg"
		local fitcmds "`fitcmds' qreg iqreg sqreg bsqreg"
		local fitcmds "`fitcmds' logistic blogit clogit"
		local fitcmds "`fitcmds' glm binreg nbreg gnbreg poisson"
		local fitcmds "`fitcmds' stcox streg stpm"
		local fitcmds "`fitcmds' xtgee xtreg xtlogit xtnbreg xtpoisson xtmixed"
		local posofcmd : list posof "`cmd'" in fitcmds
		if ( `posofcmd' > 0 ) { // estimation command
			local cat "fit"
			local pos1 : list posof "`cmd'" in regress
			local pos2 : list posof "`cmd'" in logit
			local pos3 : list posof "`cmd'" in ologit
			local pos4 : list posof "`cmd'" in mlogit
			local pos5 : list posof "`cmd'" in probit
			local pos6 : list posof "`cmd'" in oprobit
			if ( `pos1' > 0 ) local cmd "regress"
			if ( `pos2' > 0 ) local cmd "logit"
			if ( `pos3' > 0 ) local cmd "ologit"
			if ( `pos4' > 0 ) local cmd "mlogit"
			if ( `pos5' > 0 ) local cmd "probit"
			if ( `pos6' > 0 ) local cmd "oprobit"
		}
		else if ( /// inbuilt utility command
			`"`cmd'"' == "check" | ///
			`"`cmd'"' == "genmiss" | ///
			`"`cmd'"' == "rubin" ///
		) local cat "util"
		else if ( /// post estimation command
			`"`cmd'"' == "predict" | ///
			`"`cmd'"' == "lincom" | ///
			`"`cmd'"' == "testparm" ///
		) local cat "pe"
		else if ( /// manipulation command
			`"`cmd'"' == "app" | ///
			`"`cmd'"' == "appe" | ///
			`"`cmd'"' == "appen" | ///
			`"`cmd'"' == "append" | ///
			`"`cmd'"' == "mer" | ///
			`"`cmd'"' == "merg" | ///
			`"`cmd'"' == "merge" | ///
			`"`cmd'"' == "reshape" ///
		) local cat "manip"
		else if ( /// descriptive command
			`"`cmd'"' == "ta" | ///
			`"`cmd'"' == "tab" | ///
			`"`cmd'"' == "tabu" | ///
			`"`cmd'"' == "tabul" | ///
			`"`cmd'"' == "tabula" | ///
			`"`cmd'"' == "tabulat" | ///
			`"`cmd'"' == "tabulate" ///
		) local cat "desc"
		else { // unrecognised command
			display as error "command `cmd' not recognised by mim; try specifying category option"
			exit 198
		}
	}

	// BLOCK SVY PREFIX IF COMMAND IS NON-ESTIMATION, AND BLOCK VERSION
	// PREFIX IF COMMAND IS A UTILITY COMMAND OR COMMAND IS TESTPARM
	if ("`svy'" != "" & "`cat'" != "fit" ) {
		display as error "svy prefix not allowed with `cmd'"
		exit 198
	}
	if ( "`ver'" != "" & ("`cat'" == "util" | "`cmd'" == "testparm") ) {
		display as error "version prefix not allowed with `cmd'"
		exit 198
	}

	// PROCESS REMAINING MIM OPTIONS
	if ( `"`othermimopts'"' != "" ) local 0 `", `othermimopts'"'
	else local 0 ""
	if ( `"`cat'"' == "fit" ) {
		local syntaxform "[, Seed(passthru) DOTs noINDividual STorebv NOClear LRR ]"
	}
	else if ( `"`cat'"' == "manip" & `"`cmd'"' != "append" & `"`cmd'"' != "reshape" ) {
		local syntaxform ", SOrtorder(passthru)"
	}
	else local syntaxform "[, _a_very_unlikely_mim_option]" // option improves error message
	syntax `syntaxform'
	if ( "`lrr'" != "" ) local lrr "lrr"

	// EXTRACT REPORTING OPTIONS FROM STATACMD (IF CMD IS A FIT OR POST ESTIMATION COMMAND)
	if ( "`cat'" == "fit" | "`cat'" == "pe" ) {
		gettoken first remaining : cmdl, parse(",")
		local newcmdline `"`first'"'
		while ( `"`remaining'"' != "" ) {
			local newcmdline `"`newcmdline' `next'"'
			gettoken next remaining : remaining, parse(",")
		}
		parsereportopts, cmd(`cmd') `next'
		local eformstr `"`s(eformstr)'"'
		local eformopt `"`s(eformopt)'"'
		local level `"`s(level)'"'
		local options `"`s(options)'"'

		// Remove eform options from cmdline, if necessary
		if ( `"`cmd'"' == "lincom" ) {
			local cmdl `"`newcmdline' `level' `options'"'
		}
	}

	// RUN CMD
	if ( "`cat'" == "util" ) `cmd' `cmdl'
	else if ( "`cat'" == "desc" ) desc, cmd(`"`cmd'"') cmdl(`"`cmdl'"') pr(`"`prefixes'"')
	else if ( "`cat'" == "manip" ) manip, cmd(`"`cmd'"') cmdl(`"`cmdl'"') pr(`"`prefixes'"') `sortorder' `detail'
	else if ( "`cat'" == "fit" ) {
		fit, cmd(`cmd') cmdl(`"`cmdl'"') pr(`"`prefixes'"') `detail' `lrr' `seed' `dots' `individual' `noclear'
		if ( `"`storebv'"' != "" ) fit_handlebV, j(0)		// reshuffle into e(b), e(V)
		fit_display, cmd(`cmd') `level' `eformstr' `lrr'	// display combined estimates
	}
	else if ( "`cat'" == "pe" ) {
		if ( "`e(MIM_prefix2)'" != "mim" ) {
			display as error "last mim estimates not found"
			exit 301
		}
		if ( `"`e(MIM_emacros)'"' == "" ) {
			display as error "individual estimates unavailable; rerun mim without noindividual option"
			exit 498
		}
		if ( "`cmd'" == "lincom" ) milincom, cmdl(`"`cmdl'"') pr(`"`prefixes'"') `detail' `level' `eformopt'
		if ( "`cmd'" == "testparm" ) mitestparm, cmdl(`"`cmdl'"')
		if ( "`cmd'" == "predict" ) mipredict, cmdl(`"`cmdl'"') pr(`"`prefixes'"')
	}

	// AND FINALLY CLEAR ANY S-MACROS SET BY MIM OR ITS SUBCOMMANDS
	sreturn clear
end
*--------------------------------------------------------------------------------------------------------
* subprogram parsereportopts
*--------------------------------------------------------------------------------------------------------
program parsereportopts, sclass

	syntax, cmd(string) [ * ]

	local 0 `", `options'"'
	if ( `"`cmd'"' == "glm" ) local levelform "LEvel(passthru)"
	else if ( `"`cmd'"' == "xtgee" ) local levelform "LEVel(passthru)"
	else local levelform "Level(passthru)"

	if ( `"`cmd'"' == "stcox" | `"`cmd'"' == "streg" ) {
		syntax [, `levelform' EFormstr(string) EForm noHR IRr or RRr rd COEFficients * ]
	}
	else {
		syntax [, `levelform' EFormstr(string) EForm hr IRr or RRr rd COEFficients * ]
	}
	if ( `"`coefficients'"' != "" ) local coef "coef"

	local eformopt `"`efromstr' `eform' `hr' `irr' `or' `rrr' `coef' `nohr'"'
	local wc : word count `eformopt'
	if ( `wc' > 1 ) {
		local eformopts : list retokenize eformopt
		display as error "`eformopts' not allowed together"
		exit 198
	}
	else if ( `"`eformstr'"' != "" ) local eformstr `"eformstr(`eformstr')"'
	else if ( `"`eform'"' != "" ) local eformstr `"eformstr("    exp(b)")"'
	else if ( `"`irr'"' != "" ) local eformstr `"eformstr("       IRR")"'
	else if ( `"`rrr'"' != "" ) local eformstr `"eformstr("       RRR")"'
	else if ( `"`rd'"' != "" )  local eformstr `"eformstr(" Risk Dif.")"'
	else if ( `"`hr'"' == "hr" & `"`cmd'"' == "binreg" ) ///
		local eformstr `"eformstr("        HR")"'
	else if ( `"`hr'"' == "hr" | ( (`"`cmd'"' == "stcox" | `"`cmd'"' == "streg") & `"`hr'"' != "nohr" ) ) ///
		local eformstr `"eformstr(" Haz. Rat.")"'
	else if ( `"`or'"' != "" | ( `"`cmd'"' == "logistic" & `"`coef'"' == "" ) ) ///
		local eformstr `"eformstr(" Odds Rat.")"'
	else if ( `"`coef'"' != "" ) local eformstr

	sreturn local level `"`level'"'
	sreturn local eformopt `"`eformopt'"'
	sreturn local eformstr `"`eformstr'"'
	sreturn local options `"`options'"'
end
*--------------------------------------------------------------------------------------------------------
* subprogram chkvars
*--------------------------------------------------------------------------------------------------------
program chkvars
	capture confirm numeric variable _mj
	if c(rc) {
		display as error "imputation identifier variable _mj is either missing or not numeric"
		exit 498
	}
	capture confirm numeric variable _mi
	if c(rc) {
		display as error "observation identifier variable _mi is either missing or not numeric"
		exit 498
	}
end
*--------------------------------------------------------------------------------------------------------
* subprogram check
*--------------------------------------------------------------------------------------------------------
program check
	version 9

	chkvars

	syntax [varlist]

	tempvar t1 t2
	foreach var of varlist `varlist' {
		local ffive = substr(`"`var'"',1,5)
		if ( `"`var'"' != "_mi" & `"`var'"' != "_mj" & `"`ffive'"' != "_mim_" ) {
			display as text "." _cont
			capture drop _mim_`var'
			capture genmiss `var'
			if c(rc) {
				display // carriage return
				genmiss `var'
			}
			capture drop `t1'
			rename _mim_`var' `t1'
			sort _mi _mj
			capture drop `t2'
			generate byte `t2' = 0
			quietly replace `t2' = ( `var'[_n-1] != `var'[_n] ) if _mj != 0
			capture assert ( `t2' == 0 | `t1' == 1 )
			if c(rc) {
				display as error _n "non-imputed values in `var' differ across imputed datasets"
				exit 498
			}
		}
	}
	sort _mj _mi
	display as text _n "PASS"
end
*--------------------------------------------------------------------------------------------------------
* subprogram genmiss
*--------------------------------------------------------------------------------------------------------
program define genmiss
	version 9

	syntax varname
	local var "`varlist'"

	// CHECK ID VARS AND EXISTENCE OF ORIGINAL DATA
	chkvars
	quietly levelsof _mj, local(levels)
	local pos : list posof "0" in levels
	if ( `pos' == 0 ) {
		display as error "the current mim dataset does not contain the original data with missing values"
		exit 498
	}

	// CHECK THAT SPECIFIED VAR IS NOT COMPLETE
	quietly count if `var' >= .
	if ( r(N) == 0 ) {
		display as text "(`var' has no missing values)"
		quietly generate byte _mim_`var' = 0
		exit 0
	}
	
	// GENERATE MISSING INDICATOR VARIABLE
	tempvar tvar
	sort _mi
	quietly by _mi : egen `tvar' = count(`var')
	sort _mj _mi
	quietly levelsof `tvar', local(levels)
	local wc : word count `levels'
	local min : word 1 of `levels'
	if ( `wc' == 2 ) {
		local max : word 2 of `levels'
		capture assert `max' - `min' == 1
		if c(rc) local err "error"
	}
	else local err "error"
	if ( "`err'" != "" ) {
		display as error "there is a problem with your mim dataset; possible causes are "
		display as error " - imputed copies of `var' still contain missing values"
		display as error " - imputed datasets contain differing numbers of observations"
		exit 498
	}
	quietly replace `tvar' = 1 if `tvar' == `min'
	quietly replace `tvar' = 0 if `tvar' == `max'
	recast byte `tvar'
	capture drop _mim_`var'
	rename `tvar' _mim_`var'
end
*--------------------------------------------------------------------------------------------------------
* subprogram desc
*--------------------------------------------------------------------------------------------------------
program define desc
	version 9

	syntax, ///
		CMD1(string)	/// descriptive command to apply
		[ ///
		CMDLine(string)	/// contents of command line following `cmd1'
		PRefixes(string)	/// contents of command line between mim: and `cmd1'
		]

	// CHECK ID VARS
	chkvars
	quietly levelsof _mj, local(levels)

	// CHECK SYNTAX OF STATA COMMAND, AND EXTRACT USING FILENAME
	local 0 `"`cmdline'"'
	capture syntax [anything(equalok)] [if/] [in] [fw aw pw iw] [, *]
	if c(rc) {
		display as error "unsupported command syntax"
		exit 198
	}
	if ( `"`if'"' != "" ) local andif "& `if'"
	if ( `"`weight'"' != "" ) local weight `"[`weight' `exp']"'
	if ( `"`options'"' != "" ) local cmdopts `", `options'"'

	// APPLY CMD TO INDIVIDUAL DATASETS
	local remaining "`levels'"
	while ( "`remaining'" != "" ) {
		gettoken j remaining : remaining

		// DO CMD
		local docmd `"`prefixes' `cmd1' `anything' if _mj==`j' `andif' `in' `weight' `cmdopts'"'
		local docmd : list retokenize docmd
		display as input `"-> `docmd'"'
		`docmd'
		display _n
	}
end
*--------------------------------------------------------------------------------------------------------
* subprogram manip
*--------------------------------------------------------------------------------------------------------
program define manip
	version 9

	syntax, ///
		CMD1(string)	/// manipulation command to apply
		[ ///
		CMDLine(string)	/// contents of command line following cmd
		PRefixes(string)	/// contents of command line between mim: and cmd
		Detail		/// display output of cmd at each iteration
		SOrtorder(string)	/// variables that uniquely identify the observations in
					/// each dataset POST manipulation of the mim dataset(s)
		]

	if ( "`detail'" != "" ) local noisily "noisily"

	// CHECK ID VARS
	chkvars
	quietly levelsof _mj, local(levels)
	local m : word count `levels'

	// CHECK SYNTAX OF STATA COMMAND, AND EXTRACT USING FILENAME
	local 0 `"`cmdline'"'
	capture noisily syntax [anything(equalok)] [if] [in] [fw aw pw iw] [using/] [, *]
	if c(rc) {
		display as error "possibly unsupported manipulation command syntax"
		exit 198
	}
	if ( `"`weight'"' != "" ) local weight `"[`weight' `exp']"'
	if ( `"`using'"' != "" ) local mimusing `"`using'"'
	if ( `"`options'"' != "" ) local cmdopts `", `options'"'
	local cmdline `"`anything' `if' `in' `weight'"'

	// TEMPORARILY SAVE CURRENT DATASET, SO THAT INDIVIDUAL DATASETS CAN BE LOADED ONE AT A TIME
	tempfile mimmaster
	quietly save `mimmaster'

	// RATHER THAN PRESERVING CURRENT DATASET, MASTER WILL BE RELOADED MANUALLY If ERROR OCCURS
	capture noisily {

	// APPLY CMD TO INDIVIDUAL DATASETS
	gettoken cmd2 cmdline : cmdline, parse(" ,:")		// extract 2nd token for display purposes
	local cmd = trim("`cmd1' `cmd2'")				// eg. "reshape wide"
	local remaining "`levels'"
	while ( "`remaining'" != "" ) {
		gettoken j remaining : remaining

		// DECLARE NEXT TEMPORARY FILE AND EXTRACT NEXT USING DATASET, IF NECESSARY
		tempfile tfile`j'
		if ( `j' == 0 ) {
			local dfile `"`tfile`j''"'
			local m = `m' - 1
		}
		else local ifiles `"`ifiles' `tfile`j''"'
		local N2 = -1
		if ( `"`mimusing'"' != "" ) {
			quietly use _all if _mj == `j' using `mimusing'
			quietly count
			local N2 = r(N)
			if ( `"`cmd1'"' == "merge"  & `"`anything'"' != "" ) quietly sort `anything'
			else quietly sort _mi
			quietly drop _mj _mi
			quietly save `tfile`j''
			local using `"using `tfile`j''"'
		}
		local usingdisplay "using _mj == `j'"

		// EXTRACT NEXT MASTER DATASET
		quietly use _all if _mj == `j' using `mimmaster'
		quietly count
		local N1 = r(N)
		if ( `"`cmd1'"' == "merge"  & `"`anything'"' != "" ) quietly sort `anything'
		else quietly sort _mi
		quietly drop _mj _mi

		// DO CMD
		local statacmdtodisplay `"`prefixes' `cmd' `cmdline' `usingdisplay' `cmdopts'"'
		local statacmdtodisplay : list retokenize statacmdtodisplay
		capture `noisily' display as input `"-> `statacmdtodisplay'"'
		if ( `N1' == 0 ) display as error "(warning, master dataset has no observations for _mj == `j')"
		if ( `N2' == 0 ) display as error "(warning, using dataset has no observations for _mj == `j')"
		local statacmd `"`prefixes' `cmd' `cmdline' `using' `cmdopts'"'
		capture `noisily' `statacmd'
		if c(rc) {
			local rc = c(rc)
			if ( "`noisily'" == "" ) {
				display as input `"-> `statacmdtodisplay'"'
				capture noisily `statacmd'
			}
			exit `rc'
		}
		capture `noisily' display _n

		if ( `"`cmd1'"' == "append" | `"`estimates'"' != "" ) {
			quietly generate byte _mi = .
			quietly replace _mi = _n
		}

		// TEMPORARILY SAVE RESULT
		quietly save `tfile`j'', replace
	}

	// STACK THE RESULTING TEMPORARY DATASETS INTO A NEW MIM DATASET
	if ( `"`cmd'"' == "append" | `"`estimates'"' != "" ) local sortorder "_mi"
	if ( `"`cmd'"' == "reshape long" ) local sortorder `"`_dta[ReS_i]' `_dta[ReS_j]'"'
	if ( `"`cmd'"' == "reshape wide" ) local sortorder `"`_dta[ReS_i]'"'
	if ( `"`dfile'"' != "" ) {
		local ifiles `"`dfile' `ifiles'"'
		local nomj0 ""
	}
	else local nomj0 "nomj0"
	mimstack, m(`m') `nomj0' ifiles(`"`ifiles'"') sortorder(`"`sortorder'"')

	} // END OF CAPTURE NOISILY
	if c(rc) {
		local rc = c(rc)
		quietly use `"`mimmaster'"', clear 
		exit `rc'
	}
end
*--------------------------------------------------------------------------------------------------------
* subprogram fit, eclass
*--------------------------------------------------------------------------------------------------------
program define fit, eclass
	version 9

	syntax, ///
		CMD1(string)		/// estimation command to fit
		[ ///
		CMDLine(string)		/// contents of command line following cmd
		PRefixes(string)		/// prefixes between mim: and cmd
		LRR			/// instructs mim to use LRR method for constructing var/covar matrix
		FRom(integer 1)		/// fit from _mj == `from'
		to(integer 9999999)	/// fit to _mj == `to'
		Detail			/// display estimates from individual models
		DOTs				/// display dots during execution
		noINDividual		/// do not capture e(b), e(V) etc. from individual models
		NOClear			/// suppresses issue of ereturn clear
		]

	if ( `from' <= 0 | `to' <= 0 ) {
		display as error "from and to options must both be positive"
		exit 198
	}
	if ( "`detail'" != "" ) local noisily "noisily"
	if ( "`dots'" == "" ) local nodots "nodots"
	if ( "`individual'" != "" ) local noindividual "noindividual"
	local cmd `"`cmd1'"'

	// CHECK ID VARS, AND DETERMINE LEVELS TO FIT
	chkvars
	quietly levelsof _mj, local(temp)
	while ( `"`temp'"' != "" ) {
		gettoken next temp : temp
		if ( `next' >= `from' & `next' <= `to' ) local levels "`levels' `next'"
		if ( `next' >= `to' ) continue, break
	}
	local m : word count `levels'
	if ( `m' <= 1 ) {
		if ( `m' == 0 ) local s "s"
		if ( `to' != 9999999 ) local inrange `"in the range _mj = `from' to _mj = `to'"'
		display as error `"fitting a model to a mim dataset requires at least 2 imputations"'
		display as error `"your dataset has `m' imputation`s' `inrange'"'
		exit 198
	}

	// TEMPORARILY SAVE CURRENT DATASET, SO THAT INDIVIDUAL DATASETS CAN BE LOADED ONE AT A TIME
	sort _mj _mi
	tempfile mimmaster
	quietly save `mimmaster'

	// RATHER THAN PRESERVING CURRENT DATASET, MASTER WILL BE RELOADED MANUALLY AT THE END
	capture noisily {

	// FIT INDIVIDUAL MODELS
	tempname S
	gettoken first : levels
	local remaining `"`levels'"'
	while ( "`remaining'" != "" ) {
		gettoken j remaining : remaining
		quietly use _all if _mj == `j' using `mimmaster', clear
		if ( `"`detail'"' == "" & "`nodots'" == "" ) {
			display as input "." _cont
			local cr "_n"
		}
		local estcmd `"`prefixes' `cmd1' `cmdline'"'
		local estcmd : list retokenize estcmd
		capture `noisily' display as input "-> _mj==`j'"
		capture `noisily' display as input "-> `estcmd'"
		capture `noisily' `estcmd'
		if c(rc) {
			local rc = c(rc)
			if ( "`noisily'" == "" ) {
				display as input `cr' `"-> _mj==`j'"'
				display as input `"-> `estcmd'"'
				capture noisily `estcmd'
			}
			exit `rc'
		}
		capture `noisily' display _n

		// Capture data for combined results
		tempfile tfile`j'
		tempname b`j'
		matrix `b`j'' = e(b)
		local colnames : colnames `b`j''
		local eb `"`eb' `b`j''"'		// list of names of matrices containing the e(b)'s
		local N = e(N)
		if ( `j' == `first' ) {
			local firstcolnames `"`colnames'"'
			matrix `S' = e(V)
			local Nmin = `N'
			local Nmax = `N'
			local prefix "`e(prefix)'"
			local depvar "`e(depvar)'"
			local properties "`e(properties)'"
			local title "`e(title)'"
			local eform "`e(eform)'"
			local nucom "`e(df_r)'"		// complete-data residual degrees of freedom
			if ( `"`nucom'"' == "" ) local nucom = 1000
		}
		else {
			local test : list colnames == firstcolnames
			if ( `test' == 0 ) {
				display as error `"covariates in analysis of imputed dataset `j' do not match those of imputed dataset `first'"'
				exit 498
			}
			matrix `S' = `S' + e(V)
			if ( `Nmin' > `N' ) local Nmin = `N'
			if ( `Nmax' < `N' ) local Nmax = `N'
		}

		// Capture individual estimates, if necessary
		if ( "`noindividual'" == "" ) {
			if ( `j' == `first' ) {
				local escalars : e(scalars)
				local ematrices : e(matrices)
				local emacros : e(macros)
			}
			foreach scal of local escalars {
				tempname MIM_`j'_`scal'
				// JCG 14jun2006: changed `from' to `first' below
				if ( `j' == `first' ) scalar `MIM_`j'_`scal'' = e(`scal')
				else if ( e(`scal') != `MIM_`first'_`scal'' ) scalar `MIM_`j'_`scal'' = e(`scal')
			}
			foreach mat of local ematrices {
				tempname MIM_`j'_`mat'
				matrix `MIM_`j'_`mat'' = e(`mat')
			}
			foreach mac of local emacros {
				// JCG 14jun2006: changed `from' to `first' below
				if ( `j' == `first' ) local MIM_`j'_`mac' `"`e(`mac')'"'
				else if ( `"`e(`mac')'"' != `"`MIM_`first'_`mac''"' ) local MIM_`j'_`mac' `"`e(`mac')'"'
			}
		}

		// Capture changes to this dataset by the estimation cmd, and generate _mim_e
		capture drop _mim_e
		quietly generate byte _mim_e = e(sample)
		quietly save `tfile`j'', replace
	}
	// Add changes to fitted datasets back to original MIM dataset
	local remaining `"`levels'"'
	gettoken j remaining : remaining
	quietly use `tfile`j'', clear
	while ( `"`remaining'"' != "" ) {
		gettoken j remaining : remaining
		quietly append using `tfile`j''
	}
	sort _mj _mi
	capture drop _merge
	quietly merge _mj _mi using `mimmaster'
	quietly drop _merge
	sort _mj _mi
	label variable _mim_e "MIM Tools variable : estimation subsample indicator"

	// CALCULATE COMBINED ESTIMATES
	tempname Q W B T dfvec dfmin dfmax TLRR r nu lambda r1 nu1
	fit_combine, i(`"`eb'"') s(`S') b(`B') t(`T') q(`Q') w(`W') df(`dfvec') min(`dfmin') max(`dfmax') ///
		tlrr(`TLRR') r(`r') nu(`nu') l(`lambda') r1(`r1') nu1(`nu1') nucom(`nucom')

	// RETURN RESULTS
	if ( "`noclear'" == "" ) ereturn clear

	// individual results
	if ( "`noindividual'" == "" ) {
		forvalues i = `m'(-1)1 {
			local j : word `i' of `levels'
			foreach scal of local escalars {
				capture confirm scalar `MIM_`j'_`scal''
				if !c(rc) ereturn scalar MIM_`j'_`scal' = `MIM_`j'_`scal''
			}
			foreach mat of local ematrices {
				ereturn matrix MIM_`j'_`mat' = `MIM_`j'_`mat''
			}
			foreach mac of local emacros {
				ereturn local MIM_`j'_`mac' `"`MIM_`j'_`mac''"'
			}
		}
	}

	// combined results
	local inbV = -1
	local prefix2 "mim"
	local cscalars "r1 nu1 Nmin Nmax dfmin dfmax"
	local cmatrices "lambda nu r TLRR dfvec Q W B T"
	local cmacros "inbV m levels eform title properties depvar prefix2 prefix cmd"
	foreach scal of local cscalars {
		ereturn scalar MIM_`scal' = ``scal''
	}
	foreach mat of local cmatrices {
		ereturn matrix MIM_`mat' = ``mat'', copy
	}
	if ( `"`lrr'"' != "" ) {
			ereturn matrix MIM_V = `TLRR'
		}
		else {
			ereturn matrix MIM_V = `T'
	}
	local cmatrices "`cmatrices' V"
	ereturn local MIM_cscalars `"`cscalars'"'
	ereturn local MIM_cmatrices `"`cmatrices'"'
	ereturn local MIM_cmacros `"`cmacros'"'
	ereturn local MIM_escalars `"`escalars'"'
	ereturn local MIM_ematrices `"`ematrices'"'
	ereturn local MIM_emacros `"`emacros'"'
	foreach mac of local cmacros {
		ereturn local MIM_`mac' `"``mac''"'
	}

	} // END OF CAPTURE NOISILY
	if c(rc) {
		local rc = c(rc)
		quietly use `"`mimmaster'"', clear
	}
	exit `rc'
end
*--------------------------------------------------------------------------------------------------------
* subprogram fit_combine
* Calculates combined estimates and degrees of freedom.
*--------------------------------------------------------------------------------------------------------
program define fit_combine

	syntax, ///
		Indivs(string)	/// list of names of matrices containing the e(b)'s
		Sumofv(string)	/// name of matrix containing the sum of the e(V)'s
		q(string)		/// name of matrix to contain average of the e(b)'s 
		w(string)		/// name of matrix to contain average of the e(V)'s
		t(string)		/// name of matrix to contain total covariance estimate
		b(string)		/// name of matrix to contain between imputation covariance estimate
		DFvec(string)	/// name of matrix to contain estimated degrees of freedom
		min(string)		/// name of scalar to contain minimum of dfvec
		max(string)		/// name of scalar to contain maximum of dfvec
		tlrr(string)	/// name of matrix to contain LRR total covariance estimate
		r(string)		/// name of matrix to contain r
		nu(string)		/// name of matrix to contain nu
		Lambda(string)	/// name of matrix to contain lambda
		r1(string)		/// name of scalar to contain r1
		nu1(string)		/// name of scalar to contain nu1
		[ nucom(integer 1000) ]

	local m : word count `indivs'

	// sum e(b)'s
	gettoken _b remaining : indivs
	matrix `q' = `_b'
	while ( `"`remaining'"' != "" ) {
		gettoken _b remaining : remaining
		matrix `q' = `q' + `_b'
	}

	// calc combined estimates
	tempname QQ
	matrix `q' = `q'/`m'
	matrix `w' = `sumofv'/`m'
	local p = colsof(`q')
	matrix `b' = J(`p',`p',0)
	local remaining `"`indivs'"'
	gettoken first : indivs
	while ( `"`remaining'"' != "" ) {
		gettoken _b remaining : remaining
		matrix `QQ' = `_b' - `q'
		if ( "`_b'" == "`first'" ) {
			matrix `b' = `QQ''*`QQ'
			local cols : colnames `_b'
			local eqns : coleq `_b'
		}
		else matrix `b' = `b' + `QQ''*`QQ'
	}
	matrix `b' = `b'/(`m'-1)
	matrix `t' = `w' + (1 + 1/`m') * `b'

	// calc degrees of freedom
	* Next few lines assign quantities for d.f. from Barnard & Rubin 1999 B'ka 86(4): 948-955.
	tempname t1 num nuobs gamma df
	scalar `min' = .
	scalar `max' = .
	matrix `dfvec' = J(1,`p',0)
	matrix `num' = J(1,`p',0)
	matrix `nuobs' = J(1,`p',0)
	matrix `gamma' = J(1,`p',0)
	forvalues i=1/`p' {
		scalar `t1' = `b'[`i',`i']			// i-th between-imputation variance
		if ( `t1' <= 0 ) scalar `t1' = 0.000001		// `t1' could be zero
		matrix `gamma'[1,`i'] = (1+1/`m')*`t1'/`t'[`i',`i']
		matrix `nuobs'[1,`i'] = ((`nucom'+1)/(`nucom'+3))*`nucom'*(1-`gamma'[1,`i'])
		matrix `num'[1,`i'] = (`m'-1)*`gamma'[1,`i']^-2
		scalar `df' = 1/((1/`num'[1,`i']+1/`nuobs'[1,`i']))
		if ( `df' >= 1000 ) scalar `df' = 1000		// upper limit on degrees of freedom
		matrix `dfvec'[1,`i'] = `df'
		if ( `min' > `df' | `min' == . ) scalar `min' = `df'
		if ( `max' < `df' | `max' == . ) scalar `max' = `df'
	}

	// calculate additional quantities for consistency with micombine
	matrix `r' = J(1,`p',0)
	matrix `lambda' = J(1,`p',0)
	matrix `nu' = J(1,`p',0)
	forvalues j=1/`p' {
		matrix `r'[1,`j'] = (1+1/`m')*`b'[`j',`j']/`w'[`j',`j']
		matrix `nu'[1,`j'] = (`m'-1)*(1+1/`r'[1,`j'])^2
		matrix `lambda'[1,`j'] = (`r'[1,`j']+2/(`nu'[1,`j']+3))/(`r'[1,`j']+1)
	}
	matrix colnames `r' = `names'
	matrix colnames `nu' = `names'
	matrix colnames `lambda' = `names'
	* Li, Raghunathan & Rubin (1991) estimates of T and nu1
	* for F test of all params=0 on k,nu1 degrees of freedom
	tempname tscal BU
	matrix `BU' = `b'*syminv(`w')
	scalar `r1' = trace(`BU')*(1+1/`m')/`p'
	matrix `tlrr' = `w'*(1+`r1')
	scalar `tscal'= `p'*(`m'-1)
	scalar `nu1' = cond( ///
		`tscal'>4, 4+(`tscal'-4)*(1+(1-2/`tscal')/`r1')^2, ///
		0.5*`tscal'*(1+1/`p')*(1+1/`r1')^2 ///
	)

	// set matrix row and column names	
	matrix colnames `q' = `colnames'
	matrix rownames `t' = `colnames'
	matrix colnames `t' = `colnames'
	matrix rownames `b' = `colnames'
	matrix colnames `b' = `colnames'
	matrix rownames `w' = `colnames'
	matrix colnames `w' = `colnames'
	matrix rownames `tlrr' = `colnames'
	matrix colnames `tlrr' = `colnames'
	matrix coleq `q' = `coleqns'
	matrix roweq `t' = `coleqns'
	matrix coleq `t' = `coleqns'
	matrix roweq `b' = `coleqns'
	matrix coleq `b' = `coleqns'
	matrix roweq `w' = `coleqns'
	matrix coleq `w' = `coleqns'
	matrix roweq `tlrr' = `coleqns'
	matrix coleq `tlrr' = `coleqns'
end
*--------------------------------------------------------------------------------------------------------
* subprogram fit_display_indiv
* This utility program displays the coefficient table when replaying individual estimates with mim.
*--------------------------------------------------------------------------------------------------------
program define fit_display_indiv
	version 9

	syntax, j(integer) CMD(string) [ level(passthru) eformstr(string) eformopt(string) ]

	if ( `j' <= 0 ) {
		display as error "j option must be positive"
		exit 198
	}
	local cmdstr `"`cmd'"'
	if ( `"`e(MIM_1_prefix)'"' != "" ) local cmdstr `"`e(MIM_1_prefix)': `cmdstr'"'
	local cmdstr = substr( `"`cmdstr'"', 1, 20 )
	if ( `"`eformstr'"' != "" ) local eformstr `"eform(`eformstr')"'
	if ( `"`level'"' != "" | `"`eformstr'"' != "" | `"`eformopt'"' != "" ) local comma ","

	display as text _n "Estimates (" as result `"`cmdstr'"' as text ") " _cont
	display as text "for imputed dataset _mj = " as result `j'
	capture `cmd' `comma' `level' `eformopt'
	if ( _rc == 0 ) `cmd' `comma' `level' `eformopt'
	else {
		_coef_table_header
		_coef_table `comma' `level' `eformstr'
	}
	display _n
end
*--------------------------------------------------------------------------------------------------------
* subprogram fit_display
* This utility program displays the coefficient table for the combined estimates including the table
* preamble (note that the fit_display_table subprogram is used to display the table itself). The
* program asssumes that the combined estimates are currently in e().
*--------------------------------------------------------------------------------------------------------
program define fit_display
	version 9

	syntax, CMD(string) [ eformstr(string) level(passthru) LRR ]

	if ( `"`eformstr'"' != "" ) {
		local eform "eform"
		local tt `"`eformstr'"'
	}
	else local tt "     Coef."

	tempname Q vars df
	local cmdstr `"`cmd'"'
	if ( `"`e(MIM_prefix)'"' != "" ) local cmdstr `"`e(MIM_prefix)': `cmdstr'"'
	local cmdstr = substr( `"`cmdstr'"', 1, 23 )
	local title `"`e(MIM_title)'"'
	local m = "`e(MIM_m)'"
	local depvar "`e(MIM_depvar)'"
	local Nmin = e(MIM_Nmin)
	local dfmin = e(MIM_dfmin)
	if ( `"`lrr'"' != "" ) {
		matrix `vars' = vecdiag( e(MIM_TLRR) )
		local lrrstr "Using Li-Raghunathan-Rubin estimate of VCE matrix"
	}
	else {
		matrix `vars' = vecdiag( e(MIM_T) )
		*local lrrstr "Using standard Rubin estimate of VCE matrix"
	}
	matrix `Q' = e(MIM_Q)
	matrix `df' = e(MIM_dfvec)

	// DISPLAY HEADER
	display ///
	   as text _n "Multiple-imputation estimates (" as result `"`cmdstr'"' as text ")" ///
	  _col(58) as text "Imputations = " as result %7.0g `m'
	display ///
	  as text `"`title'"' ///
	  _col(58) as text "Minimum obs = " as result %7.0g `Nmin'
	display ///
	  as text `"`lrrstr'"' ///
	  _col(58) as text "Minimum dof = " as result %7.1f `dfmin' _n

	// DISPLAY COEFFICIENT TABLE
	fit_display_table, cmd(`cmd') q(`Q') vars(`vars') dof(`df') tt(`tt') ///
	  depvar(`depvar') `level' `eform' `multi'
end
*--------------------------------------------------------------------------------------------------------
* subprogram fit_display_table
* This utility program provides an ereturn display function for combined estimation results. The names
* for the matrices containing the vector of point estimates, variances and dof are passed in the q, vars
* and dof options. The name of the estimation command used by fit is passed in the cmd1 option, with
* the corresponding depvar name in the depvar option. The level option works in the usual way, and the
* eform option selects exponentiated coefficients. The title to use for the coefficient column is passed
* in the tt option, and the multi option selects multiple equation model display.
*--------------------------------------------------------------------------------------------------------
program define fit_display_table
	version 9

	syntax, ///
		CMD1(string)			///
		q(string)				///
		vars(string)			///
		dof(string)				///
		tt(string)				/// title for coefficient column
		[ ///
		depvar(string)			/// some Stata 9 commands (eg. proportion) do not return this
		Level(integer `c(level)')	///
		eform					///
		multi					/// use multiple equation display mode
		]

	if ( `level'<10 | `level'>99 ) {
		display as error "level must be between 10 and 99 inclusive"
		exit 198
	}

	// DISPLAY COEFFICIENT TABLE HEADER
	local t0 = abbrev("`depvar'",12)
	display as text "{hline 13}{c TT}{hline 64}"
	#delimit ;
	display as text
	%12s "`t0'" _col(14)"{c |}" %10s "`tt'" "  Std. Err.     t    P>|t|    [`level'% Conf. Int.]   MI.df"
	_n "{hline 13}{c +}{hline 64}" ;
	#delimit cr

	// CALCULATE AND DISPLAY RESULTS FOR COEFFICIENT TABLE
	tempname df mn se t p invt l u

	// extract display information from matrix of point estimates
	local k = colsof(`q')
	local xs : colnames `q'
	local xeqs : coleq `q'
	local feq : word 1 of `xeqs'					// first equation name

	// check if model has multiple equations			// this does not overide multi option
	forvalues i=1/`k' {
		local eq : word `i' of `xeqs'
		local var : word `i' of `xs'
		if ( `"`eq'"' != `"`feq'"' & `"`var'"' != "_cons" ) local multi "multi"
	}

	// display table
	forvalues i=1/`k' {

		// get next var and eq names
		if ( `i' != 1 ) local lvar `"`var'"'		// previous var name
		else local lvar : word 1 of `xs'
		local var : word `i' of `xs'				// next var name 
		if ( `i' != 1 ) local leq `"`eq'"'			// previous equation name
		else local leq `"`feq'"'
		local eq : word `i' of `xeqs'				// next equation name

		// determine name to display for next var
		if ( `"`multi'"' == "" & `"`eq'"' != `"`leq'"' ) local vname `"/`eq'"'
		else local vname `"`var'"'

		// display row separator, if necessary
		// this occurs upon change of equation name for multiple equation models,
		// and on first change in equation name otherwise
		if ( ///
			( `"`eq'"' != `"`leq'"' & `"`multi'"' != "" ) | ///
			( `"`eq'"' != `"`leq'"' & `"`leq'"' == `"`feq'"' ) ///
		) display as text "{hline 13}{c +}{hline 64}"

		// display equation name, if multiple equation model
		if ( `"`multi'"' != "" & ( `"`eq'"' != `"`leq'"' | `i' == 1 ) ) {
			display as result %-12s `"`eq'"' as text _col(14)"{c |}" 
		}

		// display next coefficient row, if necessary
		// this occurs provided that var is not "_cons", or
		// var is "_cons" but eform is not selected, or
		// var is "_cons" and eform is selected, but model is not multi equation and current eq is not the same as the first
		if ( `"`var'"' != "_cons" | `"`eform'"' == "" | ( `"`multi'"' == "" & `"`eq'"' != `"`feq'"' ) ) {

			// calculate p-value and CI for this coefficient
			scalar `df' =`dof'[1,`i']
			scalar `mn' = `q'[1,`i']
			scalar `se' = sqrt(`vars'[1,`i'])
			scalar `t' = `mn'/`se'
			scalar `p' = 2* ttail(`df', abs(`t'))
			scalar `invt' = invttail(`df', (1-`level'/100)/2)
			scalar `l' = `mn' - `invt'*`se'
			scalar `u' = `mn' + `invt'*`se'

			// transform to exp values, if necessary
			if ( `"`eform'"' != "" ) {
				scalar `mn' = exp(`mn')
				scalar `se' = `mn'*`se'
				scalar `l' = exp(`l')
				scalar `u' = exp(`u')
		 	}

			// sort out display format for coefficient variable type
			capture confirm variable `var'
			if ( _rc == 0 & "`var'" != "_cons" ) {
				local fmt : format `var'
				if ( substr("`fmt'",-1,1) == "f" ) local fmt = "%8."+substr("`fmt'",-2,2)
				else if ( substr("`fmt'",-2,2) == "fc" ) local fmt = "%8."+substr("`fmt'",-3,3)
				else local fmt "%8.0g"
				local fmt`i' `fmt'
			}
			else local fmt "%8.0g"

			// display next line
			local tp `"_col(36) %7.2f `t' _col(44) %7.3f `p'"'
			if ( `"`cmd1'"' == "ologit" & `"`var'"' == "_cons" ) local tp
			if ( `"`cmd1'"' == "oprobit" & `"`var'"' == "_cons" ) local tp
			if ( `"`cmd1'"' == "cnreg" & `"`var'"' == "_cons" & `"`eq'"' != `"`feq'"' ) local tp
			if ( `"`cmd1'"' == "nbreg" & `"`var'"' == "_cons" & `"`eq'"' != `"`feq'"' ) local tp
			if ( `"`cmd1'"' == "gnbreg" & `"`var'"' == "_cons" & `"`eq'"' != `"`feq'"' ) local tp
			if ( `"`cmd1'"' == "xtreg" & `"`var'"' == "_cons" & `"`eq'"' != `"`feq'"' ) local tp
			if ( `"`cmd1'"' == "xtlogit" & `"`var'"' == "_cons" & `"`eq'"' != `"`feq'"' ) local tp
			if ( `"`cmd1'"' == "xtnbreg" & `"`var'"' == "_cons" & `"`eq'"' != `"`feq'"' ) local tp
			if ( `"`cmd1'"' == "xtpoisson" & `"`var'"' == "_cons" & `"`eq'"' != `"`feq'"' ) local tp
			if ( `"`cmd1'"' == "xtmixed" & `"`var'"' == "_cons" & `"`eq'"' != `"`feq'"' ) local tp
			display ///
			   as text %12s abbrev("`vname'",12) ///
			  _col(14) "{c |}" ///
			  _col(17) as result `fmt' `mn' ///
			  _col(27) `fmt'   `se' ///
			  `tp' ///
			  _col(54) `fmt'   `l' ///
			  _col(63) `fmt'   `u' ///
			  _col(72) %7.1f `df'
		}
	}

	* DISPLAY COEFFICIENT TABLE FOOTER
	display as text "{hline 13}{c BT}{hline 64}"
	display as text ""
end
*--------------------------------------------------------------------------------------------------------
* subprogram fit_handlebV
* This utility program handles placing mim estimates into e(b), e(V) and clearing them. The other e()
* results returned by mim.fit are left intact. If j == -1, then e(b), e(V) are cleared. If j == 0, then
* combined estimates are placed into e(b), e(V). Otherwise estimates from jth imputed dataset are placed
* in e(b), e(V).
*--------------------------------------------------------------------------------------------------------
program define fit_handlebV, eclass
	version 9

	syntax, j(integer) [ NOClear ]

	if ( `j' > 0 & "`e(MIM_emacros)'" == "" ) {
		display as error "individual estimates unavailable; rerun mim without noindividual option"
		exit 498
	}
	local levels  `"`e(MIM_levels)'"'
	local posofj : list posof "`j'" in levels
	if ( `j' > 0 & `posofj' == 0 ) {
		display as error "j must be one of `e(MIM_levels)'"
		exit 198
	}
	if ( `j' == `e(MIM_inbV)' ) exit 0				// nothing to do

	// TEMPORARILY HOLD EXISTING COMBINED ESTIMATES
	local cscalars `"`e(MIM_cscalars)'"'
	local cmatrices `"`e(MIM_cmatrices)'"'
	local cmacros `"`e(MIM_cmacros)'"'
	foreach scal of local cscalars {
		tempname MIM_`scal'
		scalar `MIM_`scal'' = e(MIM_`scal')
	}
	foreach mat of local cmatrices {
		tempname MIM_`mat'
		matrix `MIM_`mat'' = e(MIM_`mat')
	}
	foreach mac of local cmacros {
		local MIM_`mac' `"`e(MIM_`mac')'"'
	}

	// TEMPORARILY HOLD EXISTING INDIVIDUAL ESTIMATES
	local escalars `"`e(MIM_escalars)'"'
	local ematrices `"`e(MIM_ematrices)'"'
	local emacros `"`e(MIM_emacros)'"'
	local temp = `j'
	local remaining `"`levels'"'
	while ( `"`remaining'"' != "" ) {
		gettoken j remaining : remaining
		foreach scal of local escalars {
			capture confirm scalar e(MIM_`j'_`scal')
			if !c(rc) {
				tempname MIM_`j'_`scal'
				scalar `MIM_`j'_`scal'' = e(MIM_`j'_`scal')
			}
		}
		foreach mat of local ematrices {
			tempname MIM_`j'_`mat'
			matrix `MIM_`j'_`mat'' = e(MIM_`j'_`mat')
		}
		foreach mac of local emacros {
			local MIM_`j'_`mac' `"`e(MIM_`j'_`mac')'"'
		}
	}
	local j = `temp'

	// CLEAR PREVIOUS ESTIMATES
	if ( `"`noclear'"' == "" ) ereturn clear

	// POST RESULTS INTO e(b) AND e(V)
	tempname b V
	gettoken first : levels
	if ( `j' == 0 ) {
		// post combined estimates into e(b), e(V)
		matrix `b' = `MIM_Q'
		matrix `V' = `MIM_V'
		local depname `"`MIM_depvar'"'
		local N = `MIM_Nmin'
		local df_r = `MIM_dfmin'
		local dof "dof(`df_r')"
		local properties `"`MIM_properties'"'
		ereturn post `b' `V', depname(`"`depname'"') obs(`N') `dof' properties(`properties') `noclear'

		ereturn local title `"`MIM_title'"'
		ereturn local properties `"`MIM_properties'"'
		ereturn local depvar `"`MIM_depvar'"'
		ereturn local prefix2 "mim"
		ereturn local prefix `"`MIM_prefix'"'
	}
	if ( `j' > 0 ) {
		// post individual estimates into e(b), e(V)
		matrix `b' = `MIM_`j'_b'
		matrix `V' = `MIM_`j'_V'
		if ( `"`MIM_`j'_depvar'"' != "" ) local depname `"`MIM_`j'_depvar'"'
		else local depname `"`MIM_`first'_depvar'"'
		capture confirm scalar `MIM_`j'_N'
		if !c(rc) local N = `MIM_`j'_N'
		else local N = `MIM_`first'_N'
		capture confirm scalar `MIM_`j'_df_r'
		if !c(rc) local df_r = `MIM_`j'_df_r'
		else {
			capture confirm scalar `MIM_`first'_df_r'
			if ~c(rc) local df_r = `MIM_`first'_df_r'
		}
		if ( "`df_r'" != "" ) local dof `"dof(`df_r')"'
		ereturn post `b' `V', depname(`"`depname'"') obs(`N') `dof' `noclear'

		foreach scal of local escalars {
			capture confirm scalar `MIM_`j'_`scal''
			if !c(rc) ereturn scalar `scal' = `MIM_`j'_`scal''
			else ereturn scalar `scal' = `MIM_`first'_`scal''
		}
		foreach mat of local ematrices {
			if ( `"`mat'"' != "b" & `"`mat'"' != "V" ) {
				ereturn matrix `mat' = `MIM_`j'_`mat'', copy
			}
		}
		foreach mac of local emacros {
			if ( "`mac'" != "depvar" & "`mac'" != "dr_r" & "`mac'" != "N" & "`mac'" != "cmd" ) { 
				if ( `"`MIM_`k'_`mac''"' != "" ) ereturn local `mac' `"`MIM_`j'_`mac''"'
				else ereturn local `mac' `"`MIM_`first'_`mac''"'
			}
		}
		*Bug fix JCG: ereturn local depvar "`e(MIM_`from'_depvar)'"
		ereturn local depvar `"`depname'"'
	}

	// UPDATE INDICATOR OF WHICH RESULTS ARE IN e(b), e(V)
	local MIM_inbV `"`j'"'

	// RETURN INDIVIDUAL ESTIMATES IN THEIR DEFAULT LOCATION
	local temp = `j'
	local remaining `"`levels'"'
	while ( `"`remaining'"' != "" ) {
		gettoken j remaining : remaining
		foreach scal of local escalars {
			capture confirm scalar `MIM_`j'_`scal''
			if !c(rc) ereturn scalar MIM_`j'_`scal' = `MIM_`j'_`scal''
		}
		foreach mat of local ematrices {
			ereturn matrix MIM_`j'_`mat' = `MIM_`j'_`mat''
		}
		foreach mac of local emacros {
			if ( `"`MIM_`j'_`mac''"' != "" ) ereturn local MIM_`j'_`mac' `"`MIM_`j'_`mac''"'
		}
	}
	local j = `temp'

	// RETURN COMBINED ESTIMATES IN THEIR DEFAULT LOCATION
	foreach scal of local cscalars {
		ereturn scalar MIM_`scal' = `MIM_`scal''
	}
	foreach mat of local cmatrices {
		ereturn matrix MIM_`mat' = `MIM_`mat''
	}
	ereturn local MIM_cscalars `"`cscalars'"'
	ereturn local MIM_cmatrices `"`cmatrices'"'
	ereturn local MIM_cmacros `"`cmacros'"'
	ereturn local MIM_escalars `"`escalars'"'
	ereturn local MIM_ematrices `"`ematrices'"'
	ereturn local MIM_emacros `"`emacros'"'
	foreach mac of local cmacros {
		ereturn local MIM_`mac' `"`MIM_`mac''"'
	}

	// FINALLY, RETURN CMD
	if ( `j' == 0 ) ereturn local cmd `"`MIM_cmd'"'
	if ( `j' > 0 ) ereturn local cmd `"`MIM_`first'_cmd'"'
end
*--------------------------------------------------------------------------------------------------------
* subprogram milincom, rclass
* This program implements an mi version of lincom.
*--------------------------------------------------------------------------------------------------------
program define milincom, rclass
	version 9

	// GET DETAILS FROM MIM ESTIMATES
	local levels `"`e(MIM_levels)'"'
	local m : word count `levels'
	local cmd `"`e(MIM_cmd)'"'
	local depvar `"`e(MIM_depvar)'"'
	local inbV `"`e(MIM_inbV)'"'

	syntax [, CMDLine(string) PRefixes(string) Detail Level(passthru) EForm or hr IRr RRr ]

	if ( `"`detail'"' != "" ) local noisily "noisily"
	local wc : word count `eform' `or' `hr' `irr' `rrr'
	if ( `wc' > 1 ) {
		local options `"`eform' `or' `hr' `irr' `rrr'"'
		local options : list retokenize options
		display as error "options `options' not allowed together"
		exit 198
	}
	else if ( `wc' == 1 | `"`cmd'"' == "logistic" )  {
		if ( "`eform'" != "" ) local tt "    exp(b)"
		if ( "`or'" != "" | `"`cmd'"' == "logistic" ) local tt " Odds Rat."
		if ( "`hr'" != "" ) local tt " Haz. Rat."
		if ( "`irr'" != "" ) local tt "       IRR"
		if ( "`rrr'" != "" ) local tt "       RRR"
		local eform "eform"
	}
	else local tt "    Coeff."

	gettoken token rest : cmdline, parse(",= ")
 	while ( `"`token'"' != "" & `"`token'"' != "," ) {
		if ( `"`token'"' == "=" ) {
			display as error _quote "=" _quote " not allowed in expression"
			exit 198
		}
		local lc `"`lc'`token'"'				// note, lc is used for display of results
		gettoken token rest : rest, parse(",= ")
	}

	// TAKE LINEAR COMBINATIONS FOR INDIVIDUAL MODELS
	tempname S b se
	gettoken first : levels
	local remaining `"`levels'"'
	while ( `"`remaining'"' != "" ) {
		gettoken j remaining : remaining
		tempname Q`j'				// to hold coefficient estimate for jth lincom
		tempname V`j'				// to hold variance of Q`j'
		local eb "`eb' `Q`j''"			// list of names of matrices holding coeff estimates
		capture `noisily' display as input `"-> mim, j(`j')"'
		fit_handlebV, j(`j') 			// put individual estimates in e(b) eV) etc.
		capture `noisily' display as input `"-> `prefixes' lincom `cmdline'"'
		capture `noisily' `prefixes' lincom `cmdline'
		if c(rc) {
			local rc = c(rc)
			if ( `"`noisily'"' == "" ) {
				capture noisily display as input `"-> mim, j(`j')"'
				capture noisily display as input `"-> `prefixes' lincom `pecmd'"'
				capture noisily `prefixes' lincom `cmdline'
			}
			fit_handlebV, j(`inbV') 	// restore estimates
			exit `rc'
		}
		scalar `b' = r(estimate)
		scalar `se' = r(se)
		if ( `"`cmd'"' == "logistic" ) matrix `Q`j'' = J( 1, 1, ln(`b') )
		else matrix `Q`j'' = J( 1, 1, `b' )
		matrix rownames `Q`j'' = (1)
		matrix colnames `Q`j'' = (1)
		if ( `"`cmd'"' == "logistic" ) matrix `V`j'' = J( 1, 1, ln(`se')^2 )
		else matrix `V`j'' = J( 1, 1, `se'^2 )
		matrix rownames `V`j'' = (1)
		matrix colnames `V`j'' = (1)
		if ( `j' == `first' ) matrix `S' = `V`j''
		else matrix `S' = `S' + `V`j''
	}

	// CALCULATE COMBINED RESULTS
	tempname Q W B T dfvec dfmin dfmax TLRR r nu lambda r1 nu1
	fit_combine, i(`"`eb'"') s(`S') b(`B') t(`T') q(`Q') w(`W') df(`dfvec') min(`dfmin') max(`dfmax') ///
		tlrr(`TLRR') r(`r') nu(`nu') l(`lambda') r1(`r1') nu1(`nu1')

	// DISPLAY RESULTS
	local pos = 79 - length("Imputations = `m'")
	display ///
		as text _n "Multiple-imputation estimates for lincom" ///
		as text _col(`pos') "Imputations = " as result `m'
	test `lc' = 0, notest
	display // blank line
	fit_display_table, q(`Q') vars(`T') dof(`dfvec') cmd(`cmd') tt("`tt'") depvar(`depvar') `level' `eform'

	// RESTORE ESTIMATES
	fit_handlebV, j(`inbV')

	// RETURN RESULTS
	tempname df
	scalar `b' = `Q'[1,1]
	scalar `se' = sqrt(`T'[1,1])
	if ( `"`cmd'"' == "logistic" ) {
		scalar `b' = exp(`b')
		scalar `se' = exp(`se')
	}
	scalar `df' = `dfvec'[1,1]
	return matrix MIM_Q = `Q'
	return matrix MIM_T = `T'
	return matrix MIM_B = `B'
	return matrix MIM_W = `W'
	return matrix MIM_dfvec = `dfvec'
	return scalar df = `df'
	return scalar se = `se'
	return scalar estimate = `b'
	global S_1 = `b'
	global S_2 = `se'
	global S_3 = `df'
end
*--------------------------------------------------------------------------------------------------------
* subprogram mitestparm, rclass
* This program implements an mi version of testparm. It performs an approximate F-test (Li, Raghunathan
* and Rubin 1991) to test the hypothesis that the specified coefficients are all equal to zero, analogous
* to the standard Wald test. The test statistic, p-value and approximate degrees of freedom are returned
* in r().
*--------------------------------------------------------------------------------------------------------
program define mitestparm, rclass
	version 9

	syntax [, CMDLine(string) ]
	local 0 `"`cmdline'"'
	syntax varlist

	// GET DETAILS FROM LAST MIM ESTIMATES
	local levels `"`e(MIM_levels)'"'
	local m : word count `levels'
	local remaining `"`levels'"'
	while ( `"`remaining'"' != "" ) {
		gettoken j remaining : remaining
		tempname _b`j' _V`j'					// e(B) and e(V) for `j'th individual model
		matrix `_b`j'' = e(MIM_`j'_b)
        	matrix `_V`j'' = e(MIM_`j'_V)
	}

	// EXTRACT COLUMN NUMBERS AND NAMES FOR VARS IN VARLIST INCLUDED IN FITTED MODEL
	local first : word 1 of `levels'
	local k = 0
	local colnames
	foreach var of varlist `varlist' {
		if ( colnumb(`_b`first'', "`var'") < . ) {	// if `var' was included in fitted model
			local k = `k' + 1
			local var`k' = colnumb(`_b`first'',"`var'")
			local colnames "`colnames' `var'"
		}
	}
	if ( `k' == 0 ) {
		display as error "varlist does not contain any covariates from the last fitted model"
		exit 198
	}

	// EXTRACT COEFFICIENT SUBVECTORS
	local rownames : rownames `_b`first''
	local remaining `"`levels'"'
	while ( `"`remaining'"' != "" ) {
		gettoken j remaining : remaining
		tempname b`j'
		matrix `b`j'' = J(1,`k',0)				// 1-by-`k' matrix of all zeros 
		forvalues c = 1/`k' {
			matrix `b`j''[1,`c'] = `_b`j''[1,`var`c'']
		}
		matrix rownames `b`j'' = `rownames'
		matrix colnames `b`j'' = `colnames'
	}

	// EXTRACT COVARIANCE SUBMATRICES
	local remaining `"`levels'"'
	while ( `"`remaining'"' != "" ) {
		gettoken j remaining : remaining
		tempname V`j'
		matrix `V`j'' = J(`k',`k',0)
		forvalues r = 1/`k' {
			forvalues c = 1/`k' {
				matrix `V`j''[`r',`c'] = `_V`j''[`var`r'',`var`c'']
			}
		}
		matrix rownames `V`j'' = `colnames'			// not an error; it should equal `colnames'
		matrix colnames `V`j'' = `colnames'
	}

	// CALCULATE AVERAGE OF COEFFICIENT SUBVECTORS
	tempname matsum Qbar
	matrix `matsum' = J(1,`k',0)					// set `matsum' to 1xk zero matrix 
	local remaining `"`levels'"'
	while ( `"`remaining'"' != "" ) {
		gettoken j remaining : remaining
		matrix `matsum' = `matsum' + `b`j''
	}
	matrix `Qbar' = 1/`m'*`matsum'
	matrix rownames `Qbar' = `rownames'
	matrix colnames `Qbar' = `colnames'

	// CALCULATE SUBMATRIX WITHIN IMPUTATION VARIANCE
	tempname Ubar
	matrix `matsum' = J(`k',`k',0) 				// set `matsum' to kxk zero matrix
	local remaining `"`levels'"'
	while ( `"`remaining'"' != "" ) {
		gettoken j remaining : remaining
		matrix `matsum' = `matsum' + `V`j''
	}
	matrix `Ubar' = 1/`m'*`matsum'

	// CALCULATE SUBMATRIX BETWEEN IMPUTATION VARIANCE
	tempname B
	matrix `matsum' = J(`k',`k',0) 				// Set `matsum' to kxk zero matrix
	local remaining `"`levels'"'
	while ( `"`remaining'"' != "" ) {
		gettoken j remaining : remaining
		matrix `matsum' = `matsum' + (`b`j'' - `Qbar')'*(`b`j'' - `Qbar')
	}
	matrix `B' = 1/(`m'-1)*`matsum'

	// CALCULATE TOTAL SUBMATRIX VARIANCE ESTIMATE
	tempname Ubarinv BUbarinv Ttilde
	matrix `Ubarinv' = inv(`Ubar')
	matrix `BUbarinv' = `B'*`Ubarinv'
	local r = (1+(1/`m'))*trace(`BUbarinv')/`k'
	matrix `Ttilde' = (1+`r')*`Ubar'

	// CALCULATE TEST STATISTIC
	tempname Q0 Qdiff Ttildeinv D
	matrix `Q0' = J(1,`k',0)
	matrix `Qdiff' = `Qbar' - `Q0'
	matrix `Ttildeinv' = inv(`Ttilde')
	matrix `D' = `Qdiff'*`Ttildeinv'*`Qdiff''/`k'		// `D' is 1-by-1 matrix, not a scalar
	local dee = `D'[1,1]
	if ( `dee' >= 1000 ) local dee = 1000			// upper limit on degrees of freedom

	// CALCULATE APPROXIMATE DEGREES OF FREEDOM
	local a = `k'*(`m'-1)
	if ( `a' > 4 ) local df = 4 + (`a'-4)*(1+(1- 2/`a')/`r')^2
	else local df = `a'*(1+1/`k')*(1+1/`r')^2/2
	if ( `df' >= 1000 ) local df = 1000				// upper limit on degrees of freedom

	// CALCULATE P-VALUE FROM F DISTRIBUTION
	local p = Ftail(`k',`df',`dee')

	// DISPLAY RESULTS
	display // blank line
	local k=0
	foreach var of varlist `colnames' {
		local k=`k'+1
		display as text " ( `k')" as result "  `var' = 0"
	}
	display // blankline
	display as text "       F(" %3.0f `k' "," %6.1f `df' ") =" as result %8.2f `dee'
	display as text _col(13) "Prob > F =" as result %10.4f `p'

	// RETURN RESULTS
	return local dee = `dee'
	return local df = `df'
	return local p = `p'
end
*--------------------------------------------------------------------------------------------------------
* subprogram mipredict
* This program implements a simple mi version of predict.
*--------------------------------------------------------------------------------------------------------
program define mipredict
	version 9

	syntax [, CMDLine(string) PRefixes(string) ]

	local 0 `"`cmdline'"'
	syntax newvarlist(min=1 max=1) [, stdp EQuation(passthru) ]
	local var : word 1 of `varlist'

	chkvars
	quietly levelsof _mj, local(all)
	local pos : list posof "0" in all
	if ( `pos' == 0 ) {
		display as error "original dataset (_mj==0) is required for prediction with mim"
		exit 498
	}

	tempvar t1_ind t1_all
	quietly generate `t1_all' = .
	if ( `"`stdp'"' != "" ) {
		tempvar t2_ind t2_all
		quietly generate `t2_all' = .
	}
	local inbV `"`e(MIM_inbV)'"'
	local levels `"`e(MIM_levels)'"'
	local remaining `"`levels'"'
	while ( "`remaining'" != "" ) {
		gettoken j remaining : remaining
		fit_handlebV, j(`j')
		capture drop `t1_ind'
		quietly `prefixes' predict `t1_ind' if _mj == `j', xb `equation'
		quietly replace `t1_all' = `t1_ind' if _mj == `j'
		if ( `"`stdp'"' != "" ) {
			capture drop `t2_ind'
			quietly `prefixes' predict `t2_ind' if _mj == `j', stdp `equation'
			quietly replace `t2_all' = `t2_ind' if _mj == `j'
		}
	}
	fit_handlebV, j(`inbV')			// restore estimates

	// calculate predicted values for original data by combining predicted values
	// for imputed datasets using Rubin's rules
	rubin `t1_all' `ts_all'
	
	// clean up
	if ( `"`stdp'"' == "" ) rename `t1_all' `var'
	else rename `t2_all' `var'
end
*--------------------------------------------------------------------------------------------------------
* subprogram rubin
* This program implements a scalar version of rubin's rules for an existing variable
* in the dataset. The variable values are combined on an observation-by-observation basis
* and each combined result is stored against the corresponding observation in the _mj==0
* dataset.
*--------------------------------------------------------------------------------------------------------
program define rubin
	version 9

	syntax varlist(min=1 max=2)
	local var : word 1 of `varlist'
	local varse : word 2 of `varlist'
	if ( "`varse'" != "" ) local stdp "stdp"

	quietly levelsof _mj, local(all)
	local pos : list posof "0" in all
	if ( `pos' == 0 ) {
		display as error "original dataset (_mj==0) is required with rubin"
		exit 498
	}
	local mj0 "0"
	local levels : list all - mj0

	tempname q qsum w b m1 m2
	local m : word count `levels'
	local from : word 1 of `levels'
	local to : word `m' of `levels'
	scalar `m1' = 1/(`m'-1)
	scalar `m2' = 1 + 1/`m'
	// Mark Lunt speed improvements to prediction
	tempvar q b w temp
	qui gen `temp' = .
	sort _mi _mj
	quietly {
		by _mi: egen `q' = mean(`var') if _mj >= `from' & _mj <= `to'
		by _mi: replace `var' = `q'[_N] if _mj == 0
		if ( `"`stdp'"' != "" ) {
			by _mi: egen `w' = mean(`varse') if _mj >= `from' & _mj <= `to'
			by _mi: replace `temp' = (`var' - `q')^2 if _mj >= `from' & _mj <= `to'
			by _mi: egen `b' = total(`temp')
			replace `b' = `m1'*`b'
			by _mi: replace `varse' = `w'[_N] + `m2'*`b'[_N] if _mj == 0
		}
	}
	sort _mj _mi
end
