{smcl}
{* *! version 3.0.3 17feb2017}{...}
{cmd:help logitfe}{right: ({browse "http://www.stata-journal.com/article.html?article=st0485":SJ17-3: st0485})}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{bf:logitfe} {hline 2}}Analytical and jackknife bias 
corrections for fixed-effects estimators of panel logit models
with individual and time effects{p_end}
{p2colreset}{...}


{title:Syntax}

{phang}
Uncorrected estimator

{p 8 16 2}{cmd:logitfe} {depvar} {indepvars} {ifin}{cmd:,} {opt noc:orrection} [{it:{help logitfe##ncoptions:NC_options}}]


{phang}
Analytical-corrected (AC) estimator

{p 8 16 2}{cmd:logitfe} {depvar} {indepvars} {ifin}
[{cmd:,} {opt an:alytical} {it:{help logitfe##acoptions:AC_options}}]


{phang}
Jackknife-corrected (JC) estimator

{p 8 16 2}{cmd:logitfe} {depvar} {indepvars} {ifin}{cmd:,} {opt jack:knife} [{it:{help logitfe##jcoptions:JC_options}}]


{marker ncoptions}{...}
{synoptset 20}{...}
{synopthdr :NC_options}
{synoptline}
{synopt :{opt noc:orrection}}compute the uncorrected estimator{p_end}
{synopt :{opt ieffects(string)}}select whether the uncorrected estimator includes individual effects; {cmd:yes} (the default) or {cmd:no}{p_end}
{synopt :{opt teffects(string)}}select whether the uncorrected estimator includes time effects; {cmd:yes} (the default) or {cmd:no}{p_end}
{synopt :{opt pop:ulation(integer)}}adjust the variance of the average partial effects (APE) by a finite population correction (FPC) using the population size declared by the user{p_end}
{synoptline}

{marker acoptions}{...}
{synoptset 20}{...}
{synopthdr :AC_options}
{synoptline}
{synopt :{opt an:alytical}}use analytical bias correction; the default{p_end}
{synopt :{opt lags(integer)}}specify the value of the trimming parameter to estimate spectral expectations; default is {cmd:lags(0)}{p_end}
{synopt :{opt ieffects(string)}}select whether the uncorrected estimator includes individual effects; {cmd:yes} (the default) or {cmd:no}{p_end}
{synopt :{opt teffects(string)}}select whether the uncorrected
estimator includes time effects; {cmd:yes} (the default) or {cmd:no}{p_end}
{synopt :{opt ibias(string)}}select whether the analytical correction accounts for individual effects; {cmd:yes} (the default) or {cmd:no}{p_end}
{synopt :{opt tbias(string)}}select whether the analytical correction accounts for time effects; {cmd:yes} (the default) or {cmd:no}{p_end}
{synopt :{opt pop:ulation(integer)}}adjust the variance of the APE by an FPC using the population size declared by the user{p_end}
{synoptline}

{marker jcoptions}{...}
{synoptset 20}{...}
{synopthdr :JC_options}
{synoptline}
{synopt :{opt jack:knife}}use a panel jackknife technique
to correct the bias{p_end}
{synopt :{opt ss1} [{help logitfe##ss1options:{it:ss1_options}}]}split jackknife in four subpanels, leaving half 
individuals and half time periods out in each subpanel{p_end}
{synopt :{opt ss2} [{help logitfe##ss2options:{it:ss2_options}}]}split jackknife in both dimensions,
leaving half panel out and including either all time periods or all individuals; the default{p_end}
{synopt :{opt js}}delete-one jackknife in cross-section, split 
panel jackknife in time series{p_end}
{synopt :{opt sj}}split panel jackknife in cross-section, delete-one
jackknife in time series{p_end}
{synopt :{opt jj}}delete-one jackknife in both cross-section and 
time series{p_end}
{synopt :{opt double}}delete-one jackknife for observations with the
same index in the cross-section and the time series (see options below for details){p_end}
{synopt :{opt ieffects(string)}}select whether the uncorrected
estimator includes individual effects; {cmd:yes} (the default) 
or {cmd:no}{p_end}
{synopt :{opt teffects(string)}}select whether the uncorrected
estimator includes time effects; {cmd:yes} (the default) or 
{cmd:no}{p_end}
{synopt :{opt ibias(string)}}select whether the split jackknife correction 
accounts for individual effects; {cmd:yes} (the default) or {cmd:no}{p_end}
{synopt :{opt tbias(string)}}select whether the split jackknife correction 
accounts for time effects; {cmd:yes} (the default) or {cmd:no}{p_end}
{synopt :{opt pop:ulation(integer)}}adjust the variance of 
the APE by an FPC 
using the population size declared by the user{p_end}
{synoptline}
{p2colreset}{...}

{marker ss1options}{...}
{synoptset 20}{...}
{synopthdr :ss1_options}
{synoptline}
{synopt :{opt mul:tiple(integer)}}allow for multiple partitions,
each one made on a randomization of the observations in the
panel; default is {cmd:multiple(0)} (the partitions are made on the original
order in the dataset){p_end}
{synopt :{opt i:ndividuals}}select whether the multiple partitions are
made only on the cross-sectional dimension{p_end}
{synopt :{opt t:ime}}select whether the multiple partitions are made
only on the time dimension{p_end}
{synoptline}
{p2colreset}{...}

{marker ss2options}{...}
{synoptset 20}{...}
{synopthdr :ss2_options}
{synoptline}
{synopt :{opt mul:tiple(integer)}}allow for multiple partitions,
each one made on a randomization of the observations in the  
panel; default is {cmd:multiple(0)} (the partitions are made on the original
order in the dataset){p_end}
{synopt :{opt i:ndividuals}}select whether the multiple partitions are
made only on the cross-sectional dimension{p_end}
{synopt :{opt t:ime}}select whether the multiple partitions are made
only on the time dimension{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
Both a panel variable and a time variable must be specified.  Use 
{helpb tsset}.{p_end}
{p 4 6 2}
{it:indepvars} may contain factor variables; see {help fvvarlist}.{p_end}
{p 4 6 2}
{it:depvar} and {it:indepvars} may contain time-series operators; see {help tsvarlist}.{p_end}


{title:Description}

{pstd}
{cmd:logitfe} fits a logit fixed-effects estimator that can include individual
or time effects and account for both the bias arising from the inclusion of
individual fixed effects or the bias arising from the inclusion of time fixed
effects.  {cmd:logitfe} with the {cmd:nocorrection} option does not correct
for the incidental parameter bias problem (Neyman and Scott 1948).

{pstd}
{cmd:logitfe} with the {cmd:analytical} option removes an analytical estimate
of the bias from the logit fixed-effects estimator using the expressions
derived in Fernandez-Val and Weidner (2013).  The trimming parameter can be set
to any value between 0 and (T-1), where T is the number of time periods.

{pstd}
{cmd:logitfe} with the {cmd:jackknife} option removes a jackknife estimate of
the bias from the fixed-effects estimator.  This method is based on the
delete-one panel jackknife of Hahn and Newey (2004) and split panel jackknife
of Dhaene and Jochmans (2015) as described in Fernandez-Val and Weidner
(2013).

{pstd}
{cmd:logitfe} displays estimates of index coefficients and APE.


{title:Options for uncorrected estimator}

{phang}
{cmd:nocorrection} computes the logit fixed-effects estimator without
correcting for the bias because of the incidental parameter problem.

{pstd}
If the {cmd:nocorrection} option is specified without the type of included
effects, the model will include both individual and time effects.
{cmd:ieffects(no)} and {cmd:teffects(no)} cannot be combined.

{phang}
{opt ieffects(string)} specifies whether the uncorrected estimator includes
individual effects.

{phang2}
{cmd:ieffects(yes)}, the default, includes individual fixed effects.

{phang2}
{cmd:ieffects(no)} omits the individual fixed effects.

{phang}
{opt teffects(string)} specifies whether the uncorrected estimator includes
time effects.

{phang2}
{cmd:teffects(yes)}, the default, includes time fixed effects.

{phang2}
{cmd:teffects(no)} omits the time fixed effects.

{phang}
{opt population(integer)} adjusts the estimation of the variance of the APE by
an FPC.  Let m be the number of original observations included in
{cmd:probitfe}, and let M>=m be the number of observations for the entire
population declared by the user.  The computation of the variance of the APE
is corrected by the factor FPC=(M-m)/(M-1).  The default is
{cmd:population(1)}, corresponding to an infinity population.  Notice that M
makes reference to the total number of observations and not the total number
of individuals.  If, for example, the population has 100 individuals followed
over 10 time periods, the user must specify {cmd:population(1000)} instead of
{cmd:population(100)}.


{title:Options for AC estimator}

{phang}
{cmd:analytical}, the default, computes the logit fixed-effects estimator
using the analytical bias correction derived in Fernandez-Val and Weidner
(2013).

{phang}
{opt lags(integer)} specifies the value of the trimming parameter to estimate
spectral expectations.  See Fernandez-Val and Weidner (2013) for details.  The
default is {cmd:lags(0)}.  This option should be used when the model is static
with strictly exogenous regressors.  The trimming parameter can be set to any
value between 0 and (T-1), where T denotes the number of time periods.  A
trimming parameter higher than 0 should be used when the model is dynamic or
some of the regressors are weakly exogenous or predetermined.  We do not
recommend setting the value of the trimming parameter to a value higher than
4.

{pstd}
If the {cmd:analytical} option is specified without the type of included
effects, the model will include both individual and time effects.
{cmd:ieffects(no)} and {cmd:teffects(no)} cannot be combined.

{phang}
{opt ieffects(string)} specifies whether the estimator includes individual
effects.

{phang2}
{cmd:ieffects(yes)}, the default, includes individual fixed effects.

{phang2}
{cmd:ieffects(no)} omits the individual fixed effects.

{phang}
{opt teffects(string)} specifies whether the estimator includes time effects.

{phang2}
{cmd:teffects(yes)}, the default, includes time fixed effects.

{phang2}
{cmd:teffects(no)} omits the time fixed effects.

{pstd}
If the {cmd:analytical} option is specified without the type of correction,
the model will include analytical bias correction for both individual and time
effects.  {cmd:ibias(no)} and {cmd:tbias(no)} cannot be combined.

{phang}
{opt ibias(string)} specifies whether the analytical correction accounts for
individual effects.

{phang2}
{cmd:ibias(yes)}, the default, corrects for the bias coming from the
individual fixed effects.

{phang2}
{cmd:ibias(no)} omits the individual fixed-effects analytical bias 
correction.

{phang}
{opt tbias(string)} specifies whether the analytical correction accounts for
time effects.

{phang2}
{cmd:tbias(yes)}, the default, corrects for the bias coming from the time
fixed effects.

{phang2}
{cmd:tbias(no)} omits the time fixed-effects analytical bias correction.

{phang}
{opt population(integer)} adjusts the estimation of the variance of the APE by
an FPC.  Let m be the number of original observations included in
{cmd:probitfe}, and let M>=m be the number of observations for the entire
population declared by the user.  The computation of the variance of the APE
is corrected by the factor FPC=(M-m)/(M-1).  The default is
{cmd:population(1)}, corresponding to an infinity population.  Notice that M
makes reference to the total number of observations and not the total number
of individuals.  If, for example, the population has 100 individuals followed
over 10 time periods, the user must specify {cmd:population(1000)} instead of
{cmd:population(100)}.


{title:Options for JC estimator}

{phang}
{cmd:jackknife} computes the logit fixed-effects estimator using the jackknife
bias corrections described in Fernandez-Val and Weidner (2013).

{phang}
{cmd:ss1} [{it:ss1_options}] specifies split panel jackknife in four
nonoverlapping subpanels; in each subpanel, half the individuals and half the
time periods are left out, and the uncorrected fixed-effects estimator is
computed in each subpanel.  Let b be the uncorrected estimator using the whole
sample and b1,...,b4 be the uncorrected estimators in each subpanel.  The
{cmd:ss1} estimator is given by 2*b - (b1 + b2 + b3 + b4)/4.

{phang2}
{opt multiple(integer)} is an {cmd:ss1} suboption that allows for different
multiple partitions, each one made on a randomization of the observations in
the panel; the default is {cmd:multiple(0)}; that is, the partitions are made
on the original order in the dataset.  If {cmd:multiple(10)} is specified, for
example, then the {cmd:ss1} estimator is computed 10 times on 10 different
randomizations of the observations in the panel; the resulting estimator is
the mean of these 10 split panel jackknife corrections.  This option can be
used if there is a dimension of the panel where there is no natural ordering
of the observations.

{pmore}
If neither the {cmd:individuals} nor {cmd:time} options are specified, the
multiple partitions are made on both the cross-sectional and the time
dimensions.

{phang2}
{cmd:individuals} specifies the multiple partitions to be made only on the
cross-sectional dimension.

{phang2}
{cmd:time} specifies the multiple partitions to be made only on the time 
dimension.

{phang}
{cmd:ss2} [{it:ss2_options}], the default, specifies split jackknife in both
dimensions.  Like {cmd:ss1}, there are four subpanels: in subpanel 1 and
subpanel 2, half the individuals are left out, but all time periods are
included in the fixed-effects estimations; in subpanel 3 and subpanel 4, half
the time periods are left out, but all the individuals are included in the
fixed-effects estimations.  Let b be the uncorrected estimator using the whole
sample, b1 the mean of the uncorrected estimator in subpanels 1 and 2, and b2
the mean of the uncorrected estimator in subpanels 3 and 4.  The {cmd:ss2}
estimator is given by 3*b - b1 - b2.

{phang2}
{opt multiple(integer)} is a {cmd:ss2} suboption that allows for different
multiple partitions, each one made on a randomization of the observations in
the panel; the default is {cmd:multiple(0)}; that is, the partitions are made
on the original order in the dataset.  If {cmd:multiple(10)} is specified, for
example, then the {cmd:ss2} estimator is computed 10 times on 10 different
randomizations of the observations in the panel; the resulting estimator is
the mean of these 10 split panel jackknife corrections.  This option can be
used if there is a dimension of the panel where there is no natural ordering
of the observations.

{pmore}
If neither the {cmd:individuals} nor {cmd:time} options are specified, the
multiple partitions are made on both the cross-sectional and the time
dimensions.

{phang2}
{cmd:individuals} specifies the multiple partitions to be made only on the
cross-sectional dimension; that is, the randomization affects only subpanels 1
and 2.

{phang2}
{cmd:time} specifies the multiple partitions to be made only on the time
dimension; that is, the randomization affects only subpanels 3 and 4.

{phang}
{cmd:js} uses delete-one panel jackknife in the cross-section and split panel
jackknife in the time series.  There are N + 2 subpanels, one for each of the
N-individuals and two subpanels in which half of the time periods are left
out.  Let b be the uncorrected fixed-effects estimator that uses the whole
sample, b1 be the mean of the N uncorrected fixed-effects estimators for each
of the N subpanels in which one individual is left out, and b2 be the mean of
the two subpanels in which half of the time periods are left out.  The
{cmd:js} estimator is given by (N+1)*b-(N-1)*b1-b2.  When N is  large, this
estimator might be computationally intensive.

{phang}
{cmd:sj} uses split panel jackknife in the cross-section and delete-one panel
jackknife in the time series.  There are T + 2 subpanels, one for each of the
T-time periods and two subpanels in which half of the individuals are left
out.  Let b be the uncorrected fixed-effects estimator that uses the whole
sample, b1 be the mean of the T uncorrected fixed-effects estimators for each
of the T subpanels in which one time period is left out, and b2 be the mean of
the two subpanels in which half of the individuals are left out.  The {cmd:sj}
estimator is given by (T+1)*b-(T-1)*b1-b2.  When T is  large, this estimator
might be computationally intensive.

{phang}
{cmd:jj} uses delete-one jackknife in both the cross-section and the time
series.  There are N + T subpanels, one for each of the N-individuals and one
for each of the T time periods.  Let b be the uncorrected fixed-effects
estimator that uses the whole sample, b1 be the mean of the N uncorrected
fixed-effects estimators for each of the N subpanels in which one individual
is left out, and b2 be the mean of the T uncorrected fixed-effects estimators
for each of the T subpanels in which one time period is left out.  The
{cmd:jj} estimator is given by (N+T-1)*b-(N-1)*b1-(T-1)*b2.  When either N or
T is large, this estimator might be computationally intensive.

{phang}
{cmd:double} uses delete-one jackknife for observations with the same
cross-section and the time-series indexes.  This type of correction makes
sense for panels where i and t index the same entities.  For example, in
country trade data, the cross-section dimension represents each country as an
importer, and the time-series dimension represents each country as an
exporter.  In this case, {cmd:double} constructs each subpanel by dropping one
country (both as an importer and as an exporter).  Let i=1,...,N denote one
dimension of the panel, and let t=1,...,N denote the other dimension.
{cmd:double} uses delete-one jackknife for the M<=N subpanels for which i=t.
Let b be the uncorrected fixed-effects estimator that uses the whole sample,
and let b1 be the mean of the M uncorrected fixed-effects estimators for each
of the M<=N subpanels in which i=t.  The {cmd:double} estimator is given by
M*b-(M-1)*b1.  When M is large, this estimator can be computationally
intensive.

{pstd}
If the {cmd:jackknife} option is specified without the type of included
effects, the model will include both individual and time effects.
{cmd:ieffects(no)} and {cmd:teffects(no)} cannot be combined.

{phang}
{opt ieffects(string)} specifies whether the estimator includes individual
effects.

{phang2}
{cmd:ieffects(yes)}, the default, includes individual fixed effects.

{phang2}
{cmd:ieffects(no)} omits the individual fixed effects.

{phang}
{opt teffects(string)} specifies whether the estimator includes time effects.

{phang2}
{cmd:teffects(yes)}, the default, includes time fixed effects.

{phang2}
{cmd:teffects(no)} omits the time fixed effects.

{pstd}
If the {cmd:jackknife} option is specified without the type of correction, the
model will include jackknife correction for both individual and time effects.
{cmd:ibias(no)} and {cmd:tbias(no)} cannot be combined.

{phang}
{opt ibias(string)} specifies whether the jackknife correction accounts for
the individual effects.

{phang2}
{cmd:ibias(yes)}, the default, corrects for the bias coming from the
individual fixed effects.

{phang2}
{cmd:ibias(no)} omits the individual fixed-effects jackknife correction.  If
this option and multiple partitions only in the time dimension are specified
together (for the jackknife {cmd:ss1} or {cmd:ss2} corrections), the resulting
estimator is equivalent to the one without multiple partitions.

{phang}
{opt tbias(string)} specifies whether the jackknife correction accounts for
the time effects.

{phang2}
{cmd:tbias(yes)}, the default, corrects for the bias coming from the time fixed effects.

{phang2}
{cmd:tbias(no)} omits the time fixed-effects jackknife correction.  If this
option and multiple partitions only in the cross-section are specified
together (for the jackknife {cmd:ss1} or {cmd:ss2} corrections), the resulting
estimator is equivalent to the one without multiple partitions.

{phang}
{opt population(integer)} adjusts the estimation of the variance of the APE by
an FPC.  Let m be the number of original observations included in
{cmd:probitfe}, and let M>=m be the number of observations for the entire
population declared by the user.  The computation of the variance of the APE
is corrected by the factor FPC=(M-m)/(M-1).  The default is
{cmd:population(1)}, corresponding to an infinite population.  Notice that M
references the total number of observations and not the total number of
individuals.  If, for example, the population has 100 individuals followed
over 10 time periods, the user must specify {cmd:population(1000)} instead of
{cmd:population(100)}.


{title:Examples}

{pstd}
Setup{p_end}
{phang2}{cmd:. use lfp_psid}{p_end}
{phang2}{cmd:. tsset ID1979 year}{p_end}

{pstd}
Uncorrected estimator: Static model with individual and time effects{p_end}
{phang2}{cmd:. logitfe lfp kids0_2 kids3_5 kids6_17 loghusbandincome age age2, nocorrection}{p_end}

{pstd}
Uncorrected estimator: Static model with individual effects only{p_end}
{phang2}{cmd:. logitfe lfp kids0_2 kids3_5 kids6_17 loghusbandincome age age2, nocorrection teffects(no)}{p_end}

{pstd}
Uncorrected estimator: Static model with time effects only{p_end}
{phang2}{cmd:. logitfe lfp kids0_2 kids3_5 kids6_17 loghusbandincome age age2, nocorrection ieffects(no)}{p_end}

{pstd}
Uncorrected estimator: Dynamic model with individual and time effects{p_end}
{phang2}{cmd:. logitfe lfp L.lfp kids0_2 kids3_5 kids6_17 loghusbandincome age age2, nocorrection}{p_end}

{pstd}
AC estimator: Dynamic model with individual and time effects and trimming parameter set to one{p_end}
{phang2}{cmd:. logitfe lfp L.lfp kids0_2 kids3_5 kids6_17 loghusbandincome age age2, analytical lags(1)}{p_end}

{pstd}
AC estimator: Dynamic model with individual and time effects and trimming
parameter set to one.  Use FPC assuming population equal to number of
observations in the dataset{p_end}
{phang2}{cmd:. logitfe lfp L.lfp kids0_2 kids3_5 kids6_17 loghusbandincome age age2, analytical lags(1)}{p_end}
{phang2}{cmd:. local N = e(N) + e(N_drop)}{p_end}
{phang2}{cmd:. logitfe lfp L.lfp kids0_2 kids3_5 kids6_17 loghusbandincome age age2, analytical lags(1) population(`N')}{p_end}

{pstd}
JC estimator: Static model with individual and time effects using the {cmd:ss1} option{p_end}
{phang2}{cmd:. logitfe lfp kids0_2 kids3_5 kids6_17 loghusbandincome age age2, jackknife ss1}{p_end}

{pstd}
JC estimator: Static model with individual and time effects using the {cmd:ss2} option{p_end}
{phang2}{cmd:. logitfe lfp kids0_2 kids3_5 kids6_17 loghusbandincome age age2, jackknife ss2}{p_end}

{pstd}
JC estimator: Static model with individual and time effects using the
{cmd:ss2} option.  Five multiple partitions in both the cross-section and the
time dimension{p_end}
{phang2}{cmd:. logitfe lfp kids0_2 kids3_5 kids6_17 loghusbandincome age age2, jackknife ss2 multiple(5)}{p_end}

{pstd}
JC estimator: Static model with individual and time effects using the
{cmd:ss2} option.  Five multiple partitions in the cross-section only{p_end}
{phang2}{cmd:. logitfe lfp kids0_2 kids3_5 kids6_17 loghusbandincome age age2, jackknife ss2 multiple(5) individuals}{p_end}

{pstd}
JC estimator: Static model with individual and time effects using the
{cmd:ss2} option.  Five multiple partitions in the time dimension only{p_end}
{phang2}{cmd:. logitfe lfp kids0_2 kids3_5 kids6_17 loghusbandincome age age2, jackknife ss2 multiple(5) time}{p_end}

{pstd}
JC estimator: Static model with individual and time effects using the {cmd:js}
option{p_end}
{phang2}{cmd:. logitfe lfp kids0_2 kids3_5 kids6_17 loghusbandincome age age2, jackknife js}{p_end}

{pstd}
JC estimator: Static model with individual and time effects using the {cmd:jj}
option{p_end}
{phang2}{cmd:. logitfe lfp kids0_2 kids3_5 kids6_17 loghusbandincome age age2, jackknife jj}{p_end}

{pstd}
JC estimator: Static model with individual and time effects using the
{cmd:double} option{p_end}
{phang2}{cmd:. use trade}{p_end}
{phang2}{cmd:. tsset id jd}{p_end}
{phang2}{cmd:. generate islands2 = islands==2}{p_end}
{phang2}{cmd:. generate landlock2 = landlock==2}{p_end}
{phang2}{cmd:. logitfe trade ldist border legal language colony currency fta islands2 religion landlock2, jackknife double}{p_end}


{title:Stored results}

{pstd}
{cmd:logitfe} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_drop)}}number of observations dropped because of all positive or all zero outcomes{p_end}
{synopt:{cmd:e(N_group_drop)}}number of groups dropped because of all positive or all zero outcomes{p_end}
{synopt:{cmd:e(N_time_drop)}}number of time periods dropped because of all positive or all zero outcomes{p_end}
{synopt:{cmd:e(N_group)}}number of groups{p_end}
{synopt:{cmd:e(k)}}number of parameters excluding individual or time effects{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(r2_p)}}pseudo-R-squared{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(ll_0)}}log likelihood, constant-only model{p_end}
{synopt:{cmd:e(chi2)}}likelihood-ratio chi-squared model test{p_end}
{synopt:{cmd:e(p)}}significance of model test{p_end}
{synopt:{cmd:e(rankV)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(rankV2)}}rank of {cmd:e(V2)}{p_end}
{synopt:{cmd:e(fpc)}}FPC factor{p_end}
{synopt:{cmd:e(T_min)}}smallest group size{p_end}
{synopt:{cmd:e(T_avg)}}average group size{p_end}
{synopt:{cmd:e(T_max)}}largest group size{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:logitfe}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(title1)}}type of included effects{p_end}
{synopt:{cmd:e(title2)}}type of correction{p_end}
{synopt:{cmd:e(title3)}}lags for trimming parameter or number of multiple partitions{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:LR}; type of model chi-squared test{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(id)}}name of cross-section variable{p_end}
{synopt:{cmd:e(time)}}name of time variable{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(b2)}}APE{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of coefficient vector{p_end}
{synopt:{cmd:e(V2)}}variance-covariance matrix of APE{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}


{title:Remarks}

{pstd}
This is a first and preliminary version.  Please feel free to share your
comments, bug reports, and propositions for extensions.

{pstd}
If you use this command in your work, please cite Ivan Fernandez-Val and
Martin Weidner (2016).


{title:Disclaimer}

{p 4 4 2}
THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
PROGRAM IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST
OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

{p 4 4 2}
IN NO EVENT WILL THE COPYRIGHT HOLDERS OR THEIR EMPLOYERS, OR ANY OTHER PARTY
WHO MAY MODIFY AND/OR REDISTRIBUTE THIS SOFTWARE, BE LIABLE TO YOU FOR
DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES
ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM.


{title:References}

{phang}
Dhaene, G., and K. Jochmans. 2015. Split-panel jackknife estimation of
fixed-effect models.  {it:Review of Economic Studies} 82: 991-1030.

{phang}
Fern{c a'}ndez-Val, I., and M. Weidner. 2016. Individual and time effects in
nonlinear panel models with large N, T.
{it:Journal of Econometrics} 192: 291-312.

{phang}
Hahn, J., and W. Newey. 2004. Jackknife and analytical bias reduction for
nonlinear panel models.  {it:Econometrica} 72: 1295-1319.

{phang}
Neyman, J., and E. L. Scott. 1948. Consistent estimates based on partially
consistent observations. {it:Econometrica} 16: 1-32.


{title:Authors}

{pstd}
Mario Cruz-Gonzalez{break}
Department of Economics{break}
Boston University{break}
Boston, MA{break}
mgonza@bu.edu

{pstd}
Iv{c a'}n Fern{c a'}ndez-Val{break}
Department of Economics{break}
Boston University{break}
Boston, MA{break}
ivanf@bu.edu

{pstd}
Martin Weidner{break}
Department of Economics{break}
University College London{break}
London, UK{break}
m.weidner@ucl.ac.uk


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 17, number 3: {browse "http://www.stata-journal.com/article.html?article=st0485":st0485}{p_end}
