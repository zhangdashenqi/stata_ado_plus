{smcl}
{* 2012-08-31 jsl}{...}
{cmd:help _rm}: SPost _rm utility commands
{hline}
{p2colset 4 27 27 2}{...}

{title:_rm commands}

{p2col:{help _rm_fvtype}}Determine how variable is used in a model;
what type of factor variable?{p_end}

{p2col:{help _rm_lincom_stats}}Return statistics computed
by {cmd:lincom}.{p_end}

{p2col:{help _rm_matrix_index}}Select rows or columns of a matrix
based on row or column indices.{p_end}

{p2col:{help _rm_matrix_nomiss}}Select rows or columns of a matrix
that do not have all missing values.{p_end}

{p2col:{help _rm_matrix_noomitted}}Remove rows or columns of
a matrix that are flagged as omitted because of collinearity.{p_end}

{p2col:{help _rm_matrix_rclist}}Create a selection vector or a
vector of indices based on the names of the rows or columns
in a matrix and the names or a numlist of what is to be selected.{p_end}

{p2col:{help _rm_matrix_select}}Select rows or columns of a matrx
using a selection vector.{p_end}

{p2col:{help _rm_modelinfo}}Return information about the estimation
command in memory.{p_end}

{p2col:{help _rm_parse_AeqB}}Parse a list of the type:
A=B C D E=F and return parallel lists.{p_end}

{p2col:{help _rm_rhsnames}}Return the names of rhs variables from
the estimation command in memory.{p_end}

INCLUDE help _rm_footer
