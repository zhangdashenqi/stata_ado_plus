*! version 1.0  09sep2003
*! version 1.1  15oct2003
*! version 1.2  09jan2004
*! version 1.3  14jan2004
*! version 1.4  13feb2004	Add b*p specification.
*! version 1.5  03mar2004	Minor changes in displaying results.
*! version 1.6  06mar2004	Add mlopts() command.
*! version 1.7  02apr2004	Use non-interactive ml routines.
*! version 1.8  21apr2004	Redo ml_options parsing using Stata defaults.
*! version 1.9  03may2004	Add starting values calculation using probit and logged OLS. Add time option.
*!		13may2004	Make positive selection coefficients the default option and create selneg option.
*!		16jun2004	Add durselgr companion utility.
*! version 2.0  30nov2005	Make weibull options like Stata's with weibull producing b*p and time option for -b.
*!		03jul2007	Update starting values calculation; remove selneg option.
*!		10jul2007	Fix how _b0dur is set.

program define dursel, eclass
  version 7.0
  syntax varlist [if] [in] [aw fw pw iw/], SELect(string) [ Dist(string) RTCensor(varname) time /*
     */ FIRTH NORobust CLuster(varname) Level(int $S_level) * ]

  mlopts mlopts, `options'

  marksample touse, novar
  if "`firth'" ~= "" {
     di in r _n "dursel for Stata does not yet support the FIRTH option"
     exit 198
  }
  if "`norobust'" == "" { local robust robust }       /* default: robust SE */
  if "`cluster'" ~= "" { 
     local clusopt "cl(`cluster')"
     if "`norobust'" ~= "" {
        di in r "Error: the norobust & cluster options are incompatible"
        exit 198
     }
  }

  if "`time'" ~= "" {        		/* Hazard or Accelerated Failure Time Interpretation */
     if "`dist'" == "lognormal" {
        di in r "Note: the lognormal reports an accelerated failure time interpretation by default"
     }
     tempname _aft
     quietly gen `_aft' = 1
  }
  else {
     tempname _aft
     quietly gen `_aft' = 0
	  }

  local wtype `weight'
  local wtexp `"`exp'"'
  if "`weight'" != "" { local wgt `"[`weight'`exp']"' }

	if "`weight'" == "pweight" | "`cluster'" != "" { 
		local robust robust
	}

gettoken depvar rhsvars : varlist                   /* separate dv,rhs    */

		tokenize `"`select'"', parse(" =")
		if "`1'" == "=" { local 1 " " }
		if "`2'" == "=" { 
			unab 1 : `1' 
			local seldep `1'
			
			local 1 " " 
			local 2 " " 
		}

		local 0 `*'
		syntax varlist(default=none) [, ]
		local selind `varlist'

  if "`seldep'" == "" { 
	tempname depvar_s
	quietly gen byte `depvar_s' =  `depvar' != . 
	local selname "select"
  }
  else {
	tempname depvar_s
	quietly gen `depvar_s' = `seldep'
	local selname `seldep'
  }

  markout `touse' `selind' `depvar_s' `cluster', strok
  marksample touse2
  markout `touse2' `depvar' `rhsvars'
  qui replace `touse' = 0 if `depvar_s' & !`touse2'
	
  if "`rtcensor'" ~= "" { 
     tempname _rtcnsr
     quietly gen `_rtcnsr' = `rtcensor'
     tempname cat
     qui tab `_rtcnsr' if `touse', matrow(`cat')          /* tabulate _rtcnsr    */
     if `cat'[1,1] ~= 0 | `cat'[2,1] ~= 1 {
     di in r "Error: Either no variation in right-censoring variable"
	     "or values other than 0 or 1 encountered."
     di in r ""
     exit 198
     }
  }

  else {
     tempname _rtcnsr
     quietly gen `_rtcnsr' = 0
  }

  tempname nobs
  quietly sum `depvar_s' if `touse'
  quietly gen `nobs' = r(sum)
  est scalar N_cens = `nobs'
  if `r(N)' == `r(sum)' {
	di in red "Dependent variable never censored due to selection: "
	di in red "model would simplify to standard duration model"
		exit 498
	}

	/* Set up starting values. */

  tempname _b0sel _b0dur _b0sig _b0
  tempvar lndepvar

  quietly probit `depvar_s' `selind' if `touse'
  matrix _b0sel =  e(b)

  quietly gen `lndepvar' = log(`depvar') if `touse' & `depvar_s'==1
  quietly reg `lndepvar' `rhsvars' if `touse' & `depvar_s'==1

  scalar _b0sig = sqrt(e(rss)/e(df_r))

  if `_aft'== 0 {
    if "`dist'" == "exp" {
       matrix _b0dur = -e(b)
       } 
    else if "`dist'" == "weibull" {
       matrix _b0dur = -e(b)/_b0sig
       } 
    }

  else if `_aft'== 1 {
    matrix _b0dur =  e(b)
    } 

  if "`dist'" != "" { 
	if "`dist'" != "exp" & "`dist'" != "weibull" & "`dist'" != "lognormal"{
	    di in red "Distribution `dist' not yet included,"
	    di in red "Specify dist(exp), dist(weibull), or dist(lognormal)."
	}
	else local distname `dist'
  }
  else local distname exp

 if "`distname'" == "exp" {

  	matrix _b0 = _b0sel , _b0dur , log(1/_b0sig)

   	di in r "" 
	di in smcl in gr "Fitting Duration Model with Selection:" 
	capture noi ml model lf expsel (`selname': `depvar_s'=`selind') 	/*
		*/	(`depvar': `depvar' `_rtcnsr' `_aft'=`rhsvars') /Z_alpha	/*
		*/	`wgt' if `touse', maximize `robust' `clusopt' missing		/*
		*/ 	search(on) nooutput `mlopts' init(_b0 , copy)			/*
		*/	title(Exponential duration model with selection)
   	di in r "" 
   	di in r "" 
	if `_aft' {di in smcl in yellow "Accelerated Failure Time Interpretation (-beta)"}
	if !`_aft' {di in smcl in yellow "Hazard Interpretation (beta)"}
	ml display , level(`level') plus neq(2)
	_diparm Z_alpha, level(`level') prob label("Z_alpha") 
	_diparm Z_alpha, level(`level') prob label("alpha") function((exp(2*(@))-1)/(exp(2*(@))+1))  derivative(4*exp(2*@)/(exp(2*@)+1)^2)
	_diparm Z_alpha, level(`level') prob label("rho") function(((exp(2*(@))-1)/(exp(2*(@))+1))/4)  derivative((4*exp(2*@)/(exp(2*@)+1)^2)/4)
	di in smcl in gr "{hline 13}{c BT}{hline 64}"
	di in smcl in gr "Number of Uncensored Observations: " `nobs'
	di in smcl in gr "{hline 78}"
     }

  else if "`distname'" == "weibull" & `_aft' == 1 {

  	matrix _b0 = _b0sel , _b0dur , 0 , log(1/_b0sig)

  	di in r "" 
	di in smcl in gr "Fitting Duration Model with Selection:" 
	capture noi ml model lf wblsel (`selname': `depvar_s'=`selind') 	/*
		*/	(`depvar': `depvar' `_rtcnsr' `_aft'=`rhsvars') /Z_alpha /ln_p	/*
		*/	`wgt' if `touse', maximize `robust' `clusopt' missing		/*
		*/ 	search(on) nooutput `mlopts' init(_b0 , copy) 			/*
		*/	title(Weibull duration model with selection)
   	di in r "" 
   	di in r "" 
	{di in smcl in yellow "Accelerated Failure Time Interpretation (-beta)"}
	ml display , level(`level') plus neq(2)
	_diparm Z_alpha, level(`level') prob label("Z_alpha")
	_diparm Z_alpha, level(`level') prob label("alpha") function((exp(2*(@))-1)/(exp(2*(@))+1))  derivative(4*exp(2*@)/(exp(2*@)+1)^2)
	_diparm Z_alpha, level(`level') prob label("rho") function(((exp(2*(@))-1)/(exp(2*(@))+1))/4)  derivative((4*exp(2*@)/(exp(2*@)+1)^2)/4)
	di in smcl in gr "{hline 13}{c BT}{hline 64}"
	_diparm ln_p, level(`level') prob label("ln_p")
	_diparm ln_p, level(`level') prob label("p") function(exp(@))  derivative(exp(@))
	di in smcl in gr "{hline 13}{c BT}{hline 64}"
	di in smcl in gr "Number of Uncensored Observations: " `nobs'
	di in smcl in gr "{hline 78}"
     }

  else if "`distname'" == "weibull" & `_aft' == 0 {

  	matrix _b0 = _b0sel , _b0dur , 0 , log(1/_b0sig)

   	di in r "" 
	di in smcl in gr "Fitting Duration Model with Selection:"  
	ml model lf wblsel_p (`selname': `depvar_s'=`selind') 		/*
		*/	(`depvar': `depvar' `_rtcnsr' `_aft'=`rhsvars') /Z_alpha /ln_p	/*
		*/	`wgt' if `touse', maximize `robust' `clusopt' missing		/*
		*/ 	search(on) nooutput `mlopts' init(_b0 , copy) 			/*
		*/	title(Weibull duration model with selection)
   	di in r "" 
   	di in r "" 
	{di in smcl in yellow "Hazard Interpretation (beta*p)"}
	ml display , level(`level') plus neq(2)
	_diparm Z_alpha, level(`level') prob label("Z_alpha") 
	_diparm Z_alpha, level(`level') prob label("alpha") function((exp(2*(@))-1)/(exp(2*(@))+1))  derivative(4*exp(2*@)/(exp(2*@)+1)^2)
	_diparm Z_alpha, level(`level') prob label("rho") function(((exp(2*(@))-1)/(exp(2*(@))+1))/4)  derivative((4*exp(2*@)/(exp(2*@)+1)^2)/4)
	di in smcl in gr "{hline 13}{c BT}{hline 64}"
	_diparm ln_p, level(`level') prob label("ln_p")
	_diparm ln_p, level(`level') prob label("p") function(exp(@))  derivative(exp(@))
	di in smcl in gr "{hline 13}{c BT}{hline 64}"
	di in smcl in gr "Number of Uncensored Observations: " `nobs'
	di in smcl in gr "{hline 78}"
     }

  else if "`distname'" == "lognormal" {

  	matrix _b0 = _b0sel , _b0dur , 0 , log(_b0sig)

   	di in r "" 
	di in smcl in gr "Fitting Duration Model with Selection:"  
	capture noi ml model lf lgnsel (`selname': `depvar_s'=`selind') 			/*
		*/	(`depvar': `depvar' `_rtcnsr'=`rhsvars') /Z_alpha /ln_sigma	/*
		*/	`wgt' if `touse', maximize `robust' `clusopt' missing			/*
		*/ 	search(on) nooutput `mlopts' 						/*
		*/	title(Lognormal duration model with selection)
   	di in r "" 
   	di in r "" 
	{di in smcl in yellow "Accelerated Failure Time Interpretation (-beta)"}
	ml display , level(`level') neq(2) plus
	_diparm Z_alpha, level(`level') prob label("Z_rho") 
	_diparm Z_alpha, level(`level') prob label("rho") function((exp(2*(@))-1)/(exp(2*(@))+1))  derivative(4*exp(2*@)/(exp(2*@)+1)^2)
	di in smcl in gr "{hline 13}{c BT}{hline 64}"
	_diparm ln_sigma, level(`level') prob label("ln_sigma")
	_diparm ln_sigma, level(`level') prob label("sigma") function(exp(@))  derivative(exp(@))
	di in smcl in gr "{hline 13}{c BT}{hline 64}"
	di in smcl in gr "Number of Uncensored Observations: " `nobs'
	di in smcl in gr "{hline 78}"
     }

end

exit

