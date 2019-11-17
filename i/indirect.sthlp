{smcl}
{cmd:help indirect}{right: ({browse "http://www.stata-journal.com/article.html?article=st0325":SJ14-1: st0325})}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{hi:indirect} {hline 2}}Indirect treatment comparisons{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:indirect} {it:varlist} {ifin}{cmd:,} [{cmd:random} {cmd:fixed} 
{opt eff(strvar)} {cmd:eform}
{cmd:tabl} 
{opt trta(strvar)} 
{opt trtb(strvar)}]

{pstd}{it:varlist} contains{p_end}

{phang}1. a ratio summary statistic (relative risk, odds ratio, hazard
ratio) on the log scale and its standard error; or{p_end}
{phang}2. a risk difference or mean difference and its standard error;
or{p_end}
{phang}3. either 1 or 2 and its 95% confidence limits;{p_end}
{phang}4. a variable that specifies the studies; and{p_end}
{phang}5. a variable that tracks the order in which the comparisons are
done (var = 0, 1, ... number of trials comparing distinct
interventions).  Trials comparing the same interventions will have the
same order number.


{title:Description}

{pstd}
{cmd:indirect} performs pairwise indirect treatment comparisons.
 

{title:Options}

{phang}
{cmd:random} specifies that a random-effects model should be used (the
default).

{phang}
{cmd:fixed} specifies that a fixed-effects model should be used.

{phang}
{opt eff(strvar)} specifies the effect size (hazard ratio, relative risk, ...,
etc.).

{phang}
{cmd:eform} specifies that {cmd:eformat} should be used.

{phang}
{cmd:tabl} specifies that the table of studies used should be displayed.

{phang}
{opt trta(strvar)} specifies the experimental treatment.

{phang}
{opt trtb(strvar)} specifies the standard treatment.


{title:Note}

{pstd}
The command {helpb metan} must be installed before running
{cmd:indirect}.


{title:Authors}

{pstd}Branko Miladinovic{p_end}
{pstd}Center for Evidence-based Medicine{p_end}
{pstd}University of South Florida{p_end}
{pstd}Tampa, FL{p_end}
{pstd}bmiladin@health.usf.edu{p_end}

{pstd}Anna Chaimani{p_end}
{pstd}Department of Hygiene and Epidemiology{p_end}
{pstd}University of Ioannina School of Medicine{p_end}
{pstd}Ioannina, Greece{p_end}
{pstd}achaiman@cc.uoi.gr{p_end}

{pstd}Iztok Hozo{p_end}
{pstd}Department of Mathematics{p_end}
{pstd}Indiana University Northwest{p_end}
{pstd}Gary, IN{p_end}
{pstd}ihozo@iun.edu

{pstd}Benjamin Djulbegovic{p_end}
{pstd}Center for Evidence-based Medicine{p_end}
{pstd}University of South Florida{p_end}
{pstd}Tampa, FL{p_end}
{pstd}bdjulbeg@health.usf.edu


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 14, number 1: {browse "http://www.stata-journal.com/article.html?article=st0325":st0325}{p_end}
