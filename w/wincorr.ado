*! version 1.1 4/22/02
*! requires winsor.ado by N. Cox
program define wincorr, rclass
  version 7
  syntax varlist [if] [in] [, p(real 0.2)]
  marksample touse
  tokenize `varlist'
  tempvar var1 var2
  capture winsor
  if _rc==199 {
    display as err "Error: requires file winsor.ado by N. Cox" 
    exit
  }
  winsor `1' if `touse', gen(`var1') p(`p')
  winsor `2' if `touse', gen(`var2') p(`p')
  quietly corr `var1' `var2' if `touse'
  local hcount = r(N) - 2*int(`p'*r(N))
  local rdf = `hcount' - 2
  local rwt = r(rho)*sqrt((r(N)-2)/(1-r(rho)^2))
  return scalar r_df = `rdf'
  return scalar t_approx = `rwt'
  return scalar r_w = r(rho)
  return scalar N = r(N)
  display
  display as txt "winsorized correlation (proportion = " as res %4.2f `p' ")"
  display as txt "r_w(`1', `2') = " as res %6.4f r(rho) as txt "  N = " as res r(N) 
  display as txt "approximate t = " as res %6.2f `rwt' as txt "  df = " as res `rdf' /*
    */ as txt "  p-value = " as res %6.4f tprob(`rdf',`rwt')
end
