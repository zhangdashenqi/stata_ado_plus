{smcl}
{* *! version 1.0 11jun2012}{...}
{cmd:help htopen}, {cmd:help htclose}, {cmd:help htput},{right: ({browse "http://www.stata-journal.com/article.html?article=dm0066":SJ12-4: dm0066})}
{cmd:help htlog}, {cmd:help htlist}, {cmd:help htsummary}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:htopen} {hline 2}}Utilities for writing files in Hypertext Markup Language{p_end}
{p2colreset}{...}


{title:Syntax}

{pstd}Open a Hypertext Markup Language (HTML) file

{p 8 14 2}
{cmd:htopen} {cmd:using} {it:{help filename}} [{cmd:,} {cmd:replace append notag}]

{pstd}Close an HTML file in use

{p 8 15 2}
{cmd:htclose} [{cmd:, notag}]

{pstd}Send expression to the HTML file

{p 8 13 2}
{cmd:htput} {it:expression}

{pstd}Send log to the HTML file

{p 8 13 2}
{cmd:htlog} {it:stata_cmd}

{pstd}List the values of variables in HTML format

{p 8 14 2}
{cmd:htlist} [{it:{help varlist}}] {ifin} [{cmd:,} {cmdab:d:isplay}
{cmdab:nod:isplay} {cmdab:nol:abel}
{cmdab:noo:bs} {cmdab:nov:arlab} {cmdab:va:rname}
{cmdab:t:able(}{it:string}{cmd:)} {cmdab:a:lign(}{it:string}{cmd:)}]

{pstd}Make a row-table of summary statistics in HTML format

{p 8 17 2}
{cmd:htsummary} {it:{help varname:varname1}} [{it:{help varname:varname2}}]
{ifin} [{cmd:,} {cmdab:h:ead} {cmdab:cl:ose} {cmdab:not:otal} {cmdab:fr:eq} {cmdab:r:ow} {cmdab:rowt:otal}
{cmdab:l:og} {cmdab:f:ormat(}{it:string}{cmd:)} {cmdab:med:ian} {cmdab:a:dd(}{it:#}{cmd:)} {cmdab:re:code(}{it:rule}{cmd:)} {cmdab:a:nova} {cmdab:k:w} {cmd:chi} {cmd:exact} {cmd:test}
{cmdab:p:val(}{it:real}{cmd:)} {cmdab:me:thod(}{it:string}{cmd:)} {cmdab:mi:ssing} {cmdab:c:olor(}{it:real}{cmd:)}]


{title:Description}

{pstd}The {cmd:ht} package is a set of commands designed to produce HTML
files from Stata. These HTML files might contain text, HTML tags,
tables, standard output from Stata, and linked objects.  The files can
then be opened by any web browser.  Stata graphics can be included as
linked objects after you export them to an image format (for example,
the {cmd:.png} format) by using the command 
{helpb graph_export:graph export}.

{pstd}{cmd:htopen} defines a file for HTML output.  By default, it adds
the {cmd:.html} extension to the {it:filename} and adds the tags to
define an HTML 4.0 document.

{pstd}{cmd:htclose} closes the HTML file.

{pstd}{cmd:htput} prints the expression in the HTML output.  It requires
the HTML output to be set up with {cmd:htopen}.  No quotes are required
around text values, and macro substitution is allowed.

{pstd}{cmd:htlog} prints the output of the Stata command to the HTML
file.  It requires the HTML output to be set up with {cmd:htopen}.

{pstd}{cmd:htlist} displays the values of variables in the HTML file.
If {it:varlist} is not specified, the values of all the variables are
displayed.  It requires the HTML output to be set up with {cmd:htopen}.

{pstd}{cmd:htsummary} makes a row-table of summary statistics in HTML
format for {it:varname1}.  It requires the HTML output to be set up with
{cmd:htopen}.  Columns for the table can be specified by {it:varname2}.
By default, mean and standard deviation are reported.  Use options to
choose appropriate summary statistics.


{title:Options for htopen}

{phang}{cmd:replace} specifies that {it:filename} be overwritten if it
already exists.  If neither {cmd:replace} nor {cmd:append} is specified,
the file is assumed to be new; if the specified file already exists, an
error message is issued, and HTML output is not started.

{phang}{cmd:append} specifies that results be appended to an existing
file.  If the file does not already exist, a new file is created.

{phang}{cmd:notag} omits the header tags ({cmd:<!DOCTYPE ...>} and
{cmd:<HTML>}).


{title:Option for htclose}

{phang}{opt notag} omits the HTML tag to close the document
({cmd:</HTML>}).


{title:Options for htlist}

{phang}{opt display} or {opt nodisplay} determines the style of output.
By default, {cmd:htlist} determines whether to use a table
({cmd:nodisplay}) or to {opt display} output based on the number of
variables to be displayed.

{phang}{opt nolabel} causes the numeric codes rather than the label
values to be displayed.

{phang}{opt noobs} suppresses the listing of the observation numbers.

{phang}{opt novarlab} suppresses the printing of the default variable
label.

{phang}{opt varname} specifies to include the variable name in the
output.

{phang}{opt table(string)} includes the HTML options specified in
{it:string} in the table.  The default is 
{cmd:table(BORDER=1 CELLSPACING=0 CELLPADDING=2)}.

{phang}{opt align(string)} specifies the alignment of the output.
{cmd:align()} supersedes the alignment in the {opt nodisplay} option.
{it:string} can be {cmd:CENTER} (the default), {cmd:RIGHT}, or
{cmd:LEFT}.


{title:Options for htsummary}

{phang}{opt head} displays the header of the table.  {cmd:head} is only
used for the first row of the table.

{phang}{opt close} ends the table.  {cmd:close} is only used for the
last row of the table.

{phang}{opt nototal} specifies not to include a column for totals.
{cmd:nototal} is only used for the first row of the table.

{phang}{opt freq} requests calculation of frequencies and percentages.
{cmd:freq} is suitable for discrete (or qualitative) variables.  If
{cmd:freq} is not specified, the default summary mean and standard
deviation will be reported.

{phang}{opt row} requests calculation of row percentages instead of the
default column percentages.  {cmd:row} is only allowed when the option
{cmd:freq} is also specified.

{phang}{opt rowtotal} requests calculation of row totals for discrete
variables.  {cmd:rowtotal} is only allowed when the option {opt freq} is
also specified.

{phang}{opt log} specifies that {it:varname1} be analyzed on a
logarithmic scale (so calculate the geometric mean instead of the
default arithmetic mean).

{phang}{opt format(string)} sets the format for {it:varname1}.

{phang}{opt median} calculates the median (centile 50) and interquartile
range (centile 75-centile 25) instead of the default arithmetic mean and
standard deviation.

{phang}{opt add(#)} adds {it:#} to {it:varname1}.  {cmd:add()} is very
useful for the logarithmic transformation of variables containing 0.

{phang}{opt recode(rule)} specifies that the variable be recoded to be
analyzed according to {it:rule}; see {helpb recode}.

{phang}{opt anova} compares groups in columns by analysis of variance
(Student's t if the number of columns is two).

{phang}{opt kw} compares groups in columns by Kruskal-Wallis (Wilcoxon
if the number of columns is two).

{phang}{opt chi} compares groups in columns by chi-squared test.
{cmd:chi} is only allowed when the option {opt freq} is also specified.

{phang}{opt exact} compares groups in columns by Fisher's exact test.
{cmd:exact} is only allowed when the option {opt freq} is also
specified.

{phang}{opt test} automatically determines the appropriate test for
comparison.  {cmd:test} will use ANOVA for means, Kruskal-Wallis for
medians, a chi-squared test for frequencies when less than 20% of cells
have an expected frequency <= 5, and Fisher's exact test for frequencies
when at least 20% of cells have an expected frequency <= 5.

{phang}{opt pval(real)} displays {it:real} as a p-value.  {cmd:pval()}
is useful when the p-value comes from methods other than those performed
by former options.

{phang}{opt method(string)} displays a footnote with {it:string} as the
method for acquiring the p-value from the option {cmd:pval()}.

{phang}{opt missing} defines a category for missing data.  This is only
for descriptive analysis and not for comparison tests.  {cmd:missing} is
only allowed when the option {opt freq} is also specified.

{phang}{opt color(real)} changes the row-background color when p-value <
{it:real}.


{title:Technical notes}

{pstd}These ado-files need some information to work.  Specifically,
{cmd:htopen} opens an HTML file -- the filename (and path) we need for
the rest of the ado-files to use to send output.  To do this,
{cmd:htopen} saves the HTML file identification in a 
{help global:global macro} called {cmd:HTfile}.  Similarly,
{cmd:htsummary} needs to retain information regarding the table, and it
is also saved in global macros:  {cmd:HTsummary} indicates whether we
are actually making a table, that is, whether we have executed the
command with the option {cmd:head}; {cmd:HTptot} indicates whether the
table has a column for totals; {cmd:HTcolor} indicates whether we
specified the option {opt color()}; and {cmd:HTsup} and {cmd:HT#} are
used for superscripts and footnotes.

{pstd}We decided to use names starting with {cmd:HT} for these global
macros so that we would have a common nomenclature for this set of
programs.  {cmd:htclose} removes all global macros whose names begin
with {cmd:HT}; users should keep this in mind if they use global macros
in their programs.

{pstd}To avoid unexpected errors due to the above macros, you should,
when writing {help do:do-files}, enclose all code between {cmd:htopen}
and the corresponding {cmd:htclose} in a {helpb capture:capture noisily}
block; that is, each {cmd:htopen} statement should be immediately
followed by the command

{pstd}{cmd:capture noisily {c -(}}

{pstd}and the corresponding {cmd:htclose} statement should be
immediately preceded by the command

{pstd}{cmd:{c )-}}

{pstd}This practice ensures that if any command in the 
{cmd:capture noisily} block fails, then Stata will transfer control to
the {cmd:htclose} command following the {cmd:capture noisily} block.
The global macros will be cleared, and we can run the corrected program
without failing because of the uncleared {cmd:HTfile} macro.


{title:Example}

{pstd}The following example generates an HTML file called
{cmd:htexample.html}, which includes the statistical results of
{cmd:auto.dta}.

{phang2}{cmd:. htopen using htexample}{p_end}
{phang2}{cmd:. sysuse auto}{p_end}
{phang2}{cmd:. htput <h1> Statistical Analysis </h1>}{p_end}
{phang2}{cmd:. summarize gear_ratio}{p_end}
{p 8 10 2}{cmd:. htput This example uses data from `r(N)' automobiles with a mean Gear Ratio of `: di %8.2f r(mean)'}{p_end}
{phang2}{cmd:. htput <h2> Table 1 </h2>}{p_end}
{phang2}{cmd:. htsummary price foreign, head format(%8.2f) test}{p_end}
{phang2}{cmd:. htsummary mpg foreign, format(%8.2f) test}{p_end}

{phang2}{cmd:. recode mpg (min/25 = 0 "Low/Medium") (25/max = 1 "High"), generate(mympg)}{p_end}
{phang2}{cmd:. label var mympg "Mileage (level)"}{p_end}

{phang2}{cmd:. htsummary mympg foreign, freq rowtotal row test}{p_end}
{phang2}{cmd:. htsummary weight foreign, median format(%8.2f) test}{p_end}

{phang2}{cmd:. htsummary length foreign, log format(%8.2f) test close}{p_end}

{phang2}{cmd:. htput <h2> Table 2 </h2>}{p_end}
{phang2}{cmd:. htlog regress weight length}{p_end}

{p 8 10 2}{cmd:. twoway (scatter weight length) (lfit weight length), name(htexample, replace)}{p_end}
{phang2}{cmd:. graph export htexample.png, replace}{p_end}

{phang2}{cmd:. htput <h2> Figure </h2>}{p_end}
{phang2}{cmd:. htput <img src="htexample.png">}{p_end}
{phang2}{cmd:. htclose}{p_end}

{pstd}After you run the example above, the HTML file called
{cmd:htexample.html} is stored in your working directory and can be
opened by any Internet browser.

{phang2}{it:({stata "htexample ex1":click to run and browse results})}{p_end}

{pstd}The first line of code opens the file for sending output.
Remember to add option {opt replace} when running more than once.
{it:filename} can contain a full path; otherwise, the file is stored in
the working directory.  After reading in the data, the program writes
the text {cmd:Statistical Analysis} using {cmd:htput}.  Because we have
written this text between the tags {cmd:<h1>} and {cmd:</h1>}, the
browser will display it in a title size.  Later, {cmd:<h2>} and
{cmd:</h2>} are used for subtitles to appear in a smaller font size.

{pstd}In line 4, the program computes statistics for the variable
{cmd:gear_ratio} by using the command {cmd:summarize}, and the log is
shown in the Stata Results window. After this, the command {cmd:htput}
sends text to the HTML file with the total number of observations and
the overall mean of {cmd:gear_ratio} expressed in an appropriate format.
Note that we can use Stata macros to write results.  {cmd:htsummary} is
used to make a table of summary statistics.  Row-tables are sent
separately; the first and the last one must include the options
{cmd:head} and {opt close}, respectively.

{pstd}Other Stata commands can be inserted while the table is still
open.  In the example above, we generate a new variable that is a
recodification of the variable {cmd:mpg} in two categories.  After the
table, a linear regression model is estimated, and the standard output
is sent to the HTML file by using the command {cmd:htlog}.  Then we make
a graph and export it to {cmd:.png} format.  This graph is included in
the HTML file as a linked object with the {cmd:<img>} tag.  Finally, we
close the HTML file.


{title:Author}

{pstd}Lloren{c c,} Quint{c o'}, BSc, MPH{p_end}
{pstd}Biostatistics Unit{p_end}
{pstd}Barcelona Centre for International Health Research{p_end}
{pstd}(CRESIB, Hospital Cl{c i'}nic -- Universitat de Barcelona){p_end}
{pstd}Barcelona, Spain{p_end}
{pstd}llorenc.quinto@cresib.cat{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 12, number 4: {browse "http://www.stata-journal.com/article.html?article=dm0066":dm0066}{p_end}
