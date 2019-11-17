* updated dec 9: removed rounding
capture program drop viblmcc
program define viblmcc
  syntax varlist , [ GENerate(namelist max=1) db graph]

  quietly logit `varlist'

  gettoken y   varlist: varlist
  gettoken iv1 varlist: varlist
  local cov = "`varlist'"

  * get predicted logit when iv1 iv2 and iv12 are 0
  tempvar yhatlogit
  quietly predict `yhatlogit', xb

  * take logit minus _cons leaves contribution of remaining covariates.
  if ("`generate'"=="") {
    tempvar temp
    local generate `temp'
  }
  else {
    display "Saving covariate contribution as `generate'"
  }
  quietly gen `generate' = `yhatlogit' - (_b[_cons] + _b[`iv1']*`iv1')

  quietly centile `generate', centile(1 10 20 30 40 50 60 70 80 90 99) normal
  display as text "Percentiles for Covariate Contribution"
  display as text  %7s "P1" %7s "P10" %7s "P20" %7s "P30" %7s "P40" %7s "P50" %7s "P60" %7s "P70" %7s "P80" %7s "P90" %7s "P99"
  display as result " " %6.0g `r(c_1)' " " %6.0g `r(c_2)' " " %6.0g `r(c_3)' " " %6.0g `r(c_4)' " " %6.0g `r(c_5)' " " %6.0g `r(c_6)' " " %6.0g `r(c_7)' " " %6.0g `r(c_8)' " " %6.0g `r(c_9)' " " %6.0g `r(c_10)' " " %6.0g `r(c_11)' 

  local cclo  = `r(c_3)' // 20th percentile
  local ccmid = `r(c_6)' // 50th percentile
  local cchi  = `r(c_9)' // 80th percentile
  local b0 = _b[_cons]
  local b1 = _b[`iv1']

  local rcclo  = round(`r(c_3)',0.001) // 20th percentile
  local rccmid = round(`r(c_6)',0.001) // 50th percentile
  local rcchi  = round(`r(c_9)',0.001) // 80th percentile
  local rb0 = round(_b[_cons],0.001)
  local rb1 = round(_b[`iv1'],0.001)

  quietly summ `iv1'
  local xmin = r(min)
  local xmax = r(max)

  local rxmin = round(r(min),0.001)
  local rxmax = round(r(max),0.001)

  if "`graph'" != "" {
    di _n in white ". viblmgraph , b0(`rb0') b1(`rb1') ccat(`rcclo' `rccmid' `rcchi') xmin(`rxmin') xmax(`rxmax') xname(`iv1')"
    viblmgraph , b0(`b0') b1(`b1') ccat(`cclo' `ccmid' `cchi') xmin(`xmin') xmax(`xmax') xname(`iv1')   
  }

  if "`db'" != "" {
    viblmdb , b0(`b0') b1(`b1') ccat(`ccmid') ccmin(`cclo') ccmax(`cchi') xname(`iv1')
  }

end

