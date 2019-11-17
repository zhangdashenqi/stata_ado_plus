program mwtest, rclass 
  version 9.2
  syntax varname(numeric) [if] [in], by(varname) [reps(integer 10000)] [simsec(integer 1000)] [exact] 
  
  tempvar rank
  
  marksample touse
 
  local group="`by'"
  preserve
  
 quietly {
    keep if `touse'
    // sanity checks
    count if `touse'
    if r(N) == 0 error 2000
    local n = r(N)
    tempvar g
    
    bysort `touse' `group' : gen `g' = (_n == 1) * `touse'
    replace `g' = sum(`g')
    local ng = `g'[_N]
    
    if `ng' == 1 {
       di as err "1 group found, 2 required"
       exit 499
    }
    else if `ng' > 2 {
      di as err "`ng' groups found, 2 required"
      exit 499
  }
  
    
    // group sizes 
    count if `g' == 1 & `touse'
    local n1 = r(N)
    count if `g' == 2  & `touse'
    local n2 = r(N)

    // group ids
    local group1 = `group'[_N - `n2']
    local group2 = `group'[_N]
    local orig_group1="`group1'"
    local orig_group2="`group2'"
    
 }
  
  egen `rank'=rank(`varlist') 
  
  // convert string grouping variable to numerical one

  capture confirm numeric variable `by'
  if _rc!=0 {
    tempvar newgroup
    
    quietly {
    
      gen `newgroup'=1 if `by' == "`group1'"
      replace `newgroup'=2 if `by'=="`group2'"
      local group1=1
      local group2=2
      local group="`newgroup'"
    }
  }
      // // smaller group
    local smaller_group = `group1'
    local greater_group = `group2'
    if `n2'<`n1' {
      local smaller_group = `group2'
      local greater_group = `group1'    
    }

  di as gr "Exact two-sample Wilcoxon ranksum (Mann-Whitney) test" _n
  
  tsrtest `group' r(diff) , quiet  reps(`reps') `exact' simsec(`simsec'): ranksamplediff `rank' `group' `smaller_group' `greater_group' 

  local ec=r(combinations)
  if `ec'==. {
    exit 20
  }
  local ex_p_twotail=r(twotail)
  local ex_p_onetail=min(r(uppertail),r(lowertail))
  local simul = r(simulated)
  capture ranksum `rank' , by(`group')
  local z=r(z)
  local asym_p_twotail=2*normprob(-abs(`z'))
  local asym_p_onetail=`asym_p_twotail'/2
  
  di _n in gr "Test of Ho: `varlist'(`by'==`orig_group1') = `varlist'(`by'==`orig_group2')" _n
  di in gr "Asymptotic z-statistic = " in ye %5.3f `z' _n
  di in gr "Asymp. two-sided p = " in ye %7.5f `asym_p_twotail'
  di in gr "Exact  two-sided p = " in ye %7.5f `ex_p_twotail'
  di in gr "Asymp. one-sided p = " in ye %7.5f `asym_p_onetail'
  di in gr "Exact  one-sided p = " in ye %7.5f `ex_p_onetail'
  
  if "`simul'"=="1" {
    di in gr _n "Note: exact p-levels have been approximated by Monte Carlo simulations."
  }
  
  return scalar z = `z'
  return scalar simulated = `simul'
  return scalar ex_p_twotail = `ex_p_twotail'
  return scalar ex_p_onetail = `ex_p_onetail'
  return scalar asym_p_twotail = `asym_p_twotail'
  return scalar asym_p_onetail = `asym_p_onetail'
end
