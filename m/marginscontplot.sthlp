{smcl}
{* *! version 1.1.0  18dec2012}{...}
{cmd:help marginscontplot}{right: ({browse "http://www.stata-journal.com/article.html?article=gr0056":SJ13-3: gr0056})}
{hline}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :{hi:marginscontplot} {hline 2}}Graph margins for continuous predictors{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 12 2}
{{cmd:marginscontplot}|{hi:mcp}}
{it:xvar1} [{cmd:(}{it:xvar1a} [{it:xvar1b} ...]{cmd:)}]
[{it:xvar2} [{cmd:(}{it:xvar2a} [{it:xvar2b} ...]{cmd:)}]]
{ifin}
[{cmd:,} {it:options}]

{synoptset 27}{...}
{marker marginscontplot_options}{...}
{synopthdr :options}
{synoptline}
{synopt :{opt at(at_list)}}fix values of model covariates{p_end}
{synopt :{cmd:at1(}[{cmd:%}]{it:at1_list}{cmd:)}}define plotting positions for {it:xvar1}{p_end}
{synopt :{cmd:at2(}[{cmd:%}]{it:at2_list}{cmd:)}}define plotting positions for {it:xvar2}{p_end}
{synopt :{opt ci}}display pointwise confidence interval(s){p_end}
{synopt :{opt mar:gopts(string)}}options for {cmd:margins}{p_end}
{synopt :{opt nograph}}suppress graph{p_end}
{synopt :{opth plot:opts(twoway_options)}}options for {cmd:graph twoway}{p_end}
{synopt :{cmdab:sav:ing(}{it:{help filename}}[{cmd:, replace}]{cmd:)}}save margins and confidence intervals to file{p_end}
{synopt :{opt sh:owmarginscmd}}show the {cmd:margins} command as issued{p_end}
{synopt :{cmd:var1(}{it:#}|{it:var1_spec}{cmd:)}}specify transformed values of {it:xvar1} for plotting{p_end}
{synopt :{cmd:var2(}{it:#}|{it:var2_spec}{cmd:)}}specify transformed values of {it:xvar2} for plotting{p_end}
{synoptline}
{p2colreset}{...}
{phang}
You must have run an estimation command before using {cmd:marginscontplot}.


{title:Description}

{pstd}
{cmd:marginscontplot} provides a graph of the marginal effect of a
continuous predictor on the response variable in the most recently fit
regression model.  When only {it:xvar1} is provided, the plot of
marginal effects is univariate at values of {it:xvar1} specified by the
{opt at1()} or {opt var1()} option.  When both {it:xvar1} and {it:xvar2}
are provided, the plot of marginal effects is against values of
{it:xvar1} specified by the {opt at1()} or {opt var1()} option for fixed
values of {it:xvar2} specified by the {opt at2()} or {opt var2()}
option.  A line is plotted for each specified value of {it:xvar2}.

{pstd}
{cmd:marginscontplot} has the distinctive ability to plot marginal
effects on the original scale of {it:xvar1} or {it:xvar2}, even when the
model includes transformed values of {it:xvar1} or {it:xvar2} but does
not include {it:xvar1} or {it:xvar2} themselves.  Such a situation
arises in models involving simple transformations such as logs and more
complicated transformations such as fractional polynomials or splines,
for example, where nonlinear relationships with continuous predictors
are to be approximated.  Transformed covariates are included in the
model to achieve this.

{pstd}
{cmd:mcp} is a synonym for {cmd:marginscontplot} for those who
prefer to type less.


{title:Options}

{phang}
{opt at(at_list)} fixes values of model covariates other than
{it:xvar1} and {it:xvar2}.  {it:at_list} has syntax {it:varname1}
{cmd:=} {it:#} [{it:varname2} {cmd:=} {it:#} ...].  By default,
predictions for such covariates are made at the observed values and
averaged across observations.

{phang}
{cmd:at1(}[{cmd:%}]{it:at1_list}{cmd:)} defines the plotting
positions for {it:xvar1} through the numlist {it:at1_list}.  If the
prefix {cmd:%} is included, {it:at1_list} is interpreted as percentiles
of the distribution of {it:xvar1}.  If {opt at1()} is omitted, all the
observed values of {it:xvar1} are used if feasible.  Note that
{it:xvar1} is always treated as the primary plotting variable on the x
dimension.

{phang}
{cmd:at2(}[{cmd:%}]{it:at2_list}{cmd:)} defines the plotting
positions for {it:xvar2} through the numlist {it:at2_list}.  If the
prefix {cmd:%} is included, {it:at2_list} is interpreted as percentiles
of the distribution of {it:xvar2}.  If {opt at2()} is omitted, all the
observed values of {it:xvar2} are used if feasible.  Note that
{it:xvar2} is always treated as the secondary "by-variable" for plotting
purposes.

{phang}
{opt ci} displays pointwise confidence intervals for the fitted
values on the margins plot.  For legibility, if more than one line is
specified, each line is plotted on a separate graph.

{phang}
{opt margopts(string)} supplies options to the {cmd:margins}
command.  The option most likely to be needed is {cmd:predict(xb)},
which means that predicted values and, hence, margins are on the scale
of the linear predictor.  For example, in a logistic regression model,
the default predictions are of the event probabilities.  Specifying
the option {cmd:margopts(predict(xb))} gives margins on the scale of the
linear predictor, that is, the predicted log odds of an event.

{pmore}
Note that the margins are calculated with the default setting,
{opt asobserved}, for {cmd:margins}.  See {helpb margins} for further
information.

{phang}
{opt nograph} suppresses the graph of marginal effects.

{phang}
{opt plotopts(twoway_options)} are options of {cmd:graph twoway};
see {manhelpi twoway_options G-3}.

{phang}
{cmd:saving(}{it:{help filename}}[{cmd:, replace}]{cmd:)} saves the
calculated margins and their confidence intervals to a file
({it:filename}{cmd:.dta}).  This can be useful for fine-tuning the plot
or tabulating the results.

{phang}
{opt showmarginscmd} displays the {cmd:margins} command that
{cmd:marginscontplot} creates and issues to Stata to do the calculations
necessary for constructing the plot.  This information can be helpful in
fine-tuning the command or identifying problems.

{phang}
{cmd:var1(}{it:#}|{it:var1_spec}{cmd:)} specifies plotting values
of {it:xvar1}.  If {opt var1(#)} is specified, then {it:#} equally
spaced values of {it:xvar1} are used as plotting positions, encompassing
the observed range of {it:xvar1}.  Alternatively, {it:var1_spec} may be
used to specify transformed plotting values of {it:xvar1}.  The syntax
of {it:var1_spec} is {it:var1} [{cmd:(}{it:var1a} [{it:var1b}
...]{cmd:)}].  {it:var1} is a variable holding user-specified plotting
values of {it:xvar1}.  {it:var1a} is a variable holding transformed
values of {it:var1} and similarly for {it:var1b} ... if required.

{pmore}
See also {help marginscontplot##remarks:{it:Remarks}}.

{phang}
{cmd:var2(}{it:#}|{it:var2_spec}{cmd:)} specifies plotting values
of {it:xvar2}.  If {opt var2(#)} is specified, then {it:#} equally
spaced values of {it:xvar2} are used as plotting positions, encompassing
the observed range of {it:xvar2}.  Alternatively, {it:var2_spec} may be
used to specify transformed plotting values of {it:xvar2}.  The syntax
of {it:var2_spec} is {it:var2} [{cmd:(}{it:var2a} [{it:var2b}
...]{cmd:)}].  {it:var2} is a variable holding user-specified plotting
values of {it:xvar2}.  {it:var2a} is a variable holding transformed
values of {it:var2} and similarly for {it:var2b} ... if required.

{pmore}
See also {help marginscontplot##remarks:{it:Remarks}}.


{marker remarks}{...}
{title:Remarks}

{pstd}
The version of {opt var1()} with {it:var1_spec} is appropriate for
use after any covariate transformation is used in the model and you want
a plot with the original (untransformed) covariate on the horizontal
axis.  This includes simple transformations such as logs and more
complicated situations.  For example, the model may involve a fractional
polynomial model in {it:xvar1} using {cmd:fracpoly} or {cmd:mfp}.
Alternatively, fractional polynomial transformations of {it:xvar1} may
be calculated using {cmd:fracgen}, and the required model fit to the
transformed variables before applying {cmd:marginscontplot}.  The same
facility is available for the {opt var2()} option.  It works in the same
way but with {it:xvar2} instead of {it:xvar1}.

{pstd}
{cmd:marginscontplot} has been designed to handle quite
high-dimensional cases, that is, cases where many margins must be
estimated.  Be aware, however, that the number of margins is limited by
the maximum matrix size; see {helpb matsize}.  This can be increased if
necessary by using the {cmd:set matsize} {it:#} command.
{cmd:marginscontplot} tells you the smallest value of {it:#} needed to
accommodate the case in question.


{title:Examples}

{pstd}Basic examples{p_end}
{phang2}{cmd:. sysuse auto}{p_end}
{phang2}{cmd:. regress mpg i.foreign weight}{p_end}
{phang2}{cmd:. marginscontplot weight}{p_end}
{phang2}{cmd:. marginscontplot weight, at1(2000(100)4500) ci}{p_end}
{phang2}{cmd:. marginscontplot weight foreign, var1(20) at2(0 1)}{p_end}

{pstd}Example using a log-transformed covariate{p_end}
{phang2}{cmd:. generate logwt = log(weight)}{p_end}
{phang2}{cmd:. regress mpg i.foreign##c.logwt}{p_end}
{phang2}{cmd:. quietly summarize weight}{p_end}
{phang2}{cmd:. range w1 r(min) r(max) 20}{p_end}
{phang2}{cmd:. generate logw1 = log(w1)}{p_end}
{phang2}{cmd:. marginscontplot weight (logwt), var1(w1 (logw1)) ci}

{pstd}Example using a fractional polynomial model{p_end}
{phang2}{cmd:. fracpoly: regress mpg weight foreign}{p_end}
{phang2}{cmd:. marginscontplot weight (Iweig__1 Iweig__2) foreign, var1(20) ci}

{pstd}Do-it-yourself fractional polynomial example{p_end}
{phang2}{cmd:. fracgen weight -2 -2}{p_end}
{phang2}{cmd:. quietly summarize weight}{p_end}
{phang2}{cmd:. range w1 r(min) r(max) 20}{p_end}
{phang2}{cmd:. generate w1a = (w1/1000)^-2}{p_end}
{phang2}{cmd:. generate w1b = (w1/1000)^-2 * ln(w1/1000)}{p_end}
{phang2}{cmd:. regress mpg i.foreign##c.(weight_1 weight_2)}{p_end}
{phang2}{cmd:. marginscontplot weight (weight_1 weight_2), var1(w1 (w1a w1b)) ci}{p_end}
{phang2}{cmd:. marginscontplot weight (weight_1 weight_2) foreign, var1(w1 (w1a w1b))}{p_end}

{pstd}Simplified version of the above{p_end}
{phang2}{cmd:. fracgen w1 -2 -2}{p_end}
{phang2}{cmd:. marginscontplot weight (weight_1 weight_2) foreign, var1(w1 (w1_1 w1_2))}{p_end}


{title:Author}

{phang}Patrick Royston{p_end}
{phang}MRC Clinical Trials Unit{p_end}
{phang}London, UK{p_end}
{phang}pr@ctu.mrc.ac.uk{p_end}


{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 13, number 3: {browse "http://www.stata-journal.com/article.html?article=gr0056":gr0056}

{p 5 14 2}
Manual:  {manlink R margins}, {manlink R marginsplot}, 
{manlink R fracpoly}, {manlink R mfp}{p_end}

{p 7 14 2}
Help:  {manhelp margins R}, {manhelp marginsplot R},
{manhelp fracpoly R}, {manhelp mfp R}{p_end}
