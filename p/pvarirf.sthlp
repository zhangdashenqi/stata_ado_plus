{smcl}
{* *! version 1.0 - 22 June 2016}{...}
{cmd:help pvarirf}{right: ({browse "http://www.stata-journal.com/article.html?article=st0455":SJ16-3: st0455})}
{hline}

{title:Title}

{phang}
{bf:pvarirf} {hline 2} Create and analyze IRFs and dynamic multipliers after
pvar


{title:Syntax}

{p 8 17 2}
{cmd:pvarirf}
[{cmd:,} {it:options}]

{synoptset 25}{...}
{synopthdr}
{synoptline}
{synopt:{opt st:ep(#)}}set forecast horizon to {it:#}; default is {cmd:step(10)}{p_end}
{synopt:{opt imp:ulse(impulsevars)}}use {it:impulsevars} as impulse variables{p_end}
{synopt:{opt res:ponse(responsevars)}}use {it:responsevars} as response variables{p_end}
{synopt:{opth po:rder(varlist)}}specify Cholesky ordering of endogenous variables{p_end}
{synopt:{opt oirf}}estimate orthogonalized impulse-response functions{p_end}
{synopt:{opt dm}}estimate dynamic multipliers instead of impulse-response functions{p_end}
{synopt:{opt cum:ulative}}estimate cumulative impulse-response or dynamic multiplier functions{p_end}
{synopt:{opt mc(#)}}use # Monte Carlo simulation draws to estimate confidence intervals{p_end}
{synopt:{opt tab:le}}display a table of the calculated IRFs or DMs{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt dots}}show iteration dots{p_end}
{synopt:{opt save(filename)}}save estimates as {it:filename}{cmd:.dta}; default is not to save{p_end}
{synopt:{opth byop:tion(by_option)}}affect how subgraphs are combined, labeled, etc.{p_end}
{synopt:{opt nodraw}}suppress display of the estimated IRFs{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:pvarif} is for use after fitting a panel vector autoregression model with
the {cmd:pvar} command; see {helpb pvar}.{p_end}


{title:Description}

{pstd}
{cmd:pvarirf} estimates and graphs impulse-response functions (IRFs) and
dynamic multipliers (DMs) after estimation by {helpb pvar}.


{title:Options}

{phang}
{opt step(#)} specifies the step (forecast) horizon; the default is 10
periods.

{phang}
{opt impulse(impulsevars)} and {opt response(responsevars)} specify the impulse
and response variables.  Usually, one of each is specified, and one graph is
drawn.  If multiple variables are specified, a separate subgraph is drawn for
each impulse-response combination.  If {opt impulse()} and {opt response()}
are not specified, subgraphs are drawn for all combinations of impulse and
response variables.

{phang}
{opth porder(varlist)} specifies the Cholesky ordering of the endogenous
variables to be used when estimating orthogonalized IRFs as well as the order
of the IRF plots.  By default, the order in which the variables were originally
specified on the {cmd:pvar} command is used.  This allows a new set of IRFs
with a different order to be produced without reestimating the system.

{phang}
{opt oirf} requests that orthogonalized IRFs be estimated.  The default is
simple IRFs.

{phang}
{opt dm} estimates dynamic multipliers for exogenous variables instead of
IRFs.

{phang}
{opt cumulative} computes cumulative IRFs.  This option may be combined with
{cmd:oirf}.

{phang}
{opt mc(#)} requests that {it:#} Monte Carlo draws be used to estimate
confidence intervals of the IRFs using Gaussian approximation.  The default is
not to estimate or plot confidence intervals; that is, {it:#} = 0.

{phang}
{opt table} displays the calculated IRFs as a table.  The default is not to
tabulate IRFs.

{phang}
{opt level(#)} specifies the confidence level, as a percentage, to be used for
computing confidence bands.  The default is {cmd:level(95)} or as set by
{helpb set level}.  {cmd:level()} is available only when {opt mc(#)} > 1 is
specified.

{phang}
{opt dots} requests the display of iteration dots.  By default, one dot
character is displayed for each iteration.  A red "x" is displayed if the
iteration returns an error.

{phang}
{opt save(filename)} specifies that the calculated IRFs be saved under the
name {it:filename}.

{phang}
{opt byoption(by_option)} affects how the subgraphs are combined, labeled,
etc.  This option is documented in {manhelpi by_option G-3}.
 
{phang}
{opt nodraw} suppresses the display of the estimated IRFs.


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse nlswork2}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}
{phang2}{cmd:. generate wage = exp(ln_wage)}{p_end}

{pstd}Fit panel vector autoregressive model with one lag by Helmert
transformation (the default){p_end}
{phang2}{cmd:. pvar wage hours}{p_end}

{pstd}Estimate impulse-response functions{p_end}
{phang2}{cmd:. pvarirf}{p_end}
{phang2}{cmd:. pvarirf, oirf mc(200) byoption(yrescale)}{p_end}
{phang2}{cmd:. pvarirf, oirf mc(200) porder(hours wage) byoption(yrescale)}
{p_end}

{pstd}Fit panel vector autoregressive model with exogenous variable{p_end}
{phang2}{cmd:. pvar wage hours, exog(wks_ue)}{p_end}

{pstd}Estimate dynamic multiplier functions{p_end}
{phang2}{cmd:. pvarirf, dm}{p_end}
{phang2}{cmd:. pvarirf, dm mc(200) byoption(yrescale)}{p_end}


{title:Stored results}

{pstd}
{cmd:pvarirf} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(iter)}}Monte Carlo iterations{p_end}
{synopt:{cmd:r(step)}}forecast horizon{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(porder)}}Cholesky order of orthogonalized IRF{p_end}


{title:Authors}

{pstd}
Michael R. M. Abrigo{break}
Philippine Institute for Development Studies{break}
mabrigo@mail.pids.gov.ph{break}

{pstd}
Inessa Love{break}
University of Hawaii at Manoa{break}
ilove@hawaii.edu{break}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 16, number 3: {browse "http://www.stata-journal.com/article.html?article=st0455":st0455}

{p 7 14 2}Help:  
{helpb pvar}, 
{helpb pvarfevd},
{helpb pvargranger},
{helpb pvarsoc}, 
{helpb pvarstable}
{p_end}
