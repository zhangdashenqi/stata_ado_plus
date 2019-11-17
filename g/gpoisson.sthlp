{smcl}
{* *! version 1.0.0  17jun2011}{...}
{cmd:help gpoisson}{right:dialogs:  {dialog gpoisson}  {dialog gpoisson, message(-svy-) name(svy_gpoisson):svy: gpoisson}}
{right: ({browse "http://www.stata-journal.com/article.html?article=st0279":SJ12-4: st0279})}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{hi:gpoisson} {hline 2}}Generalized Poisson regression{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:gpoisson} {depvar} [{indepvars}] {ifin} {weight} [{cmd:,}
{it:options}] 

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Model}
{synopt :{opt nocon:stant}}suppress constant term{p_end}
{synopt :{opth e:xposure(varname:varname_e)}}include ln({it:varname_e}) in
model with coefficient constrained to 1{p_end}
{synopt :{opth off:set(varname:varname_o)}}include {it:varname_o} in model with
coefficient constrained to 1{p_end}
{synopt :{cmdab:const:raints(}{it:{help estimation options##constraints():constraints}}{cmd:)}}apply specified linear constraints{p_end}
{synopt:{opt col:linear}}keep collinear variables{p_end}

{syntab :SE/Robust}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt oim},
{opt r:obust}, {opt cl:uster} {it:clustvar},
{opt opg}, {opt boot:strap}, or {opt jack:knife}{p_end}

{syntab :Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is
{cmd:level(95)}{p_end}
{synopt :{opt ir:r}}report incidence-rate ratios{p_end}
{synopt :{opt nocnsr:eport}}do not display constraints{p_end}
{synopt :{it:{help gpoisson##display_options:display_options}}}control
column formats, row spacing, line width, and display of omitted
variables and base and empty cells{p_end}

{syntab :Maximization}
{synopt :{it:{help gpoisson##maximize_options:maximize_options}}}control the maximization process; seldom used{p_end}
{synopt :{opt coefl:egend}}display legend instead of statistics{p_end}
{synoptline}
{p2colreset}{...}
INCLUDE help fvvarlist
{p 4 6 2}{it:depvar}, {it:indepvars}, {it:varname_e}, and {it:varname_o} may
contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2}{opt bootstrap}, {opt by}, {opt fracpoly}, {opt jackknife},
{opt mfp}, {opt mi estimate}, {opt nestreg}, {opt rolling}, {opt statsby},
{opt stepwise}, and {opt svy} are allowed; see {help prefix}.{p_end}
INCLUDE help vce_mi
{p 4 6 2}Weights are not allowed with the {helpb bootstrap} prefix.{p_end}
{p 4 6 2}{opt vce()} and weights are not allowed with the {helpb svy} prefix.
{p_end}
{p 4 6 2}{opt fweight}s, {opt iweight}s, and {opt pweight}s are allowed; see
{help weight}.{p_end}
{p 4 6 2}
See {helpb gpoisson postestimation} for features
available after estimation.{p_end}


{title:Description}

{pstd}{cmd:gpoisson} fits a generalized Poisson regression of {depvar}
on {indepvars}, where {it:depvar} is a nonnegative count variable.

{pstd}If you have overdispersed panel data, see {manhelp xtnbreg XT}.


{title:Options}

{dlgtab:Model}

{phang}{opt noconstant}, {opth "exposure(varname:varname_e)"}, 
{opt offset(varname_o)}, {opt constraints(constraints)}, 
{opt collinear}; see {helpb estimation options:[R] estimation options}.

{dlgtab:SE/Robust}

INCLUDE help vce_asymptall

{dlgtab:Reporting}

{phang}{opt level(#)}; see 
{helpb estimation options##level():[R] estimation options}.

{phang}{opt irr} reports estimated coefficients transformed to
incidence-rate ratios, that is, exp(b) rather than b.  Standard errors
and confidence intervals are similarly transformed.  This option affects
how results are displayed, not how they are estimated or stored.
{cmd:irr} may be specified at estimation or when replaying previously
estimated results.

{phang}{opt nocnsreport}; see 
{helpb estimation options##nocnsreport:[R] estimation options}.

{marker display_options}{...}
{phang}{it:display_options}:  {opt noomit:ted}, {opt vsquish}, 
{opt noempty:cells}, {opt base:levels}, {opt allbase:levels}; see 
{helpb estimation options##display_options:[R] estimation options}.

{marker maximize_options}{...}
{dlgtab:Maximization}

{phang}{it:maximize_options}:  {opt dif:ficult}, 
{opt tech:nique(algorithm_spec)}, {opt iter:ate(#)}, 
[{cmdab:no:}]{opt lo:g}, {opt tr:ace}, {opt grad:ient}, {opt showstep},
{opt hess:ian}, {opt showtol:erance}, {opt tol:erance(#)}, 
{opt ltol:erance(#)}, {opt nrtol:erance(#)}, {opt nonrtol:erance}, 
{opt from(init_specs)}; see {manhelp maximize R}.  These options are
seldom used.

{pmore}Setting the optimization type to {cmd:technique(bhhh)} resets the
default {it:vcetype} to {cmd:vce(opg)}.

{pstd}The following option is available with {opt gpoisson} but is not
shown in the dialog box:

{phang}{opt coeflegend}; see 
{helpb estimation options##coeflegend:[R] estimation options}.


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse dollhill3}{p_end}

{pstd}Fit a generalized Poisson regression{p_end}
{phang2}{cmd:. gpoisson deaths smokes i.agecat, exposure(pyears)}
{p_end}

{phang}Obtain incidence-rate ratios{p_end}
{phang2}{cmd:. gpoisson deaths smokes i.agecat, exposure(pyears) irr}

{phang}Redisplay results, but with 99% confidence intervals{p_end}
{phang2}{cmd:. gpoisson, level(99) irr}{p_end}


{title:Saved results}

{pstd}{cmd:gpoisson} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(k_eq_model)}}number of equations in overall model test{p_end}
{synopt:{cmd:e(k_dv)}}number of dependent variables{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(r2_p)}}pseudo-R-squared{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(ll_0)}}log likelihood, constant-only model{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(chi2)}}chi-squared{p_end}
{synopt:{cmd:e(p)}}significance{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:gpoisson}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
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


{title:Authors}

{pstd}Tammy Harris{p_end}
{pstd}Institute for Families in Society{p_end}
{pstd}Department of Epidemiology and Biostatistics{p_end}
{pstd}University of South Carolina{p_end}
{pstd}Columbia, SC{p_end}
{pstd}harris68@mailbox.sc.edu{p_end}

{pstd}Zhao Yang{p_end}
{pstd}Quintiles, Inc.{p_end}
{pstd}Morrisville, NC{p_end}
{pstd}tonyyangsxz@gmail.com{p_end}

{pstd}James W. Hardin{p_end}
{pstd}Institute for Families in Society{p_end}
{pstd}Department of Epidemiology and Biostatistics{p_end}
{pstd}University of South Carolina{p_end}
{pstd}Columbia, SC{p_end}
{pstd}jhardin@sc.edu{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 12, number 4: {browse "http://www.stata-journal.com/article.html?article=st0279":st0279}

{p 5 14 2}Manual:  {manlink R poisson} {manlink R nbreg}

{p 7 14 2}Help:  {helpb gpoisson postestimation},{break}
{manhelp glm R},
{manhelp poisson R},
{manhelp nbreg R},
{manhelp svy_estimation SVY:svy estimation},
{manhelp tpoisson R},
{manhelp xtpoisson XT},
{manhelp xtnbreg XT},
{manhelp zip R}{p_end}
