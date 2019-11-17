{smcl}
{hline}
help for {hi:prop_sel}
{hline}

{title:Producing a propensity score that effectively balances variables}

{title:Syntax}

{p 8 17 2}
{cmd:prop_sel}
{varlist}
[, options ]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt st:andard(real)}} Maximum allowed standardised difference
  between unexposed and exposed subjects: defaults to 0.1 {p_end}
{synopt:{opt rel:ative(real)}} Maximum allowed relative difference
  between unexposed and exposed subjects {p_end}
{synopt:{opt b:eta(namelist)}} Vector of coefficients for
  calculating expeced bias {p_end}
{synopt:{opt bias(real)}} Maximum allowed expected bias due to a
  single variable {p_end}
{synopt:{opt eform}} Present expected bias in exponentiated form {p_end}
{synopt:{opt maxt:erms(integer)}} Maximum number of terms allowed in
  logistic regression propensity score model {p_end}
{synopt:{opt maxk(integer)}} Maximum power of any variable allowed in
  logistic regression propensity score model {p_end}
{synopt:{opt p:ropensity(name)}} Name of a variable to contain
  calculated propensity scores {p_end}
{synopt:{opt w:eightvar(name)}} Name of a variable to contain
  calculated IPT weights {p_end}
{synopt:{opt graph}} Produce a graph showing imbalance in each
  variable before and after propensity weighting {p_end}
{synopt:{opt initmodel(string)}} Terms to include in the propensity
  model initially. By default, only main effects are included{p_end}
{synopt:{opt trace(integer)}} Produce diagnostic output at various
  levels (1-4) {p_end}
{synopt:{opt xip:refix(string)}}{p_end}
{synoptline}


{title:Description}

{pstd}
Conventional methods of model building are not appropriate for
  propensity models. The aim of a propensity model is to balance a set
  of variables between treated and untreated subjects, not to provide
  accurate predictions of who did or did not receive treatment. The
  command {cmd:prop_sel} sequentially adds terms to a logistic
  regression model to reduce the imbalance in the worst balanced
  variable, until all variables are balanced to an acceptable
  level. It selects terms to add by combining, in turn, each variable
  in {varlist} with each term in the model containing the variable
  with greatest imbalance, and selecting the term that reduces this
  imbalance the most. It continues to do this until all variables are
  balanced adequately, it is unable to find a term that reduces the
  imbalance in the most imbalanced variable, the next term that should be added contains 
  a variable raised to the power ({opt maxk}+1), or the propensity model
  contains {opt maxiter()} terms.

{title:Options}{dlgtab:Main}

{phang}
{opt st:andard(real)}
The default method of measuring balance is to use standardised
  differences, with a standardised difference between treated and
  untreated subjects of less than 0.1 being considered balanced. The
  default value of 0.1 can be changed by using the option 
  {opt standard(x)}, which sets the threshold for defining balance to
  {it:x}. 

{phang}
{opt rel:ative(real)} One alternative is to insist that the propensity
  score reduces the imbalances to a given proportion of the initial
  value, using the option {opt relative()}. For example, 
  {opt relative(0.1)} reduces the imbalance in each variable to at
  most 10% of the initial value. This can lead to very complicated
  models if there is very little imbalance to begin with.

{phang}
{opt b:eta(namelist min=1 max=1)} A second, preferable alternative, is
  to measure balance in terms of the expected bias in the estimate of
  the treatment effect. The expected bias due to a given variable is
  the product of the difference between the treated and untreated
  subjects in the mean of the at variable, and the coefficient for
  that variable in an outcome model. The option {opt beta()} is used
  to pass a vector of coefficients to {cmd:prop_sel}. The vector must
  contain one coefficient for each variable in {varlist}, in the same
  order.

{phang}
{opt bias(real)} When measuring imbalance in terms of expected bias,
  the option {opt bias()} sets the threshold for defining balance. It
  defaults to 0.05.

{phang}
{opt eform} If the coefficients from teh outcome model from which the
  coefficient vector {opt beta} was taken are used presented after
  exponentiation (e.g. odds ratios from logistic regression), the
  option {opt eform} can be used. This changes the presentation of the
  imbalance in each variable to show percentage bias, rather than
  absolute bias. It also changes the meaning of the {opt bias()}
  option: {opt bias(0.05)} now sets the threshold to a 5% change in
  exponentiated coefficient.

{phang}
{opt maxt:erms(integer)} limits the maximum number of terms that can
  be fitted to the propensity score. The default is {it:p{c 178}},
  where {it:p} is the number of variables in {varlist}.

{phang}
{opt maxk(integer)} limits the maximum power of any variable in any term that can
  be fitted to the propensity score. The default is 8, since that is the maximum order of an interaction allowed in stata 11. So {opt maxk} cannot be increased, only reduced. Since complex expressions in a given variable often occur when there is little overlap betwee exposed and unexposed subjects in that variable, a kernel density plot of the offending variable is produced: often restricting the range of this variable will produce a simpler propensity score with good balance.

{phang}
{opt p:ropensity(name)} gives the name of a variable to contain the
  propensity scores from the finally selected model. 

{phang}
{opt w:eightvar(name)} gives the name of a variable to contain the
  inverse probability of treatment weights from the finally selected
  model.

{phang}
{opt graph} produces a graph showing imbalance in each variable before
  and after propensity weighting.

{phang}
{opt initmodel(string)} allows for certain terms to be forced into the
  propensity model, in addition to the variables in {varlist} which
  will be included anyway.

{phang}
{opt trace(integer)} sets the trace level, with higher levels
  producing more output. The following trace levels are available: {p_end}{...}
  {p2colset 6 10 10 4}
  {p2col:1} List matrix of differences, iteration number and
  threshold used for differences.{p_end}{...}
  {p2col:2} Improvement with each term tested, and best
  improvement so far.{p_end}{...}
  {p2col:3} Keep track of which terms are fitted and
  which ones have already been fitted.{p_end}{...}
  {p2col:4} Programming diagnostics.{p_end}{...}

{phang}
{opt xip:refix(string)} Usually, {cmd:prop_sel} uses the prefix string _I
to recognise categorical variables. If you have used a different prefix,
with the {opt prefix(string)} option to {cmd:xi}, you may need to use the
same string in this option so that {cmd:prop_sel} can recognise the
categorical variables.{p_end}

{title:Remarks}

{pstd} If there is little overlap in a particular variable between
treated and untreated subjects, this will produce extremely large or
extremely small propensity scores for extreme values of this
variable. This can make the association between log-odds of treatment
and that variable highly non-linear. This is the reason for the option
{opt maxk()}: it may be easier to achieve balance by limiting the
allowable range of this variable.{p_end}

{pstd} Using relative reduction to define adequate balance can be
difficult. There may be only a small difference between exposed and
unexposed subjects initially, and removing 90% of this may require a
very complex propensity model. Using {opt beta()} is recommended
whenever possible: if it is not possible, {opt standard()} is probably
better than {opt relative()}{p_end}

{title:Saved Results}

{pstd}{cmd:prop_sel} saves the following in {cmd:r()}:{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(propstr)}}List of terms included in the final
  propensity model{p_end}


{title:Author}
{pstd}
Mark Lunt, Arthritis Research UK Epidemiology Unit

{pstd}
The University of Manchester

{pstd}
Please email {browse "mailto:mark.lunt@manchester.ac.uk":mark.lunt@manchester.ac.uk} if you encounter problems with this program

