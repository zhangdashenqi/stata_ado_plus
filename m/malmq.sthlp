{smcl}
{* *! version 1.3.0  28 JAN 2014}{...}
{cmd:help malmq}
{hline}

{title:Title}

{phang}
{bf:malmq} {hline 2} Malmquist Productivity Index using DEA frontier in Stata

{title:Syntax}

{p 8 21 2}
{cmd:malmq} {it:{help varlist:ivars}} {cmd:=} {it:{help varlist:ovars}} {cmd:,} {period}{ifin} 
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt ort:(string)}}specifies the orientation. The default is {cmd:ort(i)}, meaning the input oriented distance Data Envelopment Analysis(DEA) frontier used. {cmd:ort(out)} means the output oriented DEA frontier.
{p_end}
{synopt:{opt trace:}}lets all the sequences and results displayed in the result window be saved in the "malmq.log" file.
{p_end}
{synopt:{opt sav:ing(filename)}} specifies that the results be saved in {it:filename}.dta. If the filename already exists, the previous filename will be saved with the name of {it:filename}{cmd:_}bak{cmd:_}DMYhms.dta.
{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:malmq} selects the input and output variables from the user designated data file or in the opened data set and solves Malmquist Productivity Index using Data Envelopment Analysis(DEA) frontier by options specified. 

{phang}
The malmq program requires initial panel data set that contains the input and output variables and period for observed units. 

{phang}
Variable names must be identified by ivars for input variable, by ovars for output variable, and by period for panel period of time to allow that {cmd:malmq} program can identify and handle the multiple input-output data set.
And the variable name of Decision Making Units(DMUs) is to be specified by "dmu".

{phang}
{cmd:sav({it:filename})} option creates a {cmd: {it:filename}.dta} file that contains the results of {cmd: malmq} including the informaions of the DMU, input and output data used, 
efficiency change, technology change, total factor productivity change, scale efficiency change, and pure technical change.

{phang}
The log file, {cmd:malmquist.log}, will be created in the working directory.


{title:Examples}
{phang}{cmd:. input str20 dmu year o_q i_x}

                      dmu       year        o_q        i_x
  1. firm1 2009 1 2
  2. firm2 2009 2 4
  3. firm3 2009 3 3
  4. firm4 2009 4 5
  5. firm5 2009 5 6
  6. firm1 2010 1 2
  7. firm2 2010 3 4
  8. firm3 2010 4 3
  9. firm4 2010 3 5
  10. firm5 2010 5 5
  11. firm1 2011 1 2
  12. firm2 2011 3 4
  13. firm3 2011 4 3
  14. firm4 2011 3 5
  15. firm5 2011 5 5
  16. end

{phang}{cmd:. malmq i_x =  o_q,period(year)}

{phang}{cmd:. malmq i_x =  o_q,ort(o) period(year)}

{title:Saved Results}

{psee}
Matrix:

{psee}
{cmd: r(prodidxrslt)} the results of {cmd:malmq} that have observation rows of DMUs and variable columns with period of time, dmu, tfpch(total factor productivity change), effch*efficiency change), techch(technology change), pech(pure efficiency change), and sech(scale efficiency change).
{cmd: r(effrslt)} n by 3 matrix of the results of {cmd:malmq} where rows show dmu corresponding to the time variable and columns correspond to the variables including dmu, CRS_eff(efficiency score under the assumption of constant returns to scale), VRS_eff(efficiency score under the assumption of variable returns to scale).

{p_end}

{title:Author}

{psee}
Choonjoo Lee  

{psee}
Korea National Defense University

{psee}
Seoul, Republic of Korea

{psee}
E-mail: bloom.rambike@gmail.com
{p_end}
