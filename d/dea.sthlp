{smcl}
{* *! version 1.0.3  1 Mar 2010}{...}
{cmd:help dea}
{hline}

{title:Title}

{phang}
{bf:dea} {hline 2} Data Envelopment Analysis in Stata

{title:Syntax}

{p 8 21 2}
{cmd:dea} {it:{help varlist:inputvars}} {cmd:=} {it:{help varlist:outputvars}} {ifin} 
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt rts:(string)}}specifies the returns to scale. The default is {cmd:rts(crs)}, meaning the constant returns to scale. {cmd:rts(vrs)} and {cmd:rts(nirs)} mean the variable returns to scale 
and non-increasing returns to scale respectively.
{p_end}
{synopt:{opt ort:(string)}}specifies the orientation. The default is {cmd:ort(i)}, meaning the input oriented Data Envelopment Analysis(DEA). {cmd:ort(out)} means the output oriented DEA.
{p_end}
{synopt:{opt stage:(#)}}specifies the way to identify all efficiency slacks. The default is {cmd:stage(2)}, meaning the two-stage DEA. {cmd:stage(1)} means the two-stage DEA.
{p_end}
{synopt:{opt trace:}}lets all the sequences and results displayed in the result window be saved in the "dea.log" file.
{p_end}
{synopt:{opt sav:ing(filename)}} specifies that the results be saved in {it:filename}.dta. If the filename already exists, the previous filename will be saved with the name of {it:filename}{cmd:_}bak{cmd:_}DMYhms.dta.
{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:dea} selects the input and output variables from the user designated data file or in the opened data set and solves Data Envelopment Analysis(DEA) models by options specified. 

{phang}
There are several options to enhance the models. The user can select the desired options according to the particular model that is required. 

{phang}
The dea program requires initial data set that contains the input and output variables for observed units. 

{phang}
Variable names must be identified by inputvars for input variable and by outputvars for output variable to allow that {cmd:dea} program can identify and handle the multiple input-output data set.
And the variable name of Decision Making Units(DMUs) is to be specified by "dmu".

{phang}
The program has the ability to accommodate unlimited number of inputs/outputs with unlimited number of DMUs. The only limitation is the memory of computer used to run {cmd:dea}.

{phang}
The result file reports the informations including reference points and slacks in DEA models. 
These informations can be used to analyze the inefficient units, 
for examples, where the source of inefficiency comes from and how could improve an inefficient unit to the desired level.

{phang}
{cmd:sav({it:filename})} option creates a {cmd: {it:filename}.dta} file that contains the results of {cmd: dea} including the informaions of the DMU, input and output data used, 
ranks of Decision Making Units(DMUs), efficiency scores, reference sets, and slacks.

{phang}
The log file, {cmd:dea.log}, will be created in the working directory.


{title:Examples}

{phang}{"use ...\coelli_table6.4.dta"}

{phang}{cmd:. dea i_x = o_q}

{phang}{cmd:. dea i_x = o_q,rts(vrs)}

{phang}{cmd:. dea i_x = o_q,rts(vrs) ort(o)}

{phang}{cmd:. dea i_x = o_q,rts(vrs) ort(o) stage(2)}

{phang}{cmd:. dea i_x = o_q,rts(vrs) ort(out) stage(2) sav}

{phang}{cmd:. dea i_x = o_q,rts(vrs) ort(o) stage(2) sav(dea1_result)}


{title:Saved Results}

{psee}
Matrix:

{psee}
{cmd: r(dearslt)} the results of {cmd:dea} that have observation rows of DMUs and variable columns with input data, output data, efficiency scores, references, slacks, and more depending on the models specified.
{p_end}


{title:Author}

{psee}
Yong-bae Ji and Choonjoo Lee

{psee}
Korea National Defense University

{psee}
Seoul, Republic of Korea

{psee}
E-mail: [choonjoo lee]sarang90@kndu.ac.kr; sarang64@snu.ac.kr; bloom.rambike@gmail.com
{p_end}
