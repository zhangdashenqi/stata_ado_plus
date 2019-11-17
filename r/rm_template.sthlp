{smcl}
{* 15Jan2013 scott long}{...}
{hi:help <nm>}{right:also see: {helpb xx}, {helpb xx}, {helpb xx}}
{hline}

{title:<t>}

{p2colset 5 16 24 2}{...}
{p2col:{cmd:<nm>} {hline 2}}Collecting statistical results | 08June2012{p_end}
{p2colreset}{...}

{marker overview}
{title:Overview}

{pstd}
{cmd:<nm>} ...
The command {help xx:xx} lets you

{pstd}
For more information and examples, see {browse "http://www.indiana.edu/~jslsoc/":SPost Website}.


{title:General syntax}

{p 4 18 2}
{cmd:<nm> }[{it:zz}]{cmd:,} {it:options} [ {it:options} ]
{p_end}

{p 8 10 2}
where {it:zz} is... If no name is specified, {bf:<nm>} is used.
{p_end}


{title:Table of contents}

    {help <nm>##Place1:1. Place1}
    {help <nm>##Place2:2. Place2}


{title:Options}
{marker Place1}
{dlgtab:Place1}
{pstd}

{pstd}
Place description..
{p_end}

{pstd}
{ul:Underline sub1}
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt aa:aaa(opt)}}
Option aa is...

{synopt:{opt bb:bbb(opt)}}
Option bb is...
{p_end}

{p 5 5 2}
{ul:Underline sub2}
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt aa:aaa(opt)}}
Option aa is...

{synopt:{opt bb:bbb(opt)}}
Option bb is...
{p_end}

{marker Place2}
{dlgtab:Place2}
{pstd}

{pstd}
Place description..
{p_end}

{pstd}
{ul:Underline sub1}
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt aa:aaa(opt)}}
Option aa is...

{synopt:{opt bb:bbb(opt)}}
Option bb is...
{p_end}

{p 5 5 2}
{ul:Underline sub2}
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt aa:aaa(opt)}}
Option aa is...

{synopt:{opt bb:bbb(opt)}}
Option bb is...
{p_end}


{p 6 6 2}
Table...
{p_end}

{p2colset 10 23 22 12}{...}
{p2col :{marker stats}statistics}Description{p_end}
{p2line}
{p2col :{bf:b}}Estimates{p_end}
{p2col :{bf:est}}Same as {bf:b}{p_end}
{p2col :{bf:estimate}}Same as {bf:b}{p_end}
{p2col :{bf:expb}}Exponential of {bf:b}{p_end}
{p2col :{bf:or}}Odds ratio; same as {bf:expb}{p_end}
{p2col :{bf:orpct}}Percentage change in the odds: 100*({bf:expb}-1){p_end}
{p2col :{bf:lb}}Lower bound of confidence interval{p_end}
{p2col :{bf:ub}}Upper bound of confidence interval{p_end}
{p2col :{bf:p}}p-value{p_end}
{p2col :{bf:se}}Standard error{p_end}
{p2col :{bf:t}}t-value{p_end}
{p2col :{bf:z}}z-value{p_end}
{p2col :{bf:level}}Level used for confidence interval{p_end}
{p2line}

{p 5 5 2}
{ul:Underline sub3}
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt aa:aaa(opt)}}
Option aa is...

{synopt:{opt bb:bbb(opt)}}
Option bb is...
{p_end}

{p 6 6 2}
Commands such as {cmd:mlogit} lead to results...
{p_end}

{space 5} . <nm>, ebreturn(b) list decimal(2) clear
{space 5}
{space 5}              |         b
{space 5} -------------+-----------
{space 5} Menial       |
{space 5}        white |     -0.36
{space 5}           ed |     -0.04
{space 5}        _cons |     -0.24
{space 5} -------------+-----------
{space 5} BlueCol      |
{space 5}        white |      0.84
{space 5}           ed |     -0.15
{space 5}        _cons |      0.75
{space 5}


{marker utility}
{dlgtab:Utility options}
{pstd}

{synopt:{opt blank}} Add a blank row to {it: collect_matrix}.{p_end}

{synopt:{opt clear}} Remove {it:collect_matrix} from memory
before saving results.
For example, to create a new matrix you could use
{cmd:<nm> mymat, eb(b) clear}.
If {bf:mymat} is a matrix in memory, it is removed before creating
a new {bf:mymat}.
{p_end}

{synopt:{opt colstub(stub)}} Add {it:stub} to the front
of all column names. This is useful if you are saving the same type
of information from multiple sources.
For example, {cmd:colstub(M1)} puts M1 in front of the names of
the new columns.
{p_end}

{synopt:{opt rowstub(stub)}} Add the prefix {it:stub} to the front
of all row names.
{p_end}

{synopt:{opt level(number)}} Set the significance level used when calculating
upper and lower bounds. Must be between 10 and 99.999.
{p_end}

{synopt:{opt mv(. | .a | .b |...)}} Select the type of missing values to
using in blank cells of {it: matrix_name}.
When adding information to {it: matrix_name}, cells that do not have a
value assigned will contain missing values.
By default .z is used which displays as a blank space.
You can fill empty cells with other types of missing values.{p_end}


{title:Development work}
{marker todo}
{dlgtab:Things to do, test or debug}

{pstd}
1.
{p_end}


{title:Also see}

{pstd}
Manual: {hi:[G] graph} {hi:[R] matrix}


INCLUDE help spost13_footer
