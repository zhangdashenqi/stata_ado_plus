{smcl}
{* *! version 7.0.4 29Mar2016}{...}
{cmd:help rdplot}{right: ({browse "http://www.stata-journal.com/article.html?article=st0366_1":SJ17-2: st0366_1})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col:{cmd:rdplot} {hline 2}}Data-driven regression-discontinuity plots{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:rdplot} {it:depvar} {it:runvar} {ifin} 
[{cmd:,} 
{cmd:c(}{it:cutoff}{cmd:)} 
{cmd:p(}{it:pvalue}{cmd:)}
{cmd:kernel(}{it:kernelfn}{cmd:)}
{cmd:weights(}{it:weightsvar}{cmd:)}
{cmd:h(}{it:hvalueL hvalueR}{cmd:)} 
{cmd:nbins(}{it:nbinsvalueL nbinsvalueR}{cmd:)}
{cmd:binselect(}{it:binmethod}{cmd:)}
{cmd:scale(}{it:scalevalueL scalevalueR}{cmd:)}
{cmd:ci(}{it:cilevel}{cmd:)}
{cmd:shade}
{cmd:support(}{it:supportvalueL supportvalueR}{cmd:)}
{cmd:genvars}
{cmd:graph_options(}{it:gphopts}{cmd:)}
{cmd:hide}]

{pstd}
where {it:depvar} is the dependent variable and {it:runvar} is the
running variable (also known as the score or forcing variable).


{marker description}{...}
{title:Description}

{pstd}
{cmd:rdplot} implements several data-driven regression-discontinuity (RD)
plots, using either evenly spaced or quantile-spaced partitioning.  Two types
of RD plots are constructed: RD plots with binned sample means tracing out the
underlying regression function and RD plots with binned sample means mimicking
the underlying variability of the data.  For technical and methodological
details, see Calonico, Cattaneo, and Titiunik (2015a).

{pstd}
{cmd:rdplot} has two companion commands: {helpb rdrobust:rdrobust} for point
estimation and inference procedures and {helpb rdbwselect:rdbwselect} for
data-driven bandwidth selection.{p_end}

{pstd}
A detailed introduction to this command is given in both Calonico, Cattaneo,
and Titiunik (2014) and Calonico et al. (2017).  A companion 
{browse "www.r-project.org":R package} is also described in Calonico,
Cattaneo, and Titiunik (2015b).

{pstd}
For more details, and for related Stata and R packages useful for analysis of
RD designs, visit {browse "https://sites.google.com/site/rdpackages/"}.


{marker options}{...}
{title:Options}

{phang}
{cmd:c(}{it:cutoff}{cmd:)} specifies the RD cutoff.  The default is
{cmd:c(0)}.

{phang}
{cmd:p(}{it:pvalue}{cmd:)} specifies the order of the (global) polynomial fit
used to approximate the population conditional mean functions for control and
treated units.  The default is {cmd:p(4)}.

{phang}
{cmd:kernel(}{it:kernelfn}{cmd:)} specifies the kernel function used to
construct the global polynomial estimators.  {it:kernelfn} may be 
{opt tri:angular}, {opt epa:nechnikov}, or {opt uni:form}.  The default is
{cmd:kernel(uniform)} (that is, equal or no weighting to all observations on
the support of the kernel).

{phang}
{cmd:weights(}{it:weightsvar}{cmd:)} specifies the variable used for optional
weighting of the estimation procedure.  The unit-specific weights multiply the
kernel function.{p_end}

{phang}
{cmd:h(}{it:hvalueL hvalueR}{cmd:)} specifies the main bandwidth, h, to be
used on the left and on the right of the cutoff, respectively.  If only one
value is specified, then this value is used on both sides.  If two bandwidths
are specified, the first bandwidth is used for the data below the cutoff and
the second bandwidth is used for the data above the cutoff.  If not specified,
it is chosen to span the full support of the data.

{phang}
{cmd:nbins(}{it:nbinsvalueL nbinsvalueR}{cmd:)} specifies the number of bins
used to the left of the cutoff (denoted J-) and the number of bins used to the
right of the cutoff (denoted J+), respectively.  If only one value is
specified, then this value is used on both sides.  If not specified, J- and J+
are estimated using the {cmd:binselect()} option.

{phang}
{cmd:binselect(}{it:binmethod}{cmd:)} specifies the data-driven procedure to
select the number of bins.  This option is available only if J- and J+ are not
set manually using {cmd:nbins()}.  {it:binmethod} may be one of the following:

{phang2}
{opt es} specifies the integrated mean squared error (IMSE)-optimal
evenly spaced method using spacing estimators.{p_end}

{phang2}
{opt espr} specifies the IMSE-optimal evenly spaced method using polynomial
regression.{p_end}

{phang2}
{opt esmv} specifies the mimicking-variance evenly spaced method using spacing
estimators; the default.{p_end}

{phang2}
{opt esmvpr} specifies the mimicking-variance evenly spaced method using
polynomial regression.{p_end}

{phang2}
{opt qs} specifies the IMSE-optimal quantile-spaced method using spacing
estimators.{p_end}

{phang2}
{opt qspr} specifies the IMSE-optimal quantile-spaced method using polynomial
regression.{p_end}

{phang2}
{opt qsmv} specifies the mimicking-variance quantile-spaced method using
spacing estimators.{p_end}

{phang2}
{opt qsmvpr} specifies the mimicking-variance quantile-spaced method using
polynomial regression.{p_end}

{phang}
{cmd:scale(}{it:scalevalueL scalevalueR}{cmd:)} specifies multiplicative
factors, denoted {it:s-} and {it:s+}, respectively, to adjust the number of
bins selected.  Specifically, the number of bins used for the treatment and
control groups will be ceil({cmd:s- * J-}) and ceil({cmd:s+ * J+}), where J-
and J+ denote the optimal numbers of bins originally computed for each group.
The default is {cmd:scale(1 1)}.

{phang}
{cmd:ci(}{it:cilevel}{cmd:)} specifies the optional graphical option to
display confidence intervals of level {it:cilevel} for each bin.

{phang}
{cmd:shade} specifies the optional graphical option to replace confidence
intervals with shaded areas.

{phang}
{opt support(supportvalueL supportvalueR)} specifies an optional extended
support of the running variable to be used in the construction of the bins.
The default is the sample range.

{phang}
{cmd:genvars} generates the following new variables that store results:

{phang2}
{cmd:rdplot_id} stores a unique bin ID for each observation.  Negative natural
numbers are assigned to observations to the left of the cutoff, and positive
natural numbers are assigned to observations to the right of the cutoff.

{phang2}
{cmd:rdplot_N} stores the number of observations in the corresponding bin for
each observation.

{phang2}
{cmd:rdplot_min_bin} stores the lower end value of the bin for each observation.

{phang2}
{cmd:rdplot_max_bin} stores the upper end value of the bin for each observation.

{phang2}
{cmd:rdplot_mean_bin} stores the middle point of the corresponding bin for
each observation.

{phang2}
{cmd:rdplot_mean_x} stores the sample mean of the running variable within the
corresponding bin for each observation.

{phang2}
{cmd:rdplot_mean_y} stores the sample mean of the outcome variable within the
corresponding bin for each observation.

{phang2}
{cmd:rdplot_se_y} stores the standard deviation of the mean of the outcome
variable within the corresponding bin for each observation.

{phang2}
{cmd:rdplot_ci_l} stores the lower end value of the confidence interval for
the sample mean of the outcome variable within the corresponding bin for each
observation.

{phang2}
{cmd:rdplot_ci_r} stores the upper end value of the confidence interval for
the sample mean of the outcome variable within the corresponding bin for each
observation.

{phang2}
{cmd:rdplot_hat_y} stores predicted value of the outcome variable given by the
global polynomial estimator.

{phang}
{cmd:graph_options(}{it:gphopts}{cmd:)} specifies graphical options to be
passed on to the underlying {cmd:graph} command.

{phang}
{cmd:hide} omits the RD plot.


{title:Example: Cattaneo, Frandsen, and Titiunik (2015) incumbency data}

{pstd}Setup{p_end}
{phang2}{cmd:. use rdrobust_senate.dta}{p_end}

{pstd}Basic specification with title{p_end}
{phang2}{cmd:. rdplot vote margin, graph_options(title(RD plot))}{p_end}

{pstd}Quadratic global polynomial with confidence bands{p_end}
{phang2}{cmd:. rdplot vote margin, p(2) ci(95) shade}{p_end}


{marker stored_results}{...}
{title:Stored results}

{pstd}
{cmd:rdplot} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N_l)}}original number of observations to the left of the cutoff{p_end}
{synopt:{cmd:e(N_r)}}original number of observations to the right of the cutoff{p_end}
{synopt:{cmd:e(c)}}cutoff value{p_end}
{synopt:{cmd:e(J_star_l)}}selected number of bins to the left of the cutoff{p_end} 
{synopt:{cmd:e(J_star_r)}}selected number of bins to the right of the cutoff{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(binselect)}}method used to compute the optimal number of bins{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(coef_l)}}coefficients of the pth-order polynomial estimated to the left of the cutoff{p_end}
{synopt:{cmd:e(coef_r)}}coefficients of the pth-order polynomial estimated to the right of the cutoff{p_end}


{title:References}

{phang}
Calonico, S., M. D. Cattaneo, M. H. Farrell, and R. Titiunik. 2017.
{browse "http://www.stata-journal.com/article.html?article=st0366_1":rdrobust: Software for regression-discontinuity designs}.
{it:Stata Journal} 17: 372-404.

{phang}
Calonico, S., M. D. Cattaneo, and R. Titiunik. 2014. 
{browse "http://www.stata-journal.com/article.html?article=st0366":Robust data-driven inference in the regression-discontinuity design}.
{it:Stata Journal} 14: 909-946. 

{phang}
------. 2015a. Optimal data-driven regression discontinuity plots.
{it:Journal of the American Statistical Association} 110: 1753-1769. 

{phang}
------. 2015b. rdrobust: An R package for robust nonparametric inference in regression-discontinuity designs.
{it:R Journal} 7: 38-51.

{phang}
Cattaneo, M. D., B. Frandsen, and R. Titiunik. 2015. Randomization inference in the regression discontinuity design: An application to party advantages in the U.S. Senate.
{it:Journal of Causal Inference} 3: 1-24.


{title:Authors}

{pstd}
Sebastian Calonico{break}
University of Miami{break}
Coral Gables, FL{break}
{browse "mailto:scalonico@bus.miami.edu":scalonico@bus.miami.edu}{p_end}

{pstd}
Matias D. Cattaneo{break}
University of Michigan{break}
Ann Arbor, MI{break}
{browse "mailto:cattaneo@umich.edu":cattaneo@umich.edu}{p_end}

{pstd}
Max H. Farrell{break}
University of Chicago{break}
Chicago, IL{break}
{browse "mailto:max.farrell@chicagobooth.edu":max.farrell@chicagobooth.edu}{p_end}

{pstd}
Roc{c i'}o Titiunik{break}
University of Michigan{break}
Ann Arbor, MI{break}
{browse "mailto:titiunik@umich.edu":titiunik@umich.edu}{p_end}


{marker also_see}{...}
{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 17, number 2: {browse "http://www.stata-journal.com/article.html?article=st0366_1":st0366_1},{break}
                    {it:Stata Journal}, volume 14, number 4: {browse "http://www.stata-journal.com/article.html?article=st0366":st0366}
{p_end}
