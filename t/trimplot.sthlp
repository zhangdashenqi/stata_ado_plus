{smcl}
{* 30jan2013}{...}
{hline}
help for {hi:trimplot}
{hline}

{title:Plots of trimmed means} 

{p 8 17 2}
{cmd:trimplot} 
{it:varname}
[{cmd:if} {it:exp}] 
[{cmd:in} {it:range}]
[{cmd:,}
{cmd:over(}{it:varname}{cmd:)} 
{cmd:percent} 
{it:scatter_options}]

{p 8 17 2}
{cmd:trimplot} 
{it:varlist}
[{cmd:if} {it:exp}] 
[{cmd:in} {it:range}]
[{cmd:,}
{cmd:percent} 
{it:scatter_options}]


{title:Description}

{p 4 4 2}
{cmd:trimplot} produces plots of trimmed means versus depth for one or
more numeric variables. Such plots may help specifically in choosing or
assessing measures of level and generally in assessing the symmetry or
skewness of distributions. They can be used to compare distributions or
to assess whether transformations are necessary or effective.

{p 4 4 2}
{cmd:trimplot} may be used to show trimmed means for one variable, in
which case different groups may be distinguished by the {cmd:over()}
option; or for several variables. 


{title:Remarks} 

{p 4 4 2}Order n data values for a variable x and label them such that
x(1) <= ... <= x(n). Following Tukey (1977), depth is defined as 1 for
x(1) and x(n), 2 for x(2) and x(n-1), and so forth: it is the smaller 
number reached by counting inwards from either extreme x(1) or x(n)
toward any specified value. So the depth of x(i) is the smaller of i and
n - i + 1. 

{p 4 4 2}Trimmed means may be related to depth as follows. A trimmed
mean may be defined for any particular depth as the mean of all values
with that depth or greater. Thus the trimmed mean for depth 1 is the
mean of all values. The trimmed mean for depth 2 is the mean of all
values except those of depth 1, i.e. all values except for the
extremes. The trimmed mean for depth 3 is the mean of all values 
except those of depth 1 and 2; and so forth. 

{p 4 4 2}The highest depth observed for a distribution occurs once if n
is odd and twice if n is even; either way it labels those values whose
mean is the median. Thus trimmed means range from the mean to the
median. 

{p 4 4 2}The idea of plotting trimmed mean versus percent trimmed can
only be a little deal. An example can be found in Rosenberger and Gasko
(1983, p.315). Users knowing good and/or early references are welcome
to email me with details. 

{p 4 4 2}For more on trimmed means, see the help for {help trimmean}
(which must be installed first).  


{title:Options} 

{p 4 8 2}{cmd:over(}{it:varname}{cmd:)} specifies that calculations are
to be carried out separately for each group defined by {it:varname}.
{cmd:over()} is allowed only with a single variable to be plotted. 

{p 4 8 2}{cmd:percent} specifies that depth is to be scaled and plotted
as percent trimmed, which will range from 0 to nearly 50 (a median cannot 
be based on no observed values, so 50 cannot be attained). 

{p 4 8 2}{it:scatter_options} are options of {help twoway scatter}. 


{title:Examples}

{p 4 8 2}{cmd:. webuse citytemp}{p_end}
{p 4 8 2}{cmd:. describe}{p_end}
{p 4 8 2}{cmd:. trimplot *dd}{p_end}
{p 4 8 2}{cmd:. trimplot temp*}{p_end}
{p 4 8 2}{cmd:. skewplot tempjan, over(region) percent}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University{break} 
         n.j.cox@durham.ac.uk


{title:References}

{p 4 8 2}Rosenberger, J.L. and Gasko, M. 1983. 
Comparing location estimators: trimmed means, medians, and trimean. 
In Hoaglin, D.C., Mosteller, F. and Tukey, J.W. (Eds)
{it:Understanding robust and exploratory data analysis.}
New York: John Wiley, 297{c -}338. 

{p 4 8 2}Tukey, J.W. 1977. 
{it:Exploratory data analysis.} 
Reading, MA: Addison-Wesley. 


{title:Also see} 

{p 4 13 2}  
{help summarize}, 
{help means}, 
{help trimmean} (if installed), 
{help hsmode} (if installed), 
{help shorth} (if installed)

