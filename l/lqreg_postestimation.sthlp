{smcl}
{* *! version 1.0.0 23mar2011 N.Orsini, M.Bottai}{...}
{right: ({browse "http://www.stata-journal.com/article.html?article=st0231":SJ11-3: st0231})}
{hline}

{title:Title}

{p2colset 5 30 35 2}{...}
   Postestimation tools for lqreg
{p2colreset}{...}


{title:Introduction}

{pstd}
The following postestimation commands are of special interest after the most
recently fit logistic quantile regression model using {helpb lqreg}:

{synoptset 11}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
{synopt :{helpb lqreg postestimation##lqregplot:lqregplot}}plot the smoothed regression coefficients versus a dense set of quantiles{p_end}
{synopt :{helpb lqreg postestimation##lqregpred:lqregpred}}generate and optionally plot untransformed predicted quantiles{p_end}
{synoptline}
{p2colreset}{...}


{marker lqregplot}
{title:Syntax for lqregplot} 

{p 8 17 2}
{cmd:lqreqplot}
[{varname}]
[{cmd:,} {it:lqregplot_options}]
{p_end}

{synoptset 25}{...}
{marker lqregplot_options}{...}
{synopthdr :lqregplot_options}
{synoptline}
{synopt:{opt q:uantiles(numlist)}}estimate # quantiles; default is {cmd:quantiles(0.5)}{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt r:eps(#)}}perform # bootstrap replications{p_end}
{synopt:{opt as:e}}specify the asymptotic standard errors{p_end}
{synopt :{opt seed(#)}}set the random-number seed{p_end}
{synopt:{opt nos:mooth}}not to smooth the plot{p_end}
{synopt:{opt lo:ptions(string)}}specify {helpb lowess} options{p_end}
{synopt:{opt gen:erate(varname1 ...)}}save variables required to reproduce the plot{p_end}
{synoptline}


{title:Description for lqregplot}

{pstd} Plot the regression coefficient with confidence bands against a
dense set of quantiles.  The default choice for estimation of confidence
intervals depends on the previously fit {cmd:lqreg} and estimates are
smoothed.{p_end}


{title:Options for lqregplot}

{phang} {cmd:quantiles(}{it:numlist}{cmd:)} specifies the quantiles
to be estimated and should contain numbers between 0 and 1, exclusive.
Numbers greater than 1 are interpreted as percentages.  The default,
{cmd:quantiles(0.5)}, corresponds to the median.

{phang} {opt level(#)} specifies the confidence level, as
a percentage, for confidence intervals.  The default is {cmd:level(95)}
or as set by {cmd:set level}.

{phang} {opt reps(#)} specifies the number of bootstrap
replications to be used to obtain an estimate of the
variance-covariance matrix of the estimators.

{phang} {opt ase} specifies the asymptotic standard errors as
implemented in {helpb qreg}.

{phang}{opt seed(#)} sets the random-number seed.

{phang}{opt nosmooth} specifies not to smooth the plot of the regression coefficients. Smoothing is the default.

{phang}{opt loptions(string)} specifies {helpb lowess} options
(for instance, {cmd:bwidth()} or {cmd:mean}) when smoothing the regression
coefficients versus the set of specified quantiles.

{phang} {cmd:generate(}{it:varname1} {it:varname2}
{it:varname3} {it:varname4}{cmd:)} saves the variables required to
reproduce the plot:  quantile, point estimate, lower bound, and upper bound of
the regression coefficient, to be saved in {it:varname1},
{it:varname2}, {it:varname3}, and {it:varname4}, respectively.
This option is useful if one wants to customize the plot using 
{helpb graph twoway}.


{marker lqregpred}{...}
{title:Syntax for lqregpred}

{p 8 17 2}
{cmd:lqregpred}
{it:stubname}
{ifin}
[{cmd:,} {it:lqregpred_options}]
{p_end}

{p2colreset}{...}
{synoptset 25}{...}
{marker lqregpred_options}{...}
{synopthdr :lqregpred_options}
{synoptline}
{synopt:{opt for(varlist)}}specify (partial) prediction for a quantitative covariate modeled using one or more transformations{p_end}
{synopt:{cmd:at(}{it:var} {cmd:=} {it:#} [...]{cmd:)}}specify the values of the covariates not specified in {opt for()}{p_end}
{synopt:{opt plotvs(varname)}}plot the untransformed predicted quantiles
versus a quantitative covariate {p_end}
{synoptline}
{p2colreset}{...}


{title:Description for lqregpred}

{pstd}
Create new variables containing the untransformed predicted quantiles.
For instance, the new variables are named {it:stubname}{cmd:q5},
{it:stubname}{cmd:q50}, and {it:stubname}{cmd:q95} if {helpb lqreg} fit the quantiles
5, 50, and 95.{p_end}


{title:Options for lqregpred}

{phang} {opt for(varlist)} specifies the covariate, modeled
using one or more transformations {opt for()}, for which to compute the
(partial) predicted values, evaluating the remaining covariates at the
value of 0 unless specified differently with the {opt at()} option.

{phang} {cmd:at(}{it:var} {cmd:=} {it:#} [{it:var} {cmd:=} {it:#}
[...]]{cmd:)} specifies the values of the covariates not specified in the
{opt for()} option. {cmd:at()} works only if the {cmd:for()} option is also specified.

{phang} {opt plotvs(varname)} creates plots of the untransformed predicted quantiles
versus a quantitative covariate.


{title:Examples}

{pstd}Setup{p_end}
{phang}{cmd:. sysuse auto}{p_end}
{phang}{cmd:. lqreg mpg weight}{p_end}

{pstd}Predicted quantiles{p_end}
{phang}{cmd:. lqregpred predq, plotvs(weight)}{p_end}

{pstd}Plot smoothed regression coefficients versus a set of quantiles{p_end}
{phang}{cmd:. lqregplot weight, quantiles(.1(.1).9)}{p_end}


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

{p 4 14 2}Article:  {it:Stata Journal}, volume 11, number 3: {browse "http://www.stata-journal.com/article.html?article=st0231":st0231}

{p 7 14 2}Help:  {helpb lqreg} (if installed){p_end}
