program define prcmp2x
*! version 1.0.1     <JRG;28Sep98>    STB-47 sg101
** graph tests for paired comparisons of means,
** Syntax:  prcmp2x <xv> <yv> <fr> <yvalu> <legend> <Nx>

   version 5.0

   local Row : word 2 of $PrCmp0
   local Col : variable label `Row'
   if "`Col'" == "" { local Col "`Row'" }
   lab var `1' "`Col'"
   lab var `2' "`Col'"
   lab val `1' `4'
   lab val `2' `4'
   gph open  $PrComp_g
   gr `2' `1' [fw=`3'] in 1/`6', yreverse ylab($PrCmp2x)  /*
      */    $PrComp_G
   if `5' {
      gph pen 1
      gph font 550 275
      local Row = _result(2)*_result(5) + _result(6) + 275
      local Col = _result(4)*_result(7) + _result(8)
      gph text `Row' `Col' 0 1 /*
         */ Symbol size increases with |Diff| / (Critical Diff)
      local Row = `Row' + 950
      gph text `Row' `Col' 0 1 /*
         */ Symbol size = 0 if  |Diff| / (Critical Diff) < 1
   }
   gph close
   lab drop `4'
   global PrCmp2x
end
