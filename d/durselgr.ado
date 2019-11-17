*! 17jun2004	Program for calculating Survival function.
*! 21jul2004	Replace unconditional survival function with conditional survival function (i.e., given uncensored).
*! 07dec2005	Updated survival function calculation to correspond to changes in dursel.ado (time option).
*! 05jul2007	Update help file, write distribution check, update example.

program define durselgr, eclass
  version 8.0
  syntax varlist [if], [ HAZard SURVival SAVing(string) NOGraph GRSave(string) FIRTH ]

  if "`firth'" ~= "" {
     di in r _n "dursel for Stata does not yet support the FIRTH option"
     exit 198
  }

  if "`nograph'" ~= "" { 
	local nograph "nodraw" 
	}
  
  marksample touse

  tokenize `varlist'  
  local depname "`1'"
  local distname `e(user)'
  local savename "`generate'"
  local savegrph "`grsave'"

  if "`distname'" != "" { 
     if "`distname'" == "lgnsel" {
       di in red ""
       di in red "  The lognormal distribution is not supported by durselgr."
       di in red "  durselgr only works after specifying dist(exp) or dist(weibull) in dursel."
       di in red ""
       exit
     }
     else if "`distname'" != "expsel" & "`distname'" != "wblsel" {
       di in red ""
       di in red "  Distribution `distname' not yet included,"
       di in red "  durselgr only works after specifying dist(exp) or dist(weibull) in dursel."
       di in red ""
       exit
       }
     }
  else { 
     di in red ""
     di in red "  Distribution can't be accessed or not properly specified in previous dursel model."
     di in red "  Please re-run dursel model first."
     di in red ""
     exit
     }

  if "`hazard'" ~= "" {
     if "`survival'" ~= "" {
        di in r "Error: Can only specify one of hazard or survival"
        exit 198
     }
     local funcname hazard
  }
  else if "`survival'" ~= "" {
     local funcname survival
	  }
  else local funcname hazard

  quietly sum `depname'
  local maxdur = r(max)
  local mindur = r(min)

  tempfile dataset
  quietly save `dataset'

  foreach var of varlist _all {
	quietly sum `var'
	if r(N) == 0 {
	  drop `var'
	  }
  }

  quietly collapse (mean) _all if `touse'
  quietly expand 1000
  quietly replace `depname' = `mindur' + (`maxdur'-`mindur')*(_n/1000)

  if "`distname'" == "expsel" {

  tempname selpred durpred lambda1 lambda2 rhostar hazard survival

  quietly predict `selpred', eq(#1) xb
  quietly gen `lambda1' = exp(`selpred')

  quietly predict `durpred', eq(#2) xb
  quietly gen `lambda2' = exp(-`durpred')

  quietly gen `rhostar' = (exp(2*[Z_alpha]_b[_cons])-1)/(exp(2*[Z_alpha]_b[_cons])+1)

	quietly gen `survival' = (exp(-`lambda1'-`depname'*`lambda2')*(1 + 	/*
		*/ `rhostar'*(1-exp(-`depname'*`lambda2'))*(1-exp(-`lambda1'))))/exp(-`lambda1')

	quietly gen `hazard' = exp(ln(`lambda2') - `lambda2'*`depname' - `lambda1' /*
		*/ + ln(1+`rhostar'*(2*exp(-`depname'*`lambda2')-1)*(exp(-`lambda1')-1)))/`survival'

	if "`funcname'" == "survival" {

	  twoway line `survival' `depname', xtitle("Failure Time") ytitle("Survival Rate")	/*
		*/ sort saving(`grsave') title("Exponential Survival Function") `nograph'
	
	}

	else if "`funcname'" == "hazard" {

	  twoway line `hazard' `depname', xtitle("Failure Time") ytitle("Hazard Rate")	/*
		*/ sort saving(`grsave') title("Exponential Hazard Function") `nograph'

	}

  }


  if "`distname'" == "wblsel" {

  tempname selpred durpred lambda1 lambda2 rhostar p hazard survival

  quietly predict `selpred', eq(#1) xb
  quietly gen `lambda1' = exp(`selpred')

  quietly predict `durpred', eq(#2) xb
  quietly gen `lambda2' = exp(-`durpred')

  quietly gen `rhostar' = (exp(2*[Z_alpha]_b[_cons])-1)/(exp(2*[Z_alpha]_b[_cons])+1)
  quietly gen `p' 	= exp([ln_p]_b[_cons])

	quietly gen `survival' = (exp(-`lambda1'-(`depname'*`lambda2')^`p')*(1 + 	/*
		*/ `rhostar'*(1-exp(-(`depname'*`lambda2')^`p'))*(1-exp(-`lambda1'))))/exp(-`lambda1')

	quietly gen `hazard' = exp(ln(`lambda2') + ln(`p') + 				/*
		*/		(`p'-1)*ln(`lambda2'*`depname') 			/*
		*/		- (`lambda2'*`depname')^`p' - `lambda1'			/*
		*/		+ ln(1+`rhostar'*(2*exp(-(`depname'*`lambda2')^`p')	/*
		*/		- 1)*(exp(-`lambda1')-1)) )/`survival'		

	if "`funcname'" == "survival" {

	  twoway line `survival' `depname', xtitle("Failure Time") ytitle("Survival Rate")	/*
		*/ sort saving(`grsave') title("Weibull Survival Function") `nograph'

	}

	else if "`funcname'" == "hazard" {

	  twoway line `hazard' `depname', xtitle("Failure Time") ytitle("Hazard Rate")	/*
		*/ sort saving(`grsave') title("Weibull Hazard Function") `nograph'

	}

  }


if "`saving'" ~= "" {
  generate hazard = `hazard'
  generate survival = `survival'
  keep `depname' survival hazard
  rename `depname' _t

  label var _t 		"Failure Time"
  label var hazard	"Hazard Function from DURSEL"
  label var survival	"Survival Function from DURSEL"

  quietly save `saving'
  }

quietly use `dataset', clear

end

exit
