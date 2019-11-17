{smcl}
{* *! version 2012-08-31 scott long}{...}
{title:Title}

{p 4 21 2}
{hi:_rm_rhsnames} {hline 2}
Returns information about the variables on the right-hand-side of the
estimation command in memory. This is used by {cmd:_rm_modelinfo}.


{marker syntax}{...}
{title:Syntax}

{phang2}
{cmd:_rm_rhsnames}
        rhsnames
        rhsnvars
       [ rhs2names
        rhs2nvars ]


{synoptset 27}{...}
{synopthdr}
{synoptline}
{synopt :{opt rhsnames}}Name of a local that will recieved the names
of the rhs variables in equation 1.{p_end}
{synopt :{opt rhsnvars}}Name of a local that will recieved the the number
of rhs variables in equation 1.{p_end}
{synopt :{opt rhs2names}}Name of a local that will recieved the names
of the rhs variables in equation 2.{p_end}
{synopt :{opt rhs2nvars}}Name of a local that will recieved the the number
of rhs variables in equation 2.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:_rm_fvtype} is a programmer's tool that returns the names and number
of right-hand-side variables in the model with e-returns in memory.
{cmd:_rm_modelinfo} can used to obtain even more information.

{p2colreset}{...}

{title:Also see}

{pstd}
{help _rm} for other _rm programming commands.
INCLUDE help _rm_footer
