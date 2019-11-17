*! version 1.0  03jul2007
*! version 1.1  09mar2008	Fix sign on sigma for lognormal model.

program define sudcd, eclass
  version 7.0
  syntax varlist [if] [in] [aw fw pw iw/], DISCrete(string) Dist(string) [ RHo(varlist) RTCensor(varname) TIme /*
     */ FIRTH ROBust CLuster(varname) Level(int $S_level) * ]

  mlopts mlopts, `options'

  marksample touse, novar
  if "`firth'" ~= "" {
     di in r _n "dursel for Stata does not yet support the FIRTH option"
     exit 198
  }

  if "`robust'" ~= "" { 
     local robust robust 
     }
  if "`cluster'" ~= "" { 
     local clusopt "cl(`cluster')"
     }

  if "`dist'" != "exp" & "`dist'" != "weibull" & "`dist'" != "lognormal" {

     di in red "Distribution `dist' not yet included,"
     di in red "Specify dist(exp), dist(weibull), or dist(lognormal)."

     }

   else local distname `dist'


  if "`time'" ~= "" {        		/* Hazard or Accelerated Failure Time Interpretation */
     if "`distname'" == "lognormal" {
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

  if "`rtcensor'" ~= "" { 
     tempname _rtcnsr
     quietly gen `_rtcnsr' = `rtcensor'
     }

  else {
     tempname _rtcnsr
     quietly gen `_rtcnsr' = 0
     }


gettoken depvar_c ind_cont : varlist                   /* separate dv,rhs    */

  tokenize `"`discrete'"', parse(" =")

  if "`1'" == "=" { local 1 " " }

  if "`2'" == "=" { 
  	unab 1 : `1' 
  	local depvar_d `1'
  	
  	local 1 " " 
  	local 2 " " 
  	}

  local 0 `*'
  syntax varlist(default=none) [, ]
  local ind_disc `varlist'


  if "`rho'" ~="" {                   		/* count variables in optional rho specification. */
     local rho_num = wordcount("`rho'") + 1
     }

  else {
     local rho_num = 1
     }


  markout `touse' `ind_disc' `depvar_d' `depvar_c' `ind_cont' `cluster' `_rtcnsr' `rho', strok
	

  tempname cat

  qui tab `depvar_d' if `touse', matrow(`cat')          /* tabulate discrete depvar. */

  if `cat'[1,1] ~= 0 | `cat'[2,1] ~= 1 {
     di in red ""
     di in red "Error: Either no variation in discrete dependent variable"
     di in red "or values other than 0 or 1 encountered."
     di in red ""
     exit
     }


	/* Set up starting values. */

  tempname _b0disc _b0dur _b0rho _b0sig _b0
  tempvar lndepvar

  quietly probit `depvar_d' `ind_disc' if `touse'

     matrix _b0disc =  e(b)

  quietly gen `lndepvar' = log(`depvar_c')  if `touse'

  quietly reg `lndepvar' `ind_cont' if `touse'

     scalar _b0sig = sqrt(e(rss)/e(df_r))

     if `_aft'== 0 {

       if "`distname'" == "lognormal" {
          matrix _b0dur = e(b)
          } 
       if "`distname'" == "exp" {
          matrix _b0dur = -e(b)
          } 
       else if "`distname'" == "weibull" {
          matrix _b0dur = -e(b)/_b0sig
          } 
       }

     else if `_aft'== 1 {
       matrix _b0dur =  e(b)
       } 

     matrix _b0rho = J(1,`rho_num',0) 


 if "`distname'" == "exp" {

  	matrix _b0 = _b0disc , _b0dur , _b0rho 

   	di in r "" 
	di in smcl in gr "Fitting Exponential SUDCD Model:" 
	capture noi ml model lf sudcd_exp (`depvar_d': `depvar_d' = `ind_disc') 		/*
		*/	(`depvar_c': `depvar_c' `_rtcnsr' `_aft'= `ind_cont') (Z_alpha: `rho')	/*
		*/	`wgt' if `touse', maximize `robust' `clusopt' missing			/*
		*/ 	search(on) nooutput `mlopts' init(_b0 , copy)				/*
		*/	title(Exponential SUDCD Model)
   	di in r "" 
   	di in r "" 
	if `_aft' {di in smcl in yellow "Accelerated Failure Time Interpretation (-beta)"}
	if !`_aft' {di in smcl in yellow "Hazard Interpretation (beta)"}

	if `rho_num' == 1 {

	  ml display , level(`level') plus neq(2)
	  _diparm Z_alpha, level(`level') prob label("Z_alpha") 
	  _diparm Z_alpha, level(`level') prob label("alpha") function((exp(2*(@))-1)/(exp(2*(@))+1))  derivative(4*exp(2*@)/(exp(2*@)+1)^2)
	  _diparm Z_alpha, level(`level') prob label("rho") function(((exp(2*(@))-1)/(exp(2*(@))+1))/4)  derivative((4*exp(2*@)/(exp(2*@)+1)^2)/4)
	  di in smcl in gr "{hline 13}{c BT}{hline 64}"

	  }

	else if `rho_num' > 1 {

	  ml display , level(`level') plus neq(3)

	  }

     }

  else if "`distname'" == "weibull" & `_aft' == 1 {

  	matrix _b0 = _b0disc , _b0dur , _b0rho , log(1/_b0sig)

  	di in r "" 
	di in smcl in gr "Fitting Weibull SUDCD Model:" 
	capture noi ml model lf sudcd_wbl_aft (`depvar_d': `depvar_d' = `ind_disc') 		/*
		*/	(`depvar_c': `depvar_c' `_rtcnsr' = `ind_cont') (Z_alpha: `rho') /ln_p	/*
		*/	`wgt' if `touse', maximize `robust' `clusopt' missing			/*
		*/ 	search(on) nooutput `mlopts' init(_b0 , copy) 				/*
		*/	title(Weibull SUDCD model)
   	di in r "" 
   	di in r "" 
	{di in smcl in yellow "Accelerated Failure Time Interpretation (-beta)"}

	if `rho_num' == 1 {

	  ml display , level(`level') plus neq(2)
	  _diparm Z_alpha, level(`level') prob label("Z_alpha")
	  _diparm Z_alpha, level(`level') prob label("alpha") function((exp(2*(@))-1)/(exp(2*(@))+1))  derivative(4*exp(2*@)/(exp(2*@)+1)^2)
	  _diparm Z_alpha, level(`level') prob label("rho") function(((exp(2*(@))-1)/(exp(2*(@))+1))/4)  derivative((4*exp(2*@)/(exp(2*@)+1)^2)/4)
	  di in smcl in gr "{hline 13}{c BT}{hline 64}"
	  _diparm ln_p, level(`level') prob label("ln_p")
	  _diparm ln_p, level(`level') prob label("p") function(exp(@))  derivative(exp(@))
	  di in smcl in gr "{hline 13}{c BT}{hline 64}"

	  }

	else if `rho_num' > 1 {

	  ml display , level(`level') plus neq(3)
	  _diparm ln_p, level(`level') prob label("ln_p")
	  _diparm ln_p, level(`level') prob label("p") function(exp(@))  derivative(exp(@))
	  di in smcl in gr "{hline 13}{c BT}{hline 64}"

	  }
     }

  else if "`distname'" == "weibull" & `_aft' == 0 {

  	matrix _b0 = _b0disc , _b0dur , _b0rho , log(1/_b0sig)

   	di in r "" 
	di in smcl in gr "Fitting Weibull SUDCD Model:"  
	ml model lf sudcd_wbl_haz (`depvar_d': `depvar_d' =`ind_disc') 				/*
		*/	(`depvar_c': `depvar_c' `_rtcnsr' =`ind_cont') (Z_alpha: `rho') /ln_p	/*
		*/	`wgt' if `touse', maximize `robust' `clusopt' missing			/*
		*/ 	search(on) nooutput `mlopts' init(_b0 , copy) 				/*
		*/	title(Weibull SUDCD model)
   	di in r "" 
   	di in r "" 
	{di in smcl in yellow "Hazard Interpretation (beta*p)"}


	if `rho_num' == 1 {

	ml display , level(`level') plus neq(2)
	  _diparm Z_alpha, level(`level') prob label("Z_alpha") 
	  _diparm Z_alpha, level(`level') prob label("alpha") function((exp(2*(@))-1)/(exp(2*(@))+1))  derivative(4*exp(2*@)/(exp(2*@)+1)^2)
	  _diparm Z_alpha, level(`level') prob label("rho") function(((exp(2*(@))-1)/(exp(2*(@))+1))/4)  derivative((4*exp(2*@)/(exp(2*@)+1)^2)/4)
	  di in smcl in gr "{hline 13}{c BT}{hline 64}"
	  _diparm ln_p, level(`level') prob label("ln_p")
	  _diparm ln_p, level(`level') prob label("p") function(exp(@))  derivative(exp(@))
	  di in smcl in gr "{hline 13}{c BT}{hline 64}"

	  }

	else if `rho_num' > 1 {

	  ml display , level(`level') plus neq(3)
	  _diparm ln_p, level(`level') prob label("ln_p")
	  _diparm ln_p, level(`level') prob label("p") function(exp(@))  derivative(exp(@))
	  di in smcl in gr "{hline 13}{c BT}{hline 64}"

	  }
     }

  else if "`distname'" == "lognormal" {

  	matrix _b0 = _b0disc , _b0dur , _b0rho , log(_b0sig)

   	di in r "" 
	di in smcl in gr "Fitting Lognormal SUDCD Model:"  
	capture noi ml model lf sudcd_lgn (`depvar_d': `depvar_d'=`ind_disc') 				/*
		*/	(`depvar_c': `depvar_c' `_rtcnsr'=`ind_cont') (Z_alpha: `rho') /ln_sigma	/*
		*/	`wgt' if `touse', maximize `robust' `clusopt' missing				/*
		*/ 	search(on) nooutput `mlopts' 							/*
		*/	title(Lognormal SUDCD model)
   	di in r "" 
   	di in r "" 
	{di in smcl in yellow "Accelerated Failure Time Interpretation"}

	if `rho_num' == 1 {

	ml display , level(`level') neq(2) plus
	  _diparm Z_alpha, level(`level') prob label("Z_rho") 
	  _diparm Z_alpha, level(`level') prob label("rho") function((exp(2*(@))-1)/(exp(2*(@))+1))  derivative(4*exp(2*@)/(exp(2*@)+1)^2)
	  di in smcl in gr "{hline 13}{c BT}{hline 64}"
	  _diparm ln_sigma, level(`level') prob label("ln_sigma")
	  _diparm ln_sigma, level(`level') prob label("sigma") function(exp(@))  derivative(exp(@))
	  di in smcl in gr "{hline 13}{c BT}{hline 64}"

	  }

	else if `rho_num' > 1 {

	  ml display , level(`level') plus neq(3)
	  _diparm ln_sigma, level(`level') prob label("ln_sigma")
	  _diparm ln_sigma, level(`level') prob label("sigma") function(exp(@))  derivative(exp(@))
	  di in smcl in gr "{hline 13}{c BT}{hline 64}"

	  }
     }

end

exit

