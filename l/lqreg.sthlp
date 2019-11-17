{smcl}
{* *! N.Orsini, M. Bottai v1.0.0 23mar2011}{...}
{cmd:help lqreg}{right: ({browse "http://www.stata-journal.com/article.html?article=st0231":SJ11-3: st0231})}
{hline}

{title:Title}

{p2colset 5 14 16 2}{...}
{p2col :{hi:lqreg} {hline 2}}Logistic quantile regression for bounded outcomes{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 14 2}{cmd:lqreg} {depvar} [{indepvars}] {ifin} [{cmd:,} {it:options}]

{synoptset 22}{...}
{synopthdr :options}
{synoptline}
{synopt :{cmdab:q:uantiles(}{it:{help numlist}}{cmd:)}}specify quantiles to be estimated; default is {cmd:quantiles(0.5)}{p_end}
{synopt :{opt r:eps(#)}}perform {it:#} bootstrap replications{p_end}
{synopt :{opt seed(#)}}set random-number seed to {it:#}{p_end}
{synopt :{opt as:e}}specify asymptotic standard errors{p_end}
{synopt :{opth cl:uster(varlist)}}specify variables identifying resampling clusters{p_end}
{synopt :{opt ymin(#)}}specify minimum value of {it:depvar}{p_end}
{synopt :{opt ymax(#)}}specify maximum value of {it:depvar}{p_end}
{synopt :{opth gen:erate(varname)}}save the logistic transformation of {it:depvar}{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt nodo:ts}}suppress display of replication dots{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}After {cmd:lqreg} estimation, you can use 
{manhelp qreg_postestimation R:qreg postestimation}.  For additional features
available after estimation, see
{helpb lqreg_postestimation:lqreg postestimation}.


{title:Description}

{pstd} {cmd:lqreg} estimates logistic quantile regression for bounded outcomes.
It produces the same coefficients as {cmd:sqreg} or {cmd:qreg} for each
quantile of a logistic transformation of {depvar}.

{pstd} {cmd:lqreg} estimates the variance-covariance matrix of the coefficients
by using either bootstrap (default) or closed formulas (see 
{manhelp qreg R:qreg}).


{title:Options}

{phang}{cmd:quantiles(}{it:{help numlist}}{cmd:)} specifies the quantiles
to be estimated and should contain numbers between 0 and 1, exclusive.
Numbers greater than 1 are interpreted as percentages.  The default,
{cmd:quantiles(0.5)}, corresponds to the median.

{phang}{opt reps(#)} specifies the number of bootstrap
replications to be used to obtain an estimate of the
variance-covariance matrix of the estimators (standard errors).
For example, the default, {cmd:reps(100)}, would perform 100 bootstrap
replications.

{phang}
{opt seed(#)} sets the random-number seed.  Because bootstrapping is a
random process, this option is important to reproduce the results (see
{helpb set seed:set seed}).

{phang}{opt ase} specifies the asymptotic standard errors as
implemented in {helpb qreg}.

{phang} {opth cluster(varlist)} specifies the variables identifying
resampling clusters.  If {opt cluster()} is specified, the sample drawn
during each replication is a bootstrap sample of clusters. {cmd:cluster()}
works only if {opt reps()} is also specified.

{phang}{opt ymin(#)} sets the lower bound of {depvar} to be used in
the logistic transformation. The default is the minimum value of {it:depvar}
minus half of the minimal increment of {it:depvar}.

{phang}{opt ymax(#)} sets the upper bound of {it:depvar} to be used in
the logistic transformation. The default is the maximum value of
{it:depvar} plus half of the minimal increment of {it:depvar}.

{phang}{opt generate(varname)} creates a new variable containing
the logistic transformation of {it:depvar}.

{phang}{opt level(#)}; see
{helpb estimation options##level():[R] estimation options}.

{phang}{opt nodots} suppresses display of the replication dots when 
using bootstrap.


{title:Example}

{phang}{cmd:. sysuse auto}{p_end}

{phang}{cmd:. lqreg mpg weight length foreign, quantiles(.25 .5 .75)}{p_end}

 
{title:Saved results}

{pstd}{cmd:lqreg} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(ymin)}}lower bound for {it:depvar}{p_end}
{synopt:{cmd:e(ymax)}}upper bound for {it:depvar}{p_end}
{synopt:{cmd:e(n_q)}}number of quantiles requested{p_end}
{synopt:{cmd:e(q}{it:#}{cmd:)}}the quantiles requested{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(convcode)}}{cmd:0} if converged; otherwise, return code for why nonconvergence{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:lqreg}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(eqnames)}}names of equations{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Matrices} {p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample


{title:Authors}

{pstd}Nicola Orsini{p_end}
{pstd}Unit of Nutritional Epidemiology{p_end}
{pstd}and {p_end}
{pstd}Unit of Biostatistics{p_end}
{pstd}Institute of Environmental Medicine, Karolinska Institutet{p_end}
{pstd}Stockholm, Sweden{p_end}
{pstd}nicola.orsini@ki.se{p_end}

{pstd}Matteo Bottai{p_end}
{pstd}Division of Biostatistics{p_end}
{pstd}University of South Carolina{p_end}
{pstd}Columbia, SC{p_end}
{pstd}and {p_end}
{pstd}Unit of Biostatistics{p_end}
{pstd}Institute of Environmental Medicine, Karolinska Institutet{p_end}
{pstd}Stockholm, Sweden{p_end}
{pstd}matteo.bottai@ki.se{p_end}


{title:Also see}

{psee}Article:  {it:Stata Journal}, volume 11, number 3: {browse "http://www.stata-journal.com/article.html?article=st0231":st0231}

{p 5 14 2}Manual:  {manlink R qreg} 

{p 7 14 2}Help:  {manhelp qreg R},
{manhelp qreg_postestimation R:qreg postestimation},
{helpb lqreg_postestimation:lqreg postestimation} (if installed),
{manhelp bootstrap R}
{p_end}
