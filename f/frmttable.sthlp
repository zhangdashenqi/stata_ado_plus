{smcl}
{* *! version 1.2  03dec2012}{...}
{cmd:help frmttable}{right: ({browse "http://www.stata-journal.com/article.html?article=sg97_5":SJ12-4: sg97_5})}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{hi:frmttable} {hline 2}}A programmer's command to write formatted Word or TeX tables from a matrix of statistics{p_end}
{p2colreset}{...}
   

{title:Syntax}

{p 8 17 2}
{cmd:frmttable}
[{cmd:using} {it:filename}]
[{cmd:,} {it:options}]

{synoptset 26}{...}
{p2col:Options category}Description{p_end}
{synoptline}
{p2col:{it:{help frmttable##stat_for_opts:Statistics}}}statistics and numerical formatting{p_end}
{p2col:{it:{help frmt_opts##text_add_opts:Text additions}}}titles, notes,
added rows, and columns{p_end}
{p2col:Text formatting:}
{p2colset 7 33 35 16}{p_end}
{p2col:{it:{help frmt_opts##col_form_opts:Column formatting}}}column widths, justification, etc.{p_end}
{p2col:{it:{help frmt_opts##font_opts:Font specification}}}font specifications{p_end}
{p2col:{it:{help frmt_opts##lines_spaces_opts:Border lines and spacing}}}horizontal and vertical lines, cell spacing{p_end}
{p2colset 5 33 35 16}{...}
{p2col:{it:{help frmt_opts##file_opts:File and display options}}}TeX files, merge, replace, etc.{p_end}
{p2col:{it:{help frmt_opts##brack_opts:Brackets options}}}change brackets, for
example, around t statistics{p_end}
{p2colset 5 30 31 2}{...}
{p2line}

{pstd}
{it:{help frmt_opts##greek:Inline text formatting: Superscripts, italics, Greek characters, etc.}}{p_end}
{pstd}
{it:{help frmttable##examples:Examples of frmttable in use}}{p_end}

{marker stat_for_opts}
{synoptset 26}{...}
{p2col:{help frmttable##stats_formatting:Statistics}}Description{p_end}
{synoptline}
{p2col:{cmdab:s:tatmat(}{it:matname}{cmd:)}}matrix of statistics for body of table{p_end}
{p2col:{cmdab:sub:stat(}{it:#}{cmd:)}}number of substatistics to place below first statistics{p_end}
{p2col:{cmdab:d:oubles(}{it:matname}{cmd:)}}matrix indicating double statistics{p_end}
{p2col:{cmdab:sd:ec(}{it:numgrid}{cmd:)}}decimal places for all statistics{p_end}
{p2col:{cmdab:sf:mt(}{it:fmtgrid}{cmd:)}}numerical format for all statistics{p_end}
{p2col:{cmdab:e:q_merge}}merge multiequation statistics into multiple columns{p_end}
{p2col:{cmdab:nobl:ankrows}}drop blank rows in table{p_end}
{p2col:{cmdab:fi:ndcons}}put {cmd:_cons} in separate section of table{p_end}
{synoptline}
{marker text_add_opts}{...}

{synoptset 26}{...}
{p2col:{help frmt_opts##text_additions:Text additions}}Description{p_end}
{synoptline}
{p2col:{cmdab:va:rlabels}}use variable labels as {cmd:rtitles()}{p_end}
{p2col:{cmdab:t:itle(}{it:textcolumn}{cmd:)}}put title above table{p_end}
{p2col:{cmdab:ct:itles(}{it:textgrid}{cmd:)}}headings at top of columns{p_end}
{p2col:{cmdab:rt:itles(}{it:textgrid}{cmd:)}}headings to the left of each row{p_end}
{p2col:{cmdab:n:ote(}{it:textcolumn}{cmd:)}}put note below table{p_end}
{p2col:{cmdab:pr:etext(}{it:textcolumn}{cmd:)}}place regular text before the table{p_end}
{p2col:{cmdab:po:sttext(}{it:textcolumn}{cmd:)}}place regular text after the table{p_end}
{p2col:{cmdab:noco:ltitl}}no column titles{p_end}
{p2col:{cmdab:noro:wtitl}}no row titles{p_end}
{p2col:{cmdab:ad:drows(}{it:textgrid}{cmd:)}}add rows at bottom of table{p_end}
{p2col:{cmdab:addrt:c(}{it:#}{cmd:)}}number of {cmd:rtitles()} columns in {cmd:addrows()}{p_end}
{p2col:{cmdab:addc:ols(}{it:textgrid}{cmd:)}}add columns to the right of table{p_end}
{p2col:{cmdab:an:notate(}{it:matname}{cmd:)}}grid of annotation locations{p_end}
{p2col:{cmdab:as:ymbol(}{it:textrow}{cmd:)}}symbols for annotations{p_end}
{synoptline}
{marker col_form_opts}{...}

{synoptset 35}{...}
{p2col:{help frmt_opts##col_formats:Column formatting}}Description{p_end}
{synoptline}
{p2col:{cmdab:colw:idth(}{it:numlist}{cmd:)}*}change column widths{p_end}
{p2col:{cmdab:mu:lticol(}{it:numtriple}[{cmd:;} {it:numtriple} ...]{cmd:)}}make column titles span multiple columns{p_end}
{p2col:{cmdab:colj:ust(}{it:cjstring}[{cmd:;} {it:cjstring} ...]{cmd:)}}column-justification: left, center, right, or decimal{p_end}
{p2col:{cmdab:noce:nter}}do not center table within page{p_end}
{synoptline}
{syntab:* Word-only option}
{marker font_opts}{...}

{synoptset 34}{...}
{p2col:{help frmt_opts##fonts:Font specification}}Description{p_end}
{synoptline}
{p2col:{cmdab:ba:sefont(}{it:fontlist}{cmd:)}}change the base font for all text{p_end}
{p2col:{cmdab:titlf:ont(}{it:fontcolumn}{cmd:)}}change font for table title{p_end}
{p2col:{cmdab:notef:ont(}{it:fontcolumn}{cmd:)}}change font for notes below table{p_end}
{p2col:{cmdab:ctitlf:ont(}{it:fontgrid}[{cmd:;} {it:fontgrid} ...]{cmd:)}}change font for column titles{p_end}
{p2col:{cmdab:rtitlf:ont(}{it:fontgrid}[{cmd:;} {it:fontgrid} ...]{cmd:)}}change font for row titles{p_end}
{p2col:{cmdab:statf:ont(}{it:fontgrid}[{cmd:;} {it:fontgrid} ...]{cmd:)}}change font for statistics in body of table{p_end}
{p2col:{cmdab:addf:ont(}{it:fontname}{cmd:)}*}add a new font type{p_end}
{p2col:{cmdab:p:lain}}plain text -- one font size, no justification{p_end}
{p2col:{it:table_sections}}explanation of formatted table sections{p_end}
{synoptline}
{syntab:* Word-only option}
{marker lines_spaces_opts}{...}

{synoptset 40}{...}
{p2col:{help frmt_opts##lines_spaces:Border lines and spacing}}Description{p_end}
{synoptline}
{p2col:{cmdab:hl:ines(}{it:linestring}[{cmd:;} {it:linestring} ...]{cmd:)}}horizontal lines between rows{p_end}
{p2col:{cmdab:vl:ines(}{it:linestring}[{cmd:;} {it:linestring} ...]{cmd:)}}vertical lines between columns{p_end}
{p2col:{cmdab:hls:tyle(}{it:lstylelist}[{cmd:;} {it:lstylelist} ...]{cmd:)}*}change style of horizontal lines{p_end}
{p2col:{cmdab:vls:tyle(}{it:lstylelist}[{cmd:;} {it:lstylelist} ...]{cmd:)}*}change style of vertical lines{p_end}
{p2col:{cmdab:spaceb:ef(}{it:spacestring}[{cmd:;} {it:spacestring} ...]{cmd:)}}put space above cell contents{p_end}
{p2col:{cmdab:spacea:ft(}{it:spacestring}[{cmd:;} {it:spacestring} ...]{cmd:)}}put space below cell contents{p_end}
{p2col:{cmdab:spaceh:t(}{it:#}{cmd:)}}change size of {opt spacebef()}  and {opt spaceaft()}{p_end}
{synoptline}
{syntab:* Word-only option}
{marker page_fmt_opts}{...}

{synoptset 26}{...}
{p2col:{help frmt_opts##page_fmt:Page formatting}}Description{p_end}
{synoptline}
{p2col:{cmdab:la:ndscape}}use landscape orientation{p_end}
{p2col:{cmd:a4}}use A4-size paper (instead of 8 1/2" x 11"){p_end}
{synoptline}
{marker file_opts}{...}

{synoptset 26}{...}
{p2col:{help frmt_opts##file_options:File and display options}}Description{p_end}
{synoptline}
{p2col:{cmd:tex}}write a TeX file instead of the default Word file{p_end}
{p2col:{cmdab:m:erge}[{cmd:(}{it:tblname}{cmd:)}]}merge as new columns to existing table{p_end}
{p2col:{cmd:replace}}replace existing file{p_end}
{p2col:{cmdab:addt:able}}write a new table below existing table{p_end}
{p2col:{cmdab:ap:pend}[{cmd:(}{it:tblname}{cmd:)}]}append as new rows below existing table{p_end}
{p2col:{cmdab:re:play}[{cmd:(}{it:tblname}{cmd:)}]}write preexisting table{p_end}
{p2col:{cmdab:sto:re(}{it:tblname}{cmd:)}}store table with name {it:tblname}{p_end}
{p2col:{cmdab:cl:ear}[{cmd:(}{it:tblname}{cmd:)}]}clear existing table from memory{p_end}
{p2col:{cmdab:fr:agment}**}create TeX code fragment to insert into TeX document{p_end}
{p2col:{cmdab:nod:isplay}}do not display table in Results window{p_end}
{p2col:{cmdab:dw:ide}}display all columns, however wide{p_end}
{synoptline}
{syntab:** TeX-only option}
{marker brack_opts}{...}

{synoptset 35}{...}
{p2col:{help frmt_opts##brack_options:Brackets options}}Description{p_end}
{synoptline}
{p2col:{cmdab:sq:uarebrack}}square brackets instead of parentheses{p_end}
{p2col:{cmdab:br:ackets(}{it:textpair} [{cmd:\} {it:textpair} ...]{cmd:)}}symbols with which to bracket substatistics{p_end}
{p2col:{cmdab:nobrk:et}}put no brackets on substatistics{p_end}
{p2col:{cmdab:dbl:div(}{it:text}{cmd:)}}specify symbol dividing double
statistics; default is {cmd:dbldiv(-)}{p_end}
{synoptline}


{title:Description}

{pstd}{cmd:frmttable} is a programmer's command that takes a Stata
matrix of statistics and creates a fully formatted Word or TeX table,
which can be written to a file.

{pstd}The {cmd:frmttable} command normally uses either the 
{helpb frmttable##statmat:statmat()} option with the name of a Stata
matrix of statistics to be displayed or the 
{helpb frmt_opts##replay:replay} option, which causes the existing table
in memory to be redisplayed and possibly written to disk.

{pstd}{cmd:frmttable} makes available the capability to format Word or
TeX tables of statistics in myriad ways without the programmer having to
write the code necessary to do the formatting.  The programmer just
needs to write code that calculates statistics and can leave the
formatting chores to {cmd:frmttable}.

{pstd}Writing formatted tables directly to word processing files can
save researchers a great deal of time.  {cmd:frmttable} provides the
means to automatically create fully formatted tables within Stata,
saving researchers laborious minutes or hours of manual reformatting
each time they make modifications.  Automatically formatted tables save
time principally because researchers usually tweak their tables many
times before they are ready in their final form.

{pstd}{cmd:frmttable} gives the user much control over the final
document.  Almost every aspect of the table's structure and formatting
can be specified with options.  Users can change fonts at the table cell
level as well as change cell spacing and horizontal and vertical lines.
{cmd:frmttable} can add various text around the table, including titles,
notes below the table, and paragraphs of text above and below.
Footnotes or other text can be interspersed within the statistics.

{pstd}{cmd:frmttable} is the main code behind the {helpb outreg}
command, which creates flexible tables of estimation results.

{pstd}If {helpb using} {it:filename} is specified, {cmd:frmttable} will
create a Microsoft Word file (or a TeX file with the {cmd:tex} option).
The table created by {cmd:frmttable} is displayed in the Results window
(minus the fancy fonts) unless the 
{helpb frmt_opts##nodisplay:nodisplay} option is used.

{pstd}Successive sets of statistics can be 
{helpb frmt_opts##merge:merge}d or {helpb frmt_opts##append:append}ed by
{cmd:frmttable} into a single table.  Additional tables can be written
to the same file by using the {helpb frmt_opts##addtable:addtable}
option, with paragraphs of text between the tables.  This makes it
possible to create a do-file that writes an entire statistical appendix
in final form to a single Word or TeX file with no subsequent editing
required.

{pstd}{cmd:frmttable} converts the Stata matrix of statistics in
{cmd:statmat()}, along with various text additions like titles, into a
Mata {helpb [M-2] struct:struct} of string matrices that persists in
memory.  The persistent table data can be reused to merge or append new
results or written to a Word or TeX file with new formatting directives.
The persistent {cmd:frmttable} data can be assigned names, so multiple
tables can be manipulated simultaneously.

{pstd}This help file provides many 
{help frmttable##examples:examples of}
{helpb frmttable##examples:frmttable} {help frmttable##examples:in use}
below the descriptions of the options for statistics and numerical
formatting.

{pstd}The remaining options are detailed {help frmt_opts:here}.


{title:Options}

{marker stats_formatting}{...}
{dlgtab:Statistics and numerical formatting}
{marker statmat}{...}

{phang}{cmd:statmat(}{it:matname}{cmd:)} names the Stata matrix
containing the statistics making up the body of the table.

{pmore}If the user has filled matrix row names or column names for the
Stata matrix, they become the row titles and column titles of the table
(unless the {helpb frmt_opts##rtitles:rtitles()} or 
{helpb frmt_opts##ctitles:ctitles()} option is specified).  If the row
names and column names of the {cmd:statmat()} matrix are 
{it:{help varname:varnames}}, the option 
{helpb frmt_opts##varlabels:varlabels} will replace the variable names
with their {help label:variable labels} if they exist.

{pmore}See an application of {cmd:statmat()} in 
{help frmttable##xmpl1:Example 1}.

{marker substat}{...}
{phang}{cmd:substat(}{it:#}{cmd:)} indicates the number of substatistics
to be placed in separate rows below the principal statistic.  For
example, if the {cmd:statmat()} matrix has three rows and four columns,
a {cmd:substat(1)} option would interlace the statistics in 
{helpb frmttable##statmat:statmat()} column 2 below those of column 1
and the statistics in column 4 below those of column 3, resulting in a
final table with six rows and two statistics columns.  This allows the
programmer to create a {cmd:statmat()} with substatistics in separate
columns from the principal statistics and rely on {cmd:frmttable} to
interlace them (such as t statistics below regression coefficients or
standard deviations below means).

{pmore}See applications of {cmd:substat()} in 
{help frmttable##xmpl4:Example 4} and 
{help frmttable##xmpl5:Example 5}.

{marker doubles}{...}
{phang}{cmd:doubles(}{it:matname}{cmd:)} names the Stata matrix
indicating which statistics are double statistics.  Double statistics
are statistics made up of two numbers, such as confidence intervals or
minimum-maximum ranges.  The {cmd:doubles()} option allows the lower and
upper numbers to be placed in different columns of the {cmd:statmat()}
and to be combined in the formatted table.

{pmore}The {cmd:doubles()} matrix is a row vector with as many elements
as columns in {helpb frmttable##statmat:statmat()}.  A 0 specifies that
the column is not a second double statistic, and a 1 indicates that it
is.  Thus if {cmd:statmat()} consists of a matrix with columns
containing the means, lower confidence bounds, and upper confidence
bounds of some variables, a {cmd:doubles()} matrix of (0,0,1) would
cause the lower and upper confidence bounds to be combined into a single
confidence interval.  The default symbol to separate the lower and upper
statistic of double statistics is a dash, but this can be changed with
the {helpb frmt_opts##dbldiv:dbldiv()} option.

{marker sdec}{...}
{phang}{cmd:sdec(}{it:numgrid}{cmd:)} specifies the decimal places for
the statistics in {cmd:statmat()}.  The {it:numgrid} corresponds to the
decimal places for each of the statistics in the table.  The default is
{cmd:sdec(3)}.

{pmore}The {it:numgrid} can be a single integer applying to the whole
table, or it can be a grid of integers specifying the decimal places for
each cell in the table individually.  A {it:numgrid} is a grid of
integers 0-15 in the form used by {helpb matrix define:matrix define}.
Commas separate elements along a row, and backslashes ({cmd:\}) separate
rows.  {it:numgrid} has the form ({it:#} [{cmd:,} {it:#} ...] [{cmd:\}
{it:#} [{cmd:,} {it:#} ...] [...]]).  For example, if the table of
statistics has three rows and two columns, you could use 
{cmd:sdec(1,2 \ 2,2 \ 1,3)}.  If you specify a grid smaller than the
table of statistics, the last rows and columns of the {it:numgrid} will
be repeated to cover the whole table.  So for our table with three rows
and two columns, {cmd:sdec(1 \ 2)} would have the same effect as
{cmd:sdec(1,1 \ 2,2 \ 2,2)}.  Unbalanced rows or columns will not cause
an error; they will be filled in, and {cmd:frmttable} will display a
warning message.{p_end}

{marker sfmt}{...}
{phang}{cmd:sfmt(}{it:fmtgrid}{cmd:)} specifies the numerical format for
statistics in {cmd:statmat()}.  The {it:fmtgrid} is a grid of the format
types ({cmd:e}, {cmd:f}, {cmd:g}, {cmd:fc}, or {cmd:gc}) for each
statistic in the table.  The {it:fmtgrid} can be a single format
applying to the whole table, or it can specify formats for each cell in
the table individually.

{pmore}{it:fmtgrid} has the form {it:fmt}[{cmd:,}{it:fmt}...] [{cmd:\}
{it:fmt}[{cmd:,}{it:fmt}...] ...]], where {it:fmt} is either {cmd:e},
{cmd:f}, {cmd:fc}, {cmd:g}, or {cmd:gc}.

{p2colset 11 22 24 20}{...}
{p2col:{it:fmt}}Format type{p_end}
{synoptline}
{p2col:{opt e}}exponential (scientific) notation{p_end}
{p2col:{opt f}}fixed number of decimals{p_end}
{p2col:{opt fc}}fixed with commas for thousands, etc. --  the default{p_end}
{p2col:{opt g}}general format (see {helpb format}){p_end}
{p2col:{opt gc}}general format with commas for thousands, etc.{p_end}
{synoptline}

{pmore}The {cmd:g} and {cmd:gc} formats are not likely to be useful for
{cmd:frmttable} tables because they do not allow the user to control the
number of decimal places displayed.

{pmore}If {it:fmtgrid} has dimensions smaller or bigger than the
{cmd:statmat()} matrix, then {it:fmtgrid} is adjusted just as
{it:numgrid} is for {helpb frmttable ##sdec:sdec()}.

{marker eq_merge}{...}
{phang}{opt eq_merge} merges the columns of a multiequation
{cmd:statmat()} matrix into multiple columns, one column per equation.
This option is used by {helpb outreg}, for example, to put the
coefficients of each {helpb sureg} equation side by side instead of
stacked vertically.  The equation statistics are merged as if each of
the equations were sequentially combined with the 
{helpb frmt_opts##merge:merge} option.

{pmore}{cmd:frmttable} identifies the equations in {cmd:statmat()} by
{helpb matrix rownames:roweq} names.  All rows of {cmd:statmat()} with
the same {cmd:roweq} name are considered an equation.  If no
{cmd:roweq}s are assigned, {cmd:frmttable} considers all rows to belong
to the same (unnamed) equation.  {cmd:eq_merge} is an option whose main
purpose is to help {cmd:outreg} reorganize multiequation estimation
results.

{marker noblankrows}{...}
{phang}{cmd:noblankrows} deletes completely blank rows in the body of the
formatted table.  A blank row means that the data are missing in each column.

{marker findcons}{...}
{phang}{cmd:findcons} finds table rows with a row title of {cmd:_cons}
and assigns them to a separate 
{help frmt_opts##table_sections:row section} that is kept below the
other row sections.  This option is useful for merging statistical
results such as regression coefficients, where you want to ensure that
the constant coefficient estimates are reported below all other
coefficients even when the user merges additional statistics containing
new variables.  This option is rarely used.

{marker examples}{...}

{title:Examples}

{pstd}{help frmttable ##xmpl1:Example 1: Basic usage}{p_end}
{pstd}{help frmttable ##xmpl2:Example 2: Merge and append}{p_end}
{pstd}{help frmttable ##xmpl3:Example 3: Multicolumn titles, border lines, fonts}{p_end}
{pstd}{help frmttable ##xmpl4:Example 4: Add stars for significance to regression output: Substatistics and annotate}{p_end}
{pstd}{help frmttable ##xmpl5:Example 5: Make a table of summary statistics and merge it with a regression table}{p_end}
{pstd}{help frmttable ##xmpl6:Example 6: Create complex tables using merge and append}{p_end}
{pstd}{help frmttable ##xmpl7:Example 7: Double statistics}{p_end}
   
{marker xmpl1}
{title:Example 1: Basic usage}

{pstd}The basic role of {cmd:frmttable} is to take statistics in a Stata
matrix and organize them in a table that is displayed in the Results
window and can be written to a file as a Word table or a TeX table.

{pstd}First, we create a 2x2 Stata matrix named A:

{phang2}{cmd:. matrix A = (100,50\0,50)}{p_end}
{phang2}{cmd:. matrix list A}{p_end}
	  {res}
	  {txt}A[2,2]
	       c1   c2
  	  r1 {res} 100   50
	  {txt}r2 {res}   0   50{txt}

{pstd}The simplest usage of the {cmd:frmttable} command is to display
the matrix A:

	{com}. frmttable, statmat(A)
	{res}
	{txt}{center:{hline 17}}
	{center:{res}{center 8:100.00}{res}{center 7:50.00}}
	{center:{res}{center 8:0.00}{res}{center 7:50.00}}
	{txt}{center:{hline 17}}

{pstd}This does not get us very far.  The reason {cmd:frmttable} is
useful is that it can make extensive adjustments to the formatting of
the table and write the result to a Word or TeX document.

{pstd}The {cmd:frmttable} command below has a {cmd:using} statement
followed by a filename ({cmd:xmpl1}).  This causes the table to be
written to a Word document called {cmd:xmpl1.doc}.  Word documents are
the default; to specify that the table be written as a TeX document,
include the {cmd:tex} option.

{pstd}The {cmd:frmttable} statement below adds a number of options.  The
first, {cmd:sdec()}, sets the number of decimal places displayed for the
statistics in {cmd:statmat()} to 0.  The next three options,
{cmd:title()}, {cmd:ctitle()}, and {cmd:rtitle()}, add an overall title
to the table, titles above each column of the table, and titles on the
left of each row of the table, respectively.  The column and row titles
are designated with the syntax used for matrices: commas separate
columns and backslashes separate rows.

{phang2}{com}. frmttable using xmpl1, statmat(A) sdec(0) title("Payoffs") ctitle("","Game 1","Game 2") rtitle("Player 1"\"Player 2")
	
	{txt}{center:Payoffs}
	{txt}{center:{hline 28}}
	{center:{txt}{lalign 10:}{txt}{center 8:Game 1}{txt}{center 8:Game 2}}
	{txt}{center:{hline 28}}
	{center:{txt}{lalign 10:Player 1}{res}{center 8:100}{res}{center 8:50}}
	{center:{txt}{lalign 10:Player 2}{res}{center 8:0}{res}{center 8:50}}
	{txt}{center:{hline 28}}


{marker xmpl2}{...}
{title:Example 2: Merge and append}

{pstd}Once {cmd:frmttable} is run, the table created stays in memory (as
a {helpb [M-2] struct:struct} of Mata string matrices).  Subsequent
statistical results can be {helpb frmt_opts##merge:merge}d as new
columns of the table or {helpb frmt_opts##append:append}ed as new rows.
The merged columns are arranged so that the new row titles are matched
with the existing table's row titles, and rows with unmatched titles are
placed below the other statistics (similar to the way the Stata 
{helpb merge} command matches observations of the merged dataset).

{pstd}The {cmd:frmttable} command below merges a new column of
statistics for players 1 and 3 to the existing {cmd:frmttable} table,
created in the previous example.

{phang2}{cmd:. matrix B = (25\75)}{p_end}
	{txt}
{phang2}{com}. frmttable, statmat(B) sdec(0) ctitle("","Game 3") rtitle("Player 1"\"Player 3") merge {p_end}
	{res}
	{txt}{center:Payoffs}
	{txt}{center:{hline 36}}
	{center:{txt}{lalign 10:}{txt}{center 8:Game 1}{txt}{center 8:Game 2}{txt}{center 8:Game 3}}
	{txt}{center:{hline 36}}
	{center:{txt}{lalign 10:Player 1}{res}{center 8:100}{res}{center 8:50}{res}{center 8:25}}
	{center:{txt}{lalign 10:Player 2}{res}{center 8:0}{res}{center 8:50}{res}{center 8:}}
	{center:{txt}{lalign 10:Player 3}{res}{center 8:}{res}{center 8:}{res}{center 8:75}}
	{txt}{center:{hline 36}}
	
{pstd}In this case, the new statistics in matrix B are arranged
according to the row titles in the {cmd:rtitle()} option.  The
statistics in the first row of B for player 1 are lined up with the
statistics for {cmd:Player 1} in the existing table; the statistics for
player 3 are placed below those for player 2 because {cmd:Player 3} is a
new row title.

{pstd}The text of the row titles must match exactly for the merged
results to be placed in the same row.  Row titles of {cmd:Player 1} and
{cmd:player 1} do not match, so they would be placed in different rows.

{pstd}Next we add another column to the table for new game results.

{phang2}{com}. matrix C = (90\10){p_end}
	{txt}
{phang2}{com}. frmttable, statmat(C) sdec(0) ctitle("","Game 4") rtitle("Player 2"\"Player 4") merge{p_end}
	{res}
	{txt}{center:Payoffs}
	{txt}{center:{hline 44}}
	{center:{txt}{lalign 10:}{txt}{center 8:Game 1}{txt}{center 8:Game 2}{txt}{center 8:Game 3}{txt}{center 8:Game 4}}
	{txt}{center:{hline 44}}
	{center:{txt}{lalign 10:Player 1}{res}{center 8:100}{res}{center 8:50}{res}{center 8:25}{res}{center 8:}}
	{center:{txt}{lalign 10:Player 2}{res}{center 8:0}{res}{center 8:50}{res}{center 8:}{res}{center 8:90}}
	{center:{txt}{lalign 10:Player 3}{res}{center 8:}{res}{center 8:}{res}{center 8:75}{res}{center 8:}}
	{center:{txt}{lalign 10:Player 4}{res}{center 8:}{res}{center 8:}{res}{center 8:}{res}{center 8:10}}
	{txt}{center:{hline 44}}
	
{pstd}The statistics for player 2 and for player 4 are merged: the
statistics for player 2 are lined up with previous results for
{cmd:Player 2}, and statistics for the new row title, {cmd:Player 4},
are placed below the other rows.

{pstd}Finally, we {cmd:append} new rows to the table for the total
payoffs.

	{com}. matrix D = (100,100,100,100)
	{txt}
	{com}. frmttable, statmat(D) sdec(0) rtitle("Total") append
	{res}
	{txt}{center:Payoffs}
	{txt}{center:{hline 44}}
	{center:{txt}{lalign 10:}{txt}{center 8:Game 1}{txt}{center 8:Game 2}{txt}{center 8:Game 3}{txt}{center 8:Game 4}}
	{txt}{center:{hline 44}}
	{center:{txt}{lalign 10:Player 1}{res}{center 8:100}{res}{center 8:50}{res}{center 8:25}{res}{center 8:}}
	{center:{txt}{lalign 10:Player 2}{res}{center 8:0}{res}{center 8:50}{res}{center 8:}{res}{center 8:90}}
	{center:{txt}{lalign 10:Player 3}{res}{center 8:}{res}{center 8:}{res}{center 8:75}{res}{center 8:}}
	{center:{txt}{lalign 10:Player 4}{res}{center 8:}{res}{center 8:}{res}{center 8:}{res}{center 8:10}}
	{center:{txt}{lalign 10:Total}{res}{center 8:100}{res}{center 8:100}{res}{center 8:100}{res}{center 8:100}}
	{txt}{center:{hline 44}}
	
{pstd}Whereas the {helpb frmt_opts##merge:merge} option creates new
table columns, the {helpb frmt_opts##append:append} option creates new
rows, placing the new statistics below the existing table.  If matrix D
had more than or fewer than four columns, it would still be appended
below the existing results but with a warning message.  The arrangement
of the {cmd:append}ed results does not depend on the column titles
(unlike the way {cmd:merge} depends on the row titles).  In fact, the
{cmd:ctitles()} of the appended data are ignored if they are specified.

{pstd}An alternative way of adding rows and columns is with the options
{helpb frmt_opts##addrows:addrows()} and 
{helpb frmt_opts##addcols:addcols()}.  {cmd:merge} and {cmd:append} add
matrices of numbers to a previously created table; {cmd:addrows()} and
{cmd:addcols()} add on rows and columns of text (which can include
numbers) to the table currently being created.

{pstd}The following set of commands will create the same table as above,
but we use the {cmd:addrows()} option to attach the column totals as
text instead of {cmd:append}ing a Stata matrix:

{phang2}{com}. matrix E = (100,50,25,. \ 0,50,.,90 \ .,.,75,. \ .,.,.,10){p_end}
	{txt}
{phang2}{com}. frmttable, statmat(E) sdec(0) addrows("Total", "100", "100", "100", "100") rtitles("Player 1" \ "Player 2" \ "Player 3" \ "Player 4") ctitles("", "Game 1", "Game 2", "Game 3", "Game 4") title("Payoffs"){p_end}
	{res}
	{txt}{center:Payoffs}
	{txt}{center:{hline 44}}
	{center:{txt}{lalign 10:}{txt}{center 8:Game 1}{txt}{center 8:Game 2}{txt}{center 8:Game 3}{txt}{center 8:Game 4}}
	{txt}{center:{hline 44}}
	{center:{txt}{lalign 10:Player 1}{res}{center 8:100}{res}{center 8:50}{res}{center 8:25}{res}{center 8:}}
	{center:{txt}{lalign 10:Player 2}{res}{center 8:0}{res}{center 8:50}{res}{center 8:}{res}{center 8:90}}
	{center:{txt}{lalign 10:Player 3}{res}{center 8:}{res}{center 8:}{res}{center 8:75}{res}{center 8:}}
	{center:{txt}{lalign 10:Player 4}{res}{center 8:}{res}{center 8:}{res}{center 8:}{res}{center 8:10}}
	{center:{txt}{lalign 10:Total}{res}{center 8:100}{res}{center 8:100}{res}{center 8:100}{res}{center 8:100}}
	{txt}{center:{hline 44}}
	{marker xmpl3}{...}

{title:Example 3: Multicolumn titles, border lines, fonts}

{pstd}Many formatting options are available in {cmd:frmttable}.  This
example makes some of the column titles span multiple columns, places a
vertical line in the table, and changes the font size and typeface.

{pstd}{cmd:frmttable} can change many other aspects of the tables it
creates, such as footnotes and other annotations among the statistics,
justification of columns, and spacing above and below table cells.  You
can find additional examples of many {cmd:frmttable} formatting options
in the {helpb outreg} help file; some examples are related to 
{help outreg_complete##xmpl11:fonts}, 
{help outreg_complete##xmpl12:special characters}, 
{help outreg_complete##xmpl13:multiple tables in the same document}, and
{help outreg_complete##xmpl14:footnotes}.

{pstd}In the Stata code below, the {cmd:frmttable} table is created from
data in the matrix F.  Where F contains missing values, the table cells
will be blank.

{pstd}The table's column titles in the {cmd:ctitles()} option have two
rows, and the titles in the first row are meant to span two columns
each.  They are made to span multiple columns with the
{cmd:multicol(1,2,2;1,4,2)} option.  The two triples of numbers --
{cmd:1,2,2} and {cmd:1,4,2} -- indicate which table cells span more than
one column.  {cmd:1,2,2} indicates that the first row, second column of
the table should span two columns; {cmd:1,4,2} indicates that the first
row, fourth column of the table should span two columns.

{pstd}A dashed vertical line is placed in the table separating the row
titles from the statistics.  The {cmd:vlines(010)} option specifies
where the vertical line or lines are placed.  A {cmd:0} indicates no
line, and a {cmd:1} indicates a line.  The {cmd:010} means no line to
the left of the first cell (or column), a vertical line between the
first and second cell, and no line between the second and third cell.
Because the table has more than two columns, the "no line" specification
is extended to the rest of the columns.  The {cmd:vlstyle(a)} option
changes the line style from the default solid line to a dashed line.

{pstd}The last option, {cmd:basefont(arial fs10)}, changes the font of
the Word table to Arial, with a base font size of 10 points.  The base
font size applies to most of the table, but by default, the table's
title has larger text and the notes below the table, if any, have
smaller text.

{phang2}{com}. matrix F = (100,50,25,. \ 0,50,.,90 \ .,.,75,. \ .,.,.,10 \ 100,100,100,100){p_end}
	{txt}
{phang2}{com}. frmttable using xmpl3, statmat(F) sdec(0) title("Payoffs") replace ctitles("", "{c -(}\ul Day 1{c )-}", "", "{c -(}\ul Day 2{c )-}" ,"" \ "", "Game 1", "Game 2", "Game 3", "Game 4") multicol(1,2,2;1,4,2) rtitles("Player 1" \ "Player 2" \ "Player 3" \ "Player 4" \ "Total") vlines(010) vlstyle(a) basefont(arial fs10){p_end}
{phang2}{txt}({it:output omitted})

{pstd}The table created in this example is not shown because most of its
features (font, vertical lines, etc.) appear correctly only in the Word
table created, not in the Stata Results window.{p_end}{...}

{marker xmpl4}
{title:Example 4: Add stars for significance to regression output: Substatistics and annotate}

{pstd}The following Stata commands create a matrix, {cmd:b_se},
containing regression coefficients in the first column and standard
errors of estimates in the second column:

	{com}. sysuse auto, clear
	{com}. regress mpg length weight headroom
	{txt}({it:output omitted})
	
{phang2}{com}. matrix b_se = get(_b)', vecdiag(cholesky(diag(vecdiag(get(VCE)))))'{p_end}
{phang2}{com}. matrix colnames b_se = mpg mpg_se{p_end}
{phang2}{com}. matrix li b_se{p_end}
	{res}
	{txt}b_se[4,2]
	                 mpg      mpg_se
	  length {res} -.07849725   .05699153
	{txt}  weight {res} -.00385412   .00159743
	{txt}headroom {res} -.05143046   .55543717
	{txt}   _cons {res}  47.840789   6.1492834{reset}

{pstd}{cmd:frmttable} will convert this matrix into a formatted table.
The {cmd:substat(1)} option informs {cmd:frmttable} that the second
column of statistics, the standard errors, should be interweaved below
the first column of statistics, the coefficients, in the table.  If the
option were {cmd:substat(2)}, the second and third columns of statistics
would be interweaved below the statistics in the first column of
{cmd:statmat()}.

{pstd}In the absence of {cmd:rtitles()} and {cmd:ctitles()},
{cmd:frmttable} uses the matrix row names and column names of {cmd:b_se}
as the row and column titles for the table.

	{com}. frmttable, statmat(b_se) substat(1) sdec(3)
	{res}
	{txt}{center:{hline 21}}
	{center:{txt}{lalign 10:}{txt}{center 9:mpg}}
	{txt}{center:{hline 21}}
	{center:{txt}{lalign 10:length}{res}{center 9:-0.078}}
	{center:{txt}{lalign 10:}{res}{center 9:(0.057)}}
	{center:{txt}{lalign 10:weight}{res}{center 9:-0.004}}
	{center:{txt}{lalign 10:}{res}{center 9:(0.002)}}
	{center:{txt}{lalign 10:headroom}{res}{center 9:-0.051}}
	{center:{txt}{lalign 10:}{res}{center 9:(0.555)}}
	{center:{txt}{lalign 10:_cons}{res}{center 9:47.841}}
	{center:{txt}{lalign 10:}{res}{center 9:(6.149)}}
	{txt}{center:{hline 21}}
	
{pstd}Stars indicating significance levels can be placed next to the
standard errors by using the {cmd:annotate()} option.  First, you need
to create a Stata matrix indicating the cells to which the stars should
be added.  The matrix, named {cmd:stars} below, has a 1 in the second
row, second column, and a 2 in the fourth row, second column, because
the second and fourth coefficients are statistically significant at the
stated levels.

	{com}. local bc = rowsof(b_se)
	{com}. matrix stars = J(`bc',2,0)
	{com}. forvalues k = 1/`bc' {c -(}
{p 10 12 2}{com}2.       matrix stars[`k',2] = (abs(b_se[`k',1]/b_se[`k',2]) > invttail(`e(df_r)',0.05/2)) + (abs(b_se[`k',1]/b_se[`k',2]) > invttail(`e(df_r)',0.01/2)){p_end}
{p 10 12 2}{com}3. {c )-}{p_end}
	{com}. matrix list stars
	{res}
	{txt}stars[4,2]
	    c1  c2
	r1 {res}  0   0
	{txt}r2 {res}  0   1
	{txt}r3 {res}  0   0
	{txt}r4 {res}  0   2{reset}

{pstd}The entries of 1 and 2 in {cmd:stars} correspond to the first and
second entry of the {cmd:asymbol(*,**)} option, which adds a single star
in the cell where the 1 is and a double star in the cell where the 2 is.
All the elements of {cmd:stars} equal to 0 will have no symbols added.
The dimensions of {cmd:stars} (4x2) correspond to the dimensions of the
{cmd:statmat()} matrix, not the dimensions of the statistics in the
final table (8x1), which has a single statistics column because of the
{cmd:substat(1)} option.

{pstd}The option {cmd:varlabels} causes the variable labels for the
variables {cmd:mpg}, {cmd:length}, {cmd:weight}, and {cmd:headroom} to
be substituted for their names.

{phang2}{com}. frmttable using xmpl4, statmat(b_se) substat(1) sdec(3) annotate(stars) asymbol(*,**) varlabels{p_end}
	{res}
	{txt}{center:{hline 33}}
	{center:{txt}{lalign 16:}{txt}{center 15:Mileage (mpg)}}
	{txt}{center:{hline 33}}
	{center:{txt}{lalign 16:Length (in.)}{res}{center 15:-0.078}}
	{center:{txt}{lalign 16:}{res}{center 15:(0.057)}}
	{center:{txt}{lalign 16:Weight (lbs.)}{res}{center 15:-0.004}}
	{center:{txt}{lalign 16:}{res}{center 15:(0.002)*}}
	{center:{txt}{lalign 16:Headroom (in.)}{res}{center 15:-0.051}}
	{center:{txt}{lalign 16:}{res}{center 15:(0.555)}}
	{center:{txt}{lalign 16:Constant}{res}{center 15:47.841}}
	{center:{txt}{lalign 16:}{res}{center 15:(6.149)**}}
	{txt}{center:{hline 33}}
	

{pstd}The code above implements the most basic capabilities of 
{helpb outreg}, so the same table can more easily be created by

{phang2}{cmd:. outreg, se varlabels}


{marker xmpl5} 
{title:Example 5: Make a table of summary statistics and merge it with a regression table}

{pstd}First, we create a Stata matrix containing summary statistics for
four variables: {cmd:length}, {cmd:weight}, {cmd:headroom}, and
{cmd:mpg}.  The first column of the matrix {cmd:mean_sd} contains the
means of the variables, and the second column contains the standard
deviations.  The statistics are calculated by the {helpb summarize}
command, looping over the variables through the {helpb foreach} command.

	{com}. matrix mean_sd = J(4,2,.)
	{com}. local i = 1
	{com}. foreach v in length weight headroom mpg {c -(}
	  {com}2.         summarize `v' 
	  {com}3.         matrix mean_sd[`i',1] = r(mean)
	  {com}4.         matrix mean_sd[`i',2] = r(sd)
	  {com}5.         local i = `i' + 1
	  {com}6. {c )-}
	{txt}({it:output omitted})

	{com}. matrix rownames mean_sd = length weight headroom mpg
	{com}. matrix list mean_sd
	{res}
	{txt}mean_sd[4,2]
	                 c1         c2
	  length {res} 187.93243   22.26634
	{txt}  weight {res} 3019.4595  777.19357
	{txt}headroom {res} 2.9932432  .84599477
	{txt}     mpg {res} 21.297297  5.7855032{reset}

{pstd}We can create a formatted table with this matrix of statistics,
and we can also merge these statistics into any other table created by
{cmd:frmttable} (or by commands that call {cmd:frmttable}, such as
{cmd:outreg}).  The command below {cmd:merge}s the summary statistics
with the table of regression coefficients created in the previous
example.

{phang2}{com}. frmttable, statmat(mean_sd) substat(1) varlabels ctitles("", Summary statistics) merge{p_end}
	{res}{txt}(note: tables being merged have different numbers of row sections)

	{txt}{center:A Regression}
	{txt}{center:{hline 53}}
	{center:{txt}{lalign 16:}{txt}{center 15:Mileage (mpg)}{txt}{center 20:Summary statistics}}
	{txt}{center:{hline 53}}
	{center:{txt}{lalign 16:Length (in.)}{res}{center 15:-0.078}{res}{center 20:187.93}}
	{center:{txt}{lalign 16:}{res}{center 15:(0.057)}{res}{center 20:(22.27)}}
	{center:{txt}{lalign 16:Weight (lbs.)}{res}{center 15:-0.004}{res}{center 20:3,019.46}}
	{center:{txt}{lalign 16:}{res}{center 15:(0.002)*}{res}{center 20:(777.19)}}
	{center:{txt}{lalign 16:Headroom (in.)}{res}{center 15:-0.051}{res}{center 20:2.99}}
	{center:{txt}{lalign 16:}{res}{center 15:(0.555)}{res}{center 20:(0.85)}}
	{center:{txt}{lalign 16:Mileage (mpg)}{res}{center 15:}{res}{center 20:21.30}}
	{center:{txt}{lalign 16:}{res}{center 15:}{res}{center 20:(5.79)}}
	{center:{txt}{lalign 16:Constant}{res}{center 15:47.841}{res}{center 20:}}
	{center:{txt}{lalign 16:}{res}{center 15:(6.149)**}{res}{center 20:}}
	{center:{txt}{lalign 16:R2}{res}{center 15:0.66}{res}{center 20:}}
	{center:{txt}{lalign 16:N}{res}{center 15:74}{res}{center 20:}}
	{txt}{center:{hline 53}}
	{txt}{center:* p<0.05; ** p<0.01}{reset}
	
{pstd}This example shows how {cmd:frmttable} works, but a user can more
easily create a table like this with the following commands:

	{com}. regress mpg length weight headroom
	{com}. outreg, se varlabels
	{com}. mean length weight headroom mpg
	{com}. outreg, se varlabels merge{reset}
	
	
{marker xmpl6}{...}
{title:Example 6: Create complex tables using merge and append}

{pstd}If you use {cmd:frmttable} to handle the output from a new command
you write, users of your command can build quite complex tables by
repeatedly executing your command, along with {cmd:frmttable}'s 
{helpb frmt_opts##merge:merge} and {helpb frmt_opts##append:append}
options.  In this example, we use {helpb outreg} as an instance of a
{cmd:frmttable}-based command to build a table from parts.

{pstd}Let's say we want to create a table showing how a car's weight
affects its mileage.  We want the table to be broken down by foreign
versus domestic cars and by three categories of headroom.  It is easy
with a {cmd:frmttable}-based command such as {cmd:outreg} to create six
separate tables with all of these results.  It is also easy to create a
single table with six columns (or six rows) of coefficients by using
straightforward application of the {cmd:merge} (or {cmd:append}) option.

{pstd}It is more complicated to create a table with three columns of
foreign estimates above three columns of domestic estimates.  The
results for foreign cars must be merged across the headroom categories
into one table, and the results for the domestic cars must be merged
into a separate table.  The two tables must then be appended one below
the other.  Working with two separate {cmd:frmttable} tables
simultaneously requires the use of table names.

{pstd}The statistics for the table in this example are created in a
double {helpb foreach} loop, iterating first over foreign versus
domestic and then over three categories of headroom.  Using data from
{cmd:auto.dta}, we first recode the variable {cmd:headroom} into a new
variable, {cmd:hroom}, with just three levels.

	{com}. sysuse auto, clear
	{txt}(1978 Automobile Data)

	{com}. recode headroom (1.5=2) (3.5/5=3), gen(hroom)
	{txt}(34 differences between headroom and hroom)

{pstd}Type in the following {cmd:outreg, clear} commands, which will be
explained in just a moment:

	{com}. outreg, clear(row1)
	{com}. outreg, clear(row2){reset}

{pstd}The heart of the table building occurs with a double {cmd:foreach}
loop, iterating over {cmd:foreign} and {cmd:hroom} values.  We estimate
the correlation of {cmd:mpg} with {cmd:weight} by using the 
{helpb regress} command for each category in the double loop.  The
formatted table is built up by using the {cmd:outreg, merge} command
repeatedly.

	{com}. foreach f in 0 1 {c -(}
          {com}2.     foreach h in 2 2.5 3 {c -(}
	  {com}3.        regress mpg weight if foreign==`f' & hroom==`h'
	  {com}4.        outreg, nocons noautosumm merge(row`f')
 	  {com}5.     {c )-}
	  {com}6.  {c )-}
	{txt}({it:output omitted})

{pstd}The {helpb outreg} command has options 
{helpb outreg_complete##nocons:nocons} to suppress the constant
coefficient and {helpb outreg_complete##noautosumm:noautosumm} to
suppress R-squared and the number of observations.  The
{cmd:merge(row`f')} option is the interesting part.  This merges the
coefficients into two separate tables, named {cmd:row0} and {cmd:row1},
each of which contains three columns of estimates for the categories of
{cmd:hroom}.

{pstd}The first time the {cmd:merge} option is invoked for each table,
we want it to create the first column, basically, to merge the results
into a table that does not yet exist.  The {cmd:merge} option allows
merging into a nonexistent table for convenience in loops like this.
However, to make this work, it is important to clear out any preexisting
table of the same name.  Particularly, we want to clear out the table
from the previous time we ran the same do-file.  Otherwise, the table
would get larger and larger each time the do-file is run.  That is the
reason for the two {cmd:outreg, clear} commands just before the loop.
An alternative to the {cmd:outreg, clear} command, especially if one
needs to clear many {cmd:frmttable} tables, is 
{helpb mata clear:mata:  mata clear}, which clears all Mata memory
structures, including tables.

{pstd}Now that the tables for each row are created, we want to append
them one below the other.  We do this with a combination of the 
{helpb frmt_opts##replay:replay} and {helpb frmt_opts##append:append}
options.  The {cmd:replay(row0)} option displays the named table (and
can write it to a word processing document if {cmd:using} {it:filename}
is specified).  The {cmd:append(row1)} option appends the table
{cmd:row1}, containing the second row, below the {cmd:row0} results.
The rest of the {cmd:outreg} command below adds titles to the final
table.  The combined table now has the table name {cmd:row0}.

{phang2}{com}. outreg, replay(row0) append(row1) replace rtitle(Domestic \ "" \ Foreign) ctitle("", "", "Headroom", "" \ "Origin", "<=2.0", "2.5", ">=3.0") title(Effect of weight on MPG by origin and headroom){p_end}
	{res}
	{txt}{center:Effect of weight on MPG by origin and headroom}
	{txt}{center:{hline 43}}
	{center:{txt}{lalign 11:}{txt}{center 10:}{txt}{center 10:Headroom}{txt}{center 10:}}
	{center:{txt}{lalign 11:Origin}{txt}{center 10:<=2.0}{txt}{center 10:2.5}{txt}{center 10:>=3.0}}
	{txt}{center:{hline 43}}
	{center:{txt}{lalign 11:Domestic }{res}{center 10:-0.006}{res}{center 10:-0.007}{res}{center 10:-0.005}}
	{center:{txt}{lalign 11:}{res}{center 10:(3.62)**}{res}{center 10:(7.63)*}{res}{center 10:(8.00)**}}
	{center:{txt}{lalign 11:Foreign}{res}{center 10:-0.018}{res}{center 10:-0.008}{res}{center 10:-0.011}}
	{center:{txt}{lalign 11:}{res}{center 10:(1.87)}{res}{center 10:(2.14)}{res}{center 10:(2.64)*}}
	{txt}{center:{hline 43}}
	
{pstd}This example shows how elaborate tables can be created by
combining smaller parts by using the {cmd:merge} and {cmd:append}
options and table names.  Other useful options for this purpose are
{cmd:addrows()} and {cmd:addcols()}, which add columns of text (which
may include numbers) rather than statistics from Stata matrices.{p_end}

{marker xmpl7}{...}
{title:Example 7: Double statistics}

{pstd}Double statistics are statistics showing two numbers, such as a
minimum-maximum range or a confidence interval.  {cmd:frmttable} has the
{cmd:doubles()} option to make it easy to display double statistics.
The lower and upper values of double statistics are held in neighboring
columns of {cmd:statmat()}, and the {cmd:doubles()} option indicates
which columns are the second numbers of double statistics.
{cmd:frmttable} automatically combines the two numbers into a single
cell of the formatted table, with a dash between them.

{pstd}The following code creates a Stata matrix, {cmd:conf_int},
containing the mean of several variables in the first column and the
lower and upper confidence intervals in the second and third columns,
respectively.  The details are similar to 
{help frmttable##xmpl5:Example 5} above.

	{com}. matrix conf_int = J(4,3,.)
	{com}. local i = 1
	{com}. foreach v in length weight headroom mpg {c -(}
	{com}  2.     summarize `v' 
	{com}  3.     matrix conf_int[`i',1] = r(mean)
	{com}  4.     matrix conf_int[`i',2] = r(mean) - invttail(r(N)-1,0.05/2)*sqrt(r(Var)/r(N))
	{com}  5.     matrix conf_int[`i',3] = r(mean) + invttail(r(N)-1,0.05/2)*sqrt(r(Var)/r(N))
	{com}  6.     local i = `i' + 1
	{com}  7.  {c )-}
	{txt}({it:output omitted})

	{com}. matrix rownames conf_int = length weight headroom mpg
	{com}. matrix li conf_int

	{txt}conf_int[4,3]
	                 c1         c2         c3
	  length {res} 187.93243  182.77374  193.09113
	{txt}  weight {res} 3019.4595  2839.3983  3199.5206
	{txt}headroom {res} 2.9932432  2.7972422  3.1892443
	{txt}     mpg {res} 21.297297  19.956905   22.63769{reset}

{pstd}For {cmd:frmttable} to display double statistics, it requires a
row vector indicating which columns contain the second numbers of double
statistics.  In this example, there are second values of a double
statistic in column 3, so the third element of the {cmd:doubles()}
option matrix {cmd:dcols} is set to 1.  The {cmd:doubles(dcols)} option
causes the numbers in the second and third columns of {cmd:conf_int}
(the lower and upper confidence limits) to be combined in the final
table.

	{com}. matrix dcols = (0,0,1)
{phang2}{com}. frmttable, statmat(conf_int) substat(1) doubles(dcols) varlabels ctitles("",Summary statistics) sdec(0 \ 0 \ 0 \ 0 \ 2 \ 2 \ 1 \ 1){p_end}
	{res}
	{txt}{center:{hline 38}}
	{center:{txt}{lalign 16:}{txt}{center 20:Summary statistics}}
	{txt}{center:{hline 38}}
	{center:{txt}{lalign 16:Length (in.)}{res}{center 20:188}}
	{center:{txt}{lalign 16:}{res}{center 20:(183 - 193)}}
	{center:{txt}{lalign 16:Weight (lbs.)}{res}{center 20:3,019}}
	{center:{txt}{lalign 16:}{res}{center 20:(2,839 - 3,200)}}
	{center:{txt}{lalign 16:Headroom (in.)}{res}{center 20:2.99}}
	{center:{txt}{lalign 16:}{res}{center 20:(2.80 - 3.19)}}
	{center:{txt}{lalign 16:Mileage (mpg)}{res}{center 20:21.3}}
	{center:{txt}{lalign 16:}{res}{center 20:(20.0 - 22.6)}}
	{txt}{center:{hline 38}}

{pstd}There is only one substatistic in {cmd:substat(1)} because the
second statistic is a double statistic.

{pstd}Confidence intervals have been integrated into the {cmd:outreg}
command, making use of {cmd:frmttable}'s {cmd:doubles()} option, so the
particular table in this example is easily created with the following
commands:

{phang2}{com}. mean length weight headroom mpg{p_end}
{phang2}{com}. outreg, stats(b,ci) nostars varlabels ctitles("", Summary statistics) bdec(0 0 2 1){reset}


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

{p 7 14 2}Help:  {helpb outreg}, {helpb outtable} (if installed){p_end}
