{smcl}
{* *! version 1.1  20nov2009}{...}
{cmd:help mcd}{right: ({browse "http://www.stata-journal.com/article.html?article=up0028":SJ10-2: st0173_1})}
{hline}

{title:Title}

{p2colset 5 12 14 2}{...}
{p2col :{hi:mcd} {hline 2}}Minimum covariance determinant estimator of location and scatter
{p2colreset}{...}


{title:Syntax}

{p 8 14 2}
{cmd:mcd} {varlist} {ifin} 
[{cmd:,} {it:options}] 

{synoptset 28 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt :{opt e(#)}}set the maximum expected proportion of outliers{p_end}
{synopt :{opt proba(#)}}set the probability of selecting at least one clean
subsample in the p-subset algorithm{p_end}
{synopt :{opt trim(#)}}set the percentage of trimming {p_end}
{synopt :{opt g:enerate(newvar1 newvar2)}}create two variables flagging
outliers and reporting robust distances, respectively{p_end}
{synopt :{opt best:sample(newvar)}}create a dummy flagging observations used
for estimating the trimmed covariance matrix{p_end}
{synopt :{opt raw}}return the raw robust covariance matrix{p_end}
{synopt :{opt setseed(#)}}set the seed{p_end}
{synoptline}


{title:Description}

{pstd}
{opt mcd} finds the minimum covariance determinant (MCD) estimator of location
and scatter. By default, the one-step, reweighted MCD robust covariance matrix
is saved in matrix {cmd:covRMCD} and the one-step, reweighted MCD robust
location vector is saved in matrix {cmd:locationRMCD}.


{title:Options}

{phang}
{opt e(#)} sets the maximum expected percentage of outliers existing in the
dataset. Setting it high slows down the algorithm. The default is {cmd:e(0.2)},
but it can take on any value ranging from 0 to 0.5.

{phang}
{opt proba(#)} sets the probability of having at least one noncorrupt sample
among all those considered. The default is {cmd:proba(0.99)}, but it can take
on any value ranging from 0 to 0.9999.

{phang}
{opt trim(#)} specifies the percentage of outliers that the estimator can
withstand before breaking up. The default is {cmd: trim(0.5)}, but it can take
on any value ranging from 0 to 0.5.

{phang}
{opt generate(newvar1 newvar2)} creates two variables: one for flagging
outliers and one for reporting robust distances, respectively. These variables
can be used for outlier identification or for calculating outlyingness weights.

{phang}
{opt bestsample(newvar)} creates a new variable identifying the subsample used
for estimating the MCD location vector and scatter matrix.

{phang}
{opt raw} returns the genuine MCD location vector ({cmd:locationMCD}) and
covariance matrix ({cmd:covMCD}) rather than the one-step, reweighted MCD (the
default).

{phang}
{opt setseed(#)} allows the user to set a seed. Setting the seed ensures that
you can replicate the results.


{title:Examples}

{pstd}Setup{p_end}
{phang2}{stata "webuse auto":. webuse auto}{p_end}

{pstd}Estimate robust Mahalanobis distances{p_end}
{phang2}{stata "mcd mpg headroom trunk weight length turn displacement gear_ratio, generate(outlier RD) setseed(1000)":. mcd mpg headroom trunk weight length turn displacement gear_ratio, generate(outlier RD) setseed(1000)}{p_end}

{pstd}Display the robust reweighted covariance matrix and location vector{p_end}
{phang2}{stata "matrix list covRMCD":. matrix list covRMCD}{p_end}
{phang2}{stata "matrix list locationRMCD":. matrix list locationRMCD}{p_end}

{pstd}Generate a line ID and graph robust Mahalanobis distances{p_end}
{phang2}{stata "generate id=_n":. generate id=_n}{p_end}
{phang2}{stata "twoway(scatter id RD, mlabel(id)), xline(3.94)":. twoway(scatter id RD, mlabel(id)), xline(3.94)}{p_end}

{pstd}Drop the variable created to identify outliers{p_end}
{phang2}{stata "drop outlier RD":. drop outlier RD}{p_end}

{pstd}Same as above but using the raw data{p_end}
{phang2}{stata "mcd mpg headroom trunk weight length turn displacement gear_ratio, generate(outlier RD) raw":. mcd mpg headroom trunk weight length turn displacement gear_ratio, generate(outlier RD) raw}{p_end}

{pstd}Display the robust raw covariance matrix and location vector{p_end}
{phang2}{stata "matrix list covMCD":. matrix list covMCD}{p_end}
{phang2}{stata "matrix list locationMCD":. matrix list locationMCD}{p_end}


{title:Author}

{pstd}Vincenzo Verardi{p_end}
{pstd}University of Namur{p_end}
{pstd}Universit{c e'} Libre de Bruxelles{p_end}
{pstd}National Science Foundation of Belgium{p_end}
{pstd}vverardi@fundp.ac.be{p_end}


{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 10, number 2: {browse "http://www.stata-journal.com/article.html?article=up0028":st0173_1},{break}
           {it:Stata Journal}, volume 9, number 3: {browse "http://www.stata-journal.com/sjpdf.html?articlenum=st0173":st0173}

{p 4 14 2}{space 3}Help:  {manhelp qreg R}, {manhelp regress R};{break}
{manhelp rreg R}, {helpb mmregress}, {helpb sregress}, {helpb msregress},
{helpb mregress} (if installed)
{p_end}
