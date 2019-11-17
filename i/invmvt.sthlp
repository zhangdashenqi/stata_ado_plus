{smcl}
{* *! version 1.0  16 Apr 2015}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "invmvt##syntax"}{...}
{viewerjumpto "Description" "invmvt##description"}{...}
{viewerjumpto "Options" "invmvt##options"}{...}
{viewerjumpto "Remarks" "invmvt##remarks"}{...}
{viewerjumpto "Examples" "invmvt##examples"}{...}
{title:Title}
{phang}
{bf:invmvt} {hline 2} Quantiles of the Multivariate t Distribution

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:invmvt}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt p(#)}} Probability. Must be between 0 and 1.{p_end}
{synopt:{opt del:ta(numlist)}} The vector of non-centrality parameters of length k. No missing values allowed.{p_end}
{synopt:{opt s:igma(string)}} The scale matrix of dimension k. Must be symmetric positive-definite.{p_end}
{synopt:{opt t:ail(string)}} Specifies which quantile should be computed. lower gives the x such that P(X <= x) = p, upper such that P(X >= x) = p, and both such that P(-x <= X <= x) = p. Defaults to lower.{p_end}
{synopt:{opt df(#)}} The degree of freedom. Must be a strictly positive integer. Defaults to 1.{p_end}
{synopt:{opt shi:fts(#)}} The number of shifts of the Quasi-Monte Carlo integration algorithm to use. Must be a strictly positive integer. Defaults to 12.{p_end}
{synopt:{opt sam:ples(#)}} The number of samples in each shift of the Quasi-Monte Carlo integration algorithm to use. Must be a strictly positive integer. Defaults to 1000.{p_end}
{synopt:{opt alp:ha(#)}} The value of the Monte Carlo confidence factor to use. Must be strictly positive. Defaults to 3.{p_end}
{synopt:{opt it:ermax(#)}} The maximum number of iterations allowed in the interval bisection algorithm. Must be strictly positive. Defaults to 1000000.{p_end}
{synopt:{opt tol:erance(#)}} The desired tolerance in the interval bisection algorithm. Must be strictly positive. Defaults to 0.000001.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:invmvt} computes the equicoordinate quantile function of the multivariate t distribution for arbitrary scale matrices, based on inversion of mvt.

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt p(#)} Probability. Must be between 0 and 1.

{phang}
{opt del:ta(numlist)} The vector of non-centrality parameters of length k. No missing values allowed.

{phang}
{opt s:igma(string)} The scale matrix of dimension k. Must be symmetric positive-definite.

{phang}
{opt t:ail(string)} Specifies which quantile should be computed. lower gives the x such that P(X <= x) = p, upper such that P(X >= x) = p, and both such that P(-x <= X <= x) = p. Defaults to lower.

{phang}
{opt df(#)} The degree of freedom. Must be a strictly positive integer. Defaults to 1.

{phang}
{opt shi:fts(#)} The number of shifts of the Quasi-Monte Carlo integration algorithm to use. Must be a strictly positive integer. Defaults to 12.

{phang}
{opt sam:ples(#)} The number of samples in each shift of the Quasi-Monte Carlo integration algorithm to use. Must be a strictly positive integer. Defaults to 1000.

{phang}
{opt alp:ha(#)} The value of the Monte Carlo confidence factor to use. Must be strictly positive. Defaults to 3.

{phang}
{opt it:ermax(#)} The maximum number of iterations allowed in the interval bisection algorithm. Must be strictly positive. Defaults to 1000000.

{phang}
{opt tol:erance(#)} The desired tolerance in the interval bisection algorithm. Must be strictly positive. Defaults to 0.000001.

{marker examples}{...}
{title:Examples}

{phang} 
{stata mat Sigma = (1, 0.5, 0.5 \ 0.5, 1, 0.5 \ 0.5, 0.5, 1)}

{phang} 
{stata invmvt, p(0.95) delta(0, 0, 0) sigma(Sigma)}

{title:Authors}
{p}

Michael J. Grayling & Adrian P. Mander,
MRC Biostatistics Unit, Cambridge, UK.

Email {browse "mjg211@cam.ac.uk":mjg211@cam.ac.uk}

{title:See Also}

References:

Genz A, Bretz F (1999) Numerical Computation of Multivariate t-Probabilities
  with Application to Power Calculation of Multiple Contrasts. Journal of
  Statistical Computation and Simulation. 63: 361–378.
Genz A, Bretz F (2002) Methods for the Computation of Multivariate
  t-Probabilities. Journal of Computational and Graphical Statistics.
  11: 950–971.
Genz A, Bretz F (2009) Computation of Multivariate Normal and t Probabilities.
  Lecture Notes in Statistics, Vol 195. Springer-Verlag: Heidelberg, Germany.
Kotz S, Nadarajah S (2004) Multivariate t Distributions and Their
  Applications. Cambridge University Press: Cambridge, UK.
  
Related commands:

{help mvtden} (if installed)
{help mvt} (if installed)
{help rmvt} (if installed)
