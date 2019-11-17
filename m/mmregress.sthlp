{smcl}
{* *! version 1.0  1dec2008}{...}
{cmd:help mmregress} {right: ({browse "http://www.stata-journal.com/article.html?article=up0028":SJ10-2: st0173_1})}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{hi:mmregress} {hline 2}}MM-robust
regression{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 15 2}
{cmdab:mmregress}
{depvar}
[{indepvars}]
{ifin}
[{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt noc:onstant}}suppress constant term{p_end}

{syntab:Algorithm}
{synopt :{opt eff(#)}}fix the desired efficiency{p_end}
{synopt :{opt dummies(dummies)}}declare dummy variables{p_end}
{synopt :{cmdab:out:lier}}generate outlyingness measures{p_end}
{synopt :{opt graph}}generate an outlier identification  graphical tool{p_end}
{synopt :{opt label(varname)}}label largest outlier according to {it:varname}{p_end}
{synopt :{opt replic(#)}}set the number of subsampling to consider{p_end}
{synopt :{cmdab:init:ial}}return the initial S-estimator (or MS-estimator){p_end}
{synoptline}


{title:Description}

{pstd}
{opt mmregress} fits an MM-estimator of regression of {depvar} on {indepvars}. 
An MM-estimator of regression is a robust fitting approach that minimizes
a (rho) function of the regression residuals, which is even, nondecreasing 
for positive values and less increasing than the square function. The function used here is a Tukey biweight.
The default Gaussian efficiency is set to 70% but can be changed by calling
the {opt eff()} option.
The breakdown point is 50%.


{title:Options}

{dlgtab:Model}

{phang}
{opt noconstant}; see
{helpb estimation options##noconstant:[R] estimation options}.

{dlgtab:Algorithm}

{phang}
{opt eff(#)} fixes the Gaussian efficiency of the MM-estimator (it can be set to any value
between 0.287 and 0.99). Keep in mind, however, that a higher efficiency is
associated with a higher bias.

{phang}
{opt dummies(dummies)} specifies which variables are dichotomous. If several dummy variables are present among the explanatory variables, the preliminary S-estimator algorithm
could fail. An MS-estimator can be used instead by declaring the list of dummy variables present in the model.

{phang} {opt outlier} calculates four outlyingness measures. The first
(S_stdres or MS_stdres) contains the robust standardized residuals; the second
(S_outlier or MS_outlier) flags outliers in the vertical dimension (i.e.,
observations associated with a robust standardized residual larger than 2.25);
the third (Robust_distance) contains robust distances; and the fourth
(MCD_outlier) flags outliers in the horizontal dimension (i.e., observations
associated with robust distances larger than the 97.5 percentile of a
chi-squared).

{phang}
{opt graph} displays a graphic where outliers are flagged according to their type.

{phang}
{opt label(varname)} labels the outlier using the variable
{it:varname}.  This option only works jointly with the {cmd:graph} option. If
{opt label()} is not declared, the label will be the observation line number.

{phang}
{opt replic(#)} specifies the number of subsets to consider in the initial
steps of the algorithm. By default, the number of subsets associated with the underlying algorithm is set using the formula
replic=log(1-0.99)/log{1-(1-0.2)^(p+1)}, where p is the number of explanatory variables. 

{phang}
{opt initial} specifies to return the initial S-estimator (or MS-estimator)
instead of the final MM-estimator. This is equivalent to setting the efficiency to 0.287.


{title:Examples}

{pstd}Setup{p_end}

{phang2}{cmd:. webuse auto}{p_end}

{pstd}Robust regression with default efficiency{p_end}

{phang2}{cmd:.  xi: mmregress  price mpg headroom trunk weight length turn displacement gear_ratio i.rep78 foreign}

{phang2}{it:({stata "gr_example auto:  xi: mmregress  price mpg headroom trunk weight length turn displacement gear_ratio i.rep78 foreign":click to run})}
{...}

{pstd}Same as above, but calling the initial S-estimator{p_end}

{phang2}{cmd:.  xi: mmregress  price mpg headroom trunk weight length turn displacement gear_ratio i.rep78 foreign, initial}

{phang2}{it:({stata "gr_example auto:  xi: mmregress  price mpg headroom trunk weight length turn displacement gear_ratio i.rep78 foreign, initial":click to run})}
{...}

{pstd}Same as above, but fixing the Gaussian efficiency to 95%{p_end}

{phang2}{cmd:. xi: mmregress  price mpg headroom trunk weight length turn displacement gear_ratio i.rep78 foreign, eff(0.95)}

{pstd}Same as above, but starting the algorithm with an MS-estimator instead of an S-estimator{p_end}

{phang2}{cmd:. xi: mmregress  price mpg headroom trunk weight length turn displacement gear_ratio, dummies(i.rep78 foreign)}

{pstd}Same as above, but calling the initial MS-estimator rather than the more efficient MM-estimator{p_end}

{phang2}{cmd:. xi: mmregress  price mpg headroom trunk weight length turn displacement gear_ratio, dummies(i.rep78 foreign) initial}

{pstd}Robust fixed-effects regression{p_end}

{phang2}{cmd:. use http://fmwww.bc.edu/ec-p/data/wooldridge2k/CORNWELL, clear}{p_end}
{phang2}{cmd:. generate lncrmrte=ln(crmrte)}{p_end}
{phang2}{cmd:. xi: mmregress lncrmrte prbarr prbconv prbpris avgsen, dummies(i.county i.year)}


{title:Saved results}

{pstd}
{cmd:mmregress} saves the following in {cmd:e()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:e(scale)}}robust residual scale{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synoptset 15 tabbed}{...}

{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:mmregress}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 10, number 2: {browse "http://www.stata-journal.com/article.html?article=up0028":st0173_1},{break}
           {it:Stata Journal}, volume 9, number 3: {browse "http://www.stata-journal.com/sjpdf.html?articlenum=st0173":st0173}

{p 4 14 2}{space 3}Help:  {manhelp qreg R}, {manhelp regress R};{break}
{manhelp rreg R}, {helpb mregress}, {helpb sregress}, {helpb msregress}, {helpb mcd} (if installed)
{p_end}
