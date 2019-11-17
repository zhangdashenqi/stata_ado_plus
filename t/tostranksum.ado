*! version 1.5.1 02mar2014 by alexis dot dinno at pdx dot edu
*! perform two one-sided tests for stochastic equivalence in unpaired data

* Syntax:  tostranksum varname [if exp] [in range] , by(varname) [porder 
*          eqvtype(type) eqvlevel(#) uppereqvlevel(#) ccontinuity level(#) ]

program define tostranksum

  if int(_caller())<8 {
    di in r "tostranksum- does not support this version of Stata." _newlineewline
    di as txt "Requests for a version compatible with versions of STATA earlier than v8 are "
    di as txt "untenable since I do not have access to the software." _newlineewline 
    exit
  }
   else tostranksum8 `0'
end

program define tostranksum8, rclass byable(recall)
  version 8, missing
  syntax varname [if] [in], BY(varname) [ porder EQVType(string) /*
*/       EQVLevel(real 1) UPPEReqvlevel(real 0) CContinuity level(cilevel) ]
* Validate eqvtype
  if lower("`eqvtype'") == "" {
    local eqvtype = "epsilon"
    }

  if !(lower("`eqvtype'") == "delta" | lower("`eqvtype'") == "epsilon") {
    noisily: di as err "option eqvtype() must be either delta or epsilon"
    exit 198
    }

* Validate eqvlevel
  if (lower("`eqvtype'") == "delta") & (`eqvlevel' == 1 & `uppereqvlevel'==0) {
    local eqvlevel = 1
    }

  if (lower("`eqvtype'") == "epsilon") & (`eqvlevel' == 1 & `uppereqvlevel'==0) {
    local eqvlevel = 2
    }

  if (lower("`eqvtype'") == "delta" || lower("`eqvtype'") == "epsilon") & (`eqvlevel' <= 0 & `uppereqvlevel' != abs(`eqvlevel')) {
    noisily: di as err "option eqvlevel() incorrectly specified" _newline "the tolerance must be a positive real value"
    exit 198
    }

* Validate uppereqvlevel
  if (`uppereqvlevel'<0) {
    noisily: di as err "option uppereqvlevel() must be a positive real value"
    exit 198
    }
 
  if (`uppereqvlevel'==0 | `uppereqvlevel' == abs(`eqvlevel')) {
    local upper = abs(`eqvlevel')
    local lower = abs(`eqvlevel')
    }

  if (`uppereqvlevel'>0) {
    local upper = abs(`uppereqvlevel')
    local lower = abs(`eqvlevel')
    }


  local origby "`by'"
  capture confirm numeric variable `by'
  if _rc {
    tempvar numby
    encode `by', generate(`numby')
    local by "`numby'"
  }
  marksample touse
  markout `touse' `by'

  local x "`varlist'"
  tempname g1 g2 W v unv z
  tempvar ranks
  quietly {
    summarize `by' if `touse', meanonly
    if r(N) == 0 {
      noisily error 2000 
      }
    if r(min) == r(max) {
      di in red "1 group found, 2 required"
      exit 499
    }
    scalar `g1' = r(min)    
    scalar `g2' = r(max)

    count if `by'!=`g1' & `by'!=`g2' & `touse'
    if r(N) != 0 {
      di in red "more than 2 groups found, only 2 allowed"
      exit 499
    }

    egen double `ranks' = rank(`x') if `touse'

    summarize `ranks' if `by'==`g1' & `touse', meanonly
    local   n1   = r(N)
    scalar `W'  = r(sum)

    summarize `ranks' if `touse'
    local   n    = r(N)
    local   n2   = `n' - `n1'
    scalar `v'   = `n1'*`n2'*r(Var)/`n'
    scalar `unv' = `n1'*`n2'*(`n'+1)/12
    local se = sqrt(`v')
    local EW = `n1'*(`n'+1)/2
    if (lower("`ccontinuity'") == "") {
      local cc = 0
      }
    if (lower("`ccontinuity'") != "") {
      local cc = 0.5
      }
    if lower("`eqvtype'") == "delta" {
        local z1 = (`upper' - (sign(`W'-`EW')*(abs(`W'-`EW') - `cc')))/`se'
        local z2 = ((sign(`W'-`EW')*(abs(`W'-`EW') - `cc')) + `lower')/`se'
        }
    if lower("`eqvtype'") == "epsilon" {
        local z1 = `upper' - ( (sign(`W'-`EW')*(abs(`W'-`EW') - `cc'))/`se' )
        local z2 = ( (sign(`W'-`EW')*(abs(`W'-`EW') - `cc'))/`se' ) + `lower'
        }        
    local p1 = 1 - normal(`z1')
    local p2 = 1 - normal(`z2')    
  }

  local holdg1 = `g1' 
  local g1 = `g1'
  local g2 = `g2'

  local valulab : value label `by'
  if `"`valulab'"'!=`""' {
    local g1 : label `valulab' `g1'
    local g2 : label `valulab' `g2'
  }

  local by "`origby'"
  di as txt _newline `"Two-sample rank-sum test for stochastic equivalence"' _newline
  di in smcl as txt %12s abbrev(`"`by'"',12) /*
    */ " {c |}      obs    rank sum    expected"
  di in smcl as txt "{hline 13}{c +}{hline 33}"
  ditablin `"`g1'"' `n1' `W' `EW'
  ditablin `"`g2'"' `n2' `n'*(`n'+1)/2-`W' `n2'*(`n'+1)/2
  di in smcl as txt "{hline 13}{c +}{hline 33}"
  ditablin combined `n' `n'*(`n'+1)/2 `n'*(`n'+1)/2

  if `unv' < 1e7 {
    local vfmt `"%10.2f"' 
    }
  else             local vfmt `"%10.0g"'

  local xab = abbrev("`x'",8)
  local byab = abbrev("`by'",8)
  di in smcl as txt _newline `"unadjusted variance"' _col(22) as res `vfmt' `unv'
  di as txt `"adjustment for ties"' _col(22) as res `vfmt' `v'-`unv'
  di as txt _col(22) "{hline 10}"
  di as txt `"adjusted variance"' _col(22) as res `vfmt' `v' _newline

  if (lower("`eqvtype'") == "delta") {
    if (`upper' == `lower') {
      noisily: di as text "Delta (D) = " as res %-8.0f `lower' as res "Delta " as text "expressed in units of summed ranks (W)"
      }
    if (`upper' != `lower') {
      noisily: di as text "Delta (Dl) = " as res %-8.0f -1*`lower' as res " Dl " as text "expressed in units of summed ranks (W)"
      noisily: di as text "Delta (Du) =  " as res %-8.0f `upper' as res "Du " as text "expressed in units of summed ranks (W)"
      }
    local criticalvalue = `se'*invnormal(`level'/100)
    if (`upper' == `lower' & `lower' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if Delta <= z-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostranksum##mineqvlevel: help tostranksum}."
      }
    if (`upper' != `lower' & `lower' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if |Dl| <= z-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostranksum##mineqvlevel: help tostranksum}."
      }
    if (`upper' != `lower' & `upper' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if Du <= z-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostranksum##mineqvlevel: help tostranksum}."
      }
    if (`upper' == `lower') {
      noisily: di _newline as text "Ho: |W-E(W)| >= Delta:" _newline 
      if ("`ccontinuity'" != "") {
        noisily: di as text "Using continuity correction" _newline
        } 
      noisily: di as text "        z1 = " as res %-8.4g `z1' as text _col(38) "z2 = " as res %-8.4g `z2' _newline
      noisily: di as text "   Ho1: D-[W-E(W)] >= 0" _col(33) "Ho2: [W-E(W)]+D <= 0"
      noisily: di as text "   Ha1: D-[W-E(W)] < 0"  _col(33) "Ha2: [W-E(W)]+D > 0"
      noisily: di as text "   Pr(Z > z1) = " as res %6.4f `p1' _col(32) as text " Pr(Z > z2) = " as res %6.4f `p2'
      }
    if (`upper' != `lower') {
      noisily: di _newline as text "Ho: [W-E(W)] <= Dl, or [W-E(W)] >= Du:" _newline 
      if ("`ccontinuity'" != "") {
        noisily: di as text "Using continuity correction" _newline
        } 
      noisily: di as text "        z1 = " as res %-8.4g `z1' as text _col(38) "z2 = " as res %-8.4g `z2' _newline
      noisily: di as text "   Ho1: Du-[W-E(W)] >= 0       " _col(33) "Ho2: [W-E(W)]-Dl <= 0"
      noisily: di as text "   Ha1: Du-[W-E(W)] < 0" _col(33) "Ha2: [W-E(W)]-Dl > 0"
      noisily: di as text "   Pr(Z > z1) = " as res %6.4f `p1' _col(32) as text " Pr(Z > z2) = " as res %6.4f `p2'
      }
    }
   if lower("`eqvtype'") == "epsilon" {
    if (`upper' == `lower') {
      noisily: di as text "epsilon = " as res %-8.4f `lower' as text " " as res "`eqvtype'" as text " expressed in units of the z distribution"
      }
    if (`upper' != `lower') {
      noisily: di as text "epsilon (el) = " as res %-8.4f -1*`lower' as text " " as res " el" as text " expressed in units of the z distribution"
      noisily: di as text "epsilon (eu) =  " as res %-8.4f `upper' as text " " as res "eu" as text " expressed in units of the z distribution"
      }
    local criticalvalue = invnormal(`level'/100)
    if (`upper' == `lower' & `lower' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if epsilon <= t-crit (" %-5.3f `criticalvalue' "). See{help tostranksum##mineqvlevel: help tostranksum}." _newline
      }
    if (`upper' != `lower' & `lower' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if |el| <= t-crit (" %-5.3f `criticalvalue' "). See{help tostranksum##mineqvlevel: help tostranksum}." _newline
      }
    if (`upper' != `lower' & `upper' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if eu <= t-crit (" %-5.3f `criticalvalue' "). See{help tostranksum##mineqvlevel: help tostranksum}." _newline
      }
    if (`upper' == `lower') {
      noisily: di _newline as text "Ho: |z| >= epsilon:" _newline 
      if ("`ccontinuity'" != "") {
        noisily: di as text "Using continuity correction" _newline
        } 
      noisily: di as text "        z1 = " as res %-8.4g `z1' as text _col(38) "z2 = " as res %-8.4g `z2' _newline
      noisily: di as text "    Ho1: epsilon-z >= 0       " _col(34) "Ho2: z+epsilon <= 0"
      noisily: di as text "    Ha1: epsilon-z < 0" _col(34) "Ha2: z+epsilon > 0"
      noisily: di as text "    Pr(Z > z1) = " as res %6.4f `p1' _col(33) as text " Pr(Z > z2) = " as res %6.4f `p2'
      }
    if (`upper' != `lower') {
      noisily: di _newline as text "Ho: z <= el, or z >= eu:" _newline 
      if ("`ccontinuity'" != "") {
        noisily: di as text "Using continuity correction" _newline
        } 
      noisily: di as text "        z1 = " as res %-8.4g `z1' as text _col(38) "z2 = " as res %-8.4g `z2' _newline
      noisily: di as text "    Ho1: eu-z >= 0       " _col(34) "Ho2: z-el <= 0"
      noisily: di as text "    Ha1: eu-z < 0" _col(34) "Ha2: z-el > 0"
      noisily: di as text "    Pr(Z > z1) = " as res %6.4f `p1' _col(33) as text " Pr(Z > z2) = " as res %6.4f `p2'
      }
    }

  if (`upper' != `lower') {
    if "`eqvtype'" == "delta" {
      return scalar Du   = `upper'
      return scalar Dl   = `lower'
      }
    if "`eqvtype'" == "epsilon" {
      return scalar eu   = `upper'
      return scalar el   = `lower'
      }
    }
  if (`upper' == `lower') {
    if "`eqvtype'" == "delta" {
      return scalar Delta   = `eqvlevel'
      }
    if "`eqvtype'" == "epsilon" {
      return scalar epsilon   = `eqvlevel'
      }
    }
  return scalar  sum_exp  = `EW'
  return scalar  sum_obs  = `W'
  return scalar  group1   = `holdg1' 
  return scalar  Var_a    = `v'
  return scalar  p2       = `p2'
  return scalar  p1       = `p1'
  return scalar  z2       = `z2'
  return scalar  z1       = `z1'
  return scalar  N_2      = `n2'
  return scalar  N_1      = `n1'

  end

program define ditablin
  if length(`"`1'"') > 12 {
    local 1 = substr(`"`1'"',1,12)
    }
  di in smcl as txt %12s `"`1'"' " {c |}" as res _col(17) %7.0g `2' _col(26) %10.0g `3' _col(38) %10.0g `4'
  end
