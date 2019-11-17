{smcl}
{* 31-05-2009}{...}
{cmd:help rocmic} and {cmd:help fastmic} and {cmd:help rocmicd} and {cmd:help fastmicd} {right:Version 1.0 31-05-2009}

{hline}

{title:Title}

{p2colset 5 13 13 2}{...}
{p2col:{hi:rocmic} {hline 2}}Calculates the minimally important change (MIC) thresholds from continuous outcomes using ROC curves and an external reference criterion. {p_end}
{p2col:{hi:fastmic} {hline 2}}As above, but suppresses the ROC curve for a faster process when using the {hi:bootstrap} option.{p_end}
{p2col:{hi:rocmicd} {hline 2}}Works in the same way as {hi:rocmic} but is used to calculate minimally important deteriorations. {p_end}
{p2col:{hi:fastmicd} {hline 2}}Works in the same way as {hi:fastmic} but is used to calculate minimally important deteriorations. {p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab:rocmic}
{it:refvar classvar}
{cmd:,} {it:scale(minimum scale unit)}

{p 8 17 2}
{cmdab:fastmic}
{it:refvar classvar}
{cmd:,} {it:scale(minimum scale unit)}



{title:Descriptions}

{pstd}

{cmd:rocmic} estimates minimally important change (MIC) thresholds using two slightly different methods. The first is the cut-point
corresponding to a 45 degree tangent line intersection; this is mathematically equivalent to the point at which the sensitivity and specificity are closest 
together (Farrar et al, 2001). 
The second is the cut-point corresponding to the smallest residual sum of sensitivity and specificity; this methodology has been proposed by researchers from the EMGO 
Institute (de Vet et al, 2009).

The refvar should be the external criterion variable and must be either 0 or 1; 1 representing an improvement in health status. The classvar should be the change score variable 
(baseline minus follow-up). The minimal scale unit is the smallest increment measured by the instrument. In contrast to {cmd:roctab}, which when used with the option 
{cmd:detail}, presents sensitivity and specificity greater than or equal to each cut-point, this program naturally calculates sensitivity and specificity for values greater 
than a corresponding cut-point. Thus, to obtain the MIC, the scale's minimal increment must be added, in cases of improvement, and subtracted in cases of deterioration. 
While in this prototype program, it is necessary to add this information, in future versions of the program I anticipate this will be unnecessary.  

The program also calculated the ROC AUC with a 95% confidence interval in the same way as the command {cmd:roctab} and produces a graph of sensitivity and sensitivity 
and plots a ROC curve (although the latter function is suppressed when using {cmd:fastmic}).


{title:Options}

{dlgtab:Main}

{phang}
There are currently no options available for {cmd:rocmic}. However, it will work with the {cmd:bootstrap} command.
The program stores the MIC estimate for the 45 degree tangent line method in r(mic) and the EMGO MIC estimate is stored 
in r(emgo).


{title:Examples}

{phang}{cmd:. rocmic ref change, scale(1)}

{phang}{cmd:. rocmicd ref change, scale(0.1)}

{phang}{cmd:. bootstrap MIC=(r(mic)): fastmic ref change, scale(1)}

{phang}{cmd:. bootstrap MIC=(r(mic)), reps(1000): fastmic ref change, scale(1)}

{phang}{cmd:. bootstrap MIC=(r(emgo)): fastmicd ref change, scale(1)}

{phang}{cmd:. bootstrap MIC=(r(mic)) MICemgo=(r(emgo): fastmic ref change, scale(1)}




{title:References}


{pstd}
Farrar JT, Young JP, Jr., LaMoreaux L, Werth JL, Poole RM. Clinical importance of changes in chronic pain intensity measured on an 11-point numerical pain 
rating scale. Pain 2001;94(2):149-58.

{pstd}
de Vet H, Terluin B, Knol D, Roorda L, Mokkink B, Ostelo R, et al. There are three different ways to quantify the uncertainty when 'minimally important 
change' (MIC)  values are applied to individual patients. J Clin Epidemiol 2009(IN PRESS).

{pstd}
R. Froud, S. Eldridge, R.Lall, M.Underwood, Estimating NNT from continuous outcomes in randomised controlled trials: Methodological challenges and worked example using data 
from the UK Back Pain Exercise and Manipulation (BEAM) trial ISRCTN32683578. {it:BMC Health Services Research} {bf:2009 IN PRESS}.



{title:Acknowledgements}

{pstd}
Thanks to my PhD supervisors S. Eldridge and  M.Underwood.


{title:Author}

{pstd}
Robert Froud r.j.froud@qmul.ac.uk


{title:Also see}

{psee}
Manual:  {bf:[ST] bootstrap}
{bf:[ST] roctab}
{bf:[ST] logistic}
{bf:[ST] lsens}
{psee}
Online: www.robertfroud.info/software.html 
email: r.j.froud@qmul.ac.uk
