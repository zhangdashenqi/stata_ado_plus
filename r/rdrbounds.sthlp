{smcl}
{* *! version 0.1 08Jul2015}{...}
{cmd:help rdrbounds}{right: ({browse "http://www.stata-journal.com/article.html?article=st0435":SJ16-2: st0435})}
{hline}


{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{cmd:rdrbounds} {hline 2}}Rosenbaum bounds for inference in RD designs under local randomization{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:rdrbounds} {it:outvar} {it:runvar} {ifin} 
[{cmd:,} 
{cmdab:c:utoff(}{it:#}{cmd:)} 
{cmd:prob(}{it:varname}{cmd:)} 
{cmdab:gamma:list(}{it:numlist}{cmd:)} 
{cmd:expgamma(}{it:numlist}{cmd:)} 
{cmd:wlist(}{it:numlist}{cmd:)} 
{cmd:ulist(}{it:numlist}{cmd:)} 
{cmd:bound(}{it:bounds}{cmd:)} 
{cmdab:fm:pval}
{cmdab:stat:istic(}{it:stat}{cmd:)} 
{cmd:p(}{it:#}{cmd:)} 
{cmd:evalat(}{it:point}{cmd:)}
{cmd:kernel(}{it:kerneltype}{cmd:)}
{cmdab:null:tau(}{it:#}{cmd:)}
{cmd:fuzzy(}{it:fuzzy_var}{cmd:)}
{cmd:reps(}{it:#}{cmd:)}
{cmd:seed(}{it:#}{cmd:)}]{p_end}

{pstd}
{it:outvar} is the outcome variable.  {it:runvar} is the running
variable (also known as the score or forcing variable).


{marker description}{...}
{title:Description}

{pstd}
{cmd:rdrbounds} computes Rosenbaum bounds for p-values in regression discontinuity (RD) designs under local randomization.  See
{browse "http://www-personal.umich.edu/~cattaneo/papers/Cattaneo-Titiunik-VazquezBare_2015a_rdlocrand.pdf":Cattaneo, Titiunik, and Vazquez-Bare (2016a)}
for an introduction to this methodology.

{pstd}
A detailed introduction to this command is given in
{browse "http://www-personal.umich.edu/~cattaneo/papers/Cattaneo-Titiunik-VazquezBare2015_Stata.pdf":Cattaneo, Titiunik, and Vazquez-Bare (2016b)}.  Companion {browse "www.r-project.org":R} functions are also available 
{browse "https://sites.google.com/site/rdpackages/rdlocrand":here}.

{pstd}
Companion functions are {helpb rdrandinf}, {helpb rdwinselect}, and {helpb rdsensitivity}.

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
{cmd:prob(}{it:varname}{cmd:)} specifies the name of the variable
containing individual probabilities of treatment in a Bernoulli trial
when the selection factor gamma is zero.  The default is the proportion
of treated units in each window (assumed equal for all units).

{phang}
{opt gammalist(numlist)} specifies the list of values of gamma to be evaluated.

{phang}
{cmd:expgamma(}{it:numlist}{cmd:)} specifies the list of values of exp(gamma)
to be evaluated.  The default is {cmd:expgamma(1.5 2 2.5 3)}.

{phang}
{cmd:wlist(}{it:numlist}{cmd:)} specifies the list of window lengths to be
evaluated.  By default, the program constructs 10 windows around the cutoff,
the first one including 10 treated and control observations and then adding 5
observations to each group in subsequent windows.

{phang}
{cmd:ulist(}{it:numlist}{cmd:)} specifies the list of vectors of the
unobserved confounder to be evaluated.  The default is all vectors with ones
in the first k positions and zeros in the remaining positions; see Rosenbaum
(2002).

{phang}
{cmd:bound(}{it:bounds}{cmd:)} specifies which bounds the command calculates.
{it:bounds} may be {cmd:upper} (upper bound), {cmd:lower} (lower bound), or
{cmd:both} (both upper and lower bounds).  The default is {cmd:bound(both)}.

{phang}
{opt fmpval} calculates the p-value under fixed margins randomization
in addition to the p-value under Bernoulli trials.

{phang}
{opt statistic(stat)} specifies the statistic to be used in randomization
inference.  {it:stat} may be {cmd:ttest} (difference in means), {cmd:ksmirnov}
(Kolmogorov-Smirnov statistic), or {cmd:ranksum} (Wilcoxon-Mann-Whitney
studentized statistic).  The default is {cmd:statistic(ranksum)}.

{phang}
{cmd:p(}{it:#}{cmd:)} specifies the order of the polynomial for the outcome
transformation model.  The default is {cmd:p(0)}.

{phang}
{cmd:evalat(}{it:point}{cmd:)} specifies the point at which the transformed
variable is evaluated.  {it:point} may be {cmd:cutoff} or {cmd:means}.  The
default is {cmd:evalat(cutoff)}.

{phang}
{cmd:kernel(}{it:kerneltype}{cmd:)}  specifies the type of kernel to use as
the weighting scheme.  {it:kerneltype} may be {cmd:uniform} (uniform kernel),
{cmd:triangular} (triangular kernel), or {cmd:epan} (Epanechnikov kernel).  The
default is {cmd:kernel(uniform)}.

{phang}
{opt nulltau(#)} sets the value of the treatment effect under the null
hypothesis.  The default is {cmd:nulltau(0)}.

{phang}
{cmd:fuzzy(}{it:fuzzy_var}{cmd:)} specifies the name of the endogenous
treatment variable in the fuzzy design.  This option uses an
Anderson-Rubin-type statistic.

{phang}
{cmd:reps(}{it:#}{cmd:)} specifies the number of replications for the
randomization test.  The default is {cmd:reps(500)}.

{phang}
{cmd:seed(}{it:#}{cmd:)} sets the seed for the randomization test.  With this
option, the user can manually set the desired seed or can enter the value -1
to use the system seed.  The default is {cmd:seed(666)}.

		
{marker examples}{...}
{title:Examples: Cattaneo, Frandsen, and Titiunik (2015) incumbency data}

{pstd}
Setup{p_end}
{phang2}{cmd:. use rdlocrand_senate}{p_end}

{pstd}
Bounds using 1,000 replications specifying exp(gamma){p_end}
{phang2}{cmd:. rdrbounds demvoteshfor2 demmv, expgamma(1.2 1.5 2) wlist(.75 1) reps(1000)}{p_end}

{pstd}
Bounds specifying gamma{p_end}
{phang2}{cmd:. rdrbounds demvoteshfor2 demmv, gamma(0.2 0.5 1) wlist(.75 1) reps(1000)}{p_end}

{pstd}
Including fixed margins p-value{p_end}
{phang2}{cmd:. rdrbounds demvoteshfor2 demmv, expgamma(1.2 1.5 2) wlist(.75 1) reps(1000) fmpval}{p_end}

{pstd}
Calculate upper bound only{p_end}
{phang2}{cmd:. rdrbounds demvoteshfor2 demmv, expgamma(1.2 1.5 2) wlist(.75 1) reps(1000) bound(upper)}{p_end}



{marker saved_results}{...}
{title:Stored results}

{pstd}
{cmd:rdrbounds} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(lbounds)}} matrix of lower bounds{p_end}
{synopt:{cmd:r(ubounds)}} matrix of upper bounds{p_end}
{synopt:{cmd:r(pvals)}} matrix of p-values{p_end}
		

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
Rosenbaum, P. R. 2002. {it:Observational Studies}. New York: Springer.


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
