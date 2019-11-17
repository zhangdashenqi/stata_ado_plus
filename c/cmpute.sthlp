{smcl}
{* *! version 1.0.0  04sep2013}{...}
{cmd:help cmpute}{right: ({browse "http://www.stata-journal.com/article.html?article=dm0072":SJ13-4: dm0072})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:cmpute} {hline 2}}Replace or generate a variable{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 12 2}
{cmd:cmpute}
{dtype}
{c -(}{it:existing_var}|{it:newvar}{c )-} {cmd:=} {it:exp}
{ifin} [{cmd:,} {it:options}]

{synoptset 18}{...}
{synopthdr :options}
{synoptline}
{synopt :{opt force}}force change in storage type of {it:existing_var} to {it:type}{p_end}
{synopt :{opt lab:el(string)}}label new or regenerated variable{p_end}
{synopt :{opt replace}}replace existing variable{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:cmpute} replaces an existing variable, {it:existing_var}, or
creates a new variable, {it:newvar}, from an expression in {it:exp}.  An
error message occurs if an attempt is made to change {it:existing_var}
without specifying {opt replace}.  If {it:type} is specified,
{cmd:cmpute} sets the storage type of {it:existing_var} or {it:newvar}
to {it:type} (see also the {opt force} option).

{pstd}
Note that {cmd:cmpute} leaves formats, value labels, and
characteristics as they were, so a programmer wanting to alter any of
those needs to make the changes separately.

{pstd}
Although {cmd:cmpute} is envisaged primarily as a programmer's
tool, users may also find it convenient in interactive use as a shortcut
to creating and labeling a new (or existing) variable in one step.


{title:Options}

{phang}
{opt force} applies {cmd:recast} to force a change in the storage
type of an {it:existing_var} to {it:type}.  This option should be used
with caution because it could result in loss of data.  See
{helpb recast} for further information.  {opt force} has no effect on a
{it:newvar}.

{phang}
{opt label(string)} labels the new or regenerated variable
"{it:string}".

{phang}
{opt replace} replaces {it:existing_var}.  Using {cmd:cmpute}
with an existing variable but omitting {opt replace} raises an error
message.  {opt replace} has no effect on a {it:newvar}.


{title:Remarks}

{pstd}
{cmd:cmpute} is envisaged as a programming tool.  It often happens that you
wish to create a new variable or replace an existing one and that you also
have coded a {opt replace} option to allow an existing variable to be
overwritten.  {cmd:cmpute} handles the necessary coding and (critically) error
checking in a single line of code.  Doing this properly is cumbersome.  It
also supports expressions via {cmd:=}{it:exp} and supports labeling a
regenerated variable.

{pstd}
Specifying {it:type} sets or resets the storage type
({cmd:byte}|{cmd:int}|{cmd:long}|{cmd:float}|{cmd:double}|{cmd:str}{it:#}|{cmd:strL})
of the regenerated variable to {it:type}.  Storage type {cmd:strL} defines
long strings and is available only in Stata 13 or higher.  By default, the
storage type is {cmd:float} for {it:newvar} or is the existing type for
{it:existing_var}.  Specifying {it:type} for an existing variable overrides
its existing type.


{title:Examples}

{phang}
{cmd:. cmpute str6 make2 = substr(make, 1, 6), label("Truncated make")}{p_end}
{phang}
{cmd:. cmpute logx = ln(x), label("log(x)")}{p_end}
{phang}
{cmd:. cmpute int gear_ratio = int(100 * gear_ratio), force replace}{p_end}


{title:Author}

{pstd}Patrick Royston{p_end}
{pstd}Hub for Trials Methodology Research{p_end}
{pstd}MRC Clinical Trials Unit at UCL{p_end}
{pstd}London, UK{p_end}
{pstd}pr@ctu.mrc.ac.uk{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 13, number 4: {browse "http://www.stata-journal.com/article.html?article=dm0072":dm0072}

{p 7 14 2}Help:  {manhelp generate D}, {manhelp replace D}
{p_end}
