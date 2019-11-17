{smcl}
{* 2014-08-06 scott long & jeremy freese}{...}
{title:Title}

{p2colset 5 13 23 2}{...}
{p2col:{cmd:spex} {hline 2}}Run examples and load data to demonstrate SPost13 commands{p_end}
{p2colreset}{...}


{title:General syntax}

{p 4 12 2}{cmd:spex} [{it:modelname}] [{it:filename}] [{it:commandname}]
[ {cmd:,} {cmdab:w:eb} {cmdab:l:ocal} {cmdab:copy} ]


{title:Description}

{p 4 4 2}
{cmd:spex} allows users to easily use load data, fit models, and try commands from
Long and Freese's {it: Regression Models for Categorical Dependent Variables}
{it: Using Stata}.  Typing {cmd:spex} {it:filename} loads the specified
example dataset. Typing {cmd:spex} {it:modelname} fits that
model using data and an example specification from the book. Typing
{cmd:spex} {it:commandname} runs a postestimation command after loading
data and running a regression model. {cmd: spex} often runs multiple commands.
Each command {cmd: spex} runs is listed in Stata's Review window.


{title:Available Examples, Files, and Commands}

{dlgtab:Regression models fit by spex}

{p2colset 10 23 23 12}{...}
{p2col :{ul:{bf:Binary regression models}}}{p_end}

{p2col :{bf:logit}}Logistic regression model{p_end}
{p2col :{bf:probit}}Probit regression model{p_end}
{p2col :{bf:cloglog}}Complementary log-log regression model{p_end}
{p2col :{bf:svy}}Logistic regression model with complex survey sampling{p_end}
{p2col :}{p_end}
{p2col :{ul:{bf:Ordinal regression models}}}{p_end}

{p2col :{bf:ologit}}Ordered logistic regression model{p_end}
{p2col :{bf:oprobit}}Ordered probit regression model{p_end}
{p2col :{bf:rologit}}Rank-ordered logistic regression model{p_end}
{p2col :}{p_end}

{p2col :{ul:{bf:Nominal regression models}}}{p_end}

{p2col :{bf:mlogit}}Multinomial logistic regression model{p_end}
{p2col :{bf:mprobit}}Multinomial probit regression model{p_end}
{p2col :{bf:slogit}}Stereotype logistic regression model{p_end}
{p2col :{bf:asclogit}}Alternative-specific conditional logit regression model{p_end}
{p2col :{bf:asmprobit}}Alternative-specific multinomial probit regression{p_end}
{p2col :}{p_end}

{p2col :{ul:{bf:Count regression models}}}{p_end}

{p2col :{bf:poisson}}Poisson regression model{p_end}
{p2col :{bf:nbreg}}Negative binomial regression model{p_end}
{p2col :{bf:ztnb}}Truncated negative binomial regression model{p_end}
{p2col :{bf:tnbreg}}Truncated negative binomial regression model{p_end}
{p2col :{bf:ztp}}Truncated Poisson regression model{p_end}
{p2col :{bf:tpoisson}}Truncated Poisson regression model{p_end}
{p2col :{bf:zip}}Zero-inflated Poisson regression model{p_end}
{p2col :{bf:zinb}}Zero-inflated negative binomial regression model{p_end}
{p2col :}{p_end}

{p2col :{ul:{bf:Linear regression models}}}{p_end}

{p2col :{bf:regress}}Linear regression model{p_end}
{p2col :{bf:tobit}}Tobit regression model{p_end}
{p2col :{bf:intreg}}Interval regression model{p_end}
{p2line}


{dlgtab:Data compatible with spex}
{p2colset 9 26 26 0}
{p 6 6 2}
Many datasets are accessible using spex. Visit
{browse "http://www.indiana.edu/~jslsoc/stata/spex_data/"}
for a list of available datasets.


{dlgtab:Commands compatible with spex}

{p2colset 10 23 23 12}{...}
{p2col :{bf: fitstat}}Compute scalar measures of fit. See {help fitstat}.{p_end}
{p2col :{bf: listcoef}}Lists various regression coefficients. See {help listcoef}.{p_end}
{p2col :{bf: margins}}Computes marginal means, predictive margins, and marginal effects. See {help margins}.{p_end}
{p2col :{bf: mchange}}Computes marginal effects. See {help mchange}.{p_end}
{p2col :{bf: mtable}}Constructs tables of predictions. See {help mtable}.{p_end}
{p2col :{bf: mgen}}Generates variables for plotting predictions. See {help mgen}.{p_end}
{p2col :{bf: mlincom}}Computes linear combinations of margins estimates. See {help mlincom}.{p_end}
{p2line}


{title:Options}

{p 4 8 2}{cmd:local} data are to be loaded from the working directory
or somewhere else along the user's adopath (somewhere accessible
via {cmd:sysuse}). This is the default.

{p 4 8 2}{cmd:web} loads data from their location
on the spost website ({browse "http://www.indiana.edu/~jslsoc/stata/spex_data/"}).

{p 4 8 2}{cmd:copy} copies dataset to the working directory..


{title:Notes}

{p 4 4 2}When specifying an estimation command with spex, you can add other
options (e.g., "nolog") and these will be passed along as additional options
to the estimation command.


{title:Examples}

{phang}{cmd:. spex logit}{p_end}

{phang}{cmd:. spex mtable}{p_end}

{phang}{cmd:. spex couart4}{p_end}

INCLUDE help spost13_footer
