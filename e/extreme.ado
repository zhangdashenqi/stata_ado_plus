*! extreme 1.1.0 20 January 2015
*! Copyright (C) 2015 David Roodman

* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.

* Version history at bottom

cap program drop extreme
program extreme, eclass byable(recall) sortpreserve
	version 11.0

	if replay() {
		if "`e(cmd)'" != "extreme" error 301
		if _by() error 190
		Display `0'
		exit 0
	}

	tokenize `"`0'"', parse(", ")

	if `"`1'"' != "plot" {
		syntax anything [if] [in] [fw aw iw pw], [SIGvars(string) XIvars(string) MUvars(string) CONSTraints(string) /// 
			CLuster(varname) Robust vce(string) Level(cilevel) THRESHold(string) QUIetly small(string) GUMBel init(namelist min=1 max=1) *] 
		_get_eformopts, soptions eformopts(`options')
		local diopts `s(eform)' level(`level')
		_get_mldiopts, `s(options)'
		local diopts `diopts' `s(diopts)'
		mlopts mlopts options, `s(options)'
		_get_gropts, graphopts(`options') gettwoway
		local uniqueopts `s(twowayopts)'
		local mergedopts `s(graphopts)'
		local cmdline extreme `0'

		tokenize `"`anything'"'
	
		di _n

		if `"`1'"'!="gpd" & `"`1'"'!="gev" {
			di as err `"`1' not a valid model. Choose {cmd:gpd} or {cmd:gev}."'
			exit 198
		}
		if "`muvars'"!="" & "`1'"=="gpd" {
			di as err "{cmdab:mu:vars()} option valid only for the GEV model."
			exit 198
		}
		if "`gumbel'"!="" {
			constraint free
			local constraints `constraints' `r(free)'
			constraint `r(free)' [xi]_cons
			if "`xivars'"!="" {
				di "{cmdab:xi:vars(}`xivars'{cmd:)} ignored for Gumbel model." _n
				local xivars
			}
		}

		marksample touse

		local subcommand `1'
		macro shift
		local 0 `*'
		syntax varlist(numeric fv ts `=cond("`subcommand'"=="gpd","max=1","")')
		local depvar_user `varlist'
		fvrevar `varlist' if `touse'
		local depvar_revar `r(varlist)'
		markout `touse' `:word 1 of `r(varlist)''
		local Ndepvar: word count `depvar_revar'
		if "`subcommand'"!="gpd" {
			if `"`threshold'"'!="" {
				di  "{cmdab:thresh:old()} ignored for the GEV model." _n
			}
			local title ML fit of generalized extreme value distribution
			local depvar_thresh `depvar_revar'
		}
		else {
			tempvar depvar_thresh
			qui gen double `depvar_thresh' = . in 1
			local title ML fit of generalized Pareto distribution
		}

		if "`weight'" != "" {
			tempname wvar
			gen double `wvar' `exp' if `touse'
			local wgt [`weight'=`wvar']
			local wtype `weight'
			local wexp `"`exp'"'
		}

		if `"`small'"' != "" {
			local 0 `small'
			syntax anything, [Reps(integer 50)]
			if !inlist(`"`anything'"', "bs", "cs") {
				di as err "{cmd:small()} option must be {cmd:bs} (bootstrap) or {cmd:cs} (Cox-Snell)."
				exit 198
			}
			local small `anything'
			local smallreps `reps'
			if "`small'"=="bs" di as txt "Bootstrapped bias correction and standard errors based on `reps' replications" _n
				else if "`constraints'" !="" {
					di as err "Cox-Snell correction not available for constrained models. Try {cmd:small(bs)}."
					exit 198
				}
		}

		foreach param in mu sig xi {
			if "`param'"!="mu" | "`subcommand'"=="gev" {
				local 0 ``param'vars'
				syntax [varlist(numeric default=none fv ts)], [noConstant]
				if "`varlist'"=="" & "`constant'"!="" {
					di as err "No right-side variables for `param'."
					exit 498
				}
				local `param'vars `varlist'
				local `param'nocons `constant'
				markout `touse' `varlist'
			}
		}
		foreach param in mu sig xi {
			if "`param'"!="mu" | "`subcommand'"=="gev" {
				_rmcoll ``param'vars' if `touse', ``param'nocons' expand
				local `param'vars `r(varlist)'
				local bcolnames `bcolnames' `r(varlist)' `=cond("``param'nocons'"=="", "_cons", "")'
				fvrevar `r(varlist)' if `touse'
				tokenize `r(varlist)'
				forvalues i=1/`:word count `r(varlist)'' {  // stick "o." back on fvrevar'd omitted variables
					local `param'_revar ``param'_revar' `=cond(strpos("`:word `i' of `r(varlist)''", "o."), "o.", "")'``i''  
				}
			}
		}

		local stationary = "`mu_revar'`sig_revar'`xi_revar'"==""

		local 0 `vce'
		syntax [anything(everything)], [*]
		local bootoptions `options'
		local 0, `anything'
		syntax, [bs bootstrap *]
		if "`bs'`bootstrap'" != "" {
			local _vce `options'
			_vce_parse, argoptlist(cluster) pwallowed(cluster) old: `wgtexp', cluster(`cluster') vce(`_vce')
			local BS bs _b, notable noheader cluster(`r(cluster)') level(`level') `bootoptions':
			local vce
			local level
			if "`small'"=="bs" {
				di as txt "Warning: It may be inefficient to (non-parametrically) bootstrap the standard errors of the bootstrap-based, bias-corrected point estimates."
				di as txt "{cmd:small(bs)} by itself will produce (parametrically) bootstrapped standard errors along with bias-corrected pointed estimates." _n
			}
		}
		else {
			_vce_parse, optlist(robust oim opg) argoptlist(cluster) pwallowed(robust cluster oim opg) old: `wgtexp', `robust' cluster(`cluster') vce(`vce')
			local vce `r(vceopt)'
			local cluster `r(cluster)'
		}
		markout `touse' `r(cluster)', strok

		if "`small'"=="bs" | `"`BS'"'!="" {
			di as txt "Initial pseudorandom number generator state: " as res "`c(seed)'" _n
			local seed `c(seed)'
		}
		
		cap assert `touse'==0
		if _rc==0 {
			di as err "No observations."
			exit 2000
		}
		
		tempname b bsmall V ll zeta

		local Nthresh 1
		if "`subcommand'"=="gpd" {
			if `"`threshold'"'=="" {
				sum `depvar_revar' if `touse', meanonly
				local _threshold = r(min)
				local threshold = r(min)
				local Nthreshcoefs 1
				di as txt "Taking sample minimum of " as res r(min) as txt " as the threshold." _n
				scalar `zeta' = 1
			}
			else {
				local 0 `threshold'
				syntax anything, [plot(string)]
				local threshcoefs `plot'
				if `"`threshcoefs'"'=="" local threshcoefs /lnsig /xi
				local Nthreshcoefs: word count `threshcoefs'
				cap confirm numeric variable `anything'
				if _rc {
					parse_numlist, numlist(`"`anything'"') min(1)
					local _threshold `s(numlist)'
					local Nthresh = `: word count `_threshold''
					if `Nthresh'>1 local quietly quietly
				}
				else {
					tempvar _threshold
					gen double `_threshold' = `anything' if `touse'
					local stationary 0
				}
				tempvar touse2
				gen byte `touse2' = `touse' & `depvar_revar'>`:word 1 of `_threshold''
				sum `touse2' if `touse' `awgt', meanonly
				scalar `zeta' = r(mean)
				local touse `touse2'
			}
			mata _extremeThresh=J(0,1,0); _extremeThreshb=_extremeThreshse=J(0,0`Nthreshcoefs',0)
		}
		else {
			scalar `zeta' = 1
			local _threshold XXX
		}

		if ("`subcommand'"!="gpd" | `Nthresh'==1) & `"`mergedopts'`uniqueopts'"'!="" {
			di as err `"`mergedopts' `uniqueopts' not allowed."'
			exit 198
		}

		preserve
		qui keep if `touse'
		mata _extremeDepVar = .; _extremeIsGEV = "`subcommand'"=="gev"
		if "`subcommand'"=="gev" mata st_view(_extremeDepVar, ., st_local("depvar_thresh"))
		if `"`init'"'=="" {  // starting values from http://cran.r-project.org/web/packages/ismev/ismev.pdf#page=11
			tempname init sig0
			qui sum `:word 1 of `depvar_revar'' `awgt'
			scalar `sig0' = r(sd) `=cond("`subcommand'"=="gev", "*sqrt(6)/_pi", "")' // correct values if xi=0, model stationary, and observed mean, var correct
			if "`sig_revar'"!="" mat `init' =                  J(1,`:word count `sig_revar'', 0)
			if "`signocons'"=="" mat `init' = nullmat(`init'), ln(`sig0')
			if "`xi_revar'" !="" mat `init' =         `init' , J(1,`:word count `xi_revar'', 0)
			if "`xinocons'" =="" mat `init' =         `init' , 0
			if "`subcommand'"=="gev" mat `init' = `=cond("`mu_revar'"!="", "J(1,`:word count `mu_revar'', 0),", "")' `=cond("`munocons'"=="", "r(mean)-.5772156649*`sig0'", "")' , `init'
		}
		foreach param in sig xi mu {
			if "`param'"!="mu" | "`subcommand'"=="gev" {
				if "``param'nocons'"!="" local `param'vars ``param'vars', noconstant
			}
			else local muvars
		}
		tempname t
		foreach thresh `=cond(0`Nthresh'>1, "of numlist", "in")' `_threshold' {
			qui if "`subcommand'"=="gpd" {
				replace `depvar_thresh' = `depvar_revar' - `thresh'
				drop if `depvar_thresh'<=0
				mata st_view(_extremeDepVar, ., st_local("depvar_thresh"))
			}
			
			ml model lf2 extreme_lf2() `=cond("`subcommand'"=="gev", "(mu:`mu_revar',`munocons')", "")' (lnsig:`sig_revar',`signocons') (xi:`xi_revar',`xinocons') `wgt', ///
				collinear title(`title') `vce' constraints(`constraints') nopreserve // estimate directly even when boostrapping, in order to rescue e(ll)
			mata moptimize_init_userinfo($ML_M, 3, extreme_est_prep(_extremeDepVar))
			mata moptimize_init_userinfo($ML_M, 2, _extremeDepVar)
			mata moptimize_init_userinfo($ML_M, 1, _extremeIsGEV)

			ml init `init', copy
			`quietly' ml max, `mlopts' noclear nooutput level(`level')`=cond(`"`BS'"'=="", "", "nolog")' search(off)
			scalar `ll' = e(ll)
			if `"`BS'"' == "" {
				if "`small'"!="" extreme_small, xivars(`xivars') small(`small') smallreps(`smallreps')
			}
			else `quietly' `BS' extreme_estimate, init(`init', copy) small(`small') smallreps(`smallreps') xivars(`xivars') depvarname(`depvar_thresh')
			
			if `Nthresh'>1 {
				mat `b' = e(b)
				mat `init' = `b'
				mata _extremeThresh = _extremeThresh \ `thresh'
				foreach stat in b se {
					cap mat drop `t'
					foreach coef in `threshcoefs' {
						cap mat `t' = nullmat(`t'), _`stat'[`coef']
						if _rc mat `t' = nullmat(`t'), .
					}
					mata _extremeThresh`stat' = _extremeThresh`stat' \ st_matrix("`t'")
				}
			}
			ml clear
		}
		ereturn scalar ll = `ll'

		if `Nthresh'>1 {
			tempvar lo hi threshname
			getmata `threshname' = _extremeThresh, force
			foreach stat in b se {
				local names
				forvalues i=1/`Nthreshcoefs' {
					tempname t
					local names`stat' `names`stat'' `t'
				}
				getmata (`names`stat'') = _extremeThresh`stat', force
			}
			tokenize `threshcoefs'
			label var `threshname' "Threshold"
			qui forvalues i=1/`Nthreshcoefs' {
				local mid: word `i' of `namesb'
				cap drop `lo'
				cap drop `hi'
				gen `lo' = `mid' - invnormal((1+`level'/100)/2) * `: word `i' of `namesse''
				gen `hi' = `mid' + invnormal((1+`level'/100)/2) * `: word `i' of `namesse''
				label var `mid' `=subinstr(`"``i''"', "/", "", .)'
				label var `lo' "Confidence interval minimum"
				label var `hi' "Confidence interval maximum"
				twoway rarea `lo' `hi' `threshname', `mergedopts' || line `mid' `threshname', name(extremeThresh`i', replace) nodraw ///
					`=cond(`i'==`Nthreshcoefs', "xtitle(Threshold)",`"xtitle("") xlabels(none)"')' legend(off) ytitle(`"`:var label `mid''"') `mergedopts' `uniqueopts'
				local threshgraphs `threshgraphs' extremeThresh`i'
			}
			graph combine `threshgraphs', cols(1) name(extremeThresh, replace)
		}

		restore
		mat `b' = e(b)
		mat colnames `b' = `bcolnames'
		ereturn repost b = `b', esample(`touse') rename // pass the sample marker across the restore barrier

		mata mata drop _extremeDepVar _extremeIsGEV
		cap mata mata drop _extremeThresh _extremeThreshb _extremeThreshse 

		ereturn local threshold `threshold'
		ereturn local seed `seed'
		ereturn scalar Nthresh = cond("`subcommand'"=="gpd", `Nthresh', 0)
		ereturn scalar Ndepvar = `Ndepvar'
		ereturn scalar zeta = `zeta'
		ereturn local depvar `depvar_user'
		ereturn local model `subcommand'
		ereturn local gumbel `gumbel'
		ereturn scalar stationary = `stationary'
		cap local t = [lnsig]_cons
		if !_rc eret local diparmopts diparm(lnsig, exp label("sig"))
		if "`small'"=="bs" ereturn local vcetype Bootstrap
		ereturn local muvars `muvars'
		ereturn local sigvars `sigvars'
		ereturn local xivars `xivars'
		ereturn local wtype `wtype'
		ereturn local wexp `"`wexp'"'
		ereturn local predict extreme_p
		mat coleq `init' = `:colfullnames e(b)'
		ereturn matrix init = `init'
		eret local cmdline `cmdline'
		eret local cmd "extreme"
		Display, `diopts'
	}

	else { // plot
		syntax [anything(everything)] [fw aw iw pw], [mrl *]
		local _mrl `mrl'
		local 0 `anything' [`weight'`exp'], `options'
		syntax [anything] [if] [in] [fw aw iw pw], [PP QQ DENSity RETurn XIPROFile(string) RETPROFile(string) mrl(string) Level(cilevel) name(string) *]
		_get_kdensopts, `options'
		local kdensopts `s(kdensopts)'
		_get_gropts, graphopts(`s(options)') gettwoway
		local uniqueopts `s(twowayopts)'
		local mergedopts `s(graphopts)'
		if "`name'"=="" local name extreme
		marksample touse

		qui if "`mrl'`_mrl'"!="" {
			preserve
			keep if `touse'
			tempvar wt x mid lo hi
			tempname results hold
			local wtexp [`weight'`exp']
			local 0 `2'
			syntax varlist(ts fv max=1)
			fvrevar `varlist'
			local var `r(varlist)'
			sort `var'
			cap _est hold `hold'
			mata _extremeResults = J(0, 4, 0)
			if "`mrl'" != "" {
				parse_numlist, numlist("`mrl'") var(`var') min(2)
				foreach min of numlist `s(numlist)' {
					cap mean `var' if `var'>=`min' `wtexp', level(`level') noheader nolegend
					if !_rc {
						mata _extremeResults = _extremeResults \ (`min', (`e(N)'<=2? `=_b[`var']-`min'',.,. : `=_b[`var']-`min'':+(0,-1,1):*`=_se[`var']'*invttail(`e(df_r)',.5-`level'/200)))
					}
				}
			}
			else {
				forvalues i=1/`=_N' {
					mean `var' in `i'/`=_N' `wtexp', level(`level') noheader nolegend
					local min = `var'[`i']
					mata _extremeResults = _extremeResults \ (`min', (`e(N)'<=2? `=_b[`var']-`min'',.,. : `=_b[`var']-`min'':+(0,-1,1):*`=_se[`var']'*invttail(`e(df_r)',.5-`level'/200)))
				}
			}
			ereturn clear
			cap _estimates unhold `hold'
			getmata (`x' `mid' `lo' `hi') = _extremeResults, force
			mata mata drop _extremeResults
			label var `x' "`varlist'"
			label var `mid' "Point estimate"
			label var `lo' "Confidence interval minimum"
			label var `hi' "Confidence interval maximum"
			twoway rarea `lo' `hi' `x' `mergedopts' || line `mid' `x', xtitle("Threshold") ytitle("Mean excess") name(`"`name'MRL"', replace) legend(off) `mergedopts' `uniqueopts'
			restore
		}
		else if "`2'"!="," {
			di as err "varlist not allowed"
			exit 101
		}

		if `"`pp'`qq'`return'`density'`xiprofile'`retprofile'"' == "" exit
		if "`e(cmd)'" != "extreme" error 301
		if e(Nthresh)>1 {
			di as err "Requested plot(s) unavailable after multi-threshold estimation."
			exit 198
		}

		tokenize `"`anything'"'
		macro shift
		local 0, `*'
		if !e(stationary) {
			foreach plottype in density return retprofile {
				if "``plottype''"!="" {
					local `plottype'
					di as res "{cmd:`plottype'} plot not available for non-stationary models."
				}
			}
		}
		if "`xiprofile'"!="" & "`e(xivars)'"!="" {
			di as error "{cmdab:xiprof:ile()} plot available only for models that are stationary in xi."
			local xiprofile
		}
		if "`xiprofile'`retprofile'" != "" {
			tempname Cns
			cap mat `Cns' = e(Cns)
			if !_rc {
				di as res"{cmdab:xiprof:ile()} and {cmdab:retprof:ile()} plots not available for constrained models."
				local xiprofile
				local retprofile
			}
			else if "`e(esttype)'"=="corrected" {
				di as error "{cmdab:xiprof:ile()} and {cmdab:retprof:ile()} plots unavailable for estimates with bias correction."
				local xiprofile
				local retprofile
			}
		}

		local depvar: word 1 of `e(depvar)'
		
		tempvar modcdf modquant empcdf empquant wt
		if e(stationary) qui predict `modcdf' if `touse', cdf
		else {                                                           // transform into Gumbel variate a la Coles eq 6.6
			tempvar muhat lnsighat xihat z
			if e(model)=="gev" {
				if "`e(muvars)'"!="" qui predict `muhat' if e(sample), eq("mu")
					else scalar `muhat' = [mu]_cons
			}
				else scalar `muhat' = `e(threshold)'
			if "`e(sigvars)'"!="" qui predict `lnsighat' if e(sample), eq("lnsig")
				else scalar `lnsighat' = [lnsig]_cons
			if "`e(xivars)'" !="" qui predict `xihat'    if e(sample), eq("xi")
				else scalar `xihat'    = [xi]_cons
			qui gen `z' = ln(1+`xihat'/exp(`lnsighat')*(`depvar'-`muhat'))/`xihat' if e(sample)
			qui gen `modcdf' = cond(e(model)=="gev", exp(-exp(-`z')), 1-exp(-`z'))
		}
		label var `modcdf' `"Modeled cumulative distribution `=cond(e(stationary),""," (Gumbel scale)")'"'
		sort `modcdf'
		if "`e(wtype)'"!="" {
			qui gen double `wt' `wexp' if `touse'
			local wexp = `wt'
		}
		qui replace `touse' = 0 if !e(sample)

		qui if "`pp'`qq'`return'"!="" {
			gen `empcdf' = e(sample)
			if "`e(wtype)'"!="" {
				replace `empcdf' = `empcdf' *	`wt'
				recode `empcdf' (. = 0)
			}
			replace `empcdf' = `empcdf' + `empcdf'[_n-1] if _n>1
			replace `empcdf' = `empcdf'*(e(N)/(e(N)+1)/`empcdf'[_N]) if `touse'
			label var `empcdf' "Empirical cumulative distribution"

			if "`pp'"!="" {
				sum `empcdf' if `touse', meanonly
				scatter `modcdf' `empcdf', `mergedopts' || function y=x, range(`r(min)' `r(max)') ytitle(Modeled probability) xtitle(Empirical probability) legend(off) name(`"`name'PP"', replace) `mergedopts' `uniqueopts' || if `touse'
			}

			if "`qq'"!="" {
				if e(stationary) {
					local empquant `depvar'
					qui predict `modquant' if `touse', invccdf(1-`empcdf')
				}
				else {
					gen `modquant' = cond(e(model)=="gev", -ln(-ln(`empcdf')), -ln(1-`empcdf')) if e(sample) // Coles section 6.2.3
					local empquant `z'
				}
				label var `empquant' "Empirical quantile"
				label var `modquant' "Modeled quantile"
				sum `empquant' if `touse', meanonly
				scatter `empquant' `modquant', `mergedopts' || function y=x, range(`r(min)' `r(max)') xtitle(Modeled quantile) ytitle(Empirical quantile) legend(off) name(`"`name'QQ"', replace) `mergedopts' `uniqueopts' || if `touse'
				drop `modquant'
			}

			if "`return'"!="" {
				preserve
				keep if `touse'
				tempvar yp mid lo hi retperiod
				set obs `=_N+1'
				gen `retperiod' = (1/e(zeta))/(1-`empcdf')
				sum `retperiod' if e(sample), meanonly
				replace `empcdf' = 1-1/(2*r(max))/e(zeta) in `=_N'
				replace `touse'=1 in `=_N'
				forvalues i=`=ceil(log10(r(min)))'/`=floor(log10(2*r(max)))' {
					local xlabels `" `xlabels' `=cond(e(model)=="gpd", e(zeta)*10^`i', -1/log(1-1/10^`i'))' "`=10^`i''" "'
				}
				gen `yp' = cond(e(model)=="gpd", 1/(1-`empcdf'), -1/log(`empcdf'))
				label var `yp' "Return period"
				predictnl `mid' = `=cond(e(model)=="gpd","(`e(threshold)')","[mu]_cons")' + exp([lnsig]_cons) * cond(abs([xi]_cons)<1e-10, ln(`yp'), ((`yp')^[xi]_cons-1)/[xi]_cons), ci(`lo' `hi') level(`level') force
 				label var `mid' "Point estimate"
				label var `lo' "Confidence interval minimum"
				label var `hi' "Confidence interval maximum"
				twoway rarea `lo' `hi' `yp', astyle(ci) `mergedopts' || ///
					line `mid' `yp', `mergedopts' || ///
					scatter `depvar' `yp', xscale(log) legend(off) name(`"`name'Return"', replace) ytitle("Return level") xlabel(`xlabels') `mergedopts' `uniqueopts'
				restore
			}
		}

		if "`density'"!="" {
			tempvar zero
			gen byte `zero' = 0
			sum `depvar' if e(sample), meanonly
			local x (x - `=cond(e(model)=="gev","[mu]_cons","`e(threshold)'")')/exp([lnsig]_cons)
			local f = cond(abs([xi]_cons)<1e-5, "exp(-`x')", "(1+[xi]_cons*`x')^(-1/[xi]_cons)")
			twoway kdensity `depvar', `kdensopts' `mergedopts' || ///
				function y=1/exp([lnsig]_cons)*(`f')^(1+[xi]_cons) `=cond(e(model)=="gev", "* exp(-(`f'))","")', range(`=r(min)' `=r(max)') `mergedopts' ///
				|| scatter `zero' `depvar', ytitle(Density) msize(vsmall) msymbol("d") xtitle("") name(`"`name'Density"', replace) legend(off) `mergedopts'  `uniqueopts' || if `touse'
		}

		foreach param in xi ret {
			if "``param'profile'"!="" {
				local 0 ``param'profile'
				syntax anything, `=cond("`param'"=="ret", "PERiod(real)", "")'
				parse_numlist, numlist("`anything'") min(2)
				local numlist `s(numlist)'
				preserve
				qui keep if e(sample)
				tempname b Cns hold yp t t2
				tempvar x ll depvar
				mat `b' = e(b)
				mat `Cns' = e(`Cns')
				if `Cns'[1,1]==. mat drop `Cns'
				if "`param'"!="ret" local mlcmd ml model lf2 extreme_lf2()
					else {
						local mlcmd ml model lf extreme_return_lf()
						if "`e(model)'"=="gev" {
							scalar `yp' = -1/ln(1-1/`period')
							mat `b'[1,2] = `b'[1,1]+exp(`b'[1,2])*ln(`yp') // starting value: return level if Gumbel is mu+sig*ln(yp)
						}
						else {
							scalar `yp' = `period'*e(zeta)
							mat `b'[1,1] = exp(`b'[1,1])*ln(`yp')
						}
					}
				mata _extremeDepVar = .
				if e(model)=="gev" {
					local mlcmd `mlcmd' (mu:`e(muvars)')
					mata st_view(_extremeDepVar, ., st_global("e(depvar)"))
				}
				else {
					gen double `depvar' = `e(depvar)' - `e(threshold)'
					mata st_view(_extremeDepVar, ., "`depvar'")
				}
				local mlcmd `mlcmd' (lnsig:`e(sigvars)') /xi  [`e(wtype)'`wexp'], collinear nopreserve constraints(`Cns') nocnsnotes
				_est hold `hold'
				`mlcmd'
				ml init `b', copy
				_estimates unhold `hold'
				mata moptimize_init_userinfo($ML_M, 3, extreme_est_prep(_extremeDepVar))
				mata moptimize_init_userinfo($ML_M, 2, _extremeDepVar)
				mata moptimize_init_userinfo($ML_M, 1, "`e(model)'"=="gev")
				mata _extremeNumlist = strtoreal(tokens(st_local("numlist")))
				if "`param'"=="ret" {
					mata moptimize_init_userinfo($ML_M, 3, st_numscalar("`yp'"))
					if e(model)=="gpd" mata _extremeNumlist = _extremeNumlist:-`e(threshold)'
					mata _extremeProfileLL = extreme_profile($ML_M, `=e(k)-1', "return level", _extremeNumlist, 0)
				}
					else mata _extremeProfileLL = extreme_profile($ML_M, `e(k)', "xi", _extremeNumlist, 0)
				ml clear
				cap getmata (`x' `ll') = _extremeProfileLL, force
				if !_rc {
					if e(model)=="gpd" & "`param'"=="ret" replace `x' = `x' + `e(threshold)'
					label var `ll' "Profile log likelihood"
					label var `x' `"`=cond("`param'"=="xi", "xi", "Return level")'"'
					local profilell = e(ll) - invchi2(1,`level'/100)/2
					sum `x' if `ll'>=`profilell' & `ll'<., meanonly
					cap assert r(N)==0
					if _rc cap assert !(`x'>`r(max)' & `ll'<`profilell')
					if _rc cap assert !(`x'<`r(min)' & `ll'<`profilell')
					if _rc {
						local sigdigs = 10 ^ (floor(log10(max(abs(r(min)),abs(r(max))))) - 2)
						di as res "Profile-based `level'% confidence interval for `:var label `x'': [" round(`r(min)',`sigdigs') ", " round(`r(max)',`sigdigs') "]"
						mat `t' = `level', `r(min)', `r(max)'
						mat colnames `t' = ConfLevel Min Max
						if "`param'"=="xi" local profilemid = [xi]_cons
							else {
								local profilemid = `=cond(e(model)=="gev", "[mu]_cons", "`e(threshold)'")' + exp([lnsig]_cons)*(`yp'^[xi]_cons-1)/[xi]_cons
								mat `t2' = `period'
								mat colnames `t2' = RetPeriod
								mat `t' = `t2', `t'
							}
						ereturn matrix `param'profileCI = `t'
						local xlineopt xline(`r(min)' `profilemid' `r(max)', lpattern(dash)) yline(`profilell') 
					}
					else di as res "Profile-based `level'% confidence for `:var label `x'' interval appears to extend beyond graphing bounds. Could not be constructed. Try widening the bounds."
					line `ll' `x', `xlineopt' `lineopts' name(`name'`=proper("`param'")'Profile, replace) `mergedopts' `uniqueopts'
				}
				restore
				mata mata drop _extremeDepVar _extremeProfileLL _extremeNumlist
				cap mata mata drop _extremeYp
			}
		}
	}
end

// built-in _get_eformopts and _get_diopts don't align with ml display option sets
// This routine extracts all acceptable ml display options
cap program drop _get_mldiopts
program define _get_mldiopts, sclass
	syntax, [NOHeader NOFOOTnote First neq(passthru) SHOWEQns PLus NOCNSReport NOOMITted vsquish NOEMPTYcells BASElevels ALLBASElevels cformat(passthru) pformat(passthru) sformat(passthru) NOLSTRETCH coeflegend *]
	sreturn local diopts `noheader' `nofootnote' `first' `neq' `showeqns' `plus' `nocnsreport' `noomitted' `vsquish' `noemptycells' `baselevels' `allbaselevels' `cformat' `pformat' `sformat' `nolstretch' `coeflegend' `shr'
	sreturn local options `options'
end

cap program drop _get_kdensopts
program define _get_kdensopts, sclass
	syntax, [BWidth(passthru) Kernel(passthru) Range(passthru) n(passthru) area(passthru) HORizontal *]
	sreturn local kdensopts `bwidth' `kernel' `range' `n' `area' `horizontal'
	sreturn local options `options'
end

cap program drop Display
program Display
	version 11.0
	syntax [, Level(int $S_level) *]
	ml display, level(`level') `options' `e(diparmopts)'
end

// parse a numlist. If it has 2 entries, interpret them as bounds with 100 steps between
// if either of the 2 is missing and optional variable name provided, then interpret them as variable's min/max over entire data set
cap program drop parse_numlist
program define parse_numlist, sclass
	version 11.0
	syntax, numlist(string) min(string) [var(string)]
	numlist "`numlist'", min(`min') `=cond(`"`var'"'!="", "missingok", "")'
	if `: word count `r(numlist)''==2 {
		tokenize `r(numlist)'
		if `1'>=. | `2'>=. {
			sum `var', meanonly
			if `1'>=. local 1 = r(min)
			if `2'>=. local 2 = r(max)
		}
		numlist "`1'(`=(`2'-`1'-epsdouble())/100')`2'"
	}
	else numlist "`r(numlist)'", sort
	sreturn local numlist `r(numlist)'
end
 
* 1.1.0 Added small(bs). Fixed bugs.
