{smcl}
{* 25July2017}{...}
{hi:help t2docx}
{hline}

{title:Title}

{phang}
{bf:t2docx} {hline 2} Report Mean Comparison for a lot of variables between two groups with formatted table output in DOCX file.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:t2docx} {it:varlist} [{it:if}] [{it:in}] {it:using filename} {cmd:,} [{it:options}] {opth by:(varlist:groupvar)}

varlist is a list of numerical variables to be tested.

For each of those variables, we need to perform a standard t-test to compare it's mean difference between two groups specified by option by(groupvar). groupvar must be a dichotomous variable for the sample specified by [if] and [in]. 
groupvar maybe either numerical or string, provided that it only takes two different values for the sample.



{marker options}{...}
{title:Options for wordconvert}

{phang}
{opt replace} permits to overwrite an existing file. {p_end}

{phang}
{opt append} permits to append the output to an existing file. {p_end}

{phang}
{opt title(string)} specify the title of the table. {p_end}

{phang}
{opt fmt} specify the display format for group means and their difference; default format is %9.3f. {p_end}

{phang}
{opt not} do not output t-value. {p_end}

{phang}
{opt nostar} do not output significance stars. {p_end}

{phang}
{opt star}{opt [}{opt (symbol level [...])}{opt ]} output significance of the coefficients. {p_end}

{phang}
{opt staraux} the significance stars be printed next to the t-statistics (or standard errors, etc.) instead of the coefficient. {p_end}


{marker example}{...}
{title:Example}

{pstd}

{phang}
{stata `"sysuse auto, clear"'}
{p_end}

{pstd}
Report Mean Comparison for variables price weight length mpg between foreign group with formatted table output in DOCX file.

{phang}
{stata `"t2docx price weight length mpg using 1.docx ,replace by(foreign)"'}
{p_end}

{pstd}
Add table tile

{phang}
{stata `"t2docx price weight length mpg using 1.docx ,replace by(foreign) title("this is the t-test table")"'}
{p_end}

{pstd}
Add format for t-test table %9.2f

{phang}
{stata `"t2docx price weight length mpg using 1.docx ,replace by(foreign) fmt(%9.2f) title("this is the t-test table") "'}
{p_end}

{pstd}
Use the option append to append the output to an existing file

{phang}
{stata `"t2docx price weight length mpg turn using 1.docx ,append by(foreign) fmt(%9.2f) title("this is the t-test table")"'}
{p_end}

{pstd}
Change the significance of the coefficients and the significance stars

{phang}
{stata `"t2docx price weight length mpg rep78 headroom trunk using 1.docx ,replace by(foreign) star(* 0.01 ** 0.005 *** 0.001) title("this is the t-test table")"'}
{p_end}

{pstd}
Output coefficients without significance stars

{phang}
{stata `"t2docx price weight length mpg rep78 headroom trunk using 1.docx ,replace by(foreign) nostar title("this is the t-test table")"'}
{p_end}

{pstd}
Output table without t-value

{phang}
{stata `"t2docx price weight length mpg rep78 headroom trunk using 1.docx ,replace by(foreign) not title("this is the t-test table")"'}
{p_end}


{title:Author}

{pstd}Chuntao LI{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}chtl@zuel.edu.cn{p_end}

{pstd}Zijian LI{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}jeremylee_41@163.com{p_end}

{pstd}Yuan XUE{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}xueyuan19920310@163.com{p_end}

