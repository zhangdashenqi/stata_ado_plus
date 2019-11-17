{smcl}
{* *! version 1.0  08Jul2012}{...}
{cmd:help tsb}{right: ({browse "http://www.stata-journal.com/article.html?article=st0288":SJ13-1: st0288})}
{hline}

{title:Title}

{p2colset 5 12 14 2}{...}
{p2col :{hi:tsb} {hline 2}}Two-stage bootstrap sampling and estimation with shrinkage correction{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 18 2}
{cmd:tsb}
	{it:{help varlist}}
	{ifin}{cmd:,} {cmd:stats(&}{it:f}{cmd:())} {cmd:cluster({it:{help varname}})} [{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {cmd:stats(&}{it:f}{cmd:())}}specify a user-supplied statistical
function, {it:f}{cmd:()}, for bootstrapping {p_end}
{p2coldent :* {opth cluster(varname)}}variable identifying resampling clusters {p_end}
{synopt :{opt strata(varname)}}variable identifying strata; default is {cmd:strata(constant)}{p_end}
{synopt :{opt reps(#)}}perform {it:#} bootstrap replications; default is {cmd:reps(1000)}{p_end}
{synopt :{opt seed(#)}}set seed to {it:#}{p_end}
{synopt :{opth unbal(string)}}average cluster size to use{p_end}
{synopt :{opth lambda(real)}}lambda, a numerical value, for use in function
{it:f}{cmd:()}, if required{p_end}
{synopt :{opt noshrink}}without shrinkage correction{p_end}  
{synopt :{opt level(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt nodots}}suppress the replication dots{p_end}
{synoptline}
{p 4 6 2}* {opt stats()} and {cmd:cluster()} are required.


{title:Description}

{pstd}{cmd:tsb} performs two-stage bootstrap sampling and estimation.
Typing

{phang2}{cmd:. tsb} {it:var_list}{cmd:,} {cmd:stats(&}{it:f}{cmd:())} {opt cluster(varname)} 

{pstd}bootstraps the statistic {it:f}{cmd:()}, calculated by using the
variables in {it:var_list}.  The two-stage sampling procedure proposed
by Davison and Hinkley (1997) with shrinkage correction proceeds as
follows: At the first stage, estimates of cluster-level means are
resampled (with replacement).  At stage 2, estimates of standardized
individual-level deviations (from corresponding cluster means) are
resampled (also with replacement).  The resampled individual deviations
are then added to the cluster mean estimates chosen in stage 1,
irrespective of the cluster membership in the original data, to form a
synthetic bootstrap sample.  However, the variance in the synthetic
sample could be overestimated because of double counting the
within-cluster variance.  An optional shrinkage correction is
implemented to correct for the excess variation.

{pstd}Repeating this resampling process multiple times results in a
bootstrap sample of the statistic defined in {it:f}{cmd:()}.  Bootstrap
standard error and confidence intervals are then estimated by using
{cmd:bstat} based on the bootstrap sample.


{title:Options}

{phang}{cmd:stats(&}{it:f}{cmd:())} specifies a user-supplied Mata
function, {it:f}{cmd:()}, for calculating the statistic for
bootstrapping.  Note that the ampersand ({cmd:&}) before {it:f}{cmd:()}
is required as part of the syntax.  {cmd:stats()} is required.

{phang}{opt cluster(varname)} specifies the variable that identifies
clusters.  {cmd:cluster()} is required.

{phang}{opt strata(varname)} specifies the variable that identifies
strata.  For an example of a cluster randomized trial, the strata would
be levels of a cluster-level treatment or intervention variable.  The
default is {cmd:strata(constant)}.

{phang}{opt reps(#)} specifies the number of bootstrap replications to
be performed.  For estimation of the confidence interval, 1,000 or more
replications are generally recommended.  The default is
{cmd:reps(1000)}.

{phang}{opt seed(#)} specifies the random number seed.

{phang}{opt unbal(string)} specifies the "average" cluster size to use
in shrinkage correction.  {it:string} can be {cmd:dk} (see page 9 of
Donner and Klar [2000]), {cmd:mean}, or {cmd:median}.  The default is
{cmd:unbal(dk)}.  These are calculated independently for each stratum
specified in strata.

{phang}{opt lambda(real)} is relevant for cost-effectiveness analysis
and is the threshold willingness to pay for a unit of health outcome;
the user specifies an optional value, {it:real}, that can be called from
within the user-supplied function {it:f}{cmd:()}, if required.

{phang}{opt noshrink} specifies that the two-stage bootstrap resampling
is performed without shrinkage correction.  If this option is chosen,
instead of cluster means, whole clusters are resampled with replacement
in stage 1.  In stage 2, individuals within the chosen clusters are then
resampled also with replacement.  Cluster membership in the original
data is respected in this case.

{phang}
{opt level(#)}; see
{helpb estimation options##level():[R] estimation options}.

{phang}{opt nodots} suppresses display of the replication dots.  One dot
character is displayed for each successful replication.


{title:Examples}

{pstd}Compute two-stage bootstrap estimates of the user-supplied
function {cmd:inb()}, which calculates incremental net monetary benefit
(Drummond et al. 2005).  Resampling takes place within each stratum (in
this example, each level of the cluster-level treatment variable){p_end}
{phang2}{cmd:. tsb cost outcome, stats(&inb()) cluster(clusterid) strata(treatment)}{p_end}

{pstd}Change number of replications to 5,000{p_end}
{phang2}{cmd:. tsb cost outcome, stats(&inb()) cluster(clusterid) strata(treatment) reps(5000)}{p_end}

{pstd}Specifies {cmd:lambda()} (for willing-to-pay threshold) to be
1,0000{p_end}
{phang2}{cmd:. tsb cost outcome, stats(&inb()) cluster(clusterid) strata(treatment) lambda(10000)}{p_end}

{pstd}Compute two-stage bootstrap estimates of user-supplied function
{cmd:mept()}, which calculates the mean of the variable {cmd:cost} for
cluster-level treatment group number 1.{p_end}
{phang2}{cmd:. tsb cost if treatment==1, stats(&mept()) cluster(clusterid) }{p_end}  


{title:Saved results}

{pstd}The saved results are the same as those given by {cmd:bstat} in
{cmd:e()}.

{pstd} In addition, bootstrap sample estimates of the user-supplied
statistic and limits of the bootstrap confidence intervals given
by {cmd:bstat} are stored in {cmd:r(tsb_sam)}.{p_end}


{title:References}

{phang}Davison, A. C., and D. V. Hinkley.  1997. 
{it:Bootstrap Methods and Their Application}.  Cambridge:  Cambridge
University Press.

{phang}Donner, A., and N. Klar.  2000.  {it:Design and Analysis of Cluster Randomization Trials in Health Research}.  London: Arnold.

{phang}Drummond, M. F., M. J. Sculpher, G. W. Torrance, B. J. O'Brien,
and G. L. Stoddart.  2005.  
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
