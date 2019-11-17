{smcl}
{* 27march2013}{...}
{cmd:help glmgpscore}{right: ({browse "http://www.stata-journal.com/article.html?article=st0328":SJ14-1: st0328})}
{hline}

{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{hi:glmgpscore} {hline 2}}Estimation of the generalized propensity score through generalized linear models{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 18 2}
{cmd:glmgpscore}
{varlist} 
{ifin}
{weight}{cmd:,}
{opth t(varname)}
{opth gpscore(newvar)}
{opth predict(newvar)}
{opth sigma(newvar)}
{opth cutpoints(varname)}
{opt index(string)}
{opt nq_gps(#)}
{opt family(string)}
{opt link(string)}
[{opt t_transf(transformation)}
{opt normal_test(test)}
{opt norm_level(#)}
{opth test_varlist(varlist)}
{opt test(type)}
{opt flag_b(#)}
{opt opt_nb(string)}
{opth opt_b(varname)}
{cmdab:det:ail}]

{pstd}
{cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed;
see {help weight}.


{title:Description}

{pstd}
{cmd:glmgpscore} estimates the parameters of the conditional
distribution of the treatment given the control variables in
{varlist} by using generalized linear models (GLM).  This command is
based on {helpb gpscore}, written by Bia and Mattei (2008).
{cmd:glmgpscore} allows six different distribution functions:  binomial,
gamma, inverse Gaussian, negative binomial, normal, and Poisson coupled
with admissible links.  For the normal case, {cmd:glmgpscore} assesses
the validity of the assumed normal distribution model by a
user-specified goodness-of-fit test and estimates the generalized
propensity score (GPS).  The estimated GPS is defined as R=r(T,X), where
r(.,.) is the conditional density of the treatment given the covariates,
T is the observed treatment, and X is the vector of the observed
covariates.  {cmd:glmgpscore} then tests the balancing property by using
the algorithm suggested by Hirano and Imbens (2004) and tells the user
whether and to what extent the balancing property is supported by the
data.


{title:Options}

{pstd}
In what follows, we provide only a description of the options related
to the {cmd:glmgpscore} command and not included in {helpb gpscore} or with
a different content, referring the reader to Bia and Mattei (2008) for the
others.

{phang}
{opth gpscore(newvar)} specifies the variable name for the estimated GPS via
generalized linear model.  {cmd:gpscore()} is required.

{phang}
{opth sigma(newvar)} creates a new variable to hold the GLM fit of the
conditional standard error of the treatment given the covariates, which are
obtained from Pearson residuals.  {cmd:sigma()} is required.

{phang}
{opt family(string)} specifies the distribution family name of the treated
variable.  {cmd:family()} is required.

{phang}
{opt link(string)} specifies the link function for the treated variable.  The
default is the canonical link for the {cmd:family()} specified.  {cmd:link()}
is required.

{phang}
{opt flag_b(#)} skips either the balancing or the normal test or both and
takes as arguments {cmd:0}, {cmd:1}, or {cmd:2}.  If {cmd:flag_b()} is not
specified, the program estimates the GPS performing both the balancing and the
normal tests.  {cmd:flag_b(0)} skips both the balancing and the normal tests;
{cmd:flag_b(1)} skips only the balancing test; {cmd:flag_b(2)} skips only the
normal test.

{phang}
{opt opt_nb(string)} specifies the negative binomial dispersion parameter.  In
the GLM approach, you specify {cmd:family(nb} {it:#k}{cmd:)}, where {it:#k} is
specified through the {cmd:opt_nb()} option.  The GLM then searches for the
{it:#k} that results in the deviance-based dispersion being 1.  Instead,
{cmd:nbreg} finds the ML estimate of {it:#k}.

{phang}
{opth opt_b(varname)} specifies the name of the variable that contains the
number of binomial trials.


{title:Remarks} 

{pstd}
Please remember to use the {helpb update query} command before
running this program to make sure you have an up-to-date version of
Stata installed.  Otherwise, this program may not run properly.

{pstd}
Pay attention to the family-link combination; not all combinations are
feasible.

{pstd}
Make sure that the variables in {varlist} do not contain missing values.

{pstd}
Recall that {helpb #delimit} is not an interactive command; it
resets the character that marks the end of a command, and 
{cmd:#delimit cr} restores the carriage return delimiter.  Please take
this into account if you want to copy and paste the commands below.


{title:Examples}

{pstd}Fractional logit{p_end}
{phang2}{bf:{stata "use lotterydataset": . use lotterydataset}}{p_end}
{phang2}{bf:{stata "egen max_p=max(prize) " : . egen max_p=max(prize)}}{p_end}
{phang2}{bf:{stata "generate fraction= prize/max_p " : . generate fraction= prize/max_p }}{p_end}
{phang2}{bf:{stata "quietly generate cut1 = 23/max_p  if fraction<=23/max_p " : . quietly generate cut1 = 23/max_p  if fraction<=23/max_p }}{p_end}
{phang2}{bf:{stata "quietly replace cut1 = 80/max_p  if fraction>23/max_p & fraction<=80/max_p " : . quietly replace cut1 = 80/max_p  if fraction>23/max_p & fraction<=80/max_p }}{p_end}
{phang2}{bf:{stata "quietly replace cut1 = 485/max_p if fraction >80/max_p " : . quietly replace cut1 = 485/max_p if fraction >80/max_p }}{p_end}
    
{phang2}{cmd:. #delimit ;}{p_end}
{phang2}{cmd:. glmgpscore male ownhs owncoll tixbot workthen yearw yearm1 yearm2, }{p_end}
{phang2}{cmd:. t(fraction) gpscore(gpscore_fr) }{p_end}
{phang2}{cmd:. predict(y_hat_fr) sigma(sd_fr) cutpoints(cut1) index(mean)}{p_end}
{phang2}{cmd:. nq_gps(5) family(binomial) link(logit) detail}{p_end}
{phang2}{cmd:. ;}{p_end}
{phang2}{cmd:. #delimit cr}{p_end}

{pstd}Negative binomial distribution{p_end}
{phang2}{bf:{stata "use lotterydataset, clear": . use lotterydataset, clear}}{p_end}
{phang2}{bf:{stata "generate edu=owncoll+ownhs  " : . generate edu=owncoll+ownhs}}{p_end}
{phang2}{bf:{stata "quietly generate cut3 = 3  if edu<=3  " : . quietly generate cut3 = 3  if edu<=3 }}{p_end}
{phang2}{bf:{stata "quietly replace cut3 = 6  if edu>3 & edu<=6 " : . quietly replace cut3 = 6  if edu>3 & edu<=6 }}{p_end}
{phang2}{bf:{stata "quietly replace cut3 = 9 if edu >6 " : . quietly replace cut3 = 9 if edu >6 }}{p_end}

{phang2}{cmd:. #delimit ;}{p_end}
{phang2}{cmd:. glmgpscore male workthen yearw yearm1 yearm2, }{p_end}
{phang2}{cmd:. t(edu) gpscore(gpscore_nb) }{p_end}
{phang2}{cmd:. predict(y_hat_nb) sigma(sd_nb) cutpoints(cut3) index(p50)}{p_end}
{phang2}{cmd:. nq_gps(5) family(nb) link(log) }{p_end}
{phang2}{cmd:. ;}{p_end}
{phang2}{cmd:. #delimit cr}


{title:References}

{phang}
Bia, M., and A. Mattei. 2008.
{browse "http://www.stata-journal.com/sjpdf.html?articlenum=st0150": A Stata package for the estimation of the dose-response function through adjustment for the generalized propensity score}.
{it:Stata Journal} 8: 354-373.

{phang}
Hirano, K., and G. W. Imbens. 2004. The propensity score with continuous
treatments. In
{it:Applied Bayesian Modeling and Causal Inference from Incomplete-Data}
{it:Perspectives}, ed. A. Gelman and X.-L. Meng, 73-84. Chichester, UK:
Wiley.{p_end}


{title:Acknowledgments}

{pstd}
We thank H. Hirano and J. Wooldridge for their helpful
comments and suggestions in an early stage of the work.


{title:Authors}

{pstd}Barbara Guardabascio{p_end}
{pstd}Istat, Italian National Institute of Statistics{p_end}
{pstd}Rome, Italy{p_end}
{pstd}{browse "mailto:guardabascio@istat.it":guardabascio@istat.it}{p_end}

{pstd}Marco Ventura{p_end}
{pstd}Istat, Italian National Institute of Statistics{p_end}
{pstd}Rome, Italy{p_end}
{pstd}{browse "mailto:mventura@istat.it":mventura@istat.it}{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 14, number 1: {browse "http://www.stata-journal.com/article.html?article=st0328":st0328}{p_end}

{p 7 14 2}Help:  {helpb gpscore}, {helpb doseresponse}, {helpb glmdose},
{helpb doseresponse_model} (if installed)
{p_end}
