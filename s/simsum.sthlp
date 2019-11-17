{smcl}
{* 2sep2009, Ian White}{...}
{cmd:help simsum}{right: ({browse "http://www.stata-journal.com/article.html?article=st0200":SJ10-3: st0200})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:simsum} {hline 2}}Analyze simulation studies including Monte
Carlo error{p_end}
{p2colreset}{...}


{title:Syntax}

{p 4 4 2}
{cmd:simsum} accepts data in wide or long format.

{p 4 4 2} In wide format, data contain one record per simulated dataset.

{p 8 14 2}
{cmd:simsum} {it:estvarlist} {ifin}
     [{cmd:,} {cmd:true(}{it:expression}{cmd:)} {it:options}]

{p 4 4 2}
{it:estvarlist} is a {it:varlist} containing point estimates from one or more
analysis methods.


{p 4 4 2} In long format, data contain one record per analysis method per
simulated dataset.

{p 8 14 2}
{cmd:simsum} {it:estvarname} {ifin}
      [{cmd:,} {cmd:true(}{it:expression}{cmd:)}
       {cmdab:meth:odvar(}{it:varname}{cmd:)}
       {cmd:id(}{it:varlist}{cmd:)} {it:options}]

{p 4 4 2} {it:estvarname} is a variable containing the point estimates,
{cmd:methodvar(}{it:varname}{cmd:)} identifies the method, and
{cmd:id(}{it:varlist}{cmd:)} identifies the simulated dataset.


{title:Description}

{pstd} The {cmd:simsum} command analyzes simulation studies in which each
simulated dataset yields point estimates by one or more analysis methods.
Bias, empirical standard error, and precision relative to a reference method
can be computed for each method.  If, in addition, model-based standard errors
are available, {cmd:simsum} can compute the average model-based standard
error, the relative error in the model-based standard error, the coverage of
nominal confidence intervals, and the power to reject a null hypothesis.
Monte Carlo errors are available for all estimated quantities.


{title:Options}

    {title:Main options}

{phang} {cmd:true(}{it:expression}{cmd:)} gives the true value of the
parameter.  This option is required for calculations of bias and coverage.

{phang} {cmd:methodvar(}{it:varname}{cmd:)} specifies that the data are in long
format and that each record represents one analysis of one simulated dataset
using the method identified by {it:varname}.  The {cmd:id()} option is
required with {cmd:methodvar()}.  If {cmd:methodvar()} is not specified, the
data must be in wide format, and each record represents all analyses of one
simulated dataset.

{phang} {cmd:id(}{it:varlist}{cmd:)} uniquely identifies the dataset used for
each record, within levels of any by-variables.  The
{cmd:methodvar()} option is required with {cmd:id()}.

{phang} {cmd:se(}{it:varlist}{cmd:)} lists the names of the variables
containing the standard errors of the point estimates.  For data in long
format, this is a single variable.

{phang} {cmdab:sep:refix(}{it:string}{cmd:)} specifies that the names of the
variables containing the standard errors of the point estimates be formed by
adding the given prefix to the names of the variables containing the point
estimates.  {cmd:seprefix()} may be combined with
{cmdab:sesuffix(}{it:string}{cmd:)} but not with {cmd:se(}{it:varlist}{cmd:)}.

{phang} {cmdab:ses:uffix(}{it:string}{cmd:)} specifies that the names of the
variables containing the standard errors of the point estimates be formed by
adding the given suffix to the names of the variables containing the point
estimates.  {cmd:sesuffix()} may be combined with
{cmdab:seprefix(}{it:string}{cmd:)} but not with {cmd:se(}{it:varlist}{cmd:)}.


    {title:Data-checking options}

{phang} {cmd:graph} requests a descriptive graph of standard errors against
point estimates.

{phang} {cmdab:nomem:check} turns off checking that adequate memory is free.
This check aims to avoid spending calculation time when {cmd:simsum} is likely
to fail because of lack of memory.

{phang} {cmd:max(}{it:#}{cmd:)} specifies the maximum acceptable absolute
value of the point estimates, standardized to mean 0 and standard deviation 1.
The default is {cmd:max(10)}.

{phang} {cmd:semax(}{it:#}{cmd:)} specifies the maximum acceptable value of
the standard error as a multiple of the mean standard error.  The default is
{cmd:semax(100)}.

{phang} {cmd:dropbig} specifies that point estimates or standard errors beyond
the maximum acceptable values be dropped; otherwise, the command halts with an
error.  Missing values are always dropped.

{phang} {cmd:nolistbig} suppresses listing of point estimates and standard
errors that lie outside the acceptable limits.

{phang} {cmd:listmiss} lists observations with missing point estimates or
standard errors.


    {title:Calculation options}

{phang} {cmd:level(}{it:#}{cmd:)} specifies the confidence level for coverages
and powers.  The default is {cmd:level(95)} or as set by {cmd:set level}; see
{manhelp level R}.

{phang} {cmd:by(}{it:varlist}{cmd:)} summarizes the results by {it:varlist}.

{phang} {cmd:mcse} reports Monte Carlo errors for all summaries.

{phang} {cmd:robust} requests robust Monte Carlo errors for the statistics
{cmd:empse}, {cmd:relprec}, and {cmd:relerror}.  The default is Monte Carlo
errors based on an assumption of normally distributed point estimates.
{cmd:robust} is only useful if {cmd:mcse} is also specified.

{phang} {cmdab:modelsem:ethod(rmse}|{cmd:mean)} specifies whether the model
standard error should be summarized as the root mean squared value
({cmd:modelsemethod(rmse)}, the default) or as the arithmetic mean
({cmd:modelsemethod(mean)}).

{phang} {cmd:ref(}{it:string}{cmd:)} specifies the reference method against
which relative precisions will be calculated.  With data in wide format,
{it:string} must be a variable name.  With data in long format, {it:string}
must be a value of the method variable; if the value is labeled, the
label must be used.


    {title:Options specifying degrees of freedom}

{pstd} The number of degrees of freedom is used in calculating coverages and
powers.

{phang} {cmd:df(}{it:string}{cmd:)} specifies the degrees of freedom.  It may
contain a number (to apply to all methods), a variable name, or a list of
variables containing the degrees of freedom for each method.

{phang} {cmdab:dfp:refix(}{it:string}{cmd:)} specifies that the names of the
variables containing the degrees of freedom are formed by adding the given
prefix to the names of the variables containing the point estimates.
{cmd:dfprefix()} may be combined with {cmd:dfsuffix(}{it:string}{cmd:)} but
not with {cmd:df(}{it:string}{cmd:)}.

{phang} {cmdab:dfs:uffix(}{it:string}{cmd:)} specifies that the names of the
variables containing the degrees of freedom be formed by adding the given
suffix to the names of the variables containing the point estimates.
{cmd:dfsuffix} may be combined with {cmd:dfprefix(}{it:string}{cmd:)} but not
with {cmd:df(}{it:string}{cmd:)}.


    {title:Statistic options}

{phang} If none of the following options are specified, then all available
statistics are computed.

{phang} {cmd:bsims} reports the number of simulations with nonmissing point
estimates.

{phang} {cmd:sesims} reports the number of simulations with nonmissing
standard errors.

{phang} {cmd:bias} estimates the bias in the point estimates.

{phang} {cmd:empse} estimates the empirical standard error, defined as the
standard deviation of the point estimates.

{phang} {cmd:relprec} estimates the relative precision, defined as the inverse
squared ratio of the empirical standard error of this method to the empirical
standard error of the reference method.  This calculation is slow; omitting it
can reduce run time by up to 90%.

{phang} {cmd:modelse} estimates the model-based standard error.  See
{cmd:modelsemethod()} above.

{phang} {cmd:relerror} estimates the proportional error in the model-based
standard error, using the empirical standard error as the gold standard.

{phang} {cmd:cover} estimates the coverage of nominal confidence intervals at
the specified level.

{phang} {cmd:power} estimates at the specified level the power to reject the
null hypothesis that the true parameter is zero.


    {title:Output options}

{phang} {cmd:clear} loads the summary data into memory.

{phang} {cmd:saving(}{it:filename}{cmd:)} saves the summary data into
{it:filename}.

{phang} {cmd:nolist} suppresses listing of the results and is allowed only
when {cmd:clear} or {cmd:saving()} is specified.

{phang} {cmd:listsep} lists results using one table per statistic, giving
output that is narrower and better formatted.  The default is to list the
results as a single table.

{phang} {cmd:format(}{it:string}{cmd:)} specifies the format for printing
results and saving summary data.  If {cmd:listsep} is also specified, then up
to three formats may be specified:  1) for results on the scale of the
original estimates ({cmd:bias}, {cmd:empse}, and {cmd:modelse}); 2) for
percentages ({cmd:relprec}, {cmd:relerror}, {cmd:cover}, and {cmd:power}); 3)
for integers ({cmd:bsims} and {cmd:sesims}).  Defaults are the existing format
of the (first) estimate variable for 1 and 2, and {cmd:%7.0f} for 3.

{phang} {cmd:sepby(}{it:varlist}{cmd:)} invokes this {cmd:list} option when
printing results.

{phang} {cmdab:ab:breviate(}{it:#}{cmd:)} invokes this {cmd:list} option when
printing results.

{phang} {cmd:gen(}{it:string}{cmd:)} specifies the prefix for new variables
identifying the different statistics in the output dataset. {cmd:gen()} is
only useful with {cmd:clear} or {cmd:saving()}.  The default is {cmd:gen(stat)}
so that the new identifiers are, for example, {cmd:statnum} and {cmd:statcode}.


{title:Examples}

{pstd}This example uses data in long format stored in {cmd:MIsim.dta}:{p_end}
{phang2}{cmd:. simsum b, true(0.5) methodvar(method) id(dataset) se(se) mcse format(%7.0g)}

{pstd}Alternatively, the data could first be reshaped to wide format:{p_end}
{phang2}{cmd:. reshape wide b se, i(dataset) j(method) string}{p_end}
{phang2}{cmd:. simsum b*, true(0.5) se(se*) mcse format(%7.0g)}{p_end}


{title:Author}

{pstd}Ian R. White{p_end}
{pstd}MRC Biostatistics Unit{p_end}
{pstd}Institute of Public Health{p_end}
{pstd}Cambridge, UK{p_end}
{pstd}ian.white@mrc-bsu.cam.ac.uk{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 10, number 3: {browse "http://www.stata-journal.com/article.html?article=st0200":st0200}
{p_end}
