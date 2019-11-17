program define prcmp0x
*! version 1.0.0     <JRG;01Sep98>  STB-47 sg101
** extract an ordering of X levels from $PrCmp0X
** Syntax:  prcmp0x <L|l|M|m|N|n>
   version 5.0

   if "$PrCmp0X" == "" {
      di in red "Use refresh option"
      error 499
   }
   local R : word count $PrCmp0K
   local A = upper("`1'")
   local delt = 2*("`1'" == "`A'") - 1
   local i = 1 + ("`A'"=="M")*`R' + (`delt'<0)*(`R'-1)
   if "`A'" == "N" { local nit "*" }
   else { local nat "*" }
   local c 0
   global PrCmp0`1'
   while `c' < `R' {
      local c = `c' + 1
      `nit' local A : word `i' of ${PrCmp0X}
      `nat' local A `i'
      global PrCmp0`1' "${PrCmp0`1'}`A' "
      local i = `i' + `delt'
   }
end
