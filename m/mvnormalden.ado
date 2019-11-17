*! Date    : 02 October 2015
*! Version : 1.1
*! Authors : Michael J. Grayling & Adrian P. Mander

/*
  16/04/15 v1.0 Basic version complete
  02/10/15 v1.1 Changed method to compute density for better stability               
*/

program define mvnormalden, rclass
version 11.0
syntax , x(numlist) MEan(numlist) Sigma(string)

// Perform checks on input variables
if (colsof(`sigma') ~= rowsof(`sigma')) {
  di "{error} Covariance matrix Sigma (sigma) must be square."
  exit(198)
}
local lenx:list sizeof x
local lenmean:list sizeof mean
if (`lenx' ~= `lenmean') {
  di "{error} Vector of quantiles (x) and mean vector (mean) must be of equal length."
  exit(198)
}
if (`lenmean' ~= colsof(`sigma')) {
  di "{error} Mean vector (mean) must be the same length as the dimension of covariance matrix Sigma (sigma)."
  exit(198)
}
cap mat C = cholesky(`sigma')
if (_rc > 0) {
  di "{error} Covariance matrix Sigma (sigma) must be symmetric positive-definite."
  exit(198)
}

// Set up matrices to pass to mata
local matax ""
foreach l of local x{
  if "`matax'" == "" local matax "`l'"
  else local matax "`matax',`l'"
}
mat x = (`matax')
local matamean ""
foreach l of local mean{
  if "`matamean'" == "" local matamean "`l'"
  else local matamean "`matamean',`l'"
}
mat mean = (`matamean')
mat sigma = (`sigma')

// Compute the value of the density in mata and return the result
mata: dmvn()
return scalar Density = returnscalar[1, 1]
di "{txt}Density = {res}" returnscalar[1, 1]
end

// Start of mata
mata:

void dmvn()
{
  // Acquire required stata variables
  x    = st_matrix("x")
  mean = st_matrix("mean")
  C    = st_matrix("C")
  // Initialise all required variables
  k = rows(C)
  // Compute density
  tmp        = lusolve(C, (x :- mean)')
  rss        = colsum(tmp:^2)
  logdensity = -sum(log(diagonal(C))) - 0.5*k*log(2*pi()) - 0.5*rss
  density    = exp(logdensity)
  // Return result to stata
  st_matrix("returnscalar", density)
}

end // End of mata
