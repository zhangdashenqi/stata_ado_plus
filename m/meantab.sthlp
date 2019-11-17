{smcl}
{* $Id: personal/m/meantab.sthlp, by Keith Kranker <keith.kranker@gmail.com> on 2012/01/07 18:04:57 (revision 9f1d00439570 by user keith) $ }
{* $Date$}{...}
{cmd:help meantab}
{hline}

{title:meantab}

{p2colset 5 18 20 2}{...}
{p2col:{hi:meantab }{hline 2}}Summary statistics, with columns separated by a categorical variable.{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab:meantab} {varlist} 
{ifin} {weight} 
, over({it:catvarname})
[{it:options}] 

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main options}
{synopt:{opt t:stat}}Row with t-statistics.{p_end}
{synopt:{opt d:ifference}}Last column reports differences.{p_end}
{synopt:{opt nob:lank}}In the main table, do not display a blank row between variables. {p_end}
{synopt:{opt nose}}In the main table, do not display standard errors.{p_end}
{synopt:{opt nonb:elow}}Remove row at the bottom of table with number of individuals in each group.{p_end}
{synopt:{opt nonce:lls}}Remove row for each variable with number of individuals in the calculation.{p_end}
{synopt:{opt noncol:umn}}Remove row with number of observations when {opt nocells} is called.{p_end}
{synopt:{opt m:issing}}Treat missing values in {it:catvarname} (either . or "") as a category.{p_end}
{synopt:{opt case:wise}}Perform casewise deletion of observations.{p_end}
{synopt:{opt svy}}Use complex survey data.{p_end}

{syntab:Display options}
{synopt:{opt nois:ily}}Display extra results, including mean command output and tstat regression output.{p_end}
{synopt:{opt nomat:rix}}Suppress display of e(table).{p_end}
{synopt:{opt f:ormat("%fmt")}}Specify format for display of table matrix.{p_end}
{synopt:{opt savef:ormat("%fmt")}}Specify format for to use when saving mean and standard error in matrix (and thereore display).{p_end}
.{p_end}

{syntab:Estimation table options}
{synopt:{opt estout}}Use e(b) and e(V) columns to contruct an estimation results table.{p_end}
{synopt:{opt level(#)}}Set confidence level for {opt estout} option.{p_end}

{syntab:Mean and regress options}
{synopt:{opt std:ize(varname)}}Variable identifying strata for standardization.{p_end}
{synopt:{opt stdw:eight(varname)}}Weight variable for standardization.{p_end}
{synopt:{opt nostdr:escale}}Do not rescale the standard weight variable.{p_end}
{synopt:{opt vce(vcetype)}}{help vcetype} may be {opt bootstrap} or {opt jackknife}.{p_end}
{synopt:{opt cl:uster(varname)}}Adjust standard errors for intragroup correlation.{p_end}
{synopt:{opt robust}}Passed to regress for tstat estimation.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
  {opt stdize}, {opt stdweight} and {opt nostdrescale} are not allowed with {opt tstat}.{p_end}
{p 4 6 2}
  {opt d:ifference} is only allowed when {it:catvarname} contains only two categories.{p_end}
{p 4 6 2}
  fweights, pweights, aweights, and iweights are allowed; see {help weight}.{p_end}
{p 4 6 2}
  {opt svy} requires that the survey design variables are identified using svyset; see {help svyset}.{p_end}

{title:Description}

{pstd}{cmd:meantab} is used to create a summary statistics table that contains the means 
and standard errors for a number of variables.  Columns in this table are formed by the categorical
variable ({it:catvarname}) and also include an "all" column for all observations included in the row (or the {opt difference} between two columns).  

{pstd}This command is very similar to the command {help mean} with the {opt over} option.  
{cmd:meantab} differs primarily in its treament of missing data.  By default, this program estimates 
the rows for each variable in {varlist} separately.  That is, missing data for one 
variable in {varlist} will not cause the observation to be dropped the rows for other variables in {varlist}.

{pstd}In essence, the program {hi:meantab} runs the command: 

{p 18 8 2}  {cmd:mean} {it:y} {ifin} {weight}, over({it:catvarname})

{pstd}for each variable {it:y} in {varlist}. It then stores the means, standard errors and N in each iteration.

{pstd}The main table is displayed on screen and is stored in a matrix named {cmd:e(table)}.  Additional tables 
are also saved (type {cmd:ereturn list} to see a list).  

{pstd}If you have installed
my other program, {cmd:mat2txt2}, the matrix can be easily exported to a text file for insertion into 
a word processor or spreadsheet.


{title:Options}

{dlgtab:Main Options}

{phang}
{opt tstat} adds an additonal row with the absolute values of t-statistics on 
the coefficients from the regression: 

{p 18 8 2} xi: regress {it:y} i.{it:catvarname} {ifin} {weight}

{pmore} Stata will drop one category by default.  You can {help xi:choose} which category is dropped using

{p 18 8 2} char {it:catvarname}[omit] {c -(}# | "string_literal"{c )-}

{phang}
{opt difference} displays the difference between columns one and two (instead of an "all" column).

{phang}
{opt nonbelow} removes the row at the bottom of table with number of individuals in each group.

{phang}
{opt noncells} removes the row (for each variable) that contains the number of observations in the calculation.

{phang}
{opt noncolumn} prevents a column from being created with the number of observations when {opt nocells} is called. 

{phang}
{opt missing} indicates that missing values in {it:catvarname} (either . or "") are to 
be treated like any other value when assigning groups.

{phang}
{opt casewise} specifies casewise deletion of observations.  Statistics
are to be computed for the sample that is not missing for any of the
variables in {varlist}.  

{pmore}When the {opt casewise} is used without {opt missing}, output should match that
of 

{p 18 8 2}  mean {it:varlist}, over({it:catvarname})

{phang}
{opt svy} types "{bf:svy:}" before the mean command described above (and regress for {opt tstat}).  
Your data should be set up for survey data for this to work.  You will get a conflict if you 
use an option (e.g., cluster) that is not compatible with {opt svy}.


{dlgtab:Display options}

{phang}
{opt noisily} display additional output, including the output from the 
mean commands and the tstat regressions.

{phang}
{opt nomatrix} prevents the display of e(table).

{phang}
{opt format("%fmt")} specifies the format for the display of e(table).

{phang}
{opt:{opt savef:ormat("%fmt")}} specifies a format for to use when saving mean and standard error in matrix (and thereore display).

{dlgtab:Estimation table options}

{phang}
{opt estout} displays an estimation results table.

{pmore}
When this option is called, all the means and standard errors are combined into matrices 
e(b) and e(V).  Stata can then produce a table using these 

{phang}
{opt level(#)} sets the confidence level for {opt estout} option.

{phang}
{opt dof(#)} sets the degrees of freedom for {opt estout} option. Default equals 2.

{phang}
{opt obs(#)} sets the number of observations for {opt estout} option. 
Default equals N under the {opt casewise} option.


{dlgtab:Mean and regress options}

{phang}
{opt stdize(varname)}, {opt stdweight(varname)}, {opt nostdrescale}, 
{opt vce(vcetype)} and {opt cluster(varname)} 
are passed to the {help mean} command for each iteration of the variables in {varlist}.

{phang}
{opt vce(vcetype)} and {opt cluster(varname)}  and {opt robust}
are also passed to the {help regress} command for the {opt difference} or {opt tstat} options.



{title:Other Information}
{* $Id: personal/m/meantab.sthlp, by Keith Kranker <keith.kranker@gmail.com> on 2012/01/07 18:04:57 (revision 9f1d00439570 by user keith) $ }
{phang}Author: Keith Kranker{p_end}

{phang}$Date${p_end}


{title:Example}

{pstd}
An example with nlsw88.dta: 

	{cmd}. sysuse nlsw88, clear

	{cmd}. foreach var of varlist married grade collgrad south smsa hours ttl_exp tenure {c -(}
		replace `var' = . if uniform() < .15   {text}{it: (scatter with missing data)}
		{c )-}
		
	{cmd}. meantab grade collgrad south smsa hours ttl_exp tenure, over(married) tstat
	
	{cmd}. mat2txt2 e(table) e(_m) using "meantab_example.csv", matnames replace    {text}  {it:(if installed)}

	{cmd}. meantab  medage death marriage divorce if (region==1 | region==3), over(region) diff	
	  {it:({stata meantab_example:click to run})}
{* meantab_example}{...}

{title:Also see}

{psee}
Manual:  {hi:[R] summarize}

{psee}
Online:  
{help mean}, {help regress}, {help xi}
, {help mat2txt2} {it:(if installed)}
{p_end}
