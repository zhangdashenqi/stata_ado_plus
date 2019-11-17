program somersdtest, rclass 
  version 9.2
  syntax varname [if] [in], by(varname) [reps(integer 10000)] [simsec(integer 1000)] [exact] 
  marksample touse
  local group="`by'"
  preserve 
  quietly {
    keep if  `touse' 
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

  di as gr "Randomization test for significance of Somers' D" _n
  tempvar rank
  egen `rank'=rank(`varlist') 
  quietly {
    somd `rank' `group' `group1' `group2' 
    local somersd=r(d)
  }
  di in gr "Somers' D=" in ye %6.4f `somersd' _n
  
  tsrtest `group' r(d), quiet : somd `rank' `group' `group1' `group2' 

  local ec=r(combinations)
  if `ec'==. {
    exit 20
  }
  local p_twotail=r(twotail)
  local p_uppertail=r(uppertail)
  local p_lowertail=r(lowertail)
  di 
  di in gr "Exact  two-tailed p = " in ye %7.5f `p_twotail'
  di in gr "Exact  lower-tail p = " in ye %7.5f `p_lowertail'
  di in gr "Exact  upper-tail p = " in ye %7.5f `p_uppertail'
  
  return scalar somersd = `somersd'
  return scalar twotail = `p_twotail'
  return scalar uppertail = `p_uppertail'
  return scalar lowertail = `p_lowertail'
  return scalar simulated = r(simulated)
end

