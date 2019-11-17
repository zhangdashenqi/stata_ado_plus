{smcl}
{* 2012-08-31 scott long}{...}
{title:Title}

{p 4 21 2}
{hi:_rm_matrix_noomitted} {hline 2}
Remove rows or columns of
a matrix that are flagged as omitted because of collinearity.


{marker syntax}{...}
{title:Syntax}

{phang2}
{cmd:_rm_matrix_noomitted}
	{it:input-matrix}
	(row | col)
	[ {it:name-string} ]


{synoptset 21}{...}
{synopthdr}
{synoptline}
{synopt :{opt inpuat-matrix}}Name of matrix that is to be revised.{p_end}
{synopt :{opt row} | {opt col} }Select based on omitted variables in the rows or the
columns of the input matrix.{p_end}
{synopt :{opt name-string}}Names for each row/column of the input
matrix that will be assigned to the revised matrix. This allows you to
change row/column names.{p_end}{synoptline}
{p2colreset}{...}
{p 4 6 2}
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd: _rm_matrix_noomitted} is a programmer's tool that
extracts the rows/columns of a matrix that do not contain information
on omitted variables. This is useful when extracting information from
{cmd:e(b)} or {cmd:e(V)}.
If you want to
select both rows and columns, run the command twice, once with the row option,
then with the col option.


{marker saved_results}{...}
{title:Saved results}

{pstd}
The changed matrix is returned to with the same name. If you want the
to preserve the matrix before the selection, you must save another copy
of the matrix before running this command.

{p2colreset}{...}

{title:Also see}

{pstd}
{help _rm} for other _rm programming commands.
INCLUDE help _rm_footer

