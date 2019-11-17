{smcl}
{* 27march2013}{...}
{cmd:help glmdose}{right: ({browse "http://www.stata-journal.com/article.html?article=st0328":SJ14-1: st0328})}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{hi:glmdose} {hline 2}}Estimation of the dose-response function through the generalized linear model approach{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 15 2}
{cmd:glmdose}
{varlist} 
{ifin}
{weight}{cmd:,}
{opth outcome(varname)}
{opth t(varname)}
{opth gpscore(newvar)}
{opth predict(newvar)}
{opth sigma(newvar)}
{opth cutpoints(varname)}
{opt index(string)}
{opt nq_gps(#)}
{opth dose_response(newvar)}
{opt family(string)}
{opt link(string)}
[{opt t_transf(transformation)}
{opt normal_test(test)}
{opt norm_level(#)}
{opth test_varlist(varlist)}
{opt test(type)}
{opt flag_b(#)}
{opt cmd(regression_cmd)}
{opt reg_type_t(type)}
{opt reg_type_gps(type)}
{opt interaction(#)}
{opt tpoints(vector)}
{opt npoints(#)}
{opt delta(#)}
{opth filename(filename)}
{opt boot:strap(string)}
{opt boot_reps(#)}
{opt analysis(string)}
{opt analysis_level(#)}
{opth graph(filename)}
{opt opt_nb(string)}
{opth opt_b(varname)}
{cmdab:det:ail}]

{pstd}
{cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed;
see {help weight}.


{title:Description}

{pstd}
{cmd:glmdose} estimates the generalized propensity score (GPS) by
using the generalized linear model (GLM).  This command is based on
{helpb doseresponse}, written by Bia and Mattei (2008).  {cmd:glmdose}
allows six different distribution functions -- binomial, gamma, inverse
Gaussian, negative binomial, normal, and Poisson coupled with admissible
links -- and tests the balancing property by calling the routine
{cmd:glmgpscore}.  For the normal case, {cmd:glmdose} assesses the
validity of the assumed normal distribution model by a user-specified
goodness-of-fit test.  Finally, {cmd:glmdose} estimates the average
potential outcome for each level of the treatment in which the user is
interested.


{title:Options}

{pstd}
In what follows, we provide only a description of the options
related to the {cmd:glmdose} command and not included in
{helpb doseresponse} or with a different content, referring the reader to
Bia and Mattei (2008) for the others.

{phang}
{opth gpscore(newvar)} specifies the variable
name for the estimated GPS via generalized linear model.
{cmd:gpscore()} is required.

{phang}
{opth sigma(newvar)} creates a new variable to hold the GLM fit of the
conditional standard error of the treatment given the covariates, which are
obtained from Pearson residuals.  {cmd:sigma()} is required.

{phang}
{opt family(string)} specifies the distribution family name of the treated
variable.  {cmd:family()} is required.

{phang}
{opt link(string)} specifies the link function for the treated variable.  The
default is the canonical link for the {cmd:family()} specified.  {cmd:link()}
is required.

{phang}
{opt flag_b(#)} skips either the balancing or the normal test or both and
takes as arguments {cmd:0}, {cmd:1}, or {cmd:2}.  If {cmd:flag_b()} is not
specified, the program estimates the GPS performing both the balancing and the
normal tests.  {cmd:flag_b(0)} skips both the balancing and the normal tests;
{cmd:flag_b(1)} skips only the balancing test; {cmd:flag_b(2)} skips only the
normal test.

{phang}
{opt opt_nb(string)} specifies the negative binomial dispersion parameter.  In
the GLM approach, you specify {cmd:family(nb} {it:#k}{cmd:)}, where {it:#k} is
specified through the {cmd:opt_nb()} option.  The GLM then searches for the
{it:#k} that results in the deviance-based dispersion being 1.  Instead,
{cmd:nbreg} finds the maximum likelihood estimate of {it:#k}.

{phang}
{opth opt_b(varname)} specifies the name of the variable that contains the
number of binomial trials.


{title:Remarks} 

{pstd}
Please remember to use the {helpb update query} command before running this
program to make sure you have an up-to-date version of Stata installed.
Otherwise, this program may not run properly.

{pstd}
Pay attention to the family-link combination; not all combinations are
feasible.

{pstd}
Make sure that the variables in {varlist} do not contain missing values.

{pstd}
Recall that {helpb #delimit} is not an interactive command; it
resets the character that marks the end of a command, and 
{cmd:#delimit cr} restores the carriage return delimiter.  Please take
this into account if you want to copy and paste the commands below.


{title:Examples}

{pstd}Fractional logit{p_end}
{phang2}{bf:{stata "use lotterydataset": . use lotterydataset}}{p_end}
{phang2}{bf:{stata "egen max_p=max(prize) " : . egen max_p=max(prize)}}{p_end}
{phang2}{bf:{stata "generate fraction= prize/max_p " : . generate fraction= prize/max_p }}{p_end}
{phang2}{bf:{stata "quietly generate cut1 = 23/max_p  if fraction<=23/max_p ": . quietly generate cut1 = 23/max_p  if fraction<=23/max_p }}{p_end}
{phang2}{bf:{stata "quietly replace cut1 = 80/max_p  if fraction>23/max_p & fraction<=80/max_p " : . quietly replace cut1 = 80/max_p  if fraction>23/max_p & fraction<=80/max_p }}{p_end}
{phang2}{bf:{stata "quietly replace cut1 = 485/max_p if fraction >80/max_p " : . quietly replace cut1 = 485/max_p if fraction >80/max_p }}{p_end}
{phang2}{bf:{stata "matrix define tp1 = (0.10\0.20\0.30\0.40\0.50\0.60\0.70\0.80) " : . matrix define tp1 = (0.10\0.20\0.30\0.40\0.50\0.60\0.70\0.80) }}{p_end}
 
{phang2}{cmd: . #delimit ;}{p_end}
{phang2}{cmd: . glmdose male ownhs owncoll tixbot workthen yearw yearm1 yearm2, }{p_end}
{phang2}{cmd: . t(fraction) gpscore(gps_flog) predict(y_hat_fl) sigma(sd_fl)}{p_end}
{phang2}{cmd: . cutpoints(cut1) index(mean) nq_gps(5) family(binomial) link(logit) }{p_end}
{phang2}{cmd: . outcome(year6) dose_response(dose_response) tpoints(tp1) delta(0.1) }{p_end}
{phang2}{cmd: . reg_type_t(quadratic) reg_type_gps(quadratic)  interaction(1) }{p_end}
{phang2}{cmd: . filename("outputbin")  graph("graphoutputbin.eps")  }{p_end}
{phang2}{cmd: . bootstrap(yes) boot_reps(10)   analysis(yes) detail}{p_end}
{phang2}{cmd: . ;}{p_end}
{phang2}{cmd: . #delimit cr}{p_end}


{pstd}Negative binomial distribution{p_end}
{phang2}{bf:{stata "use lotterydataset, clear": . use lotterydataset, clear}}{p_end}
{phang2}{bf:{stata "generate edu=owncoll+ownhs " : . generate edu=owncoll+ownhs}}{p_end}
{phang2}{bf:{stata "quietly generate     cut3 = 3  if edu<=3 " : . quietly generate     cut3 = 3  if edu<=3 }}{p_end}
{phang2}{bf:{stata "quietly replace cut3 = 6  if edu>3 & edu<=6 " : . quietly replace cut3 = 6  if edu>3 & edu<=6 }}{p_end}
{phang2}{bf:{stata "quietly replace cut3 = 9 if edu >6 " : . quietly replace cut3 = 9 if edu >6 }}{p_end}
{phang2}{bf:{stata "matrix define tp3 = (0\1\2\3\4\5\6\7\8\9) " : . matrix define tp3 = (0\1\2\3\4\5\6\7\8\9) }}{p_end}

{phang2}{cmd:. #delimit ;}{p_end}
{phang2}{cmd:. glmdose male workthen yearw yearm1 yearm2, t(edu) gpscore(gps_nb) }{p_end}
{phang2}{cmd:. predict(y_hat_nb) sigma(sd_nb) cutpoints(cut3) index(p50)}{p_end}
{phang2}{cmd:. nq_gps(5) family(nb) link(log) outcome(year6) dose_response(dose_response)}{p_end}
{phang2}{cmd:. tpoints(tp3) delta(1)  reg_type_t(quadratic) reg_type_gps(quadratic)  interaction(1) }{p_end}
{phang2}{cmd:. filename("outputnb")  graph("graphoutputnb.eps") }{p_end}
{phang2}{cmd:. bootstrap(yes) boot_reps(10)   analysis(yes) detail}{p_end}
{phang2}{cmd:. ;}{p_end}
{phang2}{cmd:. #delimit cr}{p_end}


{pstd}Gamma distribution{p_end}
{phang2}{bf:{stata "use lotterydataset, clear": . use lotterydataset, clear}}{p_end}
{phang2}{bf:{stata "quietly generate     cut2 = 35 if agew<=35 " : . quietly generate     cut2 = 35 if agew<=35 }}{p_end}
{phang2}{bf:{stata "quietly replace cut2 = 47  if agew>35 & agew<=59 " : . quietly replace cut2 = 47  if agew>35 & agew<=59 }}{p_end}
{phang2}{bf:{stata "quietly replace cut2 = 59  if agew >59 " : . quietly replace cut2 = 59  if agew >59 }}{p_end}
{phang2}{bf:{stata "matrix define tp2 = (10\20\30\40\50\60\70\80)" : . matrix define tp2 = (10\20\30\40\50\60\70\80)}}{p_end}

{phang2}{cmd:. #delimit ;}{p_end}
{phang2}{cmd:. glmdose male ownhs owncoll tixbot workthen yearw yearm1 yearm2,}{p_end}
{phang2}{cmd:. t(agew) gpscore(gps_gam) predict(y_hat_g) sigma(sd_g) cutpoints(cut2) index(p50)}{p_end}
{phang2}{cmd:. nq_gps(5) family(gamma) link(log) outcome(year6) dose_response(dose_response)  }{p_end}
{phang2}{cmd:. tpoints(tp2) delta(1)  reg_type_t(quadratic) reg_type_gps(quadratic)  interaction(1) }{p_end}
{phang2}{cmd:. filename("outputgam")  graph("graphoutputgam.eps") }{p_end}
{phang2}{cmd:. bootstrap(yes) boot_reps(10)   analysis(yes) detail }{p_end}
{phang2}{cmd:. ;}{p_end}
{phang2}{cmd:. #delimit cr}{p_end}


{title:Reference}

{phang}
Bia, M., and A. Mattei. 2008.
{browse "http://www.stata-journal.com/sjpdf.html?articlenum=st0150": A Stata package for the estimation of the dose-response function through adjustment for the generalized propensity score}.
{it:Stata Journal} 8: 354-373.


{title:Acknowledgments}

{pstd}
We thank H. Hirano and J. Wooldridge for their helpful comments and
suggestions in an early stage of the work.


{title:Authors}

{pstd}Barbara Guardabascio{p_end}
{pstd}Istat, Italian National Institute of Statistics{p_end}
{pstd}Rome, Italy{p_end}
{pstd}{browse "mailto:guardabascio@istat.it":guardabascio@istat.it}{p_end}

{pstd}Marco Ventura{p_end}
{pstd}Istat, Italian National Institute of Statistics{p_end}
{pstd}Rome, Italy{p_end}
{pstd}{browse "mailto:mventura@istat.it":mventura@istat.it}{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 14, number 1: {browse "http://www.stata-journal.com/article.html?article=st0328":st0328}{p_end}

{p 7 14 2}Help:  {helpb doseresponse}, {helpb gpscore},
{helpb doseresponse_model}, {helpb glmgpscore} (if installed)
{p_end}
