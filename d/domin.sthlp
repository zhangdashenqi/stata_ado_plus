{smcl}
{* *! version 3.0 15 Jan 2014 J. N. Luchman}{...}
{cmd:help domin}
{hline}{...}

{title:Title}

{pstd}
Dominance analysis{p_end}

{title:Syntax}

{phang}
{cmd:domin} {it:depvar} [{it:indepvars} {ifin} {weight} {cmd:,} 
{opt {ul on}f{ul off}itstat(summstat)} {opt {ul on}r{ul off}eg(estcmd, options)} 
{opt {ul on}s{ul off}ets((varlist) (varlist) ...)} {opt {ul on}a{ul off}ll(varlist)} 
{opt {ul on}nocond{ul off}itional} {opt {ul on}nocom{ul off}plete} {opt {ul on}eps{ul off}ilon} 
{opt mi} {opt miopt(mi_est_opts)} {opt {ul on}cons{ul off}model}]

{phang}{cmd:pweight}s, {cmd:aweight}s, {cmd:iweight}s, and {cmd:fweight}s are allowed but must be able to be used by the 
estimation command in {opt reg()}, see help {help weights:weights}.  {help Factor variables} are also allowed, but can only 
be included in the {opt all(varlist)} and {opt sets((varlist) (varlist) ...)} options and, like weights, must be accepted by 
the estimation command in {opt reg()}.

{title:Description}

{pstd}
Dominance analysis is most useful for discerning the relative importance of  independent variables or independent variable sets
in an estimation model (see Gr{c o:}mping, 2007 for a discussion) based on overall model fit statistics.  Dominance analysis is based 
on comparisons and combinations of fit statistics from an each subset regression. Therefore, for {it:p} independent variables, there are 
regressions for all 2^{it:p}-1 combinations of independent variables (see Budescu, 1993). {cmd:domin} has 3 main statistics it produces 
from the 2^{it:p}-1 regressions. 

{pstd}
The most commonly used and reported form of dominance is {it:general dominance}. General dominance is the weakest dominance or relative 
importance criterion for independent variables as it averages across all possible incremental/marginal contributions an independent varaible 
makes to overall model fit.  That is, general dominance is an average of all possible combinations of models including (and not including) 
the focal independent variable.  Although the weakest criterion, general dominance can almost always prodice a rank ordering of independent variable 
importance.  Additionally, general dominance produces an additive decomposition (i.e., the weights can be summed to obtain the value of the full
model's fit statistic) of a fit statistic and is equivalent to Shapley value decomposition (see {stata findit shapley}).  Each independent 
variable receives a single general dominance weight ascribing it a component of the fit statistic.  Independent variables with larger general 
dominance weights are said to "generally dominate" independent variables with smaller general dominance weights. 

{pstd}
Another dominance statistic is {it:conditional dominance}.  Conditional dominance is a stronger criterion than general dominance as it allows for 
more specific comparisons and is less "averaged".  Specifically, conditional dominance weights are averaged incremental contributions to a fit 
statistic within a single order (i.e., within a number of independent variables in an estimation model).  Therefore, all independent variables will have 
conditional dominance weights equal to the number of independent variables in the model.  Thus, using conditional dominance weights, the user 
can discern how and where the relative importance of an independent variable changes as more independent variables are included in an estimation 
model. If an independent variable has a larger conditional dominance weight than another independent variable across {it:all} orders, the focal 
independent variable is said to "conditionally dominate" the comparison indepdendent variable.  Averaging across all conditional dominance weights 
within an independent variable produces the general dominance weight for that independent variable.

{pstd}
Finally, the strongest criterion is {it:complete dominance}.  Complete dominance is a qualitative designation only and, thus, does not produce a 
statistic per se.  Complete dominance compares the incremental contribution of each independent variable to each other independent variable
conditional on all other combinations of independent variables in the estimation model.  If a focal independent variable {it:always} produces a 
larger increment to the fit statistic irrespective of the model (i.e., conditional on the same independent variables) than a comparison independent 
variable, the focal independent variable is said to "completely dominate" the other, comparison independent variable.  The complete dominance 
matrix returned by {cmd:domin} reads from the left to right.  Thus, a value of 1 means that the indepdendent variable in the row completely 
dominates the independent variable in the column. Conversely, a value of -1 means the opposite, that the independent variable in the row is 
completely dominated by the independent variable in the column.  A 0 value means no complete dominance designation could be made as the 
comparison independent variables' incremental contributions differ in relative magnitude from model to model.

{pstd}
{cmd:domin} produces 2 general dominance weights in the output.  The first coefficient vector produced (i.e., "Dominance Weight" vector) is the 
general dominance weights produced by additive decomposition of the overall fit statistic.  The second coefficient vector produced (i.e., 
"Standardized Weight" vector) is the general dominance weight vector normed or standardized to be out of 100%.  The final column is a ranking 
or the relative importance of the independent variables based on the general dominance weights.  The conditional and complete dominance 
statistics are displayed below the general dominance statistics and, as outlined above, provide for more nuanced and stronger statements about 
relative importance.  

{pstd}
{cmd:Important Notes:} it is the responsibility of the user to supply {cmd:domin} with an overall fit statistic that can be validly dominance analyzed.  
Traditionally, only R2 and pseudo-R2 statistics have been used - but {cmd:domin} was written with extensibility in mind and any statistic {it:could} 
potentially be used.  Arguably, the most important criteria for a fit statistic to be validly dominance analyzed when not a R2-like statistic are a] 
{it:monononicity} or that the fit statistic will not decrease with inclusion of more independent variables (without a degree of freedom adjustment 
such as those in information criteria), b] {it:linear invariance} or that the fit statistic is invariant/unchanged for non-singular transformations 
of the independent variables, and c] {it:information content} or interpretation of the fit statistic as providing information about model fit.  
Although other statistics can be used, {cmd:domin} does assume that the fit statistic supplied {it:acts} like an R2 statistic.  Thus, {cmd:domin} assumes
that better fit is associated with higher levels of the fit statistic and all marginal contributions can be obtained by subtraction.  For model fit 
statistics that decrease with better fit (i.e., AIC, BIC, deviance), the interpretation of the dominance relationships need to be reversed (see Examples #7 and #9).  
Additionally, it is the responsibility of the user to provide {cmd:domin} with predictor combinations that can be validly dominance analyzed.  
That is, including products of variables and individual dummy codes from a dummy code set can produce invalid dominance analysis results.  If 
an independent variable should not be analyzed {it:by itself} in a regression model, than it should not be included in the {it:varlist} and the 
user should consider using a {opt sets()} specification.  {cmd:domin} requires installation of Ben Jann's {cmd:moremata} package 
(install here: {stata ssc install moremata}).

{marker options}{...}
{title:Options}

{phang}{opt fitstat(summstat)} specifies the scalar valued model fit summary statistic that {cmd:domin} searches for and uses as the basis for 
the dominance analysis.  {cmd:domin} defaults to {opt fitstat(e(r2))} and will produce a warning.

{phang}{opt reg(estcmd, options)} specifies the regression command to be dominance analyzed - which can include any user written program.  
User-written programs must follow the traditional {it: cmd depvar indepvars} syntax.  {opt reg()} also allows the user to pass options for the 
estimation command used by {cmd:domin}.  When a comma is added in {opt reg()}, all the syntax following the comma will be passed to each run of 
the estimation command as options. {cmd:domin} defaults to {opt reg(regress)} and will produce a warning.

{phang}{opt sets()} binds together independent variables as a set in the each subset regression. Hence, all variables in a set will always appear 
together and are considered a single independent variable in the each subset regression. 

{phang}The user can specify as many sets of arbitrary size as is desired and the basic syntax follows: {opt sets((x1 x2) (x3 x4))}; this will create 
two sets (denoted "set1" and "set2" in the output).  set1 will created from the variables x1 and x2 whereas set2 will be created from the variables 
x3 and x4.  All sets must be bound by parentheses - thus, each set must begin with a left paren "(" and end with a right paren ")" and all 
parentheses separating sets in the {opt sets()} option syntax must be separated by at least one space.

{phang}The {opt sets()} option is useful for obtaining dominance weights and criteria for independent variables that are conceptually inseparable, 
such as dummy or effects codes sets, can be included together in the dominance analysis using the {opt sets()} 
option.  {help Factor variables} can be included in any {opt sets()} (see Example #3 below).

{phang}{opt all()} includes a set of independent variables in all 2^{it:p}-1 regressions.  Thus, all independent variables included in the 
{opt all()} option are used as a set of covariates that do not receive dominance weights and are not directly considered in dominance criteria.  
Rather, the magnitude of the R2 associated with the independent variables in the {opt all()} option are removed from the dominance computations 
for all variables in the {it:varlist} and sets of independent variables included in the {opt sets()} option.  The {opt all()} option accepts 
{help factor variables} (see Example #2 below).

{phang}{opt noconditional} suppresses the computation of the conditional dominance matrix.  Suppressing the computation of the conditional dominance
table can save computation time when conditional dominance criteria are not desired.

{phang}{opt nocomplete} suppresses the computation of the complete dominance matrix.  Suppressing the computation of the complete dominance
table can save computation time when complete dominance criteria are not desired.  Because complete dominance is a time intensive process, 
conducting 2^({it:p}-2) comparisons, the {opt nocomplete} option can also save computation time with a number of predictors or predictor sets.

{phang}{opt epsilon} is a faster version of dominance analysis (i.e., relative weights or "epsilon"; Johnson, 2000).  {opt epsilon} obviates the 
each subset regression by orthogonalizing independent variables using singular value decomposition (see {help matrix svd}).  {opt epsilon}'s 
singular value decomposition approach is not equivalent to the each subset regression approach but is many fold faster for models with many 
independent variables and tends to produce similar answers regarding relative importance (LeBreton, Ployhart, & Ladd, 2004).  {opt epsilon} also 
does not allow the use of {opt all()}, {opt sets()}, or {opt mi} and only produces general dominance weights (i.e., requires {opt noconditional} 
and {opt nocomplete}).  Currently, {opt epsilon} assumes {opt reg(regress)} and {opt fitstat(e(r2))}.

{phang}{opt mi} invokes Stata's {help mi} options within {cmd:domin}.  Thus, each analysis is run using the {cmd:mi estimate} prefix and all 
the {opt fitstat()} statistics returned by the analysis program are averaged (see Example #10 below).  

{phang}{opt miopt()} includes options in {cmd:mi estimate} within {cmd:domin}.  Each analysis is passed the options in {opt miopt()} and each of
the entries in {opt miopt()} must be a valid option for {cmd:mi estimate}.  Invoking {opt miopt()} without {opt mi} turns {opt mi} on and produces
a warning.

{phang}{opt consmodel} adjusts all fit statistics for a baseline level of the fit statistic in {opt fitstat()}.  {opt consmodel} is useful for 
model fit statistics that are not 0 when a constant-only model is estimated (e.g., AIC, BIC) and the user wants to discern marginal contributions 
above the constant-only baseline.

{title:Final Remarks}

{phang}Some users may be interested in obtaining relative importance comparisons for interactions, non-linear variables, as well as for indicator 
variables or dummy codes (i.e., any variable that can be constructed by a {help factor variable}).  Whereas dummy codes should be included together 
in a {opt sets()} set, users can follow the residualization method laid out by LeBreton, Tonidandel, and Krasikova (2013; see Example #4) to 
obtain relative importance of interaction and non-linear variables.

{phang}{cmd:domin} can also produce standard errors using {help bootstrap}ping (see Example #5).  Although standard errors {it:can} be produced, 
the properties of standard errors for dominance weights have not been extensively studied, tend to have low statistical power, and some argue are 
not particularly meaningful (see Gr{c o:}mping, 2007).  {help permute} tests are also conceptually applicable to dominance weights as well.

{phang}{cmd:domin} comes with 2 wrapper programs {cmd:mvdom} and {cmd:mixdom}.  {cmd:mvdom} implements multivariate regression-based dominance analysis
described by Azen and Budescu (2006; see {help mvdom}).  {cmd:mixdom} implements linear mixed effects regression-based dominance analysis 
described by Luo and Azen (2013; see {help mixdom}).  Both programs are intended to be used as wrappers into {cmd:domin} and serve to illustrate 
how the user can also adapt existing regressions (by Stata Corp or user-written) to evaluate in a relative importance analysis when they do not 
follow the traditional {it:depvar indepvars} format.  As long as the wrapper program can be expressed in some way that can be evaluated in 
{it:depvar indepvars} format, any analysis could be dominance analyzed. 

{phang}Any program used by as a wrapper by {cmd:domin} must accept at least one optional argument and must accept an {help if} statement in its 
{help syntax} line.

{phang}{cmd:domin} does not directly accept the {help svy} prefix - but does accept {cmd:pweight}s.  Because {cmd:domin} does not produce standard 
errors by defualt, to respect the sampling design for complex survey data the user need only provide {cmd:domin} the {cmd:pweight} variable for 
commands that accept {cmd:pweight}s.

{title:Introductory examples}

{phang} {cmd:webuse auto}{p_end}

{phang}Example 1: linear regression dominance analysis{p_end}
{phang} {cmd:domin price mpg rep78 headroom} {p_end}

{phang}Example 2: Ordered outcome dominance analysis with covariate{p_end}
{phang} {cmd:domin rep78 trunk weight length, reg(ologit) fitstat(e(r2_p)) all(turn)} {p_end}

{phang}Example 3: Binary outcome dominance analysis with factor varaible{p_end}
{phang} {cmd:domin foreign trunk weight, reg(logit) fitstat(e(r2_p)) sets((i.rep78))} {p_end}

{phang}Example 4: Comparison of interaction and non-linear variables {p_end}
{phang} {cmd:generate mpg2 = mpg^2} {p_end}
{phang} {cmd:generate headr2 = headroom^2} {p_end}
{phang} {cmd:generate mpg_headr = mpg*headroom} {p_end}
{phang} {cmd:regress mpg2 mpg} {p_end}
{phang} {cmd:predict mpg2r, resid} {p_end}
{phang} {cmd:regress headr2 headroom} {p_end}
{phang} {cmd:predict headr2r, resid} {p_end}
{phang} {cmd:regress mpg_headr mpg headroom} {p_end}
{phang} {cmd:predict mpg_headrr, resid} {p_end}
{phang} {cmd:domin price mpg headroom mpg2r headr2r mpg_headrr} {p_end}

{phang}Example 5: Epsilon approach to dominance with bootstrapped standard errors{p_end}
{phang} {cmd:bootstrap, reps(500): domin price mpg headroom trunk turn gear_ratio foreign length weight, epsilon} {p_end}
{phang} {cmd:estat bootstrap}{p_end}

{phang}Example 6: Multivariate regression with wrapper {help mvdom}{p_end}
{phang} {cmd:domin price mpg headroom trunk turn, reg(mvdom, dvs(gear_ratio foreign length weight)) fitstat(e(r2))} {p_end}

{phang}Example 7: Gamma regression with deviance fitstat and constant-only comparison (reversed interpretation - 
which predictor reduces deviance differences from constant-only){p_end}
{phang} {cmd:domin price mpg rep78 headroom, reg(glm, family(gamma) link(power -1)) fitstat(e(deviance)) consmodel} {p_end}

{phang}Example 8: Mixed effects regression with wrapper {help mixdom}{p_end}
{phang} {cmd:webuse nlswork, clear}{p_end}
{phang} {cmd:domin ln_wage tenure hours age collgrad, reg(mixdom, id(id)) fitstat(e(r2_w)) sets((i.race))} {p_end}
{phang} {cmd:scalar drop base_u base_e}

{phang}Example 9: Multinomial regression with simple program to return BIC {p_end}
{phang} {cmd:program define myprog, eclass}{p_end}
{phang} {cmd:syntax varlist if , [option]}{p_end}
{phang} {cmd:tempname estlist}{p_end}
{phang} {cmd:mlogit `varlist' `if'}{p_end}
{phang} {cmd:estat ic}{p_end}
{phang} {cmd:matrix `estlist' = r(S)}{p_end}
{phang} {cmd:ereturn scalar bic = `estlist'[1,6]}{p_end}
{phang} {cmd:end}{p_end}
{phang} {cmd:domin race tenure hours age nev_mar, reg(myprog) fitstat(e(bic)) consmodel} {p_end}
{phang} Comparison dominance analysis with McFadden's pseudo-R2 {p_end}
{phang} {cmd:domin race tenure hours age nev_mar, reg(mlogit) fitstat(e(r2_p))} {p_end}

{phang}Example 10: Multiply imputed dominance analysis {p_end}
{phang} {cmd:webuse mheart1s20, clear} {p_end}
{phang} {cmd:domin attack smokes age bmi hsgrad female, reg(logit) fitstat(e(r2_p)) mi} {p_end}
{phang} Comparison dominance analysis without {cmd:mi} ("in 1/154" keeps only original observations for comparison as in 
{bf:{help mi_intro_substantive:[MI] intro substantive}}) {p_end}
{phang} {cmd:domin attack smokes age bmi hsgrad female in 1/154, reg(logit) fitstat(e(r2_p))} {p_end}

{title:Saved results}

{phang}{cmd:domin} saves the following results to {cmd: e()}:

{synoptset 16 tabbed}{...}
{p2col 5 15 19 2: scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(fitstat_o)}}overall fit statistic value{p_end}
{synopt:{cmd:e(fitstat_a)}}all subsets variables fit statistic value{p_end}
{synopt:{cmd:e(fitstat_c)}}constant-only fit statistic value{p_end}
{p2col 5 15 19 2: macros}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(cmd)}}{cmd:domin}{p_end}
{synopt:{cmd:e(fitstat)}}contents of the {opt fitstat()} option{p_end}
{synopt:{cmd:e(reg)}}contents of the {opt reg()} option{p_end}
{synopt:{cmd:e(mi)}}{cmd:mi}{p_end}
{synopt:{cmd:e(miopt)}}contents of the {opt miopt()} option{p_end}
{synopt:{cmd:e(estimate)}}estimation method (either {cmd:dominance} or {cmd:epsilon}){p_end}
{synopt:{cmd:e(properties)}}{cmd:b}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{p2col 5 15 19 2: matrices}{p_end}
{synopt:{cmd:e(b)}}general dominance coefficient vector{p_end}
{synopt:{cmd:e(std)}}general dominance standardized coefficient vector{p_end}
{synopt:{cmd:e(ranking)}}rank ordering based on general dominance coefficient vector{p_end}
{synopt:{cmd:e(cdldom)}}conditional dominance matrix{p_end}
{synopt:{cmd:e(cptdom)}}complete dominance matrix{p_end}
{p2col 5 15 19 2: functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{title:References}

{p 4 8 2}Azen, R. & Budescu D. V. (2003). The dominance analysis approach for comparing predictors in multiple regression. {it:Psychological Methods, 8}, 129-148.{p_end}
{p 4 8 2}Azen, R., & Budescu, D. V. (2006). Comparing predictors in multivariate regression models: An extension of dominance analysis. {it:Journal of Educational and Behavioral Statistics, 31(2)}, 157-180.{p_end}
{p 4 8 2}Azen, R. & Traxel, N. M. (2009). Using dominance analysis to determine predictor importance in logistic regression. {it:Journal of Educational and Behavioral Statistics, 34}, pp 319-347.{p_end}
{p 4 8 2}Budescu, D. V. (1993). Dominance analysis: A new approach to the problem of relative importance of predictors in multiple regression, {it:Psychological Bulletin, 114}, 542-551.{p_end}
{p 4 8 2}Gr{c o:}mping, U. (2007). Estimators of relative importance in linear regression based on variance decomposition. {it:The American Statistician, 61(2)}, 139-147.{p_end}
{p 4 8 2}Johnson, J. W. (2000). A heuristic method for estimating the relative weight of predictor variables in multiple regression. {it:Multivariate Behavioral Research, 35(1)}, 1-19.{p_end}
{p 4 8 2}LeBreton, J. M., Ployhart, R. E., & Ladd, R. T. (2004). A Monte Carlo comparison of relative importance methodologies. {it:Organizational Research Methods, 7(3)}, 258-282.{p_end}
{p 4 8 2}LeBreton, J. M., Tonidandel, S., & Krasikova, D. V. (2013). Residualized relative importance analysis a technique for the comprehensive decomposition of variance in higher order regression models. {it:Organizational Research Methods}, 16(3)}, 449-473.{p_end}
{p 4 8 2}Luo, W., & Azen, R. (2013). Determining predictor importance in hierarchical linear models using dominance analysis. {it:Journal of Educational and Behavioral Statistics, 38(1)}, 3-31.{p_end}

{title:Author}

{p 4}Joseph N. Luchman{p_end}
{p 4}Behavioral Statistics Lead{p_end}
{p 4}Fors Marsh Group LLC{p_end}
{p 4}Arlington, VA{p_end}
{p 4}jluchman@forsmarshgroup.com{p_end}

{title:Acknowledgements}

Thanks to Nick Cox, Ariel Linden, Amanda Yu, Torsten Neilands, Arlion N., Eric Melse, and De Liu for suggestions and bug reporting.
