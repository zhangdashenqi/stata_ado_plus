{smcl}
{* 05Dec2005jf}
{hline}
help for {hi:case2alt}{right:03Nov2005}
{hline}

{p 4 4 2}
{title:Convert data from one observation per case to one observation per alternative per case}

{p 4 12 2}{cmd:case2alt} {cmd:,}
{{cmdab:choice(}{it:varname}{cmd:)} | {cmdab:rank(}{it:stubname}{cmd:)}}
[{cmdab:a:lt(}{it:stubnames}{cmd:)}
{cmdab:casev:ars(}{it:varlist}{cmd:)}
{cmdab:case(}{it:varname}{cmd:)}
{cmdab:g:enerate(}{it:newvar}{cmd:)}
{cmdab:rep:lace}
{cmdab:altnum(}{it:varname}{cmd:)}
{cmdab:non:ames}]

{title:Description}

{p 4 4 2}
{cmd:case2alt} is intended to be used to configure data for the estimation of estimation
of regression models for alternative-specific data, such as {helpb clogit},
{helpb rologit} or {helpb asmprobit}. {cmd:case2alt} presumes that you have data
where each observation corresponds to an individual case and that you want to convert
the data to the form in which each observation corresponds to an alternative for a specific case.

{p 4 4 2}
Imagine that you have data with an outcome that has four alternatives, with values 1, 2, 3 and 8.
{cmd:case2alt} will reshape the data so that there are n*4 observations. If you specify an
identifying variable with the {cmd:casevars()} option, this variable will continue to identify
unique cases; otherwise, new variable _id will identify cases.

{p 4 4 2}
A new variable, called either _altnum or the name specified in {cmd:altnum()},
will identify the alternatives within a case. Additionally, however, {cmd:case2alt}
will create dummy variables y{it:value} that also identify alternatives.
In our example the new dummy variables y1, y2, y3 and y8 will be created.
Interactions will also be created with these dummies and any variables
specified in {cmd:case()}. For the variable educ, {cmd:case2alt} will create
variables y1_educ, y2_educ, y3_educ, and y8_educ.

{p 4 4 2}
If we have simple choice variable, then {cmd:case2alt} will create an outcome
variable based on {cmd:y()} that contains 1 in the observation corresponding to
the selected alternative and 0 for other alternatives. We can specify the name of
this new outcome variable using the {cmd:gen()} option, or we can have it be the
same as {opt y()} using the {cmd:replace} option, or (by default) we
can have it be named choice.

{p 4 4 2}
After using {cmd:case2alt}, we would be able to estimate models like {helpb clogit} by typing, e.g.,:

{p 4 4 2}
{cmd:. clogit choice y1* y2* y3*, group(_id)}

{p 4 4 2}
Alternative-specific variables are specified using the {cmd:alt()} option.
The contents of {cmd:alt()} should be {it:stubnames}, corresponding to a series
of variables that contain the alternative-specific values.
Specifying {cmd:alt(time)}, in our example, would imply that there are
variables time1, time2, time3 and time8 in our case-level data.

{p 4 4 2}
Case-specific variables are specified using the {cmd:casevars()} option,
where the contents should be a {varlist}.  Neither the outcome nor id variable
should be included in {cmd:casevars()}.

{p 4 4 2}
If we have ranked data, we can specify the ranked outcome with the
{cmd:rank()} outcome.  The content of rank should again be a stubname.
Specifying {cmd:rank(}rank{cmd:)} in our example would assume there are
variables rank1, rank2, rank3, rank8 that contain the relevant information
on the ranks of each alternative.

{title:Options}

{p 4 8 2}{opth choice(varname)} or {opth rank(stubname)} is required. {varname} is the
variable that indicates the value of the selected alternative.
In the case of ranked outcome, {it:stubname} with {opt rank()} will contain
the stub for the names of variables that contain information about ranks of alternatives.

{p 4 8 2}{opth case(varname)} indicates the variable, either existing or to be
created, that identifies individual cases.
If {varname} is unspecified, a new variable named _id will be created.

{p 4 8 2}{cmd:alt(}{it:stubnames}{cmd:)} contains the {it:stubnames} for
alternative-specific variables.  This requires that variables {it:stubname}# exist
for each value of an alternative.

{p 4 8 2}{opth casevars(varlist)} contains the names of the case-specific variables
(not including the id or outcome variable).

{p 4 8 2}{opth gen:erate(newvar)} and {opt replace} are used to name the variable that
contain 1 for the selected alternative and 0 for non-selected alternatives.
The variable will be named {newvar} if {newvar} is specified; the name of
the variable specified in {cmd: y()} if {opt replace} is specified; and will be named {it:choice} otherwise.
In the case of ranked data, the ranks will be contained in variable specified as the
stub in {opt yrank()} and {opt gen:erate()} or {opt replace} will be ignored.

{p 4 8 2}{opth altnum(varname)} indicates the name of the new variable used to indicate
the alternatives. _altnum will be used if altnum() is not specified.

{p 4 8 2}{opt non:ames} indicates that the case-specific interactions should be named
y# instead of using the value labels of the outcome variable.

{title:Example}

{p 4 4 2}{cmd:. use "http://www.stata-press.com/data/lfr/nomocc2.dta", clear}{break}
{cmd:. mlogit occ white ed exper}{break}
{cmd:. case2alt, choice(ed) casevars(white ed exper) replace nonames}{break}
{cmd:. clogit occ y1* y2* y3* y4*, group(_id)}{break}

{p 4 4 2}{cmd:. case2alt, rank(rank92) casevars(hntest) alt(rank04) case(id)}

{title:Authors}

    Jeremy Freese and J. Scott Long
    www.indiana.edu/~jslsoc/spost.htm
    spostsup@indiana.edu
