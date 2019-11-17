*! Date    : 10 June 2013
*! Version : 1.05
*! Author  : Adrian Mander
*! Email   : adrian.mander@mrc-bsu.cam.ac.uk
*! A numerical integration command

/*
v 1.00  1 Mar 12 The command is born
v 1.01 12 Mar 12 Altering the temporary files is this the latest?
v 1.02  9 Jul 12 Changed some error checking
v 1.03  9 Jul 12 Altered return local to return scalar
v 1.04 26 Apr 13 Allow the mata installation via this function and improve integration accuracy
v 1.05 10 Jun 13 fix bug in installmata
*/

*! integrate, f(x:+x:^2+x:^3)
*! integrate, f(x+x^2+x^3) v
*! integrate, f(x+x^2+x^3)
*! integrate, f(x+x^2+x^3)
*! integrate, f(x:^2)
*! integrate, f( normalden(x) ) lower(.) upper(.)
*! integrate, f( normalden(x) ) lower(.) upper(1.96)
*! integrate, f( normalden(x) ) lower(-1.96) upper(.)

pr integrate,rclass
version 12.0
syntax [, INSTALLmata Lower(real -1) Upper(real 1) Function(string) Quadpts(int 100) Vectorise]

if "`installmata'"=="" {
  /* The default function */
  if "`function'"=="" {
    local function "x:^2"
    di "{err}WARNING: the integrand was not specified in function() option so will be x^2"
    di
  }
  if `quadpts' <2 {
    di "{err}ERROR: quadrature points need to be 2 or more"
    exit(198)
  }

  /* Drop old code in mata */
  cap mata: mata drop myfunction()
  cap mata: mata drop tefunction()

  /* Write a MATA function */
  tempname fh
  tempfile tefile
  file open `fh' using "`tefile'.do", write replace
  file write `fh' "mata" _n
  if "`vectorise'"=="" {
    file write `fh' "rowvector myfunction(rowvector x)" _n
    file write `fh' "{" _n
    file write `fh' "return(`function')" _n
    file write `fh' "}" _n
  }
  else {
    file write `fh' "real tefunction(real x)" _n
    file write `fh' "{" _n
    file write `fh' "return(`function')" _n
    file write `fh' "}" _n _n
    file write `fh' "mata mosave tefunction(), dir(PERSONAL) replace" _n
    file write `fh' "rowvector myfunction(rowvector x)" _n
    file write `fh' "{" _n
    file write `fh' "  for (j=1; j<=cols(x); j++) {" _n
    file write `fh' "    if(j==1) vec = tefunction(x[j])" _n
    file write `fh' "    else vec = vec, tefunction(x[j])" _n
    file write `fh' "  }" _n
    file write `fh' "return(vec)" _n
    file write `fh' "}" _n
  }
  file write `fh' "mata mosave myfunction(), dir(PERSONAL) replace" _n
  file write `fh' "end" _n
  file close `fh'
  di
  di `"{pstd}{txt}Note: The function to be integrated will be compiled using Mata and stored in your personal directory {res}`c(sysdir_personal)' {txt}(make sure this is writeable){p_end}"'
  di
  qui do "`tefile'.do"

  /***************************************************************************************
   * The next part runs the mata code
   *  note that if you integrate a to b but a is bigger than b you get a negative answer!
   ***************************************************************************************/
  /*mata: st_integrate(`lower', `upper', `quadpts')
  di "{txt}The integral = {res}" r(integral)
  di
  return scalar integral= `r(integral)'
  */
  mata: st_numscalar("r(integral)",integrate(&myfunction(), `lower', `upper', `quadpts'))
  di "{txt}The integral = {res}" r(integral)
  di
  return scalar integral= `r(integral)'
 /* the else on the install mata part */
}
/*Install mata functions*/
if "`installmata'"~="" {
  di
  di `"{pstd}{txt}Creating the library for integrate the Mata function and is being stored in your personal directory {res}`c(sysdir_personal)' {txt}(make sure this is writeable!){p_end}"'
  di
  
/* Write a the whole mata stuff in a do-file and create a library file */
tempname fh
tempfile tefile2
file open `fh' using "`tefile2'.do", write replace
file write `fh' "mata:" _n
file write `fh' "mata clear" _n
file write `fh' "real scalar integrate(pointer scalar integrand, real scalar lower, real scalar upper, | real scalar quadpts, transmorphic xarg1)" _n
file write `fh' "{" _n
file write `fh' "  if (quadpts==.) quadpts=60" _n
file write `fh' "  if (args()<5) { /* this is for single dimensional functions without arguments */" _n
file write `fh' "    if ((lower==. & upper==.) | (lower==0 & upper==.) |(lower~=. & upper~=.)) {" _n
file write `fh' "     return( Re(integrate_main(integrand, lower, upper, quadpts)) )" _n
file write `fh' "    }" _n
file write `fh' "    else if (lower==. & upper~=.) {" _n
file write `fh' "      return( Re(integrate_main(integrand, 0,upper,quadpts) + integrate_main(integrand, 0,.,quadpts)) )" _n
file write `fh' "    }" _n
file write `fh' "    else if (lower~=0 & upper==.) {" _n
file write `fh' "      return( Re(integrate_main(integrand,lower,0,quadpts)+integrate_main(integrand, 0,.,quadpts)) )" _n
file write `fh' "    }" _n
file write `fh' "    else {" _n
file write `fh' "      return( Re(integrate_main(integrand, lower, upper, quadpts)) )" _n
file write `fh' "    }" _n
file write `fh' "  }" _n
file write `fh' "  else { /*there is an argument to be handled */" _n
file write `fh' "    if ((lower==. & upper==.) | (lower==0 & upper==.) |(lower~=. & upper~=.)) {" _n
file write `fh' "     return( Re(integrate_main(integrand, lower, upper, quadpts, xarg1)) )" _n
file write `fh' "    }" _n
file write `fh' "    else if (lower==. & upper~=.) {" _n
file write `fh' "      return( Re(integrate_main(integrand, 0,upper,quadpts, xarg1) + integrate_main(integrand, 0,.,quadpts, xarg1)) )" _n
file write `fh' "    }" _n
file write `fh' "    else if (lower~=0 & upper==.) {" _n
file write `fh' "      return(  Re(integrate_main(integrand,lower,0,quadpts, xarg1)+integrate_main(integrand, 0,.,quadpts, xarg1)) )" _n
file write `fh' "    }" _n
file write `fh' "    else {" _n
file write `fh' "      return( Re(integrate_main(integrand, lower, upper, quadpts, xarg1)) )" _n
file write `fh' "    }  " _n
file write `fh' "  }" _n
file write `fh' "}/* end of integrate*/" _n
file write `fh' "matrix integrate_main(pointer scalar integrand, real lower, real upper, real quadpts, | transmorphic xarg1)" _n
file write `fh' "{" _n
file write `fh' "  if (args()<5) { /* This means not containing additional arguments */" _n
file write `fh' "    /*  This is the definite integral 	*/" _n
file write `fh' "    if (lower~=. & upper~=.) {" _n
file write `fh' "      rw = legendreRW(quadpts)" _n
file write `fh' "      sum = rw[2,]:* (*integrand)( Re( (upper:-lower):/2:*rw[1,]:+(upper:+lower):/2 ) )" _n
file write `fh' "      return((upper-lower)/2*quadrowsum(sum))" _n
file write `fh' "    }" _n
file write `fh' "    /* This is the indefinite integral 0 to inf */" _n
file write `fh' "    else if ( lower==0 & upper==.) {" _n
file write `fh' "      rw = laguerreRW(quadpts, 0) /* alpha I think can be anything */" _n
file write `fh' "      sum = rw[2,]:* exp(Re(rw[1,])) :* (*integrand)( Re(rw[1,]) )" _n
file write `fh' "      return(quadrowsum(sum))" _n
file write `fh' "    }" _n
file write `fh' "    /* This is the indefinite integral -inf to inf */" _n
file write `fh' "    else if( lower==. & upper==.) {" _n
file write `fh' "      rw = hermiteRW(quadpts)" _n
file write `fh' "      sum = rw[2,] :* exp( Re(rw[1,]):^2 ) :* (*integrand)( Re(rw[1,]) )" _n
file write `fh' "      return(quadrowsum(sum))" _n
file write `fh' "    }" _n
file write `fh' "  }" _n
file write `fh' "  else {" _n
file write `fh' "    /*  This is the definite integral 	*/" _n
file write `fh' "    if (lower~=. & upper~=.) {" _n
file write `fh' "      rw = legendreRW(quadpts)" _n
file write `fh' "      sum = rw[2,]:* (*integrand)( Re( (upper:-lower):/2:*rw[1,]:+(upper:+lower):/2 ), xarg1 )" _n
file write `fh' "      return((upper-lower)/2*quadrowsum(sum))" _n
file write `fh' "    }" _n
file write `fh' "    /* This is the indefinite integral 0 to inf */" _n
file write `fh' "    else if ( lower==0 & upper==.) {" _n
file write `fh' "      rw = laguerreRW(quadpts, 0) /* alpha I think can be anything */" _n
file write `fh' "      sum = rw[2,]:* exp(Re(rw[1,])) :* (*integrand)( Re(rw[1,]), xarg1 )" _n
file write `fh' "      return(quadrowsum(sum))" _n
file write `fh' "    }" _n
file write `fh' "    /* This is the indefinite integral -inf to inf */" _n
file write `fh' "    else if( lower==. & upper==.) {" _n
file write `fh' "      rw = hermiteRW(quadpts)" _n
file write `fh' "      sum = rw[2,] :* exp( Re(rw[1,]):^2 ) :* (*integrand)( Re(rw[1,]), xarg1 )" _n
file write `fh' "      return(quadrowsum(sum))" _n
file write `fh' "    }" _n
file write `fh' "  }" _n
file write `fh' "} /*end integrate_main*/" _n
file write `fh' "matrix legendreRW(real scalar quadpts)" _n
file write `fh' "{" _n
file write `fh' "  i = (1..quadpts-1)" _n
file write `fh' "  b = i:/sqrt(4:*i:^2:-1) " _n
file write `fh' "  z1 = J(1,quadpts,0)" _n
file write `fh' "  z2 = J(1,quadpts-1,0)" _n
file write `fh' "  CM = ((z2',diag(b))\z1) + (z1\(diag(b),z2'))" _n
file write `fh' "  V=." _n
file write `fh' "  L=." _n
file write `fh' "  symeigensystem(CM, V, L)" _n
file write `fh' " w = (2:* V':^2)[,1]" _n
file write `fh' "  return( L \ w') " _n
file write `fh' "} /* end of legendreRW */" _n
file write `fh' "matrix laguerreRW(real scalar quadpts, real scalar alpha)" _n
file write `fh' "{" _n
file write `fh' "  i1 = (1..quadpts)" _n
file write `fh' "  i2 = (1..quadpts-1)" _n
file write `fh' "  a = (2:*i1:-1):+alpha" _n
file write `fh' "  b = sqrt( i2 :* (i2 :+ alpha))" _n
file write `fh' "  z1 = J(1,quadpts,0)" _n
file write `fh' "  z2 = J(1,quadpts-1,0)" _n
file write `fh' "  CM = (diag(a)) + (z1\(diag(b),z2')) + ((z2',diag(b))\z1)" _n
file write `fh' "  V=." _n
file write `fh' "  L=." _n
file write `fh' "  symeigensystem(CM, V, L)" _n
file write `fh' "  w = (gamma(alpha+1) :* V':^2 )[,1]" _n
file write `fh' "  return( L \ w') " _n
file write `fh' "} /* end of laguerreRW */" _n
file write `fh' "matrix hermiteRW(scalar quadpts)" _n
file write `fh' "{" _n
file write `fh' "   i = (1..quadpts-1)" _n
file write `fh' "   b = sqrt(i:/2)" _n
file write `fh' "   z1=J(1,quadpts,0)" _n
file write `fh' "   z2=J(1,quadpts-1,0)" _n
file write `fh' "   CM = ((z2\diag(b)),z1') + (z1',(diag(b)\z2))" _n
file write `fh' "   V=." _n
file write `fh' "   L=." _n
file write `fh' "   symeigensystem(CM, V, L)" _n
file write `fh' "   w =  ( sqrt(pi()) :* V':^2 )[,1]" _n
file write `fh' "   return(L \ w')" _n
file write `fh' "} /* end of hermiteRW */" _n
file write `fh' "  mata mlib create lintegrate, dir(PERSONAL) replace" _n
file write `fh' "  mata mlib add lintegrate legendreRW() laguerreRW() hermiteRW() integrate() integrate_main()" _n
file write `fh' "  mata mlib index" _n
file write `fh' "end /*end of MATA*/" _n
file close `fh'
do `tefile2'.do
}
end

/****************************
 * Start of MATA
 ****************************/
mata:

/***********************************************************
 * The main part of the integrate function
 *    will need to check whether this is a definite or 
 *    infinite integral by using missing data
 ***********************************************************/ 
real scalar integrate(pointer scalar integrand, real scalar lower, real scalar upper, | real scalar quadpts, transmorphic xarg1)
{
  if (quadpts==.) quadpts=60
  if (args()<5) { /* this is for single dimensional functions without arguments */
    if ((lower==. & upper==.) | (lower==0 & upper==.) |(lower~=. & upper~=.)) {
     return( Re(integrate_main(integrand, lower, upper, quadpts)) )
    }
    else if (lower==. & upper~=.) {
      return( Re(integrate_main(integrand, 0,upper,quadpts) + integrate_main(integrand, 0,.,quadpts)) )
    }
    else if (lower~=0 & upper==.) {
      return( Re(integrate_main(integrand,lower,0,quadpts)+integrate_main(integrand, 0,.,quadpts)) )
    }
    else {
      return( Re(integrate_main(integrand, lower, upper, quadpts)) )
    }
  }
  else { /*there is an argument to be handled */
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
}/* end of integrate*/

/*******************************************************************************
 * This is the main algorithm for doing a single integral 
 * with standard limits
 *******************************************************************************/
matrix integrate_main(pointer scalar integrand, real lower, real upper, real quadpts, | transmorphic xarg1)
{
  if (args()<5) { /* This means not containing additional arguments */
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
      rw = hermiteRW(quadpts)
      sum = rw[2,] :* exp( Re(rw[1,]):^2 ) :* (*integrand)( Re(rw[1,]) )
      return(quadrowsum(sum))
    }
  }
  else {
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
      rw = hermiteRW(quadpts)
      sum = rw[2,] :* exp( Re(rw[1,]):^2 ) :* (*integrand)( Re(rw[1,]), xarg1 )
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
  symeigensystem(CM, V, L)
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
  symeigensystem(CM, V, L)
  w = (gamma(alpha+1) :* V':^2 )[,1]
  return( L \ w') 
} /* end of laguerreRW */

/*************************************************************************
 * Hermite Roots and Weights THERE are rounding problems with 
 * symeigensystem that mess this function up at 200+quadptsthis function!
 *************************************************************************/
matrix hermiteRW(scalar quadpts)
{
   i = (1..quadpts-1)
   b = sqrt(i:/2)
   z1=J(1,quadpts,0)
   z2=J(1,quadpts-1,0)
   CM = ((z2\diag(b)),z1') + (z1',(diag(b)\z2))
   V=.
   L=.
   symeigensystem(CM, V, L)
   w =  ( sqrt(pi()) :* V':^2 )[,1]
   return(L \ w')
   
} /* end of hermiteRW */

end /*end of MATA*/
