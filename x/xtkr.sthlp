{smcl}
{* version 1.0.0 11August2015}{...}
{cmd:help xtkr}{right: ({browse "http://www.stata-journal.com/article.html?article=st0443":SJ16-3: st0443})}
{hline}

{title:Title}

{p2colset 5 13 15 2}{...}
{p2col:{cmd:xtkr} {hline 2}}The Keane and Runkle estimator for dynamic panel estimation{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 12 2}
{cmd:xtkr} {depvar} [{it:varlist1}] {cmd:(}{it:varlist2} {cmd:=} 
{it:varlist3}{cmd:)} {ifin} [{cmd:,} {cmd:nocons tdum}]

{p 4 4 2}
{it:varlist1} contains any exogenous explanatory variables, {it:varlist2}
contains endogenous variables, and {it:varlist3} contains the instruments.
You must {cmd:xtset} your data before using {cmd:xtkr}; see 
{helpb xtset}.{p_end}


{title:Description}

{pstd}
{cmd:xtkr} implements the Keane and Runkle (1992) estimator for dynamic panel
estimation.

{p 4 4 2}
This estimator is for panel data (large N small T) models where the
instruments are not strictly exogenous and the errors contain some form of
serial correlation.  It is most commonly applied to dynamic models that
contain a lagged dependent variable and fixed or random effects across
individuals, such as

{p 4 4 2}y_it = rho*y_(it-1) + beta*x_it + mu_i + e_it{p_end}

{p 4 4 2}
where rho is the autoregressive coefficient, x_it is an NTxK matrix of
regressors, beta is a 1xK vector of coefficients, mu_i is the
individual-specific effect, and e_it is the idiosyncratic error term.
Applying the within or first-difference estimator to remove the individual
effects will result in endogeneity in the lagged dependent variable and,
accordingly, inconsistent estimates.  While two-stage least squares will be
consistent in such situations, the Keane and Runkle (1992) estimator uses the
idea of forward filtering in the time-series literature to improve the
efficiency of the estimates when the error contains some form of serial
correlation.{p_end}

{p 4 4 2}
An alternative approach to account for serial correlation is to adopt the
difference of system generalized method of moments estimator (implemented in
Stata with {cmd:xtabond2} and {cmd:xtdpd}).  However, as the number of
instruments used in those estimators grows nonlinearly in T, it can result in
the problem of weak or too many instruments, which will bias the results
toward ordinary least squares.  Restricting or collapsing the instrument
matrix can potentially remedy the problem, but there are situations where the
Keane and Runkle (1992) estimator will be preferable.  Please see Keane and
Neal (2016) for further information.{p_end}


{title:Options}

{phang}
{cmd:nocons} suppresses the constant term.

{phang}
{cmd:tdum} demeans the data across the time dimension (that is, the average
across i for a given t).  This is equivalent and preferable to adding time
dummies to the regression because that can cause collinearity in the second
stage.


{title:Examples}

{p 4 4 2}
In cases where the regressor {cmd:x} is strictly exogenous, one might use the
following:{p_end}

{p 4 4 2}In levels form {p_end}
{phang2}{cmd:. xtkr y x (l.y = d.l.y d.l(0/1).x)}

{p 4 4 2}In first-difference form{p_end}
{phang2}{cmd:. xtkr d.y d.x (d.l.y = l2.y l(1/2).x)}

{p 4 4 2}
In cases where the regressor {cmd:x} is predetermined, one might use the
following:{p_end}

{p 4 4 2}In levels form{p_end}
{phang2}{cmd:. xtkr y (l.y x = d.l.y d.l(0/1).x)}

{p 4 4 2}In first-difference form{p_end}
{phang2}{cmd:. xtkr d.y (d.l.y d.x = l2.y l(1/2).x)}

{p 4 4 2}
In cases where the regressor {cmd:x} is endogenous, one might use the
following:{p_end}

{p 4 4 2}In levels form{p_end}
{phang2}{cmd:. xtkr y (l.y x = d.l(1/2).y d.l(1/2).x)}

{p 4 4 2}In first-difference form{p_end}
{phang2}{cmd:. xtkr d.y d.x (d.l.y = l(2/3).y l(2/3).x)}


{title:References}

{phang}
Keane, M., and T. Neal. 2016. {browse "http://www.stata-journal.com/article.html?article=st0443":The Keane and Runkle estimator for panel-data models with serial correlation and instruments that are not strictly exogenous}. 
{it:Stata Journal} 16: 523-549.

{phang}
Keane, M. P., and D. E. Runkle. 1992. On the estimation of
panel-data models with serial correlation when instruments are not strictly
exogenous. {it:Journal of Business and Economic Statistics} 10: 1-9.{p_end}


{title:Authors}

{pstd}
Michael Keane{break}
University of Oxford{break}
Oxford, UK{break}
michael.keane@nuffield.ox.ac.uk

{pstd}
Timothy Neal{break}
University of New South Wales{break}
Sydney, Australia{break}
Timothy.Neal@unsw.edu.au


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 16, number 3: {browse "http://www.stata-journal.com/article.html?article=st0443":st0443}

{p 7 14 2}Help:  {manhelp xtdata XT}, {helpb xtabond2} (if installed), {manhelp xtset XT}, {manhelp xtreg XT}, {manhelp xtdpd XT}{p_end}
