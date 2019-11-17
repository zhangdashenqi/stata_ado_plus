{smcl}
{* *! version 4.00  31aug2010}{...}
{cmd:help outreg_update}{right: ({browse "http://www.stata-journal.com/article.html?article=sg97_5":SJ12-4: sg97_5})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:outreg} {hline 2}}Changes to outreg since version 3{p_end}
{p2colreset}{...}

{pstd}
This version is a complete rewrite of {cmd:outreg}, mostly programmed in
Mata.  All it shares with the previous versions of {cmd:outreg} other
than the name is part of the command syntax.

{pstd}
The objective of this version was as complete control as is practical of
the layout and formatting of estimation tables in creating both
Microsoft Word and TeX files.

{phang2}
1. The most obvious change to {helpb outreg_complete:outreg} is that it
now writes fully formatted Microsoft Word or TeX files rather than flat
text files.  For this reason, there are several new options relating to
fonts, text justification, cell border lines, etc., that were not needed
before.

{phang2}
2. {cmd:outreg} can now display any number of statistics for each
estimated coefficient (instead of just two), and these statistics can be
displayed side by side as well as one above the other.  You can choose
from 26 different {help outreg_complete##statname:{it:statname}}s for
inclusion in a table, including the full panoply of marginal effects and
confidence intervals.

{phang2}
3. You can now selectively {helpb outreg_complete##keep:keep()} or
{helpb outreg_complete##drop:drop()} coefficients or equations from the
estimation results.

{phang2}
4. Tables can be {helpb outreg_complete##merge:merge}d (previously known
as {helpb outreg_complete##append:append}ing) more flexibly than before.
Multiple tables can also be written successively to the same file with
regular paragraphs of text in between, so it is possible to create a
whole statistical appendix in a single document with a .do file.

{phang2}
5. Text can include italics formatting, bold formating, superscripts and
subscripts, and Greek characters.  It is possible to include
user-specified fonts with the {helpb outreg_complete##addfont:addfont()}
option.  Column titles can span multiple cells with the 
{helpb outreg_complete##multicol:multicol()} option.  Footnotes can be
added to any part of the table with the 
{helpb outreg_complete##annotate:annotate()} option.

{phang2}
6. The table created by {cmd:outreg} is displayed in the Stata Results
window, minus some of the finer formatting destined for the Microsoft
Word or TeX file.


{pstd}
Some {cmd:outreg} syntax changes may cause confusion:

{phang2}
1. Name of {cmd:append} option has changed.{p_end}
{pmore2} 
Successive estimation results are now combined with the
{helpb outreg_complete##merge:merge} option, which was named
{cmd:append} in previous versions of {cmd:outreg}.  This makes the new
{cmd:outreg} consistent with the way the Stata {cmd:merge} command works
on datasets versus the Stata {cmd:append} command.

{phang2}
2. By default, variable labels are not used.{p_end}
{pmore2} 
In the new {cmd:outreg}, variable labels replace variable names only
when the {helpb outreg_complete##varlabels:varlabels} option is chosen.

{phang2}
3. By default, multiequation models are not merged into multiple
columns.{p_end}
{pmore2} 
Estimated coefficients from multiequation models like {helpb reg3} and
{helpb mlogit} are reported in one (long) column, by default.  To merge
them into separate columns for each equation, one must use the option
{helpb outreg_complete##eq_merge:eq_merge}.


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
