program define prcmp4
*! version 1.0.0     <JRG;01Sep98>      STB-47 sg101
** display means and SEs for paired comparisons of means,
** Syntax:  <R> <order> <y> <x> <xlbl?>
   version 5.0

   prcmp0x `2'
   local A "Group variable (X): `4'"
   local B = int((31-length("`A'"))/2)
   local a "Response variable (Y): `3'"
   local b = int((31-length("`a'"))/2)
   di in gr _new _dup(`B') " " "`A'" _col(36) _dup(`b') " " "`a'"
   di in gr _dup(31) "-" _sk(4) _dup(31) "-"
   di in gr _sk(6) "Level" _sk(9) _con
   if "`5'" == "" { local B "     " }
   else { local B "Label" }
   di in gr "`B'"  _sk(14) "n" _sk(9) "Mean"  _sk(9) "S.E." /*
      */ _new _dup(66) "-"
   local i 0
   while `i' < `1' {
      local i = `i' + 1
      local I : word `i' of ${PrCmp0`2'}
      local v : word `I' of $PrCmp0K
      di _sk(2) %9.0g `v' _con
      if "`5'" != "" {
         local v : lab `5' `v'
         local V = 8-length("`v'")
         di _sk(6) _dup(`V') " "  "`v'"  _con
      }
      else { di _col(15) _con }
      di _sk(6)  %9.0g PrCmp0[`I',1]+1 _sk(4) %9.0g   /*
         */ PrCmp0[`I',2] _sk(4) %9.0g PrCmp0[`I',3]
   }
   di in gr _dup(66) "-"
   global PrCmp0`2'
end
