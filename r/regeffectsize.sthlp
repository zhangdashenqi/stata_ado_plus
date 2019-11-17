{smcl}
{* *! version 1.0  21jan2009}{...}
{cmd:help regeffectsize}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{hi:regeffectsize} {hline 2}}Compute effect size for each variable in a regression model.
{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 14 2}
{cmd:regeffectsize} [, {cmd:help} ]

{synoptset 23 tabbed}
{synopthdr}
{synoptline}
{synopt:{opt help}}Display help for eta^2 and partial eta^2{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{title:Description}

{pstd}
{opt regeffectsize} computes effect size for each variable in model after regress command.  
Output includes eta2 and partial eta2.{p_end}

{title:Remarks}

{pstd}
Eta squared can be interpreted as  proportion of the total variance that is
attributed to an effect.{p_end} 
{pstd}
Partial eta squared can be interpreted as the proportion of effect + error
variance that is attributable to the effect. The formulas for partial eta
and eta squared differ in that the denominator
includes the SSeffect plus the SSerror rather than the SStotal.{p_end}

{pstd}
Note:  regeffectsize does not work with robust, cluster, bootstrap or jacknife 
standard errors.{p_end}

{title:Examples}

{pstd}{cmd:. use http://www.ats.ucla.edu/stat/data/hsb2, clear}{p_end}
{pstd}{cmd:. xi: regress write female read i.prog}{p_end}
{pstd}{cmd:. regeffectsize}{p_end}
{pstd}{cmd:. regeffectsize, help}{p_end}

{title:Author}

{p 4 4 2}Philip B. Ender{break}
UCLA Statistical Consulting Group{break}
ender@ucla.edu 

{p2colreset}{...}


