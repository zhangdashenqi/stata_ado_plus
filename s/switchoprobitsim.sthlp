{smcl}
{* *! version 1.0.0 3jun2014}{...}
{cmd: help switchoprobitsim}{right: ({browse "http://www.stata-journal.com/article.html?article=st0402":SJ15-3: st0402})}
{hline}

{title:Title}

{p2colset 5 25 27 2}{...}
{p2col :{hi:switchoprobitsim} {hline 2}}Estimate effect of potentially
endogenous binary treatment on discrete, ordered outcome
{p2colreset}{...}


{title:Syntax}

{p 8 24 2}
{cmdab:switchoprobitsim}
{it:depvar} [{it:indepvars}]
{ifin}
{weight}{cmd:,} {opt treat:ment(depvar_t = [varlist_t])}
{opt sim:ulationdraws(#)}
[{opt facdens:ity(string)} {opt facsc:ale(real)} {opt facsk:ew(real)}
{opt start:point(integer)} {opt facm:ean(real)} {opt vce(string)}
{opt sesim:ulations(integer)} {opt mixpi(integer)}]

{phang}
{cmd:pweight}s, {cmd:fweight}s, and {cmd:iweight}s are allowed; see 
{help weight}.


{title:Description}

{pstd}
{cmd:switchoprobitsim} fits a model in which {cmd:treatment()} is a binary
indicator for a treatment ({it:y_treat}) for which selection is believed
to be correlated with the outcome of interest, {it:y_ordered}.  The model
assumes that the unobservables in treatment and outcome equations follow the
distribution specified in {cmd:facdensity()} and that outcomes for treated and
untreated groups are distinct.  (A test for the hypothesis that the treated
and untreated groups belong to one outcome regime is reported as part of the
standard output.)  Parameters of the model are estimated by maximum simulated
likelihood.


{title:Options}

{phang}
{opt treatment(depvar_t = [varlist_t])} specifies the participation index
(coded as zero or one).  {cmd:treatment()} is required.

{phang}
{opt simulationdraws(#)} specifies the number of draws from the distribution
of the latent factor.  {cmd:simulationdraws()} is required.

{phang}
{opt facdensity(string)} specifies the density of the latent factor.
{it:string} may be {cmd:normal}, {cmd:uniform}, {cmd:logit}, {cmd:chi2},
{cmd:lognormal}, {cmd:gamma}, or {cmd:mixture}.  The default is
{cmd:facdensity(normal)}.  {cmd:mixture} produces eta as a two-factor mixture
of normals.  The mixing proportion for N(0,1) is specified by {cmd:mixpi()} as
an integer between 0 and 100.  For this option, {cmd:facmean()} and
{cmd:facscale()} specify the mean and scale, respectively, of a component to
be mixed with N(0,1).

{phang}
{opt facscale(real)} specifies the scale of the latent factor distribution.
The default is {cmd:facscale(1)}.

{phang}
{opt facskew(real)} specifies the skewness of the latent factor distribution
for use with {cmd:facdensity(chi2)}.  The default is {cmd:facskew(2)}.

{phang}
{opt startpoint(integer)} specifies the starting point for the Halton-sequence
draws that are used to simulate the latent factor distribution.  The default
is {cmd:startpoint(5)}.

{phang}
{opt facmean(real)} is particularly useful with the {cmd:gamma} distribution
option; because all the latent factors are normalized to mean zero, this
parameter essentially controls the skewness of the gamma distribution used.

{phang}
{opt vce(string)} specifies how to estimate the variance-covariance matrix
corresponding to the parameter estimates.  {cmd:cluster} {it:clustvar}
specifies the cluster standard errors using {it:clustvar}. {opt robust}
computes the robust variance-covariance matrix.

{phang}
{opt sesimulations(integer)} specifies the number of draws of the parameter
vector to be used in computing standard errors of average treatment effects
and average treatment effect on the treated.  The default is
{cmd:sesimulations(100)}.

{phang}
{opt mixpi(integer)} specifies the mixing proportion for a two-component
mixture of normals.  The default is {cmd:mixpi(50)}.


{title:Examples}

{pstd}
Order self-assessed health ({bf:sah}) on a 1-5 scale (excellent, very
good, good, fair, poor), and let {bf:mcd} be an indicator of participation in
Medicaid{p_end}
{phang2}{cmd:. use nhisdataex}{p_end}
{phang2}{cmd:. switchoprobitsim sah female married, treatment(mcd=female married) simulationdraws(200) facdensity(logit) vce(robust)}{p_end}
{phang2}{cmd:. switchoprobitsim sah female married [pweight=normwgt], treatment(mcd=female married) simulationdraws(200) facdensity(logit) vce(robust)}{p_end}


{title:Author}

{pstd}Christian A. Gregory{p_end}
{pstd}Economic Research Service, USDA{p_end}
{pstd}Washington, DC{p_end}
{pstd}cgregory@ers.usda.gov{p_end}


{marker also_see}{...}
{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 15, number 3: {browse "http://www.stata-journal.com/article.html?article=st0402":st0402}

{p 7 14 2}Help:  {helpb switchoprobitsim postestimation} (if installed)
{p_end}
