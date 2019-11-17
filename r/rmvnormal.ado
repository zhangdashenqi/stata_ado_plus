*! Date    : 16 April 2015
*! Version : 1.0
*! Authors : Michael J. Grayling & Adrian P. Mander

program define rmvnormal, rclass
version 11.0
syntax , MEan(numlist) Sigma(string) [n(integer 1)]

// Perform checks on input variables
if (colsof(`sigma') ~= rowsof(`sigma')) {
  di "{error} Covariance matrix Sigma (sigma) must be square."
  exit(198)
}
local lenmean:list sizeof mean
if (`lenmean' ~= colsof(`sigma')) {
  di "{error} Mean vector (mean) must be the same length as the dimension of covariance matrix Sigma (sigma)."
  exit(198)
}
if (`n' < 1) {
  di "{error} Number of random vectors to generate (n) must be a strictly positive integer."
}
cap mat C = cholesky(`sigma')
if (_rc > 0) {
  di "{error} Covariance matrix Sigma (sigma) must be symmetric positive-definite."
  exit(198)
}

// Set up matrix to pass to mata
local matamean ""
foreach l of local mean{
  if "`matamean'" == "" local matamean "`l'"
  else local matamean "`matamean',`l'"
}
mat mean = (`matamean')

// Compute the random vectors in mata and return the results
mata: rmvn(`n')
return mat rmvnormal = returnmatrix
end

// Start of mata
mata:

void rmvn(n)
{
  // Acquire required stata variables
  mean = st_matrix("mean")
  C    = st_matrix("C")
  // Initialise all required variables
  k = rows(C)
  // Initialise a matrix with each row the vector mean
  meanmat = J(n, k, 0)
  for (i = 1; i <= n; i++) {
    meanmat[i, 1::k] = mean
  }
  // Create a matrix of random N(0,1) variables
  z = J(k, n, 0)
  for (i = 1; i <= k; i++) {
    for (j = 1; j <= n; j++) {
	  z[i, j] = rnormal(1, 1, 0, 1)
    }
  }
  // Create a matrix of random MVN vectors with distirbution MVN(mean, Sigma)
  rmvnormal = (C*z)' + meanmat
  // Return result to stata
  st_matrix("returnmatrix", rmvnormal)
}

end // End of mata
