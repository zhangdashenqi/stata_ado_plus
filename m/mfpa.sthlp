{smcl}
{* *! version 1.0.3  11feb2016}{...}

{title:Title}

{p2colset 5 13 15 2}{...}
{p2col :{hi:mfpa} {hline 2}}Multivariable fractional polynomial models with extensions{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmd:mfpa}
	[{cmd:,}
		{it:options}]
        {cmd::} {it:{help mfp##reg_cmd:regression_cmd}}
	[{it:{help mfp##reg_cmd:yvar1}} [{it:{help mfp##reg_cmd:yvar2}}]]
	{it:{help mfp##reg_cmd:xvarlist}}
	{ifin}
	{weight}
	[{cmd:,} {it:regression_cmd_options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt acd(varlist)}}optimize model fit for each {it:xvar} in {it:varlist}
and its ACD transformation{p_end}
{synopt :{opt lin:adj(varlist)}}adjust linearly for each {it:xvar} in {it:varlist}{p_end}
{synopt :{it:mfp_options}}options appropriate to {help mfp}{p_end}
{synoptline}

{synopthdr :regression_cmd_options}
{synoptline}
{syntab :Adv. model}
{synopt :{it:regression_cmd_options}}options appropriate to the regression command in use{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
All weight types supported by {it:regression_cmd} are allowed; see
{help weight}.{p_end}
{p 4 6 2}
See {helpb mfp postestimation:[R] mfp postestimation} for features available
after estimation.{p_end}
{p 4 6 2}
{opt fracgen} may be used to create new variables containing fractional
polynomial powers.  See {helpb fracpoly:[R] fracpoly}.{p_end}

{p 4 6 2}
Note that the {cmd:acd} program must be installed before using {cmd:mfpa}.
This can be done by using the command
{cmd:net install st0339, from (http://www.stata-journal.com/software/sj14-2)}

{pstd}
{marker reg_cmd}where

{pin}
{it:regression_cmd} may be
{helpb areg},
{helpb clogit},
{helpb glm},
{helpb intreg}, 
{helpb logistic},
{helpb logit},
{helpb mlogit},
{helpb nbreg},
{helpb ologit},
{helpb oprobit},
{helpb poisson},
{helpb probit},
{helpb qreg},
{helpb regress},
{helpb rreg},
{helpb stcox},
{helpb stcrreg},
{helpb streg},
{helpb tobit},
{helpb xtcloglog},
{helpb xtgee},
{helpb xtnbreg},
{helpb xtpoisson},
{helpb xtprobit},
or
{helpb xttobit}.

{pin}
{it:yvar1} is not allowed for {opt streg}, {opt stcrreg}, and {opt stcox}.
For these commands, you must first {helpb stset} your data.

{pin}
{it:yvar1} and {it:yvar2} must both be specified when {it:regression_cmd} is
{opt intreg}.

{pin}
{it:xvarlist} has elements of type {varlist} and/or {opt (varlist)};
for example,

{pin2}
{cmd:x1 x2 (x3 x4 x5)}

{pin}
Elements enclosed in parentheses are tested jointly for inclusion in the
model and are not eligible for fractional polynomial transformation.


{marker description}{...}
{title:Description}

{pstd}
{opt mfpa} selects the multivariable fractional polynomial (MFP) model that best
predicts the outcome variable from the right-hand-side variables in
{it:{help varlist:xvarlist}}.

{pstd}
{cmd:mfpa} provides some extensions to the factory-standard {cmd:mfp} command,
namely

{phang}1.  {cmd:mfpa} supports factor variables;{p_end}
{phang}2.  {cmd:mfpa} has two new options: {opt linadj(varlist)} to adjust
    linearly for variables in {it:varlist}, and {opt acd(varlist)} to
    optimize the fit for each {it:xvar} in {it:varlist} and its ACD
    transformation.{p_end}


{marker related}{...}
{title:Related commands}

{pstd}
Note also the following significant changes:

{pstd}
1. For use with {cmd:mfpa}, the {cmd:mfp} post-estimation commands
{helpb fracplot} and {helpb fracpred} are replaced with {cmd:xfracplot}
and {cmd:xfracpred}, respectively. The syntax is unchanged, except that
{cmd:xfracplot} has an additional option {opt nopts} which suppresses
plotting of partial residuals.

{pstd}
2. The factory command {helpb fracpoly} (as of Stata 13, no longer part
of official Stata) is replaced with {cmd:xfracpoly},
the only change being that factor variables are allowed among
{cmd:xfracpoly}'s {it:xvarlist}. For example, the commands

{pin}{cmd:. xfracpoly: stcox x5 i.x4}{p_end}
{pin}{cmd:. xfracplot i.x4}{p_end}
{pin}{cmd:. xfracpred fx4, for(i.x4)}{p_end}

{pstd}
where {cmd:x5} is (treated as) a continuous variable and {cmd:x4} is a factor
variable, are valid, but the equivalents with {cmd:fracpoly}, {cmd:fracplot}
and {cmd:fracpred} would fail.

{pstd}
The factory command {helpb fracgen} is unchanged.
 

{title:Options}

{phang}
{opt acd(varlist)} creates the ACD transformation of each member of
{it:varlist}. It also invokes the FSPA to determine the best-fitting
FP1(p1, p2) model, as described in Remarks. For a given continuous predictor
{it:xvar}, depending on the values of {opt select(#)} and {opt alpha(#)},
{cmd:mfpa} simplifies the FP1(p1, p2) model to select one of the six
sub-models M1-M6 described in {it:Remarks}. The variable representing
the ACD transformation of {it:xvar} is named {cmd:A}{it:xvar} and is left
behind in the workspace, together with FP transformation(s) of
{cmd:A}{it:xvar}, as appropriate.

{phang}
{opt linadj(varlist)} adjusts linearly for members of {it:varlist}, that 
is the members are included in every model fit. This avoids the need for the
somewhat more complicated use of the {opt df()} and {opt select()} options
to achieve the same result.


{title:Remarks}

{pstd}
The ACD transformation (Royston 2014a) converts each predictor, x, smoothly
to an approximation, acd(x), of its empirical cumulative distribution
function. This is done by smoothing a probit transformation of the scaled
ranks of x on x. acd(x) could be used instead of x as a covariate. This has the
advantage of providing sigmoid curves in x, something that regular FP
functions cannot achieve. Details of the precise definition and some possible
uses of the ACD transformation in a univariate context are given by
Royston (2014a).

{pstd}
Royston (2014b) describes how one could go further and replace FP2 functions
with a pair of FP1 functions, one in x and the other in ACD(x). This
alternative class of four-parameter functions seems to provide about the same
flexibility as the standard FP2 family. The ACD component offers the additional
possibility of sigmoid functions, as just described.

{pstd}
Royston (2014b) discusses how the extended class of functions known as
FP1(p1, p2), namely

{pin}FP1(p1, p2) = beta1 * x^p1 + beta2 * ACD(x)^p2

{pstd}
can be fitted optimally by seeking the best combination of all 64
pairs of powers (p1, p2). The optimisation is invoked by use of the
{opt acd()} option.

{pstd}
Royston (2014b) also described simplification of the chosen function through
model reduction by applying significance testing to six sub-families of
functions, giving models M1 (most complex) through M6 (null, x omitted):

{pin}M1. FP1(p1, p2) (no simplification){p_end}
{pin}M2. FP1(p1, .)  (regular FP1 function of x){p_end}
{pin}M3. FP1(., p2)  (regular FP1 function of ACD(x)){p_end}
{pin}M4. FP1(1, .)   (linear function of x){p_end}
{pin}M5. FP1(., 1)   (linear function of ACD(x)){p_end}
{pin}M6. Null        (x omitted entirely){p_end}

{pstd}
Selection among these six sub-functions is performed by a closed
test procedure known as the FSPA. It maintains the familywise type 1 error
probability for selecting x at the value determined by the {opt select(#)}
option. To obtain a 'final' model, a structured sequence of up to five tests
is carried out, the first at the {opt select(#)} significance level and the
remainder at the significance level provided by the {opt alpha(#)} option,
the default {it:#} being 0.05. The sequence of tests is as follows:

{pin}Test 1. Compare the deviances of models 6 and 1 on 4 d.f. If non-significant
then stop and omit x, otherwise continue to step 2.

{pin}Test 2. Compare the deviances of models 4 and 1 on 3 d.f. If non-significant
then accept model 4 and stop. Otherwise, continue to step 3.

{pin}Test 3. Compare the deviance of models 2 and 1 on 2 d.f. If non-significant
then accept model 2 and stop. Otherwise continue to step 4.

{pin}Test 4. Compare the deviance of models 3 and 1 on 2 d.f. If significant
then model 1 cannot be simplified; accept model 1 and stop.
Otherwise continue to step 5.

{pin}Test 5. Compare the deviances of models 5 and 3 on 1 d.f. If significant
then model 3 cannot be simplified; accept model 3. Otherwise, accept model 5.
End of procedure.

{pstd}
Note that the values of p1 and p2 in models 2 and 3 are re-estimated to provide
the best fit, and may differ from those found for the FP1(p1, p2) model.

{pstd}
The result is selection of one of the six models. The FSPA procedure is
automatically invoked by the {opt acd(varlist)} option for each member
of {it:varlist} in the iterative fitting algorithm.
 

{title:Examples}

{phang}{stata ". webuse brcancer, clear"}{p_end}
{phang}{stata ". stset rectime, failure(censrec) scale(365.24)"}{p_end}
{phang}{stata ". mfpa, acd(x5): stcox x5"}{p_end}
{phang}{stata ". mfpa, select(0.05): stcox x1 x2 x3 x4a x4b x5 x6 x7 hormon"}{p_end}
{phang}{stata ". xfracplot x5"}{p_end}
{phang}{stata ". mfpa, select(0.05) acd(x5 x6 x7): stcox x1 x2 x3 x4a x4b x5 x6 x7 hormon"}{p_end}
{phang}{stata ". xfracplot x5"}{p_end}


{title:Author}

{phang}Patrick Royston{p_end}
{phang}MRC Clinical Trials Unit at UCL{p_end}
{phang}London, UK{p_end}
{phang}j.royston@ucl.ac.uk{p_end}


{title:References}

{phang}Royston, P. 2014a. A smooth covariate rank transformation for use
in regression models with a sigmoid dose–response function.
{it:Stata Journal} {cmd:14}(2): 329-341.

{phang}Royston, P. 2014b. mfpa: extension of mfp using the {it:acd} covariate
transformation for enhanced parametric multivariable modelling.
{it:Stata  Journal}. Submitted for publication.


{title:Also see}

{psee}
Manual:  {hi:[R] fracpoly}, {hi:[R] mfp}{p_end}

{psee}
Online:  {helpb mfp}, {helpb acd}{p_end}
