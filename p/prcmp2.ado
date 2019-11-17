program define prcmp2
*! version 1.0.0     <JRG;01Sep98>    STB-47 sg101
** display and/or graph tests for paired comparisons of means,
** Syntax:  prcmp2 <R> <order> <list> <graph> <legend> <xlbl?>

   version 5.0

   prcmp0x `2'
   if !`3' { local Lst "*" }
   if "`6'" == "" { local lbl "*" }
   qui if `4' {
      local I = `1'*(`1'-1)/2
      if `I' > _N {
         preserve
         qui set obs `I'
      }
      tempname yvalu
      tempvar yv xv fr
      gen int `yv' = .
      gen int `xv' = .
      gen int `fr' = .
      local Nx 0
      local j : word 1 of ${PrCmp0`2'}
      local J : word `j' of $PrCmp0K
      `lbl' local J : lab `6' `J'
      global PrCmp2x 1
      lab def `yvalu' 1 "`J'"
   }
   local blk 7
   local iLo 1
   local jLo 0
   local jHi 0
   di ""
   while `iLo' <= `1' {
      `Lst' local I "(Row Mean - Column Mean) / (Critical Diff)"
      `Lst' di in gr _sk(10) "`I'"
      local jLo = `jHi' + 1
      local jHi = min(`1'-1, `jHi'+`blk')
      if `3' {
          di in gr "Mean(Y) |" _con
         local j `jLo'
         while `j' <= `jHi' {
            local J : word `j' of ${PrCmp0`2'}
            di in ye _sk(2) %7.0g PrCmp0[`J',2] _sk(1) _con
            local j = `j' + 1
         }
         di ""
         di in gr "Level(X)|" _con
         local j `jLo'
         while `j' <= `jHi' {
            local J : word `j' of ${PrCmp0`2'}
            local J : word `J' of $PrCmp0K
            `lbl' local J : label `6' `J'
            local v = 8 - length("`J'")
            di in gr " " _dup(`v') " "  %8.0g "`J'"   _sk(1) _con
            local j = `j' + 1
         }
         di ""
         local j = 10*(`jHi'-`jLo'+1)
         di in gr _dup(8) "-" "+" _dup(`j') "-"
      }
      local i `iLo'
      while `i' < `1' {
         local i = `i' + 1
         local I : word `i' of ${PrCmp0`2'}
         `Lst' di " " %7.0g PrCmp0[`I',2] in gr "|"  _con
         if `4' {
            global PrCmp2x "${PrCmp2x},`i'"
            local J : word `I' of $PrCmp0K
            `lbl' local J : label `6' `J'
            lab def `yvalu' `i' "`J'", modify
         }
         local j `jLo'
         local JH = min(`i'-1, `jHi')
         while `j' <= `JH' {
            local J : word `j' of ${PrCmp0`2'}
            local Row = max(`J',`I')
            local Col = min(`J',`I')
            local sign = 2*(`J' > `I') - 1
            local T = abs(PrCmp1[`Row',`Col']) / PrCmp1[`Col',`Row']
            `Lst' local S " "
            `Lst' if `T' > 1 { local S "*" }
            `Lst' di _sk(2) %7.0g `sign'*PrCmp1[`Row',`Col'] /*
                  */    in bl "`S'" _con
            qui if `4' {
               local Nx = `Nx' + 1
               replace `xv' = `j' in `Nx'
               replace `yv' = `i' in `Nx'
               if `T' > 1 {
                  replace `fr' = 2 + round(exp(`T'),1) in `Nx'
               }
            }
            local j = `j' + 1
         }
         `Lst' di ""
         if `3' {
            local v : word `I' of $PrCmp0K
            if "`6'" != "" { local v : lab `6' `v' }
            local V = 8-length("`v'")
            di in gr _dup(`V') " " "`v'" "|" _con
            local j `jLo'
            while `j' <= `JH' {
               local J : word `j' of ${PrCmp0`2'}
               local Row = max(`J',`I')
               local Col = min(`J',`I')
               di _sk(2) %7.0g PrCmp1[`Col',`Row'] " " _con
               local j = `j' + 1
            }
            di ""
            di in gr _dup(8) " " "|"
         }
      }
      local iLo = `iLo' + `blk'
   }
   if `4' { prcmp2x `xv' `yv' `fr' `yvalu' `5' `Nx' }
   global PrCmp0`2'
end
