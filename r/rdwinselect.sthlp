{smcl}
{* *! version 0.1 08Jul2015}{...}
{cmd:help rdwinselect}{right: ({browse "http://www.stata-journal.com/article.html?article=st0435":SJ16-2: st0435})}
{hline}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{cmd:rdwinselect} {hline 2}}Window selection procedure for RD designs under local randomization{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}{cmd:rdwinselect} {it:runvar} [{it:covariates}] {ifin} 
[{cmd:,} 
{cmdab:c:utoff(}{it:#}{cmd:)}
{cmd:obsmin(}{it:#}{cmd:)}
{cmd:obsstep(}{it:#}{cmd:)}
{cmd:wmin(}{it:#}{cmd:)}
{cmd:wstep(}{it:#}{cmd:)}
{cmdab:nw:indows(}{it:#}{cmd:)}
{cmdab:stat:istic(}{it:stat}{cmd:)} 
{cmdab:approx:imate}
{cmd:p(}{it:#}{cmd:)}
{cmd:evalat(}{it:point}{cmd:)}
{cmd:kernel(}{it:kerneltype}{cmd:)}
{cmd:reps(}{it:#}{cmd:)}
{cmd:seed(}{it:#}{cmd:)}
{cmd:level(}{it:#}{cmd:)}
{cmd:plot}
{cmd:graph_options(}{it:graphopts}{cmd:)}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:rdwinselect} implements the window-selection procedure based on balance
tests for regression discontinuity (RD) designs under local randomization.
Specifically, it constructs a sequence of nested windows around the RD cutoff
and reports binomial tests for the running variable {it:runvar} and covariate
balance tests for covariates {it:covariates} (if specified).  The recommended
window is the largest window around the cutoff such that the minimum p-value
of the balance test is larger than a prespecified level for all nested
(smaller) windows.  By default, the p-values are calculated using
randomization inference methods.  See 
{browse "http://www-personal.umich.edu/~cattaneo/papers/Cattaneo-Frandsen-Titiunik_2015_JCI.pdf":Cattaneo, Frandsen, and Titiunik (2015)} and 
{browse "http://www-personal.umich.edu/~cattaneo/papers/Cattaneo-Titiunik-VazquezBare_2015a_rdlocrand.pdf":Cattaneo, Titiunik, and Vazquez-Bare (2016a)} for an introduction to this methodology.

{pstd}
A detailed introduction to this command is given in
{browse "http://www-personal.umich.edu/~cattaneo/papers/Cattaneo-Titiunik-VazquezBare2015_Stata.pdf":Cattaneo, Titiunik, and Vazquez-Bare (2016b)}.  Companion {browse "www.r-project.org":R} functions are also available 
{browse "https://sites.google.com/site/rdpackages/rdlocrand":here}.

{pstd}
Companion functions are {helpb rdrandinf}, {helpb rdsensitivity}, and {helpb rdrbounds}.

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
{cmd:obsmin(}{it:#}{cmd:)} specifies the minimum number of observations above
and below the cutoff in the smallest window.  The default is {cmd:obsmin(10)}.

{phang}
{cmd:obsstep(}{it:#}{cmd:)} specifies the minimum number of observations to be
added on each side of the cutoff in all but the first window.  The default is
{cmd:obsstep(2)}.

{phang}
{cmd:wmin(}{it:#}{cmd:)} specifies the smallest window to be used (if
{cmd:minobs()} is not specified).  Specifying both {cmd:wmin()} and
{cmd:obsmin()} returns an error.

{phang}
{cmd:wstep(}{it:#}{cmd:)} specifies the increment in window length (if
{cmd:obsstep()} is not specified).  Specifying both {cmd:obsstep()} and
{cmd:wstep()} returns an error.

{phang}
{opt nwindows(#)} specifies the number of windows to be used.  The default is
{cmd:nwindows(10)}.

{phang}
{opt statistic(stat)} specifies the statistic to be used.  {it:stat} may be
one of the following: {cmd:ttest} (difference in means), {cmd:ksmirnov}
(Kolmogorov-Smirnov statistic), {cmd:ranksum} (Wilcoxon-Mann-Whitney
studentized statistic), or {cmd:hotelling} (Hotelling's T-squared statistic).
The default is {cmd:statistic(ttest)}.

{phang}
{opt approximate}  performs the covariate balance test using a large-sample
approximation instead of randomization inference.

{phang}
{cmd:p(}{it:#}{cmd:)} specifies the order of the polynomial for the outcome
adjustment model.  The default is {cmd:p(0)}.

{phang}
{cmd:evalat(}{it:point}{cmd:)} specifies the point at which the adjusted
variable is evaluated.  {it:point} may be {cmd:cutoff} or {cmd:means}.  The
default is {cmd:evalat(cutoff)}.

{phang}
{cmd:kernel(}{it:kerneltype}{cmd:)}  specifies the type of kernel to use as
the weighting scheme.  {it:kerneltype} may be {cmd:uniform} (uniform kernel),
{cmd:triangular} (triangular kernel), or {cmd:epan} (Epanechnikov kernel).
The default is {cmd:kernel(uniform)}.

{phang}
{cmd:reps(}{it:#}{cmd:)} specifies the number of replications for the
randomization test.  The default is {cmd:reps(1000)}.

{phang}
{cmd:seed(}{it:#}{cmd:)} sets the seed for the randomization test.  With this
option, the user can manually set the desired seed or can enter the value -1
to use the system seed.  The default is {cmd:seed(666)}.

{phang}
{cmd:level(}{it:#}{cmd:)} specifies the minimum accepted value of the p-value
from the covariate balance tests to be used.  The default is {cmd:level(.15)}.

{phang}
{cmd:plot} draws a scatterplot of the minimum p-value from the covariate
balance test against window length.

{phang}
{cmd:graph_options(}{it:graphopts}{cmd:)} passes the {it:graphopts} options to
the plot.  Options such as titles should be written without double quotes.


{marker examples}{...}
{title:Examples: Cattaneo, Frandsen, and Titiunik (2015) incumbency data}

{pstd}
Setup{p_end}
{phang2}{cmd:. use rdlocrand_senate}{p_end}

{pstd}
Window selection with three covariates and default options{p_end}
{phang2}{cmd:. rdwinselect demmv dopen population demvoteshlag1}{p_end}

{pstd}
Window selection using Kolmogorov-Smirnov statistic{p_end}
{phang2}{cmd:. rdwinselect demmv dopen population demvoteshlag1, stat(ksmirnov)}{p_end}

{pstd}
Window selection with smallest window including at least 10 observations in
each group and adding 3 observations in each step{p_end}
{phang2}{cmd:. rdwinselect demmv dopen population demvoteshlag1, obsmin(10) obsstep(3)}{p_end}

{pstd}
Window selection setting smallest window at 0.5 and with 0.125 length
increments{p_end}
{phang2}{cmd:. rdwinselect demmv dopen population demvoteshlag1, wmin(.5) wstep(.125)}{p_end}

{pstd}
Window selection with asymptotic p-values using 40 windows with 
scatterplot{p_end}
{phang2}{cmd:. rdwinselect demmv dopen population demvoteshlag1, nwindows(40) approximate plot}{p_end}

{pstd}
Modify graph options: add title and x axis label{p_end}
{phang2}{cmd:. rdwinselect demmv dopen population demvoteshlag1, nwindows(40) approx plot graph_options(title(Main title) xtitle(x-axis title))}{p_end}


{marker saved_results}{...}
{title:Stored results}

{pstd}
{cmd:rdwinselect} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}sample size in recommended window{p_end}
{synopt:{cmd:r(N_left)}}sample size in recommended window to the left of the cutoff{p_end}
{synopt:{cmd:r(N_right)}}sample size in recommended window to the right of the cutoff{p_end}
{synopt:{cmd:r(rec_length)}}recommended window length{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(seed)}}seed used in permutations{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}stores the minimum p-value from covariate balance test, p-value from binomial test, sample sizes, and window length in each window{p_end}
		

{title:References}

{phang}
Cattaneo, M. D., B. R. Frandsen, and R. Titiunik. 2015.
{browse "http://www-personal.umich.edu/~cattaneo/papers/Cattaneo-Frandsen-Titiunik_2015_JCI.pdf":Randomization inference in the regression discontinuity design: An application to party advantages in the U.S. Senate}. 
{it:Journal of Causal Inference} 3: 1-24.{p_end}

{phang}
Cattaneo, M. D., R. Titiunik, and G. Vazquez-Bare. 2016a. Comparing inference approaches for RD designs: A reexamination of the effect of head start on child mortality.  
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
