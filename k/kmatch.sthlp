{smcl}
{* 14jun2017}{...}
{hi:help kmatch}
{hline}

{title:Title}

{pstd}{hi:kmatch} {hline 2} Multivariate-distance and propensity-score matching


{title:Syntax}

{pstd}
    Multivariate-distance matching (MD matching)

{p 8 15 2}
    {cmd:kmatch md}
    {help varname:{it:tvar}} [{help varlist:{it:xvars}}]
    [{cmd:(}{help varlist:{it:ovars}} [{cmd:=} {help varlist:{it:avars}}]{cmd:)} ...]
    {ifin} {weight}
    [{cmd:,}
    {help kmatch##opt:{it:options}}
    ]

{pstd}
    Propensity-score matching (PS matching)

{p 8 15 2}
    {cmd:kmatch ps}
    {help varname:{it:tvar}} [{help varlist:{it:xvars}}]
    [{cmd:(}{help varlist:{it:ovars}} [{cmd:=} {help varlist:{it:avars}}]{cmd:)} ...]
    {ifin} {weight}
    [{cmd:,}
    {help kmatch##opt:{it:options}}
    ]

{pstd}
    {help varname:{it:tvar}} is the treatment variable; {help varlist:{it:xvars}}
    are covariates to be matched; {help varlist:{it:ovars}} are outcome
    variables; {help varlist:{it:avars}} are adjustment variables. Multiple
    outcome equations may be specified, but each outcome variable can only be
    specified once.

{pstd}
    Bandwidth selection plot

{p2colset 9 50 50 2}{...}
{p2col:{cmd:kmatch} {opt cv:plot} [{it:{help numlist}}] [, {help kmatch##cvplotopt:{it:cvplotopts}}]}(display
    MISE by evaluation points)

{pmore}
    where {it:{help numlist}} specifies the values of the over-groups to be included
    in the graph. The default is to include all over-groups.

{pstd}
    Balancing diagnostics

{p2colset 9 50 50 2}{...}
{p2col:{cmd:kmatch} {opt su:mmarize} [{varlist}] [, {help kmatch##sumopt:{it:sumopts}}]}(means
    and variances in raw and balanced data)

{p2col:{cmd:kmatch} {opt dens:ity} [{varlist}] [, {help kmatch##gropts:{it:gropts}}]}(kernel
    density plots for raw and balanced data)

{p2col:{cmd:kmatch} {opt cum:ul} [{varlist}] [, {help kmatch##gropts:{it:gropts}}]}(cumulative
    distribution plots for raw and balanced data)

{p2col:{cmd:kmatch box} [{varlist}] [, {help kmatch##gropts:{it:gropts}}]}(box plots
     for raw and balanced data)

{pstd}
    Common-support diagnostics

{p2colset 9 50 50 2}{...}
{p2col:{cmd:kmatch} {opt csu:mmarize} [{varlist}] [, {help kmatch##sumopt:{it:sumopts}}]}(common-support
    means and variances)

{p2col:{cmd:kmatch} {opt cdens:ity} [{varlist}] [, {help kmatch##gropts:{it:gropts}}]}(common-support
    kernel density plots)

{p2col:{cmd:kmatch} {opt ccum:ul} [{varlist}] [, {help kmatch##gropts:{it:gropts}}]}(common-support
    cumulative distribution plots)

{p2col:{cmd:kmatch cbox} [{varlist}] [, {help kmatch##gropts:{it:gropts}}]}(common-support
    box plots)


{synoptset 20 tabbed}{...}
{marker opt}{col 5}{help kmatch##opts:{it:options}}{col 27}Description
{synoptline}
{syntab :Main}
{synopt :{opt ridge}}use ridge matching instead of kernel matching
    {p_end}
{synopt :{opt nn}[{cmd:(}{it:#}{cmd:)}]}use nearest-neighbor matching instead of kernel matching
    {p_end}
{synopt :{cmdab:bw:idth(}{help kmatch##bwidth:{it:bwspec}}{cmd:)}}half-width of
    kernel/caliper for nn-matching
    {p_end}
{synopt :{opt sh:aredbwidth}}use same bandwidth/caliper for both matching directions
    {p_end}
{synopt :{cmdab:k:ernel(}{help kmatch##kernel:{it:kernel}}{cmd:)}}kernel
    function; default is {cmd:kernel(epan)}
    {p_end}
{synopt :{opth ematch(varlist)}}match exactly on the specified variables
    {p_end}
{synopt :{opth over(varname)}}compute results for subpopulations defined by the
    values of {it:varname}
    {p_end}
{synopt :{opt tval:ue(#)}}value of {it:tvar} that is the treatment; default is
    {cmd:tvalue(1)}
    {p_end}

{syntab :MD matching}
{synopt :{cmdab:m:etric(}{help kmatch##metric:{it:metric}}{cmd:)}}({cmd:kmatch md} only)
    distance metric for covariates
    {p_end}
{synopt :{opth psv:ars(varlist)}}({cmd:kmatch md} only) include propensity score
    from {it:varlist}
    {p_end}
{synopt :{opt psw:eight(#)}}({cmd:kmatch md} only) weight given to the propensity score
    {p_end}

{syntab :Propensity score}
{synopt :{opt pscmd(command)}}command used to estimate the propensity score;
    default is {helpb logit}
    {p_end}
{synopt :{opt psopt:s(options)}}options passed through to the propensity
    score estimation command
    {p_end}
{synopt :{opt pspr:edict(options)}}options passed through to {helpb predict};
    default is {cmd:pspredict(pr)}
    {p_end}
{synopt :{opth pscore(varname)}}variable providing the propensity score
    {p_end}
{synopt :{cmd:comsup(}{it:lb} [{it:ub}]{cmd:)}}restrict common support to
    propensity scores within [{it:lb}, {it:ub}]
    {p_end}

{syntab :Estimands}
{synopt :{opt ate}}average treatment effect; the default
        {p_end}
{synopt :{opt att}}average treatment effect on the treated
        {p_end}
{synopt :{opt atc}}average treatment effect on the untreated
        {p_end}
{synopt :{opt nate}}naive average treatment effect
        {p_end}
{synopt :{opt po}}potential outcome averages
        {p_end}

{syntab :SE/CI}
{synopt :{cmd:vce(}{help kmatch##vce:{it:vcetype}}{cmd:)}}{it:vcetype} may
    be {cmdab:boot:strap} or {cmdab:jack:knife}
    {p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}
    {p_end}

{syntab :Reporting}
{synopt :{opt noi:sily}}display auxiliary results
    {p_end}
{synopt :{opt nohe:ader}}suppress output header
    {p_end}
{synopt :{opt nomtab:le}}suppress matching statistics
    {p_end}
{synopt :{opt notab:le}}suppress coefficients table (treatment effects)
    {p_end}
{synopt :{help estimation options:{it:display_options}}}standard
    reporting options
    {p_end}

{syntab :Generate}
{synopt :{cmdab:gen:erate}[{cmd:(}{it:{help kmatch##gen:spec}}{cmd:)}]}generate variables
    containing matching results
    {p_end}
{synopt :{cmdab:dy}[{cmd:(}{it:{help kmatch##dy:spec}}{cmd:)}]}generate variables
    containing potential outcome differences
    {p_end}
{synopt :{opt replace}}allow overwriting existing variables
    {p_end}
{synoptline}

{synoptset 20 tabbed}{...}
{marker cvplotopt}{col 5}{help kmatch##cvplot:{it:cvplotopts}}{col 27}Description
{synoptline}
{synopt :{opt i:ndex}}display index using marker labels
    {p_end}
{synopt :{cmdab:r:ange(}{it:lb} [{it:ub}]{cmd:)}}restrict results to bandwidths within [{it:lb}, {it:ub}]
    {p_end}
{synopt :{opt not:reated}}omit results for treated
    {p_end}
{synopt :{opt nou:ntreated}}omit results for untreated
    {p_end}
{synopt :{it:{help scatter:scatter_options}}}any options allowed by
    {helpb graph twoway scatter} {p_end}
{synopt :{cmdab:comb:opts(}{help graph combine:{it:options}}{cmd:)}}options passed
    through to {helpb graph combine}
    {p_end}
{synopt :{opt ti:tles(strlist)}}titles for subgraphs
    {p_end}
{synoptline}

{synoptset 20 tabbed}{...}
{marker sumopt}{col 5}{help kmatch##sum:{it:sumopts}}{col 27}Description
{synoptline}
{synopt :{cmd:ate} | {cmd:att} | {cmd:atc}}report results corresponding to
    specified estimand
    {p_end}
{synopt :{opt meanonly}}suppress table reporting variances
    {p_end}
{synopt :{opt varonly}}suppress table reporting means
    {p_end}
{synopt :{opt sd}}report standard deviations instead of variances
    {p_end}
{synoptline}

{synoptset 20 tabbed}{...}
{marker gropts}{col 5}{help kmatch##gr:{it:gropts}}{col 27}Description
{synoptline}
{syntab :Common options}
{synopt :{cmd:ate} | {cmd:att} | {cmd:atc}}report results corresponding to
    specified estimand
    {p_end}
{synopt :{opth o:verlevels(numlist)}}report results for selected subpopulations
    {p_end}
{synopt :{cmdab:comb:opts(}{help graph combine:{it:options}}{cmd:)}}options passed
    through to {helpb graph combine}
    {p_end}
{synopt :{opt ti:tles(strlist)}}titles for subgraphs
    {p_end}
{synopt :{opt lab:els(strlist)}}(balancing plots only) subgraph labels for raw and
    matched samples
    {p_end}
{synopt :{cmdab:byopt:s(}{help by_option:{it:byopts}}{cmd:)}}(balancing plots
    only) options passed through to {cmd:by()}
    {p_end}
{synopt :{opt nom:atched}}(common-support plots only) omit results for matched observations
    {p_end}
{synopt :{opt nou:nmatched}}(common-support plots only) omit results for unmatched observations
    {p_end}
{synopt :{opt notot:al}}(common-support plots only) omit results for combined sample
    {p_end}

{syntab :All but box/cbox}
{synopt :{it:{help line:line_options}}}any options allowed by
    {helpb graph twoway line}
    {p_end}

{syntab :For box/cbox}
{synopt :{it:{help legend_options:legend_options}}}options controlling the
    legend
    {p_end}
{synopt :{it:{help graph_box##boxlook_options:boxlook_options}}}{cmd:graph box}
    options controlling the look of the boxes
    {p_end}
{synopt :{it:{help graph_box##axis_options:axis_options}}}{cmd:graph box}
    options controlling rendering of the y axis
    {p_end}
{synopt :{it:{help graph_box##title_and_other_options:other_options}}}{cmd:graph box}
    options controlling titles, added text, aspect ratio, etc.
    {p_end}

{syntab :For density/cdensity}
{synopt :{opt n(#)}}estimate density using # points; default is {cmd:n(512)}
    {p_end}
{synopt :{cmdab:bw:idth(}{it:#}|{it:{help kmatch##bwtype:type}}{cmd:)}}set bandwidth to {it:#} or
    specify automatic bandwidth selector
    {p_end}
{synopt :{opt adj:ust(#)}}scale bandwidth by {it:#}
    {p_end}
{synopt :{cmdab:a:daptive}[{cmd:(}{it:#}{cmd:)}]}use the adaptive
    kernel density estimator
    {p_end}
{synopt :{opt ll(#)}}value of lower boundary of the domain of the variable
    {p_end}
{synopt :{opt ul(#)}}value of upper boundary of the domain of the variable
    {p_end}
{synopt :{opt refl:ection} | {opt lc}}select the boundary correction technique;
    default is renormalization
    {p_end}
{synopt :{opt k:ernel(kernel)}}type of kernel function; see {helpb kdens}
    {p_end}
{synoptline}

{pstd}
    {cmd:pweight}s, {cmd:iweight}s, and {cmd:fweight}s are allowed; see help {help weight}.


{title:Description}

{pstd}
    {cmd:kmatch} matches treated and untreated observations with respect to
    covariates {it:xvars} and, if outcome variables {it:ovars} are provided,
    estimates treatment effects based on the matched observations. If
    {it:avars} is also specified, treatment effects estimation includes
    regression adjustment with respect to {it:avars} after matching
    (equivalent to the bias-correction proposed by Abadie and Imbens 2011).

{pstd}
    {cmd:kmatch md} applies multivariate-distance matching (Mahalanobis
    matching by default); {cmd:kmatch ps} applies propensity-score matching. By
    default, a kernel function will be used to determine and weight the
    matches (see, e.g., Heckman et al. 1998a, 1998b). Alternatively, if the
    {helpb kmatch##nn:nn()} option is specified, nearest-neighbor matching will
    be applied.

{pstd}
    For kernel matching, {cmd:kmatch} offers several methods for data-driven
    bandwidth selection; see the {helpb kmatch##bwidth:bwidth()} option. If
    cross-validation is employed, the {cmd:kmatch cvplot} command can be used
    to display a plot of the cross-validation results.

{pstd}
    After running {cmd:kmatch md} or {cmd:kmatch ps}, several commands for
    evaluating the balancing of the data are available. {cmd:kmatch summarize}
    reports means and variances of the covariates for the treated and the
    untreated in the raw and matched data. {cmd:kmatch density} displays kernel
    density estimates of the specified variable(s) before and after matching 
    (for {cmd:kmatch ps}, {cmd:kmatch density} displays the density of the 
    propensity score if no variables are specified). {cmd:kmatch cumul} and
    {cmd:kmatch box} are like {cmd:kmatch density}, but display cumulative
    distributions or box plots.

{pstd}
    Some observations may be excluded from a matching solution due
    to lack of common support. Such a restriction of the sample affects the
    generalizability of the obtained results. {cmd:kmatch} provides several
    commands to evaluate how the matched and the unmatched observations deviate
    from the overall sample. {cmd:kmatch csummarize} reports the means and
    variances of the covariates for the matched, the unmatched, and the overall
    sample. Likewise,
    {cmd:kmatch cdensity}, {cmd:kmatch ccumul}, and {cmd:kmatch cbox} display
    density estimates, cumulative distributions, and box plots.

{pstd}
    {cmd:kmatch density} and {cmd:kmatch cdensity} require {cmd:kdens} and {cmd:moremata}. See
    {net "describe kdens, from(http://fmwww.bc.edu/repec/bocode/k/)":{bf:ssc describe kdens}}
    and
    {net "describe moremata, from(http://fmwww.bc.edu/repec/bocode/m/)":{bf:ssc describe moremata}}.


{marker opts}{...}
{title:Options for kmatch md and kmatch ps}

{dlgtab:Main}

{phang}
    {opt ridge}[{cmd:(}{it:#}{cmd:)}] requests that ridge matching is used
    instead of standard kernel matching, where {it:#} is the ridge parameter
    (see Frölich 2004, 2005). Specifying {it:#} is not necessary
    as {cmd:kmatch} picks a parameter appropriate for the chosen kernel. However, 
    you can type {cmd:ridge(0)} if you want to apply standard local-linear 
    matching. 

{phang}
    {opt nn}[{cmd:(}{it:#}{cmd:)}] requests that nearest-neighbor matching
    (with replacement) is used instead of kernel matching or ridge matching,
    where {it:#} specifies the (minimum) number of matches per observation. The
    default is {cmd:nn(1)} (one-to-one matching with replacement).

{marker bwidth}{...}
{phang}
    {opt bwidth(bwspec)} specifies the half-width of the kernel for kernel and
    ridge matching or sets a caliper for nearest-neighbor matching. If the
    distance between two observations is larger (or, for kernel and ridge
    matching, larger-or-equal) than the specified bandwidth or caliper they are
    not considered as a (potential) match. For nearest-neighbor matching, the
    default is to allow all observations as potential matches regardless of
    distance. For kernel and ridge matching the default is to select a
    bandwidth based on the pair-matching algorithm described below. {it:bwspec}
    may be

{p 12 14 4}
            {it:{help numlist}}

{pmore}
    to provide a specific bandwidth or caliper. If multiple values are specified,
    different bandwidths are used for the different matching directions and over
    groups (each over group consumes one or two values depending on whether
    one-sided or two-sided matching has been requested and depending
    on whether {cmd:sharedbwidth} has been specified; values will be recycled
    if {it:{help numlist}} contains fewer values than matching directions
    times over groups). For kernel and ridge matching, {it:bwspec} may also be

{p 12 14 4}
            {cmd:pm} [{it:q} [{it:f}]] [{cmd:,} {opt qui:etly}]

{pmore}
    to select a bandwidth based on a pair-matching algorithm similar to the proposal by
    Huber et al. (2013, 2015). The algorithm sets the bandwidth to {it:f} times
    the {it:q}-quantile of the distribution of (non-zero) distances between
    observations in one-to-one matching (1-nearest-neighbor matching
    with replacement). Factor {it:f} defaults to 1.5, quantile {it:q} defaults
    to 0.90. Option {opt quietly} suppresses the output of the algorithm.
    Alternatively, for kernel and ridge matching, {it:bwspec} may be

{p 12 14 4}
            {cmd:cv} [{help varname:{it:cvvar}}] [{cmd:,}
            {opt w:eighted}
            {opt nop:enalty}
            {opt nol:imit}
            {opt q:uantile(#)}
            {opt f:actor(#)}
            {opt sf:actor(#)}
            {opt n(#)}
            {opt r:ange(lb ub)}
            {opth g:rid(numlist)}
            {opt exact}
            {opt qui:etly} ]

{pmore}
    to determine the bandwidth by cross-validation. If outcome variable
    {it:cvvar} is provided, cross-validation with respect to {it:cvvar} as
    suggested by Frölich (2004, 2005) is performed. If, in addition, option
    {cmd:weighted} is specified, weighted cross-validation with respect to
    {it:cvvar} as suggested by Galdo et al. (2008; Section 4.2) is
    performed. Deviating from the literature, a correction is applied for loss of
    observations if there is lack of common support. Specify option
    {cmd:nopenalty} to skip the correction. If {it:cvvar} is omitted,
    cross-validation is performed with respect to the mean of the propensity
    score (in case of {cmd:kmatch ps}) or the means of the covariates (in case
    of {cmd:kmatch md}). Option {cmd:nopenalty} has no effect in this 
    case. Occasionally, cross-validation can yield excessively large bandwidth 
    estimates. To limit such behavior, a penalty is applied to the cross-validation 
    criterion for bandwidths larger than the standard deviation of the 
    propensity score (in case of {cmd:kmatch ps}) or the square-root of the number
    of covariates (in case of {cmd:kmatch ps}). Specify option {cmd:nolimit}
    to omit the penalty.

{pmore}
    By default, the cross-validation search algorithm starts at the bandwidth
    determined by the pair-matching method described above and leaps up or down
    until a local minimum is encountered. The local minimum is then further
    refined until the maximum number of steps is reached. Options
    {cmd:quantile()} and {cmd:factor()} set the parameters for the initial
    pair-matching bandwidth (see above). Option {cmd:sfactor()} sets the
    relative step size for the first phase of the search algorithm. The default
    is 1.5, meaning that the bandwidth is either multiplied by 1.5 or divided by
    1.5 from one step to the next, depending on search direction. The default
    is to start the algorithm with a step up; set {cmd:sfactor()}
    to a value between 0 and 1 to start with a step down. Option {cmd:n()} 
    sets the total number of steps; default is 15. Alternatively, specify 
    {cmd:range()} to use an equally-spaced evaluation
    grid between {it:lb} and {it:ub}, or provide a custom evaluation grid using
    the {cmd:grid()} option. For ridge matching, cross-validation without 
    {it:cvvar} is only approximate for reasons of speed; specify option
    {cmd:exact} to request exact computations ({cmd:exact} has no effect
    if {it:cvvar} is provided). Furthermore, specify option
    {cmd:quietly} to suppress the output of the algorithm.

{phang}
    {opt sharedbwidth} requests that the same bandwidth is used for both matching 
    directions. By default, bandwidth search will be run separately for the treated
    and for the untreated. If {cmd:sharedbwidth} is specified, bandwidth search will
    be run jointly across both groups. Option {cmd:sharedbwidth} has no effect
    if only one matching direction has been requested.

{marker kernel}{...}
{phang}
    {opt kernel(kernel)} specifies the kernel
    function for kernel matching and ridge matching. {it:kernel} may be:

        {opt e:pan}        Epanechnikov kernel function; the default
        {opt r:ectangle}   rectangle kernel function
        {opt u:niform}     synonym for {cmd:rectangle}
        {opt t:riangle}    triangle kernel function
        {opt b:iweight}    biweight kernel function
        {opt triw:eight}   triweight kernel function
        {opt c:osine}      cosine trace kernel function
        {opt p:arzen}      Parzen kernel function

{pmore}
    All kernels are defined such that they have a support of +/- 1.

{phang}
    {opth ematch(varlist)} requests that the specified variables are matched
    exactly.

{phang}
    {opth over(varname)} computes results for each subpopulation defined
    by the values of {it:varname}. Matching is performed separately for each
    group.

{phang}
    {opt tvalue(#)} specifies the value of {it:tvar} that is the treatment. The
    default is {cmd:tvalue(1)}.

{dlgtab:MD matching}

{marker metric}{...}
{phang}
    {opt metric(metric)} specifies the scaling matrix used to compute the
    multivariate distances. Option {cmd:metric()} is only allowed for
    {cmd:kmatch md}. {it:metric} may be:

{p 12 14 4}
    {opt maha:lanobis} [{help numlist:{it:units}}] [, {opth w:eights(numlist)} ]
    {p_end}
{p 12 14 4}
    {opt ivar:iance} [{help numlist:{it:units}}] [, {opth w:eights(numlist)} ]
    {p_end}
{p 12 14 4}
    {opt eucl:idean}
    {p_end}
{p 12 14 4}
    {opt mat:rix} {help matrix:{it:matname}}
    {p_end}

{pmore}
    {cmd:mahalanobis} sets the scaling matrix to the sample covariate
    covariance matrix (separately for each over group). If {it:units} is
    provided, the matrix is transformed in a way such that its diagonal
    elements are equal to the squares of the specified values (while preserving
    the correlation structure). That is, if V is the sample covariance matrix
    and {it:sd} is the vector of sample standard deviations, the scaling matrix
    is defined as S = diag({it:units}:/{it:sd}) * V *
    diag({it:units}:/{it:sd}). The rational behind such a transformation is a
    follows. The Mahalanobis distance can be interpreted as measuring the
    distance between observations in terms of standard deviations of the
    covariates (while additionally taking into account the correlation
    structure). Instead of using standard deviations as relevant units, you may
    want to specify your own units. {it:units} must contain one value for each
    covariate (plus an additional value for the propensity score, if option
    {cmd:psvars()} or option {cmd:pscore()} has been specified). If option
    {cmd:weights()} is specified, the scaling matrix is defined as S =
    diag(1:/{it:w}) * V * diag(1:/{it:w}), where {it:w} is the vector of the specified
    weights (this is equivalent to reweighing as suggested by Greevy et al.
    2012). {it:w} must contain as many values as there are covariates. The
    default is to give each covariate a weight of one. If {cmd:psvars()} or
    {cmd:pscore()} has been specified, you can use option {cmd:psweight()} to
    assign a weight to the propensity score. If {cmd:psweight()} is omitted,
    the propensity score receives a weight of one. If both, {it:units} and
    weights, are provided, both transformations are applied.

{pmore}
    {cmd:ivariance} sets the scaling matrix to a diagonal matrix with the
    sample covariate variances on the diagonal (separately for each over
    group). Argument {it:units} and option {cmd:weights()} are as above.

{pmore}
    {cmd:euclidean} sets the scaling matrix to the identity matrix.

{pmore}
    {cmd:matrix} uses the provided matrix as scaling matrix.

{phang}
    {opth psvars(varlist)} specifies that the propensity score estimated from
    {it:varlist} is included as an additional variable
    in the computation of the distances. Option {cmd:psvars()} is only allowed for
    {cmd:kmatch md}. Only one of {cmd:psvars()} and {cmd:pscore()} is allowed.

{phang}
    {opt psweight(#)} specifies the weight given to the propensity score when
    computing distances; see the {cmd:metric()} option above. The
    default is {cmd:psweight(1)}. Option {cmd:psweight()} is only allowed for
    {cmd:kmatch md}.

{dlgtab:Propensity score}

{phang}
    {opt pscmd(command)} specifies the command used to estimate the propensity
    score. The the default command is {helpb logit}. For example, specify
    {cmd:pscmd(probit)} to use a {helpb probit} model.

{phang}
    {opt psopts(options)} provides options to be passed through to the
    propensity score estimation command.

{phang}
    {opt pspredict(options)} provides options to be passed through to the call
    to {helpb predict} that generates the propensity scores after model
    estimation. The default is {cmd:pspredict(pr)} so that probabilities are
    generated. For example, specify {cmd:pspredict(xb)} to use the liner
    predictor instead of probabilities. Options allowed in {opt pspredict()}
    depend on the command used for model estimation; see {cmd:pscmd()} above.

{phang}
    {opth pscore(varname)} provides a variable containing the propensity score.
    No propensity score model will be estimated in this case.

{phang}
    {cmd:comsup(}{it:lb} [{it:ub}]{cmd:)} restricts the range of observations
    that are treated as potential matches. Observations with a propensity
    score smaller than {it:lb} or, if {it:ub} is also specified, a propensity
    score larger than {it:ub} will not be matched.

{dlgtab:Estimands}

{phang}
    {opt ate} requests that average treatment effects are reported. This is
    the default unless {cmd:att} and/or {cmd:atc} is specified. If you want to
    report results for multiple estimands, type several of these options. The options also
    affect whether two-sided or only one-sided matching is performed. {cmd:ate}
    requires matching in both directions; {cmd:att} requires matching
    the treated; {cmd:atc} requires matching the untreated.

{phang}
    {opt att} requests that average treatment effects on the
    treated are reported.

{phang}
    {opt atc} requests that average treatment effects on the
    untreated are reported.

{phang}
    {opt nate} requests that naive average treatment effects
    (unconditional mean differences; without regression adjustment) are reported
    in addition to the matched treatment effects.

{phang}
    {opt po} requests that potential outcome averages are reported in addition
    to the treatment effects.

{dlgtab:SE/CI}

{marker vce}{...}
{phang}
    {opth vce(vcetype)} determines how standard errors and confidence intervals
    are computed. {it:vcetype} may be:

            {cmd:bootstrap} [{cmd:,} {help bootstrap:{it:bootstrap_options}}]
            {cmd:jackknife} [{cmd:,} {help jackknife:{it:jackknife_options}}]

{pmore}
    Note that the results computed by the {cmd:vce()} option may not be
    consistent for nearest-neighbor matching
    (see Abadie and Imbens 2008). Use official Stata's {helpb teffetcs nnmatch}
    to obtain reliable standard errors for nearest-neighbor matching.

{pmore}
    In case of kernel and Ridge matching with automatic bandwidth selection,
    the bandwidth is held fixed across bootstrap or jackknife
    replications. If you want to repeat bandwidth search in each
    replication, use the {helpb bootstrap} or {helpb jackknife} prefix
    command. In small samples it may happen that some estimates cannot be
    computed in a specific replication (for example, because the treatment
    does not vary). {cmd:kmatch} returns such estimates as 0 and sets
    {cmd:e(k_omit)} to the number of estimates that could not be
    computed. To prevent {helpb bootstrap} and {helpb jackknife}
    from using these estimates, add option {cmd:reject(e(k_omit))} to the
    {helpb bootstrap} or {helpb jackknife} command. That is, for example, type

            {cmd: bootstrap, reject(e(k_omit)): kmatch} {it:...}

{pmore}
    When using {cmd:bootstrap} or {cmd:jackknife} via the {cmd:vce()} option,
    such estimates are excluded automatically.

{phang}
    {opt level(#)} specifies the confidence level, as a percentage, for
    confidence intervals. The default is {cmd:level(95)} or as set by
    {helpb set level}.

{dlgtab:Reporting}

{phang}
    {opt noisily} displays auxiliary results such as the output from propensity
    score estimation or the output from regression adjustment.

{phang}
    {opt noheader} suppresses the output header.

{phang}
    {opt nomtable} suppress the table containing the matching statistics.

{phang}
    {opt notable} suppresses the coefficients table containing the
    treatment effects.

{phang}
    {it:display_options} are standard reporting options as described in
    {helpb estimation options:[R] estimation options}.

{dlgtab:Generate}

{marker gen}{...}
{phang}
    {opt generate}[{cmd:(}{it:spec}{cmd:)}] generates a number of variables
    containing the matching results. {it:spec} may either be
    {help newvarlist:{it:newvarlist}} to provide explicit names for the generated
    variables or {it:prefix}{cmd:*} to provide a prefix for the variable names.
    The default prefix is {cmd:_KM_}. The following variables will be generated:

            {cmd:_KM_treat}   treatment indicator
            {cmd:_KM_nc}      number of matched controls
            {cmd:_KM_nm}      number of times used as a match
            {cmd:_KM_mw}      matching weight
            {cmd:_KM_ps}      propensity score

{pmore}
    The last variable will only be generated for {cmd:kmatch ps} or if
    {cmd:psvars()} or {cmd:pscore()} is specified.

{marker dy}{...}
{phang}
    {opt dy}[{cmd:(}{it:spec}{cmd:)}] generates variables containing potential
    outcome differences. {it:spec} may either be
    {help newvarlist:{it:newvarlist}} to provide explicit names for the generated
    variables or {it:prefix}{cmd:*} to provide a prefix for the variable names.
    The variables will then be named as {it:prefix}{it:ovar}, where {it:ovar}
    is the name of the outcome variable. The default prefix is {cmd:_DY_}. If
    regression adjustment is applied, potential outcomes will be computed as
    predictions from the regression adjustment equation plus the residuals from
    a regression of the unadjusted potential outcomes on the adjustment
    variables.

{phang}
    {opt replace} allows {cmd:generate()} and {cmd:dy()} to overwrite existing variables.


{marker cvplot}{...}
{title:Options for kmatch cvplot}

{phang}
    {opt index} displays index numbers for the steps of the search algorithm
    as marker labels. Use {it:{help marker_label_options}} to change the position
    and style of the marker labels.

{phang}
    {opt range(lb ub)} restricts the displayed results to bandwidths within the
    specified range.

{phang}
    {opt notreated} omits the results of the bandwidth search for matching the
    treated and {opt nountreated} omits the results of the bandwidth search for
    matching the untreated. These options only have an effect if separate results
    for the treated and the untreated are available. Only one of 
    {cmd:notreated} and {cmd:nountreated} is allowed.

{phang}
    {it:{help scatter:scatter_options}} are any options allowed by
    {helpb graph twoway scatter}.

{phang}
    {cmd:combopts(}{help graph combine:{it:options}}{cmd:)} are options passed
    through to {helpb graph combine}. This is only relevant when plotting results from
    multiple over-groups.

{phang}
    {opt titles(strlist)} provides titles for the subgraphs. This is only
    relevant when plotting results from multiple over-groups. Enclose the
    titles in double quotes if they contain spaces, e.g.,
    {cmd:titels({bind:"Title 1"} {bind:"Title 2"} ...)}.


{marker sum}{...}
{title:Options for kmatch summarize and kmatch csummarize}

{phang}
    {cmd:ate}, {cmd:att}, and {cmd:atc} select the results to be reported. Only
    one of {cmd:ate}, {cmd:att}, and {cmd:atc} is allowed. {cmd:ate} reports
    results corresponding to the ATE; {cmd:att} reports results corresponding
    to the ATT; {cmd:atc} reports results corresponding to the ATC. Whether a
    specific option is allowed depends context.

{phang}
    {opt meanonly} suppresses the table containing variances.

{phang}
    {opt varonly} suppress the table containing means.

{phang}
    {opt sd} reports standard deviations instead of variances.

{marker gr}{...}
{title:Options for balancing plots and common-support plots}

{dlgtab:Common options}

{phang}
    {cmd:ate}, {cmd:att}, and {cmd:atc} select the results to be reported. Only
    one of {cmd:ate}, {cmd:att}, and {cmd:atc} is allowed. {cmd:ate} reports
    results corresponding to the ATE; {cmd:att} reports results corresponding
    to the ATT; {cmd:atc} reports results corresponding to the ATC. Whether a
    specific option is allowed depends context.

{phang}
    {opth overlevels(numlist)} specifies the values of the over-groups
    to be included in the graph. The default is to include all over-groups.

{phang}
    {cmd:combopts(}{help graph combine:{it:options}}{cmd:)} are options passed
    through to {helpb graph combine}. This is only relevant when plotting results from
    multiple over-groups.

{phang}
    {opt titles(strlist)} provides titles for the subgraphs. This is only
    relevant when plotting results from multiple over-groups. Enclose the
    titles in double quotes if they contain spaces, e.g.,
    {cmd:titels({bind:"Title 1"} {bind:"Title 2"} ...)}.

{phang}
    {opt labels(strlist)} specifies labels for the subgraphs by raw and
    matched samples. The default is {cmd:labels("Raw" "Matched")}. Option
    {cmd:labels()} is only allowed for balancing plots.

{phang}
    {cmdab:byopts(}{help by_option:{it:byopts}}{cmd:)}
    are options controlling how the subgraphs by raw and matched samples
    are combined. Option {cmd:byopts()} is only allowed for balancing plots.

{phang}
    {opt nomatched} omits the results for matched observations. Option
    {cmd:nomatched} is only allowed for common-support plots.

{phang}
    {opt nounmatched} omits the results for unmatched observations. Option
    {cmd:nounmatched} is only allowed for common-support plots.

{phang}
    {opt nototal} omits the results for the combined sample. Option
    {cmd:nototal} is only allowed for common-support plots.

{dlgtab:For all but kmatch box and kmatch cbox}

{phang}
    {it:{help line:line_options}} are any options allowed by
    {helpb graph twoway line}

{dlgtab:For kmatch box and kmatch cbox}

{phang}
    {it:{help legend_options:legend_options}} are options controlling the
    legend.

{phang}
    {it:{help graph_box##boxlook_options:boxlook_options}} are {helpb graph box}
    options controlling the look of the boxes.

{phang}
    {it:{help graph_box##axis_options:axis_options}} are {helpb graph box}
    options controlling the rendering of the y axis.

{phang}
    {it:{help graph_box##title_and_other_options:other_options}} are {helpb graph box}
    options controlling titles, added text, aspect ratio, etc.

{dlgtab:For kmatch density and kmatch cdensity}

{phang}
    {opt n(#)} specifies the number of evaluation points used to estimate the
    density. The default is {cmd:n(512)}.

{marker bwtype}{...}
{phang}
    {opt bw:idth(#|type)} sets the bandwidth to {it:#} or
    specifies the automatic bandwidth selector,
    where {it:type} is {cmdab:s:ilverman} (the default),
    {cmdab:n:ormalscale}, {cmdab:o:versmoothed}, {opt sj:pi}, or
    {cmdab:d:pi}[{cmd:(}{it:#}{cmd:)}]. See {helpb kdens} for details.

{phang}
    {opt adjust(#)} causes the bandwidth to be multiplied by
    {it:#}. Default is {cmd:adjust(1)}.

{phang}
    {cmd:adaptive}[{cmd:(}{it:#}{cmd:)}] causes the adaptive kernel density
    estimator to be used. See {helpb kdens} for details.

{phang}
    {opt ll(#)} and {opt ul(#)} specify the lower and upper boundary of the
    domain of the plotted variable. {cmd:ll()} must be lower than or equal to
    the minimum observed value; {cmd:ul()} must be larger than or equal to the
    maximum observed value. If plotting the propensity score, {cmd:ll()} and
    {cmd:ul()} will be set to 0 and 1.

{phang}
    {opt reflection} and {opt lc} select the boundary
    correction technique to be used for variables with bounded support. The default
    technique is renormalization. See {helpb kdens} for details.

{phang}
    {opt kernel(kernel)} specifies the kernel function. See {helpb kdens} for
    available kernels.


{title:Examples}

{pstd}
    Mahalanobis-distance kernel matching with post-estimation balancing statistics and plots

{p 8 12 2}. {stata webuse cattaneo2}{p_end}
{p 8 12 2}. {stata kmatch md mbsmoke mmarried mage fbaby medu (bweight), att}{p_end}
{p 8 12 2}. {stata kmatch summarize}{p_end}
{p 8 12 2}. {stata kmatch density mage}{p_end}
{p 8 12 2}. {stata kmatch cumul mage}{p_end}
{p 8 12 2}. {stata kmatch box mage}{p_end}

{pstd}
    Bootstrap standard errors

{p 8 12 2}. {stata kmatch md mbsmoke mmarried mage fbaby medu (bweight), att vce(boot)}{p_end}

{pstd}
    Mahalanobis-distance nearest-neighbor matching

{p 8 12 2}. {stata kmatch md mbsmoke mmarried mage fbaby medu (bweight), att nn(5)}{p_end}
{p 8 12 2}. {stata teffects nnmatch (bweight mmarried mage fbaby medu) (mbsmoke), atet nn(5)}{p_end}

{pstd}
    Propensity-score kernel matching

{p 8 12 2}. {stata kmatch ps mbsmoke mmarried mage fbaby medu (bweight), att}{p_end}

{pstd}
    Propensity-score ridge matching

{p 8 12 2}. {stata kmatch ps mbsmoke mmarried mage fbaby medu (bweight), att ridge}{p_end}

{pstd}
    Propensity-score kernel matching with bias-adjustment

{p 8 12 2}. {stata kmatch ps mbsmoke mmarried mage fbaby medu (bweight = mmarried mage fbaby medu), att}{p_end}

{pstd}
    Mahalanobis-distance kernel matching including doubly-weighted propensity score

{p 8 12 2}. {stata kmatch md mbsmoke mmarried mage fbaby medu (bweight), att psvars(fage fedu) psweight(2)}{p_end}

{pstd}
    Mahalanobis-distance kernel matching with additional exact matching variables

{p 8 12 2}. {stata kmatch md mbsmoke mmarried mage fbaby medu (bweight), att ematch(fage fedu)}{p_end}

{pstd}
    Bandwidth selection and cross-validation diagnostics plot

{p 8 12 2}. {stata kmatch ps mbsmoke mmarried mage fbaby medu (bweight), att atc}{p_end}
{p 8 12 2}. {stata kmatch ps mbsmoke mmarried mage fbaby medu (bweight), att atc bwidth(cv)}{p_end}
{p 8 12 2}. {stata kmatch ps mbsmoke mmarried mage fbaby medu (bweight), att atc bwidth(cv bweight)}{p_end}
{p 8 12 2}. {stata kmatch cvplot, ms(o o) index mlabposition(1 1) sort}{p_end}

{pstd}
    Common-support diagnostics plots

{p 8 12 2}. {stata kmatch ps mbsmoke mmarried mage fbaby medu (bweight), att bwidth(0.0005)}{p_end}
{p 8 12 2}. {stata kmatch csummarize}{p_end}
{p 8 12 2}. {stata kmatch cdensity}{p_end}
{p 8 12 2}. {stata kmatch ccumul}{p_end}
{p 8 12 2}. {stata kmatch cbox}{p_end}

{pstd}
    Using bootstrap to test balancing (simply add the covariates as additional outcome variables)

{p 8 12 2}. {stata kmatch ps mbsmoke mmarried mage fbaby medu (bweight) (mmarried mage fbaby medu), att nate vce(boot)}{p_end}

{pstd}
    Treatment effects by subpopulation

{p 8 12 2}. {stata kmatch ps mbsmoke mmarried mage medu (bweight), att over(fbaby) vce(boot, reps(100))}{p_end}
{p 8 12 2}. {stata test [0]ATT = [1]ATT}{p_end}
{p 8 12 2}. {stata lincom [0]ATT - [1]ATT}{p_end}

{pstd}
    ATE, ATT, ATC, NATE, and potential outcome means

{p 8 12 2}. {stata kmatch ps mbsmoke mmarried mage fbaby medu (bweight), ate att atc nate po vce(boot, reps(100))}{p_end}
{p 8 12 2}. {stata test ATT = ATC}{p_end}
{p 8 12 2}. {stata test ATE = NATE}{p_end}


{title:Stored results}

{pstd}
    {cmd:kmatch md} and {cmd:kmatch ps} store the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_ovars)}}number of outcome variables{p_end}
{synopt:{cmd:e(k_omit)}}number of omitted estimates{p_end}
{synopt:{cmd:e(N_over)}}number over-groups{p_end}
{synopt:{cmd:e(tvalue)}}value of {it:tvar} that is the treatment{p_end}
{synopt:{cmd:e(ridge)}}value of ridge parameter; only if {cmd:ridge()} is specified{p_end}
{synopt:{cmd:e(nn)}}number of requested neighbors; only if {cmd:nn()} is specified{p_end}
{synopt:{cmd:e(nn_min)}}minimum number of neighbors; only if {cmd:nn()} is specified{p_end}
{synopt:{cmd:e(nn_max)}}maximum number of neighbors; only if {cmd:nn()} is specified{p_end}
{synopt:{cmd:e(pm_quantile)}}{it:q} of PM bandwidth algorithm or undefined{p_end}
{synopt:{cmd:e(pm_factor)}}{it:f} of PM bandwidth algorithm or undefined{p_end}
{synopt:{cmd:e(cv_factor)}}step size of CV bandwidth algorithm or undefined{p_end}
{synopt:{cmd:e(comsup_lb)}}lower bound of PS support; only if {cmd:comsup()} is specified{p_end}
{synopt:{cmd:e(comsup_ub)}}upper bound of PS support; only if {cmd:comsup()} is specified{p_end}
{synopt:{cmd:e(comsup_lb_n)}}number of obs below PS support; only if {cmd:comsup()} is specified{p_end}
{synopt:{cmd:e(comsup_ub_n)}}number of obs above PS support; only if {cmd:comsup()} is specified{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:kmatch}{p_end}
{synopt:{cmd:e(subcmd)}}{cmd:md} or {cmd:ps}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(tvar)}}name of treatment variable{p_end}
{synopt:{cmd:e(xvars)}}names of covariates{p_end}
{synopt:{cmd:e(ematch)}}names of exact matching variables{p_end}
{synopt:{cmd:e(psvars)}}names of variables from {cmd:psvars()}{p_end}
{synopt:{cmd:e(pscore)}}name of variable from {cmd:pscore()}{p_end}
{synopt:{cmd:e(over)}}name of over variable{p_end}
{synopt:{cmd:e(over_labels)}}values over variable{p_end}
{synopt:{cmd:e(over_namelist)}}values over variable{p_end}
{synopt:{cmd:e(ovar#)}}name of outcome variable #{p_end}
{synopt:{cmd:e(avars#)}}names of adjustment variables for outcome #{p_end}
{synopt:{cmd:e(generate)}}names of generated matching variables{p_end}
{synopt:{cmd:e(dy)}}names of generated potential outcome difference variables{p_end}
{synopt:{cmd:e(metric)}}type of metric; {cmd:kmatch md} only{p_end}
{synopt:{cmd:e(kernel)}}kernel{p_end}
{synopt:{cmd:e(pscmd)}}command used for propensity score estimation{p_end}
{synopt:{cmd:e(psopts)}}options passed through to propensity score estimation{p_end}
{synopt:{cmd:e(pspredict)}}predict options for propensity score estimation{p_end}
{synopt:{cmd:e(bw_method)}}bandwidth selection method{p_end}
{synopt:{cmd:e(cv_outcome)}}name of cross-validation outcome variable{p_end}
{synopt:{cmd:e(cv_weighted)}}{cmd:weighted} or empty{p_end}
{synopt:{cmd:e(cv_nopenalty)}}{cmd:nopenalty} or empty{p_end}
{synopt:{cmd:e(cv_nolimit)}}{cmd:nolimit} or empty{p_end}
{synopt:{cmd:e(cv_exact)}}{cmd:exact} or empty{p_end}
{synopt:{cmd:e(ate)}}{cmd:ate} or empty{p_end}
{synopt:{cmd:e(att)}}{cmd:att} or empty{p_end}
{synopt:{cmd:e(atc)}}{cmd:atc} or empty{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(properties)}}{cmd:b}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}treatment effect estimates{p_end}
{synopt:{cmd:e(_N)}}numbers of observations in over-groups{p_end}
{synopt:{cmd:e(bwidth)}}bandwidths{p_end}
{synopt:{cmd:e(S)}}scaling matrix; {cmd:kmatch md} only{p_end}
{synopt:{cmd:e(cv)}}cross-validation results{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}

{pstd}
    If the {cmd:vcd()} option is specified, additional results as described
    in help {helpb bootstrap} and {helpb jackknife} are stored in {cmd:e()}.

{pstd}
    {cmd:kmatch summarize}, {cmd:kmatch csummarize}, {cmd:kmatch density}, {cmd:kmatch cdensity},
    {cmd:kmatch cumul}, {cmd:kmatch ccumul}, {cmd:kmatch box}, {cmd:kmatch cbox} return
    macro {cmd:r(refstat)} equal to {cmd:ate}, {cmd:att}, or {cmd:atc}. Additionally,
    {cmd:kmatch summarize} and {cmd:kmatch csummarize} store the following matrices in {cmd:r()}:

{synoptset 8 tabbed}{...}
{synopt:{cmd:r(M)}}table of means and standardized differences{p_end}
{synopt:{cmd:r(V)}}table of variances and their ratios; unless {cmd:sd} is specified{p_end}
{synopt:{cmd:r(SD)}}table of standard deviations and their ratios; if {cmd:sd} is specified{p_end}
{synopt:{cmd:r(S)}}vector of standard deviations used for standardization{p_end}


{title:References}

{phang}
    Abadie, A., G.W. Imbens. 2008. On the Failure of the Bootstrap for Matching
    Estimators. Econometrica 76(6):1537–1557.
    {p_end}
{phang}
    Abadie, A., G.W. Imbens. 2011. Bias-Corrected Matching Estimators for
    Average Treatment Effects. Journal of Business & Economic Statistics
    29(1):1-11.
    {p_end}
{phang}
    Frölich, M. 2004. Finite-sample properties of propensity-score matching and
    weighting estimators. {it:The Review of Economics and Statistics} 86(1):77-90.
    {p_end}
{phang}
    Frölich, M. 2005. Matching estimators and optimal bandwidth choice.
    {it:Statistics and Computing} 15:197-215.
    {p_end}
{phang}
    Galdo, J.C., J. Smith, D. Black. 2008. Bandwidth selection and the estimation
    of treatment effects with unbalanced data. {it:Annales d'Économie et de Statistique}
    91/92:89-216.
    {p_end}
{phang}
    Greevy, R.A., Jr., C.G. Grijalva, C.L. Roumie, C. Beck, A.M. Hung, H.J.
    Murff, X. Liu, M.R. Griffin. 2012. Reweighted Mahalanobis Distance Matching
    for Cluster Randomized Trials with Missing Data. Pharmacoepidemiology and
    Drug Safety 21(S2):148–154.
    {p_end}
{phang}
    Heckman, J.J., H. Ichimura, P. Todd. 1998. Matching as an Econometric
    Evaluation Estimator. The Review of Economic Studies 65(2):261-294.
    {p_end}
{phang}
    Heckman, J.J., H. Ichimura, J. Smith, P. Todd. 1998. Characterizing Selection
    Bias Using Experimental Data. Econometrica 66(5):1017-1098.
    {p_end}
{phang}
    Huber, M., M. Lechner, A. Steinmayr. 2015. Radius matching on the propensity score with
    bias adjustment: tuning parameters and finite sample behaviour. {it:Empirical Economics}
    49:1-31.
    {p_end}
{phang}
    Huber, M., M. Lechner, C. Wunsch. 2013. The performance of estimators based on the
    propensity score. {it:Journal of Econometrics} 175:1-21.
    {p_end}


{title:Author}

{pstd}
    Ben Jann, University of Bern, jann@soz.unibe.ch

{pstd}
    Thanks for citing this software as follows:

{pmore}
    Jann, B. (2017). kmatch: Stata module for multivariate-distance and
    propensity-score matching. Available from
    {browse "https://ideas.repec.org/c/boc/bocode/s458346.html"}.


{title:Also see}

{psee}
    Online:  help for {helpb teffects}
