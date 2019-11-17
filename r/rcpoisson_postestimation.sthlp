{smcl}
{* *! version 1.1.4  14may2009}{...}
{cmd:help rcpoisson postestimation}{right: ({browse "http://www.stata-journal.com/article.html?article=st0001":SJ10-4: st0001})}
{right:also see:  {help rcpoisson}}
{hline}

{title:Title}

{p 4 16 2}
{cmd:rcpoisson postestimation} {hline 2} Postestimation tools for rcpoisson{p_end}


{title:Description}

{pstd}
The following postestimation command is of special interest after {cmd:rcpoisson}:

{synoptset 13}{...}
{p2coldent :command}description{p_end}
{synoptline}
{synopt :{helpb rcpoisson postestimation##estatgof:estat gof}}goodness-of-fit test{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
The following standard postestimation commands are available:

{synoptset 13}{...}
{p2coldent :command}description{p_end}
{synoptline}
INCLUDE help post_estat
INCLUDE help post_estimates
INCLUDE help post_lincom
INCLUDE help post_linktest
INCLUDE help post_lrtest
INCLUDE help post_margins
INCLUDE help post_nlcom
{synopt :{helpb rcpoisson postestimation##predict:predict}}predictions, residuals, influence statistics, and other diagnostic measures{p_end}
INCLUDE help post_predictnl
INCLUDE help post_suest
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}


{title:Special-interest postestimation command}

{pstd}
{cmd:estat gof} performs a goodness-of-fit test of the model.  The default is
the deviance statistic; specifying option {opt pearson} will give the Pearson
statistic.  If the test is significant, the censored Poisson regression model is
inappropriate.


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
{synopt :{opt np}}number of events from the uncensored Poisson{p_end}
{synopt :{opt ir}}incidence rate{p_end}
{synopt :{opt xb}}linear prediction{p_end}
{synopt :{opt stdp}}standard error of the linear prediction{p_end}
{synoptline}
{p2colreset}{...}
INCLUDE help esample


{title:Options for predict}

{dlgtab:Main}

{phang}
{opt n}, the default, calculates the predicted number of events 
from the right-censored Poisson distribution.

{phang}
{opt np} calculates the predicted number of events from the true underlying 
distribution (uncensored Poisson), which is
exp(xb) if neither {opt offset()} nor {opt exposure()} was
specified when the model was fit; exp(xb + offset) if {opt offset()} 
was specified; or exp(xb)*exposure if {opt exposure()} was specified.

{phang}
{opt ir} calculates the incidence rate, exp(xb), the predicted number of
events when exposure is 1.  Specifying {opt ir} is equivalent to
specifying {opt n} when neither
{opt offset()} nor {opt exposure()} was specified when the
model was fit.

{phang}
{opt xb} calculates the linear prediction, which is xb if neither
{cmd:offset()} nor {cmd:exposure()} was specified;
xb + offset if {cmd:offset()} was specified; or
xb + ln(exposure) if {cmd:exposure()} was specified;
see {cmd:nooffset} below.

{phang}
{opt stdp} calculates the standard error of the linear prediction.

{phang}
{opt nooffset} is relevant only if you specified {opt offset()} or
{opt exposure()} when you fit the model.  It modifies the
calculations made by {cmd:predict} so that they ignore the offset or exposure
variable; the linear prediction is treated as xb rather than 
{bind:xb + offset} or xb + ln(exposure). Specifying {cmd:predict} ...{cmd:,}
{cmd:nooffset} is equivalent to specifying {cmd:predict} ...{cmd:,}
{opt ir}.


{marker estatgof}{...}
{title:Syntax for estat gof}

{p 8 14 2}
{cmd:estat gof} [{cmd:,} {opt p:earson}]


{title:Option for estat gof}

{phang}
{opt pearson} requests that {cmd:estat gof} calculate the Pearson statistic
rather than the deviance statistic.


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto}{p_end}
{phang2}{cmd:. rcpoisson rep78 price foreign mpg weight, ul(4)}{p_end}

{pstd}Predict incidence rate{p_end}
{phang2}{cmd:. predict yhat, ir}

{pstd}Goodness-of-fit test{p_end}
{phang2}{cmd:. estat gof}


{title:Author}

{pstd}Rafal Raciborski{break}
      StataCorp{break}
      College Station, TX{break}
      rraciborski@stata.com{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 10, number 4: {browse "http://www.stata-journal.com/article.html?article=st0001":st0001}

{p 7 14 2}Help:  {helpb rcpoisson}
{p_end}
