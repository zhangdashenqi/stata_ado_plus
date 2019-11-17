{smcl}
{* *! version 1.0.0  19apr10}{...}
{cmd:help xblc}{right: ({browse "http://www.stata-journal.com/article.html?article=st0215":SJ11-1: st0215})}
{hline}

{title:Title}

{p2colset 5 13 10 2}{...}
{p2col :{hi: xblc} {hline 2}}Tabulate and plot results after flexible modeling of a quantitative covariate{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 12 2}
{cmd:xblc} {it:varlist}{cmd:,} {opt at(numlist)} {opt c:ovname(varname)} 
[{opt r:eference(#)} {opt pr} {opt eform} {cmdab:f:ormat(%}{it:fmt}{cmd:)}
 {opt l:evel(#)} {opt eq:uation(string)} 
 {cmdab:gen:erate(}{it:newvar1 newvar2 newvar3 newvar4}{cmd:)}]


{title:Description}

{pstd} {opt xblc} computes point and interval estimates for predictions or
differences in predictions of the response variable evaluated at different
values of a quantitative covariate modeled using one or more transformations
of the original variable specified in {it:varlist}.  It can be used after any
estimation command.


{title:Options}

{phang} {opt at(numlist)} specifies the values of the covariate specified in
{opt covname()}, at which {cmd:xblc} evaluates predictions or differences in
predictions.  The values need to be in the current dataset.  Covariates other
than the one specified with the {opt covname()} option are fixed at zero.
This is a required option.

{phang}
{opt covname(varname)} specifies the name of the quantitative covariate.  This
is a required option.

{phang} {opt reference(#)} specifies the reference value for displaying
differences in predictions.

{phang} {opt pr} computes and displays predictions (that is, mean response after
linear regression, log odds after logistic models, and log rate after Poisson
models with person-time as offset) rather than differences in predictions.  To
use this option, check that the previously fit model estimates the constant
{cmd:_b[_cons]}.

{phang}
{opt eform} displays the exponential value of predictions or differences in
predictions.

{phang}
{cmd:format(%}{it:fmt}{cmd:)} specifies the display format for presenting
numbers.  {cmd:format(%3.2f)} is the default; see help {helpb format}.{p_end}

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence
intervals.  The default is {cmd:level(95)} or as set by {helpb set level}.

{phang} {opt equation(string)} specifies the name of the equation when you
have previously fit a multiple-equation model.

{phang} {opt generate(newvar1 newvar2 newvar3 newvar4)} specifies that the
values of the original covariate, predictions or differences in
predictions, and the lower and upper bounds of the confidence interval be
saved in {it:newvar1},
{it:newvar2}, {it:newvar3}, and {it:newvar4}, respectively.  This option is very
useful for presenting the results in a graphical form.


{title:Example}

{phang}{cmd:. use http://nicolaorsini.altervista.org/data/pa_luts}{p_end}
{phang}{cmd:. quietly summarize age}{p_end}
{phang}{cmd:. generate agec = age - r(mean)}{p_end}

{phang}{cmd:. mkspline tpas = tpa, knots(37.2 39.6 42.3 45.6) cubic}{p_end}
{phang}{cmd:. logit ipss2 tpas1 tpas2 tpas3 agec}{p_end}
{phang}{cmd:. capture drop pa or lb ub}{p_end}

{phang}{cmd:. xblc tpas1-tpas3, covname(tpa) at(29 32 35 38 40 43 45 48 52 55) reference(29) eform generate(pa or lb ub)}{p_end}

{phang}{cmd:. twoway (rcap lb ub pa, sort) (scatter or pa, sort), legend(off) scheme(s1mono) xlabel(29(2)55) xmtick(29(1)55) ylabel(.2(.2)1.2, angle(horiz) format(%2.1fc)) ytitle("Age-adjusted Odds Ratios of LUTS")} 
{cmd:xtitle("Total physical activity, MET-hours/day") name(f1, replace)}


{title:Authors}

{pstd}Nicola Orsini{p_end}
{pstd}National Institute of Environmental Medicine{p_end}
{pstd}Karolinska Institutet{p_end}
{pstd}{browse "mailto:nicola.orsini@ki.se?subject=info xblc":nicola.orsini@ki.se}{p_end}
{pstd}{browse "http://nicolaorsini.altervista.org"}{p_end}

{pstd}Sander Greenland{p_end}
{pstd}Department of Epidemiology and Statistics{p_end}
{pstd}University of California-Los Angeles{p_end}
{pstd}Los Angeles, CA{p_end}


{title:Also see}

{psee}Article:  {it:Stata Journal}, volume 11, number 1: {browse "http://www.stata-journal.com/article.html?article=st0215":st0215}

{psee}
{space 1}Manual:  {manlink R lincom} {manlink R predictnl} 

{psee}
{space 3}Help:  {manhelp lincom R} {manhelp predictnl R} 
{p_end}
