{smcl}
{* 2014-08-06 scott long & jeremy freese}{...}
{title:Title}
{p2colset 5 17 23 2}{...}

{p2col:{cmd:countfit} {hline 2}}Compare fit of alternative count models{p_end}
{p2colreset}{...}


{title:General syntax}

{p 4 18 2}
{cmdab:countfit}
[{it:varlist}]
{it:[if]}
{it:[in]}
{cmd:,}
[ {opt inf:late(varlist)}
{opt noc:onstant}
{opt p:rm}
{opt n:breg}
{opt zip}
{opt zin:b}
{opt stub(prefix)}
{opt replace}
{opt nosave}
{opt note(string)}
{opt nog:raph}
{opt nod:ifferences}
{opt noprt:able}
{opt noe:stimates}
{opt nof:it}
{opt nodash}
{opt max count(#)}
{opt noi:sily} ]
{p_end}

{marker overview}
{title:Overview}

{pstd}
{cmd: countfit} compares the fit of the Poisson, negative binomial, zero-inflated
Poisson and zero-inflated negative binomial models, generating a table of
estimates, a table of differences between observed and average estimated
probabilities for each count, a graph of these differences, and various tests
and measures used to compare the fit of count models.
{p_end}

{marker specifying}
{title:Specifying the model}

{pstd}
Immediately after the command name {cmd: countfit} you specify the dependent and
independent variables as you would with {cmd: poisson} or other count models. For
zero-inflated models, the {cmd: inflate} option is used in the same was as in the
{cmd: zip} and {cmd: zinb} commands. {cmd: noconstant} can be used to exclude the constant term.
{p_end}

{marker options}
{title:Options to select the models to fit}

{pstd}
By default, {cmd: poisson}, {cmd: nbreg}, {cmd: zip} and {cmd: zinb} are estimated. If you
only want some of these models, specify the models you want with:

{p2colset 10 19 1 44}{...}
{p2col :Option}Model estimated{p_end}
{p2line}
{p2col :{opt prm}}{opt poisson}{p_end}
{p2col :{opt nbreg}}{opt nbreg}{p_end}
{p2col :{opt zip}}{opt poisson}{p_end}
{p2col :{opt zinb}}{opt poisson}{p_end}
{p2line}

{marker label}
{title:Options to label results}

{p2colset 5 18 19 0}
{synopt:{opt stub()}} is up to five letters to name the variables that are created and to label the models in the output. This name is placed in front of the type of model (e.g., namePRM). This option helps keep track of results from multiple specifications of models.
{p_end}
{p2colset 5 18 19 0}
{synopt:{opt replace}} will replace variables created with the ^generate^ option if they already exist.
{p_end}
{p2colset 5 18 19 0}
{synopt:{opt nosave}} do not save variables generated to create graph.
{p_end}
{p2colset 5 18 19 0}
{synopt:{opt note()}} is a label added to the graph that is saved.
{p_end}

{marker print}
{title:Options controlling what is printed}

{p2colset 5 18 19 0}
{synopt:{opt maxcount()}} number of counts to evaluate.
{p_end}
{p2colset 5 18 19 0}
{synopt:{opt noisily}} shows the output from the estimation commands called by {cmd: countfit}.
{p_end}
{p2colset 5 18 19 0}
{synopt:{opt nograph}} suppress graph of differences from observed counts.
{p_end}
{p2colset 5 20 19 0}
{synopt:{opt nodifferences}} suppress table of differences from observed counts.
{p_end}
{p2colset 5 18 19 0}
{synopt:{opt noprtable}} suppresses table of predictions for each model.
{p_end}
{p2colset 5 18 19 0}
{synopt:{opt noestimates}} suppress table of estimated coefficients.
{p_end}
{p2colset 5 18 19 0}
{synopt:{opt nofit}} suppress table of fit statistics and test of fit
{p_end}
{p2colset 5 18 19 0}
{synopt:{opt nodash}} suppress dashed lines between measures of fit
{p_end}
{p2colset 5 18 19 0}
{synopt:{opt noisily}} includes output from Stata estimation commands; without this option the results are only shown in the {cmd: estimates table} output.
{p_end}

{marker notes}
{title:Notes}

{pstd}
{cmd: countfit} is based on the results from the Stata models described above,
the predictions computed by {cmd: mgen}, and the fit measures computed by
{cmd: fitstat}.
{p_end}

{marker examples}
{title:Examples}

{phang}{cmd: . use couart4}{p_end}
{phang}{cmd: . countfit art fem mar kid5 phd ment, inf(ment fem) nbreg zinb nograph}{p_end}

INCLUDE help spost13_footer
