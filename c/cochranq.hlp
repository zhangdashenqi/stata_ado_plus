{smcl}
{* *! version 1.3.1  27apr2017}{...}
{cmd:help cochranq}
{hline}


{title:Title}

{p2colset 5 17 18 2}{...}
{p2col:{cmd:cochranq} {hline 2}}Cochran's {it:Q} test for proportion difference in blocked binary data{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:cochranq} {it:scorevar blockvar groupvar} {ifin} [{it:{help fweight}}] [, 
{opt m:a(method)} {opt e:s(method)} {opt noqtest} {opt nolabel} {opt wrap} {opt li:st}
{opt l:evel(#)} {opt copyleft}]


{synoptset 28 tabbed}{...}
{synopthdr:cochranq options}
{synoptline}
{syntab:Main}
{synopt :{opt m:a(method)}}which method to adjust for multiple comparisons{p_end}
{synopt :{opt e:s(method)}}choice of effect size calculations{p_end}
{synopt :{opt noqtest}}suppress Cochran's {it:Q} test output{p_end}
{synopt :{opt nolabel}}display {it:groupvar} values, rather than {it:groupvar} value labels{p_end}
{synopt :{opt wrap}}do not break wide tables{p_end}
{synopt :{opt li:st}}include results of pairwise tests in a list format.{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {opt level(95)}{p_end}
{synopt :{opt copyleft}}displays the GPL license for {cmd:cochranq}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{opt fweights} are allowed; see {help weight}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
Cochran's omnibus {it:Q} test is analogous to a {help anova:repeated measures ANOVA} for binary outcomes, 
and {cmd:cochranq} reports the results of Cochran's {it:Q} test {help cochranq##Cochran1950:1950} for 
proportion difference among {it:b} blocked binary outcomes across {it:k} groups.  

{pstd} The null hypothesis is that there is no difference in proportion of success (i.e. 
outcome = 1) between the {it:k} groups; Cochran's {it:Q} can be considered a 
generalization of {help mcc:McNemar's test} to an arbitrary number of groups.  In the 
syntax diagram above, {it:scorevar} refers to the variable recording the binary 
outcome, {it:blockvar} refers to the variable denoting the units being observed 
(e.g., test subjects), and {it:groupvar} refers to the different treatments, 
exposures, tasks, etc.  {cmd:cochranq} also calculates the non-asymptotic 
{it:p}-value for the {it:Q} statistic, which generally provides greater statistical 
power ({help cochranq##Mielke1995:Mielke and Berry, 1995}).  The use of {help weight:fweights} 
specifies the number of times an observed pattern of successes and failures 
across different groups is observed (e.g., see the structure of the {cmd:diphtheria.dta} 
data set and example command below).{p_end}

{pstd}
The non-asymptotic statistic is distributed using a variation on the Pearson Type III 
distribution, and the PDF of this distribution is numerically integrated over 
from -2/{it:gamma} to {it:Z} with 1,000 steps in order to calculate the {it:p}-value.  
Mielke and Berry  ({help cochranq##Mielke1995:1995}) write that "more information is 
available to the nonasymptotic approach.  Consequently, when the effective {it:n} is 
small, one cannot expect a result based on an infinite {it:n} to be appropriate. 
Because the Pearson type III distribution encompasses the chi-squared distribution 
as a special case, the nonasymptotic approach completely replaces the asymptotic 
approach."

{pstd}
{cmd:cochranq} presents a table of all {it:m} = {it:k}({it:k}-1)/2 {it:post hoc} 
pairwise tests using Cochran's {it:Q} with both groups in the pair (for the 
asymptotic {it:p}-values this is equivalent to {help mcc:McNemar's test} without 
continuity corrections. The {it:post hoc} tests may specify multiple comparisons 
adjustments using {opt ma()}, and {it:p}-values (adjusted or unadjusted) for 
both asymptotic (top) and non-asymptotic (bottom) distributions are presented (the 
{it:p}-values for the non-asymptotic tests are indicated with the label {cmd:na}).  
See {help cochranq##Remarks:Remarks} for consideration of situations where two or 
more pairwise comparisons have the same test statistic. When no discordant pairs 
are present in a {it:post hoc} test, missing test statistics and {it:p}-values are
reported.

{marker option}{...}
{title:Options}

{phang}{opt nolabel} causes the actual data codes to be displayed rather than the
value labels in the test output.{p_end}

{phang}{opt ma(method)} Specifies the method of adjustment used for multiple 
comparisons in {it:post hoc} pairwise tests, and must take one of the following 
values: {opt none}, {opt bonferroni}, {opt sidak}, {opt hs}, {opt hochberg}, {opt bh}, or {opt by}.  
{opt none} is the default method assumed if the {opt ma} option is omitted.  
These methods perform as follows:{p_end}

{p 8 8}{opt none} specifies no multiple comparisons adjustments be made.{p_end}

{p 8 8}{opt bonferroni} specifies the {browse "https://en.wikipedia.org/wiki/Family-wise_error_rate":family-wise error rate} 
(FWER) "Bonferroni adjustment", calculated by multiplying the {it:p}-values for 
each {it:post hoc} test by {it:m} (the total number of {it:post hoc} tests), as 
per Dunn ({help cochranq##Dunn1961:1961}).  {cmd:cochranq} will report a maximum 
Bonferroni-adjusted {it:p}-value of 1.  Those comparisons rejected with this method 
at the alpha level specified by {opt level()} are underlined in the output table, 
and starred in the list using the {opt li:st} option.{p_end}

{p 8 8}{opt sidak} specifies the "Sid{c a'}k adjustment" so that FWER is adjusted 
by multiplying the {it:p}-value of each {it:post hoc} test with 1 - (1 - {it:p})^{it:m} 
as per Sid{c a'}k ({help cochranq##Sidak:1967}).  {cmd:cochranq} will report a maximum 
Sid{c a'}k-adjusted {it:p}-value of 1.  Those comparisons rejected with this 
method at the alpha level specified by {opt level()} are underlined in the output 
table, and starred in the list using the {opt li:st} option.{p_end}

{p 8 8}{opt holm} specifies the "Holm adjustment" where the FWER is controlled by 
sequentially adjusting the {it:p}-values of each {it:post hoc} test, ordered 
from smallest to largest, with {it:p}({it:m}+1-{it:i}), where {it:i} is the ordered
position, as per Holm ({help cochranq##Holm1979:1979}).  {cmd:cochranq} reports a maximum 
Holm-adjusted {it:p}-value of 1.  In sequential tests the decision to reject or 
not reject the null hypothesis depends both on the {it:p}-values and 
their ordering, so those comparisons rejected with this method at the alpha level 
specified by {opt level()} are underlined in the output.{p_end}

{p 8 8}{opt hs} specifies the "Holm-Sid{c a'}k adjustment" where the FWER is 
controlled by sequentially adjusting the {it:p}-values of each {it:post hoc} 
test, ordered from smallest to largest, with 1 - (1 - {it:p})^({it:m}+1-{it:i}), 
where {it:i} is the ordered position (see {help cochranq##Holm1979:Holm, 1979}).  
{cmd:cochranq} reports a maximum Holm-Sid{c a'}k-adjusted {it:p}-value of 1.  
In sequential tests the decision to reject or not reject the null hypothesis 
depends both on the {it:p}-values and their ordering, so those comparisons 
rejected with this method at the alpha level specified by {opt level()} are 
underlined in the output.{p_end}

{p 8 8}{opt hochberg} specifies a "Hochberg adjustment" where the FWER is adjusted 
sequentially by adjusting the {it:p}-values of each pairwise test as 
ordered from largest to smallest with {it:p}*{it:i}, where {it:i} is the 
position in the ordering as per Hochberg ({help cochranq##Hochberg1988:1988}).  
{cmd:cochranq} reports a maximum Hochberg-adjusted {it:p}-value of 1.  In 
sequential tests the decision to reject the null hypothesis depends both on the 
{it:p}-values and their ordering, those comparisons rejected with this method at 
the alpha level specified by {opt level()} are underlined in the output.{p_end}

{p 8 8}{opt bh} specifies the "Benjamini-Hochberg adjustment" where the {browse "https://en.wikipedia.org/wiki/False_discovery_rate":false discovery rate} 
(FDR) is controlled by sequentially adjusting the {it:p}-values of 
each {it:post hoc} test, ordered from largest to smallest, with {it:p}[{it:m}/({it:m}+1-{it:i})], 
where {it:i} is the ordered position (see {help cochranq##Benjamini1995:Benjamini & Hochberg, 1995}).  
{cmd:cochranq} reports a maximum Benjamini-Hochberg-adjusted {it:p}-value of 1.   
FDR-adjusted {it:p}-values are at times referred to as {it:q}-values.  In 
sequential tests the decision to reject or not reject the null hypothesis depends 
both on the {it:p}-values and their ordering, so those comparisons rejected with 
this method at the alpha level specified by {opt level()} are underlined in the 
output.{p_end}

{p 8 8}{opt by} specifies the "Benjamini-Yekutieli adjustment" where the false 
discovery rate (FDR) is controlled by sequentiallyby adjusting the {it:p}-values of 
each pairwise test as ordered from largest to smallest with {it:p}[{it:m}/({it:m}+1-{it:i})]{it:C}, 
where {it:i} is the position in the ordering, and {it:C} = 1 + 1/2 + ... + 1/{it:m}
 (see {help cochranq##Benjamini2001:Benjamini & Yekutieli, 2001}).  Stata will 
report a maximum Benjamini-Yekutieli-adjusted {it:p}-value of 1.  Such 
FDR-adjusted {it:p}-values are sometimes referred to as {it:q}-values in the 
literature.  Because in sequential tests the decision to reject the null 
hypothesis depends both on the {it:p}-values and their ordering, those 
comparisons rejected with this method at the alpha level specified by {opt level()} are 
underlined in the output.{p_end}

{phang}{opt es(method)} specifies the method of calculation of effect size to 
be reported, and must take one of the following values: {opt none}, {opt scm}, 
or {opt bjm}.  {opt none} is the default method assumed if the {opt es} option is omitted.  
These methods perform as follows:{p_end}

{p 8 8}{opt none} specifies no effect size measure be reported.{p_end}

{p 8 8}{opt scm} specifies the Serlin, Carr and Marascuillo maximum-corrected 
effect size, {it:Q}/[{it:b}({it:k}-1)], be reported, as per Serlin, Carr and Marascuillo 
({help cochranq##Serlin2007:2007}).{p_end}

{p 8 8}{opt bjm} specifies the Berry, Johnston and Mielke chance-corrected 
effect size, {it:R} = 1 - delta/mu_delta, be reported, as per Berry, Johnston and 
Mielke ({help cochranq##Berry2007:2007}). {cmd:CAVEAT:} The example calculation 
in Berry, Johnston and Mielke's paper includes the figure mu_delta = {res:0.4521}, 
but Equation [7] contains a typographical error, and the first term should be 
2/[b(b-1)] rather than 2/[k(k-1)] (personal correspondence with Berry). {p_end}

{phang}{opt noqtest} suppresses the display of the omnibus Cochran's {it:Q} test table.{p_end}

{phang}{opt nolabel} causes the actual data codes to be displayed rather than the
value labels in the Cochran's {it:Q} test table.{p_end}

{phang}{opt wrap} requests that {cmd:cochranq} not break up wide tables to make
them readable.{p_end}

{phang}{opt list} requests that {cmd:conovertest} also provide a output in list form, 
one pairwise test per line.{p_end}

{phang}{opt level(#)} specifies the compliment of alpha*100.  The default, 
{opt level(95)} (or as set by {helpb set level}) corresponds to alpha = 0.05.

{phang}
{cmd:copyleft} displays the copying permission statement for {cmd:cochranq}.  
{cmd:cochranq} is free software, licensed under the GPL. The full license can 
be obtained by typing: 

{p 12 8 2}
{inp: . net describe cochranq, from (http://www.alexisdinno.com/stata)} 

{phang}
and clicking on the {net "describe cochranq, from (http://www.alexisdinno.com/stata)":click here to get} 
link for the ancillary file.


{marker Remarks}{...}
{title:Remarks}

{pstd}
The issue of tied multiple comparisons may arise when conducting {it:post hoc} tests 
following Cochran's {it:Q} test. This is because the score variable is nominal, 
and more than one pairwise test may share a specific value of {it:Q} due to having 
the same number of discordant pairs of observations. This is less likely to arise 
when {it:n}, or {it:k} or both are large. Tied test statistic values is an issue 
because several of the available multiple comparison procedures are {it:stepwise} 
procedures, which give different adjustments based on the position in the ordering of 
the {it:p}-values. It is unclear what the appropriate course of action is when 
attempting to use either the Holm or Holm-Sid{c a'}k FWER adjustments in the 
presence of ties. {cmd:cochranq} makes an arbitrary ordering of {it:p}-values 
when there are ties, and reports the adjusted accordingly, but users should 
interpret these numbers with caution.

{pstd}
This issue does not arise when adjusting using the FDR. From Korn, et al. ({help cochranq##Korn2004:2004}):

{p 8 8 8}
If the variables or p-values are discrete, there can be ties in the p-values 
given in (1), but this does not present a problem. Regardless of the ordering 
of the tied variables in (1), if the hypothesis associated with the first 
variable in the order is rejected, then the hypotheses associated with the other 
tied variables will also be rejected because the minimization (2) will be over 
smaller sets for the other variables. In addition, which of the tied variables 
is considered first for rejection will not matter, as the permutation 
distribution will include all of them when considering the first rejection. 
Also, if the first of the tied variables fails to reject, the procedure ceases 
and no further hypotheses are rejected, so that the situation in which the 
first tied variable fails to reject, and the later tied variables do reject, 
need not be considered.


{marker example}{...}
{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. use diphtheria}{p_end}

{pstd}Test for proportion difference of culture growth by growth media{p_end}
{phang2}{cmd:. cochranq growth cases media [fw=ncases]} {p_end}

{pstd}Setup{p_end}
{phang2}{cmd:. use motorskills}{p_end}

{pstd}Test for proportion difference of task completion by motor skill type{p_end}
{phang2}{cmd:. cochranq score subject task}

{pstd}Setup{p_end}
{phang2}{cmd:. use psychgrads}{p_end}

{pstd}Test for proportion difference of diagnosis by script, with effect size{p_end}
{phang2}{cmd:. cochranq diagnosis student script, es(bjm)}


{title:Author}

{pstd}Alexis Dinno{p_end}
{pstd}Portland State University{p_end}
{pstd}alexis.dinno@pdx.edu{p_end}

{pstd}
Please contact me with any questions, bug reports or suggestions for 
improvement. Fixing bugs will be facilitated by sending along (1) a copy of 
the data (de-labeled or anonymized is fine) in Stata .dta file format, (2) a 
copy of the command used and (3) a copy of the exact output of the command.{p_end}


{title:Suggested citation}

{p 4 8}
Dinno A. 2017. {bf:cochranq}: Cochran's {it:Q} test for proportion difference 
in blocked binary data. Stata software package. URL: {view "http://www.alexisdinno.com/stata/cochranq.html"}


{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:cochranq} saves the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(Q)}}Cochran's {it:Q} statistic{p_end}
{synopt:{cmd:r(b)}}the number of blocks (subjects) in the test{p_end}
{synopt:{cmd:r(k)}}the number of treatments (groups) in the test{p_end}
{synopt:{cmd:r(df)}}degrees of freedom for the test{p_end}
{synopt:{cmd:r(p_asymp)}}{it:p}-value for the asymptotic test{p_end}
{synopt:{cmd:r(p_nonasymp)}}{it:p}-value for the nonasymptotic test{p_end}
{synopt:{cmd:r(Z)}}the standardized {it:z} test statistic{p_end}
{synopt:{cmd:r(gamma)}}the gamma parameter for the Pearson Type III distribution approximating the exact permutation distribution of {it:Z}{p_end}
{synopt:{cmd:r(X2)}}An {it:m} length vector of pairwise Q statistics (chi-squared statistics).{p_end}
{synopt:{cmd:r(P_asymp)}}An {it:m} length vector of asymptotic {it:p}-values for pairwise tests.{p_end}
{synopt:{cmd:r(P_nonasymp)}}An {it:m} length vector of non-asymptotic {it:p}-values for pairwise tests.{p_end}
{p2colreset}{...}


{title:References}

{marker Benjamini1995}{...}
{phang}Benjamini, Y. and Hochberg, Y. 1995. {browse "http://www.jstor.org/stable/2346101?seq=1#page_scan_tab_contents":Controlling the False Discovery Rate: A Practical and Powerful Approach to Multiple Testing}.  
{it:Journal of the Royal Statistical Society. Series B (Methodological)}. 57: 289-300.{p_end}

{marker Benjamini2001}{...}
{phang}Benjamini, Y. and Yekutieli, D. 2001. {browse "http://www.jstor.org/stable/2674075?seq=1#page_scan_tab_contents":The control of the false discovery rate in multiple testing under dependency}.  {it:Annals of Statistics}. 29: 1165-1188.{p_end}

{marker Berry2007}{...}
{phang}Berry, K. J., Johnston, J. E., and Mielke, Jr., P. W. 2007. {browse "http://journals.sagepub.com/doi/pdf/10.2466/pms.104.4.1236-1242":An alternative measure of effect size for Cochran's {it:Q} test for related proportions}.  
{it:Perceptual and Motor Skills}. 104: 1236-1242.{p_end}

{marker Cochran1950}{...}
{phang}Cochran, W. G. 1950.  {browse "http://www.jstor.org/stable/2332378":The comparison of percentages in matched samples}.  
{it:Biometrika}, 37: 256-266.{p_end}

{marker Dunn1961}{...}
{phang}Dunn, O. J. 1961. {browse "http://amstat.tandfonline.com/doi/abs/10.1080/01621459.1961.10482090":Multiple comparisons among means}.  
{it:Journal of the American Statistical Association}.  56: 52-64.{p_end}

{marker Hochberg1988}{...}
{phang}Hochberg, Y. 1988. {browse "https://academic.oup.com/biomet/article-abstract/75/4/800/423177/A-sharper-Bonferroni-procedure-for-multiple-tests":A sharper Bonferroni procedure for multiple tests of significance}.  {it:Biometrika}. 75: 800-802.{p_end}

{marker Holm1979}{...}
{phang}Holm, S. 1979. {browse "http://www.jstor.org/stable/4615733":A simple sequentially rejective multiple test procedure}.  
{it:Scandinavian Journal of Statistics}.  6: 65-70.{p_end}

{marker Korn2004}{...}
{phang}Korn, E. L., Troendle, J. F., McShane, L. M., and Simon, R. 2004. 
{browse "http://www.sciencedirect.com/science/article/pii/S0378375803002118":Controlling the number of false discoveries: application to high-dimensional genomic data}.  
{it:Journal of Statistical Planning and Inference}.  124: 379-398.{p_end}

{marker Mielke1995}{...}
{phang}Mielke, P. W. and Berry, K. J. 1995.  {browse "http://journals.sagepub.com/doi/abs/10.2466/pms.1995.81.1.319":Nonasymptotic inferences based on Cochran’s {it:Q} test}.  
{it:Perceptual and Motor Skills}, 81: 319-322.{p_end}

{marker Sidak1967}{...}
{phang}Sid{c a'}k, Z. 1967. {browse "http://amstat.tandfonline.com/doi/abs/10.1080/01621459.1967.10482935":Rectangular confidence regions for the means of multivariate normal distributions}.  
{it:Journal of the American Statistical Association}.  62: 626-633.{p_end}

{marker Serlin2007}{...}
{phang}Serlin, R. C., Carr, J., and Marascuillo, L. A. 2007. {browse "http://psycnet.apa.org/journals/bul/92/3/786/":A measure of association for selected nonparametric procedures}.  
{it:Psychological Bulletin}. 92: 786-790.{p_end}


{title:Also See}

{psee}
{space 2}Help: {help anova:anova}, {help kwallis:kwallis}


