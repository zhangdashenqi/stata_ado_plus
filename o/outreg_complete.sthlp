{smcl}
{* *! version 4.09  20aug2012}{...}
{cmd:help outreg_complete}{right: ({browse "http://www.stata-journal.com/article.html?article=sg97_5":SJ12-4: sg97_5})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:outreg} {hline 2}}Reformat and write regression tables to a document file{p_end}
{p2colreset}{...}

{pstd} {hi:outreg} has many options.  To review just the basic options, see 
the {help outreg:{bf:outreg} (basic)} help file.

{pstd}
For an explanation of the major changes to {cmd:outreg} since the
previous version, see {help outreg_update:{bf:outreg} (updates)}.


{title:Syntax}

{p 8 17 2}
{cmd:outreg}
[{cmd:using} {it:filename}]
[{cmd:,} {it:options}]

{synoptset 25}{...}
{p2col:Options categories}Description{p_end}
{p2line}
{p2col:{it:{help outreg_complete##est_opts:Estimate selection}}}
which statistics are displayed in table{p_end}
{p2col:{it:{help outreg_complete##est_for_opts:Estimate formatting}}}
numerical formatting and arrangement of estimates{p_end}
{p2col:{it:{help outreg_complete##text_add_opts:Text additions}}}
titles, notes, added rows and columns{p_end}
{p2col:{it:{help outreg_complete##col_form_opts:Text formatting:}}}{p_end}
{p2col 10 32 34 2:{it:{help outreg_complete##col_form_opts:Column formatting}}}
column widths, justification, etc.{p_end}
{p2col 10 32 34 2:{it:{help outreg_complete##font_opts:Font specification}}}
font specifications for table{p_end}
{p2col 10 32 34 2:{it:{help outreg_complete##lines_spaces_opts:Lines and spaces}}}
horizontal and vertical lines, cell spacing{p_end}
{p2col 10 32 34 2:{it:{help outreg_complete##page_fmt_opts:Page formatting}}}
page orientation and size{p_end}
{p2col:{it:{help outreg_complete##file_opts:File and display options}}}
TeX files, merge, replace, etc.{p_end}
{p2col:{it:{help outreg_complete##stars_opts:Asterisk options}}}
change asterisks for statistical significance{p_end}
{p2col:{it:{help outreg_complete##brack_opts:Bracket options}}}
change the look of brackets around, for example, t statistics{p_end}
{p2col:{it:{help outreg_complete##summstat_opts:Summary statistics options}}}
summary statistics below estimates{p_end}
{p2col:{it:{help outreg_complete##frmttable_opts:frmttable options}}}
technical options passed to {helpb frmttable}{p_end}
{p2colset 5 30 31 2}{...}
{p2line}

{pstd}
{it:{help outreg_complete##greek:Inline text formatting: Superscripts, italics, Greek characters, etc.}}{p_end}
{pstd}
{it:{help outreg_complete##spec_notes:Notes about specific estimation commands}}{p_end}
{pstd}
{it:{help outreg_complete##examples:Examples}}{p_end}


{marker est_opts}{...}
{synoptset 25}{...}
{syntab:{help outreg_complete##estimate_select:Estimate selection}}
{synoptline}
{synopt:{opt se}}report standard errors instead of t statistics{p_end}
{synopt:{opt ma:rginal}}report marginal effects instead of coefficients{p_end}
{synopt:{opt or}|{cmd:hr}|{cmdab:ir:r}|{cmd:rrr}}odds ratios, that is, exp(b) instead of b{p_end}
{synopt:{cmdab:s:tats:(}{it:{help outreg_complete##statname:statname}} [{it:...}]{cmd:)}}report statistics other than b and t statistics{p_end}
{synopt:{opt nocons}}drop constant estimate (do not include {cmd:_cons} coefficient){p_end}
{synopt:{cmdab:ke:ep(}{it:eqlist}|{it:varlist}{cmd:)}}include only specified coefficients{p_end}
{synopt:{cmdab:dr:op(}{it:eqlist}|{it:varlist}{cmd:)}}exclude specified coefficients{p_end}
{synopt:{opt l:evel(#)}}set level for confidence intervals; default is {cmd:level(95)}{p_end}
{synoptline}
{marker est_for_opts}{...}

{synoptset 25}{...}
{syntab:{help outreg_complete##estimates_formatting:Estimate formatting}}
{synoptline}
{synopt:{opt bd:ec(numlist)}}decimal places for coefficients{p_end}
{synopt:{opt td:ec(#)}}decimal places for t statistics{p_end}
{synopt:{opt sd:ec(numgrid)}}decimal places for all statistics{p_end}
{synopt:{opt bf:mt(fmtlist)}}numerical format for coefficients{p_end}
{synopt:{opt sf:mt(fmtgrid)}}numerical format for all statistics{p_end}
{synopt:{opt nosub:stat}}do not put t statistics (or others) below coefficients{p_end}
{synopt:{opt e:q_merge}}merge multiequation coefficients into multiple columns{p_end}
{synoptline}
{marker text_add_opts}{...}

{synoptset 25}{...}
{syntab:{help outreg_complete##text_additions:Text additions}}
{synoptline}
{synopt:{opt va:rlabels}}use variable labels as {cmd:rtitles()}{p_end}
{synopt:{opt t:itle(textcolumn)}}put title above table{p_end}
{synopt:{opt ct:itles(textgrid)}}specify column headings{p_end}
{synopt:{opt rt:itles(textgrid)}}specify row headings{p_end}
{synopt:{opt n:ote(textcolumn)}}put note below table{p_end}
{synopt:{opt pr:etext(textcolumn)}}place regular text before the table{p_end}
{synopt:{opt po:sttext(textcolumn)}}place regular text after the table{p_end}
{synopt:{opt noco:ltitl}}no column titles{p_end}
{synopt:{opt noro:wtitl}}no row titles{p_end}
{synopt:{opt addr:ows(textgrid)}}add rows at bottom of table{p_end}
{synopt:{opt addrt:c(#)}}number of {cmd:rtitles()} columns in {cmd:addrows()}{p_end}
{synopt:{opt addc:ols(textgrid)}}add columns to right of table{p_end}
{synopt:{opt an:notate(matname)}}grid of annotation locations{p_end}
{synopt:{opt as:ymbol(textrow)}}symbols for annotations{p_end}
{synoptline}
{marker col_form_opts}{...}

{synoptset 34}{...}
{syntab:{help outreg_complete##col_formats:Column formatting}}
{synoptline}
{synopt:{opt colw:idth(numlist)}*}change column widths{p_end}
{synopt:{cmdab:mu:lticol(}{it:numtriple}[{cmd:;}{it:numtriple}...]{cmd:)}}have column titles span multiple columns{p_end}
{synopt:{cmdab:colj:ust(}{it:cjstring}[{cmd:;}{it:cjstring}...]{cmd:)}}justify columns: left, center, right, or decimal{p_end}
{synopt:{opt noce:nter}}do not center table within page{p_end}
{synoptline}
{syntab:* Option for Microsoft Word only}
{marker font_opts}{...}

{synoptset 32}{...}
{syntab:{help outreg_complete##fonts:Font specification}}
{synoptline}
{synopt:{opt ba:sefont(fontlist)}}change base font for all text{p_end}
{synopt:{opt titlf:ont(fontcolumn)}}change font for table title{p_end}
{synopt:{cmdab:ctitlf:ont(}{it:fontgrid}[{cmd:;}{it:fontgrid}...]{cmd:)}}change font for column titles{p_end}
{synopt:{cmdab:rtitlf:ont(}{it:fontgrid}[{cmd:;}{it:fontgrid}...]{cmd:)}}change font for row titles{p_end}
{synopt:{cmdab:statf:ont(}{it:fontgrid}[{cmd:;}{it:fontgrid}...]{cmd:)}}change font for statistics in body of table{p_end}
{synopt:{opt notef:ont(fontcolumn)}}change font for notes below table{p_end}
{synopt:{opt addf:ont(fontname)}*}add a new font type{p_end}
{synopt:{opt p:lain}}plain text -- one font size, no justification{p_end}
{synopt:{it:outreg_table_sections}}explanation of {cmd:outreg} table sections{p_end}
{synoptline}
{syntab:* Option for Microsoft Word only}
{marker lines_spaces_opts}{...}

{synoptset 25}{...}
{syntab:{help outreg_complete##lines_spaces:Lines and spaces}}
{synoptline}
{synopt:{opt hl:ines(linestring)}}horizontal lines between rows{p_end}
{synopt:{opt vl:ines(linestring)}}vertical lines between columns{p_end}
{synopt:{opt hls:tyle(lstylelist)}*}change style of horizontal lines (for
example, double or dashed){p_end}
{synopt:{opt vls:tyle(lstylelist)}*}change style of vertical lines (for
example, double or dashed){p_end}
{synopt:{opt spaceb:ef(spacestring)}}put space above cell contents{p_end}
{synopt:{opt spacea:ft(spacestring)}}put space below cell contents{p_end}
{synopt:{opt spaceh:t(#)}}change size of {cmd:spacebef()} and {cmd:spaceaft()}{p_end}
{synoptline}
{syntab:* Option for Microsoft Word only}
{marker page_fmt_opts}{...}

{synoptset 25}{...}
{syntab:{help outreg_complete##page_fmt:Page formatting}}
{synoptline}
{synopt:{opt la:ndscape}}pages in landscape orientation{p_end}
{synopt:{opt a4}}A4 size paper (instead of 8 1/2" x 11"){p_end}
{synoptline}
{marker file_opts}{...}

{synoptset 25}{...}
{syntab:{help outreg_complete##file_options:File and display options}}
{synoptline}
{synopt:{opt tex}}write a TeX file instead of the default Microsoft Word file{p_end}
{synopt:{opt me:rge}[{cmd:(}{it:tblname}{cmd:)}]}merge as new columns to existing table{p_end}
{synopt:{opt replace}}replace existing file{p_end}
{synopt:{opt addt:able}}write a new table below an existing table{p_end}
{synopt:{opt ap:pend}[{cmd:(}{it:tblname}{cmd:)}]}append as new rows below an existing table{p_end}
{synopt:{opt re:play}[{cmd:(}{it:tblname}{cmd:)}]}write preexisting table{p_end}
{synopt:{opt sto:re(tblname)}}store table with name {it:tblname}{p_end}
{synopt:{opt cl:ear}[{cmd:(}{it:tblname}{cmd:)}]}clear existing table from memory{p_end}
{synopt:{opt fr:agment**}}create TeX code fragment to insert into TeX document{p_end}
{synopt:{opt nod:isplay}}do not display table in Results window{p_end}
{synopt:{opt dw:ide}}display all columns however wide{p_end}
{synoptline}
{syntab:** Option for TeX only}
{marker stars_opts}{...}

{synoptset 25}{...}
{syntab:{help outreg_complete##stars_options:Asterisk options}}
{synoptline}
{synopt:{opt starlev:els(numlist)}}significance levels for asterisks{p_end}
{synopt:{opt starloc(#)}}locate asterisks next to a particular statistic;
default is 2{p_end}
{synopt:{opt margs:tars}}calculate asterisks from marginal effects, not coefficients{p_end}
{synopt:{opt nostar:s}}no asterisks for significance{p_end}
{synopt:{opt nole:gend}}no legend explaining significance levels{p_end}
{synopt:{opt si:gsymbols(textrow)}}symbols for significance (in place of
asterisks){p_end}
{synoptline}
{marker brack_opts}{...}

{synoptset 32}{...}
{syntab:{help outreg_complete##brack_options:Bracket options}}
{synoptline}
{synopt:{opt sq:uarebrack}}square brackets instead of parentheses{p_end}
{synopt:{cmdab:br:ackets(}{it:textpair} [{cmd:\}{it:textpair}...]{cmd:)}}symbols with which to bracket substatistics{p_end}
{synopt:{opt nobrk:et}}put no brackets on substatistics{p_end}
{synopt:{opt dbl:div(text)}}symbol dividing double statistics{p_end}
{synoptline}
{marker summstat_opts}{...}

{synoptset 25}{...}
{syntab:{help outreg_complete##summstat_options:Summary statistics options}}
{synoptline}
{synopt:{opt summs:tat(e_values)}}additional summary statistics below coefficients{p_end}
{synopt:{opt summd:ec(numlist)}}decimal places for summary statistics{p_end}
{synopt:{opt summt:itles(textgrid)}}row titles for summary statistics{p_end}
{synopt:{opt noau:tosumm}}no automatic summary statistics (R^2, N){p_end}
{synoptline}
{marker frmttable_opts}{...}

{synoptset 25}{...}
{syntab:{help outreg_complete##frmttable_options:frmttable options}}
{synoptline}
{synopt:{opt bl:ankrows}}allow (do not drop) blank rows in table{p_end}
{synopt:{opt nofi:ndcons}}do not assign {cmd:_cons} to separate section of table{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:outreg} arranges the results of Stata estimation commands in tables in the
same way they are typically presented in journal articles, rather than the way
they are presented in the Stata Results window.  By default, t statistics
appear in parentheses below the coefficient estimates with asterisks for
significance levels.

{pstd}
{cmd:outreg} provides as complete control as is practical of the layout and
formatting of estimation tables, both in Microsoft Word and TeX files.  Almost
every aspect of the table's structure and format (including fonts) can be
specified with options.  Multiple tables can be written to the same document,
with paragraphs of text in between, creating a whole statistical appendix.

{pstd}
{cmd:outreg} works after any estimation command in Stata (see 
{help estimation commands} for a complete list).  Like 
{helpb predict}, {cmd:outreg} uses internally saved estimation
results, so it should be invoked after the estimation.

{pstd}
{cmd:outreg} creates a Microsoft Word file by default or creates a TeX file
with the {helpb outreg_complete##tex:tex} option.  In addition, the
table created by {cmd:outreg} is displayed in the Results window, minus
some of the finer formatting destined for the Microsoft Word or TeX file.

{pstd}
Successive estimation results, which may use different variables, can be
combined by {cmd:outreg} into a single table by using the 
{helpb outreg_complete##merge:merge} option.  (In previous versions of
{cmd:outreg}, the {cmd:merge} option was called {cmd:append}.)

{phang2}
* To be precise, {cmd:outreg} can display results after every 
{help estimation command} that saves both {cmd:e(b)} and {cmd:e(V)}
values.  Estimation commands that do not save both {cmd:e(b)} and
{cmd:e(V)} are {helpb ca}, {helpb candisc}, {helpb discrim}, 
{helpb exlogistic}, {helpb expoisson}, {helpb factor}, {helpb mca},
{helpb mds}, {helpb mfp}, {helpb pca}, {helpb procrustes}, 
and {helpb svy tabulate}.  {cmd:outreg} can display the results of the
commands {helpb mean}, {helpb ratio}, {helpb proportion}, and 
{helpb total}, which may not be thought of as estimation commands, and these
commands accept the {helpb svy:svy:} prefix.


{title:Options}

{marker estimate_select}{...}
{dlgtab:Estimate selection}

{marker se}{...}
{phang}
{opt se} specifies that standard errors rather than t statistics be
reported in parentheses below the coefficient estimates.  The decimal
places displayed are those set by {helpb outreg_complete##bdec:bdec()}.

{marker marginal}{...}
{phang}
{opt marginal} specifies that marginal effects rather than coefficients
be reported.  The t statistics are for the hypothesis that the marginal
effects, not the coefficients, are equal to zero, and the asterisks
report the significance of this hypothesis test.  {opt marginal} is
equivalent to {helpb outreg_complete##stats:stats(b_dfdx t_abs_dfdx)}
(or {cmd:stats(b_dfdx se_dfdx)} if the {opt se} option is used) combined
with the {helpb outreg_complete##margstars:margstars} option.

{marker or}{marker hr}{marker irr}{marker rrr}{...}
{phang}
{opt or}|{cmd:hr}|{cmd:irr}|{cmd:rrr} cause the coefficients to be
displayed in exponentiated form: for each coefficient, exp(b)
rather than b is displayed.  Standard errors and confidence intervals
are also transformed.  Display of the intercept, if any, is suppressed.
These options are identical, but by convention, different estimation
methods use different names.

{p2colset 11 35 37 2}{...}
{p2col:Exponentiation option}Name{p_end}
{p2line}
{p2col:{opt or}}odds ratio{p_end}
{p2col:{opt hr}}hazard ratio{p_end}
{p2col:{opt irr}}incidence-rate ratio{p_end}
{p2col:{opt rrr}}relative-risk ratio{p_end}
{p2line}
{p2colreset}{...}

{pmore}
Note that after commands that report coefficients in exponentiated form by
default (such as {helpb stcox}), you must use one of the exponentiation options
for the {cmd:outreg} table to display exponentiated coefficients and standard
errors as they are displayed in the Results window.

{pmore}
The exponentiation options are equivalent to the option 
{cmd:stats(e_b t)} (or {cmd:stats(e_b e_se)} if the {cmd:se} 
option is used).

{pmore}
These options correspond to the {opt or} option used for {helpb logit},
{helpb clogit}, and {helpb glogit} estimation; {opt irr} for 
{helpb poisson} estimation; {opt rrr} for {helpb mlogit}; {opt hr} for
{helpb stcox} hazard models; and {opt eform} for {helpb xtgee}.  But these
options can be used to exponentiate the coefficients after any estimation.
Exponentiation of coefficients is explained in the
{mansection R maximizeMethodsandformulas:{it:Methods and formulas}}
section of {bf:[R] maximize}.

{marker stats}{...}
{phang}
{cmd:stats(}{it:{help outreg_complete##statname:statname}}
[{it:...}]{cmd:)} specifies the statistics to be displayed; the default
is equivalent to specifying {cmd:stats(b t_abs)}.  Multiple statistics
are arranged below each other (unless you use the 
{helpb outreg_complete##nosubstat:nosubstat} option), with varying
{helpb outreg_complete##brackets:brackets()}.  Available statistics are

{marker statname}{...}
{p2colset 11 23 25 2}{...}
{p2col:{it:statname}}Definition{p_end}
{p2line}
{p2col:{opt b}}coefficient estimates{p_end}
{p2col:{opt se}}standard errors of estimate{p_end}
{p2col:{opt t}}t statistics for the test of b=0{p_end}
{p2col:{opt t_abs}}absolute value of t statistics{p_end}
{p2col:{opt p}}p-value of t statistics{p_end}
{p2col:{opt ci}}confidence interval of estimates{p_end}
{p2col:{opt ci_l}}lower confidence interval of estimates{p_end}
{p2col:{opt ci_u}}upper confidence interval of estimates{p_end}
{p2col:{opt beta}}normalized beta coefficients (see the {cmd:beta} option of {helpb regress}){p_end}
{p2col:{opt e_b}}exponentiated form of the coefficients{p_end}
{p2col:{opt e_se}}exponentiated standard errors{p_end}
{p2col:{opt e_ci}}exponentiated confidence interval{p_end}
{p2col:{opt e_ci_l}}exponentiated lower confidence interval{p_end}
{p2col:{opt e_ci_u}}exponentiated upper confidence interval{p_end}
{p2col:{opt b_dfdx}}marginal effect of the coefficients (requires {helpb margins}){p_end}
{p2col:{opt se_dfdx}}standard errors of marginal effects{p_end}
{p2col:{opt t_dfdx}}t statistics of marginal effects{p_end}
{p2col:{opt t_abs_dfdx}}absolute value of t statistics of marginal effects {p_end}
{p2col:{opt p_dfdx}}p-values of t statistics of marginal effects{p_end}
{p2col:{opt ci_dfdx}}confidence interval of marginal effects{p_end}
{p2col:{opt ci_l_dfdx}}lower confidence interval of marginal effects{p_end}
{p2col:{opt ci_u_dfdx}}upper confidence interval of marginal effects{p_end}
{p2col:{opt at}}values around which marginal effects were estimated{p_end}
{p2line}
{p2colreset}{...}

{marker nocons}{...}
{phang}
{opt nocons} drops the constant estimate from the table.

{marker keep}{...}
{phang}
{cmd:keep(}{it:eqlist}|{it:varlist}{cmd:)} 
includes only the specified coefficients (and potentially reorders included coefficients).

{marker drop}{...}
{phang}
{cmd:drop(}{it:eqlist}|{it:varlist}{cmd:)} excludes the specified coefficients.

{pmore}
{marker eqlist}{...}
{it:eqlist} (equation list) consists of {it:eqname:} [{it:coeflist}] [{it:eqname}: [{it:coeflist}] ...].

{marker coeflist}{...}
{pmore}
{it:coeflist} (coefficient list) is like a {it:varlist} but can include
{cmd:_cons} for the constant coefficient or can include other parameter names.
{help fvvarlist:Factor-variable} notation can be included.
The {it:coeflist} can include any of the simple column names of the
{bf:e(b)} coefficient vector, which forms the basis of the table created
by {cmd:outreg}.  You can see the contents of the {bf:e(b)} vector after
an estimation command by typing {cmd:matrix list e(b)}.  If using
marginal effects (after the {helpb margins} command) rather than
coefficient estimates, the relevant vector is {bf:r(b)}.

{pmore}
{it:eqname} is a second-level column name of the {bf:e(b)} vector used
for multiequation estimation commands, such as {helpb reg3} or 
{helpb mlogit}.  Many Stata estimation commands attach additional
parameters to the coefficient vector {bf:e(b)} with a distinct equation
name.  For instance, the {helpb xtreg:xtreg, fe} command includes two
parameters in {bf:e(b)} with {it:eqname}s {bf:sigma_u:} and
{bf:sigma_e:}.  The {it:coeflist} for each of these {it:eqname}s is
{bf:_cons}.

{pmore}
To report only the coefficient estimates without additional parameters
in the {bf:e(b)} vector, it usually works to use the
{cmd:keep(}{it:depvar}{cmd::)} option, because the coefficients are
given an {it:eqname} of the dependent variable.

{pmore}
You can use the {cmd:keep()} option to reorder variables for the
formatted {cmd:outreg} table.  The estimation coefficients will be
displayed in the order specified in {cmd:keep()}.  Do not forget to
include {bf:_cons} in the reordered {it:coeflist} if you want the
constant coefficient term to be included in the formatted table.  By
default, the {bf:_cons} term is always displayed last in {cmd:outreg}
even if it is not listed last in {it:coeflist}.  To display the
{bf:_cons} coefficient in an order other than last, combine the {cmd:keep()}
option with the {helpb outreg_complete##nofindcons:nofindcons} option.
If you want the {bf:_cons} coefficient not to be last and are merging
multiple tables, you must specify the {opt nofindcons} option with all
the tables being merged, whether you use the {cmd:keep()} option for
them or not, to ensure that the coefficients merge properly.

{pmore}
If in doubt about what variable names, or especially equation names, to
include in {cmd:keep()} or {cmd:drop()}, use {cmd:matrix list e(b)} (or 
{cmd:matrix list r(b)} for marginal effects) to see what names are
assigned to saved estimation results.

{pmore}
You may have problems with {cmd:keep()} and {cmd:drop()} if you have
chosen both coefficients and marginal effects as statistics; 
they usually do not have the same {it:coeflist} because of the
absence of a constant coefficient estimate in the marginal effects.  A
{cmd:keep()} option that included {cmd:_cons} would result in an error
message because no constant would be found in the marginal
effects.  In this case, you could only {cmd:keep()} or {cmd:drop()}
variables occurring in both vectors.  However, if you are using
{cmd:drop()}, you can still eliminate the constant term with the
{cmd:nocons} option.

{marker level}{...}
{phang}
{opt level(#)} sets the significance level for confidence intervals,
which are included in the {cmd:outreg} table using the {cmd:stats(ci)}
option.  The default is {cmd:level(95)} for a 95% confidence level.  Note
that {cmd:level()} has no impact on the asterisks for the statistical
significance of coefficients (for this, see 
{helpb outreg_complete##starlevels:starlevels()}).  For more information
about {cmd:level()}, see 
{help estimation options:estimation options}.  The default
{cmd:level()} can be set for all Stata commands, including {cmd:outreg},
using the {cmd:set level} command.


{marker estimates_formatting}{...}
{dlgtab:Estimate formatting}

{marker bdec}{...}
{phang}
{cmd:bdec(}{it:{help numlist}}{cmd:)} specifies the number of decimal
places reported for coefficient estimates (the b's).  It also specifies
the decimal places reported for standard errors if the {cmd:se} option
is used.  The default is {cmd:bdec(3)}.  The minimum value is 0 and
the maximum value is 15.  If one number is specified in {cmd:bdec()}, it
will apply to all coefficients.  If multiple numbers are specified in
{cmd:bdec()}, the first number will determine the decimal places reported for
the first coefficient, the second number will determine the decimal places
reported for the second
coefficient, etc.  If there are fewer numbers in {cmd:bdec()} than
there are coefficients, the last number in {cmd:bdec()} will apply to all the
remaining coefficients.

{pmore}
The decimal places applied to each coefficient are also applied to the
corresponding standard errors, confidence intervals, beta coefficients,
and marginal effects, if they are included with the {opt se} or
{cmd:stats()} options.

{marker tdec}{...}
{phang}
{opt tdec(#)} specifies the number of decimal places reported for t
statistics.  The default is {cmd:tdec(2)}.  The minimum value is 0 and
the maximum value is 15.

{marker sdec}{...}
{phang}
{opt sdec(numgrid)} is for finer control of the decimal places of
estimates than is possible with {opt bdec()} and {opt tdec()}, but is
rarely needed.  {it:numgrid} corresponds to the decimal
places for each of the statistics in the table.  It can be used, for
instance, to specify different decimal places for coefficients versus
standard errors ({opt bdec()} applies to both) or to allow varying
decimal places for t statistics.

{pmore}
{it:numgrid} is a grid of integers 0-15 in the form used by 
{helpb matrix define}.  Commas separate elements along a row and
backslashes ({cmd:\}) separate rows.  {it:numgrid} has the form 
{it:#}[{cmd:,}{it:#}...] [{cmd:\} {it:#}[{cmd:,}{it:#}...] [{cmd:\} [...]]]}.
For example, if the table of statistics has three rows and two columns, the
option would be {cmd:sdec(1,2\2,2\1,3\2,2)}.  If you specify a
grid smaller than the table of statistics created by {cmd:outreg}, the last
rows and columns of {it:numgrid} will be repeated to cover the whole table.
Unbalanced rows or columns will not cause an error; they will be filled in, and
{cmd:outreg} will print a warning message.

{marker bfmt}{...}
{phang}
{opt bfmt(fmtlist)} specifies the numerical format for coefficients.
The possible format types are

{p2colset 11 22 24 2}{...}
{p2col:{it:fmtlist}}Format type{p_end}
{p2line}
{p2col:{opt e}}exponential (scientific) notation{p_end}
{p2col:{opt f}}fixed number of decimals{p_end}
{p2col:{opt fc}}fixed with commas for thousands, etc. --  the default{p_end}
{p2col:{opt g}}"general" format (see {helpb format}){p_end}
{p2col:{opt gc}}"general" format with commas for thousands, etc.{p_end}
{p2line}

{pmore}
Format type {cmd:e}, scientific notation, is the format most likely to
be useful for {cmd:outreg} tables.  The {cmd:g} formats do not allow the
user to control the number of decimal places displayed.

{pmore}
{it:fmtlist} consists of {it:fmt} [{it:fmt} [...]] where {it:fmt} is either
{cmd:e}, {cmd:f}, {cmd:fc}, {cmd:g}, or {cmd:gc}.  Like {opt bdec()}, if one
format is specified in {cmd:bfmt()}, it will apply to all coefficients.  If
multiple format codes are specified in {cmd:bfmt()}, the first format will
apply to the first coefficient, the second format will apply to the second
coefficient, etc.  If there are fewer {it:fmt}s in {it:fmtlist} than there are
coefficients, the last format in {cmd:bfmt()} will apply to all the remaining
coefficients.  The format applied to each coefficient is also applied to the
corresponding standard errors, confidence intervals, beta coefficients, and
marginal effects, if they are specified in {opt se} or {cmd:stats()}.

{marker sfmt}{...}
{phang}
{opt sfmt(fmtgrid)} is for finer control of the numerical formats of
estimates than is possible with {helpb outreg_complete##bfmt:bfmt()}, but
is rarely needed.  {it:fmtgrid} is a grid of the format types ({cmd:e},
{cmd:f}, {cmd:fc}, {cmd:g}, or {cmd:gc}) for each statistic in the
table.  For example, {opt sfmt()} could be used to assign different
numerical formats for the coefficients in different columns of a
multiequation estimation or to change the format for t statistics.

{pmore}
The {it:fmtgrid} in {opt sfmt()} has the same form as the {it:numgrid}
of the {helpb outreg_complete##sdec:sdec()} option above.

{marker nosubstat}{...}
{phang}
{opt nosubstat} puts additional statistics, like t statistics or other
substatistics, in columns to the right of coefficients, rather than
below them.  Applying the {opt nosubstat} with the default statistics of
{opt b} and {opt t_abs}, the {cmd:outreg} table would have only one row,
but two columns, for each coefficient.  For example, the command
{cmd:outreg using test, nosubstat stats(b,se,t,p,ci_l,ci_u)} will
arrange regression output the way it is displayed in the Stata Results
window after the {helpb regress} command, with each statistic in a
separate column.  In this case, for each variable in the regression,
there is one row of results, but six columns, of statistics (see 
{help outreg_complete##xmpl15:example 15}).

{marker eq_merge}{...}
{phang}
{opt eq_merge} merges multiequation estimation results into multiple
columns, one column per equation.  By default, {cmd:outreg} displays the
equations one below the other in a single column.  {opt eq_merge} is
most useful after estimation commands like {helpb reg3}, {helpb sureg},
{helpb mlogit}, and {helpb mprobit}, where many or all of the variables
recur in each equation.  The coefficients are merged as if the equations
were estimated one at a time and the results were sequentially combined
with the {opt merge} option.


{marker text_additions}{...}
{dlgtab:Text additions}

{marker varlabels}{...}
{phang}
{opt varlabels} replaces variable names with 
{help label:variable labels}, if they exist.  For example, if using the
{cmd:auto.dta} dataset, {opt varlabels} gives a coefficient for the 
{cmd:mpg} variable the row title {cmd:Mileage (mpg)} instead of {cmd:mpg}.
{cmd:varlabels} also replaces {cmd:_cons} with {cmd:Constant} for
constant coefficients.

{phang}
{it:{ul:Text structures used for titles}}{p_end}

{marker textcolumn}{...}
{phang2}
{it:textcolumn} is  {cmd:"}{it:string}{cmd:"} [{cmd:\"}{it:string}{cmd:"}...]

{marker textrow}{...}
{phang2}
{it:textrow} is  {cmd:"}{it:string}{cmd:"} [{cmd:,"}{it:string}{cmd:"}...]

{marker textgrid}{...}
{phang2}
{it:textgrid} is {cmd:"}{it:string}{cmd:"{ [{cmd:,"}{it:string}{cmd:"}...]
[{cmd:\"}{it:string}{cmd:"}[{cmd:,"}{it:string}{cmd:"}...] [{cmd:\} [...]]]
or a {it:textrow} or a {it:textcolumn} as a special case{p_end}
{phang2} {cmd:"}{it:string}{cmd:"} [{cmd:"}{it:string}{cmd:"} ...] will often
work in place of a {it:textrow} or a {it:textcolumn} when the user's intent is
clear, but if in doubt use the proper {it:textrow} or {it:textcolumn} syntax
above.

{marker title}{...}
{phang}
{cmd:title(}{it:{help outreg_complete##textcolumn:textcolumn}}{cmd:)}
specifies a title or titles above the regression table.  Subtitles
should be separated from the primary titles by backslashes ({cmd:\}), like
this: {cmd:title("Main title"\"First subtitle"\"Second subtitle")}.  By
default, titles are set in a larger font than the body of the table.  If
title text does not contain backslashes, you can dispense with the
quotation marks, but if in doubt, include them.

{marker ctitles}{...}
{phang}
{cmd:ctitles(}{it:{help outreg_complete##textgrid:textgrid}}{cmd:)}
specifies the column titles above the estimates.  By default, if no
{cmd:ctitles()} are specified, the name of the dependent variable is
displayed.  A simple form of {cmd:ctitles()} is, for example,
{cmd:ctitles("Variables","First Regression")}.  Note that the first
title in {cmd:ctitles()} goes above the variable name column and the
second title goes above the estimates column.  If you want no heading
above the variable name column, specify, for example, 
{cmd:ctitles("","First Regression")}.

{pmore}
Fancier titles in {cmd:ctitles()} can have multiple rows.  These are
specified as a {it:{help outreg_complete##textgrid:textgrid}}.  For
example, to put a number above the title for the estimation method (in
preparation for merging additional estimation results), you could use
{cmd:ctitles("","Regression 1"\"Independent Variables","OLS")}.  The
table would now have a first column title of "Regression 1" above the
coefficients estimates and a second column title of "OLS" in the row
below.

{pmore}
See {help outreg_complete##xmpl10:example 10} for an application of
multirow {opt ctitles()}.

{pmore}
The option {helpb outreg_complete##nocoltitl:nocoltitl}, decribed below,
removes even the default {cmd:ctitles()}.

{marker rtitles}{...}
{phang}
{cmd:rtitles(}{it:{help outreg_complete##textgrid:textgrid}}{cmd:)} replaces
the leftmost column of the table with new row titles for the coefficient
estimates.  By default (with no {cmd:rtitles()} option), the row titles are
variable names.  Multiple titles for the leftmost column in {cmd:rtitles()}
should be separated by a backslash ({cmd:\}) because they are placed below one
another (if the titles are separated with commas, they will all be placed in
the first row of the estimates).  An example of {cmd:rtitles()} is
{cmd:rtitles("Variable 1"\""\"Variable 2"\""\"Constant")}.  The empty titles
{cmd:""} are to account for the row of t statistics below the coefficients.

{pmore}
Multicolumn {cmd:rtitles()} are possible and will be merged correctly
with other estimation results.  Multicolumn {cmd:rtitles()} occur by
default, without specified {cmd:rtitles()}, after multiequation
estimations, where the first {cmd:rtitles()} column is the equation
name and the second {cmd:rtitles()} column is the variable name within
the equation.  See the second part of {help outreg_complete##xmpl6:example 6}
for an {cmd:outreg} table showing this.

{pmore}
The option {helpb outreg_complete##norowtitl:norowtitl}, described below,
removes even the default {cmd:rtitles()}.

{marker note}{...}
{phang}
{cmd:note(}{it:{help outreg_complete##textcolumn:textcolumn}}{cmd:)}
specifies a note to be displayed below the {cmd:outreg} table.  Multiple
lines of a note should be separated by backslashes ({cmd:\}), like this:
{cmd:note("First note line."\"Second note line."\"Third note line.")}.
Notes are centered immediately below the table.  By default, they are set
in a smaller font than the body of the table.  Blank note lines ({cmd:""}) are
allowed and will insert space between {cmd:note()} rows.

{marker pretext}{...}
{phang}
{cmd:pretext(}{it:{help outreg_complete##textcolumn:textcolumn}}{cmd:)}
regular text placed before the table.

{marker posttext}{...}
{phang}
{cmd:posttext(}{it:{help outreg_complete##textcolumn:textcolumn}}{cmd:)}
regular text placed after the table.

{pmore}
{cmd:pretext()} and {cmd:posttext()} contain regular paragraphs of text
to be placed before or after the {cmd:outreg} table in the document
created.  This allows a document to be created with regular paragraphs
between the tables.  The default font is applied but can be changed
with the {helpb outreg_complete##basefont:basefont()} option.  Text is
left-justified and spans the whole page.

{pmore}
Multiple paragraphs can be separated by the backslash character: 
{cmd:pretext("Paragraph 1"\"Paragraph 2")}.

{pmore} 
When creating a Microsoft Word document, you can create blank lines with empty
paragraphs: for example, {cmd:posttext(""\""\"This is text")} would
create two blank lines before the paragraph "{cmd:This is text"}.

{pmore} For Microsoft Word documents, you can also use the code {cmd:\line} for
blank lines.  You can insert page breaks between tables with the Microsoft Word
code {cmd:\page}, as in {cmd:pretext("\page")}, which is useful when
placing multiple tables within one document with the 
{helpb outreg_complete##addtable:addtable} option.  The page break or line
break codes can be used within a text string, but they must have a space
between the codes and the subsequent text: for example,
{cmd:pretext("\page\line This is text")}.  Without the space, in
{cmd:pretext("\page\lineThis is text")}, Microsoft Word would try to interpret
the code {cmd:\lineThis}, which is not defined.

{pmore}
When creating a TeX document (using option 
{helpb outreg_complete##tex:tex}), you can insert blank lines with the code
{cmd:\bigskip} (the trick used above of inserting blank paragraphs
does not work in TeX files).  You can insert page breaks between tables
with the code {cmd:\pagebreak}, as in {cmd:pretext("\pagebreak")},
which is useful with the {helpb outreg_complete##addtable:addtable}
option to put each table on a separate page.  The page break or line
break codes must be in separate rows from the text, for example,
{cmd:pretext("\pagebreak\bigskip"\"This is text")}.

{marker nocoltitl}{...}
{phang}
{opt nocoltitl} ensures that there are no column titles -- the default
column title of the dependent variable name is not used.  To replace the
column headings instead of eliminate them, use 
{helpb outreg_complete##ctitles:ctitles()}.

{marker norowtitl}{...}
{phang}
{opt norowtitl} ensures that there are no row titles -- the default row
titles of the coefficient variable names are not used.  It is unlikely
that you will want to eliminate row titles for an {cmd:outreg} table,
because it will be difficult to know which coefficient is which.  To
replace the row headings instead of eliminate them, use 
{helpb outreg_complete##rtitles:rtitles()}.

{marker addrows}{...}
{phang}
{cmd:addrows(}{it:{help outreg_complete##textgrid:textgrid}}{cmd:)} adds
rows of text to the bottom of the {cmd:outreg} table (above the notes).
All elements of the rows must be converted from numbers to text before
including them in the {it:textgrid}.  For example, to include the test
results of coefficient equality, you could use 
{cmd:addrows("t test of b1=b2","`ttest' **")} where {cmd:ttest} is the name
of a {help macro:local macro} with the value of the t test of
coefficient equality.  The asterisks are included because the t test was
significant at the 5% level.

{pmore} See {help outreg_complete##xmpl7:example 7} for an application
of {cmd:addrows()}.

{marker addrtc}{...}
{phang}
{opt addrtc(#)} is a rarely used option to specify the number of
{cmd:rtitles()} columns in {cmd:addrows()}.  It is only needed when
either {cmd:rtitles()} or {cmd:addrows()} has more than one column to
ensure that the row titles are lined up correctly with the data.
The default is {cmd:addrtc(1)}.

{marker addcols}{...}
{phang}
{cmd:addcols(}{it:{help outreg_complete##textgrid:textgrid}}{cmd:)} adds
columns to the right of table.  The contents of the new columns are not
merged -- it is the user's responsibility to ensure that the new columns
line up in the appropriate way.

{marker annotate}{...}
{phang}
{opt annotate(matname)} passes a matrix of annotation locations.

{marker asymbol}{...}
{phang} {cmd:asymbol(}{it:{help outreg_complete##textrow:textrow}}{cmd:)}
provides symbols for each annotation location in
{cmd:annotate()}.

{pmore}
{cmd:annotate()} and {cmd:asymbol()} (always specified together) are
useful for placing footnotes or other annotations next to statistics in
the {cmd:outreg} table, but they are not the most user-friendly options.
(Footnotes or annotations in any of the title regions, including row and
column titles, can be included directly in the title text with options
like {helpb outreg_complete##rtitles:rtitles()} and 
{helpb outreg_complete##ctitles:ctitles()}.)

{pmore}
The values in {cmd:annotate()} range from 0 to the number of symbols in
{cmd:asymbol()}.  The dimensions of the matrix in {cmd:annotate()} has
rows equal to the number of coefficients in the estimation and columns
equal to the number of statistics displayed (2, by default).  Whenever
the {cmd:annotate()} matrix has a value of zero, no symbol is appended
to the statistic in the corresponding cell of the table.  Where the
{cmd:annotate()} matrix has a value of 1, the first {cmd:asymbol()} symbol
is added on the left of the statistic; where there's a value of 2, the
second symbol is added; etc.

{pmore}
The {it:textrow} in {cmd:asymbol()} has the syntax
{cmd:"}{it:text}{cmd:"}[{cmd:,"}{it:text}{cmd:"} ...]].  If you want to have a
space between the statistic in the table and the {cmd:asymbol()} {it:text},
make sure to include it in the {it:text}, for example,
{cmd:asymbol(" 1"," 2")}.  Superscripts for the symbols in a Microsoft Word
file can be included as follows: enclose the symbol with curly brackets
{cmd:{}} and prepend the superscript code {cmd:\super}.

{pmore}
So for a superscript 1, the {it:text} in {cmd:asymbol()} would be
{cmd:{\super 1}}.  Make sure to include the space after {cmd:\super}.  For
TeX files, "1" can be superscripted either with the code {cmd:"$^1$"} or
{cmd:"\textsuperscript{1}"}.  See the discussion about 
{it:{help outreg_complete##greek:Inline text formatting}}.

{pmore}
To understand the correspondence between the locations in the
{cmd:annotate()} matrix and the final {cmd:outreg} table, it helps to
know how {cmd:outreg} uses the {cmd:frmttable} program to create tables.
Outreg sends the different estimation statistics in separate columns, so
for the default statistics of b and t_abs, {cmd:outreg} sends
a K x 2 matrix to {cmd:frmttable}, where K is the number of
coefficients.  The nonzero locations of {cmd:annotate()} that indicate a
symbol should be added correspond to the locations of the K x 2 matrix
passed to {cmd:frmttable}, not the 2K x 1 table of statistics created
by {cmd:frmttable}.  Perhaps a simpler way of saying this is that
{cmd:annotate()} positions correspond to the final table positions when
you use the {helpb outreg_complete##nosubstat:nosubstat} option.  If
there are S statistics (2, by default), the {cmd:annotate()} matrix
should be a K x S Stata matrix, where K is the number of columns in
{cmd:e(b)}.  This can be created in Stata for a regression with five
coefficients and the default of two statistics like this:{p_end}{...}

{pmore2}
	{cmd}. matrix annotmat = J(5,2,0){p_end}
{pmore2}
	{cmd}. matrix annotmat[1,1] = 1{p_end}
{pmore2}
	{cmd}. matrix annotmat[3,2] = 2{p_end}
{pmore2}
	{cmd}. outreg ... , annotate(annotmat) asymbol(" (1)"," (2)"){p_end}
{txt}{...}

{pmore}
This will assign the first {cmd:asymbol(" (1)")} to the first coefficient, and
the second {cmd:asymbol(" (2)")} to the third t statistic.

{pmore}
In fact, the {cmd:annotate()} matrix can be smaller than K x S if there
are rows at the bottom of the table or columns on the right of the table
that do not need any symbols.  In other words, if the {cmd:annotate()}
matrix is not the same size as the statistics, the missing, or too
large, parts of it are ignored.

{pmore}
If {cmd:annotate()} and {cmd:asymbol()} are used to create footnote
references, the footnotes themselves can be included in the 
{helpb outreg_complete##note:note()} option.

{pmore}
See {help outreg_complete##xmpl14:example 14} for an application of
{cmd:annotate()} and {cmd:asymbol()}.


{marker col_formats}{...}
{dlgtab:Column formatting}

{marker colwidth}{...}
{phang}
{cmd:colwidth(}{it:{help numlist}}{cmd:)} assigns column widths.  By
default, {cmd:outreg} makes its best guess of the appropriate column width, but
Microsoft Word Rich Text Format (RTF) files have no algorithm to ensure that
the column width exactly fits the maximum width of the contents of its cells,
the way TeX files do.  In particular, when special nonprinting formatting codes
(such as superscript codes) are included in {cmd:ctitles()} and
{cmd:rtitles()}, {cmd:outreg} will probably get the width wrong, and
{cmd:colwidth()} will be needed.  This option is only allowed for Microsoft
Word files, not TeX files, which automatically determine column widths.

{pmore}
If {it:numlist} has fewer widths than the number of columns,
{cmd:outreg} will guess the best width for the remaining columns.
Specifying {cmd:colwidth(10)} will assign a width of 10 characters to
the first column in the table, but not change the width of other
columns.  To assign a width of 10 to all columns in a five-column table,
use {cmd:colwidth(10 10 10 10 10)}.  The width of the column using
{cmd:colwidth(1)} is equal to the width of one "n" of the currently
assigned point size, with the addition of the default buffers on either
side of the cell.

{marker multicol}{...}
{phang}
{cmd:multicol(}{it:{help outreg_complete##numtriple:numtriple}}[{cmd:;}
{it:{help outreg_complete##numtriple:numtriple}} ...]{cmd:)} combines
table cells into one cell that spans multiple columns.  This is mainly
used for column titles that apply to more than one column.

{marker numtriple}{...}
{pmore}
A {it:numtriple} means three numbers, separated by commas.  Each
{it:numtriple} consist of the row of the first cell to be combined, the
column of the first cell, and the number of cells to be combined (>=2).

{pmore}
For example, to combine the heading for the first two statistics columns
in a table (with only one {helpb outreg_complete##rtitles:rtitles()}
column), the option would be {cmd:multicol(1,2,2)}.  That is, the
combined cells start in the first row of the table (below the title) and
the second column of the table (the start of the statistics columns),
and two cells are to be combined.  See an example of {cmd:multicol()} in 
{help outreg_complete##xmpl10:example 10}.

{pmore}
It often looks good to underline the 
{helpb outreg_complete##ctitles:ctitles()} in the combined cell to make clear
that the column title applies to both columns below it.  In Microsoft Word RTF
files, underlining does not apply to blank spaces, so to extend the underline
to either side of the text in the {cmd:ctitles()}, you can insert tab
characters, which will be underlined.  For example, for the {cmd:ctitles()}
text "{cmd:First 2}", you could apply codes for underlining and tabs like this:
{cmd:ctitle("","{\ul\tab First 2\tab\tab}")}.  Note the obligatory space
between the RTF code {cmd:\tab} and the text {cmd:First 2}.  Underscore
characters ({cmd:_}) can also be used to extend underlining where there is no
text, although they create a line that is slightly lower than the underlining
line.

{marker coljust}{...}
{phang}
{cmd:coljust(}{it:{help outreg_complete##cjstring:cjstring}}[{cmd:;}
{it:{help outreg_complete##cjstring:cjstring}} ...]{cmd:)} specifies
whether the table columns are left-, center-, or right-justified (that is,
the text in each row is flush with the left, center, or right side of
the column) or centered on the decimal point (for Microsoft Word files only).
By default, the {helpb outreg_complete##rtitles:rtitles()} columns are
left-justified and the rest of the columns are decimal-justified for Microsoft
Word files.  For TeX files, {helpb outreg_complete##rtitles:rtitles()} columns
are left-justified and the rest of the columns are center-justified.

{marker cjstring}{...}
{pmore}
{it:cjstring} is a string made up of

{p2colset 11 22 24 2}{...}
{p2col:{it:cjstring}}Action{p_end}
{p2line}
{p2col:{opt l}}left-justification{p_end}
{p2col:{opt c}}center-justification{p_end}
{p2col:{opt r}}right-justification{p_end}
{p2col:{opt .}}decimal-justification (Microsoft Word only){p_end}
{p2col:{cmd:{}}}repetition{p_end}
{p2line}

{pmore}
Left-, center-, and right-justification are self-explanatory, but
decimal-justification requires some elaboration.  Decimal-justification lines
up all the numbers in the column so that the decimal points are in a vertical
line.  Whole numbers are justified to the left of the decimal point.  Text in
{helpb outreg_complete##ctitles:ctitles()} is not decimal-justified --
otherwise, all {cmd:ctitles()} for the column would be to the left of the
decimal point, like whole numbers.  Instead, in columns with
decimal-justification, {cmd:ctitles()} are center-justified.

{pmore}
Decimal-justification works with comma decimal points used in many European
languages (to set comma decimal points in Stata, see
{helpb format:set dp comma}); however, Microsoft Word will recognize the comma
decimal points correctly only if the operating system has been changed to
specify comma decimal points.  In the Microsoft Windows operating system, this
can be done in the Control Panel under Regional and Language Options.  In the
Mac OS X operating system, this is done in System Preferences under Language
and Text: Formats.

{pmore}
Each letter in {it:cjstring} indicates the column justification for one column.
For example, {cmd:coljust(lccr)} left-justifies the first column,
center-justifies the second and third columns, and right-justifies the fourth
column.  If there are more than four columns, the remaining columns will be
right-justified, because the last element in the string is applied repeatedly.
If there are fewer than four columns, the extra justification characters are
ignored.

{pmore}
The curly brackets, {cmd:{}}, repeat the middle of {it:cjstring}.  For example,
{cmd:coljust(l{c}rr)} left-justifies the first column, center-justifies all the
subsequent columns up to the next to last column, and right-justifies the last
two columns.

{pmore}
The semicolon, {cmd:;}, applies column justification to separate 
{help outreg_complete##or_sections:sections} of the {cmd:outreg} table but is
not needed by most users.  {cmd:outreg} tables have two column sections:
the columns of {helpb outreg_complete##rtitles:rtitles()} (typically one
column) and the columns of estimation statistics.

{pmore}
The section divider allows you to specify the column justification
without knowing how many columns are in each section.  Hence, the
default {cmd:coljust()} parameters for Microsoft Word files are
{cmd:coljust(l;.)}, which applies left-justification to all the columns in the
first ({cmd:rtitles()}) section of the table and decimal-justification to the
remaining column sections of the table.

{pmore}
For example, {cmd:coljust(l{c}r;r{c}l)} would apply {cmd:l{c}r} only to the
first column section and would apply {cmd:r{c}l} to the second (or more) column
sections.

{pmore}
Technical note: TeX has the capability for decimal-justification with the
{cmd:dcolumn} package or the {cmd:coljust({r@{.}l})} column-justification
syntax.  However, both of these methods conflict with other capabilities of
{cmd:outreg} in ways that make them very difficult to implement.  The
{cmd:dcolumn} package interferes with the {cmd:multicol()} option and also
imposes math mode for the decimal-justified columns, which is inconsistent with
{cmd:outreg} formatting.  The {cmd:coljust({r@{.}l})} syntax splits the column
in question into two columns, which would require workarounds for many
{cmd:outreg} options.  Users who do not care to have their t statistics
displayed in a smaller font than the coefficient estimations (as is the default
in {cmd:outreg}), can modify their TeX tables manually to implement
decimal-justification by using the {cmd:dcolumn} package.

{marker nocenter}{...}
{phang}
{cmd:nocenter} specifies not to center the {cmd:outreg} table within the
document page.  This does not apply to the display of the {cmd:outreg}
table in the Stata Results window, which is always centered.


{marker fonts}{...}
{dlgtab:Font specification}

{marker basefont}{...}
{phang}
{cmd:basefont(}{it:{help outreg_complete##fontlist:fontlist}}{cmd:)}
changes the base font for all text in the {cmd:outreg} table, as well as
{helpb outreg_complete##pretext:pretext()} and
{helpb outreg_complete##posttext:posttext()}.  The default font specification
is 12-point Times New Roman for Microsoft Word documents and is left
unspecified for TeX documents (which normally means it is 10-point Times New
Roman).

{marker fontlist}{...}
{pmore}
The {it:fontlist} is made up of elements in the tables below (different
for {help outreg_complete##fontlist_word:Microsoft Word} and 
{help outreg_complete##fontlist_tex:TeX} files), separated by spaces.
The elements of the {it:fontlist} can specify font size, font type (for
example, Times New Roman, Arial, or a new font from 
{helpb outreg_complete##addfont:addfont()}), and font style (like italic
or bold).

{pmore}
If you specify more than one font type ({cmd:roman}, {cmd:arial},
{cmd:courier}, and perhaps {cmd:fnew}{it:#}), only the last choice in
the {it:fontlist} will be in effect.

{pmore}
See {help outreg_complete##xmpl11:example 11} for an application of
{cmd:basefont()}.

{marker fontlist_word}{...}
{pmore}
A {it:fontlist} for Microsoft Word files is made up of

{p2colset 11 25 27 2}{...}
{p2col:{it:fontlist}}Action{p_end}
{p2line}
{p2col:{cmd:fs}{it:#}}font size in points{p_end}
{p2col:{cmd:arial}}Arial font{p_end}
{p2col:{cmd:roman}}Times New Roman font{p_end}
{p2col:{cmd:courier}}Courier New font{p_end}
{p2col:{cmd:fnew}{it:#}}font specified in {cmd:addfont()}{p_end}
{p2col:{cmd:plain}}no special font effects{p_end}
{p2col:{cmd:b}}bold text{p_end}
{p2col:{cmd:i}}italicize text{p_end}
{p2col:{cmd:scaps}}small caps: capitalize lowercase letters{p_end}
{p2col:{cmd:ul}}underline text{p_end}
{p2col:{cmd:uldb}}underline text with a double line{p_end}
{p2col:{cmd:ulw}}underline words only (not spaces between words){p_end}
{p2line}

{marker fontlist_tex}{...}
{pmore}
A {it:fontlist} for TeX files is made up of

{p2colset 11 25 27 2}{...}
{p2col:{it:fontlist}}Action{p_end}
{p2line}
{p2col:{cmd:fs}{it:#}}font size in points (10, 11, or 12)*{p_end}
{p2col:{cmd:Huge}}bigger than {cmd:huge}{p_end}
{p2col:{cmd:huge}}bigger than {cmd:LARGE}{p_end}
{p2col:{cmd:LARGE}}bigger than {cmd:Large}{p_end}
{p2col:{cmd:Large}}bigger than {cmd:large}{p_end}
{p2col:{cmd:large}}bigger than {cmd:normalsize}{p_end}
{p2col:{cmd:normalsize}}default font size{p_end}
{p2col:{cmd:small}}smaller than {cmd:normalsize}{p_end}
{p2col:{cmd:footnotesize}}smaller than {cmd:small}{p_end}
{p2col:{cmd:scriptsize}}smaller than {cmd:footnotesize}{p_end}
{p2col:{cmd:tiny}}smaller than {cmd:scriptsize}{p_end}
{p2col:{cmd:rm}}Times New Roman font{p_end}
{p2col:{cmd:it}}italic text{p_end}
{p2col:{cmd:bf}}bold text{p_end}
{p2col:{cmd:em}}emphasize text (same as {cmd:bf}){p_end}
{p2col:{cmd:sl}}slanted text{p_end}
{p2col:{cmd:sf}}sans serif font, that is, Arial{p_end}
{p2col:{cmd:sc}}small caps{p_end}
{p2col:{cmd:tt}}teletype, that is, Courier{p_end}
{p2col:{cmd:underline}}underline text{p_end}
{p2line}
{phang2}* {cmd:fs}{it:#} can only be specified in the {cmd:basefont()} option
for TeX files, not in other font specification options.

{marker titlfont}{...}
{phang}
{cmd:titlfont(}{it:{help outreg_complete##fontcolumn:fontcolumn}}{cmd:)}
changes the font for the table's title.

{marker ctitlfont}{...}
{phang}
{cmd:ctitlfont(}{it:{help outreg_complete##fontgrid:fontgrid}} [{cmd:;}
{it:{help outreg_complete##fontgrid:fontgrid}} ...]{cmd:)} changes the
fonts for column titles.

{marker rtitlfont}{...}
{phang} {cmd:rtitlfont(}{it:{help outreg_complete##fontgrid:fontgrid}}
[{cmd:;} {it:{help outreg_complete##fontgrid:fontgrid}} ...]{cmd:)} changes
the fonts for row titles.

{marker statfont}{...}
{phang}
{cmd:statfont(}{it:{help outreg_complete##fontgrid:fontgrid}}
[{cmd:;} {it:{help outreg_complete##fontgrid:fontgrid}} ...]{cmd:)} changes the
fonts for statistics in the body of the table.

{pmore}
{cmd:ctitlfont()}'s, {cmd:rtitlfont()}'s, and {cmd:statfont()}'s
arguments are {it:fontgrid}s to allow a different font specification for
each cell of the {helpb outreg_complete##ctitles:ctitles()}, 
{helpb outreg_complete##rtitles:rtitles()}, or table statistics,
respectively.  By default, all of these areas of the table have the same
font as the {helpb outreg_complete##basefont:basefont()}, which by
default is 12-point Times New Roman for Microsoft Word files.

{marker fontgrid}{...}
{pmore}
A {it:fontgrid} consists of {it:fontrow} [{cmd:\} {it:fontrow} ... ], where
{it:fontrow} is {it:fontlist} [{cmd:,} {it:fontlist} ...] and where
{it:fontlist} is defined above for
{help outreg_complete##fontlist_word:Microsoft Word files} and for
{help outreg_complete##fontlist_tex:TeX files}.

{pmore}
For example, to make the font for the first row of {cmd:ctitles()} bold
and the second (and subsequent) rows of {cmd:ctitles()} italic, you
could use {cmd:ctitlfont(b\i)} for a Microsoft Word file or
{cmd:ctitlfont(bf\it)} for a TeX file.

{pmore}
The semicolon in the argument list applies different fonts to
separate {help outreg_complete##or_sections:sections} of the
{cmd:outreg} table.  This is more likely to be useful for row sections
than column sections.  {cmd:outreg} tables have two column sections: the
columns of {helpb outreg_complete##rtitles:rtitles()} (typically one
column), and the columns of estimation statistics.  {cmd:outreg} tables
have four row sections: the rows of 
{helpb outreg_complete##ctitles:ctitles()} (often one row), and three sections
for the {helpb outreg_complete##rtitles:rtitles()} and statistics:  the
rows of regular coefficients, the rows of constant coefficients, and the
rows of summary statistics below the coefficients.

{pmore}
The section divider allows you to specify the column or row fonts
without knowing for a particular table how many columns or rows are in
each section.  To italicize the t statistics below coefficient estimates
for the coefficients, but not italicize the summary statistics rows, you
could use {cmd:statfont(plain\i;plain\i;plain)} for a Microsoft Word file, or
{cmd:statfont(rm\it;rm\it;rm)} for a TeX file.

{pmore}
Note that if you specify a new font type or a single font point size in
{cmd:titlfont()} or {cmd:statfont()}, this is applied to all rows of the
{cmd:title()} or estimation statistics, removing the default behavior of
making the subtitles smaller than the first row of {cmd:title()} and
the substatistics like the t statistic smaller than the coefficient
estimates.  To retain this behavior, specify two rows of font sizes in
{cmd:titlfont()} or {cmd:statfont()}, with the second being smaller than
the first.  Changing the {cmd:basefont()} does not have any effect on
the differing font sizes in the rows of {cmd:title()} and estimation
statistics.

{marker notefont}{...}
{phang}
{cmd:notefont(}{it:{help outreg_complete##fontcolumn:fontcolumn}}{cmd:)}
changes the font for notes below the table.

{pmore}
{cmd:titlfont()} and {cmd:notefont()} take a {it:fontcolumn} rather than
a {it:fontlist} to allow for different fonts on different rows of titles
or notes, such as a smaller font for the subtitle than the main title.

{marker fontcolumn}{...}
{pmore}
A {it:fontcolumn} consists of {it:fontlist} [{cmd:\} {it:fontlist} ...],
where {it:fontlist} is defined above for
{help outreg_complete##fontlist_word:Microsoft Word files} or for
{help outreg_complete##fontlist_tex:TeX files}.

{pmore}
For example, to make the title font large and small caps, and the
subtitles still larger than regular text, without small caps, you could
use {cmd:titlfont(fs17 scaps\fs14)} for a Microsoft Word file, or
{cmd:titlfont(Large sc\large)} for a TeX file.

{marker addfont}{...}
{phang}
{cmd: addfont(}{it:{help outreg_complete##textrow:textrow}}{cmd:)} adds a new
font type, making it available for use in the font specifications for
various parts of the {cmd:outreg} table.  This option is available only
for Microsoft Word files, not TeX files.

{pmore}
By default, only Times New Roman ({cmd:roman}), Arial ({cmd:arial}), and
Courier New ({cmd:courier}) are available for use in Microsoft Word RTF
documents.  {cmd:addfont()} makes it possible to make additional fonts
available for use in the Microsoft Word documents created by {cmd:outreg}.

{pmore}
{it:{help outreg_complete##textrow:textrow}} is a sequence of font names in
quotation marks, separated by commas.

{pmore}
The new font in {cmd:addfont()} can be referenced in the various font
specification options, like {helpb outreg_complete##basefont:basefont()}
and {helpb outreg_complete##titlfont:titlfont()}, with the code
{cmd:fnew1} for the first new font in {cmd:addfont()} and increments of
it ({cmd:fnew2}, {cmd:fnew3}, etc.) for each additional font.

{pmore}
If the font specified in {cmd:addfont()} is not available on your computer when
using the Microsoft Word file created by {cmd:outreg}, the new font will not
display correctly -- another font will be substituted.  You can find the
correct name of each available font in Microsoft Word by scrolling through the
font selection window on the toolbar of the Microsoft Word application.

{pmore}
See {help outreg_complete##xmpl11:example 11} for an application of
{cmd:addfont()}.

{marker plain}{...}
{phang}
{cmd:plain} eliminates default formatting, reverting to plain text: only
one font size for the whole table, no column justification, and no added
space above and below the horizontal border lines.  Instead of using
{cmd:plain}, the default formatting can also be reversed feature by
feature with {helpb outreg_complete##titlfont:titlfont()}, 
{helpb outreg_complete##notefont:notefont()}, 
{helpb outreg_complete##coljust:coljust()}, 
{helpb outreg_complete##spacebef:spacebef()}, and 
{helpb outreg_complete##spaceaft:spaceaft()}.  The {cmd:plain} option does this
all at once.

{marker or_sections}{...}
{phang}
{it:outreg_table_sections}: It can be helpful for specifying fonts and
other formatting to understand how {cmd:outreg} divides the table into
sections.  The following diagram illustrates the section divisions:

		   {c TLC}{dup 53:{c -}}{c TRC}
		   {c |}                        title                        {c |}
		   {c BLC}{dup 53:{c -}}{c BRC}
		     column section 1		column section 2
		   {c TLC}{dup 18:{c -}}{c TT}{dup 34:{c -}}{c TRC}
		{c TLC}{c -} {c TLC}{dup 18:{c -}}{c TT}{dup 34:{c -}}{c TRC}
		{c |}  {c |}{dup 18: }{c |}{dup 34: }{c |}
 row section 1  {c |}  {c |}     ctitles      {c |}        ctitles{dup 19: }{c |}
		{c |}  {c |}{dup 18: }{c |}{dup 34: }{c |}
		{c LT}{c -} {c LT}{dup 18:{c -}}{c +}{dup 34:{c -}}{c RT}
		{c |}  {c |}{dup 18: }{c |}{dup 34: }{c |}
		{c |}  {c |}{dup 18: }{c |}{dup 34: }{c |}
		{c |}  {c |}{dup 18: }{c |}{dup 34: }{c |}
 row section 2  {c |}  {c |}     rtitles      {c |}        coefficient estimates{dup 5: }{c |}
		{c |}  {c |}{dup 18: }{c |}        (except for constants)    {c |}
		{c |}  {c |}{dup 18: }{c |}{dup 34: }{c |}
		{c |}  {c |}{dup 18: }{c |}{dup 34: }{c |}
		{c LT}{c -} {c LT}{dup 18:{c -}}{c +}{dup 34:{c -}}{c RT}
 row section 3  {c |}  {c |}     rtitles      {c |}        constant coefficients{dup 5: }{c |}
		{c LT}{c -} {c LT}{dup 18:{c -}}{c +}{dup 34:{c -}}{c RT}
 row section 4  {c |}  {c |}     summtitles   {c |}        summstat{dup 18: }{c |}
		{c BLC}{c -} {c BLC}{dup 18:{c -}}{c BT}{dup 34:{c -}}{c BRC}

		   {c TLC}{dup 53:{c -}}{c TRC}
		   {c |}                        note                         {c |}
		   {c BLC}{dup 53:{c -}}{c BRC}


{marker lines_spaces}{...}
{dlgtab:Lines and spaces}

{marker hlines}{...}
{phang}
{cmd:hlines(}{it:{help outreg_complete##linestring:linestring}} [{cmd:;}
{it:{help outreg_complete##linestring:linestring}} ...]{cmd:)} draws
horizontal lines between rows.

{marker vlines}{...}
{phang}
{cmd:vlines(}{it:{help outreg_complete##linestring:linestring}} [{cmd:;}
{it:{help outreg_complete##linestring:linestring}} ...]{cmd:)} draws
vertical lines between columns.

{pmore}
{opt hlines()} and {cmd:vlines()} designate where horizontal and
vertical lines will be placed to delineate parts of the table.  By
default, {cmd:outreg} draws horizontal lines above and below the
{cmd:ctitles()} header rows and at the bottom of the table above the
notes, if any.  There are no vertical lines by default.

{marker linestring}{...}
{pmore}
{it:linestring} is a string made up of

{p2colset 11 25 27 2}{...}
{p2col:{it:linestring}}Action{p_end}
{p2line}
{p2col:{opt 1}}add a line{p_end}
{p2col:{opt 0}}no line{p_end}
{p2col:{cmd:{}}}repetition{p_end}
{p2line}

{pmore}
Each {cmd:1} in {it:linestring} indicates a line and a {cmd:0} indicates
no line.  For example, {cmd:hlines(110001)} would draw a line above and
below the first row of the table and below the fifth row (above the
sixth row).  There is one more possible horizontal line than row (and
one more vertical line than column).  That is, for a five-row table, to
put a line above and below every row one would specify six
{cmd:hlines()}:  {cmd:hlines(111111)}.

{pmore}
{cmd:hlines()} and {cmd:vlines()} are not displayed correctly in the Stata
Results window.  They only apply to the final Microsoft Word or TeX document.

{pmore}
Curly brackets repeat the middle of {it:linestring}.  For example,
{cmd:hlines(11{0}1)} puts a horizontal line above and below the first
row, and another below the last row.

{pmore}
The semicolon applies line designations to separate 
{help outreg_complete##or_sections:sections} of the {cmd:outreg} table.
{cmd:outreg} tables have two column sections and four row sections.  The
column sections are made up of the columns of 
{helpb outreg_complete##rtitles:rtitles()} (typically one column) and
the columns of the estimation statistics.  The row sections are made up
of the rows of {helpb outreg_complete##ctitles:ctitles()} (often one
row), the rows of the coefficient estimates (except the constant), the
rows of the constant coefficients, and the rows of the summary
statistics below the coefficients.

{pmore}
The section divider allows you to specify {cmd:hlines()} and
{cmd:vlines()} without knowing how many rows and columns are in each
section.  Hence, the default {cmd:hlines()} elements are
{cmd:hlines(1{0};1{0}1)}, which puts a horizontal line above the header
rows, a line above the statistics rows, and a line below the last
statistics row.  By default, there are no {cmd:vlines()}, which some
graphic designers think are best avoided.

{marker hlstyle}{...}
{phang}
{cmd:hlstyle(}{it:{help outreg_complete##lstylestring:lstylestring}} [{cmd:;}
{it:{help outreg_complete##lstylestring:lstylestring}} ...]{cmd:)}
changes the style of horizontal lines.

{marker vlstyle}{...}
{phang}
{cmd:vlstyle(}{it:{help outreg_complete##lstylestring:lstylestring}} [{cmd:;}
{it:{help outreg_complete##lstylestring:lstylestring}} ...]{cmd:)}
changes the style of vertical lines.

{pmore}
{cmd:hlstyle()} and {cmd:vlstyle()} options are only available for Microsoft
Word files.  By default, all lines are solid single lines.

{marker lstylestring}{...}
{pmore}
{it:lstylestring} is a string made up of

{p2colset 11 25 27 2}{...}
{p2col:{it:lstylestring}}Action{p_end}
{p2line}
{p2col:{opt s}}single line{p_end}
{p2col:{opt d}}double line{p_end}
{p2col:{opt o}}dotted line{p_end}
{p2col:{opt a}}dashed line{p_end}
{p2col:{opt S}}heavyweight single line{p_end}
{p2col:{opt D}}heavyweight double line{p_end}
{p2col:{opt O}}heavyweight dotted line{p_end}
{p2col:{opt A}}heavyweight dashed line{p_end}
{p2col:{cmd:{}}}repetition{p_end}
{p2line}

{pmore}
Repetition using curly brackets and semicolons for section
dividers are used in the same way they are for 
{helpb outreg_complete##hlines:hlines()} and 
{helpb outreg_complete##vlines:vlines()}.

{pmore}
Some word processing applications, like Open Office or Pages (for the
Mac) do not display all Microsoft Word RTF line styles correctly.

{marker spacebef}{...}
{phang}
{cmd:spacebef(}{it:{help outreg_complete##spacestring:spacestring}}
[{cmd:;} {it:{help outreg_complete##spacestring:spacestring}} ...]{cmd:)} puts
space above cell contents.{p_end}

{marker spaceaft}{...}
{phang}
{cmd:spaceaft(}{it:{help outreg_complete##spacestring:spacestring}}
[{cmd:;} {it:{help outreg_complete##spacestring:spacestring}} ...]{cmd:)} puts
space below cell contents.{p_end}

{marker spaceht}{...}
{phang}
{opt spaceht(#)} changes the size of the space above and below cell
contents in {cmd:spacebef()} and {cmd:spaceaft()}.

{pmore}
{cmd:spacebef()} and {cmd:spaceaft()} are options to make picky changes
in the appearance of the table.  They increase the height of the cells
in particular rows so that there is more space above and below the
contents of the cell.  They are used by default to put space between the
horizontal line at the top of the table and the first header row, above
and below the line separating the header row from the statistics, and
below the last row of the table above the horizontal line.

{marker spacestring}{...}
{pmore}
{it:spacestring} has the same form as 
{it:{help outreg_complete##linestring:linestring}} above.  A "{cmd:1}"
indicates an extra space (above the cell if in {cmd:spacebef()} and below
the cell if in {cmd:spaceaft()}), and a "{cmd:0}" indicates no extra space.
{cmd:{}} repeats indicators and {cmd:;} separates row sections.

{pmore}
{cmd:spaceht()} controls how big the extra space is in {cmd:spacebef()} and
{cmd:spaceaft()}.  Each one-unit increase in {cmd:spaceht()} increases the
space by about a third of the height of a capital letter.  The default
is {cmd:spaceht(1)}.  {cmd:spaceht()} is scaled proportionally to the base
font size for the table.  For example, {cmd:spaceht(2)} makes the extra
spacing 100% larger than it is by default.

{pmore}
For TeX files (using the {opt tex} option), {cmd:spaceht()} can only
take the values 2 or 3.  The default corresponds to the LaTeX code
{cmd:\smallskip}.  Values 2 and 3 for {cmd:spaceht()} correspond to the
LaTeX codes {cmd:\medskip} and {cmd:\bigskip}, respectively.


{marker page_fmt}{...}
{dlgtab:Page formatting}

{marker landscape}{...}
{phang}
{opt landscape} puts the document page containing the {cmd:outreg} table
in landscape orientation.  This makes the page wider than it is tall, in
contrast to portrait orientation.  {opt landscape} is convenient for
wide tables.  An alternative way of fitting a table on the page is to
use a smaller {helpb outreg_complete##basefont:basefont()}, without the
need for the {opt landscape} option.

{marker a4}{...}
{phang}
{opt a4} specifies A4 size paper (instead of the default 8 1/2" x 11")
for the Microsoft Word or TeX document containing the {cmd:outreg} table.


{marker file_options}{...}
{dlgtab:File and display options}

{marker tex}{...}
{phang}
{opt tex} specifies that {cmd:outreg} writes a TeX output file rather
than a Microsoft Word file.  The output is suitable for including in a TeX
document (see the {helpb outreg_complete##fragment:fragment} option) or
loading into a TeX typesetting program such as Scientific Word.

{marker merge}{...}
{phang}
{cmd:merge}[{cmd:(}{it:{help outreg_complete##tblname:tblname}}{cmd:)}]
specifies that new estimation output be merged to the most recently
created {cmd:outreg} table.  The new coefficient estimates are combined
with previous estimates, lined up according to the appropriate variable
name (or {helpb outreg_complete##rtitles:rtitles()}), with the
coefficients for variables introduced in the new estimation placed below
the original variables, but above the constant term.

{pmore}
Note that in previous versions of {cmd:outreg}, the {cmd:merge} option
was called {cmd:append}.  Users will usually want to specify 
{helpb outreg_complete##ctitles:ctitles()} when using {cmd:merge}.

{pmore}
{opt merge} can be used even if a previous {cmd:outreg} table does not
exist for merging.  This is to enable {opt merge} to be used in loops,
as in {help outreg_complete##xmpl16:example 16}.  {cmd:outreg} issues a
warning message if no existing table is found.

{pmore}
If a {it:tblname} is specified, the current estimates will be merged to
an existing table named {it:tblname}, which could have been created with
a previous {cmd:outreg, store(}{it:tblname}{cmd:)} command or an 
{cmd:outreg, merge(}{it:tblname}{cmd:)} command.

{marker tblname}{...}
{pmore}
A {it:tblname} consists of the characters {cmd:A}-{cmd:Z}, {cmd:a}-{cmd:z},
{cmd:0}-{cmd:9}, and "{cmd:_}", and
can have a length of up to 25 characters.

{marker replace}{...}
{phang}
{opt replace} specifies that it is okay to overwrite an existing file.

{marker addtable}{...}
{phang}
{opt addtable} places the estimation results as a new table below an
existing table in the same document (rather than combining the tables as
with {helpb outreg_complete##merge:merge}).  This makes it possible to
build up a document with multiple tables in it.

{pmore}
Options {cmd:pretext()} and {cmd:posttext()} can add accompanying text
between the tables.  To put a page break between successive tables, so
that each table is on its own page, see the discussion for 
{helpb outreg_complete##pretext:pretext()} and
{helpb outreg_complete##posttext:posttext()}, above.

{pmore}
See {help outreg_complete##xmpl13:example 13} for an application of
{cmd:addtable}.

{marker append}{...}
{phang}
{cmd:append}[{cmd:(}{it:{help outreg_complete##tblname:tblname}}{cmd:)}]
combines the estimation results as new rows below an existing table.  If a
{it:tblname} is specified, the current estimates will be appended to an
existing {cmd:outreg} table named {it:tblname} (see the
{helpb outreg_complete##store:store()} option).

{pmore}
{bf:Warning: This is not the append option from previous versions of outreg -- if you are looking for that append, use {helpb outreg_complete##merge:merge}}.

{pmore}
{opt append} can be used even if no previous {cmd:outreg} table exists,
which is useful in loops for the first invocation of the 
{cmd:outreg, append} command.

{pmore}
{opt append} does not match up column headings.  The column headings of
the new table being appended are ignored unless the new table has more
columns than the original table, in which case only the headings of the
new columns are used.

{marker replay}{...}
{phang}
{cmd:replay}[{cmd:(}{it:{help outreg_complete##tblname:tblname}}{cmd:)}]
is used to rewrite an existing {cmd:outreg} table to a file without
including any new estimation results.  This can be used to rewrite the
same table with different text formatting options.  If a {it:tblname} is
specified, {cmd:replay} will use the table with that name.

{pmore}
{opt replay} is useful after running a loop that merges multiple
estimation results together, to write the final merged table to a
document file.  See {help outreg_complete##xmpl16:example 16}.

{marker store}{...}
{phang}
{cmd:store(}{it:{help outreg_complete##tblname:tblname}}{cmd:)} is used
to assign a {it:tblname} to an {cmd:outreg} table.  This is useful
mainly for building more than one table simultaneously, by merging new
estimation results to separate tables when the estimation commands must
be run sequentially.

{marker clear}{...}
{phang}
{cmd:clear}[{cmd:(}{it:{help outreg_complete##tblname:tblname}}{cmd:)}]
removes the current {cmd:outreg} table from memory.  This is helpful
when using {cmd:outreg, merge} in a loop so that the first time
{cmd:outreg, merge} is invoked, the estimation results are not merged to
an existing {cmd:outreg} table (such as the one created the last time
the do-file was run).  {cmd:outreg, clear} clears the current table,
allowing the user to start with a blank slate.

{pmore}
If a {it:tblname} is specified, the {cmd:outreg} table named
{it:tblname} will be removed from memory.

{marker fragment}{...}
{phang}
{opt fragment} creates a TeX code fragment for inclusion in a larger TeX
document instead of a stand-along TeX document.  A TeX fragment, saved to
the file {cmd:auto.tex}, can then be included in the following TeX document
with the TeX {cmd:\input{auto}} command:

{pmore2}
{cmd:\documentclass[]{article}}{p_end}
{pmore2}
{cmd:\begin{document}}{p_end}
{pmore2}
... text before inclusion of table auto.tex ...{p_end}
{pmore2}
{cmd:\input{auto}}{p_end}
{pmore2}
... text after inclusion of table auto.tex ...{p_end}
{pmore2}
{cmd:\end{document}}{p_end}

{pmore}
Including TeX fragments with the TeX {cmd:\input{}} command allows the table
created by {cmd:outreg} to be updated without having to change the TeX
code for the document itself.  This is convenient because estimation
tables often require small modifications that can be made without
having to reinsert a new table manually.  Creating TeX fragments for
inclusion in larger TeX documents is especially useful when there are
many tables in a single document (see also the 
{helpb outreg_complete##addtable:addtable} option).

{pmore}
An alternative to the TeX {cmd:\input{}} command is the TeX
{cmd:\include{}} command, which inserts page breaks before and after the
included table.

{marker nodisplay}{...}
{phang}
{opt nodisplay} suppresses the display of the table in the Stata Results
window.

{marker dwide}{...}
{phang}
{opt dwide} displays all columns in the Stata Results window, however
wide the table is.  This is mainly useful if you want to copy the table
to paste it into another document (which hopefully is not necessary).
Without the {opt dwide} option, very wide tables are displayed in the
Results window in sections containing as many columns as will fit given
the current width of the Results window.


{marker stars_options}{...}
{dlgtab:Asterisk options}

{marker starlevels}{...}
{phang}
{cmd:starlevels(}{it:{help numlist}}{cmd:)} indicates significance
levels for asterisks in percent.  By default, one asterisk is placed next to
coefficients that pass the test for significant difference from zero at
the 5% level, and two asterisks are placed next to coefficients that pass
the test for significance at the 1% level, which is equivalent to specifying
{cmd:starlevels(5 1)}.  To place one asterisk for the 10% level, two for the 5%
level, and three for the 1% level, you would specify {cmd:starlevels(10 5 1)}.
To place one asterisk for the 5% level, two for the 1% level, and three for the
0.1% level, you would specify {cmd:starlevels(5 1 .1)}.

{pmore}
{help outreg##xmpl5:Example 5} applies the {cmd:starlevels()} option.

{marker starloc}{...}
{phang}
{opt starloc(#)} puts asterisks next to the statistics indicated.  By
default, asterisks are displayed next to the second statistic
({cmd:starloc(2)}), but they can be placed next to the first statistic
(usually the coefficient estimate) or next to the third or higher statistic
if they have been specified in 
{helpb outreg_complete##stats:stats()}.

{marker margstars}{...}
{phang}
{opt margstars} calculates asterisks for significance from marginal effects
(and their standard errors), rather than from the coefficients
themselves, which is the default.

{marker nostars}{...}
{phang}
{opt nostars} suppresses the asterisks indicating significance levels.

{marker nolegend}{...}
{phang}
{opt nolegend} indicates that there will be no legend explaining the
asterisks for significance levels below the table (by default, the legend is
"* {it:p}<0.05; ** {it:p}<0.01").  To replace the legend, use the
{cmd:nolegend} option, and put your own legend in a 
{helpb outreg_complete##note:note()}.

{marker sigsymbols}{...}
{phang}
{cmd:sigsymbols(}{it:{help outreg_complete##textrow:textrow}}{cmd:)}
replaces the asterisks used to indicate statistical significance with other
symbols of your choice.  For example, to use a plus sign ({cmd:+}) to indicate
a 10% significance level, you could apply {cmd:sigsymbols(+,*,**)} along
with {cmd:starlevels(10 5 1)}.  By default, {cmd:outreg} uses one asterisk
for the first significance level, and adds an additional asterisk for each
additional significance level displayed.

{pmore}
The argument {it:textrow} consists of text separated by commas.

{pmore}
{help outreg##xmpl5:Example 5} applies the {cmd:sigsymbols()} option.


{marker brack_options}{...}
{dlgtab:Bracket options}

{marker squarebrack}{...}
{phang}
{opt squarebrack} substitutes square brackets for parentheses around the
statistics placed below the first statistic.  For the default
statistics, this means that square brackets, rather than parentheses,
are placed around t statistics below the coefficient estimates.

{pmore}
{opt squarebrack} is equivalent to {cmd:brackets("",""\[,]\(,)\<,>\|,|)}.

{marker brackets}{...}
{phang}
{cmd:brackets(}{it:{help outreg_complete##textpair:textpair}} [{cmd:\}
{it:{help outreg_complete##textpair:textpair}} ...]{cmd:)} specifies the
symbols used to bracket statistics placed below the first statistics.
By default, {cmd: outreg} places parentheses around the second
statistic, the t statistic.

{marker textpair}{...}
{pmore}
A {it:textpair} is made up of two elements of text separated by a comma.  The
default is {cmd:brackets("",""\(,)\[,]\<,>\|,|)}.

{pmore}
If there are a sufficient number of statistics for the symbols to be
used with the {helpb outreg_complete##tex:tex} option, then {cmd:<,>} and
{cmd:|,|} are replaced by {cmd:$<$,$>$} and {cmd:$|$,$|$} so that they show up
correctly in TeX documents.

{pmore}
{cmd:brackets()} has no effect when the 
{helpb outreg_complete##nosubstats:nosubstats} option is used.

{marker nobrket}{...}
{phang}
{opt nobrket} eliminates the application of {cmd:brackets()} so that
there will be no brackets around the second or higher
statistics.

{marker dbldiv}{...}
{phang}
{opt dbldiv(text)} is a rather obscure option that allows you to change
the symbol that divides double statistics.  Double statistics have both
a lower and and upper statistic, like confidence intervals, which are
the only double statistics in {cmd:outreg}.  By default, {cmd:outreg}
puts a dash ({cmd:-}) between the lower and upper statistics, but
{cmd:dbldiv()} allows you to substitute something else.  For example,
{cmd:dbldiv(:)} would put a colon between the lower and upper
statistics.


{marker summstat_options}{...}
{dlgtab:Summary statistics options}

{marker summstat}{...}
{phang} {opt summstat(e_values)} places summary statistics below the
coefficient estimates.  {it:e_values} is a grid of the names of
different {cmd:e()} return values already calculated by the estimation
command.  The syntax of {it:e_values} is the same as the other
grids in {cmd:outreg}.  Elements within a row are separated with commas
and rows are separated by backslashes.  The default is
{cmd:summstat(r2\N)} (when {cmd:e(r2)} is defined), which places the
R-squared statistic {cmd:e(r2)} below the coefficient estimates, and the
number of observations {cmd:e(N)} below that.

{pmore}
To replace the R-squared with the adjusted R-squared stored in {cmd:e(r2_a)},
you could use the options {cmd:summstat(r2_a\N)} and
{cmd:summtitles("Adjusted R2"\"N")}.  You can also specify the number of
decimal places for the summary statistics with the
{helpb outreg_complete##summdec:summdec()} option.  To see a complete list of
the {cmd:e()} macro values available after each estimation command, type
{cmd:ereturn list}.

{pmore}
Statistics not included in the {cmd:e()} return values can be added to
the table with the {helpb outreg_complete##addrows:addrows()} option, as
in {help outreg##xmpl7:example 7}.

{pmore}
See an application of {cmd:summstat()} in {help outreg##xmpl5:example 5}.

{marker summdec}{...}
{phang}
{cmd:summdec(}{it:{help numlist}}{cmd:)} designates the decimal places
displayed for summary statistics in the manner of
{helpb outreg_complete##bdec:bdec()}.

{marker summtitles}{...}
{phang}
{cmd:summtitles(}{it:{help outreg_complete##textgrid:textgrid}}{cmd:)}
designates row titles for summary statistics in the same manner as 
{helpb outreg_complete##rtitles:rtitles()}.

{marker noautosumm}{...}
{phang}
{opt noautosumm} eliminates the automatically generated summary statistics
(R-squared, if there is one, and the number of observations) from the
{cmd:outreg} table.


{marker frmttable_options}{...}
{dlgtab:frmttable options}

{marker blankrows}{...}
{phang}
{opt blankrows} allows blank rows (across all columns) in the body of
the {cmd:outreg} table to remain blank without being deleted.  By
default, {cmd:outreg} sweeps out any completely blank rows.  This option
is useful if you want to use blank rows to separate different parts of
the table.

{marker nofindcons}{...}
{phang}
{opt nofindcons} is a technical option that prevents {helpb frmttable}
from finding the constant coefficient {cmd:_cons} and putting it in a
separate row section.  Usually, finding the constant is needed to ensure
that new variable coefficients are {helpb outreg_complete##merge:merge}d
correctly, above the constant term, when multiple estimations are
merged together.  This option is most likely to be useful when you do
not want the {cmd:_cons} term to be last when using the 
{helpb outreg_complete##keep:keep()} option, or when merging with a
non-{cmd:outreg} table that treats constants differently.


{marker greek}{...}
{title:Inline text formatting: Superscripts, italics, Greek characters, etc.}

{pstd}
{cmd:outreg}'s {help outreg_complete##fonts:font specification options}
allow users to control font characteristics at the table cell level; however,
users often want to change the formatting of a word or just a character in
text or a table cell.  This is true for characteristics like
superscripts, subscripts, italics, bold text, and special characters
such as Greek letters.

{pstd}
Text strings in the {cmd:outreg} table can include inline formatting codes that
change the characteristics of just part of a string.  These codes are distinct
between Microsoft Word and TeX files, because they are really just Microsoft
Word and TeX formatting codes that are passed directly to the output files.

{pstd}
See {help outreg_complete##xmpl12:example 12} for an application of
inline formatting codes in a Microsoft Word table.

    {title:Microsoft Word inline formatting}

{pstd}
The Microsoft Word files created by {cmd:outreg} follow the Microsoft Word Rich Text Format
(RTF) specification.  Many of the RTF specification codes
can be included in {cmd:outreg} text (find the full 210-page
specification in the links of 
{browse "http://en.wikipedia.org/wiki/Rich_Text_Format":http://en.wikipedia.org/wiki/Rich_Text_Format}).
This note will explain a subset of the most useful codes.

{pstd}
Microsoft Word RTF codes are enclosed in curly braces, {cmd:{c -(}} and
{cmd:{c )-}}.  Codes start with a backslash character, {cmd:\}, and then the
code word.  There must be a space after the code word before the text begins so
that the text is distinguished from the code.  For example, the formatting to
italicize the letter "F" is {cmd:{\i F}}, because "i" is the RTF code for
italics.

{pstd}
Be careful to match opening and closing curly brackets because the
consistency of the nested curly brackets in a Microsoft Word file is essential
to the file's integrity.  If one of the curly brackets is missing, the
Microsoft Word file created by {cmd:outreg} may be corrupted and unreadable.
You can trace problems of this kind by temporarily removing inline formatting
that includes curly braces.

{p2colset 11 25 27 2}{...}
{p2col:RTF code}Action{p_end}
{p2line}
{p2col:{opt \i}}italic{p_end}
{p2col:{opt \b}}bold{p_end}
{p2col:{opt \ul}}underline{p_end}
{p2col:{opt \scaps}}small capitals{p_end}
{p2col:{opt \sub}}subscript (and shrink point size){p_end}
{p2col:{opt \super}}superscript (and shrink point size){p_end}
{p2col:{cmd:\fs}{it:#}}font size (in points * 2; for example, 12 point is {cmd:\fs24}){p_end}
{p2line}

{pstd}
Most of these codes are the same as those used in the 
{help outreg_complete##fonts:font formatting options}, but there are
some differences, such as the font size code {cmd:\fs}{it:#} using half
points, not points.

    {title:Greek and other Unicode characters in Microsoft Word}

{pstd}
Microsoft Word RTF files can display Greek letters and any other Unicode
character (as long as it can be represented by the font type you are using).
The codes are explained {help greek_in_word:here}.  Unicode codes in Microsoft
Word are an exception to the rule that the code must be followed by a space
before text.  Text can follow immediately after the Unicode code.

    {title:TeX inline formatting}

{pstd}
The discussion of TeX inline formatting is brief because TeX users are usually
familiar with inserting their own formatting codes into text.  Many online
references explain how to use TeX formatting codes.  A good place to start is
the references section of
{browse "http://en.wikipedia.org/wiki/TeX":http://en.wikipedia.org/wiki/TeX}.  

{pstd}
For many formatting effects, TeX can generate inline formatting in two
alternative ways: in math mode, which surrounds the formatted text or
equation with dollar signs ({cmd:$}), or in text mode, which uses a backslash
followed by formatting code and text in curly brackets.

{pstd}
For example, we can create a superscipted number 2 either as {cmd:$^2$} in
math mode or as {cmd:\textsuperscript{2}} in text mode.  To display
R-squared in a TeX document with the "R" italicized and a superscript
"2", one can either use the code {cmd:"$ R^2$"} or the code
{cmd:\it{R}\textsuperscript{2}"}.

{pstd}
Note the space between the "$" and "R" in {cmd:$ R^2$}; this is a Stata,
not a TeX, issue.  If we had instead written {cmd:{$R^2$}}, Stata would have
interpreted the {cmd:$R} as a global macro, which is probably undefined and
empty, so the TeX document would just contain {cmd:^2$}.  Whenever using TeX
inline formatting in math mode, which starts with a letter, make sure to
place a space between the "$" and the first letter.

{pstd}
Math mode generally italicizes text and is designed for writing
formulas.  A detailed discussion of its capabilities is beyond the scope
of this note.  Below is a table of useful text mode formatting codes.

{p2colset 11 30 32 2}{...}
{p2col:TeX code}action{p_end}
{p2line}
{p2col:{opt \it}}italic{p_end}
{p2col:{opt \bf}}bold{p_end}
{p2col:{opt \underline}}underline{p_end}
{p2col:{opt \sc}}small capitals{p_end}
{p2col:{opt \textsubscript}}subscript (and shrink point size){p_end}
{p2col:{opt \textsuperscript}}superscript (and shrink point size){p_end}
{p2line}

{pstd}
Keep in mind that many of the nonalphanumeric characters have special meaning
in TeX, namely, the following characters: {cmd:_ % # $ & ^ { } ~ \}.  If you
want these characters to be printed in TeX like any other character, include a
{cmd:\} in front of the character.  The exceptions are the last two, {cmd:~}
and {cmd:\} itself.  {cmd:~} is represented by {cmd:\textasciitilde}, and
{cmd:\} is represented by either {cmd:\textbackslash} or {cmd:$\backslash$} to
render properly in TeX.

    {title:Greek letters in TeX}

{pstd}
Greek letters can be coded in TeX documents with a backslash and the
name of the letter written in English, surrounded by "$".  For example,
a lowercase delta can be inserted with the code {cmd:$\delta$}.  Uppercase
Greek letters use the name in English with an initial capital, so an
uppercase delta is {cmd:$\Delta$}.  If you cannot remember how to spell Greek
letters in English, look at the table for Greek letter codes in Microsoft Word
{help greek_in_word:here}.


{marker spec_notes}{...}
{title:Notes about specific estimation commands}

{phang}
{helpb rocfit} reports a t statistic for the null hypothesis that the
slope is equal to 1.  {cmd:outreg} reports the t statistic for the null
hypothesis that the slope is equal to 0.

{phang}
{helpb stcox} and {helpb streg} report hazard ratios by default and the
coefficients only if the {opt nohr} option is used.  {cmd:outreg} does
the reverse.  To show the hazard rates in the {cmd:outreg} table, use
the {helpb outreg_complete##hr:hr} option.

{phang}
{helpb mim} is a user-written command that makes multiple imputations
(see also the Stata command {helpb mi}).  {cmd:mim} does not store the
estimation results in the {cmd:e(b)} and {cmd:e(V)} matrices, so it is
necessary to repost them to these matrices before {cmd:outreg} can
access the {cmd:mim} results.  This is accomplished with the following
commands:

	{cmd}. mat b = e(MIM_Q)
	{cmd}. mat V = e(MIM_V)
{phang2}{cmd:. ereturn post b V, depname(`e(MIM_depvar)') obs(`e(MIM_Nmin)')} 
	     {cmd:dof(`e(MIM_dfmin)')}{p_end}
{txt}
{pmore}
After these commands, {cmd:outreg} can be used in the usual manner.


{marker examples}{...}
{title:Examples}

{pstd}{help outreg##examples:Example 1:  Basic usage and variable labels}{p_end}
{pstd}{help outreg##xmpl2:Example 2:  Decimal places for coefficients and titles}{p_end}
{pstd}{help outreg##xmpl3:Example 3:  Merging estimation tables together}{p_end}
{pstd}{help outreg##xmpl4:Example 4:  Standard errors, brackets, and no asterisks in a TeX file}{p_end}
{pstd}{help outreg##xmpl5:Example 5:  10% significance level and summary statistics}{p_end}
{pstd}{help outreg_complete##xmpl6:Example 6:  Display some but not all coefficients}{p_end}
{pstd}{help outreg_complete##xmpl7:Example 7:  Add statistics not in summstat()}{p_end}
{pstd}{help outreg_complete##xmpl8:Example 8:  Multiequation models}{p_end}
{pstd}{help outreg_complete##xmpl9:Example 9:  Marginal effects and asterisk options}{p_end}
{p 4 20 2}{help outreg_complete##xmpl10:Example 10: Multicolumn ctitles(); merge variable means with estimation results}{p_end}
{pstd}{help outreg_complete##xmpl11:Example 11: Specifying fonts}{p_end}
{pstd}{help outreg_complete##xmpl12:Example 12: Superscripts, italics, and Greek characters}{p_end}
{pstd}{help outreg_complete##xmpl13:Example 13: Place additional tables in same document}{p_end}
{pstd}{help outreg_complete##xmpl14:Example 14: Place footnotes among coefficients}{p_end}
{p 4 20 2}{help outreg_complete##xmpl15:Example 15: Show statistics side by side, like Stata estimation results}{p_end}
{pstd}{help outreg_complete##xmpl16:Example 16: Merge multiple estimation results in a loop}{p_end}


{marker xmpl6}{...}
    {title:Example 6: Display some but not all coefficients}

{pstd}
The options {helpb outreg_complete##keep:keep()} and 
{helpb outreg_complete##drop:drop()} allow you to display some but not
all coefficients in the estimation.  {cmd:keep()} also allows you to
change the order in which the coefficient estimates are displayed.  To
{cmd:keep()} or {cmd:drop()} the constant term, include {cmd:_cons} in the
list of coefficients.

{pstd}
This first example removes dummy variable coefficients and reorders the
coefficients with {cmd:keep(weight foreign)}:

{phang2}{cmd:. tab rep78, gen(repair)}{p_end}
{phang2}{cmd:. regress mpg foreign weight repair1-repair4}{p_end}
{phang2}{cmd:. outreg using auto, keep(weight foreign) varlabels replace}
	{cmd:note(Coefficients for repair dummy variables not shown)}

{pstd}
The {cmd:keep()} and {cmd:drop()} options can use the wildcard characters
{cmd:*}, {cmd:?}, and {cmd:!} and {help fvvarlist:factor-variable} notation.

{pstd}
The second example, below, uses {cmd:keep()} to remove from the table the
auxiliary parameters included in {cmd:e(b)} by Stata.  The {helpb tobit}
command estimates a sigma parameter.  The main coefficient estimates are
included in the {cmd:e(b)} vector with the equation name {cmd:model}, and the
sigma parameter is given the equation name {cmd:sigma}.  

{pstd}
When in doubt about
which equation names are included in the {cmd:e(b)} vector after an
estimation, you can view the matrix and its names by using the 
{cmd:matrix list e(b)} command.  {cmd:outreg} includes the sigma
parameter and the equation names in the estimates table.

	{cmd:. generate wgt = weight/100}
	{cmd:. label var wgt "Weight (lbs/100)"}
	{cmd:. tobit mpg wgt, ll(17)}
	{cmd:. outreg using auto, replace }

{pstd}
To limit the table to the coefficient estimates alone, we can use the
option {cmd:keep(model:)}.  The colon after {cmd:model} indicates that
it is an equation name, not a coefficient name, and all estimates in the
{cmd:model} equation are kept.

	{cmd:. outreg using auto, keep(model:) varlabels replace}


{marker xmpl7}{...}
    {title:Example 7: Add statistics not in summstat()}

{pstd}
There are many statistics, particularly test statistics, that we may
want to report in estimation tables but that are not available in the 
{helpb outreg_complete##summstat:summstat()} option.  The statistics available
in {cmd:summstat()} are limited to the {cmd:e()} scalar values that can
be viewed after an estimation command with {cmd:ereturn list}.

{pstd}
The {helpb outreg_complete##addrows:addrows()} option can add additional
rows of text below the coefficient estimates and summary statistics.
This example shows how to display the results of the {helpb test}
command as added rows of the {cmd:outreg} table.

{pstd}
Below we test whether the coefficient on the variable {cmd:foreign} is equal to
the negative of the coefficient on {cmd:goodrep} with
{cmd:test foreign = -goodrep}.  The command {cmd:test} saves the F statistic in
the return value {cmd:r(F)} and its p-value in the return value {cmd:r(p)}.  If
we include {cmd:r(F)} and {cmd:r(p)} in {cmd:addrows()} directly, they are
reported with seven or eight decimal places.  To control the numerical
formatting of the return values {cmd:r(F)} and {cmd:r(p)}, we use the local
macro directive {cmd:display}.  {cmd:local F : display %5.2f `r(F)'} takes the
value in {cmd:r(F)} and puts it in the local macro {cmd:F} displayed with two
decimal places and a width of 5.  Similarly, we request that the local macro
{cmd:p} have three decimal places.

	{cmd}. generate goodrep = rep78==5
	{cmd}. regress mpg weight foreign goodrep
	{cmd}. test foreign = -goodrep
	{cmd}. local F : display %5.2f `r(F)'
	{cmd}. local p : display %4.3f `r(p)'
{txt}
{pstd}
We are now ready to add the test statistics to the {cmd:outreg} table.
The {cmd:addrows()} option below adds two rows, one for the F test and one
for its p-value, and two columns, one for the text in the left column
and one for the test values.  As usual, columns of text are separated
with a comma and rows of text are separated with a backslash.

{phang2}{cmd:. outreg using auto, replace}
        {cmd:addrows("F test: foreign = -goodrep","`F'"\"p value","`p'")}

{pstd}
If we wanted to report the F test statistics above the summary
statistics (R2 and N), then we would need to use the option
{cmd:noautosumm} to suppress the default summary statistics, and instead
include them in the {cmd:addrows()} option below the F test statistics.
The values of R2 and N are available in the scalars {cmd:e(r2)} and
{cmd:e(N)}.


{marker xmpl8}{...}
    {title:Example 8: Multiequation models}

{pstd}
{cmd:outreg} displays estimation results in a single column even for
multiequation models unless you choose the
{helpb outreg_complete##eq_merge:eq_merge} option (for "equation merge").  When
different equations in the estimation model share many of the same
covariates, you may prefer to display the results like the merged
results of separate estimations.  {cmd:eq_merge} puts each equation in a
separate column, and any common variables are displayed in the same row.
Using an example of seemingly unrelated regression estimation with the
three equations each sharing two covariates, {cmd:outreg} organizes the
table with a column for each of the following:
{cmd:price}, {cmd:mpg}, and {cmd:displ}.

{phang2}{cmd:. sureg (price foreign weight length) (mpg displ = foreign weight)}
{p_end}
{phang2}{cmd:. outreg using auto, varlabels eq_merge replace} 
	{cmd:ctitles("",Price Equation,Mileage Equation,Engine Size Equation)}
	{cmd:summstat(r2_1,r2_2,r2_3\N,N,N) summtitles(R2\N)}

{pstd}
Each of the equations in {cmd:sureg} has an R-squared statistic. The
{cmd:summstat()} option places these statistics below the coefficient estimates
along with the number of observations.  The {cmd:summstat()} option has
three columns and two rows.


{marker xmpl9}{...}
    {title:Example 9: Marginal effects and asterisk options}

{pstd}
{cmd:outreg} can display marginal effects estimates calculated by the
{helpb margins} command instead of displaying coefficient estimates.
{cmd:outreg} can also display marginal effects calculated by the {helpb mfx}
and {helpb dprobit} commands that were part of Stata 10 and earlier.
Displaying marginal effects requires that you run {cmd:margins, dydx(*)} or a
similar command after the estimation in question before using {cmd:outreg}.

{pstd}
The simplest way to substitute marginal effects for coefficient
estimates is with the {helpb outreg_complete##marginal:marginal} option.
This replaces the {it:{help outreg_complete## statname:statname}}
{cmd:b_dfdx} for {opt b} and {opt t_abs_dfdx} for {opt t_abs} (or
{cmd:se_dfdx} for {opt se} if the {it:option} {opt se} is in effect).
The asterisks for significance now refer to the marginal effects rather
than to the underlying coefficients.

	{cmd:. logit foreign wgt mpg}
	{cmd:. margins, dydx(*)}
	{cmd:. outreg using auto, marginal replace}

{pstd}
Marginal effects can also be combined with regression coefficients or
other statistics in the {cmd:outreg} table.   The table produced by the
command below displays each coefficient estimate with the marginal effect below
it, and the 95% confidence interval of the marginal effect below that, because
of the {helpb outreg_complete##stats:stats(b b_dfdx ci_dfdx)} option.  Note
that the statistics {opt b_dfdx} and {opt ci_dfdx} refer to whichever marginal
effects were specified in the {helpb margins} command.  This could be
{opt dydx()}, {opt eydx()}, {opt dyex()}, or {cmd:eyex()} depending on the
{cmd:margins} option used.

{pstd}
The {helpb outreg_complete##margstar:margstars} option specifies that the
asterisks refer to the significance of the hypothesis that the marginal effects
are zero rather than the hypothesis that the coefficients are zero.  The
{helpb outreg_complete##starloc:starloc(3)} option places the asterisks next to
the third statistic (the marginal effect confidence intervals) instead of the
default position next to the second statistic.

{phang2}{cmd:. outreg using auto, stat(b b_dfdx ci_dfdx) replace} 
  {cmd:title("Marginal Effects & Confidence Intervals"\"Below Coefficients")}
  {cmd: margstars starloc(3)}


{marker xmpl10}{...}
    {title:Example 10: Multicolumn ctitles(); merge variable means with estimation results}

{pstd}
Empirical papers commonly report summary statistics for the variables used in
estimations.  This example shows how to merge variable means and their
standard errors into an
estimation table, and how to make column titles that span multiple columns.

{pstd}
First, we create an {cmd:outreg} table which merges two simple
regressions, as was done in {help outreg##xmpl3:example 3}.  The
{cmd:nodisplay} option suppresses display of the {cmd:outreg} tables we
are creating, which normally appear in the Stata Results window.  The
{helpb outreg_complete##ctitles:ctitles()} have been specified to have two rows
of column titles, with a supertitle over the first two columns of
{cmd:Regressions}.

{pstd}
Notice that the two {cmd:outreg} commands below do not include a {cmd:using}
statement.  This means that the results are not written as Microsoft Word
files.  Saving the files right now is not necessary because we will merge more
estimation results below and do not need to save the intermediate files.  The
contents of the table are saved in Stata's memory in the meantime.

{phang2}{cmd:. regress mpg foreign weight}{p_end}
{phang2}{cmd:. outreg, bdec(2 5 2) varlabels nodisplay} 
	{cmd:ctitles("","Regressions"\"","Base case")}{p_end}
{phang2}{cmd:. regress mpg foreign weight weightsq}{p_end}
{phang2}{cmd:. outreg, bdec(2 5 2) bfmt(f f e f) varlabels merge}
	{cmd:ctitles("",""\"","Quadratic mpg") nodisplay}{p_end}
{txt}
{pstd}
Then we run the {helpb mean} command, which calculates variable means and
their standard errors.  {cmd:mean} is an estimation command, so it
stores its results in {cmd:e(b)} and {cmd:e(V)}, which can be
displayed and merged using {cmd:outreg}.  We {opt merge} the variable
means to the {cmd:outreg} table already created above.  The
{cmd:ctitles()} in this {cmd:outreg} command have two rows, aligning
them with the previous {opt ctitles()}.  The
{helpb outreg_complete##multicol:multicol(1,2,2)} option causes the cell in the
first row, second column, to span two cells horizontally so that the title
{cmd:Regressions} is centered over both the {cmd:Base case} and
{cmd:Quadratic mpg} columns.  The effect of the {cmd:multicol()} option cannot
be seen in the Stata Results window but does appear in the
Microsoft Word or TeX document created by {cmd:outreg}.  

{pstd}
Note that the {cmd:multicol()}
option must be used in the third and last {cmd:outreg} command, because
it is a formatting characteristic that is not retained from an earlier
{cmd:outreg} table that is merged with a new one.

{phang2}{cmd:. mean mpg foreign weight}{p_end}
{phang2}{cmd:. outreg using auto, bdec(1 3 0) nostar merge replace} 
	{cmd:ctitles("","Means &"\"","Std Errors") multicol(1,2,2)}{p_end}

{pstd}
We could embellish the {cmd:Regressions} supertitle by underlining it.  In
Microsoft Word files, this is accomplished with the formatting code 
{cmd:{\ul Regressions}}.  If we want the underline to span more widely than the
word {cmd:Regressions}, one approach is to place tab characters before and
after the word.  Spaces do not do the job because Microsoft Word does not
underline spaces.  To place one tab character on either side of the supertitle,
we would use {cmd:{\ul\tab Regressions\tab}} in the {opt ctitles()} option.
Another option is to use underscore characters, although the line they create
is offset slightly below the underlining.  See
{it:{help outreg_complete##greek:Inline text formatting}} for more information
about underlining and other within-string formatting issues.

{pstd}
The {helpb mean} command calculates the variable means and their standard
errors.  More typically, summary statistic tables report the
variable means and their standard deviations (which differ from the
standard errors of the mean by a factor of the square root of N).
To report the standard deviations of the variables, I use the as yet
unreleased command {cmd:outstat}, which, because it is also based on the
underlying formatting engine {cmd:frmttable}, can be appended to an
{cmd:outreg} table:

	{cmd:. regress mpg foreign weight}
	{cmd:. outreg}
{phang2}{cmd:. outstat mpg foreign weight using auto, merge replace } 
        {cmd:title(Merge summary statistics with regression results)}
	{cmd:sdec(2\2\4\4\0\0) varlabels basefont(fs10)}{p_end}

{pstd}
The warning message
{err:tables being merged have different numbers of row sections} is displayed
because the differing structure of the {cmd:outreg} table and the {cmd:outstat}
table mean that the {opt merge} process may not align rows the way the user
intended; but in this case, there is no problem.


{marker xmpl11}{...}
    {title:Example 11: Specifying fonts}

{pstd}
One of the objectives of this version of {cmd:outreg} is to have as
complete control as is possible of the layout and appearance of estimates
tables.  An important element of control relates to fonts.
{cmd:outreg} now enables users to specify fonts down to the table cell
level, although this is rarely needed.  You can specify font
sizes, font types (such as Times Roman or Arial), and font styles (such
as bold or italic).  For Microsoft Word files, you can apply any font type
installed on your computer by adding the font name in the
{helpb outreg_complete##addfont:addfont()} option.

{pstd}
In this example, we prepare a table for a presentation as an overhead slide
with special fonts that are displayed much larger than usual.  

{pstd}
Two specialized fonts are added to the document with the
{cmd:addfont(Futura,Didot Bold)} option.  These fonts can then be applied to
different parts of the table as {cmd:fnew1} for the first added font (Futura)
or {cmd:fnew2} for the second added font (Didot Bold).  We set the default font
of the table to be Futura in the {cmd:basefont(fs32 fnew1)} option.  This
{cmd:basefont()} option also sets the font size to 32 points to make the table
fill the whole overhead slide.  The title is assigned the second added font,
Didot Bold, with a 40-point size in {cmd:titlfont(fs40 fnew2)}.  The statistics
in the table are displayed in the Arial font for readability with the
{cmd:statfont(arial)} option.  (Times Roman, Arial, and Courier fonts are
predefined in Microsoft Word and TeX documents and do not need to be included
in {cmd:addfont()}.) The {cmd:basefont()} font characteristics apply to all
parts of the table unless otherwise specified, so the Arial font in
{cmd:statfont()} has a point size of 32.

{pstd}
Font specifications do not change the appearance of the table displayed
in the Stata Results window (only in the Microsoft Word document written to
{cmd:auto.doc}). 

	{cmd:. regress mpg foreign weight}
{phang2}{cmd:. outreg using auto, addfont(Futura,Didot Bold)}
	{cmd:basefont(fs32 fnew1) titlfont(fs40 fnew2) statfont(arial)}
	{cmd:title(New Fonts for Overhead Slides) varlabels replace}


{marker xmpl12}{...}
    {title:Example 12: Superscripts, italics, and Greek characters}

{pstd}
This example uses some of the methods of 
{it:{help outreg_complete##greek:Inline text formatting}} explained above
to apply superscripts, italic text, and Greek characters.  It is helpful
to review those methods to understand the codes used here.

{pstd}
This example is similar to {help outreg_complete##xmpl7:example 7} in
that the results of a test of coefficient equality are displayed in the
estimation table.  However, because the estimation is nonlinear, the
test statistic is a chi-squared rather than an F statistic.  We will
write the chi-squared with the Greek character chi and a superscripted
2 in the Microsoft Word table generated by {cmd:outreg}.  (A different set of
codes can produce the same formatting in TeX files, as discussed in
{it:{help outreg_complete##greek:Inline text formatting}}.)

{pstd}
The Microsoft Word code for the Unicode representation of the Greek lowercase
letter chi is {cmd:\u0966?} (see all Greek letter codes for Microsoft Word
files {help greek_in_word:here}).  The code for chi needs to be placed in
quotes in the {cmd:addrows()} option because otherwise the backslash would be
interpreted as a row divider.  The superscripted 2 is encoded as
{cmd:{\super 2}}.  Note the space between the formatting code ({cmd:\super})
and the regular text ({cmd:2}).  Without it, Microsoft Word would try to
interpret the code {cmd:\super2}, which does not exist.  Finally, we italicize
the p in p-value with {cmd:{\i p}}.  

{pstd}
The full {cmd:addrows()} option becomes 

	{cmd:addrows("\u0966{\super 2} test","`chi2'"\"{\i p} value","`p'")}

{pstd}
As in example 7, {cmd:chi2} and {cmd:p} are the value of local macros containing the
numerically formatted values of the chi-squared statistic and its p-value.

{pstd}
The {cmd:note()} option in the {cmd:outreg} command below has a couple
of tricks to it.  The first is a blank row ({cmd:""}) to separate the
{cmd:note()} text from the legend for asterisks above it.  We also add
Stata system macro values for the current time, date, and dataset filename
from predefined Stata macros {cmd:{c S|}S_TIME}, {cmd:{c S|}S_DATE}, and 
{cmd:{c S|}S_FN}, respectively.

	{cmd:. logit foreign wgt mpg}
	{cmd:. test wgt = mpg}
	{cmd:. local chi2 : display %5.2f `r(chi2)'}
	{cmd:. local p : display %4.3f `r(p)'}
{phang2}{cmd:. outreg using auto, replace}
	{cmd:addrows("\u0966?{\super 2} test","`chi2'"\"{\i p} value","`p'")}
	{cmd:note(""\"Run at $S_TIME, $S_DATE"\"Using data from $S_FN")}


{marker xmpl13}{...}
    {title:Example 13: Place additional tables in same document}

{pstd}
One of the goals for {cmd:outreg} is to create whole documents, such as
statistical appendices, from a Stata do-file.  To do this, you must be
able to write multiple tables to the same document, which is possible
with the {cmd:addtable} option.

{pstd}
The {helpb mean} command below creates summary statistics for the variables.
{cmd:outreg} with the {helpb outreg_complete##addtable:addtable} option places
a summary statistics table below the table just created in
{help outreg_complete##xmpl12:example 12} in the Microsoft Word file
{cmd:auto.doc}.  The option {helpb outreg_complete##nostars:nostars} turns off
asterisks for significance tests, and
{helpb outreg_complete##nosubstat:nosubstat} puts the standard errors side by
side with the means, as explained in {help outreg_complete##xmpl15:example 15}
below.{p_end}

	{cmd:. mean foreign wgt mpg}
{phang2}{cmd:. outreg using auto, addtable ctitle(Variables, Means, Std Errors)}
	{cmd:nostars nosubstat title("Summary Statistics") basefont(fs6)}

{pstd}
You can use the {helpb outreg_complete##pretext:pretext()} and 
{helpb outreg_complete##posttext:posttext()} options to add paragraphs of
regular text before and after each table.


{marker xmpl14}{...}
    {title:Example 14: Place footnotes among coefficients}

{pstd}
Placing footnotes in any of the text elements of an {cmd:outreg} table is
straightforward, such as in {helpb outreg_complete##title:title()}, 
{helpb outreg_complete##ctitles:ctitles()}, 
{helpb outreg_complete##rtitles:rtitles()}, or 
{helpb outreg_complete##note:note()}.  You can place a footnote number 
in the text, using a superscript as in 
{help outreg_complete##xmpl12:example 12} if you want, and place the 
footnote text in the {cmd:note()} or {cmd:posttext()}.

{pstd}
Placing a footnote in the body of the {cmd:outreg} table is not as
straightforward because the table body is made up of numeric statistics.  To
place a footnote in the body of the table, we use the {cmd:annotate()} option.
First, we create a Stata matrix with the footnote locations used by
{cmd:annotate()}, and we put the footnote symbols in the text string of
{cmd:asymbol()}.  It is helpful to review the entry for the
{helpb outreg_complete##annotate:annotate()} option for details.

{pstd}
Below we place superscripted footnotes in a regression table.  The first
footnote is added to the label of the variable {cmd:foreign}, which is
used by {cmd:outreg} because of the {opt varlabels} option.  

{pstd}
The next
two footnotes are placed among the regression statistics.  For this, we
create a Stata matrix with the {cmd:matrix annotmat = J(3,2,0)} command.
This creates a 3 x 2 matrix of zeros.  The matrix should have the
dimension of the number of coefficients (3, including the constant) by
the number of statistics (by default, 2: {cmd:b} and {cmd:t_abs}).  All
elements of the matrix {cmd:annotmat} which are zero are ignored.  The
locations with a {cmd:1} have the first {cmd:asymbol()} appended, {cmd:2} have
the second {cmd:asymbol()}, etc.  Because we want to place a footnote
next to the first t statistic, we place a 1 at position (1,2) of
{cmd:annotmat} for the first coefficient, second statistic of the table.
We want another footnote next to the third coefficient estimate, so we
place a 2 at position (3,1) of {cmd:annotmat}.  The 1 and 2 in
{cmd:annotmat} correspond to the first and second strings in
{cmd:asymbol()}, which are {cmd:{\super 2}} and {cmd:{\super 3}} because
these should be footnote numbers 2 and 3.

{pstd} 
The final footnote, footnote 4, is placed in the text labeling the summary
statistic N by using the {cmd:summtitles("{\i N}{\super 4}")} option, which
gives us an italicized N and a superscripted 4.

{pstd}
It is not possible to position a footnote next to the summary statistic
in {cmd:summstat()}.  To accomplish this, you must turn off
the automatic summary statistics with {opt noautosumm} (which
{cmd:summstat()} does by default), and place the statistic and the
footnote symbol in {cmd:addrows()}, which was described in 
{help outreg_complete##xmpl7:example 7} and 
{help outreg_complete##xmpl12:example 12}.

{pstd}
The footnote text is added below the table in the {cmd:note()} option,
with superscripts for the footnote numbers.

	{cmd:. regress mpg foreign weight}
	{cmd:. label var foreign "Car Type{\super 1}"}
	{cmd:. matrix annotmat = J(3,2,0)}
	{cmd:. matrix annotmat[1,2] = 1}
	{cmd:. matrix annotmat[3,1] = 2}
{phang2}{cmd:. outreg using auto, varlabels replace colwidth(10 10)} 
	{cmd:annotate(annotmat) asymbol("{\super 2}","{\super 3}")} 
	{cmd:basefont(fs10) summstat(N) summtitles("{\i N}{\super 4}")} 
	{cmd:note("{\super 1}First footnote."\}
	{cmd:"{\super 2}Second footnote."\}
	{cmd:"{\super 3}Third footnote."\}
	{cmd:"{\super 4}Fourth footnote.")}


{marker xmpl15}{...}
    {title:Example 15: Show statistics side by side, like Stata estimation results}

{pstd}
To show statistics side by side, such as t statistics next to the
coefficients rather than below them, use the {opt nosubstat} option.
The following example creates a table similar to Stata's display of
regression results, reporting six statistics using the {opt stats()}
option.  Asterisks for significance have been turned off with the
{cmd:nostars} option.

{phang2}{cmd:. outreg using auto, nosubstat stats(b se t p ci_l ci_u) nostar}
	{cmd:ctitles("mpg", "Coef.","Std. Err.","t","P>|t|","[95% Conf.",}
	{cmd:"Interval]") bdec(7) replace} 
	{cmd:title("Horizontal Output like Stata's -estimates post-")}


{marker xmpl16}{...}
    {title:Example 16: Merge multiple estimation results in a loop}

{pstd}
If you want to run the same estimation on different datasets or on
different groups within a dataset, it is often efficient to create a
loop using the {helpb forvalues} or {helpb foreach} command.  This
example first shows how to merge the results of each estimation in the loop
into a single {cmd:outreg} table, and second shows how to merge sequential
estimations in a loop into two separate tables.

{pstd}
Say we want to run separate regressions by groups that are indexed by
the categorical variable {cmd:rep78} in the {cmd:auto.dta} dataset.  We
use the {cmd:forvalues} command to create a loop that steps through the
values of {cmd:rep78} from 2 to 5.  For each value of {cmd:rep78}, we
run a regression of the variable {cmd:mpg} on covariates, restricting
the sample to the current value of {cmd:rep78} with the statement
{cmd:if rep78==`r'}.  ({cmd:r} is a local macro containing the current
value of the loop indicator.)

{pstd}
Following each regression, the {cmd:outreg, merge} command merges
successive regression results into a single table.  The first time that
{cmd:outreg, merge} is executed after the first regression, we actually
do not want it to merge with anything.  The {opt merge} option allows
merging without an existing table precisely to enable its use in loops,
although {cmd:outreg} does produce the warning message that no
existing {cmd:outreg} table was found.

{pstd}
To ensure that there is no preexisting table before the first
{cmd:outreg, merge} command, we precede the {cmd: forvalues} loop with
the command {cmd:outreg, clear}.  The {opt clear} option removes any
{cmd:outreg} table in memory; {cmd:outreg} tables persist until
cleared or replaced by a new table.  Even if no previous {cmd:outreg}
command has been run, if the commands in this example are rerun, the
{cmd:outreg, clear} command is necessary to clear out the previous
version of the table.

	{cmd}. outreg, clear
	{cmd}. forvalues r = 2/5 {
	  2.   quietly regress mpg price weight if rep78==`r'
	  3.   outreg, merge varlabels ctitle("","`r'") nodisplay
	  4. }{txt}

{pstd}
The {cmd:outreg} command in the loop does not need any {opt using} statement
because we do not need to save the table as a Microsoft Word document (or TeX
document) until we have merged all the regressions together.  Once we have, and
the loop is complete, we save the table as a Microsoft Word document with the
{cmd:outreg using auto, replay} command.

{phang2}{cmd:. outreg using auto, replay replace}
        {cmd:title(Regressions by Repair Record)}

{pstd}
The {cmd:replay} option tells {cmd:outreg} to use the existing
{cmd:outreg} table in memory instead of creating a new one.  If we had
left out the {cmd:replay} option, we would have created a new table from
the existing {cmd:e(b)} matrix, which holds just the results of the last
regression in the loop.  With
the {cmd:replay} option, it is possible to make 
{help outreg_complete##text_add_opts:text additions} (except for 
{helpb outreg_complete##varlabels:varlabels}) such as new titles or even
{helpb outreg_complete##addrows:addrows()}, but it is not possible to
change the numerical contents or numerical formatting of the statistics
in the table (options for 
{help outreg_complete##est_opts:estimate selection}, 
{help outreg_complete##est_for_opts:estimates formatting},
{help outreg_complete##stars_opts:asterisks}, 
{help outreg_complete##brack_opts:brackets}, and 
{help outreg_complete##summstat_opts:summary statistics} will be
ignored).  When using the {cmd:replay} option, it is possible to
specify all the text formatting options (such as 
{help outreg_complete##font_opts:fonts}, 
{help outreg_complete##lines_spaces_opts:lines, and spacing}) and the relevant
{help outreg_complete##file_opts:file options} (such as 
{helpb outreg_complete##replace:replace} or 
{helpb outreg_complete##tex:tex}).

{pstd}
Because the {cmd:outreg} command in the loop above used the {opt merge}
option, no legend was created at the bottom of the table for the
asterisks.  This can be rectified with the option 
{cmd:note(* p<0.05; ** p<0.01)} in the {cmd: outreg, replay} command.

{pstd}
There are some contexts in which it is helpful to merge the estimation
results in a loop into two separate {cmd:outreg} tables, such as when
for each iteration of the loop, the results of the first estimation are
used in the second estimation, and we want to record the results of both
estimations.  In this example, we run instrumental-variables estimation
in a loop, and we record both the first- and second-stage regressions.  To
merge the regression results into two separate tables, we need to give
the tables separate names.  Each time the {opt merge} option is used, it
will refer to either the "first" table (for the first-stage regression
results) or the "iv" table (for the second-stage results).  These
table-specific {cmd:merge} options become {cmd:merge(first)} and
{cmd:merge(iv)}.

{pstd}
As before, we precede the {cmd:forvalues} loop with {cmd:outreg, clear} to
clear out any {cmd:outreg} table in memory. In this case, though, we need to
refer to the named tables, so we have two commands: {cmd:outreg, clear(first)}
and {cmd:outreg, clear(iv)}.  The built-in Stata command for
instrumental-variables estimation, {helpb ivregress}, does not have the
capability of saving the first-stage results (although they can be displayed).
Instead we use the excellent user-written command {search ivreg2}, which saves
the first-stage results with the {cmd:savefirst} option.  The {cmd:ivreg2}
command is preceded by the {helpb quietly} command to suppress the display of
its output.  We then add the instrumental-variables estimates to the "iv"
table with the {cmd:outreg, merge(iv)} command.  The
{cmd:estimates restore _ivreg2_hsngval} command puts the first-stage estimates
into the {cmd:e(b)} and {cmd:e(V)} vectors.  The second {cmd:outreg} command,
{cmd:outreg, merge(first)}, saves the first-stage regression results in the
"first" table.

	{cmd:. webuse hsng2, clear}
	{cmd:. outreg, clear(iv)}
	{cmd:. outreg, clear(first)}
	{cmd:. forvalues r = 1/4 {c -(}}
	{txt}  2{cmd:.   quietly ivreg2 rent pcturban (hsngval = faminc) ///}
                    {cmd:if reg`r', savefirst}
	{txt}  3{cmd:.   outreg, merge(iv) varlabels ctitle("","Region `r'") ///}
                    {cmd:nodisplay}
	{txt}  4{cmd:.   quietly estimates restore _ivreg2_hsngval}
	{txt}  5{cmd:.   outreg, merge(first) varlabels ctitle("","Region `r'") ///}
                     {cmd:nodisplay}
	{txt}  6{cmd:. {c )-}}

{pstd}
We now save the two tables with two {cmd:outreg, replay} commands.  To
replay the table of first-stage estimates, we use the
{cmd:replay(first)} option; to replay the second-stage estimates, we use the
{cmd:replay(iv)} option.  By using the {cmd:addtable} option in the
second {cmd:outreg, replay} command (and {cmd:using} the same filename),
we combine both tables into the file {cmd:iv.doc}.

{phang2}{cmd:. outreg using iv, replay(first) replace}
	{cmd:title(First Stage Regressions by Region)}{p_end}
{phang2}{cmd:. outreg using iv, replay(iv) addtable}
	{cmd:title(Instrumental Variables Regression by Region)}


{title:Author}

{pstd}John Luke Gallup{p_end}
{pstd}Portland State University{p_end}
{pstd}Portland, OR{p_end}
{pstd}jlgallup@pdx.edu{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 12, number 4: {browse "http://www.stata-journal.com/article.html?article=sg97_5":sg97_5},{break}
                    {it:Stata Journal}, volume 12, number 1: {browse "http://www.stata-journal.com/article.html?article=sg97_4":sg97_4},{break}
                    {it:Stata Technical Bulletin} 59: {browse "http://www.stata.com/products/stb/journals/stb59.pdf":sg97.3},{break}
                    {it:Stata Technical Bulletin} 58: {browse "http://www.stata.com/products/stb/journals/stb58.pdf":sg97.2},{break}
                    {it:Stata Technical Bulletin} 49: {browse "http://www.stata.com/products/stb/journals/stb49.pdf":sg97.1},{break}
                    {it:Stata Technical Bulletin} 46: {browse "http://www.stata.com/products/stb/journals/stb46.pdf":sg97}

{p 7 14 2}Help:  {help outreg:{bf:outreg} (basic)}{p_end}
