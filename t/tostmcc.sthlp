{smcl}
{* *! version 1.6.0  02mar2014}{...}
{cmd:help tostmcc}
{hline}


{title:Title}

{p2colset 5 16 18 2}{...}
{p2col:{cmd:tostmcc} {hline 2}}Paired z test for stochastic equivalence in binary data
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}{cmd:mcc} {it:var_exposed_case} {it:var_exposed_control} {ifin} 
{weight} [{cmd:, {ul on}eqvt{ul off}ype(}{it:type}{cmd:)}
    {cmd: {ul on}eqvl{ul off}evel(}{it:#}{cmd:)}
    {cmd: {ul on}upper{ul off}eqvlevel(}{it:#}{cmd:)}
    {opt yates}
    {opt edwards}
    {opt l:evel(#)}]

{p 8 14 2}{cmd:mcci} {it:#a #b #c #d}  
    [{cmd:, {ul on}eqvt{ul off}ype(}{it:type}{cmd:)}
    {cmd: {ul on}eqvl{ul off}evel(}{it:#}{cmd:)}
    {cmd: {ul on}upper{ul off}eqvlevel(}{it:#}{cmd:)}
    {opt yates}
    {opt edwards}
    {opt l:evel(#)}]

{synoptset 21 tabbed}{...}
{synopthdr:tostmcc options}
{synoptline}
{syntab:Main}
{synopt :{opt eqvt:ype(string)}}specify equivalence threshold with Delta or epsilon{p_end}
{synopt :{opt eqvl:evel(#)}}the level of tolerance defining the equivalence interval{p_end}
{synopt :{opt upper:eqvlevel(#)}}the upper value of an asymmetric equivalence interval{p_end}
{synopt :{opt yates}}include a Yates continuity correction{p_end}
{synopt :{opt edwards}}include an Edwards continuity correction{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {opt level(95)}{p_end}
{synoptline}
{p2colreset}{...}
{pstd}{opt fweight}s are allowed; see {help weight}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:mcc} tests stochastic dominance of exposure in matched case-control data.  
It calculates a Wald-type asymptotic z test ({help tostmcc##Liu2002:Liu, et al., 2002}) 
in a two one-sided tests approach ({help tostmcc##Schuirmann1987:Schuirmann, 1987}).
{cmd:tostmcci} is the immediate form of {cmd:tostmcc}; see {help immed}.  Typically the 
null hypotheses of the corresponding McNemar's chi-square test 
({help tostmcc##McNemar1947:McNemar, 1947}) for stochastic dominance are 
framed from an assumption of stochastic equality (or distributional sameness) 
between cases and controls (e.g. Ho: P(exposure|case) = P(exposure|controls), 
rejecting this assumption only with sufficient evidence.  When performing tests 
of stochastic equivalence, the null hypothesis is framed as one population 
stochastically dominates the other by at least as much as the equivalence 
interval defined by some chosen level of tolerance (as specified by {opt eqvt:ype} 
and {opt eqvl:evel}).{p_end}

{pstd}
With respect to a z test, a negativist null hypothesis takes one of the 
following two forms depending on whether tolerance is defined in terms of
Delta (equivalence expressed in the units of the probability of counts of 
discordant pairs) or in terms of epsilon (equivalence expressed in the units of 
the z distribution):
 
{p 8}
Ho: |b - c| >= Delta, {p_end}
{p 8 8}where the equivalence interval ranges from |b - c|-Delta to 
|b - c|+Delta, and where b is the count of pairs with cases exposed, but 
controls unexposed, and and c is the count of pairs with cases unexposed and 
controls exposed. This null hypothesis translates directly into two one-sided 
null hypotheses: {p_end}

{p 12}
Ho1: Delta - (b - c) <= 0; and{p_end}

{p 12}
Ho2: (b - c) + Delta <= 0{p_end}

{p 8}
-OR-

{p 8}
Ho: |z| >= epsilon, {p_end}
{p 8 8}where the equivalence interval ranges from -epsilon to epsilon.  This also 
translates directly into two one-sided null hypotheses: {p_end}

{p 12}
Ho1: epsilon - z <= 0; and{p_end}

{p 12}
Ho2: z + epsilon <= 0{p_end}

{p 8 8}
When an asymmetric equivalence interval is defined using the {opt upper:eqvlevel} option 
the general negativist null hypothesis becomes:{p_end}

{p 8}
Ho: (b - c) <= Delta_lower, or (b - c) >= Delta_upper,{p_end}
{p 8 8 }
where the equivalence interval ranges from (b - c) + Delta_lower to 
(b - c) + Delta_upper.  This also translates directly into two one-sided null 
hypotheses:{p_end}

{p 12}
Ho1: Delta_upper - (b - c) <= 0; and{p_end}

{p 12}
Ho2: (b - c) - Delta_lower <= 0{p_end}

{p 8}
-OR-

{p 8}
Ho: z <= epsilon_lower, or z >= epsilon_upper,{p_end}

{p 12}
Ho1: epsilon_upper - z <= 0; and{p_end}

{p 12}
Ho2: z - epsilon_lower <= 0{p_end}
 
{pstd}
NOTE: the appropriate level of alpha is precisely the same as in the 
corresponding McNemar's test for stochastic dominance, so that, for example, if 
one wishes to make a Type I error %5 of the time, one simply conducts both of 
the one-sided tests of Ho1 and Ho2 by comparing the resulting p-value to 0.05 
({help tostmcc##Tryon2008:Tryon and Lewis, 2008}).{p_end}


{marker options}{...}
{title:Options for mcc and mcci}

{dlgtab:Main}

{phang}
{opth eqvt:ype(string)} defines whether the equivalence interval will be 
defined in terms of Delta or epsilon ({opt delta}, or {opt epsilon}).  These 
options change the way that {opt evql:evel} is interpreted: when {opt delta} is 
specified, the {opt evql:evel} is measured in the units of the variable being 
tested, and when {opt epsilon} is specified, the {opt evql:evel} is measured in 
multiples of the standard deviation of the z distribution; put another way 
epsilon = Delta/standard error.  The default is {opt delta}.{p_end}

{marker mineqvlevel}{...}
{p 8 8}
Defining tolerance in terms of epsilon means that it is not possible to reject 
any test of mean equivalence Ho if epsilon <= the critical value of z for a 
given alpha.  Because epsilon = n*Delta/standard error, we can see that it is not 
possible to reject any Ho if Delta <= the product of the standard error and 
critical value of z over n for a given alpha.  {cmd: tostmcc} reports when either 
of these conditions obtain.  Tolerances should be specified using {opt delta} by 
considering the difference in P(b) and P(c).{p_end}

{phang}
{opth eqvl:evel(#)} defines the equivalence threshold for the tests depending on 
whether {opt eqvt:ype} is {opt delta} or {opt epsilon} (see above).  Researchers 
are responsible for choosing meaningful values of Delta or epsilon.  The default 
value is .1 when {opt delta} is the {opt eqvt:ype} and 2 when {opt epsilon} is 
the {opt eqvt:ype}.{p_end}

{phang}
{opt upper:eqvlevel(#)} defines the {it: upper} equivalence threshold for the test, 
and transforms the meaning of {opt eqvl:evel} to mean the {it: lower} equivalence 
threshold for the test.  Also, {opt eqvl:evel} is assumed to be a negative value.  
Taken together, these correspond to Schuirmann's ({help tostranksum##Schuirmann1987:1987}) 
asymmetric equivalence intervals.  If {opt upper:eqvlevel}==|{opt eqvl:evel}|, then 
{opt upper:eqvlevel} will be ignored.{p_end}

{phang}
{opt yates} specifies that the test statistics incorporate a Yates continuity 
correction ({help tostmcc##Yates1934:Yates, 1934}) using the term [(b - c)-0.5] 
for z1, and the term [(b - c)+0.5] for z2. {opt yates} is exclusive of {opt edwards}{p_end}

{phang}
{opt edwards} specifies that the test statistics incorporate an Edwards continuity 
correction ({help tostmcc##Edwards1947:Edwards, 1947}) using the term [(b - c)-1] 
for z1, and the term [(b - c)+1] for z2. {opt edwards} is exclusive of {opt yates}{p_end}

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for 
determination of the thresholds at which rejecting Ho in favor of stochastic 
equivalence is impossible.  The default is {opt level(95)} or as set by {helpb set level}.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse mccxmpl}

{pstd}Test for stochastic equivalence in paired binary data{p_end}
{phang2}{cmd:. tostmcc 8 8 3 8 [fw=pop], eqvt(delta) eqvlevel(.2)}

{pstd}Same as above command, but using immediate form{p_end}
{phang2}{cmd:. tostmcci 8 8 3 8, eqvt(delta) eqvlevel(.2)}

{pstd}With asymetric equivalence intervals specified with epsilon{p_end}
{phang2}{cmd:. tostmcci 8 8 3 8, eqvt(epsilon) eqvlevel(2) upper(3)}


{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:tostmcc} and {cmd:tostmcci} save the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(z1)}}z test statistic for Ho1 (upper){p_end}
{synopt:{cmd:r(z2)}}z test statistic for Ho2 (lower){p_end}
{synopt:{cmd:r(p1)}}P(Z >= z1){p_end}
{synopt:{cmd:r(p2)}}P(Z >= z2){p_end}
{synopt:{cmd:r(D_f)}}difference in proportion with exposure{p_end}
{synopt:{cmd:r(Delta)}}Delta, tolerance level defining the equivalence interval; OR{p_end}
{synopt:{cmd:r(Du)}}Delta_upper, tolerance level defining the equivalence interval's upper side; AND{p_end}
{synopt:{cmd:r(Dl)}}Delta_lower, tolerance level defining the equivalence interval's lower side; OR{p_end}
{synopt:{cmd:r(epsilon)}}epsilon, tolerance level defining the equivalence interval{p_end}
{synopt:{cmd:r(eu)}}epsilon_upper, tolerance level defining the equivalence interval's upper side; AND{p_end}
{synopt:{cmd:r(el)}}epsilon_lower, tolerance level defining the equivalence interval's lower side{p_end}
{p2colreset}{...}


{title:Author}

{pstd}Alexis Dinno{p_end}
{pstd}Portland State University{p_end}
{pstd}alexis dot dinno at pdx dot edu{p_end}

{pstd}
Please contact me with any questions, bug reports or suggestions for 
improvement.{p_end}


{marker reference}{...}
{title:Reference}

{marker Edwards1948}{...}
{phang}
Edwards, A. 1948. Note on the "correction for continuity" in testing the 
significance of the difference between correlated proportions.  {it:Psychometrika} 
13: 185–187

{marker Liu2002}{...}
{phang}
Liu, J., et al., 2002. Tests for equivalence or non-inferiority for paired 
binary data.  {it:Statistics In Medicine} 21: 231–245.

{marker McNemar1947}{...}
{phang}
McNemar, Q. 1947. Note on the sampling error of the difference between 
correlated proportions or percentages.  {it:Psychometrika} 12: 153–157

{marker Schuirmann1987}{...}
{phang}
Schuirmann, D. A. 1987. A comparison of the two one-sided tests procedure and 
the power approach for assessing the equivalence of average bioavailability. 
{it:Pharmacometrics} 15: 657-680

{marker Tryon2008}{...}
{phang}
Tryon, W. W., and C. Lewis. 2008. An inferential confidence interval method of 
establishing statistical equivalence that corrects Tryon’s (2001) reduction 
factor. {it:Psychological Methods} 13: 272-277
{p_end}

{marker Yates1934}{...}
{phang}
Yates, F. 1934. Contingency tables involving small numbers and the Chi-squared 
test. {it: Supplement to the Journal of the Royal Statistical Society}. 1: 217-235


{title:Also See}

{psee}
{space 2}Help: {help pkequiv:pkequiv}, {help mcc:mcc}

