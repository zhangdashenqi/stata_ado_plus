*! version 1.5 - pbe - 3/14/11, 7/13/04, 12/11/03, 2/26/03
program define partcorr
  version 7.0
  syntax varlist [if] [in], part(varlist) [help]
  tempname r2part r2big oneminus semip partial mrsq
  
  tokenize `varlist'
  quietly regress `varlist' `if' `in'
  scalar `mrsq' =  e(r2)
  quietly regress `varlist' `part' `if' `in'
  scalar `r2big' = e(r2)
  quietly regress `1' `part' if e(sample)
  scalar `r2part' = e(r2)
  scalar `oneminus' = 1 - e(r2)

  scalar `semip' = `r2big' - `r2part'
  scalar `partial' = `semip'/`oneminus'
  display
  display as txt "       Response Variable: " as res "`1'"
  macro shift
  local rest `*'
  display as txt "   Predictor Variable(s): " as res "`rest'"
  display as txt "     Partial Variable(s): " as res "`part'"
  display as txt "           Number of obs: " as res e(N)
  display
  display as txt "                       Squared Corr Coef"
  display as txt "    Mutiple Correlation = "  `mrsq'
  display as txt "    Partial Correlation = "  `partial' 
  display as txt "Semipartial Correlation = "  `semip'

  if "`help'"~="" {
    display
    display as txt "    Mutiple correlation: correlation between predictor variable(s) and response variable."
    display as txt "    Partial correlation: part variable(s) partialed out of response and predictor variables."
    display as txt "Semipartial correlation: part variable(s) partialed out of predictor variables only."
  }
end
