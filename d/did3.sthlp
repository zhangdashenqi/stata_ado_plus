{smcl}
{* $Id$ }
{* $Date$}{...}
{cmd:help mat2txt2}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{hi:did3 }{hline 2}}Create difference-in-differences tables.{p_end}
{p2colreset}{...}

{title:Syntax}


{p 8 16 2}
{cmdab:did3} {it:depvarname rowvarname colvarname} {ifin} {weight} , [options]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:did3 options}
{synopt:{opt nois:ily}}Display extra results, including all regression output and means/SE tables.  Otherwise, minimum details are reported.{p_end}
{synopt:{opt f:ormat}({help format:%fmt})}Specify format for table display (matrix saves all digits){p_end}
{synopt:{opt save}}Save the ereturn results from the diff-in-diff regression.{p_end}
{synopt:{opt l:abels(type)}}Specify how to label rows and columns.  {it:type} may be {opt varname} or {opt tcpp}.{p_end}

{syntab:SE/Robust (passed thru to regression commands)}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt r:obust}, {opt boot:strap}, or {opt jack:knife}{p_end}
{synopt :{opt r:obust}}synonym for {cmd:vce(robust)}{p_end}
{synopt :{opth cl:uster(varname)}}adjust standard errors for intragroup
correlation{p_end}
{synopt :{opt ms:e1}}force mean squared error to 1{p_end}
{synopt :{opt hc2}}use u^2_j/(1-h_jj) as observation's variance{p_end}
{synopt :{opt hc3}}use u^2_j/(1-h_jj)^2 as observation's variance{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:by} may be used with did3; see {help by}.
{p_end}

 
{title:Description}

{pstd}{opt did3} Is used to create a "standard" difference-in-differences table.  {p_end}

{pstd}An example explains the idea: Consider the case where you have some outcome, say wages, in an experimental
setting.  Some individuals were "treated" ({it:treat=1}) while others serve as a "control" group ({it:treat=0}) . 
You measures wages before ({it:post=0}) and after ({it:post=1}) the intervention.  You can quickly create a table to 
estimate the effect of the treatment (of course, conditional on a number of different assumptions holding).{p_end}

{phang}{cmd:. did3 wages treat post , l(varname) }

{txt}                            post=0      post=1  Difference
{txt}               treat=1  {res}  155.1739    146.3571     -8.8168
{txt}                        {res}    2.3131      2.3983      3.3769
{txt}                        {res}                                  
{txt}               treat=0  {res}  160.1905    155.9545     -4.2359
{txt}                        {res}    2.6009      2.7817      3.8165
{txt}                        {res}                                  
{txt}            Difference  {res}   -5.0166     -9.5974     -4.5808
{txt}                        {res}    3.4691      3.6604      5.0780
{txt}           
			
{p 4 8 2}(1)	The interior cells are the coefficient estimate and standard error for {it:_const} from a {cmd:regress} command such as: {p_end}

{phang2}{cmd:. regress wages if (treat == 1 & post == 0)  }

{p 4 8 2}(2)  The difference cells are the coefficient estimate and standard error for {it:post} (or {it:treat}) from a {cmd:regress} command such as: {p_end}

{phang2}{cmd:. regress wages post if (treat == 1) }

{p 4 8 2}(3)  The difference-in-differences cell is the coefficient estimate and standard error for {it:interaction} from the {cmd:regress} command: {p_end}

{phang2}{cmd:. regress wages treat post interaction } {break}
where {it:interaction} = ({it:post})*({it:treat})


{title:Other Notes}

{pstd}As in the example above, {it:rowvarname} and {it:colvarname} must equal zero or one. {p_end}

{pstd}Because this program is based on the {help regress} command, I have allowed 
{cmd:did3} to pass {weight} and other SE/Robust options to the regressions.  
When using these options, remember this program is running nine separate
regressions, one for each cell of the table.{p_end}

{pstd}  Rows and column labels are created with the value labels (see help {help label}) 
that are assigned to {it:rowvarname} and {it:colvarname}, respectively.  If the variable 
does not have a value label, or if the option {opt label(varname)} is used, the label is
replaced with {it:varname=1} and {it:varname=0}.  The label {opt label(tcpp)} overrides this 
behavior and labels the rows "treatment" and "control" and the columns "pre" and "post."{p_end}

{pstd} The table and a few other items are returned in the {help ereturn:ereturn list}.{p_end}


{title:Examples}

{phang}{cmd:. did3 wages treat post }{p_end}

{phang}{cmd:. did3 wages treat post , noisily labels(varname) save}{p_end}
{phang}{cmd:. ereturn list} {p_end}
{phang}{cmd:. matrix save_did3 = e(table)} {p_end}
{phang}{cmd:. mat2txt2 e(table) using "example.csv", matnames replace }{text}  {it:(if installed)}{p_end}


{title:Other Information}
{* $Id$ }
{phang}Author: Keith Kranker{p_end}

{phang}$Date${p_end}


{title:Also see}

{psee}
Help:  
{help regress}, {help matrix}, {help ereturn}, {help by}
, {help mat2txt2} {it:(if installed)}
{p_end}

