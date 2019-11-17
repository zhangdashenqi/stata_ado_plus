*! version 1.9 29Oct99      (STB-56: sbe37)
/*
Updated for version 6
*/
program define mclest
  version 6
  syntax varlist [if] [in] [fweight iweight]                 /*
*/   [, SOR(varlist) SORITER(integer 10) SORTOL(real 0.0001) /*
*/      RC2(varname) EQRC2(varname) MUBY(varlist) DEBUG noNOrm ]

  if "`weight'" ~= "" {
    local weight="[`weight'`exp']"
  }

  * if no special effects, estimate the model and exit
  if "`sor'" == "" & "`rc2'" == "" & "`eqrc2'" == "" {
    clogit __didep `varlist' `weight' `if' `in', strata(__strata)
    exit 
  }

  global varlist "`varlist'"
  global if "`if'"
  global in "`in'"
  global weight "`weight'"
  if "`sor'" ~= "" {global sor "`sor'"}
  if "`debug'"  ==  "" {global debug="quietly "}

  * simple phi scale
  quietly gen __phi=($respfact-1)/($ncat-1)

  * create variables for beta parameters, store in $lftlist
  tokenize "$sor"
  local i=1
  while "`1'" ~= "" {
    gen __beta`i'=`1'*__phi
    local thislab: variable label `1'
    label variable __beta`i' "SOR effect for `1': `thislab'"
    local i=`i'+1
    macro shift
  }
  local nbeta=`i'-1
  if `nbeta' == 1 {global lftlist="__beta1"}
  if `nbeta'> 1 {global lftlist="__beta1-__beta`nbeta'"}

  quietly gen __sumbet=0
  local i=2
  while `i'<=$ncat {
    quietly gen __phi`i'=0
    local i=`i'+1
  }
  global rgtlist="__phi2-__phi$ncat"

  if "$sor" ~= "" {
    display _newline "Estimating Stereotype Ordered Regression for $sor"
  }

  if "`rc2'" ~= "" & "`eqrc2'" ~= "" {
    display
    display "Error: options RC2 and EQRC2 may not be used together"
    display "Error: The EQRC2 option will be ignored"
    display
    local eqrc2=""
  }

  if "`rc2'" ~= "" {
    global rc2="`rc2'"
    quietly tab $rc2, gen(__row)
    global rowcat=r(r)
    quietly gen __sig=($rc2-1)/($rowcat-1)
    local i=2
    while `i'<=$rowcat {
      quietly gen __msig`i'=__row`i'*__phi
      local i=`i'+1
    }
    local i=`i'-1
    global lftlist="$lftlist __msig2-__msig`i'"
    gen __mu=__sig*__phi
    label variable __mu "MU: RC2 association between $respfact and $rc2"
    gen __summu=0
    display _newline "Estimating rc2 effects for $rc2"
  }
  
  if "`eqrc2'" ~= "" {
    global eqrc2="`eqrc2'"
    quietly tab $eqrc2, gen(__row)
    global rowcat=r(r)
    quietly gen __sig=($eqrc2-1)/($rowcat-1)
    local i=2
    while `i'<=$rowcat {
      quietly gen __msig`i'=__row`i'*__phi+($respfact==`i')*__sig
      local i=`i'+1
    }
    local i=`i'-1
    global cenlist="$lftlist __msig2-__msig`i'"
    gen __mu=__sig*__phi
    label variable __mu "MU: equal RC2 association between $respfact and $rc2"
    global lftlist="$lftlist __mu"
    gen __summu=0
    display _newline "Estimating equal rc2 effects for $eqrc2"
  }
  
  if "`muby'" ~= "" & "`rc2'" == "" & "`eqrc2'" == "" {
    display
    display "Error: Either the RC2 or EQRC2 option is required"
    display "Error: when using the MUBY option"
    display "Error: The MUBY option will be ignored"
    display
    local muby=""
  }

  if "`muby'" ~= "" {
    global muby="`muby'"
    tokenize "$muby"
    local i=1
    while "`1'" ~= "" {
      gen __muby`i'=`1'*__sig*__phi
      local thislab: variable label `1'
      label variable __muby`i' "MU by `1': `thislab'"
      display _newline "mu varies by `1'"
      local i=`i'+1
      macro shift
    }
    local nmu=`i'-1
    if "$eqrc2" ~= "" {
      if `nmu' == 1 {global lftlist="$lftlist __muby1" }
      if `nmu' >1 {global lftlist="$lftlist __muby1-__muby`nmu'" }
    }
    else {
      if `nbeta' == 1 { global cenlist="__beta1" }
      if `nbeta' > 1  { global cenlist="__beta1-__beta`nbeta'" }
      if `nmu' == 1   { global cenlist="$cenlist __mu __muby1" }
      if `nmu' > 1    { global cenlist="$cenlist __mu __muby1-__muby`nmu'" }
    }
  }

  display _newline
  display "iteration" _col(17) "log likelihood" _col(40) "sub-changes" _col(59) "main changes"
  display _dup(70) "-"
  global iter=0
  global prev=0
  global chng=9999
  global lft=0
  global rgt=0
  global cen=0
  local conv=0
  if "`eqrc2'" == "" {
    while `conv' ~= 1 {
      leftest
      rightest
    if "$muby" ~= "" { cenest }
    if abs($chng) < `sortol' {local conv=1}
    if $iter >= `soriter' {local conv=1}
    }
  }
  else {
    while `conv' ~= 1 {
      eq1est
      eq2est
    if abs($chng) < `sortol' {local conv=1}
    if $iter >= `soriter' {local conv=1}
    }
  }
  display _dup(70) "-"
  if $iter >= `soriter' {
    display "Maximum number of `soriter' iterations reached without convergence"
  } 
  else {
    display "Convergence criterion `sortol' reached in $iter iterations"
  }
  display _newline

  * display the phi scale:
  if "$eqrc2" == "" {
    estimates unhold __rgt
    display _newline "Phi scale for $respfact"
    prhdsc
    prsc "phi" __phi $ncat
  }

  if "$rc2" ~= "" | "$eqrc2" ~= "" {
    * display sigma
    if "$rc2" ~= "" {
      estimates unhold __lft
      display _newline "Sigma scale for $rc2:"
    }
    if "$eqrc2" ~= "" {
      estimates unhold __cen
      display _newline "Equal Phi/Sigma scale for $respfact and $eqrc2:"
    }
    prhdsc
    prsc "sig" __msig $rowcat

    * display mu
    display _newline "Mu scaled association between $respfact and $eqrc2$rc2:"
    if "$muby" ~= "" | "$eqrc2" ~= "" {
      if "$rc2" ~= "" {estimates unhold __cen}
      if "$eqrc2" ~= "" {estimates unhold __lft}
      prhd
      prsnt "mu" __mu
      tokenize "$muby"
      local i=1
      while "`1'" ~= "" {
        prsnt "`1'" __muby`i'
        local i=`i'+1
        macro shift
      }
    }
    else {
      * estimate the final model using the phi and sigma scales
      if `nbeta' == 1 { local lftlist="__beta1"}
      if `nbeta' >1 { local lftlist="__beta1-__beta`nbeta'"}
      quietly replace __mu=__phi*__sig
      #delimit ;
      $debug clogit __didep $varlist `lftlist' __mu 
                   $weight $if $in, strata(__strata);
      #delimit cr
      prhd
      prsnt "mu" __mu
    }
    display _dup(79) "-"
  }

  * display the beta's
  if "$sor" ~= "" {
    if "$rc2" == "" & "$eqrc2" == "" { estimates unhold __lft }
    display _newline "Beta parameters:" 
    prhd
    tokenize "$sor"
    local i=1
    while "`1'" ~= "" {
    prsnt "`1'" __beta`i'
      local i=`i'+1
      macro shift
    }
    display _dup(79) "-" _newline
  }

  display _newline _newline "Full parameter listing:" 
  *display the rest
  clogit 

  if "`norm'" ~= "nonorm" {
    display _newline _newline "Normalized Solution:" 
    * normalize __phi
    if "$eqrc2" == "" {
      display _newline "Normalized phi scale for $respfact:"
      normize __phi $respfact $ncat phi
    }
    else {
      display _newline "Normalized phi/sigma scale for $respfact and $eqrc2:"
      normize __phi $respfact $ncat "phi"
    }
    if "$sor" ~= "" {
      * create variables for beta parameters, store in `finlist'
      tokenize "$sor"
      local i=1
      while "`1'" ~= "" {
        quietly replace __beta`i'=`1'*__phi
        local i=`i'+1
        macro shift
      }
      local i=`i'-1
      if `i' == 1 {local finlist="__beta1"}
      else {local finlist="__beta1-__beta`i'"}
    }
    if "$rc2" ~= "" {
      * normalize __sig
      display _newline "Normalized Sigma scale for $rc2:"
      normize __sig $rc2 $rowcat "sig"
      quietly replace __mu=__phi*__sig
      local finlist="`finlist' __mu"
    }
    if "$eqrc2" ~= "" {
      * normalize __sig
      normize __sig $eqrc2 $rowcat
      quietly replace __mu=__phi*__sig
      local finlist="`finlist' __mu"
    }

    if "$muby" ~= "" {
      tokenize "$muby"
      local i=1
      while "`1'" ~= "" {
        quietly replace __muby`i'=`1'*__sig*__phi
        local i=`i'+1
        macro shift
      }
      local i=`i'-1
      if `i' == 1 { local finlist="`finlist' __muby1" }
      else { local finlist="`finlist' __muby1-__muby`i'" }
    }
    clogit __didep $varlist `finlist' $weight $if $in, strata(__strata)
  } /* end of 'if "`norm'" ~= "nonorm" */

  * cleanup
  macro drop lftlist rgtlist rowcat cenlist muby rc2 eqrc2 cenlist
  macro drop lftlist rgtlist sor varlist iter prev chng lft rgt cen
  macro drop weight if in debug
end

program define leftest
  version 6
  if $iter>0 { estimates drop __lft }
  * given phi[j], estimate beta[k] 
  * (and if applicable, sigma[v]*(mu+mu[t]X[t]))
  $debug clogit __didep $varlist $lftlist $weight $if $in, strata(__strata)
  global iter=$iter+1
  local chng1=e(ll)-$prev
  global chng=e(ll)-$lft
  global lft =e(ll)
  global prev=e(ll)
  display $iter.1 _col(16) %15.4f e(ll) _col(36) %15.4f `chng1' _col(56) %15.4f $chng

  * prepare variables for estimating phi's
  tokenize "$sor"
  quietly replace __sumbet=0
  local i=1
  while "`1'" ~= "" {
    quietly replace __sumbet=__sumbet+_b[__beta`i']*`1'
    local i=`i'+1
    macro shift
  }
  
  if "$rc2" ~= "" {
    * update the sig scale
    local i=2
    while `i'<$rowcat {
      quietly replace __sig=_b[__msig`i']/_b[__msig$rowcat] if $rc2 == `i'
      local i=`i'+1
    }
    if "$muby" == "" {
      quietly replace __sumbet=__sumbet+_b[__msig$rowcat]*__sig
    }
    else {
      if $iter == 1 { quietly replace  __summu=_b[__msig$rowcat] }
      quietly replace __sumbet=__sumbet+__summu*__sig
    }
  }

  local i=2
  while `i'<=$ncat {
    quietly replace __phi`i'=__sumbet*($respfact==`i')
    local i=`i'+1
  }

  estimates hold __lft
end

program define rightest
  version 6
  if $iter > 1 { estimates drop __rgt }
  * given beta[k]X[k] (and if applicable, sigma[v]*(mu+mu[t]*X[t])), 
  * estimate phi[j]
  $debug clogit __didep $varlist $rgtlist $weight $if $in, strata(__strata) 
  
  local chng1=e(ll)-$prev
  global chng=e(ll)-$rgt
  global rgt =e(ll)
  global prev=e(ll)
  display $iter.2 _col(16) %15.4f e(ll) _col(36) %15.4f `chng1' _col(56) %15.4f $chng
  
  * update the phi variate
  local i=2
  while `i'<$ncat {
    quietly replace __phi=_b[__phi`i']/_b[__phi$ncat] if $respfact == `i'
    local i=`i'+1
  }

  tokenize "$sor"
  local i=1
  while "`1'" ~= "" {
    quietly replace __beta`i'=`1'*__phi
    local i=`i'+1
    macro shift
  }

  if "$muby" ~= "" {
    quietly replace __mu=__sig*__phi
    tokenize "$muby"
    local i=1
    while "`1'" ~= "" {
      quietly replace __muby`i'=`1'*__sig*__phi
      local i=`i'+1
      macro shift
    }
  }
  else if "$rc2" ~= "" {
    * redefine the __msig values
    local i=2
    while `i'<=$rowcat {
      quietly replace __msig`i'=__row`i'*__phi
      local i=`i'+1
    }
  }

  estimates hold __rgt
end

program define cenest
  version 6
  if $iter > 1 { estimates drop __cen }
  * given phi[j] and sigma[v], estimate mu and mu[t]
  $debug clogit __didep $varlist $cenlist $weight $if $in, strata(__strata)
  
  local chng1=e(ll)-$prev
  global chng=e(ll)-$cen
  global cen =e(ll)
  global prev=e(ll)
  display $iter.3 _col(16) %15.4f e(ll) _col(36) %15.4f `chng1' _col(56) %15.4f $chng
  
  quietly replace __summu=_b[__mu]
  tokenize "$muby"
  local i=1
  while "`1'" ~= "" {
    quietly replace __summu=__summu+`1'*_b[__muby`i']
    local i=`i'+1
    macro shift
  }

  * redefine the __msig values
  local i=2
  while `i'<=$rowcat {
    quietly replace __msig`i'=__row`i'*__phi*__summu
    local i=`i'+1
  }
  estimates hold __cen
end

program define eq1est
  version 6
  * treat phi=sig as given
  * estimate beta["k"], mu, and mu["t"]
  if $iter > 0 { estimates drop __lft }
  * estimate mu parameters
  $debug clogit __didep $varlist $lftlist $weight $if $in, strata(__strata)
  global iter=$iter+1
  
  local chng1=e(ll)-$prev
  global chng=e(ll)-$cen
  global cen =e(ll)
  global prev=e(ll)
  display $iter.1 _col(16) %15.4f e(ll) _col(36) %15.4f `chng1' _col(56) %15.4f $chng
  
  tokenize "$sor"
  local i=1
  quietly replace __sumbet=0
  while "`1'" ~= "" {
    quietly replace __sumbet=__sumbet+_b[__beta`i']*`1'
    local i=`i'+1
    macro shift
  }

  quietly replace __summu=_b[__mu]
  tokenize "$muby"
  local i=1
  while "`1'" ~= "" {
    quietly replace __summu=__summu+`1'*_b[__muby`i']
    local i=`i'+1
    macro shift
  }

  * redefine the __msig values
  local i=2
  #delimit ;
  while `i'<=$rowcat {
    quietly replace __msig`i'=__row`i'*__phi*__summu+
                              ($respfact==`i')*(__sig*__summu+__sumbet);
    local i=`i'+1;
  };
  #delimit cr
  estimates hold __lft
end

program define eq2est
  version 6
  * treat beta["k"], mu, and mu["t"] as given
  * estimate phi["j"]=sig["i"] 
  if $iter>1 { estimates drop __cen }
  * estimate sig["i"]=phi["i"]
  $debug clogit __didep $varlist $cenlist $weight $if $in, strata(__strata)

  local chng1=e(ll)-$prev
  global chng=e(ll)-$lft
  global lft= e(ll)
  global prev=e(ll)
  display $iter.2 _col(16) %15.4f e(ll) _col(36) %15.4f `chng1' _col(56) %15.4f $chng

  * update the phi and sig scales
  local i=2
  tempvar signew
  gen `signew'=__sig
  tempvar phinew
  gen `phinew'=__phi
  while `i'<$rowcat {
    quietly replace `signew'=_b[__msig`i']/_b[__msig$rowcat] if $eqrc2 == `i'
    quietly replace `phinew'=_b[__msig`i']/_b[__msig$rowcat] if $respfact == `i'
    local i=`i'+1
  }
  quietly replace __sig=(`signew'+__sig)/2
  quietly replace __phi=(`phinew'+__phi)/2

  tokenize "$sor"
  local i=1
  while "`1'" ~= "" {
    quietly replace __beta`i'=`1'*__phi
    local i=`i'+1
    macro shift
  }

  quietly replace __mu=__sig*__phi
  if "$muby" ~= "" {
    tokenize "$muby"
    local i=1
    while "`1'" ~= "" {
      quietly replace __muby`i'=`1'*__sig*__phi
      local i=`i'+1
      macro shift
    }
  }

  estimates hold __cen
end

program define normize
  version 6
  * `var'=variable to be normalized
  * `fact'=factor indexing unique values of `var'
  * `ncat'=number of categories of factor
  * `prefix'=optional prefix for displaying normalized values
  args var fact ncat prefix
  local sum=0
  local ss=0
  local i=1
  while `i' <= `ncat' {
    quietly summarize `var' if `fact' == `i'
    local var`i'=r(min)
    local sum=`sum'+r(min)
    local ss=`ss'+r(min)^2
    local i=`i'+1
  }
  quietly replace `var'=(`var'-`sum'/`ncat')/sqrt(`ss'-`sum'^2/`ncat')

  if "`var'" == "__phi" {
    local labvar="$respfact"
  }
  else if "`var'" == "__sig" {
    local labvar="$rc2"
  }

  if "`prefix'" ~= "" {
    prhdsc
    local i=1
    while `i' <= `ncat' {
      local var`i'=(`var`i''-`sum'/`ncat')/sqrt(`ss'-`sum'^2/`ncat')
      capture local vallab: label (`labvar') `i'
      local vallab=substr("`vallab'",1,28)
      display "`prefix'(`i'): `vallab'" _col(38) "|" _col(42) %8.4f `var`i''
      local i=`i'+1
    }
    display _dup(49) "-"
  }
end

program define prhdsc
  version 6
  display _newline _dup(49) "-"
  display _col(38) "|" _col(45) "Coef."
  display _dup(37) "-" "+" _dup(11) "-"
end

program define prsc
  version 6
  * `efnm'=effect name
  * `var'=variable
  * `ncat'=number of categories
  args efnm var ncat

  if "`efnm'" == "phi" {
    local labvar="$respfact"
  }
  else if "`efnm'" == "sig" {
    local labvar="$rc2"
  }
  
  capture local vallab: label (`labvar') 1
  local vallab=substr("`vallab'",1,28)
  display "`efnm'(1): `vallab'" _col(38) "|" _col(42) %8.0f 0
  local i=2
  while `i'<`ncat' {
    capture local vallab: label (`labvar') `i'
    local vallab=substr("`vallab'",1,28)
    display "`efnm'(`i'): `vallab'" _col(38) "|" _col(42) %8.4f /*
*/    _b[`var'`i']/_b[`var'`ncat']
    local i=`i'+1
  }
  capture local vallab: label (`labvar') `ncat'
  local vallab=substr("`vallab'",1,28)
  display "`efnm'(`ncat'): `vallab'" _col(38) "|" _col(42) %8.0f 1
  display _dup(49) "-" _newline
end

program define prhd
  version 6
  display _newline _dup(79) "-"
  display _col(38) "|" _col(45) "Coef." _col(53) "Std. Err." /*
*/  _col(69) "z" _col(75) "P>|z|"
  display _dup(37) "-" "+" _dup(41) "-"
end

program define prsnt
  version 6
  * `efnm' is the effect name
  * `var' is the variable name
  args efnm var
  local thislab: variable label `var'
  local thislab=substr("`thislab'",1,36)
  local z=_b[`var']/_se[`var']
  local prob=2*(1-normprob(abs(`z')))
  display "`thislab'" _col(38) "|" _col(42) %8.4f _b[`var'] /*
*/  _col(53) %8.4f _se[`var'] _col(64) %8.4f `z' _col(72) %8.4f `prob'
end
