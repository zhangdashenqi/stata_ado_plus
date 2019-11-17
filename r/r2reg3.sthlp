{smcl}
{hline}
{cmd:help: {helpb r2reg3}}{space 55} {cmd:dialog:} {bf:{dialog r2reg3}}
{hline}

{bf:{err:{dlgtab:Title}}}

{bf: r2reg3: Overall System R2 - Adjusted R2 - F Test - Chi2 Test}

{bf:{err:{dlgtab:Syntax}}}

{cmd: r2reg3}


{bf:{err:{dlgtab:Description}}}

{p 2 2 2}r2reg3 computes overall system R-squared (R2), Adjusted R2, and the overall significance of F-Test, and Chi2-Test, after:{p_end}
{p 3 2 2}- (3SLS) Three-Stage Least Squares {helpb reg3} for systems of simultaneous equations.{p_end}
{p 3 2 2}- (SUR) Seemingly Unrelated Regression {helpb sureg} for sets of equations.{p_end}

{p 2 2 2}r2reg3 used Four types of criteria and tests, as discussed in:{p_end}
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

{p 2 2 2}From each type of these system R2's, {cmd:r2reg3} can calculate Adjusted R2, F-Test, and Chi2-Test:{p_end}

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
{cmd:r2reg3} saves the following in {cmd:r()}:

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
 

{bf:{err:{dlgtab:Examples}}}

	{stata clear all}

	{stata sysuse r2reg3.dta , clear}

 * (1) SUR Model:

	{stata sureg (y1 y2 x1 x2) (y2 y1 x3 x4)}

	{stata r2reg3}

	{stata return list}

 * (2) 3SLS Model:

	{stata reg3 (y1 y2 x1 x2) (y2 y1 x3 x4) , exog(x1 x2 x3 x4)}

	{stata r2reg3}

	{stata return list}

 * If you want to use dialog box: Press OK to compute r2reg3

	{stata db r2reg3}


. sysuse r2reg3.dta , clear
. reg3 (y1 y2 x1 x2) (y2 y1 x3 x4) , exog(x1 x2 x3 x4)
. r2reg3

  ========================================================
  * Overall System R2 - Adjusted R2 - F Test - Chi2 Test *
  ========================================================
  +----------------------------------------------------------------------------+
  |     Name |       R2 |   Adj_R2 |        F |  P-Value |     Chi2 |  P-Value |
  |----------+----------+----------+----------+----------+----------+----------|
  |   Berndt |   0.9191 |   0.9004 |  49.2299 |   0.0000 |  42.7469 |   0.0000 |
  |  McElroy |   0.8042 |   0.7590 |  17.7985 |   0.0000 |  27.7216 |   0.0001 |
  |    Judge |   0.8228 |   0.7819 |  20.1180 |   0.0000 |  29.4159 |   0.0001 |
  |  Dhrymes |   0.8228 |   0.7819 |  20.1180 |   0.0000 |  29.4159 |   0.0001 |
  |   Greene |   0.8104 |   0.7666 |  18.5204 |   0.0000 |  28.2672 |   0.0001 |
  +----------------------------------------------------------------------------+
  Number of Parameters         =           8
  Number of Equations          =           2
  Degrees of Freedom F-Test    =      (6, 34)
  Degrees of Freedom Chi2-Test =           6
  Log Determinant of Sigma     =      9.2772
  Log Likelihood Function      =   -127.1003


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


{bf:{err:{dlgtab:Acknowledgments}}}

  I would like to thank the authors of the following Stata modules:

 - Nicholas J. Cox: for writing Stata programs about various matrix tasks {helpb matodd}.
 
 - Philip Ryan: for writing Stata programs about product of observations {helpb rprod}.


{bf:{err:{dlgtab:Author}}}

  {hi:Emad Abd Elmessih Shehata}
  {hi:Assistant Professor}
  {hi:Agricultural Research Center - Agricultural Economics Research Institute - Egypt}
  {hi:Email:   {browse "mailto:emadstat@hotmail.com":emadstat@hotmail.com}}
  {hi:WebPage:{col 27}{browse "http://emadstat.110mb.com/stata.htm"}}
  {hi:WebPage at IDEAS:{col 27}{browse "http://ideas.repec.org/f/psh494.html"}}
  {hi:WebPage at EconPapers:{col 27}{browse "http://econpapers.repec.org/RAS/psh494.htm"}}


{bf:{err:{dlgtab:r2reg3 Citation}}}

{phang}Shehata, Emad Abd Elmessih (2011){p_end}
{phang}{cmd:r2reg3: "Stata Module to Compute Overall System R2, Adj. R2, F-Test, and Chi2-Test after reg3 or sureg"}{p_end}

	{browse "http://ideas.repec.org/c/boc/bocode/s457322.html"}

	{browse "http://econpapers.repec.org/software/bocbocode/s457322.htm"}

{psee}
{p_end}

