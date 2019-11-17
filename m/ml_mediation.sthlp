{smcl}
{* 4oct2011}{...}
{hline}
help for {hi:ml_mediation}
{hline}

{title:Mediation for multilevel data}

{p 8 16 2}{cmd:ml_mediation}{cmd:,}
  {cmd:dv(}{it:varname}{cmd:)}
  {cmd:mv(}{it:varname}{cmd:)}
  {cmd:iv(}{it:varname}{cmd:)}
  {cmd:l2id(}{it:varname}{cmd:)}
    [ {cmd:cv(}{it:varlist}{cmd:)}
    {cmd:mle} ]

{title:Description}

{p 4 4 2}
{cmd:ml_mediation} computes direct, indirect and total effects for 2 level
random intercept models with continuous response variables. 

{p 4 4 2}
{bf:Note:} This program does not provide standard errors or confidence intervals for coefficients.  Bootstrap
standard errors and confidence intervals are recommended for this purpose.  You
should include the {cmd:strata} option in the {cmd:boostrap} command.
Here is an example:{p_end}{break}
{p 4 8 2}{cmd:. quietly bootstrap r(ind_eff) r(dir_eff) r(tot_eff), /// }{p_end}
{p 8 8 2}{cmd:strata(cid) reps(500): ml_mediation, dv(write) iv(hon) ///}{p_end}
{p 8 8 2}{cmd:mv(abil) cv(socst) l2id(cid)}{p_end}
{p 4 8 2}{cmd:. estat bootstrap, percentile bc}{p_end}

{title:Options}
{p 4 8 2}{cmd:cv(}{it:varlist}{cmd:)} Optional list of covariate variables.  
Variables may be continuous, binary or factor variables.{p_end}
{p 4 8 2}{cmd:mle} Option to use mle with {cmd:xtmixed} instead of 
the default reml.{p_end}
{break}

{title:Non-options}
{p 4 8 2}{cmd:dv(}{it:varname}{cmd:)} Name of the continuous dependent variable.  
Must be a level 1 variable.{p_end}
{p 4 8 2}{cmd:iv(}{it:varname}{cmd:)} Name of the continuous or binary predictor variable.{p_end}
{p 4 8 2}{cmd:mv(}{it:varname}{cmd:)} Name of the continuous mediator variable.{p_end}
{p 4 8 2}{cmd:l2id(}{it:varname}{cmd:)} Name of the level 2 id variable.{p_end}
{break}

{title:Remarks}
{p 4 8 2}{cmd:ml_mediation} is designed to work with 2 level random intercept
models. The program only allows for one MV but you are welcome to
modify the program to accomodate multiple CVs.  The indirect effect is computed as the
product of coefficients.  {cmd:panel_mediation} does not support {cmd:if} or 
{cmd:in}, so subset your data before running.{p_end}
{p 4 8 2}According to Krull & MacKinnon (2001) a predictor variable may be mediated
by a variable at the same level or lower.  Thus a level 2 mediator may be mediated
by a level 2 or level 1 variable.  A level 1 predictor may only be mediated by another
level 1 variable.  Logically, a level 1 predictor cannot affect a level 2 mediator.
{cmd:ml_mediation} does not, however, enforce this rule. {p_end}
{p 4 8 2}{bf:Note:} This program is considered to be experimental.  Please use with
extreme caution.{p_end}
{break}
{title:Examples}
{p 6 8 2}{cmd:/* example 1:  iv level 1; mv level 1 */}{p_end}
{p 4 8 2}{cmd:. ml_mediation, dv(write) iv(hon) mv(abil) cv(socst i.grp) l2id(cid)}{p_end}{break}
{p 6 8 2}{cmd:/* example 2:  iv level 2; mv level 2 */}{p_end}
{p 4 8 2}{cmd:. ml_mediation, dv(write) iv(m_hon) mv(m_abil) cv(socst i.grp) l2id(cid)}{p_end}

{title:Author}

{p 4 4 2}Phil Ender{break}{break}UCLA Statistical Consulting Group{break}ender@ucla.edu

{title:Reference}

{p 4 8 2}Krull,J.L. & MacKinnon,D.P.(2001) Multilevel modeling of individual and
{it:group level mediated effects. Multivariate Behavioral Research, 36}(2), 249-277.{p_end}
