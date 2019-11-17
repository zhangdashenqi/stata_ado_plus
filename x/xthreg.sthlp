{smcl}
{* *! version 1.1.0 15sep2013}{...}
{cmd:help xthreg}{right: ({browse " http://www.stata-journal.com/article.html?article=st0373":SJ15-1: st0373})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:xthreg} {hline 2}}Estimate fixed-effect panel threshold model{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 11 2}{cmd:xthreg} {depvar} [{indepvars}] {ifin}{cmd:,} {cmd:rx(}{it:varlist}{cmd:)} {cmd:qx(}{it:varname}{cmd:)} [{opt th:num(#)} {opt g:rid(#)} {opt t:rim(numlist)} {opt bs(numlist)} {opt thl:evel(#)} {opt gen(newvarname)} {opt noreg}
{opt nobslog} {opt thg:iven} {it:options}]

{pstd}where {depvar} is the dependent variable and {indepvars} are the regime-independent variables.{p_end}


{title:Description}

{pstd}
{cmd:xthreg} fits fixed-effect panel threshold models based on the method
proposed by Hansen (1999).  {cmd:xthreg} uses {manhelp xtreg XT} to fit the
fixed-effect panel threshold model given the threshold estimator.  The
fixed-effect panel threshold model requires balanced panel data, which is
checked automatically by {cmd:xthreg}.  The estimation and test of the
threshold effect are computed in Mata.{p_end}


{title:Options}

{phang}
{opt rx(varlist)} is the regime-dependent variable.  Time-series operators are
allowed.  {cmd:rx()} is required.

{phang}
{opt qx(varname)} is the threshold variable.  Time-series operators are
allowed.  {cmd:qx()} is required.

{phang}
{opt thnum(#)} is the number of thresholds.  In the current version (Stata 13),
{it:#} must be equal to or less than 3.  The default is {cmd:thnum(1)}.

{phang}
{opt grid(#)} is the number of grid points.  {cmd:grid()} is used to avoid
consuming too much time when computing large samples.  The default is
{cmd:grid(300)}.

{phang}
{opt trim(numlist)} is the trimming proportion to estimate each threshold.
The number of trimming proportions must be equal to the number of thresholds
specified in {cmd:thnum()}.  The default is {cmd:trim(0.01)} for all
thresholds.  For example, to fit a triple-threshold model, you may set
{cmd:trim(0.01 0.01 0.05)}.

{phang}
{opt bs(numlist)} is the number of bootstrap replications.  If {cmd:bs()} is
not set, {cmd:xthreg} does not use bootstrap for the threshold-effect test.

{phang}
{opt thlevel(#)} specifies the confidence level, as a percentage, for
confidence intervals of the threshold.  The default is {cmd:thlevel(95)}.

{phang}
{opt gen(newvarname)} generates a new categorical variable with 0, 1, 2, ... for each regime.  The default is {cmd:gen(_cat)}.

{phang}
{cmd:noreg} suppresses the display of the regression result.

{phang}
{cmd:nobslog} suppresses the iteration process of the bootstrap.

{phang}
{cmd:thgiven} fits the model based on previous results.

{phang}
{it:options} are any options available for {manhelp xtreg XT}.

{phang}
Time-series operators are allowed in {it:depvar}, {it:indepvars}, {cmd:rx()},
and {cmd:qx()}.


{title:Examples}

{phang}Setup{p_end}
{phang2}{cmd:. use hansen1999}{p_end}

{phang}Estimate a single-threshold model{p_end}
{phang2}{cmd:. xthreg i q1 q2 q3 d1 qd1, rx(c1) qx(d1) thnum(1) trim(0.01) grid(400) bs(300)}{p_end}

{phang}Estimate a triple-threshold model given the estimated result above{p_end}
{phang2}{cmd:. xthreg i q1 q2 q3 d1 qd1, rx(c1) qx(d1) thnum(3) trim(0.01 0.01 0.05) bs(0 300 300) thgiven}{p_end}
{phang2}{cmd:. xthreg i q1 q2 q3 d1 qd1, rx(c1) qx(d1) thnum(3) trim(0.01 0.01 0.05) grid(400) bs(300 300 300)}{p_end}

{phang}Estimate a triple-threshold model directly{p_end}
{phang2}{cmd:. xthreg i q1 q2 q3 d1 qd1, rx(c1) qx(d1) thnum(3) trim(0.01 0.01 0.05) bs(300 300 300)}{p_end}

{phang}Plot the confidence interval using likelihood-ratio (LR) statistics{p_end}
{phang2}{cmd:. _matplot e(LR21), columns(1 2) yline(7.35, lpattern(dash)) connect(direct) msize(small) mlabp(0) mlabs(zero) ytitle("LR Statistics") xtitle("First Threshold") recast(line) name(LR21) nodraw}{p_end}
{phang2}{cmd:. _matplot e(LR22), columns(1 2) yline(7.35, lpattern(dash)) connect(direct) msize(small) mlabp(0) mlabs(zero) ytitle("LR Statistics") xtitle("Second Threshold") recast(line) name(LR22) nodraw}{p_end}
{phang2}{cmd:. graph combine LR21 LR22, cols(1)}{p_end}


{title:Stored results}

{pstd}Along with the standard stored results of the {manhelp xtreg XT} command, {cmd:xthreg} also stores the following in {cmd:e()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2:Scalars}{p_end}
{synopt:{cmd:e(thnum)}}number of thresholds{p_end}
{synopt:{cmd:e(grid)}}number of grid search points{p_end}
{p2colreset}{...}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2:Macros}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(ix)}}regime-independent variables{p_end}
{synopt:{cmd:e(rx)}}regime-dependent variables{p_end}
{synopt:{cmd:e(qx)}}threshold variable{p_end}
{p2colreset}{...}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2:Matrices}{p_end}
{synopt:{cmd:e(Thrss)}}threshold estimator and confidence interval{p_end}
{synopt:{cmd:e(Fstat)}}threshold-effect test result{p_end}
{synopt:{cmd:e(bs)}}bootstrap number{p_end}
{synopt:{cmd:e(trim)}}trimming proportion{p_end}
{synopt:{cmd:e(LR)}}LR statistics for single-threshold
model{p_end}
{synopt:{cmd:e(LR_2_1)}}LR statistics for first threshold in double-threshold model{p_end}
{synopt:{cmd:e(LR_2_2)}}LR statistics for second threshold in double-threshold model{p_end}
{synopt:{cmd:e(LR3)}}LR statistics for third threshold in triple-threshold model{p_end}
{p2colreset}{...}


{title:References}

{phang}Gonzalo, J., and M. Wolf.  2005.  Subsampling inference in threshold autoregressive models.  {it:Journal of Econometrics} 127: 201-224.

{phang}Hansen, B. E.  1999.  Threshold effects in non-dynamic panels:
Estimation, testing, and inference.  {it:Journal of Econometrics} 93: 345-368.

{phang}Politis, D. N., J. P. Romano, and M. Wolf.  1999.  {it:Subsampling}.  New York: Springer.


{title:Author}

{pstd}Qunyong Wang{p_end}
{pstd}Institute of Statistics and Econometrics{p_end}
{pstd}Nankai University{p_end}
{pstd}Tianjin, China{p_end}
{pstd}QunyongWang@outlook.com{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 15, number 1: {browse "http://www.stata-journal.com/article.html?article=st0373":st0373}
{p_end}

{p 7 14 2}Help:  {manhelp xtreg XT}
{p_end}
