{smcl}
{* *! version 0.1 08Jul2015}{...}
{cmd:help rdsensitivity}{right: ({browse "http://www.stata-journal.com/article.html?article=st0435":SJ16-2: st0435})}
{hline}

{title:Title}

{p2colset 5 22 24 2}{...}
{p2col:{cmd:rdsensitivity} {hline 2}}Sensitivity analysis for RD designs under local randomization{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 21 2}
{cmd:rdsensitivity} {it:outvar} {it:runvar} {ifin} 
[{cmd:,} 
{cmdab:c:utoff(}{it:#}{cmd:)} 
{cmd:wlist(}{it:numlist}{cmd:)} 
{cmd:tlist(}{it:numlist}{cmd:)} 
{cmd:saving(}{it:filename}{cmd:)} 
{cmd:nodots} 
{cmd:nodraw} 
{cmd:verbose}
{cmd:ci(}{it:window} [{it:level}]{cmd:)}
{cmdab:stat:istic(}{it:stat}{cmd:)} 
{cmd:p(}{it:#}{cmd:)} 
{cmd:evalat(}{it:point}{cmd:)}
{cmd:kernel(}{it:kerneltype}{cmd:)}
{cmd:fuzzy(}{it:fuzzy_var}{cmd:)}
{cmd:reps(}{it:#}{cmd:)}
{cmd:seed(}{it:#}{cmd:)}]{p_end}

{pstd}
{it:outvar} is the outcome variable.  {it:runvar} is the running variable
(also known as the score or forcing variable).


{marker description}{...}
{title:Description}

{pstd}
{cmd:rdsensitivity} performs sensitivity analysis for regression discontinuity
designs (RD) under local randomization.  See 
{browse "http://www-personal.umich.edu/~cattaneo/papers/Cattaneo-Titiunik-VazquezBare_2015a_rdlocrand.pdf":Cattaneo, Titiunik, and Vazquez-Bare (2016a)}
for an introduction to this methodology.

{pstd}
A detailed introduction to this command is given in {browse "http://www-personal.umich.edu/~cattaneo/papers/Cattaneo-Titiunik-VazquezBare2015_Stata.pdf":Cattaneo, Titiunik, and Vazquez-Bare (2016b)}.
Companion {browse "www.r-project.org":R} functions are also available 
{browse "https://sites.google.com/site/rdpackages/rdlocrand":here}.

{pstd}
Companion functions are {helpb rdrandinf}, {helpb rdwinselect}, and 
{helpb rdrbounds}.

{pstd}
Related Stata and R packages useful for inference in RD designs are described
on the following website: 
{browse "https://sites.google.com/site/rdpackages/":https://sites.google.com/site/rdpackages/}.


{marker options}{...}
{title:Options}

{phang}
{opt cutoff(#)} specifies the RD cutoff for the running variable {it:runvar}.
The default is {cmd:cutoff(0)}.

{phang}
{cmd:wlist(}{it:#}{cmd:)} specifies the list of window lengths to be
evaluated.  By default, the program constructs 10 windows around the cutoff,
the first one including 10 treated and control observations and then adding 5
observations to each group in subsequent windows.

{phang}
{cmd:tlist(}{it:#}{cmd:)} specifies the list of values of the treatment effect
under the null to be evaluated.  By default, the program uses 10 evenly spaced
points within the asymptotic confidence interval for a constant treatment
effect in the smallest window to be used.

{phang}
{cmd:saving(}{it:filename}{cmd:)} saves the dataset containing the data for
the contour plot in {it:filename}.  This allows the user to replicate and
modify the appearance of the plot and conduct further sensitivity analysis.

{phang}
{cmd:nodots} suppresses replication dots.

{phang}
{cmd:nodraw} suppresses the contour plot.

{phang}
{cmd:verbose} displays the matrix of results.

{phang}
{cmd:ci(}{it:window} [{it:level}]{cmd:)} returns the confidence interval
corresponding to the window length indicated in {it:window}.  The value in
{cmd:ci()} needs to be one of the values in {cmd:wlist()}.  The level of the
confidence interval can be specified with the {cmd:level()} option.  The
default level is 0.05, corresponding to a 95% confidence interval.

{phang}
{opt statistic(stat)} specifies the statistic to be used in randomization
inference.  {it:stat} may be {cmd:ttest} (difference in means), {cmd:ksmirnov}
(Kolmogorov-Smirnov statistic), {cmd:ranksum} (Wilcoxon-Mann-Whitney
studentized statistic), or {cmd:all}, which specifies all three statistics.
The default is {cmd:statistic(ttest)}.

{phang}
{cmd:p(}{it:#}{cmd:)} specifies the order of the polynomial for the outcome
transformation model.  The default is {cmd:p(0)}.

{phang}
{cmd:evalat(}{it:point}{cmd:)} specifies the point at which the adjusted
variable is evaluated.  {it:point} may be {cmd:cutoff} or {cmd:means}.  The
default is {cmd:evalat(cutoff)}.

{phang}
{cmd:kernel(}{it:kerneltype}{cmd:)} specifies the type of kernel to use as the
weighting scheme.  {it:kerneltype} may be {cmd:uniform} (uniform kernel),
{cmd:triangular} (triangular kernel), or {cmd:epan} (Epanechnikov kernel).
The default is {cmd:kernel(uniform)}.

{phang}
{cmd:fuzzy(}{it:fuzzy_var}{cmd:)} specifies the name of the endogenous
treatment variable in the fuzzy design.  This option uses an
Anderson-Rubin-type statistic.

{phang}
{cmd:reps(}{it:#}{cmd:)} specifies the number of replications for the
randomization test.  The default is {cmd:reps(1000)}.

{phang}
{cmd:seed(}{it:#}{cmd:)} sets the initial seed for the randomization test.
With this option, the user can manually set the desired seed or can enter the
value -1 to use the system seed.  The default is {cmd:seed(666)}.


{marker examples}{...}
{title:Examples: Cattaneo, Frandsen, and Titiunik (2015) incumbency data}

{pstd}
Setup{p_end}
{phang2}{cmd:. use rdlocrand_senate}{p_end}

{pstd}
Sensitivity analysis using 1,000 replications{p_end}
{phang2}{cmd:. rdsensitivity demvoteshfor2 demmv, wlist(.75(.25)2) tlist(0(1)20) reps(1000)}{p_end}

{pstd}
Obtain confidence interval for window [-.75;.75]{p_end}
{phang2}{cmd:. rdsensitivity demvoteshfor2 demmv, wlist(.75(.25)2) tlist(0(1)20) reps(1000) ci(.75)}{p_end}

{pstd}
Replicate contour graph using saved dataset{p_end}
{phang2}{cmd:. rdsensitivity demvoteshfor2 demmv, wlist(.75(.25)2) tlist(0(1)20) reps(1000) saving(graphdata)}{p_end}
{phang2}{cmd:. use graphdata, clear}{p_end}
{phang2}{cmd:. twoway contour pvalue t w, ccuts(0(0.05)1)}{p_end}



{marker saved_results}{...}
{title:Stored results}

{pstd}
{cmd:rdsensitivity} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(ci_lb)}} lower limit of confidence interval{p_end}
{synopt:{cmd:r(ci_ub)}} upper limit of confidence interval{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(results)}} matrix of p-values{p_end}
		

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
