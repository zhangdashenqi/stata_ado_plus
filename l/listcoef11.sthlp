{smcl}
{* 2013-08-30 scott long & jeremy freese}{...}
{title:Title}

{p2colset 5 19 20 2}{...}
{p2col:{cmd:listcoef11} {hline 2}}Listing regression coefficients with help for interpretation
{p_end}
{p2colreset}{...}


{title:General syntax}

{p 4 18 2}
{cmd:listcoef11 }[{it:varlist}]{cmd:,} [ {opt pv:alue(#)}
[ {opt f:actor} | {opt p:ercent} | {opt s:td} ]
{opt c:onstant} {opt r:everse}
{opt gt} {opt lt} {opt adj:acent} {opt ex:pand}
{opt nol:abel} {opt h:elp}
]
{p_end}

{p 4 4 2}
where {it:varlist} contains variables from the regression model for which
coefficients are to be listed.
{p_end}

{marker overview}
{title:Overview}

{pstd}
{cmd:listcoef11} lists the estimated coefficients for a variety of regression models.
{cmd:listcoef} is the preferred command but requires Stata 12 or later.
Options allow you to specify different transformations of the coefficients,
such as factor change and percent change. Coefficients can be standardized for
a unit variance in the independent and/or dependent variables.
For {cmd:mlogit}, {cmd:mprobit} and {cmd:slogit}
coefficients for all comparisions can be listed.

{pstd}
Output for models with categorical outcomes is much clearer if you
assign value labels to the dependent variable.


{title:Table of contents}

    {help listcoef##options:General options}
    {help listcoef##options2:Options for nominal models}
    {help listcoef##models:Models compatable with {cmd:listcoef}}
    {help listcoef##returns:Returns}


{title:Options}
{marker options}
{p2colset 5 20 21 0}
{synopt:{opt pval:ue(#)}}
only coefficients with a this significance level or smaller are printed.
{p_end}
{p2colset 5 20 21 0}
{synopt:{opt fac:tor}}
factor change coefficients should be listed.
{p_end}

{synopt:{opt per:cent}}
percent change coefficients should be listed.
{p_end}

{synopt:{opt std}}
coefficients standardized to a unit variance for the
    independent and/or dependent variables should be listed.
{p_end}

{synopt:{opt con:stant}}
include constants in the output.
{p_end}

{synopt:{opt rev:erse}}
reverses the comparison implied by factor or percent change coefficients;
    presents results indicating the change in the odds of b vs. a
    instead of a vs. b.
{p_end}

{synopt:{opt help}}
includes details on the meaning of each coefficient.
{p_end}


{title:Options for {cmd:mlogit}, {cmd:mprobit}, and {cmd:slogit}}
{marker options2}
{p2colset 5 20 21 0}
{synopt:{opt gt}}
only comparisons where the first category has a larger
    value than the second will be printed (e.g., comparing outcome 2
    versus 1, but not 1 versus 2).
{p_end}

{synopt:{opt lt}}
only comparisons where the first category has a smaller
    value than the second will be printed (e.g., comparing outcome 1 versus
    2, but not 2 versus 1).
{p_end}

{synopt:{opt adj:acent}}
only comparisons where the two category values are
    adjacent will be printed (e.g., comparing outcome 1 versus 2 or 2 versus
    1, but not 1 versus 3).
{p_end}

{synopt:{opt nol:abel}}
category numbers rather than value labels are used in the output.
{p_end}

{synopt:{opt ex:pand}}
requests expanded output comparing all pairs of outcome categories
    for ^slogit^.
{p_end}


{title:Compatable Models}
{marker models}
{pstd}
{cmd:listcoef11} can be used with {cmd:clogit}, {cmd:cloglog}, {cmd:cnreg},
{cmd:intreg}, {cmd:logistic}, {cmd:logit},
{cmd:mlogit}, {cmd:mprobit}, {cmd:nbreg}, {cmd:ologit}, {cmd:oprobit},
{cmd:poisson}, {cmd:probit}, {cmd:regress}, {cmd:rologit},
{cmd:slogit}, {cmd:tobit},
{cmd:zinb}, {cmd:zip}, {cmd:ztnb}, and {cmd:ztp}.
{p_end}


{title:Returns}
{marker returns}
{pstd}
{cmd:listcoef11} creates the matrix returns r(table) that contains the
coefficients from the displayed table. For {cmd:zip} and {cmd:zinb} r(table2)
contains coefficients from the inflation equation. Depending on the model
and options, the following columns will be in the returned table.
{p_end}

{p2colset 10 23 22 12}{...}
{p2col :Column name}Contents{p_end}
{p2line}
{p2col :{bf:cat1}}Value of category 1 in contrast.{p_end}
{p2col :{bf:cat2}}Value of category 2 in contrast..{p_end}
{p2col :{bf:bstdx}}X-standardized coefficients.{p_end}
{p2col :{bf:bstdy}}Y-standardized coefficients.{p_end}
{p2col :{bf:bstd}}Fully standardized coefficients.{p_end}
{p2col :{bf:b}}Estimated coefficients.{p_end}
{p2col :{bf:delta}}Values for delta when delta() option is used.{p_end}
{p2col :{bf:expbstd}}Standardized change or exp(b) coefficients.{p_end}
{p2col :{bf:expb}}Factor change or exp(b) coefficients.{p_end}
{p2col :{bf:pctbstd}}Standardized change or exp(b) coefficients.{p_end}
{p2col :{bf:pctb}}Percent change or exp(b) coefficients.{p_end}
{p2col :{bf:pvalue}}p-values.{p_end}
{p2col :{bf:sdx}}Standard deviations of predictors.{p_end}
{p2col :{bf:z}}z-values or t-values.{p_end}
{p2line}
{p2colset 7 24 25 0}
{pstd}
{cmd:listcoef11} saves matrices as returns that
contain the statistics for the model. Depending on the model and the
options, the following matrices are returned:

{p2colset 10 23 22 12}{...}
{p2col :Matrix}Contents{p_end}
{p2line}
{p2col :{bf:b}}Estimated coefficients.{p_end}
{p2col :{bf:b_p}}p-values.{p_end}
{p2col :{bf:b_z}}z-values or t-values.{p_end}
{p2col :{bf:sd_x}}Standard deviations of predictors.{p_end}
{p2col :{bf:b_xs}}X-standardized coefficients.{p_end}
{p2col :{bf:b_ys}}Y-standardized coefficients.{p_end}
{p2col :{bf:b_std}}Fully standardized coefficients.{p_end}
{p2col :{bf:b_fact}}Factor change or exp(b) coefficients.{p_end}
{p2col :{bf:b_facts}}Standardized change or exp(b) coefficients.{p_end}
{p2col :{bf:b_pct}}Percent change or exp(b) coefficients.{p_end}
{p2col :{bf:b_pcts}}Standardized change or exp(b) coefficients.{p_end}
{p2col :{bf:b2}}Coefficients from inflation equation.{p_end}
{p2col :{bf:b2_p}}Pvalues from inflation equation.{p_end}
{p2col :{bf:b2_z}}z-values from inflation equation.{p_end}
{p2col :{bf:b2_fact}}Factor change coefficients from inflation equation.{p_end}
{p2col :{bf:b2_facts}}Standardized factor change coefficients from inflation equation.{p_end}
{p2col :{bf:b2_pct}}Percent change coefficients from inflation equation.{p_end}
{p2col :{bf:b2_pcts}}Standardized percent change coefficients from inflation equation.{p_end}
{p2col :{bf:contrast}}Categories compared in coeficient for {cmd:mlogit} and {cmd:mprobit}.{p_end}
{p2col :{bf:sdx}}Standard deviations of predictors.{p_end}
{p2line}
{p2colset 7 24 25 0}
{p2colset 10 23 22 12}{...}
{p2col :Scalars}Contents{p_end}
{p2line}
{p2col :{bf:cmd}}Name of estimation command.{p_end}
{p2col :{bf:cons}}Constant.{p_end}
{p2col :{bf:cons_z}}z-value of constant.{p_end}
{p2col :{bf:cons_p}}p-value of constant.{p_end}
{p2col :{bf:cons2}}Constant for inflation equation.{p_end}
{p2col :{bf:cons2_z}}z-value for constant in inflation equation.{p_end}
{p2col :{bf:cons2_p}}p-value for constant in inflation equation.{p_end}
{p2col :{bf:pvalue}}Show coefficients with p-values smaller than this.{p_end}
{p2line}
{p2colset 7 24 25 0}
INCLUDE help spost13_footer
