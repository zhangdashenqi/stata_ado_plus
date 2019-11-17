{smcl}
{* *! version 7.0.4 29Mar2016}{...}
{cmd:help rdbwselect}{right: ({browse "http://www.stata-journal.com/article.html?article=st0366_1":SJ17-2: st0366_1})}
{hline}

{title:Title}

{p2colset 5 19 21 2}{...}
{p2col:{cmd:rdbwselect} {hline 2}}Bandwidth selection procedures for local polynomial regression-discontinuity estimators{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 19 2}
{cmd:rdbwselect} {it:depvar} {it:runvar} {ifin} 
[{cmd:,} 
{cmd:c(}{it:cutoff}{cmd:)} 
{cmd:p(}{it:pvalue}{cmd:)} 
{cmd:q(}{it:qvalue}{cmd:)}
{cmd:deriv(}{it:dvalue}{cmd:)}
{cmd:fuzzy(}{it:fuzzyvar} [{cmd:sharpbw}]{cmd:)}
{cmd:covs(}{it:covars}{cmd:)}
{cmd:kernel(}{it:kernelfn}{cmd:)}
{cmd:weights(}{it:weightsvar}{cmd:)}
{cmd:bwselect(}{it:bwmethod}{cmd:)}
{cmd:scaleregul(}{it:scaleregulvalue}{cmd:)}
{cmd:vce(}{it:vcemethod}{cmd:)}
{cmd:all}]

{pstd}
where {it:depvar} is the dependent variable and {it:runvar} is the running
variable (also known as the score or forcing variable).


{marker description}{...}
{title:Description}

{pstd}
{cmd:rdbwselect} implements bandwidth selectors for local polynomial
regression-discontinuity (RD) point estimators and inference procedures
developed in Calonico, Cattaneo, and Titiunik (2014b); Calonico, Cattaneo, and
Farrell (Forthcoming); and Calonico et al. (2016).

{pstd}
{cmd:rdbwselect} has two companion commands: {helpb rdrobust} for point
estimation and inference procedures and {helpb rdplot:rdplot} for data-driven
RD plots (see Calonico, Cattaneo, and Titiunik [2015a] for details).{p_end}

{pstd}
A detailed introduction to this command is given in both Calonico, Cattaneo,
and Titiunik (2014a) and Calonico et al. (2017).  A companion 
{browse "www.r-project.org":R package} is also described in Calonico,
Cattaneo, and Titiunik (2015b).

{pstd}
For more details, and for related Stata and R packages useful for analysis of
RD designs, visit {browse "https://sites.google.com/site/rdpackages/"}.


{marker options}{...}
{title:Options}

{phang}
{cmd:c(}{it:cutoff}{cmd:)} specifies the RD cutoff.  The default is
{cmd:c(0)}.

{phang}
{cmd:p(}{it:pvalue}{cmd:)} specifies the order of the local polynomial used to
construct the point estimator.  The default is {cmd:p(1)} (local linear
regression).

{phang}
{cmd:q(}{it:qvalue}{cmd:)} specifies the order of the local polynomial used to
construct the bias correction.  The default is {cmd:q(2)} (local quadratic
regression).

{phang}
{cmd:deriv(}{it:dvalue}{cmd:)} specifies the order of the derivative of the
regression functions to be estimated.  The default is {cmd:deriv(0)} (sharp
RD, or fuzzy RD if {cmd:fuzzy()} is also specified).  Setting {cmd:deriv(1)}
results in estimation of a kink RD design (up to scale) or a fuzzy kink RD if
{cmd:fuzzy()} is also specified.

{phang}
{cmd:fuzzy(}{it:fuzzyvar} [{cmd:sharpbw}]{cmd:)} specifies the treatment
status variable used to implement fuzzy RD estimation (or fuzzy kink RD if
{cmd:deriv(1)} is also specified).  The default is sharp RD design.  If the
{cmd:sharpbw} option is set, the fuzzy RD estimation is performed using a
bandwidth selection procedure for the sharp RD model.  This option is
automatically selected if there is perfect compliance at either side of the
threshold.

{phang}
{cmd:covs(}{it:covars}{cmd:)} specifies additional covariates to be used for
estimation and inference.{p_end}

{phang}
{cmd:kernel(}{it:kernelfn}{cmd:)} specifies the kernel function used to
construct the local polynomial estimators.  {it:kernelfn} may be 
{opt tri:angular}, {opt epa:nechnikov}, or {opt uni:form}.  The default is
{cmd:kernel(triangular)}.{p_end}

{phang}
{cmd:weights(}{it:weightsvar}{cmd:)} specifies the variable used for optional
weighting of the estimation procedure.  The unit-specific weights multiply the
kernel function.{p_end}

{phang}
{cmd:bwselect(}{it:bwmethod}{cmd:)} specifies the bandwidth selection
procedure to be used.  For details on implementation, see Calonico, Cattaneo,
and Titiunik (2014b); Calonico, Cattaneo, and Farrell (Forthcoming); and Calonico et
al. (2016), and the companion software articles.  {it:bwmethod} may be one of
the following:

{phang2}
{opt mserd} specifies one common mean squared error (MSE)-optimal bandwidth
selector for the RD treatment-effect estimator.  This is the default.{p_end}

{phang2}
{opt msetwo} specifies two different MSE-optimal bandwidth selectors (below
and above the cutoff) for the RD treatment-effect estimator.{p_end}

{phang2}
{opt msesum} specifies one common MSE-optimal bandwidth selector for the sum
of regression estimates (as opposed to the difference thereof).{p_end}

{phang2}
{opt msecomb1} specifies min({opt mserd}, {opt msesum}).{p_end}

{phang2}
{opt msecomb2} specifies median({opt msetwo}, {opt mserd}, {opt msesum}) for
each side of the cutoff separately.{p_end}

{phang2}
{opt cerrd} specifies one common coverage error-rate (CER)-optimal bandwidth
selector for the RD treatment-effect estimator.{p_end}

{phang2}
{opt certwo} specifies two different CER-optimal bandwidth selectors (below
and above the cutoff) for the RD treatment-effect estimator.{p_end}

{phang2}
{opt cersum} specifies one common CER-optimal bandwidth selector for the sum
of regression estimates (as opposed to the difference thereof).{p_end}

{phang2}
{opt cercomb1} specifies min({opt cerrd}, {opt cersum}).{p_end}

{phang2}
{opt cercomb2} specifies median({opt certwo}, {opt cerrd}, {opt cersum}) for
each side of the cutoff separately.{p_end}

{phang}
{cmd:scaleregul(}{it:scaleregulvalue}{cmd:)} specifies the scaling factor for
the regularization term added to the denominator of the bandwidth selectors.
Setting {cmd:scaleregul(0)} removes the regularization term from the bandwidth
selectors.  The default is {cmd:scaleregul(1)}.{p_end}

{phang}
{cmd:vce(}{it:vcemethod}{cmd:)} specifies the procedure used to compute the
variance-covariance matrix estimator.  {it:vcemethod} may be one of the
following:

{phang2}
{cmd:nn} [{it:nnmatch}] specifies a heteroskedasticity-robust nearest neighbor
variance estimator with {it:nnmatch} indicating the minimum number of
neighbors to be used.  The default is {cmd:vce(nn 3)}.

{phang2}
{cmd:hc0} specifies a heteroskedasticity-robust plug-in residuals variance
estimator without weights.{p_end}

{phang2}
{cmd:hc1} specifies a heteroskedasticity-robust plug-in residuals variance
estimator with {cmd:hc1} weights.{p_end}

{phang2}
{cmd:hc2} specifies a heteroskedasticity-robust plug-in residuals variance
estimator with {cmd:hc2} weights.{p_end}

{phang2}
{cmd:hc3} specifies a heteroskedasticity-robust plug-in residuals variance
estimator with {cmd:hc3} weights.{p_end}

{phang2}
{cmd:nncluster} {it:clustervar} [{it:nnmatch}] specifies a cluster-robust
nearest neighbor variance estimator with {it:clustervar} indicating the
cluster ID variable and {it:nnmatch} indicating the minimum number of
neighbors to be used.{p_end}

{phang2}
{cmd:cluster} {it:clustervar} specifies a cluster-robust plug-in residuals
variance estimator with degrees-of-freedom weights and {it:clustervar}
indicating the cluster ID variable.{p_end}

{phang}
{cmd:all} specifies that {cmd:rdbwselect} report all available bandwidth
selection procedures.{p_end}


{marker examples}{...}
{title:Example: Cattaneo, Frandsen, and Titiunik (2015) incumbency data}
    
{pstd}Setup{p_end}
{phang2}{cmd:. use rdrobust_senate.dta}{p_end}

{pstd}MSE bandwidth selection procedure{p_end}
{phang2}{cmd:. rdbwselect vote margin}{p_end}

{pstd}All bandwidth selection procedures{p_end}
{phang2}{cmd:. rdbwselect vote margin, all}{p_end}


{marker stored_results}{...}
{title:Stored results}

{pstd}
{cmd:rdbwselect} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N_l)}}number of observations to the left of the cutoff{p_end}
{synopt:{cmd:e(N_r)}}number of observations to the right of the cutoff{p_end}
{synopt:{cmd:e(c)}}cutoff value{p_end}
{synopt:{cmd:e(p)}}order of the polynomial used for estimation of the regression function{p_end}
{synopt:{cmd:e(q)}}order of the polynomial used for estimation of the bias of the regression function estimator{p_end}
{synopt:{cmd:e(h_mserd)}}MSE-optimal bandwidth selector for the RD treatment-effect estimator{p_end}
{synopt:{cmd:e(h_msetwo_l)}}MSE-optimal bandwidth selectors below the cutoff for the RD treatment-effect estimator{p_end}
{synopt:{cmd:e(h_msetwo_r)}}MSE-optimal bandwidth selectors above the cutoff for the RD treatment-effect estimator{p_end}
{synopt:{cmd:e(h_msesum)}}MSE-optimal bandwidth selector for the sum of regression estimates{p_end}
{synopt:{cmd:e(h_msecomb1)}}min({opt mserd}, {opt msesum}){p_end}
{synopt:{cmd:e(h_msecomb2_l)}}median({opt msetwo}, {opt mserd}, {opt msesum}), below the cutoff{p_end}
{synopt:{cmd:e(h_msecomb2_r)}}median({opt msetwo}, {opt mserd}, {opt msesum}), above the cutoff{p_end}
{synopt:{cmd:e(h_cerrd)}}CER-optimal bandwidth selector for the RD treatment-effect estimator{p_end}
{synopt:{cmd:e(h_certwo_l)}}CER-optimal bandwidth selectors below the cutoff for the RD treatment-effect estimator{p_end}
{synopt:{cmd:e(h_certwo_r)}}CER-optimal bandwidth selectors above the cutoff for the RD treatment-effect estimator{p_end}
{synopt:{cmd:e(h_cersum)}}CER-optimal bandwidth selector for the sum of regression estimates{p_end}
{synopt:{cmd:e(h_cercomb1)}}min({opt cerrd}, {opt cersum}){p_end}
{synopt:{cmd:e(h_cercomb2_l)}}median({opt certwo_l}, {opt cerrd}, {opt cersum}), below the cutoff{p_end}
{synopt:{cmd:e(h_cercomb2_r)}}median({opt certwo_r}, {opt cerrd}, {opt cersum}), above the cutoff{p_end}
{synopt:{cmd:e(b_mserd)}}MSE-optimal bandwidth selector for the bias of the RD treatment-effect estimator{p_end}
{synopt:{cmd:e(b_msetwo_l)}}MSE-optimal bandwidth selectors below the cutoff for the bias of the RD treatment-effect estimator{p_end}
{synopt:{cmd:e(b_msetwo_r)}}MSE-optimal bandwidth selectors above the cutoff for the bias of the RD treatment-effect estimator{p_end}
{synopt:{cmd:e(b_msesum)}}MSE-optimal bandwidth selector for the sum of regression estimates for the bias of the RD treatment-effect estimator{p_end}
{synopt:{cmd:e(b_msecomb1)}}min({opt mserd}, {opt msesum}){p_end}
{synopt:{cmd:e(b_msecomb2_l)}}median({opt msetwo}, {opt mserd}, {opt msesum}), below the cutoff{p_end}
{synopt:{cmd:e(b_msecomb2_r)}}median({opt msetwo}, {opt mserd}, {opt msesum}), above the cutoff{p_end}
{synopt:{cmd:e(b_cerrd)}}CER-optimal bandwidth selector for the bias of the RD treatment-effect estimator{p_end}
{synopt:{cmd:e(b_certwo_l)}}CER-optimal bandwidth selectors below the cutoff for the bias of the RD treatment-effect estimator{p_end}
{synopt:{cmd:e(b_certwo_r)}}CER-optimal bandwidth selectors above the cutoff for the bias of the RD treatment-effect estimator{p_end}
{synopt:{cmd:e(b_cersum)}}CER-optimal bandwidth selector for the sum of regression estimates for the bias of the RD treatment-effect estimator{p_end}
{synopt:{cmd:e(b_cercomb1)}}min({opt cerrd}, {opt cersum}){p_end}
{synopt:{cmd:e(b_cercomb2_l)}}median({opt certwo_l}, {opt cerrd}, {opt cersum}), below the cutoff{p_end}
{synopt:{cmd:e(b_cercomb2_r)}}median({opt certwo_r}, {opt cerrd}, {opt cersum}), above the cutoff{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(runningvar)}}name of running variable{p_end}
{synopt:{cmd:e(outcomevar)}}name of outcome variable{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(covs)}}name of covariates{p_end}
{synopt:{cmd:e(vce_select)}}vcetype specified in vce(){p_end}
{synopt:{cmd:e(bwselect)}}bandwidth selection choice{p_end}
{synopt:{cmd:e(kernel)}}kernel choice{p_end}


{title:References}

{phang}
Calonico, S., M. D. Cattaneo, and M. H. Farrell. Forthcoming. On the effect of
bias estimation on coverage accuracy in nonparametric inference.
{it:Journal of the American Statistical Association}.

{phang}
Calonico, S., M. D. Cattaneo, M. H. Farrell, and R. Titiunik. 2016. Regression discontinuity designs using covariates.
Working Paper, University of Michigan.
{browse "http://www-personal.umich.edu/~cattaneo/papers/Calonico-Cattaneo-Farrell-Titiunik_2016_wp.pdf"}.{p_end}

{phang}
Calonico, S., M. D. Cattaneo, M. H. Farrell, and R. Titiunik. 2017. 
{browse "http://www.stata-journal.com/article.html?article=st0366_1":rdrobust: Software for regression-discontinuity designs}.
{it:Stata Journal} 17: 372-404.

{phang}
Calonico, S., M. D. Cattaneo, and R. Titiunik. 2014a. 
{browse "http://www.stata-journal.com/article.html?article=st0366":Robust data-driven inference in the regression-discontinuity design}. {it:Stata Journal} 14: 909-946. 

{phang}
------. 2014b. Robust nonparametric confidence intervals for regression-discontinuity designs.
{it:Econometrica} 82: 2295-2326.

{phang}
------. 2015a. Optimal data-driven regression discontinuity plots.
{it:Journal of the American Statistical Association} 110: 1753-1769. 

{phang}
------. 2015b. rdrobust: An R package for robust nonparametric inference in regression-discontinuity designs.
{it:R Journal} 7: 38-51.

{phang}
Cattaneo, M. D., B. R. Frandsen, and R. Titiunik. 2015. Randomization inference in the regression discontinuity design: An application to the study of party advantages in the U.S. Senate.
{it:Journal of Causal Inference} 3: 1-24.


{title:Authors}

{pstd}
Sebastian Calonico{break}
University of Miami{break}
Coral Gables, FL{break}
{browse "mailto:scalonico@bus.miami.edu":scalonico@bus.miami.edu}{p_end}

{pstd}
Matias D. Cattaneo{break}
University of Michigan{break}
Ann Arbor, MI{break}
{browse "mailto:cattaneo@umich.edu":cattaneo@umich.edu}{p_end}

{pstd}
Max H. Farrell{break}
University of Chicago{break}
Chicago, IL{break}
{browse "mailto:max.farrell@chicagobooth.edu":max.farrell@chicagobooth.edu}{p_end}

{pstd}
Roc{c i'}o Titiunik{break}
University of Michigan{break}
Ann Arbor, MI{break}
{browse "mailto:titiunik@umich.edu":titiunik@umich.edu}{p_end}


{marker also_see}{...}
{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 17, number 2: {browse "http://www.stata-journal.com/article.html?article=st0366_1":st0366_1},{break}
                    {it:Stata Journal}, volume 14, number 4: {browse "http://www.stata-journal.com/article.html?article=st0366":st0366}
{p_end}
