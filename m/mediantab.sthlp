{smcl}
{* 5oct2013}{...}
{cmd:help mediantab}{right: }
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{hi: mediantab} {hline 2}}Median test for a set of variables between two groups with formatted table output
{p_end}
{p2colreset}{...}


{title:Syntax}

{p 4 19 2}
{cmdab:mediantab} {varlist} {ifin}, {opth by:(varlist:groupvar)} {cmdab:f:ormat:}{cmd:(%}{it:{help format:fmt}}{cmd:)}

{pstd} {varlist} is a list of numerical variables to be tested. {p_end}
 
{pstd}  
{hi:{it:groupvar}} must be a dichotomous variable for the sample 
specified by {hi: [if] and [in]}. 
{hi:{it:groupvar}} maybe either numerical or string, provided that it only takes two different values for the sample. 
{p_end}

{pstd} {opt format}{cmd:(%}{it:{help format:fmt}}{cmd:)}
specify the display format for group means and their difference; default format is {cmd:%8.3f}.
{p_end}


{title:Description}

{pstd} 
{cmdab:mediantab} performs Stata official command {help median} on a set of variables, 
	and display the results in formmated table. Note that, {help median} can only be used for a single variable.
{p_end}
	
{pstd} For each of those variables, we need to perform a nonparametric 2-sample test on the equality of medians.  
    It tests the null hypothesis that the two samples specified by option {opth by:(varlist:groupvar)} were drawn
    from populations with the same median.  
	For two samples, the chi-squared test statistic is computed both with and without a
    continuity correction. 
{p_end}


{title:Examples}

{result}{dlgtab:The auto data}{text}

{phang2}{inp:.} {stata "sysuse auto,clear":sysuse auto,clear}{p_end}
{phang2}{inp:.} {stata "mediantab price wei len mpg, by(foreign)":mediantab price wei len mpg, by(foreign)}{p_end}
{phang2}{inp:.} {stata "mediantab price wei len mpg, by(foreign) f(%6.2f)":mediantab price wei len mpg, by(foreign) f(%6.2f)}{p_end}

{pstd}  
In case that {hi:{it:groupvar}} contains more than two groups, you can restrict it into two groups by speicifing 
 {hi: [if] and [in]}:
{p_end}

{phang2}{inp:.} {stata "tab rep78":tab rep78}{p_end}
{phang2}{inp:.} {stata "mediantab price wei len mpg if rep78==3|rep78==4, by(rep78)":mediantab price wei len mpg if rep78==3|rep78==4, by(rep78)}{p_end}

{result}{dlgtab:Save in Excel or Word}{text}

{pstd}you can use the user-written {help logout} command to export the results into Excel or Word:{p_end}

{phang2}{inp:.} {stata "logout, save(Tab2_corr) excel replace: mediantab price wei len mpg, by(foreign)":logout, save(Tab2_corr) excel replace: mediantab price wei len mpg, by(foreign)}{p_end}


{title:Author}

{phang}
{cmd:Yujun,Lian (Arlion)} Department of Finance, Lingnan College, Sun Yat-Sen University.{break}
E-mail: {browse "mailto:arlionn@163.com":arlionn@163.com}. {break}
Blog: {browse "http://blog.cnfol.com/arlion":http://blog.cnfol.com/arlion}. {break}
Homepage: {browse "http://www.lingnan.net/intranet/teachinfo/dispuser.asp?name=lianyj":http://www.lingnan.net/intranet/teachinfo/dispuser.asp?name=lianyj}. {break}
{p_end}

{pstd}   {p_end}
{pstd}   {p_end}
