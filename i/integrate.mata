*! Date    : 9 Jul 2012
*! Version : 1.01
*! Author  : Adrian Mander
*! Email   : adrian.mander@mrc-bsu.cam.ac.uk
*! A MATA library numerical integration command

/*
v 1.00   1 Mar 12 These are the mata version of the integrate commands including the library creation
v 1.01  19 Apr 12 Adding extra arguments in the function to be integrated
v 1.02   9 Jul 12 Going to make the integrand only accept a single vector as passed parameters
*/

version 12.0
mata:
mata clear

/***********************************************************
 * The main part of the integrate function
 *    will need to check whether this is a definite or 
 *    infinite integral by using missing data
 ***********************************************************/ 
real scalar integrate(pointer scalar integrand, real scalar lower, real scalar upper, | real scalar quadpts, real rowvector xarg1)
{
  if (quadpts==.) quadpts=60
  if (args()<5) { /* this is for single dimensional functions */
    if ((lower==. & upper==.) | (lower==0 & upper==.) |(lower~=. & upper~=.)) {
     return( Re(integrate_main(integrand, lower, upper, quadpts)) )
    }
    else if (lower==. & upper~=.) {
      return( Re(integrate_main(integrand, 0,upper,quadpts) + integrate_main(integrand, 0,.,quadpts)) )
    }
    else if (lower~=0 & upper==.) {
      return(  Re(integrate_main(integrand,lower,0,quadpts)+integrate_main(integrand, 0,.,quadpts)) )
    }
    else {
      return( Re(integrate_main(integrand, lower, upper, quadpts)) )
    }
  }
  else if (args()==5) {
    if ((lower==. & upper==.) | (lower==0 & upper==.) |(lower~=. & upper~=.)) {
     return( Re(integrate_main(integrand, lower, upper, quadpts, xarg1)) )
    }
    else if (lower==. & upper~=.) {
      return( Re(integrate_main(integrand, 0,upper,quadpts, xarg1) + integrate_main(integrand, 0,.,quadpts, xarg1)) )
    }
    else if (lower~=0 & upper==.) {
      return(  Re(integrate_main(integrand,lower,0,quadpts, xarg1)+integrate_main(integrand, 0,.,quadpts, xarg1)) )
    }
    else {
      return( Re(integrate_main(integrand, lower, upper, quadpts, xarg1)) )
    }  
  }
  else {
    printf("{err}ERROR?")
  }
}/* end of integrate*/

/**********************************************************
 * This is the main algorithm for doing a single integral 
 * with standard limits
 **********************************************************/
matrix integrate_main(pointer scalar integrand, real lower, real upper, real quadpts, | real rowvector xarg1)
{
  if (args()<5) {
    /*  This is the definite integral 	*/
    if (lower~=. & upper~=.) {
      rw = legendreRW(quadpts)
      sum = rw[2,]:* (*integrand)( Re( (upper:-lower):/2:*rw[1,]:+(upper:+lower):/2 ) )
      return((upper-lower)/2*quadrowsum(sum))
    }
    /* This is the indefinite integral 0 to inf */
    else if ( lower==0 & upper==.) {
      rw = laguerreRW(quadpts, 0) /* alpha I think can be anything */
      sum = rw[2,]:* exp(Re(rw[1,])) :* (*integrand)( Re(rw[1,]) )
      return(quadrowsum(sum))
    }
    /* This is the indefinite integral -inf to inf */
    else if( lower==. & upper==.) {
      if ((quadpts>60) & (quadpts~=100)) printf("\n{err}WARNING: Gauss-Hermite quadrature is numerically unstable above 60 quadrature points\n")
      rw = hermiteRW(quadpts)
      sum = rw[2,] :* exp( Re(rw[1,]):^2 )  :* (*integrand)( Re(rw[1,]) )
      return(quadrowsum(sum))
    }
  }
  else if (args()==5) {
    /*  This is the definite integral 	*/
    if (lower~=. & upper~=.) {
      rw = legendreRW(quadpts)
      sum = rw[2,]:* (*integrand)( Re( (upper:-lower):/2:*rw[1,]:+(upper:+lower):/2 ), xarg1 )
      return((upper-lower)/2*quadrowsum(sum))
    }
    /* This is the indefinite integral 0 to inf */
    else if ( lower==0 & upper==.) {
      rw = laguerreRW(quadpts, 0) /* alpha I think can be anything */
      sum = rw[2,]:* exp(Re(rw[1,])) :* (*integrand)( Re(rw[1,]), xarg1 )
      return(quadrowsum(sum))
    }
    /* This is the indefinite integral -inf to inf */
    else if( lower==. & upper==.) {
      if ((quadpts>60) & (quadpts~=100)) printf("\n{err}WARNING: Gauss-Hermite quadrature is numerically unstable above 60 (apart from 100) quadrature points\n")
      rw = hermiteRW(quadpts)
      sum = rw[2,] :* exp( Re(rw[1,]):^2 )  :* (*integrand)( Re(rw[1,]), xarg1 )
      return(quadrowsum(sum))
    }
  }
 
} /*end integrate_main*/

/***************************************************************
 *  Legendre roots/weights
 * This is the clever code to get the roots and weights without 
 * having to use the polyroots() function which starts breaking 
 * down at n=20
 * L contains the roots and w are the weights
 ***************************************************************/
matrix legendreRW(real scalar quadpts)
{
  i = (1..quadpts-1)
  b = i:/sqrt(4:*i:^2:-1) 
  z1 = J(1,quadpts,0)
  z2 = J(1,quadpts-1,0)
  CM = ((z2',diag(b))\z1) + (z1\(diag(b),z2'))
  V=.
  L=.
  eigensystem(CM, V, L)
  w = (2:* V':^2)[,1]
  return( L \ w') 
} /* end of legendreRW */
/****************************************************************
 * Laguerre Roots and Weights
 ****************************************************************/
matrix laguerreRW(real scalar quadpts, real scalar alpha)
{
  i1 = (1..quadpts)
  i2 = (1..quadpts-1)
  a = (2:*i1:-1):+alpha
  b = sqrt( i2 :* (i2 :+ alpha))
  z1 = J(1,quadpts,0)
  z2 = J(1,quadpts-1,0)
  CM = (diag(a)) + (z1\(diag(b),z2')) + ((z2',diag(b))\z1)
  V=.
  L=.
  eigensystem(CM, V, L)
  w = (gamma(alpha+1) :* V':^2 )[,1]
  return( L \ w') 
} /* end of laguerreRW */
/******************************************************************
 * Hermite Roots and Weights
 ******************************************************************/
matrix hermiteRW(scalar quadpts)
{
/*
if (quadpts==100) {
 L=(1.10795872422439482889e-01, 3.32414692342231807054e-01, 5.54114823591616988249e-01, 7.75950761540145781976e-01, 9.97977436098105243902e-01, 1.22025039121895305882e+00,
1.44282597021593278768e+00, 1.66576150874150946983e+00, 1.88911553742700837153e+00, 2.11294799637118795206e+00, 2.33732046390687850509e+00, 2.56229640237260802502e+00, 2.78794142398198931316e+00, 3.01432358033115551667e+00,
3.24151367963101295043e+00, 3.46958563641858916968e+00, 3.69861685931849193984e+00, 3.92868868342767097205e+00, 4.15988685513103054019e+00, 4.39230207868268401677e+00, 4.62603063578715577309e+00, 4.86117509179121020995e+00,
5.09784510508913624692e+00, 5.33615836013836049734e+00, 5.57624164932992410311e+00, 5.81823213520351704715e+00, 6.06227883261430263882e+00, 6.30854436111213512156e+00, 6.55720703192153931598e+00, 6.80846335285879641431e+00,
7.06253106024886543766e+00, 7.31965282230453531632e+00, 7.58010080785748888415e+00, 7.84418238446082116862e+00, 8.11224731116279191689e+00, 8.38469694041626507474e+00, 8.66199616813451771409e+00, 8.94468921732547447845e+00,
9.23342089021916155069e+00, 9.52896582339011480496e+00, 9.83226980777796909401e+00, 1.01445099412928454695e+01, 1.04671854213428121416e+01, 1.08022607536847145950e+01, 1.11524043855851252649e+01, 1.15214154007870302416e+01,
1.19150619431141658018e+01, 1.23429642228596742953e+01, 1.28237997494878089065e+01, 1.34064873381449101387e+01)
  w=(2.18892629587439125060e-01, 1.98462850254186477710e-01, 1.63130030502782941425e-01, 1.21537986844104181985e-01, 8.20518273912244646789e-02, 5.01758126774286956964e-02, 2.77791273859335142698e-02, 1.39156652202318064178e-02,
    6.30300028560805254921e-03, 2.57927326005909017346e-03, 9.52692188548619117497e-04, 3.17291971043300305539e-04, 9.51716277855096647040e-05, 2.56761593845490630553e-05, 6.22152481777786331722e-06, 1.35179715911036728661e-06,
    2.62909748375372507934e-07, 4.56812750848493951350e-08, 7.07585728388957290740e-09, 9.74792125387162124528e-10, 1.19130063492907294976e-10, 1.28790382573155823282e-11, 1.22787851441012497000e-12, 1.02887493735099254677e-13,
    7.54889687791524329227e-15, 4.82983532170303334787e-16, 2.68249216476037608006e-17, 1.28683292112115327575e-18, 5.30231618313184868536e-20, 1.86499767513025225814e-21, 5.56102696165916731717e-23, 1.39484152606876708047e-24,
    2.91735007262933241788e-26, 5.03779116621318778423e-28, 7.10181222638493422964e-30, 8.06743427870937717382e-32, 7.27457259688776757460e-34, 5.11623260438522218054e-36, 2.74878488435711249209e-38, 1.10047068271422366943e-40,
    3.18521787783591793076e-43, 6.42072520534847248278e-46, 8.59756395482527161007e-49, 7.19152946346337102982e-52, 3.45947793647555044453e-55, 8.51888308176163378638e-59, 9.01922230369355617950e-63, 3.08302899000327481204e-67,
    1.97286057487945255443e-72, 5.90806786503120681541e-79)
  return((L,-1:*L) \ (w,w))
}

*/
/*
if (quadpts==100) {
 L=(1.10795872422439482889e-01, 3.32414692342231807054e-01, 5.54114823591616988249e-01, 7.75950761540145781976e-01, 9.97977436098105243902e-01, 1.22025039121895305882e+00, 1.44282597021593278768e+00)
 L=(L, 1.66576150874150946983e+00, 1.88911553742700837153e+00, 2.11294799637118795206e+00, 2.33732046390687850509e+00, 2.56229640237260802502e+00, 2.78794142398198931316e+00, 3.01432358033115551667e+00)
 L= (L, 3.24151367963101295043e+00)
 L=(L, 3.46958563641858916968e+00, 3.69861685931849193984e+00, 3.92868868342767097205e+00, 4.15988685513103054019e+00, 4.39230207868268401677e+00, 4.62603063578715577309e+00, 4.86117509179121020995e+00, 5.09784510508913624692e+00)
 L=(L, 5.33615836013836049734e+00, 5.57624164932992410311e+00, 5.81823213520351704715e+00, 6.06227883261430263882e+00, 6.30854436111213512156e+00, 6.55720703192153931598e+00, 6.80846335285879641431e+00, 7.06253106024886543766e+00)
 L=(L, 7.31965282230453531632e+00, 7.58010080785748888415e+00, 7.84418238446082116862e+00, 8.11224731116279191689e+00, 8.38469694041626507474e+00, 8.66199616813451771409e+00, 8.94468921732547447845e+00, 9.23342089021916155069e+00)
 L=(L, 9.52896582339011480496e+00, 9.83226980777796909401e+00, 1.01445099412928454695e+01, 1.04671854213428121416e+01, 1.08022607536847145950e+01, 1.11524043855851252649e+01, 1.15214154007870302416e+01, 1.19150619431141658018e+01)
 L=(L, 1.23429642228596742953e+01, 1.28237997494878089065e+01, 1.34064873381449101387e+01)
 w=(2.18892629587439125060e-01, 1.98462850254186477710e-01, 1.63130030502782941425e-01, 1.21537986844104181985e-01, 8.20518273912244646789e-02, 5.01758126774286956964e-02, 2.77791273859335142698e-02, 1.39156652202318064178e-02)
 w= (w, 6.30300028560805254921e-03)
 w=(w, 2.57927326005909017346e-03, 9.52692188548619117497e-04, 3.17291971043300305539e-04, 9.51716277855096647040e-05, 2.56761593845490630553e-05, 6.22152481777786331722e-06, 1.35179715911036728661e-06, 2.62909748375372507934e-07)
 w=(w, 4.56812750848493951350e-08, 7.07585728388957290740e-09, 9.74792125387162124528e-10, 1.19130063492907294976e-10, 1.28790382573155823282e-11, 1.22787851441012497000e-12, 1.02887493735099254677e-13, 7.54889687791524329227e-15)
 w=(w, 4.82983532170303334787e-16, 2.68249216476037608006e-17, 1.28683292112115327575e-18, 5.30231618313184868536e-20, 1.86499767513025225814e-21, 5.56102696165916731717e-23, 1.39484152606876708047e-24, 2.91735007262933241788e-26)
 w=(w, 5.03779116621318778423e-28, 7.10181222638493422964e-30, 8.06743427870937717382e-32, 7.27457259688776757460e-34, 5.11623260438522218054e-36, 2.74878488435711249209e-38, 1.10047068271422366943e-40, 3.18521787783591793076e-43)
 w=(w, 6.42072520534847248278e-46, 8.59756395482527161007e-49, 7.19152946346337102982e-52, 3.45947793647555044453e-55, 8.51888308176163378638e-59, 9.01922230369355617950e-63, 3.08302899000327481204e-67)
 w=(w, 1.97286057487945255443e-72, 5.90806786503120681541e-79)

  return((L,-1:*L) \ (w,w))
}
*/
if (quadpts==0) {
 L=1 \(0)
 return(L)
}
else {
  i = (1..quadpts-1)
  b = sqrt(i:/2)
  z1=J(1,quadpts,0)
  z2=J(1,quadpts-1,0)
  CM = ((z2\diag(b)),z1') + (z1',(diag(b)\z2))
  V=.
  L=.
  eigensystem(CM, V, L)
  w =  ( sqrt(pi()) :* V':^2 )[,1]
  return(L \ w')
}
} /* end of hermiteRW */


mata mlib create lintegrate, dir(PERSONAL) replace
mata mlib add lintegrate *()
mata mlib index
end /*end of MATA*/

