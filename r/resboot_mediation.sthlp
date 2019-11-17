{smcl}
{* 26oct2011}
{hline}
help for {hi:resboot_mediation}
{hline}

{title:Mediation analysis with residual bootstrap}

{p 8 16 2}{cmd:resboot_mediation}
  [{cmd:if} {it:exp}] [{cmd:in} {it:range}]
  {cmd:,}
  {cmd:dv(}{it:varname}{cmd:)}
  {cmd:mv(}{it:varlist}{cmd:)}
  {cmd:iv(}{it:varname}{cmd:)}
    [ {cmd:cv(}{it:varlist}{cmd:)}
    {cmd:reps(}{it:#reps}{cmd:)} {cmd:level(}{it:level}{cmd:)} {cmd:ranres} ]

{title:Description}
{p 4 4 2}
{cmd:resboot_mediation} performs a residual bootstrap on a mediation model
with continuous mediation and response variables.  The predictor variable may be binary
or continuous.  The indirect effect is computed as the product of coefficients. 

{title:Non-options}
{p 4 8 2}{cmd:dv(}{it:varname}{cmd:)} Name of the response variable.{p_end}
{p 4 8 2}{cmd:iv(}{it:varname}{cmd:)} Name of the predictor variable.{p_end}
{p 4 8 2}{cmd:cv(}{it:varname}{cmd:)} Name of the mediator variable.{p_end}
{title:Options}
{p 4 8 2}{cmd:cv(}{it:varlist}{cmd:)} Optional list of covariate variables.{p_end}
{p 4 8 2}{cmd:reps(}{it:#reps}{cmd:)} Number of bootstrap replications (default=100).{p_end}
{p 4 8 2}{cmd:level(}{it:level}{cmd:)} Level for confidence interval (default=95).{p_end}
{p 4 8 2}{cmd:ranres} Randomly generate residuals with mean=0 and sd=rmse.{p_end}

{title:Examples}
{p 4 8 2}{cmd:. resboot_mediation, dv(science) iv(math) mv(read)}{p_end}
{p 4 8 2}{cmd:. resboot_mediation, dv(science) iv(math) mv(read) cv(write socst)}{p_end}
{p 4 8 2}{cmd:. resboot_mediation, dv(science) iv(math) mv(read) ranres}{p_end}

{title:Author}

{p 4 4 2}Phil Ender{break}UCLA Statistical Consulting Group
{break}ender@ucla.edu

