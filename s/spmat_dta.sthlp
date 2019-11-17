{smcl}
{* *! version 1.0.1  16mar2010}{...}
{cmd:help spmat dta}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{cmd:spmat dta} {hline 2}}Create an {bf:spmat} object from a
rectangular Stata dataset
{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:spmat dta} {it:objname} {it:varlist} {ifin} [{cmd:,} {it:options}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt id(varname)}}variable containing unique IDs{p_end}
{synopt:{opt idist:ance}}convert distance data to inverse distances{p_end}
{synopt:{opt norm:alize(norm)}}normalization method{p_end}
{synopt:{opt replace}}replace {it:objname}{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{opt spmat dta} creates the {cmd:spmat} object {it:objname} from a Stata dataset
containing the entries of an {it:n} x {it:n} spatial-weighting matrix.  The number
of variables in {it:varlist} should be equal to the number of observations in the dataset.


{title:Options}

{phang}
{opt id(varname)} specifies a variable containing unique place
    identifiers.  If this option is omitted, {cmd:spmat dta} will
    create the IDs {cmd:1}, ..., {it:n}.

{phang}
{opt idistance} tells {cmd:spmat} that the data are to be converted to inverse
    distances.  The value d will be converted to 1/d with the exception
    of the main diagonal, which will contain zero entries.

{phang}
{opt normalize(norm)} specifies the normalization method.
    {it:norm} can be {opt row}, {opt min:max}, or {opt spe:ctral}.

{phang}
{opt replace} allows {it:objname} to be overwritten if it already exists.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. spmat use cobj using pollute.spmat}{p_end}
{phang2}{cmd:. spmat export cobj using cobj.txt}{p_end}
{phang2}{cmd:. spmat drop cobj}{p_end}
{phang2}{cmd:. insheet using cobj.txt, delimiter(" ") clear}{p_end}
{phang2}{cmd:. rename v1 id}{p_end}

{pstd}Create the spmat object {cmd:cobj} containing a contiguity matrix
stored in the variables {cmd:v2-v542}{p_end}
{phang2}{cmd:. spmat dta cobj v*, id(id) replace}{p_end}


{title:Also see}

{psee}Online:  {helpb spmat}, {helpb spreg}, {helpb spivreg},
               {helpb spmap}, {helpb shp2dta}, {helpb mif2dta} (if installed){p_end}

