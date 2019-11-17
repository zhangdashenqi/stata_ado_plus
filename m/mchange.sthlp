{smcl}
{* 2014-08-06 scott long & jeremy freese}{...}
{title:Title}
{p2colset 5 16 23 2}{...}

{p2col:{cmd:mchange} {hline 2}}Marginal effects for regression models{p_end}
{p2colreset}{...}


{title:General syntax}

{p 4 18 2}
{cmdab:mchange }
[{it:varlist}]
{it:[if]}
{it:[in]}
{cmd:,}
[ {it:mchange-options}
{it:margins-options} ]

{p 6 6 2}
where {it:varlist} is a list of regressors for which changes are to be
computed. If no name is specified, changes for all independent variables
are computed.
{p_end}

{marker overview}
{title:Overview}

{pstd}
{cmd:mchange} uses {helpb margins} to compute marginal
effects for a regression model.
Both marginal changes (partial derivatives) and discrete changes can be
computed. Discrete changes of one, a standard deviation, from 0 to 1,
over the range, over a trimmed ranged, or for a specific increase from the
observed value can be computed.
{p_end}

{pstd}
Average marginal effects (AME) are computed by averaging over the sample.
Marginal effects at the mean (MEM) and marginal effects at representative value (MER) are computed using
{cmd:atmeans} and {cmd:at()} options.
Prior to Stata 13, standard errors and tests of AME's for discrete changes of 1, a standard deviation,
or a fixed amount from the observed value cannot be computed.
{p_end}

{pstd}
{cmd:mchange} works with models specified with factor variables and interactions
using {helpb fvvarlist:factor variable notation}.
It should work with any regression command supported by {cmd:margins},
although we have not tried every model.
{p_end}


{title:Options}

{p 2 10 2}
{it:Amount of change options}

{p 6 6 2}
{opt am:ount(change-amounts)}
{opt trim(integer-trim%)}
{opt delta(number)}
{opt center:ed}

{p 2 10 2}
{it:Statistics to compute}

{p 6 6 2}
{opt stat:istics(statistics-names)}
{opt out:comes(values)}
{opt pr(values)}
{opt cpr(values)}
{opt level(values)}

{p 2 10 2}
{it:Fixed values of independent variables}

{p 6 6 2}
{opt at(atspec)}
{opt atmean:s}

{p 2 10 2}
{it:Output controls}

{p 6 6 2}
{opt brief}
{opt command:s}
{opt dec:imals(integer)}
{opt desc:riptives}
{opt det:ails}
{opt mat:rix(matrix-name)}
{opt title(title-string)}
{opt wid:th(integer)}


{title:Options}
{p 8 10 2}

    {help mchange##levels:Specifying values of independent variables}
    {help mchange##amount:Selecting the amount of change}
    {help mchange##stats:Selecting statistics to display}
    {help mchange##output:Options controlling output}
    {help mtable##returns:Returns}

{marker levels}
{dlgtab:Setting values of independent variables}
{pstd}

{pstd}
Predictions are computed using {cmd:margins}. If values of independent variables
    are specified, predictions are computed at these values. For variables
    whose values are not specificed, changes are averaged across observed values
(i.e., {cmd:margins}' {cmd:asobserved} option).
{p_end}
{p2colset 7 20 21 0}
{synopt:{opt at(atspec)}}
where {help margins##atspec:atspec} is set in the same way as with {cmd:margins},
such as {cmd:at(wc=0 k5=0 age=50)}.
With {cmd:mchange} multiple values of a variable cannot be
specified (e.g., {cmd:at(wc=(0 1))}).

{synopt:{opt atmeans}}
All variables not specified with {cmd:at()} are held at their means.
If {cmd:if} or {cmd:in} are used to specify the sample, the means are
computed for the selected observations.

{marker amount}
{dlgtab:Amount of changes}
{pstd}

{pstd}
By default a change from 0 to 1 is computed for factor variables entered
with the {cmd:i.}{it:varname} notation (see {helpb fvvarlist:factor variable notation}).
For continuous variables, marginal changes (i.e., partial derivatives)
and discrete changes of one and a standard deviation are computed.
{p_end}

{pstd}
These defaults can be changed with {opt amount(amount-list)}
where the amount list can contain the following:
{p_end}

{p2colset 10 22 22 12}{...}
{p2col :Option}Amount of change{p_end}
{p2line}
{p2col :{bf:all}}All types of changes are computed.{p_end}
{p2col :{opt b:inary}}Change from 0 to 1.{p_end}
{p2col :{opt m:arginal}}Marginal rate of change.{p_end}
{p2col :{opt o:ne}}Change by 1.{p_end}
{p2col :{opt r:ange}}Change over range or trimmed range; see {cmd:trim()}.{p_end}
{p2col :{bf:sd}}Change by the regressor's standard deviation or by the
amount specified by {cmd:delta()}. {cmd:delta} is a synonym for
{cmd:sd}.{p_end}
{p2line}
{p2colset 7 21 22 0}
{pstd}
The range can be trimmed and an amount other than
a standard deviation can be computed with these options:
{p_end}

{synopt:{opt delta(#)}}
Change by {it:#} units instead of a standard deviation change
(e.g., {cmd:delta(4)} computes a change of 4).

{synopt:{opt trim(#)}}
Instead of computing change over the range, trim the range by this
percentile from each end of the distribution.

{synopt:{opt level(#)}}
Specified the default confidence intervals, from 10 to 99.99.

{synopt:{opt cen:tered}}
By default changes of one, a standard deviation are for an increase of these
amounts from the value of the independent variable. That is, they are {bf:uncentered} changes.
Centered changes of one, a standard deviation, or delta are
computed by adding half the value above and half the value below the value of the regressor
(e.g., mean-sd/2 to mean+sd/2).

{marker stats}
{dlgtab:Statistics}
{pstd}

{pstd}
By default the estimate of change and the p-value for a test that the
change is 0 are displayed. Other statistics can be requested with
{opt stat:istics(stat-list)}. {cmd:stats()} is a synonym.

{p2colset 10 20 19 12}{...}
{p2col :Option}Statistic{p_end}
{p2line}
{p2col :{opt ci}}Confidence interval along with change.{p_end}
{p2col :{opt all}}All statistics.{p_end}
{p2col :{opt ch:ange}}Discrete or marginal change.{p_end}
{p2col :{opt p:value}}p-value for test change is 0.{p_end}
{p2col :{opt se}}Standard error of the estimated change.{p_end}
{p2col :{opt z:value}}z-value of test change is 0.{p_end}
{p2col :{opt ll}}Lower level of CI.{p_end}
{p2col :{opt ul}}Upper level of CI.{p_end}
{p2col :{opt st:art}}Start value for discrete change.{p_end}
{p2col :{opt en:d}}End value for discrete change.{p_end}
{p2line}
{p2colset 7 25 26 0}
{pstd}
For models with multiple outcomes or outcome probabilities, you can specify
the values for which statistics are to be computed. Statistics are then
computed for all specified values.
{p_end}

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

{marker output}
{dlgtab:Controlling output}
{pstd}

{pstd}
How output is displayed is controlled by these options.
{p2colset 7 23 24 0}

{synopt:{opt brief}}
Do not show base values, values of r(at) matrix, or
details on how changes were computed.

{synopt:{opt desc:riptive}}
Show table of descriptive statistics.

{synopt:{opt title(title)}}
Label the output with this title.

{synopt:{opt dec:imals(#)}}
Number of decimal digits to display.

{synopt:{opt wid:th(#)}}
Width of columns displaying statistics.

{synopt:{opt command:s}}
Display the commands used with {cmd:margins} without the output.

{synopt:{opt det:ails}}
Display the sometime lengthy output from {cmd:margins} and {cmd:lincom} used
to compute the changes. {cmd:verbose} is a synonym.


{marker returns}{...}
{dlgtab:Returned results}
{p2colset 7 23 24 0}

{synopt:{bf:r(atspec)}}
a local with the at-specification used.

{synopt:{bf:r(atconstant)}} a matrix containing the constant values if any
    of the independent variables when predictions were made.

{synopt:{bf:r(basepred)}} a matrix with the predictions at the baseline values or
averaged over the sample depending on options used.

{synopt:{bf:r(centering)}}
a local indicating if centered or uncentered changes were computed.

{synopt:{bf:r(changes)}} a matrix containing the all changes and statistics
even if not displayed. This is also saved in the matrix {cmd:_mchange} which
is used by {cmd:mchangeplot} and {cmd:mlogitplot}.

{synopt:{bf:r(table)}} a matrix containing the displayed results.

{synopt:{opt matrix(matrix-name)}}
The matrix r(table) is saved as {it:matrix-name}.
{p_end}


{marker examples}{...}
{dlgtab:Examples}

{pstd}
{ul:{bf:Example 1: Average marginal effects of all variables in model}}{p_end}

{phang2}{cmd:. spex logit}{p_end}
{phang2}{cmd:. mchange}{p_end}

{pstd}
{ul:{bf:Example 2: Changing displayed statistics}}{p_end}

{phang2}{cmd:. spex logit}{p_end}
{phang2}{cmd:. mchange, stat(change z start end) dec(4)}{p_end}

{pstd}
{ul:{bf:Example 3: Marginal effects at specific values}}{p_end}

{phang2}{cmd:. spex logit}{p_end}
{phang2}{cmd:. mchange, at(wc=0 hc=1)}{p_end}

{pstd}
{ul:{bf:Example 4: Marginal effects only for certain values of outcome}}{p_end}

{phang2}{cmd:. spex ologit}{p_end}
{phang2}{cmd:. mchange, outcome(2)}{p_end}

{pstd}
{ul:{bf:Example 5: Adjust amount of change for discrete change}}{p_end}

{phang2}{cmd:. spex ologit}{p_end}
{phang2}{cmd:. mchange income, amount(sd) delta(15)}{p_end}

INCLUDE help spost13_footer
