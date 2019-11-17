{smcl}
{right:version:  1.1.0}
{cmd:help asreg} {right:4 May 2017}
{hline}
{viewerjumpto "Options" "asreg##options"}{...}

{title:Title}

{p 4 8}{cmd:asreg}  -  Rolling window regressions and by(group) regressions {p_end}


{title:Syntax}

{p 8 15 2}
{cmd:asreg}
{depvar} {indepvars} {ifin} 
[, {cmdab:w:indow(}{it:[rangevar] # }{cmd:)}
{cmdab:rec:ursive:}{cmd:}
  {cmdab:min:imum:(}{it: # }{cmd:)}
{cmdab:by:(}{it:varlist}{cmd:)}
{cmd:} {it:statistics_options}]

{title:Description}

{p 4 4 2} {cmd: asreg} fits a model of depvar on indepvars using linear regression in a user's defined rolling window 
or by a grouping variable. asreg is order of magnitude faster than estimating rolling window regressions through conventional
methods such as Stata loops or using the Stata's official {help rolling} command. {help asreg} has the same speed efficiency as
{help asrol}. All the rolling window calculations, estimation of regression parameters, and writing the results to Stata variables
are done in the Mata language.


{title:Speed Optimization}
 {p 4 4 2} Rolling window calculations require lots of looping over observations. The problem is compounded by different data structures such as unbalanced panel data,
 data with many duplicates, and data with many missing values. Yet, there might be data sets that have both time series gaps as well as many duplicate observations
 across groups. {help asreg} does not use a static code for all types of data structures. Instead, {help asreg} intelligently identifies data structures and matches
one of its rolling window routines with the data characteristics. Therefore, the rolling window regressions are fast even in larger data sets. {p_end} 

{p 4 4 2} {cmd: asreg} writes all regression outputs to the data in memory as separate variables. This eliminates the need for
writing the results to a separate file, and then merging them back to the data for any further calculations. New variables
from the regression results follow the following naming conventions: {p_end}

{dlgtab:Naming New Variables}

{p2colset 8 29 20 2}{...}
{p2col :{opt observations}}variable containing number of observation is named as {cmd:obs_N}{p_end}
{p2col :{opt regression slopes}}a prefix of {cmd: _b_} is added to the name of each independent variables{p_end}
{p2col :{opt constant}}variable containing constant of the regression is names as {cmd: _b_cons}{p_end}
{p2col :{opt r-squared}}r-squared and adj. r-squared are named as {cmd:R2} and {cmd:AdjR2} , respectively{p_end}
{p2col :{opt standard errors}}a prefix of {cmd: _se_} is added to the name of each independent variables {p_end}
{p2col :{opt residuals}}variable containing residuals is named as {cmd:_residuals} {p_end}
{p2col :{opt fitted}}variable containing fitted values is named as {cmd:_fitted}.{p_end}

{marker asreg_options}{...}
{dlgtab:Options}

{p 4 4 2} 
{cmd:asreg} has the following options. {p_end}

{p 4 4 2} 1. {opt w:indow}: specifies length of the rolling window.  The {opt w:indow} option accepts up to two arguments.
 If we have already declared our data as panel or time series data, {cmd: asreg} will automatically
pick the time variable. In such cases, option {opt w:indow} can have one argument, that is the length of the window, e.g., {opt window(5)}.
 If our data is not time series or panel, then we have to specify
the time variable as a first argument of the option {opt w:indow}. For example, if our time variable is year and we want a rolling window of 24,
 then option {opt w:indow} will look like: {p_end}
 
{p 8 8 2} {opt window( year 24)} {p_end}

{p 4 4 2} 2. {opt rec:ursive}: The option recursive specifies that a recursive window be used. In time series analysis, a recursive window refers to 
a window where the starting period is held fixed, the ending period advances, and the window size grows (see for example, {help rolling}). {help asreg}
allows a recursive window either by invoking the option {opt rec:ursive} or setting the length of the window greater than or equal to the sample size per group. 
For example, if sample size of our data set is 1000 observation per group, we can use a {opt rec:ursive} analysis by setting the window length equal to 1000 or greater than 1000 {p_end}
		
{p 4 4 2} 3. {opt by}: {cmd: asreg} is {help byable}. Hence, it can be run on groups as specified by option {help by}({it:varlist}) or the {help bysort} {it: varlist}: prefix.
An example of such regression might be {browse "https://en.wikipedia.org/wiki/Fama%E2%80%93MacBeth_regression": Fama and MacBeth (1973)} second stage regression, which is estimated 
cross-sectionally in each time period. Therefore, the grouping {help variable} in this case would be 
the time variable. Assume that we have our dependent variable named as{it: stock_returns}, independent variable as  {it: stock_betas}, and time variable as 
{it:month_id}, then to estimate the cross-sectional
regression for each month, {help asreg} command will look like:

 {p 4 4 2}{stata "bys month_id: asreg stock_returns  stock_betas" :. bys month_id: asreg stock_return  stock_betas} {p_end}
 
 {p 4 4 2} 4. {opt  min:imum}: {help asreg} estimates regressions where number of observations are greater than number of regressors.
 However, there is a way to limit the regression estimates to a desired number of observations. The option {opt min:imum}
 can be used for this purpose. If option {opt min} is used, {help asreg} then finds the required number of observation for the regression estimated such that : {p_end}
 {p 4 8 2} obs = max(number of regressors (including the intercept), minimum observation as specified by the option {opt min}). {p_end}
 {p 4 4 2} For example, if we have 4 explanatory variables, then the number of regressors will be equal to 4 plus 1 i.e. 5. 
 Therefore, if {help asreg} receives the value of 8 from the option {opt min}, the required number of observations will be : max(5,8) = 8. If a specific
 rolling window does not have that many observations, values of the new variable will be replaced with missing values. {p_end}

 {dlgtab:Statistics_Options}

{p2colset 8 21 21 2}{...}
{p2col :{opt fit:ted}}reports {stata help regress postestimation##predict:residuals} and fitted values for the last observation in the rolling window. 
If option window is not specified, then the residuals are calculated within each group as specified by the option {help by}({it:varlist}) or the {help bysort} {it: varlist}: {p_end}
{p2col :{opt se:rror}}reports standard errors for each explanatory variable{p_end}
{p2col :{opt other}}Most commonly used regression statistics such as number of observations, slope coefficients, r-squared, and adjusted r-squared are
written to new variables by default. Therefore, if these statistics are not needed, they can be dropped once asreg is estimated.{p_end}


 {dlgtab:Examples}

 
 {title:Example 1: Regression for each company in a rolling window of 10 years}
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "bys company: asreg invest mvalue kstock, wind(year 10)" :. bys company: asreg invest mvalue kstock, wind(year 10)} {p_end}
 {p 4 8 2} The grunfeld data set is a panel data set, so we can omit the word year from the option window. Therefore, the command can also be 
 estimated as shown below:{p_end}
  {p 4 8 2}{stata "bys company: asreg invest mvalue kstock, wind(10)" :. bys company: asreg invest mvalue kstock, wind(10)} {p_end}

   {title:Example 2: Regression for each company in a recursive window}
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "bys company: asreg invest mvalue kstock, wind(year 10) rec" :. bys company: asreg invest mvalue kstock, wind(year 10) rec} {p_end}
 {p 4 8 2} OR {p_end}

  {p 4 8 2}{stata "bys company: asreg invest mvalue kstock, wind(year 1000)" :. bys company: asreg invest mvalue kstock, wind(year 1000)} {p_end}

 
 {title:Example 3: Using option minimum}
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "bys company: asreg invest mvalue kstock, wind(10) min(5)" :. bys company: asreg invest mvalue kstock, wind(10) min(5)} {p_end}

 
 
 {title:Example 4: Reporting standard errors} 
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "bys company: asreg invest mvalue kstock, wind(10) se" :. bys company: asreg invest mvalue kstock, wind(10) se} {p_end}
 
 
 
 {title:Example 5: Reporting standard errors, fitted values and residuals} 
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "bys company: asreg invest mvalue kstock, wind(10) se fit" :. bys company: asreg invest mvalue kstock, wind(10) se fit} {p_end}

 
 
 {title:Example 6: No window - by groups regressions} 
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "bys company: asreg invest mvalue kstock" :. bys company: asreg invest mvalue kstock} {p_end}

 
 
 {title:Example 7: Yearly cross-sectional regressions} 
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "bys year: asreg invest mvalue kstock" :. bys year: asreg invest mvalue kstock} {p_end}
 

 
{title:Author}

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: *
*                                                                   *
*            Dr. Attaullah Shah                                     *
*            Institute of Management Sciences, Peshawar, Pakistan   *
*            Email: attaullah.shah@imsciences.edu.pk                *
*           {browse "www.OpenDoors.Pk": www.OpenDoors.Pk}                                       *
*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*


{marker also}{...}
{title:Also see}

{psee}
{stata "ssc desc astile":astile}, 
{stata "ssc desc ascol":ascol},
{stata "ssc desc asrol":asrol},
{stata "ssc desc searchfor":searchfor}





