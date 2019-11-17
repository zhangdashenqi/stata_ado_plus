*! Log likelihood for cfa1: linear form; v.2.1
program define cfa1_lf

   args lnf $CFA1theta
   * $CFA1theta contains all the names needed:
   * $CFA1theta == l_1 ... l_q v_1 ... v_q m_1 ... m_q phi

   gettoken lnf allthenames : 0

   tempvar lnl
   qui g double `lnl' = .

   nobreak mata: CFA1_NormalLKHDr( "`allthenames'", "$CFA1vars", "`lnl'")

   qui replace `lnf' = `lnl'

end

*! NormalLKHDr: normal likelihood with normal deviates in variables
*! v.2.1 Stas Kolenikov skolenik@gmail.com
cap mata: mata drop CFA1_NormalLKHDr()
mata:
void CFA1_NormalLKHDr(
       string parnames, // the parameter names
       string varnames, // the variables
       string loglkhd // where the stuff is to be returned
       ) {

   // declarations
   real matrix data, lnl, parms // views of the data
   real matrix lambda, means, vars, phi // parameters
   real matrix Sigma, WorkSigma, InvWorkSigma, SS // the covariance matrices and temp matrix
   real scalar p, n // dimension, no. obs

   // get the data in
   st_view(data=., ., tokens(varnames) )
   st_view(lnl=., ., tokens(loglkhd) )
   st_view(parms=., 1, tokens(parnames) )

   n=rows(data)
   p=cols(data)

   // get the parameters in
   lambda= parms[1,1..p]
   vars  = parms[1,p+1..2*p]
   means = parms[1,2*p+1..3*p]
   phi   = parms[1,3*p+1]

   Sigma = lambda'*lambda*phi + diag(vars)

   SS = cholesky(Sigma)
   InvWorkSigma = solvelower(SS,I(rows(SS)))
   InvWorkSigma = solveupper(SS',InvWorkSigma)
   ldetWS = 2*ln(dettriangular(SS))

   for( i=1; i<=n; i++ ) {
      lnl[i,1] = -.5*(data[i,.]-means)*InvWorkSigma*(data[i,.]-means)' - .5*ldetWS - .5*p*ln(2*pi())
   }

}

end


exit

History:
v.2.0 March 10, 2006 -- re-written for Stata 9 and Mata
v.2.1 March 10, 2006 -- everything is moved to Mata
