*! Date        : 9 May 2008
*! Version     : 1.10
*! Authors     : Adrian Mander
*! Email       : adrian.mander@mrc-hnr.cam.ac.uk
*! Description : Bland-Altman plots with trend adjustment

/*
17/5/06   v1.3  add-in the middle line
6/10/06   v1.4  Handle multiple data points at the same point by using frequency option
                Also add Scatter option just to add options to the scatter part of the plot
2/9/07    v1.5  Changed version from 8 to 9.2
11/12/07  v1.6  Extended the shaded area
14/12/07  v1.7  Add limits of agreement into the info option
11/2/08   v1.8  BUGs fixed and extended the shading to the xlimits
17/4/08   v1.9  BUG fix.. the info limits were the wrong way round!
9/5/08    v1.10 Allowing shading to extend beyond data to any limit you like
*/

prog def batplot, rclass
version 9.2
syntax varlist (min=2 max=2) [if] [in] [,NOtrend INFO VALabel(varname) MOPTIONS(string asis) XLABel(numlist) SHADING(numlist min=2 max=2) SCatter(string asis) NOGraph *]
local gopt "`options'"

if "`moptions'"~="" local mopt `"moptions(`moptions')"'

preserve
tempvar touse
mark `touse' `if' `in'
markout `touse' `m1' `m2'
qui keep if `touse'

if "`xlabel'"~="" {
  local glab `"xlabel(`xlabel')"'
  local i 0
  foreach xv of local xlabel {
    if `i++'==0 local sxmin "`xv'"
    local sxmax "`xv'"
  }
  local shade "shade(`sxmin' `sxmax')"
}

/* To stop the shading going the whole length of the x-axis */
if "`shading'"~="" {
  local i 0
  foreach s of local shading {
    if `i++'==0 local smin "`s'"
    else local smax "`s'"
  }
  if `smin'<`smax' local shade "shade(`smin' `smax')"
  else local shade "shade(`smax' `smin')"
}


/* NOW do the trend version */

if "`valabel'"~="" local add "val(`valabel')"

_calctrend `varlist', `gopt' `notrend' `info' `add' `mopt' sc(`scatter') `glab' `shade' `nograph' 


  return local mean = "`r(mean)'"
  return local b0 = "`r(b0)'"
  return local b1 = "`r(b1)'"
  return local c0 = "`r(c0)'"
  return local c1 = "`r(c1)'"
  return local eqn = "`r(eqn)'"
  return local upper = "`r(upper)'"
  return local lower = "`r(lower)'"

restore
end


/* calculate trend and do a BA plot with trend */

prog def _calctrend,rclass
syntax [varlist] [,NOTREND INFO VALabel(varname) MOPTIONS(string asis) SCatter(string asis) shade(numlist) NOGraph *]
local xopt "`options'"

if "`shade'"~="" {
  local i 0
  foreach s of local shade {
    if `i++'==0 local a "`s'"
    local b "`s'"
  }
  local sxmin = `a'
  local sxmax = `b'
}


local i 1
foreach var of varlist `varlist' {
  local v`i++' "`var'"
}

tempvar av diff

qui gen `av' = (`v1' + `v2')/2 
qui gen `diff' = `v1' - `v2' 
local ytit "Difference (`v1'-`v2')"
local xtit "Average of `v1' and `v2'"

lab var `diff' "Diff"
lab var `av' "Mean"


if "`notrend'"~="" {
  qui summ `diff'
  local xbar = `r(mean)'
  local sd = `r(Var)'^.5
  local n = `r(N)'
  local se = `sd'/`n'^.5
  local t = invttail(`n'-1, .95)
  local lrr = `xbar' - invnorm(0.975)*`sd'  /* 95% lower limit of agreement */
  local urr = `xbar' + invnorm(0.975)*`sd'  /* 95% upper limit of agreement */ 
  local mrr = `xbar'                        /* 95% mean agreement */ 

  di "{text}Mean difference = {res}`mrr'"
  di "{text}Limits of agreement ({res}`lrr'{text},{res}`urr'{text})"



  local min = `r(min)'
  local max = `r(max)'
  local lcb = `xbar' - `t'*`se'
  local ucb = `xbar' + `t'*`se'
  qui summ `av'
  local xmin = `r(min)'
  local xmax = `r(max)'
  qui corr `av' `diff'
  local r = `r(rho)'
  local n = `r(N)'
  local sig = ttail(`n'-2, `r'*((`n'-2)/(1-`r'^2))^.5)

  tempvar uy ly my

/* The bit to extend the shade */

  
  local obs =`c(N)'+2
  qui set obs `obs'
  if "`sxmin'"~="" qui replace `av'=`sxmin' in `obs--'
  if "`sxmax'"~="" qui replace `av'=`sxmax' in `obs'
 

  qui gen `uy' = `urr'
  qui gen `ly' = `lrr'
  qui gen `my' = `mrr'


  sort `av'

  if "`info'"~="" {
    local te1:di %6.3f `mrr'
    local te2:di %6.3f `lrr'
    local te3:di %6.3f `urr'
 
    qui count if (`diff'>`urr' | `diff'<`lrr' ) & `diff'~=.
    local nout = `r(N)'
    qui count if `diff'~=.
    local n = `r(N)'
    local pctout : di %6.2f `nout'/`n'*100
    local xopt `"`xopt' subtitle("`nout'/`n' = `pctout'% outside the limits of agreement" "Mean difference `te1'" "95% limits of agreement (`te2',`te3')") "'
  }
  if "`valabel'"~="" {
    tempvar label
    qui gen `label' = ""
    cap confirm string variable `valabel'
    if _rc~=0 qui replace `label' = string(`valabel') if `diff'>`urr' | `diff'<`lrr'
    else qui replace `label' = `valabel' if `diff'>`urr' | `diff'<`lrr'
    local scatteropt "mlabel(`label') note(Points outside limits labelled by `valabel')"
  }

  tempvar freq
  qui bysort `diff' `av':gen  `freq'=_N
  local fopt "[fw=`freq']"
  if index("`scatter'","jitter")~=0 local fopt "" 

if "`nograph'"=="" twoway (rarea `uy' `ly' `av', bc(gs13) sort) (scatter `diff' `av' `fopt', m(o) `scatteropt' `scatter' `moptions' ) (line `my' `av',lp(dash) sort ) , ////
 legend(off) ytitle(`ytit') xtitle(`xtit') xlabel(`xmin' `xmax') `xopt'

  return local lower = `lrr'
  return local upper = `urr'
  return local mean = `mrr'
}

else {
  qui reg `diff' `av'
  local b1 = _b[`av']
  local b0 = _b[_cons]
  local sd = `e(rmse)'
  qui predict resid , resid
  qui gen absresid = abs(resid)

  /* Analysis of the residuals */

  qui reg absresid `av'
  local c0 = _b[_cons]
  local c1=_b[`av']

  qui su `diff'
  local max = `r(max)'
  local min = `r(min)'
  qui su `av'
  local xmax = r(max)
  local xmin = r(min)

  local max: di %5.3f `xmax'
  local min: di %5.3f `xmin'

  tempvar y uy ly  x

/* The bit to extend the shade */

  local obs =`c(N)'+2
  qui set obs `obs'
  if "`sxmin'"~="" qui replace `av'=`sxmin' in `obs--'
  if "`sxmax'"~="" qui replace `av'=`sxmax' in `obs'
 

  sort `av'
  qui gen `y' = `b0'+`b1'*`av' 
  qui gen `uy' = `b0'+`b1'*`av' + 2.46*(`c0'+`c1'*`av')
  qui gen `ly' = `b0'+`b1'*`av' - 2.46*(`c0'+`c1'*`av')

  if "`info'"~="" {
    qui count if (`diff'>`uy' | `diff'<`ly') & `diff'~=.
    local nout = `r(N)'
    qui count if `diff'~=.
    local n = `r(N)'
    local pctout : di %6.2f `nout'/`n'*100
    local te0 : di %5.2f `b0'
    local te1 : di %5.2f `b1'
    local te2 : di %5.2f `c0'
    local te3 : di %5.2f `c1'
    local xopt `"`xopt' subtitle("`nout'/`n' = `pctout'% outside the limits of agreement" "Mean Diff = `te0'+ `te1'*Average " "Limits +/- 2.46*(`te2' + `te3'*Average) ") "'
  }
  if "`valabel'"~="" {
    tempvar label
    qui gen `label' = ""
    cap confirm string variable `valabel'
    if _rc~=0 qui replace `label' = string(`valabel') if `diff'>`uy' | `diff'<`ly'
    else qui replace `label' = `valabel' if `diff'>`uy' | `diff'<`ly'
    local scatteropt "mlabel(`label') note(Points outside limits labelled by `valabel')"
  }

  tempvar freq
  qui bysort `diff' `av':gen  `freq'=_N
  local fopt "[fw=`freq']"
  if index("`scatter'","jitter")~=0 local fopt "" 

if "`nograph'"==""  {
   twoway (rarea `uy' `ly' `av', bc(gs13) sort)(scatter `diff' `av' `fopt', `scatteropt' `scatter') /*
*/(line `y' `av', lp(dash) sort) , legend(off) ytitle(`ytit') xtitle(`xtit') xlabel(`xmin' `xmax') `xopt'
}

  return local b0 = `b0'
  return local b1 = `b1'
  return local c0 = `c0'
  return local c1 = `c1'
  return local eqn = "`b0'+`b1'*av"
  return local upper = "`b0'+`b1'*Average + 2.46*(`c0'+`c1'*Average)"
  return local lower = "`b0'+`b1'*Average - 2.46*(`c0'+`c1'*Average)"

}

end


