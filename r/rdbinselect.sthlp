{smcl}
{* *! version 5.5 17Jun2014}{...} 
{cmd:help rdbinselect}{right: ({browse "http://www.stata-journal.com/article.html?article=st0366":SJ14-4: st0366})}
{hline}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{hi:rdbinselect} {hline 2}}Integrated mean squared error (IMSE)-optimal data-driven regression-discontinuity (RD) plots
{p2colreset}{...}

{pstd}Note: this command is no longer maintained and is included only for
back compatibility. Please use the new command {helpb rdplot:rdplot}.


{marker syntax}{...}
{title:Syntax}

{p 8 11 2}{cmd:rdbinselect } {it:depvar} {it:runvar} {ifin} 
[{cmd:,} 
{cmd:c(}{it:cutoff}{cmd:)} 
{cmd:p(}{it:pvalue}{cmd:)}
{cmd:numbinl(}{it:numbinlvalue}{cmd:)}
{cmd:numbinr(}{it:numbinrvalue}{cmd:)}
{cmd:binselect(}{it:binmethod}{cmd:)}
{cmd:lowerend(}{it:xlvalue}{cmd:)} 
{cmd:upperend(}{it:xuvalue}{cmd:)} 
{cmd:scale(}{it:scalevalue}{cmd:)}
{cmd:scalel(}{it:scalelvalue}{cmd:)}
{cmd:scaler(}{it:scalervalue}{cmd:)}
{cmd:generate(}{it:idname meanxname meanyname}{cmd:)}
{cmd:graph_options(}{it:gphopts}{cmd:)}
{cmd:hide}]


{synoptset 28 tabbed}{...}

{marker description}{...}
{title:Description}

{pstd}{cmd:rdbinselect} implements IMSE-optimal data-driven evenly spaced and quantile-based RD plots.  This command is superseded by the command {help rdplot:rdplot} and is included only for back compatability.
See
{browse "http://www-personal.umich.edu/~cattaneo/papers/RD-binselect.pdf":Calonico, Cattaneo, and Titiunik (2014a)} 
and
{browse "http://www-personal.umich.edu/~cattaneo/papers/Calonico-Cattaneo-Titiunik_2014_Stata.pdf":Calonico, Cattaneo, and Titiunik (forthcoming)} for a discussion on the results implemented by these commands.

{pstd}A companion {browse "www.r-project.org":R} package is described in {browse "http://www-personal.umich.edu/~cattaneo/papers/Calonico-Cattaneo-Titiunik_2014_JSS.pdf":Calonico, Cattaneo, and Titiunik (2014b)}.


{marker options}{...}
{title:Options}

{phang}{cmd:c(}{it:cutoff}{cmd:)} specifies the RD cutoff in
{it:indepvar}.  The default is {cmd:c(0)}.

{phang}{cmd:p(}{it:pvalue}{cmd:)} specifies the order of the
global polynomial used to approximate the population conditional mean
functions for control and treated units.  The default is {cmd:p(4)}.

{phang}{cmd:numbinl(}{it:numbinlvalue}{cmd:)} specifies the number of bins used to the left of the cutoff, denoted J-.
If not specified, J- is estimated using the method and options chosen below.

{phang}{cmd:numbinr(}{it:numbinrvalue}{cmd:)} specifies the number of bins used to the right of the cutoff, denoted J+.
If not specified, J+ is estimated using the method and options chosen below.

{phang}{cmd:binselect(}{it:binmethod}{cmd:)} specifies the the partition-length selection procedure to be used.  This option is available only if J- and J+ are not set manually.
{it:binmethod} may be one of the following:{p_end} 

{phang2}{opt es} specifies the evenly spaced method using spacings estimators; the default.{p_end}

{phang2}{opt espr} specifies the evenly spaced method with polynomial regression.{p_end}

{phang2}{opt esdw} specifies the density-weighted evenly spaced method.{p_end}

{phang2}{opt qs} specifies the quantile-spaced method with spacings estimators.{p_end}

{phang2}{opt qspr} specifies the quantile-spaced method using polynomial regression.{p_end}

{phang2}{opt qsdw} specifies the density-weighted quantile-spaced method.{p_end}

{phang}{cmd:lowerend(}{it:xlvalue}{cmd:)} specifies the lower bound for {it:indepvar} to the left of the cutoff.
The default is the minimum value in sample.

{phang}{cmd:upperend(}{it:xuvalue}{cmd:)} specifies the upper bound for
{it:indepvar} to the right of the cutoff.  The default is the maximum
value in sample.

{phang}{cmd:scale(}{it:scalevalue}{cmd:)} specifies a multiplicative
factor to be used with the optimal number of bins selected.
Specifically, the number of bins used for the treatment and control
groups will be {cmd:scale(}{it:scalevalue}{cmd:)} * J+ and
{cmd:scale(}{it:scalevalue}{cmd:)} * J- , where J- and J+ denote the
optimal numbers of bins originally computed for each group.  The default
is {cmd:scale(1)}.

{phang}{cmd:scalel(}{it:scalelvalue}{cmd:)} specifies a multiplicative
factor to be used with the optimal number of bins selected to the left of the
cutoff.  The number of bins used will be
{cmd:scalel(}{it:scalelvalue}{cmd:)} * J-.  The default is
{cmd:scalel(1)}.

{phang}{cmd:scaler(}{it:scalervalue}{cmd:)} specifies a multiplicative factor to be used with the optimal number of bins selected to the right of the cutoff.  The number of bins used will be {cmd:scaler(}{it:scalervalue}{cmd:)} * J+.
The default is {cmd:scaler(1)}.

{phang}{cmd:generate(}{it:idname} {it:meanxname} {it:meanyname}{cmd:)} generates new variables storing the results;{p_end}

{phang2}{it:idname} specifies the name of a new generated variable with a unique bin id that identifies the chosen bins.  This variable indicates the bin (between {cmd:lowerend()} and {cmd:upperend()}) to which each observation belongs.
Negative natural numbers are assigned to observations to the left of the cutoff, and positive natural numbers are assigned to observations to the right of the cutoff.{p_end}

{phang2}{it:meanxname} specifies the name of a new generated variable (of the same length as {it:idname}) with the middle point of the running variable within each chosen bin.{p_end}

{phang2}{it:meanyname} specifies the name of a new generated variable (of the same length as {it:idname}) with the sample mean of the outcome variable within each chosen bin.{p_end}

{phang}{cmd:graph_options(}{it:gphopts}{cmd:)} specifies graphical options to be passed on to the underlying graph command.

{phang}{cmd:hide} omits the RD plot.


{marker example}{...}
{title:Example}

{phang}{cmd:Example: Cattaneo, Frandsen, and Titiunik (forthcoming) incumbency data}{p_end}

{phang}Setup{p_end}
{phang2}{cmd:. use rdrobust_RDsenate.dta}{p_end}

{phang}Basic specification with title{p_end}
{phang2}{cmd:. rdbinselect vote margin, graph_options(title(RD Plot))}{p_end}

{phang}Setting lower and upper bounds on the running variable{p_end}
{phang2}{cmd:. rdbinselect vote margin, lowerend(-50) upperend(50)}{p_end}


{marker stored_results}{...}
{title:Stored results}

{p 4 8}{cmd:rdbinselect} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(J_star_l)}} number of bins to the left of the cutoff{p_end}
{synopt:{cmd:e(J_star_r)}} number of bins to the right of the cutoff{p_end}
{synopt:{cmd:e(binlength_l)}} length of bins to the left of the cutoff{p_end}
{synopt:{cmd:e(binlength_r)}} length of bins to the right of the cutoff{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(gamma_p1_l)}} coefficients of the pth-order polynomial estimated to the left of the cutoff{p_end}
{synopt:{cmd:e(gamma_p1_r)}} coefficients of the pth-order polynomial estimated to the right of the cutoff{p_end}


{title:References}

{p 4 8}Calonico, S., M. D. Cattaneo, and R. Titiunik.  2014a.  Optimal
data-driven regression discontinuity plots.  Working Paper, University
of Michigan.
{browse "http://www-personal.umich.edu/~cattaneo/papers/RD-binselect.pdf"}.

{p 4 8}_____.  2014b.  rdrobust:
An R package for robust inference in regression-discontinuity designs.
Working Paper, University of Michigan.
{browse "http://www-personal.umich.edu/~cattaneo/papers/Calonico-Cattaneo-Titiunik_2014_Rpkg.pdf"}.

{p 4 8}_____.  Forthcoming.  Robust nonparametric confidence intervals for regression-discontinuity designs.  {it:Econometrica}.
{browse "http://www-personal.umich.edu/~cattaneo/papers/Calonico-Cattaneo-Titiunik_2014_ECMA.pdf"}.

{p 4 8}Cattaneo, M. D., B. Frandsen, and R. Titiunik.  Forthcoming.  Randomization inference in the regression discontinuity design: An application to the study of party advantages in the U.S. Senate.  {it:Journal of Causal Inference}.
{browse "http://www-personal.umich.edu/~cattaneo/papers/Cattaneo-Frandsen-Titiunik_2014_JCI.pdf"}.


{marker Authors}{...}
{title:Authors}

{pstd}Sebastian Calonico{p_end}
{pstd}University of Miami{p_end}
{pstd}Coral Gables, FL{p_end}
{pstd}scalonico@bus.miami.edu{p_end}

{pstd}Matias D. Cattaneo{p_end}
{pstd}University of Michigan{p_end}
{pstd}Ann Arbor, MI{p_end}
{pstd}cattaneo@umich.edu{p_end}

{pstd}Roc{c i'}o Titiunik{p_end}
{pstd}University of Michigan{p_end}
{pstd}Ann Arbor, MI{p_end}
{pstd}titiunik@umich.edu{p_end}


{marker also_see}{...}
{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 14, number 4: {browse "http://www.stata-journal.com/article.html?article=st0366":st0366}
{p_end}
