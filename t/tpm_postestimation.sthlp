{smcl}
{* documented: 10oct2010}{...}
{* revised: 14nov2010}{...}
{* revised: 25oct2012}{...}
{cmd:help tpm postestimation}{right:also see:  {help tpm}{space 4}}
{hline}

{p2colset 5 27 33 2}{...}
{p2col :tpm postestimation {hline 2}}Postestimation tools for tpm{p_end}
{p2colreset}{...}


{title:Description}

{pstd}
The following postestimation commands are available for {opt tpm}:

{synoptset 13 notes}{...}
{p2coldent :command}description{p_end}
{synoptline}
{synopt:{bf:{help estat}}}AIC, BIC, VCE, and estimation sample summary{p_end}
INCLUDE help post_estimates
INCLUDE help post_lincom
INCLUDE help post_lrtest
INCLUDE help post_margins
INCLUDE help post_nlcom
{synopt :{helpb tpm postestimation##predict:predict}}predictions{p_end}
INCLUDE help post_predictnl
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}


{marker predict}{...}
{title:Syntax for predict}


{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:{help tpm postestimation##options:options}}] 

{p 8 16 2}
{cmd:predict} {dtype} {c -(}{it:stub*}{c |}{it:newvar1} ... {it:newvarq}{c )-}
{ifin} {cmd:,} {opt sc:ores}


{synoptset 16 tabbed}{...}
{marker options}{...}
{synopthdr :options}
{synoptline}
{syntab :Main}
{synopt :{opt normal}} uses normal theory retransformation to obtain fitted values{p_end}
{synopt :{opt duan}} uses Duan's smearing retransformation to obtain fitted values{p_end}
{synopt :{opt sc:ores}} calculate first derivative of the log likelihood with respect to xb{p_end}

{syntab :Options}
{synopt :{opt nooff:set}} ignore any {opt offset()} or {opt exposure()} variable{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:predict} returns E({depvar}|{indepvar}). In particular, the combined prediction 
is computed as the product of the probability of a positive outcome (first part) and 
the expected value of Y | Y>0 (second part).  This statistic is available both in and 
out of sample; type {cmd:predict} ... {cmd:if e(sample)} ... if wanted only for the 
estimation sample.{p_end}

{title:Options for predict}

{dlgtab:Main}

{phang}
{opt normal} uses normal theory retransformation to obtain fitted values. Either {opt normal} or {opt duan} must be specified when a linear regression of the log of the second part outcome is estimated.{p_end}

{phang}
{opt duan} uses Duan's smearing retransformation to obtain fitted values. Either {opt normal} or {opt duan} must be specified when a linear regression of the log of the second part outcome is estimated.{p_end}

{phang}
{opt scores} create a score variable for each equation (part) in the model. 
Since the score for the second part of the model make sense only with respect 
to the estimation subsample (where Y>0), the calculation is automatically restricted to the 
estimation subsample. {p_end}

{dlgtab:Options}

{phang}
{opt nooffset} may be combined with most statistics and specifies that
the calculation should be made, ignoring any offset or exposure variable
specified when the model was fit.  

{pmore}
If neither the {opt offset(varname_o)} option nor the 
{opt exposure(varname_e)} option was specified when the model was fit,
specifying {opt nooffset} does nothing.


{title:Remarks}
{phang}Retransformation after OLS regression of ln({it:depvar}) is needed to obtain 
consistent predictions of {it:depvar}. {cmd:tpm} implements this using normal theory 
and smearing retransformations but both assume that the errors in the regression are 
homoscedastic. Retransformation in the case of heteroscedastic errors is conceptually 
complex and we have not implemented it in {cmd:tpm}. We suggest the gamma GLM 
with log link as an alternative to a regression of ln({it:depvar}).


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse womenwk, clear}{p_end}
{phang2}{cmd:. replace wage = 0 if wage==.}{p_end}

{pstd}Two part model with logit and glm with Gaussian family and identity link{p_end}
{phang2}{cmd:. tpm wage educ age married children, first(logit) second(glm)}{p_end}
{phang2}{cmd:. predict wagehat1}{p_end}
  
{pstd}Two part model with probit and glm with gamma family and log link{p_end}
{phang2}{cmd:. tpm wage educ age married children, f(probit) s(glm, fam(gamma) link(log))}{p_end}
{phang2}{cmd:. margins, dydx(*)}{p_end}

{pstd}Two part model with probit and linear regression{p_end}
{phang2}{cmd:. tpm wage educ age married children, f(probit) s(regress)}{p_end}
{phang2}{cmd:. margins, dydx(*)}{p_end}

{pstd}Two part model with probit and linear regression of log({it:depvar>0}){p_end}
{phang2}{cmd:. tpm wage educ age married children, f(probit) s(regress, log)}{p_end}
{phang2}{cmd:. margins, dydx(*)}{p_end}
{phang2}{cmd:. margins, predict(duan) dydx(*)}{p_end}

