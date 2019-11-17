*! version 1.1 - pbe, xc - 29oct08
capture program drop rregfit
program define rregfit, rclass
version 8.2
syntax [, TUne(real 7)]

if e(cmd)~="rreg" {
  display as err "last rreg model not found"
  exit
}

tempvar resid absdev yhat ybar1 ybar2 rho_1 rho_2 psi psip
tempname rreg

quietly estimates store rreg
quietly rreg `e(depvar)' if e(sample)
quietly local mest = _b[_cons]

quietly estimates restore rreg

/* get name of dv */
local dv = e(depvar)

/* get predicted and residuals */
quietly predict double `yhat' if e(sample)
quietly predict double `resid' if e(sample), resid

/* default value for c = 4.685 */
local c = `tune'*4.685/7

/* scale parameter following rreg definition*/
quietly sum `resid' if e(sample), detail
quietly gen double `absdev' = abs(`resid'-r(p50)) if e(sample)
quietly sum `absdev', detail
local scale = r(p50)/.6745

quietly gen double `ybar1' = abs(`dv'-`mest')/`scale' if e(sample)
quietly gen double  `rho_1' = (`c')^2/6*(1 - (1-(`ybar1'/`c')^2)^3) if e(sample)
quietly replace `rho_1' = (`c')^2/6 if `ybar1'>=`c' & e(sample)

quietly gen double `ybar2' = abs(`resid')/`scale' if e(sample)
quietly gen double `rho_2' = (`c')^2/6*(1 - (1-(`ybar2'/`c')^2)^3) if e(sample)
quietly replace `rho_2' = (`c')^2/6 if `ybar2'>=`c' & e(sample)

quietly sum `rho_1', meanonly
local rho1=r(mean)
quietly sum `rho_2', meanonly
local rho2=r(mean)
local rregr2=(`rho1' - `rho2')/`rho1'

quietly sum `rho_2'
local deviance = 2*(`scale')^2*r(sum)
local bicr = 2*r(sum)+(e(df_m)+1)*ln(e(N))
local aicr = 2*r(sum)

quietly gen double `psi' = ((`resid'/`scale')*(1-(`ybar2'/`c')^2)^2)^2 if e(sample)
quietly replace `psi' = 0 if abs(`resid')>`c'*`scale' & e(sample)
quietly gen double `psip' = (1-(`ybar2'/`c')^2)*(1-5*(`ybar2'/`c')^2) if e(sample)
quietly replace `psip' = 0 if abs(`resid')>`c'*`scale' & e(sample)
quietly sum `psi', meanonly
local mpsi = r(mean)
quietly sum `psip', meanonly
local mpsip = r(mean)
local aicr = `aicr'+2*`mpsi'/`mpsip'*(e(df_m)+1)

display
display as txt "robust regression measures of fit"
display as txt "R-square = " as res `rregr2'
display as txt "AICR     = " as res `aicr'
display as txt "BICR     = " as res `bicr'
display as txt "deviance = " as res `deviance'

return scalar scale_factor = `scale'
return scalar deviance = `deviance'
return scalar aicr = `aicr'
return scalar bicr = `bicr'
return scalar R2 = `rregr2'

quietly drop _est_rreg
end
