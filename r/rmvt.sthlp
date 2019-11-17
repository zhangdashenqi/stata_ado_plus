{smcl}
{* *! version 1.0  16 Apr 2015}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "rmvt##syntax"}{...}
{viewerjumpto "Description" "rmvt##description"}{...}
{viewerjumpto "Options" "rmvt##options"}{...}
{viewerjumpto "Remarks" "rmvt##remarks"}{...}
{viewerjumpto "Examples" "rmvt##examples"}{...}
{title:Title}
{phang}
{bf:rmvt} {hline 2} Random Multivariate t Distribution Vectors

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:rmvt}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt n(#)}} The number of random vectors to generate. Must be a strictly positive integer. Defaults to 1.{p_end}
{synopt:{opt del:ta(numlist)}} The vector of non-centrality parameters of length k. No missing values allowed.{p_end}
{synopt:{opt s:igma(string)}} The scale matrix of dimension k. Must be symmetric positive-definite.{p_end}
{synopt:{opt df(#)}} The degree of freedom. Must be a strictly positive integer. Defaults to 1.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:rmvt} draws n random vectors from the multivariate t distribution for arbitrary scale matrices.

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt del:ta(numlist)} The vector of non-centrality parameters of length k. No missing values allowed.

{phang}
{opt s:igma(string)} The scale matrix of dimension k. Must be symmetric positive-definite.

{phang}
{opt df(#)} The degree of freedom. Must be a strictly positive integer. Defaults to 1.

{phang}
{opt n(#)} The number of random vectors to generate. Must be a strictly positive integer. Defaults to 1.

{marker examples}{...}
{title:Examples}

{phang} 
{stata mat Sigma = (1, 0.5, 0.5 \ 0.5, 1, 0.5 \ 0.5, 0.5, 1)}

{phang} 
{stata rmvt, delta(0, 0, 0) sigma(Sigma) n(10)}

{title:Authors}
{p}

Michael J. Grayling & Adrian P. Mander,
MRC Biostatistics Unit, Cambridge, UK.

Email {browse "mjg211@cam.ac.uk":mjg211@cam.ac.uk}

{title:See Also}

References:

Kotz S, Nadarajah S (2004) Multivariate t Distributions and Their
  Applications. Cambridge University Press: Cambridge, UK.

Related commands:

{help mvtden} (if installed)
{help mvt} (if installed)
{help invmvt} (if installed)
