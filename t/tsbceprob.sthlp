{smcl}
{* *! version 1.0  09Jul2012}{...}
{cmd:help tsbceprob}{right: ({browse "http://www.stata-journal.com/article.html?article=st0288":SJ13-1: st0288})}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{hi:tsbceprob} {hline 2}}Cost-effectiveness probabilities using two-stage bootstrap sampling with shrinkage correction{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:tsbceprob}
	{it:{help varlist}}
	{ifin}{cmd:,} {cmd:stats(&nb())} 
        {cmd:cluster(}{it:{help varname}}{cmd:)} 
        {cmd:strata(}{it:{help varname}}{cmd:)} 
	{cmd:lambda(}{it:{help real}}{cmd:)}
        [{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {cmd:stats(&nb())}}specify the statistical function {cmd:nb()}, for calculating net monetary benefit for bootstrapping{p_end}
{p2coldent :* {opth cluster(varname)}}variable for identifying resampling clusters{p_end}
{p2coldent :* {opt strata(varname)}}variable identifying strata; typically the variable for cluster-level interventions or comparators in a trial{p_end}
{p2coldent :* {opth lambda(real)}}willingness-to-pay (WTP) threshold value for
use in {cmd:nb()}{p_end}
{synopt :{opt reps(#)}}perform {it:#} bootstrap replications; default is {cmd:reps(1000)}{p_end}
{synopt :{opt seed(#)}}set seed to {it:#}{p_end}
{synopt :{opth unbal(string)}}average cluster size to use{p_end}
{synopt :{opt noshrink}}without shrinkage correction{p_end}  
{synopt :{opt level(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt nodots}}suppress the replication dots{p_end}
{synoptline}
{p 4 6 2}* {opt stats()}, {cmd:cluster()}, {cmd:strata()}, and {cmd:lambda()}
are required.

{title:Description}

{pstd}{cmd:tsbceprob} of the {cmd:tsb} suite is for estimating
cost-effectiveness probabilities by using the two-stage bootstrap
procedure (Davison and Hinkley 1997) for clustered data.  Interventions
(or comparators) are assumed to be at cluster level.  Typing

{phang2}{cmd:. tsbceprob} {it:var_list}{cmd:,} {cmd:stats(&nb())} 
{opt cluster(varname)} {opt strata(varname)} {opt lambda(real)}

{pstd}bootstraps the net benefit statistic, {cmd:nb()}, calculated by
using the variables in {it:var_list}.  {cmd:nb()} assumes the first
variable in {it:var_list} to be costs and the second, health outcomes
(or effects).  Resampling takes place independently within each stratum.
The estimated cost-effectiveness probabilities can subsequently be used
for plotting cost-effectiveness acceptability curves (Drummond et al.
2005).  See example c below.


{title:Options}

{phang}{cmd:stats(&nb())} specifies the net monetary benefit statistic,
{cmd:nb()}, for bootstrapping.  Note that 1) {cmd:tsbceprob} is designed
to work with {cmd:nb()} only; 2) the ampersand, {cmd:&}, before the
function name is required as part of the syntax; and 3) {cmd:nb()} is a
Mata function.  {cmd:stats(&nb())} is required.

{phang}{opt cluster(varname)} specifies the variable that identifies
clusters.  {cmd:cluster()} is required.

{phang}{opt strata(varname)} specifies the variable that identifies
strata.  For an example of a cluster randomized trial, the strata would
be a cluster-level intervention or comparator variable.  {cmd:strata()}
is required.

{phang}{opt lambda(real)} specifies the WTP threshold that is passed to
{cmd:nb()} for calculating the net monetary benefit.  {cmd:lambda()} is
required.

{phang}{opt reps(#)} specifies the number of bootstrap replications to
be performed.  The default is {cmd:reps(1000)}.

{phang}{opt seed(#)} specifies the random number seed.

{phang}{opt unbal(string)} specifies the average cluster size to use in
shrinkage correction.  {it:string} can be {cmd:dk} (see page 9 of Donner
and Klar [2000]), {cmd:mean}, or {cmd:median}.  The default is
{cmd:unbal(dk)}.  These are calculated independently for each stratum
specified in strata.

{phang}{opt noshrink} specifies that the two-stage bootstrap resampling
is performed without shrinkage correction.  If this option is chosen,
instead of cluster means, whole clusters are resampled with replacement
in stage 1.  In stage 2, individuals within the chosen clusters are
resampled with replacement.  Cluster membership in the original data is
respected in this case.

{phang}{opt level(#)}; see
{helpb estimation options##level():[R] estimation options}.

{phang}{opt nodots} suppresses display of the replication dots.  One dot
character is displayed for each successful replication.


{title:Examples}

{pstd}a) Estimate cost-effectiveness probabilities by using two-stage
bootstrap for cluster-level treatment groups at a WTP threshold of
20,000{p_end}
{phang2}{cmd:. tsbceprob cost effect, stats(&nb()) cluster(clusterid) strata(treatment) lambda(20000)}{p_end}

{pstd}b) Change WTP to 45,000 and increase number of replications to
5,000{p_end}
{phang2}{cmd:. tsbceprob cost effect, stats(&nb()) cluster(clusterid) strata(treatment) lambda(45000) reps(5000)}{p_end}

{pstd}c) Plot cost-effectiveness acceptability curves (CEACs) over a
range of WTP thresholds from 0 to 60,000 (in steps of 5,000) for three
cluster-level treatment groups (control, {cmd:tx1}, and {cmd:tx2}).
This example shows how this can be done by embedding {cmd:tsbceprob}
inside a {cmd:foreach} loop over a range of WTP values.  The estimated
cost-effectiveness (CE) probabilities and their corresponding WTP values
are stored in the matrix {it:ceprob_mat}.  The CE probabilities are
subsequently exported into the current Stata dataset by {cmd:svmat} for
plotting the CEACs by using {cmd:scatter}.{p_end}
{phang2}{cmd:. foreach num of numlist 0(5000)60000 {c -(} }{p_end}
{phang3}{cmd:1. tsbceprob cost effect, stats(&nb()) cluster(clusterid) strata(treatment) reps(1000)} 
{cmd: nodots seed(101) lambda(`num') }{p_end}
{phang3}{cmd:2. matrix ceprob_mat = (nullmat(ceprob_mat)\r(tsb_ceprob)) }{p_end}
{phang2}{cmd:{c )-} }{p_end}
{phang2}{cmd:. svmat ceprob_mat, names(tsb_ceprob)}{p_end}
{phang2}{cmd:. rename tsb_ceprob1 tx_control}{p_end}
{phang2}{cmd:. rename tsb_ceprob2 tx_1}{p_end}
{phang2}{cmd:. rename tsb_ceprob3 tx_2}{p_end}
{phang2}{cmd:. rename tsb_ceprob4 lval}{p_end}
{phang2}{cmd:. label variable tx_control "Control"}{p_end}
{phang2}{cmd:. label variable tx_1 "tx1"}{p_end}
{phang2}{cmd:. label variable tx_2 "tx2"}{p_end}
{phang2}{cmd:. label variable lval "Willingness-to-pay threshold (£)"}{p_end}
{phang2}{cmd:. scatter tx_control tx_1 tx_2 lval, connect(l l l) msize(small small small)}
{cmd: ytitle("Mean probability cost-effective") yscale(range(0 1)) ylabel(0(0.2)1)}
{cmd: xlabel(0(10000)60000)}{p_end}


{title:Saved results}

{pstd}CE probability estimates are stored in the matrix
{cmd:r(tsb_ceprob)} for a given WTP value.  These row matrices can be
stacked into a single matrix and exported into Stata for plotting CEACs.
See, for instance, example c above.


{title:References}

{phang}Davison, A. C., and D. V. Hinkley. 1997.
{it:Bootstrap Methods and Their Application}.  Cambridge:  Cambridge
University Press.

{phang}Donner, A., and N. Klar. 2000. {it:Design and Analysis of Cluster Randomization Trials in Health Research}.  London: Arnold.

{phang}Drummond, M. F., M. J. Sculpher, G. W. Torrance,
B. J. O'Brien, and G. L. Stoddart.  2005.  
{it:Methods for the Economic Evaluation of Health Care Programmes}. 3rd ed.
Oxford: Oxford University Press.


{title:Author}

{pstd}Edmond S.-W. Ng{p_end}
{pstd}Department of Health Services Research and Policy{p_end}
{pstd}London School of Hygiene and Tropical Medicine{p_end}
{pstd}London, UK{p_end}
{pstd}edmondngsw@googlemail.com{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 13, number 1: {browse "http://www.stata-journal.com/article.html?article=st0288":st0288}{p_end}
