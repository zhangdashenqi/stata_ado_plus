{smcl}
{* $Id: personal/n/normdiff.sthlp, by Keith Kranker <keith.kranker@gmail.com> on 2012/01/07 18:15:06 (revision ef3e55439b13 by user keith) $ }
{* $Date$}{...}
{cmd:help normdiff}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{hi:normdiff }{hline 2}}Create a table to compare two groups, including normalized differences.{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab:normdiff} {varlist} 
{ifin} 
, over({it:catvarname})
[{it:options}] 

{synoptset 17 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main options}
{synopt:{opt nonormd:iff}}Don't include normalized differences in main table.{p_end}
{synopt:{opt d:ifference}}Add a column with difference between means (not normalized).{p_end}
{synopt:{opt a:ll}}Add a column with overal mean.{p_end}
{synopt:{opt t:stat}}Add a column with t-statistic.{p_end}
{synopt:{opt p:value}}Add a column with p-value for the null hypothesis of equal means.{p_end}
{synopt:{opt c:asewise}}Perform casewise deletion of observations.{p_end}

{syntab:Options to use a regression to calculate {opt difference}, {opt tstat}, and/or {opt pvalue}}
{synopt:{opt cluster(varname)}, {opt robust}, {opt x(varlist)}, {opt fe}, {opt re}, {opt be}, {opt pa}, {opt i(varname)}, {opt qui:etly}}

{syntab:Display options}
{synopt:{opt n(string)}}Specify location of sample size.  {it:string} must belong to {below|over|total|off}. Default is n(below). {p_end}
{synopt:{opt f:ormat(%fmt)}}Specify the {help format} for display. {p_end}
{synoptline}

{p2colreset}{...}


{title:Description}

{pstd}{cmd:normdiff} is used to create a summary statistics table with a row for each variable in 
{varlist}, comparing the subsamples identified by the categorical
variable ({it:catvarname}).  

{pstd}Columns (1) and (2) are simply means for observations with {it:catvarname} ==0 and ==1, respectively 
(other values are not allowed). When data is missing, the behavior is identical to my
{help meantab} command:  the mean for each variable in {it:varlist} is calculated seperately.

{pstd}The third column calculates the normalized difference between 
the sample means in columns (1) and (2).  This forumla is given in Formula 3 in 
Imbens & Wooldridge (2009, p24).  

{pmore} Delta_x = [ x_1 - x_0 ] / sqrt( S2_1 + S2_0 )  {break}{space 2}{break}
{break} Where x_w is a sample mean and S2_w is the sample varience of the 
{break} the variabe x, for the subsample with  {it:catvarname}==w.

{pstd}You can also add other columns via the options (see below). The main table is displayed on screen 
and is stored in a matrix named {cmd:e(table)}.  Sample sizes are stored in a matrix named cmd(e(_n)).  
Additional results are included other matrix tables.  Type {help ereturn list} for a list.

{pstd}For the difference, tstat, and pvalue options, I allow the option of 
using a regression to calculate the treatment/control groups. If you want this 
to be the case, you can pass the additional options to the regress/xtregress command.  
P-values are always calculated by regression.


{pstd}If you have installed
my other program, {cmd:mat2txt2}, the matrix can be easily exported to a text file for insertion into 
a word processor or spreadsheet.  If you do not want normalized differences, I recommend my other program,
{help meantab}.

{title:Options}

{dlgtab:Main Options}

{phang}{opt nonormdiff} excludes normalized differences from display and from e(table).{p_end}

{phang}{opt a:ll} adds a column with overall means.{p_end}

{phang}{opt difference} adds a column w/ difference between means (not-normalized).* {p_end}
{pmore} {space 4}Column (difference) = Column (2) - Column (1){p_end}

{phang}{opt tstat} adds a column with a t-statistic for the null hypothesis of equal means.  Formula 4 in 
Imbens & Wooldridge (2009, p24).  

{pmore} {space 4}T = [ x_1 - x_0 ] / sqrt( S2_1/N_1 + S2_0/N_0 )  
{break}{space 2}{break}{space 4}where N_w refers to the size of the subsample with data for the variable x.*

{phang}
{opt casewise} specifies casewise deletion of observations.  Statistics
are to be computed for the sample that is not missing for any of the
variables in {varlist}.  

{phang}{opt p:value} adds a column with p-value for the null hypothesis of equal means. 
P-values are calculated with a regression, followed by the {help test} command.{p_end}

{phang}{opt c:asewise} performs casewise deletion of observations.{p_end}


{dlgtab:Options to use a regression to calculate selected columns}

{phang}
The following commands cause the difference, tstat, and/or pvalue colummns to be calculated 
with a regression.  {help regress} is used if one of these options are specified.

{phang}{opt cluster(varname)} and {opt robust} calculate clustered/robust standard errors.

{phang}{opt x(varlist)} passes control variables to the regression. Both adjusted and unadjusted 
differences will be shown.

{phang}{opt quietly} causes the regression output to be supressed from display.

{phang}You can use the {help xtreg} command instead of {help regress:OLS} by using one of the following commands:
{opt fe}, {opt re}, {opt be}, {opt pa}, {opt i(varname)}.  These options are simply passed to {help xtreg}


{dlgtab:Display options}

{phang}
{opt n(below|over|total|off)} specifies the location of sample sizes in the table.

{p 8 15 2}{bf:below}:{space 1}the default, below the table  
{break}(automatically changed to n(over) if N changes by row)

{p 8 15 2}{bf:over}:{space 2}N_0 and N_1 as two additional columns 

{p 8 15 2}{bf:total}:{space 1}N = (N_0 + N_1) as one additional column 

{p 8 15 2}{bf:off}:{space 3}Sample size not displayed

{phang}
{opt format(%fmt)} specifies the {help format} for the display of e(table).  
The default is ususally {opt format(%10.0g)}.


{title:Reference}

{phang} Imbens & Wooldridge  (2009) "Recent Developments in the Econometrics of Program Evaluation."
{it:Journal of Economic Literature}.  March 2009, Volume XLVII, Number 1. ({browse www.aeaweb.org/articles.php?doi=10.1257/jel.47.1.5:link})

{title:Other Information}
{* $Id: personal/n/normdiff.sthlp, by Keith Kranker <keith.kranker@gmail.com> on 2012/01/07 18:15:06 (revision ef3e55439b13 by user keith) $ }
{phang}Author: Keith Kranker{p_end}

{phang}$Date${p_end}

{title:Example}

{pstd}
A meaningless example with nlsw88.dta: 

	{cmd}. sysuse lifeexp, clear
	{cmd}. gen regionSA = (region == 3)

	{cmd}. normdiff popgrowth lexp if region!=2, over(regionSA)
		
	{cmd}. normdiff popgrowth lexp gnppc safewater, over(regionSA) diff tstat n(below) f(%16.4gc)
	
	{cmd}. mat2txt2 e(table) e(_n) using "normdiff_example.csv", matnames replace    {text}  {it:(if installed)}

	  {it:({stata normdiff_example:click to run})}
{* normdiff_example}{...}

{title:Also see}

{psee}
Manual:  {hi:[R] summarize}

{psee}
Online:  
{help mean}, {help regress} , {help xtreg}, {help xi} {break}
{help meantab}, {help mat2txt2} {it:(if installed)}
{p_end}
