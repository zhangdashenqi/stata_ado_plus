{smcl}
{* *! version 1.1.1  14jun2009}{...}
{cmd:help xtileJ}
{hline}

{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{manlink D xtileJ} {hline 2}}Computes a variable that contains quantiles. 
{p_end}
{p2colreset}{...}


{title:Syntax}

{phang}
Create variable containing quantile categories

{p 8 15 2}
{cmd:xtileJ}
{it:newvar} {cmd:=} {it:{help exp}}
{ifin}
{weight}
[{cmd:,} {it: by(varlist)} {it:{help pctile##xtile_options:xtile_options}}]


{synoptset 22 tabbed}{...}
{marker xtile_options}{...}
{synopthdr :xtile_options}
{synoptline}
{synopt :{opt n:quantiles(#)}}number of quantiles; default is
{cmd:nquantiles(2)}{p_end}
{synoptline}


{p 4 6 2}
{opt aweight}s, {opt fweight}s, and {opt pweight}s are allowed
(see {manhelp weight U:11.1.6 weight}), except when
the {opt altdef} option is specified, in which case no weights are allowed.
{p_end}


{title:Description}

{p 4 6 2}
{opt xtile}  is similar to STATA's {help xtile} command except 
that xtileJ allows 'by' groups. 
This program runs much more quickly than the {help xtile2} (if installed) 
command that allows 'by' groups. 


{title:Also see}

{psee}
Manual:  {manlink D xtile}


