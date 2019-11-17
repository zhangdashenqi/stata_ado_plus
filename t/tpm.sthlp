{smcl}
{* documented: 10oct2010}{...}
{* revised: 14nov2010}{...}
{* revised: 8nov2011}{...}
{* revised: 25oct2012}{...}
{* revised: 08aug2013}{...}
{cmd:help tpm} {right:also see:  {help tpm postestimation}}
{hline}

{title:Title}

{p2colset 6 13 13 13}{...}
{p2col :tpm {hline 2}}Two-part models{p_end}
{p2colreset}{...}


{title:Syntax}

{phang} Same regressors in first and second parts

{p 8 17 2}
{cmd:tpm}
{it:{help depvar:depvar}}
[{indepvars}]
{ifin}
{weight}
[{cmd:,} {it:{help tpm##tpmoptions:tpm_options}}]


{phang} Different regressors in first and second parts (caution: see {it:{help tpm##remarks:Remarks}} below)

{p 8 17 2}
{cmd:tpm}
{it:equation1} {it:equation2}
{ifin}
{weight}
[{cmd:,} {it:{help tpm##tpmoptions:tpm_options}}]

{pstd}where {it:equation1} and {it:equation2} are specified as

{p 8 12 2}{cmd:(} {depvar} [{cmd:=}] [{indepvars}] {cmd:)}


{marker tpmoptions}{...}
{synoptset 27 tabbed}{...}
{synopthdr :tpm_options}
{synoptline}
{syntab:Model}
{synopt :{opt f:irstpart}({it:{help tpm##foptions:f_options}})}specify the model 
for the first part{p_end}
{synopt :{opt s:econdpart}({it:{help tpm##soptions:s_options}})}specify the model 
for the second part{p_end}

{syntab:SE/Robust}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt conventional},
    {opt r:obust}, {opt cl:uster clustvar}, {opt boot:strap}, or
    {opt jack:knife}{p_end}
{synopt :{opt r:obust}}synonym for {opt vce(robust)}{p_end}
{synopt :{opth cl:uster(clustvar)}}synonym for {opt vce(cluster clustvar)}{p_end}
{synopt :{opt suest}}combine the estimation results of first and second part to derive
a simultaneous (co)variance matrix of the sandwich/robust type{p_end}

{syntab :Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt nocnsr:eport}}do not display constraints{p_end}
{synopt :{it:{help tpm##display_options:display_options}}}control spacing
           and display of omitted variables and base and empty cells{p_end}
{synoptline}
{p 4 6 2}{it:indepvars} may contain factor variables; see {helpb fvvarlist}.
{p_end}
{p 4 6 2}{it:depvar} and {it:indepvars} may
contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2}
{opt bootstrap}, {opt by}, {opt jackknife}, {opt nestreg},
{opt rolling}, {opt statsby}, {opt stepwise}, and {opt svy}
are allowed; see {help prefix}.
{p_end}
{p 4 6 2}Weights are not allowed with the {helpb bootstrap} prefix.{p_end}
{p 4 6 2}{cmd:aweight}s are not allowed with the {helpb jackknife} prefix.
{p_end}
{p 4 6 2}
{opt vce()} and weights are not allowed with the {helpb svy} prefix.
{p_end}
{p 4 6 2}
{opt aweight}s, {opt fweight}s, {opt pweight}s, and {opt iweight}s
are allowed; see {help weight}.{p_end}
{p 4 6 2}
{opt coeflegend} does not appear in the dialog box.{p_end}
{p 4 6 2}
See {helpb tpm_postestimation} for features available after estimation.{p_end}

{marker foptions}{...}
{synoptset 26 tabbed}{...}
{synopthdr :f_options}
{synoptline}
{syntab:Model}
{synopt :{helpb logit} [, {it:{help tpm##logit_options:logit_options}}]} specifies 
the model for the binary, first part outcome as a logistic regression{p_end}
{synopt :{helpb probit} [, {it:{help tpm##probit_options:probit_options}}]} specifies 
the model for the binary, first part outcome as a probit regression{p_end}
{synoptline}
{p2colreset}{...}

{marker soptions}{...}
{synoptset 26 tabbed}{...}
{synopthdr :s_options}
{synoptline}
{syntab:Model}
{synopt :{helpb glm} [, {it:{help tpm##glm_options:glm_options}}]} specifies the 
model for the second part outcome as a generalized linear model{p_end}
{synopt :{helpb regress} [, {it:{help tpm##regress_options:regress_options}}]} 
specifies the model for the continuous, second part outcome as a linear regression 
estimated using OLS{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:tpm} fits a two-part regression model of {it:depvar} on {it:indepvars}.  The 
first part models the probability that {it:depvar}>0 using a binary choice model 
(logit or probit).  The second part models the distribution of {it:depvar} | {it:depvar}>0 
using linear (regress) and generalized linear models (glm).


{title:Options}

{dlgtab:Model}

{phang}
{opt f:irstpart(string)} specifies the first part of the model for a binary outcome.  It 
is not optional.  It should be {cmd:logit} or {cmd:probit}.  Each can be specified 
with its options, except {opt vce()} which should be specified as a {cmd:tpm} option.

{phang}
{opt s:econdpart(string)} specifies the second part of the model for a positive 
outcome.  It is not optional.  It should be {cmd:regress} or {cmd:glm}. Each can be specified 
with options, except {opt vce()} which should be specified as a {cmd:tpm} option.

{dlgtab:SE/Robust}

{phang}
{opt vce(vcetype)} specifies the type of standard error reported, which
includes types that are derived from asymptotic theory, that are robust to
some kinds of misspecification, that allow for intragroup correlation, and
that use bootstrap or jackknife methods; see
{helpb vce_option:[R] {it:vce_option}}.
{p_end}

{pmore}
{cmd:vce(conventional)}, the default, uses the conventionally derived variance
estimators for first and second part models.

{pmore}
Note that options related to the variance 
estimators for both parts must be specified using {cmd:vce(}{it:vcetype}{cmd:)} in the {cmd:tpm} syntax.
Specifying {cmd:vce(robust)} is equivalent to specifying
{cmd:vce(cluster} {it:clustvar}{cmd:)}. 

{phang}
{cmd:suest} combines the estimation results of first and second part to derive
a simultaneous (co)variance matrix of the sandwich/robust type. 
Typical applications of {opt suest} are tests for cross-part
hypotheses using {helpb test} or {helpb testnl}.

{marker logit_options}{...}
{title:Options for the first part: logit}

{dlgtab:Model}

{phang}
{opt noconstant}, {opth offset(varname)},
{opt constraints(constraints)}, {opt collinear}; see
{helpb estimation options:[R] estimation options}.

{phang}
{opt asis} forces retention of perfect predictor variables and their
associated perfectly predicted observations and may produce instabilities in
maximization; see {manhelp probit R}.


{marker maximize_options}{...}
{dlgtab:Maximization}

{phang}
{it:maximize_options}:
{opt dif:ficult}, {opt tech:nique(algorithm_spec)},
{opt iter:ate(#)}, [{cmd:{ul:no}}]{opt lo:g}, {opt tr:ace}, 
{opt grad:ient}, {opt showstep},
{opt hess:ian},
{opt showtol:erance},
{opt tol:erance(#)},
{opt ltol:erance(#)},
{opt nrtol:erance(#)},
{opt nonrtol:erance},
{opt from(init_specs)}; see {manhelp maximize R}.  These options are seldom
used.


{marker probit_options}{...}
{title:Options for the first part: probit}

{dlgtab:Model}

{phang}
{opt noconstant}, {opth offset(varname)},
{opt constraints(constraints)}, {opt collinear}; see
{helpb estimation options:[R] estimation options}.

{phang}
{marker asis}
{opt asis} specifies that all specified variables and observations be retained
in the maximization process.  This option is typically not specified and may
introduce numerical instability.  Normally {cmd:probit} drops variables that
perfectly predict success or failure in the dependent variable along with
their associated observations.  In those cases, the effective coefficient on
the dropped variables is infinity (negative infinity) for variables that
completely determine a success (failure).  Dropping the variable and perfectly
predicted observations has no effect on the likelihood or estimates of the
remaining coefficients and increases the numerical stability of the
optimization process.  Specifying this option forces retention of perfect
predictor variables and their associated observations.

{marker probit_maximize}{...}
{dlgtab:Maximization}

{phang}
{it:maximize_options}:
{opt dif:ficult}, {opt tech:nique(algorithm_spec)},
{opt iter:ate(#)}, [{cmd:{ul:no}}]{opt lo:g}, {opt tr:ace}, 
{opt grad:ient}, {opt showstep},
{opt hess:ian},
{opt showtol:erance},
{opt tol:erance(#)},
{opt ltol:erance(#)},
{opt nrtol:erance(#)},
{opt nonrtol:erance},
{opt from(init_specs)}; see {manhelp maximize R}.  These options are seldom
used.


{marker glm_options}{...}
{title:Options for the second part: glm}

{dlgtab:Model}
{synoptset 23}{...}

{synopt :{opth f:amily(tpm##familyname:familyname)}} specifies the distribution of
{depvar}; {cmd:family(gaussian)} is the default.{p_end}
{synopt :{opth l:ink(tpm##linkname:linkname)}} specifies the link function; the
default is the canonical link for the {cmd:family()} specified.{p_end}

{dlgtab:Model 2}

{phang}
{opt noconstant}, {opth exposure(varname)}, {opt offset(varname)},
{opt constraints(constraints)}, {opt collinear}; see 
{helpb estimation options:[R] estimation options}.
{opt constraints(constraints)} and {opt collinear} are not allowed with 
{opt irls}.

{phang}
{opth mu(varname)} specifies {it:varname} as the initial estimate for the mean
of {depvar}.  This option can be useful with models that experience convergence
difficulties, such as {cmd:family(binomial)} models with power or odds-power
links.  {opt init(varname)} is a synonym.


{phang}
{opt disp(#)} multiplies the variance of {depvar}
by {it:#} and divides the deviance by {it:#}.  The resulting distributions are
members of the quasilikelihood family.

{phang}
{cmd:scale(x2}|{cmd:dev}|{it:#}{cmd:)} overrides the
default scale parameter.  This option is allowed only with Hessian
(information matrix) variance estimates.

{pmore}
By default, {cmd:scale(1)} is assumed for the 
discrete distributions (binomial, Poisson, and negative binomial),
and {cmd:scale(x2)} is assumed for the continuous distributions
(Gaussian, gamma, and inverse Gaussian).

{pmore}
{cmd:scale(x2)} specifies that the scale parameter be set to the Pearson
chi-squared (or generalized chi-squared) statistic divided by the residual
degrees of freedom, which is recommended by McCullagh and Nelder (1989) as a
good general choice for continuous distributions.

{pmore}
{cmd:scale(dev)} sets the scale parameter to the deviance divided by the
residual degrees of freedom.  This option provides an alternative to
{cmd:scale(x2)} for continuous distributions and overdispersed or
underdispersed discrete distributions.

{pmore}
{opt scale(#)} sets the scale parameter to {it:#}.
For example, using {cmd:scale(1)} in {cmd:family(gamma)} models results in
exponential-errors regression.  Additional use of {cmd:link(log)} rather than
the default {cmd:link(power -1)} for {cmd:family(gamma)} essentially
reproduces Stata's {opt streg}, {cmd:dist(exp) nohr} command (see
{manhelp streg ST}) if all the observations are uncensored.


{marker maximize_options}{...}
{dlgtab:Maximization}

{phang}
{opt ml} requests that optimization be carried out using Stata's {opt ml}
commands and is the default.

{phang}
{opt irls} requests iterated, reweighted least-squares (IRLS) optimization of
the deviance instead of Newton-Raphson optimization of the
log likelihood.  If the {opt irls} option is not specified, the optimization
is carried out using Stata's {opt ml} commands, in which case all options of
{opt ml maximize} are also available.

{phang}
{it:maximize_options}:
{opt dif:ficult},
{opt tech:nique(algorithm_spec)},
{opt iter:ate(#)},
[{cmdab:no:}]{opt lo:g},
{opt tr:ace},
{opt grad:ient},
{opt showstep},
{opt hess:ian},
{opt showtol:erance},
{opt tol:erance(#)},
{opt ltol:erance(#)},
{opt nrtol:erance(#)},
{opt nonrtol:erance},
{opt from(init_specs)}; see {manhelp maximize R}. These options are seldom used.

{pmore}
Setting the optimization type to {cmd:technique(bhhh)} resets the default
{it:vcetype} to {cmd:vce(opg)}.

{phang}
{opt fisher(#)} specifies the number of Newton-Raphson steps that
should use the Fisher scoring Hessian or EIM
before switching to the observed information matrix (OIM).  This option is
useful only for Newton-Raphson optimization (and not when using {cmd:irls}).

{phang}
{opt search} specifies that the command search for good starting
values.  This option is useful only for Newton-Raphson optimization (and
not when using {opt irls}).

{marker familyname}{...}
{synoptset 23}{...}
{synopthdr :familyname}
{synoptline}
{synopt :{opt gau:ssian}}Gaussian (normal){p_end}
{synopt :{opt ig:aussian}}inverse Gaussian{p_end}{...}
{synopt :{opt b:inomial}[{it:{help varname:varnameN}}|{it:#N}]}Bernoulli/binomial{p_end}{...}
{synopt :{opt p:oisson}}Poisson{p_end}{...}
{synopt :{opt nb:inomial}[{it:#k}|{cmd:ml}]}negative binomial{p_end}{...}
{synopt :{opt gam:ma}}gamma{p_end}
{synoptline}
{p2colreset}{...}

{marker linkname}{...}
{synoptset 23}{...}
{synopthdr :linkname}
{synoptline}
{synopt :{opt i:dentity}}identity{p_end}
{synopt :{opt log}}log{p_end}
{synopt :{opt l:ogit}}logit{p_end}{...}
{synopt :{opt p:robit}}probit{p_end}{...}
{synopt :{opt c:loglog}}cloglog{p_end}{...}
{synopt :{opt pow:er} {it:#}}power{p_end}
{synopt :{opt opo:wer} {it:#}}odds power{p_end}{...}
{synopt :{opt nb:inomial}}negative binomial{p_end}{...}
{synopt :{opt logl:og}}log-log{p_end}{...}
{synopt :{opt logc}}log-complement{p_end}{...}
{synoptline}
{p2colreset}{...}

{marker regress_options}{...}
{title:Options for the second part: regress}

{dlgtab:Model}

{phang}
{opt log} specifies that the linear regression be estimated on the logarithm of the 
second part, continuous outcome.

{dlgtab:Model 2}

{phang}
{opt noconstant}; see
{helpb estimation options##noconstant:[R] estimation options}. 

{dlgtab:Reporting}

{phang}
{opt level(#)}; see 
{helpb estimation options##level():[R] estimation options}.

{phang}
{opt nocnsreport}; see
     {helpb estimation options##nocnsreport:[R] estimation options}.

{marker display_options}{...}
{phang}
{it:display_options}:
{opt noomit:ted},
{opt vsquish},
{opt noempty:cells},
{opt base:levels},
{opt allbase:levels};
    see {helpb estimation options##display_options:[R] estimation options}.


{marker remarks}{...}
{title:Remarks}
{phang}{cmd:tpm} is designed to estimate models in which the positive outcome 
is continuous. It does not deal with discrete or count outcomes. It also does
not allow {helpb boxcox} or other models that may be appropriate for continuous
outcomes.

{phang}The statistical logic of the two-part model is that there is a vector 
of variables, {it:indepvars}, that explain {it:depvar}. Therefore, variables 
that enter the specification for the first-part should, in general, also enter the 
specification for the second-part. In some situations, there may be legitimate 
theoretical (conceptual) or statistical reasons that lead to different lists of 
independent variables. For completeness, {cmd:tpm} has a syntax that allows for 
different covariates in each equation, but we do not generally recommend the 
use of this. There is typically no justification for different regressors in 
each of the two parts.

 
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse womenwk, clear}{p_end}
{phang2}{cmd:. replace wage = 0 if wage==.}{p_end}

{pstd}Two part model with logit and glm with Gaussian family and identity link{p_end}
{phang2}{cmd:. tpm wage educ age married children, first(logit) second(glm)}{p_end}
  
{pstd}Two part model with probit and glm with gamma family and log link{p_end}
{phang2}{cmd:. tpm wage educ age married children, f(probit) s(glm, fam(gamma) link(log))}{p_end}

{pstd}Two part model with probit and linear regression{p_end}
{phang2}{cmd:. tpm wage educ age married children, f(probit) s(regress)}{p_end}

{pstd}Two part model with probit and linear regression of log({it:depvar>0}){p_end}
{phang2}{cmd:. tpm wage educ age married children, f(probit) s(regress, log)}{p_end}

{pstd}Two part model with different covariates in first and second parts{p_end}
{phang2}{cmd:. tpm (first: wage = educ age children) (second: wage = educ age married), f(probit) s(glm, fam(gamma) link(log))}{p_end}


{title:Saved results}

{pstd}
if {cmd:probit} is specified as first part {cmd:tpm} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N_probit)}}number of observations{p_end}
{synopt:{cmd:e(N_cds_probit)}}number of completely determined successes{p_end}
{synopt:{cmd:e(N_cdf_probit)}}number of completely determined failures{p_end}
{synopt:{cmd:e(k_probit)}}number of parameters{p_end}
{synopt:{cmd:e(k_eq_probit)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(k_eq_model_probit)}}number of equations in model (Wald test){p_end}
{synopt:{cmd:e(k_dv_probit)}}number of dependent variables{p_end}
{synopt:{cmd:e(k_autoCns_probit)}}number of base, empty, and omitted constraints{p_end}
{synopt:{cmd:e(df_m_probit)}}model degrees of freedom{p_end}
{synopt:{cmd:e(r2_p_probit)}}pseudo-R-squared{p_end}
{synopt:{cmd:e(ll_probit)}}log likelihood{p_end}
{synopt:{cmd:e(ll_0_probit)}}log likelihood, contant-only model{p_end}
{synopt:{cmd:e(N_clust_probit)}}number of clusters{p_end}
{synopt:{cmd:e(chi2_probit)}}chi-squared{p_end}
{synopt:{cmd:e(p_probit)}}significance{p_end}
{synopt:{cmd:e(rank_probit)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(ic_probit)}}number of iterations{p_end}
{synopt:{cmd:e(rc_probit)}}return code{p_end}
{synopt:{cmd:e(converged_probit)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(offset_probit)}}offset{p_end}
{synopt:{cmd:e(chi2type_probit)}}{cmd:Wald} or {cmd:LR}; type of model chi-squared test{p_end}
{synopt:{cmd:e(opt_probit)}}type of optimization{p_end}
{synopt:{cmd:e(which_probit)}}{cmd:max} or {cmd:min}; whether optimizer is to perform
                     maximization or minimization{p_end}
{synopt:{cmd:e(ml_method_probit)}}type of {cmd:ml} method{p_end}
{synopt:{cmd:e(user_probit)}}name of likelihood-evaluator program{p_end}
{synopt:{cmd:e(technique_probit)}}maximization technique{p_end}
{synopt:{cmd:e(singularHmethod_probit)}}{cmd:m-marquardt} or {cmd:hybrid}; method
                      used when Hessian is singular{p_end}
{synopt:{cmd:e(crittype_probit)}}optimization criterion{p_end}
{synopt:{cmd:e(asbalanced_probit)}}factor variables {cmd:fvset} as {cmd:asbalanced}{p_end}
{synopt:{cmd:e(asobserved_probit)}}factor variables {cmd:fvset} as {cmd:asobserved}{p_end}

{pstd}
if {cmd:logit} is specified as first part {cmd:tpm} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N_logit)}}number of observations{p_end}
{synopt:{cmd:e(N_cds_logit)}}number of completely determined successes{p_end}
{synopt:{cmd:e(N_cdf_logit)}}number of completely determined failures{p_end}
{synopt:{cmd:e(k_logit)}}number of parameters{p_end}
{synopt:{cmd:e(k_eq_logit)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(k_eq_model_logit)}}number of equations in model Wald test{p_end}
{synopt:{cmd:e(k_dv_logit)}}number of dependent variables{p_end}
{synopt:{cmd:e(k_autoCns_logit)}}number of base, empty, and omitted constraints{p_end}
{synopt:{cmd:e(df_m_logit)}}model degrees of freedom{p_end}
{synopt:{cmd:e(r2_p_logit)}}pseudo-R-squared{p_end}
{synopt:{cmd:e(ll_logit)}}log likelihood{p_end}
{synopt:{cmd:e(ll_0_logit)}}log likelihood, contant-only model{p_end}
{synopt:{cmd:e(N_clust_logit)}}number of clusters{p_end}
{synopt:{cmd:e(chi2_logit)}}chi-squared{p_end}
{synopt:{cmd:e(p_logit)}}significance{p_end}
{synopt:{cmd:e(rank_logit)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(ic_logit)}}number of iterations{p_end}
{synopt:{cmd:e(rc_logit)}}return code{p_end}
{synopt:{cmd:e(converged_logit)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(offset_logit)}}offset{p_end}
{synopt:{cmd:e(chi2type_logit)}}{cmd:Wald} or {cmd:LR}; type of model chi-squared test{p_end}
{synopt:{cmd:e(opt_logit)}}type of optimization{p_end}
{synopt:{cmd:e(which_logit)}}{cmd:max} or {cmd:min}; whether optimizer is to perform
       maximization or minimization{p_end}
{synopt:{cmd:e(ml_method_logit)}}type of {cmd:ml} method{p_end}
{synopt:{cmd:e(user_logit)}}name of likelihood-evaluator program{p_end}
{synopt:{cmd:e(technique_logit)}}maximization technique{p_end}
{synopt:{cmd:e(singularHmethod_logit)}}{cmd:m-marquardt} or {cmd:hybrid}; method
                      used when Hessian is singular{p_end}
{synopt:{cmd:e(crittype_logit)}}optimization criterion{p_end}
{synopt:{cmd:e(asbalanced_logit)}}factor variables {cmd:fvset} as {cmd:asbalanced}{p_end}
{synopt:{cmd:e(asobserved_logit)}}factor variables {cmd:fvset} as {cmd:asobserved}{p_end}

{pstd}
if {cmd:glm} is specified as second part {cmd:tpm} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N_glm)}}number of observations{p_end}
{synopt:{cmd:e(k_glm)}}number of parameters{p_end}
{synopt:{cmd:e(k_eq_glm)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(k_eq_model_glm)}}number of equations in model Wald test{p_end}
{synopt:{cmd:e(k_dv_glm)}}number of dependent variables{p_end}
{synopt:{cmd:e(k_autoCns_glm)}}number of base, empty, and omitted constraints{p_end}
{synopt:{cmd:e(df_m_glm)}}model degrees of freedom{p_end}
{synopt:{cmd:e(df_glm)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(phi_glm)}}scale parameter{p_end}
{synopt:{cmd:e(aic_glm)}}model AIC{p_end}
{synopt:{cmd:e(bic_glm)}}model BIC{p_end}
{synopt:{cmd:e(ll_glm)}}log likelihood, if NR{p_end}
{synopt:{cmd:e(N_clust_glm)}}number of clusters{p_end}
{synopt:{cmd:e(chi2_glm)}}chi-squared{p_end}
{synopt:{cmd:e(p_glm)}}significance{p_end}
{synopt:{cmd:e(deviance_glm)}}deviance{p_end}
{synopt:{cmd:e(deviance_s_glm)}}scaled deviance{p_end}
{synopt:{cmd:e(deviance_p_glm)}}Pearson deviance{p_end}
{synopt:{cmd:e(deviance_ps_glm)}}scaled Pearson deviance{p_end}
{synopt:{cmd:e(dispers_glm)}}dispersion{p_end}
{synopt:{cmd:e(dispers_s_glm)}}scaled dispersion{p_end}
{synopt:{cmd:e(dispers_p_glm)}}Pearson dispersion{p_end}
{synopt:{cmd:e(dispers_ps_glm)}}scaled Pearson dispersion{p_end}
{synopt:{cmd:e(nbml_glm)}}{cmd:1} if negative binomial parameter estimated via ML,
	{cmd:0} otherwise{p_end}
{synopt:{cmd:e(vf_glm)}}factor set by {cmd:vfactor()}, {cmd:1} if not set{p_end}
{synopt:{cmd:e(power_glm)}}power set by {cmd:power()}, {cmd:opower()}{p_end}
{synopt:{cmd:e(rank_glm)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(ic_glm)}}number of iterations{p_end}
{synopt:{cmd:e(rc_glm)}}return code{p_end}
{synopt:{cmd:e(converged_glm)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}


{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(varfunc_glm)}}name of variance function used{p_end}
{synopt:{cmd:e(varfunct_glm)}}{cmd:Gaussian}, {cmd:Inverse Gaussian},
                 {cmd:Binomial}, {cmd:Poisson}, {cmd:Neg. Binomial},
		 {cmd:Bernoulli}, {cmd:Power}, or {cmd:Gamma}{p_end}
{synopt:{cmd:e(varfuncf_glm)}}variance function{p_end}
{synopt:{cmd:e(link_glm)}}name of link function used{p_end}
{synopt:{cmd:e(linkt_glm)}}link title{p_end}
{synopt:{cmd:e(linkf_glm)}}link form{p_end}
{synopt:{cmd:e(m_glm)}}number of binomial trials{p_end}
{synopt:{cmd:e(offset_glm)}}offset{p_end}
{synopt:{cmd:e(chi2type_glm)}}{cmd:Wald} or {cmd:LR}; type of model chi-squared
	test{p_end}
{synopt:{cmd:e(cons_glm)}}set if {cmd:noconstant} specified{p_end}
{synopt:{cmd:e(hac_kernel_glm)}}HAC kernel{p_end}
{synopt:{cmd:e(hac_lag_glm)}}HAC lag{p_end}
{synopt:{cmd:e(opt_glm)}}{cmd:ml} or {cmd:irls}{p_end}
{synopt:{cmd:e(opt1_glm)}}optimization title, line 1{p_end}
{synopt:{cmd:e(opt2_glm)}}optimization title, line 2{p_end}
{synopt:{cmd:e(which_glm)}}{cmd:max} or {cmd:min}; whether optimizer is to perform
                         maximization or minimization{p_end}
{synopt:{cmd:e(ml_method_glm)}}type of {cmd:ml} method{p_end}
{synopt:{cmd:e(user_glm)}}name of likelihood-evaluator program{p_end}
{synopt:{cmd:e(technique_glm)}}maximization technique{p_end}
{synopt:{cmd:e(singularHmethod_glm)}}{cmd:m-marquardt} or {cmd:hybrid}; method used
                          when Hessian is singular{p_end}
{synopt:{cmd:e(crittype_glm)}}optimization criterion{p_end}
{synopt:{cmd:e(asbalanced_glm)}}factor variables {cmd:fvset} as {cmd:asbalanced}{p_end}
{synopt:{cmd:e(asobserved_glm)}}factor variables {cmd:fvset} as {cmd:asobserved}{p_end}


{pstd}
{cmd:tpm} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:tpm}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(estat_cmd)}}program used to implement {cmd:estat}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(gradient)}}gradient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(V_modelbased)}}model-based variance{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample (first part){p_end}
{p2colreset}{...}

