{smcl}
{* *! version 1.6.1  14mar2014}{...}
{cmd:help tost}
{hline}


{title:Title}

{p2colset 5 13 15 2}{...}
{p2col:{cmd:tost} {hline 2}}Two one-sided tests of equivalence{p_end}
{p2colreset}{...}


{synoptset 28 tabbed}{...}
{synopthdr:tost commands}
{synoptline}
{syntab:Miscellaneous}
{synopt :{opt tostt}}Mean equivalence {it:t} tests{p_end}
{synopt :{opt tostti}}Immediate command for mean equivalence {it:t} tests{p_end}
{synopt :{opt tostpr}}{it:z} tests of proportion equivalence{p_end}
{synopt :{opt tostpri}}Immediate command for {it:z} tests of proportion equivalence{p_end}
{synopt :{opt tostsignrank}}Tests for stochastic equivalence on paired or matched data{p_end}
{synopt :{opt tostranksum}}Two-sample rank-sum test for stochastic equivalence{p_end}
{synopt :{opt tostmcc}}Paired {it:z}-test for stochastic equivalence in binary data{p_end}
{synopt :{opt tostmcci}}Immediate command for paired {it:z}-test for stochastic equivalence in binary data{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
The {net "describe tost, from(http://doyenne.com/stata)":tost} package provides a suite of commands to perform 
two one-sided tests of equivalence corresponding to the {help ttest} & 
{help ttesti}, {help prtest} & {help prtesti}, {help mcc} & {help mcci}, 
{help signrank} and {help ranksum} tests of difference, thus addressing 
inference about equivalence for a number of paired and unpaired, parametric and 
nonparametric study designs and data types.  Each command tests a null 
hypothesis that samples were drawn from populations different by at least plus 
or minus some researcher-defined level of tolerance, which can be defined in 
terms of units of the data or rank units (Delta), or in units of the test 
statistic's distribution (epsilon).  Enough evidence rejects this null 
hypothesis in favor of equivalence within the tolerance.  Equivalence intervals
for all tests may be defined symmetrically or asymmetrically.

{pstd}
These tests are equivalence tests are all more or less based on the {it:t} and 
{it:z} tests following the logic laid out by Schuirmann ({help tost##Schuirmann1987:1987}),
but with variations as detailed in the help files for each command.  All the 
{help tost} commands are based on a Wald-type test, where some difference in 
sample statistics is divided by the standard deviation of that difference: 
theta/st.dev. theta. A general test for equivalence null hypothesis takes one 
of the following two forms depending on whether equivalence is defined in terms 
of Delta, or epsilon:{p_end}

{p 8}
Ho: |theta| >= Delta, {p_end}
{p 8 8}where the equivalence interval ranges from theta-Delta to theta+Delta. 
This translates  directly into two one-sided null hypotheses: {p_end}

{p 12}
Ho1: Delta - theta <= 0; and{p_end}

{p 12}
Ho2: theta + Delta <= 0{p_end}

{p 8}
-OR-

{p 8}
Ho: |{it:t}| >= epsilon, (may substitute {it:z} for {it:t} in these expressions){p_end}
{p 8 8}where the equivalence interval ranges from -epsilon to epsilon. This also 
translates directly into two one-sided null hypotheses: {p_end}

{p 12}
Ho1: epsilon - z <= 0; and{p_end}

{p 12}
Ho2: z + epsilon <= 0{p_end}

{p 8 8}
When an asymmetric equivalence interval is defined using the the general 
negativist null hypothesis becomes:{p_end}

{p 8}
Ho: theta <= Delta_lower, or theta >= Delta_upper,{p_end}
{p 8 8 }
where the equivalence interval ranges from theta+Delta_lower to 
theta+Delta_upper. This also translates directly into two one-sided null 
hypotheses:{p_end}

{p 12}
Ho1: Delta_upper - theta <= 0; and{p_end}

{p 12}
Ho2: theta - Delta_lower <= 0{p_end}

{p 8}
-OR-

{p 8}
Ho: z <= epsilon_lower, or z >= epsilon_upper, and{p_end}

{p 12}
Ho1: epsilon_upper - z <= 0; and{p_end}

{p 12}
Ho2: z - epsilon_lower <= 0{p_end}


{title:Author}

{pstd}Alexis Dinno{p_end}
{pstd}Portland State University{p_end}
{pstd}alexis dot dinno at pdx dot edu{p_end}

{pstd}
Development of {net "describe tost, from(http://doyenne.com/stata)":tost} is ongoing, please contact me with any questions, bug 
reports or suggestions for improvement.{p_end}


{title:References}

{marker Schuirmann1987}{...}
{phang}
Schuirmann, D. A. 1987. A comparison of the two one-sided tests procedure and 
the power approach for assessing the equivalence of average bioavailability. 
{it:Pharmacometrics}. 15: 657-680

{title:Also See}

{psee}
{space 2}Help: {help tostt}, {help tostpr}, {help tostsignrank}, {help tostranksum}, {help tostmcc}

