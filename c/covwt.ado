program define covwt, rclass

*! Version: 0.1
*! Author:  Mark Lunt
*! Date:    15 December, 2006

version 9.0

syntax varlist [if] [in] [pw fw /]

marksample touse

tempname mean covar
tempvar wt nonzero Ndashv sigmawv

local p: word count `varlist'

if "`weight'" ~= "" {
  gen `wt' = `exp'
}
else {
  gen `wt' = 1
}

quietly {
  gen `nonzero' = `wt' > 0 if `touse'
  egen `Ndashv' = sum(`nonzero')
  egen `sigmawv' = sum(`wt'*`nonzero')
  local Ndash = `Ndashv'[1]
  local sigmaw = `sigmawv'[1]
}

if "`weight'" == "pweight" {
  local denom = (`Ndash' - 1) * `sigmaw' / `Ndash'
}
else {
  local denom = `sigmaw' - 1
}

mata: covwt("`varlist'","`wt'", "`touse'", `denom')

matrix `mean' = r(mean)
matrix `covar' = r(covar)

matrix rownames `covar' = `varlist'
matrix colnames `covar' = `varlist'
matrix colnames `mean' = `varlist'


return matrix mean = `mean'
return matrix covar = `covar'

end

