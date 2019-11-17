{smcl}
{* *! version 1.0.0  21jan2008}{...}
{cmd:help vselect}{right: ({browse "http://www.stata-journal.com/article.html?article=up0031":SJ11-1: st0213_1})}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{hi:vselect} {hline 2}}Linear regression variable selection{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 15 2}
{cmd:vselect} {depvar} {indepvars} {ifin} {weight} [{cmd :,} {opt fix(varlist)} {cmd:best} {opt back:ward} {opt for:ward} {opt r2adj} {opt aic}
{opt aicc} {opt bic}]

{phang2}{cmd:fweight}s, {cmd:aweight}s, and {cmd:pweight}s are allowed; see {help weight}.


{title:Description}

{pstd}
{cmd:vselect} performs variable selection for linear regression.  Through the
use of the Furnival-Wilson leaps-and-bounds algorithm, all-subsets variable
selection is supported.  This is done when the user specifies the {cmd:best}
option.  The stepwise methods, forward selection and backward elimination, are
also supported (by specifying {cmd:forward} or {cmd:backward}).

{pstd}All-subsets variable selection provides the R^2 adjusted, Mallows's C,
Akaike's information criterion, Akaike's corrected information criterion, and
Bayesian information criterion for the best regression at each quantity of
predictors.  For stepwise selection, the user must tell {cmd:vselect} which
information criterion to use.

{pstd}The user may also specify a fixed predictor list in {cmd:fix()} that
will be included in every model.


{title:Options}

{phang} {cmd:fix(}{it:varlist}{cmd:)} fixes these predictors in every 
regression.

{phang} {cmd:best} gives the best model for each quantity of predictors.

{phang} {cmd:backward} selects a model by backward elimination.

{phang} {cmd:forward} selects a model by forward selection.

{phang} {cmd:r2adj} uses R^2 adjusted information criterion in stepwise
selection.

{phang} {cmd:aic} uses Akaike's information criterion in stepwise selection.

{phang} {cmd:aicc} uses Akaike's corrected information criterion in stepwise
selection.

{phang} {cmd:bic} uses Bayesian information criterion in stepwise selection.


{title:Examples}

{phang}{stata "sysuse auto":. sysuse auto}{p_end}
{phang}{stata "regress mpg weight trunk length foreign":. regress mpg weight trunk length foreign}{p_end}
{phang}{stata "estat ic":. estat ic}{p_end}
{phang}{stata "vselect mpg weight trunk length foreign, best":. vselect mpg weight trunk length foreign, best}{p_end}
{phang}{stata "regress mpg weight foreign length":. regress mpg weight foreign length}{p_end}
{phang}{stata "estat ic":. estat ic}{p_end}
{phang}{stata "vselect mpg weight trunk length, fix(foreign) best":. vselect mpg weight trunk length, fix(foreign) best}{p_end}
{phang}{stata "regress mpg foreign `r(best2)'":. regress mpg foreign `r(best2)'}{p_end}
{phang}{stata "estat ic":. estat ic}{p_end}
{phang}{stata "vselect mpg weight trunk length foreign, forward aicc":. vselect mpg weight trunk length foreign, forward aicc}{p_end}
{phang}{stata "vselect mpg weight trunk length foreign, backward bic":. vselect mpg weight trunk length foreign, backward bic}{p_end}
{phang}{stata "estat ic":. estat ic}{p_end}

{phang}{stata "webuse census13":. webuse census13}{p_end}
{phang}{stata "generate ne = region == 1":. generate ne = region == 1}{p_end}
{phang}{stata "generate n = region == 2":. generate n = region == 2}{p_end}
{phang}{stata "generate s = region == 3":. generate s = region == 3}{p_end}
{phang}{stata "generate w = region == 4":. generate w = region == 4}{p_end}
{phang}{stata "summarize medage":. summarize medage}{p_end}
{phang}{stata "generate tmedage = (medage-r(mean))/r(sd)":. generate tmedage = (medage-r(mean))/r(sd)}{p_end}
{phang}{stata "generate tmedage2 = tmedage^2":. generate tmedage2 = tmedage^2}{p_end}
{phang}{stata "vselect brate tmedage tmedage2 dvcrate n s w [aweight=pop], best fix(mrgrate)":. vselect brate tmedage tmedage2 dvcrate n s w [aweight=pop], best fix(mrgrate)}{p_end}
{phang}{stata "regress brate mrgrate `r(best5)' [aweight=pop]":. regress brate mrgrate `r(best5)' [aweight=pop]}{p_end}
{phang}{stata "estat ic":. estat ic}{p_end}


{title:Saved results}

{pstd}
{cmd:vselect} saves the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:r(bestK)}}variable list of predictors from best K predictor model{p_end}
{synopt:{cmd:r(besti)}}variable list of predictors from best i predictor model{p_end}
{synopt:{cmd:r(best1)}}variable list of predictors from best 1 predictor model{p_end}
{synopt:{cmd:r(predlist)}}variable list of predictors from the optimal model{p_end}

{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:r(info)}}contains the information criteria for the best models{p_end}
{p2colreset}{...}


{title:Authors}

{pstd}Charles Lindsey{p_end}
{pstd}StataCorp{p_end}
{pstd}College Station, TX{p_end}
{pstd}clindsey@stata.com{p_end}

{pstd}Simon Sheather{p_end}
{pstd}Department of Statistics{p_end}
{pstd}Texas A&M University{p_end}
{pstd}College Station, TX{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 11, number 1: {browse "http://www.stata-journal.com/article.html?article=up0031":st0213_1},{break}
                    {it:Stata Journal}, volume 10, number 4: {browse "http://www.stata-journal.com/article.html?article=st0213":st0213}

{p 7 14 2}Help:  {manhelp nestreg R}, {manhelp stepwise R}
{p_end}
