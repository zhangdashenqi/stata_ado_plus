{smcl}
{* 08aug2016}{...}
{cmd:help lorenz}{right: ({browse "http://www.stata-journal.com/article.html?article=st0457":SJ16-4: st0457})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col:{cmd:lorenz} {hline 2}}Lorenz and concentration curves{p_end}


{title:Syntax}

{pstd}
Estimating Lorenz and concentration curves:

{p 8 15 2}
{cmd:lorenz} [{cmdab:e:stimate}] {varlist} {ifin} {weight}
[{cmd:,}
{help lorenz##estopt:{it:estimate_options}}]

{pstd}
Computing contrasts between outcome variables or subgroups:

{p 8 15 2}
{cmd:lorenz} {cmdab:c:ontrast} [{help lorenz##contrast:{it:base}}]
[{cmd:,}
{help lorenz##contopt:{it:contrast_options}}]

{p 8 8 2}
{it:base} is the name of the outcome variable or the value of the
subpopulation to be used as base.  {it:base} may also be {cmd:#1}, {cmd:#2},
or {cmd:#3}, etc., to refer to the 1st, 2nd, or 3rd, etc., outcome variable or
subpopulation.  See the {helpb lorenz##contrast:contrast()} option of
{cmd:lorenz estimate} for more details.

{pstd}
Drawing a line graph of the results:

{p 8 15 2}
{cmd:lorenz} {cmdab:g:raph}
[{cmd:,}
{help lorenz##grtopt:{it:graph_options}}]


{synoptset 22 tabbed}{...}
{marker estopt}{col 5}{help lorenz##estoptions:{it:estimate_options}}{col 29}Description
{synoptline}
{syntab :Main}
{synopt :{opt gap}}compute equality gap curves{p_end}
{synopt :{opt sum}}compute total (unnormalized) Lorenz curves{p_end}
{synopt :{opt general:ized}}compute generalized Lorenz curves{p_end}
{synopt :{opt abs:olute}}compute absolute Lorenz curves{p_end}
{synopt :{opt percent}}report Lorenz ordinates as percentages{p_end}
{synopt :{cmdab:norm:alize(}{help lorenz##normalize:{it:spec}}{cmd:)}}normalize
Lorenz curves with respect to the specified total{p_end}
{synopt :{opt gini}}also report Gini coefficients{p_end}

{syntab :Percentiles}
{synopt :{opt n:quantiles(#)}}use {it:#} equally spaced percentiles (plus an additional 
point at the origin); default is {cmd:nquantiles(20)}{p_end}
{synopt :{cmdab:p:ercentiles(}{help lorenz##percentiles:{it:numlist}}{cmd:)}}use 
percentiles corresponding to the specified percentages{p_end}
{synopt :{cmd:pvar(}{help varname:{it:pvar}}{cmd:)}}compute concentration curves 
with respect to {it:pvar}{p_end}
{synopt :{opt step}}determine Lorenz ordinates from step function; default is to use linear interpolation{p_end}

{syntab :Over}
{synopt :{opth over(varname)}}compute results for subpopulations defined by 
the values of {it:varname}{p_end}
{synopt :{opt t:otal}}include overall results across all subpopulations; only 
allowed with {cmd:over()}{p_end}

{syntab :Contrast/Graph}
{synopt :{cmdab:c:ontrast}[{cmd:(}{help lorenz##contrast:{it:spec}}{cmd:)}]}compute
differences in Lorenz curves between outcome variables or
subpopulations{p_end}
{synopt :{cmdab:g:raph}[{cmd:(}{help lorenz##gropt:{it:options}}{cmd:)}]}draw
line graph of the results; {it:options} are 
{help lorenz##gropt:{it:graph_options}} as described below{p_end}

{syntab :SE/SVY}
{synopt :{cmd:vce(}{help lorenz##vcetype:{it:vcetype}}{cmd:)}}{it:vcetype} may
be {cmd:analytic} (the default), {cmdab:cl:uster} {it:clustvar},
{cmdab:boot:strap}, or {cmdab:jack:knife}{p_end}
{synopt :{opt cl:uster(clustvar)}}synonym for 
{cmd:vce(cluster} {it:clustvar}{cmd:)}{p_end}
{synopt :{cmd:svy}[{cmd:(}{help lorenz##svy:{it:subpop}}{cmd:)}]}take account
of survey design as set by {helpb svyset}, optionally restricting
computations to {it:subpop}{p_end}
{synopt :{opt nose}}suppress computation of standard errors and confidence 
intervals (CIs){p_end}

{syntab :Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt nohe:ader}}suppress output header{p_end}
{synopt :{opt notab:le}}suppress output table{p_end}
{synopt :{opt nogtab:le}}suppress table of Gini coefficients{p_end}
{synopt :{help lorenz##displayopts:{it:display_options}}}standard
reporting options as described in 
{helpb estimation options:[R] estimation options}{p_end}
{synoptline}
{p 4 6 2}
{opt pweight}s, {opt fweight}s, and {opt iweight}s are allowed; see {help weight}.


{synoptset 22}{...}
{marker contopt}{col 5}{help lorenz##contoptions:{it:contrast_options}}{col 29}Description
{synoptline}
{synopt :{opt r:atio}}compute ratios instead of differences{p_end}
{synopt :{opt lnr:atio}}compute logarithms of ratios instead of differences{p_end}
{synopt :{cmdab:g:raph}[{cmd:(}{help lorenz##gropt:{it:options}}{cmd:)}]}draw
line graph of the results;  {it:options} are 
{help lorenz##gropt:{it:graph_options}} as described below{p_end}
{synopt :{help lorenz##displayopts:{it:display_options}}}standard 
reporting options as described in 
{helpb estimation options:[R] estimation options}{p_end}
{synoptline}


{synoptset 30 tabbed}{...}
{marker gropt}{col 5}{help lorenz##groptions:{it:graph_options}}{col 29}Description
{synoptline}
{syntab :Main}
{synopt :{opt prop:ortion}}population axis in proportion, not percent{p_end}
{synopt :{opt nodiag:onal}}omit the equal distribution diagonal{p_end}
{synopt :{cmdab:diag:onal(}{help line_options:{it:line_options}}{cmd:)}}affect rendition 
of the equal distribution diagonal{p_end}
{synopt :{cmd:keep(}{help lorenz##keep:{it:list}}{cmd:)}}select and order 
results to be included as subgraphs{p_end}
{synopt :{cmd:prange(}{it:min} {it:max}{cmd:)}}restrict range of percentiles 
to be included in the graph{p_end}
{synopt :{cmdab:g:ini(%}{help format:{it:fmt}}{cmd:)}}specify format for Gini
coefficients; default is {cmd:gini(%9.3g)}{p_end}
{synopt :{opt nog:ini}}omit Gini coefficients from subgraph labels{p_end}

{syntab :Labels/Rendering}
{synopt :{it:{help connect_options}}}affect rendition of the plotted lines{p_end}
{synopt :{cmdab:lab:els(}{help lorenz##labels:{cmd:"}{it:label1}{cmd:" "}{it:label2}{cmd:"} ...{cmd:)}}}specify 
custom labels for subgraphs{p_end}
{synopt :{cmdab:byopt:s(}{help by_option:{it:byopts}}{cmd:)}}specify how 
subgraphs are combined{p_end}
{synopt :{opt over:lay}}combine results in single graph instead of using 
subgraphs{p_end}
{synopt :{cmd:o}{it:#}{cmd:(}{help lorenz##oopts:{it:options}}{cmd:)}}affect rendition 
of {it:#}th plot; for use with {cmd:overlay}{p_end}

{syntab :Confidence intervals}
{synopt :{opt l:evel(#)}}set confidence level; not allowed if {cmd:ci()} is 
{cmd:bc}, {cmd:bca}, or {cmd:percentile}{p_end}
{synopt :{cmd:ci(}{help lorenz##citype:{it:citype}}{cmd:)}}choose type of 
bootstrap CI; {it:citype} may be {cmdab:nor:mal} (the default), {cmd:bc}, 
{cmd:bca}, or {cmdab:p:ercentile}{p_end}
{synopt :{cmdab:ciopt:s(}{help area_options:{it:area_options}}{cmd:)}}affect 
rendition of the plotted confidence areas; see {manhelp graph_twoway_rarea G-2:graph twoway rarea}{p_end}
{synopt :{opt noci}}omit CIs{p_end}

{syntab :Add plots}
{synopt :{opth "addplot(addplot_option:plot)"}}add other plots to the graph{p_end}

{syntab :Y axis, X axis, Title, Caption, Legend, Overall}
{synopt :{it:{help twoway_options}}}any options other than {cmd:by()} 
documented in {helpb twoway_options:[G-3] {it:twoway_options}}{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:lorenz estimate} computes Lorenz and concentration curves from
individual-level data.  The default is to compute standardized (relative)
Lorenz and concentration curves, but the command also supports generalized and
absolute Lorenz and concentration curves.  Furthermore, the command can
compute unnormalized Lorenz and concentration curves (such that the estimates
reflect cumulative totals) or Lorenz and concentration curves that are
normalized to a specified total.  The command supports variance estimation for
complex samples (for methodological details, see Jann [2016]).

{pstd}
Given the results from {cmd:lorenz estimate} for several outcome variables or
subpopulations, {cmd:lorenz contrast} computes differences in Lorenz and
concentration curves between outcome variables or subpopulations.

{pstd}
{cmd:lorenz graph} plots the results from {cmd:lorenz estimate} or
{cmd:lorenz} {cmd:contrast} as a line diagram.  It includes CIs as shaded
areas.

{pstd}
{cmd:lorenz} without arguments replays the previous results.  It can apply
reporting options.


{marker estoptions}{...}
{title:Options for lorenz estimate}

{dlgtab:Main}

{pstd}
Only one instance of {cmd:gap}, {cmd:sum}, {cmd:generalized}, or
{cmd:absolute} is allowed.

{phang2}
{cmd:gap} computes equality gap curves instead of relative Lorenz curves.
Equality gap curves are defined as EG(p) = p - L(p), where L(p) is the
ordinate of the (relative) Lorenz curve at percentile p.

{phang2}
{cmd:sum} computes total (unnormalized) Lorenz curves instead of relative
Lorenz curves.

{phang2}
{cmd:generalized} computes generalized Lorenz curves instead of relative
Lorenz curves.

{phang2}
{cmd:absolute} computes absolute Lorenz curves instead of relative Lorenz
curves.

{phang}
{cmd:percent} expresses results as percentages instead of proportions.
{cmd:percent} is not allowed in combination with {cmd:sum}, {cmd:generalized},
or {cmd:absolute}.

{marker normalize}{...}
{phang}
{cmd:normalize(}{it:spec}{cmd:)} normalizes Lorenz ordinates with respect to
the specified total (not allowed in combination with {cmd:sum},
{cmd:generalized}, or {cmd:absolute}).  {it:spec} is

            [{it:over}{cmd::}][{it:total}] [{cmd:,} {opt a:verage}]

{pmore}
where {it:over} may be

            {cmd:.}      the subpopulation at hand (the default)
            {it:#}      the subpopulation identified by value {it:#}
            {cmd:#}{it:#}     the {it:#}th subpopulation
            {cmdab:t:otal}  the total across all subpopulations

{pmore}
and {it:total} may be

            {cmd:.}        the total of the variable at hand (the default)
            {cmd:*}        the total of the sum across all analyzed outcome variables
            {varlist}  the total of the sum across the variables in {varlist}
            {it:#}        a total equal to {it:#}

{pmore}
{it:total} specifies the variables to compute the total or sets the total to a
fixed value.  If multiple variables are specified, it uses the total across
all specified variables ({varlist} may contain external variables that are not
among the list of analyzed outcome variables).  {it:over} selects the
reference population to compute the total; {it:over} is allowed only if you
specify the {cmd:over()} option (see below).  Suboption {cmd:average} accounts
for subpopulation sizes (sum of weights) so that the results are relative to
the average outcome in the reference population; this is relevant only if
{it:over} is present.

{phang}
{cmd:gini} reports the distributions' Gini coefficients (also known as
concentration indices if you specify {cmd:pvar()}) to be computed and reported
in a separate table.

{dlgtab:Percentiles}

{phang}
{opt nquantiles(#)} specifies the number of (equally spaced) percentiles used
to determine the Lorenz ordinates (plus an additional point at the origin).
The default is {cmd:nquantiles(20)}.  This is equivalent to typing
{cmd:percentiles(0(5)100)}.

{marker percentiles}{...}
{phang}
{opth percentiles(numlist)} specifies, as percentages, the percentiles to
compute the Lorenz ordinates.  The numbers in {it:numlist} must be within 0
and 100.  You may apply shorthand conventions as described in help 
{it:{help numlist}}.  For example, to compute Lorenz ordinates from 0 to 100%
in steps of 1 percentage point, type {cmd:percentiles(0(1)100)}.  The numbers
provided in {cmd:percentiles()} do not need to be equally spaced and do not
need to cover the whole distribution.  For example, to focus on the top 10%
and use an increased resolution for the top 1%, type 
{cmd:percentiles(90(1)98 99(0.1)100)}.

{phang}
{cmd:pvar(}{help varname:{it:pvar}}{cmd:)} computes concentration curves with
respect to variable {it:pvar}.  That is, it will determine the ordinates of
the curves from observations sorted in ascending order of {it:pvar} instead of
the outcome variable (and use average outcome values within ties of {it:pvar}).

{phang}
{opt step} determines the Lorenz ordinates from the step function of the
cumulative outcomes.  The default is to use linear interpolation in regions
where the step function is flat.

{dlgtab:Over}

{phang}
{opth over(varname)} repeats results for each subpopulation defined by the
values of {it:varname}.  Only one outcome variable is allowed if you specify
{cmd:over()}.

{phang}
{opt total} reports additional overall results across all subpopulations.
{cmd:total} is allowed only if you specify {cmd:over()}.

{dlgtab:Contrast/graph}

{marker contrast}{...}
{phang}
{cmd:contrast}[{cmd:(}{it:spec}{cmd:)}] computes differences in Lorenz
ordinates between outcome variables or between subpopulations.  {it:spec} is

	    [{it:base}] [{cmd:,} {cmdab:r:atio} {cmdab:lnr:atio}]

{pmore}
where {it:base} is the name of the outcome variable or the value of the
subpopulation used as the base for the contrasts.  If {it:base} is omitted,
{cmd:contrast()} computes adjacent contrasts across outcome variables or
subpopulations (or contrasts with respect to the total if total results across
subpopulations have been requested).

{pmore}
Use the suboption {cmd:ratio} to compute contrasts as ratios, or use the
suboption {cmd:lnratio} to compute contrasts as logarithms of ratios.  The
default is to compute contrasts as differences.

{pmore}
If you specify {cmd:over()} together with {cmd:total}, the default is to use
the overall total across subpopulations as base for the contrasts.  In all
other cases, the default is to compute adjacent contrasts (that is, using the
preceding outcome variable or subpopulation as base).  Alternatively, specify
{it:base} to select the base for the contrasts.

{pmore}
With multiple outcome variables, {it:base} is the name of the outcome variable
used as the base.  For example,

{phang2}
{cmd:. lorenz estimate y1990 y2000 y2010, contrast(y1990)}

{pmore}
computes differences in Lorenz curves with respect to {cmd:y1990}.  Likewise,
if you specify {cmd:over()}, {it:base} is the value of the subpopulation used
as the base.  For example,

{phang2}
{cmd:. lorenz estimate wage, over(race) contrast(1)}

{pmore}
computes differences with respect to {cmd:race}==1.  Alternatively, {it:base}
may also be {cmd:#1}, {cmd:#2}, {cmd:#3}, etc., to use the 1st, 2nd, 3rd,
etc., outcome variable or subpopulation as the base for the contrasts.  For
example,

{phang2}
{cmd:. lorenz estimate wage, over(race) contrast(#2)}

{pmore}
uses the second subpopulation as the base for the contrasts.

{phang}
{cmd:graph}[{cmd:(}{help lorenz##groptions:{it:options}}{cmd:)}] draws a line
graph of the results.  I describe {it:options} for 
{helpb lorenz##groptions:lorenz graph} below.

{dlgtab:SE/SVY}

{marker vcetype}{...}
{phang}
{opth vce(vcetype)} determines how to compute standard errors and CIs.
{it:vcetype} may be

	    {cmd:analytic}
            {cmd:cluster} {it:clustvar}
            {cmd:bootstrap} [{cmd:,} {help bootstrap:{it:bootstrap_options}}]
            {cmd:jackknife} [{cmd:,} {help jackknife:{it:jackknife_options}}]
    
{pmore}
The default is {cmd:vce(analytic)}, using approximate formulas for variance
estimation assuming independent data.  For clustered data, specify
{cmd:vce(cluster} {it:clustvar}{cmd:)}, where {it:clustvar} is the variable
identifying the clusters.  Methods and formulas are based on Binder and
Kovacevic (1995) and Kovacevic and Binder (1997).  For bootstrap and jackknife
estimation, see {manhelpi vce_option R}.  Variance estimation is not supported
if you specify {cmd:iweight}s or {cmd:fweight}s.

{phang}
{opt cluster(clustvar)} is a synonym for {cmd:vce(cluster}
{it:clustvar}{cmd:)}.

{marker svy}{...}
{phang}
{cmd:svy}[{cmd:(}{it:subpop}{cmd:)}] accounts for the survey design for
variance estimation.  Methods and formulas are based on Binder and Kovacevic
(1995).  The data need to be set up for survey estimation; see help 
{helpb svyset}.  Specify {it:subpop} to restrict survey estimation to a
subpopulation, where {it:subpop} is
 
	    [{varname}] [{it:{help if}}]

{pmore}
The subpopulation is defined by observations for which {it:varname}!=0 and for
which the {cmd:if} condition is met.  See {helpb svy} and 
{manlink SVY subpopulation estimation} for more information on subpopulation
estimation.

{pmore}
The {cmd:svy} option is allowed only if Taylor linearization is the variance
estimation method set by {helpb svyset} (the default).  For other variance
estimation methods, use the usual {helpb svy} prefix command.  For example,
type {cmd:svy brr: lorenz} ... to use balanced repeated-replication variance
estimation.  The {cmd:svy} option is available because {cmd:lorenz} does not
allow the {helpb svy} prefix for Taylor linearization.

{phang}
{opt nose} suppresses the computation of standard errors and CIs.  Use the
{cmd:nose} option to speed up computations, for example, when applying a
prefix command that uses replication techniques for variance estimation, such
as {helpb svy jackknife}.  You cannot use the {cmd:nose} option together with
{cmd:vce()}, {cmd:cluster()}, or {cmd:svy}.

{dlgtab:Reporting}

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for CIs.  The
default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{opt noheader} suppresses the output header; only the coefficient table is
displayed.

{phang}
{opt notable} suppresses the coefficient table.

{phang}
{opt nogtable} suppresses the table containing the Gini coefficients.

{marker displayopts}{...}
{phang}
{it:display_options} are standard reporting options such as {cmd:cformat()},
{cmd:pformat()}, {cmd:sformat()}, or {cmd:coeflegend}; see 
{helpb estimation options:[R] estimation options}.

{marker contoptions}
{title:Options for lorenz contrast}

{phang}
{cmd:ratio} causes contrasts to be reported as ratios.  The default is to
report contrasts as differences.

{phang}
{cmd:lnratio} causes contrasts to be reported as logarithms of ratios.  The
default is to report contrasts as differences.

{phang}
{cmd:graph}[{cmd:(}{help lorenz##groptions:{it:options}}{cmd:)}] draws a 
line graph of the results.  I describe {it:options} for
{helpb lorenz##groptions:lorenz graph} below.

{phang}
{it:display_options} are standard reporting options such as {cmd:cformat()},
{cmd:pformat()}, {cmd:sformat()}, or {cmd:coeflegend}; see 
{helpb estimation options:[R] estimation options}.

{marker groptions}
{title:Options for lorenz graph}

{dlgtab:Main}

{phang}
{opt proportion} scales the population axis as a proportions (0 to 1).  The
default is to scale the axis as a percentages (0 to 100).

{phang}
{opt nodiagonal} omits the equal distribution diagonal included by default for
graphing relative Lorenz or concentration curves.  There is no equal
distribution diagonal included for graphing equality gap curves, total,
generalized, and absolute Lorenz curves.  There is also no equal distribution
diagonal for graphing contrasts.

{marker diagonal}{...}
{phang}
{opt diagonal(line_options)} affects the rendition of the equal distribution
diagonal, and {it:line_options} are as described in 
{manhelpi line_options G-3}.

{marker keep}{...}
{phang}
{opt keep(list)} selects and orders the results to be included as subgraphs.
Use {cmd:keep()} if {cmd:lorenz estimate} has been applied to multiple outcome
variables or subpopulations.  For multiple outcome variables, {it:list} is a
list of the names of the outcome variables to be included.  Example:

{phang2}
{cmd:. lorenz estimate y1990 y2000 y2010}{p_end}
{phang2}
{cmd:. lorenz graph, keep(y2010 y1990)}

{pmore}
When you specify {cmd:over()} in {cmd:lorenz} {cmd:estimate}, {it:list} is a
list of the included subpopulation values.  {it:list} may also contain
{cmdab:t:otal} for the overall results (if overall results were requested).
Example:

{phang2}
{cmd:. lorenz estimate wage, over(race) total}{p_end}
{phang2}
{cmd:. lorenz graph, keep(total 1 2)}

{pmore}
Furthermore, {it:list} may contain elements such as {cmd:#1}, {cmd:#2},
{cmd:#3}, etc., to refer to the 1st, 2nd, 3rd, etc., outcome variable or
subpopulation.  Example:

{phang2}
{cmd:. lorenz estimate wage, over(race)}{p_end}
{phang2}
{cmd:. lorenz graph, keep(#1 #3)}

{phang}
{cmd:prange(}{it:min} {it:max}{cmd:)} restricts the range of the points to be
included in the graph.  It omits points whose abscissas lie outside {it:min}
and {it:max}.  {it:min} and {it:max} must be within [0,100].  For example, to
include only the upper half of the distribution, type {cmd:prange(50 100)}.

{phang}
{cmd:gini(%}{it:fmt}{cmd:)} sets the format for the Gini coefficients included
in the subgraph or legend labels; see {manhelp format D}.  The default is
{cmd:gini(%9.3g)}.  {cmd:gini()} includes Gini coefficients only if
information on Gini coefficients is available in the provided results (that
is, if you apply the {cmd:gini} option to {cmd:lorenz estimate}).

{phang}
{cmd:nogini} suppresses the Gini coefficients.  This is relevant only if you
specify the {cmd:gini} option when calling {cmd:lorenz estimate}.

{dlgtab:Labels/Rendering}

{phang}
{it:connect_options} affect the rendition of the plotted lines; see 
{manhelpi connect_options G-3}.

{marker labels}{...}
{phang}
{cmd:labels(}{cmd:"}{it:label1}{cmd:" "}{it:label2}{cmd:"} ...{cmd:)}
specifies custom labels for the included subgraphs.  The default is to use the
variable labels of the outcome variables or the value labels of the
subpopulations, respectively.  {it:labels} is a list of labels applied one by
one to the subgraphs.  Use quotes if a label contains spaces, for example,
{cmd:labels("label one" "label two"} ...{cmd:)}.  Type an empty string to use
the default label for a specific subgraph.  For example,
{cmd:labels("}{it:label1}{cmd:" "" "}{it:label3}{cmd:")} specifies custom
labels for the first and third subgraphs and uses default labels for the other
subgraphs.

{phang}
{opt byopts(byopts)} determines how subgraphs are combined; see
{helpb by_option:[G-3] {it:by_option}}.

{phang}
{cmd:overlay} includes results from multiple outcome variables or
subpopulations in the same plot instead of creating subgraphs.

{marker oopts}{...}
{phang}
{cmd:o}{it:#}{cmd:(}{it:options}{cmd:)} affects the rendition of the line of
the {it:#}th outcome variable or subpopulation if you specify {cmd:overlay}.
For example, type {cmd:o2(lwidth(*2))} to increase the line width for the
second outcome variable or subpopulation.  {it:options} are the following:

{p2colset 9 30 32 15}{...}
{p2col:{it:options}}Description{p_end}
{p2line}
{p2col:{it:{help connect_options}}}rendition of the plotted line{p_end}
{p2col:[{cmd:no}]{cmd:ci}}whether to draw the CI{p_end}
{p2col:{cmd:ciopts(}{help lorenz##ciopts:{it:area_options}}{cmd:)}}rendition of CI (see below){p_end}
{p2line}

{dlgtab:Confidence intervals}

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for CIs.  The
default is the level used for computing the {cmd:lorenz} {cmd:estimate}
results.  {cmd:level()} cannot be used together with {cmd:ci(bc)},
{cmd:ci(bca)}, or {cmd:ci(percentile)}.  To change the level for these CIs,
specify {cmd:level()} when computing the results.

{marker citype}{...}
{phang}
{opt ci(citype)} chooses the type of CI to be plotted for results that have
been computed using the bootstrap technique.  {it:citype} may be

{p2colset 9 25 27 30}{...}
{p2col:{it:citype}}Description{p_end}
{p2line}
{p2col:{cmdab:nor:mal}}normal-based CIs; the default{p_end}
{p2col:{cmd:bc}}bias-corrected (BC) CIs{p_end}
{p2col:{cmd:bca}}BC and accelerated CIs{p_end}
{p2col:{cmdab:p:ercentile}}percentile CIs{p_end}
{p2line}

{pmore}
{cmd:bca} is available only if you request BCa CIs when running {cmd:lorenz}
{cmd:estimate}.

{marker ciopts}{...}
{phang}
{opt ciopts(area_options)} affects the rendition of the plotted confidence
areas.  {it:area_options} are as described in 
{helpb area_options:[G-3] {it:area_options}}.

{phang}
{opt noci} omits CIs from the plot.

{dlgtab:Add plots}

{phang}
{opt addplot(plot)} adds other plots to the generated graph; see 
{manhelp addplot_option G-3:{it:addplot_option}}.

{dlgtab:Y axis, X axis, Title, Caption, Legend, Overall}

{phang}
{it:twoway_options} are general twoway options, other than {cmd:by()}, as
documented in {helpb twoway_options:[G-3] {it:twoway_options}}.


{title:Examples}

{phang}{bf:. {stata sysuse nlsw88}}{p_end}
{phang}{bf:. {stata lorenz estimate wage}}{p_end}
{phang}{bf:. {stata lorenz graph, aspectratio(1)}}{p_end}

{phang}{bf:. {stata lorenz estimate wage, over(union)}}{p_end}
{phang}{bf:. {stata lorenz graph, aspectratio(1) overlay}}{p_end}

{phang}{bf:. {stata lorenz estimate wage, over(union) generalized}}{p_end}
{phang}{bf:. {stata lorenz graph, overlay}}{p_end}

{phang}{bf:. {stata lorenz estimate wage, over(union) generalized contrast(1)}}{p_end}
{phang}{bf:. {stata lorenz graph, yline(0)}}{p_end}

{pstd}
For further examples, see Jann (2016).


{title:Stored results}

{pstd}
{cmd:lorenz estimate} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(N_over)}}number of subpopulations{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(ngrid)}}number of points in estimation grid{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(level)}}confidence level for CIs{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:lorenz}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}names of outcome variables{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V} or {cmd:b}{p_end}
{synopt:{cmd:e(pvar)}}name of variable specified in {cmd:pvar()}{p_end}
{synopt:{cmd:e(type)}}{cmd:gap}, {cmd:sum}, {cmd:generalized}, {cmd:absolute}, or empty{p_end}
{synopt:{cmd:e(percent)}}{cmd:percent} or empty{p_end}
{synopt:{cmd:e(norm)}}{it:#} or names of reference variables or empty{p_end}
{synopt:{cmd:e(normpop)}}{cmd:total} or {it:overvar} {cmd:=} {it:#} or empty{p_end}
{synopt:{cmd:e(normavg)}}{cmd:average} or empty{p_end}
{synopt:{cmd:e(percentiles)}}percentile thresholds{p_end}
{synopt:{cmd:e(step)}}{cmd:step} or empty{p_end}
{synopt:{cmd:e(gini)}}{cmd:gini} or empty{p_end}
{synopt:{cmd:e(over)}}name of {cmd:over()} variable{p_end}
{synopt:{cmd:e(over_namelist)}}values from {cmd:over()} variable{p_end}
{synopt:{cmd:e(over_labels)}}labels from {cmd:over()} variable{p_end}
{synopt:{cmd:e(total)}}{cmd:total} or empty{p_end}
{synopt:{cmd:e(contrast)}}{cmd:contrast} or empty{p_end}
{synopt:{cmd:e(baseval)}}{cmd:+} or value or name of base for contrasts{p_end}
{synopt:{cmd:e(ratio)}}{cmd:ratio} or empty{p_end}
{synopt:{cmd:e(lnratio)}}{cmd:lnratio} or empty{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}estimates (Lorenz ordinates){p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of estimates{p_end}
{synopt:{cmd:e(p)}}population percentages (Lorenz abscissas){p_end}
{synopt:{cmd:e(_N)}}numbers of observations in subpopulations{p_end}
{synopt:{cmd:e(G)}}Gini coefficients (if {cmd:gini} is specified){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}

{pstd}
If you specify the {cmd:svy} option, {cmd:e()} stores various additional
results as described in {helpb svy}.


{title:References}

{phang}
Binder, D. A., and M. S. Kovacevic. 1995. Estimating some measures of
income inequality from survey data: An application of the estimating
equations approach. {it:Survey Methodology} 21: 137-145.

{phang}
Jann, B. 2016. {browse "http://www.stata-journal.com/article.html?article=st0457":Estimating Lorenz and concentration curves}.
{it:Stata Journal} 16: 837-866.

{phang}
Kovacevic, M. S., and D. A. Binder. 1997. Variance estimation for
measures of income inequality and polarization -- The estimating
equations approach. {it:Journal of Official Statistics} 13: 41-58.


{title:Author}

{pstd}Ben Jann{p_end}
{pstd}University of Bern{p_end}
{pstd}Bern, Switzerland{p_end}
{pstd}ben.jann@soz.unibe.ch{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 16, number 4: {browse "http://www.stata-journal.com/article.html?article=st0457":st0457}

{p 7 14 2}Help:  {manhelp graph_twoway_line G-2:graph twoway line},
{helpb pshare}, {helpb svylorenz}, {helpb alorenz}, {helpb clorenz}, 
{helpb glcurve}, {helpb ldtest} (if installed){p_end}
