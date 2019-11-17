*! version 1.4.1 01mar2014 by alexis dot dinno at pdx dot edu
*! perform two one-sided tests of proportion equivalence

* Syntax:  tostpr varname [=exp] [if exp] [in range] [, eqvtype(type) 
*          eqvlevel(#) uppereqvlevel(#) by(groupname) yates ha level(#) ]

program define tostpr

  if int(_caller())<8 {
    di in r "tostpr- does not support this version of Stata." _newline
    di as txt "Requests for a v7 compatible version will be relatively easy to honor." 
    di as txt "Requests for a v6 compatible version may be less easy." 
    di as txt "Requests for a version compatible with versions of STATA earlier than v6 are "
    di as txt "untenable since I do not have access to the software." _newline 
    di as txt "All requests are welcome and will be considered."
    exit
  }
   else tostpr8 `0'
end

program define tostpr8, rclass byable(recall)
 version 8.0, missing

	/* turn "==" into "=" if needed before calling -syntax- */
	gettoken vn rest : 0, parse(" =")
	gettoken eq rest : rest, parse(" =")
	if "`eq'" == "==" {
		local 0 `vn' = `rest'
	}

 syntax varname [=/exp] [if] [in] [, EQVType(string) EQVLevel(real 1) /*
*/       UPPEReqvlevel(real 0) BY(varname) YAtes ha Level(cilevel)]

 quietly {

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

 if lower("`eqvtype'") == "delta" & (`eqvlevel' >= 1 | `uppereqvlevel' >= 1) {
   noisily: di as err "option eqvlevel() incorrectly specified" _newline "you are likely to find all proportions equivalent within an interval of plus or minus 1 or more"
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
   
* Invalidate options specified with one-sample test
 capture confirm number `exp'
 if _rc == 0 {
   if "`by'" != "" {
     noisily di as err "may not combine = and option by()"
     exit 198
     }
   
   if ("`yates'" != "" | "`ha'" != "") {
     noisily di _newline as res "continuity correction options are not available for one-sample tests"
     local yates = ""
     local ha = "" 
     }
   }

* Validate continuity correction option
 if ("`yates'" != "" & "`ha'" != "") {
   noisily di as err "continuity correction options must be either yates or ha, but not both"
   exit 198
   }

 local continuity = 0
 
*******************************************************************************
* The business starts here                                                    *
*******************************************************************************

**********
* conduct the positivist z test of proportion difference
 if "`exp'" != "" & "`by'" == "" {
   local eexp = "= `exp'"
   }
 quietly: prtest `varlist' `eexp' `if' `in', by("`by'") level(`level')

 capture confirm number `exp'
 if _rc != 0 {
   local n1 = r(N_1)
   local m1 = r(P_1)
   local se1= sqrt(r(P_1)*(1-r(P_1))/(`n1'))
   local n2 = r(N_2)
   local m2 = r(P_2)
   local se2= sqrt(r(P_2)*(1-r(P_2))/(`n2'))
   local N  = `n1'+`n2'
   local p  = (r(P_1)*r(N_1) +  r(P_2)*r(N_2))/(`N')
   local se_p = sqrt( `p'*(1-`p')*((1/`n1') + (1/`n2')) )
   if ("`yates'" != "") {
     local continuity = 0.5*((1/`n1') + (1/`n2'))
     }
   if ("`ha'" != "") {
     local continuity = 1/(2*min(`n1',`n2'))
     local se_p = sqrt( (((`m1'/`n1') * (1-(`m1'/`n1')))/(`n1'-1)) + (((`m2'/`n2') * (1-(`m2'/`n2')))/(`n2'-1)))
     }
   if lower("`eqvtype'") == "delta" {
     local z1 = (`upper' - (r(P_1) - r(P_2))+`continuity')/`se_p'
     local z2 = ((r(P_1) - r(P_2))+`lower'-`continuity')/`se_p'
     }
   if lower("`eqvtype'") == "epsilon" {
     local z1 = `upper' - ( ((r(P_1) - r(P_2))+`continuity')/`se_p' )
     local z2 = ( ((r(P_1) - r(P_2))-`continuity')/`se_p' ) + `lower'
     }
   local p1 = 1 - normal(`z1')
   local p2 = 1 - normal(`z2')
   if "`by'" != "" {
     sum `by'
     local min = r(min)
     local max = r(max)
     }
   }
 

**********
* one-sample test of proportion equivalence
 if _rc == 0 {
   local n1 = r(N_1)
   local m1 = r(P_1)
   local se = sqrt(r(P_1)*(1-r(P_1))/(`n1'))
   local se_p = sqrt(`exp'*(1-`exp')/`n1')
   if lower("`eqvtype'") == "delta" {
     local z1 = (`upper' - (r(P_1) - `exp'))/`se_p'
     local z2 = ((r(P_1) - `exp')+`lower')/`se_p'
     }
   if lower("`eqvtype'") == "epsilon" {
     local z1 = `upper' - ( ((r(P_1) - `exp'))/`se_p' )
     local z2 = ( ((r(P_1) - `exp'))/`se_p' ) + `lower'
     }
   local p1 = 1 - normal(`z1')
   local p2 = 1 - normal(`z2')
   local name1 = trim(substr(trim(`"`varlist'"'),1,12))
   local c1 = 53 - length(`"`name1'"')
   noisily: di
   noisily: di as text `"One-sample test of proportion equivalence"' /*
     */ _col(`c1') as res abbrev(`"`varlist'"', 12) as text _col(53) /*
     */ `": Number of obs = "' as res %8.0g `n1'
   noisily: _prtest1 `varlist' `n1' `m1' `se' `level' 
   if lower("`eqvtype'") == "delta" {
     noisily: di in smcl as text "{hline 13}{c +}{hline 64}"
     if (`upper' == `lower') {
       noisily: _prtest2 "Delta-diff" `n1' `upper'-(`m1'-`exp') `se_p' `level'
       noisily: _prtest2 "diff+Delta" `n1' (`m1'-`exp')+`lower' `se_p' `level'
       }
     if (`upper' != `lower') {
       noisily: _prtest2 "Du-diff" `n1' `upper'-(`m1'-`exp') `se_p' `level'
       noisily: _prtest2 "diff-Dl" `n1' (`m1'-`exp')+`lower' `se_p' `level'
       }
     }
   noisily: di in smcl as text "{hline 13}{c BT}{hline 64}"
   if lower("`eqvtype'") == "delta" {
     noisily: di as text "      diff = prop(" as res "`varlist'" as text ") - " as res `exp' as text " = " as res `m1' - `exp'    
     if (`upper' == `lower') {
       noisily: di as text "     Delta = " as res %-8.4f `lower' as res "Delta " as text "expressed in same units as prop(" as res "`varlist'" as text ")"
       }
     if (`upper' != `lower') {
       noisily: di as text "Delta (Dl) = " as res %-8.4f -1*`lower' as res "Dl " as text "expressed in same units as prop(" as res "`varlist'" as text ")"
       noisily: di as text "Delta (Du) = " as res %-8.4f `upper' as res "Du " as text "expressed in same units as prop(" as res "`varlist'" as text ")"
       }
     local criticalvalue = `se_p'*invnormal(`level'/100)
     if (`upper' == `lower' & `lower' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if Delta <= z-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostpr##mineqvlevel: help tostpr}."
       }
     if (`upper' != `lower' & `lower' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if |Dl| <= t-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostpr##mineqvlevel: help tostpr}."
       }
     if (`upper' != `lower' & `upper' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if Du <= t-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostpr##mineqvlevel: help tostpr}."
       }
     if (`upper' == `lower') {
       noisily: di _newline as text "Ho: |diff| >= Delta:" _newline 
       noisily: di as text "        z1 = " as res %-8.4g `z1' as text _col(38) "z2 = " as res %-8.4g `z2' _newline
       noisily: di as text "   Ho1: Delta-diff >= 0" _col(33) "Ho2: diff+Delta <= 0"
       noisily: di as text "   Ha1: Delta-diff < 0"  _col(33) "Ha2: diff+Delta > 0"
       noisily: di as text "   Pr(Z > z1) = " as res %6.4f `p1' _col(32) as text " Pr(Z > z2) = " as res %6.4f `p2'
       }
     if (`upper' != `lower') {
       noisily: di _newline as text "Ho: diff <= Dl, or diff >= Du:" _newline 
       noisily: di as text "        z1 = " as res %-8.4g `z1' as text _col(38) "z2 = " as res %-8.4g `z2' _newline
       noisily: di as text "   Ho1: Du-diff >= 0" _col(33) "Ho2: diff-Dl <= 0"
       noisily: di as text "   Ha1: Du-diff < 0"  _col(33) "Ha2: diff-Dl > 0"
       noisily: di as text "   Pr(Z > z1) = " as res %6.4f `p1' _col(32) as text " Pr(Z > z2) = " as res %6.4f `p2'
       }
     }
   if lower("`eqvtype'") == "epsilon" {
     noisily: di as text "        diff = prop(" as res "`varlist'" as text ") - " as res `exp' as text " = " as res `m1' - `exp'     
     if (`upper' == `lower') {
       noisily: di as text "     epsilon = " as res %-8.4f `lower' as res "epsilon " as text "expressed in units of the z distribution"
       }
     if (`upper' != `lower') {
       noisily: di as text "epsilon (el) = " as res %-8.4f -1*`lower' as text " " as res "el" as text " expressed in units of the z distribution"
       noisily: di as text "epsilon (eu) = " as res %-8.4f `upper' as text " " as res "eu" as text " expressed in units of the z distribution"
       }
     local criticalvalue = invnormal(`level'/100)
     if (`upper' == `lower' & `lower' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if epsilon <= z-crit (" %-5.3f `criticalvalue' "). See{help tostpr##mineqvlevel: help tostpr}."
       }
     if (`upper' != `lower' & `lower' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if |el| <= z-crit (" %-5.3f `criticalvalue' "). See{help tostpr##mineqvlevel: help tostpr}."
       }
     if (`upper' != `lower' & `upper' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if eu <= z-crit (" %-5.3f `criticalvalue' "). See{help tostpr##mineqvlevel: help tostpr}."
       }
     if (`upper' == `lower') {
       noisily: di _newline as text "Ho: |z| >= epsilon:" _newline 
       noisily: di as text "        z1 = " as res %-8.4g `z1' as text _col(38) "z2 = " as res %-8.4g `z2' _newline
       noisily: di as text "   Ho1: epsilon-z >= 0" _col(33) "Ho2: z+epsilon <= 0"
       noisily: di as text "   Ha1: epsilon-z < 0"  _col(33) "Ha2: z+epsilon > 0"
       noisily: di as text "   Pr(Z > z1) = " as res %6.4f `p1' _col(32) as text " Pr(Z > z2) = " as res %6.4f `p2'
       }
     if (`upper' != `lower') {
       noisily: di _newline as text "Ho: z <= el, or z >= eu:" _newline 
       noisily: di as text "        z1 = " as res %-8.4g `z1' as text _col(38) "z2 = " as res %-8.4g `z2' _newline
       noisily: di as text "   Ho1: eu-z >= 0" _col(33) "Ho2: z-el <= 0"
       noisily: di as text "   Ha1: eu-z < 0"  _col(33) "Ha2: z-el > 0"
       noisily: di as text "   Pr(Z > z1) = " as res %6.4f `p1' _col(32) as text " Pr(Z > z2) = " as res %6.4f `p2'
       }
     }
   }


**********
* two-sample z test of proportion equivalence
 if _rc != 0 {
   noisily: di
   if "`by'" != "" {
     local name1 = "`: label (`by')`min''"
     local name2 = "`: label (`by')`max''"
     local c1 = 53 - length(`"`name1'"')
     local c2 = 53 - length(`"`name2'"')
     noisily: di as text "Two-sample test of proportion equivalence" /*
       */ _col(`c1') as res "`name1'" as text _col(53) /*
       */ `": Number of obs = "' as res %8.0g `n1'
     noisily di as text _col(`c2') as res "`name2'" as text _col(53) /*
       */ `": Number of obs = "' as res %8.0g `n2'			
     noisily: _prtest1 "`name1'" `n1' `m1' `se1' `level' 
     noisily: _prtest2 "`name2'" `n2' `m2' `se2' `level' 
     }
   if "`by'" == "" {
     local name1 = trim(substr(trim(`"`varlist'"'),1,12))
     local name2 = trim(substr(trim(`"`exp'"'),1,12))
     local c1 = 53 - length(`"`name1'"')
     local c2 = 53 - length(`"`name2'"')
     noisily: di in gr "Two-sample test of proportion equivalence" /*
       */ _col(`c1') in ye abbrev(`"`varlist'"', 12) in gr _col(53) /*
       */ `": Number of obs = "' in ye %8.0g `n1'
     noisily: di _col(`c2') as res (abbrev(`"`exp'"', 12)) as text _col(53) /*
       */ `": Number of obs = "' as res %8.0g `n2'			
     noisily: _prtest1 `varlist' `n1' `m1' `se1' `level' 
     noisily: _prtest2 `exp' `n2' `m2' `se2' `level' 
     }
   noisily: di in smcl as text "{hline 13}{c +}{hline 64}"
   if lower("`eqvtype'") == "delta" {
     if (`upper' == `lower') {
       noisily: _prtest2 "Delta-diff" `N' `upper'-(`m1'-`m2') `se_p' `level'
       noisily: _prtest2 "diff+Delta" `N' (`m1'-`m2')+`lower' `se_p' `level'
       }
     if (`upper' != `lower') {
       noisily: _prtest2 "Du-diff" `N' `upper'-(`m1'-`m2') `se_p' `level'
       noisily: _prtest2 "diff-Dl" `N' (`m1'-`m2')+`lower' `se_p' `level'
       }
     }
   if lower("`eqvtype'") == "epsilon" {
     noisily: _prtest2 "      diff" `N' `m1'-`m2' `se_p' `level'
     }
   noisily: di in smcl as text "{hline 13}{c BT}{hline 64}"
   if lower("`eqvtype'") == "delta" {
     if "`by'" == "" {
       noisily: di as text "      diff = prop(" as res "`varlist'" as text ") - prop(" as res "`exp'" as text ") = "  as res `m1' - `m2'     
       }
     if "`by'" != "" {
       noisily: di as text "      diff = prop(`varlist'|`by' = " as res "`name1'" as text ") - prop(`varlist'|`by' = " as res "`name2'" as text ")"     
       noisily: di as text "           = " as res `m1' - `m2'     
       }
     if (`upper' == `lower') {
       noisily: di as text "     Delta = " as res %-8.4f `lower' as res "Delta " as text "expressed in same units as prop(" as res "`varlist'" as text ")"
       }
     if (`upper' != `lower') {
       noisily: di as text "Delta (Dl) = " as res %-8.4f -1*`lower' as res "Dl " as text "expressed in same units as prop(" as res "`varlist'" as text ")"
       noisily: di as text "Delta (Du) = " as res %-8.4f `upper' as res "Du " as text "expressed in same units as prop(" as res "`varlist'" as text ")"
       }
     local criticalvalue = `se_p'*invnormal(`level'/100)
     if (`upper' == `lower' & `lower' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if Delta <= z-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostpr##mineqvlevel: help tostpr}."
       }
     if (`upper' != `lower' & `lower' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if |Dl| <= t-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostpr##mineqvlevel: help tostpr}."
       }
     if (`upper' != `lower' & `upper' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if Du <= t-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostpr##mineqvlevel: help tostpr}."
       }
     if (`upper' == `lower') {
       noisily: di _newline as text "Ho: |diff| >= Delta:" _newline 
       if ("`yates'" != "") {
         noisily: di as text "Using the Yates continuity correction" _newline
         } 
       if ("`ha'" != "") {
         noisily: di as text "Using the Hauck-Anderson continuity correction" _newline
         } 
       noisily: di as text "        z1 = " as res %-8.4g `z1' as text _col(38) "z2 = " as res %-8.4g `z2' _newline
       noisily: di as text "   Ho1: Delta-diff >= 0" _col(33) "Ho2: diff+Delta <= 0"
       noisily: di as text "   Ha1: Delta-diff < 0"  _col(33) "Ha2: diff+Delta > 0"
       noisily: di as text "   Pr(Z > z1) = " as res %6.4f `p1' _col(32) as text " Pr(Z > z2) = " as res %6.4f `p2'
       }
     if (`upper' != `lower') {
       noisily: di _newline as text "Ho: diff <= Dl, or diff >= Du:" _newline 
       if ("`yates'" != "") {
         noisily: di as text "Using the Yates continuity correction" _newline
         } 
       if ("`ha'" != "") {
         noisily: di as text "Using the Hauck-Anderson continuity correction" _newline
         } 
       noisily: di as text "        z1 = " as res %-8.4g `z1' as text _col(38) "z2 = " as res %-8.4g `z2' _newline
       noisily: di as text "   Ho1: Du-diff >= 0" _col(33) "Ho2: diff-Dl <= 0"
       noisily: di as text "   Ha1: Du-diff < 0"  _col(33) "Ha2: diff-Dl > 0"
       noisily: di as text "   Pr(Z > z1) = " as res %6.4f `p1' _col(32) as text " Pr(Z > z2) = " as res %6.4f `p2'
       }
     }
   if lower("`eqvtype'") == "epsilon" {
     if "`by'" == "" {
       noisily: di as text "        diff = prop(" as res "`varlist'" as text ") - prop(" as res "`exp'" as text ") = "  as res `m1' - `m2'     
       }
     if "`by'" != "" {
       noisily: di as text "        diff = prop(`varlist'|`by' = " as res "`name1'" as text ") - prop(`varlist'|`by' = " as res "`name2'" as text ")"     
       noisily: di as text "             = " as res `m1' - `m2'     
       }
     if (`upper' == `lower') {
       noisily: di as text "     epsilon = " as res %-8.4f `lower' as res "epsilon " as text "expressed in units of the z distribution"
       }
     if (`upper' != `lower') {
       noisily: di as text "epsilon (el) = " as res %-8.4f -1*`lower' as text " " as res "el" as text " expressed in units of the z distribution"
       noisily: di as text "epsilon (eu) = " as res %-8.4f `upper' as text " " as res "eu" as text " expressed in units of the z distribution"
       }
     local criticalvalue = invnormal(`level'/100)
     if (`upper' == `lower' & `lower' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if epsilon <= z-crit (" %-5.3f `criticalvalue' "). See{help tostpr##mineqvlevel: help tostpr}."
       }
     if (`upper' != `lower' & `lower' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if |el| <= z-crit (" %-5.3f `criticalvalue' "). See{help tostpr##mineqvlevel: help tostpr}."
       }
     if (`upper' != `lower' & `upper' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if eu <= z-crit (" %-5.3f `criticalvalue' "). See{help tostpr##mineqvlevel: help tostpr}."
       }
     if (`upper' == `lower') {
       noisily: di _newline as text "Ho: |z| >= epsilon:" _newline 
       if ("`yates'" != "") {
         noisily: di as text "Using the Yates continuity correction" _newline
         } 
       if ("`ha'" != "") {
         noisily: di as text "Using the Hauck-Anderson continuity correction" _newline
         } 
       noisily: di as text "        z1 = " as res %-8.4g `z1' as text _col(38) "z2 = " as res %-8.4g `z2' _newline
       noisily: di as text "   Ho1: epsilon-z >= 0" _col(33) "Ho2: z+epsilon <= 0"
       noisily: di as text "   Ha1: epsilon-z < 0"  _col(33) "Ha2: z+epsilon > 0"
       noisily: di as text "   Pr(Z > z1) = " as res %6.4f `p1' _col(32) as text " Pr(Z > z2) = " as res %6.4f `p2'
       }
     if (`upper' != `lower') {
       noisily: di _newline as text "Ho: z <= el, or z >= eu:" _newline 
       if ("`yates'" != "") {
         noisily: di as text "Using the Yates continuity correction" _newline
         } 
       if ("`ha'" != "") {
         noisily: di as text "Using the Hauck-Anderson continuity correction" _newline
         } 
       noisily: di as text "        z1 = " as res %-8.4g `z1' as text _col(38) "z2 = " as res %-8.4g `z2' _newline
       noisily: di as text "   Ho1: eu-z >= 0" _col(33) "Ho2: z-el <= 0"
       noisily: di as text "   Ha1: eu-z < 0"  _col(33) "Ha2: z-el > 0"
       noisily: di as text "   Pr(Z > z1) = " as res %6.4f `p1' _col(32) as text " Pr(Z > z2) = " as res %6.4f `p2'
       }
     }
   }


*******************************************************************************
* Program end. Close up shop and return things.                               *
*******************************************************************************

  }

 capture confirm number `exp'
 if (`upper' == `lower') {
   if "`eqvtype'" == "delta" {
     return scalar Delta   = `eqvlevel'
     }
   if "`eqvtype'" == "epsilon" {
     return scalar epsilon   = `eqvlevel'
     }
   }
 if (`upper' != `lower') {
   if "`eqvtype'" == "delta" {
     return scalar Dl   = `lower'
     return scalar Du   = `upper'
     }
   if "`eqvtype'" == "epsilon" {
     return scalar el   = `lower'
     return scalar eu   = `upper'
     }
   }
 return scalar N_1     = `n1'
 return scalar P_1     = `m1'
 if _rc != 0 {
   return scalar N_2   = `n2'
   return scalar P_2   = `m2'
   }
 return scalar z1      = `z1'
 return scalar z2      = `z1'
end

program define _prtest1
 local name = abbrev(`"`1'"', 12)
 local n "`2'"
 local mean "`3'"
 local se "`4'"
 local level "`5'"
 local show = "`6'" 
 if `n' == 1 | `n' >= . {
   local se = .
   }
 local beg = 13 - length(`"`name'"')
 if "`show'" != "" {
   local z z
 	 local zp P>|z| 
   }
 local cil `=string(`level')'
 local cil `=length("`cil'")'
 noisily: di in smcl as text "{hline 13}{c TT}{hline 64}"
 noisily: di in smcl as text "    Variable {c |}" /*
 */ _col(22) "Mean" _col(29) /*
 */ "Std. Err." _col(44) "`z'" _col(49) /*
 */ "`zp'" _col(`=61-`cil'') `"[`=strsubdp("`level'")'% Conf. Interval]"'
 noisily: di in smcl as text "{hline 13}{c +}{hline 64}"
 local vval = (100-(100-`level')/2)/100
 noisily: di in smcl as text _col(`beg') `"`name'"' /*
 */ as text _col(14) "{c |}" as res /*
 */ _col(17) %9.0g  `mean'   /*
 */ _col(28) %9.0g  `se'     /*
 */ _col(58) %9.0g  `mean'-invnorm(`vval')*`se'   /*
 */ _col(70) %9.0g  `mean'+invnorm(`vval')*`se'
 end

program define _prtest2
 local name = abbrev(`"`1'"', 12)
 local n "`2'"
 local mean "`3'"
 local se "`4'"
 if `n' == 1 | `n' == . {
   local se = .
   }
 local level "`5'"
 local vval = (100 - (100-`level')/2)/100
 noisily: di in smcl as text %12s `"`name'"' " {c |}" as res /*
 		*/ _col(17) %9.0g  `mean'   /*
		*/ _col(28) %9.0g  `se'     /*
		*/ _col(58) %9.0g  `mean'-invnorm(`vval')/*
		*/ *`se'   /*
		*/ _col(70) %9.0g  `mean'+invnorm(`vval')*`se'
 end

exit

