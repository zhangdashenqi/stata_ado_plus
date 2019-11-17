{smcl}
{* *! version 1.4.1  01mar2014}{...}
{cmd:help tostpr}
{hline}


{title:Title}

{p2colset 5 15 15 2}{...}
{p2col:{cmd:tostpr} {hline 2}}One- and two-sample z tests of proportion-equivalence{p_end}
{p2colreset}{...}


{title:Syntax}

{pstd}
One-sample proportion-equivalence z test

{p 8 14 2}
{cmd:tostpr} {varname} {cmd:==} {it:#} {ifin}
        [{cmd:,} {opt eqvt:ype(type)}
        {opt eqvl:evel(#)}
        {cmd: {ul on}upper{ul off}eqvlevel(}{it:#}{cmd:)}        
        {cmd:{ul on}l{ul off}evel(}{it:#}{cmd:)}]


{pstd}
Two-sample proportion-equivalence z test

{p 8 14 2}
{cmd:tostpr} {varname:1} {cmd:==} {varname:2} {ifin}
        [{cmd:,} {opt eqvt:ype(type)}
        {opt eqvl:evel(#)} {opt y:ates} {opt ha}
        {cmd: {ul on}upper{ul off}eqvlevel(}{it:#}{cmd:)}        
        {cmd:{ul on}l{ul off}evel(}{it:#}{cmd:)}]


{pstd}
Two-group proportion-equivalence z test

{p 8 14 2}
{cmd:tostpr} {varname} {ifin}
        {cmd:, }{opth by:(varlist:groupvar)}
        [{opt eqvt:ype(type)}
        {opt eqvl:evel(#)}
        {cmd: {ul on}upper{ul off}eqvlevel(}{it:#}{cmd:)}        
        {opt y:ates} {opt ha}
        {cmd:{ul on}l{ul off}evel(}{it:#}{cmd:)}]


{phang}
Immediate form of one-sample z test of proportion-equivalence

{p 8 16 2}
{cmd:tostpri} {it:#obs1} {it:#p1} {it:#p2} 
        [, {opt eqvt:ype(type)}
        {opt eqvl:evel(#)}
        {cmd: {ul on}upper{ul off}eqvlevel(}{it:#}{cmd:)}        
        {opt l:evel(#)} {opt c:ount}]


{phang}
Immediate form of two-sample z test of proportion-equivalence

{p 8 16 2}{cmd:tostpri} {it:#obs1} {it:#p1} {it:#obs2} {it:#p2} 
        [{cmd:,} {opt eqvt:ype(type)}
        {opt eqvl:evel(#)} 
        {cmd: {ul on}upper{ul off}eqvlevel(}{it:#}{cmd:)}        
        {opt y:ates} {opt ha} {opt l:evel(#)} {opt c:ount}]


{phang}
{cmd:by} is allowed with the non-immediate form of {cmd:tostpri}; see 
{manhelp by D}.


{synoptset 28 tabbed}{...}
{synopthdr:tostpr & tostpri options}
{synoptline}
{syntab:Miscellaneous}
{synopt :{opt eqvt:ype(string)}}specify equivalence threshold with Delta or epsilon{p_end}
{synopt :{opt eqvl:evel(#)}}the level of tolerance defining the equivalence interval{p_end}
{synopt :{opt upper:eqvlevel(#)}}the upper value of an asymmetric equivalence interval{p_end}
{synopt :{opth by:(varlist:groupvar)}}variable defining the two groups{p_end}
{synopt :{opt c:ount}}integers, not proportions are used with {cmd: tostpri}{p_end}
{synopt :{opt ya:tes}}use the Yates continuity correction{p_end}
{synopt :{opt ha}}use the Hauck-Anderson continuity correction{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {opt level(95)}{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:tostpr} tests for the equivalence of proportions within a symmetric 
equivalence interval defined by {opt eqvt:ype} and {opt eqvl:evel} using a two 
one-sided z tests approach ({help tostpr##Hauck1984:Hauck and Anderson, 1984}; 
{help tostpr##Schuirmann1987:Schuirmann, 1987}).  Typically null hypotheses are 
framed from an assumption of a lack of difference between two quantities, and 
reject this assumption only with sufficient evidence.  When performing tests
of equivalence, one frames a null hypothesis with the assumption that two 
quantities are different within an equivalence interval defined by some chosen 
level of tolerance (as specified by {opt eqvl:evel}).{p_end}

{pstd}
With respect to a z test of proportions, an equivalence null hypothesis takes 
one of the following two forms depending on whether equivalence is defined in 
terms of Delta (equivalence expressed in the same units as prop(x) and prop(y) 
or in terms of epsilon (equivalence expressed in the units of the z 
distribution):{p_end}

{p 8}
Ho: |prop(x) - prop(y)| >= Delta, {p_end}
{p 8 8}where the equivalence interval ranges from diff-Delta to diff+Delta, and 
where diff is the difference in proportions. This translates  directly into two 
one-sided null hypotheses: {p_end}

{p 12}
Ho1: Delta - [prop(x) - prop(y)] <= 0; and{p_end}

{p 12}
Ho2: [prop(x) - prop(y)] + Delta <= 0{p_end}

{p 8}
-OR-

{p 8}
Ho: |z| >= epsilon, {p_end}
{p 8 8}where the equivalence interval ranges from -epsilon to epsilon. This also 
translates directly into two one-sided null hypotheses: {p_end}

{p 12}
Ho1: epsilon - z <= 0; and{p_end}

{p 12}
Ho2: z + epsilon <= 0{p_end}

{p 8 8}
When an asymmetric equivalence interval is defined using the {opt upper:eqvlevel} option 
the general negativist null hypothesis becomes:{p_end}

{p 8}
Ho: [prop(x) - prop(y)] <= Delta_lower, or [prop(x) - prop(y)] >= Delta_upper,{p_end}
{p 8 8 }
where the equivalence interval ranges from [prop(x) - prop(y)]+Delta_lower to 
[prop(x) - prop(y)]+Delta_upper. This also translates directly into two 
one-sided null hypotheses:{p_end}

{p 12}
Ho1: Delta_upper - [prop(x) - prop(y)] <= 0; and{p_end}

{p 12}
Ho2: [prop(x) - prop(y)] - Delta_lower <= 0{p_end}

{p 8}
-OR-

{p 8}
Ho: z <= epsilon_lower, or z >= epsilon_upper, and{p_end}

{p 12}
Ho1: epsilon_upper - z <= 0; and{p_end}

{p 12}
Ho2: z - epsilon_lower <= 0{p_end}

{pstd}
NOTE: the appropriate level of alpha is precisely the same as in the 
corresponding two-sided test of proportion difference, so that, for example, if 
one wishes to make a Type I error %5 of the time, one simply conducts both of 
the one-sided tests of Ho1 and Ho2 by comparing the resulting p-value to 0.05 
({help tostpr##Tryon2008:Tryon and Lewis, 2008}).{p_end}


{title:Options}

{dlgtab:Main}

{phang}
{opth eqvt:ype(string)} defines whether the equivalence interval will be 
defined in terms of Delta or epsilon ({opt delta}, or {opt epsilon}). These 
options change the way that {opt evql:evel} is interpreted: when {opt delta} is 
specified, the {opt evql:evel} is measured in the units of the proportion of the 
variable being tested, and when {opt epsilon} is specified, the {opt evql:evel} 
is measured in multiples of the standard deviation of the z distribution; put 
another way epsilon = Delta/standard error. The default is {opt delta}.{p_end}

{marker mineqvlevel}{...}
{p 8 8}
Defining tolerance in terms of epsilon means that it is not possible to reject 
any test of mean equivalence Ho if epsilon <= the critical value of z for a 
given alpha. Because epsilon = Delta/standard error, we can see that it is not 
possible to reject any Ho if Delta <= the product of the standard error and 
critical value of z for a given alpha. {cmd: tostpr} and {cmd: tostpri} now report 
when either of these conditions obtain.{p_end}

{phang}
{opth eqvl:evel(#)} defines the equivalence threshold for the tests depending on 
whether {opt eqvt:ype} is {opt delta} or {opt epsilon} (see above). Researchers 
are responsible for choosing meaningful values of Delta or epsilon. The default 
value is 0.1 when {opt delta} is the type, and is 2 when {opt epsilon} is the type.{p_end}

{phang}
{opt upper:eqvlevel(#)} defines the {it: upper} equivalence threshold for the test, 
and transforms the meaning of {opt eqvl:evel} to mean the {it: lower} equivalence 
threshold for the test. Also, {opt eqvl:evel} is assumed to be a negative value. 
Taken together, these are analogous to Schuirmann's ({help tostt##Schuirmann1987:1987}) 
asymmetric equivalence intervals. If {opt upper:eqvlevel}==|{opt eqvl:evel}|, then 
{opt upper:eqvlevel} will be ignored.{p_end}

{phang}
{opth by:(varlist:groupvar)} specifies the {it:groupvar} that defines the two
groups that {cmd:tostpr} will use to test the hypothesis that their proportions 
are different.  Specifying {opt by(groupvar)} implies a two sample z test.  
Do not confuse the {opt by()} option with the {cmd:by} prefix; you can specify 
both.{p_end}

{phang}
{opt c:ount} specifies that integer counts instead of proportions be used with 
{cmd: tostpri}.  In the first syntax, {cmd: tostpri} expects that {it: #obs1} and 
{it: #p1} are counts -- {it: #p1} < {it: #obs1} -- and {it: #p2} is a proportion. 
In the second syntax, {cmd: tostpri} expects that all four numbers are integer 
counts, that {it: #obs1} > {it: #p1}, and that {it: #obs2} > {it: #p2}.

{phang}
{opt yates} specifies that the test statistics incorporate the Yates continuity 
correction ({help tostpr##Yates1934:Yates 1934}). This option is included for convenience 
althouth the Hauck-Anderson correction (see {opt ha}) is preferred ({help tostpr##Tu1997:Tu 1997}).

{phang}
{opt ha} specifies that the test statistics incorporate the Hauck-Anderson 
continuity correction ({help tostpr##Hauck1986:Hauck and Anderson 1986}). This is the preferred 
continuity correction option ({help tostpr##Tu1997:Tu 1997}).

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence
intervals.  The default is {opt level(95)} or as set by {helpb set level}.


{title:Remarks}

{pstd}
As described by Tryon and Lewis ({help tostpr##Tryon2008:Tryon and Lewis 2008}), when both 
tests of difference and equivalence are taken together, there are four possible 
interpretations:{p_end}

{p 4 8 2}
1.  One may reject the null hypothesis of no difference, but fail to reject the 
null hypothesis of difference, and conclude that there is a {it: relevant difference} 
in proportions at least as large as Delta or epsilon.{p_end}

{p 4 8 2}
2.  One may fail to reject the null hypothesis of no difference, but reject the 
null hypothesis of difference, and conclude that the proportions are {it: equivalent} 
within the equivalence range (i.e. defined by Delta or epsilon).{p_end}

{p 4 8 2}
3.  One may reject {it:both} the null hypothesis of no difference and the null 
hypothesis of difference, and conclude that the proportions are {it: trivially different}, 
within the equivalence range (i.e. defined by Delta or epsilon).{p_end}

{p 4 8 2}
4.  One may fail to reject {it:both} the null hypothesis of no difference and the 
null hypothesis of difference, and draw an {it: indeterminate} conclusion, because 
the data are underpowered to detect difference or equivalence.{p_end}


{title:Examples}

{pstd}
These examples correspond to those written in the help file for 
{help prtest:prtest}:{p_end}

    {cmd:. sysuse auto}                                         (setup)
    {inp:. tostpr foreign==.4, eqvt(delta) eqvl(.15) upper(.2)} (one-sample proportion-equivalence test)

    {cmd:. webuse cure}                                         (setup)
    {cmd:. tostpr cure1==cure2, eqvt(epsilon) eqvl(2.5)}        (two-sample proportion-equivalence test)

    {cmd:. webuse cure2}                                        (setup)
    {cmd:. tostpr cure, by(sex) ha}                             (two-group proportion-equivalence test)
                                                                ({cmd:cure} has same proportion for males and females)
                                                                (inlcudes Hauck-Anderson continuity correction)

    {cmd:. tostpri 50 .52 .70, eqvt(delta) eqvl(.1)}            (immediate form of one-sample test of proportion-equivalence)
                                                                (note warning about value of Delta!)

    {cmd:. tostpri 30 4  .7, count eqvt(epsilon) eqvl(2)}       (first two numbers are counts)

    {cmd:. tostpri 30 .4  45 .67, eqvt(delta) eqvl(.2)}         (immediate form of two-sample test of proportion-equivalence)

    {cmd:. tostpri 30 4  45 17, count eqvt(delta) eqvl(.2)}      (all numbers are counts)


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
The one-sample forms of {cmd:tostpr} and {cmd:tostpri} saves the following in 
{cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(z2)}}z statistic under Ho2{p_end}
{synopt:{cmd:r(z1)}}z statistic under Ho1{p_end}
{synopt:{cmd:r(P_1)}}proportion for variable 1{p_end}
{synopt:{cmd:r(N_1)}}number of observations for variable 1{p_end}
{synopt:{cmd:r(Delta)}}Delta, tolerance level defining the equivalence interval; OR{p_end}
{synopt:{cmd:r(Du)}}Delta_upper, tolerance level defining the equivalence interval's upper side; AND{p_end}
{synopt:{cmd:r(Dl)}}Delta_lower, tolerance level defining the equivalence interval's lower side; OR{p_end}
{synopt:{cmd:r(epsilon)}}epsilon, tolerance level defining the equivalence interval{p_end}
{synopt:{cmd:r(eu)}}epsilon_upper, tolerance level defining the equivalence interval's upper side; AND{p_end}
{synopt:{cmd:r(el)}}epsilon_lower, tolerance level defining the equivalence interval's lower side{p_end}
{p2colreset}{...}

{pstd}
The two-sample and two-group forms of {cmd:tostpr} and {cmd: tostpri} save the 
following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(z2)}}z statistic under Ho2{p_end}
{synopt:{cmd:r(z1)}}z statistic under Ho1{p_end}
{synopt:{cmd:r(P_2)}}proportion for variable 2{p_end}
{synopt:{cmd:r(N_2)}}number of observations for variable 2{p_end}
{synopt:{cmd:r(P_1)}}proportion for variable 1{p_end}
{synopt:{cmd:r(N_1)}}number of observations for variable 1{p_end}
{synopt:{cmd:r(Delta)}}Delta, tolerance level defining the equivalence interval; OR{p_end}
{synopt:{cmd:r(Du)}}Delta_upper, tolerance level defining the equivalence interval's upper side; AND{p_end}
{synopt:{cmd:r(Dl)}}Delta_lower, tolerance level defining the equivalence interval's lower side; OR{p_end}
{synopt:{cmd:r(epsilon)}}epsilon, tolerance level defining the equivalence interval{p_end}
{synopt:{cmd:r(eu)}}epsilon_upper, tolerance level defining the equivalence interval's upper side; AND{p_end}
{synopt:{cmd:r(el)}}epsilon_lower, tolerance level defining the equivalence interval's lower side{p_end}
{p2colreset}{...}


{title:References}

{marker Hauck1984}{...}
{phang}
Hauck, W. W. and S. Anderson. 1984. A new statistical procedure for testing 
equivalence in two-group comparative bioavailability trials. 
{it:Journal of Pharmacokinetics and Pharmacodynamics}. 12: 83-91

{marker Hauck1986}{...}
{phang}
Hauck, W. W. and Anderson, S. 1986. A comparison of large-sample confidence 
interval methods for the difference of two binomial probabilities. 
{it: The American Statistician}, 40: 318-322.

{marker Schuirmann1987}{...}
{phang}
Schuirmann, D. A. 1987. A comparison of the two one-sided tests procedure and 
the power approach for assessing the equivalence of average bioavailability. 
{it:Pharmacometrics}. 15: 657-680

{marker Tryon2008}{...}
{phang}
Tryon, W. W., and C. Lewis. 2008. An inferential confidence interval method of 
establishing statistical equivalence that corrects Tryon’s (2001) reduction 
factor. {it:Psychological Methods}. 13: 272-277

{marker Tu1997}{...}
{phang}
Tu, D. 1997. Two one-sided tests procedures in establishing therapeutic 
equivalence with binary clinical endpoints: Fixed sample performances and sample 
size determination. {it: Journal of Statistical Computing and Simmulation}. 59: 
271-290

{marker Yates1934}{...}
{phang}
Yates, F. 1934. Contingency tables involving small numbers and the Chi-squared 
test. {it: Supplement to the Journal of the Royal Statistical Society}. 1: 217-235

{title:Also See}

{psee}
{space 2}Help: {help pkequiv:pkequiv}, {help prtest:prtest}

