{smcl}
{* *! version 1.1.4  06aug2013}{...}
{cmd:help sfpanel postestimation}{right: ({browse "http://www.stata-journal.com/article.html?article=up0047":SJ15-2: st0315_1})}
{hline}

{title:Title}

{p2colset 5 31 33 2}{...}
{p2col :{hi:sfpanel postestimation} {hline 2}}Postestimation tools for sfpanel{p_end}
{p2colreset}{...}


{title:Description}

{pstd}
The following postestimation commands are available after {cmd:sfpanel}:

{synoptset 13}{...}
{p2coldent :command}description{p_end}
{synoptline}
{synopt :{helpb estat}}AIC, BIC, VCE, and estimation sample summary{p_end}
INCLUDE help post_estimates
INCLUDE help post_lincom
INCLUDE help post_lrtest
INCLUDE help post_margins
INCLUDE help post_nlcom
{synopt :{helpb sfpanel postestimation##predict:predict}}predictions, residuals, influence statistics, and other diagnostic measures{p_end}
INCLUDE help post_predictnl
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}


{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:statistic}]

{p 8 16 2}
{cmd:predict} {dtype}
{c -(}{it:stub}{cmd:*}{c |}{it:newvar_xb} {it:newvar_v} {it:newvar_u}{c )-}
{ifin}{cmd:,}
{opt sc:ores}

{synoptset 15}{...}
{synopthdr :statistic}
{synoptline}
{synopt :{opt xb}}linear prediction; the default{p_end}
{synopt :{opt stdp}}standard error of the prediction{p_end}
{synopt :{opt u}}estimates of (technical or cost) inefficiency via E(u|e) (Jondrow et al. 1982){p_end}
{synopt :{opt u0}}estimates of (technical or cost) inefficiency via E(u|e) when the random effect is zero; only after {cmd:model(tre)}{p_end}
{synopt :{opt m}}estimates of (technical or cost) inefficiency via M(u|e){p_end}
{synopt :{opt jlms}}estimates of (technical or cost) efficiency via exp{-E(u|e)}{p_end}
{synopt :{opt bc}}estimates of (technical or cost) efficiency via E{exp(-u|e)} (Battese and Coelli 1988){p_end}
{synopt :{opt ci}}estimates of confidence interval for (technical or cost) inefficiency and efficiency{p_end}
{synopt :{opt marginal}}marginal effects of the exogenous determinants on the unconditional mean and variance of the inefficiency{p_end}
{synopt :{opt trunc(tlevel)}}truncation of estimated efficiency and inefficiency{p_end}
{synopt :{opt scores}}calculates score variables{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
These statistics are only available for the estimation sample.


{title:Options for predict}

{phang}
{opt xb}, the default, calculates the linear prediction.

{phang}
{opt stdp} calculates the standard error of the linear prediction.

{phang}
{opt u} produces estimates of (technical or cost) inefficiency via E(u|e)
using the estimator of Jondrow et al. (1982).

{phang}
{opt u0} produces estimates of (technical or cost) inefficiency via
E(u|e) using the estimator of Jondrow et al. (1982) when the random effect is
zero.  This statistic is allowed only when the estimation is performed with
the {cmd:model(tre)} option.

{phang}
{opt m} produces estimates of (technical or cost) inefficiency via
M(u|e), the mode of the conditional distribution u|e.  This statistic is not
allowed when the estimation is performed with the option {cmd:model(fels)},
{cmd:model(fecss)}, {cmd:model(fe)}, or {cmd:model(regls)}.

{phang}
{opt jlms} produces estimates of (technical or cost) efficiency via
exp{-E(u|e)}.

{phang}
{opt bc} produces estimates of (technical or cost) efficiency via
E{exp(-u|e)} using the estimator of Battese and Coelli (1988).  This statistic
is not allowed when the estimation is performed with the option
{cmd:model(fecss)}, {cmd:model(fels)}, {cmd:model(fe)}, or {cmd:model(regls)}.

{phang}
{opt ci} computes the confidence interval using the approach proposed
by Horrace and Schmidt (1996).  This option can be used only with the
{cmd:u}, {opt jlms}, or {opt bc} statistic but not when the estimation
is performed with {cmd:model(fels)}, {cmd:model(bc92)},
{cmd:model(kumb90)}, {cmd:model(fecss)}, {cmd:model(fe)}, or
{cmd:model(regls)}.  The default is {cmd:level(95)}, or a 95%
confidence interval.  If the option {opt level(#)} is used in the
previous estimation command, the confidence interval will be computed
using the {it:#} level.  This option creates two additional variables:
{it:newvar_LBcilevel} and {it:newvar_UBcilevel}, the lower and
the upper bound, respectively.

{phang}
{opt marginal} calculates the marginal effects of the exogenous
determinants on E(u) and Var(u) using the approach proposed by Wang
(2002).  The marginal effects are observation specific and are saved in
the new variables {it:{help varname:varname_m_M}} and {it:varname_u_V},
the marginal effects on the unconditional mean and the variance of
inefficiency, respectively.  {it:varname_m} and {it:varname_u} are the names
of each exogenous determinant specified in options 
{cmd:emean(}{it:{help varlist:varlist_m}}[{cmd:,} {opt noconstant}]{cmd:)} 
and {cmd:usigma(}{it:varlist_u}[{cmd:,} {opt noconstant}]{cmd:)}.
{opt marginal} can be used only if the estimation is performed with
the {cmd:model(bc95)} option or if the inefficiency in {cmd:model(tfe)} or
{cmd:model(tre)} is {cmd:distribution(tnormal)}.  When they are both
specified, {it:varlist_m} and {it:varlist_u} must contain the same
variables in the same order.  This option can be specified in two ways:
i) together with {opt u}, {opt m}, {opt jlms}, or {opt bc}; and ii)
alone without specifying {it:newvar}.

{phang}
{opt trunc(tlevel)} excludes from the inefficiency estimation the
units whose effects are, at least at one time period, in the upper and
bottom {it:tlevel}% range.  {opt trunc()} can be used only if the
estimation is performed with {cmd:model(fe)}, {cmd:model(regls)},
{cmd:model(fecss)}, and {cmd:model(fels)}.

{phang}
{opt scores} calculates score variables.  This option is not
allowed when the estimation is performed with the option
{cmd:model(fecss)}, {cmd:model(fels)}, {cmd:model(fe)}, or
{cmd:model(regls)}.  When the argument of the option {cmd:model()} is
{opt tfe} or {opt bc95}, scores are defined as the derivative of the
objective function with respect to the 
{help mf_moptimize##def_parameter:parameters}.  When the argument of the
option {cmd:model()} is {opt tre}, {opt bc88}, {opt bc92}, {opt kumb90},
or {opt pl81}, they are generated as the derivative of the objective
function with respect to the {help mf_moptimize##def_K:coefficients}.
This difference is due to the different {opt moptimize()} 
{it:evaluator type} used to implement the estimators (see 
{helpb mata moptimize()}).


{title:Remarks}

{pstd}When the {cmd:sfpanel} command is used to estimate production frontiers,
{cmd:predict} will provide the postestimation of technical (in)efficiency,
while when the {cmd:sfpanel} command is used to estimate cost frontiers,
{cmd:predict} will provide the postestimation of cost (in)efficiency.  It is
worth noting that {cmd:sfpanel} and the related {cmd:predict} command follow
the definitions of technical and cost (in)efficiency given in Kumbhakar and
Lovell (2000).{p_end}


{title:Examples}

{pstd}True fixed-effects model (Greene 2005){p_end}
{phang2}{cmd:. webuse xtfrontier1}{p_end}
{phang2}{cmd:. sfpanel lnwidgets lnworkers lnmachines, m(tfe) usigma(lnworkers) robust}{p_end}

{pstd}Linear prediction{p_end}
{phang2}{cmd:. predict xb}

{pstd}Technical inefficiency{p_end}
{phang2}{cmd:. predict ineffmean, u}{p_end}
{phang2}{cmd:. predict ineffmode, m}{p_end}

{pstd}Technical efficiency{p_end}
{phang2}{cmd:. predict jlms, jlms}{p_end}

{pstd}Technical efficiency and inefficiency confidence intervals{p_end}
{phang2}{cmd:. predict ineffmean, u ci}{p_end}
{phang2}{cmd:. predict bc, bc ci}{p_end}
{phang2}{cmd:. predict jlms, jlms ci}{p_end}

{pstd}Nonmonotonic marginal effects{p_end}
{phang2}{cmd:. webuse xtfrontier1, clear}{p_end}
{phang2}{cmd:. sfpanel lnwidgets lnworkers lnmachines, m(tfe) d(tnormal) e(lnworkers) u(lnworkers) robust}{p_end}
{phang2}{cmd:. predict, marginal}{p_end}

{pstd}Score variables{p_end}
{phang2}{cmd:. predict score*, scores}{p_end}


{title:References}

{phang}
Battese, G. E., and T. J. Coelli. 1988. Prediction of firm-level
technical efficiencies with a generalized frontier production function and
panel data.  {it:Journal of Econometrics} 38: 387-399.

{phang}
Greene, W.  2005.  Reconsidering heterogeneity in panel data estimators
of the stochastic frontier model.  {it:Journal of Econometrics} 126: 269-303.

{phang}
Horrace, W. C., and P. Schmidt. 1996. Confidence statements for
efficiency estimates from stochastic frontier models. 
{it:Journal of Productivity Analysis} 7: 257-282.

{phang}
Jondrow, J., C. A. K. Lovell, I. S. Materov, and P. Schmidt. 1982. On
the estimation of technical inefficiency in the stochastic frontier production
function model.  {it:Journal of Econometrics} 19: 233-238.

{phang}
Kumbhakar, S. C., and C. A. K. Lovell. 2000. 
{it:Stochastic Frontier Analysis}.  Cambridge: Cambridge University Press.

{phang}
Wang, H.-J. 2002. Heteroscedasticity and non-monotonic efficiency
effects of a stochastic frontier model.  {it:Journal of Productivity Analysis}
18: 241-253.


{title:Authors}

{pstd}Federico Belotti{p_end}
{pstd}Centre for Economic and International Studies{p_end}
{pstd}University of Rome Tor Vergata{p_end}
{pstd}Rome, Italy{p_end}
{pstd}federico.belotti@uniroma2.it{p_end}

{pstd}Silvio Daidone{p_end}
{pstd}Centre for Health Economics{p_end}
{pstd}University of York{p_end}
{pstd}York, UK{p_end}
{pstd}silvio.daidone@york.ac.uk{p_end}

{pstd}Vincenzo Atella{p_end}
{pstd}Centre for Economic and International Studies{p_end}
{pstd}University of Rome Tor Vergata{p_end}
{pstd}Rome, Italy{p_end}
{pstd}atella@uniroma2.it{p_end}

{pstd}Giuseppe Ilardi{p_end}
{pstd}Economic and Financial Statistics Department{p_end}
{pstd}Bank of Italy{p_end}
{pstd}Rome, Italy{p_end}
{pstd}giuseppe.ilardi@bancaditalia.it{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 15, number 2: {browse "http://www.stata-journal.com/article.html?article=up0047":st0315_1},{break}
                    {it:Stata Journal}, volume 13, number 4: {browse "http://www.stata-journal.com/article.html?article=st0315":st0315}

{p 7 14 2}Help:  {helpb sfpanel}, {helpb sfcross},
{help sfcross postestimation} (if installed)
{p_end}
