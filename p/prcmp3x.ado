program define prcmp3x
*! version 1.0.1     <JRG;28Sep98>     STB-47 sg101
** graph confidence intervals for paired comparisons of means,
** Syntax:  prcmp3x <xv1> <xv2> <yv> <xv> <Nx> <yvalu> <legend>

   version 5.0
   qui summ `1', meanonly
   local Row = _result(5)
   local Col = _result(6)
   qui summ `2', meanonly
   local row = min(`Row', _result(5))
   local col = max(`Col', _result(6))
   local v : word 2 of $PrCmp0
   local V : var lab `v'
   if "`V'" != "" { local v "`V'" }
   lab var `3' "`v'"
   local v : word 1 of $PrCmp0
   local V : var lab `v'
   if "`V'" != "" { local v "`V'" }
   local v "Difference in `v'"
   lab val `3' `6'

   gph open $PrComp_g
   gr `3' `4' in 1/`5', yreverse b2("`v'")    /*
      */ xscale(`row',`col') ylab($PrCmp3x) $PrComp_G
   local ay = _result(5)
   local by = _result(6)
   local ax = _result(7)
   local bx = _result(8)

   local v 0
   while `v' < `5' {
      local v = `v' + 1
      local Row = `3'[`v']*`ay' + `by'
      local Col = `1'[`v']*`ax' + `bx'
      local V = `2'[`v']*`ax' + `bx'
      gph line `Row' `Col' `Row' `V'
   }
   if `7' {
      local V = `row'*`ax' + `bx'
      local Row = 2*`ay' + `by'
      local Col = `col'*`ax' + `bx'
*      gph clear `by' `V' `Row' `Col'
      local Col = 0.5*(_result(3)+_result(4))*`ax' + `bx'
      local Row = `ay' + `by'
      gph pen 1
      gph font 550 275
      gph text `Row' `Col' 0 0 /*
   */ (A group of intervals pairs its level with each level above it)
   }
   gph close
end
