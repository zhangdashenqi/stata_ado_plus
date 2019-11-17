{smcl}
{* version 2.1 of help file  8Feb2016 for -bivariate.ado- Version 2.2, 9Feb2016}{...}
{vieweralsosee "[R] tabstat" "mansection R tabstat"}{...}
{vieweralsosee "[MV] Linear discriminant analysis" "mansection MV discrimlda"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] tabstat" "help tabstat"}{...}
{vieweralsosee "[MV] discrim lda" "help discrim_lda"}{...}
{vieweralsosee "User written frmttable" "help frmttable"}{...}
{vieweralsosee "User written outreg" "help outreg"}{...}
{vieweralsosee "User-written sumtable" "help sumtable"}{...}
{vieweralsosee "User-written partchart" "help partchart"}{...}
{vieweralsosee "User-written esttab" "help esttab"}{...}
{viewerjumpto "Syntax" "bivariate##syntax"}{...}
{viewerjumpto "Description" "bivariate##description"}{...}
{viewerjumpto "Options" "bivariate##options"}{...}
{viewerjumpto "Remarks" "bivariate##remarks"}{...}
{viewerjumpto "Examples" "bivariate##examples"}{...}
{viewerjumpto "Stored results" "bivariate##results"}{...}
{viewerjumpto "Author" "bivariate##author"}{...}
{title:Title}

    {hi:bivariate} - Bivariate associations of a dependent variable with each independent variable

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:bivariate} {depvar} [{indepvars}] {ifin} {weight}
   [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main options}
{synopt:{opt novif}}suppresses the computation and display 
of the "Variance Inflation Factor."   Unless suppressed, 
the last column of the output presents the VIF score 
from Stata's {help estat vif} command.{p_end}
{synopt:{opt unc:entered}}specifies that the VIF should be
"uncentered."  See {help estat vif} for details. This option is
not compatible with the option {opt novif}{p_end}
{synopt:{opt l:ist}}specifies that all factor-variable operators and 
time-series operators be removed from {cmd:indepvars}.{p_end}
{synopt:{opt row:names(eqname|varname)}}{p_end}
{synopt:}For dummy variables in the independent variables list, 
appends the value label of the larger value of the dummy as either 
the prefix (eqname) or the suffix (varname) of the row label{p_end}
{synopt:{opt obsg:ain}}requests an additional column of output
which gives the number of additional observations that would be gained
by omitting the designated variable from {cmd:indepvars}.{p_end}
{synopt:{opt m:atrix(matrixname)}}specifies the name of the matrix of 
bivariate statistics returned as {cmd:r({it:matrixname})}.  
Default is to return matrix in {cmd:r({it:bivariate})}{p_end}
{syntab:Tabstat options}
{synopt:{opt t:abstat}}provide univariate summary statistics 
on dependent and all independent variables using casewise deletion{p_end}
{synopt:{opt f:ormat}[{cmd:(%}{it:{help format:fmt}}{cmd:)}]}display format 
for {cmd:tabstat} statistics; default format is {cmd:%9.0g}{p_end}
{synopt:{opt addstat(tabstat_statname_options)}}{p_end}
{synopt:}specifies that the {cmd:tabstat} output contain additional statistics. 
See {help tabstat##statname:tabstat help} for a list of available statistics.{p_end}
{syntab:Groupstat options}
{synopt:{opt group}{cmd:(}{it:{categorical_variable}}{cmd:)}}{p_end}
{synopt:}Use Stata's {help discrim_lda} command and its postestimation command {cmd: estat grsummarize} 
to construct a table of summary statistics for every value of {it: categorical_variable}.{p_end}
{synopt:{opt groupst:ats(statlist)}}{p_end}
{synopt:}Specify the summary statistics to be computed for each variable and each 
value of {it: categorical_variable}.  The available options are listed 
{help discrim_estat##options_estat_grsummarize:here}.{p_end}
{synopt:{opt nowide}}Specify that the returned matrix of groups statistics be in 
long format.  The default is for it to be in wide format.{p_end} 
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:by} is not allowed; see {manhelp by D}.{p_end}
{p 4 6 2}
{cmd:weight}s are in beta, to be used with care; see {help weight}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:bivariate} produces a table of bivariate associations between a dependent 
variable and each of a set of indpendent variables.
Unless it is suppressed by the option {cmd:novif}, the last column presents the 
{browse "http://en.wikipedia.org/wiki/Variance_inflation_factor":variance inflation factor}
(VIF) for each of the independent variables as computed by Stata's {help estat vif} command. 
All calculations are performed on the subset of observations not missing for any of the variables in the analysis (i.e. "casewise deletion").

{pstd}
If the {cmd:tabstat} option is chosen, {cmd:bivariate} groups the observations by categories of the grouping variable
and displays the summary statistics for each category in a separate columen.

{pstd}
If the {cmd:group} option is chosen, {cmd:bivariate} also produces a table containing similar descriptive statistics 
on the same sample, with a column for each level of the grouping variable.

{pstd}
For categorical variables with more than two values, prefix {cmd:i.} to the variable name so that each level of the
the categoriacal variable is treated as a dummy variable.  See {help factor variables}

{marker options}{...}
{title:Options}

{phang}
{opth row:names(eqname|varname)} For dummy variables in the independent variables list, 
	appends the value label of the larger value of the dummy as either the prefix 
	({cmd:eqname}) or the suffix ({cmd:varname}) of the row label{p_end}

{phang}
{opt obsgain} requests an additional column of output
which gives the number of additional observations that would be gained
by omitting the designated variable from {cmd:indepvars}.  This option 
is sometimes more informative when combined with the {cmd:list} option.
The variable which most constrains the sample size is returned 
in the local macro {cmd:r(maxobsgainvar)} and the number of observations added 
by dropping that variable is returned in {cmd:r(maxobsgain)}. {p_end}

{phang}
{opt t:abstat} requests the optional table of univariate descriptive statistics 
	on the complete list of variables with casewise deletion.  The table is saved 
	in matrices {cmd:r({it:StatTotal})} and {cmd:r({it:TransposedST})}.  
	Since it is common to all the variables in the table, the number 
	of observations is excluded from the tabstat output on each variable, 
	but is instead separately saved in {cmd:r({it:N})}. 

{phang}
{opt format} and {cmd:format(%}{it:{help format:fmt}}{cmd:)} specify how the descriptive
   statistics are to be formatted.  The default is to use a {cmd:%9.0g} format.

{pmore}
   {opt format} without (%{it:{help format:fmt}}{cmd:)} specifies that each variable's statistics be formatted
   with the variable's current display format; see {manhelp format D}.

{pmore}
   {cmd:format(%}{it:{help format:fmt}}{cmd:)} specifies the format to be used for all
   statistics.  The maximum width of the specified format should not exceed
   nine characters.

{phang}
{opt l:ist} specifies that all factor-variable operators and 
	time-series operators be removed from {cmd:indepvars} and that the descriptive statistics 
	output be computed on the resulting list of base variables.  
	This is an option of the Stata command {help fvrevar}.
	Use this option with care, since statistics like the mean 
	or the correlation coefficient which are computed on a polytomous, 
	nominal factor variable are likely to be nonsense. Rarely used{p_end}

{phang}
{opth m:atrix(matrixname)} designates a specific name for the saved matrix of bivariate results.  
   If the option is chosen, the matrix of bivariate results is saved as {cmd:r({it:matrixname})}.  
   The default name is {cmd:r(bivariate)}.

{marker remarks}{...}
{title:Remarks}

{pstd}
The {cmd:bivariate} command is designed to precede a command 
like {cmd:regress} in order 
to provide bivariate and (optionally) descriptive statistics 
on the same variables over the same sample
as used in the subsequent {cmd:regress} command.  Like {cmd:regress}, 
the {cmd:bivariate} command assumes the first variable is the dependent 
variable and the rest are independent variables.

{pstd}
For continuous independent variables, {cmd:bivariate} presents the correlation coefficient 
of each independent variable wih the dependent variable and the t-statistic of
test of the null hypothesis that the correlation coefficient is zero, with a 
p-value giving the significance level at which this hypothesis can be rejcted 
against a two-sided alternative.

{pstd}
If {cmd:bivariate} detects that a variable in the variable list is dichotomous, 
it assumes that it is a dummy variable.  Instead of presenting the correlation 
coefficient, it presents the mean of the dependent variable for each of the two
values of that dichotomous variable.  In this case, the t-statisitc tests the
hypothesis that the two means are identical, while the p-value gives the 
signficance level at which this null can be rejected against a two-sided 
alternative.

{pstd}
The list of independent variables for the bivariate command, {indepvars},
can include {help factor variables}.  In the output, these variables are
expanded into temporary variables matching those used 
in a subsequent estimation command.  If the option {cmd:list} is added,
the factor variables are not disassembled, but the {cmd:bivariate} statistics
on these unexpanded factor variables may be uninterpretable or irrelevant.
The {cmd:list} option can be combined with the {cmd:obsgain} option to
diagnose the degree to which missing observations on some {indepvars} are 
constraining the sample size.

{pstd}
Unless the option {cmd: novif} is specified, the right-most column
of {cmd:bivariate}'s output displays the 
{browse "http://en.wikipedia.org/wiki/Variance_inflation_factor":variance inflation factor}
for each independent variable as computed by Stata's {help estat vif} command.
For independent variable Xj, the {cmd: VIF} is defined as:

{p 12 6 2}
VIFj  =  1/ ( 1 - R^2j)

{pstd}
where R^2j is the R^2 of the regressio of Xj in all the other independent variables.  
See {browse "http://ideas.repec.org/c/boc/bocode/s456301.html": ivvif} 
for an expanded calculation of VIF's in the context of instrumental variable regression. 

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto}{p_end}

{pstd}Produce a table of bivariate statistics measuring the strength 
of two-way association between the dependent variable and 
each of the independent variables and append a table of 
descriptive univariate statistics.{p_end}
{phang2}{cmd:. bivariate price weight mpg rep78 foreign, tabstat obsgain}{p_end}

{pstd}Note that the last column of bivariate output, labeled {cmd:obsgain}, 
indicates that the variable {cmd:rep78} is constraining the sample size for the regression
because it has 5 fewer observations than do the other variables.
Now let's see what {cmd:bivariate} returns to the user.{p_end}
{phang2}{cmd:. return list}{p_end}

{pstd}In addition to the descriptive statistics, the program returns 
in local {cmd:r(...)} macros the identity of the variables 
with the largest values of the VIF and of {cmd:obsgain}.   

{pstd}Demonstrate that the descriptive statistics produced above 
are for the same sample that would be used in the corresponding regression command.{p_end}
{phang2}{cmd:. regress price weight mpg rep78 foreign}{p_end}
{phang2}{cmd:. gen byte insample = e(sample)}{p_end}
{phang2}{cmd:. summ price weight mpg rep78 if insample}{p_end}
{phang2}{cmd:. tab foreign if insample, sum(price)}{p_end}

{pstd}The matrices of bivariate statistics 
and of descriptive statistics (if requested by the option {opt t:abstat}) 
can be formatted for cleaner listing and 
can be retrieved for export.{p_end}
{phang2}{cmd:. bivariate price weight mpg rep78 foreign, tabstat format(%9.3f)}{p_end}
{phang2}{cmd:. matrix list r(bivariate)}     //  Or use matlist  {p_end}
{phang2}{cmd:. matrix list r(TransposedST)}  //  Available with the -tabstat- option {p_end}

{pstd}John Luke Gallup's program {search frmttable} can be used to produce publishable versions of the 
matrices returned by {cmd: bivariate}. For example, after executing the following two commands, 
open the MS Word file called "word.doc" to see the resulting table:{p_end}
{phang2}{cmd:. bivariate price weight mpg rep78 foreign, novif}{p_end}
{phang2}{cmd:. frmttable using word, replace statmat(r(bivariate))} 
{cmd:rtitles("Vehicle weight" \ "Miles per gallon" \ "Repair record" \ "Foreign or domestic")}
{cmd:sdec(3,0,0,2,3,1,0) title("Table _. Bivariate relationships between vehicle price and each independent variables")}{p_end}

{pstd}Another way to use the programs together is
with the options {cmd:group} and {cmd:groupstats}.{p_end}
{phang2}{cmd:. bivariate price weight mpg rep78, group(foreign) groupstats(n mean sd)}{p_end}
{phang2}{cmd:. matrix list r(grouptab)}{p_end}
{phang2}{cmd:. frmttable, statmat(r(grouptab))}{p_end}
{phang2}{cmd:. frmttable, statmat(r(frmttable)) substat(1)}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{syntab:scalars:}
{synopt:{opt r(N)}}Number of observations on which all variables are present{p_end}
{synopt:{opt r(maxobsgain)}}Maximum number of observations to be gained by omitting a single variable (if {opt obsg:ain} specified){p_end}
{synopt:{opt r(maxvifval)}}Maximum value of the VIF statistic (unless {opt novif} is specified){p_end}
{synopt:{opt r(meanvif)}}Mean value of the VIF statistic (unless {opt novif} is specified){p_end}

{syntab:macros:}
{synopt:{opt r(maxobsgainvar)}}Name of the variable which, if omitted, would most increase the number of observations(if {opt obsg:ain} specified){p_end}
{synopt:{opt r(maxvifvar)}}Name of the variable with the highest VIF statistic{p_end}
{synopt:{opt r(N_stats)}}Number of statistics requested in the {opt groupst:ats(statlist)} option (excluding n){p_end}
{synopt:{opt r(statlist)}}Names of the statistics included in the {opt groupst:ats(statlist)} option (excluding n){p_end}

{syntab:matrices:}
{synopt:{opt r(bivariate)}}Main results of the {cmd:bivariate} command stored as 
a matrix with K-1 rows, where K is the number of variables in {it:varlist}.
If the {opt m:atrix(matrixname)} option has been specified, the same results are stored 
in a matrix called {opt r(matrixname)}.{p_end}
{synopt:{opt r(vifmat)}}VIF statistics for the K-1 variables, sorted from largest to smallest (unless {opt novif} is specified){p_end}
{synopt:{opt r(grouptab)}}Results of the {opt group(varlist)} and {opt groupst:ats(statlist)}} options, if specified{p_end}
{synopt:{opt r(StatTotal)}}Results of the {help tabstat} option, if specified. Dimension S x K, where S is 7 plus the number of additional requested statistics in the option {opt addstat}{p_end}
{synopt:{opt r(TransposedST)}}Transposed r(StatTotal) of dimension K x S (if {help tabstat} option specified){p_end}


{marker author}{...}
{title:Author}

{p 4 8 20} 
{browse "http://www.cgdev.org/expert/mead-over/":Mead Over},
Center for Global Development, Washington, DC 20036 USA. Email:
{browse "mailto:mover@cgdev.org":MOver@CGDev.Org} if you observe any
problems. 
