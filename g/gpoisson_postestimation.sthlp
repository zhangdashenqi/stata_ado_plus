{smcl}
{* *! version 1.0.0  17jul2011}{...}
{cmd:help gpoisson postestimation} {...}
{right:dialogs:  {dialog gpoisson_p:predict}}
{right: ({browse "http://www.stata-journal.com/article.html?article=st0279":SJ12-4: st0279})}
{hline}

{title:Title}

{p2colset 5 32 34 2}{...}
{p2col :{hi:gpoisson postestimation} {hline 2}}Postestimation tools for
gpoisson{p_end}
{p2colreset}{...}


{title:Description}

{pstd}The following standard postestimation commands are available after
{cmd:gpoisson}:

{synoptset 13 notes}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
INCLUDE help post_estat
INCLUDE help post_svy_estat
INCLUDE help post_estimates
INCLUDE help post_lincom
INCLUDE help post_linktest
INCLUDE help post_lrtest_star
INCLUDE help post_margins
INCLUDE help post_nlcom
{synopt :{helpb gpoisson postestimation##predict:predict}}predictions, residuals, influence statistics, and other diagnostic measures{p_end}
INCLUDE help post_predictnl
INCLUDE help post_suest
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}
INCLUDE help post_lrtest_star_msg


{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} 
[{cmd:,} {it:statistic} {opt nooff:set}]

{synoptset 11 tabbed}{...}
{synopthdr :statistic}
{synoptline}
{syntab :Main}
{synopt :{opt n}}number of events; the default{p_end}
{synopt :{opt ir}}incidence rate{p_end}
{synopt :{opt xb}}linear prediction{p_end}
{synopt :{opt stdp}}standard error of the linear prediction{p_end}
{synopt :{opt sc:ore}}first derivative of the log likelihood with respect to
xb{p_end}
{synoptline}
{p2colreset}{...}
INCLUDE help esample


INCLUDE help menu_predict


{title:Options for predict}

{dlgtab:Main}

{phang}{opt n}, the default, calculates the predicted number of events.
The predicted number of events is exp(xb) if neither {opt offset()} nor
{opt exposure()} was specified when the model was fit; exp(xb + offset)
if {opt offset()} was specified; or exp(xb)*exposure if {opt exposure()}
was specified.

{phang}{opt ir} calculates the incidence rate, exp(xb), which is the
predicted number of events when the exposure is 1.  Specifying {opt ir}
is equivalent to specifying {opt n} when neither {opt offset()} nor 
{opt exposure()} was specified when the model was fit.

{phang}{opt xb} calculates the linear prediction.  The linear prediction
is xb if neither {cmd:offset()} nor {cmd:exposure()} was specified; xb +
offset if {cmd:offset()} was specified; or xb + ln(exposure) if
{cmd:exposure()} was specified.  See {cmd:nooffset} below.

{phang}{opt stdp} calculates the standard error of the linear
prediction.

{phang}{opt score} calculates the equation-level score, the derivative
of the log likelihood with respect to the linear prediction.

{phang}{opt nooffset} is relevant only if you specified {opt offset()}
or {opt exposure()} when you fit the model.  It modifies the
calculations made by {cmd:predict} so that they ignore the offset or
exposure variable; the linear prediction is treated as xb rather than as
{bind:xb + offset} or xb + ln(exposure).  Specifying {cmd:predict}
...{cmd:,} {cmd:nooffset} is equivalent to specifying {cmd:predict}
...{cmd:,} {opt ir}.


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse dollhill3}{p_end}
{phang2}{cmd:. gpoisson deaths smokes i.agecat, exp(pyears)}{p_end}

{pstd}Predict incidence rate{p_end}
{phang2}{cmd:. predict deathrate, ir}


{title:Authors}

{pstd}Tammy Harris{p_end}
{pstd}Institute for Families in Society{p_end}
{pstd}Department of Epidemiology and Biostatistics{p_end}
{pstd}University of South Carolina{p_end}
{pstd}Columbia, SC{p_end}
{pstd}harris68@mailbox.sc.edu{p_end}

{pstd}Zhao Yang{p_end}
{pstd}Quintiles, Inc.{p_end}
{pstd}Morrisville, NC{p_end}
{pstd}tonyyangsxz@gmail.com{p_end}

{pstd}James W. Hardin{p_end}
{pstd}Institute for Families in Society{p_end}
{pstd}Department of Epidemiology and Biostatistics{p_end}
{pstd}University of South Carolina{p_end}
{pstd}Columbia, SC{p_end}
{pstd}jhardin@sc.edu{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 12, number 4: {browse "http://www.stata-journal.com/article.html?article=st0279":st0279}

{p 5 14 2}Manual:  {manlink R poisson postestimation}, {manlink R nbreg postestimation}

{p 7 14 2}Help:  {helpb gpoisson}, {manhelp poisson R}, {manhelp nbreg R} (if installed){p_end}
