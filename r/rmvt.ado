*! Date    : 16 April 2015
*! Version : 1.0
*! Authors : Michael J. Grayling & Adrian P. Mander

program define rmvt, rclass
version 11.0
syntax , Sigma(string) DELta(numlist) [df(integer 1) n(integer 1)]

// Perform checks on input variables
if (colsof(`sigma') ~= rowsof(`sigma')) {
  di "{error} Scale matrix Sigma (sigma) must be square."
  exit(198)
}
local lendelta:list sizeof delta
if (`lendelta' ~= colsof(`sigma')) {
  di "{error} Vector of non-centrality parameters (delta) must be the same length as the dimension of scale matrix Sigma (sigma)."
  exit(198)
}
if (`n' < 1) {
  di "{error} Number of random vectors to generate (n) must be a strictly positive integer."
}
cap mat C = cholesky(`sigma')
if (_rc > 0) {
  di "{error} Scale matrix Sigma (sigma) must be symmetric positive-definite."
  exit(198)
}
if (`df' < 1) {
  di "{error} Degree of freedom (df) must be a strictly positive integer."
  exit(198)
}

// Set up matrix to pass to mata
local matadelta ""
foreach l of local delta{
  if "`matadelta'" == "" local matadelta "`l'"
  else local matadelta "`matadelta',`l'"
}
mat delta = (`matadelta')

// Compute the random vectors in mata and return the results
mata: rmvt(`df', `n')
return matrix rmvt = returnmatrix
end

// Start of mata
mata:

void rmvt(df, n)
{
  // Acquire required stata variables
  delta = st_matrix("delta")
  C     = st_matrix("C")
  // Initialise all required variables
  k = rows(C)
  // Initialise a matrix with each row the vector delta
  deltamat = J(n, k, 0)
  for (i = 1; i <= n; i++) {
    deltamat[i, 1::k] = delta
  }
  // Create a matrix of random normal variables and a vector of random chi2
  // variables
  z   = J(k, n, 0)
  rchi2 = J(n, 1, 0)
  for (i = 1; i <= n; i++) {
    for (j = 1; j <= k; j++) {
	  z[j, i] = rnormal(1, 1, 0, 1)
	}
	rchi2[i] = rchi2(1, 1, df)
  }
  // Create a matrix of random multivariate normal vectors with distribution
  // MVN(0, Sigma)
  rmvnormal = (C*z)'
  // Create a matrix of the desired multivariate t vectors with distribution
  // MVT(delta, Sigma)
  rmvt = rmvnormal:/sqrt(rchi2/df) + deltamat
  // Return result to stata
  st_matrix("returnmatrix", rmvt)
}

end // End of mata
