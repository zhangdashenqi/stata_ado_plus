*! version 2.0 pbe 1/29/11, 10/1/04, 3/14/00
program define rtab
  version 8.2
  syntax varlist [if] [in] [, SEParator(int 0) * ]
  marksample touse
  tokenize `varlist'
  preserve
  tempvar freq cfreq pct cpct
  contract `1' if `touse', f(`freq') cf(`cfreq') p(`pct') cp(`cpct')
  foreach v in freq cfreq pct cpct {
               char ``v''[varname] "`v'"
  }
  gsort -`cpct'
  list, sep(`separator') subvarname `options'
end

