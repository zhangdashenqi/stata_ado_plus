{smcl}
{* 20Oct2009 version 1.7.6 jsl}{...}
{cmd:help mlogtest}: Help for tests for the multinomial logit model - 2009-10-20
{hline}
{p2colset 4 14 14 2}{...}

{title:Overview}

{p 4 4 2 78}
The command {cmd:mlogtest} computes a variety of tests for the multinomial logit model.
The user selects the tests they want by specifying the appropriate options. For each
independent variable, {cmd:mlogtest} can perform either a LR or Wald test of the
null hypothesis that the coefficients of the variable equal zero across all equations.
{cmd:mlogtest} can also perform Wald or LR tests of whether any pair of outcome
categories can be combined. In addition, {cmd:mlogtest} computes the Hausman and
Small-Hsiao tests of the assumption of the independence of irrelevance alternatives (IIA)
for each possible omitted category.

{title:Syntax}

{p 8 13 2}
{cmd:mlogtest} [{it:varlist}]
[{cmd:,} {it:options}]

{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:{it:Tests of variables}}

{synopt:{opt varlist}}Selects variables to test with the wald or lr options.
By default, all variables in the model are tested.{p_end}

{synopt:{opt w:ald}}Use Wald tests for each variable.{p_end}

{synopt:{opt lr}}Use LR test for each variable.{p_end}

{synopt:{opt set}{bf:(}{it:varlist} [{bf:\} {it:varlist}]{bf:)}}
Specify a set of variables is to be tested with {cmd:lrtest} or
{cmd:lr}. The slash {bf:\} specifies multiple sets of variables.
This option is particularly useful when a categorical variable is
included as a set of dummy variables, allowing that the coefficients for
all of the dummy variables are zero across all equations.{p_end}

{syntab:{it:Tests for combining categories}}

{synopt:{opt c:ombine}}Compute Wald tests of whether two outcomes can be
combined.{p_end}

{synopt:{opt lrc:ombine}}Compute LR tests of whether two outcomes can be
combined.{p_end}

{syntab:{it:Tests of IIA}}

{synopt:{opt h:ausman}} Compute Hausman-McFadden tests using Stata's {cmd:hausman}
command.{p_end}

{synopt:{opt d:etail}}Detailed results for {cmd:hausman} option are given.{p_end}

{synopt:{opt sm:hsiao}}Compute Small-Hsiao tests{p_end}

{synopt:{opt su:est}}Compute Hausman-McFadden tests using Stata's {cmd:suest}
command.{p_end}

{synopt:{opt i:ia}}All of the IIA tests should be computed.{p_end}

{synopt:{opt b:ase}}Conduct IIA test omitting the base category of the original
{cmd:mlogit} estimation. This is done by re-estimating the model using the largest
remaining category as the base category. The original estimates are
restored to memory.{p_end}

{syntab:{it:Other}}

{synopt:{opt a:ll}}All tests should be performed.{p_end}

{synoptline}

{title:Examples}

{bf:    . mlogit whoclass income dad_educ male black hispanic asian}
{bf:    . * compute all tests}
{bf:    . mlogtest, all}

{bf:    . mlogit whoclass income dad_educ male black hispanic asian singlpar}
{bf:    >  stepmommlogit whoclass income dad_educ male black hispanic asian}
{bf:    . * teset groups of dummy variables}
{bf:    . mlogtest, lr set(black hispanic asian \ singlpar stepmom stepdad)}

{title:Returned matrices}

{p 4 4}
{bf:r(combine)}: results of Wald tests to combine categories.  Rows represent all
contrasts among categories; columns indicates the categories contrasted, the
chisq, df, and p of test.

{p 4 4}
{bf:r(lrcomb)}: results of LR tests to combine categories.  Rows represent all
contrasts among categories; columns indicates the categories contrasted, the
chisq, df, and p of test.

{p 4 4}
{bf:r(hausman)}: results of Hausman tests of IIA assumption.  Each row is one test.
Columns indicate the omitted category of a given test, the chisq, df, and p.

{p 4 4}
{bf:r(smhsiao)}: results of Small-Hsiao tests of IIA assumption.

{p 4 4}
{bf:r(wald)}: results of Wald test that all coefficients of an independent variable
equals zero

{p 4 4}
{bf:r(lrtest)}: results of likelihood-ratio test that all coefficients of an
independent variable equals zero

{title:Acknowledgment}

{p 4 4}
The code used for the Small-Hsiao test is based on a program by Nick Winter.
INCLUDE help spost_footer

