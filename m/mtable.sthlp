{smcl}
{* 2014-08-06 scott long & jeremy freese}{...}
{title:Title}

{p2colset 5 15 23 2}{...}
{p2col:{cmd:mtable} {hline 2}}Construct tables of predictions using{cmd:margins}{p_end}
{p2colreset}{...}


{title:General syntax}

{p 4 18 2}
{cmd:mtable} [{it:if}] [{it:in}]{cmd:,} [ {it:mtable-options} {it:margins-options} ]
{p_end}

{marker overview}
{title:Overview}

{pstd}
{cmd:mtable} uses {helpb margins} to construct tables of predictions.
If the outcome has multiple categories, {cmd:mtable} automatically
submits multiple {cmd:margins} commands for all outcomes and combines the
results in the table. Results from multiple calls of {cmd:mtable} can be
combined into a single table.
{p_end}

{pstd}
{cmd:margins} is a complicated command with many options.
It is possible that {cmd:mtable} will not work with every option that is
available with {cmd:margins}.
{p_end}


{title:Options}

    {help mtable##margins:Options for margins}
    {help mtable##stats:Which statistics to display}
    {help mtable##atvars:Displaying at-variables}
    {help mtable##show:Controlling how results are displayed}
    {help mtable##combine:Combining tables}
    {help mtable##matrices:Matrices that are created}
    {help mtable##returns:Returns}

{marker margins}
{dlgtab:Options for margins}
{p2colset 7 24 25 0}
{p 6 6 2}
{cmd:mtable} supports most options from {cmd:margins}. Below are margins options commonly used by {cmd:mtable}.

{synopt:{opt at(atspec)}}
Specify the values of regressors for which predictions are calculated.
For example, {cmd:at(wc=(0 1) k5=(0 1 2 3))}.
A single value or multiple values can be specified for variables.
A single variable or multiple variables can be included.
For details, see {help margins##at_op:at(atspec)}.

{synopt:{opt atmeans}}
All regressors not specified with {cmd:at()} are held at their means.
If {cmd:if} or {cmd:in} are used to specify the sample, the means are
computed for the selected observations. If {cmd:atmeans} is not specified,
marginal effects are averaged across observations.

{synopt:{opt over(varlist)}}
Predictions are calculated separately for groups defined by {it:varlist}.
Values must be nonnegative integers. Variables in {it:varlist} do not need to
be in your model.

{synopt:{opt post}}
For binary models, this options posts the estimates in the same way that
{cmd:margins, post} does.
With the {cmd:outcomes()} option, results can be posted for
a single outcome category of a categorical outcome. For details on
using posted results, see {help mlincom}

{synopt:{opt dydx(varlist)}}
Computes marginal effects of variables included in {it:varlist}.
Different marginal effects are computed depending on the factor variable notation
included in the preceding regression model.
By default, a marginal change is computed for variables
with no factor variable notation and variables with the {cmd:c.} prefix.
Discrete changes between categories are computed for
variables with the {cmd:i.} prefix. See {helpb fvvarlist:factor variable notation} for
more information.

{p 6 6 2}
{it:if} or {it:in} conditions select the observations
used by {cmd:margins}.
With {cmd:atmeans}, the means are computed conditionally
on the {it:if} or {it:in} conditions. If {cmd:atmeans} is not used, the
average prediction is the average for the sample selected by the
{it:if} or {it:in} conditions.

{synopt:{opt detail:s}}
Display output from {cmd:margins} used to estimate quantities in table.

{synopt:{opt command:s}}
Display {cmd:margins} commands used to estimate quantities in table.

{marker stats}
{dlgtab:Statistics to include in the table}
{p2colset 7 29 29 0}
{p 6 6 2}

{synopt:{opt stat:istics(statlist)}}specifies which statistics to
include in the table. By default only estimates are displayed. Additional
statistics can be select with this option.
{p_end}

{p2colset 10 23 23 12}{...}
{p2col :Name}Description{p_end}
{p2line}
{p2col :{ul:{bf:est}}{bf:imate}}Estimates including probabilities, dydx, etc.{p_end}
{p2col :{bf:ll}}Lower level bound of confidence interval.{p_end}
{p2col :{bf:ul}}Upper level bound of confidence interval.{p_end}
{p2col :{ul:{bf:p}}{bf:value}}p-value for test prediction is 0.{p_end}
{p2col :{bf:se}}Standard error of prediction.{p_end}
{p2col :{bf:z}}z-value for test prediction is 0.{p_end}
{p2col :{bf:all}}Display all statistics.{p_end}
{p2col :{bf:ci}}Display estimate, ll, and ul.{p_end}
{p2line}
{p2colset 8 27 28 0}
{synopt:{opt allstats}}
Display all statictics.
Equivalent to {cmd:statistics(all)}.

{synopt:{opt ci}}
Display estimate and bounds of confidence interval.
Equivalent to {cmd:statistics(est ll ul)}.

{synopt:{opt level(#)}}
Adjusts the range of confidence intervals, from 10 to 99.99.

{synopt:{opt pv:alue}}
Display estimate and p-value.
Equivalent to {cmd:statistics(est pvalue)}.

{synopt:{opt out:comes(numlist)}}
Estimates displayed for these values of the outcome for models
where {cmd:outcomes()} is an option for {cmd:predict}, such as {cmd:mlogit}.
Outcome values must be non-negative integers.
{p_end}

{synopt:{opt pr(numlist)}}
Estimates displayed for these probabilities for models
where {cmd:pr()} is an option for {cmd:predict}, such as {cmd:poisson}.
Outcome values must be non-negative integers.
{p_end}

{synopt:{opt cpr(numlist)}}
Estimates displayed for these conditional probabilities for models
where {cmd:pr()} is an option for {cmd:predict}.
Outcome values must be non-negative integers.
{p_end}

{marker atvars}
{dlgtab:at-variables in the table}
{p2colset 9 26 26 0}
{p 6 6 2}
By default, the table includes values of those variables specified with {cmd:at()}
that vary.
For example, with {cmd:mtable, at(a=(0 1) b=1)}, variable {bf:a} is included
in the table, but variable {bf:b} is not.
Variables included in the table are referred to as "{it:at-variables}".
{p_end}

{p 6 6 2}
The following options control how {it:at-variables} are included in the table.
{p_end}

{synopt:{opt atv:ars(varlist)}}Selects the {it:at-variables} to
include in the table.
{bf:atvars(_none)} excludes all {it:at-variables}.
{bf:atvars(_all)} includes all variables including those that do not vary.
{p_end}

{synopt:{opt noat:vars}}Do not include any at-variables in table.
This is equivalent to {cmd:atvars(_none)}.
{p_end}

{synopt:{opt atr:ight}}By default, the {it:at-variables} are listed
before the estimates. {bf:atright} places the {it:at-variables} to the
right.
{p_end}

{marker show}
{dlgtab:Controlling how results are displayed}
{p2colset 9 25 26 0}
{synopt:{opt long}}
Display table with statistics in rows. The column are labeled
with the category number or label.

{synopt:{opt wide}}
Display table with statistics in columns. Column names are the
name of the statistic plus the category name or label.

{synopt:{opt roweq:nm(string)}}
Add a row equation name to the table.
For details, see {help matrix roweq}.

{synopt:{opt coleq:nm(string)}}
Add a column equation name to the table.
For details, see {help matrix coleq}.

{synopt:{opt rowst:ub(string)}}
String is added to all row names.

{synopt:{opt colst:ub(string)}}
String is added to all column names.

{synopt:{opt rowna:me(string)}}
Name to label row.

{synopt:{opt title(string)}} Title used to label table. If stacking multiple
mtable results using {cmd:below} or {cmd:right}, the most recent title is used.

{synopt:{opt tw:idth(#)}} Width of margins for row labels.

{synopt:{opt wid:th(#)}} Width of columns with estimates.

{synopt:{opt dec:imal(#)}} Number of decimal digits displayed.

{synopt:{opt estn:ame(string)}} Name to label estimates. By
default the name from {cmd:margins} is used.

{synopt:{opt nol:abel}} Do not use value labels when labeling outcomes.
{p_end}

{synopt:{opt nofvlabel}} Do not use factor variable labels for labeling
output.
{p_end}

{synopt:{opt nobs}} Display number of observations used by {cmd:margins}.
{p_end}

{synopt:{opt valuel:ength(#)}} Limits length of value labels used to
label results.
{p_end}

{synopt:{opt names(rows|columns|all|none)}} Specify whether row names,
column names, all (row and column) names, or no names will be shown in
table. See {helpb matlist} for details. This option overwrites the
defaults and can lead to poorly formatted output.
{p_end}

{synopt:{opt norownum:bers}} Is a synonyms for {cmd:names(columns)}.
{p_end}

{marker combine}
{dlgtab:Combining tables}
{p2colset 9 26 26 0}
{p 6 6 2}
You can combine the current {cmd:mtable} results with those
from the last execution of {cmd:mtable}. This allows you to build tables
using as many {cmd:mtable} commands as needed. The table is displayed using
the display options from the last {cmd:mtable} used.
{p_end}

{synopt:{opt below}}
Place the current results below those from last {cmd:mtable}.
{p_end}

{synopt:{opt right}}
Place current results to the right of those from last {cmd:mtable}.
{p_end}

{synopt:{opt clear}}
Clear prior results before saving results to construct a new table.
{p_end}

{marker model}
{dlgtab:Model types}
{p2colset 9 24 25 0}
{p 6 6 2}
Behavior of command depends on
what options are permitted by {cmd:predict}.
For convenience, three major types of models are called {it:categorical},
{it:count}, and {it:binary} models.

{p2line}
{p2col :categorical}{cmd:predict} allows {cmd:outcome(}{it:#}{cmd:)},
such as {cmd: mlogit}.{p_end}
{p2col :count}{cmd:predict} allows {cmd:pr(}{it:#}{cmd:)},
such as {cmd: poisson}.{p_end}
{p2col :binary}{cmd:predict} default is {cmd:pr}, such as {cmd: logit}.{p_end}
{p2col :other}None of the above, such as {cmd: regress}.{p_end}
{p2line}

{p 6 6 2}
Categorical or binary models assume all outcomes
unless either {cmd:outcome()} is specified
or the marginal prediction is specified using the {cmd:margins} options
{cmd:predict()} or {cmd:expression()}.

{marker matrices}
{dlgtab:Matrices that are created}

{p2colset 7 26 27 0}
{p 6 6 2}
Matrices with the displayed results are saved to memory if the statistic is
shown in the table (controlled by {cmd:statistics()}).
{p_end}

{p2colset 10 28 29 12}{...}
{p2col :Name} Description{p_end}
{p2line}
{p2col :{bf:_mtab_display}} The displayed table.{p_end}
{p2col :{bf:_mtab_atdisplay}} The displayed values of at-variables.{p_end}
{p2line}

{p2colset 7 26 27 0}
{p 6 6 2}
To view these matrices, use the {cmd: matrix list} command.
{p_end}

{synopt:{opt mat:rix(name)}}
Save {cmd: _mtab_display} to the matrix named {it:matrix-name}. If the matrix
    exists, it will be over-written. By default, {cmd: _mtab_display} is saved as
    {cmd: r(table)} in Stata's memory.
    {cmd: _mtab_atdisplay} is saved as {cmd: r(atspec)} by default
    in Stata's memory.


{marker returns}{...}
{dlgtab:Returns}

{p2colset 7 24 25 0}
{p 6 6 2}
{cmd:r(table)} is a matrix with the results shown in the prediction table.

{p 6 6 2}
{cmd:r(atspec)} is a local with the at-specification used in making predictions.


{marker examples}{...}
{dlgtab:Examples}

{pstd}
{ul:Example 1: Computing probabilities for two levels of a categorical variable}
{p_end}

{phang2}{cmd:. spex logit}{p_end}
{phang2} {cmd:. mtable, at(wc=(0 1)) atmeans}{p_end}

{pstd}
{ul:Example 2: Stacking multiple mtable commands, labeling row equations}
{p_end}

{phang2}{cmd:. spex ologit}{p_end}
{phang2}{cmd:. mtable, at(female=(0 1)) roweqnm(MEM) atmeans}{p_end}
{phang2}{cmd:. mtable, at(female=(0 1)) roweqnm(AME) below}{p_end}

{pstd}
{ul:Example 3: Changing displayed statistics}
{p_end}

{phang2}{cmd:. spex ologit}{p_end}
{phang2}{cmd:. mtable, at(age=(30(15)60) year=3) stat(ul ll z)}{p_end}

{pstd}
{ul:Example 4: Changing estimate name}
{p_end}

{phang2}{cmd:. spex logit}{p_end}
{phang2}{cmd:. mtable, estname(Estimate)}{p_end}

{pstd}
{ul:Example 5: Viewing matrix of results }
{p_end}

{phang2}{cmd:. spex mlogit}{p_end}
{phang2}{cmd:. mtable, matrix(store_results)}{p_end}
{phang2}{cmd:. matrix list store_results}{p_end}

{pstd}
{ul:Example 6: Changing variables shown using atvar()}
{p_end}

{phang2}{cmd:. spex nbreg}{p_end}
{phang2}{cmd:. mtable, at(female=(0 1) married=(0 1) kid5=(1 2) ) atvar(female)}{p_end}

{pstd}
{ul:Example 7: Computing probabilities with means conditioned on an if statement}
{p_end}

{phang2}{cmd:. spex ologit}{p_end}
{phang2}{cmd:. mtable if female==1, at(white=(0 1)) atmeans}{p_end}

INCLUDE help spost13_footer
