{smcl}
{* *! version 1.0.0 3mar2014}{...}
{cmd:help switchoprobit}{right: ({browse "http://www.stata-journal.com/article.html?article=st0402":SJ15-3: st0402})}
{hline}

{title:Title}

{p2colset 5 22 24 2}{...}
{p2col :{hi:switchoprobit} {hline 2}}Estimate effect of binary treatment on discrete, ordered outcome{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 21 2}
{cmdab:switchoprobit}
{it:y_ordered x_ordered}
{ifin}
{weight}{cmd:,} {opt treat(varlist)}
[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opt treat(varlist)}}binary indicator for a treatment{p_end}
{synopt:{opt vce(string)}}specify how to estimate the variance-covariance
matrix corresponding to the parameter estimates{p_end}
{synopt:{opt level(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synoptline}
{pstd}* {cmd:treat()} is required.{p_end}
{p 4 6 2}
{cmd:pweight}s, {cmd:fweight}s, and {cmd:iweight}s are allowed; see {help weight}.


{title:Description}

{pstd}
{cmd:switchoprobit} fits a model in which {cmd:treat()} is a binary indicator
for a treatment ({it:y_treat}) for which selection is believed correlated with
the outcome of interest, {it:y_ordered}.  The model assumes that the
unobservables in treatment and outcome equations have a bivariate normal
distribution and that outcomes for treated and untreated groups are distinct.
(A test for the hypothesis that the treated and untreated groups belong to one
outcome regime is reported as part of standard output.)  Parameters of the
model are estimated by maximum likelihood.


{title:Options}

{phang}
{opt treat(varlist)} specifies the binary indicator for a treatment.
{cmd:treat()} is required.

{phang}
{opt vce(string)} specifies how to estimate the variance-covariance matrix
corresponding to the parameter estimates.  {cmd:cluster} {it:clustvar}
specifies the cluster standard errors using {it:clustvar}.  {cmd:robust}
computes the robust variance-covariance matrix and standard errors.

{phang}
{opt level(#)} sets confidence level.  The default is {cmd:level(95)}.


{title:Examples}

{pstd}
Order self-assessed health ({bf:sah}) on a 1-5 scale (excellent, very
good, good, fair, poor), and let {bf:mcd} be an indicator of participation in
Medicaid{p_end}
{phang2}{cmd:. use nhisdataex}{p_end}
{phang2}{cmd:. switchoprobit sah female married, treat(mcd female married)}{p_end}
{phang2}{cmd:. switchoprobit sah female married [pweight=normwgt], treat(mcd female married) vce(robust)}{p_end}


{title:Author}

{pstd}Christian A. Gregory{p_end}
{pstd}Economic Research Service, USDA{p_end}
{pstd}Washington, DC{p_end}
{pstd}cgregory@ers.usda.gov{p_end}


{marker also_see}{...}
{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 15, number 3: {browse "http://www.stata-journal.com/article.html?article=st0402":st0402}

{p 7 14 2}Help:  {helpb switchoprobit postestimation} (if installed)
{p_end}
