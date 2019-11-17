program define prcmp0
*! version 1.0.0     <JRG;01Sep98>    STB-47 sg101
** do the base calculations for paired comparisons of means,
**    but only if necessary
*  Syntax:  prcmp0 `varlist' `weight' `if'`in'
   version 5.0

   local a "`*'"
   qui cap assert colsof(PrCmp0) == 3
   local i = _rc + ("$PrCmp0" != "`a'") + ("$PrCmp0K" == "")
   if !(`i') {
      local t1 = rowsof(PrCmp0)
      qui oneway `a'
      local i = sqrt(_result(4)/_result(5)) != PrCmp0[`t1',3]
   }
   if !(`i') { exit }
   quietly {
      tempvar use
      local y "`1'"
      local x "`2'"
      mac shift 2
      local wt "`1'"
      if "`1'" != "[]" { local wt "`1'`2'" }
      mark `use' `*'
      markout `use' `y' `x'
      count if `use'
      if !_result(1) { error 2000 }
      preserve
      keep if `use'
      macro drop PrCmp*
      oneway `y' `x' `wt'   , tab
      local R = _result(3) + 2
      matrix PrCmp0 = J(`R', 3, 0)
      matrix PrCmp0[`R', 1] = _result(5)
      matrix PrCmp0[`R', 3] = sqrt(_result(4)/_result(5))
      tempvar key
      sort `x'
      by `x': gen byte `key' = (_n < _N)
      sort `key' `x'
      local lbl : value label `x'
      tempvar ym xl xi
      gen str8 `xl' = ""
      gen double `ym' = .
      gen int `xi' = _n
      local i 1
      while `i' < `R' {
         local xI = `x'[`i']
         summ `y' `wt' if `x' == `xI'
         matrix PrCmp0[`i', 1] = _result(1) - 1
         matrix PrCmp0[`i', 2] = _result(3)
         matrix PrCmp0[`i', 3] = sqrt( _result(4)/_result(1) )

         global PrCmp0K "${PrCmp0K}`xI' "
         global PrCmp0N "${PrCmp0N}`i' "
         replace `ym' = _result(3) in `i'
         if "`lbl'" != "" {
            local L : label `lbl' `xI'
            replace `xl' = "`L'" in `i'
         }
         local i = `i' + 1
      }
      nobreak {
         local R = `R' - 1
         X `ym' `R' `xi' PrCmp0M
         if "`lbl'" != "" { X `xl' `R' `xi' PrCmp0L }
         else { global PrCmp0L "$PrCmp0N" }
         matrix rownames PrCmp0 = $PrCmp0K AOV_RMSE
         matrix colnames PrCmp0 = df Mean SE
         global PrCmp0X "$PrCmp0L $PrCmp0M"
         macro drop PrCmp0L PrCmp0M PrCmp0N
         global PrCmp0 "`a'"
      }
   }
end


program define X
   global `4'
   sort `1' in 1/`2'
   local i 0
   while `i' < `2' {
      local i = `i' + 1
      local a = `3'[`i']
      global `4' "${`4'}`a' "
   }
end
