{smcl}
{* *! version 2.0mc 2017-05-23}{...}
{hline}
help for {cmd:table1_mc}
{hline}

{title:Title}

{p2colset 5 15 21 2}{...}
{p2col: {bf:table1_mc}}{hline 2} Create "Table 1" of baseline characteristics for a manuscript

{title:Syntax}

{p 8 18 2}
{opt table1_mc} {ifin} {weight}, {opt vars(var_spec)} [{it:options}]

{phang}{it:var_spec} = {it: varname vartype} [{it:{help fmt:%fmt1}} [{it:{help fmt:%fmt2}}]] [ \ {it:varname vartype} [{it:{help fmt:%fmt1}} [{it:{help fmt:%fmt2}}]] \ ...]

{phang}where {it: vartype} is one of:{p_end}
{tab}contn  - continuous, normally distributed  (mean and SD will be reported)
{tab}contln - continuous, log normally distributed (geometric mean and GSD ...)
{tab}conts  - continuous, neither log normally or normally distributed (median and IQR ...)
{tab}cat    - categorical, groups compared using Pearson's chi-squared test
{tab}cate   - categorical, groups compared using Fisher's exact test
{tab}bin    - binary (0/1), groups compared using Pearson's chi-squared test
{tab}bine   - binary (0/1), groups compared using Fisher's exact test

{phang}{opt fweight}s are allowed; see {help weight}


{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:#Columns/Rows}
{synopt:{opt by(varname)}}group observations by {it:varname}{p_end}
{synopt:{opt total(before|after)}}include a total column before/after presenting by group{p_end}
{synopt:{opt one:col}}report categorical variable levels underneath variable name instead of in
separate column{p_end}
{synopt:{opt mis:sing}}don't exclude missing values from categorical variables (not binary) {p_end}
{synopt:{opt test}}include column describing the significance test used{p_end}
{synopt:{opt pairwise123}}report pairwise comparisons (unadjusted for multiple comparisons) between first 3 groups, ignoring any missing data{p_end}

{syntab:Contents of Cells}
{synopt:{cmdab:f:ormat(}{it:{help fmt:%fmt}}{cmd:)}}default display format for continuous variables{p_end}
{synopt:{cmdab:percf:ormat(}{it:{help fmt:%fmt}}{cmd:)}}default display format for percentages for categorical/binary vars{p_end}
{synopt:{opt iqrmiddle("string")}}allows for e.g. median (Q1, Q3) using iqrmiddle(", ") rather than median (Q1-Q3){p_end}
{synopt:{opt sdleft("string")}}allows for e.g. mean±sd using sdleft("±") rather than mean (SD){p_end}
{synopt:{opt sdright("string")}}allows for e.g. mean±sd using sdright("") rather than mean (SD){p_end}
{synopt:{opt gsdleft("string")}}allows for presentation other than: geometric mean (×/GSD){p_end}
{synopt:{opt gsdright("string")}}allows for presentation other than: geometric mean (×/GSD){p_end}
{synopt:{opt percsign("string")}}default is percsign("%"); consider percsign(""){p_end}
{synopt:{opt nos:pacelowpercent}}report e.g. (3%) instead of the default ( 3%), [the default can look nice if output is right/left justified]{p_end}
{synopt:{opt percent}}report % rather than n (%) for categorical/binary vars{p_end}
{synopt:{opt percent_n}}report % (n) rather than n (%) for categorical/binary vars{p_end}
{synopt:{opt slashN}}report n/N instead of n for categorical/binary vars {p_end}
{synopt:{opt pdp(#)}}max number of decimal places in p-value; default is pdp(3){p_end}
{synopt:{opt gurmeet}}equivalent to specifying:  percformat(%5.1f) percent_n percsign("") iqrmiddle(",") sdleft(" [±") sdright("]") gsdleft(" [×/") gsdright("]") onecol{p_end}

{syntab:Output}
{synopt:{cmdab:sav:ing(}{it}{help filename}{sf} [, {help import_excel##exportoptions:export_excel_options}{sf}]{cmd:)}}save table to Excel file{p_end}
{synopt:{opt clear}}replace the dataset in memory with the table{p_end}


{title:Description}

{pstd}
{opt table1_mc} generates a "Table 1" of characteristics for a manuscript. Such a table generally
includes a collection of baseline characteristics which may be either continuous or categorical. The
observations are often grouped, with a "p-value" column on the right comparing the characteristics
between groups.{p_end}

{pstd}The {bf:vars} option is required and contains a list of the variable/s to be included as
rows in the table. Each variable must also have a type specified ({it:contn}, {it:contln}, {it:conts}, {it:cat},
{it:cate}, {it:bin} or {it:bine} - see above). If the observations are grouped using {bf:by()}, a
significance test is performed to compare each characteristic between groups. {it:contln} and {it:contn} variables
are compared using ANOVA (with and without log transformation of positive values respectively),
{it:conts} variables are compared using the Wilcoxon rank-sum (2 groups)
or Kruskal-Wallis (>2 groups) test, {it:cat} and {it:bin} variables are compared using Pearson's
chi-squared test and {it:cate} and {it:bine} variables are compared using Fisher's exact test.
{bf:pairwise123} reports p-values from applying those same tests between 2 groups.
Specifying the {bf:test} option adds a column to the table describing the test used.{p_end}

{pstd}The display format of each variable in the table depends on the variable type. For continuous
variables the default display format is the same as that variable's current display format. You can
change the table's default display format of summary statistics for continuous variables using the {bf:format()} option.
 After each variable's type you may
optionally specify a display format to override the table's default by specifying {it:{help fmt:%fmt1}}.
Specification of {it:{help fmt:%fmt2}} also, will affect the display format of IQR/SD/GSD.
For categorical/binary variables the default is to
display the percentage using either 0 or 1 decimal place depending on the total frequency. You
can change this default using the {bf:percformat()} option.{p_end}

{pstd}GSD is the geometric standard deviation, equivalently the multiplicative standard deviation.
The default times-divide symbol is very similar to that proposed by Limpert & Stahel (2011).{p_end}

{pstd}The underlying results table can be (i) saved to an Excel file using the {bf:saving()} option, and/or 
(ii) kept in memory, replacing the original dataset, using the {bf:clear} option.{p_end} 


{title:Remarks}

{pstd}Other user written commands that do similar things include:{break}
{cmd:tabout} (http://tabout.net.au/docs/home.php){break}
{cmd:sumtable} (two stats in two (not one) columns, generally not as flexible, no testing){break}
{cmd:partchart} (quite similar but strangely doesn't seem to express IQR as (Q1-Q3), reporting instead the difference between the two quartiles){break}
Table1 (http://www.stata.com/meeting/oceania16/slides/donath-oceania16.pdf - v nice, but no p-values, and not in public domain as of May 2017){p_end}


{title:Example}

{phang}{sf:. }{stata "sysuse auto, clear"}{p_end}
{phang}{sf:. }{stata "generate much_headroom = (headroom>3)"}{p_end}
{phang}{sf:. }{stata "table1_mc, by(foreign) vars(price conts \ price contln %5.0f %4.2f \ weight contn %5.0f \ rep78 cate \ much_headroom bine)"}{p_end}
{phang}{sf:. }{stata "table1_mc, by(foreign) vars(price conts \ price contln %5.0f %4.2f \ weight contn %5.0f \ rep78 cate \ much_headroom bine) gurmeet"}{p_end}
{phang}{sf:. }{stata "table1_mc, by(foreign) vars(price conts \ price contln %5.0f %4.2f \ weight contn %5.0f \ rep78 cate \ much_headroom bine) saving(auto.xls, replace) clear"}{p_end}


{title:References}

{phang}Limpert E, Stahel WA. Problems with Using the Normal Distribution – and Ways to Improve Quality and Efficiency of Data Analysis. PLoS ONE. 2011;6(7):e21403. doi:10.1371/journal.pone.0021403.{p_end} 


{title:Authors}

{pstd} {cmd:table1_mc} is essentially an extension of {cmd:table1}, with some minor revision. 

{p 4 4 2}
table1_mc: Mark Chatfield, Menzies School of Health Research, Darwin, Australia, mark.chatfield@menzies.edu.au{break}
table1       : Phil Clayton, ANZDATA Registry, Australia, phil@anzdata.org.au{p_end}

