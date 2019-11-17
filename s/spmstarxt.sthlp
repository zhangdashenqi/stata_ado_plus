{smcl}
{hline}
{cmd:help: {helpb spmstarxt}}{space 55} {cmd:dialog:} {bf:{dialog spmstarxt}}
{hline}

{bf:{err:{dlgtab:Title}}}

{bf:spmstarxt: (m-STAR) Spatial Panel Multiparametric Spatio Temporal AutoRegressive Regression}

{marker 00}{bf:{err:{dlgtab:Table of Contents}}}
{p 4 8 2}

{p 5}{helpb spmstarxt##01:Syntax}{p_end}
{p 5}{helpb spmstarxt##02:Options}{p_end}
{p 5}{helpb spmstarxt##03:Other Options}{p_end}
{p 5}{helpb spmstarxt##04:Description}{p_end}
{p 5}{helpb spmstarxt##05:Saved Results}{p_end}
{p 5}{helpb spmstarxt##06:References}{p_end}

{p 1}*** {helpb spmstarxt##07:Examples}{p_end}

{p 5}{helpb spmstarxt##09:Author}{p_end}

{p2colreset}{...}
{marker 01}{bf:{err:{dlgtab:Syntax}}}

{p 4 8 6}
{opt spmstarxt} {depvar} {indepvars} {ifin} {weight}, {bf:{err:id(#)}} {opt wmf:ile(weight_file)}{p_end} 
{p 4 8 6} 
{opt wmat(weight_matrix_name_W)} {opt eigw(eig_var_name_eW)} {opt nw:mat(#)}{p_end} 
{p 4 8 6} 
{err: [} {opt stand} {opt pred:ict(new_var)} {opt res:id(new_var)} {opt nolog} {opt robust} {opt nocons:tant}{p_end} 
{p 8 8 6} 
 {opt l:evel(#)} {opth vce(vcetype)} {err:]}{p_end} 
{p 8 8 6} 
{helpb maximize} {it: specify other maximization options}{p_end} 
{p 8 8 6} 
{helpb constraint} {it:apply specified linear constraints}{p_end}

{p2colreset}{...}
{marker 02}{bf:{err:{dlgtab:Options}}}
{p 2 10 2}

{synoptset 10 tabbed}{...}
{synopthdr}
{synoptline}

{synopt :{err:*} {opt id(#)}}Number of Cross Sections in the Model{p_end} 

{synopt :{err:*} {opt wmf:ile(weight_file)}}weight matrix file name{p_end}

{synopt :{err:*} {opt wmat(weight_matrix_name)}}name of the new spatial weight matrix to be used from importing {cmd:wmfile()}, it has two types; row-standardized, and binary weight matrix.{p_end}

{synopt :{err:*} {opt eigw(eig_var_name)}}new eigenvalues variable name{p_end}

{synopt :{err:*} {opt nw:mat(1, 2, 3, 4)}} number of Rho's matrixes to be used,
that can use more than Weight Matrix: (Border, Language, Currency, Trade...){p_end}

{p2colreset}{...}
{marker 03}{bf:{err:{dlgtab:Other Options}}}
{p 2 10 2}

{synoptset 3 tabbed}{...}
{synopthdr}
{synoptline}

{synopt :{opt stand}}new row-standardized weight matrix within each row sum equals 1.
 Default is Binary spatial weight matrix which each element is 0 or 1{p_end}

{synopt :{opt pred:ict(new_variable)}}predicted values variable{p_end}

{synopt :{opt res:id(new_variable)}}residuals values variable{p_end}

{synopt :{opt nolog}}suppress iteration of the log likelihood.{p_end}

{synopt :{opt robust}}Use Huber-White standard errors.{p_end}

{synopt:{opt nocons:tant}}Exclude Constant Term from Equation.{p_end}

{synopt :{opt level(#)}}confidence intervals level. Default is level(95){p_end}

{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt ols},
   {opt r:obust}, {opt cl:uster} {it:clustvar}, {opt boot:strap}, 
   {opt jack:knife}, {opt hc2}, or {opt hc3}{p_end}

{p2colreset}{...}
{marker 04}{bf:{err:{dlgtab:Description}}}

{p 2 2 2} {cmd:spmstarxt} estimate Spatial Panel econometric regression (MSTAR) "Multiparametric Spatio Temporal AutoRegressive Regression" models for Cross Section data.{p_end}

{p 2 4 2}{cmd:spmstarxt} can generate:{p_end}
    {cmd:- Binary Weight Matrix.}
    {cmd:- Binary Eigenvalues Variable.}

    {cmd:- Row-Standardized Weight Matrix.}
    {cmd:- Row-Standardized Eigenvalues Variable.}

{p 2 4 2} {cmd:spmstarxt} predicted values are obtained from conditional expectation expression.{p_end}

{pmore2}{bf:Yh = E(y|x) = inv(I-Rho*W) * X*Beta}

{p 3 4 2} R2, R2 Adjusted, and F-Test, are obtained from two ways:{p_end} 
{p 5 4 2} 1- squared correlation between predicted (Yh) and observed dependent variable (Y).{p_end}
{p 5 4 2} 2- Ratio of variance between predicted (Yh) and observed dependent variable (Y).{p_end}
{p 5 4 2}  - R2 Adjusted: R2_a=1-(1-R2)*(N-1)/(N-K-1).{p_end}
{p 5 4 2}  - F-Test=R2/(1-R2)*(N-K-1)/(K).{p_end}

{p 2 4 2}{help maximize:Other maximization_options} allows the user to specify other maximization options (e.g., difficult, trace, iterate(#), constraint(#), etc.).  
However, you should rarely have to specify them, though they may be helpful if parameters approach boundary values.

{p2colreset}{...}
{marker 05}{bf:{err:{dlgtab:Saved Results}}}

{p 2 4 2 }{cmd:spmstarxt} saves the following results in {cmd:e()}:

Scalars
{col 4}{cmd:e(chi2)}{col 22}chi-squared 
{col 4}{cmd:e(fth)}{col 22}F-test due to r2h
{col 4}{cmd:e(ftv)}{col 22}F-test due to r2v
{col 4}{cmd:e(ic)}{col 22}number of iterations
{col 4}{cmd:e(k)}{col 22}number of parameters
{col 4}{cmd:e(ll)}{col 22}log likelihood
{col 4}{cmd:e(ll_0)}{col 22}log likelihood for OLS
{col 4}{cmd:e(N)}{col 22}number of observations
{col 4}{cmd:e(p)}{col 22}significance of model of test 
{col 4}{cmd:e(p_wald)}{col 22}p-value for Wald test
{col 4}{cmd:e(r2_a)}{col 22}Adjusted R-squared
{col 4}{cmd:e(r2c)}{col 22}Centered R-squared, 1-rss/yyc
{col 4}{cmd:e(r2h)}{col 22}R2 between predicted and observed depvar
{col 4}{cmd:e(r2h_a)}{col 22}adjusted r2h
{col 4}{cmd:e(r2u)}{col 22}Uncentered R-squared, 1-rss/yy
{col 4}{cmd:e(r2v)}{col 22}R2 variance ratio between predicted and observed depvar
{col 4}{cmd:e(r2v_a)}{col 22}adjusted r2v
{col 4}{cmd:e(rank)}{col 22}rank of e(V)

Matrixes
{col 4}{cmd:e(b)}{col 22}coefficient vector
{col 4}{cmd:e(V)}{col 22}variance-covariance matrix of the estimators

Functions      
{col 4}{cmd:e(sample)}{col 22}marks estimation sample

{marker 06}{bf:{err:{dlgtab:References}}}

{p 4 8 2}Anselin, L., Kelejian, H. H. (1997)
{cmd: "Testing for Spatial Error Autocorrelation in the Presence of Endogenous Regressors",}
{it:International Regional Science Review, (20)}; 153-182.

{p 4 8 2}Anselin, L. (2001)
{cmd: "Spatial Econometrics",}
{it:In Baltagi, B. (Ed).: A Companion to Theoretical Econometrics Basil Blackwell: Oxford, UK}.

{p 4 8 2}Anselin, L. (2007)
{cmd: "Spatial Econometrics",}
{it:In T. C. Mills and K. Patterson (Eds).: Palgrave Handbook of Econometrics. Vol 1, Econometric Theory. New York: Palgrave MacMillan}.

{p 4 8 2}Hays, Jude C., Aya Kachi & Robert J. Franzese, Jr (2010)
{cmd: "A Spatial Model Incorporating Dynamic, Endogenous Network Interdependence: A Political Science Application",}
{it:Statistical Methodology 7(3)}; 406-428.

{p 4 8 2}James LeSage and R. Kelly Pace (2009)
{cmd: "Introduction to Spatial Econometrics",}
{it:Publisher: Chapman & Hall/CRC}.

{p2colreset}{...}
{marker 07}{bf:{err:{dlgtab:Examples}}}

	{bf:{err:* (m-STAR) Multiparametric Spatio Temporal AutoRegressive Regression}}

*** {err:YOU MUST HAVE DIFFERENT Weighted Matrixes:}

	{stata clear all}

	{stata sysuse spmstarxt.dta, clear}

	{stata spmstarxt y x1 x2 , wmfile(SPWmstarxt1) wmat(W1) eigw(eW1) id(7) nwmat(1) predict(Yh)}

	{stata spmstarxt y x1 x2 , wmfile(SPWmstarxt2) wmat(W2) eigw(eW2) id(7) nwmat(2) predict(Yh)}

	{stata spmstarxt y x1 x2 , wmfile(SPWmstarxt3) wmat(W3) eigw(eW3) id(7) nwmat(3) predict(Yh)}

	{stata spmstarxt y x1 x2 , wmfile(SPWmstarxt4) wmat(W4) eigw(eW4) id(7) nwmat(4) predict(Yh)}

{marker 09}{bf:{err:{dlgtab:Author}}}

  {hi:Emad Abd Elmessih Shehata}
  {hi:Assistant Professor}
  {hi:Agricultural Research Center - Agricultural Economics Research Institute - Egypt}
  {hi:Email:   {browse "mailto:emadstat@hotmail.com":emadstat@hotmail.com}}
  {hi:WebPage:{col 27}{browse "http://emadstat.110mb.com/stata.htm"}}
  {hi:WebPage at IDEAS:{col 27}{browse "http://ideas.repec.org/f/psh494.html"}}
  {hi:WebPage at EconPapers:{col 27}{browse "http://econpapers.repec.org/RAS/psh494.htm"}}

{bf:{err:{dlgtab:spmstarxt Citation}}}

{phang}Shehata, Emad Abd Elmessih (2011){p_end}
{phang}{cmd:SPMSTARXT: "Stata Module to Estimate (m-STAR) Spatial Panel Multiparametric Spatio Temporal AutoRegressive Regression"}{p_end}

{title:Online Help:}

{p 4 12 2} {helpb spregcs}, {helpb spregxt}, {helpb spautoreg}, {helpb spweight},
{helpb gs3sls}, {helpb gs2slsxt}, {helpb spmstar}, {helpb spmstarxt},
{helpb spweightcs}, {helpb spweightxt}, {helpb spcs2xt} {opt (if installed)}.{p_end}

{psee}
{p_end}

