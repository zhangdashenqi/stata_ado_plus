{smcl}
{* *! version 1.1  27feb2011}{...}
{cmd:help hacreg}{right: ({browse "http://www.stata-journal.com/article.html?article=st0272":SJ12-3: st0272})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:hacreg} {hline 2}}Regression with heteroskedasticity- and
autocorrelation-consistent standard errors{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2} {cmd:hacreg} {depvar} {indepvars} {ifin} [{cmd:,} {opt noc:onstant}
{opt l:evel(#)} {it:{help lrcov:lrcov_options}}]


{title:Description}

{pstd}The {cmd:hacreg} command implements heteroskedasticity- and
autocorrelation-consistent standard errors.  {cmd:hacreg} has
several improvements over the official Stata {cmd:newey} command.  For
example, the {cmd:hacreg} command can automatically determine the
optimal lag based on information criteria.  Moreover, {cmd:hacreg}
allows more flexible treatment with long-run covariance, such as
prewhitening the data and more kernel functions.


{title:Options}

{phang}{cmd:noconstant} suppresses the constant in the regression
equation.

{phang}{cmd:level(}{it:#}{cmd:)} sets the confidence level; default
is {cmd:level(95)}.

{phang}{it:lrcov_options} specifies the options to compute LRCOV, which
include {cmd:vic(}{it:string}{cmd:)}, {cmd:vlag(}{it:#}{cmd:)},
{cmd:kernel(}{it:string}{cmd:)}, {cmd:bwidth(}{it:#}{cmd:)},
{cmd:bmeth(}{it:string}{cmd:)}, {cmd:blag(}{it:#}{cmd:)}, and
{cmd:btrunc}.  All of these options are specified in the same way as for
the {helpb lrcov} command.


{title:Examples}

{phang}{cmd:.} {bf:{stata use stockwatson}}{p_end}
{phang}{cmd:.} {bf:{stata generate lnpoj=ln(poj)}}{p_end}
{phang}{cmd:.} {bf:{stata generate dlnpoj=D.lnpoj*100}}{p_end}
{phang}{cmd:.} {bf:{stata hacreg dlnpoj L(0/18).fdd if tin(1950m1,2000m12), kernel(bartlett) bwidth(8)}}{p_end}

{phang}{cmd:.} {bf:{stata qui hacreg dlnpoj DL(0/17).fdd L18.fdd if tin(1950m1,2000m12), kernel(bartlett) bwidth(8)}}{p_end}
{phang}{cmd:.} {bf:{stata est store est2}}{p_end}
{phang}{cmd:.} {bf:{stata qui hacreg dlnpoj DL(0/17).fdd L18.fdd if tin(1950m1,2000m12), kernel(bartlett) bwidth(15)}}{p_end}
{phang}{cmd:.} {bf:{stata est store est3}}{p_end}
{phang}{cmd:.} {bf:{stata generate month=month(dofm(mdate))}}{p_end}
{phang}{cmd:.} {bf:{stata qui hacreg dlnpoj DL(0/17).fdd L18.fdd i.month if tin(1950m1,2000m12) , kernel(bartlett) bwidth(8)}}{p_end}
{phang}{cmd:.} {bf:{stata est store est4}}{p_end}
{phang}{cmd:.} {bf:{stata estimates table est2 est3 est4, style(oneline)}}{p_end}


{title:Saved results}

{pstd}{cmd:hacreg} saves the following in {cmdab:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(r2)}}R-squared{p_end}
{synopt:{cmd:e(r2_a)}}adjusted R-squared{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(rss)}}residual sum of squares{p_end}
{synopt:{cmd:e(rmse)}}root of mean squared error{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(ll_0)}}log likelihood, constant-only model{p_end}
{synopt:{cmd:e(mss)}}residual sum of squares{p_end}
{synopt:{cmd:e(F)}}model F statistic{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:hacreg}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(predict)}}program to implement {cmd:predict}{p_end}
{synopt:{cmd:e(vcetype)}}type of covariance{p_end}
{synopt:{cmd:e(title)}}title of regression{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector {p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Functions}{p_end}
{synopt:{hi:e(sample)}}marks estimation sample{p_end}


{title:Author}

{pstd}Qunyong Wang{p_end}
{pstd}Institute of Statistics and Econometrics{p_end}
{pstd}Nankai University{p_end}
{pstd}brynewqy@nankai.edu.cn{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 12, number 3: {browse "http://www.stata-journal.com/article.html?article=st0272":st0272}

{p 7 14 2}Help:  {helpb lrcov}, {helpb cointreg}, {helpb ivreg2} (if
installed), {helpb newey}{p_end}
