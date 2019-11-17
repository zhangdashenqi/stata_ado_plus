{smcl}
{* *! version 1.0  3 Jul 2012}{...}
{viewerjumpto "Syntax" "examplehelpfile##syntax"}{...}
{viewerjumpto "Description" "examplehelpfile##description"}{...}
{viewerjumpto "Options" "examplehelpfile##options"}{...}
{viewerjumpto "Remarks" "examplehelpfile##remarks"}{...}
{viewerjumpto "Examples" "examplehelpfile##examples"}{...}
{title:Title}
{phang}
{bf:makehlp} {hline 2} Automatically create a help file

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:makehlp}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt f:ile(string)}} specifies the adofile excluding the .ado extension.{p_end}
{synopt:{opt r:eplace}} specifies that the old help file is replaced.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:makehlp} creates help files automatically from a Stata ado file. This should save developers some time as
the helpfiles are not exactly WYSIWYG.

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt f:ile(string)} specifies the adofile excluding the .ado extension.

{phang}
{opt r:eplace} specifies that the old help file is replaced.


{marker examples}{...}
{title:Examples}

{phang} {cmd: makehlp, file(makehlp) replace}

{title:Author}
{p}
{p_end}
{pstd}
Adrian Mander, MRC Biostatistics Unit, Cambridge, UK.

{pstd}
Email {browse "mailto:adrian.mander@mrc-bsu.cam.ac.uk":adrian.mander@mrc-bsu.cam.ac.uk}
