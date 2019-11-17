*! Mata definitions for confa package; 3 March 2009; v.2.0

set matalnum on

mata:

mata set matastrict on
mata clear

//////////////////////////////////////////////
// needed by confa.ado

real CONFA_NF( string input ) {
   real scalar nopenpar, nclosepar, ncolon;
   // opening and closing parentheses

   nopenpar  = length(tokens(input, ")" ))
   nclosepar = length(tokens(input, "(" ))
   // n*par will be 2*nf
   ncolon    = length(tokens(input, ":" ))
   // ncolon will be 2*nf + 1

   if ( (nopenpar == nclosepar) & (nopenpar == ncolon-1 ) ) {
      if (mod(nopenpar,2) == 0) {
          return( nopenpar/2 )
      }
   }

   // if everything was OK, should've exited by now
   // if something's wrong, return zero
   return(0)
}

matrix CONFA_StrucToSigma(real vector parms) {
   real scalar CONFA_loglevel, nobsvar, nfactors, eqno;
   real matrix Lambda, Phi, Theta, Sigma, CONFA_Struc;

   // loglevel
   CONFA_loglevel = strtoreal( st_global("CONFA_loglevel"))

   CONFA_Struc = st_matrix("CONFA_Struc")
   if (CONFA_loglevel>4) CONFA_Struc

   if (CONFA_loglevel>4) {
      printf("{txt}Current parameter values:\n")
      parms
   }

   // the length should coinicde with the # pars from CONFA_Struc
   if ( cols(parms) ~= rows(CONFA_Struc) ) {
      // something's wrong, let's just drop out with an empty matrix
      if (CONFA_loglevel>4) {
         printf("{txt}Expected parameters: {res}%3.0f{txt}; received parameters: {res}%3.0f\n",
                rows(CONFA_Struc),cols(parms))
      }
      return(J(0,0,0))
   }

   // # observed variables: max entry in the number of means
   nobsvar = colmax( select(CONFA_Struc[,3], !(CONFA_Struc[,1]-J(rows(CONFA_Struc),1,1)) ) )
   if (CONFA_loglevel>4) printf("{txt}No. of observed variables: {res}%3.0f\n",nobsvar)

   // # observed factors: max entry in the phi indices
   nfactors = colmax( select(CONFA_Struc[,3], !(CONFA_Struc[,1]-J(rows(CONFA_Struc),1,3)) ) )
   if (CONFA_loglevel>4) printf("{txt}No. of latent factors: {res}%3.0f\n",nfactors)

   // set up the matrices
   Lambda = J(nobsvar,nfactors,0)
   Phi    = J(nfactors,nfactors,0)
   Theta  = J(nobsvar,nobsvar,0)

   // fill the stuff in
   for(eqno=nobsvar+1;eqno<=rows(CONFA_Struc);eqno++) {
      if (CONFA_Struc[eqno,1] == 2) {
         // a lambda-type entry
         Lambda[ CONFA_Struc[eqno,3], CONFA_Struc[eqno,4] ] = parms[eqno]
      }
      if (CONFA_Struc[eqno,1] == 3) {
         // a phi-type entry
         Phi[ CONFA_Struc[eqno,3], CONFA_Struc[eqno,4] ] = parms[eqno]
         Phi[ CONFA_Struc[eqno,4], CONFA_Struc[eqno,3] ] = parms[eqno]
      }
      if (CONFA_Struc[eqno,1] == 4) {
         // a theta-type entry
         Theta[ CONFA_Struc[eqno,3], CONFA_Struc[eqno,3] ] = parms[eqno]
      }
      if (CONFA_Struc[eqno,1] == 5) {
         // a theta-type correlated errors entry
         Theta[ CONFA_Struc[eqno,3], CONFA_Struc[eqno, 4] ] = parms[eqno]
         Theta[ CONFA_Struc[eqno,4], CONFA_Struc[eqno, 3] ] = parms[eqno]
      }
   }
   if (CONFA_loglevel > 4) {
      printf("{txt}Loadings:\n")
      Lambda
      printf("{txt}Factor covariances:\n")
      Phi
      printf("{txt}Residual variances:\n")
      Theta
   }
   Sigma = Lambda*Phi*Lambda' + Theta
   if (CONFA_loglevel > 4) {
      printf("{txt}Implied moments:\n")
      Sigma
   }

   if (CONFA_loglevel == -1) {
      // post matrices to Stata
      st_matrix("CONFA_Lambda",Lambda)
      st_matrix("CONFA_Phi",Phi)
      st_matrix("CONFA_Theta",Theta)
      st_matrix("CONFA_Sigma",Sigma)
   }

   // done with model structure, compute and return implied matrix
   return( Sigma )
}

// vech covariance matrix, for Satorra-Bentler
void SBvechZZtoB(string dlist, string blist) {
   real matrix data, moments, B;
   real scalar i;

   // view the deviation variables
   st_view(data=.,.,tokens(dlist))
   // view the moment variables
   // blist=st_local("blist")
   st_view(moments=.,.,tokens(blist))
   // vectorize!
   for(i=1; i<=rows(data); i++) {
     B = data[i,.]'*data[i,.]
     moments[i,.] = vech(B)'
   }
}

// duplication matrix, for Satorra-Bentler
void Dupl(scalar p, string Dname) {
   real scalar pstar, k;
   real matrix Ipstar, D;

   pstar = p*(p+1)/2
   Ipstar = I(pstar)
   D = J(p*p,0,.)
   for(k=1;k<=pstar;k++) {
      D = (D, vec(invvech(Ipstar[.,k])))
   }
   st_matrix(Dname,D)
}

// Satorra-Bentler Delta matrix
// Delta = \frac \partial{\partial \theta} vech \Sigma(\theta)
void SBStrucToDelta(string DeltaName) {
   real scalar CONFA_loglevel, p, t, varno, facno, i, j, k, fac1, fac2, k1, k2;
   // log level, # obs vars, # parameters, current var, current factor, cycle indices, temp indices
   real matrix Lambda, Phi, Theta, Sigma, CONFA_Struc, Delta, DeltaRow;
   // must be self-explanatory
   real matrix U, E;
   // identity matrices of the size #factors and #obs vars

   // loglevel

   CONFA_loglevel = strtoreal( st_global("CONFA_loglevel"))

   // need the CONFA matrices
   CONFA_Struc = st_matrix("CONFA_Struc")
   Sigma  = st_matrix("CONFA_Sigma")
   Lambda = st_matrix("CONFA_Lambda")
   Phi    = st_matrix("CONFA_Phi")
   // Theta  = st_matrix("CONFA_Theta")

   if (CONFA_loglevel>4) CONFA_Struc

   // # parameters in the model
   t = rows(CONFA_Struc)

   // cols(Delta) = t = # pars
   // rows(Delta) = pstar = p*(p+1)/2 = length( vech( Sigma ) )
   // but that should be accumulated one by one...
   Delta = J(0,t,.)

   // sources of u and e vectors
   p = rows( Sigma )
   U = I( p )
   E = I( rows(Phi) )

   for(i=1;i<=p;i++) {
     for(j=i;j<=p;j++) {
       if (CONFA_loglevel > 4) printf("{txt}Working with pair ({res}%2.0f{txt},{res}%2.0f{txt})\n",i,j)
       DeltaRow = J(1,t,0)
       // parse Struc matrix and see how each parameter affects Cov(X_i,X_j)
       for(k=1;k<=t;k++) {
          if (CONFA_Struc[k,1] == 1) {
             // a mean-type entry
             // for the moment, assume it does not affect anything
          }
          if (CONFA_Struc[k,1] == 2) {
             // a lambda-type entry
             // CONFA_Struc[k,.] = (2, equation #, variable #, factor #)
             varno = CONFA_Struc[k,3]
             facno = CONFA_Struc[k,4]
             DeltaRow[1,k] = U[i,.] * U[.,varno] * E[facno,.] * Phi * Lambda' * U[.,j] +
                             U[i,.] * Lambda * Phi * E[.,facno] * U[varno,.] * U[.,j]
          }
          if (CONFA_Struc[k,1] == 3) {
             // a phi-type entry
             // CONFA_Struc[k,.] = (3, equation #, `factor`kk'', `factor`k'')
             fac1 = CONFA_Struc[k,3]
             fac2 = CONFA_Struc[k,4]
             DeltaRow[1,k] = U[i,.] * Lambda * E[.,fac1] * E[fac2,.] * Lambda' * U[.,j]
          }
          if (CONFA_Struc[k,1] == 4) {
             // a theta-type entry
             // CONFA_Struc[k,.] = (4, equation #, variable #, 0)
             varno = CONFA_Struc[k,3]
             DeltaRow[1,k] = (i==j) & (i==varno)
          }
          if (CONFA_Struc[k,1] == 5) {
             // a theta_{jk}-type entry
             // CONFA_Struc[k,.] = (5, equation #, variable k1, variable k2)
             k1 = CONFA_Struc[k,3]
             k2 = CONFA_Struc[k,4]
             DeltaRow[1,k] = ((i==k1) & (j==k2) ) | ((i==k2) & (j==k1))
          }
       }
       Delta = Delta \ DeltaRow
     }
   }

   st_matrix(DeltaName,Delta)
}


///////////////////////////////////////////
// needed by confa_p.ado

void CONFA_P_EB(string Fnames, string ObsVarNames, string ToUseName) {
  real matrix ff, xx;
  // views
  real matrix bb, Sigma, Lambda, Theta, Phi;
  // substantive matrices
  real scalar p

  // view on the newly generated factors
  st_view(ff=.,.,tokens(Fnames),ToUseName)

  // view on the observed variables
  st_view(xx=.,.,tokens(ObsVarNames),ToUseName)

  // get the estimated matrices
  bb = st_matrix("e(b)")
  Sigma = st_matrix("e(Sigma)")
  Theta = st_matrix("e(Theta)")
  Lambda = st_matrix("e(Lambda)")
  Phi = st_matrix("e(Phi)")

  // # observed vars
  p = rows(Sigma)

  // prediction
  ff[,] = (xx-J(rows(xx),1,1)*bb[1..p]) * invsym(Sigma) * Lambda * Phi
}

void CONFA_P_MLE(string Fnames, string ObsVarNames, string ToUseName) {
  real matrix ff, xx;
  // views
  real matrix bb, Sigma, Lambda, Theta, Phi, ThetaInv;
  // substantive matrices
  real scalar p

  // view on the newly generated factors
  st_view(ff=.,.,tokens(Fnames),ToUseName)

  // view on the observed variables
  st_view(xx=.,.,tokens(ObsVarNames),ToUseName)

  // get the estimated matrices
  bb = st_matrix("e(b)")
  Sigma = st_matrix("e(Sigma)")
  Theta = st_matrix("e(Theta)")
  Lambda = st_matrix("e(Lambda)")
  Phi = st_matrix("e(Phi)")

  // # observed vars
  p = rows(Sigma)

  // Theta is the vector of diagonal elements,
  // so the inverse is easy!
  ThetaInv = diag( 1:/Theta )

  // prediction
  ff[,] = (xx-J(rows(xx),1,1)*bb[1..p]) * ThetaInv * Lambda * invsym(Lambda' * ThetaInv * Lambda)
}

//////////////////////////////////
// needed by confa_lf.ado

void CONFA_NormalLKHDr( string ParsName, string lnfname) {
   // ParsName are the parameters
   // lnfname is the name of the likelihood variable
   // the observed variables are in $CONFA_obsvar

   real scalar CONFA_loglevel, nobsvar, ldetWS, i;
   // log level, # obs vars, log determinant, cycle index
   real matrix Sigma, means, SS, InvWorkSigma;
   // intermediate computations
   string scalar obsvar, touse;
   // list of observed variables
   real matrix data, lnl, parms;
   // views

   CONFA_loglevel = strtoreal( st_global("CONFA_loglevel"))

   obsvar = st_global("CONFA_obsvar")
   nobsvar = length(tokens(obsvar))

   touse = st_global("CONFA_touse")

   st_view(data=., ., tokens(obsvar), touse )
   st_view(lnl=., ., tokens(lnfname), touse)
   st_view(parms=., ., tokens(ParsName), touse)

   // using the set up where the means are the first nobsvar entries of the parameter vector,
   means = parms[1,1..nobsvar]

   Sigma = CONFA_StrucToSigma(parms[1,.])

   if (CONFA_loglevel > 2) {
      parms[1,.]
      means
      Sigma
   }

// do some equilibration??

   SS = cholesky(Sigma)
   InvWorkSigma = solvelower(SS,I(rows(SS)))
   InvWorkSigma = solveupper(SS',InvWorkSigma)
   ldetWS = 2*ln(dettriangular(SS))

   for( i=1; i<=rows(data); i++ ) {
      lnl[i,1] = -.5*(data[i,.]-means)*InvWorkSigma*(data[i,.]-means)' - .5*ldetWS - .5*nobsvar*ln(2*pi())
   }

   if (CONFA_loglevel>2) {
      sum(lnl)
   }

}

// normal likelihood with missing data
void CONFA_NormalLKHDrMiss( string ParsName, string lnfname) {
   // ParsName are the parameters
   // lnfname is the name of the likelihood variable
   // the observed variables are in $CONFA_obsvar


   real scalar CONFA_loglevel, nobsvar, thisldetWS, i, j;
   // log level, # obs vars, log determinant, cycle index
   real matrix Sigma, means, thisSigma, thisSS, thisInvSigma, thispattern, parms;
   // intermediate computations
   string scalar obsvar, misspat, touse;
   // list of observed variables; the names of the missing patterns and touse tempvars
   real matrix data, lnl, parmview, pattern, mdata, mlnl, info;
   // views

   CONFA_loglevel = strtoreal( st_global("CONFA_loglevel"))

   obsvar = st_global("CONFA_obsvar")
   nobsvar = length(tokens(obsvar))

   misspat = st_global("CONFA_miss")
   touse   = st_global("CONFA_touse")

   st_view(pattern=., ., misspat, touse )
   st_view(data=., ., tokens(obsvar), touse )
   st_view(lnl=., ., lnfname, touse )

   // STILL USING THE FIRST OBSERVATIONS TO GET THE PARAMETERS!!!
   st_view(parmview=., ., tokens(ParsName), touse )
   parms = parmview[1,1..cols(parmview)]

   if (CONFA_loglevel>2) {
        obsvar
        parms
   }

   // using the set up where the means are the first nobsvar entries of the parameter vector,
   means = parms[1..nobsvar]

   Sigma = CONFA_StrucToSigma(parms)

   // utilize an existing set up of the missing data patterns
   // data assumed to be sorted by the patterns of missing data

   info = panelsetup( pattern, 1 )

   for (i=1; i<=rows(info); i++) {
           panelsubview(mdata=., data, i, info)
           panelsubview(mlnl=., lnl, i, info)
           // mdata should contain the portion of the data with the same missing data pattern
           // mlnl will be conforming to mdata

           // OK, now need to figure out that pattern
           thispattern = J(1, cols(data), 1) - colmissing( mdata[1,] )
           if (CONFA_loglevel > 2) {
               printf("{txt}Pattern #{res}%5.0f{txt} :", i)
               thispattern
           };

           // modify the matrices

           thisSigma = select( select( Sigma, thispattern), thispattern' )
           thisSS = cholesky(thisSigma)
           thisInvSigma = solvelower(thisSS,I(rows(thisSS)))
           thisInvSigma = solveupper(thisSS',thisInvSigma)
           thisldetWS = 2*ln(dettriangular(thisSS))

           if (CONFA_loglevel > 3) {
              thisSigma
              thisInvSigma
           };

           for( j=1; j<=rows(mdata); j++ ) {
              // this is actually a single line broken by arithmetic operator signs
              // that's bad style but it works
              mlnl[j,1] = -.5*(select(data[j,.],thispattern)-select(means,thispattern)) *
                              thisInvSigma *
                              (select(data[j,.],thispattern)-select(means,thispattern))' -
                              .5*thisldetWS - .5*sum(thispattern)*ln(2*pi())
           }

           if (CONFA_loglevel>3) {
              mlnl
           };

   }


}

// Bollen-Stine bootstrap rotation
void CONFA_BSrotate(
       string SigmaName, // the parameter matrix name
       string varnames // the variable names
       ) {

   // declarations
   real matrix data  // views of the data
   real matrix Sigma, SS, S2, SS2  // the covariance matrices and temp matrices
   real matrix means // the means -- need modifications for weighted data!!!
   real scalar n // dimension, no. obs

   // get the data in
   st_view(data=., ., tokens(varnames) )
   n=rows(data)

   Sigma = st_matrix(SigmaName)

   // probability weights!!!
   means = colsum(data)/n
   SS = (cross(data,data)-n*means'*means)/(n-1)

   S2 = cholesky(Sigma)
   SS2 = cholesky(SS)
   SS2 = solveupper(SS2',I(rows(SS)))

   data[,] = data*SS2*S2'

}


// build a library
mata mlib create lconfa, replace
mata mlib add lconfa *()
mata mlib index

end
// of mata

exit

// don't need this:

string scalar CONFA_UL( string input ) {

  string rowvector s;
  real scalar i,j,n;

  // tokenize input into a string vector
  s = tokens( input )
  n = cols( s )
  for(i=1;i<=n;i++) {
    // as I go over the elements, compare to the previous ones
    for(j=1;j<i;j++) {
       if ( s[i] == s[j] ) {
         s[i] = ""
         continue
       }
    }
  }
  // assemble back into a string scalar
  return( stritrim(invtokens( s ) ) )
}
