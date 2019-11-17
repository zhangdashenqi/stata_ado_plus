*** program for NB2 with multinomial endogeneity           ***
*** 5 parts: 1. this routine; 2. ml for mixed mlogit;      ***
*** 3. ml for joint mmlogit and nb2 (mtreatnb);            ***
*** 4. mata mmlogit; 5; mata mtreatnb;                     ***
***                                                        ***
*** author: Partha Deb                                     ***
*** written: January 16, 2006                              ***
*** modified: August 25, 2006                             ***

program mtreatnb, sortpreserve
	version 9.1

	if replay() {
		if ("`e(cmd)'" != "mtreatnb") error 301
		Replay `0'
	}
	else Estimate `0'
end

program Estimate, eclass

	// parse the command
	syntax varlist [fweight pweight aweight iweight] [if] [in] ///
		, MTREATment(string) SIMulationdraws(integer) [BASEcategory(string) ///
		Robust CLuster(varname) ALTSTart(string) ALTFACtors(string) ///
		PREfix(string) SCAle(integer 1) STARTpoint(integer 20) VERbose *]
	mlopts mlopts, `options'

	cap macro drop MMLOGIT_* MTREATNB_*

	if "`prefix'"=="" capture drop _I*
	else capture drop `prefix'*

	if "`cluster'" != "" {
		local clopt cluster(`cluster')
	}

	if "`weight'" != "" {
		tempvar wvar
		quietly gen double `wvar' `exp'
		local wgt "[`weight'=`wvar']"
		local awgt "[aw=`wvar']"
	}

	// mark the estimation sample
	marksample touse
	markout `touse' `wvar'
	markout `touse' `cluster', strok

	gettoken lhs rhs : varlist
  _rmcoll `rhs' `wgt' if `touse', `constant'
  local rhs `r(varlist)'

	gettoken mtreat mrhs : mtreatment
  _rmcoll `mrhs' `wgt' if `touse', `constant'
  local mrhs `r(varlist)'

	tempvar mtvar 
	tempname mlabel

	qui egen `mtvar' = group(`mtreat') if `touse', lname(`mlabel')

	tempname N altlevels
	local tabwgt  "`weight'"
	if ("`tabwgt'" == "pweight") local tabwgt "iweight"
	qui tabulate `mtreat' [`tabwgt'`exp'] if `touse', matcell(`N') matrow(`altlevels')
	local nalt = r(r)
	if `nalt' < 3 {
		di as error "there are `nalt' outcomes in `mtreat'; the minimum " ///
		 "number of outcomes is 3"
		exit 148
	}
	if `nalt' > 10 {
		di as error "there are `nalt' outcomes in `mtreat'; the maximum " ///
		 "number of outcomes is 10"
		exit 149
	}

	if "`basecategory'" == "" {
		/* mimic -mlogit-: use maximum frequency as default base outcome */
		local ni = `N'[1,1]
		local ibase = 1
		local basecategory = `altlevels'[1,1]
		forvalues i=2/`nalt' {
			if `N'[`i',1] > `ni' {
				local ni = `N'[`i',1]
				local ibase = `i'
				local basecategory = `altlevels'[`i',1]
			}
		}
	}
	else {
		local altlabels : value label `mtreat'
		AlternativeIndex "`altlevels'" "`altlabels'" "`basecategory'" "`mtreat'" 
		local ibase = r(index)
	}

	tempname bintvar
	qui tab `mtvar' if `touse', gen(`bintvar')

	_labels2names `mtreat' `if', stub(_outcome_) noint
	local altlabels `"`s(names)'"'
	local nalt = `s(n_cat)'

	forvalues i=1/`nalt' {
		if (`i' == `ibase') continue
		local ai : word `i' of `altlabels'
		if "`prefix'"=="" local newname`i' "_I`ai'"
		else local newname`i' `"`prefix'`ai' "'
		rename `bintvar'`i' `newname`i''
		local ymmlnames `"`ymmlnames' `newname`i''"'
		local mmlmodel `"`mmlmodel' (`ai': `newname`i'' = `mrhs')"'
		local mtvars `"`mtvars' `newname`i''"'
		local lam`i' "/lambda_`ai'"
		local lamname `" `lamname' `lam`i'' "'
	}
		local nbmodel `"`lhs' `mtvars' `rhs'"'
		local mtnbmodel `"`mmlmodel' (`lhs': `lhs' = `mtvars' `rhs') /lnalpha `lamname' "'

	preserve
	qui keep if `touse'

	forvalues i=1/`=`nalt'-1' {
		gettoken yname ymmlnames: ymmlnames
		if (`i'==1) {
			local ymmlnamesinquotes `" " `yname' " "'
		}
		else {
			local ymmlnamesinquotes `" `ymmlnamesinquotes' ," `yname' " "'
		}
	}

	local xmmlnames `mrhs'
	local colsofx : word count `xmmlnames'
	forvalues i=1/`colsofx' {
		gettoken xname xmmlnames: xmmlnames
		if (`i'==1) {
			local xmmlnamesinquotes `" " `xname' " "'
		}
		else {
			local xmmlnamesinquotes `" `xmmlnamesinquotes' ," `xname' " "'
		}
	}

	local xnbnames "`mtvars' `rhs'"
	local colsofx : word count `xnbnames'
	forvalues i=1/`colsofx' {
		gettoken xname xnbnames: xnbnames
		if (`i'==1) {
			local xnbnamesinquotes `" " `xname' " "'
		}
		else {
			local xnbnamesinquotes `" `xnbnamesinquotes' ," `xname' " "'
		}
	}

	GLOBALS "`nalt'"

	qui sum `touse'
	scalar nobs = r(sum)
	scalar neq = $MMLOGIT_neq
	scalar neqall = $MTREATNB_neq
	scalar sim = `simulationdraws'

	mata: _mtreatnb_ymml = st_data(., (`ymmlnamesinquotes'))
	mata: _mtreatnb_xmml = st_data(., (`xmmlnamesinquotes'))
	mata: _mtreatnb_ynb = st_data(., ("`lhs'"))
	mata: _mtreatnb_xnb = st_data(., (`xnbnamesinquotes'))

	mata:	_mtreatnb_nobs = st_numscalar("nobs")
	mata: _mtreatnb_rnd = `scale'*invnormal(halton(_mtreatnb_nobs ///
												*`simulationdraws',$MMLOGIT_neq,`startpoint',0))
	mata: _mtreatnb_rmat=.

	forvalues i=1/$MMLOGIT_neq {
		mata: _mtreatnb_rnd`i'=colshape(_mtreatnb_rnd[,`i'],`simulationdraws')
		if (`i'==1) mata: _mtreatnb_rmat = _mtreatnb_rnd`i'
		else mata: _mtreatnb_rmat = (_mtreatnb_rmat, _mtreatnb_rnd`i')
		mata: mata drop _mtreatnb_rnd`i'
	}
	mata: mata drop _mtreatnb_rnd

	tempname s
	if `"`altstart'"' == "" {
		qui mlogit `mtvar' `mrhs', base(`ibase')
		mat `s'=e(b)
		local contin init(`s',copy) search(off)

		di in green "Fitting mixed multinomial logit regression for treatments:"
		ml model d2 mmlogit_lf `mmlmodel' , `robust' `clopt' `mlopts' ///
			`contin' missing nopreserve maximize
		if "`verbose'"=="verbose" {
			ml display
			}
		mat `s'=e(b)
		scalar ll_mmlogit = e(ll)
		di " "
		di in green "Fitting negative binomial regression for outcome:"
		if "`verbose'"=="verbose" {
			nbreg `nbmodel', `robust' `clopt'
		}
		else {
			nbreg `nbmodel', `robust' `clopt' nodisplay
		}
		scalar ll_nbreg = e(ll)
		if `"`altfactors'"'=="" {
			mat `s'=(`s',e(b),J(1,$MMLOGIT_neq,0))
		}
		else mat `s'=(`s',e(b),`altfactors') 
	}

	else {
		mat `s' = `altstart'
		scalar ll_mmlogit = .
		scalar ll_nbreg = .
	}
	
	local contin init(`s',copy) search(off)

	local title "Multinomial treatment-effects NB regression"
	di " "
	di in green "Fitting full model for treatments and outcome:"
	ml model d2 mtreatnb_lf `mtnbmodel' ///
			, title(`title') `robust' `clopt' `mlopts' `contin' missing ///
			nopreserve maximize waldtest(`=$MMLOGIT_neq+1')

	ereturn scalar k_aux = `=$MMLOGIT_neq+1'
	ereturn scalar i_base = `ibase'
	ereturn scalar simulationdraws = sim
	ereturn scalar ll_exog = ll_mmlogit + ll_nbreg
	ereturn local cmd mtreatnb
	ereturn local outcome `mtreat'

	Replay `mtreat'
restore
end 


program Replay

		if `e(k_aux)' {
			local alpha diparm(lnalpha, exp label(alpha)) 
		}
		ml display, `alpha'

		local i = `e(i_base)'
	_labels2names `e(outcome)', stub(_outcome_) noint
	local altlabels `"`s(names)'"'
		local b : word `i' of `altlabels'
		local s = `e(simulationdraws)'
		di in yellow `"{p}Notes:{p_end}"'
		di in gr `"{p}1. `b' is the base outcome{p_end}"'
		di in gr `"{p}2. `s' Halton sequence-based quasirandom draws per observation{p_end}"'
		ml_footnote

end


program AlternativeIndex, rclass
	args  altlevels altlabels level choice

	local index = .
	local nalt = rowsof(`altlevels')
	if "`level'"!="" {
		local i = 0
		while `++i'<=`nalt' & `index'>=. {
			local ialt = `altlevels'[`i',1]
			if (`"`level'"'==`"`ialt'"') local index = `i'
		}
		if `index'>=. & "`altlabels'"!="" {
			local i = 0
			while `++i'<=`nalt' & `index'>=. {
				local label : label `altlabels' `=`altlevels'[`i',1]'
				if (`"`level'"'==`"`label'"') local index = `i'
			}
		}
		if `index'>=. {
			di as error "{p}baseoutcome(`level') is not an "   ///
	"outcome of `choice'; use {help tabulate##|_new:tabulate} for a " ///
			 "list of values{p_end}"
			exit 459
		}
	}
	return local index = `index'
end 


program GLOBALS
	args nalt

	global MMLOGIT_neq = `nalt'-1
	global MTREATNB_neq = 2*$MMLOGIT_neq+2

	forvalues i=1/$MMLOGIT_neq {
		local L_g `"`L_g' g`i'"'
	}
	global MMLOGIT_g `"`L_g'"'

	forvalues i=`=$MMLOGIT_neq+1'/9 {
		local L_gr `"`L_gr' g`i'"'
	}
	global MMLOGIT_gr `"`L_gr'"'

	forvalues i=10/`=$MMLOGIT_neq+12' {
		local L_g `"`L_g' g`i'"'
	}
	global MTREATNB_g `"`L_g'"'

	forvalues i=`=$MMLOGIT_neq+12'/20 {
		local L_gr `"`L_gr' g`i'"'
	}
	global MTREATNB_gr `"`L_gr'"'

end
