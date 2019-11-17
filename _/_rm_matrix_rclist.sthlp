{smcl}
{* 2012-08-31}{...}
{title:Title}

{p 4 21 2}
{hi:_rm_matrix_rclist} {hline 2}
evaluates a list of names or a {help numlist} to create a selection
vector and a list of names that can be used
to extract information from a matrix.


{marker syntax}{...}
{title:Syntax}

{phang2}
{cmd:_rm_matrix_rclist}
	{cmd:,}
		{it:options}
	[
		{it:options}
	]


{synoptset 22}{...}
{synopthdr}
{synoptline}
{syntab:Required}

{synopt :{opt rcnames(matrix-names)}}is a string with
the names of the rows or columns from the matrix where you want to
select elements.
{p_end}
{synopt :{opt rclist(names|numlist)}}{it:names} is a string with
names corresponding to row or column names in the matrix where you want to
make a select. If {it:numlist} is used, you can specify the row or column
numbers that you want to select.
{p_end}

{syntab:Optional}

{synopt :{opt rclabels(labels)}}A string with
labels that will be assigned to the names or numbers in {cmd:rclist()}.
{p_end}
{synopt :{opt quietly}}Suppress display of error message.
{cmd:r(error)} is returned.{p_end}
{synopt :{opt unab}}Unabbreviate the names in {it:rc-list} using
{cmd:fvexpand}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:_rm_matrix_rclist} is a programmer's tool for evaluating a list to
select rows or columns from a matrix. You provide the row or column names
from the matrix and either a numerical list of rows/columns or names of the
rows/columns. The command returns a selection vecto of which rows/columns
of the matrix you want to select; this can be used by {cmd:_rm_matrix_select}.
It also provides a vector of indices for the selected rows and columns that
can be used by {cmd:_rm_matrix_index}. A local with the names of the
selected columns is also returned. Optionally you can provide a string
of labels that will replace the row/column labels currently in the matrix;
this allows you to easily assign more useful labels.


{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:_rm_matrix_rclist} saves in {cmd:s()}:

{p2colset 9 28 32 2}{...}
{pstd}Macros:{p_end}

{p2col :{cmd:s(error)}}1 indicates error decoding list.{p_end}
{p2col :{cmd:s(isnumlist)}}1 if selection made using numlist.{p_end}
{p2col :{cmd:s(newnames)}}Names for the selected elements.{p_end}

{pstd}Matrices:{p_end}

{p2col :{cmd:s(selectmat)}}A row vector with one column for each
name in {it:rcnames}. A 1 indicates that element was selected; a
0 that it was not.{p_end}
{p2col :{cmd:s(indexmat)}}A row vector with one column for each
element of {it:rcnames} that was selected.{p_end}

{p2colreset}{...}

{title:Also see}

{pstd}
{help _rm} for other _rm programming commands.
INCLUDE help _rm_footer
