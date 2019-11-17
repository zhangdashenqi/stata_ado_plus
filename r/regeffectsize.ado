*! version 2.1 - pbe - 3/16/13 - vce(ols) only
*! version 1.1 - pbe - 8/16/10 - more space for variable names
*! version 1.0 - pbe - 1/21/09
program define regeffectsize
version 9.0
  syntax [, help]
  if "`e(cmd)'"~="regress" {
    display as err "regress not found"
    exit
  }
  if "`e(vce)'"~="ols" {
    display as err "regeffectsize does not work with robust, cluster, bootstrap or jacknife standard errors"
    exit
  }
  local mss  = e(mss)
  local rss  = e(rss)
  local dfr  = e(df_r)
  local mrsq = e(r2)
  local mse  = `rss'/`dfr'
  local dvar = e(depvar)
  local xvars : colfullnames e(b)
  local xcount = wordcount("`xvars'") -1
  display
  display as txt "Regression Effect Size"
  display
  display as txt _column(44) "% change"
  display as txt "variable" _column(30) "eta^2" _column(45) "eta^2" _column(55) "partial eta^2"
  
  forvalues i=1/`xcount' {
    local xname = word("`xvars'",`i')
    quietly test `xname'
    local F    = r(F)
    local ss   = `F'*`mse'
    local spe2 = `ss'/(`rss'+`mss')
    local pct  = `spe2'/`mrsq'*100
    local pe2  = `ss'/(`ss'+`rss')
    display as txt "`xname' " as res _column(29) `spe2' _column(43) `pct'  _column(57) as res `pe2'
  }
  if "`help'"!="" {
    display
    display as txt "-regeffectsize- help"
    display as txt "        eta^2 -- Eta squared is the proportion of the total variance that is" 
    display as txt "                 attributed to an effect."
    display as txt "partial eta^2 -- Partial eta squared is the proportion of effect + error" 
    display as txt "                 variance that is attributable to the effect. The formula" 
    display as txt "                 differs from the eta squared formula in that the denominator" 
    display as txt "                 includes the SSeffect plus the SSerror rather than the SStotal." 
  }

end

