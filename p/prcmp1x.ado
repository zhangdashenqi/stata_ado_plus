program define prcmp1x
*! version 1.0.0     <JRG;01Sep98>   STB-47 sg101
** output standard header(s)
** Syntax: prcmp1x <1|2> <`test'>
   version 5.0

   local test "`2'"
   if `1' == 1 {
      local v "Pairwise Comparisons of Means"
      di _new in gr _dup(19) " " "`v'"  _new
      parse "$PrCmp0", parse(" ")
      local v : var lab `1'
      di in gr "Response variable (Y): `1'" _col(36) "`v'"
      local v : var lab `2'
      di in gr "Group variable (X):    `2'" _col(36) "`v'"
      mac shift 2
      if "`1'" != "[]" {
         di in gr "Weighting: " in ye "`1' `2'"
         mac shift
      }
      mac shift
      if "`1'" != "" { di in gr "<if><in> qualifier: " "`*'" }
      exit
   }
   else {
      parse "$PrCmp1", parse(" ")
      local V "Simultaneous"
      local H "(Tukey wsd method)"
      local 3 : di %9.0g `3'
      local 3 = ltrim("`3'")
      local F "Homogeneous error SD = `3', degrees of freedom = `4'"
      if "`2'" != "stdrng" {
         if "`3'" == "" {
            local F "Welch standard errors, "
            local F "`F'Satterthwaite approximate degrees of freedom"
         }
         local V "Individual"
         local H "(t method)"
      }
      local P "confidence"
      if "`test'" != "" {
         local P "significance"
         local 1 = 1 - `1'
      }
      local v : di %8.0g 100*`1'
      global PrCmp1x = ltrim("`v'")
      di _new in gr "`V' `P' level: " "$PrCmp1x" "%" _sk(4) "`H'"
      di in gr "`F'"
   }
end
