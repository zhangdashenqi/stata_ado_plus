{smcl}
{* *! version 1.0.1  11jul2011}
{cmd:help mibeta}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{cmd:mibeta} {hline 2}}Standardized coefficients after linear regression with multiply-imputed data{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:mibeta} {depvar} [{indepvars}] {ifin} {weight}
   [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt fisherz}}use Fisher's z transformation{p_end}
{synopt :{opt nocoef}}suppress MI estimates of coefficients{p_end}
{synopt :{opth miopts:(mi_estimate:miopts)}}control MI coefficient table; see {manhelp mi_estimate MI:mi estimate}{p_end}
{synopt :{it:{help regress##options:regopts}}}control linear regression estimation; see {manhelp regress R}{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:mibeta} provides descriptive statistics of standardized coefficients and
R-squared measures over imputed data when multiple-imputation analysis is
performed using linear regression: {cmd:mi estimate:} {cmd:regress}.


{title:Options}

{phang}
{opt fisherz} specifies that Rubin's rules are applied to the estimates of
standardized coefficients and R-squared measures after Fisher's z (inverse
hyperbolic tangent, {cmd:atanh()}) transformation.  The final estimates are
then transformed back using the inverse, hyperbolic tangent {cmd:tanh()},
transformation.  Using {cmd:fisherz} may lead to missing {cmd:mean} values
when the estimates of standardized coefficients are outside of [-1,1], which
may happen when regressors are highly collinear.

{phang}
{opt nocoef} suppresses the display of tables containing multiple-imputation
estimates of coefficients.  This option suppresses any output produced by
{cmd:mi estimate:} {cmd:regress}.

{phang}
{opt miopts(miopts)} controls multiple-imputation estimation.  {it:miopts}
specifies any options supported by {manhelp mi_estimate MI: mi estimate}.

{phang}
{it:regopts}; see {helpb regress##options:[R] regress}.


{title:Remarks}

{pstd}
By default, {cmd:mibeta} reports descriptive statistics (mean, median,
minimum, maximum, and the 25th and the 75th percentiles) of standardized
coefficients, R-squared and adjusted R-squared coefficients using the original
scale.  The reported {cmd:mean} statistic obtained by averaging the estimates
of these measures over imputed data (that is, by applying Rubin's rules to the
estimates in the original metric) must be used with caution because the
distribution of these measures is not symmetric and may be far from Normal.
Harel (2009) suggests to use Fisher's z transformation for the R-squared
measures to improve normality (option {cmd:fihserz}).  Marshall et al. (2009)
recommend to look at quantiles (as also reported by {cmd:mibeta}) of the
distribution over the imputed datasets to obtain more appropriate estimates.


{title:Examples}

{pstd}Create multiply-imputed data{p_end}
{phang2}{cmd:. sysuse auto}{p_end}
{phang2}{cmd:. mi set mlong}{p_end}
{phang2}{cmd:. mi register imputed rep78}{p_end}
{phang2}{cmd:. mi impute mlogit rep78 mpg weight length price turn trunk, add(5) rseed(231729)}{p_end}

{pstd}Fit linear regression model to multiply-imputed data and obtain standardized coefficients{p_end}
{phang2}{cmd:. mibeta mpg weight length i.rep78}{p_end}

{pstd}Obtain variance information about MI estimates of coefficients{p_end}
{phang2}{cmd:. mibeta mpg weight length i.rep78, miopts(vartable)}{p_end}

{pstd}Use robust variance estimator to estimate within-imputation variance of coefficients{p_end}
{phang2}{cmd:. mibeta mpg weight length i.rep78, vce(robust)}{p_end}


{title:Saved results}

{pstd}
{cmd:mibeta} is a wrapper for {cmd:mi estimate:} {cmd:regress} which also
computes summary statistics over imputed datasets for standardized
coefficients and R-squared mesures.  {cmd:mibeta} is implemented as an ado
file.  The results saved by {cmd:mi estimate:} {cmd:regress} are saved in
{cmd:e()}.


{title:References}

{pstd}
Marshall A., D. G. Altman, R. L. Holder, and P. Royston. 2009. Combining
estimates of interest in prognostic modelling studies after multiple
imputation: current practice and guidelines. {it:BMC Medical Research}
{it:Methodology} 9:57.

{pstd}
Harel, O. 2009. The estimation of R2 and adjusted R2 in incomplete data sets
using multiple imputation. {it:Journal of Applied Statistics}, 36: 1109-1118.


{title:Author}

{pstd}Yulia Marchenko, StataCorp.{p_end}
{pstd}ymarchenko@stata.com{p_end}


{title:Also see}

{psee}
{space 2}Help:  {manhelp mi_estimate MI: mi estimate}, {manhelp regress R}, 
{manhelp mi MI}
{p_end}
