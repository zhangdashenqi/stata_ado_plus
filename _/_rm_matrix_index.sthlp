{smcl}
{* 2012-08-31 scott long}{...}
{title:Title}

{p 4 21 2}
{hi:_rm_matrix_index} {hline 2}
Select rows or columns from a matrix using index numbers for the rows/columns
wanted in the order that they are to appear in the revised matrix.


{marker syntax}{...}
{title:Syntax}

{phang2}
{cmd:_rm_matrix_index}
	{it:input-matrix}
	{it:index-vector}
	(row | col)
	[ {it:name-string} ]


{synoptset 21}{...}
{synopthdr}
{synoptline}
{synopt :{opt inpuat-matrix}}Name of matrix that is to be revised.{p_end}
{synopt :{opt index-vector}}Name of row vector where each element is
the column or row number to be select. The new matrix contains these rows
or columns in the order they appear in this vector.{p_end}
{synopt :{opt row} | {opt col} }Select based on row indices or column
indices.{p_end}
{synopt :{opt name-string}}Names for each row/column of the input
matrix that will be assigned to the revised matrix. This allows you to
change row/column names.{p_end}{synoptline}
{p2colreset}{...}
{p 4 6 2}
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd: _rm_matrix_index} is a programmer's tool that
makes selections using the index numbers of the
rows or columns to be kept in the revised matrix. The revised matrix places
the rows or columns in the order the indices are entered in the index vector.
This command differs from {cmd: _rm_matrix_select} which use a selection
vector of 0 and 1 indicating which rows or columns to select. If you want to
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

