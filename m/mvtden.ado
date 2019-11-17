*! Date    : 02 October 2015
*! Version : 1.1
*! Authors : Michael J. Grayling & Adrian P. Mander

/*
  16/04/15 v1.0 Basic version complete
  02/10/15 v1.1 Changed method to compute density for better stability               
*/

program define mvtden, rclass
version 11.0
syntax , x(numlist) Sigma(string) DELta(numlist) [df(integer 1)]

// Perform checks on input variables
if (colsof(`sigma') ~= rowsof(`sigma')) {
  di "{error} Scale matrix Sigma (sigma) must be square."
  exit(198)
}
local lenx:list sizeof x
local lendelta:list sizeof delta
if (`lenx' ~= `lendelta') {
  di "{error} Vector of quantiles (x) and vector of non-centrality parameters (delta) must be of equal length."
  exit(198)
}
if (`lendelta' ~= colsof(`sigma')) {
  di "{error} Vector of non-centrality parameters (delta) must be the same length as the dimension of scale matrix Sigma (sigma)."
  exit(198)
}
cap mat C = cholesky(`sigma')
if (_rc > 0) {
  di "{error} Scale matrix Sigma (sigma) must be symmetric positive-definite."
  exit(198)
}
if (`df' < 1) {
  di "{error} Degree of freedom (df) must be a positive integer."
  exit(198)
}

// Set up matrices to pass to mata
local matax ""
foreach l of local x{
  if "`matax'" == "" local matax "`l'"
  else local matax "`matax',`l'"
}
mat x = (`matax')
local matadelta ""
foreach l of local delta{
  if "`matadelta'" == "" local matadelta "`l'"
  else local matadelta "`matadelta',`l'"
}
mat delta = (`matadelta')
mat sigma = (`sigma')

// Compute the value of the density in mata and return the result
mata: dmvt(`df')
return scalar Density = returnscalar[1, 1]
di "{txt}Density = {res}" returnscalar[1, 1]
end

// Start of mata
mata:

void dmvt(df)
{
  // Acquire required stata variables
  x     = st_matrix("x")
  delta = st_matrix("delta")
  C     = st_matrix("C")
  // Initialise all required variables
  k = rows(C)
  // Compute density
  tmp        = lusolve(C, (x :- delta)')
  rss        = colsum(tmp:^2)
  logdensity = lngamma((df + k)/2) - (lngamma(df/2) + sum(log(diagonal(C))) +
                 (k/2)*log(pi()*df)) - 0.5*(df + k)*log(1 + (rss/df))
  density    = exp(logdensity)
  // Return result to stata
  st_matrix("returnscalar", density)
}

end // End of mata
