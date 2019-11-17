{smcl}
{* *! version 1.0  25april2011}{...}
{cmd:help robivreg}{right: ({browse "http://www.stata-journal.com/article.html?article=st0252":SJ12-2: st0252})}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{hi:robivreg} {hline 2}}Robust instrumental-variables regression
estimator{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 14 2}
{cmd:robivreg} {depvar}  
[{it:varlist1}] {cmd:(}{it:varlist2} {cmd:=} {it:instlist}{cmd:)} 
{ifin}
[{cmd:,} {cmd:first robust} {cmd:cluster(}{it:varname}{cmd:)}
{cmdab:g:enerate(}{it:varname}{cmd:)}
{cmd:raw}
{cmd:cutoff(}{it:#}{cmd:)}
{cmd:mcd}
{cmd:graph}
{cmd:label(}{it:varname}{cmd:)}
{cmd:test}
{cmd:nreps(}{it:#}{cmd:)}
{cmdab:nod:ots}]


{title:Description}

{pstd}{cmd:robivreg} fits a robust-to-outliers linear regression of
{it:depvar} on {it:varlist1} and {it:varlist2}, using {it:instlist}
(along with {it:varlist1}) as instruments for {it:varlist2}.


{title:Options}

{phang}{cmd:first} reports various first-stage results and
identification statistics. May not be used with {cmd:raw}.

{phang}{cmd:robust} produces standard errors and statistics that are
robust to arbitrary heteroskedasticity.

{phang}{cmd:cluster(}{it:varname}{cmd:)} produces standard errors and
statistics that are robust to both arbitrary heteroskedasticity and
intragroup correlation, where {it:varname} identifies the group.

{phang}{cmd:generate(}{it:varname}{cmd:)} generates a dummy named
{it:varname}, which takes the value of 1 for observations that are
flagged as outliers.

{phang}{cmd:raw} specifies that Cohen-Freue, Ortiz-Molina, and Zamar's
estimator (2006) should be returned.  Note that the standard errors
reported are different from the ones that they proposed because these
are robust to heteroskedasticity and asymmetry.  The asymptotic variance
of the {cmd:raw} estimator is described in Verardi and Croux (2009).

{phang}{cmd:cutoff(}{it:#}{cmd:)} allows the user to change the
percentile above which an individual is considered to be an outlier.
The default is {cmd:cutoff(0.99)}.

{phang}{cmd:mcd} specifies that a minimum covariance determinant
estimator of location and scatter be used to estimate the robust
covariance matrices.  By default, an S-estimator of location and scatter
is used.

{phang}{cmd:graph} generates a graphic in which outliers are identified
according to their type, and labeled using the variable {it:varname}.
Vertical lines identify vertical outliers (observations with a large
residual), and the horizontal line identifies leverage points.

{phang}{cmd:label(}{it:varname}{cmd:)} labels the outliers as
{it:varname}.  {cmd:label()} only has an effect if specified with
{cmd:graph}.

{phang}{cmd:test} specifies to report a test for the presence of
outliers in the sample.  To test for the appropriateness of a robust
instrumental-variables procedure relative to the classical
instrumental-variables estimator, we rely on the W statistic proposed by
Dehon, Gassner, and Verardi (2009) and Desbordes and Verardi (2011).

{phang}{cmd:nreps(}{it:#}{cmd:)} specifies the number of bootstrap
replicates performed when the {cmd:test} and {cmd:cluster()} options are
both specified.  The default is {cmd:nreps(50)}.

{phang}{cmd:nodots} suppresses the replication dots.


{title:Example}

{pstd}Setup{p_end}
{phang2}{stata "use http://fmwww.bc.edu/ec-p/data/hayashi/griliches76.dta":{bf:. use http://fmwww.bc.edu/ec-p/data/hayashi/griliches76.dta}}{p_end}

{pstd}Instrumental variables:  Example follows Hayashi (2000, 255); see
{helpb ivreg2}{p_end}
{phang2}{stata "robivreg lw s expr tenure rns smsa year (iq=med kww age mrt), test" :{bf:. robivreg lw s expr tenure rns smsa year (iq=med kww age mrt), test}}


{title:Saved results}

{pstd}{cmd:robivreg} saves the following in {cmd:e()} (see 
{helpb ivreg2}):

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(Wstat)}}outliers test statistic (if {cmd:cluster()} not
specified){p_end}
{synopt:{cmd:e(Wstatp)}}p-value of outliers test (if {cmd:cluster()} not specified){p_end}
{synopt:{cmd:e(Wstat_cl)}}outliers test statistic (if {cmd:cluster()} specified){p_end}
{synopt:{cmd:e(Wstatp_cl)}}p-value of outliers test (if {cmd:cluster()} specified){p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(yy)}}total sum of squares (SS), uncentered{p_end}
{synopt:{cmd:e(yyc)}}total SS, centered{p_end}
{synopt:{cmd:e(rss)}}residual SS{p_end}
{synopt:{cmd:e(mss)}}model SS{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(r2u)}}uncentered R-squared{p_end}
{synopt:{cmd:e(r2c)}}centered R-squared{p_end}
{synopt:{cmd:e(r2)}}centered R-squared if the equation has a constant; uncentered otherwise{p_end}
{synopt:{cmd:e(r2_a)}}adjusted R-squared{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(rankxx)}}rank of the matrix of observations on right-hand-side variables{p_end}
{synopt:{cmd:e(rankzz)}}rank of the matrix of observations on instruments{p_end}
{synopt:{cmd:e(rankV)}}rank of covariance matrix V of coefficients{p_end}
{synopt:{cmd:e(rankS)}}rank of covariance matrix S of orthogonality conditions{p_end}
{synopt:{cmd:e(rmse)}}root mean squared error{p_end}
{synopt:{cmd:e(F)}}F statistic{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(bw)}}bandwidth{p_end}
{synopt:{cmd:e(lambda)}}limited-information maximum-likelihood eigenvalue{p_end}
{synopt:{cmd:e(kclass)}}k in k-class estimation{p_end}
{synopt:{cmd:e(fuller)}}Fuller parameter alpha{p_end}
{synopt:{cmd:e(sargan)}}Sargan statistic{p_end}
{synopt:{cmd:e(sarganp)}}p-value of Sargan statistic{p_end}
{synopt:{cmd:e(sargandf)}}degrees of freedom of Sargan statistic{p_end}
{synopt:{cmd:e(j)}}Hansen J statistic{p_end}
{synopt:{cmd:e(jp)}}p-value of Hansen J statistic{p_end}
{synopt:{cmd:e(jdf)}}degrees of freedom of Hansen J statistic{p_end}
{synopt:{cmd:e(arubin)}}Anderson-Rubin overidentification likelihood-ratio statistic{p_end}
{synopt:{cmd:e(arubinp)}}p-value of Anderson-Rubin overidentification likelihood-ratio statistic{p_end}
{synopt:{cmd:e(arubindf)}}degrees of freedom of Anderson-Rubin
overidentification statistic{p_end}
{synopt:{cmd:e(idstat)}}Lagrange multiplier (LM) test statistic for underidentification (Anderson or Kleibergen-Paap){p_end}
{synopt:{cmd:e(idp)}}p-value of underidentification LM statistic{p_end}
{synopt:{cmd:e(iddf)}}degrees of freedom of underidentification LM statistic{p_end}
{synopt:{cmd:e(widstat)}}F statistic for weak identification (Cragg-Donald or Kleibergen-Paap){p_end}
{synopt:{cmd:e(arf)}}Anderson-Rubin F test of significance of endogenous regressors{p_end}
{synopt:{cmd:e(arfp)}}p-value of Anderson-Rubin F test of endogenous regressors{p_end}
{synopt:{cmd:e(archi2)}}Anderson-Rubin chi-squared test of significance of endogenous regressors{p_end}
{synopt:{cmd:e(archi2p)}}p-value of Anderson-Rubin chi-squared test of endogenous regressors{p_end}
{synopt:{cmd:e(ardf)}}degrees of freedom of Anderson-Rubin test of endogenous regressors{p_end}
{synopt:{cmd:e(ardf_r)}}denominator degrees of freedom of autoregressive F test of endogenous regressors{p_end}
{synopt:{cmd:e(redstat)}}LM statistic for instrument redundancy{p_end}
{synopt:{cmd:e(redp)}}p-value of LM statistic for instrument redundancy{p_end}
{synopt:{cmd:e(reddf)}}degrees of freedom of LM statistic for instrument redundancy{p_end}
{synopt:{cmd:e(cstat)}}C statistic{p_end}
{synopt:{cmd:e(cstatp)}}p-value of C statistic{p_end}
{synopt:{cmd:e(cstatdf)}}degrees of freedom of C statistic{p_end}
{synopt:{cmd:e(cons)}}{cmd:1} when equation has a Stata-supplied constant; {cmd:0} otherwise{p_end}
{synopt:{cmd:e(partialcons)}}same as above but prior to partialing out (see {cmd:e(partial)}){p_end}
{synopt:{cmd:e(partial_ct)}}number of partialed-out variables (see {cmd:e(partial)}){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:ivreg2}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(instd)}}instrumented variable{p_end}
{synopt:{cmd:e(insts)}}instruments{p_end}
{synopt:{cmd:e(version)}}version number of {cmd:ivreg2}{p_end}
{synopt:{cmd:e(model)}}{cmd:ols}, {cmd:iv}, {cmd:gmm}, {cmd:liml}, or {cmd:kclass}{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(vcetype)}}covariance estimation method{p_end}
{synopt:{cmd:e(inexog)}}included instruments (regressors){p_end}
{synopt:{cmd:e(exexog)}}excluded instruments{p_end}
{synopt:{cmd:e(collin)}}variables dropped because of collinearities{p_end}
{synopt:{cmd:e(dups)}}duplicate variables{p_end}
{synopt:{cmd:e(ecollin)}}endogenous variables reclassified as exogenous because of collinearities with instruments{p_end}
{synopt:{cmd:e(clist)}}instruments tested for orthogonality{p_end}
{synopt:{cmd:e(redlist)}}instruments tested for redundancy{p_end}
{synopt:{cmd:e(partial)}}partialed-out exogenous regressors{p_end}
{synopt:{cmd:e(small)}}{cmd:small}{p_end}
{synopt:{cmd:e(kernel)}}kernel{p_end}
{synopt:{cmd:e(tvar)}}name of time variable{p_end}
{synopt:{cmd:e(ivar)}}panel variable{p_end}
{synopt:{cmd:e(firsteqs)}}names of stored first-stage equations{p_end}
{synopt:{cmd:e(rfeq)}}name of stored reduced-form equation{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(S)}}covariance matrix of orthogonality conditions{p_end}
{synopt:{cmd:e(W)}}weight matrix used to compute generalized method of moments estimates {p_end}
{synopt:{cmd:e(first)}}first-stage regression results{p_end}
{synopt:{cmd:e(ccev)}}eigenvalues corresponding to the Anderson canonical correlations test{p_end}
{synopt:{cmd:e(cdev)}}eigenvalues corresponding to the Cragg-Donald test{p_end}

{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{title:References}

{phang}Cohen-Freue, G. V., H. Ortiz-Molina, and R. H. Zamar.  2006.  A natural
robustification of the ordinary instrumental variables estimator.  Working
paper. {browse "http://www.stat.ubc.ca/~ruben/website/cv/cohen-zamar.pdf"}.

{phang} Dehon, C., M. Gassner, and V. Verardi.  2009.  Extending the
Hausman test to check for the presence of outliers.  ECARES Working
Paper 2011-036, Universit{c e'} Libre de Bruxelles.
{browse "http://ideas.repec.org/p/eca/wpaper/2013-102578.html"}.

{phang}Desbordes, R., and V. Verardi.  2011.  The positive causal impact
of foreign direct investment on productivity: A not so typical
relationship.  Discussion Paper No. 11-06, University of Strathclyde Business
School, Department of Economics.  {browse "http://www.strath.ac.uk/media/departments/economics/researchdiscussionpapers/2011/11-06_Final.pdf"}.

{phang}Hayashi, F. 2000.  {it:Econometrics}.  Princeton: Princeton University
Press.

{phang}Verardi, V. and C. Croux.  2009.  Robust regression in Stata.
 {it:Stata Journal} {browse "http://www.stata-journal.com/article.html?article=st0173":9: 439-453}.


{title:Authors}

{pstd}Rodolphe Desbordes{p_end}
{pstd}University of Strathclyde{p_end}
{pstd}Glasgow, UK{p_end}
{pstd}rodolphe.desbordes@strath.ac.uk{p_end}

{pstd}Verardi Vincenzo{p_end}
{pstd}University of Namur{p_end}
{pstd}(Centre for Research in the Economics of Development){p_end}
{pstd}and Universit{c e'} Libre de
      Bruxelles{p_end}
{pstd}(European Center for Advanced Research in Economics and
        Statistics and Center for Knowledge Economics){p_end}
{pstd}Namur, Belgium{p_end}
{pstd}vverardi@ulb.ac.be{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 12, number 2: {browse "http://www.stata-journal.com/article.html?article=st0252":st0252}

{p 5 14 2}Manual:  {manlink U 20 Estimation and postestimation commands}, {manlink U 26 Overview of Stata estimation commands}, {manlink R ivregress}{p_end}

{p 7 14 2}Help:  {helpb ivreg2}, {helpb smultiv}, {helpb mmregress},
{helpb ivregress}, {helpb newey},
{helpb overid}, {helpb ivendog}, {helpb ivhettest}, {helpb ivreset},
{helpb xtivreg2}, {helpb xtoverid}, {helpb ranktest},
{helpb condivreg},
{helpb rivtest},
{helpb cgmreg},
{helpb est}, {helpb postest},
{helpb regress}{p_end}
