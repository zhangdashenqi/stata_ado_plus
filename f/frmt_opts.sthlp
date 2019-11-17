{smcl}
{* *! version 4.08  05jan2011}{...}
{cmd:help frmt_opts}{right: ({browse "http://www.stata-journal.com/article.html?article=sg97_5":SJ12-4: sg97_5})}
{hline}

{marker text_add_opts}{...}

{synoptset 24}{...}
{p2col:{help frmt_opts##text_additions:Text additions}}Description{p_end}
{p2line}
{p2col:{cmdab:va:rlabels}}use variable labels as {cmd:rtitles()}{p_end}
{p2col:{cmdab:t:itle(}{it:textcolumn}{cmd:)}}put title above table{p_end}
{p2col:{cmdab:ct:itles(}{it:textgrid}{cmd:)}}put headings at top of columns{p_end}
{p2col:{cmdab:rt:itles(}{it:textgrid}{cmd:)}}put headings to the left of each row{p_end}
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
{p2line}
{marker col_form_opts}{...}

{synoptset 37}{...}
{p2col:{help frmt_opts##col_formats:Column formatting}}Description{p_end}
{p2line}
{p2col:{cmdab:colw:idth(}{it:numlist}{cmd:)}*}change column widths{p_end}
{p2col:{cmdab:mu:lticol(}{it:numtriple}[{cmd:;} {it:numtriple} ...]{cmd:)}}make column titles span multiple columns{p_end}
{p2col:{cmdab:colj:ust(}{it:cjstring}[{cmd:;} {it:cjstring} ...]{cmd:)}}column-justification: left, center, right, or decimal{p_end}
{p2col:{cmdab:noce:nter}}do not center table within page{p_end}
{p2line}
{syntab:* Word-only option}
{marker font_opts}{...}

{synoptset 35}{...}
{p2col:{help frmt_opts##fonts:Font specification}}Description{p_end}
{p2line}
{p2col:{cmdab:ba:sefont(}{it:fontlist}{cmd:)}}change the base font for all text{p_end}
{p2col:{cmdab:titlf:ont(}{it:fontcolumn}{cmd:)}}change font for table title{p_end}
{p2col:{cmdab:notef:ont(}{it:fontcolumn}{cmd:)}}change font for notes below table{p_end}
{p2col:{cmdab:ctitlf:ont(}{it:fontgrid}[{cmd:;} {it:fontgrid} ...]{cmd:)}}change font for column titles{p_end}
{p2col:{cmdab:rtitlf:ont(}{it:fontgrid}[{cmd:;} {it:fontgrid} ...]{cmd:)}}change font for row titles{p_end}
{p2col:{cmdab:statf:ont(}{it:fontgrid}[{cmd:;} {it:fontgrid} ...]{cmd:)}}change font for statistics in body of table{p_end}
{p2col:{cmdab:addf:ont(}{it:fontname}{cmd:)}*}add new font type{p_end}
{p2col:{cmdab:p:lain}}plain text -- one font size, no justification{p_end}
{p2col:{it:table_sections}}explanation of formatted table sections{p_end}
{p2line}
{syntab:* Word-only option}
{marker lines_spaces_opts}{...}

{synoptset 40}{...}
{p2col:{help frmt_opts##lines_spaces:Border lines and spacing}}Description{p_end}
{p2line}
{p2col:{cmdab:hl:ines(}{it:linestring}[{cmd:;} {it:linestring} ...]{cmd:)}}horizontal lines between rows{p_end}
{p2col:{cmdab:vl:ines(}{it:linestring}[{cmd:;} {it:linestring} ...]{cmd:)}}vertical lines between columns{p_end}
{p2col:{cmdab:hls:tyle(}{it:lstylelist}[{cmd:;} {it:lstylelist} ...]{cmd:)}*}change style of
horizontal lines{p_end}
{p2col:{cmdab:vls:tyle(}{it:lstylelist}[{cmd:;} {it:lstylelist} ...]{cmd:)}*}change style of
vertical lines{p_end}
{p2col:{cmdab:spaceb:ef(}{it:spacestring}[{cmd:;} {it:spacestring} ...]{cmd:)}}put space above cell contents{p_end}
{p2col:{cmdab:spacea:ft(}{it:spacestring}[{cmd:;} {it:spacestring} ...]{cmd:)}}put space below cell contents{p_end}
{p2col:{cmdab:spaceh:t(}{it:#}{cmd:)}}change size of {cmd:spacebef()} and {cmd:spaceaft()}{p_end}
{p2line}
{syntab:* Word-only option}
{marker page_fmt_opts}{...}

{synoptset 19}{...}
{p2col:{help frmt_opts##page_fmt:Page formatting}}Description{p_end}
{p2line}
{p2col:{cmdab:la:ndscape}}use landscape orientation{p_end}
{p2col:{cmd:a4}}use A4-size paper (instead of 8 1/2" x 11"){p_end}
{p2line}
{marker file_opts}{...}

{synoptset 27}{...}
{p2col:{help frmt_opts##file_options:File and display options}}Description{p_end}
{p2line}
{p2col:{cmd:tex}}write a TeX file instead of the default Word file{p_end}
{p2col:{cmdab:m:erge}[{cmd:(}{it:tblname}{cmd:)}]}merge as new columns to existing table{p_end}
{p2col:{cmd:replace}}replace existing file{p_end}
{p2col:{cmdab:addt:able}}write a new table below an existing table{p_end}
{p2col:{cmdab:ap:pend}[{cmd:(}{it:tblname}{cmd:)}]}append as new rows below an existing table{p_end}
{p2col:{cmdab:re:play}[{cmd:(}{it:tblname}{cmd:)}]}write preexisting table{p_end}
{p2col:{cmdab:sto:re(}{it:tblname}{cmd:)}}store table with name {it:tblname}{p_end}
{p2col:{cmdab:cl:ear}[{cmd:(}{it:tblname}{cmd:)}]}clear existing table from memory{p_end}
{p2col:{cmdab:fr:agment}**}create TeX code fragment to insert into TeX document{p_end}
{p2col:{cmdab:nod:isplay}}do not display table in results window{p_end}
{p2col:{cmdab:dw:ide}}display all columns, however wide{p_end}
{p2line}
{syntab:** TeX-only option}
{marker brack_opts}{...}

{synoptset 34}{...}
{p2col:{help frmt_opts##brack_options:Brackets options}}Description{p_end}
{p2line}
{p2col:{cmdab:sq:uarebrack}}use square brackets instead of parentheses{p_end}
{p2col:{cmdab:br:ackets(}{it:textpair} [{cmd:\} {it:textpair} ...]{cmd:)}}specify symbols with which to bracket substatistics{p_end}
{p2col:{cmdab:nobrk:et}}put no brackets on substatistics{p_end}
{p2col:{cmdab:dbl:div(}{it:text}{cmd:)}}specify symbol dividing double
statistics; default is {cmd:dbldiv(-)}{p_end}
{p2line}

{pstd}
{it:{help frmt_opts##greek:Inline text formatting: Superscripts, italics, Greek characters, etc.}}{p_end}


{title:Options}

{marker text_additions}{...}
{dlgtab:Text additions}
{marker varlabels}{...}

{phang}{cmd:varlabels} replaces variable names with 
{help label:variable labels} in row and column titles if the variable
labels exist.  For example, if using {cmd:auto.dta}, {opt varlabel}
gives a coefficient for the {opt mpg} variable the row title
{cmd:Mileage (mpg)} instead of {cmd:mpg}.  {cmd:varlabels} also replaces
{cmd:_cons} with {cmd:Constant} for constant coefficients.

{phang}{it:{ul:Text structures used for titles}}{p_end}

{marker textcolumn}{...}
{phang2}{it:textcolumn} is "{it:string}" [{cmd:\} "{it:string}"
...]{p_end}

{marker textrow}{...}
{phang2}{it:textrow} is "{it:string}"[{cmd:,} "{it:string}" ...]{p_end}

{marker textgrid}{...}
{phang2}{it:textgrid} is "{it:string}"[{cmd:,} "{it:string}" ...]
[{cmd:\} "{it:string}"[{cmd:,} "{it:string}" ...] [{cmd:\} [...]]] or a
{it:textrow} or a {it:textcolumn} as a special case{p_end}

{phang2}"{it:string}" ["{it:string}" ...] will often work in place of a
{it:textrow} or a {it:textcolumn} when the user's intent is clear, but
if in doubt, use the proper {it:textrow} or {it:textcolumn} syntax
above.

{marker title}{...}
{phang}{cmd:title(}{it:{help frmt_opts##textcolumn:textcolumn}}{cmd:)}
specifies a title or titles above the table.  Subtitles should be
separated from the primary titles by backslashes, like this:
{cmd:title("Main title" \ "First subtitle" \ "Second subtitle")}.  By
default, titles are set in a larger font than the body of the table.  If
title text does not contain backslashes, you can dispense with the
quotation marks, but if in doubt, include them.

{marker ctitles}{...}
{phang}{cmd:ctitles(}{it:{help frmt_opts##textgrid:textgrid}}{cmd:)}
specifies the column titles above the statistics.  A simple form of
{cmd:ctitles()} is, for example, 
{cmd:ctitles("Variables", "First Regression")}.  If there is a column of
row titles, the first title in {cmd:ctitles()} goes above this column
and the second title goes above the first statistics column.  If you
want no heading above the row titles column, specify, for example,
{cmd:ctitles("", "First Regression")}.

{pmore}Fancier titles in {cmd:ctitles()} can have multiple rows.  These
are specified as a {it:textgrid}.  For example, to put a number above
the column title for the estimation method using {helpb outreg} (in
preparation for merging additional estimation results), one could use
{cmd:ctitles("", "Regression 1" \ "Independent Variables", "OLS")}.  The
table would now have a first column title of {cmd:Regression 1} above
the coefficients estimates and a second column title of {cmd:OLS} in the
row below.

{pmore}See {help outreg_complete##xmpl10:example 10} in {helpb outreg}
for an application of multirow {cmd:ctitles()}.

{pmore}The option {helpb frmt_opts##nocoltitl:nocoltitl} removes even
the default column titles.

{marker rtitles}{...}
{phang}{cmd:rtitles(}{it:textgrid}{cmd:)} fills the leftmost column of
the table with new row titles for the statistics.  In {cmd:outreg}, the
default row titles (with no {cmd:rtitles()} option) are variable names.
Multiple titles for the leftmost column in {cmd:rtitles()} should be
separated by a backslash ({cmd:\}) because they are placed below one
another (if the titles are separated with commas, they will all be
placed in the first row of the estimates).  An example of
{cmd:rtitles()} in {helpb outreg} is 
{cmd:rtitles("Variable 1" \ "" \ "Variable 2" \ "" \ "Constant")}.  The
empty titles are to account for the t statistics below the coefficients.

{pmore}Multicolumn {cmd:rtitles()} are possible and will be merged
correctly with other estimation results.  Multicolumn {cmd:rtitles()}
occur by default, without a specified {cmd:rtitles()}, after
multiequation estimations, where the first {cmd:rtitles()} column is the
equation name, and the second {cmd:rtitles()} column is the variable
name within the equation.  See the second part of 
{help outreg_complete##xmpl6:example 6} in {helpb outreg} for a table
showing this.

{pmore}The option {helpb frmt_opts##norowtitl:norowtitl} removes even
the default row titles.

{marker note}{...}
{phang}{cmd:note(}{it:{help frmt_opts##textcolumn:textcolumn}}{cmd:)}
specifies a note to be displayed below the formatted table.  Multiple
lines of a note should be separated by backslashes, like this:
{cmd:note("First note line." \ "Second note line." \ "Third note line.")}.
Notes are centered immediately below the table.  By default, they are
set in a smaller font than the body of the table.  Empty note lines
({cmd:""}) are permitted if you want to insert space between
{cmd:note()} rows.

{marker pretext}{...}
{phang}{cmd:pretext(}{it:textcolumn}{cmd:)} places regular text before
the table.

{marker posttext}{...}
{phang}{cmd:posttext(}{it:textcolumn}{cmd:)} places regular text after
the table.

{pmore}{opt pretext()} and {opt posttext()} contain regular paragraphs
of text to be placed before or after the formatted table in the document
created.  This allows a document to be created with regular paragraphs
between the tables.  The default font is applied but can be changed with
the {helpb frmt_opts##basefont:basefont()} option.  Text is
left-justified and spans the whole page.

{pmore}Multiple paragraphs can be separated by the backslash character,
for example, {cmd:pretext("Paragraph 1" \ "Paragraph 2")}.

{pmore}When creating a Word document, you can create blank lines by
inserting empy paragraphs, like this: 
{cmd:posttext("" \ "" \ "This is text")}. If this command were used, the
Word document would display two blank lines before the paragraph
{cmd:This is text}.

{pmore}For Word documents, you can also use the code {cmd:\line} to
insert blank lines.  You can insert page breaks between tables with the
Word code {cmd:\page} in {cmd:pretext()}; this is useful when placing
multiple tables within one document with the 
{helpb frmt_opts##addtable:addtable} option.  The page break or line
break codes can be used within a text string, but they must have a space
between the code and the subsequent text, for example,
{cmd:pretext("\page\line This is text")}.  Without the space, in
{cmd:pretext("\page\lineThis is text")}, Word would try to interpret the
code {cmd:\lineThis}, which is not defined.

{pmore}When creating a TeX document (using option 
{helpb frmt_opts##tex:tex}), you can insert blank lines by using the
code {cmd:\bigskip} (the trick used above of inserting blank paragraphs
does not work in TeX files).  You can insert page breaks between tables
with the code {cmd:\pagebreak}, which is useful with the {cmd:addtable}
option to put each table on a separate page.  The page break or line
break codes must be in separate rows from text, for example,
{cmd:pretext("\pagebreak\bigskip" \ "This is text")}.

{marker nocoltitl}{...}
{phang}{opt nocoltitl} ensures that there are no column titles -- the
default column titles are not used.  To replace the column headings
instead of eliminate them, use {helpb frmt_opts##ctitles:ctitles()}.

{marker norowtitl}{...}
{phang}{opt norowtitl} ensures that there are no row titles -- the
default row titles are not used.  To replace the row headings instead of
eliminate them, use {helpb frmt_opts##rtitles:rtitles()}.

{marker addrows}{...}
{phang}{cmd:addrows(}{it:{help frmt_opts##textgrid:textgrid}}{cmd:)}
adds rows of text to the bottom of the table (above the notes).  All
elements of the rows must be converted from numbers to text before being
included in the {it:textgrid}.  For example, to include the test results
of coefficient equality, you could use 
{cmd:addrows("t test of b1=b2", "`ttest' **")}, where {cmd:ttest} is the
name of a {help macro:local macro} with the value of the t test of
coefficient equality.  The asterisks are included because the t test was
significant at the 5% level.

{pmore}See {help outreg_complete##xmpl7:example 7} in {helpb outreg} for
an application of {cmd:addrows()}.

{marker addrtc}{...}
{phang}{opt addrtc(#)} is a rarely used option to specify the number of
{cmd:rtitles()} columns in {cmd:addrows()}.  It is only needed when
either {cmd:rtitles()} or {cmd:addrows()} has more than one column to
ensure that the row titles are lined up correctly vis-a-vis the data.
The default is {cmd:addrtc(1)}.

{marker addcols}{...}
{phang}{cmd:addcols(}{it:textgrid}{cmd:)} adds columns to the right of
the table.  The contents of the new columns are not merged -- it is the
user's responsibility to ensure that the new columns line up in the
appropriate way.

{marker annotate}{...}
{phang}{opt annotate(matname)} passes a matrix of annotation locations.

{marker asymbol}{...}
{phang}{cmd:asymbol(}{it:{help frmt_opts##textrow:textrow}{cmd:)}}
provides symbols for each annotation location in {cmd:annotate()}.

{pmore}{opt annotate()} and {opt asymbol()} (always specified together)
are useful for placing footnotes or other annotations next to statistics
in the formatted table, but they are not the most user friendly.
(Footnotes or annotations in any of the title regions, including row and
column titles, can be included directly in the title text with options
such as {helpb frmt_opts##rtitles:rtitles()} and 
{helpb frmt_opts##ctitles:ctitles()}.)

{pmore}The values in {cmd:annotate()} range from 0 to the number of
symbols in {opt asymbol()}.  In the case of {helpb outreg}, the
dimensions of the matrix in {cmd:annotate()} have rows equal to the
number of coefficients in the estimation and columns equal to the number
of statistics displayed (two, by default).  Whenever the
{cmd:annotate()} matrix has a value of 0, no symbol is appended to the
statistic in the corresponding cell of the table.  Where the
{cmd:annotate()} matrix has a value of 1, the first {cmd:asymbol()}
symbol is added to the left of the statistic; where there is a value of
2, the second symbol is added, etc.

{pmore}The {it:textrow} in {opt asymbol()} has the syntax
"{it:text}"[{cmd:,} "{it:text}" [...]].  If you want to have a space
between the statistic in the table and the {cmd:asymbol()} {it:text},
make sure to include it in the {it:text}, for example, 
{cmd:asymbol(" 1", " 2")}.  Superscripts for the symbols in a Word file
can be included as follows: enclose the symbol with curly brackets and
prepend the superscript code {cmd:\super}.  So for a superscript 1, the
{it:text} in {cmd:asymbol()} would be {cmd:"{\super 1}"}.  Make sure to
include the space after {cmd:\super}.  For TeX files, 1 can be
superscripted with either {cmd:"$^1$"} or {cmd:"\textsuperscript{1}"}.
See the discussion about {help frmt_opts##greek:inline formatting}.

{pmore}To understand the correspondence between the locations in the
{cmd:annotate()} matrix and the final formatted table, you should know
how the {cmd:frmttable} program (called by {helpb outreg} and other
programs) creates tables.  In the case of {cmd:outreg}, it sends the
different estimation statistics in separate columns.  So for the default
statistics of {cmd:b} and {cmd:t_abs}, {cmd:outreg} sends a Kx2 matrix
to {cmd:frmttable}, where K is the number of coefficients.  The nonzero
locations of {cmd:annotate()} indicate that a symbol should be added to
correspond to the locations of the Kx2 matrix passed to {cmd:frmttable},
not to the 2Kx1 table of statistics created by {cmd:frmttable}.  Perhaps
a simpler way of saying this is that {cmd:annotate()} positions
correspond to the final table positions when you use the 
{helpb frmttable##substat:substat()} option.  If there are S statistics
(two by default), the {cmd:annotate()} matrix should be a KxS Stata
matrix, where K is the number of columns in {cmd:e(b)}.  This can be
created in Stata for a regression with five coefficients and the default
of two statistics like this:

{pmore2}{cmd}. matrix annotmat = J(5,2,0){p_end}
{pmore2}{cmd}. matrix annotmat[1,1] = 1{p_end}
{pmore2}{cmd}. matrix annotmat[3,2] = 2{p_end}
{pmore2}{cmd}. outreg ... , annotate(annotmat) asymbol(" (1)", " (2)"){p_end}{txt}{...}

{pmore}This will assign the first {cmd:asymbol(" (1)")} to the first
coefficient and the second {cmd:asymbol(" (2)")} to the third t
statistic.

{pmore}In fact, the {cmd:annotate()} matrix can be smaller than KxS if
there are rows at the bottom of the table or columns to the right of the
table that do not need any symbols.  In other words, if the
{cmd:annotate()} matrix is not the same size as the statistics, then the
missing, or too large, parts of it are ignored.

{pmore}If {cmd:annotate()} and {cmd:asymbol()} are used to create
footnote references, the footnotes themselves can be included in the
{helpb frmt_opts##note:note()} option.

{pmore}See {help outreg_complete##xmpl14:example 14} in {helpb outreg}
for an application of {cmd:annotate()} and {cmd:asymbol()}.

{marker col_formats}{...}
{dlgtab:Column formatting}

{marker colwidth}{...}
{phang}{cmd:colwidth(}{it:{help numlist}}{cmd:)} assigns column widths.
By default, the program makes its best guess of the appropriate column
width, but Word Rich Text Format (RTF) files, unlike TeX files, have no
algorithm to ensure that the column width exactly fits the maximum width
of the contents of its cells.  In particular, when special nonprinting
formatting codes (such as superscript codes) are included in
{cmd:ctitles()} and {cmd:rtitles()}, the program will probably get the
width wrong, and {cmd:colwidth()} will be needed.  This option is only
allowed for Word files, because TeX files automatically determine column
widths.

{pmore}If {cmd:colwidth()} has fewer widths than the number of columns,
the program will guess the best width for the remaining columns.
Specifying {cmd:colwidth(10:)} will assign a width of 10 characters to
the first column in the table but not change the width of other columns.
To assign a width of 10 to all columns in a five-column table, use
{cmd:colwidth(10 10 10 10 10)}.  The width of the column using
{cmd:colwidth(1)} is equal to the width of one "n" of the currently
assigned point size, with the addition of the default buffers on either
side of the cell.

{marker multicol}{...}
{phang}{cmd:multicol(}{it:{help frmt_opts##numtriple:numtriple}}[{cmd:;}
{it:numtriple} ...]{cmd:)} combines table cells into one cell that spans
multiple columns.  This is mainly used for column titles that apply to
more than one column.

{marker numtriple}{...}
{pmore}A {it:numtriple} means three numbers separated by commas.  Each
{it:numtriple} consist of the row of the first cell to be combined, the
column of the first cell, and the number of cells to be combined (>=2).

{pmore}For example, to combine the heading for the first two statistics
columns in a table (with only one {helpb frmt_opts##rtitles:rtitles()}
column), the option would be {cmd:multicol(1,2,2)}.  That is, the
combined cells start in the first row of the table (below the title) and
the second column of the table (the start of the statistics columns),
and two cells are to be combined.  See an example of this in 
{help outreg_complete##xmpl10:example 10} in {helpb outreg}.

{pmore}It often looks good to underline the 
{helpb frmt_opts##ctitles:ctitles()} in the combined cell to make clear
that the column title applies to both columns below it.  In Word RTF
files, underlining does not apply to blank spaces, so to extend the
underline to either side of the text in the {cmd:ctitles()}, you can
insert tab characters, which will be underlined.  For example, for the
{cmd:ctitles()} text {cmd:First 2}, you could apply codes for
underlining and tabs like this: 
{cmd:ctitle("", "\ul\tab First 2\tab\tab")}.  Note the obligatory space
between RTF code ({cmd:\tab}) and the text.  Underscore characters
({cmd:_}) can also be used to extend underlining where there is no text,
although they create a line that is slightly lower than the underlining
line.

{marker coljust}{...}
{phang}{cmd:coljust(}{it:{help frmt_opts##cjstring:cjstring}}[{cmd:;}
{it:cjstring} ...]{cmd:)} specifies whether the table columns are left-,
center-, or right-justified (that is, the text in each row is flush with
the left, center, or right side of the column) or centered on the
decimal point (for Word files only).  By default for Word files, the
{helpb frmt_opts##rtitles:rtitles()} columns are left-justified, and the
rest of the columns are decimal-justified.  For TeX files,
{cmd:rtitles()} columns are left-justified, and the rest of the columns
are center-justified.

{marker cjstring}{...}
{pmore}{it:cjstring} is a string made up of

{p2colset 11 22 22 15}{...}
{p2col:{it:cjstring}}Action{p_end}
{p2line}
{p2col:{opt l}}left-justification{p_end}
{p2col:{opt c}}center-justification{p_end}
{p2col:{opt r}}right-justification{p_end}
{p2col:{opt .}}decimal-justification (Word only){p_end}
{p2col:{cmd:{}}}repetition{p_end}
{p2line}

{pmore}Left-, center-, and right-justification are self-explanatory, but
decimal-justification requires some elaboration.  Decimal-justification
lines up all the numbers in the column so that the decimal points are in
a vertical line.  Whole numbers are justified to the left of the decimal
point.  Text in {helpb frmt_opts##ctitles:ctitles()} is not
decimal-justified -- otherwise, all the {cmd:ctitles()} for the column
would be to the left of the decimal point, like whole numbers.  Instead,
in columns with decimal-justification, {cmd:ctitles()} are
center-justified.

{pmore}Decimal-justification works with comma decimal points used in
many European languages (to set comma decimal points in Stata, see
{helpb format:set dp comma}).  However, Microsoft Word will recognize
the comma decimal points correctly only if the operating system has been
changed to specify comma decimal points.  In the Windows operating
system, this can be done in the Control Panel under Regional and
Language Options.  In the OS X operating system, this can be done in
System Preferences under Language and Text: Formats.

{pmore}Each letter in {it:cjstring} indicates the column-justification
for one column.  For example, {cmd:coljust(lccr)} left-justifies the
first column, center-justifies the second and third columns, and
right-justifies the fourth column.  If there are more than four columns,
the remaining columns will be right-justified because the last element
in the string is applied repeatedly.  If there are fewer than four
columns, the extra justification characters are ignored.

{pmore}The curly brackets {cmd:{}} repeat the middle of {it:cjstring}.
For example, {cmd:coljust(l{c}rr)} left-justifies the first column,
center-justifies all the subsequent columns up to the next-to-last
column, and right-justifies the last two columns.

{pmore}The semicolon applies column-justification to separate 
{help frmt_opts##table_sections:sections} of the formatted table but is
not needed by most users.  Formatted tables have two column sections:
the columns of {helpb frmt_opts##rtitles:rtitles()} (typically one
column) and the columns of statistics.

{pmore}The section divider allows you to specify the
column-justification without knowing how many columns are in each
section.  Hence, the default {cmd:coljust()} parameters for Word files
are {cmd:coljust(l;.)}, which applies left-justification to all the
columns in the first ({cmd:rtitles()}) section of the table and
decimal-justification to the remaining column sections of the table.

{pmore}For example, {cmd:coljust(l{c}r;r{c}l)} would apply {cmd:l{c}r}
only to the first column section and would apply {cmd:r{c}l} to the
second column section (or other column sections).

{pmore}Technical note: TeX has the capability for decimal-justification
through the {cmd:dcolumn} package or the {cmd:coljust({r@{.}l})}
column-justification syntax.  However, both of these methods conflict
with other capabilities of formatted tables in ways that make them very
difficult to implement.  The {cmd:dcolumn} package imposes math mode for
the decimal-justified columns, which is inconsistent with the default
formatting, and also interferes with the {cmd:multicol()} option.  The
{cmd:coljust({r@{.}l})} syntax splits the column in question into two
columns, which would require work-arounds for many options.  Users who
do not care to have their t statistics displayed in a smaller font than
the coefficient estimations (the default) can modify their TeX tables
manually to implement decimal-justification through the {cmd:dcolumn}
package.

{marker nocenter}{...}
{phang}{cmd:nocenter} requests that the formatted table not be centered
within the document page.  This does not apply to the display of the
table in the Stata Results window, which is always centered.

{marker fonts}{...}
{dlgtab:Font specification}

{marker basefont}{...}
{phang}{cmd:basefont(}{it:{help frmt_opts##fontlist:fontlist}}{cmd:)}
changes the base font for all text in the formatted table, as well as
{helpb frmt_opts##pretext:pretext()} and 
{helpb frmt_opts##posttext:posttext()}.  The default font specification
is 12-point Times New Roman for Word documents and is left unspecified
for TeX documents (which normally means it is 10-point Times New Roman).

{marker fontlist}{...}
{pmore}The {it:fontlist} is made up of elements in the tables below
(different for {help frmt_opts##fontlist_word:Word} and 
{help frmt_opts##fontlist_tex:TeX} files), separated by spaces.  The
elements of the {it:fontlist} can specify font size, font type (for
example, Times New Roman, Arial, or a new font from 
{helpb frmt_opts##addfont:addfont()}), and font style (such as italic or
bold).

{pmore}If you specify more than one font type ({cmd:roman}, {cmd:arial},
{cmd:courier}, and perhaps {cmd:fnew}{it:#}), only the last choice in
the {it:fontlist} will be in effect.

{pmore}See {help outreg_complete##xmpl11:example 11} in {helpb outreg}
for an application of {cmd:basefont()}.

{marker fontlist_word}{...}
{pmore}
A {it:fontlist} for Word files can comprise the following:

{p2colset 11 23 27 10}{...}
{p2col:{it:fontlist}}Action{p_end}
{p2line}
{p2col:{cmd:fs}{it:#}}font size in points{p_end}
{p2col:{cmd:arial}}Arial font{p_end}
{p2col:{cmd:roman}}Times New Roman font{p_end}
{p2col:{cmd:courier}}Courier New font{p_end}
{p2col:{cmd:fnew}{it:#}}font specified in {cmd:addfont()}{p_end}
{p2col:{cmd:plain}}no special font effects{p_end}
{p2col:{cmd:b}}make text bold{p_end}
{p2col:{cmd:i}}italicize text{p_end}
{p2col:{cmd:scaps}}small caps{p_end}
{p2col:{cmd:ul}}underline text{p_end}
{p2col:{cmd:uldb}}underline text with a double line{p_end}
{p2col:{cmd:ulw}}underline words only (not spaces between words){p_end}
{p2line}

{marker fontlist_tex}{...}
{pmore}
A {it:fontlist} for TeX files can comprise the following:

{p2colset 11 25 27 10}{...}
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
{p2col:{cmd:it}}italicize text{p_end}
{p2col:{cmd:bf}}make text bold{p_end}
{p2col:{cmd:em}}emphasize text (same as {cmd:bf}){p_end}
{p2col:{cmd:sl}}slant text{p_end}
{p2col:{cmd:sf}}use sans-serif font, that is, Arial{p_end}
{p2col:{cmd:sc}}small caps{p_end}
{p2col:{cmd:tt}}use teletype font, that is, Courier{p_end}
{p2col:{cmd:underline}}underline text{p_end}
{p2line}
{phang2}* {cmd:fs}{it:#} can only be specified in the {cmd:basefont()}
option for TeX files, not in other font specification options.

{marker titlfont}{...}
{phang}{cmd:titlfont(}{it:{help frmt_opts##fontcolumn:fontcolumn}}{cmd:)} 
changes the font for the table's title.

{marker notefont}{...}
{phang}{cmd:notefont(}{it:fontcolumn}{cmd:)} changes the font for notes
below the table.

{pmore}{cmd:titlfont()} and {cmd:notefont()} take a {it:fontcolumn}
rather than a {it:fontlist} to allow for different fonts on different
rows of titles or notes, such as a font for the subtitle that is smaller
than the font of the main title.

{marker fontcolumn}{...}
{pmore}A {it:fontcolumn} consists of {it:fontlist} [{cmd:\}
{it:fontlist} [...]], where {it:fontlist} is defined above for 
{help frmt_opts##fontlist_word:Word files} or for 
{help frmt_opts##fontlist_tex:TeX files}.

{pmore}For example, to make the title font large and small caps and the
subtitles still larger than regular text but without small caps, you
could use {cmd:titlfont(fs17 scaps \ fs14)} for a Word file or
{cmd:titlfont(Large sc \ large)} for a TeX file.

{marker ctitlfont}{...}
{phang}{cmd:ctitlfont(}{it:{help frmt_opts##fontgrid:fontgrid}}[{cmd:;}
{it:fontgrid} [...]]{cmd:)} changes the fonts for column titles.

{marker rtitlfont}{...}
{phang}{cmd:rtitlfont(}{it:fontgrid}[{cmd:;} {it:fontgrid} [...]]{cmd:)}
changes the fonts for row titles.

{marker statfont}{...}
{phang}{cmd:statfont(}{it:fontgrid}[{cmd:;} {it:fontgrid} [...]]{cmd:)}
changes the fonts for statistics in the body of the table.

{pmore}The arguments for {cmd:ctitlfont()}, {cmd:rtitlfont()}, and
{cmd:statfont()} are {it:fontgrids} to allow a different font
specification for each cell of column titles, row titles, or table
statistics, respectively.  By default, all these areas of the table have
the same font as the {helpb frmt_opts##basefont:basefont()}, which by
default is 12-point Times New Roman for Word files.

{marker fontgrid}{...}
{pmore}A {it:fontgrid} consists of {it:fontrow} [{cmd:\} {it:fontrow}
[...]], where {it:fontrow} is {it:fontlist} [{cmd:,} {it:fontlist}
[...]] and where {it:fontlist} is defined above for 
{help frmt_opts##fontlist_word:Word files} and for 
{help frmt_opts##fontlist_tex:TeX files}.

{pmore}For example, to make the font for the first row of
{cmd:ctitles()} bold and the second (and subsequent) rows of
{cmd:ctitles()} italic, you could use {cmd:ctitlfont(b \ i)} for a Word
file or {cmd:ctitlfont(bf \ it)} for a TeX file.

{pmore}The semicolon in the argument list applies different fonts to
separate {help frmt_opts##table_sections:sections} of the formatted
table.  This is more likely to be useful for row sections than column
sections.  Formatted tables have two column sections: the columns of
{helpb frmt_opts##rtitles:rtitles()} (typically one column) and the
columns of statistics.  {helpb outreg} tables, for example, have four
row sections: the rows of {helpb frmt_opts##ctitles:ctitles()} (often
one row) and three sections for the {helpb frmt_opts##rtitles:rtitles()}
and statistics (the rows of regular coefficients, the rows of constant
coefficients, and the rows of summary statistics below the
coefficients).

{pmore}The section divider allows you to specify the column or row fonts
without knowing for a particular table how many columns or rows are in
each section.  To italicize the t statistics below coefficient estimates
for the coefficients but not italicize the summary statistics rows, you
could use {cmd:statfont(plain \ i; plain \ i; plain)} for a Word file or
{cmd:statfont(rm \ it; rm \ it; rm)} for a TeX file.

{pmore}If you specify a new font type or a single font point size in
{cmd:titlfont()} or {cmd:statfont()}, this is applied to all rows of the
{cmd:title()} or estimation statistics, removing the default method of
making the subtitles smaller than the first row of {cmd:title()} and the
substatistics, such as the t statistic, smaller than the coefficient
estimates.  To retain this method, specify two rows of font sizes in
{cmd:titlfont()} or {cmd:statfont()}, with the second being smaller than
the first.  Changing the {cmd:basefont()} does not have any effect on
the differing font sizes in the rows of {cmd:title()} and estimation
statistics.

{marker addfont}{...}
{phang}{cmd:addfont(}{it:fontname}{cmd:)} adds a new font type, making
it available for use in the font specifications for various parts of the
formatted table.  This option is available only for Word files, not TeX
files.

{pmore}By default, only Times New Roman ({cmd:roman}), Arial
({cmd:arial}), and Courier New ({cmd:courier}) are available for use in
Word RTF documents.  {cmd:addfont()} makes it possible to make
additional fonts available for use in the Word documents created.

{pmore}{it:fontname} is a sequence of font names in quotation marks,
separated by commas.

{pmore}The new fonts in {cmd:addfont()} can be referenced in the various
font specification options, such as 
{helpb frmt_opts##basefont:basefont()} and 
{helpb frmt_opts##titlfont:titlfont()}, with the code {cmd:fnew1} for
the first new font in {cmd:addfont()} and increments of it ({cmd:fnew2},
{cmd:fnew3}, etc.) for each additional font.

{pmore}If the font specified in {cmd:addfont()} is not available on your
computer when using the Word file created, the new font will not display
correctly -- another font will be substituted.  You can find the correct
name of each available font in Word by scrolling through the font
selection window on the toolbar of the Word application.  Correct
capitalization of the font name is necessary.

{pmore}See {help outreg_complete##xmpl11:example 11} of {helpb outreg}
for an application of {cmd:addfont()}.

{marker plain}{...}
{phang}{cmd:plain} eliminates default formatting, reverting to plain
text: only one font size for the whole table, no column-justification,
and no added space above and below the horizontal border lines.  Instead
of using {cmd:plain}, the default formatting can also be reversed
feature by feature with {helpb frmt_opts##titlfont:titlfont()}, 
{helpb frmt_opts##notefont:notefont()}, 
{helpb frmt_opts##coljust:coljust()}, 
{helpb frmt_opts##spacebef:spacebef()}, and 
{helpb frmt_opts##spaceaft:spaceaft()}.  The {cmd:plain} option does
this all at once.

{marker table_sections}{...}
{phang}{it:table_sections}: It can be helpful for specifying fonts and
other formatting to understand how {helpb outreg} divides the table into
sections.  The following diagram illustrates the section divisions:

		   {c TLC}{dup 56:{c -}}{c TRC}
		   {c |}                        title                           {c |}
		   {c BLC}{dup 56:{c -}}{c BRC}
		     column section 1		column section 2
		   {c TLC}{dup 18:{c -}}{c TT}{dup 37:{c -}}{c TRC}
		{c TLC}{c -} {c TLC}{dup 18:{c -}}{c TT}{dup 37:{c -}}{c TRC}
		{c |}  {c |}{dup 18: }{c |}{dup 37: }{c |}
 row section 1  {c |}  {c |}     ctitles      {c |}        ctitles{dup 22: }{c |}
		{c |}  {c |}{dup 18: }{c |}{dup 37: }{c |}
		{c LT}{c -} {c LT}{dup 18:{c -}}{c +}{dup 37:{c -}}{c RT}
		{c |}  {c |}{dup 18: }{c |}{dup 37: }{c |}
		{c |}  {c |}{dup 18: }{c |}{dup 37: }{c |}
		{c |}  {c |}{dup 18: }{c |}{dup 37: }{c |}
 row section 2  {c |}  {c |}     rtitles      {c |}        coefficient estimates{dup 8: }{c |}
		{c |}  {c |}{dup 18: }{c |}        (except for constants)       {c |}
		{c |}  {c |}{dup 18: }{c |}{dup 37: }{c |}
		{c |}  {c |}{dup 18: }{c |}{dup 37: }{c |}
		{c LT}{c -} {c LT}{dup 18:{c -}}{c +}{dup 37:{c -}}{c RT}
 row section 3  {c |}  {c |}     rtitles      {c |}        constant coefficients{dup 8: }{c |}
		{c LT}{c -} {c LT}{dup 18:{c -}}{c +}{dup 37:{c -}}{c RT}
 row section 4  {c |}  {c |}     summtitles   {c |}        summstats{dup 20: }{c |}
		{c BLC}{c -} {c BLC}{dup 18:{c -}}{c BT}{dup 37:{c -}}{c BRC}

		   {c TLC}{dup 56:{c -}}{c TRC}
		   {c |}                        note                            {c |}
		   {c BLC}{dup 56:{c -}}{c BRC}


{marker lines_spaces}{...}
{dlgtab:Border lines and spacing}

{marker hlines}{...}
{phang}{cmd:hlines(}{it:{help frmt_opts##linestring:linestring}}[{cmd:;}
{it:linestring} [...]]{cmd:)} draws horizontal lines between rows.

{marker vlines}{...}
{phang}{cmd:vlines(}{it:linestring}[{cmd:;} {it:linestring}
[...]]{cmd:)} draws vertical lines between columns.

{pmore}{cmd:hlines()} and {cmd:vlines()} designate where horizontal and
vertical lines will be placed to delineate parts of the table.  By
default, the formatted table has horizontal lines above and below the
{cmd:ctitles()} header rows and at the bottom of the table above the
notes, if any.  There are no vertical lines by default.

{marker linestring}{...}
{pmore}
{it:linestring} can comprise the following:

{p2colset 11 24 27 30}{...}
{p2col:{it:linestring}}Action{p_end}
{p2line}
{p2col:{cmd:1}}add a line{p_end}
{p2col:{cmd:0}}no line{p_end}
{p2col:{cmd:{}}}repetition{p_end}
{p2line}

{pmore}Each {cmd:1} in {it:linestring} indicates a line, and a {cmd:0}
indicates no line.  For example, {cmd:hlines(110001)} would draw a line
above and below the first row of the table and below the fifth row
(above the sixth row).  There is one more possible horizontal line than
row (and one more vertical line than column).  That is, for a five-row
table, to put a line above and below every row, one would specify six
{cmd:hlines()}: {cmd:hlines(111111)}.

{pmore}{cmd:hlines()} and {cmd:vlines()} are not displayed correctly in
the Stata Results window.  They only apply to the final Word or TeX
document.

{pmore}Curly brackets repeat the middle of {it:linestring}.  For
example, {cmd:hlines(}{cmd:11{0}1}{cmd:)} puts a horizontal line above
and below the first row and another below the last row.

{pmore}The semicolon applies line designations to separate 
{help frmt_opts##table_sections:sections} of the formatted table.
{helpb outreg} tables, for example, have two column sections and four
row sections.  The column sections are made up of the columns of 
{helpb frmt_opts##rtitles:rtitles()} (typically one column) and the
columns of the estimation statistics.  The row sections are made up of
the rows of {helpb frmt_opts##ctitles:ctitles()} (often one row), the
rows of the coefficient estimates (except the constant), the rows of the
constant coefficients, and the rows of the summary statistics below the
coefficients.

{pmore}The section divider allows you to specify the {cmd:hlines()} and
{cmd:vlines()} without knowing how many rows and columns are in each
section.  The default is {cmd:hlines(1{0};1{0}1)}, which puts a
horizontal line above the header rows, a line above the statistics rows,
and a line below the last statistics row.  By default, there are no
{cmd:vlines()}, which some graphic designers think are best avoided.

{marker hlstyle}
{phang}{cmd:hlstyle(}{it:{help frmt_opts##lstylestring:lstylestring}}[{cmd:;}
{it:lstylestring} [...]]{cmd:)} changes the style of horizontal
lines.

{marker vlstyle}{...}
{phang}{cmd:vlstyle(}{it:lstylestring}[{cmd:;} {it:lstylestring}
[...]]{cmd:)} changes the style of vertical lines.

{pmore}{cmd:hlstyle()} and {cmd:vlstyle()} options are only available
for Word files.  By default, all lines are solid single lines.

{marker lstylestring}{...}
{pmore}
{it:lstylestring} can comprise the following:

{p2colset 11 25 27 15}{...}
{p2col:{it:lstylestring}}Action{p_end}
{p2line}
{p2col:{cmd:s}}single line{p_end}
{p2col:{cmd:d}}double line{p_end}
{p2col:{cmd:o}}dotted line{p_end}
{p2col:{cmd:a}}dashed line{p_end}
{p2col:{cmd:S}}heavy weight single line{p_end}
{p2col:{cmd:D}}heavy weight double line{p_end}
{p2col:{cmd:O}}heavy weight dotted line{p_end}
{p2col:{cmd:A}}heavy weight dashed line{p_end}
{p2col:{cmd:{}}}repetition{p_end}
{p2line}

{pmore}Repetition by using curly brackets and semicolons for section
dividers is used in the same way it is for 
{helpb frmt_opts##hlines:hlines()} and 
{helpb frmt_opts##vlines:vlines()}.

{pmore}Some word processing applications, such as OpenOffice or Pages
(for the Mac), do not display all Word RTF line styles correctly.

{marker spacebef}{...}
{phang}{cmd:spacebef(}{it:{help frmt_opts##spacestring:spacestring}}[{cmd:;}
{it:spacestring} [...]]{cmd:)} puts space above cell contents.

{marker spaceaft}{...}
{phang}{cmd:spaceaft(}{it:spacestring}[{cmd:;} {it:spacestring}
[...]]{cmd:)} puts space below cell contents.

{marker spaceht}{...}
{phang}{opt spaceht(#)} changes the size of the space above and below
cell contents in {cmd:spacebef()} and {cmd:spaceaft()}.

{pmore}{cmd:spacebef()} and {cmd:spaceaft()} are options to make
meticulous changes in the appearance of the table.  They increase the
height of the cells in particular rows so that there is more space above
and below the contents of the cell.  They are used by default to put
space between the horizontal line at the top of the table and the first
header row, put space above and below the line separating the header row
from the statistics, and put space below the last row of the table,
above the horizontal line.

{marker spacestring}{...}
{pmore}{it:spacestring} has the same form as 
{it:{help frmt_opts##linestring:linestring}} above.  A {cmd:1} indicates
an extra space (above the cell if in {cmd:spacebef()} and below the cell
if in {cmd:spaceaft()}), and a {cmd:0} indicates no extra space.  The
{cmd:{}} specify the indicator to repeat, and {cmd:;} separates row
sections.

{pmore}{cmd:spaceht()} controls how big the extra space is in
{cmd:spacebef()} and {cmd:spaceaft()}.  Each one-unit increase in
{cmd:spaceht()} increases the space by about one-third of the height of
a capital letter.  The default is {cmd:spaceht(1)}.  {opt spaceht()} is
scaled proportionally to the base font size for the table.  For example,
{cmd:spaceht(2)} makes the extra spacing 100% larger than it is by
default.

{pmore}For TeX files (using the {opt tex} option), {opt spaceht()} can
only take the values {cmd:2} or {cmd:3}.  The default corresponds to the
LaTeX code \smallskip.

{pmore}Values {cmd:2} and {cmd:3} for {opt spaceht()} correspond to the
LaTeX codes \medskip and \bigskip, respectively.

{marker page_fmt}{...}
{dlgtab:Page formatting}

{marker landscape}{...}
{phang}{opt landscape} puts the document page containing the formatted
table in landscape orientation.  This makes the page wider than it is
tall, in contrast to portrait orientation.  {opt landscape} is
convenient for wide tables.  An alternative way of fitting a table on
the page is to use a smaller {helpb frmt_opts##basefont:basefont()},
without the need for the {opt landscape} option.

{marker a4}{...}
{phang}{opt a4} specifies A4-size paper (instead of the default 8 1/2" x
11") for the Word or TeX document containing the formatted table.

{marker file_options}{...}
{dlgtab:File and display options}

{marker tex}{...}
{phang}{opt tex} writes a TeX output file rather than a Word file (as
long as {opt using} {it:filename} is specified).  The output is suitable
for including in a TeX document (see the 
{helpb frmt_opts##fragment:fragment} option) or loading into a TeX
typesetting program such as Scientific Word.

{marker merge}{...}
{phang}{cmd:merge}[{cmd:(}{it:{help frmt_opts##tblname:tblname}}{cmd:)}]
specifies that new statistics be merged to the most recently created
formatted table.  The new statistics are combined with previous
estimates, lined up according to the appropriate variable name (or
{helpb frmt_opts##rtitles:rtitles()}), with the statistics corresponding
to new row titles placed below the original statistics.  In the case of
{cmd:outreg}, coefficient estimates of new variables are placed below
the estimates for existing coefficients but above the constant term.

{pmore}In a previous version of the {helpb outreg} command, the
{cmd:merge} option was called {cmd:append}.  Users will usually want to
specify {helpb frmt_opts##ctitles:ctitles()} when using {cmd:merge}.

{pmore}{opt merge} can be used even if a previous formatted table does
not exist for merging.  This will enable {opt merge} to be used in
loops, as in {cmd:outreg} {help outreg_complete##xmpl16:example 16}.
Users will see a warning message if no existing table is found.

{pmore}If a {it:tblname} is specified, the current estimates will be
merged to an existing table named {it:tblname}, which could have been
created with a previous command by using the {opt store(tblname)}, 
{opt merge(tblname)}, or {opt append(tblname)} option.

{marker tblname}{...}
{pmore}A {it:tblname} may comprise the characters {cmd:A}-{cmd:Z},
{cmd:a}-{cmd:z}, {cmd:0}-{cmd:9}, and the underline symbol ({cmd:_}) and
can have a length of up to 25 characters.

{marker replace}{...}
{phang}{opt replace} specifies that it is okay to overwrite an existing
file.

{marker addtable}{...}
{phang}{opt addtable} places the estimation results as a new table below
an existing table in the same document (rather than combining the tables
as with {helpb frmt_opts##merge:merge}).  This makes it possible to
build up a document with multiple tables in it.

{pmore}The options {opt pretext()} and {opt posttext()} can add
accompanying text between the tables.  To put a page break between
successive tables so that each table is on its own page, see the
discussion for {helpb frmt_opts##pretext:pretext()} and
{cmd:posttext()}.

{pmore}See {help outreg_complete##xmpl13:example 13} in {helpb outreg}
for an application of {cmd:addtable}.

{marker append}{...}
{phang}{cmd:append}[{cmd:(}{it:{help frmt_opts##tblname:tblname}}{cmd:)}] 
combines the statistics as new rows below an existing table.  If a
{it:tblname} is specified, the statistics will be appended to an
existing formatted table named {it:tblname} (see the 
{helpb frmt_opts##store:store()} option).

{pmore}{cmd:Warning: This is not the append option from previous versions of {helpb outreg}. That append option has now become {helpb frmt_opts##merge:merge}}.

{pmore}{opt append} can be used even if no previous formatted table
exists, which is useful in loops for the first invocation of the
{cmd:append} option.

{pmore}{opt append} does not match up column headings.  The column
headings of the new table being appended are ignored unless the new
table has more columns than the original table, in which case only the
headings of the new columns are used.

{marker replay}{...}
{phang}{cmd:replay}[{cmd:(}{it:{help frmt_opts##tblname:tblname}}{cmd:)}] 
is used to rewrite an existing formatted table to a file without
including any new statistics (unless paired with {cmd:merge} or
{cmd:append}).  This can be used to rewrite the same table with
different text formatting options.  It is also used after building a
table in a loop to write the final table to a file.  If a {it:tblname}
is specified, {cmd:replay} will use the table with that name.

{pmore}{opt replay} is used after running a loop that merges multiple
estimation results to write the final merged table to a document file.
See {cmd:outreg} {help outreg_complete##xmpl16:example 16}.

{pmore}{cmd:replay} changes the behavior of {cmd:merge} and {cmd:append}
when they have table names, causing them to merge or append results from
the table specified into the table specified by {cmd:replay}.

{marker store}{...}
{phang}{cmd:store(}{it:{help frmt_opts##tblname:tblname}}{cmd:)} is used
to assign a {it:tblname} to a formatted table.  This is useful mainly
for building more than one table simultaneously by merging new
estimation results to separate tables when the estimation commands must
be run sequentially.

{marker clear}{...}
{phang}{cmd:clear}[{cmd:(}{it:tblname}{cmd:)}] removes the current
formatted table from memory.  This is helpful when using the {opt merge}
option in a loop so that the first time it is invoked, the estimation
results are not merged to an existing formatted table (such as the one
created the last time the do-file was run).  The command 
{cmd:outreg, clear} clears the current table, allowing the user to start
with a blank slate.

{pmore}If a {it:tblname} is specified, the formatted table named
{it:tblname} will be removed from memory.  When you use multiple
{it:tblnames}, they must be {opt clear}ed one by one.  An alternative is
to use {helpb mata clear:mata: mata clear} to clear all of Mata's memory
space, including the formatted tables.

{marker fragment}{...}
{phang}{opt fragment} creates a TeX code fragment for inclusion in a
larger TeX document instead of a stand-alone TeX document.  A TeX
fragment saved to the file auto.tex can then be included in the
following TeX document with the TeX {cmd:\input{auto}} command:

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

{pmore}Including TeX fragments with the TeX {cmd:\input{}} command
allows the formatted table to be updated without having to change the
TeX code for the document itself.  This is convenient because estimation
tables often require small modifications, which can be made without
having to reinsert a new table manually.  Creating TeX fragments for
inclusion in larger TeX documents is especially useful when there are
many tables in a single document (see also the 
{helpb frmt_opts##addtable:addtable} option).

{pmore}An alternative to the TeX {cmd:\input{}} command is the TeX
{cmd:\include{}} command, which inserts page breaks before and after the
included table.

{marker nodisplay}{...}
{phang}{opt nodisplay} suppresses the display of the table in the Stata
Results window.

{marker dwide}{...}
{phang}{opt dwide} displays all columns in the Stata Results window,
however wide the table is.  This is mainly useful if you want to copy
the table to paste it into another document (which hopefully is not
necessary).  Without the {opt dwide} option, very wide tables are
displayed in the Results window in sections containing as many columns
as will fit given the current width of the Results window.

{marker brack_options}{...}
{dlgtab:Brackets options}

{marker squarebrack}{...}
{phang}{opt squarebrack} substitutes square brackets for parentheses
around the statistics placed below the first statistic.  For the default
statistics, this means that square brackets rather than parentheses are
placed around t statistics below the coefficient estimates.

{pmore}{opt squarebrack} is equivalent to 
{cmd:brackets("", "" \ [,] \ (,) \ <,> \ |,|)}.

{marker brackets}{...}
{phang}{cmd:brackets(}{it:{help frmt_opts##textpair:textpair}} [{cmd:\}
{it:textpair} [...]]{cmd:)} specifies the symbols used to bracket
statistics.  By default, the first statistic has no brackets, and
parentheses are placed around the second statistic, such as the t
statistic below the estimated coefficient estimate when using 
{helpb outreg}.

{marker textpair}{...}
{pmore}A {it:textpair} is made up of two elements of text separated by a
comma.  The default is {cmd:brackets("", "" \ (,) \ [,] \ <,> \ |,|)}.

{pmore}If there are a sufficient number of statistics for the symbols
{cmd:<,>} and {cmd:|,|} to be used with the {helpb frmt_opts##tex:tex}
option, they are replaced by {cmd:$<$},{cmd:$>$} and {cmd:$|$},{cmd:$|$}
so that they show up correctly in TeX documents.

{pmore}{cmd:brackets()} has no effect when the 
{helpb frmttable##substat:substat()} option is in effect.

{marker nobrket}{...}
{phang}{opt nobrket} eliminates the application of {cmd:brackets()}, so
there would be no brackets around the second or higher statistics.

{marker dbldiv}{...}
{phang}{opt dbldiv(text)} is a rather obscure option that allows you to
change the symbol that divides double statistics.  Double statistics
have both a lower and an upper statistic, such as confidence intervals.
The default is {cmd:dbldiv(-)}, with a dash between the lower and upper
statistics, but {cmd:dbldiv()} allows you to substitute something else.
For example, {cmd:dbldiv(:)} would put a colon between the lower and
upper statistics.


{marker greek}{...}
{title:Inline text formatting: Superscripts, italics, Greek characters, etc.}

{pstd}The {help frmt_opts##fonts:font specification options} allow users
to control font characteristics at the table cell level, but users often
want to change the formatting of a word or just a character in the text
or a table cell.  This is true for characteristics such as superscripts,
subscripts, italics, bold text, and special characters such as Greek
letters.

{pstd}Text strings in the formatted table can include inline formatting
codes that change the characteristics of just part of a string.  These
codes are distinct between Word and TeX files because they are really
just Word and TeX formatting codes passed directly to the output files.

{pstd}See {help outreg_complete##xmpl12:example 12} in {helpb outreg}
for an application of inline formatting codes in a Word table.

    {title:Word inline formatting}

{pstd}The Word files are written in the Word RTF specification.  Most of
the RTF specification codes can be included in the formatted text (find
the full 210-page specification in the links of 
{browse "http://en.wikipedia.org/wiki/Rich_Text_Format":en.wikipedia.org/wiki/Rich_Text_Format}).
This note will explain a subset of the most useful codes.

{pstd}Word RTF codes are enclosed in curly braces, {com}{{text} and
{com}}{text}.  Codes start
with a backslash, {cmd:\}, and then the code word.  There must be a space
after the code word before the text begins so that the text is
distinguished from the code.  For example, the formatting to italicize
the letter F is {cmd:{\i F}} because {cmd:\i} is the RTF code for
italics.

{pstd}Be very careful to match opening and closing curly brackets
because the consistency of the nested curly brackets in a Word file is
essential to the file's integrity.  If one of the curly brackets is
missing, the Word file may be corrupted and unreadable.  You can trace
problems of this kind by temporarily removing inline formatting that
includes curly braces.

{p2colset 11 23 37 10}{...}
{p2col:RTF code}Action{p_end}
{p2line}
{p2col:{opt \i}}italic{p_end}
{p2col:{opt \b}}bold{p_end}
{p2col:{opt \ul}}underline{p_end}
{p2col:{opt \scaps}}small capitals{p_end}
{p2col:{opt \sub}}subscript (and shrink point size){p_end}
{p2col:{opt \super}}superscript (and shrink point size){p_end}
{p2col:{cmd:\fs}{it:#}}font size (in points * 2; for example, 12 point is
{cmd:\fs24}){p_end}
{p2line}

{pstd}Most of these codes are the same as those used in the 
{help frmt_opts##fonts:font formatting options}, but there are some
differences, such as the font size code {cmd:\fs}{it:#} using double points, not
points.

    {title:Greek and other Unicode characters in Word}

{pstd}Word RTF files can display Greek letters and any other Unicode
character (as long as it can be represented by the font type you are
using).  The codes are explained {help greek_in_word:here}.  Unicode
codes in Word are an exception to the rule that the code must be
followed by a space before the text.  Text can follow immediately after the
Unicode code.

    {title:TeX inline formatting}

{pstd}The discussion of TeX inline formatting is brief because TeX users
are usually familiar with inserting their own formatting codes into
text.  Many online references explain how to use TeX formatting codes.
A good place to start is the references section of 
{browse "http://en.wikipedia.org/wiki/TeX":en.wikipedia.org/wiki/TeX}.

{pstd}For many formatting effects, TeX can generate inline formatting
in two alternative ways: in math mode, which surrounds the formatted
text or equation with dollar signs ({cmd:$}), or in text mode, which uses a
backslash followed by formatting code and text in curly brackets.

{pstd}For example, we can create a superscripted number 2 either as
{cmd:$^2$} in math mode or as {cmd:\textsuperscript{2}} in text mode.
To display R-squared in a TeX document with the R italicized and a
superscript 2, one can use either the code {cmd:$ R^2$} or the code
{cmd:\it{R}\textsuperscript{2}}.  The space between the {cmd:$} and the
{cmd:R} in {cmd:$ R^2$} is a Stata, not a TeX, issue.  If we had instead
written {cmd:$R^2$}, Stata would have interpreted the {cmd:$R} as a
global macro, which is probably undefined and empty, so the TeX document
would just contain {cmd:^2$}.  Whenever using math mode in TeX inline
formatting that starts with a letter, make sure to place a space between
the {cmd:$} and the first letter.

{pstd}Math mode generally italicizes text and is designed for writing
formulas.  A detailed discussion of its capabilities is beyond the scope
of this note.  Below is a table of useful text-mode formatting codes.

{p2colset 11 31 37 15}{...}
{p2col:TeX code}Action{p_end}
{p2line}
{p2col:{opt \it}}italic{p_end}
{p2col:{opt \bf}}bold{p_end}
{p2col:{opt \underline}}underline{p_end}
{p2col:{opt \sc}}small capitals{p_end}
{p2col:{opt \textsubscript}}subscript (and shrink point size){p_end}
{p2col:{opt \textsuperscript}}superscript (and shrink point size){p_end}
{p2line}

{pstd}Keep in mind that many of the nonalphanumeric characters have
special meaning in TeX, namely, the following characters:

{pmore}{cmd:_  %  #  $  &  ^  {  }  ~  \}

{pstd}If you want these characters to be printed in TeX like any other
character, include a backslash ({cmd:\}) in front of the character.  The
exceptions are the last two characters: {cmd:~} and {cmd:\} itself.  The
{cmd:~} is represented by {cmd:\textasciitilde}, and the {cmd:\} is
represented by either {cmd:\textbackslash} or {cmd:$\backslash$} to
render properly in TeX.

    {title:Greek letters in TeX}

{pstd}Greek letters can be coded in TeX documents with a backslash and
the name of the letter written in English surrounded by dollar signs
({cmd:$}).  For example, a lowercase delta can be inserted with the code
{cmd:$\delta$}.  Uppercase Greek letters use the name in English with an
initial capital, so an uppercase delta can be inserted with the code
{cmd:$\Delta$}.  If you cannot remember how to spell Greek letters in
English, look at the table for Greek letter codes in Word 
{help greek_in_word:here}.{p_end} 
{marker spec_notes}{...}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 12, number 4: {browse "http://www.stata-journal.com/article.html?article=sg97_5":sg97_5},{break}
                    {it:Stata Journal}, volume 12, number 1: {browse "http://www.stata-journal.com/article.html?article=sg97_4":sg97_4},{break}
                    {it:Stata Technical Bulletin} 59: {browse "http://www.stata.com/products/stb/journals/stb59.pdf":sg97.3},{break}
                    {it:Stata Technical Bulletin} 58: {browse "http://www.stata.com/products/stb/journals/stb58.pdf":sg97.2},{break}
                    {it:Stata Technical Bulletin} 49: {browse "http://www.stata.com/products/stb/journals/stb49.pdf":sg97.1},{break}
                    {it:Stata Technical Bulletin} 46: {browse "http://www.stata.com/products/stb/journals/stb46.pdf":sg97}
{p_end}
