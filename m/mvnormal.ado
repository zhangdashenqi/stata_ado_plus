*! Date    : 21 September 2015
*! Version : 1.5
*! Authors : Michael J. Grayling & Adrian P. Mander

/*
  16/04/15 v1.0 Basic version complete
  01/06/15 v1.1 Extended to use variable re-ordering
  16/09/15 v1.3 Changed to use binormal() for 2-dimensional case
  20/09/15 v1.4 Removed dependency on integrate() being pre-installed and
                tailored integration to our particular requirements
  21/09/15 v1.5 Removed all dependency on numerical integration and made small
                changes for improved efficiency                  
*/

program define mvnormal, rclass
version 11.0
syntax , LOWer(numlist miss) UPPer(numlist miss) MEan(numlist) ///
         Sigma(string) [SHIfts(integer 12) SAMples(integer 1000) ALPha(real 3)]

// Perform checks on input variables
if (colsof(`sigma') ~= rowsof(`sigma')) {
  di "{error} Covariance matrix Sigma (sigma) must be square."
  exit(198)
}
local lenlower:list sizeof lower
local lenupper:list sizeof upper
local lenmean:list sizeof mean
if (`lenlower' ~= `lenupper') {
  di "{error} Vector of lower limits (lower) and vector of upper limits (upper) must be of equal length."
  exit(198)
}
if (`lenlower' ~= `lenmean') {
  di "{error} Mean vector (mean) and vector of lower limits (lower) must be of equal length."
  exit(198)
}
if (`lenmean' ~= colsof(`sigma')) {
  di "{error} Mean vector (mean) must be the same length as the dimension of covariance matrix Sigma (sigma)."
  exit(198)
}
if (`lenmean' > 100) {
  di "{error} Only multivariate normal distributions of dimension up to 100 are supported."
  exit(198)
}
forvalues i = 1/`lenlower' {
  local loweri:word `i' of `lower'
  local upperi:word `i' of `upper'
  if ((`loweri' != .) & (`upperi' != .)) {
    if (`loweri' >= `upperi') {
      di "{error} Each lower integration limit (in lower) must be strictly less than the corresponding upper limit (in upper)."
      exit(198)
    }
  }
}
mat C = cholesky(`sigma')
if (_rc > 0) {
  di "{error} Covariance matrix Sigma (sigma) must be symmetric positive-definite."
  exit(198)
}
if (`shifts' < 1) {
  di "{error} Number of shifts of the Quasi-Monte-Carlo integration algorithm to use (shifts) must be a strictly positive integer."
  exit(198)
}
if (`samples' < 1) {
  di "{error} Number of samples to use in each shift of the Quasi-Monte-Carlo integration algorithm (samples) must be a strictly positive integer."
  exit(198)
}
if (`alpha' <= 0) {
  di "{error} Chosen Monte-Carlo confidence factor (alpha) must be strictly positive."
  exit(198)
}

// Set up matrices to pass to mata
local matalower ""
foreach l of local lower{
  if "`matalower'" == "" local matalower "`l'"
  else local matalower "`matalower',`l'"
}
mat lower = (`matalower')
local mataupper ""
foreach l of local upper{
  if "`mataupper'" == "" local mataupper "`l'"
  else local mataupper "`mataupper',`l'"
}
mat upper = (`mataupper')
local matamean ""
foreach l of local mean{
  if "`matamean'" == "" local matamean "`l'"
  else local matamean "`matamean',`l'"
}
mat mean = (`matamean')
mat sigma = (`sigma')


// Compute the value of the integral and estimated error in mata and return
// the results
mata: mvn(`shifts', `samples', `alpha')
mat returnmatrix = returnmatrix
return local Integral = returnmatrix[1, 1]
return local Error = returnmatrix[1, 2]
di "{txt}Integral = {res}" returnmatrix[1, 1]
di "{txt}Error = {res}" returnmatrix[1, 2]
end

// Start of mata
mata:

void mvn(M, N, alpha)
{
  // Acquire required stata variables
  lower = st_matrix("lower")
  upper = st_matrix("upper")
  mean  = st_matrix("mean")
  Sigma = st_matrix("sigma")
  // Initialise all required variables
  k = rows(Sigma)
  // If we're dealing with the univariate or bivariate normal case use the
  // standard functions
  if (k == 1) {
    if (lower == .) {
	  lower = -8e+307
	}
	if (upper == .) {
	  upper = 8e+307
	}
    I = normal((upper - mean)/sqrt(Sigma)) - normal((lower - mean)/sqrt(Sigma))
    E = 0
  }
  else if (k == 2) {
    for (i = 1; i <= 2; i++) {
	  if (lower[i] == .) {
	    lower[i] = -8e+307
	  }
	  if (upper[i] == .) {
	    upper[i] = 8e+307
	  }
	}
	I = binormal((upper[1] - mean[1])/sqrt(Sigma[1, 1]),
	             (upper[2] - mean[2])/sqrt(Sigma[2, 2]),
	             Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2])) +
		  binormal((lower[1] - mean[1])/sqrt(Sigma[1, 1]),
				   (lower[2] - mean[2])/sqrt(Sigma[2, 2]),
				   Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2])) -
		    binormal((upper[1] - mean[1])/sqrt(Sigma[1, 1]),
			  	     (lower[2] - mean[2])/sqrt(Sigma[2, 2]),
				     Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2])) -
			  binormal((lower[1] - mean[1])/sqrt(Sigma[1, 1]),
				       (upper[2] - mean[2])/sqrt(Sigma[2, 2]),
				       Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2]))	   
	E = 0
  }
  // If we're dealing with an actual multivariate case then use the
  // Quasi-Monte-Carlo Randomised-Lattice Separation-Of-Variables method
  else if (k > 2) {
    // Algorithm is for the case with 0 means, so adjust lower and upper
    // and then re-order variables for maximum efficiency
    a         = lower - mean
    b         = upper - mean
    C         = J(k, k, 0)
    y         = J(1, k - 1, 0)  
    atilde    = J(1, k - 1, 0)
    btilde    = J(1, k - 1, 0)
    atilde[1] = a[1]
    btilde[1] = b[1]
    // Loop over each column of Sigma
    for (i = 1; i <= k - 1; i++) {
      // Determine variate with minimum expectation
	  args = J(1, k - i + 1, 0)
      for (j = 1; j <= k - i + 1; j++){
        s = j + i - 1
	    if (i > 1) {
	      if ((a[s] ~= .) & (b[s] ~= .)) {
		    args[j] = normal((b[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                               sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2))) -
                        normal((a[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                                 sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2)))
          }
          else if ((a[s] == .) & (b[s] ~= .)) {
	        args[j] = normal((b[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                               sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2))) 
          }
          else if ((b[s] == .) & (a[s] ~= .)) {
  	        args[j] = 1 - normal((a[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                                   sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2)))
          }
          else if ((a[s] == .) & (b[s] == .)) {
	        args[j] = 1
          }
        } 
        else {
          if ((a[s] ~= .) & (b[s] ~= .)) {
            args[j] = normal(b[s]/sqrt(Sigma[1, 1])) -
                        normal(a[s]/sqrt(Sigma[1, 1])) 
          }
          else if ((a[s] == .) & (b[s] ~= .)) {
            args[j] = normal(b[s]/sqrt(Sigma[1, 1])) 
          }
          else if ((b[s] == .) & (a[s] ~= .)) {
            args[j] = 1 - normal(a[s]/sqrt(Sigma[1, 1])) 
          }
          else if ((a[s] == .) & (b[s] == .)) {
            args[j] = 1
          }
        }
      }
      minindex(args, 1, ii, ww)
      m = i - 1 + ii[1]
      // Change elements m and i of a, b, Sigma and C
      tempa    = a
      tempb    = b
      tempa[i] = a[m]
      tempa[m] = a[i]
      a        = tempa
      tempb[i] = b[m]
      tempb[m] = b[i]
      b        = tempb
      tempSigma          = Sigma
      tempSigma[i, 1::k] = Sigma[m, 1::k]
      tempSigma[m, 1::k] = Sigma[i, 1::k]
      Sigma              = tempSigma
      Sigma[1::k, i]     = tempSigma[1::k, m]
      Sigma[1::k, m]     = tempSigma[1::k, i]
      if (i > 1){
        tempC          = C
        tempC[i, 1::k] = C[m, 1::k]
        tempC[m, 1::k] = C[i, 1::k]
        C              = tempC
        C[1::k, i]     = tempC[1::k, m]
        C[1::k, m]     = tempC[1::k, i]
        // Compute next column of C and next value of atilda and btilda
        C[i, i]        = sqrt(Sigma[i, i] - sum(C[i, 1::(i - 1)]:^2))
        for (s = i + 1; s <= k; s++){
          C[s, i]      = (Sigma[s, i] - sum(C[i, 1::(i - 1)]:*C[s, 1::(i - 1)]))/
                           C[i, i]
        }
        atilde[i]      = (a[i] - sum(C[i, 1::(i - 1)]:*y[1::(i - 1)]))/C[i, i]
        btilde[i]      = (b[i] - sum(C[i, 1::(i - 1)]:*y[1::(i - 1)]))/C[i, i]
      } else {
        C[i, i]        = sqrt(Sigma[i, i])
        C[2::k, i]     = Sigma[2::k, i]/C[i, i]
      }
      // Compute next value of y using integrate
      y[i]  = (normalden(atilde[i]) - normalden(btilde[i]))/
                (normal(btilde[i]) - normal(atilde[i]))
    }
    // Set the final element of C
    C[k, k] = sqrt(Sigma[k, k] - sum(C[k, 1::(k - 1)]:^2))
    // List of the first 100 primes to use in the integration algorithm
    p = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67,
         71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139,
         149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223,
         227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293,
         307, 311, 313, 317, 331, 337, 347, 349, 353, 359, 367, 373, 379, 383,
         389, 397, 401, 409, 419, 421, 431, 433, 439, 443, 449, 457, 461, 463,
         467, 479, 487, 491, 499, 503, 509, 521, 523, 541)
    // Initialise all required variables
    I   = 0
    V   = 0 
    sqp = p[1::(k - 1)]:^0.5
    d   = J(1, k, 0)
    e   = J(1, k, 1)
    f   = J(1, k, 0)
    // First elements of d, e and f are always the same
    if (a[1] ~= .) {
      d[1] = normal(a[1]/C[1, 1])
    }
    if (b[1] ~= .) {
      e[1] = normal(b[1]/C[1, 1])
    }
    f[1] = e[1] - d[1]
    // Perform M shifts of the Quasi-Monte-Carlo integration algorithm
    for (i = 1; i <= M; i++) {
      Ii = 0
      // We require k - 1 random uniform numbers
      Delta = runiform(1, k - 1)
      // Use N samples in each shift
      for (j = 1; j <= N; j++) {
        // Loop to compute other values of d, e and f
        for (l = 2; l <= k; l++) {
          y[l - 1] = invnormal(d[l - 1] +
                       abs(2*(mod(j*sqp[l - 1] + Delta[l - 1], 1)) - 1)*
                         (e[l - 1] - d[l - 1]))
          if (a[l] ~= .) {
            d[l]   = normal((a[l] - sum(C[l, 1::(l - 1)]:*y[1::(l - 1)]))/C[l, l])
          }
          if (b[l] ~= .) {
            e[l]   = normal((b[l] - sum(C[l, 1::(l - 1)]:*y[1::(l - 1)]))/C[l, l])
          }
          f[l]     = (e[l] - d[l])*f[l - 1]
        }
        Ii         = Ii + (f[k] - Ii)/j
      }
      // Update the values of the variables
      delta = (Ii - I)/i
      I     = I + delta
      V     = (i - 2)*V/i + delta^2
      E     = alpha*sqrt(V)
    }
  }
  // Return results to stata
  st_matrix("returnmatrix", (I, E))
}

end // End of mata
