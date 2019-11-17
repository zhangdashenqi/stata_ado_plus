/****************************************
* EWreg.ado
*
* Runs Error-In-Variable model regression, with 1 mismeasured regressors and several
* perfectly measured regressors.
*
* Uses the High-Order-Moments method of Erickson Whited 2000, Journal of Political
* Economy, also described in Erickson Whited 2002, Econometric Theory.
*
* Author:  Robert Parham, University of Rochester
*          June 30, 2012
*
* Version: 1.0
*
* Based on Gauss code provided by Toni M. Whited
*
*
* USAGE:
* syntax: EWreg depvar misindep [indepvars] [if] [in] [, option]
* options:
*	METHod 		- one of "GMM3","GMM4","GMM5","GMM6","GMM7". default is "GMM3"
*	BXint		- a numlist of starting values for beta (the coefficient on misindep)
*				  zero means use the best guess, and should be part of the list.
* 				  defualt is 0.
*	HAScons 	- indicates that indepvars contains a constant variable, and so a constant
* 				  should not be added in the estimation process
*	NOPRN 		- supress printing of results
*
* RETURN:
* EWreg saves the following in e()
*
* scalars:
* 	e(N) 		- number of observations
*	e(Jstat) 	- J statistic on overidentifying restrictions
*	e(Jval) 	- p-val on Jstat
*	e(dfree)	- Degrees of freedom for Jval
*	e(rho) 		- the rho^2 value (see EW2000 JPE)
*	e(tau) 		- the tau^2 value (see EW2000 JPE)
*	e(SErho) 	- s.e. on rho^2
*	e(SEtau) 	- s.e. on tau^2
* 	e(obj)		- value of GMM objective function
*	e(ID3stat) 	- Test statistic on identification test with 3 moments
*	e(ID3val) 	- p-val on ID3val
*	e(ID4stat) 	- Test statistic on identification test with 4 moments
*	e(ID4val) 	- p-val on ID4val
*
* macros:
*	e(bxint) 	- the numlist of initial guesses for beta
*
* matrices:
* 	e(b) 		- regression coeffiecints
* 	e(V) 		- Variance-Covariance matrix on e(b)
* 	e(inflnc) 	- Influence functions on (misindep,indepvars)
*	e(serr) 	- standard errors on e(b)
* 	e(vcrhotau) - Variance-Covariance matrix on (rho,tau)
*	e(w) 		- weighting matrix used in GMM step of estimation
* 	e(inflncrhotau)	- Influence functions on (rho,tau)
*
****************************************/


capture program drop EWreg
program define EWreg, eclass
	version 10.1
	syntax varlist(min=2 numeric) [if] [in] [, METHod(string) BXint(numlist) HAScons NOPRN]
	marksample touse
	
	quietly count if `touse'
	if `r(N)' == 0 error 2000
		
	gettoken depvar varlist: varlist 		// separate varlist
	gettoken misindep indepvars: varlist 	// separate varlist

	if "`bxint'"=="" local bxint = "0"

	tempname b V cst
	mata: doEW("`depvar'", "`misindep'", "`indepvars'", "`method'", "`bxint'", "`hascons'" , "`touse'" )
	mat `b' = r(beta)
	mat `V' = r(VCmat)
	local cst = cond("`hascons'" == "", "_cons", "")
	local vnames `misindep' `cst' `indepvars'
	matname `V' `vnames'
	matname `b' `vnames', c(.)
	local N = r(N)
	ereturn post `b' `V', depname(`depvar') obs(`N') esample(`touse')
	ereturn matrix inflnc  = inflnc
	ereturn matrix serr  = serr
	ereturn matrix vcrhotau = vcrhotau
	ereturn matrix inflncrhotau = inflncrhotau
	ereturn matrix w = w
	ereturn scalar Jstat = r(Jstat)
	ereturn scalar Jval = r(Jval)
	ereturn scalar dfree = r(dfree)
	ereturn scalar rho = r(rho)
	ereturn scalar tau = r(tau)
	ereturn scalar SErho = r(SErho)
	ereturn scalar SEtau = r(SEtau)
	ereturn scalar obj = r(obj)
	ereturn local  bxint = "`bxint'"
	ereturn scalar ID3val = r(ID3val)
	ereturn scalar ID3stat = r(ID3stat)
	ereturn scalar ID4val = r(ID4val)
	ereturn scalar ID4stat = r(ID4stat)
	if ("`noprn'"=="") {
		display _newline "`method' Errors-In-Variables results" _col(60) "Number of obs = " e(N)
		ereturn display
		if ( e(Jstat) > 0 ) {
			display "Sargan-Hansen J statistic: " %7.3f e(Jstat)
			display "Chi-sq(" %3.0f e(dfree) " ) P-val = " ///
			%5.4f e(Jval) _newline
		}
	}
end

version 10.1
mata:
mata clear

// subroutine to define the f vector.
function deff(a,ey2_d,eyx_d,ex2_d,ey2x_d,eyx2_d,ey3x_d,ey2x2_d,eyx3_d,ex3_d,ey3_d,ey4x_d,/*
			 */ ey3x2_d,ey2x3_d,eyx4_d,ey4_d,ex4_d,ey5x_d,ey4x2_d,ey3x3_d,ey2x4_d,eyx5_d,/*
			 */ ey5_d,ex5_d,ey6x_d,ey5x2_d,ey4x3_d,ey3x4_d,ey2x5_d,eyx6_d,eestim,nneeqq)
{
	f=J(1,nneeqq,0)
	
	f[,1]=ey2_d-(a[1,1]^2)*a[2,1]-a[3,1]
	f[,2]=eyx_d-a[1,1]*a[2,1]
	f[,3]=ex2_d-a[2,1]-a[4,1]
	f[,4]=ey2x_d-(a[1,1]^2)*a[5,1]
	f[,5]=eyx2_d-a[1,1]*a[5,1]

	if (eestim>1)
	{
		f[,6]=ey3x_d-(a[1,1]^3)*a[6,1]-3*a[1,1]*a[2,1]*a[3,1]
		f[,7]=ey2x2_d-(a[1,1]^2)*(a[6,1]+a[2,1]*a[4,1])-a[3,1]*(a[2,1]+a[4,1])
		f[,8]=eyx3_d-a[1,1]*a[6,1]-3*a[1,1]*a[2,1]*a[4,1]
	}
	
	if (eestim>2)
	{
		f[,9]=ex3_d-a[5,1]-a[7,1]
		f[,10]=ey3_d-(a[1,1]^3)*a[5,1]-a[8,1]
		f[,11]=ey4x_d-(a[1,1]^4)*a[9,1]-6*(a[1,1]^2)*a[5,1]*a[3,1]-4*a[1,1]*a[2,1]*a[8,1]
		f[,12]=ey3x2_d-(a[1,1]^3)*(a[9,1]+a[5,1]*a[4,1])-3*a[1,1]*a[5,1]*a[3,1]-a[8,1]*(a[2,1]+a[4,1])
		f[,13]=ey2x3_d-(a[1,1]^2)*(a[9,1]+3*a[5,1]*a[4,1]+a[2,1]*a[7,1])-a[3,1]*(a[5,1]+a[7,1])
		f[,14]=eyx4_d-a[1,1]*(a[9,1]+6*a[5,1]*a[4,1]+4*a[2,1]*a[7,1])
	}
	
	if (eestim>3)
	{
		f[,15]=ey4_d-(a[1,1]^4)*a[6,1]-6*(a[1,1]^2)*a[2,1]*a[3,1]-a[10,1]
		f[,16]=ex4_d-a[6,1]-6*a[2,1]*a[4,1]-a[11,1]
		f[,17]=ey5x_d-(a[1,1]^5)*a[12,1]-10*(a[1,1]^3)*a[6,1]*a[3,1]-10*(a[1,1]^2)*a[5,1]*a[8,1]-5*a[1,1]*a[2,1]*a[10,1]
		f[,18]=ey4x2_d-(a[1,1]^4)*(a[12,1]+a[6,1]*a[4,1])-6*(a[1,1]^2)*(a[6,1]*a[3,1]+a[2,1]*a[3,1]*a[4,1])-4*a[1,1]*a[5,1]*a[8,1]-a[10,1]*(a[2,1]+a[4,1])
		f[,19]=ey3x3_d-(a[1,1]^3)*(a[12,1]+3*a[6,1]*a[4,1]+a[5,1]*a[7,1])-a[1,1]*(3*a[6,1]*a[3,1]+9*a[2,1]*a[3,1]*a[4,1])-a[8,1]*(a[5,1]+a[7,1])
		f[,20]=ey2x4_d-(a[1,1]^2)*(a[12,1]+6*a[6,1]*a[4,1]+4*a[5,1]*a[7,1]+a[2,1]*a[11,1])-a[3,1]*(a[6,1]+6*a[2,1]*a[4,1]+a[11,1])
		f[,21]=eyx5_d-a[1,1]*(a[12,1]+10*a[6,1]*a[4,1]+10*a[5,1]*a[7,1]+5*a[2,1]*a[11,1])
	}
	
	if (eestim>4)
	{
		f[,22]=ey5_d-(a[1,1]^5)*a[9,1]-10*(a[1,1]^3)*a[5,1]*a[3,1]/*
			 */-10*(a[1,1]^2)*a[2,1]*a[8,1]-a[13,1]
		f[,23]=ex5_d-a[9,1]-10*a[5,1]*a[4,1]-10*a[2,1]*a[7,1]-a[14,1]
		f[,24]=ey6x_d-(a[1,1]^6)*a[15,1]/*
			 */-15*(a[1,1]^4)*a[9,1]*a[3,1]/*
			 */-20*(a[1,1]^3)*a[6,1]*a[8,1]/*
			 */-15*(a[1,1]^2)*a[5,1]*a[10,1]/*
			 */-6*a[1,1]*a[2,1]*a[13,1]
		f[,25]=ey5x2_d-(a[1,1]^5)*(a[15,1]+a[9,1]*a[4,1])/*
			 */-10*(a[1,1]^3)*(a[9,1]*a[3,1]+a[5,1]*a[3,1]*a[4,1])/*
			 */-10*(a[1,1]^2)*(a[6,1]*a[8,1]+a[2,1]*a[8,1]*a[4,1])/*
			 */-5*a[1,1]*a[5,1]*a[10,1]/*
			 */-a[13,1]*(a[2,1]+a[4,1])
		f[,26]=ey4x3_d/*
			 */-(a[1,1]^4)*(a[15,1]+3*a[9,1]*a[4,1]+a[6,1]*a[7,1])/*
			 */-6*(a[1,1]^2)*(a[9,1]*a[3,1]+3*a[5,1]*a[3,1]*a[4,1]+a[2,1]*a[3,1]*a[7,1])/*
			 */-4*a[1,1]*(a[6,1]*a[8,1]+3*a[2,1]*a[8,1]*a[4,1])/*
			 */-a[10,1]*(a[5,1]+a[7,1])
		f[,27]=ey3x4_d/*
			 */-(a[1,1]^3)*(a[15,1]+6*a[9,1]*a[4,1]+4*a[6,1]*a[7,1]+a[5,1]*a[11,1])/*
			 */-a[1,1]*(3*a[9,1]*a[3,1]+18*a[5,1]*a[3,1]*a[4,1]+12*a[2,1]*a[3,1]*a[7,1])/*
			 */-a[8,1]*(a[6,1]+6*a[2,1]*a[4,1]+a[11,1])
		f[,28]=ey2x5_d/*
			 */-(a[1,1]^2)*(a[15,1]+10*a[9,1]*a[4,1]+10*a[6,1]*a[7,1]+5*a[5,1]*a[11,1]/*
			 */+a[2,1]*a[14,1])/*
			 */-a[3,1]*(a[9,1]+10*a[5,1]*a[4,1]+10*a[2,1]*a[7,1]+a[14,1])
		f[,29]=eyx6_d/*
			 */-a[1,1]*(a[15,1]+15*a[9,1]*a[4,1]+20*a[6,1]*a[7,1]+15*a[5,1]*a[11,1]/*
			 */+6*a[2,1]*a[14,1])
	}

	f=f'
	return (f)
}


// subroutine to define the f vector for the optimal weighting matrix.
function optw(y2_d,yx_d,x2_d,y2x_d,yx2_d,y3x_d,y2x2_d,yx3_d,x3_d,y3_d,y4x_d,/*
			*/y3x2_d,y2x3_d,yx4_d,y4_d,x4_d,y5x_d,y4x2_d,y3x3_d,y2x4_d,yx5_d,/*
            */y5_d,x5_d,y6x_d,y5x2_d,y4x3_d,y3x4_d,y2x5_d,yx6_d,/*
            */ey2_d,eyx_d,ex2_d,ey2x_d,eyx2_d,ey3x_d,ey2x2_d,eyx3_d,ex3_d,/*
            */ey3_d,ey4x_d,ey3x2_d,ey2x3_d,eyx4_d,ey4_d,ex4_d,ey5x_d,ey4x2_d,/*
            */ey3x3_d,ey2x4_d,eyx5_d,ey5_d,ex5_d,ey6x_d,ey5x2_d,ey4x3_d,/*
            */ey3x4_d,ey2x5_d,eyx6_d,/*
            */inezz,zy_d,zx_d,eyx_z,ey2_z,ex2_z,ey3_z,ey2x_z,eyx2_z,ex3_z,ey4_z,/*
            */ey3x_z,ey2x2_z,eyx3_z,ex4_z,ey5_z,ey4x_z,ey3x2_z,ey2x3_z,eyx4_z,ex5_z,/*
            */ey6_z,ey5x_z,ey4x2_z,ey3x3_z,ey2x4_z,eyx5_z,ex6_z,n,neq,estim)
{
	f=J(n,neq,0)

	f[,1]=y2_d:-ey2_d
	f[,2]=yx_d:-eyx_d
	f[,3]=x2_d:-ex2_d
	f[,4]=y2x_d:-ey2x_d
	f[,5]=yx2_d:-eyx2_d
	
	if (estim>1)
	{
		f[,6]=y3x_d:-ey3x_d
		f[,7]=y2x2_d:-ey2x2_d
		f[,8]=yx3_d:-eyx3_d
	}
	
	if (estim>2)
	{
		f[,9]=x3_d:-ex3_d
		f[,10]=y3_d:-ey3_d
		f[,11]=y4x_d:-ey4x_d
		f[,12]=y3x2_d:-ey3x2_d
		f[,13]=y2x3_d:-ey2x3_d
		f[,14]=yx4_d:-eyx4_d
	}
	
	if (estim>3)
	{
		f[,15]=y4_d:-ey4_d
		f[,16]=x4_d:-ex4_d
		f[,17]=y5x_d:-ey5x_d
		f[,18]=y4x2_d:-ey4x2_d
		f[,19]=y3x3_d:-ey3x3_d
		f[,20]=y2x4_d:-ey2x4_d
		f[,21]=yx5_d:-eyx5_d
	}
	
	if (estim>4)
	{
		f[,22]=y5_d:-ey5_d
		f[,23]=x5_d:-ex5_d
		f[,24]=y6x_d:-ey6x_d
		f[,25]=y5x2_d:-ey5x2_d
		f[,26]=y4x3_d:-ey4x3_d
		f[,27]=y3x4_d:-ey3x4_d
		f[,28]=y2x5_d:-ey2x5_d
		f[,29]=yx6_d:-eyx6_d
	}

	// this part makes the standard error adjustment.

	ei=J(n,neq,0)

	ei[,4]=(-2*eyx_z'*inezz*(zy_d')-ey2_z'*inezz*(zx_d'))'
	ei[,5]=(-ex2_z'*inezz*zy_d'-2*eyx_z'*inezz*zx_d')'

	if (estim>1)
	{
		ei[,6]=(-3*ey2x_z'*inezz*zy_d'-ey3_z'*inezz*zx_d')'
		ei[,7]=(-2*eyx2_z'*inezz*zy_d'-2*ey2x_z'*inezz*zx_d')'
		ei[,8]=(-ex3_z'*inezz*zy_d'-3*eyx2_z'*inezz*zx_d')'
	}

	if (estim>2)
	{
		ei[,9]=(-3*ex2_z'*inezz*zx_d')'
		ei[,10]=(-3*ey2_z'*inezz*zy_d')'
		ei[,11]=(-4*ey3x_z'*inezz*zy_d'-ey4_z'*inezz*zx_d')'
		ei[,12]=(-3*ey2x2_z'*inezz*zy_d'-2*ey3x_z'*inezz*zx_d')'
		ei[,13]=(-2*eyx3_z'*inezz*zy_d'-3*ey2x2_z'*inezz*zx_d')'
		ei[,14]=(-ex4_z'*inezz*zy_d'-4*eyx3_z'*inezz*zx_d')'
	}

	if (estim>3)
	{
		ei[,15]=(-4*ey3_z'*inezz*zy_d')'
		ei[,16]=(-4*ex3_z'*inezz*zx_d')'
		ei[,17]=(-5*ey4x_z'*inezz*zy_d'-ey5_z'*inezz*zx_d')'
		ei[,18]=(-4*ey3x2_z'*inezz*zy_d'-2*ey4x_z'*inezz*zx_d')'
		ei[,19]=(-3*ey2x3_z'*inezz*zy_d'-3*ey3x2_z'*inezz*zx_d')'
		ei[,20]=(-2*eyx4_z'*inezz*zy_d'-4*ey2x3_z'*inezz*zx_d')'
		ei[,21]=(-ex5_z'*inezz*zy_d'-5*eyx4_z'*inezz*zx_d')'
	}

	if (estim>4)
	{
		ei[,22]=(-5*ey4_z'*inezz*zy_d')'
		ei[,23]=(-5*ex4_z'*inezz*zx_d')'
		ei[,24]=(-6*ey5x_z'*inezz*zy_d'-ey6_z'*inezz*zx_d')'
		ei[,25]=(-5*ey4x2_z'*inezz*zy_d'-2*ey5x_z'*inezz*zx_d')'
		ei[,26]=(-4*ey3x3_z'*inezz*zy_d'-3*ey4x2_z'*inezz*zx_d')'
		ei[,27]=(-3*ey2x4_z'*inezz*zy_d'-4*ey3x3_z'*inezz*zx_d')'
		ei[,28]=(-2*eyx5_z'*inezz*zy_d'-5*ey2x4_z'*inezz*zx_d')'
		ei[,29]=(-ex6_z'*inezz*zy_d'-6*eyx5_z'*inezz*zx_d')'
	}

	f=f+ei
	
	return (f)
}


// subroutine to compute gradient matrix.
function grad1(a,neq)
{
	dvdc1=J(neq,1,0)
	dvdc2=J(neq,1,0)
	dvdc3=J(neq,1,0)
	dvdc4=J(neq,1,0)
	dvdc5=J(neq,1,0)

	dvdc1[1,1]=-2*a[1,1]*a[2,1]
	dvdc1[2,1]=-a[2,1]
	dvdc1[3,1]=0
	dvdc1[4,1]=-2*a[1,1]*a[5,1]
	dvdc1[5,1]=-a[5,1]

	dvdc2[1,1]=-(a[1,1]^2)
	dvdc2[2,1]=-a[1,1]
	dvdc2[3,1]=-1
	dvdc2[4,1]=0
	dvdc2[5,1]=0

	dvdc3[1,1]=-1
	dvdc3[2,1]=0
	dvdc3[3,1]=0
	dvdc3[4,1]=0
	dvdc3[5,1]=0

	dvdc4[1,1]=0
	dvdc4[2,1]=0
	dvdc4[3,1]=-1
	dvdc4[4,1]=0
	dvdc4[5,1]=0

	dvdc5[1,1]=0
	dvdc5[2,1]=0
	dvdc5[3,1]=0
	dvdc5[4,1]=-(a[1,1]^2)
	dvdc5[5,1]=-a[1,1]

	dvdc=(dvdc1,dvdc2,dvdc3,dvdc4,dvdc5)
	return(dvdc)
}

// subroutine to compute gradient matrix.
function grad2(a,neq)
{
	dvdc1=J(neq,1,0)
	dvdc2=J(neq,1,0)
	dvdc3=J(neq,1,0)
	dvdc4=J(neq,1,0)
	dvdc5=J(neq,1,0)
	dvdc6=J(neq,1,0)

	dvdc1[1,1]=-2*a[1,1]*a[2,1]
	dvdc1[2,1]=-a[2,1]
	dvdc1[3,1]=0
	dvdc1[4,1]=-2*a[1,1]*a[5,1]
	dvdc1[5,1]=-a[5,1]
	dvdc1[6,1]=-3*(a[1,1]^2)*a[6,1]-3*a[2,1]*a[3,1]
	dvdc1[7,1]=-2*a[1,1]*(a[6,1]+a[2,1]*a[4,1])
	dvdc1[8,1]=-a[6,1]-3*a[2,1]*a[4,1]

	dvdc2[1,1]=-(a[1,1]^2)
	dvdc2[2,1]=-a[1,1]
	dvdc2[3,1]=-1
	dvdc2[4,1]=0
	dvdc2[5,1]=0
	dvdc2[6,1]=-3*a[1,1]*a[3,1]
	dvdc2[7,1]=-(a[1,1]^2)*a[4,1]-a[3,1]
	dvdc2[8,1]=-3*a[1,1]*a[4,1]

	dvdc3[1,1]=-1
	dvdc3[2,1]=0
	dvdc3[3,1]=0
	dvdc3[4,1]=0
	dvdc3[5,1]=0
	dvdc3[6,1]=-3*a[1,1]*a[2,1]
	dvdc3[7,1]=-(a[2,1]+a[4,1])
	dvdc3[8,1]=0

	dvdc4[1,1]=0
	dvdc4[2,1]=0
	dvdc4[3,1]=-1
	dvdc4[4,1]=0
	dvdc4[5,1]=0
	dvdc4[6,1]=0
	dvdc4[7,1]=-(a[1,1]^2)*a[2,1]-a[3,1]
	dvdc4[8,1]=-3*a[1,1]*a[2,1]

	dvdc5[1,1]=0
	dvdc5[2,1]=0
	dvdc5[3,1]=0
	dvdc5[4,1]=-(a[1,1]^2)
	dvdc5[5,1]=-a[1,1]
	dvdc5[6,1]=0
	dvdc5[7,1]=0
	dvdc5[8,1]=0

	dvdc6[1,1]=0
	dvdc6[2,1]=0
	dvdc6[3,1]=0
	dvdc6[4,1]=0
	dvdc6[5,1]=0
	dvdc6[6,1]=-(a[1,1]^3)
	dvdc6[7,1]=-(a[1,1]^2)
	dvdc6[8,1]=-a[1,1]

	dvdc=(dvdc1,dvdc2,dvdc3,dvdc4,dvdc5,dvdc6)
	return(dvdc)
}

// subroutine to compute gradient matrix.
function grad3(a,neq)
{
	dvdc1=J(neq,1,0)
	dvdc2=J(neq,1,0)
	dvdc3=J(neq,1,0)
	dvdc4=J(neq,1,0)
	dvdc5=J(neq,1,0)
	dvdc6=J(neq,1,0)
	dvdc7=J(neq,1,0)
	dvdc8=J(neq,1,0)
	dvdc9=J(neq,1,0)

	dvdc1[1,1]=-2*a[1,1]*a[2,1]
	dvdc1[2,1]=-a[2,1]
	dvdc1[3,1]=0
	dvdc1[4,1]=-2*a[1,1]*a[5,1]
	dvdc1[5,1]=-a[5,1]
	dvdc1[6,1]=-3*(a[1,1]^2)*a[6,1]-3*a[2,1]*a[3,1]
	dvdc1[7,1]=-2*a[1,1]*(a[6,1]+a[2,1]*a[4,1])
	dvdc1[8,1]=-a[6,1]-3*a[2,1]*a[4,1]
	dvdc1[9,1]=0
	dvdc1[10,1]=-3*(a[1,1]^2)*a[5,1]
	dvdc1[11,1]=-4*(a[1,1]^3)*a[9,1]-12*a[1,1]*a[5,1]*a[3,1]/*
			  */-4*a[2,1]*a[8,1]
	dvdc1[12,1]=-3*(a[1,1]^2)*(a[9,1]+a[5,1]*a[4,1])/*
			  */-3*a[5,1]*a[3,1]
	dvdc1[13,1]=-2*a[1,1]*(a[9,1]+3*a[5,1]*a[4,1]+a[2,1]*a[7,1])
	dvdc1[14,1]=-(a[9,1]+6*a[5,1]*a[4,1]+4*a[2,1]*a[7,1])

	dvdc2[1,1]=-(a[1,1]^2)
	dvdc2[2,1]=-a[1,1]
	dvdc2[3,1]=-1
	dvdc2[4,1]=0
	dvdc2[5,1]=0
	dvdc2[6,1]=-3*a[1,1]*a[3,1]
	dvdc2[7,1]=-(a[1,1]^2)*a[4,1]-a[3,1]
	dvdc2[8,1]=-3*a[1,1]*a[4,1]
	dvdc2[9,1]=0
	dvdc2[10,1]=0
	dvdc2[11,1]=-4*a[1,1]*a[8,1]
	dvdc2[12,1]=-a[8,1]
	dvdc2[13,1]=-(a[1,1]^2)*a[7,1]
	dvdc2[14,1]=-4*a[1,1]*a[7,1]

	dvdc3[1,1]=-1
	dvdc3[2,1]=0
	dvdc3[3,1]=0
	dvdc3[4,1]=0
	dvdc3[5,1]=0
	dvdc3[6,1]=-3*a[1,1]*a[2,1]
	dvdc3[7,1]=-(a[2,1]+a[4,1])
	dvdc3[8,1]=0
	dvdc3[9,1]=0
	dvdc3[10,1]=0
	dvdc3[11,1]=-6*(a[1,1]^2)*a[5,1]
	dvdc3[12,1]=-3*a[1,1]*a[5,1]
	dvdc3[13,1]=-(a[5,1]+a[7,1])
	dvdc3[14,1]=0

	dvdc4[1,1]=0
	dvdc4[2,1]=0
	dvdc4[3,1]=-1
	dvdc4[4,1]=0
	dvdc4[5,1]=0
	dvdc4[6,1]=0
	dvdc4[7,1]=-(a[1,1]^2)*a[2,1]-a[3,1]
	dvdc4[8,1]=-3*a[1,1]*a[2,1]
	dvdc4[9,1]=0
	dvdc4[10,1]=0
	dvdc4[11,1]=0
	dvdc4[12,1]=-(a[1,1]^3)*a[5,1]-a[8,1]
	dvdc4[13,1]=-3*(a[1,1]^2)*a[5,1]
	dvdc4[14,1]=-6*a[1,1]*a[5,1]

	dvdc5[1,1]=0
	dvdc5[2,1]=0
	dvdc5[3,1]=0
	dvdc5[4,1]=-(a[1,1]^2)
	dvdc5[5,1]=-a[1,1]
	dvdc5[6,1]=0
	dvdc5[7,1]=0
	dvdc5[8,1]=0
	dvdc5[9,1]=-1
	dvdc5[10,1]=-(a[1,1]^3)
	dvdc5[11,1]=-6*(a[1,1]^2)*a[3,1]
	dvdc5[12,1]=-(a[1,1]^3)*a[4,1]-3*a[1,1]*a[3,1]
	dvdc5[13,1]=-3*(a[1,1]^2)*a[4,1]-a[3,1]
	dvdc5[14,1]=-6*a[1,1]*a[4,1]

	dvdc6[1,1]=0
	dvdc6[2,1]=0
	dvdc6[3,1]=0
	dvdc6[4,1]=0
	dvdc6[5,1]=0
	dvdc6[6,1]=-(a[1,1]^3)
	dvdc6[7,1]=-(a[1,1]^2)
	dvdc6[8,1]=-a[1,1]
	dvdc6[9,1]=0
	dvdc6[10,1]=0
	dvdc6[11,1]=0
	dvdc6[12,1]=0
	dvdc6[13,1]=0
	dvdc6[14,1]=0

	dvdc7[1,1]=0
	dvdc7[2,1]=0
	dvdc7[3,1]=0
	dvdc7[4,1]=0
	dvdc7[5,1]=0
	dvdc7[6,1]=0
	dvdc7[7,1]=0
	dvdc7[8,1]=0
	dvdc7[9,1]=-1
	dvdc7[10,1]=0
	dvdc7[11,1]=0
	dvdc7[12,1]=0
	dvdc7[13,1]=-(a[1,1]^2)*a[2,1]-a[3,1]
	dvdc7[14,1]=-4*a[1,1]*a[2,1]

	dvdc8[1,1]=0
	dvdc8[2,1]=0
	dvdc8[3,1]=0
	dvdc8[4,1]=0
	dvdc8[5,1]=0
	dvdc8[6,1]=0
	dvdc8[7,1]=0
	dvdc8[8,1]=0
	dvdc8[9,1]=0
	dvdc8[10,1]=-1
	dvdc8[11,1]=-4*a[1,1]*a[2,1]
	dvdc8[12,1]=-(a[2,1]+a[4,1])
	dvdc8[13,1]=0
	dvdc8[14,1]=0

	dvdc9[1,1]=0
	dvdc9[2,1]=0
	dvdc9[3,1]=0
	dvdc9[4,1]=0
	dvdc9[5,1]=0
	dvdc9[6,1]=0
	dvdc9[7,1]=0
	dvdc9[8,1]=0
	dvdc9[9,1]=0
	dvdc9[10,1]=0
	dvdc9[11,1]=-(a[1,1]^4)
	dvdc9[12,1]=-(a[1,1]^3)
	dvdc9[13,1]=-(a[1,1]^2)
	dvdc9[14,1]=-a[1,1]

	dvdc=(dvdc1,dvdc2,dvdc3,dvdc4,dvdc5,dvdc6,dvdc7,dvdc8,dvdc9)
	return(dvdc)
}



// subroutine to compute gradient matrix.
function grad4(a,neq)
{
	dvdc1=J(neq,1,0)
	dvdc2=J(neq,1,0)
	dvdc3=J(neq,1,0)
	dvdc4=J(neq,1,0)
	dvdc5=J(neq,1,0)
	dvdc6=J(neq,1,0)
	dvdc7=J(neq,1,0)
	dvdc8=J(neq,1,0)
	dvdc9=J(neq,1,0)
	dvdc10=J(neq,1,0)
	dvdc11=J(neq,1,0)
	dvdc12=J(neq,1,0)

	dvdc1[1,1]=-2*a[1,1]*a[2,1]
	dvdc1[2,1]=-a[2,1]
	dvdc1[3,1]=0
	dvdc1[4,1]=-2*a[1,1]*a[5,1]
	dvdc1[5,1]=-a[5,1]
	dvdc1[6,1]=-3*(a[1,1]^2)*a[6,1]-3*a[2,1]*a[3,1]
	dvdc1[7,1]=-2*a[1,1]*(a[6,1]+a[2,1]*a[4,1])
	dvdc1[8,1]=-a[6,1]-3*a[2,1]*a[4,1]
	dvdc1[9,1]=0
	dvdc1[10,1]=-3*(a[1,1]^2)*a[5,1]
	dvdc1[11,1]=-4*(a[1,1]^3)*a[9,1]-12*a[1,1]*a[5,1]*a[3,1]/*
			  */-4*a[2,1]*a[8,1]
	dvdc1[12,1]=-3*(a[1,1]^2)*(a[9,1]+a[5,1]*a[4,1])/*
			  */-3*a[5,1]*a[3,1]
	dvdc1[13,1]=-2*a[1,1]*(a[9,1]+3*a[5,1]*a[4,1]+a[2,1]*a[7,1])
	dvdc1[14,1]=-(a[9,1]+6*a[5,1]*a[4,1]+4*a[2,1]*a[7,1])
	dvdc1[15,1]=-4*(a[1,1]^3)*a[6,1]-12*a[1,1]*a[2,1]*a[3,1]
	dvdc1[16,1]=0
	dvdc1[17,1]=-5*(a[1,1]^4)*a[12,1]-30*(a[1,1]^2)*a[6,1]*a[3,1]/*
			  */-20*a[1,1]*a[5,1]*a[8,1]-5*a[2,1]*a[10,1]
	dvdc1[18,1]=-4*(a[1,1]^3)*(a[12,1]+a[6,1]*a[4,1])/*
			  */-12*a[1,1]*(a[6,1]*a[3,1]+a[2,1]*a[3,1]*a[4,1])/*
			  */-4*a[5,1]*a[8,1]
	dvdc1[19,1]=-3*(a[1,1]^2)*(a[12,1]+3*a[6,1]*a[4,1]+a[5,1]*a[7,1])/*
			  */-(3*a[6,1]*a[3,1]+9*a[2,1]*a[3,1]*a[4,1])
	dvdc1[20,1]=-2*a[1,1]*(a[12,1]+6*a[6,1]*a[4,1]+4*a[5,1]*a[7,1]/*
			  */+a[2,1]*a[11,1])
	dvdc1[21,1]=-(a[12,1]+10*a[6,1]*a[4,1]+10*a[5,1]*a[7,1]/*
			  */+5*a[2,1]*a[11,1])

	dvdc2[1,1]=-(a[1,1]^2)
	dvdc2[2,1]=-a[1,1]
	dvdc2[3,1]=-1
	dvdc2[4,1]=0
	dvdc2[5,1]=0
	dvdc2[6,1]=-3*a[1,1]*a[3,1]
	dvdc2[7,1]=-(a[1,1]^2)*a[4,1]-a[3,1]
	dvdc2[8,1]=-3*a[1,1]*a[4,1]
	dvdc2[9,1]=0
	dvdc2[10,1]=0
	dvdc2[11,1]=-4*a[1,1]*a[8,1]
	dvdc2[12,1]=-a[8,1]
	dvdc2[13,1]=-(a[1,1]^2)*a[7,1]
	dvdc2[14,1]=-4*a[1,1]*a[7,1]
	dvdc2[15,1]=-6*(a[1,1]^2)*a[3,1]
	dvdc2[16,1]=-6*a[4,1]
	dvdc2[17,1]=-5*a[1,1]*a[10,1]
	dvdc2[18,1]=-6*(a[1,1]^2)*a[3,1]*a[4,1]-a[10,1]
	dvdc2[19,1]=-9*a[1,1]*a[3,1]*a[4,1]
	dvdc2[20,1]=-(a[1,1]^2)*a[11,1]-6*a[3,1]*a[4,1]
	dvdc2[21,1]=-5*a[1,1]*a[11,1]

	dvdc3[1,1]=-1
	dvdc3[2,1]=0
	dvdc3[3,1]=0
	dvdc3[4,1]=0
	dvdc3[5,1]=0
	dvdc3[6,1]=-3*a[1,1]*a[2,1]
	dvdc3[7,1]=-(a[2,1]+a[4,1])
	dvdc3[8,1]=0
	dvdc3[9,1]=0
	dvdc3[10,1]=0
	dvdc3[11,1]=-6*(a[1,1]^2)*a[5,1]
	dvdc3[12,1]=-3*a[1,1]*a[5,1]
	dvdc3[13,1]=-(a[5,1]+a[7,1])
	dvdc3[14,1]=0
	dvdc3[15,1]=-6*(a[1,1]^2)*a[2,1]
	dvdc3[16,1]=0
	dvdc3[17,1]=-10*(a[1,1]^3)*a[6,1]
	dvdc3[18,1]=-6*(a[1,1]^2)*(a[6,1]+a[2,1])
	dvdc3[19,1]=-a[1,1]*(3*a[6,1]+9*a[2,1]*a[4,1])
	dvdc3[20,1]=-(a[6,1]+6*a[2,1]*a[4,1]+a[11,1])
	dvdc3[21,1]=0

	dvdc4[1,1]=0
	dvdc4[2,1]=0
	dvdc4[3,1]=-1
	dvdc4[4,1]=0
	dvdc4[5,1]=0
	dvdc4[6,1]=0
	dvdc4[7,1]=-(a[1,1]^2)*a[2,1]-a[3,1]
	dvdc4[8,1]=-3*a[1,1]*a[2,1]
	dvdc4[9,1]=0
	dvdc4[10,1]=0
	dvdc4[11,1]=0
	dvdc4[12,1]=-(a[1,1]^3)*a[5,1]-a[8,1]
	dvdc4[13,1]=-3*(a[1,1]^2)*a[5,1]
	dvdc4[14,1]=-6*a[1,1]*a[5,1]
	dvdc4[15,1]=0
	dvdc4[16,1]=-6*a[2,1]
	dvdc4[17,1]=0
	dvdc4[18,1]=-(a[1,1]^4)*a[6,1]-6*(a[1,1]^2)*a[2,1]*a[3,1]-a[10,1]
	dvdc4[19,1]=-3*(a[1,1]^3)*a[6,1]-9*a[1,1]*a[2,1]*a[3,1]
	dvdc4[20,1]=-6*(a[1,1]^2)*a[6,1]-6*a[2,1]*a[3,1]
	dvdc4[21,1]=-10*a[1,1]*a[6,1]

	dvdc5[1,1]=0
	dvdc5[2,1]=0
	dvdc5[3,1]=0
	dvdc5[4,1]=-(a[1,1]^2)
	dvdc5[5,1]=-a[1,1]
	dvdc5[6,1]=0
	dvdc5[7,1]=0
	dvdc5[8,1]=0
	dvdc5[9,1]=-1
	dvdc5[10,1]=-(a[1,1]^3)
	dvdc5[11,1]=-6*(a[1,1]^2)*a[3,1]
	dvdc5[12,1]=-(a[1,1]^3)*a[4,1]-3*a[1,1]*a[3,1]
	dvdc5[13,1]=-3*(a[1,1]^2)*a[4,1]-a[3,1]
	dvdc5[14,1]=-6*a[1,1]*a[4,1]
	dvdc5[15,1]=0
	dvdc5[16,1]=0
	dvdc5[17,1]=-10*(a[1,1]^2)*a[8,1]
	dvdc5[18,1]=-4*a[1,1]*a[8,1]
	dvdc5[19,1]=-(a[1,1]^3)*a[7,1]-a[8,1]
	dvdc5[20,1]=-4*(a[1,1]^2)*a[7,1]
	dvdc5[21,1]=-10*a[1,1]*a[7,1]

	dvdc6[1,1]=0
	dvdc6[2,1]=0
	dvdc6[3,1]=0
	dvdc6[4,1]=0
	dvdc6[5,1]=0
	dvdc6[6,1]=-(a[1,1]^3)
	dvdc6[7,1]=-(a[1,1]^2)
	dvdc6[8,1]=-a[1,1]
	dvdc6[9,1]=0
	dvdc6[10,1]=0
	dvdc6[11,1]=0
	dvdc6[12,1]=0
	dvdc6[13,1]=0
	dvdc6[14,1]=0
	dvdc6[15,1]=-(a[1,1]^4)
	dvdc6[16,1]=-1
	dvdc6[17,1]=-10*(a[1,1]^3)*a[3,1]
	dvdc6[18,1]=-(a[1,1]^4)*a[4,1]-6*(a[1,1]^2)*a[3,1]
	dvdc6[19,1]=-3*(a[1,1]^3)*a[4,1]-3*a[1,1]*a[3,1]
	dvdc6[20,1]=-6*(a[1,1]^2)*a[4,1]-a[3,1]
	dvdc6[21,1]=-10*a[1,1]*a[4,1]

	dvdc7[1,1]=0
	dvdc7[2,1]=0
	dvdc7[3,1]=0
	dvdc7[4,1]=0
	dvdc7[5,1]=0
	dvdc7[6,1]=0
	dvdc7[7,1]=0
	dvdc7[8,1]=0
	dvdc7[9,1]=-1
	dvdc7[10,1]=0
	dvdc7[11,1]=0
	dvdc7[12,1]=0
	dvdc7[13,1]=-(a[1,1]^2)*a[2,1]-a[3,1]
	dvdc7[14,1]=-4*a[1,1]*a[2,1]
	dvdc7[15,1]=0
	dvdc7[16,1]=0
	dvdc7[17,1]=0
	dvdc7[18,1]=0
	dvdc7[19,1]=-(a[1,1]^3)*a[5,1]-a[8,1]
	dvdc7[20,1]=-4*(a[1,1]^2)*a[5,1]
	dvdc7[21,1]=-10*a[1,1]*a[5,1]

	dvdc8[1,1]=0
	dvdc8[2,1]=0
	dvdc8[3,1]=0
	dvdc8[4,1]=0
	dvdc8[5,1]=0
	dvdc8[6,1]=0
	dvdc8[7,1]=0
	dvdc8[8,1]=0
	dvdc8[9,1]=0
	dvdc8[10,1]=-1
	dvdc8[11,1]=-4*a[1,1]*a[2,1]
	dvdc8[12,1]=-(a[2,1]+a[4,1])
	dvdc8[13,1]=0
	dvdc8[14,1]=0
	dvdc8[15,1]=0
	dvdc8[16,1]=0
	dvdc8[17,1]=-10*(a[1,1]^2)*a[5,1]
	dvdc8[18,1]=-4*a[1,1]*a[5,1]
	dvdc8[19,1]=-(a[5,1]+a[7,1])
	dvdc8[20,1]=0
	dvdc8[21,1]=0

	dvdc9[1,1]=0
	dvdc9[2,1]=0
	dvdc9[3,1]=0
	dvdc9[4,1]=0
	dvdc9[5,1]=0
	dvdc9[6,1]=0
	dvdc9[7,1]=0
	dvdc9[8,1]=0
	dvdc9[9,1]=0
	dvdc9[10,1]=0
	dvdc9[11,1]=-(a[1,1]^4)
	dvdc9[12,1]=-(a[1,1]^3)
	dvdc9[13,1]=-(a[1,1]^2)
	dvdc9[14,1]=-a[1,1]
	dvdc9[15,1]=0
	dvdc9[16,1]=0
	dvdc9[17,1]=0
	dvdc9[18,1]=0
	dvdc9[19,1]=0
	dvdc9[20,1]=0
	dvdc9[21,1]=0

	dvdc10[1,1]=0
	dvdc10[2,1]=0
	dvdc10[3,1]=0
	dvdc10[4,1]=0
	dvdc10[5,1]=0
	dvdc10[6,1]=0
	dvdc10[7,1]=0
	dvdc10[8,1]=0
	dvdc10[9,1]=0
	dvdc10[10,1]=0
	dvdc10[11,1]=0
	dvdc10[12,1]=0
	dvdc10[13,1]=0
	dvdc10[14,1]=0
	dvdc10[15,1]=-1
	dvdc10[16,1]=0
	dvdc10[17,1]=-5*a[1,1]*a[2,1]
	dvdc10[18,1]=-(a[2,1]+a[4,1])
	dvdc10[19,1]=0
	dvdc10[20,1]=0
	dvdc10[21,1]=0

	dvdc11[1,1]=0
	dvdc11[2,1]=0
	dvdc11[3,1]=0
	dvdc11[4,1]=0
	dvdc11[5,1]=0
	dvdc11[6,1]=0
	dvdc11[7,1]=0
	dvdc11[8,1]=0
	dvdc11[9,1]=0
	dvdc11[10,1]=0
	dvdc11[11,1]=0
	dvdc11[12,1]=0
	dvdc11[13,1]=0
	dvdc11[14,1]=0
	dvdc11[15,1]=0
	dvdc11[16,1]=-1
	dvdc11[17,1]=0
	dvdc11[18,1]=0
	dvdc11[19,1]=0
	dvdc11[20,1]=-(a[1,1]^2)*a[2,1]-a[3,1]
	dvdc11[21,1]=-5*a[1,1]*a[2,1]

	dvdc12[1,1]=0
	dvdc12[2,1]=0
	dvdc12[3,1]=0
	dvdc12[4,1]=0
	dvdc12[5,1]=0
	dvdc12[6,1]=0
	dvdc12[7,1]=0
	dvdc12[8,1]=0
	dvdc12[9,1]=0
	dvdc12[10,1]=0
	dvdc12[11,1]=0
	dvdc12[12,1]=0
	dvdc12[13,1]=0
	dvdc12[14,1]=0
	dvdc12[15,1]=0
	dvdc12[16,1]=0
	dvdc12[17,1]=-(a[1,1]^5)
	dvdc12[18,1]=-(a[1,1]^4)
	dvdc12[19,1]=-(a[1,1]^3)
	dvdc12[20,1]=-(a[1,1]^2)
	dvdc12[21,1]=-a[1,1]

	dvdc=(dvdc1,dvdc2,dvdc3,dvdc4,dvdc5,dvdc6,dvdc7,dvdc8,dvdc9,dvdc10,dvdc11,dvdc12)
	return(dvdc)
}



// subroutine to compute gradient matrix.
function grad5(a,neq)
{
	dvdc1=J(neq,1,0)
	dvdc2=J(neq,1,0)
	dvdc3=J(neq,1,0)
	dvdc4=J(neq,1,0)
	dvdc5=J(neq,1,0)
	dvdc6=J(neq,1,0)
	dvdc7=J(neq,1,0)
	dvdc8=J(neq,1,0)
	dvdc9=J(neq,1,0)
	dvdc10=J(neq,1,0)
	dvdc11=J(neq,1,0)
	dvdc12=J(neq,1,0)
	dvdc13=J(neq,1,0)
	dvdc14=J(neq,1,0)
	dvdc15=J(neq,1,0)

	dvdc1[1,1]=-2*a[1,1]*a[2,1]
	dvdc1[2,1]=-a[2,1]
	dvdc1[3,1]=0
	dvdc1[4,1]=-2*a[1,1]*a[5,1]
	dvdc1[5,1]=-a[5,1]
	dvdc1[6,1]=-3*(a[1,1]^2)*a[6,1]-3*a[2,1]*a[3,1]
	dvdc1[7,1]=-2*a[1,1]*(a[6,1]+a[2,1]*a[4,1])
	dvdc1[8,1]=-a[6,1]-3*a[2,1]*a[4,1]
	dvdc1[9,1]=0
	dvdc1[10,1]=-3*(a[1,1]^2)*a[5,1]
	dvdc1[11,1]=-4*(a[1,1]^3)*a[9,1]-12*a[1,1]*a[5,1]*a[3,1]/*
			  */-4*a[2,1]*a[8,1]
	dvdc1[12,1]=-3*(a[1,1]^2)*(a[9,1]+a[5,1]*a[4,1])/*
			  */-3*a[5,1]*a[3,1]
	dvdc1[13,1]=-2*a[1,1]*(a[9,1]+3*a[5,1]*a[4,1]+a[2,1]*a[7,1])
	dvdc1[14,1]=-(a[9,1]+6*a[5,1]*a[4,1]+4*a[2,1]*a[7,1])
	dvdc1[15,1]=-4*(a[1,1]^3)*a[6,1]-12*a[1,1]*a[2,1]*a[3,1]
	dvdc1[16,1]=0
	dvdc1[17,1]=-5*(a[1,1]^4)*a[12,1]-30*(a[1,1]^2)*a[6,1]*a[3,1]/*
			  */-20*a[1,1]*a[5,1]*a[8,1]-5*a[2,1]*a[10,1]
	dvdc1[18,1]=-4*(a[1,1]^3)*(a[12,1]+a[6,1]*a[4,1])/*
			  */-12*a[1,1]*(a[6,1]*a[3,1]+a[2,1]*a[3,1]*a[4,1])/*
			  */-4*a[5,1]*a[8,1]
	dvdc1[19,1]=-3*(a[1,1]^2)*(a[12,1]+3*a[6,1]*a[4,1]+a[5,1]*a[7,1])/*
			  */-(3*a[6,1]*a[3,1]+9*a[2,1]*a[3,1]*a[4,1])
	dvdc1[20,1]=-2*a[1,1]*(a[12,1]+6*a[6,1]*a[4,1]+4*a[5,1]*a[7,1]/*
			  */+a[2,1]*a[11,1])
	dvdc1[21,1]=-(a[12,1]+10*a[6,1]*a[4,1]+10*a[5,1]*a[7,1]/*
			  */+5*a[2,1]*a[11,1])
	dvdc1[22,1]=-5*(a[1,1]^4)*a[9,1]-30*(a[1,1]^2)*a[5,1]*a[3,1]/*
			  */-20*a[1,1]*a[2,1]*a[8,1]
	dvdc1[23,1]=0
	dvdc1[24,1]=-6*(a[1,1]^5)*a[15,1]-60*(a[1,1]^3)*a[9,1]*a[3,1]/*
			  */-60*(a[1,1]^2)*a[6,1]*a[8,1]-30*a[1,1]*a[5,1]*a[10,1]/*
			  */-6*a[2,1]*a[13,1]
	dvdc1[25,1]=-5*(a[1,1]^4)*(a[15,1]+a[9,1]*a[4,1])/*
			  */-30*(a[1,1]^2)*(a[9,1]*a[3,1]+a[5,1]*a[3,1]*a[4,1])/*
			  */-20*a[1,1]*(a[6,1]*a[8,1]+a[2,1]*a[8,1]*a[4,1])/*
			  */-5*a[5,1]*a[10,1]
	dvdc1[26,1]=-4*(a[1,1]^3)*(a[15,1]+3*a[9,1]*a[4,1]+a[6,1]*a[7,1])/*
			  */-12*a[1,1]*(a[9,1]*a[3,1]+3*a[5,1]*a[3,1]*a[4,1]+a[2,1]*a[3,1]*a[7,1])/*
			  */-4*(a[6,1]*a[8,1]+3*a[2,1]*a[8,1]*a[4,1])
	dvdc1[27,1]=-3*(a[1,1]^2)*(a[15,1]+6*a[9,1]*a[4,1]+4*a[6,1]*a[7,1]+a[5,1]*a[11,1])/*
			  */-(3*a[9,1]*a[3,1]+18*a[5,1]*a[3,1]*a[4,1]+12*a[2,1]*a[3,1]*a[7,1])
	dvdc1[28,1]=-2*a[1,1]*(a[15,1]+10*a[9,1]*a[4,1]+10*a[6,1]*a[7,1]+5*a[5,1]*a[11,1]/*
			  */+a[2,1]*a[14,1])
	dvdc1[29,1]=-(a[15,1]+15*a[9,1]*a[4,1]+20*a[6,1]*a[7,1]/*
			  */+15*a[5,1]*a[11,1]+6*a[2,1]*a[14,1])

	dvdc2[1,1]=-(a[1,1]^2)
	dvdc2[2,1]=-a[1,1]
	dvdc2[3,1]=-1
	dvdc2[4,1]=0
	dvdc2[5,1]=0
	dvdc2[6,1]=-3*a[1,1]*a[3,1]
	dvdc2[7,1]=-(a[1,1]^2)*a[4,1]-a[3,1]
	dvdc2[8,1]=-3*a[1,1]*a[4,1]
	dvdc2[9,1]=0
	dvdc2[10,1]=0
	dvdc2[11,1]=-4*a[1,1]*a[8,1]
	dvdc2[12,1]=-a[8,1]
	dvdc2[13,1]=-(a[1,1]^2)*a[7,1]
	dvdc2[14,1]=-4*a[1,1]*a[7,1]
	dvdc2[15,1]=-6*(a[1,1]^2)*a[3,1]
	dvdc2[16,1]=-6*a[4,1]
	dvdc2[17,1]=-5*a[1,1]*a[10,1]
	dvdc2[18,1]=-6*(a[1,1]^2)*a[3,1]*a[4,1]-a[10,1]
	dvdc2[19,1]=-9*a[1,1]*a[3,1]*a[4,1]
	dvdc2[20,1]=-(a[1,1]^2)*a[11,1]-6*a[3,1]*a[4,1]
	dvdc2[21,1]=-5*a[1,1]*a[11,1]
	dvdc2[22,1]=-10*(a[1,1]^2)*a[8,1]
	dvdc2[23,1]=-10*a[7,1]
	dvdc2[24,1]=-6*a[1,1]*a[13,1]
	dvdc2[25,1]=-10*(a[1,1]^2)*a[8,1]*a[4,1]-a[13,1]
	dvdc2[26,1]=-6*(a[1,1]^2)*a[3,1]*a[7,1]-12*a[1,1]*a[8,1]*a[4,1]
	dvdc2[27,1]=-12*a[1,1]*a[3,1]*a[7,1]-6*a[8,1]*a[4,1]
	dvdc2[28,1]=-(a[1,1]^2)*a[14,1]-10*a[3,1]*a[7,1]
	dvdc2[29,1]=-6*a[1,1]*a[14,1]

	dvdc3[1,1]=-1
	dvdc3[2,1]=0
	dvdc3[3,1]=0
	dvdc3[4,1]=0
	dvdc3[5,1]=0
	dvdc3[6,1]=-3*a[1,1]*a[2,1]
	dvdc3[7,1]=-(a[2,1]+a[4,1])
	dvdc3[8,1]=0
	dvdc3[9,1]=0
	dvdc3[10,1]=0
	dvdc3[11,1]=-6*(a[1,1]^2)*a[5,1]
	dvdc3[12,1]=-3*a[1,1]*a[5,1]
	dvdc3[13,1]=-(a[5,1]+a[7,1])
	dvdc3[14,1]=0
	dvdc3[15,1]=-6*(a[1,1]^2)*a[2,1]
	dvdc3[16,1]=0
	dvdc3[17,1]=-10*(a[1,1]^3)*a[6,1]
	dvdc3[18,1]=-6*(a[1,1]^2)*(a[6,1]+a[2,1])
	dvdc3[19,1]=-a[1,1]*(3*a[6,1]+9*a[2,1]*a[4,1])
	dvdc3[20,1]=-(a[6,1]+6*a[2,1]*a[4,1]+a[11,1])
	dvdc3[21,1]=0
	dvdc3[22,1]=-10*(a[1,1]^3)*a[5,1]
	dvdc3[23,1]=0
	dvdc3[24,1]=-15*(a[1,1]^4)*a[9,1]
	dvdc3[25,1]=-10*(a[1,1]^3)*(a[9,1]+a[5,1]*a[4,1])
	dvdc3[26,1]=-6*(a[1,1]^2)*(a[9,1]+3*a[5,1]*a[4,1]+a[2,1]*a[7,1])
	dvdc3[27,1]=-a[1,1]*(3*a[9,1]+18*a[5,1]*a[4,1]+12*a[2,1]*a[7,1])
	dvdc3[28,1]=-(a[9,1]+10*a[5,1]*a[4,1]+10*a[2,1]*a[7,1]+a[14,1])
	dvdc3[29,1]=0

	dvdc4[1,1]=0
	dvdc4[2,1]=0
	dvdc4[3,1]=-1
	dvdc4[4,1]=0
	dvdc4[5,1]=0
	dvdc4[6,1]=0
	dvdc4[7,1]=-(a[1,1]^2)*a[2,1]-a[3,1]
	dvdc4[8,1]=-3*a[1,1]*a[2,1]
	dvdc4[9,1]=0
	dvdc4[10,1]=0
	dvdc4[11,1]=0
	dvdc4[12,1]=-(a[1,1]^3)*a[5,1]-a[8,1]
	dvdc4[13,1]=-3*(a[1,1]^2)*a[5,1]
	dvdc4[14,1]=-6*a[1,1]*a[5,1]
	dvdc4[15,1]=0
	dvdc4[16,1]=-6*a[2,1]
	dvdc4[17,1]=0
	dvdc4[18,1]=-(a[1,1]^4)*a[6,1]-6*(a[1,1]^2)*a[2,1]*a[3,1]-a[10,1]
	dvdc4[19,1]=-3*(a[1,1]^3)*a[6,1]-9*a[1,1]*a[2,1]*a[3,1]
	dvdc4[20,1]=-6*(a[1,1]^2)*a[6,1]-6*a[2,1]*a[3,1]
	dvdc4[21,1]=-10*a[1,1]*a[6,1]
	dvdc4[22,1]=0
	dvdc4[23,1]=-10*a[5,1]
	dvdc4[24,1]=0
	dvdc4[25,1]=-(a[1,1]^5)*a[9,1]-10*(a[1,1]^3)*a[5,1]*a[3,1]/*
			  */-10*(a[1,1]^2)*a[2,1]*a[8,1]-a[13,1]
	dvdc4[26,1]=-3*(a[1,1]^4)*a[9,1]-18*(a[1,1]^2)*a[5,1]*a[3,1]/*
			  */-12*a[1,1]*a[2,1]*a[8,1]
	dvdc4[27,1]=-6*(a[1,1]^3)*a[9,1]-18*a[1,1]*a[5,1]*a[3,1]/*
			  */-6*a[8,1]*a[2,1]
	dvdc4[28,1]=-10*(a[1,1]^2)*a[9,1]-10*a[3,1]*a[5,1]
	dvdc4[29,1]=-15*a[1,1]*a[9,1]

	dvdc5[1,1]=0
	dvdc5[2,1]=0
	dvdc5[3,1]=0
	dvdc5[4,1]=-(a[1,1]^2)
	dvdc5[5,1]=-a[1,1]
	dvdc5[6,1]=0
	dvdc5[7,1]=0
	dvdc5[8,1]=0
	dvdc5[9,1]=-1
	dvdc5[10,1]=-(a[1,1]^3)
	dvdc5[11,1]=-6*(a[1,1]^2)*a[3,1]
	dvdc5[12,1]=-(a[1,1]^3)*a[4,1]-3*a[1,1]*a[3,1]
	dvdc5[13,1]=-3*(a[1,1]^2)*a[4,1]-a[3,1]
	dvdc5[14,1]=-6*a[1,1]*a[4,1]
	dvdc5[15,1]=0
	dvdc5[16,1]=0
	dvdc5[17,1]=-10*(a[1,1]^2)*a[8,1]
	dvdc5[18,1]=-4*a[1,1]*a[8,1]
	dvdc5[19,1]=-(a[1,1]^3)*a[7,1]-a[8,1]
	dvdc5[20,1]=-4*(a[1,1]^2)*a[7,1]
	dvdc5[21,1]=-10*a[1,1]*a[7,1]
	dvdc5[22,1]=-10*(a[1,1]^3)*a[3,1]
	dvdc5[23,1]=-10*a[4,1]
	dvdc5[24,1]=-15*(a[1,1]^2)*a[10,1]
	dvdc5[25,1]=-10*(a[1,1]^3)*a[3,1]*a[4,1]-5*a[1,1]*a[10,1]
	dvdc5[26,1]=-18*(a[1,1]^2)*a[3,1]*a[4,1]-a[10,1]
	dvdc5[27,1]=-(a[1,1]^3)*a[11,1]-18*a[1,1]*a[3,1]*a[4,1]
	dvdc5[28,1]=-5*(a[1,1]^2)*a[11,1]-10*a[3,1]*a[4,1]
	dvdc5[29,1]=-15*a[1,1]*a[11,1]

	dvdc6[1,1]=0
	dvdc6[2,1]=0
	dvdc6[3,1]=0
	dvdc6[4,1]=0
	dvdc6[5,1]=0
	dvdc6[6,1]=-(a[1,1]^3)
	dvdc6[7,1]=-(a[1,1]^2)
	dvdc6[8,1]=-a[1,1]
	dvdc6[9,1]=0
	dvdc6[10,1]=0
	dvdc6[11,1]=0
	dvdc6[12,1]=0
	dvdc6[13,1]=0
	dvdc6[14,1]=0
	dvdc6[15,1]=-(a[1,1]^4)
	dvdc6[16,1]=-1
	dvdc6[17,1]=-10*(a[1,1]^3)*a[3,1]
	dvdc6[18,1]=-(a[1,1]^4)*a[4,1]-6*(a[1,1]^2)*a[3,1]
	dvdc6[19,1]=-3*(a[1,1]^3)*a[4,1]-3*a[1,1]*a[3,1]
	dvdc6[20,1]=-6*(a[1,1]^2)*a[4,1]-a[3,1]
	dvdc6[21,1]=-10*a[1,1]*a[4,1]
	dvdc6[22,1]=0
	dvdc6[23,1]=0
	dvdc6[24,1]=-20*(a[1,1]^3)*a[8,1]
	dvdc6[25,1]=-10*(a[1,1]^2)*a[8,1]
	dvdc6[26,1]=-(a[1,1]^4)*a[7,1]-4*a[1,1]*a[8,1]
	dvdc6[27,1]=-4*(a[1,1]^3)*a[7,1]-a[8,1]
	dvdc6[28,1]=-10*(a[1,1]^2)*a[7,1]
	dvdc6[29,1]=-20*a[1,1]*a[7,1]

	dvdc7[1,1]=0
	dvdc7[2,1]=0
	dvdc7[3,1]=0
	dvdc7[4,1]=0
	dvdc7[5,1]=0
	dvdc7[6,1]=0
	dvdc7[7,1]=0
	dvdc7[8,1]=0
	dvdc7[9,1]=-1
	dvdc7[10,1]=0
	dvdc7[11,1]=0
	dvdc7[12,1]=0
	dvdc7[13,1]=-(a[1,1]^2)*a[2,1]-a[3,1]
	dvdc7[14,1]=-4*a[1,1]*a[2,1]
	dvdc7[15,1]=0
	dvdc7[16,1]=0
	dvdc7[17,1]=0
	dvdc7[18,1]=0
	dvdc7[19,1]=-(a[1,1]^3)*a[5,1]-a[8,1]
	dvdc7[20,1]=-4*(a[1,1]^2)*a[5,1]
	dvdc7[21,1]=-10*a[1,1]*a[5,1]
	dvdc7[22,1]=0
	dvdc7[23,1]=-10*a[2,1]
	dvdc7[24,1]=0
	dvdc7[25,1]=0
	dvdc7[26,1]=-(a[1,1]^4)*a[6,1]-6*(a[1,1]^2)*a[2,1]*a[3,1]-a[10,1]
	dvdc7[27,1]=-4*(a[1,1]^3)*a[6,1]-12*a[1,1]*a[2,1]*a[3,1]
	dvdc7[28,1]=-10*(a[1,1]^2)*a[6,1]-10*a[3,1]*a[2,1]
	dvdc7[29,1]=-20*a[1,1]*a[6,1]

	dvdc8[1,1]=0
	dvdc8[2,1]=0
	dvdc8[3,1]=0
	dvdc8[4,1]=0
	dvdc8[5,1]=0
	dvdc8[6,1]=0
	dvdc8[7,1]=0
	dvdc8[8,1]=0
	dvdc8[9,1]=0
	dvdc8[10,1]=-1
	dvdc8[11,1]=-4*a[1,1]*a[2,1]
	dvdc8[12,1]=-(a[2,1]+a[4,1])
	dvdc8[13,1]=0
	dvdc8[14,1]=0
	dvdc8[15,1]=0
	dvdc8[16,1]=0
	dvdc8[17,1]=-10*(a[1,1]^2)*a[5,1]
	dvdc8[18,1]=-4*a[1,1]*a[5,1]
	dvdc8[19,1]=-(a[5,1]+a[7,1])
	dvdc8[20,1]=0
	dvdc8[21,1]=0
	dvdc8[22,1]=-10*(a[1,1]^2)*a[2,1]
	dvdc8[23,1]=0
	dvdc8[24,1]=-20*(a[1,1]^3)*a[6,1]
	dvdc8[25,1]=-10*(a[1,1]^2)*(a[6,1]+a[2,1]*a[4,1])
	dvdc8[26,1]=-4*a[1,1]*(a[6,1]+3*a[2,1]*a[4,1])
	dvdc8[27,1]=-(a[6,1]+6*a[2,1]*a[4,1]+a[11,1])
	dvdc8[28,1]=0
	dvdc8[29,1]=0

	dvdc9[1,1]=0
	dvdc9[2,1]=0
	dvdc9[3,1]=0
	dvdc9[4,1]=0
	dvdc9[5,1]=0
	dvdc9[6,1]=0
	dvdc9[7,1]=0
	dvdc9[8,1]=0
	dvdc9[9,1]=0
	dvdc9[10,1]=0
	dvdc9[11,1]=-(a[1,1]^4)
	dvdc9[12,1]=-(a[1,1]^3)
	dvdc9[13,1]=-(a[1,1]^2)
	dvdc9[14,1]=-a[1,1]
	dvdc9[15,1]=0
	dvdc9[16,1]=0
	dvdc9[17,1]=0
	dvdc9[18,1]=0
	dvdc9[19,1]=0
	dvdc9[20,1]=0
	dvdc9[21,1]=0
	dvdc9[22,1]=-(a[1,1]^5)
	dvdc9[23,1]=-1
	dvdc9[24,1]=-15*(a[1,1]^4)*a[3,1]
	dvdc9[25,1]=-(a[1,1]^5)*a[4,1]-10*(a[1,1]^3)*a[3,1]
	dvdc9[26,1]=-3*(a[1,1]^4)*a[4,1]-6*(a[1,1]^2)*a[3,1]
	dvdc9[27,1]=-6*(a[1,1]^3)*a[4,1]-3*a[1,1]*a[3,1]
	dvdc9[28,1]=-10*(a[1,1]^2)*a[4,1]-a[3,1]
	dvdc9[29,1]=-15*a[1,1]*a[4,1]

	dvdc10[1,1]=0
	dvdc10[2,1]=0
	dvdc10[3,1]=0
	dvdc10[4,1]=0
	dvdc10[5,1]=0
	dvdc10[6,1]=0
	dvdc10[7,1]=0
	dvdc10[8,1]=0
	dvdc10[9,1]=0
	dvdc10[10,1]=0
	dvdc10[11,1]=0
	dvdc10[12,1]=0
	dvdc10[13,1]=0
	dvdc10[14,1]=0
	dvdc10[15,1]=-1
	dvdc10[16,1]=0
	dvdc10[17,1]=-5*a[1,1]*a[2,1]
	dvdc10[18,1]=-(a[2,1]+a[4,1])
	dvdc10[19,1]=0
	dvdc10[20,1]=0
	dvdc10[21,1]=0
	dvdc10[22,1]=0
	dvdc10[23,1]=0
	dvdc10[24,1]=-15*(a[1,1]^2)*a[5,1]
	dvdc10[25,1]=-5*a[1,1]*a[5,1]
	dvdc10[26,1]=-(a[5,1]+a[7,1])
	dvdc10[27,1]=0
	dvdc10[28,1]=0
	dvdc10[29,1]=0

	dvdc11[1,1]=0
	dvdc11[2,1]=0
	dvdc11[3,1]=0
	dvdc11[4,1]=0
	dvdc11[5,1]=0
	dvdc11[6,1]=0
	dvdc11[7,1]=0
	dvdc11[8,1]=0
	dvdc11[9,1]=0
	dvdc11[10,1]=0
	dvdc11[11,1]=0
	dvdc11[12,1]=0
	dvdc11[13,1]=0
	dvdc11[14,1]=0
	dvdc11[15,1]=0
	dvdc11[16,1]=-1
	dvdc11[17,1]=0
	dvdc11[18,1]=0
	dvdc11[19,1]=0
	dvdc11[20,1]=-(a[1,1]^2)*a[2,1]-a[3,1]
	dvdc11[21,1]=-5*a[1,1]*a[2,1]
	dvdc11[22,1]=0
	dvdc11[23,1]=0
	dvdc11[24,1]=0
	dvdc11[25,1]=0
	dvdc11[26,1]=0
	dvdc11[27,1]=-(a[1,1]^3)*a[5,1]-a[8,1]
	dvdc11[28,1]=-5*(a[1,1]^2)*a[5,1]
	dvdc11[29,1]=-15*a[1,1]*a[5,1]

	dvdc12[1,1]=0
	dvdc12[2,1]=0
	dvdc12[3,1]=0
	dvdc12[4,1]=0
	dvdc12[5,1]=0
	dvdc12[6,1]=0
	dvdc12[7,1]=0
	dvdc12[8,1]=0
	dvdc12[9,1]=0
	dvdc12[10,1]=0
	dvdc12[11,1]=0
	dvdc12[12,1]=0
	dvdc12[13,1]=0
	dvdc12[14,1]=0
	dvdc12[15,1]=0
	dvdc12[16,1]=0
	dvdc12[17,1]=-(a[1,1]^5)
	dvdc12[18,1]=-(a[1,1]^4)
	dvdc12[19,1]=-(a[1,1]^3)
	dvdc12[20,1]=-(a[1,1]^2)
	dvdc12[21,1]=-a[1,1]
	dvdc12[22,1]=0
	dvdc12[23,1]=0
	dvdc12[24,1]=0
	dvdc12[25,1]=0
	dvdc12[26,1]=0
	dvdc12[27,1]=0
	dvdc12[28,1]=0
	dvdc12[29,1]=0

	dvdc13[1,1]=0
	dvdc13[2,1]=0
	dvdc13[3,1]=0
	dvdc13[4,1]=0
	dvdc13[5,1]=0
	dvdc13[6,1]=0
	dvdc13[7,1]=0
	dvdc13[8,1]=0
	dvdc13[9,1]=0
	dvdc13[10,1]=0
	dvdc13[11,1]=0
	dvdc13[12,1]=0
	dvdc13[13,1]=0
	dvdc13[14,1]=0
	dvdc13[15,1]=0
	dvdc13[16,1]=0
	dvdc13[17,1]=0
	dvdc13[18,1]=0
	dvdc13[19,1]=0
	dvdc13[20,1]=0
	dvdc13[21,1]=0
	dvdc13[22,1]=-1
	dvdc13[23,1]=0
	dvdc13[24,1]=-6*a[1,1]*a[2,1]
	dvdc13[25,1]=-(a[2,1]+a[4,1])
	dvdc13[26,1]=0
	dvdc13[27,1]=0
	dvdc13[28,1]=0
	dvdc13[29,1]=0

	dvdc14[1,1]=0
	dvdc14[2,1]=0
	dvdc14[3,1]=0
	dvdc14[4,1]=0
	dvdc14[5,1]=0
	dvdc14[6,1]=0
	dvdc14[7,1]=0
	dvdc14[8,1]=0
	dvdc14[9,1]=0
	dvdc14[10,1]=0
	dvdc14[11,1]=0
	dvdc14[12,1]=0
	dvdc14[13,1]=0
	dvdc14[14,1]=0
	dvdc14[15,1]=0
	dvdc14[16,1]=0
	dvdc14[17,1]=0
	dvdc14[18,1]=0
	dvdc14[19,1]=0
	dvdc14[20,1]=0
	dvdc14[21,1]=0
	dvdc14[22,1]=0
	dvdc14[23,1]=-1
	dvdc14[24,1]=0
	dvdc14[25,1]=0
	dvdc14[26,1]=0
	dvdc14[27,1]=0
	dvdc14[28,1]=-(a[1,1]^2)*a[2,1]-a[3,1]
	dvdc14[29,1]=-6*a[1,1]*a[2,1]

	dvdc15[1,1]=0
	dvdc15[2,1]=0
	dvdc15[3,1]=0
	dvdc15[4,1]=0
	dvdc15[5,1]=0
	dvdc15[6,1]=0
	dvdc15[7,1]=0
	dvdc15[8,1]=0
	dvdc15[9,1]=0
	dvdc15[10,1]=0
	dvdc15[11,1]=0
	dvdc15[12,1]=0
	dvdc15[13,1]=0
	dvdc15[14,1]=0
	dvdc15[15,1]=0
	dvdc15[16,1]=0
	dvdc15[17,1]=0
	dvdc15[18,1]=0
	dvdc15[19,1]=0
	dvdc15[20,1]=0
	dvdc15[21,1]=0
	dvdc15[22,1]=0
	dvdc15[23,1]=0
	dvdc15[24,1]=-(a[1,1]^6)
	dvdc15[25,1]=-(a[1,1]^5)
	dvdc15[26,1]=-(a[1,1]^4)
	dvdc15[27,1]=-(a[1,1]^3)
	dvdc15[28,1]=-(a[1,1]^2)
	dvdc15[29,1]=-a[1,1]

	dvdc=(dvdc1,dvdc2,dvdc3,dvdc4,dvdc5,dvdc6,dvdc7,dvdc8,dvdc9,dvdc10,dvdc11,dvdc12,dvdc13,dvdc14,dvdc15)
	return(dvdc)
}



// Subroutine to compute squeezes.
//
// This subroutine compares the values of the objective function at the
// points c+s*dc and c+0.5*s*dc, with dc = the proposed change in the vector
// of parameters, and with step length s initially at 1. s is halved until
// minus the objective function stops declining.
function squeez4(s_c,s_dc,ey2_d,eyx_d,ex2_d,ey2x_d,eyx2_d,ey3x_d,ey2x2_d,eyx3_d,ex3_d,/*
              */ ey3_d,ey4x_d,ey3x2_d,ey2x3_d,eyx4_d,ey4_d,ex4_d,ey5x_d,ey4x2_d,/*
              */ ey3x3_d,ey2x4_d,eyx5_d,ey5_d,ex5_d,ey6x_d,ey5x2_d,ey4x3_d,/*
              */ ey3x4_d,ey2x5_d,eyx6_d,maxsqez,obj,estim,neq,w,ID)
{
	s_c1=s_c-s_dc
	s_lm=1/2
	s_itr=1

	if (ID==3 || ID==4)
	{
		s_f1 = EWIDcvec(ey2_d,ex2_d,eyx_d,ey3x_d,ey2x2_d,eyx3_d,ey2x_d,eyx2_d,ID) - s_c1
	}
	else
	{
		s_f1=deff(s_c1,ey2_d,eyx_d,ex2_d,ey2x_d,eyx2_d,ey3x_d,ey2x2_d,eyx3_d,ex3_d,/*
			   */ ey3_d,ey4x_d,ey3x2_d,ey2x3_d,eyx4_d,ey4_d,ex4_d,ey5x_d,ey4x2_d,/*
			   */ ey3x3_d,ey2x4_d,eyx5_d,ey5_d,ex5_d,ey6x_d,ey5x2_d,ey4x3_d,/*
			   */ ey3x4_d,ey2x5_d,eyx6_d,estim,neq)
	}
	lc1 = s_f1'*w*s_f1

	while (s_itr<=maxsqez)
	{
		s_c2=s_c-s_lm*s_dc
		if (ID==3 || ID==4)
		{
			s_f2 = EWIDcvec(ey2_d,ex2_d,eyx_d,ey3x_d,ey2x2_d,eyx3_d,ey2x_d,eyx2_d,ID) - s_c2
		}
		else
		{
			s_f2=deff(s_c2,ey2_d,eyx_d,ex2_d,ey2x_d,eyx2_d,ey3x_d,ey2x2_d,eyx3_d,ex3_d,/*
				   */ ey3_d,ey4x_d,ey3x2_d,ey2x3_d,eyx4_d,ey4_d,ex4_d,ey5x_d,ey4x2_d,/*
				   */ ey3x3_d,ey2x4_d,eyx5_d,ey5_d,ex5_d,ey6x_d,ey5x2_d,ey4x3_d,/*
				   */ ey3x4_d,ey2x5_d,eyx6_d,estim,neq)
		}
		lc2 = s_f2'*w*s_f2

		if (lc1 <= lc2 && lc1 <= obj) 
		{
			s=(s_c1\s_itr-1)
			return(s)
		}
		else
		{
			s_c1=s_c2
			s_lm=s_lm/2
			lc1=lc2
			s_itr=s_itr+1
		}
	}
	
	s=(s_c2\s_itr-1)
	return(s)
}

// Subroutine to do the GMM optimuization step
function EWgmm(w,c,ey2_d,eyx_d,ex2_d,ey2x_d,eyx2_d,ey3x_d,ey2x2_d,eyx3_d,/*
		    */ ex3_d,ey3_d,ey4x_d,ey3x2_d,ey2x3_d,eyx4_d,ey4_d,ex4_d,ey5x_d,/*
			*/ ey4x2_d,ey3x3_d,ey2x4_d,eyx5_d,ey5_d,ex5_d,ey6x_d,ey5x2_d,/*
	   	    */ ey4x3_d,ey3x4_d,ey2x5_d,eyx6_d,estim,neq,ID)
{
	//-------------set internal optimization variables------------
	maxiter=299
	maxsqez=240
	tol=1e-9

	//-------------start of iteration loop------------------------
	iter=1
	dc=1                     // Initialize the step length.

	while (norm(dc,.)>=tol)
	{
		if (ID==3 || ID==4)
		{
			f = EWIDcvec(ey2_d,ex2_d,eyx_d,ey3x_d,ey2x2_d,eyx3_d,ey2x_d,eyx2_d,ID) - c
			g = -I(neq)
		} 
		else
		{
			f=deff(c,ey2_d,eyx_d,ex2_d,ey2x_d,eyx2_d,ey3x_d,ey2x2_d,eyx3_d,ex3_d,ey3_d,ey4x_d,/*
				  */ ey3x2_d,ey2x3_d,eyx4_d,ey4_d,ex4_d,ey5x_d,ey4x2_d,ey3x3_d,ey2x4_d,eyx5_d,/*
				  */ ey5_d,ex5_d,ey6x_d,ey5x2_d,ey4x3_d,ey3x4_d,ey2x5_d,eyx6_d,estim,neq)    

			if (estim==2)
			{
				g=grad2(c,neq)                  
			}																		
			else if (estim==3)
			{
				g=grad3(c,neq)
			}
			else if (estim==4)
			{
				g=grad4(c,neq)
			}
			else if (estim==5)
			{
				g=grad5(c,neq)
			}
		}

		obj = f'*w*f                // This computes the value of the objective function.

		gwg= g'*w*g                 // This uses the GAUSS-NEWTON method to compute full step dc.
		gwf= g'*w*f
		dc= pinv(gwg)*gwf

		if (maxsqez > 0) 
		{
			s=squeez4(c,dc,ey2_d,eyx_d,ex2_d,ey2x_d,eyx2_d,ey3x_d,ey2x2_d,eyx3_d,ex3_d,/*
						*/ ey3_d,ey4x_d,ey3x2_d,ey2x3_d,eyx4_d,ey4_d,ex4_d,ey5x_d,ey4x2_d,/*
						*/ ey3x3_d,ey2x4_d,eyx5_d,ey5_d,ex5_d,ey6x_d,ey5x2_d,ey4x3_d,/*
						*/ ey3x4_d,ey2x5_d,eyx6_d,maxsqez,obj,estim,neq,w,ID)
			c_new = s[1..rows(c),1]
		}
		else
		{
			c_new=c-dc
		}

		dc=c_new-c                      // Update variables for the next iteration.
		c=c_new

		iter=iter+1
		if (iter>=maxiter)   			// Quit iterating if necessary.
		{           
			break
		}
	}
	
	return(c)
}

function EWIDcvec(ey2_d,ex2_d,eyx_d,ey3x_d,ey2x2_d,eyx3_d,ey2x_d,eyx2_d,ID)
{
	if (ID==3)
	{
		c = J(2,1,0)
		c[1,1] = ey2x_d
		c[2,1] = eyx2_d
	}
	else if (ID==4)
	{
		c = J(8,1,0)
		c[1,1] = ey2_d
		c[2,1] = ex2_d
		c[3,1] = eyx_d
		c[4,1] = ey3x_d
		c[5,1] = ey2x2_d
		c[6,1] = eyx3_d
		c[7,1] = ey2x_d
		c[8,1] = eyx2_d
	}
	else
	{
		errprintf("ID = %d is not a valid option\n", ID)
		exit(error(198))
	}

	return (c)
}

function EWIDoptw(y2_d,yx_d,x2_d,y2x_d,yx2_d,y3x_d,y2x2_d,yx3_d,inezz,zy_d,zx_d,/*
			   */ eyx_z,ey2_z,ex2_z,ey3_z,ey2x_z,eyx2_z,ex3_z,n,neq,c,ID)
{
	f=J(n,neq,0)

	if (ID==3)
	{
		f[,1] = y2x_d  :- c[1,1] + (-2*eyx_z'*inezz*zy_d'  - ey2_z'*inezz*zx_d')'
		f[,2] = yx2_d  :- c[2,1] + (-ex2_z'*inezz*zy_d'    - 2*eyx_z'*inezz*zx_d')'
	}

	if (ID==4)
	{
		f[,1] = y2_d   :- c[1,1]
		f[,2] = yx_d   :- c[2,1]
		f[,3] = x2_d   :- c[3,1]
		f[,4] = y3x_d  :- c[4,1] + (-3*ey2x_z'*inezz*zy_d' - ey3_z'*inezz*zx_d')'
		f[,5] = y2x2_d :- c[5,1] + (-2*eyx2_z'*inezz*zy_d' - 2*ey2x_z'*inezz*zx_d')'
		f[,6] = yx3_d  :- c[6,1] + (-ex3_z'*inezz*zy_d'    - 3*eyx2_z'*inezz*zx_d')'
		f[,7] = y2x_d  :- c[7,1] + (-2*eyx_z'*inezz*zy_d'  - ey2_z'*inezz*zx_d')'
		f[,8] = yx2_d  :- c[8,1] + (-ex2_z'*inezz*zy_d'    - 2*eyx_z'*inezz*zx_d')'
	}

	return (f)
}


void doEW(string scalar depvar, string scalar misindep, string scalar indepvars, 	///
          string scalar meth, string scalar bXint, 									///
		  string scalar hascons, string scalar touse)
{
	st_view(y, ., depvar, touse)
	st_view(x, ., misindep, touse)
	st_view(z=., ., tokens(indepvars), touse)
	bXint_nums = strtoreal(tokens(bXint))
	
	n = rows(y)

	if (hascons=="")
	{
		con = J(n,1,1)
		z = (con,z)
	}

	nz = cols(z)
	
	// Build all the ugly matrices
	{
	mux=pinv(z'*z)*(z'*x)
	muy=pinv(z'*z)*(z'*y)
	y_d=y-z*muy
	x_d=x-z*mux

	y2_d=y_d:^2
	yx_d=(x_d:*y_d)
	x2_d=x_d:^2
	y2x_d=(x_d:*y2_d)
	yx2_d=(x2_d:*y_d)
	y3x_d=y2x_d:*y_d
	y2x2_d=y2_d:*x2_d
	yx3_d=yx2_d:*x_d

	x3_d=x_d:*x2_d
	y3_d=y_d:*y2_d
	y4x_d=y3_d:*yx_d
	y3x2_d=y3_d:*x2_d
	y2x3_d=y2_d:*x3_d
	yx4_d=yx_d:*x3_d
	y4_d=y2_d:^2
	x4_d=x2_d:^2
	y5x_d=y_d:*y4x_d
	y4x2_d=y_d:*y3x2_d
	y3x3_d=y_d:*y2x3_d
	y2x4_d=y_d:*yx4_d
	yx5_d=yx4_d:*x_d

	y5_d=y2_d:*y3_d
	x5_d=x2_d:*x3_d
	y6x_d=y5_d:*yx_d
	y5x2_d=y5_d:*x2_d
	y4x3_d=y4_d:*x3_d
	y3x4_d=y3_d:*x4_d
	y2x5_d=y2_d:*x5_d
	yx6_d=yx_d:*x5_d

	ey2_d=mean(y2_d)
	eyx_d=mean(yx_d)
	ex2_d=mean(x2_d)
	ey2x_d=mean(y2x_d)
	eyx2_d=mean(yx2_d)
	ey3x_d=mean(y3x_d)
	ey2x2_d=mean(y2x2_d)
	eyx3_d=mean(yx3_d)

	ex3_d=mean(x3_d)
	ey3_d=mean(y3_d)
	ey4x_d=mean(y4x_d)
	ey3x2_d=mean(y3x2_d)
	ey2x3_d=mean(y2x3_d)
	eyx4_d=mean(yx4_d)
	ey4_d=mean(y4_d)
	ex4_d=mean(x4_d)
	ey5x_d=mean(y5x_d)
	ey4x2_d=mean(y4x2_d)
	ey3x3_d=mean(y3x3_d)
	ey2x4_d=mean(y2x4_d)
	eyx5_d=mean(yx5_d)

	ey5_d=mean(y5_d)
	ex5_d=mean(x5_d)
	ey6x_d=mean(y6x_d)
	ey5x2_d=mean(y5x2_d)
	ey4x3_d=mean(y4x3_d)
	ey3x4_d=mean(y3x4_d)
	ey2x5_d=mean(y2x5_d)
	eyx6_d=mean(yx6_d)


	// Make the moments for the correct standard errors for beta.

	y6_d=y_d:^6
	x6_d=x_d:^6

	idx = J(nz,1,1)
	ey2_z   = mean(y2_d[,idx]:*z)'
	eyx_z   = mean(yx_d[,idx]:*z)'
	ex2_z   = mean(x2_d[,idx]:*z)'
	ey2x_z  = mean(y2x_d[,idx]:*z)'
	eyx2_z  = mean(yx2_d[,idx]:*z)'
	ey3x_z  = mean(y3x_d[,idx]:*z)'
	ey2x2_z = mean(y2x2_d[,idx]:*z)'
	eyx3_z  = mean(yx3_d[,idx]:*z)'
	ey3_z   = mean(y3_d[,idx]:*z)'
	ex3_z   = mean(x3_d[,idx]:*z)'
	ey4x_z  = mean(y4x_d[,idx]:*z)'
	ey3x2_z = mean(y3x2_d[,idx]:*z)'
	ey2x3_z = mean(y2x3_d[,idx]:*z)'
	eyx4_z  = mean(yx4_d[,idx]:*z)'
	ey4_z   = mean(y4_d[,idx]:*z)'
	ex4_z   = mean(x4_d[,idx]:*z)'
	ey5x_z  = mean(y5x_d[,idx]:*z)'
	ey4x2_z = mean(y4x2_d[,idx]:*z)'
	ey3x3_z = mean(y3x3_d[,idx]:*z)'
	ey2x4_z = mean(y2x4_d[,idx]:*z)'
	eyx5_z  = mean(yx5_d[,idx]:*z)'
	ey5_z   = mean(y5_d[,idx]:*z)'
	ex5_z   = mean(x5_d[,idx]:*z)'
	ey6x_z  = mean(y6x_d[,idx]:*z)'
	ey5x2_z = mean(y5x2_d[,idx]:*z)'
	ey4x3_z = mean(y4x3_d[,idx]:*z)'
	ey3x4_z = mean(y3x4_d[,idx]:*z)'
	ey2x5_z = mean(y2x5_d[,idx]:*z)'
	eyx6_z  = mean(yx6_d[,idx]:*z)'
	ey6_z   = mean(y6_d[,idx]:*z)'
	ex6_z   = mean(x6_d[,idx]:*z)'

	ezz = (z'*z)/n
	inezz = pinv(ezz)
	zy_d = z:*y_d[,idx]
	zx_d = z:*x_d[,idx]
	}

	//----------here we do identification tests.------------------
	for (ID=3;ID<=4;ID++)
	{
		c   = EWIDcvec(ey2_d,ex2_d,eyx_d,ey3x_d,ey2x2_d,eyx3_d,ey2x_d,eyx2_d,ID)
		neq = rows(c)
		ff  = EWIDoptw(y2_d,yx_d,x2_d,y2x_d,yx2_d,y3x_d,y2x2_d,yx3_d,inezz,zy_d,zx_d,/*
			        */ eyx_z,ey2_z,ex2_z,ey3_z,ey2x_z,eyx2_z,ex3_z,n,neq,c,ID)
		w   = pinv((ff'*ff)/n)
		c   = EWgmm(w,c,ey2_d,eyx_d,ex2_d,ey2x_d,eyx2_d,ey3x_d,ey2x2_d,eyx3_d,/*
		         */ ex3_d,ey3_d,ey4x_d,ey3x2_d,ey2x3_d,eyx4_d,ey4_d,ex4_d,ey5x_d,/*
				 */ ey4x2_d,ey3x3_d,ey2x4_d,eyx5_d,ey5_d,ex5_d,ey6x_d,ey5x2_d,/*
				 */ ey4x3_d,ey3x4_d,ey2x5_d,eyx6_d,-1,neq,ID)
		ff  = EWIDoptw(y2_d,yx_d,x2_d,y2x_d,yx2_d,y3x_d,y2x2_d,yx3_d,inezz,zy_d,zx_d,/*
			        */ eyx_z,ey2_z,ex2_z,ey3_z,ey2x_z,eyx2_z,ex3_z,n,neq,c,ID)
		w   = pinv((ff'*ff)/n)
		if (ID==3)
		{
			ID3val  = n*c'*w*c     		//Newey West Wald test for c==0
			ID3stat = 1-chi2(2,ID3val)
		}
		if (ID==4)
		{
			Cum4 = J(5,1,0)
			Cum4[1,1] = ey3x_d  - 3*eyx_d*ey2_d
			Cum4[2,1] = ey2x2_d - ey2_d*ex2_d - 2*eyx_d^2
			Cum4[3,1] = eyx3_d  - 3*eyx_d*ex2_d
			Cum4[4,1] = ey2x_d
			Cum4[5,1] = eyx2_d
			
			Vee = J(5,neq,0)
			Vee[1,1] = -3*eyx_d
			Vee[1,2] = -3*ey2_d
			Vee[1,4] = 1
			Vee[2,1] = -ex2_d
			Vee[2,2] = -4*eyx_d
			Vee[2,3] = -ey2_d
			Vee[2,5] = 1
			Vee[3,2] = -3*ex2_d
			Vee[3,3] = -3*eyx_d
			Vee[3,6] = 1
			Vee[4,7] = 1
			Vee[5,8] = 1

			w = pinv(Vee*((ff'*ff)/n)*Vee')
			ID4val  = n*Cum4'*w*Cum4
			ID4stat = 1-chi2(5,ID4val)
		}
	}

	
	// Now define method
	
	if (strupper(meth)=="GMM3" || meth=="")
	{
		nc=5
		neq=5
		estim=1
	}
	else if (strupper(meth)=="GMM4")
	{
		nc=6
		neq=8
		estim=2
	}
	else if (strupper(meth)=="GMM5")
	{
		nc=9
		neq=14
		estim=3
	}
	else if (strupper(meth)=="GMM6")
	{
		nc=12
		neq=21
		estim=4
	}
	else if (strupper(meth)=="GMM7")
	{
		nc=15
		neq=29
		estim=5
	}
	else
	{
		errprintf("method = %s is not a valid option\n", meth)
		exit(error(198))
	}

	// Start the GMM part
	//----------here we input the starting values.----------------

	if (estim==1)
	{
		bXint_nums = 0
	}

	c       = J(nc,1,0)
	bXlen   = cols(bXint_nums)
	objsave = J(bXlen,1,0)

	for (rep=1;rep<=(bXlen+1);rep++)
	{
		if (rep<(bXlen+1))
		{
			c[1,1] = bXint_nums[1,rep]
		}
		else
		{
			if (bXlen>1)
			{
				// restore best inital value
				minindex(objsave, 1, ind, where)
				c[1,1] = bXint_nums[1,ind[1,1]]
			}
			else
			{
				// no point in restoring - only one value tested
				break
			}
		}
	
		if (c[1,1]==0)
		{
			c[1,1]=(ey2x_d)/(eyx2_d)
		}
			
		c[2,1]=(eyx_d)/c[1,1]
		c[3,1]=(ey2_d)-(c[1,1]^2)*c[2,1]
		c[4,1]=(ex2_d)-c[2,1]
		c[5,1]=(eyx2_d)/c[1,1]

		if (estim>1)
		{
			c[6,1]=((eyx3_d)-3*c[1,1]*c[2,1]*c[4,1])/c[1,1]
		}
		if (estim>2)
		{
			c[7,1]=(ex3_d)-c[5,1]
			c[8,1]=(ey3_d)-(c[1,1]^3)*c[5,1]
			c[9,1]=((eyx4_d)/c[1,1])-6*c[5,1]*c[4,1]-4*c[2,1]*c[7,1]
		}
		if (estim>3)
		{
			c[10,1]=(ey4_d)-(c[1,1]^4)*c[6,1]-6*(c[1,1]^2)*c[2,1]*c[3,1]
			c[11,1]=(ex4_d)-c[6,1]-6*c[2,1]*c[4,1]
			c[12,1]=((eyx5_d)/c[1,1])-10*c[6,1]*c[4,1]-10*c[5,1]*c[7,1] ///
					-5*c[2,1]*c[11,1]
		}
		if (estim>4)
		{
			c[13,1]=(ey5_d)-(c[1,1]^5)*c[9,1]-10*(c[1,1]^3)*c[5,1]*c[3,1] ///
					-10*(c[1,1]^2)*c[2,1]*c[8,1]
			c[14,1]=(ex5_d)-c[9,1]-10*c[5,1]*c[4,1]-10*c[2,1]*c[7,1]
			c[15,1]=((eyx6_d)/c[1,1])-15*c[9,1]*c[4,1]-20*c[6,1]*c[7,1] ///
					-15*c[5,1]*c[11,1]-6*c[2,1]*c[14,1]
		}

		// We only need to maximize if the estimator is not exactly identified -> not
		// for GMM3, but for all the rest. Note that gradX calculates analytical
		// derivetives
		if (estim>1)
		{
			//--------the program creates the weighting matrix.------------
			ff=optw(y2_d,yx_d,x2_d,y2x_d,yx2_d,y3x_d,y2x2_d,yx3_d,x3_d,y3_d,y4x_d,/*
				  */y3x2_d,y2x3_d,yx4_d,y4_d,x4_d,y5x_d,y4x2_d,y3x3_d,y2x4_d,yx5_d,/*
				  */y5_d,x5_d,y6x_d,y5x2_d,y4x3_d,y3x4_d,y2x5_d,yx6_d,/*
				  */ey2_d,eyx_d,ex2_d,ey2x_d,eyx2_d,ey3x_d,ey2x2_d,eyx3_d,ex3_d,/*
				  */ey3_d,ey4x_d,ey3x2_d,ey2x3_d,eyx4_d,ey4_d,ex4_d,ey5x_d,ey4x2_d,/*
				  */ey3x3_d,ey2x4_d,eyx5_d,ey5_d,ex5_d,ey6x_d,ey5x2_d,ey4x3_d,/*
				  */ey3x4_d,ey2x5_d,eyx6_d,/*
				  */inezz,zy_d,zx_d,eyx_z,ey2_z,ex2_z,ey3_z,ey2x_z,eyx2_z,ex3_z,ey4_z,/*
				  */ey3x_z,ey2x2_z,eyx3_z,ex4_z,ey5_z,ey4x_z,ey3x2_z,ey2x3_z,eyx4_z,ex5_z,/*
				  */ey6_z,ey5x_z,ey4x2_z,ey3x3_z,ey2x4_z,eyx5_z,ex6_z,n,neq,estim)
			w=pinv((ff'*ff)/n)

			c = EWgmm(w,c,ey2_d,eyx_d,ex2_d,ey2x_d,eyx2_d,ey3x_d,ey2x2_d,eyx3_d,/*
				   */ ex3_d,ey3_d,ey4x_d,ey3x2_d,ey2x3_d,eyx4_d,ey4_d,ex4_d,ey5x_d,/*
				   */ ey4x2_d,ey3x3_d,ey2x4_d,eyx5_d,ey5_d,ex5_d,ey6x_d,ey5x2_d,/*
				   */ ey4x3_d,ey3x4_d,ey2x5_d,eyx6_d,estim,neq,0)
		}

		// Now do t-stats and friends

		ff=optw(y2_d,yx_d,x2_d,y2x_d,yx2_d,y3x_d,y2x2_d,yx3_d,x3_d,y3_d,y4x_d,/*
			  */y3x2_d,y2x3_d,yx4_d,y4_d,x4_d,y5x_d,y4x2_d,y3x3_d,y2x4_d,yx5_d,/*
			  */y5_d,x5_d,y6x_d,y5x2_d,y4x3_d,y3x4_d,y2x5_d,yx6_d,/*
			  */ey2_d,eyx_d,ex2_d,ey2x_d,eyx2_d,ey3x_d,ey2x2_d,eyx3_d,ex3_d,/*
			  */ey3_d,ey4x_d,ey3x2_d,ey2x3_d,eyx4_d,ey4_d,ex4_d,ey5x_d,ey4x2_d,/*
			  */ey3x3_d,ey2x4_d,eyx5_d,ey5_d,ex5_d,ey6x_d,ey5x2_d,ey4x3_d,/*
			  */ey3x4_d,ey2x5_d,eyx6_d,/*
			  */inezz,zy_d,zx_d,eyx_z,ey2_z,ex2_z,ey3_z,ey2x_z,eyx2_z,ex3_z,ey4_z,/*
			  */ey3x_z,ey2x2_z,eyx3_z,ex4_z,ey5_z,ey4x_z,ey3x2_z,ey2x3_z,eyx4_z,ex5_z,/*
			  */ey6_z,ey5x_z,ey4x2_z,ey3x3_z,ey2x4_z,eyx5_z,ex6_z,n,neq,estim)
		f=deff(c,ey2_d,eyx_d,ex2_d,ey2x_d,eyx2_d,ey3x_d,ey2x2_d,eyx3_d,ex3_d,ey3_d,ey4x_d,/*
			  */ ey3x2_d,ey2x3_d,eyx4_d,ey4_d,ex4_d,ey5x_d,ey4x2_d,ey3x3_d,ey2x4_d,eyx5_d,/*
			  */ ey5_d,ex5_d,ey6x_d,ey5x2_d,ey4x3_d,ey3x4_d,ey2x5_d,eyx6_d,estim,neq)    
		w=pinv((ff'*ff)/n)
		obj = f'*w*f
		
		if (rep<(bXlen+1))
		{
			objsave[rep,1]=obj
		}
	}


	if (estim==1)
	{
		g=grad1(c,neq)
	}
	else if (estim==2)
	{
		g=grad2(c,neq)
	}
	else if (estim==3)
	{
		g=grad3(c,neq)
	}
	else if (estim==4)
	{
		g=grad4(c,neq)
	}
	else if (estim==5)
	{
		g=grad5(c,neq)
	}

	gwg=g'*w*g
	vcX=pinv(gwg)/n
	stderr=sqrt(diagonal(vcX))
	inflnc=-n*vcX*g'*w*ff'

	bX  = c[1,1]						
	seX = stderr[1,1]					
	inflncX = inflnc[1,]'
	dfree = neq-nc

	if (estim>1)
	{
		Jstat = obj*n					
		Jval  = 1-chi2(dfree,Jstat)	
	}
	else
	{
		Jstat = -1						
		Jval  = -1						
	}

	// Make bZ, seZ and friends

	c11 = c[1,1]
	bZ = muy[,1]-c11*mux[,1]

	gee = J((nz*2+1), nz, 0)
	gee[1..nz,1..nz] = I(nz)
	gee[(nz+1)..(nz*2),1..nz] = -c11*I(nz)
	gee[(nz*2+1),] = -mux[,1]'

	bigphi = ((inezz*zy_d')\(inezz*zx_d')\(-inflnc[1,]))
	avar = (bigphi*bigphi')/n:^2
	vcZ = gee'*avar*gee
	seZ = sqrt(diagonal(vcZ))
	inflncZ = -bigphi'*gee

	//--------------rho2 and tau2-------------------------------------------------
	ez = mean(z)
	sigz=(z-J(n,1,1)#ez)'*(z-J(n,1,1)#ez)/n

	numer=muy'*sigz*muy + c[1,1]:^2*c[2,1]
	rho=numer/(numer+c[3,1])					

	numer=mux'*sigz*mux + c[2,1]
	tau=numer/(numer+c[4,1])					

	vecsigz=J(nz+nz*(nz-1)/2,1,0)
	vecsigz[1..nz,1]=diagonal(sigz)

	phiz=J(n,nz+nz*(nz-1)/2,0)
	phiz[,1..nz]=(z-J(n,1,1)#ez):*(z-J(n,1,1)#ez)

	// here we pack the top half of the sigz matrix into a vector
	counter=nz+nz*(nz-1)/2
	for (qq=nz;qq>=2;qq--)
	{
		for (ee=qq-1;ee>=1;ee--)
		{
			vecsigz[counter,1]=sigz[ee,qq]
			phiz[,counter]=(z[,ee]-J(n,1,1)#ez[1,ee]):*(z[,qq]-J(n,1,1)#ez[1,qq])
			counter=counter-1
		}
	}

	phiz=phiz-J(n,1,1)#vecsigz'
	phimuy=inezz*zy_d'
	phimux=inezz*zx_d'

	//--make the influence functions for the standard errors for rho2 and tau2.
	bigphi=(phimux\phimuy\(phiz')\(-inflnc[1..4,]))
	avar=(bigphi*bigphi')/n:^2
	//--------------first column is for rho2 and the second is for tau2.
	gee = J(2*nz+(nz+nz*(nz-1)/2)+4,2,0)
	//-----------first,do rho2---------------------------
	numer=muy'*sigz*muy + c[1,1]:^2*c[2,1]
	denom=numer + c[3,1]; ;
	//------------derivatives wrt muy---------------------
	for (qq=1;qq<=nz;qq++)
	{
		gee[nz+qq,1]= (2*muy'*sigz[,qq])/denom - numer*(2*muy'*sigz[,qq])/(denom:^2)
	}
	//------------derivatives wrt the first part of sigz--
	for (qq=1;qq<=nz;qq++)
	{
		gee[2*nz+qq,1]=(muy[qq,1]:^2)/denom-numer/(denom:^2)*muy[qq,1]:^2
	}
	//------------derivatives wrt the second part of sigz--
	counter=2*nz+(nz+nz*(nz-1)/2)
	for (qq=nz;qq>=2;qq--)
	{
		for (ee=qq-1;ee>=1;ee--)
		{
			gee[counter,1]= 2*muy[ee,1]*muy[qq,1]/denom-2*numer/(denom:^2)*muy[ee,1]*muy[qq,1]
			counter=counter-1
		}
	}
	//------------derivatives wrt c--
	counter=2*nz+(nz+nz*(nz-1)/2)
	gee[counter+1,1]=2*c[1,1]*c[2,1]/denom-2*numer/(denom:^2)*c[1,1]*c[2,1]
	gee[counter+2,1]=(c[1,1]:^2)/denom-numer/(denom:^2)*c[1,1]:^2
	gee[counter+3,1]=-numer/(denom:^2)

	//-----------now for tau2------------------------
	numer=mux'*sigz*mux+c[2,1]
	denom=numer+c[4,1]
	//------------derivatives wrt mux---------------------
	for (qq=1;qq<=nz;qq++)
	{
		gee[qq,2]=(2*mux'*sigz[,qq])/denom-numer*(2*mux'*sigz[,qq])/(denom:^2)
	}
	//------------derivatives wrt the first part of sigz--
	for (qq=1;qq<=nz;qq++)
	{
		gee[2*nz+qq,2]=(mux[qq,1]:^2)/denom-numer/(denom:^2)*mux[qq,1]:^2
	}
	//------------derivatives wrt the second part of sigz--
	counter=2*nz+(nz+nz*(nz-1)/2)
	for (qq=nz;qq>=2;qq--)
	{
		for (ee=qq-1;ee>=1;ee--)
		{
			gee[counter,2]= 2*mux[ee,1]*mux[qq,1]/denom-2*numer/(denom:^2)*mux[ee,1]*mux[qq,1]
			counter=counter-1
		}
	}
	//------------derivatives wrt c--
	counter=2*nz+(nz+nz*(nz-1)/2)
	gee[counter+2,2]=1/denom-numer/(denom:^2)
	gee[counter+4,2]=-numer/(denom:^2)


	//--------------done with influnence funcs. Now use them.----------------------

	vcrhotau=gee'*avar*gee

	inflncrho=-bigphi'*gee[,1]				
	inflnctau=-bigphi'*gee[,2]				

	SErho=sqrt(vcrhotau[1,1])			
	SEtau=sqrt(vcrhotau[2,2])			

	//--------------All done. Save return values and exit.--------------------------
	beta = J(nz+1,1,1)
	beta[1,1] = bX
	beta[2..(nz+1),1] = bZ
	inflnc = inflncX, inflncZ
	vcmat = inflnc'*inflnc/n:^2
	serr = sqrt(diagonal(vcmat))
	st_matrix("r(beta)",beta')
	st_matrix("r(VCmat)",vcmat)
	st_matrix("serr",serr)
	st_matrix("inflnc",inflnc)
	st_numscalar("r(N)",n)
	st_numscalar("r(Jstat)",Jstat)
	st_numscalar("r(Jval)",Jval)
	st_numscalar("r(dfree)",dfree)
	st_numscalar("r(rho)",rho)
	st_numscalar("r(tau)",tau)
	st_numscalar("r(SErho)",SErho)
	st_numscalar("r(SEtau)",SEtau)
	st_matrix("vcrhotau",vcrhotau)
	st_matrix("inflncrhotau",(inflncrho, inflnctau))
	st_matrix("w",w)
	st_numscalar("r(obj)",obj)
	st_numscalar("r(ID3val)",ID3val)
	st_numscalar("r(ID3stat)",ID3stat)
	st_numscalar("r(ID4val)",ID4val)
	st_numscalar("r(ID4stat)",ID4stat)
}
end
