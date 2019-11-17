{smcl}
{* 03Nov2005}{...}
{hline}
help for {hi:asprvalue}{right:03Nov2005}
{hline}

{title:Predicted probabilities for models with alternative-specific variables}

{p 8 15 2}{cmd:asprvalue} [{cmd:,}
{cmd:x(}{it:variables_and_values}{cmd:)}
{cmdab:r:est(}{it:stat}{cmd:)}
{cmdab:b:ase(}{it:refcatname}{cmd:)}
{cmdab:c:at(}{it:catnames}{cmd:)}
{cmdab:s:ave}
{cmdab:d:iff}
{cmdab:br:ief}

{p 4 4 2}
where {it:variables_and_values} is an alternating list of variables
and numeric values

{p 4 4 2}
{it:stat} is either mean or asmean (alternative-specific means for alternative-specific variables)

{p 4 4 2}
{cmd:asprvalue} is intended to be used to compute predicted probabilities for logit or probit models
that can combine case- and alternative-specific variables.  For these models, predicted probabilities
depend on the values of the independent variables, which may or may not vary over the alternatives for
a particular case.  {cmd:asprvalue} allows you to specify the values of the independent variables and
presents predicted probabilities for the different alternatives.  The command presently works after
{helpb clogit}, {helpb rologit}, or {helpb asmprobit}.

{p 4 4 2}
{cmd:IMPORTANT:} For {helpb clogit} and {helpb rologit} models, case-specific variables are specified
by a set of interactions with dummy variables for the alternatives.  {cmd:asprvalue} can only be used
if these interaction variables are named {it:alternative_name}X{it:case_specific_varname}.  In other
words, if the dummy variables for the alternatives are named "car" and "bus" and a case-specific
variable is "male", the interactions must be named "carXmale" and "busXmale".  These names for the
interactions correspond with the names used if the data have been arranged for estimation using
the command {cmd:case2choice}.  A capital "X" cannot be used in the names of any of the other
variables in the model.

{title:Options}

{p 4 8 2}
{cmd:save}  saves current values of indepenent variables and predictions
for computing changes using the diff option.

{p 4 8 2}
{cmd:diff}  computes difference between current predictions and those
that were saved.

{p 4 8 2}
{cmd:x()} sets the values of independent variables for calculating
predicted values.  For case-specific variables, the list must alternate
variable names and values.  For alternative-specific variables, the list
may either be followed by a single value to be assigned to all alternatives
or J values if there are J alternatives.  For {helpb clogit} or {helpb rologit}
, when J values are specified, these
are assigned to the alternatives in the order they have been specified by
{cmd:cat()} or in the estimation command, with the value to be assigned to the
reference category being last.  For {helpb asmprobit}, the different alternatives are specified
using a single variable rather than a series of dummy variables, and values for
alternative-specific variables should be ordered to correspond with the ascending
values of the variable.


{p 4 8 2}
{cmd:rest()} sets the values for variables unspecified in {cmd:x()}.  The default
is {it:mean}, which holds all unspecified variables to their case-specific means.
One can also specific "asmean", which holds unspecified alternative-specific
variables to their alternative-specific means.  For example, if "time" was an
alternative-specific variable, {it:mean} would assign all alternatives the
mean of "time" over all individuals and alternatives, while {it:asmean} would assign
each alternative the mean of "time" for that alternative.

{p 4 8 2}
{cmd:base()} specifies the name of the base (reference) category.  If this is not
specified, "base" will be used to refer to this category in the output.  This option
should not be used after {helpb asmprobit}.

{p 4 8 2}
{cmd:cat()} specifies the names of the dummy variables in the model used to
indicate different alternatives (the alternative-specific intercepts).  {cmd:cat()} only
needs to be specified if the model includes no case-specific variables, as otherwise
this list is inferred from the names of the interaction terms for case-specific
variables.  The name of the reference category should not be included in {cmd:cat()}. This option
should not be used after {helpb asmprobit}.

{p 4 8 2}
{cmd:brief} prints only limited output.

{title:Examples}

{p 4 4 2}
{cmd:. use "http://www.stata-press.com/data/lfr/nomocc2.dta", clear}{break}
{cmd:. gen busXhinc = bus*hinc}{break}
{cmd:. gen trainXhinc = train*hinc}{break}
{cmd:. gen busXpsize = bus*psize}{break}
{cmd:. gen trainXpsize = train*psize}{break}
{cmd:. clogit choice train* bus* time invc , group(id)}{break}
{cmd:. asprvalue, x(time 600 invc 30 hinc 40 psize 0) base(car)}{break}

{p 4 4 2}
{cmd:. asprvalue, x(psize 0) base(car) save}{break}
{cmd:. asprvalue, x(psize 1) base(car) dif}{break}

{p 4 4 2}
{cmd:. asprvalue, x(psize 0) base(car) rest(asmean) save}{break}
{cmd:. asprvalue, x(psize 1) base(car) rest(asmean) dif}{break}

{p 4 4 2}
{cmd:. asprvalue, x(time 600 hinc 40 psize 1) base(car) save}{break}
{cmd:. asprvalue, x(time 700 600 600 hinc 40 psize 1) base(car) dif}{break}
{cmd:. asprvalue, x(time 600 700 600 hinc 40 psize 1) base(car) dif}{break}
{cmd:. asprvalue, x(time 600 600 700 hinc 40 psize 1) base(car) dif}{break}

{title:Authors}

    Jeremy Freese and J. Scott Long
    {browse www.indiana.edu/~jslsoc/spost.htm}
    spostsup@indiana.edu
