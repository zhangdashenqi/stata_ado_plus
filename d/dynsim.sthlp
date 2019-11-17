{smcl}
{* *! version 7.0 01jul2011}{...}
{cmd:help dynsim}{right: ({browse "http://www.stata-journal.com/article.html?article=st0242":SJ11-4: st0242})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:dynsim} {hline 2}}Produce dynamic simulations of autoregressive relationships in ordinary least-squares models{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:dynsim}{cmd:,} 
{cmd:ldv(}{it:varname}{cmd:)} 
{cmd:scen1(}{it:string}{cmd:)}
[{cmd:scen2(}{it:string}{cmd:)} 
{cmd:scen3(}{it:string}{cmd:)} 
{cmd:scen4(}{it:string}{cmd:)} 
{cmd:n(}{it:integer}{cmd:)} 
{cmd:sig(}{it:cilevel}{cmd:)} 
{cmd:shock(}{it:varname}{cmd:)} 
{cmd:shock_data(}{it:filename}{cmd:)} 
{cmd:shock_num(}{it:numlist}{cmd:)} 
{cmdab:mod:ify(}{it:varlist}{cmd:)} 
{cmdab:int:er(}{it:varlist}{cmd:)} 
{cmdab:sav:ing(}{it:string}{cmd:)} 
{cmdab:fore:cast(}{it:string}{cmd:)}]


{title:Description}

{pstd}{cmd:dynsim} uses King, Tomz, and Wittenberg's (2000) Clarify
statistical package to present long-term dynamics for autoregressive
series.  The user specifies a number of scenarios (up to four), and the
program estimates the value of the predicted dependent variable (and
confidence intervals) for each scenario for a user-specified number of
iterations.  The command is dynamic in that each iteration updates the
value of the lagged dependent variable based on the predicted value from
the previous iteration.

{pstd}Available options include specifying the values of an exogenous
variable ({opt shock()}) to change with each iteration.  The program also
effectively interacts the shock variable with up to four
other independent variables in the model.

{pstd}The user must have downloaded and installed the Clarify package 
({helpb estsimp}, {helpb setx}, and {helpb simqi}).  The model must be fit via
{opt estsimp} {opt regress} prior to running {cmd:dynsim}.


{title:Options}

{phang}{opt ldv(varname)} specifies the name of the lagged dependent
variable.  {cmd:ldv()} is required.

{phang}{opt scen1(string)} specifies the values of the variables used to
generate the predicted values when t=0.  At least one scenario must be
given.  The coding designation is identical to the options used in
Clarify's {cmd:setx} (except for setting the values to
a specific observation).  At each subsequent iteration, these values
will not change except for the value of the lagged dependent
variable, the shock variable ({opt shock()}, if specified), and the
interacted variable ({opt inter()}, if specified).  {cmd:scen1()} is
required.

{phang}{opt scen2(string)}, {opt scen3(string)}, and {opt scen4(string)}
are optional and are only used if more than one scenario is desired.  A
maximum of four scenarios is allowed.  These follow the same conventions as
{opt scen1()}.

{phang}{opt n(integer)} specifies the number of iterations (or time
intervals) over which the program will generate the predicted value of the
dependent variable.  The default is {cmd:n(10)}.

{phang}{opt sig(cilevel)} specifies the level of statistical
significance of the confidence intervals (calculated via the percentile
method).  This value must be between 10 and 99.99; see 
{manhelp level R}.

{phang}{opt shock(varname)} allows the user to choose an
independent variable (and its first {cmd:n()} values) and have the
variable (and potentially different values) impact the scenarios at each
simulation.  If this command is specified, the user must specify the
{opt n()} shock values through either a dataset containing the variable
({opt shock_data()}) or a Stata {it:numlist} ({opt shock_num()}).  For
example, if {cmd:shock_data(shock.dta)} is specified, then
{cmd:dynsim} will read the first {opt n()} values of the {opt shock()}
variable.  If {cmd:shock_num()} is specified as
{cmd:0(10)100}, the value of the {opt shock()} variable will be 0 at
time t+1, 10 at time t+2, and so on.  The number of values assigned to
the shock variable must exceed the number of simulations.  If the shock
variable is interacted with another variable in the model, the user must
also specify the name of the modifying variable ({cmd:modify()}) and the
interaction variable ({opt inter()}).

{phang}{opt shock_data(filename)} is one of two ways of specifying the
shock values.  This must either give the filename or be located in the
working directory.  The dataset used to get the shock variable (called
the shock dataset) must have at least the number of iterations
specified in {opt n()}, and it must contain a variable with the same name
as the shock variable ({opt shock()}).

{phang}{opt shock_num(numlist)} is the second way of specifying the
shock values.  Any {it:numlist} is acceptable if it contains at
least {opt n()} values; see {manhelp numlist P}.

{phang}{opt modify(varlist)} specifies up to four variables that
modify the relationship between the shock variable and the dependent
variable.  If the shock variable interacts with another variable in
the model, {cmd:dynsim} automatically updates the value of the
interaction to be the product of the shock and it modifies the variable at each
iteration.  If {opt inter()} is specified, then {cmd:modify()} must also be
specified.  The same number of variables must appear in {opt inter()}
as in {cmd:modify()}.  The variables must also appear in the same order as in
{cmd:estsimp}.

{phang}{opt inter(varlist)} specifies up to four interaction variables.
If {cmd:modify()} is specified, then {cmd:inter()} must also be specified.  Much like 
{cmd:modify()}, the variables must appear in the same order as in
{cmd:estsimp}.

{phang}{opt saving(string)} creates a dataset containing the
predicted values and confidence intervals for each scenario.  It
automatically replaces any dataset with the same name, so change the
name of the dataset used if you do not want it replaced.

{phang}{opt forecast(string)} produces confidence intervals based on
one of four options for calculating the conditional variance of a
forecast: The {opt ae} suboption analytically calculates the standard errors based
on Enders' (2010, 81-89) formula for the conditional variance of the
forecast.  The {opt ag} suboption analytically calculates the standard errors 
based on Greene's (2008, 686-689) formula for the conditional variance
of a forecast.  The {opt se} and {opt sg} suboptions use the Enders and Greene
formulas, respectively, but use the simulations to produce {cmd:n()}
estimates of the conditional variance, which are then used to produce
confidence intervals based on the percentile method.


{title:Examples}

{phang2}{cmd:. webuse grunfeld}{p_end}
{phang2}{cmd:. xtset company year, yearly}{p_end}
{phang2}{cmd:. generate lag_invest = L.invest}{p_end}
{phang2}{cmd:. generate z = mvalue*kstock}{p_end}
{phang2}{cmd:. estsimp regress invest lag_invest mvalue kstock}{p_end}

{pstd}The following calculates 20 simulations of predicted values of
{cmd:invest} (and 95% confidence intervals) based on two scenarios of the
other variables' values and saves them in {cmd:test_data.dta}:{p_end}

{phang2}{cmd:. dynsim, ldv(lag_invest) scen1(lag_invest 139 mvalue 0 kstock 10) scen2(lag_invest 50 mvalue 20 kstock 100) n(20) sig(95) saving(test_data)}{p_end}

{pstd}We can view the returned matrices to examine the starting values
of each scenario and the values for each iteration.  Here we
present the matrices for the first scenario:{p_end}

{phang2}{cmd:. matrix list r(t0_s1)}{p_end}
{phang2}{cmd:. matrix list r(xc_s1)}{p_end}

{pstd}Then load the dataset, list the values, and graph them as
an {cmd:rcapsym} figure:{p_end}

{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. use test_data, clear}{p_end}
{phang2}{cmd:. list}{p_end}
{phang2}{cmd:. twoway (rcapsym lower_1 upper_1 t, msymbol(O)) (rcapsym lower_2 upper_2 t, msymbol(Sh)), ytitle("Real Gross Investment") legend(label (1 "Scenario 1") label (2 "Scenario 2"))}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}The following calculates 15 simulations of predicted values of
{cmd:invest} (and 90% confidence intervals) based on two scenarios and
a shock variable, which takes the values of the {it:numlist} at each
subsequent simulation: {p_end}

{phang2}{cmd:. dynsim, ldv(lag_invest) scen1(lag_invest 139 mvalue 0 kstock 10) scen2(lag_invest 50 mvalue 20 kstock 100) n(15) sig(90) saving(test_data) shock(kstock) shock_num(0(1)20)}{p_end}

{pstd}The following calculates 10 simulations of predicted values of
{cmd:invest} (and 99% confidence intervals) based on two scenarios and
a shock variable, which takes the values of the {it:numlist} at each
subsequent simulation.  Additionally, the value of {cmd:inter()} changes based on
the shock value (specified by the {it:numlist}) and the value of the modify
variable.{p_end}

{pstd}First, reestimate the model with the new interaction variable {cmd:z}:{p_end}

{phang2}{cmd:. estsimp regress invest lag_invest mvalue kstock z, genname(k)}{p_end}

{phang2}{cmd:. dynsim, ldv(lag_invest) scen1(lag_invest 139 mvalue 0 kstock 10 z 0) scen2(lag_invest 50 mvalue 20 kstock 100 z 2000) n(10) sig(99) saving(test_data) shock(kstock) shock_num(0(1)20) modify(mvalue) inter(z)}{p_end}


{title:Saved results}

{pstd}
{cmd:dynsim} saves the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(t0_s1)}}values of variables at time t=0 for first scenario{p_end}
{synopt:{cmd:r(t0_s2)}}values of variables at time t=0 for second scenario{p_end}
{synopt:{cmd:r(t0_s3)}}values of variables at time t=0 for third scenario{p_end}
{synopt:{cmd:r(t0_s4)}}values of variables at time t=0 for fourth scenario{p_end}
{synopt:{cmd:r(xc_s1)}}values of variables for first scenario{p_end}
{synopt:{cmd:r(xc_s2)}}values of variables for second scenario{p_end}
{synopt:{cmd:r(xc_s3)}}values of variables for third scenario{p_end}
{synopt:{cmd:r(xc_s4)}}values of variables for fourth scenario{p_end}
{p2colreset}{...}


{title:References}

{phang}Enders, W. 2010. {it:Applied Econometric Time Series}. 3rd ed.
Hoboken, NJ: Wiley.

{phang}Greene, W. H. 2008. {it:Econometric Analysis}. 6th ed. Upper
Saddle River, NJ: Prentice Hall.

{phang}King, G., M. Tomz, and J. Wittenberg. 2000. Making the most of
statistical analyses: Improving interpretation and presentation. {it:American Journal of Political Science} 44: 347-361.


{title:Citation}

{pstd}For a more in-depth discussion of this program (including
examples) or when citing this program, please view the article "But Wait,
There's More! Maximizing Substantive Inferences in TSCS Models" 
presented at the 2010 Annual Meeting of the St. Louis Area Methods Meeting
(SLAMM). {p_end}


{title:Authors}

{pstd}Laron K. Williams{p_end}
{pstd}University of Missouri{p_end}
{pstd}Columbia, MO{p_end}
{pstd}williamslaro@missouri.edu{p_end}

{pstd}Guy D. Whitten{p_end}
{pstd}Texas A&M University{p_end}
{pstd}College Station, TX{p_end}
{pstd}g-whitten@pols.tamu.edu{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 11, number 4: {browse "http://www.stata-journal.com/article.html?article=st0242":st0242}{p_end}
