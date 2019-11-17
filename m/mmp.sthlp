{smcl}
{* *! version 1.0.0  20may2010}{...}
{cmd:help mmp} {right: ({browse "http://www.stata-journal.com/article.html?article=st0189":SJ10-2: st0189})}
{hline}

{title:Title}

{p2colset 5 12 14 2}{...}
{p2col :{hi:mmp} {hline 2}}Marginal model plots{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 11 2}
{cmd:mmp}{cmd:,} {opt m:ean(string)} {opt smo:other(string)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt mean(string)}} option for {helpb predict} to use to generate expectation{p_end}
{p2coldent:* {opt smoother(string)}} smoother to use for generating model and alternative lines{p_end}
{synopt:{cmdab:smoopt:ions(}{it:string}{cmd:)}} options for smoother{p_end}
{synopt:{opt lin:ear}} render a marginal model plot for the linear x'e(b) form{p_end}
{synopt:{opt p:redictors}} render marginal model plot for each predictor{p_end}
{synopt:{cmdab:var:list(}{it:{help varlist}}{cmd:)}} render marginal model
plot for each selected predictor{p_end}
{synopt:{opt gen:erate}} create variables from lowess estimates used in
plots{p_end}
{synopt:{cmdab:indg:options(}{it:string}{cmd:)}} options for individual marginal model plots{p_end}
{synopt:{cmdab:gopt:ions(}{it:string}{cmd:)}} options for combined plot{p_end}
{synoptline}
{p 4 6 2}* {opt mean(string)} and {opt smoother(string)} are required.{p_end}


{title:Description}

{pstd}{cmd:mmp} draws the specified marginal model plots after a generalized linear
model is estimated.  These plots assess how well the model estimates the mean
of the response, conditional on the predictors.  A marginal model plot has
three overlaid components.

{pstd}The first component is a scatterplot of a variable or linear combination
of predictors on the horizontal axis versus the response on the vertical axis.

{pstd}For the second component, a smoother is used to estimate the response
based on the horizontal quantity.  This yields the alternative line, which is
rendered in blue.

{pstd}The third component is obtained by using the smoother to estimate the
conditional mean of the fitted prediction of the response, based on the
horizontal quantity.  This yields the model line, which is rendered as a red
dashed line.

{pstd}A marginal model plot should be generated for each continuous predictor
in the model and the linear x'e(b) form.  The estimated model is a good fit if
the red and blue lines match well.


{title:Options}

{phang} {opt mean(string)} tells {cmd:mmp} what options to pass to 
{helpb predict} to estimate the response based on the predictors.  For linear
regression, {it:string} would be {cmd:xb}.  For logistic regression,
{it:string} would be {cmd:pr}. {cmd:mean()} is required.

{phang} {opt smoother(string)} uses the specified smoothing command to draw
the model and alternative lines.  The smoothing command must have a
{cmd:generate()} option, which takes a single argument; for example, the
{cmd:lowess} command has a {cmd:generate()} option and so is appropriate to
specify in {cmd:smoother()}. {cmd:smoother()} is required.

{phang} {opt smooptions(string)} performs the smoothing with the specified
options.

{phang} {opt linear} draws a marginal model plot for the horizontal quantity
linear x'e(b) form.

{phang} {opt predictors} draws a marginal model plot for each of the
predictors in the model.

{phang} {cmd:varlist({it:{help varlist}})} draws a marginal model plot for
each of the specified variables. This option is ignored if {opt predictors} is
used.

{phang} {opt generate} generates the variables {it:x}{cmd:_model} and {it:x}{cmd:_alt}
for each output plot for predictor {it:x} corresponding to the lowess
estimates for the model and alternative lines.  If {opt linear} is specified,
then {cmd:generate} creates the variables {cmd:linform_model} and
{cmd:linform_alt}.

{phang} {opt indgoptions(string)} draws individual marginal model plots with
the specified {it:{help twoway_options}} applied to each plot.

{phang} {opt goptions(string)} draws marginal model plots with the specified
{helpb graph combine} options applied to the combined graphic.


{title:Examples}

{phang2}{bf:{stata "sysuse auto":. sysuse auto}}

{phang2}{bf:{stata "regress mpg weight foreign":. regress mpg weight foreign}}

{phang2}{bf:{stata "mmp, mean(xb) smoother(lowess) linear predictors smooptions(bwidth(.66))":. mmp, mean(xb) smoother(lowess) linear predictors smooptions(bwidth(.66))}}

{phang2}{bf:{stata "generate weight2 = weight^2":. generate weight2 = weight^2}}

{phang2}{bf:{stata "regress mpg weight weight2 foreign":. regress mpg weight weight2 foreign}}

{phang2}{bf:{stata "mmp, mean(xb) smoother(lowess) linear predictors smooptions(bwidth(.66))":. mmp, mean(xb) smoother(lowess) linear predictors smooptions(bwidth(.66))}}


{title:Also see}

{psee}
Article: {it:Stata Journal}, volume 10, number 2: {browse "http://www.stata-journal.com/article.html?article=st0189":st0189}{p_end}
