{smcl}
{* *! version 1.1.13  04jun2007}{...}
{cmd:help confa postestimation}{right: ({browse "http://www.stata-journal.com/article.html?article=st0169":SJ9-3: st0169})}
{hline}

{title:Title}

{p2colset 5 29 31 2}{...}
{p2col :{hi:confa postestimation} {hline 2}}Postestimation tools for confa{p_end}
{p2colreset}{...}


{title:Description}

{pstd}The following commands are available after {helpb confa}:{p_end}

{synoptset 17}{...}
{p2coldent :command}description{p_end}
{synoptline}
{synopt :{helpb confa_estat##fit:estat fitindices}}fit indices{p_end}
{synopt :{helpb confa_estat##ic:estat aic}}AIC{p_end}
{synopt :{helpb confa_estat##ic:estat bic}}BIC{p_end}
{synopt :{helpb confa_estat##corr:estat correlate}}correlations of factors and measurement errors{p_end}
{synopt :{helpb confa_estat##predict:predict}}factor scores{p_end}
{synopt :{helpb bollenstine}}Bollen-Stine bootstrap{p_end}
{synoptline}
{p2colreset}{...}


{marker fit}{...}
{title:The estat fitindices command}

    {title:Syntax}

{p 8 15 2}
{cmd:estat} {cmdab:fit:indices}
[{cmd:,} {it:options}]

{p2colset 9 27 29 2}{...}
{p2col:{it:options}}fit index{p_end}
{p2line}
{p2col :{opt aic}}Akaike information criterion{p_end}
{p2col :{opt bic}}Schwarz Bayesian information criterion{p_end}
{p2col :{opt cfi}}comparative fit index{p_end}
{p2col :{opt rmsea}}root mean squared error of approximation{p_end}
{p2col :{opt rmsr}}root mean squared residual{p_end}
{p2col :{opt tli}}Tucker-Lewis index{p_end}
{p2col :{opt _all}}all the above indices, the default{p_end}
{p2line}
{p2colreset}{...}

    {title:Description}

{pmore}{opt estat }{cmd:fitindices} computes, prints, and saves into
{cmd:r()} results several traditional fit indices.

    {title:Options}

{phang2}
{opt aic} requests the Akaike information criterion (AIC).

{phang2}
{opt bic} requests the Schwarz Bayesian information criterion (BIC).

{phang2}
{opt cfi} requests the CFI (Bentler 1990b).

{phang2}
{opt rmsea} requests the RMSEA (Browne and Cudeck 1993).

{phang2}
{opt rmsr} requests the RMSR.

{phang2}
{opt tli} requests the TLI (Tucker and Lewis 1973).

{phang2}
{opt _all} requests all the above indices. This is the default
behavior if no option is specified.


{marker ic}{...}
{title:The estat aic and estat bic commands}

    {title:Syntax}

{p 8 15 2}
{cmd:estat} {cmd:aic}

{p 8 15 2}
{cmd:estat} {cmd:aic}

    {title:Description}

{pmore}{cmd:estat aic} and {cmd:estat bic} compute the Akaike and Schwarz
Bayesian information criteria, respectively.


{title:The estat correlate command}

    {title:Syntax}

{p 8 15 2}
{cmd:estat} {cmdab:corr:elate}
[{cmd:,}
{opt level(#)}
{opt bound}]

    {title:Description}

{marker corr}{...}
{pmore}{opt estat} {cmd:correlate} transforms the covariance parameters into
correlations for factor covariances and measurement-error covariances.  The
delta method standard errors are given; for correlations close to plus or
minus 1, the confidence intervals may extend beyond the range of admissible
values.{p_end}

    {title:Options}

{phang2}{opt level(#)} changes the confidence level for confidence-interval
reporting.{p_end}

{phang2}{cmd:bound} provides an alternative confidence interval based on
Fisher's z transform of the correlation coefficient. It guarantees
that the end points of the interval are in the (-1,1) range, provided the
estimate itself is in this range.


{marker predict}{...}
{title:The predict command}

    {title:Syntax}

{p 8 19 2}
{cmd:predict} {dtype} {it:{help newvarlist}} {ifin} [{cmd:,} {it:scoring_method}]

{p2colset 9 27 29 2}{...}
{p2col:{it:scoring_method}}factor scoring method{p_end}
{p2line}
{p2col:{cmdab:reg:ression}}regression, or empirical Bayes, score{p_end}
{p2col:{cmdab:emp:iricalbayes}}alias for {cmd:regression}{p_end}
{p2col:{cmdab:eb:ayes}}alias for {cmd:regression}{p_end}
{p2col:{opt mle}}MLE, or Bartlett score{p_end}
{p2col:{cmdab:bart:lett}}alias for {cmd:mle}{p_end}
{p2line}
{p2colreset}{...}

    {title:Description}

{pmore} {cmd:predict} can be used to create factor scores following {cmd:confa}.
The number of variables in {it:newvarlist} must be the same as the number of
factors in the model specification; all factors are predicted at once by the
relevant matrix formula.

    {title:Options}

{phang2}
{opt regression}, {opt empiricalbayes}, or {opt ebayes}
requests regression, or empirical Bayes, factor scoring procedure.

{phang2}
{opt mle} or {opt bartlett} requests Bartlett scoring procedure.


{title:Example}

{phang}{cmd:. use hs-cfa}{p_end}
{phang}{cmd:. confa (vis: x1 x2 x3) (text: x4 x5 x6) (math: x7 x8 x9), from(iv) corr(x7:x8)}{p_end}
{phang}{cmd:. estat fit}{p_end}
{phang}{cmd:. estat corr}{p_end}
{phang}{cmd:. estat corr, bound}{p_end}
{phang}{cmd:. predict fa1-fa3, reg}{p_end}
{phang}{cmd:. predict fb1-fb3, bart}{p_end}


{title:References}

{phang}
Bentler, P. M. 1990. Comparative fit indexes in structural models. 
{it:Psychological Bulletin} 107: 238-246.

{phang}
Browne, M. W., and R. Cudeck. 1993. Alternative ways of assessing model fit.
In {it:Testing Structural Equation Models}, ed. K. A. Bollen and J. S. Long,
136-162. Newbury Park, CA: Sage.

{phang}
Tucker, L. R., and C. Lewis. 1973. A reliability coefficient for maximum likelihood factor analysis. {it:Psychometrika} 38: 1-10.


{title:Author}

{pstd}Stanislav Kolenikov{p_end}
{pstd}Department of Statistics{p_end}
{pstd}University of Missouri{p_end}
{pstd}Columbia, MO{p_end}
{pstd}kolenikovs@missouri.edu{p_end}


{title:Also see}

{psee}
Article: {it:Stata Journal}, volume 9, number 3: {browse "http://www.stata-journal.com/article.html?article=st0169":st0169}

{psee}Online: {helpb confa}, {helpb bollenstine}{p_end}
