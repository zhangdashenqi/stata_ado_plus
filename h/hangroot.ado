*! version 1.4.4 MLB 20Feb2011
* Add the logistic distribution
* use Stata's gammaden() function instead of my own formula
* version 1.4.2 MLB 03Jan2010
* fix sort order in the theoretical distribution
* version 1.4.1 MLB 04Dec2009
* implement the empirical distribution
* version 1.4.0 MLB 19Nov2009
* Implemented the suspended rootogram
* version 1.3.0 MLB 17Nov2009
* added the par() option and the Chi square distribution
* version 1.2.3 MLB 15Jan2008
* fixed bug when filling in zero bins when the number of bins is larger 
* than the number of observations in the dataset
* fixed bug with -discrete- option
* version 1.2.2 MLB 23Dec2007
* implemented the log-normal, Weibull, gamma, Gumbel, inverse gamma, 
* Wald, Fisk, Dagum, Singh-Maddala, Generalized Beta II, and the
* generalized extreme value distribution
* version 1.2.1 MLB 17Dec2007
* Fixed bug in axis title options, and changed default legend
* with beta distribution only use those cases between 0 and 1
* integrated hangroot with betafit and paretofit
* version 1.2.0 MLB 29Nov2007
* added exponential, laplace, uniform, geometric distribution
* changed to dist option instead of normal poisson etc options
* added plot, and ci options
* version 1.1.1 MLB 27Nov2007
* corrected a bug in the calculations of the hight of the bars	
* version 1.1.0 MLB 10Nov2007
* correct bug in passing thru options to -twoway rspike-/-twoway rbar-
* added beta, pareto and poisson distribution
* allowed fweights
* version 1.0.0 MLB 04Nov2007
program define hangroot, rclass sortpreserve
	version 9.2
	syntax  [varname(default=none)] ///
	[if] [in] [fweight /] [,          ///
	SPike                           /// default 
	BAR                             /// 
    DIST(string)                    ///
    ci                              ///
    par(numlist)                    /// overwrite parameters
	SUSPended                       ///	suspended rootogram
	noTHEORetical                   /// suppress display of theoretical distribution
    Level(integer $S_level)         /// 
	BIN(passthru)                   /// number of bins
	Width(passthru)                 /// width of bins
	START(passthru)                 /// first bin position
	Discrete                        ///
	LEGend(passthru)                ///
	YTItle(passthru)                ///
	XTItle(passthru)                ///
	MAINOpt(string)                 /// options for the main graph (counts or residuals)
	CIOpt(string)                   /// options for the confidence intervals
	THEOROpt(string)                /// options for the theoretical distribution
	BY(varlist)                     /// not allowed
	HORizontal                      /// not allowed
	VERTical                        /// not allowed
	plot(str asis)                  /// extra overlaid graph
	*                               /// options sent to -twoway rbar-/ -twoway rspike-
	]

    // TLAs (may be) allowed for distribution options 
	local l = max(4, length("`: word 1 of `dist''"))

	// second element in dist() is grouping variable name if dist() is theoretical distribution
	local groupvar : word 2 of `dist'
	local dist : word 1 of `dist'
	if "`dist'" == substr("theoretical", 1, `l') & "`groupvar'" == "" {
		di as err "two elements must be specified in the dist() option when specifying the theoretical distribution in the dist() option"
		di as err "the second element must be the grouping variable"
		exit 198
	}
	if "`dist'" == substr("theoretical", 1, `l') {
		confirm variable `groupvar'
	}
	
	// case-insensitive (allowing Gaussian, Weibull, etc.) 
	local dist = lower("`dist'") 
	
	marksample touse
	markout `touse' `groupvar', strok
	
	if "`varlist'" != "" & "`dist'" == "dagum" & "`par'" == "" {
		di as error "the best fitting dagum distribution must be fit using dagumfit"
		di as error "first estimate the model without covariates and than type hangroot without varlist"
		di as error "or fix the paremters using the par() option"
		exit 198
	}
	if "`varlist'" != "" & "`dist'" == "sm" & "`par'" == "" {
		di as error "the best fitting Singh-Maddala distribution must be fit using smfit"
		di as error "first estimate the model without covariates and than type hangroot without varlist"
		di as error "or fix the paremters using the par() option"
		exit 198
	}
	if "`varlist'" != "" & "`dist'" == "gb2" & "`par'" == "" {
		di as error "the best fitting Generalized Beta (Second Kind) distribution must be fit using gb2fit"
		di as error "first estimate the model without covariates and than type hangroot without varlist"
		di as error "or fix the paremters using the par() option"
		exit 198
	}
	if "`varlist'" != "" & "`dist'" == "gevfit" & "`par'" == "" {
		di as error "the best fitting generalized extreme value distribution must be fit using gevfit"
		di as error "first estimate the model without covariates and than type hangroot without varlist"
		di as error "or fix the paremters using the par() option"
		exit 198
	}
	
	if "`varlist'" == "" & "`weight'" != "" {
		di as err "weights may not be specified in the post-estimation syntax"
		di as err "the weights will be copied from the last estimation command"
		exit 198
	}
	if "`varlist'" == "" & "`if'`in'" != "" {
		di as err "the if and in qualifiers may not be specified in the post-estimation syntax"
		di as err "these will be copied from the last estimation command"
		exit 198
	}

	if "`suspended'" == "" & "`theoretical'" != "" {
		di as error "the notheoretical option can only be specified when the suspended option is specified"
		exit 198
	}
	
	if "`theoretical'" != "" & `"`theoropt'"' != "" {
		di as error "the theoropt() option can not be specified together with the notheoretical option"
		exit 198
  	}
	
	if "`ci'" == "" & `"`ciopt'"' != ""  {
		di as error "the ciopt() option can only be specified together with the ci option"
		exit 198
	}
	
	local XXfit = 0
	if "`varlist'" == "" {
		if ("`e(cmd)'" == "betafit"     & "`e(alpha)'`e(beta)'`e(mu)'`e(phi)'" != "") | ///
		   ("`e(cmd)'" == "paretofit"   & `e(nocov)' ) | ///
		   ("`e(cmd)'" == "lognfit"     & `e(nocov)')  | ///
		   ("`e(cmd)'" == "gammafit"    & "`e(alpha)'`e(beta)'" != "") | ///
		   ("`e(cmd)'" == "gumbelfit"   & "`e(mu)'`e(alpha)'" != "") | ///
		   ("`e(cmd)'" == "invgammafit" & "`e(alpha)'`e(beta)'" != "") | ///
		   ("`e(cmd)'" == "invgaussfit" & "`e(mu)'`e(lambda)'" != "") | ///
		   ("`e(cmd)'" == "dagumfit"    & `e(nocov)') | ///
		   ("`e(cmd)'" == "smfit"       & `e(nocov)') | ///
		   ("`e(cmd)'" == "gb2fit"      & `e(nocov)') | ///
		   ("`e(cmd)'" == "fiskfit"     & `e(nocov)') | ///
		   ("`e(cmd)'" == "gevfit"      & `e(nocov)'){
			local varlist "`e(depvar)'"
			local weight "`e(wtype)'"
			local exp "`e(wexp)'"
			qui replace `touse' = e(sample)
			local XXfit = 1
		}
		else if "`e(cmd)'" == "weibullfit" {
			if `e(length_b_b)' == 1 & `e(length_b_c)' == 1 {
				local varlist "`e(depvar)'"
				local weight "`e(wtype)'"
				local exp "`e(wexp)'"
				qui replace `touse' = e(sample)
				local XXfit = 1
			}
		}
		else {
			di as err "varlist required when hangroot is not preceded by" 
			di as err "betafit, paretofit, lognfit, weibullfit, gammafit," 
			di as err "gumbelfit, invgammafit, invgaussfit, dagumfit,"
			di as err "smfit, gb2fit, fiskfit, or gevfit"
			di as err "and these models need to be estimated without covariates"
			exit 100
		}
	}
	
	// distribution defaults to beta if betafit was the last model estimated
	//                       to paretao if paretofit was the last model estimated   
	//                       to lognormal if lognfit was the last model estimated
	//                       to weibull if weibullfit was the last model estimated
	//                       to gamma if gammafit was the last model estimated
	//                       to gumbel if gumbelfit was the last model estimated
	//                       to invgamma if invgammafit was the last model estimated
	//                       to wald if invgaussfit was the last model estimated
	//                       to dagum if dagumfit was the last model estimated
	//                       to sm if smfit was the last model estimated
	//                       to gb2 if gb2fit was the last model estimated
	//                       to fisk if fiskfit was the last model estimated
	// otherwise the default is normal (Gaussian) 
	if "`dist'" == "" {
		if "`e(cmd)'" == "betafit" & "`e(alpha)'`e(beta)'`e(mu)'`e(phi)'" != "" {
			local dist beta
		}
		else if "`e(cmd)'" == "paretofit" & `e(nocov)' {
			local dist pareto
		}
		else if "`e(cmd)'" == "lognfit" & `e(nocov)' {
			local dist lognormal
		}
		else if "`e(cmd)'" == "weibullfit" {
			if `e(length_b_b)' == 1 & `e(length_b_c)' == 1 {
				local dist weibull
			}
		}
		else if "`e(cmd)'" == "gammafit" & "`e(alpha)'`e(beta)'" != "" {
			local dist gamma
		}
		else if "`e(cmd)'" == "gumbelfit" & "`e(mu)'`e(alpha)'" != "" {
			local dist gumbel
		}
		else if "`e(cmd)'" == "invgammafit" & "`e(alpha)'`e(beta)'" != "" {
			local dist invgamma
		}
		else if "`e(cmd)'" == "invgaussfit" & "`e(mu)'`e(lambda)'" != "" {
			local dist wald
		}
		else if "`e(cmd)'" == "dagumfit" & `e(nocov)' {
			local dist dagum
		}
		else if "`e(cmd)'" == "smfit"       & `e(nocov)' {
			local dist sm
		}
		else if "`e(cmd)'" == "gb2fit" & `e(nocov)' {
			local dist gb2
		}
		else if "`e(cmd)'" == "fiskfit"       & `e(nocov)' {
			local dist fisk
		}
		else if "`e(cmd)'" == "gevfit"      & `e(nocov)' {
			local dist gev
		}
		else {
			local dist normal
		}
	}
	else if "`dist'" == substr("normal", 1, `l')  |  /// 
		"`dist'" == substr("gaussian", 1, `l') {  
		local dist normal 
	}	
	else if "`dist'" == substr("poisson", 1, `l') {
		local dist poisson
	}
	else if "`dist'" == substr("beta", 1, `l') {
		local dist beta
	}
	else if "`dist'" == substr("pareto", 1, `l') {
		local dist pareto
	}
	else if "`dist'" == substr("exponential", 1, `l') {
		local dist exponential
	}
	else if "`dist'" == substr("laplace", 1, `l') {
		local dist laplace
	}
	else if "`dist'" == substr("uniform", 1, `l') {
		local dist uniform
	}
	else if "`dist'" == substr("geometric", 1, `l') {
		local dist geometric
	}
	else if "`dist'" == substr("lognormal", 1, `l') {
		local dist lognormal
	}
	else if "`dist'" == substr("weibull", 1, `l') {
		local dist weibull
	}
	else if "`dist'" == substr("gamma", 1, `l') {
		local dist gamma
	}
	else if "`dist'" == substr("gumbel", 1, `l') {
		local dist gumbel
	}
	else if "`dist'" == substr("invgamma", 1, `l') {
		local dist invgamma
	}
	else if "`dist'" == substr("wald", 1, `l') {
		local dist wald
	}
	else if "`dist'" == substr("dagum", 1, `l') {
		local dist dagum
	}
	else if "`dist'" == "sm" {
		local dist sm
	}
	else if "`dist'" == "gb2" {
		local dist gb2
	}
	else if "`dist'" == substr("fisk", 1, `l') {
		local dist fisk
	}
	else if "`dist'" == "gev" {
		local dist gev
	}
	else if "`dist'" == "chi2" {
		local dist chi2 
	}	
	else if "`dist'" == substr("logistic", 1, `l'){
		local dist logistic
	}
	else if "`dist'" == substr("theoretical", 1, `l') {
		local dist "theoretical"
	}
	else {
		di as err "distribution `dist' not recognized"
		exit 198
	}

	local kpar : word count `par'
	if inlist("`dist'", "poisson", "exponential", "geometric", "chi2") & !(`kpar' == 0 | `kpar' == 1) {
		di as error "`kpar' parameters where specified in the par() option while the `dist' distribution contains 1 parameter"
		exit 198
	}
	if (inlist("`dist'", "normal", "beta", "pareto", "laplace", "uniform", ///
	                     "lognormal", "weibull", "gumbel", "invgamma") | ///
	   inlist("`dist'", "wald", " fisk", "gamma", "logistic")) & !(`kpar' == 0 | `kpar' == 2 ) {
	   	di as error "`kpar' parameters where specified in the par() option while the `dist' distribution contains 2 parameter"
	   	exit 198
	}
	if inlist("`dist'", "dagum", "sm", "gev") & !(`kpar' == 0 | `kpar' == 3) {
		di as error "`kpar' parameters where specified in the par() option while the `dist' distribution contains 3 parameter"
		exit 198
	}
	if inlist("`dist'", "gb2") & !(`kpar' == 0 | `kpar' == 4) {
		di as error "`kpar' parameters where specified in the par() option while the `dist' distribution contains 4 parameter"
		exit 198
	}

	//poisson and geometric implies discrete
	if "`dist'" == "poisson" | ///
	   "`dist'" == "geometric" {
		local discrete "discrete"
	}
	
	//exponential, poisson, geometric, lognormal, weibull, and gamma only valid for values >= 0
	if "`dist'" == "exponential" | ///
	   "`dist'" == "poisson"     | ///
	   "`dist'" == "geometric"   | ///
	   "`dist'" == "lognormal"   | ///
	   "`dist'" == "weibull"     | ///
	   "`dist'" == "gamma"       | ///
	   "`dist'" == "chi2" {
		qui count if `varlist' < 0 & `touse'
		if r(N) > 0 {
			local s = cond(r(N)>1,"s","")
			local have = cond(r(N)>1,"have","has")
			local these = cond(r(N)>1,"these","this")
			di as txt "warning: `r(N)' observation`s' `have' a value less than 0"
			di as txt "`these' observation`s' will be ignored"
			tempvar out
			gen byte `out' = 0 if `varlist' >= 0 /* missing means do not use*/
			markout `touse' `out'
		}
	}
	
	// pareto, invgamma, wald, fisk, dagum, sm, and gb2  only valid for values > 0
	if "`dist'" == "pareto"   | ///
	   "`dist'" == "invgamma" | ///
	   "`dist'" == "wald"     | ///
	   "`dist'" == "fisk"     | ///
	   "`dist'" == "dagum"    | ///
	   "`dist'" == "sm"       | ///
	   "`dist'" == "gb2" {
		qui count if `varlist' <= 0 & `touse'
		if r(N) > 0 {
			local s = cond(r(N)>1,"s","")
			local have = cond(r(N)>1,"have","has")
			local these = cond(r(N)>1,"these","this")
			di as txt "warning: `r(N)' observation`s' `have' a value less than"
			di as txt "or equal to 0, `these' observation`s' will be ignored"
			tempvar out
			gen byte `out' = 0 if `varlist' > 0 /* missing means do not use*/
			markout `touse' `out'
		}
	}
	
	// beta only valid for values > 0 & < 1
	if "`dist'" == "beta" {
		qui count if (`varlist' <= 0 | `varlist' >= 1) & `touse'
		if r(N) > 0 {
			local s = cond(r(N)>1,"s","")
			local have = cond(r(N)>1,"have","has")
			local these = cond(r(N)>1,"these","this")
			di as txt "warning: `r(N)' observation`s' `have' a value less than or equal to 0"
			di as txt "or more than or equal to 1, `these' observation`s' will be ignored"
			tempvar out
			gen byte `out' = 0 if  (`varlist' <= 0 | `varlist' >= 1) /* missing means do not use*/
			markout `touse' `out'	
		}
	}
	
	//poisson and geometric only valid for discrete values (including 0)
	if "`dist'" == "poisson" | ///
	   "`dist'" == "geometric" {
		qui count if mod(`varlist',1) != 0 & `varlist' != 0 & `touse'
		if r(N) > 0 {
			local s = cond(r(N)>1,"s","")
			local these = cond(r(N)>1,"these","this")
			di as txt "warning: `r(N)' observation`s' have a non-integer value"
			di as txt "`these' observation`s' will be ignored"
			tempvar out2
			gen byte `out2' = 0 if mod(`varlist',1) == 0 | ///
			                       `varlist' == 0 /* missing means do not use*/
			markout `touse' `out2'
		}
	}

	qui count if `touse'
	if r(N) == 0 {
		di as err "no observations"
		exit 2000
	}
	
	// remove options that may not be passed on to -twoway rspike- or -twoway rbar-
	if `"`by'"' != "" {
		local err "by() "
	}
	if "`horizontal'" != "" {
		local err "`err'horizontal "
	}
	if "`vertical'" != "" {
		local err "`err'vertical "
	}
	if "`err'" != "" {
		local s = cond(`: word count `err''>1,"s","")
		di as err "option`s' `err'not allowed"
		exit 198
	}

	// default graph type is spike
	if "`spike'`bar'" == "" {
		local spike "spike"
	}
	
	if "`spike'" != "" & "`bar'" != "" {
		di as err "options spike and bar may not be combined"
		exit 198
	}
	

	if "`weight'" != "" {
		local wght "[`weight' = `exp']"
	}
	
	if "`suspended'" != "" local minus "-"

	tempvar newobs
	qui gen byte `newobs' = 0
	
	tempvar h x theor floor t step
	if "`dist'" != "theoretical" {
		twoway__histogram_gen2 `varlist' if `touse' `wght', ///
		gen(`h' `x') display `bin' `width' `start' `discrete'
		local w = r(width)
		local min = r(min)
		local max = r(max)
		local nobs = r(N)
		local nbins = r(bin)
	}
	else {
		tokenize `levs'
		sum `varlist' `wght' if `groupvar' & `touse', meanonly
		local nobstheor = r(sum_w)
		local mintheor = r(min)
		local maxtheor = r(max)
		sum `varlist' `wght' if !`groupvar' & `touse', meanonly
		local nobsemp = r(sum_w)
		local minemp = r(min)
		local maxemp = r(max)
		
		local max     = max(`maxtheor', `maxemp')
		local min     = min(`mintheor', `minemp')
		local nobsmin = min(`nobstheor', `nobsemp')
		if "`discrete'" != "" {
			di as err "option discrete not allowed with the empricial distribution"
			exit 198
		}
		if "`bin'`width'" == "" {
			local bin =  ceil(min(sqrt(`nobsmin'), 10*ln(`nobsmin')/ln(10)))
			local bin "bin(`bin')"
		}
		if "`start'" == "" {
				local start "start(`min')"
		}
		
		tempvar theor theorgr
	
		twoway__histogram_gen2 `varlist' if `touse' & `groupvar' `wght', ///
		gen(`theor' `x') `bin' `width' `start' `discrete' tmax(`max')
		qui drop `x'
		
		// !`groupvar' does not include missing values in `groupvar' as these have
		// been filtered out in `touse'
		twoway__histogram_gen2 `varlist' if `touse' & !`groupvar' `wght', ///
		gen(`h' `x') display `bin' `width' `start' `discrete' tmax(`max')
		local w = r(width)
		local min = r(min)
		local max = r(max)
		local nobs = r(N)
		local nbins = r(bin)
		
		qui replace `theor' = sqrt(`theor'*`nobs'*`w')
		qui gen `theorgr' = `minus'`theor'

		tempvar x2
		qui gen `x2' = `x' - .5*`w'
		qui replace `x2' = `x2'[_n-1] + `w' in `=`nbins'+1'
		qui replace `x2' = `x2'[_n-1] in `=`nbins'+2'
		qui replace `x2' = `x2'[1] in `=`nbins'+3'
		sort `x2' `theorgr'

		qui replace `theorgr' = `theorgr'[1] in 2
		qui replace `theorgr' = 0 in 1
		qui replace `theorgr' = `theorgr'[`=`nbins'+1'] in `=`nbins'+2'
		qui replace `theorgr' = 0 in `=`nbins'+3'
		
		local gr "line `theorgr' `x2', connect(J)"
	}

	// twoway__histogram_gen2 creates new observations when #bins>N
	qui replace `newobs' = 1 if `newobs' == .

	qui sum `varlist' if `touse' `wght', detail
	local sd = r(sd)
	local var = r(Var)
	local m = r(mean)
	local median = r(p50)
	
	if "`dist'" == "normal"{
		if "`par'" != "" {
			local m : word 1 of `par'
			local sd : word 2 of `par'    
		}
		qui gen `theor' = sqrt(normden(`x', `m', `sd')*`nobs'*`w') 
		local grden "normden(x, `m', `sd')"
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')"
		return scalar mu = `m'
		return scalar sigma = `sd'
	}
	if "`dist'" == "logistic"{
		if "`par'" != "" {
			local mu : word 1 of `par'
			local s : word 2 of `par'    
		}
		else {
			local mu = `m'
			local s = `sd'*sqrt(3)/_pi
		}
		local z (`x' - `mu' )/`s'
		qui gen `theor' = sqrt(exp(-1*`z')/(`s'*(1+exp(-1*`z'))^2)*`nobs'*`w') 
		local z (x - `mu' )/`s'
		local grden "exp(-1*`z')/(`s'*(1+exp(-1*`z'))^2)"
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')"
		return scalar mu = `mu'
		return scalar s = `s'
	}
	if "`dist'" == "beta" {
		if `XXfit' & "`e(alpha)'`e(beta)'" != "" & "`par'" == "" {
			local alpha = e(alpha)
			local beta = e(beta)
			qui gen `theor' = sqrt(betaden(`alpha',`beta',`x')*`nobs'*`w')
	                local grden "betaden(`alpha',`beta',x)"
	                local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')"
	                return scalar alpha = `alpha'
	                return scalar beta = `beta'

		}
		else if `XXfit' & "`e(mu)'`e(phi)'" != "" & "`par'" == "" {
			local mu = invlogit(e(mu))
			local phi = exp(e(ln_phi))
			qui gen `theor' = sqrt(exp(lngamma(`phi') - lngamma(`mu'*`phi')- lngamma((1-`mu')*`phi'))*`x'^(`mu'*`phi' - 1)*(1-`x')^((1-`mu')*`phi' - 1)*`nobs'*`w')
			local grden "exp(lngamma(`phi') - lngamma(`mu'*`phi')- lngamma((1-`mu')*`phi'))*x^(`mu'*`phi' - 1)*(1-x)^((1-`mu')*`phi' - 1)"
			local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')"
			return scalar mu = `mu'
			return scalar phi = `phi'
		}
		else {
			if "`par'" != "" {
				local alpha : word 1 of `par'
				local beta : word 2 of `par'
			}
			else {
				local alpha = `m'*((`m'*(1-`m'))/(`var')-1)
				local beta = (1-`m')*((`m'*(1-`m'))/(`var')-1)
			}
			qui gen `theor' = sqrt(betaden(`alpha',`beta',`x')*`nobs'*`w')
	                local grden "betaden(`alpha',`beta',x)"
	                local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')"
	                return scalar alpha = `alpha'
	                return scalar beta = `beta'
		}
	}
	if "`dist'" == "poisson" {
		if "`par'" != "" {
			local lambda : word 1 of `par'
		}
		else {
			local lambda = `m'
		}
		tempvar theorgr
		qui gen `theor' = sqrt((exp(-`lambda')*`lambda'^`x'/(exp(lngamma(`x'+1))))*`nobs'*`w')
		qui gen `theorgr' = `minus'sqrt((exp(-`lambda')*`lambda'^`x'/(exp(lngamma(`x'+1))))*`nobs'*`w')
		local grden "exp(-`lambda')*`lambda'^x/(exp(lngamma(x+1)))"
		local gr "scatter `theorgr' `x', msymbol(D) || line `theorgr' `x', sort"
		return scalar lambda = `lambda'
	}
	if "`dist'" == "pareto" {
		if `XXfit' & "`par'" == "" {
			local xm = e(x0)
			local k = e(ba)
		}
		else {
			if "`par'" != "" {
				local xm : word 1 of `par'
				local k : word 2 of `par'
			}
			else {
				local xm = `min'
				tempvar temp
				qui gen double `temp' = ln(`varlist') - ln(`xm') if `touse'
				sum `temp' `wght', meanonly
				local k = r(N)/r(sum)
			}
		}
		qui gen `theor' = sqrt((`k'*`xm'^`k'/`x'^(`k'+1))*`nobs'*`w')
		local grden "`k'*`xm'^`k'/x^(`k'+1)"
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`xm' `max')" 
		return scalar x_m = `xm'
		return scalar k = `k'
	}
	if "`dist'" == "exponential" {
		if "`par'" != "" {
			local lambda : word 1 of `par'
		}
		else {
			local lambda = 1/`m'
		}
		qui gen `theor' = sqrt((`lambda'*exp(-`lambda'*`x'))*`nobs'*`w')
		local grden "`lambda'*exp(-`lambda'*x)"
		return scalar lambda = `lambda'
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')" 
	}
	if "`dist'" == "laplace" {
		if "`par'" != "" {
			local m : word 1 of `par'
			local b : word 2 of `par'
		}
		else {
			local m = `median'
			tempvar absdif
			gen `absdif' = abs(`varlist' - `m') if `touse'
			sum `absdif' `wght' if `touse', meanonly
			local b = r(mean)
		}
		qui gen `theor' = sqrt((1/(2*`b')*exp(-1*abs(`x'-`m')/`b'))*`nobs'*`w')
		local grden "1/(2*`b')*exp(-1*abs(x-`m')/`b')"
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')" 
		return scalar mu = `m'
		return scalar b = `b'
	}
	if "`dist'" == "uniform" {
		if "`par'" != "" {
			local a : word 1 of `par'
			local b : word 2 of `par'
		}
		else {
			local a = `m' - sqrt(3)*`sd'
			local b = `m' + sqrt(3)*`sd'
		}
		local range = `b'-`a'
		qui gen `theor' = sqrt((1/`range')*`nobs'*`w')
		local grden "1/`range'"
		local gr "function y = `minus'sqrt(`nobs'*`w'*`grden'), range(`a' `b')" 
		return scalar min = `a'
		return scalar max = `b'
	}
	if "`dist'" == "geometric" {
		if "`par'" != "" {
			local p : word 1 of `par'
		}
		else {
			local p = 1/(1+`m')
		}
		qui gen `theor' = sqrt(((1-`p')^(`x')*`p')*`nobs'*`w')
		tempvar theorgr
		qui gen `theorgr' = `minus'sqrt(((1-`p')^(`x')*`p')*`nobs'*`w')
		local grden "(1-`p')^(x)*`p'"
		local gr "scatter `theor' `x', msymbol(D) || line `theor' `x', sort"
		return scalar p = `p'
	}
	if "`dist'" == "lognormal" {
		if `XXfit' & "`par'" == "" {
			local mu = `e(bm)'
			local sigma = `e(bv)'
		}
		else {
			if "`par'" != "" {
				local mu : word 1 of `par'
				local sigma : word 2 of `par'
			}
			else {
				tempvar logvar
				qui gen double `logvar' = log(`varlist') if `touse'
				qui sum `logvar' if `touse' `wght'
				local mu = `r(mean)'
				// maximum likelihood does not contain the N-1 small sample correction
				local sigma = sqrt( ((`r(N)'-1)/`r(N)') * `r(Var)')
			}
		}
		qui gen `theor' = sqrt( ///
			(1 / (`x' * `sigma' * sqrt(2 * _pi))) * ///
                	exp(-(log(`x') - `mu')^2 / (2 * `sigma'^2)) *  ///
		`nobs'*`w')
		local grden "(1 / (x * `sigma' * sqrt(2 * _pi))) * exp(-(log(x) - `mu')^2 / (2 * `sigma'^2))"
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')" 
		return scalar mu = `mu'
		return scalar sigma = `sigma'
	}
	if "`dist'" == "weibull" {
		if `XXfit' & "`par'" == "" {
			tempname b c mat
			matrix `mat' = e(b)
			scalar `b' = el(`mat',1,1)
			matrix `mat' = e(c)
			scalar `c' = el(`mat',1,1)
		}
		else if "`weight'" == "" & "`par'" == "" {
			tempvar i mrank y x2
			sort `touse' `varlist'
			qui by `touse' (`varlist') : gen long `i' = _n if `touse'
			qui bys `touse' `varlist' (`i') : replace `i' = `i'[_N] if _N > 1 & `touse'
			qui gen double `mrank' = (`i' -.3)/(`nobs'+.4) if `touse'
			qui gen double `y' = ln(-1*ln((1-`mrank')))
			qui gen double `x2' = ln(`varlist')
			qui reg `y' `x2'
			local c = _b[`x2']
			local b = exp(-_b[_cons]/_b[`x2'])
		}
		else {
			if "`par'" != "" {
				local c : word 1 of `par'
				local b : word 2 of `par'
			}
			else {
				tempvar i mrank y x2
				local is "="
				local exp2 : list exp - is
				sum `exp2' if `touse', meanonly
				local nobs2 = r(sum)
				sort `touse' `varlist'
				qui by `touse' (`varlist') : gen double `i' = sum(exp2) if `touse'
				qui bys `touse' `varlist' (`i') : replace `i' = `i'[_N] if _N > 1 & `touse'
				qui gen double `y' = ln(-1*ln((1-`mrank')))
				qui gen double `x2' = ln(`varlist')
				qui reg `y' `x2'
				local c = _b[`x2']
				local b = exp(-_b[_cons]/_b[`x2'])
			}
		}
		qui gen `theor' = sqrt( (`c'/`b')*(`x'/`b')^(`c' - 1)*exp(-(`x'/`b')^`c') * `nobs'*`w')
		local grden "(`c'/`b')*(x/`b')^(`c' - 1)*exp(-(x/`b')^`c')"
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')"
		return scalar b = `b'
		return scalar c = `c'
		sort `x'
	}
	if "`dist'" == "gamma" {
		if `XXfit' & "`par'" == "" {
			local a = `e(alpha)'
			if "`e(user)'" == "gammafit_lf" {
				local b = `e(beta)'
			}
			else {
				local b = 1/`e(beta)'
			}
		}
		else {
			if "`par'" != "" {
				local a : word 1 of `par'
				local b : word 2 of `par'
			}
			else {
				tempname s a b
				tempvar log
				gen double `log' = ln(`varlist')
				sum `log' if `touse' `wght', meanonly
				scalar `s' = ln(`m') - r(mean)
				scalar `a' = (3 - `s' + sqrt((`s'-3)^2 + 24*`s'))/(12*`s')
				scalar `a' = `a' - ( ln(`a') - digamma(`a') - `s' ) / ///
								   ( 1/`a' - trigamma(`a') )
				scalar `b' = `m'/`a'
			}
		}
		qui gen `theor' = sqrt( gammaden(`a', `b', 0,`x')*`nobs'*`w')
		local grden "gammaden(`a', `b', 0, x)"
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')"
		return scalar a = `a'
		return scalar b = `b'
	}
	if "`dist'" == "gumbel" {
		if `XXfit' & "`par'" == "" {
			local a = `e(alpha)'
			local mu = `e(mu)'
		}
		else {
			if "`par'" != "" {
				local a : word 1 of `par'
				local s : word 2 of `par'
			}
			else {
				local a = `sd'*sqrt(6)/_pi
				// need to subtract gamma * a
				// gamma = - digamma(1)
				local mu = `m' + digamma(1)*`a'
			}
		}
		qui gen `theor' = sqrt(((1 / `a') * exp(-(`x' - `mu') / `a') * exp(-exp(-(`x' - `mu') / `a'))) *`nobs'*`w')
		local grden "(1 / `a') * exp(-(x - `mu') / `a') * exp(-exp(-(x - `mu') / `a'))"
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')"
		return scalar mu = `mu'
		return scalar a = `a'
	}
	if "`dist'" == "invgamma" {
		if `XXfit' & "`par'" == "" {
			local a = `e(alpha)'
			local b = `e(beta)'
		}
		else {
			if "`par'" != "" {
				local a : word 1 of `par'
				local b : word 2 of `par'
			}
			else {
				local a = (`m'^2)/`var' + 2
				local b = `m'*(`a'-1)
			}
		}
		qui gen `theor' = sqrt((`b'^`a'/exp(lngamma(`a'))*`x'^(-`a'-1)*exp(-`b'/`x'))*`nobs'*`w')
		local grden "`b'^`a'/exp(lngamma(`a'))*x^(-`a'-1)*exp(-`b'/x)"
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')"
		return scalar a = `a'
		return scalar b = `b'
	}
	if "`dist'" == "wald" {
		if `XXfit' & "`par'" == "" {
			local mu = `e(mu)'
			local l = `e(lambda)'
		}
		else {
			if "`par'" != "" {
				local mu : word 1 of `par'
				local l : word 2 of `par'
			}
			else {
				local mu = `m'
				tempvar diff
				qui gen double `diff' = 1/`varlist' - 1/`m'
				sum `diff' if `touse' `wght', meanonly
				local l = 1/r(mean)
			}
		}
		qui gen `theor' = sqrt( ///
		(sqrt(`l'/(2*_pi*`x'^3)) * exp(-`l'*(`x'-`mu')^2 / (2*`mu'^2*`x')))* ///
		`nobs'*`w')
		local grden "sqrt(`l'/(2*_pi*x^3)) * exp(-`l'*(x-`mu')^2 / (2*`mu'^2*x))"
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')"
		return scalar mu = `mu'
		return scalar lambda = `l'
	}
	if "`dist'" == "fisk" {
		if `XXfit' & "`par'" == "" {
			local a = [a]_b[_cons]
			local b = [b]_b[_cons]
		}
		else if "`weight'" == "" & "`par'" == "" {
			tempvar i mrank y x2
			sort `touse' `varlist'
			qui by `touse' (`varlist') : gen long `i' = _n if `touse'
			qui bys `touse' `varlist' (`i') : replace `i' = `i'[_N] if _N > 1 & `touse'
			qui gen double `mrank' = (`i' -.3)/(`nobs'+.4) if `touse'
			qui gen double `y' = ln(-1/(`mrank' - 1) - 1)
			qui gen double `x2' = ln(`varlist')
			qui reg `y' `x2'
			local a = _b[`x2']
			local b = 1/(exp(_b[_cons]/_b[`x2']))
		}
		else {
			if "`par'" != "" {
				local a : word 1 of `par'
				local b : word 2 of `par'
			}
			else {
				tempvar i mrank y x2
				local is "="
				local exp2 : list exp - is
				sum `exp2' if `touse', meanonly
				local nobs2 = r(sum)
				sort `touse' `varlist'
				qui by `touse' (`varlist') : gen double `i' = sum(exp2) if `touse'
				qui bys `touse' `varlist' (`i') : replace `i' = `i'[_N] if _N > 1 & `touse'
				qui gen double `y' = ln(-1/(`mrank' - 1) - 1)
				qui gen double `x2' = ln(`varlist')
				qui reg `y' `x2'
				local a = _b[`x2']
				local b = 1/(exp(_b[_cons]/_b[`x2']))
			}
		}
		qui gen `theor' = sqrt(( ///
		(`a')*((`b'/`x')^`a')*(1/`x')/(1 + (`b'/`x')^`a')^(2) ///
		)*`nobs'*`w')
		local grden "(`a')*((`b'/x)^`a')*(1/x)/(1 + (`b'/x)^`a')^(2)"
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')"
		sort `x'
	}
	if "`dist'" == "dagum" {
		if "`par'" != "" {
			local a : word 1 of `par'
			local b : word 2 of `par'
			local p : word 3 of `par'
		}
		else {
			local a = [a]_b[_cons]
			local b = [b]_b[_cons]
			local p = [p]_b[_cons]
		}
		
		qui gen `theor' = sqrt(( ///
		(`a'*`p')*((`b'/`x')^`a')*(1/`x')/(1 + (`b'/`x')^`a')^(`p'+1) ///
		)*`nobs'*`w')
		local grden "(`a'*`p')*((`b'/x)^`a')*(1/x)/(1 + (`b'/x)^`a')^(`p'+1)"
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')"
	}
	if "`dist'" == "sm" {
		if "`par'" != "" {
			local a : word 1 of `par'
			local b : word 2 of `par'
			local q : word 3 of `par'
		}
		else {
			local a = [a]_b[_cons]
			local b = [b]_b[_cons]
			local q = [q]_b[_cons]
		}
		qui gen `theor' = sqrt(( ///
		(`a'*`q'/`b')*((1 + (`x'/`b')^`a')^-(`q'+1))*((`x'/`b')^(`a'-1)) ///
		)*`nobs'*`w')
		local grden "(`a'*`q'/`b')*((1 + (x/`b')^`a')^-(`q'+1))*((x/`b')^(`a'-1))"
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')"
	}
	if "`dist'" == "gb2" {
		if "`par'" != "" {
			local a : word 1 of `par'
			local b : word 2 of `par'
			local p : word 3 of `par'
			local q : word 4 of `par'
		}
		else {
			local a = [a]_b[_cons]
			local b = [b]_b[_cons]
			local p = [p]_b[_cons]
			local q = [q]_b[_cons]
		}
		local B =  exp(lngamma(`p'))*exp(lngamma(`q'))/exp(lngamma(`p'+`q'))
		qui gen `theor' = sqrt(( ///
		`a'*`x'^(`a'*`p'-1)*((`b'^(`a'*`p'))*`B'*(1 + (`x'/`b')^`a' )^(`p'+`q'))^-1 ///
		)*`nobs'*`w')
		local grden "`a'*x^(`a'*`p'-1)*((`b'^(`a'*`p'))*`B'*(1 + (x/`b')^`a' )^(`p'+`q'))^-1"
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')"
	}
	if "`dist'" == "gev" {
		if "`par'" != "" {
			local loc : word 1 of `par'
			local scale : word 2 of `par'
			local shape : word 3 of `par'
		}
		else {
			local loc = `e(blocation)'
			local scale = `e(bscale)'
			local shape = `e(bshape)'
		}
		qui gen `theor' = sqrt(( ///
		1/`scale' * (1+`shape'*((`x'-`loc')/`scale'))^(-1-1/`shape')* ///
		exp(-1*(1+`shape'*((`x'-`loc')/`scale'))^(-1/`shape')) ///
		)*`nobs'*`w')
		local grden "1/`scale'*(1+`shape'*((x-`loc')/`scale'))^(-1-1/`shape')*exp(-1*(1+`shape'*((x-`loc')/`scale'))^(-1/`shape'))"
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')"
	}
	if "`dist'" == "chi2" {
		if "`par'" != "" {
			local v : word 1 of `par'
		}
		else {
			local v = `m'
		}
		qui gen `theor' = sqrt(gammaden(`=`v'/2',2,0,`x')*`nobs'*`w')
		local grden "gammaden(`=`v'/2',2,0,x)"
		local gr "function y = `minus'sqrt(`nobs'*`w'*(`grden')), range(`min' `max')"
		return scalar v = `v'
	}
	
	qui gen `floor' = `minus'(`theor' - sqrt(`h'*`nobs'*`w'))

	if "`ci'" != "" {
		tempvar lb ub count
		if `level' < 10 | `level' > 99 local level = 95
		local bonf = `level'/(100*`nbins')
		local B = invchi2tail(1,`bonf')
		qui gen `count' = `h'*`w'*`nobs'
		qui gen `lb' = (`B' + 2*`count' - ///
		           sqrt(`B'*(`B' + 4*`count'*(`nobs'-`count')/`nobs'))) / ///
		           (2*(`nobs' + `B'))
		qui gen `ub' = (`B' + 2*`count' + ///
			   sqrt(`B'*(`B' + 4*`count'*(`nobs'-`count')/`nobs'))) / ///
		           (2*(`nobs' + `B'))
		if "`suspended'" != "" {
			tempvar cioffset 
			qui gen `cioffset' = (sqrt(`ub'*`nobs') - sqrt(`lb'*`nobs'))/2
			qui replace `lb' = - `cioffset' /*+ cond(-`cioffset' < -`theor', `cioffset' - `theor', 0)*/
			qui replace `ub' = `cioffset'   /*+ cond(-`cioffset' < -`theor', `cioffset' - `theor', 0)*/
			if "`dist'" != "theoretical" {
				tempvar xsusp
				qui gen `xsusp' = `x'
				if _N < `nbins' + 2 {
					qui set obs `=`nbins'+2'
					qui replace `newobs' = 1 if `newobs' == .
				}
				qui replace `xsusp' = `xsusp'[1]-.5*`w' in `=`nbins'+1'
				qui replace `xsusp' = `xsusp'[`nbins']+.5*`w' in `=`nbins'+2'
				sort `xsusp'
				qui replace `lb' = `lb'[2] in 1
				qui replace `lb' = `lb'[`=`nbins'+1'] in `=`nbins'+2'
				qui replace `ub' = `ub'[2] in 1
				qui replace `ub' = `ub'[`=`nbins'+1'] in `=`nbins'+2'
			}
			else{
				tempvar xsusp
				qui gen `xsusp' = `x'
				qui replace `xsusp' = `xsusp'[1] in 2
				qui replace `xsusp' = `x2' in 1
				qui replace `xsusp' = `x2' in `=`nbins'+2'
				qui replace `lb' = `lb'[1] in 2
				qui replace `ub' = `ub'[1] in 2
				qui replace `lb' = `lb'[`=`nbins'+1'] in `=`nbins'+2'
				qui replace `ub' = `ub'[`=`nbins'+1'] in `=`nbins'+2'
			}
		}
		else {
			qui replace `lb' = `theor' - sqrt(`lb'*`nobs') 
			qui replace `ub' = `theor' - sqrt(`ub'*`nobs')
		}
		local bla = .5*`w'
		if "`spike'" != ""  & "`suspended'" == "" {
			local cispike "rbar `lb' `ub' `x', astyle(ci) barw(`bla') `ciopt'"
		}
		if "`bar'" != "" & "`suspended'" == "" {
			local cibar "rcap `lb' `ub' `x', `ciopt'"
		}	
		if "`suspended'" != "" {
			local ciarea "rarea `lb' `ub' `xsusp', astyle(ci) `ciopt'  || pci 0 `min' 0 `max', lstyle(yxline)"
		}
	}
	
	if `"`xtitle'"' == "" {
		local xtitle : variable label `varlist'
		if "`xtitle'" == "" {
			local xtitle "`varlist'"
		}
		local xtitle `"xtitle("`xtitle'")"'
	}

	if `"`ytitle'"' == "" {
		if "`theoretical'" != "" {
			local ytitle `"ytitle("sqrt(residuals)")"'
		}
		else{
			local ytitle `"ytitle("sqrt(frequency)")"'
		}
	}

	if `"`legend'"' == "" {
		if "`ci'" != "" {
			if "`suspended'" == "" {
				if "`spike'" != "" {
					local legend `"legend(order(1 "`level'% Conf. Int."))"'
				}
				else {
					local legend `"legend(order(3 "`level'% Conf. Int."))"'
				}
			}
			else if "`theoretical'" != "" {
				local legend `"legend(order(1 "`level'% Conf. Int." 3 "residual"))"'
			}
			else {
				local legend `"legend(order(1 "`level'% Conf. Int." 3 "residual" 4 "theoretical" "distribution"))"'
			}
		}
		else {
			local legend "legend(off)"
		}
	}
	
	if "`bar'" != "" {
		local barw "barw(`w')"
	}
	
	if "`suspended'" != "" {
		tempvar zero
		gen byte `zero' = 0
		if "`spike'" != "" local lstyle "lstyle(p3)"
		local maingr r`spike'`bar' `zero' `floor' `x', `lstyle' `mainopt'
	}
	else {
		if "`spike'" != "" local lstyle "lstyle(p1)"
		local maingr r`spike'`bar' `theor' `floor' `x', `lstyle' `mainopt'
	}
	if "`theoretical'" == "" local theordistgr `"`gr' lstyle(p1)"'
	
	twoway `cispike'`ciarea' || `maingr' ///
	       `barw' yline(0) `options' `ytitle' `xtitle' `legend' ||                    ///
	`theordistgr' `theoropt' || `cibar' || `plot'
	
	// cleanup extra obs created by twoway__histrogram_gen2
	qui drop if `newobs'

end
		
