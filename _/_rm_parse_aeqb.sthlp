{smcl}
{* <date>}{...}
{title:Title}

{p 4 21 2}
{hi:_rm_parse_AeqB} {hline 2}
parses a list of the form A=B B=C D E F and returns list for the left
element and the right element where it is assume if a single element
is in the list that it imples D=D


{marker syntax}{...}
{title:Syntax}

{phang2}
{cmd:_rm_parse_AeqB}
	{cmd:,}
		{it:options}
	[
		{it:options}
	]


{synoptset 27}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opt list(ab-list)}}{it:ab-list}is a string with information
of the form a=b c repeated as often as needed. Where the
left element is called the label elmement and the right the source element.
{p_end}

{syntab:Optional}

{synopt :{opt sourcenames(names-for-right)}}{it:names-for-right} are
the names to assign to the elements on the right.{p_end}
{synopt :{opt labelnames(names-for-left)}}{it:names-for-left} are
the names to assign to the elements on the left; these are the newly
labeled elements, such as PrY_1=b labels b as PrY_1.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
<notes>
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:_rm_parse_AeqB} is a programmer's tool that parses a A=B list.

    local list "a=1 b=2 3 4 c=99"
    local srcok "1 2 3"
    di "valid source names: `srcok'"

    local lblok "a b d"
    di "valid labels:       `lblok'"

    di "list is: `list'"
    di "NOTE: labels: 1 2 3 4 are ok; 5   not"
    di "NOTE: source: 1 2 3   are ok; 4 5 not"

    _rm_parse_AeqB, list(`list') sourcenames(`srcok') labelnames(`lblok')

    di "`s(label_names)'      name to use as label"
    di "`s(source_names)'     name to use as source"
    di "`s(label_valid)'      string of 1 0's for valid and not"
    di "`s(source_valid)'     string of 1 0's for valid and not"
    di "`s(error)'            0 ok; 1 unbalanced; 2 invalid label"


{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:_rm_parse_AeqB} saves in {cmd:s()}:

{p2colset 9 28 32 2}{...}
{pstd}Macros:{p_end}

{p2col :{cmd:s(label_names)}}Parsed labels for left of equal sign.{p_end}
{p2col :{cmd:s(source_names)}}Parsed names for right of equal sign.{p_end}
{p2col :{cmd:s(label_valid)}}If list of valid labels is given, this returns
    a string of 1 and 0 with 1 indicting a valid name.{p_end}
{p2col :{cmd:s(source_valid)}}If list of valid source  names
    is given, this returns
    a string of 1 and 0 with 1 indicting a valid name.{p_end}
{p2col :{cmd:s(error)}}1 if the A=B list is invalid.{p_end}
{p2colreset}{...}


{title:Also see}

{pstd}
{help _rm} for other _rm programming commands.
INCLUDE help _rm_footer
