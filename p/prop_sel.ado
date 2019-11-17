program define prop_sel, rclass

  *! $Revision: 1.8 $
  *! Author:  Mark Lunt
  *! Date:    March 20, 2012 @ 15:38:17
  
  version 11
  
    syntax varlist [if] [in] [,STandard(real -1) RELative(real -1)      ///
        bias(real -1) Beta(namelist min=1 max=1) Propensity(name)       ///
        Weightvar(name) XIPrefix(namelist min=1 max=1) trace(integer 0) ///
        MAXTerms(integer -1 ) eform INITmodel(string) graph             ///
        MAXK(integer 8)]
  

    foreach num of numlist 1/4 {
      if `trace' >= `num' {
        local trace`num' noisily
      }
      else {
        local trace`num' quietly
      }
    }
  
    tokenize `varlist'
    local treat `1'
    macro shift
    local allvars  `*'
    local testvars `allvars'
    unab contvars : `allvars'
    local contvars : list uniq contvars
    local p : word count `contvars'
  
    // Check that the treatment variable was valid, bail if it wasn't
    capture tab `treat' if `treat'
    if _rc == 0 {
      local levels = r(r)
      if `levels' > 2 {
        di as error "The first variable in the varlist must be a dichotomous exposure variable"
        exit  
      }
    }
    else {
        di as error "The first variable in the varlist must be a dichotomous exposure variable"
        exit  
    }
  
    if "`xiprefix'" == "" {
      local xiprefix _I
    }
    local xiplen = length("`xiprefix'")
  
    foreach var of varlist `contvars' {
      if substr("`var'",1,`xiplen') == ("`xiprefix'") {
        local indicvars `indicvars' `var'
        local croot : subinstr local var "`xiprefix'" ""
        local croot = regexr("`croot'", "_[0-9]+$", "")
        local croots `croots' `croot'
      }
      else {
        local IV_`var' c.`var'
      }
    }
  
    local croots : list uniq croots
    if "`indicvars'" ~= "" {
      foreach var of varlist `indicvars' {
        local contvars : subinstr local contvars "`var'" "", word
      }
  
      foreach r in `croots' {
        local cfvars `cfvars' i.`r'
        local IV_`r' i.`r'
      }
      xi `cfvars', prefix(_C) noomit
      unab indicvars : _C*
      
      foreach var in `allvars' {
        if substr("`var'", 1, `xiplen') == "`xiprefix'" {
          local nvar = substr("`var'", `xiplen'+1, .)
          local var _C`nvar'
        }
        local tvars `tvars' `var'
      }
      local allvars `tvars'
    }
  
    if "`initmodel'" != "" {
      local im
      foreach term in `initmodel' {
        if substr("`term'",1,`xiplen') == ("`xiprefix'") {
          local term : subinstr local term "`xiprefix'" ""
          local term = regexr("`term'", "_[0-9\*]+$", "")
          local term i.`term'
        }
        foreach var of varlist `contvars' `croots' {
          if strpos("`term'", "`var'") > 0 {
            local IV_`var' `IV_`var'' `term'
          }
        }
        local im `im' `term'
      }
    }
  
    tempname imbalances b covaru covart covar sdm
    if "`relative'" != "" {
      tempname init_imb rel_imb
    }
  
    if "`beta'" == "" & `relative' == -1 {
      if `standard'== -1 {
        local standard = 0.1
      }
      local relative
      local threshold `standard'
    }
    else if `relative' != -1 {
      local standard 
      local threshold `relative'
    }
    local check_val el(`imbalances', 1, 1)
  
    else if "`beta'" != "" {
      local standard 
      local relative
      capture confirm matrix `beta'
      if _rc != 0 {
        noi di as error "Unable to find matrix `beta'"
        exit
      }
      local bnames : colnames `beta'
      local bnnames
      foreach var in `bnames' {
        if regexm("`var'", "^`xiprefix'") {
          local var = regexr("`var'", "^`xiprefix'", "_C")
        }
        local bnnames `bnnames' `var'
      }
      matrix colnames `beta' = `bnnames'
      if `bias' == -1 {
        local bias 0.05
      }
      if "`eform'" != "" {
        local bias = ln(1+`bias')
      }
      local threshold `bias'
      local check_val el(`imbalances', 1, 1)
    }
  
    if `maxterms' == -1 {
      local maxterms = `p'^2
    }
  

  marksample touse

    quietly {
      local propstr `contvars' `cfvars' `im'
      tempvar iptw prop
      logit `treat' `propstr' if `touse'
      predict `prop' if `touse'
      gen `iptw' = 1/`prop' if `touse'
      replace `iptw' = 1/(1-`prop') if `treat' == 0 & `touse'
      matrix `imbalances' = J(1, `p', 0)
      matrix colnames `imbalances' = `allvars'
      covwt `allvars' if `touse' & `treat' == 1
      matrix `covart' = r(covar)
      covwt `allvars' if `touse' & `treat' == 0
      matrix `covaru' = r(covar)
      matrix `covar' = (`covart' + `covaru') / 2
      matrix `sdm'   = vecdiag(`covar')
      foreach n of numlist 1/`p'{
        matrix `sdm'[1, `n'] = sqrt(el("`sdm'", 1, `n'))
      }
      if "`relative'" != "" {
        matrix `init_imb' = `imbalances'
        matrix `rel_imb'  = `imbalances'
      }
      
      foreach var of varlist `allvars' {
        qui regress `var' `treat' [pw=`iptw'] if `touse'
        matrix `b' = e(b)
        matrix `imbalances'[1, colnumb(`imbalances', "`var'")] = `b'[1, 1]
        local cn = colnumb("`sdm'", "`var'")
        local sd = el("`sdm'", 1, `cn')
        `trace4' di "Imbalance in `var' is " el(`b', 1, 1) " with an SD of " `sd' _cont
        `trace4' di "Giving a standardised difference of " el(`b', 1, 1)/`sd'
        matrix `imbalances'[1, colnumb(`imbalances', "`var'")] =  ///
            abs(`imbalances'[1, colnumb(`imbalances', "`var'")] / `sd')
        
        if "`relative'" != "" {
          qui regress `var' `treat' if `touse'
          matrix `b' = e(b)
          matrix `init_imb'[1, colnumb(`init_imb', "`var'")] = `b'[1, 1]
          matrix `rel_imb'[1, colnumb(`rel_imb', "`var'")]  =  1
        }
        else if "`beta'" != "" {
          local cn = colnumb("`beta'", "`var'")
          local coef = el("`beta'", 1, `cn')
          matrix `imbalances'[1, colnumb(`imbalances', "`var'")] =  ///
              abs(`imbalances'[1, colnumb(`imbalances', "`var'")]  ///
  * `coef')
        }
      }
      sort_vector `imbalances'
      matrix `imbalances' = r(sorted)
      local sorted_names : colnames `imbalances'
      `trace1' matrix list `imbalances'
    }
  
  


  local k 1
  local best_improvement
  quietly {
    local cv = `check_val'
    while ((`cv' > `threshold') & (`k' <= `maxterms')) {
      `trace1' di as text "Biggest difference is " as result `cv'   ///
               as text " which is bigger than " as result `threshold'
      `trace1' di as text "k is " as result `k' as text ", which is less than "  ///
               as result `maxterms'
        local best_term
        local best_improvement 0
        local imb_1 = `imbalances'[1, 1]
        local imb_2 = `imbalances'[1, 2]
        `trace1' di as text "Iteration " as result `k'
        local tested_terms
        

      foreach i of numlist 1 {
        foreach j of numlist `i'/`p' {
              local var_1 : word `i' of `sorted_names'
              if regexm("`var_1'", "^_C") {
                local vari_1 = regexr("`var_1'", "^_C", "")
                local vari_1 = regexr("`vari_1'", "_[0-9]*$", "")
                unab vari_1 : `vari_1'
                local type_1 i
              }
              else {
                local type_1 c
                local vari_1 `var_1'
              }
            
              local var_2 : word `j' of `sorted_names'
              if regexm("`var_2'", "^_C") {
                local vari_2 = regexr("`var_2'", "^_C", "")
                local vari_2 = regexr("`vari_2'", "_[0-9]*$", "")
                unab vari_2 : `vari_2'
                local type_2 i
              }
              else {
                local type_2 c
                local vari_2 `var_2'
              }
            

            `trace4' di "|`var_1'||`var_2'||`vari_1'"
            `trace4' di "`IV_`vari_1''"
            local improvement = 0
          
            foreach var_3 in `IV_`vari_1'' {
              local var_4 `type_2'.`var_2'
                if ("`type_2'" == "c") | (strpos("`var_3'", "`type_2'.`vari_2'") == 0) {
                  local next_term `var_3'#`type_2'.`vari_2'
                  local next_term : subinstr local next_term "#" " ", all count(local test)
                  // fencepost error: max 8 terms in interaction means max 7 #'s
                  
                  if `test' < 8 {
                    local next_term : list sort next_term
                    local next_term : subinstr local next_term " " "#", all
                    local test : list next_term in propstr
                    
                    if `test' == 0 {
                      `trace3' di as result "`next_term'" as text " is not in propstr"
                      local test : list next_term in tested_terms
                      if `test' == 0 {
                        local tested_terms `tested_terms' `next_term'
                        drop `iptw' `prop'
                        qui logit `treat' `propstr' `next_term' if `touse'
                        predict `prop' if `touse'
                        gen `iptw' = 1/`prop' if `touse'
                        replace `iptw' = 1/(1-`prop') if `treat' == 0 & `touse'
                          regress `var_1' `treat' [pw=`iptw'] if `touse'
                          matrix `b' = e(b)
                          local new_imb = el("`b'", 1, 1)
                          if "`standard'" != "" {
                            local cn = colnumb("`sdm'", "`var_1'")
                            local sd = el("`sdm'", 1, `cn')
                            local new_imb = abs(`new_imb'/`sd')
                          }
                          else if "`beta'" != "" {
                            local new_imb = abs(`new_imb'*`beta'[1, colnumb(`beta', "`var_1'")])
                          }
                          else {
                            local cn = colnumb("`sdm'", "`var_1'")
                            local sd = el("`sdm'", 1, `cn')
                            `trace4' di `"local cn = colnumb(`init_imb', "`var_1'")"'
                            local cn = colnumb(`init_imb', "`var_1'")
                            `trace4' di "local new_imb = abs(`new_imb'/el(`init_imb', 1, `cn'))"
                            local new_imb = abs(`new_imb'/(el(`init_imb', 1, `cn')*`sd'))
                          }
                          local improvement = (`imb_1' - `new_imb')
                          
                          `trace2' di as text "New imbalance in " as result "`var_`i''"     ///
                                   as text " = " as result `new_imb'
                          `trace2' di as text "Improvement with " as result "`next_term'"   ///
                                   as text " = " as result `improvement'
                          if `improvement' > `best_improvement' {
                            `trace2' di as text "Improvement better than " as result `best_improvement'  ///
                                as text ": new best term"
                            local best_term `next_term'
                            local best_improvement = `improvement'
                            local best_vars `vari_1' `vari_2'
                            // change the below to lists an only allow uniq terms
                          }
                        

                      }
                      else {
                        `trace3' di as result "`next_term'" as text " was already in tested_terms"
                      }
                    }
                    else {
                      `trace3' di as result "`next_term'" as text " was already in propstr"
                    }
                  }
                }
                else {
                `trace3' di as text "Categorical variable " as result "`vari_2'"  ///
                            as text " is already in the term " as result "`var_3'"
                }
              
               

            }
          

        }
      }
      if `best_improvement' == 0 {
        local cv = -1
      }
      else {
          local last_var
          local order 0
          local termlist : subinstr local best_term "#" " ", all
          local count : word count `termlist'
          local iter 0
          while `iter' < `count' {
            local iter = `iter' + 1
            local curr_var : word `iter' of `termlist'
            if ("`curr_var'" == "`last_var'") {
              local order = `order' + 1
            }
            else {
              local order = 1
              local last_var `curr_var'
            }
            if `order' > `maxk' {
              local last_var : subinstr local last_var "c." ""
              noi di
              noi di as error "The algorithm would now add " as result "`best_term'"
              noi di as error "but this contains the variable " as result "`last_var'" _cont
              noi di as error " to the power " as result `order' as error ","
              noi di as error "which is greater than the limit of " as result `maxk' as error "."
              noi di
              noi di as error "This may be due to a lack of overlap in " as result "`last_var'" _cont
              noi di as error "."
              noi di as error "Graphing density of `last_var' in exposed and unexposed to check."
              graph tw kdensity `last_var' if `treat' == 0 || kdensity `last_var' if `treat' == 1, ///
                       legend(label(1 "`treat' == 0") label(2 "`treat' == 1"))
              exit
            }
          }
        

          drop `iptw' `prop'
          local propstr `propstr' `best_term'
          noi di as text "Term " as result `k' as text ": " as result "`best_term'"
          
          foreach var of varlist `best_vars' {
            local IV_`var' `IV_`var'' `best_term'
          }
        
          qui logit `treat' `propstr' if `touse'
          predict `prop'  if `touse'
          gen `iptw' = 1/`prop' if `touse'
          replace `iptw' = 1/(1-`prop') if `treat' == 0 & `touse'
          foreach var of varlist `allvars' {
            qui regress `var' `treat' [pw=`iptw'] if `touse'
            matrix `b' = e(b)
            matrix `imbalances'[1, colnumb(`imbalances', "`var'")] = `b'[1, 1]
            local cn = colnumb("`sdm'", "`var'")
            local sd = el("`sdm'", 1, `cn')
            matrix `imbalances'[1, colnumb(`imbalances', "`var'")] =  ///
                abs(`imbalances'[1, colnumb(`imbalances', "`var'")] / `sd')
            if "`relative'" != "" {
              `trace4' matrix list `imbalances'
              matrix `imbalances'[1, colnumb(`imbalances', "`var'")]  =   ///
                  abs(`imbalances'[1, colnumb(`imbalances', "`var'")] /  ///
                  `init_imb'[1, colnumb(`init_imb', "`var'")])           
            }
            else if "`beta'" != "" {
              local cn = colnumb("`beta'", "`var'")
              local coef = el("`beta'", 1, `cn')
              matrix `imbalances'[1, colnumb(`imbalances', "`var'")] =  ///
                     abs(`imbalances'[1, colnumb(`imbalances', "`var'")] * `coef' * `sd')
            }
          }
          sort_vector `imbalances'
          matrix `imbalances' = r(sorted)
          local sorted_names : colnames `imbalances'
          `trace1' matrix list `imbalances'
          
        

        local k = `k' + 1
        local cv = `check_val'
      }
    }
  }
    if "`propensity'" != "" {
      generate `propensity' = `prop'
    }
    if "`weightvar'" != "" {
      generate `weightvar' = `iptw'
    }
  

  
  if `cv' == -1 {
    di as error "It was not possible to find an adequate propensity score"
  }
  di as text _n "The propensity score contains the following variables: "
  di as result "`propstr'" _n
    xi `cfvars', prefix(`xiprefix') noomit
  
  if "`beta'" != "" {
    local pb beta(`beta') `eform'
  }
  
  di as text "Initial balance: " _n
  pbalchk `treat' `testvars' if `touse', `pb'
  
  di as text "Final balance: " _n
  pbalchk `treat' `testvars' if `touse', wt(`iptw') `pb' `graph'
  

    local ret
    foreach term in `propstr' {
      local t `term'
      if strpos("`term'", ".") == 0 {
        local t c.`term'
      }
      local ret : list ret | t
    }
    `trace4' di "`ret'"
    qui return local propstr `ret'
  

end

