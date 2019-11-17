program define prcmp3
*! version 1.0.0     <JRG;01Sep98>     STB-47 sg101
** display confidence intervals for paired comparisons of means,
** Syntax:  prcmp3 <R> <order> <list> <graph> <legend> <xlbl?>
   version 5.0

   prcmp0x `2'
   if "`6'" == "" { local lbl "*" }
   qui if `4' {
      local I = `1'*(`1'-1)/2
      if `I' > _N {
         preserve
         qui set obs `I'
      }
      tempname yvalu
      tempvar yv xv xv1 xv2
      gen int `yv' = .
      gen `xv' = .
      gen `xv1' = .
      gen `xv2' = .
      local Nx 0
      local j : word 1 of ${PrCmp0`2'}
      local Top : word `j' of $PrCmp0K
      `lbl' local Top : lab `6' `Top'
      local Delt 3
      local yh 1
      global PrCmp3x 0
      lab def `yvalu' 0 "`Top'"
   }
   if `3' {
      local i = 62 + int((16-length("$PrCmp1x"))/2)
      di _new in gr _col(`i') "${PrCmp1x}%"
      di in gr "Level(X)" _sk(4) "Mean(Y)" _sk(3) "Level(X)" /*
         */    _sk(4) "Mean(Y)" _sk(6) "Diff Mean" _sk(5)   /*
         */    "Confidence Limits" _new _dup(79) "-"
   }
   else { local Lst "*" }
   local i 1
   while `i' < `1' {
      local i = `i' + 1
      local I : word `i' of ${PrCmp0`2'}
      local v : word `I' of $PrCmp0K
      `lbl' local v : lab `6' `v'
      if `3' {
         local V = 8-length("`v'")
         di `SP' _dup(`V') " " %8.0g "`v'" "  " %9.0g    /*
               */    PrCmp0[`I',2] _con
      }
      if `4' {
         local yh = `yh' + `Delt'
         global PrCmp3x "${PrCmp3x},`yh'"
         local v = substr("`v'", 1, 8)
         lab def `yvalu' `yh' "`v'", modify
      }
      `Lst' local skp 3
      local j 1
      while `j' < `i' {
         local J : word `j' of ${PrCmp0`2'}
         if `3' {
            local v : word `J' of $PrCmp0K
            `lbl' local v : lab `6' `v'
            local V = 8-length("`v'")
            di _sk(`skp') _dup(`V') " " %8.0g "`v'" "  "    /*
                  */    %9.0g PrCmp0[`J',2] _con
         }
         local Row = max(`J',`I')
         local Col = min(`J',`I')
         local sign = 2*(`J' > `I') - 1  /* correct the sign */
         local T = `sign'*PrCmp1[`Row',`Col']
         if `3' {
            di _sk(6) %9.0g `T' _sk(3) %9.0g    /*
               */    `T'-PrCmp1[`Col',`Row']  _sk(2) %9.0g /*
               */    `T'+PrCmp1[`Col',`Row']
            local skp 22
         }
         qui if `4' {
            local Nx = `Nx' + 1
            * local A = `i' + (`j'-1)/(`1'-1)
            replace `xv' = `T' in `Nx'
            replace `yv' = `yh' in `Nx'
            replace `xv1' = `T'-PrCmp1[`Col',`Row'] in `Nx'
            replace `xv2' = `T'+PrCmp1[`Col',`Row'] in `Nx'
            local yh = `yh' + 1
         }
         local j = `j' + 1
      }
      `Lst' local SP "_new"
   }
   `Lst' di in gr _dup(79) "-"
   if `4' {
      prcmp3x `xv1' `xv2' `yv' `xv' `Nx' `yvalu' `5'
      lab drop `yvalu'
   }
   macro drop PrCmp0`2' PrCmp3x
end
