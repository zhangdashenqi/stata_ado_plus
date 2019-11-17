program define prcmp1
*! version 1.0.0     <JRG;01Sep98>    STB-47 sg101
** get diff and CI half-width for paired comparisons of means,
**    but only if necessary
** Syntax:  prcmp1 <level> <t|stdrng> [<sigma> <nu>]
   version 5.0

   local a "`*'"
   qui cap assert rowsof(PrCmp0) == rowsof(PrCmp1) + 1
   if !_rc & "$PrCmp1" == "`a'" { exit }
   local R = rowsof(PrCmp0) - 1
   local c : word count `a'
   if `c' == 2 { local Eq "*" }
   else {
      local Uneq "*"
      if "`2'" == "stdrng" {
         qui qsturng `R' `4' `1'
         local A = $S_1/sqrt(2)
      }
      else { local A = invt(`4', `1') }
      local A = `A' * `3'
   }
   matrix PrCmp1 = J(`R', `R', 0)
   local i 1
   while `i' < `R' {
      local Mi = PrCmp0[`i',2]
      `Eq' local Ni = PrCmp0[`i',1] + 1
      local j = `i' + 1
      while `j' <= `R' {
         local Mj = PrCmp0[`j',2]
         `Eq' local Nj = PrCmp0[`j',1] + 1
         matrix PrCmp1[`j',`i'] = `Mi' - `Mj'
         `Eq' matrix PrCmp1[`i',`j']=`A'*sqrt((`Ni'+`Nj')/(`Ni'*`Nj'))
         `Uneq' X `i' `j' `1'
         `Uneq' matrix PrCmp1[`i',`j'] = $S_1
         local j = `j' + 1
      }
      local i = `i' + 1
   }
   matrix rownames PrCmp1 = $PrCmp0K
   matrix colnames PrCmp1 = $PrCmp0K
   global PrCmp1 "`a'"
end


program define X
   local s1 = PrCmp0[`1',3]
   local s2 = PrCmp0[`2',3]
   local s1 = `s1'*`s1'
   local s2 = `s2'*`s2'
   local v = `s1' + `s2'
   local f1 = PrCmp0[`1',1]
   local f2 = PrCmp0[`2',1]
   local nu = `v'*`v'/(`s1'*`s1'/`f1' + `s2'*`s2'/`f2')
   global S_1 = sqrt(`v') * invt(`nu', `3')
end
