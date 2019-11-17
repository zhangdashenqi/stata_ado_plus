{smcl}
{* 5/6/14}{...}
{cmd:help graphout}{right: ({browse "http://www.stata-journal.com/article.html?article=gr0060":SJ14-4: gr0060})}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{cmd:graphout} {hline 2}}Save graphs to a file{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 11 2}
{cmd:graphout} {cmd:using} {it:filename}{cmd:.}{it:extension} [{cmd:,} {it: options}]

{pstd}
The file format can be RTF, TeX, or HTML and must be specified in
{cmd:.}{it:extension} of {it:filename}{cmd:.}{it:extension}.
{cmd:.rtf} produces an RTF file for use with word processors, {cmd:.html} produces an HTML file, and {cmd:.tex} produces a LaTeX file.
{p_end}


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Output (HTML, RTF, and TeX)}
{synopt:{cmdab:rep:lace}} overwrite an existing file {p_end}
{synopt:{cmdab:app:end}} append the output to an existing file {p_end}

{syntab:Size (HTML and TeX only)}
{synopt:{cmdab:height(}{it:string}{cmd:)}} adjust the height of graphs {p_end}
{synopt:{cmdab:width(}{it:string}{cmd:)}} adjust the width of graphs {p_end}
{synopt:{cmdab:scale(}{it:numlist}{cmd:)}} adjust the scale of graphs {p_end}

{syntab:Layout (RTF, HTML, and TeX)}
{synopt:{cmdab:align:ment(}{it:string}{cmd:)}} center, right-align, or left-align the
graphs {p_end}

{syntab:Text (RTF, HTML, and TeX)}
{synopt:{cmdab:noc:ount}} do not add "Figure #" to each graph{p_end}
{synopt:{cmdab:base:count(}{it:numlist}{cmd:)}} specify the starting # for "Figure #"{p_end}

{syntab:Advanced (TeX only)}
{synopt:{cmdab:place:ment(}{it:string})} specify the placement of a float in
TeX file {p_end}
{synopt:{cmdab:fbar:rier(}{it:#}{cmd:)}} add "{cmd:\FloatBarrier}" command to every
graph in TeX file{p_end}
{synopt:{cmdab:doc:ument}} make a stand-alone TeX document {p_end}
{synopt:{cmdab:lab:el(}{it:string}{cmd:)}} add "{cmd:\label}{{it:string}}" to
TeX
files {p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:graphout} saves graphs to a text file specified by {cmd:using}
{it:filename}{cmd:.}{it:extension}, where {cmd:.}{it:extension} can be
{cmd:.rtf} for RTF, {cmd:.html} for HTML, or {cmd:.tex} for TeX files.
The {cmd:.}{it:extension} for file names must be specified.  HTML files
require graphs to be in PNG format.{p_end}

{pstd}
RTF, HTML, and TeX files created by {cmd: graphout} are linked to the
specified graphs stored by {cmd:graphsto}. To embed graphs, one must
convert HTML and RTF files to PDFs and typeset TeX files.{p_end}


{marker opt}{...}
{title:Options}

{dlgtab:Output (HTML, RTF, and TeX)}

{phang}
{cmd:replace} overwrites an existing file.{p_end}

{phang}
{cmd:append} appends the output to an existing file.{p_end}

{dlgtab:Size (HTML and TeX)}

{phang}
{cmd:height(}{it:string}{cmd:)} specifies the height of the graphs in
TeX or HTML files.{p_end}

{phang}
{cmd:width(}{it:string}{cmd:)} specifies the width of the graphs in TeX
or HTML files.  For TeX files, {it:string} should be a nonnegative
number along with the unit of measure ({cmd:mm}, {cmd:cm}, {cmd:in}).
For example, to create a file with graphs that are 5 inches tall by 5
inches wide, type {cmd:height(5in)} {cmd:width(5in)}.  In HTML mode,
{it:string} should only be a nonnegative number that refers to the
number of pixels.  For example, to create a file with graphs that are
100 pixels tall by 100 pixels wide, type {cmd:height(100)}
{cmd:width(100)}.{p_end}

{phang}
{cmd:scale(}{it:numlist}{cmd:)} specifies how to scale the graphs in TeX or HTML
files and must range between zero and one.  For HTML and TeX files,
{it:#} should be a nonnegative number between zero and one.  For example, to
create a file with graphs that are half the size of the original graphs, type
{cmd:scale(.5)}.{p_end}

{dlgtab:Layout (RTF, HTML, and TeX)}

{phang}
{cmd:alignment(}{it:string}{cmd:)} specifies the alignment of the
graphs.  {it: string} should be one of the following alignments:
{cmdab:c:enter}, {cmdab:r:ight}, {cmdab:l:eft}.{p_end}

{dlgtab:Text (RTF, HTML, and TeX)}

{phang}
{cmd:nocount} specifies that "{cmd:Figure}{it:#}" not be added before each
graph.{p_end}

{phang}
{cmd:basecount(}{it:numlist}{cmd:)} specifies the starting {it:#} for "{cmd:Figure} {it:#}".{p_end}  
{dlgtab:Advanced (TeX)}

{phang}
{cmd:placement(}{it:string}{cmd:)} adjusts the placement of 
a float in a LaTeX document.{p_end}  
        {it:string}{col 20}Figure is placed at
	{hline}
	{cmd:h}{col 20}{...}roughly the location in the source text 
	
	{cmd:t}{col 20}{...}the top of the page
	
	{cmd:b}{col 20}{...}the bottom of the page
	
	{cmd:p}{col 20}{...}a special page for floats only

	{cmd:H}{col 20}{...}precise location in text (requires "{cmd:float}" package) 
	
	{hline}

{phang}
{cmd:fbarrier(}{it:#}{cmd:)} adds the {cmd:\FloatBarrier} command to every graph.  If {cmd:document} is specified, the {cmd:placeins} package is added to the TeX file.  If not, the {cmd:placeins} package must be added manually to the main TeX document.
In LaTeX documents, too many floats can cause an error -- "{cmd:Too many unprocessed floats}". This option will avoid this error.{p_end}  
{phang}
{cmd:document} adds {cmd:\documentclass}{article}, {cmd:\usepackage}{graphicx}, and
{cmd:\begin}{document} to the beginning of the TeX document and {cmd:\end}{document} to the 
end of the document.{p_end}

{phang}
{cmd:label(}{it:string}{cmd:)} adds {cmd:\label}{{it:string}} to the TeX file.  This option automatically turns figures into floats.{p_end}  

{marker examples}{...}
{title:Examples}

{phang}Below are several basic examples of {cmd: graphout}{p_end}
	{cmd:. sysuse auto}
	{txt}(1978 Automobile Data)

{phang}
Add graphs to an HTML file{p_end}
	{cmd:. histogram price, frequency}
	{txt}(bin=8, start=3291, width=1576.875)
	{cmd:. graphsto g1.png, replace title(Price histogram)}
	{txt}(file g1.png written in PNG format)
	{cmd:. graphout using example.html, replace scale(.5)}
	{txt}(file example.html written in HTML format)
	{cmd:. graph twoway scatter price mpg}
	{cmd:. graphsto g2.png, replace title(Price MPG scatter)}
	{txt}(file g2.png written in PNG format)
	{cmd:. graphout using example.html, append scale(.5)}

{phang}
Add graphs to a TeX file{p_end}
	{cmd:. histogram price, frequency}
	{txt}(bin=8, start=3291, width=1576.875)
	{cmd:. graphsto g3.eps, replace title(Price histogram) note(Now with LaTeX)} 
	{txt}(file g3.eps written in EPS format)
	{cmd:. graphout using example.tex, replace scale(.5) align(c)} 
	{txt}(file example.tex written in TeX format)
	{cmd:. graph twoway scatter price mpg}
	{cmd:. graphsto g4.eps, replace title(Price MPG scatter)} 
	{txt}(file g4.eps written in EPS format)
	{cmd:. graphout using example.tex, append scale(.5) align(c)}

{phang}
Add graphs to an RTF file{p_end}
	{cmd:. histogram trunk, frequency}
	{txt}(bin=8, start=5, width=2.25)
	{cmd:. graphsto g5.eps, replace title(Price histogram)}
	{txt}(file g5.eps written in EPS format)
	{cmd:. graphout using example.rtf, replace align(l)}
	{txt}(file example.rtf written in RTF format)
	{cmd:. graph twoway scatter price weight}
	{cmd:. graphsto g6.eps, replace title(Price MPG scatter)}
	{txt}(file g6.eps written in EPS format)
	{cmd:. graphout using example.rtf, append align(l)}


{marker Author}{...}
{title:Author}

{pstd}Joseph D. Wolfe{p_end}
{pstd}University of Alabama at Birmingham{p_end}
{pstd}Birmingham, AL{p_end}
{pstd}jdwolfe@uab.edu{p_end}


{marker also_see}{...}
{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 14, number 4: {browse "http://www.stata-journal.com/article.html?article=gr0060":gr0060}

{p 5 14 2}Manual:  {manhelp graph G-2}

{p 7 14 2}Help:  {helpb graphsto},{break}
{manhelp graph_intro G-1:graph intro},
{manhelp graph_export G-2: graph export}
{p_end}
