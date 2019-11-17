{smcl}
{* scott long}{...}
{title:Put e-returns into a matrix | 2013-07-26}

{p 8 18 2}
{cmd:matereg} {it:matrixout} {it:rowout colout} [{cmd:=}] {it:ereturn-name} [ {it:rowin colin} ]

{pstd}
Row/column in {it:matrixout} are specified as: {it:#} | {opt n:ext} | {opt l:ast},
where last is the last row/column in the matrix and next adds a row/column.

{pstd}{it:ereturn-name} can be a scalar, numerical local, or matrix e-return. If it is
a matrix, the row/column are specified as {it:#} | {opt l:ast}.

where last is the last row/column in the matrix and next adds a row/column.

{title:Examples}

{pstd}To xxxx:{p_end}

{phang2}{cmd:. }
{p_end}

{title:Author}

{p 2 5 10}
Scott Long

{p 2 8 0}
{browse "http://www.indiana.edu/~jslsoc/spost.htm":The SPost website.}
{browse "http://www.indiana.edu/~jslsoc/web_workflow/wf_home.htm":The Workflow website.}
{p_end}
