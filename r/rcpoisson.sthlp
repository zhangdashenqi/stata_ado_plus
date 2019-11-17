{smcl}
{* *! version 1.2.6  26jun2009}{...}
{cmd:help rcpoisson}{right: ({browse "http://www.stata-journal.com/article.html?article=st0219":SJ11-1: st0219})}
{right:also see:  {help rcpoisson postestimation}}
{hline}

{title:Title}

{p 5 16 2}
{cmd:rcpoisson} {hline 2} Right-censored Poisson regression{p_end}


{title:Syntax}

{p 8 16 2}
{cmd:rcpoisson} {depvar} [{indepvars}] {ifin} {weight}{cmd:,}
{cmd:ul}[{bf:(}{it:#}|{it:varname}{bf:)}] [{it:options}] 

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {cmd:ul}[{cmd:(}{it:#}|{it:varname}{bf:)}]}right-censoring limit{p_end}
{synopt :{opt nocon:stant}}suppress constant term{p_end}
{synopt :{opth e:xposure(varname:varname_e)}}include ln({it:varname_e}) in
model with coefficient constrained to 1{p_end}
{synopt :{opth off:set(varname:varname_o)}}include {it:varname_o} in model with
coefficient constrained to 1{p_end}
{synopt :{cmdab:const:raints(}{it:{help estimation options##constraints():constraints}}{cmd:)}}apply specified linear constraints{p_end}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt oim},
{opt robust}, or {opt cluster} {it:clustvar}{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is
{cmd:level(95)}{p_end}
{synopt :{opt ir:r}}report incidence-rate ratios{p_end}
{synopt :{opt nocnsr:eport}}do not display constraints{p_end}
{synopt :{opt coefl:egend}}display coefficient legend instead of coefficient table{p_end}
{synopt :{it:{help poisson##display_options:display_options}}}control spacing
           and display of omitted variables and base and empty cells{p_end}
{synopt :{it:{help poisson##maximize_options:maximize_options}}}control the maximization process; seldom used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt ul}{bf:(}{it:#}|{it:varname}{bf:)} is required.{p_end}
INCLUDE help fvvarlist
{p 4 6 2}{it:depvar}, {it:indepvars}, {it:varname_e}, and {it:varname_o} may
contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2}{opt bootstrap}, {opt by}, {opt jackknife}, {opt mi estimate}, {opt nestreg}, {opt rolling}, {opt statsby}, and {opt stepwise} are allowed; see {help prefix}.{p_end}
{p 4 6 2}Weights are not allowed with the {helpb bootstrap} prefix.{p_end}
{p 4 6 2}{opt fweight}s, {opt iweight}s, and {opt pweight}s are allowed; see
{help weight}.{p_end}
{p 4 6 2}
See {help rcpoisson_postestimation:rcpoisson postestimation} for features
available after estimation.{p_end}


{title:Description}

{pstd}
{cmd:rcpoisson} fits a right-censored Poisson regression of {depvar} on
{indepvars}, where {it:depvar} is a nonnegative count variable.


{title:Options}

{phang}
{cmd:ul}[{cmd:(}{it:#}|{it:varname}{cmd:)}] indicates the right-censoring limit.  A constant censoring
threshold may be indicated as {cmd:ul(}{it:#}{cmd:)}, in which case
observations with {it:depvar} >= # are censored; or the threshold may be
indicated as {cmd:ul}, in which case
observations with {it:depvar} >= {cmd:max(}{it:depvar}{cmd:)} are censored.  A
variable censoring limit is specified as {cmd:ul(}{it:varname}{cmd:)}, in
which case observations with {it:depvar_i} >= {it:varname_i} are censored.
This is a required option.

{phang}
{opt noconstant},
{opth "exposure(varname:varname_e)"},
{opt offset(varname_o)}, and {opt constraints(constraints)}; see
{helpb estimation options:[R] estimation options}.

{phang}
{cmd:vce(}{it:vcetype}{cmd:)} specifies the type of standard error reported.  Supported options
include {cmd:oim} (the default), {cmd:robust}, and {cmd:cluster} {it:clustvar};
see {manhelpi vce_option R}.

{phang}
{opt level(#)}; see
{helpb estimation options##level():[R] estimation options}.

{phang}
{opt irr} reports estimated coefficients transformed to incidence-rate
ratios, that is, exp(b) rather than b.  Standard errors and confidence
intervals are similarly transformed.  This option affects how results are
displayed, not how they are estimated or stored.  {opt irr} may be specified at
estimation or when replaying previously estimated results.

{phang}
{opt nocnsreport}; see
     {helpb estimation options##nocnsreport:[R] estimation options}.

{phang}
{opt coeflegend}; see
     {helpb estimation options##coeflegend:[R] estimation options}.

{marker display_options}{...}
{phang}
{it:display_options}:
{opt noomit:ted},
{opt vsquish},
{opt noempty:cells},
{opt base:levels}, and
{opt allbase:levels};
    see {helpb estimation options##display_options:[R] estimation options}.

{marker maximize_options}{...}
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
{opt tol:erance(#)}, {opt ltol:erance(#)}, 
{opt nrtol:erance(#)}, {opt nonrtol:erance},  and
{opt from(init_specs)}; see {manhelp maximize R}.  These options are seldom
used.


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto}{p_end}

{pstd}Fit a right-censored Poisson regression{p_end}
{phang2}{cmd:. rcpoisson rep78 price foreign mpg weight, ul(4)}
{p_end}

{phang}Obtain incidence-rate ratios{p_end}
{phang2}{cmd:. rcpoisson, irr}

{phang}Redisplay results, but with 99% confidence intervals{p_end}
{phang2}{cmd:. rcpoisson, level(99) irr}{p_end}


{title:Saved results}

{pstd}
{cmd:rcpoisson} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_rc)}}number of right-censored observations{p_end}
{synopt:{cmd:e(N_unc)}}number of uncensored observations{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(k_eq)}}number of equations{p_end}
{synopt:{cmd:e(k_eq_model)}}number of equations in model Wald test{p_end}
{synopt:{cmd:e(k_dv)}}number of dependent variables{p_end}
{synopt:{cmd:e(k_autoCns)}}number of base, empty, and omitted constraints{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(r2_p)}}pseudo-R-squared{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(ll_0)}}log likelihood, constant-only model{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(chi2)}}chi-squared statistic{p_end}
{synopt:{cmd:e(p)}}significance{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:rcpoisson}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(ulopt)}}contents of {cmd:ul()}{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(offset)}}offset{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:Wald} or {cmd:LR}; type of model chi-squared
	test{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(opt)}}type of optimization{p_end}
{synopt:{cmd:e(which)}}{cmd:max} or {cmd:min}; whether optimizer is to perform
                         maximization or minimization{p_end}
{synopt:{cmd:e(ml_method)}}type of {cmd:ml} method{p_end}
{synopt:{cmd:e(user)}}name of likelihood-evaluator program{p_end}
{synopt:{cmd:e(technique)}}maximization technique{p_end}
{synopt:{cmd:e(singularHmethod)}}{cmd:m-marquardt} or {cmd:hybrid}; method used
                          when Hessian is singular{p_end}
{synopt:{cmd:e(crittype)}}optimization criterion{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(estat_cmd)}}program used to implement {cmd:estat}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{synopt:{cmd:e(asbalanced)}}factor variables {cmd:fvset} as {cmd:asbalanced}{p_end}
{synopt:{cmd:e(asobserved)}}factor variables {cmd:fvset} as {cmd:asobserved}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(Cns)}}constraints matrix{p_end}
{synopt:{cmd:e(ilog)}}iteration log (up to 20 iterations){p_end}
{synopt:{cmd:e(gradient)}}gradient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(V_modelbased)}}model-based variance{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{title:Author}

{pstd}Rafal Raciborski{break}
      StataCorp{break}
      College Station, TX{break}
      rraciborski@stata.com{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 11, number 1: {browse "http://www.stata-journal.com/article.html?article=st0219":st0219}

{p 7 14 2}Help:  {help rcpoisson postestimation},{break}
{manhelp glm R},
{manhelp nbreg R},
{manhelp zip R},
{manhelp ztp R}
{p_end}
