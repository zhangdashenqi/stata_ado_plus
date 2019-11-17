{smcl}
{* *! version 7.0.4 29Mar2016}{...}
{cmd:help rdbwselect_2014}{right: ({browse "http://www.stata-journal.com/article.html?article=st0366_1":SJ17-2: st0366_1})}
{hline}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{cmd:rdbwselect_2014} {hline 2}}Deprecated bandwidth selection procedures for local polynomial regression-discontinuity estimators{p_end}

{phang}
{ul:Important}: This command is no longer supported or updated; it is
made available only for backward compatibility purposes.  Please use 
{helpb rdbwselect:rdbwselect} instead.{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 23 2}{cmd:rdbwselect_2014} {it:depvar} {it:runvar} {ifin} 
[{cmd:,} 
{cmd:c(}{it:cutoff}{cmd:)} 
{cmd:p(}{it:pvalue}{cmd:)} 
{cmd:q(}{it:qvalue}{cmd:)}
{cmd:deriv(}{it:dvalue}{cmd:)}
{cmd:rho(}{it:rhovalue}{cmd:)}
{cmd:kernel(}{it:kernelfn}{cmd:)}
{cmd:bwselect(}{it:bwmethod}{cmd:)}
{cmd:scaleregul(}{it:scaleregulvalue}{cmd:)}
{cmd:delta(}{it:deltavalue}{cmd:)}
{cmd:cvgrid_min(}{it:cvgrid_minvalue}{cmd:)}
{cmd:cvgrid_max(}{it:cvgrid_maxvalue}{cmd:)}
{cmd:cvgrid_length(}{it:cvgrid_lengthvalue}{cmd:)}
{cmd:cvplot}
{cmd:vce(}{it:vcemethod}{cmd:)}
{cmd:matches(}{it:nummatches}{cmd:)}
{cmd:all}]

{pstd} where {depvar} is the dependent variable and {it:runvar} is the
running variable (also known as the score or forcing variable).
{synoptset 28 tabbed}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:rdbwselect_2014} is a deprecated command implementing three bandwidth
selectors for local polynomial regression-discontinuity (RD) point estimators
and inference procedures, as described in Calonico, Cattaneo, and Titiunik
(2014).  This command is no longer supported or updated.  It is made
available only for backward compatibility purposes.  This command
uses compiled Mata functions given in {cmd:rdbwselect_2014_fun.do}.{p_end}

{pstd}
The latest version of the {cmd:rdrobust} package includes the following commands:{p_end}

{phang2}{helpb rdrobust:rdrobust} for point estimation and inference procedures.{p_end}

{phang2}{helpb rdbwselect:rdbwselect} for data-driven bandwidth selection.{p_end}

{phang2}{helpb rdplot:rdplot} for data-driven RD plots.{p_end}

{pstd}
For more details, and for related Stata and R packages useful for analysis of
RD designs, visit {browse "https://sites.google.com/site/rdpackages/"}.


{marker options}{...}
{title:Options}

{phang}{cmd:c(}{it:cutoff}{cmd:)} specifies the RD cutoff.  The default is
{cmd:c(0)}.

{phang}
{cmd:p(}{it:pvalue}{cmd:)} specifies the order of the local polynomial to be
used to construct the point estimator.  The default is {cmd:p(1)} (local
linear regression).

{phang}
{cmd:q(}{it:qvalue}{cmd:)} specifies the order of the local polynomial to be
used to construct the bias correction.  The default is {cmd:q(2)} (local
quadratic regression).

{phang}
{cmd:deriv(}{it:dvalue}{cmd:)} specifies the order of the derivative of the
regression functions to be estimated.  The default is {cmd:deriv(0)} (sharp
RD, or fuzzy RD if {cmd:fuzzy()} is also specified).  Setting {cmd:deriv(1)}
results in estimation of a kink RD design (up to scale) or a fuzzy kink RD if
{cmd:fuzzy()} is also specified.

{phang}
{cmd:rho(}{it:rhovalue}{cmd:)} sets the pilot bandwidth, b, equal to h/rho,
where h is computed using the method and options chosen below.

{phang}
{cmd:kernel(}{it:kernelfn}{cmd:)} specifies the kernel function used to
construct the local polynomial estimators.  {it:kernelfn} may be 
{opt tri:angular}, {opt epa:nechnikov}, or {opt uni:form}.  The default is
{cmd:kernel(triangular)}.

{phang}
{cmd:bwselect(}{it:bwmethod}{cmd:)} specifies the bandwidth selection
procedure to be used.  By default, it computes both h and b, unless rho is
specified, in which case it computes only h and sets b=h/rho.  {it:bwmethod}
may be one of the following:{p_end}

{phang2}
{opt CCT} for the bandwidth selector proposed by Calonico, Cattaneo, and
Titiunik (2014).  The default is {cmd:bwselect(CCT)}.{p_end}

{phang2}
{opt IK} for the bandwidth selector proposed by Imbens and Kalyanaraman (2012)
(available only for sharp RD design).{p_end}

{phang2}
{opt CV} for the cross-validation method proposed by Ludwig and Miller (2007)
(available only for sharp RD design).{p_end}

{phang}
{cmd:scaleregul(}{it:scaleregulvalue}{cmd:)} specifies the scaling factor for
the regularization terms of {cmd:bwselect(CCT)} and {cmd:bwselect(IK)}
bandwidth selectors.  Setting {cmd:scaleregul(0)} removes the regularization
term from the bandwidth selectors.  The default is {cmd:scaleregul(1)}.

{phang}
{cmd:delta(}{it:deltavalue}{cmd:)} specifies the quantile that defines the
sample used in the cross-validation procedure.  This option is used only if
{cmd:bwselect(}{opt CV}{cmd:)} is specified.  The default is {cmd:delta(0.5)},
that is, the median of the control and treated subsamples.

{phang}
{cmd:cvgrid_min(}{it:cvgrid_minvalue}{cmd:)} specifies the minimum value of
the bandwidth grid used in the cross-validation procedure.  This option is
used only if {cmd:bwselect(}{opt CV}{cmd:)} is specified.

{phang}
{cmd:cvgrid_max(}{it:cvgrid_maxvalue}{cmd:)} specifies the maximum value of
the bandwidth grid used in the cross-validation procedure.  This option is
used only if {cmd:bwselect(}{opt CV}{cmd:)} is specified.

{phang}
{cmd:cvgrid_length(}{it:cvgrid_lengthvalue}{cmd:)} specifies the bin length of
the (evenly spaced) bandwidth grid used in the cross-validation procedure.
This option is used only if {cmd:bwselect(}{opt CV}{cmd:)} is specified.

{phang}
{cmd:cvplot} generates a graph of the cross-validation objective function.
This option is used only if {cmd:bwselect(}{opt CV}{cmd:)} is specified.

{phang}
{cmd:vce(}{it:vcemethod}{cmd:)} specifies the procedure used to compute the
variance-covariance matrix estimator.  This option is used only if the
{cmd:bwselect(CCT)} or {cmd:bwselect(IK)} bandwidth procedure is used.
{it:vcemethod} may be one of the following:{p_end}

{phang2}
{opt nn} for nearest neighbor residuals using {cmd:matches()}.  This is the
default option (with {cmd:matches(3)}; see below).{p_end}

{phang2}
{opt resid} for estimated plug-in residuals using h bandwidths.{p_end}

{phang}
{cmd:matches(}{it:nummatches}{cmd:)} specifies the number of matches in the
nearest-neighbor-based variance-covariance matrix estimator.  This option is
used only when nearest neighbor residuals are used.  The default is
{cmd:matches(3)}.

{phang}
{cmd:all} implements all three bandwidth selection procedures; see
{cmd:bwselect()} above.{p_end}


{title:References}

{phang}
Calonico, S., M. D. Cattaneo, and R. Titiunik.  2014.  {browse "http://www.stata-journal.com/article.html?article=st0366":Robust data-driven inference in the regression-discontinuity design}. 
{it:Stata Journal} 14: 909-946.

{phang}
Imbens, G. W., and K. Kalyanaraman. 2012.  Optimal bandwidth
choice for the regression discontinuity estimator.  
{it:Review of Economic Studies} 79: 933-959.

{phang}
Ludwig, J., and D. L. Miller. 2007.  Does Head Start improve
children's life chances?  Evidence from a regression discontinuity design.
{it:Quarterly Journal of Economics} 122: 159-208.


{title:Authors}

{pstd}Sebastian Calonico{break}
University of Miami{break}
Coral Gables, FL{break}
{browse "mailto:scalonico@bus.miami.edu":scalonico@bus.miami.edu}

{pstd}Matias D. Cattaneo{break}
University of Michigan{break}
Ann Arbor, MI{break}
{browse "mailto:cattaneo@umich.edu":cattaneo@umich.edu}

{pstd}Roc{c i'}o Titiunik{break}
University of Michigan{break}
Ann Arbor, MI{break}
{browse "mailto:titiunik@umich.edu":titiunik@umich.edu}


{marker also_see}{...}
{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 17, number 2: {browse "http://www.stata-journal.com/article.html?article=st0366_1":st0366_1},{break}
                    {it:Stata Journal}, volume 14, number 4: {browse "http://www.stata-journal.com/article.html?article=st0366":st0366}
{p_end}
