{smcl}
{* 30jan2014}{...}
{hi:help cntrade}{right: ({browse "http://www.stata-journal.com/article.html?article=dm0074":SJ14-2: dm0074})}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col:{hi: cntrade} {hline 2}}Download historical market quotations for a list
of stock codes from NetEase, a website providing financial information
in China{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 18 2}
{cmdab:cntrade} {it: codelist}
[{cmd:,} {cmd:path(}{it:foldername}{cmd:)}]

{phang}
{it:codelist} is a list of stock codes to be downloaded from NetEase.  The
stock codes must be separated by spaces.  For each valid stock code, there
will be one Stata-format data file as output, which will contain all the
trading information for that stock.  The code will be the filename with
{cmd:.dta} as the extension.  In China, stocks are identified by six-digit
numbers.  Examples of stock codes and the names of their corresponding firms
are as follows:

{phang2} {hi:000001} Pingan Bank  {p_end}
{phang2} {hi:000002} Vanke Real Estate Co., Ltd. {p_end}
{phang2} {hi:600000} Pudong Development Bank {p_end}
{phang2} {hi:600005} Wuhan Steel Co., Ltd. {p_end}
{phang2} {hi:900901} INESA Electron Co., Ltd. {p_end}

{phang2}
The leading zeros in each stock code can be omitted.


{title:Description}

{pstd}
{cmd:cntrade} automatically downloads historical trading quotations from
NetEase ({browse http:www.163.com}).


{title:Option}

{phang}
{opt path(foldername)} specifies the folder where the output {cmd:.dta} files
will be saved.  {it:foldername} can be an existing folder or a new folder.  If
{it:foldername} does not exist, {cmd:cntrade} will create it automatically.
If {cmd:path()} is not specified, the output will be saved to the current
working directory.  Specifying {cmd:path()} is strongly recommended.


{title:Examples}

{phang}{cmd:. cntrade 600000} {p_end}
{phang}{cmd:. cntrade 2 } {p_end}
{phang}{cmd:. cntrade 600000, path(c:/temp/)} {p_end}
{phang}{cmd:. cntrade 2, path(c:/temp/)} {p_end}
{phang}{cmd:. cntrade 600000 000001 600810, path(c:/temp/)} {p_end}
{phang}{cmd:. cntrade 600000 000001 600810} {p_end}
{phang}{cmd:. cntrade 2  16} {p_end}


{title:Authors}

{pstd}Xuan Zhang{p_end}
{pstd}Zhongnan University of Economics and Law{p_end}
{pstd}Wuhan, China{p_end}
{pstd}zhangx@znufe.edu.cn{p_end}

{pstd}Chuntao Li{p_end}
{pstd}Zhongnan University of Economics and Law{p_end}
{pstd}Wuhan, China{p_end}
{pstd}chtl@znufe.edu.cn{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 14, number 2:  {browse "http://www.stata-journal.com/article.html?article=dm0074":dm0074}{p_end}
