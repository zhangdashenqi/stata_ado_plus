{smcl}
{* *! version 1.1  29oct2008}{...}
{cmd:help rregfit}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{hi:rregfit} {hline 2}}Computes several fit measures following rreg.
{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 14 2}
{cmd:rregfit} [, {cmd: tune(} real {bf:)}

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{title:Description}

{pstd}
{opt rregfit} computes robust regression R-square, AICR, BICR and deviance following {cmd:rreg}. {p_end}

{title:Option}

{pstd}
{opt tune()} - If an alternative tuning parameter is used for {cmd:rreg}, then 
the same value should be used in {cmd:rregfit}.  Otherwise the default tuning
parameter of 7 will be used.{p_end}

{title:Examples}

{pstd}{cmd:. rreg crime pctmetro pctwhite single}{p_end}
{pstd}{cmd:. rregfit}{p_end}


{title:References}
{pstd}Hampel, F. R., Ronchetti, E.M., Rousseeuw, P.J. and Stahel, W.A. (1986)
Robust Statistics: The Approach Based on Influence Functions, New York:
John Wiley & Sons, Inc.{break}
Ronchetti, E. (1985) "Robust Model Selection in Regression," Statistics
and Probability Letters, 3, 21-23.{break}
(2008) SAS 9.2 Documentation for GLM. Cary, NC: SAS Institute Inc.{p_end}  

{title:Author}

{p 4 4 2}Philip B. Ender{break}
UCLA Statistical Consulting Group{break}
ender@ucla.edu {p_end}

{p 4 4 2}Xiao Chen{break}
UCLA Statistical Consulting Group{break}
xiao.chen@ucla.edu {p_end}

{p2colreset}{...}


