{smcl}
{* *! version 1.0 - 22 June 2016}{...}
{cmd:help pvar}{right: ({browse "http://www.stata-journal.com/article.html?article=st0455":SJ16-3: st0455})}
{hline}

{title:Title}

{phang}
{bf:pvar} {hline 2} Panel vector autoregression models 


{title:Syntax}

{p 8 17 2}
{cmd:pvar} 
{depvarlist}
{ifin} 
[, {it:options}]

{synoptset 28}{...}
{synopthdr}
{synoptline}
{synopt:{opt la:gs(#)}}use first {it:#} lags in the underlying panel VAR; default is {cmd:lags(1)}{p_end}
{synopt:{opth ex:og(varlist)}}use time-varying exogenous variables in {it:varlist}{p_end}
{synopt:{opt fod}}use Helmert transformation to remove panel-specific fixed effects; the default{p_end}
{synopt:{opt fd}}use first difference to remove panel-specific fixed effects{p_end}
{synopt:{opt td}}remove cross-sectional mean from each variable in {it:depvarlist} and in {it:varlist} if specified{p_end}
{synopt:{opth instl:ags(numlist)}}specify lag orders of {it:depvarlist} to be used as instruments{p_end}
{synopt:{opt gmms:tyle}}use "GMM-style" instruments; may be used only with {cmd:instlags()}{p_end}
{synopt:{opt gmmo:pts(options)}}override the default GMM options{p_end}
{synopt:{cmd:vce(}{it:vcetype} [{cmd:,} {opt indep:endent}]{cmd:)}}{it:vcetype} may be {cmd:robust}, {cmd:cluster} {it:clustervar}, {cmd:bootstrap}, {cmd:jackknife}, {cmd:hac} {it:kernel} {it:lags}, or {cmd:unadjusted}; default is
{cmd:vce(unadjusted)}{p_end}
{synopt:{opt overid}}report Hansen's J statistic of overidentifying restrictions{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt nop:rint}}do not display coefficient table{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
You must {cmd:xtset} your data before using {cmd:pvar}; see {manhelp xtset XT}.


{title:Description}

{pstd}
{cmd:pvar} fits homogeneous panel vector autoregression (VAR) models by
fitting a multivariate panel regression of each dependent variable on lags of
itself and on lags of all other dependent variables using generalized method
of moments (GMM).  {cmd:pvar} also fits a variant of panel vector
autoregression models known as pVARX, which also includes exogenous
explanatory variables.  The command is implemented using the interactive
version of Stata's {helpb gmm} command with analytic derivatives.


{title:Options}

{phang}
{opt lags(#)} specifies the maximum lag order {it:#} to be included in the
model.  The default is to use the first lag of each variable in
{it:depvarlist}.

{phang}
{opth exog(varlist)} specifies a list of exogenous variables to be included in
the panel VAR.

{phang}
{cmd:fod} and {cmd:fd} specify how the panel-specific fixed effects will be
removed.  {cmd:fod} specifies that the panel-specific fixed effects be removed
using forward orthogonal deviation or Helmert transformation.  By default, the
first {it:#} lags of transformed {it:depvarlist} in the model are instrumented
by the same lags in levels (that is, untransformed).  {cmd:fod} is the default
option.  {cmd:fd} specifies that the panel-specific fixed effects be removed
using first difference instead of forward orthogonal deviations.  By default,
the first {it:#} lags of transformed (that is, differenced) {it:depvarlist} in
the model are instrumented by the ({it:#}+1)th to (2{it:#})th  lags of
{it:depvarlist} in levels (that is, untransformed).

{phang}
{opt td} subtracts from each variable in the model its cross-sectional mean
before estimation.  This could be used to remove common time fixed effects
from all the variables prior to any other transformation.

{phang}
{opth instlags(numlist)} overrides the default lag orders of {it:depvarlist}
used as instruments in the model (see the {cmd:fod} and {cmd:fd} options above
that describe which lags are used as default).  Instead, {it:numlist}th lags
are used as instruments.

{phang}
{opt gmmstyle} specifies that "GMM-style" instruments as proposed by
Holtz-Eakin, Newey, and Rosen (1988) be used.  Lag length to be used as
instruments must be specified with {cmd:instlags()}.  For each instrument
based on lags of {it:depvarlist}, missing values are substituted with zero.
Observations with no valid instruments are excluded.  This option is available
only with {cmd:instlags()}.

{phang}
{opth gmmopts(options)} overrides the default {cmd:gmm} options run by
{cmd:pvar}.  Each equation in the model may be accessed individually using the
variable names in {it:depvarlist} as equation names.  See {manhelp gmm R} for
the available options.

{phang}
{cmd:vce(}{it:vcetype}[{cmd:,} {opt indep:endent}]{cmd:)} specifies the type
of standard error reported, which includes types that are robust to some types
of misspecification, that allow for intragroup correlation, and that use
bootstrap or jackknife methods; see {manhelp vce_option R}.

{phang}
{opt overid} specifies that Hansen's J statistic of overidentifying
restriction be reported.  This option is available only for overidentified
systems.

{phang}
{opt level(#)} specifies the confidence level, as a percentage, to be used for
reporting confidence intervals.  The default is {cmd:level(95)} or as set by
{helpb set level}.

{phang}
{opt noprint} suppresses printing of the coefficient table.


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse nlswork2}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}
{phang2}{cmd:. generate wage = exp(ln_wage)}{p_end}
    
{pstd}Fit panel VAR model with one lag by Helmert transformation (the default)
{p_end}
{phang2}{cmd:. pvar wage hours}{p_end}

{pstd}Same as above but with standard errors clustered by industry occupation
{p_end}
{phang2}{cmd:. egen indocc = group(ind_code occ_code)}{p_end}
{phang2}{cmd:. pvar wage hours, vce(cluster indocc)}{p_end}

{pstd}Same as first but use the first three lags as instruments{p_end}
{phang2}{cmd:. pvar wage hours, instlags(1/3)}{p_end}

{pstd}Same as above but use GMM-style instruments{p_end}
{phang2}{cmd:. pvar wage hours, instlags(1/3) gmmstyle}{p_end}

{pstd}Same as above but report overidentification test{p_end}
{phang2}{cmd:. pvar wage hours, instlags(1/3) gmmstyle overid}{p_end}

{pstd}Fit default {cmd:pvar} options using {opt gmmopts(options)}{p_end}
{phang2}{cmd:. pvar wage hours, gmmopts(winitial(identity) wmatrix(robust) twostep vce(unadjusted))}


{title:Stored results}

{pstd}
{cmd:pvar} stores the following in {cmd:e()}:

{synoptset 20}{...}
{p2col 5 20 24 2:Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(n)}}number of panels{p_end}
{synopt:{cmd:e(tmin)}}first time period in sample{p_end}
{synopt:{cmd:e(tmax)}}last time period in sample{p_end}
{synopt:{cmd:e(tbar)}}average time periods among panels{p_end}
{synopt:{cmd:e(mlag)}}maximum lag order in panel VAR{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(Q)}}criterion function{p_end}
{synopt:{cmd:e(J)}}Hansen's J chi-squared statistic{p_end}
{synopt:{cmd:e(J_df)}}J-statistic degrees of freedom{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(ic)}}number of iterations used by iterative GMM estimator{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}

{p2col 5 20 24 2:Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:pvar}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}names of dependent variables{p_end}
{synopt:{cmd:e(exog)}}names of exogenous variables, if specified{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(instr)}}instruments{p_end}
{synopt:{cmd:e(eqnames)}}equation names{p_end}
{synopt:{cmd:e(timevar)}}name of time variable{p_end}
{synopt:{cmd:e(panelvar)}}name of panel variable{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{p2col 5 20 24 2:Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimator{p_end}
{synopt:{cmd:e(Sigma)}}variance-covariance matrix of the model residuals{p_end}
{synopt:{cmd:e(W)}}weight matrix used for final round of estimation{p_end}
{synopt:{cmd:e(init)}}initial values of the estimators{p_end}

{p2col 5 20 24 2:Functions}{p_end}
{synopt:{cmd:e(sample)}}mark estimation sample{p_end}
{p2colreset}{...}


{title:Reference}

{phang}
Holtz-Eakin, D., W. Newey, and H. S. Rosen. 1988. Estimating vector
autoregressions with panel data. {it:Econometrica} 56: 1371-1395.


{title:Authors}

{pstd}Michael R. M. Abrigo{break}
Philippine Institute for Development Studies{break}
mabrigo@mail.pids.gov.ph

{pstd}Inessa Love{break}
University of Hawaii at Manoa{break}
ilove@hawaii.edu


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 16, number 3: {browse "http://www.stata-journal.com/article.html?article=st0455":st0455}

{p 7 14 2}Help:
{helpb pvarirf},
{helpb pvarfevd},
{helpb pvargranger},
{helpb pvarsoc},
{helpb pvarstable}
{p_end}
