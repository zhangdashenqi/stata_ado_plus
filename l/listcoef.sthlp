{smcl}
{* 2014-08-06 scott long & jeremy freese}{...}
{title:Title}

{p2colset 5 17 20 2}{...}
{p2col:{cmd:listcoef} {hline 2}}Listing regression coefficients with help for interpretation
{p_end}
{p2colreset}{...}


{title:General syntax}

{p 4 18 2}
{cmd:listcoef }[{it:varlist}]{cmd:,} [ {opt pv:alue(#)}
[ {opt f:actor} | {opt p:ercent} | {opt s:td} ]
{opt c:onstant} {opt r:everse}
{opt gt} {opt lt} {opt adj:acent}
{opt pos:itive} {opt neg:ative}
{opt ex:pand}
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
{cmd:listcoef} lists the estimated coefficients for a variety of regression models.
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
    {help listcoef##models:Models compatable with listcoef}
    {help listcoef##returns:Returns}
    {help listcoef##examples:Examples}


{marker options}
{title:Options}
{p2colset 5 18 19 0}
{synopt:{opt pval:ue(#)}}
only coefficients with a significance level of {opt #} or smaller are printed.
{p_end}
{p2colset 5 18 19 0}
{synopt:{opt fac:tor}}
factor change coefficients are listed.
{p_end}

{synopt:{opt per:cent}}
percent change coefficients are listed.
{p_end}

{synopt:{opt std}}
coefficients standardized to a unit variance for the
    independent and/or dependent variables are be listed.
{p_end}

{synopt:{opt constantoff}}
do not show constants in the output.
{p_end}

{synopt:{opt rev:erse}}
reverses the comparison implied by factor or percent change coefficients;
    presents results indicating the change in the odds of b vs. a
    instead of a vs. b.
{p_end}

{synopt:{opt vsquish}}
removes blanks rows sperating factor variables.
{p_end}

{synopt:{opt nofvlabel}}
display factor variable level values instead of labels.
{p_end}

{synopt:{opt help}}
includes details on the meaning of each coefficient.
{p_end}

{marker options2}
{title:Options for {cmd:mlogit}, {cmd:mprobit}, and {cmd:slogit}}
{p2colset 5 18 19 0}
{synopt:{opt gt}}
only comparisons where the first category has a larger
    value than the second are printed (e.g., comparing outcome 2
    versus 1, but not 1 versus 2).
{p_end}

{synopt:{opt lt}}
only comparisons where the first category has a smaller
    value than the second are printed (e.g., comparing outcome 1 versus
    2, but not 2 versus 1).
{p_end}

{synopt:{opt adj:acent}}
only comparisons where the two category values are
    adjacent are printed (e.g., comparing outcome 1 versus 2 or 2 versus
    1, but not 1 versus 3).
{p_end}

{synopt:{opt pos:itive}}
only comparisons where the coefficient is positive
    are printed.
{p_end}

{synopt:{opt neg:ative}}
only comparisons where the coefficient is negative
    are printed.
{p_end}

{synopt:{opt nol:abel}}
category numbers rather than value labels are used in the output.
{p_end}

{synopt:{opt ex:pand}}
requests expanded output comparing all pairs of outcome categories
for {cmd:slogit}.
{p_end}


{title:Compatable Models}
{marker models}
{pstd}
{cmd:listcoef} can be used with {cmd:clogit}, {cmd:cloglog}, {cmd:cnreg},
{cmd:intreg}, {cmd:logistic}, {cmd:logit},
{cmd:mlogit}, {cmd:mprobit}, {cmd:nbreg}, {cmd:ologit}, {cmd:oprobit},
{cmd:poisson}, {cmd:probit}, {cmd:regress}, {cmd:rologit},
{cmd:slogit}, {cmd:tobit},
{cmd:zinb}, {cmd:zip}, {cmd:ztnb}, and {cmd:ztp}.
{p_end}


{title:Returns}
{marker returns}
{pstd}
{cmd:listcoef} creates returns {cmd:r(table)} that contains the
coefficients from the displayed table. For {cmd:zip} and {cmd:zinb}, {cmd:r(table2)}
contains coefficients from the inflation equation.
{cmd:r(cmd)} returns the name of the estimation command and {cmd:r(pvalue)}
the value specified with the {cmd:pvalue()} option.
{p2colset 7 24 25 0}


{marker examples}{...}
{title:Examples}

{pstd}
{ul:{bf:Example 1: Simple display of coefficients}}
{p_end}

{phang2}{cmd:. spex logit}{p_end}
{phang2}{cmd:. listcoef, help}{p_end}
{phang2}{cmd:. listcoef, pct help}{p_end}

{pstd}
{ul:{bf:Example 2: Display multinomial results}}
{p_end}

{phang2}{cmd:. spex mlogit}{p_end}
{phang2}{cmd:. listcoef, help factor pvalue(0.10) positive}{p_end}

INCLUDE help spost13_footer
