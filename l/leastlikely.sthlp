{smcl}
{* jeremy freese}{...}

{title:List least likely observations}

{p2colset 5 16 24 2}{...}
{p2col:{cmd:leastlikely} {hline 2} List observations with lowest likelihoods}
{p2colreset}{...}

{title:Syntax}

{p 4 18 2}{cmd:leastlikely} [{it:varlist}] [{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
{cmd:,} [{cmd:n(}{it:#}{cmd:)} {cmdab:g:enerate(}{it:varname}{cmd:)} {it:options allowed by {cmd:list} command}]

{title:Overview}

{pstd}For regression models for categorical dependent variables,
{cmd:leastlikely} lists the in-sample observations with the lowest
predicted probabilities of observing the outcome value that was
actually observed.  For example, in a model with a binary dependent
variable, {cmd:leastlikely} lists the observations that have the lowest
predicted probability of {it:depvar=0} among those cases for which
{it:depvar=0}, and it lists the observations that have the lowest predicted
probability of {it: depvar=1} among those cases for which {it:depvar=1}.  The
least likely values represent relatively deviant cases that may warrant
closer inspection.{p_end}

{pstd}{cmd:leastlikely} works with estimation commands for models of binary
outcomes in which option {cmd:p} after {cmd:predict} provides the predicted
probability  of a positive outcome (e.g., {cmd:logit}, {cmd:probit}), but the
dependent  variable must be coded as 0 and 1.  Likewise, {cmd:leastlikely}
works with estimation commands for models of ordinal or nominal outcomes
in which option {cmd:outcome(}{it:#}{cmd:)} after {cmd: predict} provides the
predicted probability of outcome {it:#}.  Exceptions are commands in which the
predicted probabilities are probabilities within groups or panels or for
"blocked" data; {cmd:leastlikely} will produce an error message if executed
after {cmd:blogit}, {cmd:bprobit}, {cmd:clogit}, {cmd:glogit},
{cmd:gprobit}, {cmd:nlogit}, or {cmd:xtlogit}.{p_end}

{pstd}{cmd:leastlikely} lists the observation number and the
predicted probability (as Prob or as the variable name specified by the
{cmd:generate} option).  Values of variables in {it:varlist} will also be
displayed.{p_end}


{title:Options}

{p2colset 5 20 21 0}
{synopt:{opt n()}} specifies the number of observations to be listed
for each outcome.  The default is 5.  If multiple observations have the same
probabilities, more than the specified number will be listed to include all
of them.{p_end}

{p2colset 5 20 21 0}
{synopt:{opt gen:erate(varname)}} specifies that the probabilities
of observing the outcome value that was observed should be stored in
{it:varname}.  If not specified, the variable name {cmd:Prob} will be created
but dropped after the output is produced.
{p_end}

{title:Examples}

{pstd}To list least likely observations:
{p_end}

{phang2}
{cmd:. logit low age lwt race2 race3 smoke ptl ht ui}
{p_end}

{phang2}
{cmd:. leastlikely}
{p_end}

{pstd}To list ten observations and save probabilities as variable:
{p_end}

{phang2}{cmd:. leastlikely age lwt, n(10) g(prob)}
{p_end}


INCLUDE help spost13_footer

