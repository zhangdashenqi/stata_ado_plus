
{smcl}
{.-}
help for {cmd:panelstat} {right:()}
{.-}
 
{title:Title}

panelstat - Provides a detailed characterization of a panel data set.

{title:Syntax}

{p 8 15}
{cmd:panelstat} {it:panelvar} {it:timevar} ] [{help if}] [{help in}] , [{it:options}]

{p}

{title:Description}

{p} 
This command analyzes a panel data set and produces a full characterization of the panel structure. 
The command is implemented for a typical panel and requires both a panel variable and a time variable. 
 
{title:Options}

General Options

{p 0 4}{cmd: CONT} the time variable ignores a time gap common to all individuals in that period. For example, if you have yearly data
from 2000 to 2010 but no observation recorded in 2005, it would ignore the year of 2005 in all calculations

{p 0 4} {cmd:FORCE1} if the panel has multiple individual observations per time unit it forces the command to run by keeping only one observation per {it:panelvar} X {it:timevar} pair

{p 0 4} {cmd:FORCE2} similar to {cmd:FORCE1} but drops all observations with multiple individual observations per time unit

Basic Descriptives

{p 0 4}{cmd: GAPS} characterizes the (temporal) gap structure of the data set

{p 0 4}{cmd: RUNS} provides information about complete "runs" on the data, where a "run" is a sequence of consecutive values for the same individual

{p 0 4}{cmd: PATTERN} shows the most common patterns of the data set

{p 0 4}{cmd: DEMO} characterizes the flows that occur in consecutive time periods

{p 0 4}{cmd: NOSUM} does not report summary statistics for the panel

{p 0 4}{cmd: ALL} selects the four options {cmd: gaps}, {cmd: runs}, {cmd: pattern} and {cmd: demo}

Advanced Descriptives

{p 0 4} {cmd:TABOVERT(}{it:varlist}{cmd:)} creates a tabulation of the variables in {it:varlist} along the time dimension. It is meant for use with categorical variables

{p 0 4} {cmd:WIV}({it:varlist}{cmd:} [, {cmd:keep}]) provides statistics for {it:varlist} along the {it:panelvar} dimension. With the option {cmd:keep} it creates individual level variables with stub {it:_wiv_var}

{p 0 4} {cmd:WTV}({it:varlist}{cmd:} [, {cmd:keep}]) provides statistics for {it:varlist} along the {it:timevar} dimension.  With the option {cmd:keep} it creates time level variables with stub {it:_wtv_var}

{p 0 4} {cmd:ABS}({it:varlist} [ ,{cmd:keep}]) reports on absolute changes over time for each variable in {it:varlist}. With the option {cmd:keep} it creates variables of type {it:_abs_var} indicating the type of change.  

{p 0 4} {cmd:REL}({it:varlist} [ ,{cmd:keep}]) reports on relative changes over time for each variable in {it:varlist}. With the option {cmd:keep} it creates variables of type {it:_rel_var} indicating the type of change.  

{p 0 4} {cmd:QUANTR}({it:varlist} [ ,{cmd:keep} {cmd:rel} ]) computes year to year changes for quantiles of {it:varlist}. With the option {cmd:keep} it creates variables of type {it:_quantr_var} indicating the type of change.
With the option {cmd:rel} it presents the table as row standardized. It is meant for use with continuous variables

{p 0 4} {cmd:FLOWS(}{it:varlist}{cmd:)} decomposes the changes on the sum of the time observations for each variable in {it:varlist}

{p 0 4} {cmd:TRANS(}{it:varlist}{cmd:)} calculates the share of individuals that have the same movement across categories of {it:varlist} from t-1 to t. It is meant for use with categorical variables

{p 0 4} {cmd:CHECKID(}{it:var}{cmd:)} compares the variable with {it:panelvar} to check whether variable can be used as an alternative {it:panelvar}. By default it creates the variable _check_var

{p 0 4} {cmd:MISCODE(}{it:stud}{cmd:)} requires one stub identifying a set of variables coded as stub1, stub2,...etc. It checks to find for offsetting
changes between pairs of variables - possibly signaling situations of category miscoding. If it finds a possible miscoding between variable stubi and stubk
then it creates a flagging variable _flag_m_i_k to signal the observations with possible miscodings 

{p 0 4} {cmd:DEMOBY}({it:var}[,keep]) calculates changes over time across {it:var}. It can be used to check movements of individuals across units of {it:var}.
With the keep option it creates the variable _demoby_var identifitying for each observation whether it is the first time it shows up in the data (first), if it moves
across the units of {it:var} (mover), if it remains in the same units of {it:var} (stayer) or if it returns to a previous unit of {it:var}.

Changing Parameters

{p 0 4}{cmdab:SETMAXPAT}{cmd:(}{it:integer}{cmd:)} specifies the number of patterns to display. Affects the behavior of option {cmd:pattern}. Default is 10

{p 0 4}{cmdab:SETNLAGS}{cmd:(}{it:integer}{cmd:)} specifies the number of lags to use in options {cmd: ABS} and {cmd:REL}. Default is 10

{p 0 4}{cmdab:SETABSV}{cmd:(}{it:integer}{cmd:)} set threshold value for abnormal absolute change. Affects the behavior of option {cmd: ABS}. Default is 10

{p 0 4}{cmdab:SETRELV}{cmd:(}{it:integer}{cmd:)} set threshold value for abnormal relative change.  Affects the behavior of option {cmd: REL}. Default is 100

{p 0 4}{cmdab:SETLLMIS}{cmd:(}{it:real}{cmd:)} used with option {cmd: miscode}. Only flags changes above this lower limit. Default is 10

{p 0 4}{cmdab:SETDIFMIS}{cmd:(}{it:real}{cmd:)} used with option {cmd: miscode}. Only flags if difference between changes is below {cmdab:difmis}. Default is 100

{p 0 4}{cmdab:SETSDMIS}{cmd:(}{it:real}{cmd:)} used with option {cmd: miscode}. Factor applied to standard deviation of changes. Only flags if change larger than factor
times within standard deviation. Default is 1

{p 0 4}{cmdab:SETQTLL}{cmd:(}{it:integer}{cmd:)} used with option {cmd: quantr}. Sets the value to define quantile 1 (var<=setqtll)
times within standard deviation. Default is 25

{p 0 4}{cmdab:SETQTUL}{cmd:(}{it:integer}{cmd:)} used with option {cmd: quantr}. Sets the value to define quantile 3 (var>setqtul)
times within standard deviation. Default is 100

Miscellaneous

{p 0 4}{cmd: EXCEL(}{it:filename}{cmd:)} outputs results to an excel file. Implemented only for some options.

{p 0 4} {cmd:KEEPMaxgap(}{it:new varname}{cmd:)} create a variable containing the largest gap size for each individual

{p 0 4} {cmd:KEEPNgaps(}{it:new varname}{cmd:)} creates a variable containing the number of gaps for each individual

{title:Examples}

Example 1:
Basic characterization of a panel.

{p 8 16}{inp:. panelstat id time}{p_end}

Example2:
Full characterization of a panel.

{p 8 16}{inp:. panelstat id time, all}{p_end}

Example3:

use nlswork
panelstat idcode year, tabovert(union)

{title:Remarks}

Please notice that this software is provided "as is", without warranty of any kind, whether
express, implied, or statutory, including, but not limited to, any warranty of merchantability
or fitness for a particular purpose or any warranty that the contents of the item will be error-free.
In no respect shall the author incur any liability for any damages, including, but limited to, 
direct, indirect, special, or consequential damages arising out of, resulting from, or any way 
connected to the use of the item, whether or not based upon warranty, contract, tort, or otherwise. 

{title:Dependencies}

option checkid requires installation of package {cmd:group2hdfe} (version 1.01 03jul2014) by Paulo Guimaraes
option excel requires instalation of {cmd:excelcol} (excelcol 1.0.0 19jul2014) by Sergiy Radyakin
option pattern and tabovert require installation of {cmd:sreshape} by Kenneth L. Simons
option fast requires installation of {cmd:ftools} package (version 2.7.0 14feb2017 - development version) by Sergio Correia

{title:Author}

{p}
Paulo Guimaraes, BPlim, Banco de Portugal, Portugal.

{p}
Email: {browse "mailto:pguimaraes2001@gmail.com":pguimaraes2001@gmail.com}

I appreciate your feedback. Comments are welcome!

