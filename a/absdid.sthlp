{smcl}
{* *! version 2.0.1 Kenneth Houngbedji 04feb2016}{...}
{cmd:help absdid}{right: ({browse "http://www.stata-journal.com/article.html?article=st0442":SJ16-2: st0442})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{bf: absdid} {hline 2}}Semiparametric difference-in-differences
estimator of {help absdid##A2005:Abadie (2005)}{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{opt absdid} {depvar} {ifin}{cmd:,} 
    {opth tv:ar(varname)}
    {opth xv:ar(varlist)}
	[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opth tv:ar(varname)}}binary treatment variable{p_end}
{p2coldent :* {opth xv:ar(varlist)}}specify the variables for the selection into
treatment equation{p_end}
{synopt :{opth yxv:ar(varlist)}}list of variables that can modify the treatment 
effect{p_end}
{synopt :{opt ord:er(#)}}set order of the polynomial function used to estimate the propensity score{p_end}
{synopt :{opt sle}}set a logistic function to estimate the propensity score{p_end}
{synopt :{opt csi:nf(#)}}drop the observations in which the propensity score 
is less than {it:#}{p_end}
{synopt :{opt csu:p(#)}}drop the observations in which the propensity score is 
greater than {it:#}{p_end}
{synoptline}
{pstd}* {cmd:tvar()} and {cmd:xvar()} are required.{p_end}
{p 4 6 2}
{opt xvar(varlist)} and {opt yxvar(varlist)} may contain factor variables and
interactions terms; see {help fvvarlist}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:absdid} implements the semiparametric difference-in-differences estimator
of {help absdid##A2005:Abadie (2005)}.

{pstd}
The estimator compares {depvar} (the change of the outcome of interest between
baseline and follow-up) across the treated ({opt tvar(varname)} == {cmd:1})
and the untreated ({opt tvar(varname)} == {cmd:0}) groups.  To address
nonrandom selection into treatment groups, the estimator adjusts for
observable differences between treatment groups at the baseline based on the
list of control variables, {opt xvar(varlist)}.


{marker options}{...}
{title:Options}

{phang}
{opth tvar(varname)} is the binary treatment variable.  It takes the value
{cmd:1} when the observation is treated and takes the value {cmd:0} otherwise.
{cmd:tvar()} is required.

{phang}
{opth xvar(varlist)} are the control variables.  They can be either continuous
or binary and are used to estimate the propensity score.  {cmd:xvar()} is
required.

{phang}
{opth yxvar(varlist)} is a list of variables that can modify the treatment
effect.  By default, the treatment effect is assumed to be constant.

{phang}
{opt order(#)} represents the order of the polynomial function used to
estimate the propensity score.  It takes integer values and the default is
{cmd:order(1)}.

{phang}
{opt sle} forces the use of a logistic specification to estimate the
propensity score (see {help absdid##H2003:Hirano, Imbens, and Ridder [2003]}).
This ensures, for instance, that the estimated propensity score is always
greater than 0 and less than 1.  By default, the propensity score is estimated
with a linear regression.

{phang}
{opt csinf(#)} drops the observations of which the propensity score is less
than {it:#}.  The default is {cmd:csinf(0)}.

{phang}
{opt csup(#)} drops the observations of which the propensity score is greater
than {it:#}.  The default is {cmd:csup(1)}.


{marker examples}{...}
{title:Examples: Union-wage premium}

{pstd}Setup{p_end}
{phang2}{cmd:. use absdid}{p_end}

{pstd}Estimate the union-wage premium{p_end}
{phang2}{cmd:. absdid dlwage, tvar(union97) xvar(age black hispanic married grade)}{p_end}

{pstd}Union-wage premium with the {opt sle} option{p_end}
{phang2}{cmd:. absdid dlwage, tvar(union97) xvar(age black hispanic married grade) sle}{p_end}

{pstd}Union-wage premium when the probability to be treated varies between {cmd:0.01} and {cmd:0.99}{p_end}
{phang2}{cmd:. absdid dlwage, tvar(union97) xvar(age black hispanic married grade) csinf(0.01) csup(0.99)}{p_end}

{pstd}Union-wage premium using a polynomial function of order 4 to estimate the propensity score{p_end}
{phang2}{cmd:. absdid dlwage, tvar(union97) xvar(age black hispanic married grade) order(4)}{p_end}

{pstd}Variation of union-wage premium across age and education{p_end}
{phang2}{cmd:. absdid dlwage, tvar(union97) xvar(age black hispanic married grade) yxvar(age hschool college)}{p_end}

{pstd}Interaction terms{p_end}
{phang2}{cmd:. absdid dlwage, tvar(union97) xvar(c.age##c.age black hispanic married grade) yxvar(c.age##c.age hschool college)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:absdid} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:absdid}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{marker A2005}{...}
{phang}
Abadie, A. 2005. Semiparametric difference-in-differences estimators.
{it:Review of Economic Studies} 72: 1-19.

{marker H2003}{...}
{phang}
Hirano, K., G. W. Imbens, and G. Ridder. 2003. Efficient estimation of average
treatment effects using the estimated propensity score.  {it:Econometrica} 71:
1161-1189.


{marker author}{...}
{title:Author}

{marker contact}{...}
{pstd}Kenneth Houngbedji{break}
Paris School of Economics{break}
Paris, France{break}
{browse "mailto:kenneth.houngbedji@psemail.eu":kenneth.houngbedji@psemail.eu}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 16, number 2: {browse "http://www.stata-journal.com/article.html?article=st0442":st0442}{p_end}
