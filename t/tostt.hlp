{smcl}
{* *! version 1.4.1  28feb2014}{...}
{cmd:help tostt}
{hline}


{title:Title}

{p2colset 5 14 18 2}{...}
{p2col:{cmd:tostt} {hline 2}}Mean-equivalence t tests{p_end}
{p2colreset}{...}


{title:Syntax}

{pstd}
One-sample mean-equivalence t test

{p 8 14 2}
{cmd:tostt} {varname} {cmd:==} {it:#} {ifin}
        [{cmd:, {ul on}eqvt{ul off}ype(}{it:type}{cmd:)}
        {cmd: {ul on}eqvl{ul off}evel(}{it:#}{cmd:)}
        {cmd: {ul on}upper{ul off}eqvlevel(}{it:#}{cmd:)}        
        {cmd:{ul on}l{ul off}evel(}{it:#}{cmd:)}]


{pstd}
Two-sample unpaired mean-equivalence t test

{p 8 14 2}
{cmd:tostt} {varname:1} {cmd:==} {varname:2} {ifin}
        [{cmd:, {ul on}unp{ul off}aired}
        {cmd:{ul on}eqvt{ul off}ype(}{it:type}{cmd:)}
        {cmd: {ul on}eqvl{ul off}evel(}{it:#}{cmd:)}
        {cmd: {ul on}upper{ul off}eqvlevel(}{it:#}{cmd:)}
        {cmd:{ul on}une{ul off}qual}
        {cmd:{ul on}w{ul off}elch}
        {cmd:{ul on}l{ul off}evel(}{it:#}{cmd:)}]


{pstd}
Two-sample paired mean-equivalence t test

{p 8 14 2}
{cmd:tostt} {varname:1} {cmd:==} {varname:2} {ifin}
        [{cmd:, {ul on}eqvt{ul off}ype(}{it:type}{cmd:)}
        {cmd: {ul on}eqvl{ul off}evel(}{it:#}{cmd:)}
        {cmd: {ul on}upper{ul off}eqvlevel(}{it:#}{cmd:)}
        {cmd:{ul on}l{ul off}evel(}{it:#}{cmd:)}]


{pstd}
Two-group unpaired mean-equivalence t test

{p 8 14 2}
{cmd:tostt} {varname} {ifin}
        {cmd:, }{opth by:(varlist:groupvar)}
        [{cmd:{ul on}eqvt{ul off}ype(}{it:type}{cmd:)}
        {cmd: {ul on}eqvl{ul off}evel(}{it:#}{cmd:)}
        {cmd: {ul on}upper{ul off}eqvlevel(}{it:#}{cmd:)}
        {cmd:{ul on}une{ul off}qual}
        {cmd:{ul on}w{ul off}elch}
        {cmd:{ul on}l{ul off}evel(}{it:#}{cmd:)}]


{pstd}
Immediate form of one-sample mean-equivalence t test

{p 8 14 2}
{cmd:tostti}
        {it:#obs}
        {it:#mean}
        {it:#sd}
        {it:#val}
        [{cmd:, {ul on}eqvt{ul off}ype(}{it:type}{cmd:)}
        {cmd: {ul on}eqvl{ul off}evel(}{it:#}{cmd:)}
        {cmd: {ul on}upper{ul off}eqvlevel(}{it:#}{cmd:)}
        {opt x:name(string)}
        {opt l:evel(#)}]


{pstd}
Immediate form of two-sample mean-equivalence t test

{p 8 14 2}
        {cmd:tostti}
        {it:#obs1}
        {it:#mean1}
        {it:#sd1}
        {it:#obs2}
        {it:#mean2}
        {it:#sd2}
        [{cmd:, {ul on}eqvt{ul off}ype(}{it:type}{cmd:)}
        {cmd: {ul on}eqvl{ul off}evel(}{it:#}{cmd:)}
        {cmd: {ul on}upper{ul off}eqvlevel(}{it:#}{cmd:)}
        {cmd:{ul on}une{ul off}qual}
        {cmd:{ul on}w{ul off}elch}
        {opt x:name(string)}
        {opt y:name(string)}
        {cmd:{ul on}l{ul off}evel(}{it:#}{cmd:)}]


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Miscellaneous}
{synopt :{opt eqvt:ype(string)}}specify equivalence threshold with Delta or epsilon{p_end}
{synopt :{opt eqvl:evel(#)}}the level of tolerance defining the equivalence interval{p_end}
{synopt :{opt upper:eqvlevel(#)}}the upper value of an asymmetric equivalence interval{p_end}
{synopt :{opt unp:aired}}the data are unpaired{p_end}
{synopt :{opth by:(varlist:groupvar)}}variable defining the two groups (implies {cmd:unpaired}){p_end}
{synopt :{opt une:qual}}unpaired data have unequal variances{p_end}
{synopt :{opt w:elch}}use Welch's approximation (implies {opt unequal}){p_end}
{synopt :{opt x:name(string)}}the name of the first variable{p_end}
{synopt :{opt y:name(string)}}the name of the second variable{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {opt level(95)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}


{title:Description}

{pstd}
{cmd:tostt} tests for the equivalence of means within a symmetric equivalence 
interval defined by {opt eqvt:ype} and {opt eqvl:evel} using a two one-sided t 
tests approach ({help tostt##Schuirmann1987:Schuirmann, 1987}).  Typically null 
hypotheses are framed from an assumption of a lack of difference between two 
quantities, and reject this assumption only with sufficient evidence.  When 
performing tests of equivalence, one frames a null hypothesis with the 
assumption that two quantities are different within an equivalence interval 
defined by some chosen level of tolerance (as specified by {opt eqvt:ype} and 
{opt eqvl:evel}).{p_end}

{pstd}
With respect to an unpaired t test, an equivalence null hypothesis takes one of 
the following two forms depending on whether equivalence is defined in terms of
Delta (equivalence expressed in the same units as the x and y) or in terms of 
epsilon (equivalence expressed in the units of the t distribution with the 
given degrees of freedom):
 
{p 8}
Ho: |mean(x) - mean(y)| >= Delta, {p_end}
{p 8 8}where the equivalence interval ranges from diff-Delta to diff+Delta, and 
where diff is either the mean difference or the difference in means depending on
whether the test is paired or unpaired. This translates directly into two 
one-sided null hypotheses: {p_end}

{p 12}
Ho1: Delta - [mean(x) - mean(y)] <= 0; and{p_end}

{p 12}
Ho2: [mean(x) - mean(y)] + Delta <= 0{p_end}

{p 8}
-OR-

{p 8}
Ho: |t| >= epsilon, {p_end}
{p 8 8}where the equivalence interval ranges from -epsilon to epsilon. This also 
translates directly into two one-sided null hypotheses: {p_end}

{p 12}
Ho1: epsilon - t <= 0; and{p_end}

{p 12}
Ho2: t + epsilon <= 0{p_end}

{p 8 8}
When an asymmetric equivalence interval is defined using the {opt upper:eqvlevel} option 
the general negativist null hypothesis becomes:{p_end}

{p 8}
Ho: [mean(x) - mean(y)] <= Delta_lower, or [mean(x) - mean(y)] >= Delta_upper,{p_end}
{p 8 8 }
where the equivalence interval ranges from [mean(x) - mean(y)] + Delta_lower to 
[mean(x) - mean(y)] + Delta_upper. This also translates directly into two 
one-sided null hypotheses:{p_end}

{p 12}
Ho1: Delta_upper - [mean(x) - mean(y)] <= 0; and{p_end}

{p 12}
Ho2: [mean(x) - mean(y)] - Delta_lower <= 0{p_end}

{p 8}
-OR-

{p 8}
Ho: t <= epsilon_lower, or t >= epsilon_upper,{p_end}

{p 12}
Ho1: epsilon_upper - t <= 0; and{p_end}

{p 12}
Ho2: t - epsilon_lower <= 0{p_end}
 
{pstd}
NOTE: the appropriate level of alpha is precisely the same as in the 
corresponding two-sided test of mean difference, so that, for example, if one 
wishes to make a Type I error %5 of the time, one simply conducts both of the 
one-sided tests of Ho1 and Ho2 by comparing the resulting p-value to 0.05 
({help tostt##Tryon2008:Tryon and Lewis, 2008}).{p_end}


{title:Options}

{dlgtab:Main}

{phang}
{opth eqvt:ype(string)} defines whether the equivalence interval will be 
defined in terms of Delta or epsilon ({opt delta}, or {opt epsilon}). These 
options change the way that {opt evql:evel} is interpreted: when {opt delta} is 
specified, the {opt evql:evel} is measured in the units of the variable being 
tested, and when {opt epsilon} is specified, the {opt evql:evel} is measured in 
multiples of the standard deviation of the t distribution; put another way 
epsilon = Delta/standard error. The default is {opt delta}.{p_end}

{marker mineqvlevel}{...}
{p 8 8}
Defining tolerance in terms of epsilon means that it is not possible to reject 
any test of mean equivalence Ho if epsilon <= the critical value of t for a 
given alpha and degrees of freedom. Because epsilon = Delta/standard error, we 
can see that it is not possible to reject any Ho if Delta <= the product of the 
standard error and critical value of t for a given alpha and degrees of freedom.
{cmd: tostt} and {cmd: tostti} now report when either of these conditions obtain.{p_end}

{phang}
{opth eqvl:evel(#)} defines the equivalence threshold for the tests depending on 
whether {opt eqvt:ype} is {opt delta} or {opt epsilon} (see above). Researchers 
are responsible for choosing meaningful values of Delta or epsilon. The default 
value is 1 when {opt delta} is the {opt eqvt:ype} and 2 when {opt epsilon} is the {opt eqvt:ype}.{p_end}

{phang}
{opt upper:eqvlevel(#)} defines the {it: upper} equivalence threshold for the test, 
and transforms the meaning of {opt eqvl:evel} to mean the {it: lower} equivalence 
threshold for the test. Also, {opt eqvl:evel} is assumed to be a negative value. 
Taken together, these correspond to Schuirmann's ({help tostt##Schuirmann1987:1987}) 
asymmetric equivalence intervals. If {opt upper:eqvlevel}==|{opt eqvl:evel}|, then 
{opt upper:eqvlevel} will be ignored.{p_end}

{phang}
{opth by:(varlist:groupvar)} specifies the {it:groupvar} that defines the two
groups that {cmd:tostt} will use to test the hypothesis that their means are
different.  Specifying {opt by(groupvar)} implies an unpaired (two sample) t 
test.  Do not confuse the {opt by()} option with the {cmd:by} prefix; you can 
specify both.{p_end}

{phang}
{opt unpaired} specifies that the data be treated as unpaired.  The 
{opt unpaired} option is used when the two set of values to be compared are 
in different variables.{p_end}

{phang}
{opt unequal} specifies that the unpaired data not be assumed to have equal 
variances.

{phang}
{opt welch} specifies that the approximate degrees of freedom for the test 
be obtained from Welch's formula ({help tostt##Welch1947:1947}) rather than 
Satterthwaite's approximation formula ({help ttest##Satterthwaite1946:1946}), 
which is the default when {opt unequal} is specified.  Specifying {opt welch} 
implies {opt unequal}.{p_end}

{phang}
{opt xname(string)} specifies how the first variable will be labeled in the 
output. The default value of {opt xname} is {cmd:x}.

{phang}
{opt yname(string)} specifies how the second variable will be labeled in the 
output. The default value of {opt yname} is {cmd:y}.

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence
intervals.  The default is {opt level(95)} or as set by {helpb set level}.


{title:Remarks}

{pstd}
As described by Tryon and Lewis ({help tostt##Tryon2008:2008}), when both tests 
of difference and equivalence are taken together, there are four possible 
interpretations:{p_end}

{p 4 8 2}
1.  One may reject the null hypothesis of no difference, but fail to reject the 
null hypothesis of difference, and conclude that there is a {it: relevant difference} 
in means at least as large as Delta or epsilon.{p_end}

{p 4 8 2}
2.  One may fail to reject the null hypothesis of no difference, but reject the 
null hypothesis of difference, and conclude that the means are {it: equivalent} 
within the equivalence range (i.e. defined by Delta or epsilon).{p_end}

{p 4 8 2}
3.  One may reject {it:both} the null hypothesis of no difference and the null 
hypothesis of difference, and conclude that the means are {it: trivially different}, 
within the equivalence range (i.e. defined by Delta or epsilon).{p_end}

{p 4 8 2}
4.  One may fail to reject {it:both} the null hypothesis of no difference and the 
null hypothesis of difference, and draw an {it: indeterminate} conclusion, because 
the data are underpowered to detect difference or equivalence.{p_end}


{title:Examples}

{pstd}
These examples correspond to those written in the help file for 
{help ttest:ttest}:{p_end}

    {cmd:. sysuse auto}                                   (setup)
    {inp:. tostt mpg==20, eqvt(delta) eqvl(2.5) upper(3)} (one-sample mean-equivalence test)

    {cmd:. webuse fuel}                                   (setup)
    {cmd:. tostt mpg1==mpg2, eqvt(epsilon) eqvl(3)}       (two-sample paired mean-equivalence test)

    {cmd:. webuse fuel3}                                  (setup)
    {cmd:. tostt mpg, by(treated)}                        (two-group unpaired mean-comparison test)
                                                          (note warning about value of Delta!)
    
                                 (no setup required)
    {cmd:. tostti 24 62.6 15.8 75}                        (immediate form; n=24, m=62.6, sd=15.8;
                                                                test m=75)


{title:Author}

{pstd}Alexis Dinno{p_end}
{pstd}Portland State University{p_end}
{pstd}alexis dot dinno at pdx dot edu{p_end}

{pstd}
Please contact me with any questions, bug reports or suggestions for 
improvement.{p_end}

{pstd}
I am endebted to my winter 2013 students for their inspiration.


{title:Saved results}

{pstd}
The one-sample form of {cmd:tostt} saves the following in 
{cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(sd_1)}}standard deviation for the variable{p_end}
{synopt:{cmd:r(se)}}estimate of standard error{p_end}
{synopt:{cmd:r(p2)}}upper one-sided p-value under Ho2{p_end}
{synopt:{cmd:r(p1)}}upper one-sided p-value under Ho1{p_end}
{synopt:{cmd:r(t2)}}t2 statistic under Ho2{p_end}
{synopt:{cmd:r(t1)}}t1 statistic under Ho1{p_end}
{synopt:{cmd:r(df_t)}}degrees of freedom{p_end}
{synopt:{cmd:r(mu_1)}}x_1 bar, mean for the population{p_end}
{synopt:{cmd:r(N_1)}}sample size n_1{p_end}
{synopt:{cmd:r(Delta)}}Delta, tolerance level defining the equivalence interval; OR{p_end}
{synopt:{cmd:r(Du)}}Delta_upper, tolerance level defining the equivalence interval's upper side; AND{p_end}
{synopt:{cmd:r(Dl)}}Delta_lower, tolerance level defining the equivalence interval's lower side; OR{p_end}
{synopt:{cmd:r(epsilon)}}epsilon, tolerance level defining the equivalence interval{p_end}
{synopt:{cmd:r(eu)}}epsilon_upper, tolerance level defining the equivalence interval's upper side; AND{p_end}
{synopt:{cmd:r(el)}}epsilon_lower, tolerance level defining the equivalence interval's lower side{p_end}
{p2colreset}{...}

{pstd}
The two-sample and two-group forms of {cmd:tostt} save the following in 
{cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(sd_2)}}standard deviation for second variable{p_end}
{synopt:{cmd:r(sd_1)}}standard deviation for first variable{p_end}
{synopt:{cmd:r(se)}}estimate of standard error{p_end}
{synopt:{cmd:r(p2)}}upper one-sided p-value under Ho2{p_end}
{synopt:{cmd:r(p1)}}upper one-sided p-value under Ho1{p_end}
{synopt:{cmd:r(t2)}}t statistic under Ho2{p_end}
{synopt:{cmd:r(t1)}}t statistic under Ho1{p_end}
{synopt:{cmd:r(df_t)}}degrees of freedom{p_end}
{synopt:{cmd:r(mu_2)}}x_2 bar, mean for population 2{p_end}
{synopt:{cmd:r(N_2)}}sample size n_2{p_end}
{synopt:{cmd:r(mu_1)}}x_1 bar, mean for population 1{p_end}
{synopt:{cmd:r(N_1)}}sample size n_1{p_end}
{synopt:{cmd:r(Delta)}}Delta, tolerance level defining the equivalence interval; OR{p_end}
{synopt:{cmd:r(Du)}}Delta_upper, tolerance level defining the equivalence interval's upper side; AND{p_end}
{synopt:{cmd:r(Dl)}}Delta_lower, tolerance level defining the equivalence interval's lower side; OR{p_end}
{synopt:{cmd:r(epsilon)}}epsilon, tolerance level defining the equivalence interval{p_end}
{synopt:{cmd:r(eu)}}epsilon_upper, tolerance level defining the equivalence interval's upper side; AND{p_end}
{synopt:{cmd:r(el)}}epsilon_lower, tolerance level defining the equivalence interval's lower side{p_end}
{p2colreset}{...}


{title:References}

{marker Satterthwaite1946}{...}
{phang}
Satterthwaite, F. E. 1946. An approximate distribution of estimates of variance 
components. {it:Biometrics Bulletin} 2: 110-114.

{marker Schuirmann1987}{...}
{phang}
Schuirmann, D. A. 1987. A comparison of the two one-sided tests procedure and 
the power approach for assessing the equivalence of average bioavailability. 
{it:Pharmacometrics}. 15: 657-680

{marker Tryon2008}{...}
{phang}
Tryon, W. W., and C. Lewis. 2008. An inferential confidence interval method of 
establishing statistical equivalence that corrects TryonÕs (2001) reduction 
factor. {it:Psychological Methods}. 13: 272-277

{marker Welch1947}{...}
{phang}
Welch, B. L. 1947. The generalization of `Student's' problem when several 
different population variances are involved. {it:Biometrika} 34: 28-35.


{title:Also See}

{psee}
{space 2}Help: {help pkequiv:pkequiv}, {help ttest:ttest}

