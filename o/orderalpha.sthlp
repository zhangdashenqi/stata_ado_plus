{smcl}
{* *! version 1.0  3mar2011}{...}
{cmd:help orderalpha}{right: ({browse "http://www.stata-journal.com/article.html?article=st0270":SJ12-3: st0270})}
{hline}

{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{hi:orderalpha} {hline 2}}Order-alpha efficiency analysis{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:orderalpha}
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
{synopt :{opt alp:ha(#)}}set benchmark percentile; default is {cmd:alpha(100)}{p_end}
{synopt :{opt boot:strap}}perform bootstrap using 100 replications{p_end}
{synopt :{opt reps:(#)}}perform bootstrap using {it:#} replications{p_end}
{synopt :{opt tun:e(#)}}set tuning parameter for subsampling bootstrap; values within the [0.5,1] interval are allowed{p_end}
{synopt :{opt lev:el(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{cmdab:tab:le(}{cmdab:f:ull}|{cmdab:s:cores}{cmd:)}}display table of results{p_end}
{synopt :{cmdab:dot:s(}{cmd:1}|{cmd:2)}}display replication and loop dots{p_end}
{synopt :{opt inv:ert}}report reciprocal of output-oriented efficiency scores{p_end}
{synopt :{opt gen:erate(newvarlist)}}supply names of new variables containing efficiency scores, ranks, and a reference DMU{p_end}
{synopt :{opt repl:ace}}replace existing variables in {it:newvarlist}{p_end}
{synopt :{opt nog:enerate}}do not create new variables containing results{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{cmd:bootstrap}, {cmd:by}, and {cmd:svy} are not allowed; see {help prefix}.{p_end}


{title:Description}

{pstd}{cmd:orderalpha} computes nonparametric order-alpha efficiency
scores for decision-making units (DMUs) as proposed by Daraio and Simar
(2007, 74).  Order-alpha efficiency (Aragon, Daouia, and Thomas-Agnan
2005) generalizes the free disposal hull (FDH) approach to efficiency
measurement (Deprins, Simar, and Tulkens 1984), which for
{cmd:alpha(100)} represents a special case of {cmd:orderalpha}.  Unlike
FDH, which envelops all data points by a nonconvex
production-possibility frontier, {cmd:orderalpha} is a partial frontier
approach that allows for superefficient units located beyond the
estimated frontier.  For example, for {cmd:ort(input)}, rather than
using minimum input consumption -- among DMUs that produce at least as
much output -- as the benchmark, {cmd:orderalpha} uses the (100 -
{it:alpha})th percentile.  For {cmd:ort(output)}, the benchmark is the
{it:alpha}th percentile of output generation among DMUs that use equal
or less input.  The number of DMUs is limited to the value of 
{helpb matsize}.


{marker options}{...}
{title:Options}

{phang}{opt dmu(varname)} specifies an identifier for the considered
DMUs.  {it:varname} must uniquely identify DMUs.  It may be either a
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

{phang}{opt alpha(#)} specifies the {it:#}th percentile as benchmark.
The default is {cmd:alpha(100)}, that is, FDH.  Specified values smaller
than unity are still interpreted in terms of percentiles, not quantiles.
Values outside (0,100] are not allowed.

{phang}{cmd:bootstrap} invokes bootstrapping using 100 replications.  If
neither {cmd:bootstrap} nor {opt reps()} is specified, {cmd:orderalpha}
does not compute standard errors for the estimated efficiency scores.
The bootstrap will fail in determining nonzero standard errors for DMUs
for which no (or only few) peers are available in the sample apart from
the DMU itself.  For large samples, bootstrapping generates a huge N x N
variance-covariance matrix and requires substantial computing time,
which quadratically increases in N.

{phang}{opt reps(#)} is equivalent to option {opt bootstrap}, except it
allows for choosing the number of bootstrap replications.

{phang}{opt tune(#)} determines the size of the bootstrap samples as
int(N^{it:#}).  Values within the [0.5,1] interval are allowed.
Subsampling is applied to account for the naive bootstrap being
inconsistent in a boundary estimation framework.  The boundary nature of
the estimation problem vanishes as {opt alpha()} departs from 100.  For
values of {opt alpha()} substantially smaller than 100, one may apply
the naive bootstrap, {cmd:tune(1)}.  For FDH, the specified value should
be smaller than unity.  The default is 
{cmd:tune(}{c -(}1+exp(50-alpha/2){c )-}/{c -(}2+exp(50-alpha/2){c )-}{cmd:)}.  
This is equal to 2/3 for FDH.

{phang}
{opt level(#)}
specifies the confidence level, as a percentage, for confidence intervals.
The default is {cmd:level(95)} or as set by {helpb set level}.

{phang}{cmd:table(full}|{cmd:scores)} invokes the display of a results
table.  For {cmd:table(scores)}, estimated efficiency scores are
displayed as if they were regression coefficients.  For
{cmd:table(full)}, efficiency ranks and reference DMUs are also
displayed.  Displayed results are sorted by the values of {it:varname}.
{cmd:orderalpha} may generate a huge table because N scores are
computed.  For this reason, suppressing table display is the default.
{cmd:table(full)} is not allowed for N > 2994 and cannot be redisplayed
by typing {cmd:orderalpha} without arguments.

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
{it:newvar2} denotes efficiency ranks, and {it:newvar3} denotes the
reference DMU.  If -- because of ties in the data -- more than one
reference DMU is identified for some DMUs, further variables
{it:newvar3}_2, {it:newvar3}_3, ... are created.  If {cmd:generate()} is
not specified or fewer than three names are assigned, the default names
are {cmd:_oa_ort_alpha}, {cmd:_oarank_ort_alpha}, and
{cmd:_oaref_ort_alpha}.  For FDH, the default names are {cmd:_fdh_ort},
{cmd:_fdhrank_ort}, and {cmd:_fdhref_ort}.

{phang}{cmd:replace} specifies that existing variables named
{it:newvar1}, {it:newvar2}, or {it:newvar3} be replaced.

{phang}{cmd:nogenerate} specifies that results not be saved to new
variables.


{title:Examples}

{pstd}FDH input-oriented efficiency{p_end}
{phang2}{cmd:. orderalpha capital labor energy = durables perishables}{p_end}

{pstd}Order {cmd:alpha(95)} output-oriented efficiency{p_end}
{phang2}{cmd:. orderalpha capital labor energy = durables perishables, dmu(firm) ort(output) alpha(95) generate(effi rank ref)}{p_end}

{pstd}Order {cmd:alpha(90)} input-oriented efficiency with bootstrap{p_end}
{phang2}{cmd:. orderalpha capital labor energy = durables perishables, dmu(firm) alpha(90) reps(250) dots(2) generate(effi rank ref) replace}{p_end}

{pstd}After {cmd:orderalpha} with bootstrapping, Stata's testing routines can be used as usual{p_end}
{phang2}{cmd:. test _b[firm:Boogle]-_b[firm:Macrosoft]=0}{p_end}


{title:Saved results}

{pstd}
{cmd:orderalpha} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(alpha)}}value of {opt alpha()}{p_end}
{synopt:{cmd:e(inputs)}}number of inputs{p_end}
{synopt:{cmd:e(outputs)}}number of outputs{p_end}
{synopt:{cmd:e(efficient)}}share of efficient DMUs{p_end}
{synopt:{cmd:e(super)}}share of superefficient DMUs{p_end}
{synopt:{cmd:e(mean_e)}}mean estimated efficiency{p_end}
{synopt:{cmd:e(med_e)}}median estimated efficiency{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:orderalpha}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(title)}}{cmd:Order-alpha efficiency analysis}{p_end}
{synopt:{cmd:e(dmuid)}}{it:varname} (name of DMU identifier){p_end}
{synopt:{cmd:e(model)}}either {cmd:Order-alpha} or {cmd:FDH}{p_end}
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
{synopt:{cmd:e(ranks)}}vector of efficiency ranks {p_end}
{synopt:{cmd:e(reference)}}matrix of reference DMUs (not if {it:varname} is string variable){p_end}

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


{title:Acknowledgment}

{pstd}This work has been supported in part by the Collaborative Research
Center "Statistical Modelling of Nonlinear Dynamic Processes" (SFB 823)
of the German Research Foundation (DFG).


{title:References}

{phang}
Aragon, Y., A. Daouia, and C. Thomas-Agnan.  2005.  Nonparametric frontier
estimation: A conditional quantile-based approach. 
{it:Econometric Theory} 21: 358-389.

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

{p 7 14 2}Help:  {manhelp frontier R}, {helpb dea}, {helpb orderm} (if installed){p_end}
