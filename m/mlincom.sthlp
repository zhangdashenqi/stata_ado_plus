{smcl}
{* 2015-01-09 scott long & jeremy freese}{...}
{title:Title}

{p2colset 5 16 17 2}{...}
{p2col:{cmd:mlincom} {hline 2}}Computing linear combinations of {cmd:margins} estimates{p_end}
{p2colreset}{...}


{title:General syntax}

{p 6 18 2}
{cmd:mlincom} {it:exp} [ {cmd:,} {it:options} ]
{p_end}

{p 4 4 2}
{it:exp} is the expression for a linear combination of estimates
from the last {cmd:margins, post} command or {cmd:mtable, post}.
Estimates are referred
to by number (1 for 1st, 2 for 2nd, et.). Valid expressions
include {cmd:1-2} and {cmd:(1-2)-(3-4)}.
If no {it:linear_combination} is specified, the results from the last
{cmd:mlincom} are listed.
{p_end}


{title:Overview}

{pstd}
{cmd:mlincom} uses {cmd:lincom} to compute linear combinations of estimates
from {cmd:margins, post}. This lets you estimates discrete changes,
second differences, and other linear combinations.
Results can be accumlated from multiple {cmd:mlincom} commands.
Computing a second difference is as simple as
{cmd:mlincom (1-2)-(3-4)} which computes the difference betweeen the first
and second estimate from {cmd:margins}, the difference between the third and
fourth, and then the difference between these differences.
{p_end}

{pstd}
{cmd:mlincom} must be run when the results from {cmd:margins} were placed
in memory with the {cmd:post} option.
{p_end}


{title:Table of contents}

    {help mlincom##stats:Which statistics to display}
    {help mlincom##show:Controlling how results are displayed}
    {help mlincom##table:Adding results to prior results}
    {help mlincom##matrices:Matrices created}
    {help mlincom##examples:Examples}


{title:Options}
{marker stats}
{dlgtab:Statistics to include in the table}
{p2colset 8 25 25 0}
{synopt:{opt stat:istics(list)}}select statistics to
display. The following statistics can be included
in {it:list}.
{p_end}

{p2colset 10 23 22 12}{...}
{p2col :Name}Description{p_end}
{p2line}
{p2col :{ul:{bf:e}}{bf:stimate}}Estimated linear combination{p_end}
{p2col :{ul:{bf:l}}{bf:l}}Lower level bound of confidence interval{p_end}
{p2col :{ul:{bf:u}}{bf:l}}Upper level bound of confidence interval{p_end}
{p2col :{ul:{bf:p}}{bf:value}}p-value for test estimate is 0{p_end}
{p2col :{ul:{bf:s}}{bf:e}}Standard error of estimate{p_end}
{p2col :{bf:z}}z-value{p_end}
{p2col :{bf:noci}}Only display estimate{p_end}
{p2col :{bf:all}}Display all statistics{p_end}

{p2line}

{marker show}
{dlgtab:Controlling what is displayed}
{p2colset 8 24 25 0}
{synopt:{opt rown:ame(string)}}Label for row of table. By default rows
are numbered.

{synopt:{opt roweq:nm(string)}}Add row equation name to table. See {help matrix rownames}

{synopt:{opt twid:th(#)}}Width of the columns in table.

{synopt:{opt d:etail}}Show output from {cmd:lincom} in addition to table.

{synopt:{opt notab:le}}Show only {cmd:lincom} output.

{synopt:{opt wid:th(#)}}Width of the columns in table.

{synopt:{opt dec:imal(#)}}Decimal digits displayed in table.

{synopt:{opt estn:ame(string)}}Column name labeling estimates in table.

{synopt:{opt title(string)}}Display {it:string} above table.

{marker table}
{dlgtab:Add results to the table}

{p 7 7 2}
Results from {cmd:mlincom} are save to the matrix _mlincom. You can
add new rows to an existing matrix _mlincom to create a table combining
results from multiple uses of {cmd:mlincom}.

{p2colset 8 15 15 0}
{synopt:{opt add}}Add current results to those saved from an earlier.
All of the {cmd:mlincom} commands must include the same statistics from {opt stat()}.

{synopt:{opt clear}}Clear results saved from prior {cmd:mlincom}.

{marker matrices}
{dlgtab:Matrices used by mlincom}

{p 7 7 2}
{cmd:mlincom} saves the current table to the matrix {opt _mlincom}, adding
them to what is in the matrix if option {cmd:add} is used. The matrix
has columns corresponding to the displayed results. In addition, the
matrix {opt _mlincom_allstats} contains all statistics, not just those in
the table.


{marker examples}{...}
{dlgtab:Examples}


{pstd}{ul:{bf:Example 1: Test discrete change for wc when k5 = 0}}{p_end}

{phang2}{cmd:. sysuse binlfp2,clear}{p_end}
{phang2}{cmd:. logit lfp k5 k618 age wc hc lwg inc, nolog}{p_end}
{phang2}{cmd:. estimates store blm}{p_end}
{phang2}{cmd:. margins, at(k5=(0) wc=(0 1)) atmeans post}{p_end}
{phang2}{cmd:. mlincom 2-1, rown(DCwc_k5is0)}{p_end}
{phang2}{cmd:. estimate restore blm}{p_end}

{pstd}{ul:{bf:Example 2: Loop through tests of DC as values of k5 change}}{p_end}

{phang2}{cmd:mlincom, clear // remove any prior results}{p_end}
{phang2}{cmd:foreach k in 0 1 2 3 } { {p_end}
{phang3}{cmd:  local i = `k' + 1}{p_end}
{phang3}{cmd:  qui estimate restore blm}{p_end}
{phang3}{cmd:  qui margins, at(k5=(`k') wc=(0 1)) atmeans post}{p_end}
{phang3}{cmd:  qui mlincom 2-1, add rowname(DCwc_k5is`k')}{p_end}
{phang3}{cmd:}}{p_end}
{phang2}{cmd:mlincom}{p_end}
{phang2}{cmd:estimate restore blm}{p_end}

{pstd}{ul:{bf:Example 3: Second difference at means and average of difference}}{p_end}

{phang2}{cmd:. estimate restore blm}{p_end}
{phang2}{cmd:. margins, at(wc=1 hc=1) at(wc=0 hc=1) at(wc=1 hc=0) at(wc=0 hc=0) atmeans post}{p_end}
{phang2}{cmd:. mlincom (1-2)-(3-4), clear rowname(atmeans) stats(est p ll ul)}{p_end}
{phang2}{cmd:. estimate restore blm}{p_end}
{phang2}{cmd:. margins, at(wc=1 hc=1) at(wc=0 hc=1) at(wc=1 hc=0) at(wc=0 hc=0) post}{p_end}
{phang2}{cmd:. mlincom (1-2)-(3-4), add rowname(average) stats(est p ll ul)}{p_end}

{pstd}{ul:{bf:Example 4: Access matrix of mlincom}}{p_end}

{phang2}{cmd:. estimate restore blm}{p_end}
{phang2}{cmd:. margins, at(wc=1 hc=1) at(wc=0 hc=1) at(wc=1 hc=0) at(wc=0 hc=0) atmeans post}{p_end}
{phang2}{cmd:. mlincom 2-1, clear stats(all)}{p_end}
{phang2}{cmd:. mlincom 4-3, stats(all) add}{p_end}
{phang2}{cmd:. matrix list _mlincom}{p_end}

INCLUDE help spost13_footer
