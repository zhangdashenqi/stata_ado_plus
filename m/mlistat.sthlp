{smcl}
{* 2014-09-02 jeremy freese & scott long}{...}
{title:Title}

{p2colset 5 16 23 2}{...}
{p2col:{cmd:mlistat} {hline 2}}List r(at) matrix computed by {cmd:margins}{p_end}
{p2colreset}{...}


{title:General syntax}

{p 4 8 2}
{cmd:mlistat} [{it:your_matrix}]{cmd:,}
[
{opt at:vars(select_at_variables)}
{opt nos:plit}
{opt noc:onstant}
{opt nov:ary}
{opt savec:onstant(matname)}
{opt savev:arying(matname)}
{opt allbase:levels}
{opt fv:expand}
{opt qui:etly}
{opt roweq:nm(row_eq_name_to_add)}
{opt dec:imals(decimal_digits)}
{opt width(column_width)}
]

{marker overview}
{title:Overview}

{pstd}
Following the {cmd:margins} command, the {bf:r(at)} matrix
holds the values of the predictors
at which predictions are computed.
{cmd:mlistat} presents constant and varying values separately for greater clarity, and allows you to list values for selections of variables.


{title:Options}
{p2colset 5 26 27 0}
{p2col:{opt at:vars(varlist)}}
list only the at variables specified. For example,
{cmd:atvars(k5 wc)} or {cmd:atvars(1(1)3)}.
{p_end}

{synopt:{opt nos:plit}} do not divide output into constant and varying {bf:at()} values.
{p_end}

{synopt:{opt noc:onstant}} do not print {bf:at()} values that are constant.
{p_end}

{synopt:{opt nov:ary}} do not print {bf:at()} values that vary.
{p_end}

{synopt:{opt savec:onstant(matname)}} save constant {bf:at()} values as matrix {it:matname}.
{p_end}

{synopt:{opt savev:arying(matname)}} save varying {bf:at()} values as matrix {it:matname}.
{p_end}

{synopt:{opt allbaselevels}} print column values for base levels and other omitted variables.
{p_end}

{synopt:{opt fv:expand}} print factor variables as set of indicator variables.
{p_end}

{synopt:{opt qui:etly}} results are not printed.
{p_end}

{synopt:{opt coleq:nm(colstub)}}
add the equation name {it:colstub} to the columns in the matrix where
the results are saved.
For example, {cmd:coleqstub("Model 1")} adds add "Model 1" above
columns with the results.
{p_end}

{synopt:{opt roweq:nm(rowstub)}} add the equation name {it:rowstub} to the rows where results are saved.
{p_end}

{synopt:{opt dec:imal(numlist)}} set the number of decimal digits
for each column when listing the matrix.
Columns can have different numbers of decimal digits.
For example, {cmd:mlistat, decimal(3 2 2)}.
{p_end}

{synopt:{opt width(number)}} specify the width of the columns.
{p_end}

{marker examples}{...}
{title:Examples}

{pstd}
{ul:{bf:Using mlistat after margins}}{p_end}

{phang2}{cmd:. spex logit}{p_end}
{phang2}{cmd:. margins, at(wc=(0 1) hc=(0 1) lwg=3 inc=50)}{p_end}
{phang2}{cmd:. mlistat}{p_end}
{phang2}{cmd:. mlistat, noconstant }{p_end}
{phang2}{cmd:. mlistat, atvar(1.wc) }{p_end}

INCLUDE help spost13_footer
