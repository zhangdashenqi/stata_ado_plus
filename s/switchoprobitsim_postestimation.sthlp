{smcl}
{* *! version 1.0.0 3mar2014}{...}
{cmd:help switchoprobitsim postestimation}{right: ({browse "http://www.stata-journal.com/article.html?article=st0402":SJ15-3: st0402})}
{hline}

{title:Title}

{p2colset 5 40 42 2}{...}
{p2col:{cmd:switchoprobitsim postestimation} {hline 2}}Postestimation
tools for switchoprobitsim{p_end}
{p2colreset}{...}


{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}
{cmd:predict}
{dtype}
{newvar}
{ifin}
[{cmd:,} {it:options}]

{marker options}{...}
{synoptset 13}{...}
{synopthdr}
{synoptline}
{synopt:{opt p11}}joint probability of treatment and outcome 1; the default{p_end}
{synopt:{opt p1}{it:#}}joint probability of treatment and outcome {it:#}{p_end}
{synopt:{opt p0}{it:#}}joint probability of nontreatment and outcome {it:#}{p_end}
{synopt:{opt te}{it:#}}treatment effect on outcome {it:#}{p_end}
{synopt:{opt tt}{it:#}}treatment effect on treated for outcome {it:#}{p_end}
{synopt:{opt sete}{it:#}}standard error of treatment effect on outcome {it:#}{p_end}
{synopt:{opt sett}{it:#}}standard error of treatment on treated for outcome {it:#}{p_end}
{synopt:{opt ptr}}probability of treatment{p_end}
{synopt:{opt xbout0}}linear prediction for outcome, untreated group{p_end}
{synopt:{opt xbout1}}linear prediction for outcome, treated group{p_end}
{synopt:{opt lf}}likelihood contribution{p_end}
{synoptline}
{p2colreset}{...}


{title:Options for predict}

{phang}
{opt p11} calculates the joint probability of participation in treatment and
outcome 1; the default.

{phang}
{opt p1}{it:#} calculates the joint probability of participation in treatment
and outcome {it:#}.

{phang}
{opt p0}{it:#} calculates the joint probability of nonparticipation in
treatment and outcome {it:#}.

{phang}
{opt te}{it:#} calculates the treatment effect on outcome {it:#}.

{phang}
{opt tt}{it:#} calculates the treatment effect on the treated for outcome
{it:#}.

{phang}
{opt sete}{it:#} calculates the standard error of the treatment effect on
outcome {it:#}.

{phang}
{opt sett}{it:#} calculates the standard error of the treatment effect on the
treated for outcome {it:#}.

{phang}
{opt ptr} calculates the probability of treatment.

{phang}
{opt xbout0} calculates the linear predictions for the outcome variable for
the untreated group.

{phang}
{opt xbout1} calculates the linear predictions for the outcome variable for
the treated group.

{phang}
{opt lf} calculates the likelihood contribution for each observation.


{title:Examples}

{phang}{cmd:. switchoprobitsim y x1 x2, treatment(d=x1 x2 z) simulationdraws(50) facdensity(normal) vce(robust)}{p_end}
{phang}{cmd:. predict pr11}{p_end}
{phang}{cmd:. predict ate1, te1}{p_end}
{phang}{cmd:. predict att3, tt3}{p_end}


{title:Author}

{pstd}Christian A. Gregory{p_end}
{pstd}Economic Research Service, USDA{p_end}
{pstd}Washington, DC{p_end}
{pstd}cgregory@ers.usda.gov{p_end}


{marker also_see}{...}
{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 15, number 3: {browse "http://www.stata-journal.com/article.html?article=st0402":st0402}

{p 7 14 2}Help:  {helpb switchoprobitsim} (if installed)
{p_end}
