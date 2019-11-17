{smcl}
help {cmd:qoguse}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :Using Quality of Government (QoG) Data} {p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 12 2}
{opt qoguse}
[{varlist}]
{ifin}
{cmd:,}
{opt v:ersion()}
{opt f:ormat()}
[{opt y:ears()}
{opt clear}]


{title:Description}

{pstd}{cmd:qoguse} loades the most recent release of the {it:Quality of Government (QoG) datasets} from the
internet into memory. If you don`t need the complete dataset, you can opt for specific variables with [{help varlist}] 
and/or years with the option {opt y:ears}. 

{phang}
{opt v:ersion()} defines which version of the QoG-data you want to use. The alternatives are {it:Basic} ({opt bas}), 
{it:Standard} ({opt std}), {it:Social Policy} ({opt soc}) and the {it:Expert Survey} ({opt exp}) dataset. Each version has 
different formats which you have to specify:

{phang}
{opt f:ormat()} defines the different datasets. For the {it:Basic} and {it:Standard} version you can choose between 
Cross-Section Data ({opt cs}) and Time-Series Data ({opt ts}). For the {it:Social Policy} dataset you can choose cross-Section 
Data({opt cs}) or Time-Series Data in a long ({opt tsl}) or in a wide format ({opt tsw}). The {it:Expert Survey} is available 
as Individual-Level ({opt ind}) or Country-Level ({opt ctry}) data.

{title:other Options}

{phang}
{opt y:ears}({help numlist}) specifies the different years to be kept in the data. You can use a {help numlist} 
to specify the years, which must be in 4-digit-format (e.g. {opt y:ears(1990 1995/1997 2002)}). This option is only available
with the following format()-options: {opt ts}, {opt tsl} and {opt ind}.

{phang}
{opt clear} specifies that it is okay to replace the data in memory,
even though the current data have not been saved to disk.


The QoG-data is provided by {it:University of Gothenburg: The Quality of Government Institute}.

{title:Examples}

{phang}{cmd:. qoguse}, version(bas) format(cs) clear

{phang}{cmd:. qoguse} ccode year bdm_* ar_cbi, version(std) format(ts) clear

{phang}{cmd:. qoguse}, version(soc) format(tsl) y(1990 1995/1997 2002) clear

{phang}{cmd:. qoguse}, version(exp) format(ctry) clear


{title:Author}

{pstd}Christoph Thewes, University of Potsdam, thewes@uni-potsdam.de{p_end}

{title:Also see}

{psee} Help: {helpb use}, {helpb qogmerge} {it:(if installed)}

{psee} Source: {hi:http://www.qog.pol.gu.se}

{psee} Data: {hi:http://www.qog.pol.gu.se/data/}










