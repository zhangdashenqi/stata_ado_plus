* dec 9, changed rounding behavior
capture program drop viblicc
program define viblicc
  syntax varlist , [ GENerate(namelist max=1) db graph]

  quietly logit `varlist'

  gettoken y   varlist: varlist
  gettoken iv1 varlist: varlist
  gettoken iv2 varlist: varlist
  gettoken iv12 varlist: varlist
  local cov = "`varlist'"

  * get predicted logit when iv1 iv2 and iv12 are 0
  tempvar yhatlogit
  quietly predict `yhatlogit', xb

  if ("`generate'"=="") {
    tempvar temp
    local generate `temp'
  }
  else {
    display "Saving covariate contribution as `generate'"
  }

  * take logit minus _cons leaves contribution of remaining covariates.
  quietly gen `generate' = `yhatlogit' - (_b[_cons] + _b[`iv1']*`iv1' + _b[`iv2']*`iv2' + _b[`iv12']*`iv12')

  quietly centile `generate', centile(1 10 20 30 40 50 60 70 80 90 99) normal
  display as text "Percentiles for Covariate Contribution"
  display as text  %7s "P1" %7s "P10" %7s "P20" %7s "P30" %7s "P40" %7s "P50" %7s "P60" %7s "P70" %7s "P80" %7s "P90" %7s "P99"
  display as result " " %6.0g `r(c_1)' " " %6.0g `r(c_2)' " " %6.0g `r(c_3)' " " %6.0g `r(c_4)' " " %6.0g `r(c_5)' " " %6.0g `r(c_6)' " " %6.0g `r(c_7)' " " %6.0g `r(c_8)' " " %6.0g `r(c_9)' " " %6.0g `r(c_10)' " " %6.0g `r(c_11)' 

  local b0 = _b[_cons]
  local b1 = _b[`iv1']
  local b2 = _b[`iv2']
  local b12 = _b[`iv12']
  local ccmin = `r(c_3)' // 20th percentile
  local ccat  = `r(c_6)' // 50th percentile
  local ccmax = `r(c_9)' // 80th percentile

  local rb0 = round(_b[_cons],0.001)
  local rb1 = round(_b[`iv1'],0.001)
  local rb2 = round(_b[`iv2'],0.001)
  local rb12 = round(_b[`iv12'],0.001)
  local rccmin = round(`r(c_3)',0.001) // 20th percentile
  local rccat  = round(`r(c_6)',0.001) // 50th percentile
  local rccmax = round(`r(c_9)',0.001) // 80th percentile

  if "`graph'" != "" {
    di _n in white ". vibligraph , b0(`rb0') b1(`rb1') b2(`rb2') b12(`rb12') ccat(`rccat') ccmin(`rccmin') ccmax(`rccmax') x1name(`iv1') x2name(`iv2')"
    vibligraph , b0(`b0') b1(`b1') b2(`b2') b12(`b12') ccat(`ccat') ccmin(`ccmin') ccmax(`ccmax') x1name(`iv1') x2name(`iv2')
   }

  if "`db'" != "" {
    viblidb , b0(`b0') b1(`b1') b2(`b2') b12(`b12') ccat(`ccat') ccmin(`ccmin') ccmax(`ccmax') x1name(`iv1') x2name(`iv2')
  }

end

