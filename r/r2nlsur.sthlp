{smcl}
{hline}
{cmd:help: {helpb r2nlsur}}{space 55} {cmd:dialog:} {bf:{dialog r2nlsur}}
{hline}

{bf:{err:{dlgtab:Title}}}

{bf: r2nlsur: Overall NL-SUR System R2 - Adjusted R2 - F Test - Chi2 Test}

{bf:{err:{dlgtab:Syntax}}}

{cmd: r2nlsur}

{bf:{err:{dlgtab:Description}}}

{p 2 2 2}r2nlsur computes Overall Nonlinear Seemingly Unrelated Regression (NL-SUR) System R2, Adj. R2, F-Test, and Chi2-Test after:{p_end}
{p 3 2 2}- (NL-SUR) Nonlinear Seemingly Unrelated Regression {helpb nlsur} for sets of equations.{p_end}

{p 2 2 2}r2nlsur used Four types of criteria and tests, as discussed in:{p_end}
{p 2 2 2}{cmd: McElroy(1977), Judge et al(1985), Dhrymes(1974), Greene(1993), and Berndt(1991)}.{p_end} 
{p 6 2 2}see eq.12.1.33-36 in Judge et al(1985, p.477).{p_end}

   {cmd:1- Berndt  System R2} = 1-|E'E|  / |Yb'Yb|
   {cmd:2- McElroy System R2} = 1-(U'W*U)/ (Y'W*Y)
   {cmd:3- Judge   System R2} = 1-(U'U)  / (Y'Y)
                           Q
   {cmd:4- Dhrymes System R2} = Sum [R2i (yi' Dt yi']/[Y(I(Q) # Dt)Y]
                          i=1
   {cmd:5- Greene  System R2} = 1-(Q/trace(inv(Sig))*SYs)

{p 2 2 2}Judge and Dhrymes are identical results.

{p 2 2 2}From each type of these system R2's, {cmd:r2nlsur} can calculate Adjusted R2, F-Test, and Chi2-Test:{p_end}

    {cmd:Adjusted R2} = 1-(1-R2)*((QN-Q)/(QN-K))
         {cmd:F-Test} = R2/(1-R2)*[(QN-K)/(K-Q)]
      {cmd:Chi2-Test} = -N*(log(1-R2))

where
   |E'E| = determinant of residual matrix (NxQ)
 |Yb'Yb| = determinant of dependent variables matrix in deviation from mean (NxQ)
      yi = dependent variable of eq. i (Nx1)
       Y = stacked vector of dependent variables (QNx1)
       U = stacked vector of residuals (QNx1)
       W = variance-covariance matrix of residuals (W=inv(Omega) # I(N))
       N = number of observations
       K = Number of Parameters
       Q = Number of Equations
     R2i = R2 of eq. i
      Dt = I(N)-JJ'/N, with J=(1,1,...,1)' (Nx1)
     SYs = (Yb1*Yb2*...Ybq)/N
     Sig = Sigma hat Matrix
 Degrees of Freedom F-Test    = (K-Q), (QN)
 Degrees of Freedom Chi2-Test = (K-Q)
 Log Determinant of Sigma     = log|Sigma matrix|
 Log Likelihood Function LLF  =-(N*Q/2)*(1+log(2*_pi))-(N/2*abs(log(Sigma)))

{bf:{err:{dlgtab:Saved Results}}}

{pstd}
{cmd:r2nlsur} saves the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 15 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}Number of Observations{p_end}
{synopt:{cmd:r(k)}}Number of Parameters{p_end}
{synopt:{cmd:r(k_eq)}}Number of Equations{p_end}
{synopt:{cmd:r(chi_df)}}DF chi-squared{p_end}
{synopt:{cmd:r(f_df1)}}F-Test DF1 Numerator{p_end}
{synopt:{cmd:r(f_df2)}}F-Test DF2 Denominator{p_end}
{synopt:{cmd:r(r2_b)}}Berndt R-squared{p_end}
{synopt:{cmd:r(r2_j)}}Judge R-squared{p_end}
{synopt:{cmd:r(r2_m)}}McElroy R-squared{p_end}
{synopt:{cmd:r(r2_d)}}Dhrymes R-squared{p_end}
{synopt:{cmd:r(r2_g)}}Greene R-squared{p_end}
{synopt:{cmd:r(r2a_b)}}Berndt Adjusted R-squared{p_end}
{synopt:{cmd:r(r2a_j)}}Judge Adjusted R-squared{p_end}
{synopt:{cmd:r(r2a_m)}}McElroy Adjusted R-squared{p_end}
{synopt:{cmd:r(r2a_d)}}Dhrymes Adjusted R-squared{p_end}
{synopt:{cmd:r(r2a_g)}}Greene Adjusted R-squared{p_end}
{synopt:{cmd:r(f_b)}}Berndt F Test{p_end}
{synopt:{cmd:r(f_j)}}Judge F Test{p_end}
{synopt:{cmd:r(f_m)}}McElroy F Test{p_end}
{synopt:{cmd:r(f_d)}}Dhrymes F Test{p_end}
{synopt:{cmd:r(f_g)}}Greene F Test{p_end}
{synopt:{cmd:r(chi_b)}}Berndt Chi2 Test{p_end}
{synopt:{cmd:r(chi_j)}}Judge Chi2 Test{p_end}
{synopt:{cmd:r(chi_m)}}McElroy Chi2 Test{p_end}
{synopt:{cmd:r(chi_d)}}Dhrymes Chi2 Test{p_end}
{synopt:{cmd:r(chi_g)}}Greene Chi2 Test{p_end}
{synopt:{cmd:r(lsig2)}}Log Determinant of Sigma{p_end}
{synopt:{cmd:r(llf)}}Log Likelihood Function{p_end}

{bf:{err:{dlgtab:References}}}

{p 4 8 2}Berndt, Ernst R. (1991)
{cmd: "The practice of econometrics: Classical and contemporary",}
{it:Addison-Wesley Publishing Company}; 468.

{p 4 8 2}Dhrymes, Phoebus J. (1974)
{cmd: "Econometrics: Statistical Foundations and Applications",}
{it:2ed edition Springer- Verlag New York, USA.}.

{p 4 8 2}Greene, William (1993)
{cmd: "Econometric Analysis",}
{it:2nd ed., Macmillan Publishing Company Inc., New York, USA.}; 490-491.

{p 4 8 2}Judge, Georege, W. E. Griffiths, R. Carter Hill, Helmut Lutkepohl, & Tsoung-Chao Lee(1985)
{cmd: "The Theory and Practice of Econometrics",}
{it:2nd ed., John Wiley & Sons, Inc., New York, USA}; 477-478.

{p 4 8 2}Kmenta, Jan (1986)
{cmd: "Elements of Econometrics",}
{it:2nd ed., Macmillan Publishing Company, Inc., New York, USA}; 645.

{p 4 8 2}McElroy, Marjorie B. (1977)
{cmd: "Goodness of Fit for Seemingly Unrelated Regressions: Glahn's R2y,x and Hooper's r~2",}
{it:Journal of Econometrics, 6(3), November}; 381-387.

{bf:{err:{dlgtab:Examples}}}

 {stata clear all}

 {stata sysuse r2nlsur.dta , clear}

 {stata nlsur (y1={B10}+{B11}*y2+{B12}*x1+{B13}*x2) (y2={B20}+{B21}*y1+{B22}*x3+{B23}*x4)}
 {stata r2nlsur}

 {stata sureg (y1 y2 x1 x2) (y2 y1 x3 x4)}
 {stata r2reg3}

 {stata return list}

 * If you want to use dialog box: Press OK to compute r2nlsur

	{stata db r2nlsur}

. sysuse r2nlsur.dta , clear
. nlsur (y1 = {B10} + {B11}*x1+ {B12}*x2) (y2 = {B20} + {B21}*x3+ {B22}*x4)

FGNLS regression 
---------------------------------------------------------------------
       Equation |       Obs  Parms       RMSE      R-sq     Constant
----------------+----------------------------------------------------
 1           y1 |        17      3   9.056705    0.8555          B10
 2           y2 |        17      3   10.75922    0.8318          B20
---------------------------------------------------------------------

------------------------------------------------------------------------------
             |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
        /B10 |   183.5815   43.95101     4.18   0.000     97.43906    269.7239
        /B11 |   .4956588   .4326135     1.15   0.252     -.352248    1.343566
        /B12 |  -1.370874   .1363473   -10.05   0.000     -1.63811   -1.103638
        /B20 |   37.62409   30.21636     1.25   0.213    -21.59888    96.84706
        /B21 |  -.3675841   .2675172    -1.37   0.169    -.8919083      .15674
        /B22 |   2.288538   .8959307     2.55   0.011     .5325456     4.04453
------------------------------------------------------------------------------

. r2nlsur
==============================================================================
* Overall NL-SUR System R2 - Adjusted R2 - F Test - Chi2 Test (fgnls) 
==============================================================================

+----------------------------------------------------------------------------+
|     Name |       R2 |   Adj_R2 |        F |  P-Value |     Chi2 |  P-Value |
|----------+----------+----------+----------+----------+----------+----------|
|   Berndt |   0.9293 |   0.9192 |  92.0573 |   0.0000 |  45.0464 |   0.0000 |
|  McElroy |   0.8315 |   0.8074 |  34.5394 |   0.0000 |  30.2724 |   0.0000 |
|    Judge |   0.8425 |   0.8200 |  37.4452 |   0.0000 |  31.4219 |   0.0000 |
|  Dhrymes |   0.8425 |   0.8200 |  37.4452 |   0.0000 |  31.4219 |   0.0000 |
|   Greene |   0.8133 |   0.7866 |  30.4844 |   0.0000 |  28.5263 |   0.0000 |
+----------------------------------------------------------------------------+
  Number of Parameters         =           6
  Number of Equations          =           2
  Degrees of Freedom F-Test    =      (4, 34)
  Degrees of Freedom Chi2-Test =           4
  Log Determinant of Sigma     =      9.1462
  Log Likelihood Function      =   -125.9864
{hline}

{bf:{err:{dlgtab:Author}}}

  {hi:Emad Abd Elmessih Shehata}
  {hi:Assistant Professor}
  {hi:Agricultural Research Center - Agricultural Economics Research Institute - Egypt}
  {hi:Email:   {browse "mailto:emadstat@hotmail.com":emadstat@hotmail.com}}
  {hi:WebPage:{col 27}{browse "http://emadstat.110mb.com/stata.htm"}}
  {hi:WebPage at IDEAS:{col 27}{browse "http://ideas.repec.org/f/psh494.html"}}
  {hi:WebPage at EconPapers:{col 27}{browse "http://econpapers.repec.org/RAS/psh494.htm"}}

{bf:{err:{dlgtab:r2nlsur Citation}}}

{p 1}{cmd:Shehata, Emad Abd Elmessih (2012)}{p_end}
{p 1 10 1}{cmd:R2NLSUR: "Overall Nonlinear Seemingly Unrelated Regression (NL-SUR) System R2, Adj. R2, F-Test, and Chi2-Test after (nlsur) Regressions"}{p_end}

{title:Online Help:}

{p 2 10 2}
{helpb lmanlsur}, {helpb lmhnlsur}, {helpb lmnnlsur}, {helpb lmcovnlsur}, {helpb r2nlsur}{p_end}
{p 2 10 2}
{helpb lmareg3}, {helpb lmhreg3}, {helpb lmnreg3}, {helpb lmcovreg3}, {helpb r2reg3}{p_end}
{p 2 10 2}
{helpb lmasem}, {helpb lmhsem}, {helpb lmnsem}, {helpb lmcovsem}, {helpb r2sem}. {opt (if installed)}.{p_end}

{psee}
{p_end}

