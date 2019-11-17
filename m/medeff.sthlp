{smcl}
{* 15dec2011}{...}
{cmd:help medeff}{right: ({browse "http://www.stata-journal.com/article.html?article=up0036":SJ12-2: st0243_1})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:medeff} {hline 2}}Estimate causal mediation
effects{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:medeff}
{cmd:(}{it:model} {depvar} {varlist}{cmd:)}
{cmd:(}{it:model} {depvar} {varlist}{cmd:)}
{ifin} {weight}{cmd:,}
{opth med:iate(varname)}
{cmd:treat(}{varname} [{it:# #}]{cmd:)}
[{cmdab:sim:s}{cmd:(}{it:#}{cmd:)}
{cmd:seed}{cmd:(}{it:#}{cmd:)}
{cmd:vce}{cmd:(}{help medeff##vcetype:{it:vcetype}}{cmd:)}
{cmdab:l:evel}{cmd:(}{it:#}{cmd:)}
{opth inte:ract(varname)}]

{marker model}{...}
{pstd}
{it:model} in the first set of parentheses specifies the model for the mediator variable.
{it:model} in the second set of parentheses specifies the model for the outcome variable.
Available model types are OLS regression ({helpb regress}), probit
({helpb probit}), and logit ({helpb logit}).
Restrictrictions on observations specified with the {cmd:if} or
{cmd:in} qualifier apply to both models.

{pstd}{cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed;
see {help weight}.


{title:Description}

{pstd} {cmd:medeff} is the workhorse command for estimating mediation
effects for a variety of data types.  For a continuous mediator variable
and a continuous outcome variable, the results will be identical to the
usual Baron and Kenny method.  The command can, however, accommodate
other data types, including binary outcomes and mediators, and calculate
the correct estimates.


{title:Options}

{phang}
{cmd:mediate}{cmd:(}{it:varname}{cmd:)} is required
and specifies the mediating variable to use in the analysis.

{phang} {cmd:treat(}{it:varname} [{it:# #}]{cmd:)} is required and
specifies the treatment variable to use in the analysis, where the
numbers following the treatment name are values to use for the control
and treatment conditions, respectively.  By default, these are set to 0
and 1.

{phang}  
{cmdab:sims(}{it:#}{cmd:)} specifies the number of simulations to
run for the quasi-Bayesian approximation of parameter uncertainty.  The
default is {cmd:sims(1000)}.  Higher values will increase the computational
time.

{phang}                                                      
{cmd:seed(}{it:#}{cmd:)} sets the random-number seed for precise
replicability (though with sufficient {cmd:sims()}, results will be very
similar).  The default value is the current random-number seed.

{marker vcetype}{...}
{phang}                                                      
{cmd:vce(}{it:vcetype}{cmd:)} allows users to specify how the standard
errors will be calculated.  {it:vcetype} may be {opt r:obust},
{opt cl:uster} {it:clustvar}, {opt boot:strap}, or {opt jack:knife}.

{phang}                                                      
{cmd:level(}{it:#}{cmd:)} specifies the confidence level, as a
percentage, for confidence intervals.  The default is {cmd:level(95)} or
as set by {cmd:set level}.

{phang}
{opt interact(varname)} allows for an interaction between the treatment
and mediating variable.  Interaction terms must be specified prior to running
{cmd:medeff} and included in the model for the outcome variable.


{title:Examples}

{phang}{cmd:. medeff (regress M T x) (regress Y T M x), mediate(M) treat(T) sims(1000) seed(1)}{p_end}
{phang}{cmd:. medeff (probit M T x) (regress Y T M x), mediate(M) treat(T) sims(1000)}{p_end}
{phang}{cmd:. medeff (regress M T x) (probit Y T M x), mediate(M) treat(T) sims(1000)}{p_end}
{phang}{cmd:. medeff (regress M T x) (probit Y T M x) if x>0, mediate(M) treat(T) sims(1000) }{p_end}


{title:Remarks}

{pstd} {cmd:medeff} only supports OLS, probit, and logit in either
stage of the analysis thus far.  Any estimation technique other than those
will produce an error.  After conducting mediation analysis, users should
conduct a formal sensitivity analysis and report these results (see
{helpb medsens}).  A requirement for causal mediation analysis is that the same
observations are used in the mediator and outcome regressions.  The command
will automatically restrict samples to do this.


{title:Saved results}

{pstd}{cmd:medeff} saves the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2:Scalars}{p_end}
{synopt:{cmd:r(delta0)}}point estimate for ACME under the
control condition{p_end}
{synopt:{cmd:r(delta1)}}point estimate for ACME under the treatment condition{p_end}
{synopt:{cmd:r(delta0hi)}}upper bound of confidence interval for delta0{p_end}
{synopt:{cmd:r(delta0lo)}}lower bound of confidence interval for delta0{p_end}
{synopt:{cmd:r(delta1hi)}}upper bound of confidence interval for delta1{p_end}
{synopt:{cmd:r(delta1lo)}}lower bound of confidence interval for delta1{p_end}
{synopt:{cmd:r(tau)}}point estimate for total effect{p_end}
{synopt:{cmd:r(tauhi)}}upper bound of confidence interval for tau{p_end}
{synopt:{cmd:r(taulo)}}lower bound of confidence interval for tau{p_end}
{synopt:{cmd:r(zeta0)}}point estimate for ADE under the control condition{p_end}
{synopt:{cmd:r(zeta1)}}point estimate for ADE under the treatment condition{p_end}
{synopt:{cmd:r(zeta0hi)}}upper bound of confidence interval for zeta0{p_end}
{synopt:{cmd:r(zeta0lo)}}lower bound of confidence interval for zeta0{p_end}
{synopt:{cmd:r(zeta1hi)}}upper bound of confidence interval for zeta1{p_end}
{synopt:{cmd:r(zeta1lo)}}lower bound of confidence interval for zeta1{p_end}


{title:Bibliography and sources}

{pstd}
The procedures used for estimation are discussed extensively elsewhere.

{phang}Imai, K., L. Keele, and D. Tingley. 2010.  A general approach to
causal mediation analysis.  {it:Psychological Methods} 15: 309-334.

{phang}Imai, K., L. Keele, D. Tingley, and T. Yamamoto. 2010.  
Causal mediation analysis using R.  In
{it:Advances in Social Science Research Using R}, ed. H. D. Vinod, 129-154.
New York: Springer.{p_end}

{phang}Imai, K., L. Keele, and T. Yamamoto. 2010.  Identification,
inference, and sensitivity analysis for causal mediation effects.
{it:Statistical Sciences} 25: 51-71.

{pstd}Please cite upon use: Hicks, Raymond and Dustin Tingley (2011)
mediation: Stata package for causal mediation analysis. 

{pstd}Also cite the above journal articles that form the theoretical basis of
the package.


{title:Authors}

{pstd}Raymond Hicks{p_end}
{pstd}Niehaus Center for Globalization and Governance{p_end}
{pstd}Princeton University {p_end}
{pstd}Princeton, NJ{p_end}
{pstd}{browse "mailto:rhicks@princeton.edu":rhicks@princeton.edu}{p_end}

{pstd}Dustin Tingley {p_end}
{pstd}Department of Government{p_end}
{pstd}Harvard University{p_end}
{pstd}Cambridge, MA{p_end}
{pstd}{browse "mailto:dtingley@gov.harvard.edu":dtingley@gov.harvard.edu}{p_end}


{title:Also see}

{pstd}Further details about the analytical formulas and algorithms
used in these programs can be found at
{browse "http://imai.princeton.edu/projects/mechanisms.html":http://imai.princeton.edu/projects/mechanisms.html}.

{p 4 14 2}Article:  {it:Stata Journal}, volume 12, number 2: {browse "http://www.stata-journal.com/article.html?article=up0036":st0243_1},{break}
                    {it:Stata Journal}, volume 11, number 4: {browse "http://www.stata-journal.com/article.html?article=st0243":st0243}
{p_end}
