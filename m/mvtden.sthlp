{smcl}
{* *! version 1.0  16 Apr 2015}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "mvtden##syntax"}{...}
{viewerjumpto "Description" "mvtden##description"}{...}
{viewerjumpto "Options" "mvtden##options"}{...}
{viewerjumpto "Remarks" "mvtden##remarks"}{...}
{viewerjumpto "Examples" "mvtden##examples"}{...}
{title:Title}
{phang}
{bf:mvtden} {hline 2} Density of the Multivariate t Distribution

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:mvtden}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt x(numlist)}} The vector of quantiles of length k. No missing values allowed.{p_end}
{synopt:{opt del:ta(numlist)}} The vector of non-centrality parameters of length k. No missing values allowed.{p_end}
{synopt:{opt s:igma(string)}} The scale matrix of dimension k. Must be symmetric positive-definite.{p_end}
{synopt:{opt df(#)}} The degree of freedom. Must be a strictly positive integer. Defaults to 1.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:mvtden} computes the density of the multivariate t distribution for arbitrary quantiles and scale matrices.

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt x(numlist)} The vector of quantiles of length k. No missing values allowed.

{phang}
{opt del:ta(numlist)} The vector of non-centrality parameters of length k. No missing values allowed.

{phang}
{opt s:igma(string)} The scale matrix of dimension k. Must be symmetric positive-definite.

{phang}
{opt df(#)} The degree of freedom. Must be a strictly positive integer. Defaults to 1.

{marker examples}{...}
{title:Examples}

{phang} 
{stata mat Sigma = (1, 0.5, 0.5 \ 0.5, 1, 0.5 \ 0.5, 0.5, 1)}

{phang} 
{stata mvtden, x(0, 0, 0) delta(0, 0, 0) sigma(Sigma)}

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

{help mvt} (if installed)
{help rmvt} (if installed)
{help invmvt} (if installed)
