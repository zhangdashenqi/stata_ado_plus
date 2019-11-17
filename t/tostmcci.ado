*! version 1.6.0 02mar2014 by alexis dot dinno at pdx dot edu
*! perform two one-sided tests for stochastic equivalence in paired data

* Syntax:  tostmcci varname [if exp] [in range] [fweight exp], [ 
*          eqvtype(type) eqvlevel(#) uppereqvlevel(#) yates edwards level(#) ]

program define tostmcci

  if int(_caller())<8 {
    di in r "tostmcci- does not support this version of Stata." _newlineewline
    di as txt "Requests for a version compatible with versions of STATA earlier than v8 are "
    di as txt "untenable since I do not have access to the software." _newlineewline 
    exit
  }
   else tostmcci8 `0'
end

program tostmcci8, rclass
  version 8, missing

  gettoken a 0 : 0, parse(" ,")
  gettoken b 0 : 0, parse(" ,")
  gettoken c 0 : 0, parse(" ,")
  gettoken d 0 : 0, parse(" ,")

  confirm integer number `a'
  confirm integer number `b'
  confirm integer number `c'
  confirm integer number `d'

  if `a'<0 | `b'<0 | `c'<0 | `d'<0 { 
    di in red "negative numbers invalid"
    exit 498
  }

  syntax  [, EQVType(string) EQVLevel(real 1) UPPEReqvlevel(real 0) yates /*
*/        edwards Level(cilevel) ]

* Validate eqvtype
  if lower("`eqvtype'") == "" {
    local eqvtype = "delta"
    }

  if !(lower("`eqvtype'") == "delta" | lower("`eqvtype'") == "epsilon") {
    noisily: di as err "option eqvtype() must be one of: delta, or epsilon"
    exit 198
    }

* Validate eqvlevel
  if (lower("`eqvtype'") == "delta") & (`eqvlevel' == 1 & `uppereqvlevel'==0) {
    local eqvlevel = 0.1
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

* Validate continuity correction option
  if ("`yates'" != "" & "`edwards'" != "") {
    noisily di as err "continuity correction options must be either yates or edwards, but not both"
    exit 198
    }

  di as txt _newline "Test for equivalence in paired binary data" 
  di as txt "{hline 17}{c TT}{hline 24}{c TT}{hline 12}"

  _crc4fld `a' `b' `c' `d' /*
    */ Controls Cases Exposed Unexposed Exposed Unexposed
  di as txt "{hline 17}{c BT}{hline 24}{c BT}{hline 12}"
  local n = `a'+`b'+`c'+`d'
  local den = `b' + `c'
  local low = min(`b',`c')
  local diff = `b' - `c'
  local se = sqrt((`b'+`c') - (`n'*(((`b'/`n')-(`c'/`n'))^2)))
  
  local continuity = 0
  if ("`yates'" != "") {
    local continuity = 0.5
    }
  if ("`edwards'" != "") {
    local continuity = 1
    }

  if (lower("`eqvtype'")=="delta") {
    local z1 = ( (`n'*`upper') - ((`diff') - `continuity') )/`se'
    local z2 = ( ((`diff') + `continuity') + (`n'*`lower') )/`se'
    }
  if (lower("`eqvtype'")=="epsilon") {
    local z1 = `upper' - (( (`diff') - `continuity' )/`se')
    local z2 = (( (`diff') + `continuity' )/`se') + `lower'
    }
  local p1 = 1 - normal(`z1')
  local p2 = 1 - normal(`z2')

  if lower("`eqvtype'") == "delta" {
    noisily: di as txt "       diff = " as res `b' as txt " - " as res `c' as txt " = " `diff'   
    noisily: di as txt "  s.e. diff = " as res %-8.4f `se'    
    if (`upper' == `lower') {
      noisily: di as txt "      Delta = " as res %-8.4f `lower' 
      noisily: di as res "      Delta " as txt "expressed in units of probability"
      }
    if (`upper' != `lower') {
      noisily: di as txt " Delta (Dl) = " as res %-8.4f -1*`lower'
      noisily: di as txt " Delta (Du) = " as res %-8.4f `upper' 
      noisily: di as res  " Delta lower" as txt " and " as res "upper" as txt " expressed in units of probability"
      }
    local criticalvalue = (`se'*invnormal(`level'/100))/`n'
    if (`upper' == `lower' & `lower' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if Delta <= z-crit*s.e/n ( " %-6.4g `criticalvalue' "). See{help tostmcc##mineqvlevel: help tostmcc}."
      }
    if (`upper' != `lower' & `lower' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if |Dl| <= t-crit*s.e/n ( " %-6.4g `criticalvalue' "). See{help tostmcc##mineqvlevel: help tostmcc}."
      }
    if (`upper' != `lower' & `upper' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if Du <= t-crit*s.e/n ( " %-6.4g `criticalvalue' "). See{help tostmcc##mineqvlevel: help tostmcc}."
      }
    if (`upper' == `lower') {
      noisily: di _newline as txt "Ho: |diff| >= Delta:" _newline 
      if ("`yates'" != "") {
        noisily: di as txt "Using the Yates continuity correction" _newline
        } 
      if ("`edwards'" != "") {
        noisily: di as txt "Using the Edwards continuity correction" _newline
        } 
      noisily: di as txt "        z1 = " as res %-8.4g `z1' as txt _col(38) "z2 = " as res %-8.4g `z2' _newline
      noisily: di as txt "   Ho1: Delta-diff >= 0" _col(33) "Ho2: diff+Delta <= 0"
      noisily: di as txt "   Ha1: Delta-diff < 0"  _col(33) "Ha2: diff+Delta > 0"
      noisily: di as txt "   Pr(Z > z1) = " as res %6.4f `p1' _col(32) as txt " Pr(Z > z2) = " as res %6.4f `p2'
      }
    if (`upper' != `lower') {
      noisily: di _newline as txt "Ho: diff <= Dl, or diff >= Du:" _newline 
      if ("`yates'" != "") {
        noisily: di as txt "Using the Yates continuity correction" _newline
        } 
      if ("`edwards'" != "") {
        noisily: di as txt "Using the Edwards continuity correction" _newline
        } 
      noisily: di as txt "        z1 = " as res %-8.4g `z1' as txt _col(38) "z2 = " as res %-8.4g `z2' _newline
      noisily: di as txt "   Ho1: Du-diff >= 0" _col(33) "Ho2: diff-Dl <= 0"
      noisily: di as txt "   Ha1: Du-diff < 0"  _col(33) "Ha2: diff-Dl > 0"
      noisily: di as txt "   Pr(Z > z1) = " as res %6.4f `p1' _col(32) as txt " Pr(Z > z2) = " as res %6.4f `p2'
      }
    }
  if lower("`eqvtype'") == "epsilon" {
    noisily: di as txt "        diff = " as res `b' as txt " - " as res `c' as txt " = " as res `diff'    
    noisily: di as txt "   s.e. diff = " as res %-8.4f `se'    
    if (`upper' == `lower') {
      noisily: di as txt "     epsilon = " as res %-8.4f `lower' 
      noisily: di as res "     epsilon " as txt "expressed in units of the z distribution"
      }
    if (`upper' != `lower') {
      noisily: di as txt "epsilon (el) = " as res %-8.4f -1*`lower'
      noisily: di as txt "epsilon (eu) = " as res %-8.4f `upper'
      noisily: di as res "epsilon lower" as txt " and " as res "upper" as txt " expressed in units of the z distribution"
      }
    local criticalvalue = invnormal(`level'/100)
    if (`upper' == `lower' & `lower' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if epsilon <= z-crit (" %-5.3f `criticalvalue' "). See{help tostmcc##mineqvlevel: help tostmcc}."
      }
    if (`upper' != `lower' & `lower' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if |el| <= z-crit (" %-5.3f `criticalvalue' "). See{help tostmcc##mineqvlevel: help tostmcc}."
      }
    if (`upper' != `lower' & `upper' <= `criticalvalue') {
      noisily: di _newline as res "Impossible to reject any Ho if eu <= z-crit (" %-5.3f `criticalvalue' "). See{help tostmcc##mineqvlevel: help tostmcc}."
      }
    if (`upper' == `lower') {
      noisily: di _newline as txt "Ho: |z| >= epsilon:" _newline 
      if ("`yates'" != "") {
        noisily: di as txt "Using the Yates continuity correction" _newline
        } 
      if ("`edwards'" != "") {
        noisily: di as txt "Using the Edwards continuity correction" _newline
        } 
      noisily: di as txt "        z1 = " as res %-8.4g `z1' as txt _col(38) "z2 = " as res %-8.4g `z2' _newline
      noisily: di as txt "   Ho1: epsilon-z >= 0" _col(33) "Ho2: z+epsilon <= 0"
      noisily: di as txt "   Ha1: epsilon-z < 0"  _col(33) "Ha2: z+epsilon > 0"
      noisily: di as txt "   Pr(Z > z1) = " as res %6.4f `p1' _col(32) as txt " Pr(Z > z2) = " as res %6.4f `p2'
      }
    if (`upper' != `lower') {
      noisily: di _newline as txt "Ho: z <= el, or z >= eu:" _newline 
      if ("`yates'" != "") {
        noisily: di as txt "Using the Yates continuity correction" _newline
        } 
      if ("`edwards'" != "") {
        noisily: di as txt "Using the Edwards continuity correction" _newline
        } 
      noisily: di as txt "        z1 = " as res %-8.4g `z1' as txt _col(38) "z2 = " as res %-8.4g `z2' _newline
      noisily: di as txt "   Ho1: eu-z >= 0" _col(33) "Ho2: z-el <= 0"
      noisily: di as txt "   Ha1: eu-z < 0"  _col(33) "Ha2: z-el > 0"
      noisily: di as txt "   Pr(Z > z1) = " as res %6.4f `p1' _col(32) as txt " Pr(Z > z2) = " as res %6.4f `p2'
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
  return scalar  D_f  = (`b'/`n') - (`c'/`n')
  return scalar  p2   = `p2'
  return scalar  p1   = `p1' 
  return scalar  z2   = `z2'
  return scalar  z1   = `z1' 
end
