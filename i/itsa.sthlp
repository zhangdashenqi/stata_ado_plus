{smcl}
{* 17sep2014}{...}
{* 06Aug2014}{...}
{* 24Mar2014}{...}
{* 11Feb2014}{...}
{cmd:help itsa}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{hi:itsa} {hline 2}}Interrupted time series analysis for single and multiple groups {p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 15 2}
        {cmd:itsa} {depvar} [{indepvars}] {ifin} [{it:{help weight:weight}}] 
        {cmd: ,}  
        {opt trp:eriod}({it:{help numlist:numlist}}) 
		[ {opt sing:le}  
		{opt treat:id}({it:#}) 
		{opt cont:id}({it:{help numlist:numlist}})  
		{cmdab:prais:}
		{cmdab:lag:}({it:#}) 
		{opt fig:ure} 
		{opt posttr:end}
		{opt repl:ace} 
		{opt pre:fix}({it:string}) 
		{it:model_options} 
        ]
		
		
{p 4 4 2}
Dataset for a single panel must be declared to be time-series data using
{cmd: tsset} {it:timevar}. When the dataset contains multiple panels, a
strongly balanced panel dataset using {cmd: tsset} {it:panelvar}
{it:timevar} must be declared; see {help tsset}. 
 

{marker options}{...}
{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmdab:trp:eriod(}{it:numlist}{cmd:)}}{...}
{cmd:Required.} The time period when the intervention begins.
The values entered for time period must be in the same units as the
panel time variable specified in {cmd:tsset} {it:timevar}; see 
{help tsset}. More than one period may be specified. {p_end}

{synopt:{cmdab:sing:le}}{...}
Indicates that {cmd:itsa} will be used for a single group
analysis. Conversely, omitting {cmd:single} indicates that {cmd:itsa} is
for a multiple group comparison. {p_end}

{synopt:{cmdab:treat:id(}{it:#}{cmd:)}}{...}
When the dataset contains multiple panels, {cmd:treatid()} 
specifies the identifier of the single treated unit under study.  The value entered 
must be in the same units as the panel variable specified
in {cmd:tsset} {it:panelvar timevar}; see {help tsset}. When the dataset
contains data for only a single panel, {cmd:treatid()} must be
omitted.{p_end}

{synopt:{cmdab:cont:id(}{it:numlist}{cmd:)}}{...}
A list of identifiers to be used as control units in the
multiple group analysis. The values entered must be in
the same units as the panel variable specified in {cmd:tsset}
{it:panelvar timevar}; see {help tsset}. If {cmd:contid()} is not specified,
all non-treated units in the data will be used as controls. {p_end}

{synopt:{cmdab:prais:}}{...} 
Specifies that a {help prais} model should be estimated. 
All {help prais} options are available. If {help prais} is not specified, 
{cmd:itsa} will use {help newey} as the default model. {p_end}

{synopt:{cmdab:lag:(}{it:#}{cmd:)}}{...} 
When {cmd:itsa} uses {help newey}, the maximum lag to be
considered in the autocorrelation structure should be specified. If you specify
{cmd:lag(0)}, the output is the same as {cmd:regress, vce(robust)}; 
Default is {cmd:lag(0)}. An error message will appear if both {help prais} 
and {cmd:lag} are specified. {p_end}

{synopt:{cmdab:fig:ure}}{...} 
Produces a line plot of the predicted {it:depvar} variable
combined with a scatter plot of the actual values of {it:depvar}
over time. In a multiple group analysis, {cmd:figure} plots
the average values of all controls used in the analysis.{p_end}

{synopt:{cmdab:posttr:end}}{...}
Produces post-treatment trend estimates for the specified model. In the case of a 
single-group ITSA, one estimate is produced. In the case of a multiple-group ITSA,
an estimate is produced for the treatment group, the control group, and the difference.
In the case of multiple treatment periods, a separate table is produced for each 
treatment period. {p_end}


{synopt:{cmdab:repl:ace}}{...}
Replaces variables created by {cmd:itsa} if they already exist.
If {cmd:prefix()} is specified, only variables created by {cmd:itsa}
with the same prefix will be replaced. {p_end}
	
{synopt:{cmdab:pre:fix(}{it:string}{cmd:)}}{...} 
Adds a prefix to the names of variables created by {cmd:itsa}.
Short prefixes are recommended. {p_end}

{synopt:{it:model_options}}{...} 
Specifies all available options for {help prais} when the {cmd:prais} 
option is chosen; otherwise all available options of {help newey} other than {cmd:lag()}. {p_end}


{synoptline}
{p2colreset}{...}
{p 4 6 2}

INCLUDE help fvvarlist
{p 4 6 2}
{it:depvar} and {it:indepvars} may contain time-series operators; see
{help tsvarlist}.{p_end}

{marker weight}{...}
{p 4 6 2}{opt aweight}s are allowed; see {help weight}.{p_end}
{p 4 6 2}
See {manhelp newey_postestimation TS:newey postestimation} and 
{manhelp prais_postestimation TS:prais postestimation} for features
available after estimation.{p_end}


	
{title:Description}

{pstd}
{cmd:itsa} estimates the effect of an intervention when the outcome
variable is ordered as a time series, and a number of observations are
available in both pre- and post-intervention periods. The study
design is generally referred to as an interrupted time series because
the intervention is expected to {it:interrupt} the level and/or trend
subsequent to its introduction (Campbell & Stanley, 1966; Glass, Willson
& Gottman, 1975; Shadish, Cook & Campbell, 2002). {cmd:itsa} is a
wrapper program for, by default, {helpb newey}, which produces Newey-West standard
errors for coefficients estimated by OLS regression, or 
optionally {helpb prais}, which 
uses the generalized least-squares method to estimate the parameters in a 
linear regression model in which the errors are assumed to follow a first-order 
autoregressive process. {cmd:itsa} estimates treatment effects for either a
single treatment group (with pre- and post-intervention observations)
or a multiple-group comparison (i.e., the single treatment group is
compared with one or more control groups). Additionally, {cmd:itsa} can
estimate treatment effects for multiple treatment periods.{p_end}


{title:Remarks} 

{pstd}
Regression (with methods to account for autocorrelation) is the most
commonly used modeling technique in interrupted time series analyses.
When there is only one group under study (no comparison groups) the
regression model assumes the following form (Simonton 1977a, 1977b; Huitema & McKean 2000; Linden & Adams 2011):

{pstd}
Y_t = ß0 + ß1(T) + ß2(X_t) + ß3(XT_t)  (1)

{pstd}
Here Y_t is the aggregated outcome variable measured at each
equally-spaced time-point t, T is the time since the start of the study,
X_t is a dummy (indicator) variable representing the intervention
(pre-intervention periods 0, otherwise 1), and XT_t is an interaction
term.  In the case of a single group study, ß0 represents the intercept,
or starting level of the outcome variable. ß1 is the slope,
or trajectory of the outcome variable until the introduction of the
intervention. ß2 represents the change in the level of the outcome that 
occurs in the period immediately following the introduction of the intervention 
(compared to the counterfactual). ß3 represents the difference between pre- and
post-intervention slopes of the outcome. Thus, we look for significant p-values 
in ß2 to indicate an immediate treatment effect, or in ß3 to indicate a treatment effect over time.

{pstd}
When one or more control groups are available for comparison, the
regression model in Equation 1 is expanded to include four additional
terms (ß4 to ß7) (Simonton 1977a, 1977b; Linden & Adams 2011):

{pstd}
Y_t = ß0 + ß1(T) + ß2(X_t) + ß3(TX_t) + ß4(Z) + ß5(ZT) + ß6(ZX_t) + ß7(ZTX_t)  (2)

{pstd}
Here Z is a dummy variable to denote the cohort assignment (treatment or
control) and ZT, ZX_t and ZTX_t are all interaction terms among
previously described variables. Now the coefficients ß0 to ß3 represent
the control group and the coefficients ß4 to ß7 represent values of the
treatment group. More specifically, ß4 represents the difference in the
level (intercept) of the dependent variable between treatment and
controls prior to the intervention, ß5 represents the difference in the
slope (trend) of the dependent variable between treatment and
controls prior to the intervention, ß6 indicates the difference between
treatment and control groups in the level of the dependent variable
in the period in which the intervention was introduced, and ß7
represents the difference between treatment and control groups in the
slope (trend) of the outcome variable after initiation of the intervention 
compared to pre-intervention (akin to a difference-in-differences of slopes).
The two parameters ß4 and ß5 play a particularly important role in
establishing whether the treatment and control groups are balanced on
both the level and the trajectory of the dependent variable in the
pre-intervention period. If these data were from an RCT, we would
expect there to be similar levels and slopes prior to the intervention.
However, in an observational study where equivalence between groups
cannot be ensured, any observed differences will likely raise concerns
about the ability to draw causal inferences about the outcomes.
 

{title:Examples}

{pstd}
There are three general scenarios in which {cmd:itsa} can be
implemented: (1) a single group ITSA using data with only the one panel,
(2) a single group ITSA in data where there are other panels, and (3) a
multiple group ITSA. The examples below are described accordingly, using
data from Abadie, Diamond, and Hainmueller (2010) and Linden and Adams
(2011): {p_end}

{pstd}
{opt (1) Single Group TSA in data with only one panel:}{p_end}

{pstd}
Load single panel data and declare the dataset as time series: {p_end}

{p 4 8 2}{stata "sysuse cigsales_single, clear":. sysuse cigsales_single, clear}{p_end}
{p 4 8 2}{stata "tsset year": . tsset year} {p_end}

{pstd}
We specify a single-group ITSA, the first year of the intervention is 1989,
plot the results, and produce a table of the post-treatment trend estimates. 
We then run {helpb actest} to test for autocorrelation over
the past 12 periods.{p_end}

{p 4 8 2}{stata "itsa cigsale, single trperiod(1989) lag(1) fig posttrend": . itsa cigsale, single trperiod(1989) lag(1) fig posttrend}{p_end}
{p 4 8 2}{stata "actest, lags(12)": . actest, lags(12)}{p_end}

{pstd}
{opt (2) Single Group TSA in data with multiple panels:}{p_end}

{pstd}
Load multiple panel data and declare the dataset as panel: {p_end}

{p 4 8 2}{stata "sysuse cigsales":. sysuse cigsales} {p_end}
{p 4 8 2}{stata "tsset state year":. tsset state year} {p_end}

{pstd}
We specify a single-group ITSA with State 3 (California) as the
treatment group, the first year of the intervention is 1989, plot the
results, and produce a table of the post-treatment trend estimates. {p_end}

{p 4 8 2}{stata "itsa cigsale, single treat(3) trperiod(1989) lag(1) fig posttr": . itsa cigsale, single treat(3) trperiod(1989) lag(1) fig posttr}{p_end}

{pstd}
Same as above, but we specify {cmd:prais} to estimate an AR1 model with the tscorr rhotype and robust standard error options. {p_end}

{p 4 8 2}{stata "itsa cigsale, single treat(3) trperiod(1989) fig posttr replace prais rhotype(tscorr) vce(robust)":. itsa cigsale, single treat(3) trperiod(1989) fig posttr replace prais rhotype(tscorr) vce(robust)}{p_end}

{pstd}
Here we specify two treatment periods, starting in 1982 and 1989. {p_end}

{p 4 8 2}{stata "itsa cigsale, single treat(3) trperiod(1982 1989) lag(1) fig posttr replace":. itsa cigsale, single treat(3) trperiod(1982 1989) lag(1) fig posttr replace} {p_end}

{pstd}
Same as above, but we limit the range of observations to the period 1975 to 1995. {p_end}

{p 4 8 2}{stata "itsa cigsale if inrange(year, 1975, 1995), single treat(3) trperiod(1982 1989) lag(1) fig posttr replace": . itsa cigsale if inrange(year, 1975, 1995), single treat(3) trperiod(1982 1989) lag(1) fig posttr replace} {p_end}

{pstd}
{opt (3) Multiple Group ITSA:}{p_end}

{pstd}
We specify a multiple-group ITSA by omitting {cmd:single}, and allow all
other groups in the file to be used as control groups.{p_end}

{p 4 8 2}{stata "itsa cigsale, treat(3) trperiod(1989) lag(1) fig posttr replace":. itsa cigsale, treat(3) trperiod(1989) lag(1) fig posttr replace}{p_end}

{pstd}
Same as above, but we specify specific control groups to use in the
analysis.{p_end}

{p 4 8 2}{stata "itsa cigsale, treat(3) trperiod(1989) contid(4 8 19) lag(1) replace fig posttr": . itsa cigsale, treat(3) trperiod(1989) contid(4 8 19) lag(1) replace fig posttr}


{marker output_tables}{...}
{title:Output tables}

{pstd}
{cmd:itsa} produces several variables, as defined under {cmd:Remarks}
above. Below is a cross reference to default names for those variables that appear in the regression output tables 
(and used when {cmd:posttrend} is specified). Variables starting with {cmd:_z} are added to the dataset only when a 
multiple-group comparison is specified. {cmd:(trperiod)} is a suffix added to certain variables indicating the start 
of the intervention period. This is particularly helpful for differentiating between added variables when multiple 
interventions are specified. If the user specifies a {cmd:prefix()}, it will naturally be applied:

{synoptset 20 tabbed}{...}
{p2col 5 25 19 2:}{p_end}
{synopt:{cmd:Variable}}{cmd:Description}{p_end}

{synopt:{cmd:_t}}time since the start of the study{p_end}
{synopt:{cmd:_x(trperiod)}}a dummy variable representing the intervention periods (pre-intervention periods 0, otherwise 1){p_end}
{synopt:{cmd:_x_t(trperiod)}}interaction of _t and _x{p_end}
{synopt:{cmd:_z}}a dummy variable to denote the cohort assignment (treatment or control){p_end}
{synopt:{cmd:_z_x(trperiod)}}interaction of _z and _x{p_end}
{synopt:{cmd:_z_x_t(trperiod)}}interaction of _z, _x, and _t{p_end}
{synopt:{cmd:_s_{it:depvar}_pred}}predicted values generated after running {cmd:itsa} for a single group {p_end}
{synopt:{cmd:_m_{it:depvar}_pred}}predicted values generated after running {cmd:itsa} for a multiple-group comparison {p_end}

{p2colreset}{...}


{title:References}

{p 4 8 2}
Abadie, A., Diamond, A., Hainmueller, J. 2010. 
Synthetic control methods for comparative case studies: estimating the
effect of California's Tobacco Control Program.
{it: Journal of the American Statistical Association} 
105(490): 493{c -}505. {p_end}

{p 4 8 2}
Campbell, D.T., Stanley, J.C. 1966. 
{it:Experimental and Quasi-Experimental Designs for Research.}
 Chicago: Rand McNally.{p_end}

{p 4 8 2}
Glass, G.V., Willson, V.K., Gottman, J.M. 1975. 
{it:The Design and Analysis of Time-Series Experiments.} 
Boulder, CO: Colorado Associated University Press. {p_end}

{p 4 8 2}
Huitema, B.E., McKean J.W. 2000.
Design specification issues in time-series intervention models.
{it: Educational and Psychological Measurement}
60(1): 38{c -}58. {p_end}

{p 4 8 2} 
Linden, A. Conducting interrupted time series analysis for single and multiple group comparisons. 
{it:Stata Journal} 
Forthcoming{p_end}

{p 4 8 2} 
Linden, A., Adams, J.L. 2011. 
Applying a propensity-score based weighting model to interrupted time
series data: improving causal inference in program evaluation. 
{it:Journal of Evaluation in Clinical Practice} 
17: 1231{c -}1238.{p_end}

{p 4 8 2}
Shadish, S.R., Cook, T.D., Campbell, D.T. 2002.
{it:Experimental and Quasi-Experimental Designs for Generalized Causal Inference.} 
Boston: Houghton Mifflin.{p_end}

{p 4 8 2} 
Simonton, D.K. 1977a. 
Cross sectional time-series experiments: some suggested statistical analyses. 
{it:Psychological Bulletin} 
84: 489{c -}502.{p_end}

{p 4 8 2} 
Simonton, D.K. 1977b. Erratum to Simonton. 
{it:Psychological Bulletin}
84: 1097. {p_end}


{marker citation}{title:Citation of {cmd:itsa}}

{p 4 8 2}{cmd:itsa} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel. 2014. 
itsa: Stata module for conducting interrupted time series analysis for single and multiple groups.
{browse "http://ideas.repec.org/c/boc/bocode/s457793.html"}
{p_end}


{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
Ann Arbor, MI, USA{break} 
{browse "mailto:alinden@lindenconsulting.org":alinden@lindenconsulting.org}{break}
{browse "http://www.lindenconsulting.org"}{p_end}

        
{title:Acknowledgments} 

{p 4 4 2}I owe a tremendous debt of gratitude to Nicholas J. Cox for his
never-ending support and patience with me while originally developing {cmd:itsa}.
I would also like to thank Steven J. Samuels for creating the {cmd: posttrend}
option and help with various other improvements to {cmd:itsa}.


{title:Also see}

{p 4 8 2}Online:  {helpb newey}, {helpb prais}, {helpb actest} (if installed), {helpb abar} (if installed) {p_end}

