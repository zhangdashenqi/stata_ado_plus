*! version 2.4 -- 10/14/11 -- pbe -- add ratio total to direct
*! version 2.3 -- 10/5/11  -- pbe -- factor var, need stata 11
*! version 2.2.1 -7/5/11   -- pbe -- return c_path
*! version 2.1 -- 2/16/11  -- pbe -- return matrices
*! version 2.0 -- 5/07/10  -- pbe -- multiple mediators
*! version 1.1 -- 4/29/10  -- pbe -- probit
program binary_mediation, rclass
version 11.0  
  /* continuous/binary dv and/or mv                                     
    quietly bootstrap r(tot_ind) r(dir_eff) r(tot_eff), rep(200): ///  
      binary_mediation, dv(honors) iv(ses) mv(read)                      
    estat bootstrap, percentile bc                                    
  */
  syntax [if] [in], dv(varname) mv(varlist) iv(varname) ///
     [ cv(varlist fv) probit quietly diagram ]
  marksample touse
  markout `touse' `dv' `mv' `iv' `cv'
  tempname a b ab bin sdm mu vx 

  if "`probit'"=="" {
    local typebin "logit"
    local scale = (_pi*_pi)/3
  }
  else {
    local typebin "probit"
    local scale = 1
  }
  
  local anybin=0
  local nmv : word count `mv'
  matrix   `a'=J(`nmv',1,0)
  matrix   `b'=J(`nmv',1,0)
  matrix  `ab'=J(`nmv',1,0)
  matrix `bin'=J(`nmv',1,1)
  matrix `sdm'=J(`nmv',1,0)
  matrix  `mu'=J(`nmv',1,0)
  
  capture assert `dv'==0 | `dv'==1 | missing(`dv')
  local bindv=_rc
  quietly sum `iv' if `touse'
  local sdx=r(sd)
  quietly sum `dv' if `touse'
  local sdy=r(sd)
  quietly corr `mv' `iv' if `touse', cov
  matrix cov = r(C)
  
  /* a paths */
  local kount=0
  foreach mvname of varlist `mv' {
    local kount=`kount'+1
    capture assert `mvname'==0 | `mvname'==1 | missing(`mvname')
    mat `bin'[`kount',1]=_rc==0
    quietly sum `mvname' if `touse'
    matrix `sdm'[`kount',1]=r(sd)
    matrix  `mu'[`kount',1]=r(mean)
    if `bin'[`kount',1]==0 {
      `quietly' display as txt "OLS regression: `mvname' on iv (a`kount' path) "
      `quietly' regress `mvname' `iv' `cv' if `touse', beta noheader
      matrix `a'[`kount',1] = _b[`iv']*`sdx'/`sdm'[`kount',1]
    }
    else if "`typebin'"=="logit" {
      `quietly' display as txt "Logit: `mvname' on iv (a`kount' path) "
      `quietly' logit `mvname' `iv' `cv' if `touse', nolog
      local sdmp=sqrt(_b[`iv']^2*`sdx'^2 + `scale')
      matrix `a'[`kount',1] = _b[`iv']*`sdx'/`sdmp'
    }
    else if "`typebin'"=="probit" {
      `quietly' display as txt "Probit: `mvname' on iv (a`kount' path) "
      `quietly' probit `mvname' `iv' `cv' if `touse', nolog
      local sdmp=sqrt(_b[`iv']^2*`sdx'^2 + `scale')
      matrix `a'[`kount',1] = _b[`iv']*`sdx'/`sdmp'
    }
  }

  /* c path */
  if `bindv'!=0 {
      `quietly' display as txt "OLS regression: dv on iv (c path)"
      `quietly' regress `dv' `iv' `cv' if `touse', nohead 
      local c=_b[`iv']*`sdx'/`sdy'
      local dvtype "continuous"
  }
  else if "`typebin'"=="logit" {
    `quietly' display as txt "Logit: dv on iv (c path)"
    `quietly' logit `dv' `iv' `cv' if `touse', nolog
  }
  else if "`typebin'"=="probit" {
    `quietly' display as txt "Probit: dv on iv (c path)"
    `quietly' probit `dv' `iv' `cv' if `touse', nolog
  }
  if `bindv'==0 {
    local c=_b[`iv']
    local sdyp=sqrt(`c'^2*`sdx'^2 + `scale')
    local c= `c'*`sdx'/`sdyp'
    local dvtype "binary"
    local anybin=1
  }

  /* b & c' paths */
  if `bindv'!=0 {
    `quietly' display as txt "OLS regression: dv on mv & iv (b & c' paths)"
    `quietly' regress `dv' `mv' `iv' `cv' if `touse', nohead 
    local cp=_b[`iv']*`sdx'/`sdy'
    local totind=0
    local kount=0
    foreach mvname of varlist `mv' {
      local kount=`kount'+1
      matrix `b'[`kount',1] = _b[`mvname']*`sdm'[`kount',1]/`sdy'
      matrix `ab'[`kount',1]=`a'[`kount',1]*`b'[`kount',1]
      local totind=`totind'+`a'[`kount',1]*`b'[`kount',1]
    }
  }
  else if "`typebin'"=="logit" {
    `quietly' display as txt "Logit: dv on mv & iv (b & c' paths)"
    `quietly' logit `dv' `mv' `iv' `cv' if `touse', nolog
  }
  else if "`typebin'"=="probit" {
    `quietly' display as txt "Probit: dv on mv & iv (b * c' paths)"
    `quietly' probit `dv' `mv' `iv' `cv' if `touse', nolog
  }
  
  if `bindv'==0 {
    matrix c=e(b)
    matrix c=c[1,1..`nmv'+1]
    matrix `vx'=c*cov*c'
    local sdyp=sqrt(el(`vx',1,1) + `scale')    
    local cp=_b[`iv']
    local cp= `cp'*`sdx'/`sdyp'
    local totind=0
    local kount=0
    foreach mvname of varlist `mv' {
      local kount=`kount'+1
      matrix `b'[`kount',1] = _b[`mvname']*`sdm'[`kount',1]/`sdyp'
      matrix `ab'[`kount',1]=`a'[`kount',1]*`b'[`kount',1]
      local totind=`totind'+`a'[`kount',1]*`b'[`kount',1]
    }
  }

  display
  display as txt "Indirect effects with `dvtype' response variable " as res "`dv'"
  forvalues i=1/`nmv' {
    if `bin'[`i',1]==1 {
      local vtype "binary"
      local anybin=1
    }
    else {
      local vtype "continuous"
    }
    display as txt "        indir_`i' = " as res `ab'[`i',1] _col(36) as txt "(" word("`mv'",`i') ", `vtype')"
    return scalar indir_`i' = `ab'[`i',1]
  }
  display as txt "total indirect  = " as res `totind'
  return scalar tot_ind = `totind'
  display as txt " direct effect  = " as res `cp'
  local toteff=`totind'+`cp'
  return scalar dir_eff = `cp'
  display as txt "  total effect  = " as res `toteff'
  return scalar tot_eff = `toteff'
  display as txt "       c_path   = " as res `c'
  return scalar c_path=`c'
  local ind2tot=`totind'/`toteff'
  local ind2dir=`totind'/`cp'
  local tot2dir=`toteff'/`cp'
  display as txt "proportion of total effect mediated = " as res `ind2tot'
  display as txt "ratio of indirect to direct effect  = " as res `ind2dir'
  display as txt "ratio of total to direct effect     = " as res `tot2dir'
  if `anybin'==1 {
  display as text "Binary models use `typebin' regression"
  }
  
  /* return matrices */
    return matrix mat_a=`a'
    return matrix mat_b=`b'
  
  if "`diagram'"=="diagram" {
  display
  display as txt "Reference Mediation Diagram"
  display
  display as res "  IV ---  coef c  --- DV"
  display
  display as res "           MV1"
  display as res "         /     \"
  display as res "   coef a1     coef b1"
  display as res "     /             \"
  display as res "  IV --- coef c' --- DV"
  display as res "    \               /"
  display as res "   coef a2     coef b2"
  display as res "        \       /"
  display as res "           MV2"
  }

capture matrix drop cov c

end
