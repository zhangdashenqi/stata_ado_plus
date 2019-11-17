{smcl}
{* *! version 1.0  16 Apr 2015}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "rmvnormal##syntax"}{...}
{viewerjumpto "Description" "rmvnormal##description"}{...}
{viewerjumpto "Options" "rmvnormal##options"}{...}
{viewerjumpto "Remarks" "rmvnormal##remarks"}{...}
{viewerjumpto "Examples" "rmvnormal##examples"}{...}
{title:Title}
{phang}
{bf:rmvnormal} {hline 2} Random Multivariate Normal Distribution Vectors

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:rmvnormal}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt me:an(numlist)}} The mean vector of length k. No missing values allowed.{p_end}
{synopt:{opt s:igma(string)}} The covariance matrix of dimension k. Must be symmetric positive-definite.{p_end}
{synopt:{opt n(#)}} The number of random vectors to generate. Must be a strictly positive integer. Defaults to 1.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:rmvnormal} draws n random vectors from the multivariate normal distribution for arbitrary mean vectors and covariance matrices.

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt me:an(numlist)} The mean vector of length k. No missing values allowed.

{phang}
{opt s:igma(string)} The covariance matrix of dimension k. Must be symmetric positive-definite.

{phang}
{opt n(#)} The number of random vectors to generate. Must be a strictly positive integer. Defaults to 1.

{marker examples}{...}
{title:Examples}

{phang} 
{stata mat Sigma = (1, 0.5, 0.5 \ 0.5, 1, 0.5 \ 0.5, 0.5, 1)}

{phang} 
{stata rmvnormal, mean(0, 0, 0) sigma(Sigma) n(10)}

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
{help mvnormal} (if installed)
{help invmvnormal} (if installed)
