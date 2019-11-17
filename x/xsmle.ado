*! version 1.3.7 2may2014 
*! authors Federico Belotti, Gordon Hughes, Andrea Piano Mortari
*! see end of file for version comments

/***************************************************************************
** Stata program for ML estimation of balanced (and unbalanced through the prefix command -mi-) panel data spatial models
**
** Programmed by: Gordon Hughes, Department of Economics, University of Edinburgh, E-mail: g.a.hughes@ed.ac.uk
** 				  Federico Belotti, Centre for Economics and International Studies, University of Rome Tor Vergata, E-mail: f.belotti@gmail.com	
**				  Andrea Piano Mortari, Centre for Economics and International Studies, University of Rome Tor Vergata, E-mail: andreapm@gmail.com

** The likelihood mata functions are based upon Matlab code originally written by J Paul Elhorst and J.P. LeSage
** See: J.P. Elhorst (2009) 'Spatial panel data models' in M.M. Fischer & A.Getis (Eds),
** Handbook of Applied Spatial Analysis, pp. 377-407.

**************************************************************************/

program define xsmle, eclass prop(xt swml mi) sortpreserve byable(recall)
version 10

local vvcheck = max(10,c(stata_version))
if `vvcheck' < 11 local __fv
else local __fv "fv"

syntax varlist(numeric min=2 `__fv') [if] [in] [aweight iweight /] ///
										[, WMATrix(string) EMATrix(string) DMATrix(string) ///
							 			FE RE MODel(string) TYPE(string) NOEFFects NOSE NSIM(integer 100) ///
										NOCONStant VCE(passthru) ROBust CLuster(passthru) Level(cilevel) ///
										CONSTRaints(numlist min=1) DLAG HAUSMAN ///
										TECHnique(string) ITERate(integer 100) NOWARNing DIFFICULT NOLOG ///
				                        TRace GRADient SHOWSTEP HESSian SHOWTOLerance TOLerance(real 1e-6) ///
				                        LTOLerance(real 1e-7) NRTOLerance(real 1e-5) POSTScore POSTHessian ///
							 			DURBin(varlist numeric min=1 `__fv') FROM(string) ERRor(integer 1) *] 

local vvcheck = max(10,c(stata_version))
local vv : di "version " string(max(10,c(stata_version))) ", missing:"								
local _cmd_line "`0'"

*** Parsing of spatial weight matrices 
ParseSpatMat, cwmat(`wmatrix') cemat(`ematrix') cdmat(`dmatrix')
if "`r(_wmatspmatobj)'"!="" {
	mat `wmatrix' = r(_wmatspmatobj)
	local _wmatspmatobj 1
}
else local wmatrix "`r(wmatrix)'"
if "`r(_ematspmatobj)'"!="" {
	mat `ematrix' = r(_ematspmatobj)
	local _ematspmatobj 1
}
else local ematrix "`r(ematrix)'"
if "`r(_dmatspmatobj)'"!="" {
	mat `dmatrix' = r(_dmatspmatobj)
	local _dmatspmatobj 1
}
else local dmatrix "`r(dmatrix)'"

*** Default RE
if ("`fe'" == "" | "`re'" != "") local re "re"
if "`fe'" != "" {
	local effects 1
	if "`noconstant'"!="" {
    	display in yel "Warning: option -noconstant- is redundant in fixed-effects models"
  	}
	else local noconstant "noconstant"
}
if "`re'" != "" local effects 2
local lytransf=0
	
*** Parsing model
ParseMod modtype : `"`model'"'
if `effects'==1 {
	*** Parsing type
	if "`type'" != "" {
		gettoken type _leeyu: type, parse(",")
		ParseLY leeyu : `"`=regexr("`_leeyu'",",","")'"'
		*** Lee and Yu (2010) data transf?
		if "`leeyu'" != "" local lytransf=1
	}
}
else {
  	*** Parsing type
	if "`type'" != "" {
		gettoken type _leeyu: type, parse(",")
		if  "`_leeyu'" !="" {
			di as error "Lee and Yu (2010) transformation not allowed in random-effects models"
    		error 198 
		}
	}
}
ParseType efftype : `"`type'"'

*** Hausman parsing
if "`hausman'"!="" {
	local postscore postscore
	local posthessian posthessian
	if `effects' == 1 local _tobeestimated 2
	else local _tobeestimated 1
	if `modtype'==4 | `modtype'==5 {
		di as err "-hausman- option is not allowed if model(`model')"
		error 198
	}
}

*** Mark sample
marksample touse

*** Lagged dependent var?
if "`dlag'" != "" local lagdep=1
else local lagdep=0

*** Nsim for effects s.e. cannot be 1
if "`nsim'"=="1" {
	di in yel "Number of simulations cannot be equal to 1. nsim() has been set to 2"
	di in yel "Use option nose to suppress s.e. effects computation"
	local nsim 2
}

*** No S.E. from option
if "`nose'"!="" {
	local nsim 1
}

	
***********************************************************************************
******* Define macros to correctly create _InIt_OpTiMiZaTiOn() structure **********
***********************************************************************************

if "`difficult'"!="" local difficult "hybrid"
else local difficult "m-marquardt"
if "`nowarning'"!="" local nowarning "on"
else local nowarning "off"
if "`technique'"!="" local technique "`technique'"
else local technique "nr"
if "`nolog'"!="" local nolog "none"
else local nolog "value"
if "`trace'"!="" local trace "on"
else local trace "off"
if "`gradient'"!="" local gradient "on"
else local gradient "off"
if "`showstep'"!="" local showstep "on"
else local showstep "off"
if "`hessian'"!="" local hessian "on"
else local hessian "off"
if "`showtolerance'"!="" local showtolerance "on"
else local showtolerance "off"
if "`constraints'" != "" local constrained_est "on"
else local constrained_est "off"
*** L and NR tol to ensure converg in sac model with time or both fixed-effects
if `modtype'==4 & (`efftype'==2 | `efftype'==3) {
	local ltolerance 1e-4 
	local nrtolerance 1e-2
}
*** Scalars
scalar TOLerance = `tolerance'
scalar LTOLerance = `ltolerance'
scalar NRTOLerance = `nrtolerance'
scalar MaXiterate = `iterate'
scalar CILEVEL = `level'

/// Parsing of display options
_get_diopts diopts options, `options'

/// ERRORS
	
	if `modtype' == 3 & "`noeffects'"!="" {
    	display in yel "Warning: there are no indirect effects in SEM models. Option -noeffects- is redundant"
  	}

  	if (`modtype'==1 & "`ematrix'"!="") {
    	display as error "Specify wmatrix() option with SAR model"
    	error 198
  	}
  	if (`modtype'==3 & "`wmatrix'"!="") {
    	display as error "Specify ematrix() option with SEM model"
    	error 198
  	}
  	if (`modtype'==2 & "`ematrix'"!="" & "`wmatrix'"=="") {
    	display as error "Specify wmatrix() option with SDM model"
    	error 198
  	}
  	if (`modtype'==2 & "`ematrix'"!="" & "`wmatrix'"=="" & "`dmatrix'"!="") {
    	display as error "Specify wmatrix() option with SDM model"
    	error 198
  	}
  	if (`modtype'==4 & ("`wmatrix'"=="" | "`ematrix'"=="")) {
    	display as error "Both wmatrix() and ematrix() must be specified with SAC model"
    	error 198
  	}
  	
  	if ("`fe'"!="" & "`re'"!="") {
    	display as error "Both -fe- and -re- specified - specify one or the other"
    	error 198
  	}
  	if (`modtype'==4 & "`re'"!="") {
    	display as error "SAC model can only be estimated using the -fe- option"
    	error 198
  	}
  	if (`modtype'==5 & "`fe'"!="") {
    	display as error "GSPRE model can only be estimated using the -re- option"
    	error 198
  	}
  	if (`modtype'==5 &  (`error'==1 | `error'==4) & ("`wmatrix'"=="" | "`ematrix'"=="")) {
    	display as error "Both wmatrix() and ematrix() must be specified in GSPRE model with error(`error')"
    	error 198
  	}
  	if (`modtype'==5 &  `error'==2  & "`ematrix'"!="" & "`wmatrix'"=="") {
    	display as error "Specify wmatrix() option in GSPRE model with error(`error')"
    	error 198
  	}
  	if (`modtype'==5 &  `error'==2  & "`ematrix'"!="" & "`wmatrix'"!="") {
    	display as error "Specify only wmatrix() option in GSPRE model with error(`error')"
    	error 198
  	}
  	if (`modtype'==5 &  `error'==3  & "`wmatrix'"!="" & "`ematrix'"=="" ) {
    	display as error "Specify ematrix() option in GSPRE model with error(`error')"
    	error 198
  	}
  	if (`modtype'==5 &  `error'==3  & "`wmatrix'"!="" & "`ematrix'"!="" ) {
    	display as error "Specify only ematrix() option in GSPRE model with error(`error')"
    	error 198
  	}
  	if ((`lagdep' > 0) & (`modtype' >= 3)) {
    	display as error "A lagged dependent variable is only available for SAR and SDM models"
    	error 198
  	}
  	if (`lagdep' == 1 & `lytransf' == 1 & `effects'==1) {
    	display as error "Lee and Yu (2010) transformation not allowed in dynamic models"
    	error 198 
  	}
  	if ((`modtype' != 2) & ("`durbin'" != "")) {
    	display as error "durbin() option only allowed with model(sdm)"
    	error 198
  	}
	if (`effects'==2 & "`type'"!="") {
		di in yel "Warning: Option type(`type') will be ignored"
	}
	if (`lytransf'==1 & "`type'"!="ind") {
		di in yel "Warning: Suboption -`type'- will be replaced with -ind-"
		di in yel "Lee and Yu (2010) spatial fixed-effects transformation will be applied"
		local efftype 1
		local type "ind"
	}
	
*** CONSTANT?
  	if "`noconstant'" != "" local noconst=1
  	else local noconst=0
	if (`effects'==1 & `lagdep'==1) local noconst=1

*** First varlist parsing
	gettoken lhs rhs: varlist 
	local lhs_name "`lhs'"

*** Durbin parsing
	if `modtype'==2 {
		if "`durbin'" == "" {
			local durbin "`rhs'"
			di in yel "Warning: All regressors will be spatially lagged", _n
		}
	}

**************************************************************************************************************
**************** Check for panel setup and perform checks necessary for weighted estimation ******************
**************************************************************************************************************
     
    *** Check for panel setup                
	_xt, trequired 
	local id: char _dta[_TSpanel]
	local time: char _dta[_TStvar]
	tempvar temp_id temp_t Ti
	qui egen `temp_id'=group(`id') if `touse'==1
	sort `temp_id' `time'
	qui by `temp_id': g `temp_t' = _n if `temp_id'!=.
	
	*** Count panels and original panel length (before any transformation of the data) 
	qui by `temp_id': gen long `Ti' = _N if _n==_N & `touse'==1
	qui summ `Ti' if `touse'==1, mean
	local t_orig = r(max)
	qui count if `Ti'<.
	local N_g = r(N)
	
	*** Set up weights
	tempvar wtval
	gen `wtval'=1
	if "`weight'" != "" {
	    quietly replace `wtval'=`exp'
		local __equal "="
	}
	local wtvar "`wtval'"
	
***********************************************************************
*** Get temporary variable names and perform Factor Variables check ***
***********************************************************************
*** (Note: Also remove base collinear variables if fv are specified)

	local fvops = "`s(fvops)'" == "true" 
	if `fvops' {
		if _caller() >= 11 {
			
	    	local vv_fv : di "version " string(max(11,_caller())) ", missing:"
	    	
			********* Factor Variables parsing ****
			`vv_fv' _fv_check_depvar `lhs'
			
			local fvars "rhs durbin"
			foreach l of local fvars {
				if "`l'"=="rhs" local fv_nocons "`nocons'"
				fvexpand ``l''
				local _n_vars: word count `r(varlist)'
				local rvarlist "`r(varlist)'"
				fvrevar `rvarlist'
				local _`l'_temp "`r(varlist)'"
				forvalues _var=1/`_n_vars'  {
					_ms_parse_parts `:word `_var' of `rvarlist''
					*** Get temporary names here
					if "`r(type)'"=="variable" {
						local _`l'_tempnames "`_`l'_tempnames' `r(name)'"
						local _`l'_ntemp "`_`l'_ntemp' `:word `_var' of `_`l'_temp''"
					}
					if "`r(type)'"=="factor" & `r(omit)'==0 {
						local _`l'_tempnames "`_`l'_tempnames' `r(op)'.`r(name)'"
						local _`l'_ntemp "`_`l'_ntemp' `:word `_var' of `_`l'_temp''"
					}
					if ("`r(type)'"=="interaction" | "`r(type)'"=="product") & `r(omit)'==0 {
						local _inter
						forvalues lev=1/`r(k_names)' {
							if `lev'!=`r(k_names)' local _inter "`_inter'`r(op`lev')'.`r(name`lev')'#"
							else local _inter "`_inter'`r(op`lev')'.`r(name`lev')'"
						}
						local _`l'_tempnames "`_`l'_tempnames' `_inter'"
						local _`l'_ntemp "`_`l'_ntemp' `:word `_var' of `_`l'_temp''"						
					}
				}
				*** Remove duplicate names (Notice that collinear regressor other than fv base levels are removed later)
				local _`l'_names: list uniq _`l'_tempnames
				*** Update fvars components after fv parsing
				local `l' "`_`l'_ntemp'"
			}
		}	
	}

*** Test for missing values in dependent and independent variables
	local __check_missing "`lhs' `rhs' `durbin'"
  	egen _xsmle_missing_obs=rowmiss(`__check_missing')
  	quietly sum _xsmle_missing_obs
  	drop _xsmle_missing_obs
  	local nobs=r(N)
  	local nmissval=r(sum)
  	if `nmissval' > 0 {
    	display as error "Error - the panel data must be strongly balanced with no missing values"
    	error 198
  	}

*** Parsing vce options

	local crittype "Log-likelihood"
	
	cap _vce_parse, argopt(CLuster) opt(OIM OPG Robust) old	///
	: [`weight' `__equal' `exp'], `vce' `robust' `cluster'
	
	if _rc == 0 {
		local vce "`r(vce)'"
		if "`vce'" == "" local vce "oim"
		if "`vce'"=="cluster" {
			local vcetype "Robust"
			local clustervar "`r(cluster)'"
			local crittype "Log-pseudolikelihood"
		}
		if "`vce'"=="robust" {
			local vce "cluster"
			local vcetype "Robust"
			local clustervar "`id'"
			local crittype "Log-pseudolikelihood"
		}
		if "`vce'"=="opg" local vcetype "OPG"	
	}
	else {
		local vce = regexr("`vce'","vce\(","")
		local vce = regexr("`vce'","\)","")
		
		gettoken vcetocheck _sub_vcetocheck: vce
		local _sub_vcetocheck = subinstr("`_sub_vcetocheck'"," ","",.)
		ParseOTHvce vce : `"`vcetocheck'"'
		
		if "`vce'" == "dkraay" {
			if "`_sub_vcetocheck'"=="" local roblag = floor(4*(`t_orig'/100)^(2/9))
			else {
				cap confirm n `_sub_vcetocheck'
				if _rc {
					dis as error "The lag in vce(dkraay `_sub_vcetocheck') must be an integer number"
					error 198
				}
				if regexm("`_sub_vcetocheck'","[0-9][0-9]*") local roblag = regexs(0)					
				if `roblag'>=`t_orig' {
					di as error "The lag for vce(dkraay) is too large"
					error 198
				}
			}
			local vcetype "Robust"
			local crittype "Log-pseudolikelihood"
			scalar roblag = `roblag'
		}
		if "`vce'" == "srobust" {
			*** Parsing of the spatial contiguity matrix for two-way clustering
			Parse2waycsSpatMat, csmat(`_sub_vcetocheck')
			if "`r(_smatspmatobj)'"!="" {
				mat `smatrix' = r(_smatspmatobj)
				local _smatspmatobj 1
			}
			else local smatrix "`r(smatrix)'"
			local vcetype "Robust"
			local crittype "Log-pseudolikelihood"			
		}
	}


*** Remove collinearity
_rmcollright `rhs' if `touse' [`weight' `__equal' `exp'], `noconstant' 		
local rhs "`r(varblocklist)'"
if `modtype'==2 {
	_rmcollright `durbin' if `touse' [`weight' `__equal' `exp'], `noconstant' 			
	local durbin "`r(varblocklist)'"
}

if `fvops'==0 {
	local _rhs_names "`rhs'"
	local _durbin_names "`durbin'"
}

local _k_final: word count `_rhs_names'
local _rhsvar "`_rhs_names'"
local _kd_final: word count `_durbin_names'
local _durb_rhsvar "`_durbin_names'"

****************************************************************************
// Names for display

if `effects' == 1 local _rhs_names "`_rhs_names'"
if `lagdep' == 1 local _rhs_names "l.`lhs_name' `_rhs_names'"

if `effects'==2 {
	if `noconst' == 0 local _rhs_names "`_rhs_names' _cons"
	local pname_theta "sigma_a"
	if `lagdep'==0 & (`modtype'==1 | `modtype'==2) local pname_theta "lgt_theta"
	if `modtype'==3 local pname_theta "ln_phi"
	local cname_theta "Variance"
}

foreach name of local _rhs_names {
	local _colnames "`_colnames' Main"
}

if `modtype' == 1 {
	/*if `effects'==1 local sigma2e_name "sigma2_e"
	else local sigma2e_name "sigma_e"*/
	local sigma2e_name "sigma2_e"
	
	local _regr_names "`_rhs_names' rho `pname_theta' `sigma2e_name'"
	local __colnames "`_colnames' Spatial `cname_theta' Variance"
	local _k_exp = 2 + `:word count `pname_theta''
}
if `modtype' == 2 {
	/*
	if `effects'==1  local sigma2e_name "sigma2_e"
	else local sigma2e_name "sigma_e"
	*/
	local sigma2e_name "sigma2_e"
	
	foreach name of local _durbin_names {
		local _colnames_durb "`_colnames_durb' Wx"
	}
	local _regr_names "`_rhs_names' `_durbin_names' rho `pname_theta' `sigma2e_name'"
	local __colnames "`_colnames' `_colnames_durb' Spatial `cname_theta' Variance"
	local _k_exp = 2 + `:word count `pname_theta''
}
if `modtype' == 3 {
	local _regr_names "`_rhs_names' lambda `pname_theta' sigma2_e"
	local __colnames "`_colnames' Spatial `cname_theta' Variance"
	local _k_exp = 2 + `:word count `pname_theta''
}
if `modtype' == 4 {
	local _regr_names "`_rhs_names' rho lambda sigma2_e"
	local __colnames "`_colnames' Spatial Spatial Variance"
	local _k_exp = 3 
}

if `modtype' == 5 {
	if `error'==1 {
		local _regr_names "`_rhs_names' phi lambda sigma_mu sigma_e"
		local __colnames "`_colnames' Spatial Spatial Variance Variance"
		local _k_exp = 4
	}
	if `error'==2 {
		local _regr_names "`_rhs_names' phi sigma_mu sigma_e"
		local __colnames "`_colnames' Spatial Variance Variance"
		local _k_exp = 3
	}
	if `error'==3 {
		local _regr_names "`_rhs_names' lambda sigma_mu sigma_e"
		local __colnames "`_colnames' Spatial Variance Variance"
		local _k_exp = 3
	}
	if `error'==4 {
		local _regr_names "`_rhs_names' phi sigma_mu sigma_e"
		local __colnames "`_colnames' Spatial Variance Variance"
		local _k_exp = 3
	}
}

/// Assign names (just for starting values and constraints)
tempname init_b
mat `init_b'= J(1,`: word count `_regr_names'',.)
`vv' mat colnames `init_b' = `_regr_names' 
`vv' mat coleq `init_b' = `__colnames'

if "`from'" != "" {
	/*local _colfullnames: colfullnames `init_b'
	tempname mat_from*/	
	local arg `from'
	`vv' _mkvec `init_b', from(`arg') /*colnames(`_colfullnames')*/ update error("from()")
	
	if `s(k_fill)'==0 & regexm("`vv'", "10") {
		di in yel "Warning: from() option failed to properly set starting values."
		di in yel " from() must be a properly labeled vector or have equation and colnames fully"
		di in yel " specified via the" in gr " eqname:name=# " in yel "syntax."
	}
}

*** Parsing of constraints (if defined)
if "`constraints'"!="" {
	local contraintsy 1
	tempname _vinit_b
	mat `_vinit_b' = J(1,`: word count `_regr_names'',0)
	mat colnames `_vinit_b' = `_regr_names'
	mat coleq `_vinit_b' = `__colnames'
	_parse_constraints, constraintslist(`constraints') estparams(`_vinit_b')
}

********************** Display info ********************** 
cap qui tab `temp_t' if `touse'==1
local t_max = r(r)
local nobs = r(N)
**********************************************************
 
/* Check if weight is constant within panel.
   Note: weight variable is normalized in _xsmle_est()
   since we need the right e(sample), i.e after any data transf */

sort `temp_id'
tempvar _xsmle_weight_sd
qui by `temp_id': egen `_xsmle_weight_sd'=sd(`wtvar')
sum `_xsmle_weight_sd', mean
local panel_sd_max=r(max)
if `panel_sd_max' > 0 & `panel_sd_max'!=. {
	display as error "Weights must be constant within panels"
	error 198
}
if `panel_sd_max' == . {
	display as error "The dataset in memory is not a panel dataset."
	error 198		
}

*** Sort data for the estimation of spatial panel data models
sort `temp_t' `temp_id' 

*********************************************************************
********************* Model estimation ******************************
*********************************************************************

*** Collect init optimization options
mata: _InIt = _InIt_OpTiMiZaTiOn_xsmle()
*** The following to check the content of the structure ** Just for debugging
*mata: liststruct(_InIt)


#delimit ;
mata: _xsmle_est(`N_g', `t_max', "`touse'", "`temp_id'", "`temp_t'",  
				 "`lhs'", "`rhs'", "`durbin'", `noconst', 
				 "`wmatrix'", "`ematrix'", "`dmatrix'", "`smatrix'", "`wtvar'", "`weight'",
				 `modtype', `effects', `efftype', `lytransf', `lagdep',`error',
				  _InIt, &_xsmle_sv(), "`init_b'", &_xsmle_diagn());
#delimit cr

/// Collect the originbal to use to fix the dlag issue in performing the hausman test
if "`hausman'"!="" marksample htouse

if `lytransf'==1 | `lagdep'==1 {
	/* Fix estimation sample for lytransf */
	tempname rulez
	qui gen `rulez' = 1
	qui replace `rulez' = . if `temp_t'==`t_max' & `lytransf'==1
	qui replace `rulez' = . if `temp_t'==1 & `lagdep'==1
	markout `touse' `rulez'
	qui tab `temp_t' if `touse'
	local t_max = r(r)
	qui count if `touse'
	local nobs = r(N)
}

/// Assign names
`vv' mat colnames __b = `_regr_names' 
`vv' mat coleq __b = `__colnames'
`vv' mat colnames _V = `_regr_names'
`vv' mat rownames _V = `_regr_names' 
`vv' mat coleq _V = `__colnames'
`vv' mat roweq _V = `__colnames'

if "`noeffects'" == "" {
	if `modtype' == 1 | `modtype' == 2 | `modtype' == 4 { 
		
		tempname _oVc _bbeta _ttheta _dir _indir _tot _vdir _vindir _vtot	 	
		cap mat `_oVc' = cholesky(_V)
		if _rc {
			di in yel "Warning: e(V) matrix is not positive definite."
			di in yel "         Spatial effects Std. Err. will be computed using a modified"
			di in yel "         positive definite matrix (Rebonato and Jackel, 2000)."
				qui{
					mata: _VVV = st_matrix("_V")
					mata: eigensystem(_VVV, X=., L=.)
					mata: nlesszero = cols(L[mm_which(Re(L):<0)])
					mata: L[mm_which(Re(L):<0)] = J(1,nlesszero,0.000000001)
					mata: _AAA = Re((X*diag(L)*X'))
					mata: st_matrix("`_oVc'", cholesky(_AAA))	
				}
		}
		
		if "`nsim'"=="1" {
			local _rows = rowsof(_V)
			local _cols = colsof(_V)
			mat `_oVc' = J(`_rows',`_cols',0)
			mata: draws = _xsmle_draws("__b","`_oVc'", `nsim')
		}
		else mata: draws = _xsmle_draws("__b","`_oVc'", `nsim')
		
		mat `_bbeta' = __b[1,"Main:"]
		if `lagdep' == 1 mat `_bbeta' = `_bbeta'[1,2...]
		local _bbetanames_temp: colnames `_bbeta'
		local _n_bbetanames: word count `_bbetanames_temp'

		forvalues _name=1/`_n_bbetanames'  {

			if `vvcheck'>=11 {
				`vv_fv' _ms_parse_parts `:word `_name' of `_bbetanames_temp''
				local rtype "`r(type)'"
			}
			else local rtype "variable"
			
			if "`rtype'"=="variable" local _bbetanames "`_bbetanames' `r(name)'"		
			if "`r(type)'"=="factor" & "`r(omit)'"=="0" local _bbetanames "`_bbetanames' `r(op)'.`r(name)'"
			if ("`r(type)'"=="interaction" | "`r(type)'"=="product") & "`r(omit)'"=="0" {
				local _inter
				forvalues lev=1/`r(k_names)' {
					if `lev'!=`r(k_names)' local _inter "`_inter'`r(op`lev')'.`r(name`lev')'#"
					else local _inter "`_inter'`r(op`lev')'.`r(name`lev')'"
				}
				local _bbetanames "`_bbetanames' `_inter'"						
			}			
		}

		if `noconst'==0 {
			local _posofcons: list posof "_cons" in _bbetanames
		    local __cons _cons
		    local _bbetanames: list _bbetanames - __cons
		}
		
		if `modtype'==2 {
			mat `_ttheta' = __b[1,"Wx:"]
			local _tthetanames_temp: colnames `_ttheta'
			local _n_tthetanames: word count `_tthetanames_temp'

			forvalues _name=1/`_n_tthetanames'  {

				if `vvcheck'>=11 {
					`vv_fv' _ms_parse_parts `:word `_name' of `_tthetanames_temp''
					local rtype "`r(type)'"
				}
				else local rtype "variable"
	
				if "`rtype'"=="variable" local _tthetanames "`_tthetanames' `r(name)'"		
				if "`r(type)'"=="factor" & "`r(omit)'"=="0" local _tthetanames "`_tthetanames' `r(op)'.`r(name)'"
				if ("`r(type)'"=="interaction" | "`r(type)'"=="product") & "`r(omit)'"=="0" {
					local _inter
					forvalues lev=1/`r(k_names)' {
						if `lev'!=`r(k_names)' local _inter "`_inter'`r(op`lev')'.`r(name`lev')'#"
						else local _inter "`_inter'`r(op`lev')'.`r(name`lev')'"
					}
					local _tthetanames "`_tthetanames' `_inter'"						
				}					
			}
		}
		
		*** Check for which variables must be computeted what
		local _allvars "`_bbetanames' `_tthetanames'"
		local _allvars: list uniq _allvars
		local _nallvars: word count `_allvars'
		local _case1: list _bbetanames - _tthetanames
		local _case2: list _bbetanames & _tthetanames
		local _case3: list _tthetanames - _bbetanames
		
		mata: `_dir' = J(1,`_nallvars',.)
		mata: `_indir' = J(1,`_nallvars',.)
		mata: `_tot' = J(1,`_nallvars',.)
		mata: `_vdir' = J(`_nallvars',`_nallvars',0)
		mata: `_vindir' = J(`_nallvars',`_nallvars',0)
		mata: `_vtot' = J(`_nallvars',`_nallvars',0)
		
		local _for_rho_pos: colnames __b
		local __posrho: list posof "rho" in _for_rho_pos

		forvalues _c=1/3 {
				
			foreach _v of local _case`_c' {
			
				local __nbeta: word count `_bbetanames'
				if (`_c' == 1 | `_c' == 2) {
					local __posbeta: list posof "`_v'" in _bbetanames
					local __posbeta = `__posbeta' + cond(`lagdep' == 1,1,0)
				}
				if (`_c' == 2 | `_c' == 3) {
					local __postheta: list posof "`_v'" in _tthetanames
					local __postheta = `__postheta'+`__nbeta' + cond(`noconst'==0,1,0) + cond(`lagdep' == 1,1,0)
				}
				if "`__postheta'"=="" local __postheta = 1
				if "`__posbeta'"=="" local __posbeta = 1

				mata: __effects = _xsmle_effects(draws[.,`__posbeta'],draws[.,`__posrho'],"`wmatrix'",`_c',"`dmatrix'",draws[.,`__postheta'])
				local __posfin: list posof "`_v'" in _allvars
				mata: `_dir'[1,`__posfin'] = __effects[1,1]
				mata: `_indir'[1,`__posfin'] = __effects[1,2]
				mata: `_tot'[1,`__posfin'] = __effects[1,3]
				mata: `_vdir'[`__posfin',`__posfin'] = __effects[2,1]
				mata: `_vindir'[`__posfin',`__posfin'] = __effects[2,2]
				mata: `_vtot'[`__posfin',`__posfin'] = __effects[2,3]
					
				local __nbeta
				local __posbeta
				local __postheta	
			}
		}
		
		mata: st_matrix("`_dir'",`_dir')
		mata: st_matrix("`_indir'",`_indir')
		mata: st_matrix("`_tot'",`_tot')
		mata: st_matrix("`_vdir'",`_vdir')
		mata: st_matrix("`_vindir'",`_vindir')
		mata: st_matrix("`_vtot'",`_vtot')
		
		** Fix names
		local __effnames "`_allvars'"		
		foreach name of local __effnames {
			local _colnames_vdir "`_colnames_vdir' Direct"
			local _colnames_vindir "`_colnames_vindir' Indirect"
			local _colnames_vtot "`_colnames_vtot' Total"
		}
		
		mat __b = __b,`_dir',`_indir',`_tot'
		`vv' mat colnames __b = `_regr_names' `__effnames' `__effnames' `__effnames'
		`vv' mat coleq __b = `__colnames' `_colnames_vdir' `_colnames_vindir' `_colnames_vtot'
		
		mata: __V = st_matrix("_V")
		if "`nsim'"=="1" {
			mata: _diag(`_vdir',0)
			mata: _diag(`_vindir',0)
			mata: _diag(`_vtot',0)
		}
		mata: __V = blockdiag(__V,`_vdir')
		mata: __V = blockdiag(__V,`_vindir')
		mata: __V = blockdiag(__V,`_vtot')
		mata: st_matrix("_V", __V)
		`vv' mat colnames _V = `_regr_names' `__effnames' `__effnames' `__effnames'
		`vv' mat rownames _V = `_regr_names' `__effnames' `__effnames' `__effnames' 
		`vv' mat coleq _V = `__colnames' `_colnames_vdir' `_colnames_vindir' `_colnames_vtot'
		`vv' mat roweq _V = `__colnames' `_colnames_vdir' `_colnames_vindir' `_colnames_vtot'
	}
}

local to_count_eqs: coleq __b
local to_count_eqs: list uniq to_count_eqs
local k_eq: word count `to_count_eqs'

if `modtype'==2 & `lagdep'==1 {
	** Make sigma_mu positive
	local _n__b: word count `_regr_names'
	local _n__b = `_n__b'-1
	tempname __sigma_mu
	scalar `__sigma_mu' = abs(__b[1,`_n__b'])
	mat __b[1,`_n__b'] = `__sigma_mu' 
}

*** Post result for display
eret post __b _V, e(`touse') obs(`nobs')

///////////////// Display results /////////////////

*** Common post 
eret local depvar "`lhs_name'"
eret local rhsvar "`_rhsvar'"
eret local drhsvar "`_durb_rhsvar'"
eret local predict "xsmle_p"
eret local cmd "xsmle" 
eret local noconst "`noconst'"
if "`model'"=="" local model "sar"
eret local model "`model'"
eret local effects "`re'`fe'"
eret local cmdline "`_cmd_line'"
eret local technique "`technique'"
if "`e(effects)'"=="re" & "`e(model)'"=="sar" eret local ml_method "v0"
else eret local ml_method "v1"
eret scalar rank = _rank_V

if "`contraintsy'"=="1" {
	forvalues i=1/`: word count `constraints'' {
		cap constr get `i'
		eret local constr`i' "`r(contents)'"
	}
}

if `effects==1' {
	if `efftype'==1 local type "ind"
	if `efftype'==2 local type "time"
	if `efftype'==3 local type "both"
	local df_adj `N_g'
}
eret scalar sigma_e = sigma_e
if `modtype'==1 | `modtype'==2 {
	if `effects'==1 {
		eret scalar a_avg = mu_av
		eret local user "_xsmle_vlfun_fesar"
	}
	if `effects'==2 {
		eret scalar sigma_a = sigma_a
		if `lagdep'==0 eret local user "_xsmle_vlfun_resar"
		else eret local user "_xsmle_vlfun_dresar"
	}
}
if `modtype'==3 {
	if `effects'==1 {
		eret scalar a_avg = mu_av
		eret local user "_xsmle_vlfun_fesem"
	}
	if `effects'==2 {
		eret scalar sigma_a = sigma_a
		eret local ml_method "v0"
		eret local user "_xsmle_vlfun_resem"
	}
}
if `modtype'==4 {
	eret scalar a_avg = mu_av
	eret local user "_xsmle_vlfun_fesac"
}
if `modtype'==5 {
	if `error'==1 eret local user "_xsmle_vlfun_gspre1"
	if `error'==2 eret local user "_xsmle_vlfun_gspre2"
	if `error'==3 eret local user "_xsmle_vlfun_gspre3"
	if `error'==4 eret local user "_xsmle_vlfun_gspre4"
	eret local gspre_err "`error'"
	eret scalar sigma_mu = sigma_mu
}
eret local type "`type'"
eret local ivar `id'
eret local tvar `time'
eret scalar t_max = `t_max'
eret scalar N_g = `N_g'
if "`vce'"=="cluster" eret scalar N_clust = N_clust
else eret scalar N_clust = `N_g'
eret scalar ll = ll
if `lagdep'==0 eret local dlag "no"
else eret local dlag "yes"
cap eret scalar ll_c = c_ll
eret matrix ilog = itlog
eret matrix gradient = _grad
eret scalar converged = converged
eret scalar ic = itfinal
eret local crittype "`crittype'"
eret local vce "`vce'"
eret local vcetype "`vcetype'"
eret local clustvar "`clustervar'"
if "`weight'" != "" {
	eret local wtype "`weight'"
	eret local wexp "`__equal' `exp'"
}
if `noconst' == 0 local _df_r_cons = 1
else local _df_r_cons = 0
eret scalar df_m = `_k_final' + `_kd_final' + `df_adj'
eret scalar k_exp = `_k_exp' 
*eret scalar df_r = `e(N)' - (`e(df_m)' + `e(k_exp)' + `_df_r_cons')
if "`roblag'"!="" eret scalar dkraay_lag = roblag
if `effects' == 1 {
	if "`leeyu'" != "" eret local transf_type "leeyu"
	else eret local transf_type "demean"
}
if "`postscore'"!="" eret matrix score = _score
if "`posthessian'"!="" eret matrix hessian = _hessian
eret scalar k_eq = `k_eq'
eret scalar r2 = r2
eret scalar r2_b = r2_b
eret scalar r2_w = r2_w

*** Matrices post
if "`wmatrix'"!="" {
	eret local wmatrix "`wmatrix'"
	if "`_wmatspmatobj'" == "1" eret local w_spmat_obj 1
	else eret local w_spmat_obj 0
}
if "`ematrix'"!="" {
	eret local ematrix "`ematrix'"
	if "`_ematspmatobj'" == "1" eret local e_spmat_obj 1
	else eret local e_spmat_obj 0
}
if "`dmatrix'"!="" {
	eret local dmatrix "`dmatrix'"
	if "`_dmatspmatobj'" == "1" eret local d_spmat_obj 1
	else eret local d_spmat_obj 0
}

**********************************
**** Perform the Hausman test ****
**********************************
if "`hausman'"!="" {
	
	if `_tobeestimated'==1 local _stobeestimated "fixed-effects"
	else local _stobeestimated "random-effects"
	di in yel "... estimating `_stobeestimated' model to perform Hausman test"
	
	tempname __betafe __betare __scorefe __scorere __Hessfe __Hessre
	
	if "`noeffects'" != "" local _minus_effects 0
	else {		
		if `modtype' == 1 | `modtype' == 2 local _minus_effects = `: word count `__effnames''*3
		if `modtype' == 3 local _minus_effects 0
	}
		
	if `_tobeestimated' == 1 {
		mat `__betare' = e(b)
		local __creg: word count `_rhs_names'
		if "`noconstant'"!= "" {
			local __colre = colsof(`__betare')-2-`_minus_effects'
			mat `__betare' = `__betare'[1,1..`__colre']		
		}
		else {
			local __posofcons = `__creg'+1
			local __creg1 = `__creg'+2
			local __colre = colsof(`__betare')-2-`_minus_effects'
			mat `__betare' = `__betare'[1,1..`__creg'],`__betare'[1,`__creg1'..`__colre']
		}
		mat `__scorere' = e(score)
		mat `__Hessre' = e(hessian)
	} 
	else {		
		mat `__betafe' = e(b)
		local __colfe = colsof(`__betafe')-1-`_minus_effects' 
		mat `__betafe' = `__betafe'[1,1..`__colfe']
		mat `__scorefe' = e(score)
		mat `__Hessfe' = e(hessian)
		if "`noconstant'"!= "" local noconst 0
	}	

	#delimit ;
	cap mata: _xsmle_est(`e(N_g)', `t_orig', "`htouse'", "`temp_id'", "`temp_t'",  
					 "`lhs'", "`rhs'", "`durbin'", `noconst', 
					 "`wmatrix'", "`ematrix'", "`dmatrix'", "`smatrix'", "`wtvar'", "`weight'",
					 `modtype', `_tobeestimated', `efftype', `lytransf', `lagdep',`error',
					  _InIt, &_xsmle_sv(), "`init_b'", &_xsmle_diagn());
	#delimit cr

	local _rc = _rc
	if `_rc' == 0 {
		if `_tobeestimated' == 1 {
			mat `__betafe' = __b
			local __colfe = colsof(`__betafe')-1
			mat `__betafe' = `__betafe'[1,1..`__colfe']
			mat `__scorefe' = _score
			mat `__Hessfe' = _hessian
		} 
		else {		
			mat `__betare' = __b
			local __creg: word count `_rhs_names'
			local __posofcons = `__creg'+1
			local __creg1 = `__creg'+2
			local __colre = colsof(`__betare')-2
			mat `__betare' = `__betare'[1,1..`__creg'],`__betare'[1,`__creg1'..`__colre']
			mat `__scorere' = _score
			mat `__Hessre' = _hessian
		}
    	
		mata: _xsmle_hausman_ml("`temp_id' `temp_t'", `e(t_max)', `__creg', `__posofcons',"`__betafe'","`__betare'", "`__scorefe'", "`__scorere'", "`__Hessfe'", "`__Hessre'")
	}
}

**********************************
*** Display estimation results ***
**********************************

DiSpLaY, level(`level') hausman(`_rc') `diopts'

/// Destructor
local _scalars "_hau_chi2_df _hau_chi2_p _hau_chi2 N_clust converged itfinal ll CILEVEL MaXiterate NRTOLerance LTOLerance TOLerance roblag"
local _matrices "_hessian _score _V _grad __b"
foreach n of local _scalars {
	cap scalar drop	`n'
}
foreach n of local _matrices {
	cap matrix drop	`n'
}
if "`_wmatspmatobj'" == "1" cap mat drop `wmatrix'
if "`_ematspmatobj'" == "1" cap mat drop `ematrix'
if "`_dmatspmatobj'" == "1" cap mat drop `dmatrix'

end



program define DiSpLaY, eclass
        syntax [, Level(string) hausman(string) *]
	  
		local diopts "`options'"
		local vv : di "version " string(max(10,c(stata_version))) ", missing:"
		
		if "`e(effects)'" == "fe" {
			if "`e(model)'" == "sar" {
				if "`e(type)'" == "ind"  eret local title "SAR with spatial fixed-effects"
				if "`e(type)'" == "time" eret local title "SAR with time fixed-effects"
				if "`e(type)'" == "both" eret local title "SAR with spatial and time fixed-effects"
			}
			if "`e(model)'" == "sdm" {
				if "`e(type)'" == "ind"  eret local title "SDM with spatial fixed-effects"
				if "`e(type)'" == "time" eret local title "SDM with time fixed-effects"
				if "`e(type)'" == "both" eret local title "SDM with spatial and time fixed-effects"
			}
			if "`e(model)'" == "sem" {
				if "`e(type)'" == "ind"  eret local title "SEM with spatial fixed-effects"
				if "`e(type)'" == "time" eret local title "SEM with time fixed-effects"
				if "`e(type)'" == "both" eret local title "SEM with spatial and time fixed-effects"
			}
			if "`e(model)'" == "sac" {
				if "`e(type)'" == "ind"  eret local title "SAC with spatial fixed-effects"
				if "`e(type)'" == "time" eret local title "SAC with time fixed-effects"
				if "`e(type)'" == "both" eret local title "SAC with spatial and time fixed-effects"
			}
		}
		else {
			if "`e(model)'" == "sar" eret local title "SAR with random-effects"
			if "`e(model)'" == "sdm" eret local title "SDM with random-effects"
			if "`e(model)'" == "sem" eret local title "SEM with random-effects"
			if "`e(model)'" == "gspre" eret local title "GSPRE with random-effects"
		}
		
        #delimit ;
		di as txt _n "`e(title)'" _col(54) "Number of obs " _col(68) "=" /*
			*/ _col(70) as res %9.0g e(N) _n;
        di in gr "Group variable: " in ye abbrev("`e(ivar)'",12) 
           in gr _col(51) "Number of groups" _col(68) "="
                 _col(70) in ye %9.0g `e(N_g)';
        di in gr "Time variable: " in ye abbrev("`e(tvar)'",12)                    
           in gr _col(55) in gr "Panel length" _col(68) "="
                 _col(70) in ye %9.0g `e(t_max)' _n;
        /*di       _col(64) in gr "avg" _col(68) "="
                 _col(70) in ye %9.1f `e(g_avg)' ;
        di       _col(64) in gr "max" _col(68) "="
                 _col(70) in ye %9.0g `e(g_max)' _n */;   
    	display in gr "R-sq:" _col(10) "within  = " in yel %6.4f `e(r2_w)';
    	display in gr _col(10) "between = " %6.4f in yel `e(r2_b)';
    	display in gr _col(10) "overall = " %6.4f in yel `e(r2)' _n;
    	if "`e(effects)'"=="fe" display in gr "Mean of fixed-effects = " in yel %7.4f e(a_avg) _n;   
   		if "`e(ll_c)'"!="" local _ll = `e(ll_c)';
		else local _ll = `e(ll)';
        di in gr "`e(crittype)' = " in yellow %10.4f `_ll';
		if "`e(vce)'"=="srobust" di in gr _col(9) 
		"(Standard errors adjusted for both within-" in yel "`e(ivar)'" in gr " and cross-" in yel "`e(ivar)'" in gr " correlation)";
        #delimit cr                    

*** DISPLAY RESULTS
`vv' _coef_table, level(`level') `diopts' 

if "`hausman'"!="" & "`hausman'"=="0" {
    di as text "Ho: difference in coeffs not systematic " _c
    di _col(40) in smcl "{help j_chibar##|_new:chi2(" _hau_chi2_df ") = }" /*
        */ as result %5.2f _hau_chi2 _c
    di _col(60) as text "Prob>=chi2 = " as result %5.4f /*
            */ _hau_chi2_p
    di as text "{hline 78}"
    eret scalar hau_chi2 = _hau_chi2
	eret scalar hau_chi2_p = _hau_chi2_p
	eret scalar hau_chi2_df = _hau_chi2_df
}
if "`hausman'"!="" & "`hausman'"!="0" {
	di as text "  Fitted models fails to meet the asymptotic assumptions of the Hausman test"
	di as text "{hline 78}"
}
end


/* ----------------------------------------------------------------- */

program define ParseLY
	args returmac colon leeyu
	
	local 0 ", `leeyu'"
	syntax [, LEEYU * ]

	if `"`options'"' != "" {
		di as error "The type() suboption is incorrectly specified"
		exit 198
	}
	local wc : word count `leeyu'
	if `wc' > 1 {
		di as error "type() invalid, only " /*
			*/ "one type_option can be specified"
		exit 198
	}
	c_local `returmac' `leeyu'
	
end

/* ----------------------------------------------------------------- */

program define ParseOTHvce
	args returmac colon vce
	
	local 0 ", `vce'"
	syntax [, DKraay * ]

** SROBust ** it works but it is not included for now (not documented)

	if `"`options'"' != "" {
		di as error "option vce() incorrectly specified"
		exit 198
	}
	local wc : word count `dkraay' `srobust'
	if `wc' > 1 {
		di as error "vce() invalid, only " /*
			*/ "one vce_option can be specified"
		exit 198
	}
	c_local `returmac' `dkraay'`srobust'
	
end
	
/* ----------------------------------------------------------------- */

program define Parse2waycsSpatMat, rclass
	syntax [, CSMATrix(string) ]

mata: st_rclear()
ret local rcmd "Parse2waycsSpatMat"

local smatrix `csmatrix'


if ("`smatrix'"=="") {
	display as error "Option -vce()- incorrectly specified. Suboption -srobust- requires that also a Stata matrix or a -spamat- object {it:name} is specified."
	error 198
}
else {
	local n_smatrix: word count `smatrix'
	if `n_smatrix'!=1 {
		display as error "Only one Stata matrix (or -spmat- object) is allowed in -vce(srobust {it:name})-."
	    error 198
	}
	capture confirm matrix `smatrix'
	local _rc_mat_assert = _rc
	if `_rc_mat_assert' != 0 {
		capture mata: SPMAT_assert_object("`smatrix'")
		local _rc_spmat_assert = _rc
		if `_rc_spmat_assert' == 3499 {
			capt findfile spmat.ado
		    if _rc {
		        di as error "Only Stata matrix and -spmat- objects are allowed as argument of -vce(drobust {it:name})-."
				di as error "You can install -spmat- by typing {stata net install sppack}."
		        error 499
		    }
		}
		if `_rc_spmat_assert' != 0 {
			di "{inp}`smatrix' {err}is not a valid {help spmat} object"
			exit 498
		}
		capture mata: SPMAT_check_if_banded("`smatrix'",1)
		if _rc !=0 {
			di as error "xsmle does not support banded matrices"
			exit 498
		}
		
		tempname smatrix_new
		capture spmat getmatrix `smatrix' `smatrix_new'
		if _rc {
			di "{inp}`smatrix' {err}is not a valid {help spmat} object"
			exit 498
		}
		else {
			tempname _smatspmatobj
			mata: st_matrix("`_smatspmatobj'", `smatrix_new')
			mata: `smatrix_new'=.
			local rww=rowsof(`_smatspmatobj')
		    local rcw=colsof(`_smatspmatobj')
		    if `rww' != `rcw' {
			    display as error "The matrix specified in vce(srobust {it:`smatrix'}) is not square."
			    error 198
		    }	
			ret matrix _smatspmatobj = `_smatspmatobj'
		}
	}
	if `_rc_mat_assert' == 0 {
    	local rww=rowsof(`smatrix')
    	local rcw=colsof(`smatrix')
    	if `rww' != `rcw' {
	    	display as error "The matrix specified in vce(srobust {it:`smatrix'}) is not square."
	    	error 198
    	}
		return local smatrix "`smatrix'"
	}
}

di in yel "Warning: Two-way clustering a' la Cameroon et al. (2009) requires a contiguity-like spatial structure."
di in yel "         Be aware that valid ineference may be conducted ONLY with such a structure."
di ""

end


/* ----------------------------------------------------------------- */

program define ParseSpatMat, rclass
	syntax [, CWMATrix(string) CEMATrix(string) CDMATrix(string) ]

mata: st_rclear()
ret local rcmd "ParseSpatMat"

local wmatrix `cwmatrix'
local ematrix `cematrix'
local dmatrix `cdmatrix'

if ("`wmatrix'"=="" & "`ematrix'"=="") {
	display as error "At least one of wmatrix() and ematrix() must be specified"
	error 198
}
if ("`wmatrix'" != "") {
	local n_wmatrix: word count `wmatrix'
	if `n_wmatrix'!=1 {
		display as error "Only one spatial weighting matrix `wmatrix' is allowed"
	    error 198
	}
	capture confirm matrix `wmatrix'
	local _rc_mat_assert = _rc
	if `_rc_mat_assert' != 0 {
		capture mata: SPMAT_assert_object("`wmatrix'")
		local _rc_spmat_assert = _rc
		if `_rc_spmat_assert' == 3499 {
			capt findfile spmat.ado
		    if _rc {
		        di as error "Only stata matrix and -spmat- objects are allowed as argument of -wmat()-."
				di as error "You can install -spmat- by typing {stata net install sppack}."
		        error 499
		    }
		}
		if `_rc_spmat_assert' != 0 {
			di "{inp}`wmatrix' {err}is not a valid {help spmat} object"
			exit 498
		}
		capture mata: SPMAT_check_if_banded("`wmatrix'",1)
		if _rc !=0 {
			di as error "xsmle does not support banded matrices"
			exit 498
		}
		
		tempname wmatrix_new
		capture spmat getmatrix `wmatrix' `wmatrix_new'
		if _rc {
			di "{inp}`wmatrix' {err}is not a valid {help spmat} object"
			exit 498
		}
		else {
			tempname _wmatspmatobj
			mata: st_matrix("`_wmatspmatobj'", `wmatrix_new')
			mata: `wmatrix_new'=.
			local rww=rowsof(`_wmatspmatobj')
		    local rcw=colsof(`_wmatspmatobj')
		    if `rww' != `rcw' {
			    display as error "Spatial weighting matrix `wmatrix' is not square"
			    error 198
		    }	
			ret matrix _wmatspmatobj = `_wmatspmatobj'
		}
	}
	if `_rc_mat_assert' == 0 {
    	local rww=rowsof(`wmatrix')
    	local rcw=colsof(`wmatrix')
    	if `rww' != `rcw' {
	    	display as error "Spatial weighting matrix `wmatrix' is not square"
	    	error 198
    	}
		return local wmatrix "`wmatrix'"
	}
}

if ("`ematrix'" != "") {
	local n_ematrix: word count `ematrix'
	if `n_ematrix'!=1 {
		display as error "Only one spatial weighting matrix `ematrix' is allowed"
	    error 198
	}
	capture confirm matrix `ematrix'
	local _rc_mat_assert = _rc
	if `_rc_mat_assert' != 0 {
		capture mata: SPMAT_assert_object("`ematrix'")
		local _rc_spmat_assert = _rc
		if `_rc_spmat_assert' == 3499 {
			capt findfile spmat.ado
		    if _rc {
		        di as error "Only stata matrix and -spmat- objects are allowed as argument of -emat()-."
				di as error "You can install -spmat- by typing {stata net install sppack}."
		        error 499
		    }
		}
		if `_rc_spmat_assert' != 0 {
			di "{inp}`ematrix' {err}is not a valid {help spmat} object"
			exit 498
		}
		
		capture mata: SPMAT_check_if_banded("`ematrix'",1)
		if _rc !=0 {
			di as error "xsmle does not support banded matrices"
			exit 498
		}
		
		tempname ematrix_new
		capture spmat getmatrix `ematrix' `ematrix_new'
		if _rc {
			di "{inp}`ematrix' {err}is not a valid {help spmat} object"
			exit 498
		}
		else {
			tempname _ematspmatobj
			mata: st_matrix("`_ematspmatobj'", `ematrix_new')
			mata: `ematrix_new'=.
			local rww=rowsof(`_ematspmatobj')
		    local rcw=colsof(`_ematspmatobj')
		    if `rww' != `rcw' {
			    display as error "Spatial weighting matrix `ematrix' is not square"
			    error 198
		    }	
			ret matrix _ematspmatobj = `_ematspmatobj'
		}
	}
	if `_rc_mat_assert' == 0 {
    	local rww=rowsof(`ematrix')
    	local rcw=colsof(`ematrix')
    	if `rww' != `rcw' {
	    	display as error "Spatial weighting matrix `ematrix' is not square"
	    	error 198
    	}
		return local ematrix "`ematrix'"
	}
}

if ("`dmatrix'" != "") {
	local n_dmatrix: word count `dmatrix'
	if `n_dmatrix'!=1 {
		display as error "Only one spatial weighting matrix `dmatrix' is allowed"
	    error 198
	}
	capture confirm matrix `dmatrix'
	local _rc_mat_assert = _rc
	if `_rc_mat_assert' != 0 {
		capture mata: SPMAT_assert_object("`dmatrix'")
		local _rc_spmat_assert = _rc
		if `_rc_spmat_assert' == 3499 {
			capt findfile spmat.ado
		    if _rc {
		        di as error "Only stata matrix and -spmat- objects are allowed as argument of the option -dmat()-."
				di as error "You can install -spmat- by typing {stata net install sppack}."
		        error 499
		    }
		}
		if `_rc_spmat_assert' != 0 {
			di "{inp}`dmatrix' {err}is not a valid {help spmat} object"
			exit 498
		}
		
		capture mata: SPMAT_check_if_banded("`dmatrix'",1)
		if _rc !=0 {
			di as error "xsmle does not support banded matrices"
			exit 498
		}
		
		tempname dmatrix_new
		capture spmat getmatrix `dmatrix' `dmatrix_new'
		if _rc {
			di "{inp}`dmatrix' {err}is not a valid {help spmat} object"
			exit 498
		}
		else {
			tempname _dmatspmatobj
			mata: st_matrix("`_dmatspmatobj'", `dmatrix_new')
			mata: `dmatrix_new'=.
			local rww=rowsof(`_dmatspmatobj')
		    local rcw=colsof(`_dmatspmatobj')
		    if `rww' != `rcw' {
			    display as error "Spatial weighting matrix `dmatrix' is not square"
			    error 198
		    }	
			ret matrix _dmatspmatobj = `_dmatspmatobj'
		}
	}
	if `_rc_mat_assert' == 0 {
    	local rww=rowsof(`dmatrix')
    	local rcw=colsof(`dmatrix')
    	if `rww' != `rcw' {
	    	display as error "Spatial weighting matrix `dmatrix' is not square"
	    	error 198
    	}
		return local dmatrix "`dmatrix'"
	}
}


end



/* ----------------------------------------------------------------- */

program define ParseMod
	args returmac colon model

	local 0 ", `model'"
	syntax [, SAR SDM SEM SAC GSPRE * ]

	if `"`options'"' != "" {
		di as error "model(`options') not allowed"
		exit 198
	}
	
	local wc : word count `sar' `sdm' `sem' `sac' `gspre'

	if `wc' > 1 {
		di as error "model() invalid, only " /*
			*/ "one model can be specified"
		exit 198
	}

	if `wc' == 0 {
		c_local `returmac' 1
	}
	else {
		if ("`sar'"=="sar") local modtype=1
		if ("`sdm'"=="sdm") local modtype=2
		if ("`sem'"=="sem") local modtype=3
		if ("`sac'"=="sac") local modtype=4
		if ("`gspre'"=="gspre") local modtype=5
		c_local `returmac' `modtype' 		
	}	

end

/* ----------------------------------------------------------------- */

program define ParseType
	args returmac colon type

	local 0 ", `type'"
	syntax [, Ind Time Both * ]

	if `"`options'"' != "" {
		di as error "type(`options') not allowed"
		exit 198
	}
	
	local wc : word count `ind' `time' `both'

	if `wc' > 1 {
		di as error "type() invalid, only " /*
			*/ "one type can be specified"
		exit 198
	}
	if `wc' == 0 {
		c_local `returmac' 1
	}
	else {
		if ("`ind'"=="ind") local _efftype=1
		if ("`time'"=="time") local _efftype=2
		if ("`both'"=="both") local _efftype=3
		c_local `returmac' `_efftype' 		
	}	

end

/* ----------------------------------------------------------------- */

program define ParseIndirect
	args retumac retumac1 colon opts 

	local 0 ", `opts'"
	
	syntax [, INDirect NSIM(integer 500) * ]


	if `"`options'"' != "" {
		di as error "`options' not allowed"
		exit 198
	}

	c_local `retumac' `indirect'
	c_local `retumac1' `nsim'
	
end

/* ----------------------------------------------------------------- */

* version 1.0.0  25jun2009 from Stata 11.2
program _get_diopts, sclass
	/* Syntax:
	 * 	_get_diopts <lmacname> [<lmacname>] [, <options>]
	 *
	 * Examples:
	 * 	_get_diopts diopts, `options'
	 * 	_get_diopts diopts options, `options'
	 */

	local DIOPTS	Level(cilevel)		///
			vsquish			///
			ALLBASElevels		///
			NOBASElevels		/// [sic]
			BASElevels		///
			noCNSReport		///
			FULLCNSReport		///
			noOMITted		///
			noEMPTYcells		///
			COEFLegend		///
			SELEGEND

	syntax namelist(max=2) [, `DIOPTS' *]

	opts_exclusive "`baselevels' `nobaselevels'"
	opts_exclusive "`cnsreport' `fullcnsreport'"
	opts_exclusive "`coeflegend' `selegend'"
	local K : list sizeof namelist
	gettoken c_diopts c_opts : namelist

	if `K' == 1 & `:length local options' {
		syntax namelist(max=2) [, `DIOPTS']
	}

	if "`level'" != "`c(level)'" {
		local levelopt level(`level')
	}
	c_local `c_diopts'			///
			`levelopt'		///
			`vsquish'		///
			`allbaselevels'		///
			`baselevels'		///
			`cnsreport'		///
			`fullcnsreport'		///
			`omitted'		///
			`emptycells'		///
			`coeflegend'		///
			`selegend'

	if `K' == 2 {
		c_local `c_opts' `"`options'"'
	}
	
end

/* ----------------------------------------------------------------- */

* version 1.0.1  22aug2009 from Stata 11.2
program _post_vce_rank

	syntax, [CHecksize]

	/* use checksize option if it is possible to have a [0,0] e(V)
 	   matrix */

	if "`checksize'" != "" {
		tempname V
		capture matrix `V' = e(V)
		if _rc {
			exit
		}
		local cols = colsof(`V')
		if `cols' == 0 {
			exit
		}
	}
	tempname V Vi rank
	
	mat `V' = e(V)
	mat `Vi' = invsym(`V')
	sca `rank' = rowsof(`V') - diag0cnt(`Vi')
	
	mata:st_numscalar("e(rank)", st_numscalar("`rank'"))
	
end


/* ----------------------------------------------------------------- */

* version 1.0.3  10oct2011 from Stata 11.2 (sfpanel)
program define _parse_constraints, eclass

syntax, constraintslist(string asis) estparams(string asis) 

if "`constraintslist'"!="" {
	tempname b
	mat `b' = (`estparams')
	eret post `b'
		foreach cns of local constraintslist {
			constraint get `cns'
			if `r(defined)' != 0 {
				makecns `cns'
				if "`r(clist)'" == "" continue
				mat _CNS = nullmat(_CNS) \ get(Cns)	
		
			}
			else {
				di as err "Constraint `cns' is not defined."
			    error 198
			    exit
			}
		}
	
}

end



exit



********************************** VERSION COMMENTS **********************************
* version 1.3.8 16mar2016 - Fix (again) a bug in the  -constraint()- option preventing multiple contraints 
*						  - Fix a display bug for RE models (sigma_e is actually sigma2_e)
* version 1.3.7 2may2014 - Fix the -constraint()- option bug
* version 1.3.6 12mar2014 - Version number sync between version of the pkg (SSC and econometrics.it) 
* version 1.3.5 13jul2013 - Hausman test, Time-Spatial clustering for e(V) and roblag(default) = floor(4*(5/100)^(2/9)) added
* version 1.3.4 13may2013 - Small-bug fixes: syntax errors
* version 1.3.3 18apr2013 - Small-bug fixes and factor variables full compatibility
* version 1.3.2 21mar2013 - Examples revised to distribute usaww.spmat
* version 1.3.1 12feb2013 - Check for banded matrices added
* version 1.3 23jan2013 - Small-bug fixes: syntax errors
* version 1.2 23nov2012 - Small-bug fixes: syntax errors
* version 1.1 20oct2012 - Small-bug fixes: syntax errors
* version 1.0.4 4apr2012 - Small-bug fixes: syntax errors
* version 1.0.3 15nov2011 - Small-bug fixes: syntax errors
* version 1.0.2 28sep2011 - Small-bug fixes: syntax errors
* version 1.0.1  20sep2011 - First version: merge between -spm- by fbapm and -xsmle- by gh 



