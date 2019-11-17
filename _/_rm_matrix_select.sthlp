{smcl}
{* 2012-08-31 scott long}{...}
{title:Title}

{p 4 21 2}
{hi:_rm_matrix_select} {hline 2}
Select rows or columns from a matrix using a selection vector and the
mata select() function.


{marker syntax}{...}
{title:Syntax}

{phang2}
{cmd:_rm_matrix_select}
	{it:input-matrix}
	{it:select-vector}
	(row | col)
	[ {it:name-string} ]


{synoptset 21}{...}
{synopthdr}
{synoptline}
{synopt :{opt inpuat-matrix}}Name of matrix that is to be revised.{p_end}
{synopt :{opt select-vector}}Name of row vector where each element
corresponds to a column or row in the {it:input-matrix}.
If an elment is 1, that row or column will be selected.{p_end}
{synopt :{opt row} | {opt col} }Select based on rows or columns.{p_end}
{synopt :{opt name-string}}Names for each row/column of the input
matrix that will be assigned to the revised matrix. This allows you to
change row/column names.{p_end}{synoptline}
{p2colreset}{...}
{p 4 6 2}
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd: _rm_matrix_select} is a programmer's tool that
makes selections using a selection vector that is passed to
mata's select() comand. The revised matrix keeps the rows and
columns in the same order as before selection. To change the order,
see {cmd: _rm_matrix_index} which allows a reordering of rows
or columns.
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

