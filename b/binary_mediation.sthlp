{smcl}
{* 7may2010}{...}
{hline}
help for {hi:binary_mediation}
{hline}

{title:Mediation with binary mediator and/or response variables}

{p 8 16 2}{cmd:binary_mediation}
  [{cmd:if} {it:exp}] [{cmd:in} {it:range}]
  {cmd:,}
  {cmd:dv(}{it:varname}{cmd:)}
  {cmd:mv(}{it:varlist}{cmd:)}
  {cmd:iv(}{it:varname}{cmd:)}
    [ {cmd:cv(}{it:varlist}{cmd:)}
    {cmd:quietly} {cmd:probit} {cmd:diagram} ]

{title:Description}

{p 4 4 2}
{cmd:binary_mediation} computes indirect effects for models with multiple mediator 
variables (binary or continuous) along with
either a binary or continuous response variable using standardized coefficients. 

{p 4 4 2}
{bf:Note:} This program does not provide standard errors or statistical tests for coefficients.  Bootstrap
standard errors and confidence intervals are recommended for this purpose. Here is some example code:{p_end}
{p 4 8 2}{cmd:. bootstrap r(tot_ind) r(dir_eff) r(tot_eff), bca reps(500): ///} {p_end}
{p 4 8 2}{cmd:   binary_mediation, dv(honors) iv(ses) mv(hiread socst)}{p_end}
{p 4 8 2}{cmd:. estat bootstrap, percentile bc bca}{p_end}

{title:Options}
{p 4 8 2}{cmd:cv(}{it:varlist}{cmd:)} Optional list of covariate variables.{p_end}
{p 4 8 2}{cmd:quietly} Supress OLS, probit  or logistic regression output.{p_end}
{p 4 8 2}{cmd:probit} Use probit instead of logistic regression model.{p_end}
{p 4 8 2}{cmd:diagram} Display mediation reference diagram.{p_end}

{title:Examples}

{p 4 8 2}{cmd:. binary_mediation, dv(honors) iv(ses) mv(hiread socst)}{p_end}
{p 4 8 2}{cmd:. binary_mediation, dv(honors) iv(ses) mv(hiread socst) cv(math science)}{p_end}
{p 4 8 2}{cmd:. binary_mediation, dv(honors) iv(ses) mv(hiread socst) quietly diagram}{p_end}
{p 4 8 2}{cmd:. binary_mediation, dv(honors) iv(ses) mv(hiread socst) quietly probit}{p_end}
{p 4 8 2}{cmd:. binary_mediation, dv(honors) iv(ses) mv(hiread socst) quietly raw}{p_end}

{title:Author}

{p 4 4 2}Phil Ender{break}Statistical Consulting Group
{break}UCLA Academic Technology Services{break}ender@ucla.edu

{title:References}

{p 4 8 2}Kenny,D.A.(2008) Mediation with Dichotomous Outcomes. Retrieved April 23, 
2010 from website: http://davidakenny.net/cm/mediate.htm.{p_end}
{p 4 8 2}Kenny,D.A.(2009) Mediation. Retrieved April 23, 2010 from website:
http://davidakenny.net/cm/mediate.htm.{p_end}
{p 4 8 2}Herr,N.A. (undated) Mediation with Dichotomous Outcomes. Retrieved April 23, 2010 from website:
http://nrherr.bol.ucla.edu/Mediation/logmed.html.{p_end}
