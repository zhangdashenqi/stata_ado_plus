{smcl}
{* *! version 4.02 23sep2011}{...}
{cmd:help outreg (basic options)}{right: ({browse "http://www.stata-journal.com/article.html?article=sg97_5":SJ12-4: sg97_5})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:outreg} {hline 2}}Reformat and write regression tables to a document file{p_end}
{p2colreset}{...}

{pstd}
This is a simplified help file for {hi:outreg} with a subset of options
for a typical regression table.  For complete {cmd:outreg}
documentation, see {help outreg_complete:{bf:outreg} (complete)}.{p_end}

{pstd}
For an explanation of the major changes to {cmd:outreg} since the last
version, see {help outreg_update:{bf:outreg} (updates)}.


{title:Syntax}

{p 8 17 2}
{cmd:outreg}
[{opt using} {it:filename}]
[{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:{help outreg##basic_options:Basic options}}
{synopt:{opt se}}standard errors, not t statistics, below coefficients{p_end}
{synopt:{opt bd:ec(numlist)}}decimal places for estimates b; default is {cmd:bdec(3)}{p_end}
{synopt:{opt summs:tat(e_values)}}place additional summary statistics below coefficient estimates{p_end}
{synopt:{opt starlev:els(numlist)}}specify significance levels for asterisks{p_end}
{synopt:{opt e:q_merge}}create separate columns for each equation after a multiequation estimation{p_end}
{synopt:{opt va:rlabels}}use variable labels as row headings{p_end}
{synopt:{opt t:itle(textcolumn)}}put title above table{p_end}
{synopt:{opt ct:itles(textgrid)}}specify column headings{p_end}
{synopt:{opt rt:itles(textgrid)}}specify row headings{p_end}
{synopt:{opt n:ote(textcolumn)}}put note below table{p_end}
{synopt:{opt sq:uarebrack}}use square brackets instead of parentheses{p_end}
{synopt:{opt tex}}write TeX file instead of default Microsoft Word file{p_end}
{synopt:{opt m:erge}}merge table with a previous table{p_end}
{synopt:{opt replace}}overwrite existing file{p_end}
{synoptline}
{p2colreset}{...}
{marker textcolumn}{marker textrow}{marker textgrid}{...}
{phang}where the syntax of{p_end}
{phang2}
{it:textcolumn} is  "{it:string}" [\"{it:string}"...]{p_end}
{phang2}
{it:textrow} is  "{it:string}" [,"{it:string}"...]{p_end}
{phang2}
{it:textgrid} is  "{it:string}" [,"{it:string}"...] [\ "{it:string}"[,"{it:string}"...] [\ [...]]] or a {it:textrow} or a {it:textcolumn} as a special case{p_end}

{phang2}
"{it:string}" ["{it:string}" ...] will often work in place of a
{it:textrow} or a {it:textcolumn} when the user's intent is clear, but
if in doubt use the proper {it:textrow} or {it:textcolumn} syntax
above.{p_end}

{pstd}
There are many other options available; see 
{help outreg_complete:{bf:outreg} (complete)}.


{title:Description}

{pstd}
{cmd:outreg} formats the results of Stata estimation commands in tables
in the same way they are typically presented in journal articles, rather
than the way they are presented in the Stata Results window.  By
default, t statistics appear in parentheses below the coefficient
estimates with asterisks for significance levels, with the number of
observations and R-squared (no pseudo-R-squared) below all the
estimates.  {cmd:outreg} automates the process of converting estimation
results to standard tables by creating a Microsoft Word or TeX document
containing a formatted table.  Almost every aspect of the table's
structure and formatting (including fonts) can be specified with
options.

{pstd}
{cmd:outreg} works after any estimation command in Stata (see
{help estimation commands} for a complete list).  Like {helpb predict},
{cmd:outreg} uses internally saved estimation results, so it should be
invoked after the estimation.

{pstd}
The table created by {cmd:outreg} is displayed in the Results window,
minus the fancy font specifications, unless the 
{helpb outreg_complete##nodisplay:nodisplay} option is used.  If
{cmd:using} {it:filename} is specified, {cmd:outreg} creates a Microsoft
Word file by default or creates a TeX file with the
{helpb outreg##tex:tex} option.

{pstd}
Successive estimation results, which may use different variables, can be
combined by {cmd:outreg} into a single table with the variable
coefficients lined up properly by using the {helpb outreg##merge:merge}
option.  (In previous versions of {cmd:outreg}, the {cmd:merge} option
was called {cmd:append}.)


{marker basic_options}{...}
{title:Options}

{dlgtab:Basic}

{marker se}{...}
{phang}
{opt se} specifies that standard errors rather than t statistics be
reported in parentheses below the coefficient estimates.  The decimal
places displayed are those set by {cmd:bdec()}.

{marker bdec}{...}
{phang}
{opt bdec(numlist)} specifies the number of decimal places reported for
coefficient estimates (the b's).  It also specifies the decimal places
reported for standard errors if the {cmd:se} option is specified.  The
default is {cmd:bdec(3)}.  The minimum value is 0 and the maximum value
is 15.  If one number is specified in {cmd:bdec()}, it will apply to all
coefficients.  If multiple numbers are specified in {cmd:bdec()}, the
first number will determine the decimal places reported for the first
coefficient, the second number will determine the decimal places
reported for the second coefficient, etc.  If there are fewer numbers in
{cmd:bdec()} than there are coefficients, the last number in
{cmd:bdec()} will apply to all the remaining coefficients.

{marker tdec}{...}
{phang}
{opt summstat(e_values)} places additional summary statistics below the
coefficient estimates.  {it:e_values} is a grid of the names of
different {cmd:e()} return values already calculated by the estimation
command.  The syntax of {it:e_values} is the same as the other grids
used in {cmd:outreg}, like the {it:{help outreg##textcolumn:textgrid}}.
Elements within a row are separated with commas ({cmd:,}), and rows are
separated by backslashes ({cmd:\}).  The default is {cmd:summstat(r2\N)}
(when {cmd:e(r2)} is defined), which places the R-squared statistic
{cmd:e(r2)} below the coefficient estimates and the number of
observations {cmd:e(N)} below that.

{pmore}
To replace the R-squared with the adjusted R-squared stored in
{cmd:e(r2_a)}, you can use the options {cmd:summstat(r2_a\N)} and
{cmd:summtitle("Adjusted R2"\"N")}.  You can also specify the decimal
places for the summary statistics with the 
{helpb outreg_complete##summdec:summdec()} option.  To see a complete
list of the {cmd:e()} macro values available after each estimation
command, type {helpb ereturn list}.

{pmore}
Statistics not included in the {cmd:e()} return values can be added to
the table with the {helpb outreg_complete##addrows:addrows()} option.

{marker starlevels}{...}
{phang}
{opt starlevels(numlist)} indicates significance levels in percentages
for asterisks.  By default, one asterisk is placed next to coefficients
that pass the test for significant difference from zero at the 5% level,
and two asterisks are placed next to coefficients that pass the test for
significance at the 1% level; this is equivalent to 
{cmd:starlevels(5 1)}.  To place one asterisk for the 10% level, two for
the 5% level, and three for the 1% level, you would specify
{cmd:starlevels(10 5 1)}.  To place one asterisk for the 5% level, two
for the 1% level, and three for the 0.1% level, you would specify
{cmd:starlevels(5 1 .1)}.

{marker summdec}{...}
{phang}
{opt eq_merge} creates separate columns for each equation after a
multiequation estimation.  The entries in each column are merged
according to the variable names, similarly to the 
{helpb outreg#merge:merge} option for combining separate estimation
results.  This option is useful after estimation commands like 
{helpb reg3}, {helpb sureg}, {helpb mlogit}, {helpb mprobit}, etc.,
where many of the same variables occur in different equations.

{phang}
{opt varlabels} causes {cmd:outreg} to use variable labels (rather than
variable names) as row titles for each coefficient.  See {cmd:rtitles()}
below to specify row titles manually.

{marker title}{...}
{phang}
{cmd:title(}{it:{help outreg##textcolumn:textcolumn}}{cmd:)} specifies a
title or titles above the regression table.  Subtitles should be
separated from the primary titles by backslashes (\), like this:
{cmd:title("Main title"\"First subtitle"\"Second subtitle")}.  By
default, titles are set in a larger font than the body of the table.

{marker ctitles}{...}
{phang} 
{cmd:ctitles(}{it:{help outreg##textgrid:textgrid}}{cmd:)} specifies the
column titles above the estimates.  By default, if no {cmd:ctitles()}
are specified, the name of the dependent variable is displayed.  A
simple form of {cmd:ctitles()} is, for example,
{cmd:ctitles("Variables","First Regression")}.  Note that the first
title in {cmd:ctitles()} goes above the variable name column and the
second title goes above the estimates column.  If you want no heading
above the variable name column, specify, for example,
{cmd:ctitles("","First Regression")}.  Fancier titles in {cmd:ctitles()}
can have multiple rows.  See {helpb outreg_complete##ctitles:ctitles()}
in {help outreg_complete:{bf:outreg} (complete)} for details.

{marker rtitles}{...}
{phang}
{cmd:rtitles(}{it:{help outreg##textgrid:textgrid}}{cmd:)} replaces the
leftmost column of the table with new row titles for the coefficient
estimates.  By default (with no {cmd:rtitles()} option), the row titles
are variable names.  Multiple titles in {cmd:rtitles()} should be
separated by a backslash (\) because they are placed below one another
(if the titles are separated with commas, they will all be placed in the
first row of the estimates).  An example of {cmd:rtitles()} is
{cmd:rtitles("Variable 1"\""\"Variable 2"\""\"Constant")}.  The empty
titles "" are to account for the rows of t statistics below the
coefficients.

{marker note}{...}
{phang}
{cmd:note(}{it:{help outreg##textcolumn:textcolumn}}{cmd:)} specifies a
note to be displayed below the {cmd:outreg} table.  Multiple lines of a
note should be separated by backslashes (\), like this:
{cmd:note("First note line."\"Second note line."\"Third note line.")}.
Notes are centered immediately below the table.  By default, they are
set in a smaller font than the body of the table.

{marker squarebrack}{...}
{phang}
{opt squarebrack} substitutes square brackets for parentheses around the
statistics placed below the first statistic.  This means that square
brackets, rather than parentheses, are placed around t statistics below
the coefficient estimates (when using the default statistics).  See
{helpb outreg_complete##brackets:brackets()} in
{help outreg_complete:{bf:outreg} (complete)} for more complete control of
bracket symbols around statistics.

{marker tex}{...}
{phang}
{opt tex} specifies that {cmd:outreg} write a TeX output file rather
than a Microsoft Word file.  The output is suitable for including in a
TeX document (see the {helpb outreg_complete##fragment:fragment} option
{help outreg_complete:{bf:outreg} (complete)})
or loading into a TeX typesetting program such as Scientific Word.

{marker merge}{...}
{phang}
{opt merge} specifies that new estimation output be merged with an
existing table.  The coefficient estimates are lined up, matching the
text in the left-most columns by the appropriate variable name or 
{helpb outreg##rtitles:rtitles()} with the coefficients for new
variables placed below the original variables but above the constant
term.  Note that in previous versions of {cmd:outreg}, the {cmd:merge}
option was called {cmd:append}.  Users will usually want to specify
{helpb outreg##ctitles:ctitles()} when using {cmd:merge}.

{marker replace}{...}
{phang}
{opt replace} specifies that it is okay to overwrite an existing file.


{title:Remarks}

{pstd}
For information on many other options, see 
{help outreg_complete:{bf:outreg} (complete)}.


{marker examples}{...}
{title:Examples}

{pstd}{help outreg##xmpl1:Example 1: Basic usage and variable labels}{p_end}
{pstd}{help outreg##xmpl2:Example 2: Decimal places for coefficients and titles}{p_end}
{pstd}{help outreg##xmpl3:Example 3: Merging estimation tables together}{p_end}
{pstd}{help outreg##xmpl4:Example 4: Standard errors, brackets, and no asterisks in a TeX file}{p_end}
{pstd}{help outreg##xmpl5:Example 5: 10% significance level and summary statistics}{p_end}


{marker xmpl1}{...}
    {title:Example 1: Basic usage and variable labels}

{pstd}
{cmd:outreg} is used after an estimation command because it needs the
saved estimation results to construct a formatted table.  Consider a
regression using Stata's {cmd:auto.dta} dataset:

{phang2}{cmd:. sysuse auto}{p_end}
{phang2}{cmd:. regress mpg foreign weight}{p_end}

{pstd}
The simplest form of {cmd:outreg} displays a reformatted estimation
table in the Stata Results window.

{phang2}{cmd:. outreg}

{pstd}
If you use the {cmd:outreg using auto} command, it will create a new
Microsoft Word file named auto.doc and it will display the table in the
Results window (a feature that can be turned off with the
{helpb outreg_complete##nodisplay:nodisplay} option).  {cmd:outreg} can
also create tables in TeX format with the {helpb outreg##tex:tex}
option.

{pstd}
The option {cmd:varlabels} replaces variable names with their labels; in
our example, the independent variable {cmd:mpg} listed above the column
of regression coefficients uses the label {cmd:Mileage (mpg)}, the
variable foreign uses its label {cmd:Car type}, etc.  You can customize
the variable labels before invoking {cmd:outreg} to provide the desired
captions in the {cmd:outreg} table.  Alternatively, you can specify
column and row titles directly with the 
{helpb outreg##ctitles:ctitles()} and {helpb outreg##rtitles:rtitles()}
options.

{pstd}
If the file {cmd:auto.doc} already exists from a previous {cmd:outreg}
command, then we must also include the {cmd:replace} option.

{phang2}{cmd:. outreg using auto, varlabels replace}


{marker xmpl2}{...}
    {title:Example 2: Decimal places for coefficients and titles} 

{pstd}
The regression table in the previous example would be improved by
formatting the coefficient values and adding informative titles.  By
default, the regression coefficients are shown with three decimal places
in {cmd:outreg} tables, but this is not very satisfactory for the
{hi:weight} variable in the regression above.  The {cmd:weight}
coefficient is statistically significant, but only one nonzero digit is
displayed.  We could use the option {cmd:bdec(5)} to display five
decimal places for all the coefficients, but we can do even better.  To
display five decimal places of the {cmd:weight} coefficient only and two
decimal places of the other coefficients, we use {cmd:bdec(2 5 2)}.

{pstd}We can add a title to the table with the {cmd:title()} option.  As
long as the title text contains no backslashes (which indicate multiple
lines of title) or commas, no quotation marks are required.  So we add
the option {cmd:title(What cars have low mileage?)}.  We also change the
column heading of the estimates from the name of the independent
variable to {cmd:Base case} with the option {cmd:ctitles("",Base case)}.
We need the {cmd:""} to indicate that there is no title heading in the
left-most column of the table.  We can get away with no quotes around
{cmd:Base case} because it contains no backslahes or commas, which are
interpreted by {cmd:ctitles()} as column and row delimiters.

{phang2}{cmd:. outreg using auto, bdec(2 5 2) replace}
           {cmd:title(What cars have low mileage?) ctitles("",Base case)}

{pstd}
If you run the commands above and open the resulting file,
{cmd:auto.doc}, in Microsoft Word or most other word-processing
softwares, you can see the formatted table created by {cmd:outreg}.


{marker xmpl3}{...}
    {title:Example 3: Merging estimation tables together}

{pstd}
Users often want to include several related estimations in the same
table.  {cmd:outreg} can combine multiple estimation results with the
{cmd:merge} option.

{pstd}
We create new variable {cmd:weightsq} for the second regression.

{phang2}{cmd:. generate weightsq = weight^2}{p_end}
{phang2}{cmd:. label var weightsq "Weight squared"}{p_end}

{pstd}
Then we run the second regression with the quadratic {cmd:weightsq}
term.

{phang2}{cmd:. regress mpg foreign weight weightsq}

{pstd}
We add the second regression results to the regression table in example
2 above by using the {cmd:merge} option.  In the second regression, the
{cmd:weightsq} term is statistically significant but very small because
of the small units used for {cmd:weight} (pounds).  We can avoid
displaying a large number of decimal places by formatting the
{cmd:weightsq} coefficient in scientific notation with the option 
{helpb outreg_complete##bfmt:bfmt(f f e f)}.  We also specify the number
of decimal places for each coefficient as we did in the first
regression.  We add an informative column title with the options
{cmd:bdec(2 5 2)} and {cmd:ctitles("",Quadratic mpg)}.  Note that
although there are four coefficients (counting the constant), there are
only three numbers in {cmd:bdec(2 5 2)}.  The last number in
{cmd:bdec()} applies to all the remaining coefficients.

{phang2}{cmd:. outreg using auto, bdec(2 5 2) bfmt(f f e f)}
          {cmd:ctitles("",Quadratic mpg) varlabels merge replace}

{pstd}
The coefficients and t statistics for the variables are aligned
correctly in the merged table, and the scientific notation is applied to
the {cmd:weightsq} variable.

{pstd}
Because the first {cmd:outreg} table from example 2 used 
{cmd:varlabels}, we need to use {cmd:varlabels} in the {cmd:outreg}
command that merges the second regression.  If we did not, the row
titles would differ between the original table and the new results being
merged, causing the coefficients to be aligned incorrectly.  For
example, the label for the first coefficient in the original table is
{cmd:Car type}.  Without the {cmd:varlabels} option in the {cmd:outreg}
command above, the first coefficient of the second regression would be
labeled {cmd:foreign} and would be treated as new variable instead of
being aligned in the first row with {cmd:Car type}.


{marker xmpl4}{...}
    {title:Example 4: Standard errors, brackets, and no asterisks in a TeX file}

{pstd} Economics journals often prefer standard errors to t statistics
and do not use asterisks to denote statistical significance.  The
{cmd:se} option replaces t statistics with standard errors, and the
{cmd:nostar} option suppresses asterisks.  We will also replace the
parentheses around the standard errors with square brackets by using the
{cmd:squarebrack} option, and we will save the document as a TeX file
with the {cmd:tex} option.  Note that the decimal places specified by
the {cmd:bdec()} option apply to both the coefficients and the standard
errors.

{phang2}{cmd:. regress mpg foreign weight}{p_end}
{phang2}{cmd:. outreg using auto, se bdec(2 5 2) squarebrack nostars replace}
        {cmd:tex varlabels title(No t statistics, please - we're economists)}


{marker xmpl5}{...}
   {title:Example 5: 10% significance level and summary statistics}

{pstd}
The cutoff levels for asterisks indicating statistical significance can
be modified with the {helpb outreg##starlevels:starlevels()} option.
The default levels are one asterisk for 5% significance and two
asterisks for 1% significance (that is, {cmd:starlevels(5 1)}).  To add
a symbol for 10% significance, we use the {cmd:starlevels(10 5 1)}
option; this would display one asterisk for 10%, two for 5%, and three
for 1%.  To retain the original number of asterisks for 5% and 1% levels
but add a cross symbol for the 10% level, we can use the option 
{helpb outreg_complete##sigsymbols:sigsymbols(+,*,**)}, with the symbols
corresponding to the significance levels in {cmd:starlevels()}.  The
legend at the bottom of the table is modified to reflect these options.

{pstd}
The default summary statistics are the R-squared (if it's defined) and
the number of observations.  Instead, we display the F statistic and the
adjusted R-squared by using the {helpb outreg##summstat:summstat()}
option.  The symbols used for these statistics in the estimates return
values are {cmd:F} and {cmd:r2_a}.  All available return values after an
estimation can be seen with the command {helpb ereturn list}.  The
{cmd:summstat(F\r2_a)} option is specified with a backslash separating
the statistics because we want them to be on different rows in the same
column (if we used a comma to separate the values, they would be on the
same row in different columns, making the table one column wider).  We
also specify the names of the statistics in 
{cmd:summtitles(F statistic\Adjusted R-squared)}, similarly to
{helpb outreg##rtitles:rtitles()}.  To give the F statistic one decimal
place and the adjusted R-squared two decimal places, we use the
{cmd:summdec(1 2)} option.

{phang2}{cmd:. regress mpg foreign weight turn}{p_end}
{phang2}{cmd:. outreg using auto, bdec(2 5 3 2) varlabels replace} 
        {cmd:starlevels(10 5 1) sigsymbols(+,*,**) summstat(F\r2_a)}
        {cmd:summtitle(F statistic\Adjusted R-squared) summdec(1 2)}

{pstd}
For additional examples of the use of {cmd:outreg}, see the 
{help outreg_complete##examples:examples} in the 
{help outreg_complete:{bf:outreg} (complete)} documentation.


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

{p 7 14 2}Help:  {help outreg_complete:{bf:outreg} (complete)}
{p_end}
