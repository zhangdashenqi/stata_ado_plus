{smcl}
{right:Version 1.4 October, 2014}
{cmd:help Ketchup}
{hline}

{phang}
{bf:ketchup} {hline 2} HTML and PDF dynamic report producer. Ketchup spices up {it:SMCL} 
logfile and gives it a modern look, inserts graphs and images in the logfile, and converts 
it to HTML or PDF. {browse "http://www.haghish.com/statistics/stata-blog/reproducible-research/dynamic_documents/markdown.php":Markdown syntax}
can be used for writing text and inserting graphs in the document which enhances the readability
of the do-file. 
Using functions from {help Synlight} and {help Weaver} packages, 
Ketchup also provide HTML-based syntax highlighter and support for writing dynamic text. Visit 
{browse "http://www.haghish.com/statistics/stata-blog/reproducible-research/ketchup.php":http://haghish.com/ketchup}
 for a complete guide on using the ketchup package, downloading template 
do-files. 


{title:Author} 
        {p 8 8 2}E. F. Haghish{break} 
	Center for Medical Biometry and Medical Informatics{break}
	University of Freiburg, Germany{break} 
        {browse haghish@imbi.uni-freiburg.de}{break}
	{browse "http://haghish.com/statistics/stata-blog/reproducible-research/ketchup.php":{it:http://haghish.com/ketchup}}{break}


{title:Syntax}

{p 8 17 2}
{cmdab:ket:chup}
{it:smclfile}
[{cmd:,} {it:replace erase keep export(name) nolight title(str) author(str) affiliation(str) style(name) font(str) printer(name) setpath(str) pandoc(str)}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt replace}}replace the converted document if already exists{p_end}
{synopt:{opt erase}}erase the {it:smclfile} after generating the {it:html}
or {it:pdf} file{p_end}
{synopt:{opt keep}}preserve the HTML document after generating the PDF document {p_end}
{synopt:{opt e:xport(name)}}export the {it:smcl} to the specified formats which can be
{bf:html} or {bf:pdf}{p_end}
{synopt:{opt no:light}}disable the syntax highlighter{p_end}
{synopt:{opt t:itle(str)}}print the title of the document on the first page{p_end}
{synopt:{opt au:thor(str)}}print author name (or any relevant information) under the title{p_end}
{synopt:{opt aff:iliation(str)}}print author affiliation (or any relevant information) under the title{p_end}
{synopt:{opt d:ate}}print the date on the first page{p_end}
{synopt:{opt sty:le(name)}}specify the document style which can be
{bf:modern}, {bf:classic}, {bf:stata}, {bf:elegant}, {bf:plain}, or {bf:minimal}{p_end}
{synopt:{opt f:ont(str)}}specifies the font for all 
headings and paragraphs{p_end}
{synopt:{opt pan:doc(str)}}specify the path to Pandoc on the Operating System{p_end}
{synopt:{opt p:rinter(name)}}define the PDF printer which can be {help ketchup##prince:{ul:prince}xml} or {help ketchup##wk:{ul:wk}htmltopdf}, 
abbreviated as {help ketchup##prince:prince}  and 
{help ketchup##wk:wk} respectively. {p_end}
{synopt:{opt set:path(str)}}specify the file path to the 
printer on the operating system{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:ketchup} is a dynamic document producer and logfile convertor which converts {it:SMCL} logfile to {it:HTML} or 
{it:PDF}. While translating the logfile, {cmd: Ketchup} automatically separates 
Stata codes from outputs and styles them accordingly. There are several document styles 
available in Ketchup which can be selected using the {opt sty:le(name)} option. 

{pstd}
Similar to {help MarkDoc} package that produces editable dynamic documents (Docx, Doc, Tex, 
Odt, etc), the Ketchup package provides the possibility of using 
{browse "http://www.haghish.com/statistics/stata-blog/reproducible-research/dynamic_documents/markdown.php":Markdown syntax}
for writing and styling text (e.g. writing headings, adding lists, link, etc) as well as inserting graphs and images in the document. 
Markdown syntax make the do-file friendlier and does not reduce the 
readability of the do-file. This capability allows Stata users to comments the results in 
a stylish way, directly in the Stata do-file editor and include the graphs to the 
logfile without the need of learning an additional command. 

{pstd}
Markdown syntax and text most be written as {help comment} after signs such as
"{bf:/*}", "{bf://}",  and "{bf:*}". The "{bf:/*}" and "{bf:*/}" signs are the easiest way to
write the comment and Markdown codes in do-file. To make this feature available,
the  "{bf:/*}" and "{bf:*/}" should be placed independently on separate lines, leaving the
rest of the line empty (see the example below). This helps {cmd:Ketchup} to
distinguish between comments that are made within Stata codes and comments 
that meant to be text headings or paragraphs. Ketchup will automatically remove the 
comment signs from the dynamic documents. 

{pstd}
The Ketchup package requires two additional user-written Stata packages which are 
{help Weaver} and {help Synlight} because it borrows some of these packages' functions for 
inserting, resizing, and styling graphs, writing dynamic text, and 
providing syntax highlighter for Stata codes in the dynamic document. Graphs can be 
resized and aligned to center, left, or right side of the document using the {help img} command. 
The {help knit} command can be used to write and style dynamic text i.e. text 
that includes Macros. These commands are further described below. 


{title:Syntax Highlighter} 

{pstd} 
{bf:Ketchup} has a built-in Syntax highlighter which highlights Stata
commands, options, functions, macros, string, and numbers.
Syntax highlighter relies on {help Synlight} package. To install Synlight, type
{cmd: ssc install synlight}. If Synlight is not installed on the machine, Ketchup will 
return an error message and ask you to install Synlight. 

{pstd} 
Syntax highlighting from Stata smcl logfile relies on running several loops for highlighting 
Stata commands, options, functions, strings, macros, and digits. The process becomes 
slow if the SMCL logfile is large. In that case, the {opt no:light} option is recommended 
which deactivates the syntax highlighting program and 
significantly speeds up the process of generating the dynamic document. 


{title:Adding graphs to the document} 

{pstd} As mentioned at the package description, Markdown syntax can be used to
insert a graph or image in the document. However, Markdown syntax cannot style the 
imported graph e.g. it cannot resize it or align it to the center, right side, or left side
of the document. Instead, it simply inserts the graph in its full size which usually larger 
than the document's width. 

{pstd}
One solution to this problem is to resize the graph while exporting it from Stata. However 
the resized graph may not be large enough for publication. Another solution is using HTML 
syntax within the
comments which will be read by Markdown convertor (see the example below). HTML {bf:width()} and 
{bf:hight()} options can be used to resize the graph in the document. but require basic familiarity 
with HTML syntax.

{pstd}
A better solution has been provided by {help img} command which is borrowed
from {help Weaver} package. The {help img} command allows you to easily insert,
resize, and style graphs in the document. This command has been modified in the Weaver package to 
support Ketchup. 


{title:Dynamic text writing} 

{pstd} 
One of the problems resulting from writing text as {help comment} is that it eliminates 
the possibility of writing dynamic text i.e. interpreting a {help macro} content within the 
text paragraphs or headings. The {bf:{help knit}} command which is borrowed from the {help Weaver} package
was updated to provide support for the Ketchup. The knit command can be
used to write dynamic text and style it using {help ketchup##add:Additional Markup Codes}
(see the example below). 


{title:Presentation Mode} 

{pstd} When several graphs need to be compared to one another, the presentation mode
allows you to insert many small-size graphs beside each other which can be
viewed in full-screen mode with a mouse click. 
{bf:Ketchup} automatically adds a presentation mode to the graphs
and images in the HTML document. By clicking on the images they zoom into 
presentation mode. This capability is more useful if the image is inserted 
and resized using "{bf:<img}" HTML tag or {help img} command (see the example below). This 
function only appear in the HTML document but not the PDF. 


{marker add}{...}
{title:Additional Markup codes}

{p 4 4 2}The Additional Markup codes have two main purposes. They can be used with the 
{help knit} command for styling dynamic text as well as providing additional functions 
for styling text in the document such as changing font color, highlighting text, etc. 
Use these codes in the comments, along with other Markdown syntax (see the example below).
The text should appear betweeb the markup brackets (e.g. [-yellow] for highlighting text)
and ends with [#]. {break} 

{synoptset 22}{...}
{p2col:{it:Markup}}Description{p_end}
{synoptline}

{syntab:{ul:Headings}}
{synopt :{bf: *-} txt {bf: -*}}prints a {bf:heading 1} in <h1>txt</h1> html tag {p_end}
{synopt :{bf: *--} txt {bf: --*}}prints a {bf:heading 2} in <h2>txt</h2> html tag {p_end}
{synopt :{bf: *---} txt {bf: ---*}}prints a {bf:heading 3} in <h3>txt</h3> html tag {p_end}
{synopt :{bf: *----} txt {bf: ----*}}prints a {bf:heading 4} in <h4>txt</h4> html tag {p_end}

{syntab:{ul:Text decoration}}
{synopt :{bf: #*} txt {bf: *#}}{bf:undescores} the text by adding <u>txt</u> html tag {p_end}
{synopt :{bf: #_} txt {bf: _#}}makes the text {bf:italic} by adding <em>txt</em> html tag {p_end}
{synopt :{bf: #__} txt {bf: __#}}makes the text {bf:bold} by adding <strong>txt</strong> html tag {p_end}
{synopt :{bf: #___} txt {bf: ___#}}makes the text {bf:italic and bold} by adding <strong><em>txt</em><strong> html tag {p_end}

{syntab:{ul:Page & paragraph break}}
{synopt :{bf: line-break}}breaks the text paragraphs and begins a new paragraph{p_end}
{synopt :{bf: page-break}}breaks the page and begins a new page{p_end}

{syntab:{ul:Text alignment}}
{synopt :{bf: [center]} txt {bf: [#]}}aligns the txt to the center of the page {p_end}
{synopt :{bf: [right]} txt {bf: [#]}}aligns the txt to the right side of the page{p_end}

{syntab:{ul:Text color}}
{synopt :{bf: [blue]} txt {bf: [#]}}changes the txt color to blue {p_end}
{synopt :{bf: [green]} txt {bf: [#]}}changes the txt color to green {p_end}
{synopt :{bf: [red]} txt {bf: [#]}}changes the txt color to red{p_end}
{synopt :{bf: [purple]} txt {bf: [#]}}changes the txt color to purple {p_end}
{synopt :{bf: [pink]} txt {bf: [#]}}changes the txt color to pink {p_end}
{synopt :{bf: [orange]} txt {bf: [#]}}changes the txt color to orange {p_end}

{syntab:{ul:Text background color}}
{synopt :{bf: [-yellow]} txt {bf: [#]}}changes the txt background color to yellow {p_end}
{synopt :{bf: [-blue]} txt {bf: [#]}}changes the txt background color to blue {p_end}
{synopt :{bf: [-green]} txt {bf: [#]}}changes the txt background color to green {p_end}
{synopt :{bf: [-pink]} txt {bf: [#]}}changes the txt background color to pink {p_end}
{synopt :{bf: [-purple]} txt {bf: [#]}}changes the txt background color to purple {p_end}
{synopt :{bf: [-gray]} txt {bf: [#]}}changes the txt background color to gray {p_end}
{synoptline}
{p2colreset}{...}


{title:Options}

{dlgtab:Main}

{phang}
{opt replace} replace the converted document (html, pdf, xml) if already exists{p_end}

{phang}
{opt erase} removes the {it:smclfile} after exporting it.{p_end}

{phang}
{opt keep} preserves the HTML file after exporting it to PDF. If the exporting document is
PDF, by default the HTML file is automatically removed after creating the PDF.{p_end}

{phang}
{opt e:xport(name)} specifies the file format (extension) for the exportation and creates a 
new file with a similar name as the {it:smclfile} but with the given extension. The supported
file extensions are {bf:pdf} and {bf:html}. The default format is {bf:html}.{p_end}

{phang}
{opt no:light} disables the syntax highlighter and speeds up Ketchup process.{p_end}

{phang}
{opt t:itle(str)} specifies the title of the document on the top of the first
page.{p_end}

{phang}
{opt au:thor(str)} specifies the author name (or any relevant information)
on the top of the first page.{p_end}

{phang}
{opt aff:iliation(str)} specifies authors' affiliation (or any relevant information)
under the title of the document. {p_end}

{phang}
{opt d:ate} specifies the date under the document title. To make the date appear
with the same font as the rest of the document, the code was written in JavaScript
which writes the date in the format of Month name / day / year.{p_end}

{phang}
{opt sty:le(name)} change the style of the converted document. The available styles are
{bf:modern}, {bf:classic}, {bf:stata}, {bf:plain}, {bf:elegant}, and {bf:minimal}. 
The default style is {bf:modern}. The {bf:minimal} and {bf:plain} are 
the most printer-friendly styles.{p_end}

{phang}
{opt f:ont(str)} specifies the text font for all 
headings, subheadings, paragraphs, and quotes. Each {bf:style(}name{bf:)} option automatically
applies different fonts. Therefore, use this option only if you are 
unsatisfied with the default fonts.{p_end}

{phang}
{opt pan:doc(str)} specifies the path to executable {browse "http://johnmacfarlane.net/pandoc/":Pandoc} file on the Operating System. 
This option is only for {help ketchup##trouble:Software Troubleshooting}. {p_end}

{phang}
{opt p:rinter(name)} specifies the PDF printer driver. Ketchup can use two 
different PDF Printer freeware which are 
{browse "http://www.princexml.com/":{ul:prince}xml} and {browse "http://wkhtmltopdf.org/":{ul:wk}htmltopdf}. 
In general, both printers produce a very similar
output but princexml is relatively faster and more accurate in reading the style sheets. 
You can read more about {browse "http://www.haghish.com/packages/pdf_printer.php":comparing Princexml and wkhtmltopdf PDF printers}
to find out which one meet your demands.
Princexml is the default PDF printer.{p_end}

{phang}
{opt set:path(str)} specifies the file path to the PDF printer on the 
Operating System. Use this option only if the default software that are installed in the 
{help ketchup##sof:Weaver Directory} are not functioning and Ketchup fails to produce the 
PDF document. In that case, install the software manually and provide the file path to the 
PDF printer drive (see {help ketchup##trouble:Software Troubleshooting}). {p_end}


{marker sof}{...}
{title:Software Installation}
{psee}

{pstd}
The Ketchup package requires {bf:Pandoc} to convert Markdown syntax to HTML. 
Ketchup also requires {bf:princexml} or {bf:wkhtmltopdf}
to print the HTML document to PDF.
Ketchup automatically downloads the required software on the machine and stores them in the 
Weaver directory which is located in ~/ado/plus/Weaver/. To find the location of 
ado/plus/ directory on your machine navigate to /ado/plus/ directory by typing 
{stata cd "`c(sysdir_plus)'":cd "`c(sysdir_plus)'"} in Stata command window. The usual complete
paths to the Weaver directory are shown below. Note that username refers to your machine's username.

{p 8 8 2}{bf:Windows:} {it:C:\ado\plus\Weaver} 

{p 8 8 2}{bf:Macintosh:} {it:/Users/username/Library/Application Support/Stata/ado/plus/Weaver} 

{p 8 8 2}{bf:Unix:} {it:/home/username/ado/plus/Weaver}

{pstd}
Ketchup does not install all the software at once. By default, Ketchup only installs {help ketchup##pan:Pandoc} 
and {help ketchup##prince:princexml} printer. If you specify the
{help ketchup##wk:wkhtmltopdf} printer in the options, Ketchup install the wkhtmltopdf printer
if it does not find it in Weaver directory. 


{marker trouble}{...}
{title:Software troubleshoot}

{pstd}
As mentioned, Ketchup downloads the required software automatically and does not require 
manual software installation. The default software downloaded with Ketchup is expected to 
work properly in Microsoft Windows {bf:XP}, Windows {bf:7}, and Windows {bf:8.1}, Macintosh  
{bf:OSX 10.9.5}, Linux {bf:Mint 17 Cinnamon} (32bit & 64bit), Ubuntu {bf:14} (64bit), and 
{bf:CentOS 7} (64bit). Other operating systems may require manual software installation. 

{pstd}
However, if for some technical or permission reasons Ketchup fails to download, access, or run the
required software, install the software manually and provide Ketchup the 
file path to Pandoc using {opt pan:doc(str)} option and file path to the PDF printer drive 
using {opt set:path(str)} option. visit 
{browse "http://www.haghish.com/packages/pandoc.php":Installing Pandoc for Stata packages} 
and also 
{browse "http://www.haghish.com/packages/pdf_printer.php":PDF Printers for Ketchup and Weaver} 
for more information regarding manual installation of Pandoc and PDF drivers. 


{title:Remarks}

{pstd}
Working with Ketchup requires basic 
knowledge of writing and styling text in Markdown format.
The {browse "http://www.haghish.com/statistics/stata-blog/reproducible-research/ketchup.php":Ketchup Homepage} 
(visit {browse "http://www.haghish.com/statistics/stata-blog/reproducible-research/ketchup.php":http://haghish.com/ketchup})
includes a complete tutorial for trouble-shooting the third-party software 
as well as explaining how to use Ketchup properly. There are also several 
templates do-files which are available for download that can 
serve as a good example of working with Ketchup. 
{break}

{pstd}
If the logfile is closed using "{bf:qui log c}" command, Ketchup automatically removes it 
from the end of the {it:smclfile}. However, any other command for terminating the logfile 
will be registered in the log file and will be considered a Stata command (i.e. it will be 
printed in a code box). Similarly, the {help knit} commands that is used for writing
dynamic text and the {help img} command which inserts graphs, are automatically 
removed from the document and only their outputs are maintained. In other 
words, these commands will not appear in the code boxes which distinguish Stata codes
from the outputs. 

{pstd}
Ketchup also automatically removes the "{bf:/*}" and "{bf:*/}" signs when they are used
 for writing text in the logfile. To make this feature available the "{bf:/*}" and 
"{bf:*/}" should be on a new line, keeping the rest of the line empty. Ketchup does
 not remove these signs if they are used for commenting a command or are not placed
 on a new line individually. In other words, if the comment signs appear on the same
 line after text or Stata commands, they will be preserved. Indents before or after 
the "{bf:/*}" and "{bf:*/}" are not an issue and may be used to distinct the comments from
 the Stata codes (see the example below).

{pstd}
Finally, Ketchup becomes slower when the syntax highlighter is active,
because it runs several loops for recoding Stata commands, functions, options, etc.
If your SMCL log file includes hundreds of lines you can noticeably speed up 
the process by specifying {opt no:light} option which disables syntax highlighting.
 

{title:Example}

{phang}{cmd:. qui log using example, replace}

{phang}{cmd:. local title "This is the Title"}

{phang}{cmd:. knit *- `title' -* }

{phang}{cmd:. set linesize 80}

{phang}{cmd:. set more off}

{phang}{cmd:. sysuse auto, clear}

{phang}{cmd:. histogram price}

{phang}{cmd:. graph export graph.png, replace}

    {bf:.        /*} 
    {bf:         #Introduction to Ketchup Package (heading 1)} 
    {bf:         ##Using Markdown (heading 2)}
    
    {bf:         In this a __smcl__ file which allows you to turn your}
    {bf:         _Marcdown_ to a document of any format, I will demonstrate}
    {bf:         Ketchup package by using the __Auto.dta__ dataset.}

    {bf:         ###Auto.dta (heading 3)}
    {bf:         I will simply open the dataset and describe it}
    {bf:         then I will export it to pdf}

    {bf:         #Adding a Graph to the report}
    {bf:         You can change the relative path to the graph or an absolute file path}

    {bf:         ![Importing a Graph](./graph.png)}

    {bf:         #Importing and resizing a graph, using HTML code}    
    {bf:         <img src="./graph.png" width=350 height=230 > }

    {bf:         #Highlighting text} 
    {bf:         [-yellow]You can easily highlight your text[#] or even [blue]change its color[#]}
    {bf:         */}


{phang}{cmd:. img graph.png, w(300) h(200) center }

{phang}{cmd:. list in 1/5}

{phang}{cmd:. qui log c}

{phang}{cmd:. ketchup example, export(pdf) printer(prince) title("The First Report") date}


{title:Also see}

{psee}
{space 0}{bf:{help Weaver}}: HTML & PDF Dynamic Report producer

{psee}
{space 0}{bf:{help Markdoc}}: Converting SMCL to Markdown and other formats using Pandoc

{psee}
{space 0}{bf:{help Synlight}}: SMCL to HTML convertor and syntax highlighter

