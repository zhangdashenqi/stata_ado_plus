{smcl}
{* 2014-08-06 scott long & jeremy freese}{...}
{title:Title}

{p2colset 5 16 16 1}{...}
{p2col:{cmd:fitstat} {hline 2}}Scalar measures of fit for regression models{p_end}
{p2colreset}{...}


{title:General syntax}


{p 4 18 2}
{cmd:fitstat}{cmd:,}  [ {opt save} {opt dif:f} {opt s:aving(name)} {opt u:sing(name)} {opt force} {opt ic} ]
{p_end}

{marker overview}
{title:Overview}

{pstd}
{cmd:fitstat} is a post-estimation command that computes measures
of fit for the following regression models: {cmd:clogit}, {cmd:cloglog},
{cmd:intreg}, {cmd:logistic}, {cmd:logit}, {cmd:mlogit}, {cmd:nbreg},
{cmd:ocratio}, {cmd:ologit}, {cmd:oprobit}, {cmd:poisson}, {cmd:probit},
{cmd:regress}, {cmd:tnbreg}, {cmd:tpoisson}, {cmd:zinb}, {cmd:zip},
{cmd:ztnb}, {cmd:ztp}.
With the {opt save} and {opt diff} options
(or {opt s:aving()} and {opt u:sing()}),
{cmd:fitstat} compares fit measures for two models.
{p_end}

{pstd}
For all models, {cmd:fitstat} reports the log-likelihoods of the full and
intercept-only models, the deviance (D), the likelihood ratio or Wald chi-square,
 Akaike's Information Criterion (AIC), AIC/N, and the Bayesian Information
Criterion (BIC).
{p_end}

{pstd}
Except for {cmd:regress}, {cmd:fitstat} reports
McFadden's R2, McFadden's adjusted R2, the maximum likelihood R2,
and Cragg & Uhler's R2.
These measures equal R2 for OLS regression.
{cmd:fitstat} reports R2 and the adjusted R2 after {cmd:regress}.
{cmd:fitstat} reports the regular and adjusted count R2 for
models with categorical outcomes.
For ordered or binary logit or probit models, as well as models for censored
data ({cmd:tobit}, {cmd:cnreg}, or {cmd:intreg}),
it reports McKelvey and Zavoina's R2.
In addition, it reports Efron's R2 for {cmd:logit} or {cmd:probit},
and reports Tjur's Coefficient of Discrimination for binary outcome models.
{p_end}

{pstd}
Not all measures are provided for models estimated with pweights or iweights.
{p_end}


{title:Options}
{p2colset 5 18 19 0}
{synopt:{opt save}} saves the computed measures in a matrix for subsequent
comparisons.
{p_end}
{p2colset 5 18 19 0}
{synopt:{opt s:aving(name)}} is equivalent to {cmd:save} but allows
you to save the current model with a name of 16 characters of less.
{p_end}
{p2colset 5 18 19 0}
{synopt:{opt dif:f}} compares the fit measures for the current model
(i.e., the model in memory) with those saved using {cmd: save}.  If a
likelihood-ratio test comparing the two models is permitted by Stata's
{help lrtest:lrtest} command, the results will be presented in the row labeled
"p-value".
{p_end}
{p2colset 5 18 19 0}
{synopt:{opt u:sing(name)}} is equivalent to {opt diff}
but allow you to refer to saved results by name used with {cmd: saving()}.
{p_end}
{p2colset 5 18 19 0}
{synopt:{opt force}} will provide comparisons and likelihood-ratio test results
even if number of observations differs or other differences suggest the comparison
is invalid.
{p_end}
{p2colset 5 18 19 0}
{synopt:{opt ic}} only presents information measures.
{p_end}


{title:Examples}

{pstd}{ul:{bf:Compute fit statistics for a single model}}{p_end}

{phang2}{cmd:. use mroz,clear}{p_end}
{phang2}{cmd:. logit lfp k5 k618 age wc hc lwg inc}{p_end}
{phang2}{cmd:. fitstat}
{p_end}

{pstd}{ul:{bf:Obtain AIC and BIC measures only}}{p_end}

{phang2}{cmd:. fitstat, ic}
{p_end}

{pstd}{ul:{bf:Compare fit statistics for models}}{p_end}

{phang2}{cmd:. logit lfp k5 k618 age wc hc lwg inc}{p_end}
{phang2}{cmd:. fitstat, save}{p_end}
{phang2}{cmd:. logit lfp k5 k618 age age2 wc hc lwg inc}{p_end}
{phang2}{cmd:. fitstat, diff}
{p_end}

{pstd}{ul:{bf:Compare fit statistics with named models}}{p_end}

{phang2}{cmd:. logit lfp k5 k618 age age2 wc hc lwg inc}{p_end}
{phang2}{cmd:. fitstat, saving(agesq)}{p_end}
{phang2}{cmd:. logit lfp k5 k618 age wc hc lwg inc}{p_end}
{phang2}{cmd:. fitstat, using(agesq)}
{p_end}

INCLUDE help spost13_footer
