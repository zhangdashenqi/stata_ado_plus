*! version 1.2 - pbe - 1/27/05, 7/23/04, 6/9/01
*! based on two-step heteroscedastic regression in 4th edition of Greene
program define wls0
  version 8.0
  syntax varlist [if] [in] , WVars(varlist) Type(string) [ NOConst ROBust hc2 hc3 GRaph ]

  local typerr = 0
  if "`type'"~="abse" & "`type'"~="absen" & "`type'"~="e2" & "`type'"~="loge2" & "`type'"~="xb2" {
    local typerr = 1
  }
  
  if `typerr' {
    display
    display in red "Error: WLS type must be one of the following:"
    display in red "       abse  - absolute value of residual"
    display in red "       absen  - absolute value of residual, ala Neter et al"
    display in red "       e2    - residual squared"
    display in red "       loge2 - log residual squa"
    display in red "       xb2   - fitted value squared"
    exit
  }

  capture drop _wls_wgt _wls_res
  quietly regress `varlist' `if' `in'
  tempvar p1 p2 p3 e grp bsd ee

  quietly predict `p3'
  quietly predict `e', resid
  
  if "`type'"=="abse" { 
    generate `ee' = abs(`e') 
    local eetype " type: proportional to abs(e)"
  }
  if "`type'"=="absen" { 
    generate `ee' = abs(`e') 
    local eetype " type: proportional to abs(e), ala Neter et al"
  }
  if "`type'"=="e2" { 
    generate `ee' = (`e')^2 
    local eetype " type: proportional to e^2"
  }
  if "`type'"=="loge2" { 
    generate `ee' = log((`e')^2 )
    local eetype " type: proportional to log(e)^2 "
  }
  if "`type'"=="xb2" {
    quietly replace `p3' = (`p3')^2
    local eetype " type: proportional to xb^2 "
  }
  
  if "`type'"~="xb2" {
    quietly regress `ee' `wvars', `noconst'
    quietly predict `p1'
  }

  if "`type'"=="loge2" { 
    generate _wls_wgt = 1/exp(`p1') 
  }
  else if "`type'"=="xb2" { 
    generate _wls_wgt = 1/(`p3') 
  }
  else if "`type'"=="absen" { 
    generate _wls_wgt = 1/(`p1')^2 
  } 
  else { 
    generate _wls_wgt = 1/(`p1') 
  }


  label variable _wls_wgt "wls weights"

  display
  display in green "WLS regression - `eetype'"
  display
  regress `varlist' `if' `in' [aw = _wls_wgt], `robust' `hc2' `hc3'
  quietly predict _wls_res, resid
  quietly predict `p2'
  label variable _wls_res "wls residuals"
  quietly replace _wls_res = _wls_res*_wls_wgt
  if "`graph'" != "" {
    graph twoway scatter _wls_res `p2', yline(0) 
  }
end
