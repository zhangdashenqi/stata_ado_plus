{smcl}
{* 04feb2009}{...}
{cmd:help mfpboot_bif}{right: ({browse "http://www.stata-journal.com/article.html?article=st0177":SJ9-4: st0177})}
{hline}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{hi:mfpboot_bif} {hline 2}}Bootstrap inclusion fraction for multivariable fractional polynomial models{p_end}


{title:Syntax}

{p 8 14 2}
{cmd:mfpboot_bif}
	[{cmd:,} {opt t:erm(#)} {opt g:enerate}]


{title:Description}

{pstd}
{cmd:mfpboot_bif} computes the bootstrap inclusion fraction (BIF) for each
predictor in a dataset created by {helpb mfpboot}. The BIF for a given variable
is the proportion of bootstrap replications in which the variable 
entered the model selected by {helpb mfp}.


{title:Options}

{phang}
{opt term(#)} refers to the fractional polynomial (FP) term. The default is
{cmd:term(1)}, meaning to compute the BIF for the first term of the FP function of a
predictor (the only term, if the variable was modeled as FP1 or linear).
Specifying {cmd:term(2)} would compute the BIF for the FP2 term and would
indicate the fraction of bootstrap replicates in which multivariable fractional
polynomial selected an FP2 function for each variable.

{phang}
{opt generate} generates new variables indicating whether each FP term
in the dataset has been selected (new variable taking on the value 1) or not
(taking on the value 0). The new variables are named by appending {cmd:i}{it:#}
to the name of the original variable, where {it:#} is 1 (for the FP1
or linear term) or 2 (for the FP2 term).


{title:Examples}

{phang}{cmd:. use mfpboot}

{phang}{cmd:. mfpboot_bif}

{phang}{cmd:. mfpboot_bif, term(2) generate}


{title:Also see}

{psee}
Article: {it:Stata Journal}, volume 9, number 4: {browse "http://www.stata-journal.com/article.html?article=st0177":st0177}{p_end}

{psee}
Manual:  {manlink R mfp}, {manlink R fracpoly}

{psee}
Online:  {manhelp mfp R}, {helpb mfpboot}, {helpb pmbeval}
{p_end}
