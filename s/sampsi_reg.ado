*! Date        : 2 June 2011
*! Version     : 1.02
*! Authors     : Adrian Mander
*! Email       : adrian.mander@mrc-bsu.cam.ac.uk
*!
*! Sample size calculations for linear regression

/*
version 1.01 16Oct07   Trying to correct the limitations of command .. I haven't finished this
version 1.02 2Jun11    Found an error with function

*/

prog def sampsi_reg, rclass
version 9.0
syntax [varlist] [, NULL(real 0) ALT(real 0.5) N1(real 100) SD1(real 1) Alpha(real 0.05) Power(real 0.9) ////
Solve(string) ONESIDED  SX(real 1) SY(real 1) VARmethod(string) YXCORR(real 0.75) ]

/*
 Set two defaults :
  1) that the residual SD is SD1()
  2) that we are solving for n

Problem
sampsi_reg, null(0) alt(5) sx(0.5) sy(12.3)
sampsi_reg, null(0) alt(22.6) sy(16.7) varmethod(sdy)
*/

if ((`alt'*`alt'*`sx'*`sx')>(`sy'*`sy')) {
  di "{error}Warning alt^2 * Sx^2 > Sy^2!)"
  di "{res}     alt^2 * Sx^2 ="`alt'*`alt'*`sx'*`sx'
  di "             Sy^2 ="`sy'*`sy'
  exit(196)
}

if "`varmethod'"=="" local varmethod "res"
if "`solve'"=="" local solve "n"

/*
 Need to calculate the residual variance 
 EITHER by 
*/

if "`varmethod'"~="sdy" & "`sy'"~="1" {
  di "{error}Warning: If you have specified the variance of the Y's then you should use the {res}varmethod(sdy) {err}option"
  exit(196)
}

if "`varmethod'"=="res" local sres = `sd1'
if "`varmethod'"=="sdy" local sres = sqrt(`sy'^2-(`alt'-`null')^2*`sx'^2)
if "`varmethod'"=="r" local sres = (`alt'-`null')*`sx'*sqrt( (1/`yxcorr'^2)-1 )

if "`onesided'"~="" local localalpha = `alpha'
else local localalpha = `alpha'/2

if "`solve'"=="n" {
  /* Calculate the sample size */
  local temp 0
  local oldn 10
  local niter 1
  local relaxiter 0
  while abs(`temp'-`oldn')>`relaxiter' {
    local t1 = invttail(`oldn'-2, 1-`power')
    local t2 = invttail(`oldn'-2, `localalpha')
    local newn = ( (`t1'+`t2')^2 * `sres'^2 )/( (`alt'-`null')^2*`sx'^2 )
    local temp = `oldn'
    local oldn = int(`newn')+1
    if `niter'>2000 {
      di as error "Over 2000 iterations in sampsi_reg and still no solution"
      di "{error}Warning alt^2 * Sx^2 ~= Sy^2!)"
      di "{res}     alt^2 * Sx^2 ="`alt'*`alt'*`sx'*`sx'
      di "             Sy^2 ="`sy'*`sy'
      di "{error}Please lower sx or increase alt or increase sy"
      exit(198)
    }
    if `niter++'>100 local relaxiter 1
  }

  di
  di as text "Estimated sample size for linear regression
  di "Test Ho: slope alt = slope null, usually null slope is 0
  di "Assumptions:"
  di
  if "`oneside'"==""  di as text "          Alpha = " as res %9.4f `alpha' as text "  (two-sided)"
  else  di as text "          Alpha = " as res %9.4f `alpha' as text "  (one-sided)"
  di as text "          Power = " as res %9.4f `power'
  di as text "     Null Slope = " as res %9.4f `null'
  di as text "      Alt Slope = " as res %9.4f `alt'
  di as text "    Residual sd = " as res %9.4f `sres'
  di as text "      SD of X's = " as res %9.4f `sx'
  if "`varmethod'"=="sdy"   di as text "      SD of Y's = " as res %9.4f `sy'
  if "`varmethod'"=="r"   di as text   "Corr(Y's & X's) = " as res %9.4f `yxcorr'
  di
  di
  di as text "Estimated required sample size:"
  di
  di "          n = " as res `oldn'

  return local power=`power'
  return local N_1 =`oldn'
  return local N_2 =`oldn'
}

/* Calculate the power */
if "`solve'"=="power" {

  local t = invttail(`n1'-2, 1-`localalpha')
  local delta = ((`alt'-`null')*`sx')/`sres'
  local power = ( ttail(`n1'-2, `delta'*sqrt(`n1')-`t' )  + ttail(`n1'-2, -1*`delta'*sqrt(`n1')-`t' ))

  di
  di as text "Estimate power for linear regression
  di "Test Ho: Alt. Slope = Null Slope, usually Null Slope is 0
  di
  di "Assumptions:"
  di
  if "`oneside'"==""  di as text "          Alpha = " as res %9.4f `alpha' as text "  (two-sided)"
  else  di as text "          Alpha = " as res %9.4f `alpha' as text "  (one-sided)"
  di as text "              N = " as res %9.4f `n1'
  di as text "     Null Slope = " as res %9.4f `null'
  di as text "      Alt Slope = " as res %9.4f `alt'
  di as text "    Residual sd = " as res %9.4f `sres'
  di as text "      SD of X's = " as res %9.4f `sx'
  if "`varmethod'"=="sdy"   di as text "      SD of Y's = " as res %9.4f `sy'
  if "`varmethod'"=="r"   di as text   "Corr(Y's & X's) = " as res %9.4f `yxcorr'
  di
  di
  di as text "Estimated power:"
  di
  di "       Power = " as res `power'

  return local power=`power'
  return local N_1 =`n1'
  return local N_2 =`n1'


}



end

