{smcl}
{* 3jan2013}{...}
{cmd:help chinafin}{right: }
{hline}

{title:Title}

{p2colset 5 25 27 2}{...}
{p2col:{hi: chinafin} {hline 2}}Downloads historical financial data for a list
of Chinese public firms from the Internet
{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 18 2}
{cmdab:chinafin} {it: codelist}{cmd:,}
[{it:options}]

{synoptset 36 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt path(foldername)}}output folder{p_end}

{synoptline}
{p2colreset}{...}


{pstd}{it:codelist} is a list of stock codes to be downloaded. Stock codes are separated by spaces. 
For each valid stock code, there will be one Stata-format data file output 
containing all the annual report financial data for the corresponding listed firm. 
The stock code will also be used as the output file name, with .dta as the extension.
In China, stocks are identified by a six digit number, instead of using tickers as in NYSE.
Examples of Stock Codes and the name of the list firms are as following: {p_end}
{pstd} {hi:000001} Pingan Bank  {p_end}
{pstd} {hi:000002} Vank Real Estate Co. Ltd. {p_end}
{pstd} {hi:600000} Pudong Development Bank {p_end}
{pstd} {hi:600005} Wuhan Steel Co. Ltd. {p_end}
{pstd} {hi:900901} INESA Electron Co.,Ltd. {p_end}

{pstd}The leading zeros in each stock code can  be omitted. {p_end}

{pstd}{it:path} specifies the folder where Stata-formatted financial data for each stock are saved {p_end}
{pstd} The folders can be either existing folders or new folders  {p_end}
{pstd} If the folder specified does not exist, {cmd: chinafin} will create it automatically {p_end}



{title:Examples}

{phang}{cmd:. chinafin 002046 300236 600573, path(d:\account) } {p_end}
{phang}{cmd:. chinafin 002046 300236 600573} {p_end}
{phang}{cmd:. chinafin 2 5} {p_end}

{title:Authors}

{pstd}Xuan Zhang{p_end}
{pstd}Zhongnan University of Economics and Law{p_end}
{pstd}Wuhan, China{p_end}
{pstd}zhangx@znufe.edu.cn{p_end}

{pstd}Chuntao Li{p_end}
{pstd}Zhongnan University of Economics and Law{p_end}
{pstd}Wuhan, China{p_end}
{pstd}chtl@znufe.edu.cn{p_end}

{pstd}Cheng Pan{p_end}
{pstd}Zhongnan University of Economics and Law{p_end}
{pstd}Wuhan, China{p_end}
{pstd}panchengmail@163.com{p_end}

{title:Acknowledgments}

{pstd}We owe Prof. Christopher Baum many thanks for his help and suggestions on designing the code, especially on Mata programming. Of course, all the errors belong to the authors.{p_end}



