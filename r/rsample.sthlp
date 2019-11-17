{smcl}
{cmd:help rsample}{right: ({browse "http://www.stata-journal.com/article.html?article=st0229":SJ11-2: st0229})}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{hi:rsample} {hline 2}}Generate a random sample from a user-defined distribution{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{opt rsample} {it:pdf_function} [{cmd:,} {it: options}]{p_end}
{p2colreset}{...}

{synoptset 10}{...}
{synopthdr}
{synoptline}
{synopt :{opt l:eft(#)}}left bound of the support interval{p_end}
{synopt :{opt r:ight(#)}}right bound of the support interval{p_end}
{synopt :{opt b:ins(#)}}number of bins into which the support interval is split{p_end}
{synopt :{opt s:ize(#)}}number of observations to be generated{p_end}
{synopt :{opt p:lot(#)}}display results in a histogram{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd} {cmd:rsample} generates a random sample from a user-defined probability
distribution function into a new variable called {cmd:rsample}.  If the sample
is to be generated into an existing Stata dataset, the number of observations is
preserved; otherwise, it is set to 5,000.

{pstd} {it:pdf_function} specifies the probability distribution function from
which to draw the sample.  It must be nonnegative on the specified support
interval, and it must be expressed as a function of x.


{title:Options}

{phang} {opt left(#)} specifies the left bound of the support interval.  The
default is {cmd:left(-2)}.  {it:#} can take on any real value, and it must be
less than the right bound of the support interval.

{phang}
{opt right(#)} specifies the right bound of the support interval.  The default
is {cmd:right(2)}.  {it:#} can take on any real value, and it must be greater than the left
bound of the support interval.

{phang}
{opt bins(#)} specifies the number of bins into which the support interval is
split for the purposes of the algorithm.  Essentially, it allows the user to
specify the precision of the algorithm.  The default is {cmd:bins(1000)}, but
it is set to be one-fifth of the total number of observations _N if
{cmd:bins()} is
specified to be larger than _N.

{phang}
{opt size(#)} specifies the number of observations to be generated.  The
default is {cmd:size(5000)}, but this value is applied only if there is no
dataset currently in use.  If the random sample is to be generated into an
existing Stata dataset, the original number of observations is preserved even
if this option is specified.

{phang}
{opt plot(#)} specifies whether results will be plotted into a histogram.
It only takes values {cmd:1} for displaying the plot and {cmd:0} for no graphical display.  The
default is {cmd:plot(1)}.


{title:Examples}

{phang}
{cmd: . rsample exp(-x^2)}

{phang}
{cmd: . rsample exp(-x^2), left(-2.5) right(2.5)}

{phang}
{cmd: . rsample exp(-abs(x)), left(-4) right(4) bins(500)}

{phang}
{cmd: . rsample exp(-abs(x)), left(-4) right(4) size(500)}

{phang}
{cmd: . rsample exp(-abs(x)), plot(0)}

{phang}
{cmd: . rsample exp(-log(x)^2), left(0.1) right(6) bins(300) size(3000) plot(0)}


{title:Author}

{pstd}Katar{c i'}na Luk{c a'}csy{p_end}
{pstd}Central European University{p_end}
{pstd}Budapest, Hungary{p_end}
{pstd}lukacsy_katarina@phd.ceu.hu


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 11, number 2: {browse "http://www.stata-journal.com/article.html?article=st0229":st0229}
{p_end}
