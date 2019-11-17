{smcl}
{* 5/6/14}{...}
{cmd:help graphsto}{right: ({browse "http://www.stata-journal.com/article.html?article=gr0060":SJ14-4: gr0060})}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{cmd:graphsto} {hline 2}}Collect graphs for graphout{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 11 2}
{cmd:graphsto} {it:graphname}{cmd:.}{it:suffix} [{cmd:,}
{cmd:title(}{it:string}{cmd:)} {cmd:note(}{it:string}{cmd:)} {cmd:replace}
{cmdab:dir:ectory} {cmd:clear}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:graphsto} is a wrapper for {cmd:graph export}.  {cmd:graphsto}
exports graphs as the output format specified by {cmd:.}{it:suffix},
where {it:suffix} can be a variety of file types ({cmd:.eps},
{cmd:.png}, etc.); see {manlink G-2 graph export} for a full list of file types.  {cmd:graphsto} can also store
graph titles and notes.

{pstd}
{cmd:graphout} constructs an RTF, an HTML, or a TeX file that contains links to
the graphs stored by {cmd:graphsto}. See {helpb graphout} for more information on this command. 


{marker options}{...}
{title:Options}

{phang}{cmd:title(}{it:string}{cmd:)} adds a title above each graph.

{phang}{cmd:note(}{it:string}{cmd:)} adds a note below each graph.

{phang}{cmd:replace} overwrites an existing file.

{phang}{cmd:directory} lists the graph names stored in the global macro.

{phang}{cmd:clear} clears the graph names stored in the global macro.


{marker examples}{...}
{title:Examples}

{p 4 8 2}
Below are several basic examples using {cmd: graphsto} with {cmd:graphout}{p_end}
{phang2}{cmd:. sysuse auto}{p_end}
	{txt}(1978 Automobile Data)

{p 4 8 2}
Add graphs to an HTML file{p_end}
{phang2}{cmd:. histogram price, frequency}{p_end}
	{txt}(bin=8, start=3291, width=1576.875)
{phang2}{cmd:. graphsto g1.png, replace title(Fig1: Price histogram)}{p_end}
	{txt}(file g1.png written in PNG format)
{phang2}{cmd:. graphout using example.html, replace scale(.5)}{p_end}
	{txt}(file example.html written in HTML format)
{phang2}{cmd:. graph twoway scatter price mpg}{p_end}
{phang2}{cmd:. graphsto g2.png, replace title(Fig2: Price MPG scatter)}{p_end}
	{txt}(file g2.png written in PNG format)
{phang2}{cmd:. graphout using example.html, append scale(.5)}{p_end}

{p 4 8 2}
Add graphs to a TeX file{p_end}
{phang2}{cmd:. histogram price, frequency}{p_end}
	{txt}(bin=8, start=3291, width=1576.875)
{phang2}{cmd:. graphsto g3.eps, replace title(Price histogram) note(Now with LaTeX)}{p_end}
{phang2}{txt}(file g3.eps written in EPS format){p_end}
{phang2}{cmd:. graphout using example.tex, replace scale(.5) align(c)}{p_end}{phang2}{txt}(file example.tex written in TeX format){p_end}
{phang2}{cmd:. graph twoway scatter price mpg}{p_end}
{phang2}{cmd:. graphsto g4.eps, replace title(Price MPG scatter)}{p_end}{phang2}{txt}(file g4.eps written in EPS format){p_end}
{phang2}{cmd:. graphout using example.tex, append scale(.5) align(c)}{p_end}

{p 4 8 2}
Add graphs to an RTF file{p_end}
{phang2}{cmd:. histogram trunk, frequency}{p_end}
	{txt}(bin=8, start=5, width=2.25)
{phang2}{cmd:. graphsto g5.eps, replace title(Fig1: Price histogram)}{p_end}
	{txt}(file g5.eps written in EPS format)
{phang2}{cmd:. graphout using example.rtf, replace align(l)}{p_end}
	{txt}(file example.rtf written in RTF format)
{phang2}{cmd:. graph twoway scatter price weight}{p_end}
{phang2}{cmd:. graphsto g6.eps, replace title(Fig2: Price MPG scatter)}{p_end}
	{txt}(file g6.eps written in EPS format)
{phang2}{cmd:. graphout using example.rtf, append align(l)}{p_end}


{marker Author}{...}
{title:Author}

{pstd}Joseph D. Wolfe{p_end}
{pstd}University of Alabama at Birmingham{p_end}
{pstd}Birmingham, AL{p_end}
{pstd}jdwolfe@uab.edu{p_end}


{marker also_see}{...}
{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 14, number 4: {browse "http://www.stata-journal.com/article.html?article=gr0060":gr0060}

{p 5 10 2}
Manual:  {manhelp graph G-2}
{p_end}
