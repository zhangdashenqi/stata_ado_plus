*! version 1.4.0 28feb2014 by alexis dot dinno at pdx dot edu
*! perform two one-sided t tests of mean equivalence

* Syntax:  tostti #obs1 #mean #sd1 #obs2 #mean2 #sd2 [, eqvtype(type) 
*          eqvlevel(#) uppereqvlevel(#) unequal welch level(#) ]
 
 
program define tostti

  if int(_caller())<8 {
    di in r "tostti- does not support this version of Stata." _newline
    di as txt "Requests for a v7 compatible version will be relatively easy to honor." 
    di as txt "Requests for a v6 compatible version may be less easy." 
    di as txt "Requests for a version compatible with versions of STATA earlier than v6 are "
    di as txt "untenable since I do not have access to the software." _newline 
    di as txt "All requests are welcome and will be considered."
    exit
  }
   else tostti8 `0'
end

program define tostti8, rclass
 version 8.0, missing

* a little parsing
 gettoken 1 0 : 0 , parse(" ,")
 gettoken 2 0 : 0 , parse(" ,")
 gettoken 3 0 : 0 , parse(" ,")
 gettoken 4 0 : 0 , parse(" ,")
 gettoken 5 : 0 , parse(" ,")
 if "`5'"=="" | "`5'"=="," {
   local twosample = 0
   }
 if "`5'"!="" & "`5'"!="," {
   local twosample = 1
   gettoken 5 0 : 0 , parse(" ,")
   gettoken 6 0 : 0 , parse(" ,")
   }

 syntax [, EQVType(string) EQVLevel(real 1) UPPEReqvlevel(real 0) Xname(string) /*
 */     Yname(string) UNEqual Welch Level(cilevel) ]

 quietly {

* Validate eqvtype
 if lower("`eqvtype'") == "" {
   local eqvtype = "delta"
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
   
* Validate unequal variances against Welch
 if "`welch'" != "" & "`unequal'" == "" {
   noisily: di _newline as res "welch option specified, proceeding by assuming unequal variances"
   local unequal = "unequal"
   }

* Invalidate options specified with one-sample test
 if `twosample'==0 {
   if "`welch'" != "" {
     noisily: di as err "welch option invalid for one-sample tests"
     exit 198
     } 
   if "`unequal'" != "" {
     noisily: di as err "unequal option invalid for one-sample tests"
     exit 198
     } 
   }


*******************************************************************************
* The business starts here                                                    *
*******************************************************************************

**********
* conduct the positivist t test of difference

 if `twosample'==1 {
   ttesti `1' `2' `3' `4' `5' `6', `unequal' `welch' level(`level')
   local n1 = r(N_1)
   local m1 = r(mu_1)
   local s1 = r(sd_1)
   local n2 = r(N_2)
   local m2 = r(mu_2)
   local s2 = r(sd_2)
   local n = `n1'+`n2'
   local s = r(se)
   local df = r(df_t)
   if lower("`eqvtype'") == "delta" {
     local t1 = (`upper' - (r(mu_1) - r(mu_2)))/r(se)
     local t2 = ((r(mu_1) - r(mu_2))+`lower')/r(se)
     }
   if lower("`eqvtype'") == "epsilon" {
     local t1 = `upper' - ( ( (r(mu_1) - r(mu_2)))/r(se) )
     local t2 = ( ((r(mu_1) - r(mu_2)))/r(se) ) + `lower'
     }
   local p1 = ttail(`df',`t1')
   local p2 = ttail(`df',`t2')
   }
 

**********
* one-sample t test of mean equivalence
 if `twosample'==0 {
   ttesti `1' `2' `3' `4', level(`level')
   if "`xname'" == "" {
     local xname = "x"
     }
   local n1 = r(N_1)
   local m1 = r(mu_1)
   local s1 = r(sd_1)
   local s = r(se)
   local n = r(N_1)
   local df = r(df_t)
   if lower("`eqvtype'") == "delta" {
     local t1 = (`upper' - (r(mu_1) - `4'))/r(se)
     local t2 = ((r(mu_1) - `4')+`lower')/r(se)
     }
   if lower("`eqvtype'") == "epsilon" {
     local t1 = `upper' - ( ((r(mu_1) - `4'))/r(se) )
     local t2 = ( ((r(mu_1) - `4'))/r(se) ) + `lower'
     }
   local p1 = ttail(`df',`t1')
   local p2 = ttail(`df',`t2')
   noisily: di as text _newline "One-sample t test of mean equivalence"
   noisily: _ttest header `level' `xname'
   noisily: _ttest table `level' `xname' `n1' `m1' `s1'
   if lower("`eqvtype'") == "delta" {
     noisily: _ttest divline
     if (`upper' == `lower') {
       noisily: _ttest dtable `level' "D-diff" `n' `upper'-(`m1'-`4') r(se) `df'
       noisily: _ttest dtable `level' "diff+D" `n' (`m1'-`4')+`lower' r(se) `df'
       }
     if (`upper' != `lower') {
       noisily: _ttest dtable `level' "Du-diff" `n' `upper'-(`m1'-`4') r(se) `df'
       noisily: _ttest dtable `level' "diff-Dl" `n' (`m1'-`4')+`lower' r(se) `df'
       }
     
     }
   noisily: _ttest botline
   if lower("`eqvtype'") == "delta" {
     noisily: di as text "      diff = mean(" as res "`xname'" as text ") - " as res `4' as text " = " as res `m1'-`4'    
     if (`upper' == `lower') {
       noisily: di as text " Delta (D) = " as res %-8.4f `lower' as res "Delta " as text "expressed in same units as " as res "`xname'"
       }
     if (`upper' != `lower') {
       noisily: di as text "Delta (Dl) = " as res %-8.4f -1*`lower' as res "Dl " as text "expressed in same units as " as res "`xname'"
       noisily: di as text "Delta (Du) = " as res %-8.4f `upper' as res "Du " as text "expressed in same units as " as res "`xname'"
       }
     local criticalvalue = r(se)*invttail(`df',(1-(`level'/100)))
     if (`upper' == `lower' & `lower' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if Delta <= t-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostt##mineqvlevel: help tostt}." _newline
       }
     if (`upper' != `lower' & `lower' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if |Dl| <= t-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostt##mineqvlevel: help tostt}." _newline
       }
     if (`upper' != `lower' & `upper' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if Du <= t-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostt##mineqvlevel: help tostt}." _newline
       }
     noisily: di as text "        df = " as res %-8.0g `df' as text " using `n' - 1"
     if (`upper' == `lower') {
       noisily: di as text "        df = " as res %-8.0g `df' as text " using `n' - 1"
       noisily: di _newline as text "Ho: |diff| >= Delta:" _newline 
       noisily: di as text "        t1 = " as res %-8.4g `t1' as text _col(38) "t2 = " as res %-8.4g `t2' _newline
       noisily: di as text "   Ho1: Delta-diff >= 0       " _col(33) "Ho2: diff+Delta <= 0"
       noisily: di as text "   Ha1: Delta-diff < 0" _col(33) "Ha2: diff+Delta > 0"
       noisily: di as text "   Pr(T > t1) = " as res %6.4f `p1' _col(32) as text " Pr(T > t2) = " as res %6.4f `p2'
       }
     if (`upper' != `lower') {
       noisily: di as text "        df = " as res %-8.0g `df' as text " using `n' - 1"
       noisily: di _newline as text "Ho: diff <= Dl, or dif >= Du:" _newline 
       noisily: di as text "        t1 = " as res %-8.4g `t1' as text _col(38) "t2 = " as res %-8.4g `t2' _newline
       noisily: di as text "   Ho1: Du-diff >= 0       " _col(33) "Ho2: diff-Dl <= 0"
       noisily: di as text "   Ha1: Du-diff < 0" _col(33) "Ha2: diff-Dl > 0"
       noisily: di as text "   Pr(T > t1) = " as res %6.4f `p1' _col(32) as text " Pr(T > t2) = " as res %6.4f `p2'
       }
     }
   if lower("`eqvtype'") == "epsilon" {
     noisily: di as text "        diff = mean(" as res "`xname'" as text ") - " as res `4' as text " = " as res `m1'-`4'
     if (`upper' == `lower') {
       noisily: di as text "     epsilon = " as res %-8.4f `lower' as text " " as res "`eqvtype'" as text " expressed in units of the t distribution"
       }
     if (`upper' != `lower') {
       noisily: di as text "epsilon (el) = " as res %-8.4f -1*`lower' as text " " as res "el" as text " expressed in units of the t distribution"
       noisily: di as text "epsilon (eu) = " as res %-8.4f `upper' as text " " as res "eu" as text " expressed in units of the t distribution"
       }
     local criticalvalue = invttail(`df',(1-(`level'/100)))
     if (`upper' == `lower' & `lower' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if epsilon <= t-crit (" %-5.3f `criticalvalue' "). See{help tostt##mineqvlevel: help tostt}." _newline
       }
     if (`upper' != `lower' & `lower' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if |el| <= t-crit (" %-5.3f `criticalvalue' "). See{help tostt##mineqvlevel: help tostt}." _newline
       }
     if (`upper' != `lower' & `upper' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if eu <= t-crit (" %-5.3f `criticalvalue' "). See{help tostt##mineqvlevel: help tostt}." _newline
       }
     if (`upper' == `lower') {
       noisily: di as text "          df = " as res %-8.0g `df' as text " using `n' - 1"
       noisily: di _newline as text "Ho: |t| >= epsilon:" _newline 
       noisily: di as text "        t1 = " as res %-8.4g `t1' as text _col(38) "t2 = " as res %-8.4g `t2' _newline
       noisily: di as text "    Ho1: epsilon-t >= 0       " _col(34) "Ho2: t+epsilon <= 0"
       noisily: di as text "    Ha1: epsilon-t < 0" _col(34) "Ha2: t+epsilon > 0"
       noisily: di as text "    Pr(T > t1) = " as res %6.4f `p1' _col(33) as text " Pr(T > t2) = " as res %6.4f `p2'
       }
     if (`upper' != `lower') {
       noisily: di as text "          df = " as res %-8.0g `df' as text " using `n' - 1"
       noisily: di _newline as text "Ho: t <= el, or t >= eu:" _newline 
       noisily: di as text "        t1 = " as res %-8.4g `t1' as text _col(38) "t2 = " as res %-8.4g `t2' _newline
       noisily: di as text "    Ho1: eu-t >= 0       " _col(34) "Ho2: t-el <= 0"
       noisily: di as text "    Ha1: eu-t < 0" _col(34) "Ha2: t-el > 0"
       noisily: di as text "    Pr(T > t1) = " as res %6.4f `p1' _col(33) as text " Pr(T > t2) = " as res %6.4f `p2'
       }
     }
   }


**********
* two-sample unpaired t test of mean equivalence
 if `twosample'==1 {
   if ("`unequal'" == "" & "`welch'" == "") {
     noisily: di as text _newline "Two-sample unpaired t test of mean equivalence with equal variances"
     }
   if ("`unequal'" != "" | "`welch'" != ""){
     noisily: di as text _newline "Two-sample unpaired t test of mean equivalence with unequal variances"
     }
   if "`xname'" == "" {
     local xname = "x"
     }
   if "`yname'" == "" {
     local yname = "y"
     }
   noisily: _ttest header `level' `xname'
   noisily: _ttest table `level' `xname' `n1' `m1' `s1'
   noisily: _ttest table `level' `yname'  `n2' `m2' `s2'
   noisily: _ttest divline
   local scomb = sqrt(( (`n1'-1)*(`s1')^2 + `n1'*(( (`n1'*`m1'+`n2'*`m2')/(`n1'+`n2') )-`m1')^2 + (`n2'-1)*(`s2')^2 + `n2'*(((`n1'*`m1'+`n2'*`m2')/(`n1'+`n2'))-`m2')^2)/(`n'-1))
   noisily:	_ttest table `level' "combined" (`n1'+`n2') ((`n1'*`m1'+`n2'*`m2')/(`n1'+`n2')) `scomb'
   if lower("`eqvtype'") == "delta" {
     noisily: _ttest divline
     if (`upper' == `lower') {
       noisily: _ttest dtable `level' "D-diff" `n' `upper'-(`m1'-`m2') `s' `df'
       noisily: _ttest dtable `level' "diff+D" `n' (`m1'-`m2')+`lower' `s' `df'
       }
     if (`upper' != `lower') {
       noisily: _ttest dtable `level' "Du-diff" `n' `upper'-(`m1'-`m2') `s' `df'
       noisily: _ttest dtable `level' "diff-Dl" `n' (`m1'-`m2')+`lower' `s' `df'
       }
     }
   noisily: _ttest botline
   if lower("`eqvtype'") == "delta" {
     if (`upper' == `lower') {
       noisily: di as text " Delta (D) = " as res %-8.4f `lower' as res "Delta " as text "expressed in same units as " as res "`xname'" as text " and " as res "`yname'"
       }
     if (`upper' != `lower') {
       noisily: di as text "Delta (Dl) = " as res %-8.4f -1*`lower' as res "Dl " as text "expressed in same units as " as res "`xname'" as text " and " as res "`yname'"
       noisily: di as text "Delta (Du) = " as res %-8.4f `upper' as res "Du " as text "expressed in same units as " as res "`xname'" as text " and " as res "`yname'"
       }
     local criticalvalue = r(se)*invttail(`df',(1-(`level'/100)))
     if (`upper' == `lower' & `lower' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if Delta <= t-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostt##mineqvlevel: help tostt}." _newline
       }
     if (`upper' != `lower' & `lower' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if |Dl| <= t-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostt##mineqvlevel: help tostt}." _newline
       }
     if (`upper' != `lower' & `upper' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if Du <= t-crit*s.e. ( " %-6.4g `criticalvalue' "). See{help tostt##mineqvlevel: help tostt}." _newline
       }
     }
   if lower("`eqvtype'") == "epsilon" {
     noisily: di as text "        diff = mean(" as res "`xname'" as text ") - mean(" as res "`yname'" as text ") = " as res `m1'-`m2'
     if (`upper' == `lower') {
       noisily: di as text "     epsilon = " as res %-8.4f `lower' as text " " as res "`eqvtype'" as text " expressed in units of the t distribution"
       }
     if (`upper' != `lower') {
       noisily: di as text "epsilon (el) = " as res %-8.4f -1*`lower' as text " " as res "el" as text " expressed in units of the t distribution"
       noisily: di as text "epsilon (eu) = " as res %-8.4f `upper' as text " " as res "eu" as text " expressed in units of the t distribution"
       }
     local criticalvalue = invttail(`df',(1-(`level'/100)))
     if (`upper' == `lower' & `lower' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if epsilon <= t-crit (" %-5.3f `criticalvalue' "). See{help tostt##mineqvlevel: help tostt}." _newline
       }
     if (`upper' != `lower' & `lower' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if |el| <= t-crit (" %-5.3f `criticalvalue' "). See{help tostt##mineqvlevel: help tostt}." _newline
       }
     if (`upper' != `lower' & `upper' <= `criticalvalue') {
       noisily: di _newline as res "Impossible to reject any Ho if eu <= t-crit (" %-5.3f `criticalvalue' "). See{help tostt##mineqvlevel: help tostt}." _newline
       }
     }
   if lower("`eqvtype'") == "delta" {
     if "`welch'" == "" & "`unequal'" != "" {
       noisily: di as text "        df = " as res %-8.0g `df' as text " using Satterthwaite's formula"
       }
     if "`welch'" != "" & "`unequal'" != "" {
       noisily: di as text "        df = " as res %-8.0g `df' as text " using Welch's formula"
       }
     if  "`unequal'" == "" {
       noisily: di as text "        df = " as res %-8.0g `df' as text " using `n1' + `n2' - 2"
       }
     if (`upper' == `lower') {
       noisily: di _newline as text "Ho: |diff| >= Delta:" _newline 
       noisily: di as text "        t1 = " as res %-8.4g `t1' as text _col(38) "t2 = " as res %-8.4g `t2' _newline
       noisily: di as text "   Ho1: Delta-diff >= 0       " _col(33) "Ho2: diff+Delta <= 0"
       noisily: di as text "   Ha1: Delta-diff < 0" _col(33) "Ha2: diff+Delta > 0"
       noisily: di as text "   Pr(T > t1) = " as res %6.4f `p1' _col(32) as text " Pr(T > t2) = " as res %6.4f `p2'
       }
     if (`upper' != `lower') {
       noisily: di _newline as text "Ho: diff <= Dl, or dif >= Du:" _newline 
       noisily: di as text "        t1 = " as res %-8.4g `t1' as text _col(38) "t2 = " as res %-8.4g `t2' _newline
       noisily: di as text "   Ho1: Du-diff >= 0       " _col(33) "Ho2: diff-Dl <= 0"
       noisily: di as text "   Ha1: Du-diff < 0" _col(33) "Ha2: diff-Dl > 0"
       noisily: di as text "   Pr(T > t1) = " as res %6.4f `p1' _col(32) as text " Pr(T > t2) = " as res %6.4f `p2'
       }
     }
   if lower("`eqvtype'") == "epsilon" {
     if "`welch'" == "" & "`unequal'" != "" {
       noisily: di as text "          df = " as res %-8.0g `df' as text " using Satterthwaite's formula"
       }
     if "`welch'" != "" & "`unequal'" != "" {
       noisily: di as text "          df = " as res %-8.0g `df' as text " using Welch's formula"
       }
     if  "`unequal'" == "" {
       noisily: di as text "          df = " as res %-8.0g `df' as text " using `n1' + `n2' - 2"
       }
     if (`upper' == `lower') {
       noisily: di _newline as text "Ho: |t| >= epsilon:" _newline 
       noisily: di as text "        t1 = " as res %-8.4g `t1' as text _col(38) "t2 = " as res %-8.4g `t2' _newline
       noisily: di as text "    Ho1: epsilon-t >= 0       " _col(34) "Ho2: t+epsilon <= 0"
       noisily: di as text "    Ha1: epsilon-t < 0" _col(34) "Ha2: t+epsilon > 0"
       noisily: di as text "    Pr(T > t1) = " as res %6.4f `p1' _col(33) as text " Pr(T > t2) = " as res %6.4f `p2'
       }
     if (`upper' != `lower') {
       noisily: di _newline as text "Ho: t <= el, or t >= eu:" _newline 
       noisily: di as text "        t1 = " as res %-8.4g `t1' as text _col(38) "t2 = " as res %-8.4g `t2' _newline
       noisily: di as text "    Ho1: eu-t >= 0       " _col(34) "Ho2: t-el <= 0"
       noisily: di as text "    Ha1: eu-t < 0" _col(34) "Ha2: t-el > 0"
       noisily: di as text "    Pr(T > t1) = " as res %6.4f `p1' _col(33) as text " Pr(T > t2) = " as res %6.4f `p2'
       }
     }
   }


*******************************************************************************
* Program end. Close up shop and return things.                               *
*******************************************************************************

  }

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
 return scalar mu_1    = `m1'
 if `twosample'==1 {
   return scalar N_2   = `n2'
   return scalar mu_2  = `m2'
   }
 return scalar df_t    = `df'
 return scalar t1      = `t1'
 return scalar t2      = `t1'
 return scalar p1      = `p1'
 return scalar p2      = `p2'
 return scalar se      = `s'
 return scalar sd_1    = `s1'
 if `twosample'==1 {
   return scalar sd_2  = `s2'
   }
end

