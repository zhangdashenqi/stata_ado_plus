{smcl}
{* *! version 1.3  28Oct2008}{...}
{cmd:help bollenstine} {right: ({browse "http://www.stata-journal.com/article.html?article=st0169":SJ9-3: st0169})}
{hline}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{hi:bollenstine} {hline 2}}Bollen-Stine bootstrap following confirmatory factor analysis
{p2colreset}{...}


{title:Syntax}

{p 8 19 2}
{cmd:bollenstine} [{cmd:,} {cmdab:r:eps(}{it:#}{cmd:) }
{cmdab:sav:ing(}{it:filename}{cmd:) }
{cmdab:confaopt:ions(}{it:string}{cmd:)}
{it:bootstrap_options}]
{p_end}


{title:Description}

{pstd}{cmd:bollenstine} performs the Bollen and Stine (1992) bootstrap
following structural equation models (confirmatory factor analysis) estimation.
The original data are rotated to conform to the fitted structure.
By default, {cmd:bollenstine} refits the model
with rotated data and uses the estimates as
starting values in each bootstrap iteration. It also rejects samples
where convergence was not achieved (implemented through the {cmd:reject(e(converged) == 0)} option supplied to
{helpb bootstrap}).


{title:Options}

{phang}{cmd:reps(}{it:#}{cmd:)} specifies the number of bootstrap replications.
The default is {cmd:reps(200)}.{p_end}

{phang}{cmd:saving(}{it:filename}{cmd:)} specifies the file
where the simulation results (the parameter estimates and the fit statistics)
are to be stored. The default is a temporary file that will
be deleted as soon as {cmd:bollenstine} finishes.{p_end}

{phang}{opt confaoptions(string)} allows the transfer of {cmd:confa}
options to {cmd:bollenstine}. If nondefault model options ({cmd:unitvar()} and
{cmd:correlated()}) were used, one would need to use them with
{cmd:bollenstine} as well.

{phang}All nonstandard model options, like {cmd:unitvar()} or {cmd:correlated()},
must be specified with {cmd:bollenstine} to produce correct results!

{phang}All other options are assumed to be {it:bootstrap_options}
and passed through to {helpb bootstrap}.


{title:Example}

{phang2}{cmd:. use hs-cfa}{p_end}
{phang2}{cmd:. confa (vis: x1 x2 x3) (text: x4 x5 x6) (math: x7 x8 x9), from(iv) correlated(x7:x8)}{p_end}
{phang2}{cmd:. set seed 10101}{p_end}
{phang2}{cmd:. bollenstine, reps(200) confaoptions(iter(20) corr(x7:x8))}


{title:Reference}

{phang}{bind:}Bollen, K., and R. Stine. 1992.
Bootstrapping goodness-of-fit measures in structural
equation models. {it:Sociological Methods and Research} 21: 205-229.
{p_end}


{title:Author}

{pstd}Stanislav Kolenikov{p_end}
{pstd}Department of Statistics{p_end}
{pstd}University of Missouri{p_end}
{pstd}Columbia, MO{p_end}
{pstd}kolenikovs@missouri.edu{p_end}


{title:Also see}

{psee}
Article: {it:Stata Journal}, volume 9, number 3: {browse "http://www.stata-journal.com/article.html?article=st0169":st0169}

{psee}Online: {helpb confa}, {helpb confa_estat:confa postestimation}, 
{helpb bootstrap} (if installed){p_end}
