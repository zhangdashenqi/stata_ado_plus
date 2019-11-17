{smcl}
{* *! version 1.0 - 22 June 2016}{...}
{cmd:help pvarstable}{right: ({browse "http://www.stata-journal.com/article.html?article=st0455":SJ16-3: st0455})}
{hline}

{title:Title}

{p 5 21 2}
{bf:pvarstable} {hline 2} Check the stability condition of panel VAR estimates computed using pvar


{title:Syntax}

{p 8 17 2}
{cmd:pvarstable} 
[{cmd:,} {it:options}]

{synoptset 20}{...}
{synopthdr}
{synoptline}
{synopt:{opt est:imates(estname)}}use previously saved results {it: estname}; default is to use active results{p_end}
{synopt:{opt gra:ph}}graph eigenvalue of the companion matrix{p_end}
{synopt:{opt nogri:d}}suppress polar grid circles{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:pvarstable} can be used only after {cmd:pvar}; see {helpb pvar}.{p_end}


{title:Description}

{pstd}
{cmd:pvarstable} checks the eigenvalue condition after estimating the
parameters of a panel vector autoregression using {helpb pvar}.


{title:Options}

{phang}
{opt estimates(estname)} requests that {cmd:pvarstable} use the previously
obtained set of {helpb pvar} estimates saved in {it:estname}.  By default,
{cmd:pvarstable} uses the active estimation results.  See
{manhelp estimates R} for information on saving and restoring estimation
results.

{phang}
{opt graph} requests {cmd:pvarstable} to draw a graph of the eigenvalue of the
companion matrix.

{phang}
{opt nogrid} suppresses the polar grid circles on the plotted eigenvalues.
This option may be specified only with {cmd:graph}.


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse nlswork2}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}
{phang2}{cmd:. generate wage = exp(ln_wage)}{p_end}

{pstd}Fit panel vector autoregressive model{p_end}
{phang2}{cmd:. pvar wage hours}{p_end}

{pstd}Check stability of the {cmd:pvar} results{p_end}
{phang2}{cmd:. pvarstable}

{pstd}Same as above, but graph eigenvalues of the companion matrix{p_end}
{phang2}{cmd:. pvarstable, graph}

{pstd}Same as above, but suppress polar grids{p_end}
{phang2}{cmd:. pvarstable, graph nogrid}


{title:Stored results}

{pstd}
{cmd:pvarstable} stores the following in {cmd:r()}:

{synoptset 13 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(Re)}}real part of the eigenvalues of the companion matrix{p_end}
{synopt:{cmd:r(Im)}}imaginary part of the eigenvalues of the companion matrix{p_end}
{synopt:{cmd:r(Modulus)}}modulus of the eigenvalues of the companion matrix{p_end}
{p2colreset}{...}


{title:Authors}

{pstd}
Michael R. M. Abrigo{break}
Philippine Institute for Development Studies{break}
mabrigo@mail.pids.gov.ph{break}

{pstd}
Inessa Love{break}
University of Hawaii at Manoa{break}
ilove@hawaii.edu


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 16, number 3: {browse "http://www.stata-journal.com/article.html?article=st0455":st0455}

{p 7 14 2}Help:  
{helpb pvar}, 
{helpb pvarirf}, 
{helpb pvarfevd}, 
{helpb pvargranger},
{helpb pvarsoc}
{p_end}
