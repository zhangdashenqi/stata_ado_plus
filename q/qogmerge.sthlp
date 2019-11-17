{smcl}
help for {cmd:qogmerge}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :Merging Quality of Government (QoG)} {p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}{cmd:qogmerge}
{it:country}
{it:time}
{cmd:,}
{opt v:ersion()}
{opt f:ormat()}
[{it:options}]


{pstd}{ul:{it:country}} is either (a) a variable holding the names of the
countries {ul:OR} (b) a single country name.

{pstd}{ul:{it:time}} is either (a) a variable holding the years in the survey
{ul:OR} (b) a single 4-digit year.


{title:Description}

{pstd}
{cmd:qogmerge} merges the latest release of {it:Quality of Government (QoG) data} 
to the data stored in the memory.

{pstd}The QOG-data is a dataset containing aggregate statistics of the Quality of Government of
various countries worldwide measured at various points in time. It is provided by
{it:University of Gothenburg: The Quality of Government Institute}.

{pstd}{cmd:qogmerge} merges the aggregate information of the QoG data to the
dataset in memory, using {it:country} and {it:year} as a key. To enable this, the
user must specify country and year in specific format. The {it:country}
must be specified either in the "numeric ISO-3166 format" or as "full
English country names" as defined by the International
Standardization Organization. {it:Year} must be specified in
4-digit-numeric-format.

{pstd}Usually both, country and time, will be specified by listing the variables in the data loaded in memory in which 
countries and years are stored. If data is based on only {ul:one country} or on a {ul:single year}, specify only this 
country/year instead of a country-variable or a time-variable (see {help qogmerge##examples:Examples} below)

{phang}
{opt v:ersion()} defines which version of the QoG-data you want to use. The alternatives are {it:Basic} ({opt bas}), 
{it:Standard} ({opt std}), {it:Social Policy} ({opt soc}) and the {it:Expert Survey} ({opt exp}) dataset. Each version has 
different formats which you have to specify:

{phang}
{opt f:ormat()} defines the different datasets. For the {it:Basic} and {it:Standard} version you can choose between 
Cross-Section Data ({opt cs}) and Time-Series Data ({opt ts}). For the {it:Social Policy} dataset you can choose cross-Section 
Data({opt cs}) or Time-Series Data in a long ({opt tsl}) or in a wide format ({opt tsw}). Merging the {it:Expert Survey} is 
only possible for Country-Level ({opt ctry}) data. It is not possible to merge format ({opt ind}) since this data is based on a 
web-survey by country experts and has individual experts, not country-year, as the unit of analysis.

{pstd}
Time information (year) is only available for {opt f:ormat(ts/tsl)}; {opt f:ormat(cs/ctry)} can only be merged at country-level.
If you specify a time-variable (or a single year), this information will be ignored.

{title:other Options}

{phang} {opt from()} is used to specify the location of the QoG-Data. You can specify 
the complete path on your computer or a local/global macro
containing this information. If {cmd:from()} is not specified, qogmerge will use
the latest version from the internet (filesize max. 35MB). If you use data stored on your computer, ensure that you use the correct 
file regarding {opt v:ersion()} and {opt f:ormat()}, and vice versa.

{pstd}{it:All {help merge}-options} are allowed with {it:qogmerge}. If
{cmd:keep()} is not specified, {cmd:keep(1 3)} is default.

{marker examples}
{title:Examples}

Example 1: Merging QoG-data to the World Values Survey (WVS)

{pstd} Assume you have already downloaded and unzipped the data of the
World Values Survey (WVS). We load into memory all rounds of the WVS

{phang2}{cmd:. use wvs1981_2008_v20090914.dta, clear}

{pstd}In this file the country names are stored in variable s009. However
the information in this file given in ISO 3166 Alpha-2 format, which
is not suitable for {cmd:qogmerge}. We use the user defined program
{net "describe http://fmwww.bc.edu/RePEc/bocode/k/kountry":kountry}
by Rafal Raciborski to convert the information stored in
s009 into the right format:

{phang2}{cmd:. kountry s009, from(iso2c)}

{pstd} This command creates the variable NAMES_STD holding the
standardized English country names. You can now use {cmd:qogmerge}. Here we add all variables from QoG to the WVS

{phang2}{cmd:. qogmerge NAMES_STD s020, version(std) format(ts)}

{pstd}although it is recommended to apply the option {cmd:keepusing({varlist})} to reduce the size of the new data set.

Example 2: Merge QoG to the 1st wave of European Social Survey (ESS)

{phang2}{cmd:. use ESS1e06_2.dta}{p_end}
{phang2}{cmd:. kountry cntry, from(iso2c)}{p_end}
{phang2}{cmd:. qogmerge NAMES_STD, version(bas) format(cs)}{p_end}


Example 3: Merge QoG and ESS for Sweden only

{phang2}{cmd:. use ESS1e06_2.dta if cntry == "SE"}{p_end}
{phang2}{cmd:. qogmerge Sweden inwyr, version(soc) format(tsl)}{p_end}


Example 4: Merge OoG to round II of the Eurp. Quality of Life Survey

{phang2}{cmd:. use analytical_file_8_sept_2008_compact_file.dta}{p_end}
{phang2}{cmd:. kountry country_abbr, from(iso2c)}{p_end}
{phang2}{cmd:. qogmerge NAMES_STD 2007, version(std) format(ts)}{p_end}


Example 5: Using option {cmd:from()}
{phang}-direct path:{p_end}
{phang2}{cmd:. qogmerge {it:country} {it:time}, version(std) format(ts) from(C:/Data/QoG_t_s_v6Apr11.dta)}{p_end}

{phang}-global macro:{p_end}
{phang2}{cmd:. global qog "C:/Data/QoG_t_s_v6Apr11.dta"}{p_end}
{phang2}{cmd:. qogmerge {it:country} {it:time}, version(std) format(ts) from($qog)}{p_end}


{title:Author}

{pstd}Christoph Thewes, University of Potsdam, thewes@uni-potsdam.de{p_end}

{title:Also see}

{psee} Help: {helpb merge}, {helpb qoguse} {it:(if installed)}, {helpb kountry} {it:(if installed)}

{psee} Online:
{net "describe http://fmwww.bc.edu/RePEc/bocode/k/kountry":kountry}

{psee} Source: {hi:http://www.qog.pol.gu.se}

{psee} Data: {hi:http://www.qog.pol.gu.se/data/}










