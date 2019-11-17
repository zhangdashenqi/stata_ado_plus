{smcl}
{* *! version 1.0.1 5jul2011}{...}
{cmd:help orderm}{right: ({browse "http://www.stata-journal.com/article.html?article=st0270":SJ12-3: st0270})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:orderm} {hline 2}}Order-m efficiency analysis{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:orderm}
{it:{help varlist:varlist1}} {cmd:=} {it:{help varlist:varlist2}} {ifin}
[{cmd:,} {it:options}]

{pstd}
where {it:varlist1} specifies inputs to production and {it:varlist2} specifies
outputs from production.  Both lists of variables must be mutually exclusive.
At least one input variable and one output variable are required.  Any variable
in {it:varlist1} and {it:varlist2} needs to be numeric and strictly
positive.  DMUs with missing or nonpositive values in any input variable or
output variable are dropped.

{synoptset 20}{...}
{synopthdr :options}
{synoptline}
{synopt :{opth dmu(varname)}}identifier; default is observation number {it:_n}{p_end}
{synopt :{cmd:ort(}{cmdab:i:nput}|{cmdab:o:utput}{cmd:)}}consider {cmd:input} or {cmd:output} efficiency; default is {cmd:ort(input)}{p_end}
{synopt :{opt m(#)}}set size of reference sample; default is {opt m}[ceil{c -(}{it:N}^(2/3){c )-}]{p_end}
{synopt :{opt d:raws(#)}}set number of resampling replications; default is {cmd:draws(200)}{p_end}
{synopt :{opt boot:strap}}perform bootstrap using 50 replications{p_end}
{synopt :{opt reps(#)}}perform bootstrap using {it:#} replications{p_end}
{synopt :{opt tun:e(#)}}set tuning parameter for subsampling bootstrap; values within the [0.5,1] interval are allowed{p_end}
{synopt :{opt lev:el(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{cmdab:tab:le(}{cmdab:f:ull}|{cmdab:s:cores}{cmd:)}}display table of results{p_end}
{synopt :{cmdab:dot:s(1}|{cmd:2)}}display replication and loop dots{p_end}
{synopt :{opt inv:ert}}report reciprocal of output-oriented efficiency scores{p_end}
{synopt :{opt gen:erate(newvarlist)}}supply names of new variables containing efficiency scores, ranks, and a pseudo-reference DMU{p_end}
{synopt :{opt repl:ace}}replace existing variables in {it:newvarlist}{p_end}
{synopt :{opt nog:enerate}}do not create new variables containing results{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{cmd:bootstrap}, {cmd:by}, and {cmd:svy} are not allowed; see {help prefix}.{p_end}


{title:Description}

{pstd}{cmd:orderm} computes nonparametric order-m efficiency scores for
decision-making units (DMUs) as proposed by Daraio and Simar (2007, 72).
Order-m efficiency (Cazals, Florens, and Simar 2002) generalizes the
free disposal hull (FDH) approach to efficiency measurement (Deprins,
Simar, and Tulkens 1984).  For {opt m(#)} approaching infinity,
{cmd:orderm} coincides with FDH.  Unlike FDH, which envelops all data
points by a nonconvex production-possibility frontier, {cmd:orderm} is a
partial frontier approach that allows for superefficient units located
beyond the estimated frontier.  Rather than performing FDH efficiency
analysis using the entire sample as reference, {cmd:orderm} uses
artificial reference samples of size {opt m(#)}, which are randomly
drawn with replacement from the peer DMU in the original data.  Drawing
the artificial sample is repeated {opt draws(#)} times, and order-m
efficiency scores are estimated as averages of FDH-like efficiency
scores.  Depending on the composition of the artificial reference
sample, a DMU may or may not serve as its own reference.  This -- unlike
FHD, where a DMU is always available as its own peer -- allows for a
superefficient DMU: (input-oriented) efficiency scores may exceed the
value of 1.  The number of DMUs is limited to the value of 
{helpb matsize}; for large values of {opt m(#)} or if bootstrapping is
specified, the maximum allowed sample size may be smaller than this.


{marker options}{...}
{title:Options}

{phang}{opt dmu(varname)} specifies an identifier for the considered
DMUs.  {it:varname} must uniquely identify DMUs. It may be either a
numeric or a string variable.  If no identifier is specified, the
observation number {it:_n} is used.  To make estimation results easily
accessible and result tables informative, one should choose an
informative variable name such as the real names of the DMUs.

{phang}{cmd:ort(input}|{cmd:output)} specifies whether {cmd:input} or
{cmd:output} efficiency is computed.  The default is {cmd:ort(input)}.
For the former, inefficiency is defined in terms of possible
proportional reduction in input consumption.  For the latter,
inefficiency is defined in terms of possible proportional increase in
output generation.  For {cmd:ort(input)}, efficiency scores are smaller
than 1 for inefficient DMUs; for {cmd:ort(output)}, efficiency scores
are greater than 1 for inefficient DMUs unless the {cmd:invert} option
is specified.  Efficient DMUs in either case are indicated by efficiency
scores taking the value of 1.  Superefficient DMUs located beyond the
estimated production-possibility frontier exhibit input-oriented
efficiency greater than 1 and output-oriented efficiency smaller than
unity.

{phang}{opt m(#)} specifies the size of the artificial reference sample.
The default is {cmd:m(}ceil{c -(}N^(2/3){c )-}{cmd:)}.  Noninteger and
nonpositive values are not allowed.  Most applications choose values
substantially smaller than N.  Note: Even for {cmd:m(}{it:N}{cmd:)},
{cmd:orderm} does not yield results for FDH efficiency analysis.  This
requires {cmd:m()} to approach infinity.  Yet rather than choosing a
very large value for {opt m()}, one can carry out FDH efficiency
analysis more efficiently by using {helpb orderalpha:orderalpha}.

{phang}{opt draws(#)} specifies the number of resampling replications.
The default is {cmd:draws(200)}, as suggested by Daraio and Simar
(2007).  Yet depending on the data, making estimated efficiency scores
converge may require values that substantially exceed the default.
Noninteger and nonpositive values are not allowed.

{phang}{opt bootstrap} invokes bootstrapping using 50 replications.
Unless standard errors are definitely required, users are strongly
advised not to request bootstrapping for large (and even moderately
sized) samples.  Because of nested resampling, computing time required
by bootstrapping may become excessive.  One may also consider 
{helpb orderalpha:orderalpha} as an alternative.  If neither
{cmd:bootstrap} nor {opt reps()} is specified, {cmd:orderm} does not
compute standard errors for the estimated efficiency scores.  The
bootstrap will fail in determining nonzero standard errors for a DMU for
which no peers are available in the sample apart from the DMU itself.

{phang}{opt reps(#)} is equivalent to option {opt bootstrap} except it
allows for choosing the number of bootstrap replications.

{phang}{opt tune(#)} determines the size of the bootstrap samples as
int(N^{it:#}).  Values within the [0.5,1] interval are allowed.
Subsampling is applied to account for the naive bootstrap being
inconsistent in a boundary estimation framework.  The boundary nature of
the estimation problem vanishes as {opt m()} departs from infinity.  For
small values of {opt m()}, one may apply the naive bootstrap,
{cmd:tune(1)}.  The default is 
{cmd:tune(}{c -(}2+exp(-m/N){c )-}/3{cmd:)}, which is equal to 2/3 for FDH.

{phang}{opt level(#)}
specifies the confidence level, as a percentage, for confidence intervals.
The default is {cmd:level(95)} or as set by {helpb set level}.

{phang}{cmd:table(full}|{cmd:scores)} invokes the display of a results
table.  For {cmd:table(scores)}, estimated efficiency scores are
displayed as if they were regression coefficients.  For
{cmd:table(full)}, efficiency ranks and pseudo-reference DMUs are also
displayed. {cmd:orderm} may generate a huge table because N scores are
computed. For this reason, suppressing table display is the default.
{cmd:table(full)} is not allowed for N > 2994 and cannot be redisplayed
by typing {cmd:orderm} without arguments.

{phang}{cmd:dots(1}|{cmd:2)} invokes a display of replication dots and
loop dots.  For {cmd:dots(1)}, one dot character is displayed for each
bootstrap replication.  For {cmd:dots(2)}, one dot character is also
displayed for each DMU being analyzed.  Type {cmd:2} dots are not
displayed during bootstrap replications.

{phang}{cmd:invert} enables output-oriented efficiency to be reported
analogously to input-oriented efficiency by taking the reciprocal: with
{cmd:invert} specified, inefficient DMUs exhibit efficiency scores
smaller than 1, regardless of how {cmd:ort()} is specified.
{cmd:invert} has no effect on input-oriented efficiency.

{phang}{opt generate(newvarlist)} specifies the names of new variables
containing estimation results.  {it:newvarlist} may consist of up to
three names.  {it:newvar1} denotes estimated efficiency scores,
{it:newvar2} denotes efficiency ranks, and {it:newvar3} denotes the name
of the pseudo-reference DMU.  If -- because of ties in the data -- more
than one pseudo-reference DMU is identified for some DMUs, further
variables {it:newvar3_2}, {it:newvar3_3}, ... are created.  If 
{opt generate(newvarlist)} is not specified or fewer than three names
are assigned, the default names are {cmd:_om_ort_m},
{cmd:_omrank_ort_m}, and {cmd:_omref_ort_m}.

{phang}{cmd:replace} specifies that existing variables named
{it:newvar1}, {it:newvar2}, or {it:newvar3} be replaced.

{phang}{cmd:nogenerate} specifies that results not be saved to new
variables.


{title:Examples}

{pstd}Order {cmd:m(25)} output-oriented efficiency{p_end}
{phang2}{cmd:. orderm firm capital labor energy = durables perishables, ort(output) m(25) generate(effi rank ref)}{p_end}

{pstd}Order {cmd:m(10)} input-oriented efficiency with bootstrap{p_end}
{phang2}{cmd:. orderm firm capital labor energy = durables perishables, m(10) reps(50) dots(2) generate(effi rank ref) replace}{p_end}

{pstd}After {cmd:orderm} with bootstrapping, Stata's testing routines can be used as usual{p_end}
{phang2}{cmd:. test _b[firm:Boogle]-_b[firm:Macrosoft]=0}{p_end}


{title:Saved results}

{pstd}
{cmd:orderm} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(m)}}value of {opt m()}{p_end}
{synopt:{cmd:e(draws)}}value of {opt draws()}{p_end}
{synopt:{cmd:e(inputs)}}number of inputs{p_end}
{synopt:{cmd:e(outputs)}}number of outputs{p_end}
{synopt:{cmd:e(efficient)}}share of efficient DMUs{p_end}
{synopt:{cmd:e(super)}}share of superefficient DMUs{p_end}
{synopt:{cmd:e(mean_e)}}mean estimated efficiency{p_end}
{synopt:{cmd:e(med_e)}}median estimated efficiency{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:orderm}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(title)}}{cmd:Order-m efficiency analysis}{p_end}
{synopt:{cmd:e(dmuid)}}{it:varname} (name of DMU identifier){p_end}
{synopt:{cmd:e(model)}}{cmd:Order-m}{p_end}
{synopt:{cmd:e(saved)}}names of new variables (not for option {opt nogenerate}){p_end}
{synopt:{cmd:e(table)}}{cmd:scores}, {cmd:full}, or {cmd:no}{p_end}
{synopt:{cmd:e(invert)}}either {opt inverted} or {opt notinverted} (not saved for {cmd:ort(input)}){p_end}
{synopt:{cmd:e(ort)}}either {opt input} or {opt output}{p_end}
{synopt:{cmd:e(outputlist)}}{it:varlist2} (list of outputs){p_end}
{synopt:{cmd:e(inputlist)}}{it:varlist1} (list of inputs){p_end}
{synopt:{cmd:e(properties)}}{opt b V}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(ranks)}}vector of efficiency ranks ({it:colnames} are of the form {it: varname:value_of_varname}){p_end}
{synopt:{cmd:e(reference)}}matrix of pseudo-reference DMUs (not if {it:varname} is string variable){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{pstd}
Further results are saved in {cmd:e()} if the option {cmd:bootstrap} or
{cmd:reps()} is specified:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N_reps)}}number of bootstrap replications{p_end}
{synopt:{cmd:e(tune)}}value of tuning parameter{p_end}
{synopt:{cmd:e(N_bs)}}size of bootstrap samples{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(vce)}}{cmd:bootstrap}{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:Bootstrap}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(bias)}}estimated biases{p_end}
{synopt:{cmd:e(reps)}}number of nonmissing results{p_end}
{synopt:{cmd:e(b_bs)}}bootstrap estimates{p_end}


{title:Acknowledgments}

{pstd}
This work has been supported in part by the Collaborative Research
Center "Statistical Modelling of Nonlinear Dynamic Processes" (SFB 823)
of the German Research Foundation (DFG).


{title:References}

{phang}
Cazals, C., J.-P. Florens, and L. Simar.  2002.
Nonparametric frontier estimation: A robust approach.
{it:Journal of Econometrics} 106: 1-25.

{phang}
Daraio, C., and L. Simar.  2007.
{it:Advanced Robust and Nonparametric Methods in Efficiency Analysis: Methodology and Applications}.
New York: Springer.

{phang}
Deprins, D., L. Simar, and H. Tulkens.  1984.  Measuring labor-efficiency in
post offices.  In
{it:The Performance of Public Enterprises: Concepts and Measurement},
ed. M. Marchand, P. Pestieau, and H. Tulkens, 243-267. Amsterdam:
North-Holland.


{title:Author}

{pstd}Harald Tauchmann{p_end}
{pstd}Rheinisch-Westf{c a:}lisches Institut f{c u:}r Wirtschaftsforschung (RWI)
{p_end}
{pstd}and CINCH (Centre of Health Economics Research){p_end}
{pstd}Essen, Germany{p_end}
{pstd}harald.tauchmann@rwi-essen.de{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 12, number 3: {browse "http://www.stata-journal.com/article.html?article=st0270":st0270}

{p 5 14 2}Manual:  {manlink R frontier}

{p 7 14 2}Help:  {manhelp frontier R}, {helpb dea}, {helpb orderalpha} (if installed){p_end}
