*! version 1.5.1 02mar2014 by alexis dot dinno at pdx dot edu
*! perform two one-sided tests for stochastic equivalence in paired data

* Syntax:  tostsignrank varname [=exp] [if exp] [in range] [, eqvtype(type) 
*          eqvlevel(#) uppereqvlevel(#) ccontinuity level(#) ]

program define tostsignrank

  if int(_caller())<8 {
    di in r "tostsignrank- does not support this version of Stata." _newline
    di as txt "Requests for a version compatible with versions of STATA earlier than v8 are "
    di as txt "untenable since I do not have access to the software." _newline 
    exit
  }
   else tostsignrank8 `0'
end

program define tostsignrank8, rclass byable(recall)
  version 8.0, missing

  /* turn "==" into "=" if needed before calling -syntax- */
  gettoken vn rest : 0, parse(" =")
  gettoken eq rest : rest, parse(" =")
  if "`eq'" == "==" {
    local 0 `vn' = `rest'
    }

  syntax varname [=/exp] [if] [in] [, EQVType(string) EQVLevel(real 1) /*
*/      UPPEReqvlevel(real 0) CContinuity level(cilevel) ] 

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


  tempname tp tn v unv z adj0
  tempvar touse diff ranks t

  quietly {
    mark `touse' `if' `in'
    gen double `diff' = `varlist'-(`exp') if `touse'
    markout `touse' `diff'
    egen double `ranks' = rank(abs(`diff')) if `touse'
    
    /* We do want to OMIT the ranks corresponding to `diff'==0 in the sums.  */
    gen double `t' = sum(cond(`diff'>0,`ranks',0))
    scalar `tp' = `t'[_N]
    replace `t' = sum(cond(`diff'<0,`ranks',0))
    scalar `tn' = `t'[_N]
    replace `t' = sum(cond(`diff'~=0,`ranks'*`ranks',0))
    scalar `v' = `t'[_N]/4
    local se = 2*sqrt(`v')
    if (lower("`ccontinuity'") == "") {
      local cc = 0
      }
    if (lower("`ccontinuity'") != "") {
      local cc = 0.5
      }
    if lower("`eqvtype'") == "delta" {
        local z1 = (`upper' - (sign(`tp'-`tn')*(abs(`tp'-`tn') - `cc')))/`se'
        local z2 = ((sign(`tp'-`tn')*(abs(`tp'-`tn') - `cc')) + `lower')/`se'
        }
    if lower("`eqvtype'") == "epsilon" {
        local z1 = `upper' - ( (sign(`tp'-`tn')*(abs(`tp'-`tn') - `cc'))/`se' )
        local z2 = ( (sign(`tp'-`tn')*(abs(`tp'-`tn') - `cc'))/`se' ) + `lower'
        }        
    local p1 = 1 - normal(`z1')
    local p2 = 1 - normal(`z2')
    count if `touse'
    local n = r(N)
    scalar `unv' = `n'*(`n'+1)*(2*`n'+1)/24
    count if `diff' == 0 & `touse'
    local n0 = r(N)
    scalar `adj0' = -`n0'*(`n0'+1)*(2*`n0'+1)/24
    count if `diff' > 0 & `touse'
    local np = r(N)
    local nn = `n' - `np' - `n0'
      }

  di _newline as txt `"Signed-rank test for stochastic equivalence"' _newline
  di in smcl as txt `"        sign {c |}      obs   sum ranks    expected"'
  di in smcl as txt "{hline 13}{c +}{hline 33}"
  ditablin positive `np' `tp' (`tp'+`tn')/2
  ditablin negative `nn' `tn' (`tp'+`tn')/2
  ditablin zero     `n0' `n0'*(`n0'+1)/2 `n0'*(`n0'+1)/2 
  di in smcl as txt "{hline 13}{c +}{hline 33}"
  ditablin all `n' `n'*(`n'+1)/2 `n'*(`n'+1)/2 

  if `unv' < 1e7 { 
    local vfmt `"%10.2f"' 
    }
   else
    local vfmt `"%10.0g"'

  di in smcl as txt _newline `"unadjusted variance"' _col(22) as res `vfmt' `unv'
  di as txt `"adjustment for ties"' _col(22) as res `vfmt' `v'-`unv'-`adj0'
  di as txt `"adjustment for zeros"' _col(22) as res `vfmt' `adj0'
  di as txt _col(22) "{hline 10}"
  di as txt `"adjusted variance"' _col(22) as res `vfmt' `v' _newline

  if (lower("`eqvtype'") == "delta") {
    if (`upper' == `lower') {
      noisily: di as text "Delta (D) = " as res %-8.0f `lower' as res "Delta " as text "expressed in units of signed ranks (T)"
      }
    if (`upper' != `lower') {
      noisily: di as text "Delta (Dl) = " as res %-8.0f -1*`lower' as res " Dl " as text "expressed in units of signed ranks (T)"
      noisily: di as text "Delta (Du) =  " as res %-8.0f `upper' as res "Du " as text "expressed in units of signed ranks (T)"
      }
    local criticalvalue = `se'*invnormal(`level'/100)
    if (`upper' == `lower' & `lower' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if Delta <= z-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostsignrank##mineqvlevel: help tostsignrank}."
      }
    if (`upper' != `lower' & `lower' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if |Dl| <= z-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostsignrank##mineqvlevel: help tostsignrank}."
      }
    if (`upper' != `lower' & `upper' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if Du <= z-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostsignrank##mineqvlevel: help tostsignrank}."
      }
    if (`upper' == `lower') {
      noisily: di _newline as text "Ho: |T-E(T)| >= Delta:" _newline 
      if ("`ccontinuity'" != "") {
        noisily: di as text "Using continuity correction" _newline
        } 
      noisily: di as text "        z1 = " as res %-8.4g `z1' as text _col(38) "z2 = " as res %-8.4g `z2' _newline
      noisily: di as text "   Ho1: D-[T-E(T)] >= 0" _col(33) "Ho2: [T-E(T)]+D <= 0"
      noisily: di as text "   Ha1: D-[T-E(T)] < 0"  _col(33) "Ha2: [T-E(T)]+D > 0"
      noisily: di as text "   Pr(Z > z1) = " as res %6.4f `p1' _col(32) as text " Pr(Z > z2) = " as res %6.4f `p2'
      }
    if (`upper' != `lower') {
      noisily: di _newline as text "Ho: [T-E(T)] <= Dl, or [T-E(T)] >= Du:" _newline 
      if ("`ccontinuity'" != "") {
        noisily: di as text "Using continuity correction" _newline
        } 
      noisily: di as text "        z1 = " as res %-8.4g `z1' as text _col(38) "z2 = " as res %-8.4g `z2' _newline
      noisily: di as text "   Ho1: Du-[T-E(T)] >= 0       " _col(33) "Ho2: [T-E(T)]-Dl <= 0"
      noisily: di as text "   Ha1: Du-[T-E(T)] < 0" _col(33) "Ha2: [T-E(T)]-Dl > 0"
      noisily: di as text "   Pr(Z > z1) = " as res %6.4f `p1' _col(32) as text " Pr(Z > z2) = " as res %6.4f `p2'
      }
    }
   if lower("`eqvtype'") == "epsilon" {
    if (`upper' == `lower') {
      noisily: di as text "epsilon = " as res %-8.4f `lower' as text " " as res "epsilon" as text " expressed in units of the z distribution"
      }
    if (`upper' != `lower') {
      noisily: di as text "epsilon (el) = " as res %-8.4f -1*`lower' as text " " as res " el" as text " expressed in units of the z distribution"
      noisily: di as text "epsilon (eu) =  " as res %-8.4f `upper' as text " " as res "eu" as text " expressed in units of the z distribution"
      }
    local criticalvalue = invnormal(`level'/100)
    if (`upper' == `lower' & `lower' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if epsilon <= t-crit (" %-5.3f `criticalvalue' "). See{help tostsignrank##mineqvlevel: help tostsignrank}." _newline
      }
    if (`upper' != `lower' & `lower' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if |el| <= t-crit (" %-5.3f `criticalvalue' "). See{help tostsignrank##mineqvlevel: help tostsignrank}." _newline
      }
    if (`upper' != `lower' & `upper' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if eu <= t-crit (" %-5.3f `criticalvalue' "). See{help tostsignrank##mineqvlevel: help tostsignrank}." _newline
      }
    if (`upper' == `lower') {
      noisily: di _newline as text "Ho: |z| >= epsilon:" _newline 
      if ("`ccontinuity'" != "") {
        noisily: di as text "Using continuity correction" _newline
        } 
      noisily: di as text "        z1 = " as res %-8.4g `z1' as text _col(38) "z2 = " as res %-8.4g `z2' _newline
      noisily: di as text "    Ho1: epsilon-z >= 0       " _col(34) "Ho2: z+epsilon <= 0"
      noisily: di as text "    Ha1: epsilon-z < 0" _col(34) "Ha2: z+epsilon > 0"
      noisily: di as text "    Pr(Z > t1) = " as res %6.4f `p1' _col(33) as text " Pr(Z > t2) = " as res %6.4f `p2'
      }
    if (`upper' != `lower') {
      noisily: di _newline as text "Ho: z <= el, or z >= eu:" _newline 
      if ("`ccontinuity'" != "") {
        noisily: di as text "Using continuity correction" _newline
        } 
      noisily: di as text "        z1 = " as res %-8.4g `z1' as text _col(38) "z2 = " as res %-8.4g `z2' _newline
      noisily: di as text "    Ho1: eu-z >= 0       " _col(34) "Ho2: z-el <= 0"
      noisily: di as text "    Ha1: eu-z < 0" _col(34) "Ha2: z-el > 0"
      noisily: di as text "    Pr(Z > t1) = " as res %6.4f `p1' _col(33) as text " Pr(Z > t2) = " as res %6.4f `p2'
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
  ret scalar p2 = `p2'
  ret scalar p1 = `p1'
  ret scalar z2 = `z2'
  ret scalar z1 = `z1'
  ret scalar Var_a = `v'
  ret scalar sum_newlineeg = `tn'
  ret scalar sum_pos = `tp'
  ret scalar N_tie = `n0'
  ret scalar N_pos = `np'
  ret scalar N_newlineeg = `nn'
  end 

program define ditablin
  di in smcl as txt %12s `"`1'"' `" {c |}"' as res _col(17) %7.0g `2' _col(26) %10.0g `3' _col(38) %10.0g `4'
  end
  
