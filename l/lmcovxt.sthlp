{smcl}
{hline}
{cmd:help: {helpb lmcovxt}}{space 55} {cmd:dialog:} {bf:{dialog lmcovxt}}
{hline}

{bf:{err:{dlgtab:Title}}}

{p 4 8 2}
{bf:lmcovxt: Breusch-Pagan LM Diagonal Covariance Matrix Panel Test}

{marker 00}{bf:{err:{dlgtab:Table of Contents}}}
{p 4 8 2}

{p 5}{helpb lmcovxt##01:Syntax}{p_end}
{p 5}{helpb lmcovxt##02:Options}{p_end}
{p 5}{helpb lmcovxt##03:Description}{p_end}
{p 5}{helpb lmcovxt##04:Saved Results}{p_end}
{p 5}{helpb lmcovxt##05:References}{p_end}

{p 1}*** {helpb lmcovxt##06:Examples}{p_end}

{p 5}{helpb lmcovxt##08:Author}{p_end}

{p2colreset}{...}
{marker 01}{bf:{err:{dlgtab:Syntax}}}

{p 4 4 6}
{opt lmcovxt} {depvar} {indepvars} {ifin} {weight} , {bf:{err:id(#)}} {err:[}{opt nocons:tant} {opth vce(vcetype)} {opt l:evel(#)}{err:]}{p_end}

{p2colreset}{...}
{marker 02}{bf:{err:{dlgtab:Options}}}
{p 1 1 1}

{synoptset 15 tabbed}{...}

{synopt :* {cmd: {opt id(#)} Number of Cross Sections in the Model}}{p_end} 

{synopt :{opt nocons:tant}}suppress constant term{p_end}

{synopt :{opth vce(vcetype)}}{opt ols}, {opt r:obust}, {opt cl:uster}, {opt boot:strap}, {opt jack:knife}, {opt hc2}, {opt hc3}{p_end}

{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}

{p2colreset}{...}
{marker 03}{bf:{err:{dlgtab:Description}}}

{p 2 2 2} {cmd:lmcovxt} computes Breusch-Pagan LM Diagonal Covariance Matrix Test for panel data.{p_end} 
{p 2 2 2} Ho: Null hypothesis of diagonal covariance matrix means no cross-section correlation. LM test has an asymptotic Chi2 distribution with [N(N-1)/2] degrees of freedom.{p_end}

{p2colreset}{...}
{marker 04}{bf:{err:{dlgtab:Saved Results}}}

{p 2 4 2 }{cmd:lmcovxt} saves the following in {cmd:r()}:

{col 4}{cmd:r(lmcov)}{col 20}Lagrange Multiplier LM Test
{col 4}{cmd:r(lmcovp)}{col 20}Lagrange Multiplier LM Test P-Value
{col 4}{cmd:r(lmcovdf)}{col 20}Chi2 Degrees of Freedom

{marker 05}{bf:{err:{dlgtab:References}}}

{p 4 8 2}Greene, William (1993)
{cmd: "Econometric Analysis",}
{it:2nd ed., Macmillan Publishing Company Inc., New York, USA.}.

{p 4 8 2}Greene, William (2007)
{cmd: "Econometric Analysis",}
{it:6th ed., Macmillan Publishing Company Inc., New York, USA.}.

{p 4 8 2}Judge, Georege, R. Carter Hill, William . E. Griffiths, Helmut Lutkepohl, & Tsoung-Chao Lee (1988)
{cmd: "Introduction To The Theory And Practice Of Econometrics",}
{it:2nd ed., John Wiley & Sons, Inc., New York, USA}.

{p 4 8 2}Judge, Georege, W. E. Griffiths, R. Carter Hill, Helmut Lutkepohl, & Tsoung-Chao Lee(1985)
{cmd: "The Theory and Practice of Econometrics",}
{it:2nd ed., John Wiley & Sons, Inc., New York, USA}.

{p2colreset}{...}
{marker 06}{bf:{err:{dlgtab:Examples}}}

  {stata clear all}

  {stata sysuse lmcovxt.dta, clear}

  {stata db lmcovxt}

  {stata lmcovxt y x1 , id(4)}

. lmcovxt y x1 , id(4)
==============================================================================
* Breusch-Pagan LM Diagonal Covariance Matrix Test
==============================================================================
    Ho: Run OLS Regression  -  Ha: Run Panel Regression

    Lagrange Multiplier Test  =   25.23999
    Degrees of Freedom        =        6.0
    P-Value > Chi2(6)         =    0.00031
==============================================================================

{marker 08}{bf:{err:{dlgtab:Author}}}

  {hi:Emad Abd Elmessih Shehata}
  {hi:Assistant Professor}
  {hi:Agricultural Research Center - Agricultural Economics Research Institute - Egypt}
  {hi:Email:   {browse "mailto:emadstat@hotmail.com":emadstat@hotmail.com}}
  {hi:WebPage:{col 27}{browse "http://emadstat.110mb.com/stata.htm"}}
  {hi:WebPage at IDEAS:{col 27}{browse "http://ideas.repec.org/f/psh494.html"}}
  {hi:WebPage at EconPapers:{col 27}{browse "http://econpapers.repec.org/RAS/psh494.htm"}}

{bf:{err:{dlgtab:lmcovxt Citation}}}

{phang}Shehata, Emad Abd Elmessih (2012){p_end}
{phang}{cmd:LMCOVXT: "Stata Module to Compute Breusch-Pagan Lagrange Multiplier Diagonal Covariance Matrix Test for Panel Data"}{p_end}

{title:Online Help:}

{p 2 12 2}{helpb lmcovxt}, {helpb xtidt}, {helpb ghxt}. {opt (if installed)}.{p_end}

{psee}
{p_end}

