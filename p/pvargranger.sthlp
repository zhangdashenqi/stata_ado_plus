{smcl}
{* *! version 1.0 - 22 June 2016}{...}
{cmd:help pvargranger}{right: ({browse "http://www.stata-journal.com/article.html?article=st0455":SJ16-3: st0455})}
{hline}

{title:Title}

{phang}
{bf:pvargranger} {hline 2} Perform pairwise Granger causality tests after pvar


{title:Syntax}

{p 8 17 2}
{cmd:pvargranger} 
[{cmd:,} {opt est:imates(estname)}]

{phang}
{cmd:pvargranger} can be used only after {cmd:pvar}; see {helpb pvar}.


{title:Description}

{pstd}
{cmd:pvargranger} performs a set of Granger causality Wald tests for each
equation of the underlying panel vector autoregression model.  It is
a convenient alternative to Stata's built-in {helpb test} command.


{title:Option}

{phang}
{opt estimates(estname)} requests that {cmd:pvargranger} use the previously
obtained set of panel VAR estimates saved as {it:estname}.  By default,
{cmd:pvargranger} uses the active (that is, the latest) results.
See {manhelp estimates R} for information about saving and restoring
estimation results.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse nlswork2}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}
{phang2}{cmd:. generate wage = exp(ln_wage)}{p_end}

{pstd}Fit a panel vector autoregression model{p_end}
{phang2}{cmd:. pvar wage hours}

{pstd}Perform pairwise Granger causality tests on the model{p_end}
{phang2}{cmd:. pvargranger}


{title:Stored results}

{pstd}
{cmd:pvargranger} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrix}{p_end}
{synopt:{cmd:r(pgstats)}}chi-squared, degrees of freedom, and p-values{p_end}
{p2colreset}{...}


{title:Authors}

{pstd}Michael R. M. Abrigo{break}
Philippine Institute for Development Studies{break}
mabrigo@mail.pids.gov.ph

{pstd}Inessa Love{break}
University of Hawaii at Manoa{break}
ilove@hawaii.edu


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 16, number 3: {browse "http://www.stata-journal.com/article.html?article=st0455":st0455}

{p 7 14 2}Help:
{helpb pvar},
{helpb pvarirf},
{helpb pvarfevd},
{helpb pvarsoc},
{helpb pvarstable}
{p_end}
