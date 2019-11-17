{smcl}
{* *! version 1.0 16 Apr 2015}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "mvnormal##syntax"}{...}
{viewerjumpto "Description" "mvnormal##description"}{...}
{viewerjumpto "Options" "mvnormal##options"}{...}
{viewerjumpto "Remarks" "mvnormal##remarks"}{...}
{viewerjumpto "Examples" "mvnormal##examples"}{...}
{title:Title}
{phang}
{bf:mvnormal} {hline 2} Multivariate Normal Distribution

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:mvnormal}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt low:er(numlist miss)}} The vector of lower limits of length k. Use . to indicate a value is -Infinity.{p_end}
{synopt:{opt upp:er(numlist miss)}} The vector of upper limits of length k. Use . to indicate a value is +Infinity.{p_end}
{synopt:{opt me:an(numlist)}} The mean vector of length k. No missing values allowed.{p_end}
{synopt:{opt s:igma(string)}} The covariance matrix of dimension k. Must be symmetric positive-definite.{p_end}
{synopt:{opt shi:fts(#)}} The number of shifts of the Quasi-Monte Carlo integration algorithm to use. Must be a strictly positive integer. Defaults to 12.{p_end}
{synopt:{opt sam:ples(#)}} The number of samples in each shift of the Quasi-Monte Carlo integration algorithm to use. Must be a strictly positive integer. Defaults to 1000.{p_end}
{synopt:{opt alp:ha(#)}} The value of the Monte Carlo confidence factor to use. Must be strictly positive. Defaults to 3.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:mvnormal} computes the distribution function of the multivariate normal distribution for arbitrary limits, mean vectors and correlation matrices.

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt low:er(numlist miss)} The vector of lower limits of length k. Use . to indicate a value is -Infinity.

{phang}
{opt upp:er(numlist miss)} The vector of upper limits of length k. Use . to indicate a value is +Infinity.

{phang}
{opt me:an(numlist)} The mean vector of length k. No missing values allowed.

{phang}
{opt s:igma(string)} The covariance matrix of dimension k. Must be symmetric positive-definite.

{phang}
{opt shi:fts(#)} The number of shifts of the Quasi-Monte Carlo integration algorithm to use. Must be a strictly positive integer. Defaults to 12.

{phang}
{opt sam:ples(#)} The number of samples in each shift of the Quasi-Monte Carlo integration algorithm to use. Must be a strictly positive integer. Defaults to 1000.

{phang}
{opt alp:ha(#)} The value of the Monte Carlo confidence factor to use. Must be strictly positive. Defaults to 3.

{marker examples}{...}
{title:Examples}

{phang} 
{stata mat Sigma = (1, 0.5, 0.5 \ 0.5, 1, 0.5 \ 0.5, 0.5, 1)}

{phang} 
{stata mvnormal, lower(-2.06, -2.06, -2.06) upper(2.06, 2.06, 2.06) mean(0, 0, 0) sigma(Sigma)}

{title:Authors}
{p}

Michael J. Grayling & Adrian P. Mander,
MRC Biostatistics Unit, Cambridge, UK.

Email {browse "mjg211@cam.ac.uk":mjg211@cam.ac.uk}

{title:See Also}

References:

Genz A (1992) Numerical Computation of Multivariate Normal Probabilities.
  Journal of Computational and Graphical Statistics. 1: 141–150.
Genz A, Bretz F (2009) Computation of Multivariate Normal and t Probabilities.
  Lecture Notes in Statistics, Vol 195. Springer-Verlag: Heidelberg, Germany.
Tong YL (2012) The Multivariate Normal Distribution. Springer-Verlag: New York,
  US. 
  
Related commands:

{help mvnormalden} (if installed)
{help rmvnormal} (if installed)
{help invmvnormal} (if installed)
