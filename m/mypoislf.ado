*! version 1.0 10Dec1997 Joseph Hilbe   STB-45 sg91
program define mypoislf
   local lnf "`1'"
   local I "`2'"
   local depvar="$S_mldepn"
   if "$S_mloff" != "" {    /* adjust for offset if specified */
      tempvar Io
      qui gen double `Io' = `I' + $S_mloff
   }
   else  local Io "`I'"
   quietly replace `lnf'= -exp(`Io')+`depvar'*`Io' -lngamma(`depvar'+1)
end
