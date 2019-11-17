{smcl}
{* *! version 1.0  16 Apr 2015}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "mvnormalden##syntax"}{...}
{viewerjumpto "Description" "mvnormalden##description"}{...}
{viewerjumpto "Options" "mvnormalden##options"}{...}
{viewerjumpto "Remarks" "mvnormalden##remarks"}{...}
{viewerjumpto "Examples" "mvnormalden##examples"}{...}
{title:Title}
{phang}
{bf:mvnormalden} {hline 2} Density of the Multivariate Normal Distribution

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:mvnormalden}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt x(numlist)}} The vector of quantiles of length k. No missing values allowed.{p_end}
{synopt:{opt me:an(numlist)}} The mean vector of length k. No missing values allowed.{p_end}
{synopt:{opt s:igma(string)}} The covariance matrix of dimension k. Must be symmetric positive-definite.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:mvnormalden} computes the density of the multivariate normal distribution for arbitrary quantiles, mean vectors and covariance matrices.

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt x(numlist)} The vector of quantiles of length k. No missing values allowed.

{phang}
{opt me:an(numlist)} The mean vector of length k. No missing values allowed.

{phang}
{opt s:igma(string)} The covariance matrix of dimension k. Must be symmetric positive-definite.

{marker examples}{...}
{title:Examples}

{phang} 
{stata mat Sigma = (1, 0.5, 0.5 \ 0.5, 1, 0.5 \ 0.5, 0.5, 1)}

{phang} 
{stata mvnormalden, x(0, 0, 0) mean(0, 0, 0) sigma(Sigma)}

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

{help mvnormal} (if installed)
{help rmvnormal} (if installed)
{help invmvnormal} (if installed)
