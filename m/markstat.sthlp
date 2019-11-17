{smcl}
{* 26oct2016 25may2017}{...}
{title:Title}

{phang}
{bf:markstat} {hline 2} literate data analysis with Stata and Markdown

{title:Syntax}

{p 4 6 2}
{cmd:markstat using} {it:filename} [, {opt pdf} {opt mathjax} {opt strict} 
  {opt bib:liography}]

{title:Arguments}

{phang}
{it:filename} is a required argument specifying the name of the 
Stata-Markdown file. It should have extension {bf: .stmd}, but 
this may be omitted when typing the command.

{phang}
{opt pdf} is an optional argument used to request generating a
PDF rather than an HTML file. 

{phang}
{opt mathjax} is used to render LaTeX equations in HTML documents
using the JavaScript library MathJax.

{phang}
{opt strict} controls the way the command distinguishes Markdown 
annotations from Stata commands, as explained in the 
{help markstat##strict:Stata code} section below.

{phang}
{opt bib:liography} is used to resolve citations using a BibTeX 
database and add a list of references at the end of the document,
see {help markstat##citations:citations} below.

{title:Description}

{pstd}
The basic idea of this command is to prepare an input file that 
combines comments and annotations written in Markdown, with Stata 
commands that appear in blocks indented one tab or four spaces, as in the
following example:

 {col 8}{c TLC}{hline 65}{c TRC}
 {col 8}{c |}  Stata Markdown{col 74}{c |}
 {col 8}{c |}  --------------{col 74}{c |}
 {col 8}{c |}{col 74}{c |}
 {col 8}{c |} Let us read the fuel efficiency data that ships with Stata{col 74}{c |}
 {col 8}{c |}{col 74}{c |}
 {col 8}{c |}{col 13}sysuse auto, clear{col 74}{c |}
 {col 8}{c |}{col 74}{c |}
 {col 8}{c |} To study how fuel efficiency depends on weight it is useful to{col 74}{c |}
 {col 8}{c |} transform the dependent variable from "miles per gallon" to{col 74}{c |}
 {col 8}{c |} "gallons per 100 miles"{col 74}{c |}
 {col 8}{c |}{col 74}{c |}
 {col 8}{c |}{col 13} gen gphm = 100/mpg{col 74}{c |}
 {col 8}{c |}{col 74}{c |}
 {col 8}{c |} We then obtain a fairly linear relationship{col 74}{c |}
 {col 8}{c |}{col 74}{c |}
 {col 8}{c |}{col 13} twoway scatter gphm weight | lfit gphm weight,  ///{col 74}{c |}
 {col 8}{c |}{col 13}    ytitle(Gallons per 100 Miles) legend(off){col 74}{c |}
 {col 8}{c |}{col 13} graph export auto.png, width(500) replace{col 74}{c |}
 {col 8}{c |}{col 74}{c |}
 {col 8}{c |} ![Fuel Efficiency by Weight](auto.png){col 74}{c |}
 {col 8}{c |}{col 74}{c |}
 {col 8}{c |} The regression equation estimated by OLS is{col 74}{c |}
 {col 8}{c |}{col 74}{c |}
 {col 8}{c |}{col 13} regress gphm weight{col 74}{c |}
 {col 8}{c |}{col 74}{c |}
 {col 8}{c |} Thus, a car that weighs 1,000 pounds more than another requires{col 74}{c |}
 {col 8}{c |} on average an extra 1.4 gallons to travel 100 miles.{col 74}{c |}
 {col 8}{c |}{col 74}{c |}
 {col 8}{c |} That's all for now!{col 74}{c |}
 {col 8}{c BLC}{hline 65}{c BRC}
{smcl}

{pstd}
Saving this code as {bf:auto.stmd} and running the command
{bf: markstat using auto} produces the web page shown at
{browse "http://data.princeton.edu/stata/markdown/auto"}. 

{title:Requirements}

{pstd}
The command uses an external Markdown processor, {cmd: pandoc},
which can be downloaded for Linux, Mac or Windows from
{browse "http://pandoc.org/installing"}.

{pstd}
It also requires the Stata command {cmd:whereis}, which is used
to keep track of ancillary programs and is usually installed
together with {cmd: markdown}.
After downloading {cmd:pandoc}, you save the location of the 
executable in the {it:whereis} directory by running the command
{cmd: whereis pandoc} {it:location}.

{pstd}
If you want to generate PDF output you also need LaTeX, specifically
{cmd: pdflatex}, which comes with MiKTeX on Windows, MacTeX 
on Macs or Live TeX on Linux. You save the  location of the converter 
by running the command {cmd: whereis pdflatex} {it:location}.

{pstd}
To properly render Stata logs in PDF format you also need the
LaTeX package {cmd: stata.sty} available from the Stata Journal.
The Stata command {cmd:sjlatex} will install all journal files, but 
we only need this one. I suggest you download if from
{bf:http://www.stata-journal.com/production/sjlatex/stata.sty},
copy it in your local textmf folder and update the TeX database.
Note also that {bf:stata.sty} requires alttt.sty and 
pstricks.sty; these packages are available in most TeX distributions.

{pstd}
For server installations these tooling steps are usually completed 
by a system administrator.

{title:Markdown Code}

{pstd}
Markdown is a lightweight markup language invented by John Gruber.
It is easy to write and, more importantly, it was designed to be
easy to read, without intrusive markings. See {it: Markdown: Basics}
at {browse "http://daringfireball.net/projects/markdown/basics"}
for a quick introduction.

{pstd}
Our example uses only two Markdown features: the use of dashes as
underlining to create a heading at level 2, and the construction
{bf:![alt-text](source)} to create a link to an image given a
title(alt-text) and a source, in our case
{bf:![Fuel Efficiency by Weight](auto.png)}. 
You may use italics, bold and monospace fonts, create
numbered and bulleted lists, insert links, and much more.

{pstd}
Pandoc implements several extensions to Markdown, including metadata, 
basic tables, and pipe tables. It also lets you incorporate inline and
display mathematical equations using LaTeX notation. See John MacFarlane's 
{it:User's Guide} at {browse "http://pandoc.org/MANUAL.html"}
for more information.
 
{title:Stata Code}{marker strict}

{pstd}
The simple indentation rule using one tab or four spaces for Stata code
permits clean input but precludes some advanced Markdown options, 
including multi-paragraph and nested lists. An alternative is to use a
{it:Stata code fences}, activated via the {opt strict} option.
In this case Stata code goes in blocks like this:

{col 8}```{c -(}s{c )-}
{col 8}     // Stata commands go here
{col 8}```

{pstd}
The braces are optional, so the opening fence may be coded as
{bf:```{c -(}s{c )-}} or just as {bf:```s}. The closing fence
is always {bf:```}.

{pstd} 
There is also an option to supress echoing Stata commands in  a strict 
code block, which is indicated by appending a slash to the {bf:s},
so the opening fence is either {bf:```{c -(}s/{c )-}} or just 
{bf:```s/}. This feature may be useful in producing dynamic documents
where the code itself is of secondary interest.

{pstd}
You may also use inline code to quote Stata results using the syntax

{col 8}`s [fmt] {it:expression}`

{pstd}
where {bf:[fmt]} is an optional format. For example after a regression you may 
retrieve the value of R-squared using {bf:`s e(r2)`}, or 
using {bf:`s %5.2f e(r2)`}  to print the value with just two decimals.  

{pstd}
Inline code is intended for short text, and cannot span more than one line.
The {cmd:markstat} command uses Stata's {cmd:display} command to evaluate
the code, and retrieves only one line of output to be spliced with the text.
The expression may contain macro evaluations and/or compound quotes.

{title:Mata Code}

{pstd}
Stata code can always use {cmd: mata:} to enter Mata and {cmd: end} to exit,
but {cmd: markstat} also allows coding Mata blocks directly, using an {bf: m} 
instead of an {bf: s} in the code fence:

{col 8}```{c -(}m{c )-}
{col 8}     // Mata code goes here
{col 8}```

{pstd}
The braces are optional	just as before, and the code may be supressed
by appending a slash to the {bf: m}, although this is rare.

{pstd}
Mata results may also be displayed inline using the syntax

{col 8}`m [fmt] {it:expression}`

{pstd}
which is identical to inline Stata but with an {bf: m} instead of an {bf: s}.

{title:Citations}{marker citations}

{pstd}
Thanks to the amazing Pandoc, {cmd:markstat} supports bibliographic
references. In addition to the {opt bib:liography} option, the document
must include a YAML block with the name of the BibTeX database,
and may optionally include also a reference to a citation style. 
For more information and examples see the website linked below.

{title:Website}

{pstd}
For more detailed information, including documentation, examples,
and answers to frequently asked questions, please visit
{browse "http://data.princeton.edu/stata/markdown"}.

{title:Author}

{pstd}
Germ{c a'}n Rodr{c i'}guez <grodri@princeton.edu>
{browse "http://data.princeton.edu":data.princeton.edu}.

