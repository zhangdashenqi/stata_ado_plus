program ml_mediation, rclass
*! version .9 -- pbe -- 10/4/11
  version 11.0
  syntax, dv(varname max=1) iv(varname max=1) mv(varname max=1) ///
          l2id(varname max=1) [ cv(varlist fv) mle ]
          
   local meth "reml"
   if "`mle'"~="" {
     local meth "mle"
   }
          
  /* is the mv level 2 ? */
  tempvar mvsd
  egen `mvsd'=sd(`mv'), by(`l2id')
  quietly sum `mvsd'
  local mvl "1"
  if r(max)==0 & r(min)==0 {
    local mvl "2"
  }
  
  display
  display as res "Equation 1 (c_path): `dv' = `iv' `cv'"
  xtmixed `dv' `iv' `cv' || `l2id':, `meth'
  local c_path = _b[`iv']
  
  display
  display as res "Equation 2 (a_path): `mv' = `iv' `cv'"  
  
  if "`mvl'"=="1" {
    xtmixed `mv' `iv' `cv' || `l2id':, `meth'
  }
  if "`mvl'"=="2" {
    xtreg `mv' `iv' `cv', i(`l2id') be
  }
  local a_path = _b[`iv']
  display
  display as res "Equation 3 (b_path & c_prime): `dv' = `mv' `iv' `cv'"
  xtmixed `dv' `mv' `iv' `cv' || `l2id':
  local b_path = _b[`mv']
  local c_prime = _b[`iv']
  local ind_eff = `a_path'*`b_path'
  local tot_eff = `ind_eff' + `c_prime'
  
  display
  display as txt "The mediator, " as res "`mv'" as txt ", is a level `mvl' variable"
  display as txt "c_path  = " as res `c_path'
  display as txt "a_path  = " as res `a_path'
  display as txt "b_path  = " as res `b_path'
  display as txt "c_prime = " as res `c_prime' as txt "  same as dir_eff" 
  display as txt "ind_eff = " as res `ind_eff'
  display as txt "dir_eff = " as res `c_prime'
  display as txt "tot_eff = " as res `tot_eff'
  display
  local ind2tot = `ind_eff'/`tot_eff'
  local ind2dir = `ind_eff'/`c_prime'
  local tot2dir = `tot_eff'/`c_prime'
  display as txt "proportion of total effect mediated = " as res `ind2tot'
  display as txt "ratio of indirect to direct effect  = " as res `ind2dir'
  display as txt "ratio of total to direct effect     = " as res `tot2dir'
  
  return scalar c_path  = `c_path'
  return scalar a_path  = `a_path'
  return scalar b_path  = `b_path' 
  return scalar ind_eff = `a_path'*`b_path'
  return scalar dir_eff = `c_prime'
  return scalar tot_eff = `tot_eff'
end

/* 
panel_mediation, dv(math) iv(mhmwk) mv(hmwk) cv(white) l2id(scid) 

bootstrap indeff=r(ind_eff) direff=r(dir_eff), ///
  cluster(scid) idcluster(newvar) rep(100): ///
  panel_mediation, dv(math) iv(mhmwk) mv(hmwk)  cv(white) l2id(scid)

drop newvar

estat boot, percent bc
*/
