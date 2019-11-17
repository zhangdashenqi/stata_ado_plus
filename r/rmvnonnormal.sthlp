{smcl}
{* *! version 1.2.1  07mar2013}{...}
{cmd:help rmvnonnormal}{right: ({browse "http://www.stata-journal.com/article.html?article=st0371":SJ15-1: st0371})}
{hline}

{title:Title}

{p2colset 5 21 23 2}{...}
{p2col :{hi:rmvnonnormal} {hline 2}}Generate multivariate nonnormal
random numbers{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 11 2}
{cmdab:rmvnonnormal}{cmd:,} {cmd:n(}{it:#}{cmd:)} {cmdab:skew:ness(}{it:vectorname}{cmd:)} {cmdab:kurt:osis(}{it:vectorname}{cmd:)} {cmdab:corr:elation(}{it:matname}{cmd:)} 


{marker description}{...}
{title:Description}

{pstd}
{cmd:rmvnonnormal} generates multivariate nonnormal random numbers with
specified skewness, kurtosis, and correlation matrix by implementing the
power method proposed by Vale and Maurelli (1983).


{marker options}{...}
{title:Options}

{phang}{cmd:n(}{it:#}{cmd:)} specifies the sample size of multivariate
nonnormal random numbers. {cmd:n()} is required.{p_end}

{phang}{cmd:skewness(}{it:vectorname}{cmd:)} specifies the vector with
skewness of each random variable in multivariate nonnormal random
variables, where k is the dimension of the vector {it:vectorname}.
{cmd:skewness()} is required.{p_end}

{phang}{cmd:kurtosis(}{it:vectorname}{cmd:)} specifies the vector with
kurtosis of each random variable in multivariate nonnormal random
variables, where k is the dimension of the vector {it:vectorname}.
{cmd:kurtosis()} is required.{p_end}

{phang}{cmd:correlation(}{it:matname}{cmd:)} specifies the matrix of
intercorrelations among multivariate nonnormal random variables, where k
is the number of rows and columns of the matrix {it:matname}.
{cmd:correlation()} is required.{p_end}


{marker example}{...}
{title:Example}

{phang}{cmd:. set seed 735}{p_end}
{phang}{cmd:. matrix C = (1,0.3\0.3,1)}{p_end}
{phang}{cmd:. matrix S = (1.5,2)}{p_end}
{phang}{cmd:. matrix K = (3.5,4)}{p_end}
{phang}{cmd:. rmvnonnormal, n(1000) skewness(S) kurtosis(K) correlation(C)}{p_end}
{phang}{cmd:. return list}{p_end}

{phang}matrices:{p_end}
{phang2}r(table) : {cmd:2 x 4}{p_end}
{phang3}r(Y) : {cmd:1000 x 2}{p_end}

{phang}{cmd:. matrix list r(table)}{p_end}

{phang}r(table)[2,4]{p_end}
{pmore2}{space 1}    	     mean {space 7}sd{space 1}    skewness{space 1} kurtosis{p_end}
{phang}Y1{space 1}  {cmd: -.02194593 .99951995 1.4408197 2.9355151}{p_end}
{phang}Y2{space 2}  {cmd:   .00421734 1.0344233 1.7600212 3.7932998}{p_end}


{title:Stored results}

{phang}
{cmd:rmvnonnormal} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}descriptive statistics{p_end}
{synopt:{cmd:r(Y)}}n x k random numbers{p_end}


{marker Reference}{...}
{title:Reference}

{phang} Vale, C. D., and V. A. Maurelli. 1983. Simulating multivariate
nonnormal distributions. {it: Psychometrika} 48: 465-471.{p_end}


{marker Author}{...}
{title:Author}

{pstd}Sunbok Lee{p_end}
{pstd}Center for Family Research{p_end}
{pstd}University of Georgia{p_end}
{pstd}Athens, GA{p_end}
{pstd}sunboklee@gmail.com{p_end}


{marker also_see}{...}
{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 15, number 1: {browse "http://www.stata-journal.com/article.html?article=st0371":st0371}
{p_end}
