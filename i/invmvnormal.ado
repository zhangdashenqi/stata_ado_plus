*! Date    : 21 September 2015
*! Version : 1.4
*! Authors : Michael J. Grayling & Adrian P. Mander

/*
  16/04/15 v1.0 Basic version complete
  01/06/15 v1.1 Extended to use variable re-ordering
  16/09/15 v1.2 Changed to use binormal() for 2-dimensional case
  17/09/15 v1.3 Fixed bug in initial limits for interval bisection
  21/09/15 v1.4 Changed to utilise new improved code from mvnormal.ado, with no
                requirement upon integrate(). Added some code to determine a
                sensible starting interval to bisect over; most of the time this
                should lead to substantial gains in speed
*/

program define invmvnormal, rclass
version 11.0
syntax , p(real) MEan(numlist) Sigma(string) [Tail(string) ///
         SHIfts(integer 12) SAMples(integer 1000) ALPha(real 3) ///
         ITermax(integer 1000000) TOLerance(real 0.000001)] 

// Perform checks on input variables
if ((`p' <= 0) | (`p' >= 1)) {
  di "{error} Probability (p) must be between 0 and 1."
  exit(198)
} 
if (colsof(`sigma') ~= rowsof(`sigma')) {
  di "{error} Covariance matrix Sigma (sigma) must be square."
  exit(198)
}
local lenmean:list sizeof mean
if (`lenmean' ~= colsof(`sigma')) {
  di "{error} Vector of means (mean) must be the same length as the dimension of covariance matrix Sigma (sigma)."
  exit(198)
}
if (`lenmean' > 100) {
  di "{error} Only multivariate normal distributions of dimension up to 100 are supported."
  exit(198)
}
cap mat C = cholesky(`sigma')
if (_rc > 0) {
  di "{error} Covariance matrix Sigma (sigma) must be symmetric positive-definite."
  exit(198)
}
if "`tail'"=="" local tail "lower"
if (("`tail'" ~= "lower") & ("`tail'" ~= "upper") & ("`tail'" ~= "both")) {
  di "{error} tail must be set to one of lower, upper or both."
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
if (`itermax' < 1) {
  di "{error} Number of allowed iterations in the interval bisection quantile finding algorithm (itermax) must be a strictly positive integer."
  exit(198)
}
if (`tolerance' < 0) {
  di "{error} The tolerance in the interval bisection quantile finding algorithm (tolerance) must be strictly positive."
  exit(198)
}
if (`alpha' <= 0) {
  di "{error} Chosen Monte-Carlo confidence factor (alpha) must be strictly positive."
  exit(198)
}

// Set up matrices to pass to mata
local matamean ""
foreach l of local mean{
  if "`matamean'" == "" local matamean "`l'"
  else local matamean "`matamean',`l'"
}
mat mean = (`matamean')
mat sigma = (`sigma')

// Compute the value of the quantile and return the result
mata: qmvn(`p', "`tail'", `shifts', `samples', `alpha', `itermax', `tolerance')
mat returnmatrix = returnmatrix
return local Quantile = returnmatrix[1, 1]
return local Error = returnmatrix[1, 2]
return local Flag = returnmatrix[1, 3]
return local fQuantile = returnmatrix[1, 4]
return local Iterations = returnmatrix[1, 5]
di "{txt}Quantile = {res}" returnmatrix[1, 1]
di "{txt}Error = {res}" returnmatrix[1, 2]
di "{txt}Flag = {res}" returnmatrix[1, 3]
di "{txt}fQuantile = {res}" returnmatrix[1, 4]
di "{txt}Iterations = {res}" returnmatrix[1, 5]
end

// Start of mata
mata:

void qmvn(p, tail, M, N, alpha, itermax, tol)
{
  // Determine if trivial case is desired
  if ((p == 0) | (p == 1)) {
    q     = .
    error = 0
    flag  = 0
    fq    = 0
    iter  = 0
  }
  else {
    // Acquire required variables from stata
    mean  = st_matrix("mean")
    Sigma = st_matrix("sigma")
    // Initialise all required variables
    k = rows(Sigma)
    // If we're dealing with the univariate normal case use the standard
    // function
    if (k == 1) {
      if (tail == "upper") {
        p   = 1 - p
      }
      else if (tail == "both") {
        p   = 0.5 + 0.5*p
      }
      q     = invnormal(p) + mean
      error = 0
      flag  = 0
      fq    = 0
      iter  = 0
    }
    // If we're dealing with an actual multivariate case then use the
    // Quasi-Monte-Carlo Randomised-Lattice Separation-Of-Variables method,
    // along with modified interval bisection
    else {
      // List of the first 100 primes to use in randomised lattice algorithm
      primes = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59,
                61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127,
                131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193,
                197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269,
                271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349,
                353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431,
                433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503,
                509, 521, 523, 541)
      sqp = primes[1::(k - 1)]:^0.5
      // Determine sensible starting interval to bisect over
      b   = 10
	  if (tail == "both") {
	    a = 10^-6
	  }
	  else {
	    a = -10
	  }
	  fa  = qFinder(a, p, k, tail, M, N, alpha, mean, Sigma, sqp)
	  fb  = qFinder(b, p, k, tail, M, N, alpha, mean, Sigma, sqp)
	  if (fa == 0) {
	    q     = a
        error = 0
        flag  = 0
        fq    = 0
        iter  = 0
	  }
	  else if (fb == 0) {
	    q     = b
        error = 0
        flag  = 0
        fq    = 0
        iter  = 0
	  }
	  else {
	    if (tail == "both") {
	      while ((fa > 0) & (a >= 10^-20)) {
	        a  = a/2
	        fa = qFinder(a, p, k, tail, M, N, alpha, mean, Sigma, sqp)
	      }
	      while ((fb < 0) & (b <= 10^6)) {
	        b  = 2*b
	        fb = qFinder(b, p, k, tail, M, N, alpha, mean, Sigma, sqp)
	      }
	    }
	    else {
	      while (((fa > 0 & fb > 0) | (fa < 0 & fb < 0)) & (a >= -10^6)) {
	        a  = 2*a
	        b  = 2*b
	        fa = qFinder(a, p, k, tail, M, N, alpha, mean, Sigma, sqp)
	        fb = qFinder(b, p, k, tail, M, N, alpha, mean, Sigma, sqp)
	      }
	    }
	    if (fa == 0) {
	      q     = a
          error = 0
          flag  = 0
          fq    = 0
          iter  = 0
	    }
	    else if (fb == 0) {
	      q     = b
          error = 0
          flag  = 0
          fq    = 0
          iter  = 0
	    }
	    // Perform modified interval bisection
	    else if ((fa < 0 & fb > 0) | (fa > 0 & fb < 0)) {
          iter = 1
          while (iter <= itermax) {
            c  = a - ((b - a)/(fb - fa))*fa
            fc = qFinder(c, p, k, tail, M, N, alpha, mean, Sigma, sqp)
            if ((fc == 0) | ((b - a)/2 < tol)) {
              break
            }
            else {
              if (((fa < 0) & (fc < 0)) | ((fa > 0) & (fc > 0))) {
                a  = c
                fa = fc
              }
              else {
                b  = c
			    fb = fc
              }
              iter = iter + 1
            }
          }
          q     = c
          error = (b - a)/2
          fq    = fc
          if (iter == itermax + 1) {
            flag  = 1
          }
          else {
            flag  = 0
          }
	    }
	    else {
	      q     = .
          error = .
          flag  = 2
          fq    = .
          iter  = .
	    }
	  }
    }
  }
  // Return result to stata
  st_matrix("returnmatrix", (q, error, flag, fq, iter))
}

function qFinder(q, p, k, tail, M, N, alpha, mean, Sigma, sqp)
{
  // Initialise all required variables
  if (tail == "lower") {
    a = J(1, k, .)
    b = J(1, k, q)
  }
  else if (tail == "upper") {
    a = J(1, k, q)
    b = J(1, k, .)
  }
  else {
    a = J(1, k, -q)
    b = J(1, k, q)
  }
  if (k == 2) {
    for (i = 1; i <= 2; i++) {
	  if (a[i] == .) {
	    a[i] = -8e+307
	  }
	  if (b[i] == .) {
	    b[i] = 8e+307
	  }
	}
	I = binormal((b[1] - mean[1])/sqrt(Sigma[1, 1]),
	             (b[2] - mean[2])/sqrt(Sigma[2, 2]),
	             Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2])) +
		  binormal((a[1] - mean[1])/sqrt(Sigma[1, 1]),
				   (a[2] - mean[2])/sqrt(Sigma[2, 2]),
				   Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2])) -
		    binormal((b[1] - mean[1])/sqrt(Sigma[1, 1]),
			  	     (a[2] - mean[2])/sqrt(Sigma[2, 2]),
				     Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2])) -
			  binormal((a[1] - mean[1])/sqrt(Sigma[1, 1]),
				       (b[2] - mean[2])/sqrt(Sigma[2, 2]),
				       Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2]))	
  }
  else {
    // Algorithm is for the case with 0 means, so adjust lower and upper
    // and then re-order variables for maximum efficiency
    a = a - mean
    b = b - mean
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
      // Compute next value of y using normalden
      y[i]  = (normalden(atilde[i]) - normalden(btilde[i]))/
                (normal(btilde[i]) - normal(atilde[i]))
    }
    // Set the final element of C
    C[k, k] = sqrt(Sigma[k, k] - sum(C[k, 1::(k - 1)]:^2))
    I = 0
    d = J(1, k, 0)
    e = J(1, k, 1)
    f = J(1, k, 0)
    w = J(1, k - 1, 0)
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
      I     = I + (Ii - I)/i
    }
  }
  return(I - p)
}

end // End of mata
