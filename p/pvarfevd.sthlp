{smcl}
{* *! version 1.0 - 22 June 2016}{...}
{cmd:help pvarfevd}{right: ({browse "http://www.stata-journal.com/article.html?article=st0455":SJ16-3: st0455})}
{hline}

{title:Title}

{phang}
{bf:pvarfevd} {hline 2} Calculate FEVDs after pvar


{title:Syntax}

{p 8 17 2}
{cmd:pvarfevd}
[{cmd:,} {it:options}]

{synoptset 25}{...}
{synopthdr}
{synoptline}
{synopt:{opt st:ep(#)}}set forecast horizon to {it:#}; default is {cmd:step(10)}{p_end}
{synopt:{opt imp:ulse(impulsevars)}}use {it:impulsevars} as impulse variables{p_end}
{synopt:{opt res:ponse(responsevars)}}use {it:responsevars} as response variables{p_end}
{synopt:{opth po:rder(varlist)}}specify Cholesky ordering of endogenous variables{p_end}
{synopt:{opt mc(#)}}use {it:#} Monte Carlo simulation draws to estimate standard errors and 90% confidence intervals{p_end}
{synopt:{opt dots}}show iteration dots{p_end}
{synopt:{opt save(filename)}}save forecast-error variance decomposition as
{it:filename}{cmd:.dta}; default is not to save{p_end}
{synopt:{opt notable}}suppress display of results table{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:pvarfevd} is for use after fitting a panel vector autoregressive model
with the {cmd:pvar} command; see {helpb pvar}.{p_end}


{title:Description}

{pstd}
{cmd:pvarfevd} estimates and displays Cholesky forecast-error variance
decomposition (FEVD) after estimation by {helpb pvar}.  Standard errors and
confidence intervals based on Monte Carlo simulation may be optionally
computed.

{pstd}
One should exercise caution in interpreting computed FEVD when
exogenous variables are included in the underlying panel VAR model.
Contributions of exogenous variables, when included in the panel VAR
model, to forecast-error variance are disregarded in calculating FEVD.

{pstd}
The rows of the table are the time since impulse.  Each column represents the
share of an {opt impulse()} variable to the forecast-error variance of a
{opt response()} variable.


{title:Options}

{phang}
{opt step(#)} specifies the step (forecast) horizon; the default is 10 
periods.

{phang}
{opt impulse(impulsevars)} and {opt response(responsevars)} specify the
impulse and response variables for which FEVD are to be reported.  If
{opt impulse()} or {opt response()} is not specified, each endogenous
variable is used in turn.

{phang}
{opth porder(varlist)} specifies the Cholesky ordering of the endogenous
variables to be used when estimating FEVDs.  By default, the order in which
the variables were originally specified on the underlying {cmd:pvar} command
is used.

{phang}
{opt mc(#)} requests that {it:#} Monte Carlo draws be used to estimate the
standard errors and the percentile-based 90% confidence intervals of the
FEVDs.  Computed standard errors and confidence intervals are not displayed
but may be saved as a separate file.

{phang}
{opt dots} requests the display of iteration dots.  By default, one dot
character is displayed for each iteration.  A red "x" is displayed if the
iteration returns an error.

{phang}
{opt save(filename)} specifies that the FEVDs be saved under the name
{it:filename}.  In addition, standard errors and percentile-based 90%
confidence intervals are saved when {opt mc(#)} > 1 is specified.

{phang}
{opt notable} requests the table be constructed but not displayed.


{title:Example}

{phang}{cmd:. webuse nlswork2}{p_end}

{phang}{cmd:. xtset idcode year}{p_end}

{phang}{cmd:. generate wage = exp(ln_wage)}{p_end}

{phang}{cmd:. pvar wage hours}

{phang}{cmd:. pvarfevd}


{title:Stored results}

{pstd}
{cmd:pvarfevd} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(iter)}}Monte Carlo iterations{p_end}
{synopt:{cmd:r(step)}}forecast horizon{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(porder)}}Cholesky order{p_end}


{title:Authors}

{pstd}
Michael R. M. Abrigo{break}
Philippine Institute for Development Studies{break}
mabrigo@mail.pids.gov.ph

{pstd}
Inessa Love{break}
University of Hawaii at Manoa{break}
ilove@hawaii.edu

	
{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 16, number 3: {browse "http://www.stata-journal.com/article.html?article=st0455":st0455}

{p 7 14 2}Help:  
{helpb pvar},
{helpb pvarirf},
{helpb pvargranger},
{helpb pvarsoc},
{helpb pvarstable}
{p_end}
