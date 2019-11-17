{smcl}
{* <date>}{...}
{title:Title}

{p 4 21 2}
{hi:<nm>} {hline 2}
<descripton>


{marker syntax}{...}
{title:Syntax}

{phang2}
{cmd:<nm>}
	[{cmd:,}
		{it:options}
	]


{synoptset 27}{...}
{synopthdr}
{synoptline}
{synopt :{opt <OPT>:<opt>(<input>)}}{it:<input>}
	<option description>{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
<notes>
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:<nm>} is a programmer's tool that...


{marker options}{...}
{title:Options}

{phang}
{opt <OPTopt>(<input>)} <optiondetails>.


{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:<nm>} saves in {cmd:s()}:

{p2colset 9 28 32 2}{...}
{pstd}Macros:{p_end}

{p2col :{cmd:s(<return>)}}<return_desc>{p_end}

{p2colreset}{...}

{title:Also see}

{pstd}
Manual: {hi:[R] margins}
INCLUDE help _rm_footer
