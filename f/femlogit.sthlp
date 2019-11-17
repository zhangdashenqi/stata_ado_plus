{smcl}
{* *! version 1.2.0 9jun2014 17:51}{...}
{cmd:help femlogit}{right: ({browse "http://www.stata-journal.com/article.html?article=st0362":SJ14-4: st0362})}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{cmd:femlogit} {hline 2}}Multinomial (polytomous) logistic regression with fixed effects
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:femlogit} 
{depvar} 
[{indepvars}] 
{ifin}
[{cmd:,} {it:options}]

{synoptset 20}{...}
{synopthdr}
{synoptline}
{synopt :{opth gr:oup(varlist)}}matched group variables; overrides default information from {helpb xtset}{p_end}
{synopt :{opt b:aseoutcome(#)}}value of {depvar} that will be the base outcome{p_end}
{synopt :{cmdab:const:raints(}{it:clist}{cmd:)}}apply specified linear constraints;
  {it:clist} has the form {it:#} [{cmd:-}{it:#}] [{cmd:,} {it:#} [{cmd:-}{it:#}] {it:...}]{p_end}
{synopt :{opt diff:icult}}use a different stepping algorithm in nonconcave regions{p_end}
{synopt :{opt or}}report odds ratios{p_end}
{synopt :{opt r:obust}}Huber-White-sandwich estimator{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:femlogit} fits a multinomial logistic regression with fixed effects as
derived by {help femlogit##Chamberlain.1980:Chamberlain(1980, 231)}.  This
model is an extension of the {help mlogit:standard multinomial logit}
({cmd:mlogit}), the 
{mansection SEM example41g:multinomial logistic regression with random effects},
and the {help clogit:fixed-effects logit} ({cmd:clogit}).  In contrast
to {cmd:mlogit} and multinomial logistic regression with random effects
and similar to {cmd:clogit}, the alternative-specific constants are
specific for each unit that decides between the alternatives.  These
alternative-specific latent propensities for alternatives do not have to
be independent of the controlled independent variables.  The model
extends {cmd:clogit} because more than two outcomes can be modeled as
alternatives.

{pstd}
For a more detailed description, see {help femlogit##Lee.2002:Lee (2002)}
and {help femlogit##Pforr.2013:Pforr (2013)}.


{marker options}{...}
{title:Options}

{phang}
{opth group(varlist)} specifies one or more identifier variables (numeric or
string) for the matched groups.  It overrides default information from 
{helpb xtset}.

{phang}
{opt baseoutcome(#)} specifies the value of {depvar} to use as the base
outcome.  The default is to choose the mode outcome.

{phang}
{cmd:constraints(}{it:clist}{cmd:)} specifies the linear constraints to be
applied during estimation. The default is to perform unconstrained estimation.
{it:clist} has the form {it:#} [{cmd:-}{it:#}] [{cmd:,} {it:#} 
[{cmd:-}{it:#}] ...].

{phang}
{opt difficult} specifies that the "hybrid" method be used in nonconcave
regions of the likelihood function instead of the default "modified Marquardt"
method ({help femlogit##Gould.2010:Gould, Pitblado, and Poi 2010, 15-17}).

{phang}
{opt or} reports the estimated coefficients transformed to odds ratios, that
is, exp(b) rather than b.  Confidence intervals are similarly transformed.
This option affects how results are displayed, not how they are estimated.

{phang}
{opt robust} uses the robust or sandwich estimator of variance.  This is valid
only for quasi-maximum-likelihood interpretation 
({help femlogit##Wooldridge.2010:Wooldridge 2010, 502ff.}).  It can be
interpreted only as heteroskedasticity robustness, not as panel robustness.


{marker examples}{...}
{title:Examples}

{pstd}Setup (see {manlink SEM example41g}){p_end}
{phang2}{cmd:. use http://www.stata-press.com/data/r13/gsem_lineup}{p_end}

{pstd}Restrict to panel groups with less than six observations within
panel group to decrease estimation time{p_end}
{phang2}{cmd:. by suspect, sort: keep if _n < 6}{p_end}

{pstd}Fit multinomial logistic regression with fixed effects{p_end}
{phang2}{cmd:. femlogit chosen suswhite witmale violent, group(suspect)}{p_end}

{pstd}Example with British election panel data{p_end}
{phang2}{cmd:. doedit femlogit_example2.do}{p_end}

{pstd}Example with multilevel data on effect of smoking on birth outcomes{p_end}
{phang2}{cmd:. doedit femlogit_example3.do}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:femlogit} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_drop)}}number of observations dropped{p_end}
{synopt:{cmd:e(N_group_drop)}}number of groups dropped{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(k_eq_model)}}number of equations in overall model test{p_end}
{synopt:{cmd:e(k_dv)}}number of dependent variables{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(r2_p)}}pseudo-R-squared{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(ll_0)}}log likelihood, constant-only model{p_end}
{synopt:{cmd:e(chi2)}}chi-squared{p_end}
{synopt:{cmd:e(p)}}significance{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}
{synopt:{cmd:e(baseout)}}value of {it:depvar} to be treated as the base
	outcome{p_end}
{synopt:{cmd:e(ibaseout)}}index of the base outcome{p_end}
{synopt:{cmd:e(k_out)}}number of outcomes{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:femlogit}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:Wald} or {cmd:LR}; type of model chi-squared
	test{p_end}
{synopt:{cmd:e(vce)}}{cmd:oim} or {cmd:robust}{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:Robust}{p_end}
{synopt:{cmd:e(opt)}}{cmd:moptimize}{p_end}
{synopt:{cmd:e(which)}}{cmd:max}{p_end}
{synopt:{cmd:e(ml_method)}}{cmd:gf2}{p_end}
{synopt:{cmd:e(user)}}{cmd:femlogit_eval_gf2}{p_end}
{synopt:{cmd:e(technique)}}{cmd:nr}{p_end}
{synopt:{cmd:e(crittype)}}{cmd:log likelihood} or {cmd:log pseudolikelihood}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(predict)}}{cmd:_predict}{p_end}
{synopt:{cmd:e(marginsok)}}{cmd:xb}{p_end}
{synopt:{cmd:e(marginsnotok)}}{cmd:stdp stddp}{p_end}
{synopt:{cmd:e(eqnames)}}names of equations{p_end}
{synopt:{cmd:e(group)}}names of {cmd:group()} variables{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(Cns)}}constraints matrix{p_end}
{synopt:{cmd:e(ilog)}}iteration log (up to 20 iterations){p_end}
{synopt:{cmd:e(gradient)}}gradient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(V_modelbased)}}model-based variance{p_end}
{synopt:{cmd:e(out)}}outcome values{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{marker Chamberlain.1980}{...}
{phang}
Chamberlain, G. 1980. Analysis of covariance with qualitative data.
{it:Review of Economic Studies} 47: 225-238.

{marker Gould.2010}{...}
{phang}
Gould, W., J. Pitblado, and B. Poi. 2010. {browse "http://www.stata.com/bookstore/maximum-likelihood-estimation-stata/":{it:Maximum Likelihood Estimation with Stata}}. 4th ed. College Station, TX: Stata Press.

{marker Lee.2002}{...}
{phang}
Lee, M.-J. 2002. {it:Panel Data Econometrics: Methods-of-Moments and Limited Dependent Variables}. San Diego: Academic Press.

{marker Pforr.2013}{...}
{phang}
Pforr, K. 2013. {it:femlogit: Implementation und Anwendung der multinominalen logistischen Regression mit "fixed effects"}, vol. 11 of GESIS-Schriftenreihe. K{c o:}ln: GESIS -- Leibniz-Institut für Sozialwissenschaften.

{marker Wooldridge.2010}{...}
{phang}
Wooldridge, J. M. 2010. {browse "http://www.stata.com/bookstore/econometric-analysis-cross-section-panel-data/":{it:Econometric Analysis of Cross Section and Panel Data}}. 2nd ed. Cambridge, MA: MIT Press.


{title:Author}

{pstd}Klaus Pforr{p_end}
{pstd}GESIS -- Leibniz-Institute for the Social Sciences{p_end}
{pstd}Mannheim, Germany{p_end}
{pstd}klaus.pforr@gesis.org{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 14, number 4: {browse "http://www.stata-journal.com/article.html?article=st0362":st0362}{p_end}
