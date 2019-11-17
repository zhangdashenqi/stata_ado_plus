{smcl}
{* *! version 1.0  26sep2012}{...}
{cmd:help EWreg}
{hline}

{title:Title}

{phang}
{bf:EWreg} {hline 2} Erickson-Whited linear cross-sectional regression for one mismeasured regressor and arbitrarily many perfectly measured regressors


{title:Syntax}

{p 8 17 2}
{cmdab:EWreg}
depvar misindepvar [indepvars]
{ifin}
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt meth:od}}Highest order of moment to use: one of GMM(3-7); default is GMM3{p_end}
{synopt:{opt bx:int}}A numlist of starting values for the coefficient on misindepvar; 
					default is the GMM3 estimate.
					Note: when the numlist contains 0, the GMM3 estimate is contained in the numlist{p_end}
{synopt:{opt has:cons}}Indicates that indepvars contains a constant variable, and so a constant should not be added in the estimation process{p_end}
{synopt:{opt noprn}}Supress printing of results{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:EWreg} estimates a classical linear errors-in-variables model with one
mismeasured regressor and arbitrarily many perfectly measured regressors.

{pstd}
Yi = Xi*b + Zi*a + ui

{pstd}
xi = Xi + vi

{pstd}
In which Yi is the dependent variable, Xi is the (scalar) unobservable mismeasured regressor, Zi is a vector of
perfectly measured regressors, ui is the regression disturbance, xi is the proxy for Xi, and vi is the
measurement error.

{pstd}
The estimator is from Erickson and Whited (2000, 2002).  It uses information in the higher order moments of the observable variables to
identify the regression coefficient.  This procedure implements the estimator for a single cross section. See {helpb XTEWreg: [XT] XTEWreg} for a related procedure that implements this estimator in a panel.

{pstd}
The procedure returns estimates of regression coefficients, the R2 of the regression (rho2), and
the R2 of the measurement equation (tau2), which is an index of measurement quality. This index ranges between zero and one, with
zero indicating a worthless proxy and one indicating a perfect proxy.

{pstd}
The procedure also returns the results of two identification diaggnostic tests, one of which is based on third order moments
and the other of which is based on both third and fourth order moments. The estimators are unidentified if the mismeasured regressor
is normally distributed. These tests are diagnostics to determine whether the estimator idenfication assumptions are satisfied. These
assumptions include a nonnormally distributed mismeasured regressor and b != 0.

{pstd}
Because the estimator is a GMM estimator, it also provides the test of the overidentifying restrictions of the model.


{title:Options}

{phang}
{opt method} sets the highest order of moment to use.  Five versions of the estimator are
available.  GMM3 uses only the third order moments, and it is an exactly
identified estimator.  GMM4 - GMM7 use moments of up to orders four
through seven.  These latter estimators are overidentified.

{phang}
{opt bxint} is a numlist of starting values for the coefficient on misindep. GMM4 - GMM7
require numerical minimization of a nonlinear objective function and thus require starting values.
The default is to use the GMM3 estimate as a starting value. It is strongly recommended that the
user provide a numlist of starting value that contains the OLS estimate. If the numlist contains
zero, the GMM3 estimate will also be used as a possible starting value.

{phang}
{opt hascons} indicates that indepvar already contains a constant variable, and so a constant should no be added by the estimation procedure.

{phang}
{opt noprn} disables printing of results table.


{title:Examples}

{phang}{cmd:. EWreg ik q}

{phang}{cmd:. EWreg ik q cfk oik, meth(GMM5) bx(-0.1(0.1)0.5) }


{title:Saved results}

{pstd}
{cmd:EWreg} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(Jstat)}}J statistic for the overidentifying restrictions{p_end}
{synopt:{cmd:e(Jval)}}p-val of Jstat{p_end}
{synopt:{cmd:e(dfree)}}Degrees of freedom for Jval{p_end}
{synopt:{cmd:e(rho)}}estimate of rho^2{p_end}
{synopt:{cmd:e(tau)}}estimate of tau^2{p_end}
{synopt:{cmd:e(SErho)}}standard error for rho^2{p_end}
{synopt:{cmd:e(SEtau)}}standard error for tau^2{p_end}
{synopt:{cmd:e(obj)}}value of GMM objective function{p_end}
{synopt:{cmd:e(ID3stat)}}Test statistic for the identification test with third-order moments{p_end}
{synopt:{cmd:e(ID3val)}}p-val for ID3val{p_end}
{synopt:{cmd:e(ID4stat)}}Test statistic for the identification test with third- and fourth-order moments{p_end}
{synopt:{cmd:e(ID4val)}}p-val for ID4val{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(bxint)}}numlist of initial guesses for beta{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}regression coeffiecients{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix for e(b){p_end}
{synopt:{cmd:e(inflnc)}}influence functions for (misindepvar,indepvars){p_end}
{synopt:{cmd:e(serr)}}standard errors for e(b){p_end}
{synopt:{cmd:e(vcrhotau)}}variance-covariance matrix for (rho^2,tau^2){p_end}
{synopt:{cmd:e(w)}}the GMM weight matrix{p_end}
{synopt:{cmd:e(inflncrhotau)}}influence functions for (rho^2,tau^2){p_end}
{p2colreset}{...}


{title:References}

{phang}
Erickson, T. and T. M. Whited. 2000. {it:Measurement error and the relationship between investment and q.} Journal of Political Economy 108: 1027--1057.

{phang}
Erickson, T. and T. M. Whited. 2002. {it:Two-step GMM estimation of the errors-in-variables model using high-order moments.} Econometric Theory 18: 776-799.


{title:Remark}

{pstd}
This is version 1.0 of the EWreg command. Please send bug reports and feature requests to robert.parham@simon.rochester.edu. Adapted to Stata by Robert Parham, based on code provided by Toni M. Whited.


{title:Also see}

{psee}
Help: {helpb XTEWreg: [XT] XTEWreg}
