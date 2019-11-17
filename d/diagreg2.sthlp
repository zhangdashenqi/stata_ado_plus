{smcl}
{hline}
{cmd:help: {helpb diagreg2}}{space 55} {cmd:dialog:} {bf:{dialog diagreg2}}
{hline}

{bf:{err:{dlgtab:Title}}}

{bf: diagreg2: 2SLS-IV Model Selection Diagnostic Criteria}

{marker 00}{bf:{err:{dlgtab:Table of Contents}}}
{p 4 8 2}

{p 5}{helpb diagreg2##01:Syntax}{p_end}
{p 5}{helpb diagreg2##02:Model}{p_end}
{p 5}{helpb diagreg2##03:GMM Options}{p_end}
{p 5}{helpb diagreg2##06:Other Options}{p_end}
{p 5}{helpb diagreg2##07:Description}{p_end}
{p 5}{helpb diagreg2##08:Saved Results}{p_end}
{p 5}{helpb diagreg2##09:References}{p_end}

{p 1}*** {helpb diagreg2##10:Examples}{p_end}

{p 5}{helpb diagreg2##11:Author}{p_end}

{marker 01}{bf:{err:{dlgtab:Syntax}}}

{p 2 4 2} 
{cmd:diagreg2} {depvar} {it:{help varlist:indepvars}} {cmd:({it:{help varlist:endog}} = {it:{help varlist:inst}})} {ifin} , {p_end} 
{p 6 6 2}
{opt model(2sls, liml, gmm, melo, fuller, kclass)}{p_end} 
{p 6 6 2}
{err: [} {opt dn} {opt kc(#)} {opt kf(#)} {opt hetcov(type)} {opt nocons:tant} {opt noconexog} {err:]}{p_end}

{marker 02}{bf:{err:{dlgtab:Model}}}

{synoptset 16}{...}
{p2coldent:{it:model}}description{p_end}
{synopt:{opt 2sls}}Two-Stage Least Squares (2SLS){p_end}
{synopt:{opt liml}}Limited-Information Maximum Likelihood (LIML){p_end}
{synopt:{opt melo}}Minimum Expected Loss (MELO){p_end}
{synopt:{opt fuller}}Fuller k-Class LIML{p_end}
{synopt:{opt kclass}}Theil K-Class LIML{p_end}
{synopt:{opt gmm}}Generalized Method of Moments (GMM){p_end}

{marker 03}{bf:{err:{dlgtab:GMM Options}}}

{synoptset 16}{...}
{p2coldent:{it:hetcov Options}}Description{p_end}

{synopt:{bf:hetcov({err:{it:white}})}}White Method{p_end}
{synopt:{bf:hetcov({err:{it:bart}})}}Bartlett Method{p_end}
{synopt:{bf:hetcov({err:{it:dan}})}}Daniell Method{p_end}
{synopt:{bf:hetcov({err:{it:nwest}})}}Newey-West Method{p_end}
{synopt:{bf:hetcov({err:{it:parzen}})}}Parzen Method{p_end}
{synopt:{bf:hetcov({err:{it:quad}})}}Quadratic spectral Method{p_end}
{synopt:{bf:hetcov({err:{it:tent}})}}Tent Method{p_end}
{synopt:{bf:hetcov({err:{it:trunc}})}}Truncated Method{p_end}
{synopt:{bf:hetcov({err:{it:tukeym}})}}Tukey-Hamming Method{p_end}
{synopt:{bf:hetcov({err:{it:tukeyn}})}}Tukey-Hanning Method{p_end}

{marker 06}{bf:{err:{dlgtab:Other Options}}}

{synoptset 16}{...}
{synopt:{bf:kf({err:{it:#}})}}Fuller k-Class LIML Value{p_end}

{synopt:{bf:kc({err:{it:#}})}}Theil k-Class LIML Value{p_end}

{synopt:{opt nocons:tant}}Exclude Constant Term from RHS Equation only{p_end}

{synopt:{bf:noconexog}}Exclude Constant Term from all Equations (both RHS and Instrumental Equations). Results of using {cmd:noconexog} option are identical to Stata {helpb ivregress} and {helpb ivreg2}.
 The default of {cmd:diagreg2} is including Constant Term in both RHS and Instrumental Equations{p_end}

{synopt:{bf:dn}}Use (N) divisor instead of (N-K) for Degrees of Freedom (DF){p_end}

{marker 07}{bf:{err:{dlgtab:Description}}}

{pstd}
{cmd:diagreg2} estimate 2SLS-IV Model Selection Diagnostic Criteria for instrumental variables regression models, via 2sls, liml, melo, gmm, and kclass. {cmd:diagreg2} dont deal with Missing values (.) in variables{p_end}

{marker 08}{bf:{err:{dlgtab:Saved Results}}}

{pstd}
{cmd:diagreg2} saves the following in {cmd:e()}:

{col 4}{cmd:e(llf)}{col 20}Log Likelihood Function
{col 4}{cmd:e(aic)}{col 20}AKAIKE Final Prediction Error
{col 4}{cmd:e(laic)}{col 20}Akaike Information Criterion ln AIC
{col 4}{cmd:e(sc)}{col 20}Schwartz Criterion
{col 4}{cmd:e(lsc)}{col 20}Schwarz Criterion Log SC
{col 4}{cmd:e(fpe)}{col 20}Amemiya Prediction Criterion
{col 4}{cmd:e(gcv)}{col 20}Craven-Wahba Generalized Cross Validation-GCV
{col 4}{cmd:e(hq)}{col 20}Hannan-Quinn Criterion
{col 4}{cmd:e(rice)}{col 20}Rice Criterion
{col 4}{cmd:e(shibata)}{col 20}Shibata Criterion

{marker 09}{bf:{err:{dlgtab:References}}}

{p 4 8 2}Damodar Gujarati (1995)
{cmd: "Basic Econometrics"}
{it:3rd Edition, McGraw Hill, New York, USA}.

{p 4 8 2}Greene, William (1993)
{cmd: "Econometric Analysis",}
{it:2nd ed., Macmillan Publishing Company Inc., New York, USA}.

{p 4 8 2}Greene, William (2007)
{cmd: "Econometric Analysis",}
{it:6th ed., Upper Saddle River, NJ: Prentice-Hall}.

{p 4 8 2}Griffiths, W., R. Carter Hill & George Judge (1993)
{cmd: "Learning and Practicing Econometrics",}
{it:John Wiley & Sons, Inc., New York, USA}.

{p 4 8 2}Harvey, Andrew (1990)
{cmd: "The Econometric Analysis of Time Series",}
{it:2nd edition, MIT Press, Cambridge, Massachusetts}.

{p 4 8 2}Judge, Georege, R. Carter Hill, William . E. Griffiths, Helmut Lutkepohl, & Tsoung-Chao Lee (1988)
{cmd: "Introduction To The Theory And Practice Of Econometrics",}
{it:2nd ed., John Wiley & Sons, Inc., New York, USA}.

{p 4 8 2}Judge, Georege, W. E. Griffiths, R. Carter Hill, Helmut Lutkepohl, & Tsoung-Chao Lee(1985)
{cmd: "The Theory and Practice of Econometrics",}
{it:2nd ed., John Wiley & Sons, Inc., New York, USA}.

{p 4 8 2}Kmenta, Jan (1986)
{cmd: "Elements of Econometrics",}
{it: 2nd ed., Macmillan Publishing Company, Inc., New York, USA}.

{p 4 8 2}Maddala, G. (1992)
{cmd: "Introduction to Econometrics",}
{it:2nd ed., Macmillan Publishing Company, New York, USA}.

{p 4 8 2}White, Halbert (1980)
{cmd: "A Heteroskedasticity-Consistent Covariance Matrix Estimator and a Direct Test for Heteroskedasticity",}
{it:Econometrica, 48}; 817-838.

{marker 10}{bf:{err:{dlgtab:Examples}}}

 {stata clear all}

 {stata sysuse diagreg2.dta , clear}

 {stata db diagreg2}

 {stata diagreg2 y1 x1 x2 (y2 = x1 x2 x3 x4) , model(2sls)}
 {stata diagreg2 y1 x1 x2 (y2 = x1 x2 x3 x4) , model(melo)}
 {stata diagreg2 y1 x1 x2 (y2 = x1 x2 x3 x4) , model(liml)}
 {stata diagreg2 y1 x1 x2 (y2 = x1 x2 x3 x4) , model(fuller) kf(0.5)}
 {stata diagreg2 y1 x1 x2 (y2 = x1 x2 x3 x4) , model(kclass) kc(0.5)}
 {stata diagreg2 y1 x1 x2 (y2 = x1 x2 x3 x4) , model(gmm) hetcov(white)}
 {stata diagreg2 y1 x1 x2 (y2 = x1 x2 x3 x4) , model(gmm) hetcov(bart)}
 {stata diagreg2 y1 x1 x2 (y2 = x1 x2 x3 x4) , model(gmm) hetcov(dan)}
 {stata diagreg2 y1 x1 x2 (y2 = x1 x2 x3 x4) , model(gmm) hetcov(nwest)}
 {stata diagreg2 y1 x1 x2 (y2 = x1 x2 x3 x4) , model(gmm) hetcov(parzen)}
 {stata diagreg2 y1 x1 x2 (y2 = x1 x2 x3 x4) , model(gmm) hetcov(quad)}
 {stata diagreg2 y1 x1 x2 (y2 = x1 x2 x3 x4) , model(gmm) hetcov(tent)}
 {stata diagreg2 y1 x1 x2 (y2 = x1 x2 x3 x4) , model(gmm) hetcov(trunc)}
 {stata diagreg2 y1 x1 x2 (y2 = x1 x2 x3 x4) , model(gmm) hetcov(tukeym)}
 {stata diagreg2 y1 x1 x2 (y2 = x1 x2 x3 x4) , model(gmm) hetcov(tukeyn)}
{hline}

. clear all
. sysuse diagreg2.dta , clear
. diagreg2 y1 x1 x2 (y2 = x1 x2 x3 x4) , model(2sls)

------------------------------------------------------------
  y1 = y2 + x1 + x2
==============================================================================
* Two Stage Least Squares (2SLS)
==============================================================================
  Number of Obs    =         17
  Wald Test        =    79.9520         P-Value > Chi2(3)        =     0.0000
  F Test           =    26.6507         P-Value > F(3 , 13)      =     0.0000
  R-squared        =     0.8592         Raw R2                   =     0.9954
  R-squared Adj    =     0.8267         Raw R2 Adj               =     0.9944
  Root MSE (Sigma) =    10.2244         Log Likelihood Function  =   -61.3630
------------------------------------------------------------------------------
          y1 |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
          y2 |    .237333   .2422811     0.98   0.345    -.2860835    .7607495
          x1 |   .2821278   .5433329     0.52   0.612    -.8916715    1.455927
          x2 |  -1.044795    .362648    -2.88   0.013    -1.828248   -.2613411
       _cons |   145.8444   61.72083     2.36   0.034     12.50468    279.1842
------------------------------------------------------------------------------

==============================================================================
* 2SLS-IV Model Selection Diagnostic Criteria - 2sls 
==============================================================================
  Log Likelihood Function       LLF             =    -61.3630
  Akaike Final Prediction Error AIC             =    113.7768
  Schwartz Criterion            SC              =    131.7988
  Akaike Information Criterion  ln AIC          =      4.7342
  Schwarz Criterion             ln SC           =      4.8813
  Amemiya Prediction Criterion  FPE             =    122.9872
  Hannan-Quinn Criterion        HQ              =    115.4520
  Rice Criterion                Rice            =    123.5463
  Shibata Criterion             Shibata         =    108.1564
  Craven-Wahba Generalized Cross Validation GCV =    117.8732
---------------------------------------------------------------

{marker 11}{bf:{err:{dlgtab:Author}}}

  {hi:Emad Abd Elmessih Shehata}
  {hi:Assistant Professor}
  {hi:Agricultural Research Center - Agricultural Economics Research Institute - Egypt}
  {hi:Email:   {browse "mailto:emadstat@hotmail.com":emadstat@hotmail.com}}
  {hi:WebPage:{col 27}{browse "http://emadstat.110mb.com/stata.htm"}}
  {hi:WebPage at IDEAS:{col 27}{browse "http://ideas.repec.org/f/psh494.html"}}
  {hi:WebPage at EconPapers:{col 27}{browse "http://econpapers.repec.org/RAS/psh494.htm"}}

{bf:{err:{dlgtab:diagreg2 Citation}}}

{phang}Shehata, Emad Abd Elmessih (2011){p_end}
{phang}{cmd: DIAGREG2: "Stata Module to Compute 2SLS-IV Model Selection Diagnostic Criteria"}{p_end}

{title:Online Help:}

{p 4 12 2}
{helpb diagreg}, {helpb diagreg2}, {helpb ivregress} {opt (if installed)}.{p_end}

{psee}
{p_end}

