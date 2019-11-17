{smcl}
{* *! version 1.2.1  07mar2013}{...}
{cmd:help rnonnormal}{right: ({browse "http://www.stata-journal.com/article.html?article=st0371":SJ15-1: st0371})}
{hline}

{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{hi:rnonnormal} {hline 2}}Generate nonnormal random numbers{p_end} 
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 11 2}
{cmdab:rnonnormal}{cmd:,} {cmd:n(}{it:#}{cmd:)}
{cmdab:skew:ness(}{it:#}{cmd:)} {cmdab:kurt:osis(}{it:#}{cmd:)}


{marker description}{...}
{title:Description}

{pstd}
{cmd:rnonnormal} generates univariate nonnormal random numbers with
specified skewness and kurtosis by implementing the power method
proposed by Fleishman (1978).


{marker options}{...}
{title:Options}

{phang}{cmd:n(}{it:#}{cmd:)} specifies the sample size of univariate
nonnormal random numbers. {cmd:n()} is required.{p_end}

{phang}{cmd:skewness(}{it:#}{cmd:)} specifies the skewness of univariate
nonnormal random numbers. {cmd:skewness()} is required.{p_end}

{phang}{cmd:kurtosis(}{it:#}{cmd:)} specifies the kurtosis of univariate
nonnormal random numbers. {cmd:kurtosis()} is required.{p_end}


{marker example}{...}
{title:Example}

{phang}{cmd:. set seed 777}{p_end}
{phang}{cmd:. rnonnormal, n(1000) skewness(1.5) kurtosis(3.75)}{p_end}
{phang}{cmd:. return list}{p_end}

{phang}scalars:{p_end}
{phang3}{space 3}r(a) ={space 1} {cmd:-.2210276210126192}{p_end}
{phang3}{space 3}r(b) ={space 1} {cmd:.8658862035231392}{p_end}
{phang3}{space 3}r(c) ={space 1} {cmd:.2210276210126192}{p_end}
{phang3}{space 3}r(d) ={space 1} {cmd:.0272206991580893}{p_end}
{phang3}r(kurt) ={space 1} {cmd:3.612271257758691}{p_end}
{phang3}r(skew) ={space 1} {cmd:1.452691091582093}{p_end}
{phang3}{space 2}r(sd) ={space 1} {cmd:1.027291300889708}{p_end}
{phang3}r(mean) ={space 1} {cmd:.0202128245923377}{p_end}

{phang}matrices:{p_end}
{phang3}{space 3}r(Y) : {cmd:1000 x 1}{p_end}


{title:Stored results}

{phang}
{cmd:rnonnormal} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(a)}}a in Fleishman's equation{p_end}
{synopt:{cmd:r(b)}}b in Fleishman's equation{p_end}
{synopt:{cmd:r(c)}}c in Fleishman's equation{p_end}
{synopt:{cmd:r(d)}}d in Fleishman's equation{p_end}
{synopt:{cmd:r(skew)}}sample skewness{p_end}
{synopt:{cmd:r(kurt)}}sample kurtosis{p_end}
{synopt:{cmd:r(sd)}}sample standard deviation{p_end}
{synopt:{cmd:r(mean)}}sample mean{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(Y)}}n x 1 random numbers{p_end}


{marker Reference}{...}
{title:Reference}

{phang} Fleishman, A. I. 1978. A method for simulating non-normal
distributions. {it:Psychometrika} 43: 521-532.


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
