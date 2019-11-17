{smcl}
{* *! version 0.1 08Jul2015}{...}
{cmd:help rdrandinf}{right: ({browse "http://www.stata-journal.com/article.html?article=st0435":SJ16-2: st0435})}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{cmd:rdrandinf} {hline 2}}Randomization inference for RD designs under local randomization{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:rdrandinf} {it:outvar} {it:runvar} {ifin} 
[{cmd:,} 
{cmd:{opt c:utoff}(}{it:#}{cmd:)} 
{cmd:wl(}{it:#}{cmd:)} 
{cmd:wr(}{it:#}{cmd:)} 
{cmd:{opt stat:istic}(}{it:stat}{cmd:)} 
{cmd:p(}{it:#}{cmd:)} 
{cmd:evall(}{it:#}{cmd:)} 
{cmd:evalr(}{it:#}{cmd:)} 
{cmd:kernel(}{it:kerneltype}{cmd:)} 
{cmd:{opt null:tau}(}{it:#}{cmd:)}
{cmd:ci(}{it:level} [{it:tlist}]{cmd:)} 
{cmd:{opt interf:ci}(}{it:#}{cmd:)} 
{cmd:fuzzy(}{it:fuzzy_var} [{it:fuzzy_stat}]{cmd:)} 
{cmd:d(}{it:#}{cmd:)} 
{cmd:dscale(}{it:#}{cmd:)}
{cmdab:be:rnoulli(}{it:varname}{cmd:)} 
{cmd:reps(}{it:#}{cmd:)} 
{cmd:seed(}{it:#}{cmd:)}
{cmdab:cov:ariates(}{it:varlist}{cmd:)} 
{cmd:obsmin(}{it:#}{cmd:)}
{cmd:obsstep(}{it:#}{cmd:)}
{cmd:wmin(}{it:#}{cmd:)}
{cmd:wstep(}{it:#}{cmd:)}
{cmdab:nw:indows(}{it:#}{cmd:)}
{cmd:rdwstat(}{it:stat}{cmd:)}
{opt approx:imate}
{cmd:rdwreps(}{it:#}{cmd:)}
{cmd:level(}{it:#}{cmd:)}
{cmd:plot}
{cmd:graph_options(}{it:graphopts}{cmd:)}
{opt qui:etly}]{p_end}

{pstd}
{it:outvar} is the outcome variable.  {it:runvar} is the running
variable (also known as the score or forcing variable).


{marker description}{...}
{title:Description}

{pstd}
{cmd:rdrandinf} implements randomization inference and related methods for
regression discontinuity (RD) designs, using observations in a specified or
data-driven selected window around the cutoff where local randomization is
assumed to hold.  See
{browse "http://www-personal.umich.edu/~cattaneo/papers/Cattaneo-Frandsen-Titiunik_2015_JCI.pdf":Cattaneo, Frandsen, and Titiunik (2015)}
and
{browse "http://www-personal.umich.edu/~cattaneo/papers/Cattaneo-Titiunik-VazquezBare_2015a_rdlocrand.pdf":Cattaneo, Titiunik, and Vazquez-Bare (2016a)}
for an introduction to this methodology.{p_end}

{pstd}
A detailed introduction to this command is given in
{browse "http://www-personal.umich.edu/~cattaneo/papers/Cattaneo-Titiunik-VazquezBare2015_Stata.pdf":Cattaneo, Titiunik, and Vazquez-Bare (2016b)}.  Companion {browse "www.r-project.org":R} functions are also available 
{browse "https://sites.google.com/site/rdpackages/rdlocrand":here}.{p_end}

{pstd}
Companion functions are {helpb rdwinselect}, {helpb rdsensitivity}, and {helpb rdrbounds}.{p_end}

{pstd}
Related Stata and R packages useful for inference in RD designs are described
on the following website: 
{browse "https://sites.google.com/site/rdpackages/":https://sites.google.com/site/rdpackages/}.{p_end}


{marker options}{...}
{title:Options}

{phang}
{opt cutoff(#)} specifies the RD cutoff for the running variable {it:runvar}.
The default is {cmd:cutoff(0)}.

{phang}
{cmd:wl(}{it:#}{cmd:)} specifies the left limit of the window.  The default is
the minimum of the running variable.

{phang}
{cmd:wr(}{it:#}{cmd:)} specifies the right limit of the window.  The default is
the maximum of the running variable.

{phang}
{opt statistic(stat)} specifies the statistic to be used for randomization
inference.  {it:stat} may be {cmd:ttest} (difference in means), {cmd:ksmirnov}
(Kolmogorov-Smirnov statistic), {cmd:ranksum} (Wilcoxon-Mann-Whitney
studentized statistic), or {cmd:all}, which specifies all three statistics.
The default is {cmd:statistic(ttest)}.

{phang}
{cmd:p(}{it:#}{cmd:)} specifies the order of the polynomial for the outcome
transformation model.  The default is {cmd:p(0)}.

{phang}
{cmd:evall(}{it:#}{cmd:)} specifies the point at the left of the cutoff at which the transformed outcome is evaluated.  The default is the cutoff value.

{phang}
{cmd:evalr(}{it:#}{cmd:)} specifies the point at the right of the cutoff at
which the transformed outcome is evaluated.  The default is the cutoff value.

{phang}
{cmd:kernel(}{it:kerneltype}{cmd:)}  specifies the type of kernel to use as
the weighting scheme.  {it:kerneltype} may be {cmd:uniform} (uniform kernel),
{cmd:triangular} (triangular kernel), or {cmd:epan} (Epanechnikov kernel).
The default is {cmd:kernel(uniform)}.

{phang}
{opt nulltau(#)} sets the value of the treatment effect under the null
hypothesis.  The default is {cmd:nulltau(0)}.

{phang}
{cmd:ci(}{it:level} [{it:tlist}]{cmd:)} calculates a confidence interval
for the treatment effect by test inversion, where {it:level} specifies
the level of the confidence interval and {it:tlist} indicates the grid
of treatment effects to be evaluated.  This option uses
{cmd:rdsensitivity} to calculate the confidence interval; type {cmd:help}
{cmd:rdsensitivity} for details.

{phang}
{opt interfci(#)} sets the level for Rosenbaum's confidence interval
under arbitrary interference between units (Rosenbaum 2007).  See Cattaneo, Titiunik, and Vazquez-Bare (2016b) for details.

{phang}
{cmd:fuzzy(}{it:fuzzy_var} [{it:fuzzy_stat}]{cmd:)} specifies the name of the
endogenous treatment variable in the fuzzy design.  The options for statistics
in fuzzy designs are {cmd:ar} for an Anderson-Rubin-type statistic and
{cmd:tsls} for a two-stage least-squares statistic.  The default
{it:fuzzy_stat} is {cmd:ar}.

{phang}
{cmd:d(}{it:#}{cmd:)} specifies the effect size for asymptotic power
calculation.  The default is 0.5 times the standard deviation of the outcome
variable for the control group.

{phang}
{cmd:dscale(}{it:#}{cmd:)} specifies the fraction of the standard deviation of
the outcome variable for the control group used as an alternative hypothesis
for asymptotic power calculation.  The default is {cmd:dscale(.5)}.

{phang}
{opt bernoulli(varname)} specifies that the randomization mechanism follow
Bernoulli trials instead of fixed margins randomization.  The values of the
probability of treatment for each unit must be provided in the variable
{it:varname}.

{phang}
{cmd:reps(}{it:#}{cmd:)} specifies the number of replications.  The default is
{cmd:reps(1000)}.

{phang}
{cmd:seed(}{it:#}{cmd:)} sets the seed for the randomization test.  With this
option, the user can manually set the desired seed or can enter the value -1
to use the system seed.  The default is {cmd:seed(666)}.

{pstd}
NOTE: When the window around the cutoff is not specified, {cmd:rdrandinf} can
select the window automatically using the companion command 
{helpb rdwinselect}.  The following options are available:

{phang}
{opt covariates(varlist)} specifies the covariates used by the {helpb rdwinselect} command.

{phang}
{cmd:obsmin(}{it:#}{cmd:)} specifies the minimum number of observations above
and below the cutoff in the smallest window used by the {helpb rdwinselect}
command.  The default is {cmd:obsmin(10)}.

{phang}
{cmd:obsstep(}{it:#}{cmd:)} specifies the minimum number of observations to be
added on each side of the cutoff for the sequence of nested windows
constructed by the {helpb rdwinselect} command.  The default is
{cmd:obsstep(2)}.

{phang}
{cmd:wmin(}{it:#}{cmd:)} specifies the smallest window to be used (if {cmd:minobs()} is not specified) by the {helpb rdwinselect} command.
Specifying both {cmd:wmin()} and {cmd:obsmin()} returns an error.

{phang}
{cmd:wstep(}{it:#}{cmd:)} specifies the increment in window length (if
{cmd:obsstep()} is not specified) by the {helpb rdwinselect} command.
Specifying both {cmd:obsstep()} and {cmd:wstep()} returns an error.

{phang}
{opt nwindows(#)} specifies the number of windows to be used by the 
{helpb rdwinselect} command.  The default is {cmd:nwindows(10)}.

{phang}
{cmd:rdwstat(}{it:stat}{cmd:)} specifies the statistic to be used by the
{helpb rdwinselect}  command (see help file for options).  The default option
is {cmd:rdwstat(ttest)}.

{phang}
{cmd:approximate} forces the {helpb rdwinselect} command to conduct the
covariate balance tests using a large-sample approximation instead of
finite-sample exact randomization inference methods.

{phang}
{cmd:rdwreps(}{it:#}{cmd:)} specifies the number of replications to be used by
the {helpb rdwinselect} command.  The default is {cmd:rdwreps(1000)}.

{phang}
{cmd:level(}{it:#}{cmd:)} specifies the minimum accepted value of the p-value from the covariate balance tests to be used by the {helpb rdwinselect} command.  The default is {cmd:level(.15)}.

{phang}
{cmd:plot} draws a scatterplot of the minimum p-value from the covariate
balance test against window length implemented by the {helpb rdwinselect}
command.

{phang}
{cmd:graph_options(}{it:graphopts}{cmd:)} passes the {it:graphopts}
options to the plot.  Options such as titles should be written without
double quotes.

{phang}
{cmd:quietly} suppresses output from  the {helpb rdwinselect} command.
	
		
{marker examples}{...}
{title:Examples: Cattaneo, Frandsen, and Titiunik (2015) incumbency data}

{pstd}
Setup{p_end}
{phang2}{cmd:. use rdlocrand_senate}{p_end}

{pstd}
Randomization inference with user-specified window and default options{p_end}
{phang2}{cmd:. rdrandinf demvoteshfor2 demmv, cutoff(0) wl(-.75) wr(.75)}{p_end}

{pstd}
Randomization inference with all statistics{p_end}
{phang2}{cmd:. rdrandinf demvoteshfor2 demmv, cutoff(0) wl(-.75) wr(.75) stat(all)}{p_end}

{pstd}
Randomization inference with triangular weights{p_end}
{phang2}{cmd:. rdrandinf demvoteshfor2 demmv, cutoff(0) wl(-.75) wr(.75) kernel(triangular)}{p_end}

{pstd}
Randomization inference on the Kolmogorov-Smirnov statistic with {cmd:rdwinselect} window options{p_end}
{phang2}{cmd:. rdrandinf demvoteshfor2 demmv, cutoff(0) statistic(ksmirnov) covariates(dopen population demvoteshlag1) wmin(.5) wstep(.125)}{p_end}

{pstd}
Randomization inference with linear adjustment{p_end}
{phang2}{cmd:. rdrandinf demvoteshfor2 demmv, cutoff(0) wl(-.75) wr(.75) p(1)}{p_end}

{pstd}
Randomization inference under Bernoulli trials with .5 probability of treatment{p_end}
{phang2}{cmd:. generate probs=.5}{p_end}
{phang2}{cmd:. rdrandinf demvoteshfor2 demmv, cutoff(0) wl(-.75) wr(.75) bernoulli(probs)}{p_end}

{pstd}
Confidence interval under interference{p_end}
{phang2}{cmd:. rdrandinf demvoteshfor2 demmv, cutoff(0) wl(-.75) wr(.75) interfci(.05)}{p_end}

{pstd}
Confidence interval for the treatment effect{p_end}
{phang2}{cmd:. rdrandinf demvoteshfor2 demmv, wl(-.75) wr(.75) ci(.05 3(1)20)}{p_end}

{pstd}
Linear adjustment with effects evaluated at the mean of the running variable{p_end}
{phang2}{cmd:. quietly summarize demmv if abs(demmv)<=.75 & demmv>=0 & demmv!=. & demvoteshfor2!=.}{p_end}
{phang2}{cmd:. local mt=r(mean)}{p_end}
{phang2}{cmd:. quietly summarize demmv if abs(demmv)<=.75 & demmv<0  & demmv!=. & demvoteshfor2!=.}{p_end}
{phang2}{cmd:. local mc=r(mean)}{p_end}
{phang2}{cmd:. rdrandinf demvoteshfor2 demmv, wl(-.75) wr(.75) p(1) evall(`mc') evalr(`mt')}{p_end}


{marker saved_results}{...}
{title:Stored results}

{pstd}
{cmd:rdrandinf} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(w_length)}}length of window used{p_end}
{synopt:{cmd:r(N)}}sample size in used window{p_end}
{synopt:{cmd:r(N_left)}}sample size in used window to the left of the cutoff{p_end}
{synopt:{cmd:r(N_right)}}sample size in used window to the right of the cutoff{p_end}
{synopt:{cmd:r(p)}}order of polynomial in adjusted model{p_end}
{synopt:{cmd:r(obs_stat)}}observed statistic{p_end}
{synopt:{cmd:r(ci_lb)}}lower limit of confidence interval (if {cmd:ci()} option is specified){p_end}
{synopt:{cmd:r(ci_ub)}}upper limit of confidence interval (if {cmd:ci()} option is specified){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(seed)}}seed used in permutations{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(t)}}matrix of observed statistics (when {cmd:all} is specified){p_end}
{synopt:{cmd:r(p_val)}}matrix of p-values (when {cmd:all} is specified){p_end}
		

{title:References}

{phang}
Cattaneo, M. D., B. R. Frandsen, and R. Titiunik. 2015.
{browse "http://www-personal.umich.edu/~cattaneo/papers/Cattaneo-Frandsen-Titiunik_2015_JCI.pdf":Randomization inference in the regression discontinuity design: An application to party advantages in the U.S. Senate}. 
{it:Journal of Causal Inference} 3: 1-24.{p_end}

{phang}
Cattaneo, M. D., R. Titiunik, and G. Vazquez-Bare. 2016a. Comparing inference
approaches for RD designs: A reexamination of the effect of head start on
child mortality.
Working paper, University of Michigan.
{browse "http://www-personal.umich.edu/~titiunik/papers/CattaneoTitiunikVazquezBare2015_wp.pdf"}.

{phang}
------. 2016b.
{browse "http://www.stata-journal.com/article.html?article=st0435":Inference in regression discontinuity designs under local randomization}. 
{it:Stata Journal} 16: 331-367.

{phang}
Rosenbaum, P. R. 2007. Interference between units in randomized experiments.
{it:Journal of the American Statistical Association} 102: 191-200.


{title:Authors}

{pstd}
Matias D. Cattaneo{break}
University of Michigan{break}
Ann Arbor, MI{break}
{browse "mailto:cattaneo@umich.edu":cattaneo@umich.edu}

{pstd}
Roc{c i'}o Titiunik{break}
University of Michigan{break}
Ann Arbor, MI{break}
{browse "mailto:titiunik@umich.edu":titiunik@umich.edu}

{pstd}
Gonzalo Vazquez-Bare{break}
University of Michigan{break}
Ann Arbor, MI{break}
{browse "mailto:gvazquez@umich.edu":gvazquez@umich.edu}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 16, number 2: {browse "http://www.stata-journal.com/article.html?article=st0435":st0435}{p_end}
