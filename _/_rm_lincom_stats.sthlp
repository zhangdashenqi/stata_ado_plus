{smcl}
{* <date>}{...}
{title:_rm_lincom_stats: statistics based on lincom}

{p 4 21 2}
{hi:_rm_lincom_stats} {hline 2}
{cmd:lincom} returns only {cmd:r(se)} and {cmd:r(estimate).
{cmd:_rm_lincom_stats} creates returns with other information about the test.


{marker syntax}{...}
{title:Syntax}

{phang2}
{cmd:_rm_lincom_stats}


{marker description}{...}
{title:Description}

{pstd}
{cmd:_rm_lincom_stats} is a programmer's tool that makes it easy to use
results from {cmd:lincom}. In SPost this is being use to process the
results of {cmd:lincom} applied to estimates from {cmd:margins}.


{marker options}{...}
{title:Options}

{phang}
{opt <OPTopt>(<input>)} <optiondetails>.


{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:_rm_lincom_stats} saves in {cmd:s()}:

{p2colset 9 28 32 2}{...}
{pstd}Macros:{p_end}

{p2col :{cmd:s(level)}}Level used in the CI.{p_end}
{p2col :{cmd:s(ub)}}Upper bound of the CI.{p_end}
{p2col :{cmd:s(lb)}}Lower bound of the CI.{p_end}
{p2col :{cmd:s(p)}}P>|z| of test Ho: est=0.{p_end}
{p2col :{cmd:s(z)}}z-value of test Ho: est=0.{p_end}
{p2col :{cmd:s(se)}}Std. Err of the estimate.{p_end}
{p2col :{cmd:s(est)}}The estimated linear combination.{p_end}

{p2colreset}{...}

{title:Also see}

{pstd}
{help _rm} for other _rm programming commands.
INCLUDE help _rm_footer

