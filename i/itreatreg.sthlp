{smcl}
{* *! itreatreg version 1.0 August 2010 by Graham K. Brown and Thanos Mergoupis}{...}
{cmd:help itreatreg}{right: ({browse "http://www.stata-journal.com/article.html?article=st0240":SJ11-4: st0240})}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col: {hi:itreatreg} {hline 2}}Treatment-effects model with average treatment
effect corrected for interaction terms on the treatment variable{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:itreatreg}
{depvar}
[{it:indepvars_ni}]
{ifin}{cmd:,}
{cmd:treat(}{it:depvar_t} {cmd:=} {it:indepvars_t} [{cmd:,} {cmdab:noc:onstant}]{cmd:)}
{cmd:x(}{it:xvars} [{cmd:=} {it:indepvars_i}]{cmd:)}
{cmd:gen(}{it:stubname}{cmd:)}
[{it:options}]

{synoptset 15 tabbed}{...}
{synopthdr:options}
{synoptline}
{p2coldent :* {opt treat()}}equation for treatment effects{p_end}
{synopt:{opt noconstant}}treatment equation estimated with constant suppressed{p_end}
{p2coldent :* {opt x()}}equations for interaction terms{p_end}
{p2coldent :* {opt gen()}}{it:stubname} for variables containing corrected predictions{p_end}
{synopt:{opt oos}}out-of-sample prediction{p_end}
{synopt:{opt twostep}}two-step estimation procedure used in place of ML{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt treat()}, {opt x()}, and {opt gen()} are required.{p_end}
{p 4 6 2}{depvar} specifies the dependent variable in the main equation, not
the treatment equation.{p_end}
{p 4 6 2}
{it:indepvars_ni} specifies only the independent variables in
the main equation that are not also interacted with the treatment
variable.  Variables that are included along with an interaction term on
the treatment variable should be specified in the {opt x()} option (see
below).  {it:indepvars_ni} is optional in the sense that one may
wish to estimate a model in which all of the independent variables are
accompanied by equivalent interaction terms with the treatment variable,
in which case this list would be empty.  If a variable that is also
interacted with the treatment effect is included here rather than in the
{opt x()} option, {opt itreatreg} will generate correct estimates on the
coefficients but incorrect predictions and average treatment effect (ATE).


{title:Description}

{pstd}
{opt itreatreg} fits a treatment-effects model and produces corrected
predictions and ATE for equations on the dependent variable with
interaction terms on the treatment variable.  If the equation contains
no interactions with the treatment variable, then {helpb treatreg} is the
appropriate command.  {opt itreatreg} creates two new variables named
{it:stubname}{cmd:ctrt} and {it:stubname}{cmd:cntrt}, containing,
respectively, the corrected prediction in the presence of the treatment
effect and in its absence.  {opt itreatreg} also displays and returns
the corrected ATE.  The computational heart
of the command calls {cmd:treatreg} internally to estimate the
coefficients, so if {helpb predict} or other
{helpb treatreg postestimation} commands are run after {opt itreatreg},
this will produce incorrect predictions.


{title:Options}

{phang}
{cmd:treat(}{it:depvar_t} {cmd:=} {it:indepvars_t} [{cmd:, noconstant}]{cmd:)} 
specifies the equation for the treatment selection, where {it:depvar_t}
is the treatment variable and {it:indepvars_t} is the list of
predictor variables for the treatment, in a manner identical to the
specification in the {cmd:treatreg} command.  It is an integral
part of specifying a treatment-effects model and is required.  The
{cmd:noconstant} option suppresses the constant in the treatment
equation.

{phang}
{cmd:x(}{it:xvars} [{cmd:=} {it:indepvars_i}]{cmd:)}
specifies the
treatment interaction variables {it:xvars} and, optionally, the
original variables {it:indepvars_i} that were interacted with the treatment.
{cmd:x()} is required.  The inclusion of {it:indepvars_i} is optional if one
wishes to include only the interaction term.  At least one {it:xvar} must be
specified, otherwise {cmd:treatreg} itself is appropriate.  Moreover, if the
original variables are included, then they must be specified correctly in
{cmd:x()} and not included in the list of independent variables
{it:indepvars_ni} directly after the dependent variable.  For example,
{cmd:itreatreg y1, treat(y2=x1) x(y2x2) gen(pr)} would fit a simple model in
which an interaction between the treatment variable {cmd:y2} and an independent
variable {cmd:x2} -- that is, {cmd:y2x2} -- is the sole predictor of {cmd:y1},
aside from the treatment variable itself.  Inclusion of the original
independent variable {cmd:x2} in the model must be specified:  {cmd:itreatreg}
{cmd:y1}{cmd:,} {cmd:treat(y2=x1)} {cmd:x(y2x2=x2)} {cmd:gen(pr)}.

{phang}
{cmd:gen(}{it:stubname}{cmd:)} is required and specifies the {it:stubname} for
the two new variables created by {cmd:itreatreg}, {it:stubname}{cmd:ctrt} and
{it:stubname}{cmd:cntrt}, that contain for each observation, respectively, the
predicted value of the dependent variable {it:depvar} in the presence of the
treatment and the predicted value in the absence of the treatment.  This is
analogous to the {cmd:predict} {it:varname}{cmd:, yctrt} and {cmd:predict}
{it:varname}{cmd:, ycntrt} postestimation commands for {cmd:treatreg}, but it
is corrected for the effect of the interaction variables.  Contrary to the
usual {cmd:predict} syntax, the default in {opt itreatreg} is to create
predictions only for those observations used in the estimation process.
Applying the predictions to the entire dataset requires specification of the
{opt oos} option (see below).  If the variable names created by this process
are unavailable (for example, if one specifies {cmd:gen(pr)} when there already
exists a variable named {cmd:prctrt}), then {cmd:itreatreg} will still produce
the estimated coefficients but will not calculate the predicted values or the
ATE.

{phang}
{opt oos} specifies that the predicted values generated by
{cmd:treatreg} -- and hence the calculation of the ATE -- are applied to
all observations in the dataset.  By default, the predictions are
otherwise applied only to those observations included in the estimation
of the coefficients.

{phang}
{opt twostep} specifies that two-step consistent estimates of the
parameters, standard errors, and covariance matrix of the model be
produced instead of the default maximum likelihood estimates.


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse labor}{p_end}
{phang2}{cmd:. generate wc = 0}{p_end}
{phang2}{cmd:. replace wc = 1 if we > 12}{p_end}
{phang2}{cmd:. generate wcXwa = wc*wa}{p_end}
{phang2}{cmd:. generate wcXcit = wc*cit}{p_end}

{p 4 4 2}Obtain estimates with all terms included{p_end}
{p 8 12 2}{cmd:. itreatreg ww, treat(wc=wmed wfed) x(wcXwa=wa wcXcit=cit) gen(p1)}

{p 4 4 2}Obtain estimates with only one interaction term included{p_end}
{p 8 12 2}{cmd:. itreatreg ww wa, treat(wc=wmed wfed) x(wcXcit=cit) gen(p2)}

{p 4 4 2}Obtain estimates with only one of the original independent variables included 
but both interaction terms{p_end}
{p 8 12 2}{cmd:. itreatreg ww, treat(wc=wmed wfed) x(wcXwa wcXcit=cit) gen(p3)}

{p 4 4 2}Obtain estimates with all terms included based on women aged under 30 but with 
predictions applied to the entire dataset{p_end}
{p 8 12 2}{cmd:. itreatreg ww if wa<30, treat(wc=wmed wfed) x(wcXwa=wa wcXcit=cit) gen(p4) oos}


{title:Saved results}

{pstd}
The {helpb treatreg} command called internally saves the following in {cmd:e()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(k_eq_model)}}number of equations in overall model test{p_end}
{synopt:{cmd:e(k_aux)}}number of auxiliary parameters{p_end}
{synopt:{cmd:e(k_dv)}}number of dependent variables{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(lambda)}}lambda{p_end}
{synopt:{cmd:e(selambda)}}standard error of lambda{p_end}
{synopt:{cmd:e(sigma)}}estimate of sigma{p_end}
{synopt:{cmd:e(chi2)}}chi-squared{p_end}
{synopt:{cmd:e(chi2_c)}}chi-squared for comparison test{p_end}
{synopt:{cmd:e(p_c)}}p-value for comparison test{p_end}
{synopt:{cmd:e(p)}}significance{p_end}
{synopt:{cmd:e(rho)}}rho{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:treatreg}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(hazard)}}variable containing hazard{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:Wald} or {cmd:LR}; type of model chi-squared
	test{p_end}
{synopt:{cmd:e(chi2_ct)}}{cmd:Wald} or {cmd:LR}; type of model chi-squared
	test corresponding to {cmd:e(chi2_c)}{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(opt)}}type of optimization{p_end}
{synopt:{cmd:e(which)}}{cmd:max} or {cmd:min}; whether optimizer is to perform maximization or minimization{p_end}
{synopt:{cmd:e(method)}}{cmd:ml} or {cmd:twostep}{p_end}
{synopt:{cmd:e(ml_method)}}type of {cmd:ml} method{p_end}
{synopt:{cmd:e(user)}}name of likelihood-evaluator program{p_end}
{synopt:{cmd:e(technique)}}maximization technique{p_end}
{synopt:{cmd:e(crittype)}}optimization criterion{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(footnote)}}program used to implement the footnote display{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(ilog)}}iteration log (up to 20 iterations){p_end}
{synopt:{cmd:e(gradient)}}gradient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{pstd}
In addition, {opt itreatreg} saves the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(ate)}}ATE{p_end}
{synopt:{cmd:r(te_sd)}}standard deviation of the treatment effect{p_end}
{synopt:{cmd:r(ate)}}number of observations used to generate ATE{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(varctrt)}}name of new variable with predicted values in the presence of treatment{p_end}
{synopt:{cmd:r(varcntrt)}}name of new variable with predicted values in the absence of treatment{p_end}
{p2colreset}{...}


{title:Authors}

{pstd}Graham K. Brown{p_end}
{pstd}Centre for Development Studies{p_end}
{pstd}University of Bath{p_end}
{pstd}Bath, UK{p_end}
{pstd}g.k.brown@bath.ac.uk{p_end}

{pstd}Thanos Mergoupis{p_end}
{pstd}Department of Economics{p_end}
{pstd}University of Bath{p_end}
{pstd}Bath, UK{p_end}
{pstd}a.mergoupis@bath.ac.uk{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 11, number 4: {browse "http://www.stata-journal.com/article.html?article=st0240":st0240}

{p 4 14 2}{space 1}Manual:  {manlink R treatreg}

{p 4 14 2}{space 3}Help:  {manhelp treatreg_postestimation R:treatreg postestimation}, {manhelp heckman R}, {manhelp probit R}, {manhelp regress R}
{p_end}
