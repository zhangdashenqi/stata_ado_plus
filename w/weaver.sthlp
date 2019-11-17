{smcl}
{right:Version 1.4 : October, 2014}
{cmd:help Weaver}
{hline}

{phang}
{bf:weaver} {hline 2} A module for literate statistical practice which produces HTML & 
PDF dynamic reports from Stata Do-file Editor. The main idea of the Weaver package is to
provide the possibility of deciding which codes of the do-file should appear in the 
dynamic report and which should not. In other words, Weaver allows Stata users to do 
exploratory data analysis and select which commands, outputs, and comments should appear 
in the dynamic report. Weaver also provides commands and options for writing text using 
{browse "http://www.haghish.com/statistics/stata-blog/reproducible-research/dynamic_documents/markdown.php":Markdown syntax}, 
writing dynamic text (printing {help Macros} content in the text) and styling dynamic text 
using {browse "http://www.haghish.com/statistics/stata-blog/reproducible-research/dynamic_documents/additional_markup.php":Additional Markup Codes}, 
 adding and resizing graphs, adding title page and automate table of content, changing 
 font color and highlighting text, and also, getting a live-preview of the HTML and PDF 
 document as you are weaving the analysis. Visit 
{browse "http://www.haghish.com/statistics/stata-blog/reproducible-research/weaver.php":http://haghish.com/weaver} 
for a complete tutorial on Weaver as well as downloading template do-files. 


{title:Author} 
        {p 8 8 2}E. F. Haghish{break} 
	Center for Medical Biometry and Medical Informatics{break}
	University of Freiburg, Germany{break} 
        {browse haghish@imbi.uni-freiburg.de}{break}
	{browse "http://www.haghish.com/statistics/stata-blog/reproducible-research/weaver.php":{it:http://haghish.com/weaver}}{break}
   


{title:Weaver Commands' Syntax}

{p 8 17 2}
{cmdab:weave} using {it:filename} [{cmd:,} {it:replace} {it:append} {it:erase} {it:date} 
{it:unbreak} {it:title(str)} {it:author(str)} {it:affiliation(str)} {it:address(str)} 
{it:runhead(str)} {it:summary(str)} {it:scheme(name)} {it:style(name)} {it:font(str)}  
{it:contents} {it:landscape} {it:printer(name)} {it:setpath(str)} {it:pandoc(str)}]

{p 8 17 2}
{cmdab:weavend} 

{p 8 17 2}
{cmdab:m:arku}{cmdab:p:} [{it:smclfile}]

{p 8 17 2}
{cmdab:m:ark}{cmdab:d:own} [{it:filename}] [, {it:erase} {it:html}]

{p 8 17 2}
{cmdab:div} {it:command}

{p 8 17 2}
{cmdab:codes} {it:command}

{p 8 17 2}
{cmdab:results} {it:command}

{p 8 17 2}
{cmdab:img} {it:path/filename.suffix} [{cmd:,} {it:width(int)} {it:height(int)} {it:left} 
{it:center} {it:right}]

{p 8 17 2}
{cmdab:quo:te} {it:"string"}

{p 8 17 2}
{cmdab:kn:it} {it:"string"}

{p 8 17 2}
{cmdab:html} {it:"string"}

{p 8 17 2}
{cmdab:linebreak}

{p 8 17 2}
{cmdab:pagebreak}

{p 8 17 2}
{cmdab:report} [{it:htmlfiles.html}] [{cmd:,} {it:export(name)} {it:printer(name)} {it:setpath(str)}]


{title:Options}

{dlgtab:weave options}

{phang}{opt replace} replaces the HTML file if already exists{p_end}

{phang}{opt append} appenda more content to the existing HTML file{p_end}

{phang}{opt erase} remove the HTML file after producing the PDF docuemnt{p_end}

{phang}{cmdab:un:break:} remove page-break between the title page, table of contents, and 
the rest of the document{p_end}

{phang}{cmdab:t:itle:(}{it:string}{cmd:)} name the HTML file in the <title> tag 
and prints the title of the document on the first page{p_end}

{phang}{cmdab:au:thor:(}{it:string}{cmd:)} prints the author name on the first page of the
 report{p_end}

{phang}{cmdab:aff:iliation:(}{it:string}{cmd:)} prints the author's affiliation 
(or any preferred relevant information) on the first page{p_end}

{phang}{cmdab:add:ress:(}{it:string}{cmd:)} prints the author's contact information 
(or any preferred relevant information) on the first page{p_end}

{phang}{cmdab:d:ate} prints the date on the first page{p_end}

{phang}{cmdab:sty:le:(}{it:name}{cmd:)} change the style of the document. The available 
styles are
{bf:modern}, {bf:classic}, {bf:stata}, {bf:elegant}, and {bf:minimal}. 
The {bf:modern} style is the default style. Each style automatically applies a particular 
{help scheme}, only for the duration of weaving the document. The default scheme of
user's Stata will be restored with the {cmd:weavend} command.{p_end}

{phang}{cmdab:nos:cheme} preserves the current scheme and does not allow the 
{bf:style} option to change the scheme. {p_end}

{phang}{cmdab:f:ont:(}{it:string}{cmd:)} specifies the text font for all 
headings, subheadings, paragraphs, and quotes. Each {cmdab:sty:le:(}{it:name}{cmd:)}
option automatically
applies different fonts. Therefore, use this option only if you are 
unsatisfied with the default fonts.{p_end}

{phang}{cmdab:cont:ents} add an automatic table of contents and create a reference link 
to the coresponding headings{p_end}

{phang}{cmdab:land:scape} flips the page to the landscape mode to increase the width of 
the report{p_end}

{phang}{cmdab:run:head:(}{it:string}{cmd:)} add a running head to the top-left corner of 
the report{p_end}

{phang}{cmdab:sum:mary:(}{it:string}{cmd:)} add a summary paragraph to the first page of 
the report. This option can be used for writing abstract or summary of the report.{p_end}

{phang}{cmdab:p:rinter:(}{it:name}{cmd:)} defines the name of the PDF printer and 
it can be {cmdab:prince:xml} or {cmdab:wk:htmltopdf}. For more information regarding 
these two PDF printers see 
{browse "http://www.haghish.com/packages/pdf_printer.php":{it:PDF Printers for Ketchup and Weaver}}
{p_end}

{phang}{cmdab:set:path:(}{it:string}{cmd:)} defines the file path to the 
specified printer. This option is only needed if the PDF printer that is automatically installed in 
the {bf:~/ado/plus/Weaver} directory is not working properly. If Weaver fails to produce 
PDF outputs, install the PDF drive manually and provide the file path using this option. 
See {help weaver##trouble:Software troubleshoot} for more details.{p_end}

{phang}{cmdab:pan:doc(str)} specify the path to Pandoc on the Operating System. This option 
is only needed if Pandoc software that is installed in 
the {bf:~/ado/plus/Weaver} directory is not working properly.
See {help weaver##trouble:Software troubleshoot} for more details.{p_end}


{dlgtab:img options}

{phang}{cmdab:w:idth:(}{it:int}{cmd:)} resizes the width of the image{p_end}

{phang}{cmdab:h:eight:(}{it:int}{cmd:)} resizes the height of the image{p_end}

{phang}{opt left} aligns the image in the left side of the document. This is the default condition{p_end}

{phang}{opt center} aligns the image in the center{p_end}

{phang}{opt right} aligns the image in the right{p_end}


{dlgtab:markdown options}

{phang}{opt html} If {it:filename} is specified, 
indicates that the {it:filename} is in the HTML format rather than SMCL{p_end}

{phang}{opt erase} If {it:filename} is specified,
removes the smclfile after appending it to the Weaver report{p_end}



{dlgtab:report options}

{phang}{cmdab:e:xport:(}{it:name}{cmd:)} defines the name of the PDF output. No suffix needed{p_end}

{phang}{cmdab:p:rinter:(}{it:name}{cmd:)} defines the name of the PDF printer and it can be 
{cmdab:prince:xml} or {cmdab:wk:htmltopdf}. This option is only needed if the {bf:report}  
command is used independent of the {bf:weave} command, to print a PDF from a HTML document
 on your machine{p_end}

{phang}{cmdab:set:path:(}{it:string}{cmd:)} defines the file path to the 
specified printer. Similar to the {cmd:weave} command, this option is only needed if the 
PDF printer that is automatically installed in 
the {bf:~/ado/plus/Weaver} directory is not working properly. If Weaver fails to produce 
PDF outputs, install the PDF drive manually and provide the file path using this option. 
See {help weaver##sof:Software Installation} for more details. If the {opt setpath(str)} option is 
defined in the {cmd:weave} command, this option does not need to be defined in {cmd:report}
command.{p_end}


{title:Description}

{pstd}
The {bf:Weaver} package provides a set of commands for writing and styling a dynamic report 
in Stata using Stata Do-file Editor. Weaver facilitate writing text by making Markdown 
codes available for writing text and importing graphs.
Furthermore, the {bf:additional markup codes} were defined to provide the possibility of 
changing text color and highlighting text as well as styling dynamic text.

{pstd}
What makes Weaver different from the {help ketchup} package - which also create HTML and 
PDF dynamic reports- is that Weaver can select 
what Stata commands, outputs, text, and comments to appear in the dynamic 
document and what content should be ignored in the report. This feature is particularly 
interesting because it avoids starting a new do-file for creating the dynamic document. 
In addition, Weaver also allows to suppress Stata commands or outputs. In other words, 
it can quietly run a Stata command without printing an output, or in contrast, print 
outputs of a command without printing the command. This allows to hide some commands or 
outputs which are very technical and not of interest of people that the report is shared 
with.

{pstd}
The biggest advantage of Weaver compared to {help ketchup} is 
that it does not need to be compiled. In fact, Weaver is a HTML-based logfile that stores
text, commands, and output in {it:HTML} format rather than {it:SMCL}. As a result, the document 
can be live-viewed in HTML (opening the html logfile and refreshing the browser) and PDF 
(using {cmd:report} command) at any point. 


{pstd}
The commands that are used for writing and styling the dynamic report in Weaver are explained below.


{synoptset 38}{...}
{p2col:Command}Description{p_end}
{synoptline}
{synopt :{cmd:weave }using {it:filename} [{cmd:,} {it:options}]}creates a HTML document 
for the dynamic report. Therefore, the dynamic report begins with this command. weave can 
accept several options that determine the title, author name, author information and 
affiliation, date, running head, summary of the report, table of content, scheme 
(for graphs), report's style, report's page format (A4 regular or A4 landscape), 
and the printer's options.{p_end}


{synopt :{cmd:weavend}}closes the HTML file and prints the PDF document, if the PDF 
printer is installed. weavend also automatically opens the PDF report. The document
 ends with this command.{p_end}


{synopt :{cmdab:m:arku}{cmdab:p:} {it:[smclfile]}} {cmd:Markup} command which can be abbreviated as "{bf:mp}", 
automatically opens a temporary smcl logfile.
Defining the name of the smclfile is optional. If no name is defined, 
markup automatically names the smclfile as {it:markdown.smcl} and replaces 
any file with this name if already exists. The {it:markdown.smcl} file would
be a temporary logfile and automatically will be terminated and erased by the 
{bf:markdown} command. {p_end}

{p 46 46 2}The main function of markup command is opening a smclfile for reading the 
text that is written in the form of {help comments} i.e. written between 
{bf:"/*"} ... {bf:"*/"} or after {bf:"//"} or {bf:"*"} signs. Any text (not Stata commands)
 should be written after {cmd:markup} command in order to appear in the document.  


{synopt :{cmdab:m:ark}{cmdab:d:own} [{it:filename}] [, {it:options}]}{cmd:markdown} 
command which can be abbreviated as "{bf:md}", performs 3 different tasks: 

{p 46 46 2}
If no filename is specified, markdown reads the temporary smcl logfile from the {bf:markup} 
command to close the logfile and append it to the document. To do so, {cmd:markdown} 
command translates the smclfile into HTML and then appends it to Weaver's document. 
 
{p 46 46 2}
If the smcl filename is specified, {cmd:markdown} repeats the same process and attach the 
translated HTML to the document. Therefore, an external smcl logfile can be appended to the 
Weaver's document. 

{p 46 46 2}
{cmd:markdown} can also append an HTML file to the document. To do so, in addition to the 
filename (path/name of the html file), the "{bf:html}" option should also be specified. 
Note that the linesize of the external smcl or html file should be equal or less than 80. {p_end}


{synopt :{cmd: div }{it:command}}separates the Stata command from the results by putting 
them into different boxes. Based on the selected style in the {bf:weaver} command, 
the font, color, and boarders of the boxes varies. Only Stata commands that begin with the 
{cmd:div} command will appear in the document. Therefore commands that do not begin with 
{cmd:div} will be run by Stata but ignored in the document. {p_end}


{synopt :{cmdab:cod:es} {it:command}}prints the Stata command syntax in a code box and 
suppresses the results from the report. Use the command in occasions when you 
only want to include the command in the document and omit the Stata output. Note that 
the output will only be suppressed from the document but Stata will quietly run the 
codes. {p_end}


{synopt :{cmdab:res:ults} {it:command}}prints the Stata output without
showing the command code. Use it when you want to omit the Stata codes.{p_end}


{synopt :{cmd: img }{it:path/filename.suffix} [, {it:options}]}
inserts image to the report. The image can be resized using {bf:width}
 and {bf:height} options and also be placed on the left, center, or right
 side of the document page. {p_end}

{p 46 46 2}If the image is located in the working directory, only 
specifying the filename.suffix would be enough to insert the image 
in the report. If the image is in a different folder, the complete
 path to the image file or alternatively, the relative path to the image 
should be specified. The graph/image 
should be in a format recognizable by web browsers 
(e.g. PNG, JPEG, etc). 


{synopt :{cmdab:quo:te} {it:"string"}}creates a quote text box which 
is aligned to the center of the document and has a background color to make 
the text more distinctive. This is useful for writing a summary or conclusion that 
you wish to emphasis. {p_end}


{synopt :{cmdab:kn:it} {it:"string"}}{cmd:knit} command can be used to write dynamic text, i.e. 
text that includes {help macros}.
In addition, it provides the possibility of writing text inside a Stata program.
the {cmd:knit} command can make use of the {help weaver##additional:additional markup codes}
 for styling the text. {p_end}


{synopt :{cmd: html }{it:"string"}}adds HTML 
(or any other web language scripts) to the report. 
This is an advanced command for those who know a web language 
and wish to add something to the document which is not 
supported by Weaver package. To do so, include the script as a string
after the command. {p_end}


{synopt :{cmd: linebreak }}adds a <br /> tag to the report which adds an empty line. 
This command can be used to add space between objects or text in the document.{p_end}


{synopt :{cmd: pagebreak}}breaks the page and begins a new page in the document. 
When used, the next command will appear on the top of the next page. Page-breaks only 
appear in the PDF document but not the HTML.{p_end}


{synopt :{cmd: report } [{it:filename.suffix}] [, {it:options}]}
produces the PDF document at any time while working on the document.
 It can also be used to create a PDF out of existing HTML document as well. 
The main purpose of this command is to provide a PDF check while
you are weaving a document. {p_end}

{p 46 46 2}If no filename and option is specified, the command will
look for filename, printer name, and printer path from the {cmd:weave}
command and prints a PDF of the current HTML document, without 
terminating the document.

{p 46 46 2}If {cmd:report} is used independent of {cmd:Weaver} to produce a PDF document
from a HTML file, 
the existing file should be in HTML, XHTML, or XML formats. 
{p_end}

{synoptline}
{p2colreset}{...}



{title:Markdown codes}

{p 4 4 2}
{browse "http://daringfireball.net/projects/markdown/":Markdown}
is a text-to-HTML convertor which allows writing  
and styling plain text format and converting it to HTML.
Markdown provides a simple solution for writing headings and subheadings, adding links, 
creating a list, separating paragraphs, and also adding images to the document. 
For a complete guide on markdown codes and applying them in Weaver, 
visit {browse "http://haghish.com/statistics/stata-blog/reproducible-research/dynamic_documents/markdown.php":Writing with Markdown in Stata}. {break} 


{title:Additional markup codes}

{p 4 4 2}The following Markup codes are added to the Weaver package. These codes can be
 used along with other Markdown codes, as well as other commands such as {cmd: knit} and 
 {cmd: html}. The additional markup codes are not meant to replace the Markdown syntax. 
 Instead, they are providing additional capabilities for styling text, such as changing 
 font color and highlighting text. The additional markup codes are particularly important 
 for styling dynamic text. visit 
 {browse "http://haghish.com/statistics/stata-blog/reproducible-research/dynamic_documents/additional_markup.php":Additional Markup Codes}
 for more information. {break} 

{synoptset 22}{...}
{marker additional}
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

{syntab:{ul:Link}}
{synopt :{bf: [-- "}link{bf:" --][- }txt{bf:  -]}}assigns a link to the corresponding txt {p_end}

{synoptline}
{p2colreset}{...}


{title:Required Software}
{psee}

{pstd}
The Weaver package requires {browse "http://johnmacfarlane.net/pandoc/":Pandoc} 
to convert Markdown syntax to HTML. 
Weaver also requires {browse "http://www.princexml.com/":Princexml} or 
{browse "http://wkhtmltopdf.org/":wkhtmltopdf}
to print the HTML document to PDF. Weaver automatically download these software in the 
{help weaver##sof:Weaver directory}. These software are further described below.

{marker pan}{...}
{phang}
{bf:Pandoc} is a markup convertor and can support several formats including HTML,
XHTML, XML, LaTeX, Docx, Markdown, PDF (via LaTex), EPUB, etc. 
Pandoc helps to translate Markdown codes into HTML.
To read more about Pandoc visit 
{browse "http://johnmacfarlane.net/pandoc/index.html":{it:johnmacfarlane.net}}. 

{marker prince}{...}
{phang}
{bf:Princexml} is an advanced HTML to PDF printing component for Windows, Mac, 
and Unix, which is hosted at {browse "http://princexml.com":{it:princexml.com}}. 
Prince is a quick printer and it carefully reads and implements the CSS 
script and applies it on the PDF file. Because of this feature, prince is 
the default PDF printer in Weaver. The free version 
of princexml will leave a trademark on the first page of the PDF which is removable 
by clicking it and hitting backspace or delete keys. 

{marker wk}{...}
{phang}
{bf:wkhtmltopdf} is a free open source (LGPL) command line tools to render HTML into PDF.
Compared to princexml, the wkhtmltopdf is relatively slower and is not as accurate as 
princexml in rendering the CSS styles. However, in contrast to princexml, wkhtmltopdf does 
not leave a trademark on the PDF output. The application is available for Windows, Mac, 
and Unix on {browse "http://wkhtmltopdf.org":{it:wkhtmltopdf.org}}.


{marker sof}{...}
{title:Software Installation}
{psee}

{pstd}
The required software i.e. Pandoc, Princexml, and wkhtmltopdf are downloaded and placed in Weaver 
directory which is located in {bf:~/ado/plus/Weaver/} on your machine. To find the location of 
ado/plus/ directory on your machine navigate to /ado/plus/ directory by typing 
{stata cd "`c(sysdir_plus)'":cd "`c(sysdir_plus)'"} in Stata command window. The usual complete
paths to the Weaver directory are shown below. Note that username refers to your machine's username.

{p 8 8 2}{bf:Windows:} {it:C:\ado\plus\Weaver} 

{p 8 8 2}{bf:Macintosh:} {it:/Users/username/Library/Application Support/Stata/ado/plus/Weaver} 

{p 8 8 2}{bf:Unix:} {it:/home/username/ado/plus/Weaver}

{pstd}
Weaver does not install all the software at once. By default, it only installs Pandoc 
and princexml printer. If the wkhtmltopdf printer is specified
in the options, Weaver installs the wkhtmltopdf printer instead of princexml if it does 
not find it in the /ado/plus/Weaver/ directory. 

{pstd}
Alternatively, you may install the PDF printer drives manually and use the {it:setpath(str)}
option to specify the path to the PDF drive on your machine. 
visit {browse "http://haghish.com/weaver"} for more details. 


{marker trouble}{...}
{title:Software troubleshoot}

{pstd}
As mentioned,Weaver downloads the required software automatically. The default software 
downloaded with Weaver are expected to 
work properly in Microsoft Windows {bf:XP}, Windows {bf:7}, and Windows {bf:8.1}, Macintosh  
{bf:OSX 10.9.5}, Linux {bf:Mint 17 Cinnamon} (32bit & 64bit), Ubuntu {bf:14} (64bit), and 
{bf:CentOS 7} (64bit). Other operating systems may require manual software installation. 

{pstd}
However, if for some technical or permission reasons Weaver fails to download, access, or run 
Pandoc or any of the PDF drivers, install them manually and provide the 
file path to Pandoc using {opt pan:doc(str)} option and file path to the PDF driver using 
{opt set:path(str)} option. visit 
{browse "http://www.haghish.com/packages/pandoc.php":Installing Pandoc for Stata packages}  
and also {browse "http://www.haghish.com/packages/pdf_printer.php":PDF Printers for Ketchup and Weaver} 
for more information regarding manual installation of Pandoc and PDF drivers. 


{title:Remarks}
{psee}

{pstd}
Weaver interacts with the operating system for installing, creating, replacing, and removing files. 
Make sure that you run Stata as administrator. In addition, check permissions of the working 
directory. Stata should be allowed to remove or replace files in the working directory. 


{title:Example}

{p 4 12 2}{cmd:. weave} using {it:example1}, {bf:replace} {bf:date} {bf:contents} {bf:scheme}(minimal) ///{break}
{bf:title}("Stata Weaver Package") {bf:author}("E. F. Haghish") {bf:printer}(prince) ///{break}
{bf:affiliation}("University of Freiburg") {bf:runhead}("Example 1 report") ///{break}

{phang}{cmd:. markup} 

{p 18 18 2}/* {break}

{p 18 18 2}
	Introduction to Stata Weaver Package{break}
	===================================={break}

{p 18 18 2}
	Part 1: Weaver commands	{break}
	----------------------- {break}
	
{p 18 18 2}	
	the Weaver package is a suitable tool for writing dynamic reports {break}	
	in Stata and it provide all the accessories and tools of {break}
	TextEdit  or Notepad software in Stata Do-file Editor.{break} 
	To see more example do-files and {bf:__}DOWNLOAD TEMPLATE DO-FILES{bf:__} {break} 
	visit [Weaver Homepage](http://http://www.haghish.com/weaver/){break}
	
	{p 18 18 2}###basics{break}
	In this example, I will show you how to perform the very {break}
	basic tasks in Weaver, using the Auto.dta dataset.{break}
	note that these Markup text is written between {bf:/*} and {bf:*/}, {break}
	each on a separate line. Also, the text is note that the text {break}
	follows the {bf:markup} command and ends with the {bf:markdown} command.{break} 

{p 18 18 2}In this example you will learn:{break}

{p 18 18 2}
    - How to weave!{break}
	- How use the {bf:markup} and {bf:markdown} commands{break}
	- How to use Markdown codes to create titles & write a paragraph{break}
	- How to create a bullet list{break}
	- And finally, how to insert an image in your document{break}


{p 18 18 2}Part 2: text and background color	{break}
		   --------------------------------- {break}

{p 18 18 2}		   
	next I will show you how to change the text color and highlight text.{break}
	To change the color, you can use the additional Markup codes. [blue] {break} 
	color name inside a square brackets can be used to change the font {break}
	color [#]. [#yellow] Alternatively, hashtag plus a color name e.g. {break}
	#yellow inside a square brackets can be used to highlight text [#]. {break}
	Note that both codes should end with a hashtag inside a square {break}
	brackets to stop the change.{break}

{p 18 18 2}*/{break} 

{phang}{cmd:. markdown}

{phang}{cmd:. div sysuse} auto {break}

{phang}{cmd:. div list} in 1/5 {break}

{phang}{cmd:. div hist} mpg {break}

{phang}{cmd:. div graph export} graph.png, replace {break}

{phang}{cmd:. img} graph.png {break}

{phang}{cmd:. pagebreak}{break}

{phang}{cmd:. markup} 

{p 18 18 2}// You can also change the width and height of the image{break}
	// and align it to the left, center, or the right side of the document{break}
	
{phang}{cmd:. markdown}

{phang}{cmd:. img} graph.png, w(600) h(400) center {break}

{phang}{cmd:. weavend}



{title:Acknowledgement}

{p 4 4 2}After reading an article by Quinto, Sanz, Lazzari, & Aponte (2012) entitled 
"HTML output in Stata", I improved some parts of the Weaver program based on their 
programming tricks for temporarily storing Stata output. 


{title:Also see}

{psee}
{space 0}{bf:{help Ketchup}}: Converting SMCL to a modern-looking HTML or PDF using Pandoc

{psee}
{space 0}{bf:{help Markdoc}}: Converting SMCL to any format using Pandoc

{psee}
{space 0}{bf:{help Synlight}}: SMCL to HTML translator and syntax highlighter

