{smcl}
{* *! version 1.0 - 22 June 2016}{...}
{cmd:help pvarsoc}{right: ({browse "http://www.stata-journal.com/article.html?article=st0455":SJ16-3: st0455})}
{hline}

{title:Title}

{p 5 18 2}
{bf:pvarsoc} {hline 2} Obtain lag-order selection statistics for panel VAR
estimated using GMM


{title:Syntax}

{p 8 17 2}
{cmd:pvarsoc} 
{depvarlist}
{ifin} 
[{cmd:,} {it:options}]

{synoptset 20}{...}
{synopthdr}
{synoptline}
{synopt:{opt m:axlag(#)}}set maximum lag order to {it:#}; default is {cmd:maxlag(4)}{p_end}
{synopt:{opth pinstl:ag(numlist)}}override default lag order of {it:depvarlist} used as instruments{p_end}
{synopt:{opth pvaro:pts(pvar:options)}}pass {it:options} to {cmd:pvar}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
This command uses {cmd:pvar}.  You must {cmd:xtset } your data before using
{cmd:pvarsoc}; see {manhelp xtset XT}.{p_end}


{title:Description}

{pstd}
{cmd:pvarsoc} reports the overall coefficient of determination, Hansen's
(1982) J statistic and corresponding p-value, and moment model
selection criteria (MMSC) developed by Andrews and Lu (2001): MMSC-Bayesian
information criterion (MBIC), MMSC-Akaike information criterion (MAIC), and
MMSC-Hannan and Quinn information criterion (MQIC) for a series of panel
vector autoregressions of order 1, ..., {cmd:maxlag()} estimated using
{cmd:pvar}.  See {helpb pvar} for details.

{pstd}
Similar to maximum likelihood-based information criteria AIC, BIC, and HQIC,
the model that minimizes the MAIC, MBIC, or MQIC is the preferred model.
Andrews and Lu's MMSC are based on Hansen's J statistic, which requires the
number of moment conditions to be greater than the number of endogenous
variables in the model.


{title:Options}

{phang}
{opt maxlag(#)} specifies the maximum lag order for which the statistics are
obtained.

{phang}
{opth pinstl:ag(numlist)} specifies that {it:numlist}th lag from the highest
lag order of {it:depvarlist} specified in the panel VAR model implemented
using {cmd:pvar} be used; see {helpb pvar} for estimation details.  This
option cannot be specified with the {cmd:pvaropts(instlag({it:numlist}))}
option.

{phang}
{opt pvaropts(options)} passes arguments to {cmd:pvar}; see {helpb pvar}.


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse grunfeld}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}Preestimation {cmd:pvarsoc}, used to select the lag order for a panel
VAR{p_end}
{phang2}{cmd:. pvarsoc invest mvalue kstock}

{pstd}Same as above but use the fourth to eighth lags as instruments in each
model{p_end}
{phang2}{cmd:. pvarsoc invest mvalue kstock, pvaro(instl(4/8))}

{pstd}Same as above but use the first to fifth lags from the highest lag used
in the panel VAR model as instruments; that is, use the first to fifth lags as
instruments for pVAR(1), second to sixth for pVAR(2), etc.{p_end}
{phang2}{cmd:. pvarsoc invest mvalue kstock, pinstl(1/5)}


{title:Stored results}

{pstd}
{cmd:pvarsoc} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(n)}}number of panels{p_end}
{synopt:{cmd:r(tmin)}}first time period in sample{p_end}
{synopt:{cmd:r(tmax)}}last time period in sample{p_end}
{synopt:{cmd:r(tbar)}}average time periods among panels{p_end}
{synopt:{cmd:r(maxlag)}}maximum lag order in pVAR{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(endog)}}names of endogenous variables{p_end}
{synopt:{cmd:r(exog)}}names of exogenous variables, if specified{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(stats)}}coefficient of determination, J, and p-value, MBIC, MAIC, and MQIC{p_end}


{title:References}

{phang}
Andrews, D. W. K., and B. Lu. 2001. Consistent model and moment selection
procedures for GMM estimation with application to dynamic panel data models.
{it:Journal of Econometrics} 101: 123-164.

{phang}
Hansen, L. P. 1982. Large sample properties of generalized method of moments
estimators.  {it:Econometrica} 50: 1029-1054.


{title:Authors}

{pstd}
Michael R. M. Abrigo{break}
Philippine Institute for Development Studies{break}
mabrigo@mail.pids.gov.ph

{pstd}
Inessa Love{break}
University of Hawaii at Manoa{break}
ilove@hawaii.edu


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 16, number 3: {browse "http://www.stata-journal.com/article.html?article=st0455":st0455}

{p 7 14 2}Help:  
{helpb pvar},
{helpb pvarirf},
{helpb pvarfevd},
{helpb pvargranger},
{helpb pvarstable}
{p_end}
