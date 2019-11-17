{smcl}
{hline}
{cmd:help: {helpb gs2slsxt}}{space 55} {cmd:dialog:} {bf:{dialog gs2slsxt}}
{hline}

{bf:{err:{dlgtab:Title}}}

{bf:gs2slsxt: Generalized Spatial Panel Autoregressive 2SLS Regression}

{marker 00}{bf:{err:{dlgtab:Table of Contents}}}
{p 4 8 2}

{p 5}{helpb gs2slsxt##01:Syntax}{p_end}
{p 5}{helpb gs2slsxt##02:Options}{p_end}
{p 5}{helpb gs2slsxt##03:Description}{p_end}
{p 5}{helpb gs2slsxt##05:References}{p_end}

{p 1}*** {helpb gs2slsxt##06:Examples}{p_end}

{p 5}{helpb gs2slsxt##07:Acknowledgments}{p_end}
{p 5}{helpb gs2slsxt##08:Author}{p_end}

{p2colreset}{...}
{marker 01}{bf:{err:{dlgtab:Syntax}}}

{p 5 5 6}
{opt gs2slsxt} {depvar} {indepvars} {ifin} {weight} , {bf:{err:id(#)}}{p_end} 
{p 3 5 6} 
{err: [} {opt wmf:ile(weight_file)} {opt wm:at(weight_matrix_name_W)} {opt eigw(eig_var_name_eW)}{p_end} 
{p 5 5 6}
{opt m:odel(spgls|gs2sls|gs2slsar)} {opt aux(varlist)} {opt ord:er(#)} {opt gmm(#)} {opt nocons:tant}{p_end} 
{p 5 5 6} 
{opt be fe re ec2sls} {opt nosa sa} {opt small} {opt l:evel(#)} {opth vce(vcetype)} {err:]}{p_end}

{p2colreset}{...}
{marker 02}{bf:{err:{dlgtab:Options}}}
{p 1 1 1}

{synoptset 3 tabbed}{...}
{synoptline}

{synopt :* {cmd: {opt id(#)} Number of Cross Sections in the Model}}{p_end} 
{synopt :{opt wmf:ile(weight_file)} Open CROSS SECTION weight matrix file. {cmd:gs2slsxt} will convert automatically spatial cross section weight matrix to spatial PANEL weight matrix.}{p_end} 
{synopt :{opt wm:at(weight_matrix_name)} Set name of the new spatial panel weight matrix, it has two types; row-standardized, and binary weight matrix.}{p_end} 
{synopt :{opt eigw(eig_var_name)} Set name of new panel eigenvalues variable.}{p_end} 
{synopt :{opt m:odel(spgls, gs2sls, gs2slsar)}}{p_end} 
{col 5} 1- {bf:model({err:{it:spgls}})}    Spatial Panel Autoregressive Generalized Least Squares Model
{p 25 25 2}When panel data model with error components are both spatially and time-wise correlated.
Generalized method of moments (GMM) that suggested in Kelejian-Prucha (1999), and Kapoor-Kelejian-Prucha (2007) are used in the estimation of {bf:model({err:{it:spgls}})}{p_end}
{col 5} 2- {bf:model({err:{it:gs2sls}})}   Generalized Spatial Panel 2SLS Model
{col 5} 3- {bf:model({err:{it:gs2slsar}})} Generalized Spatial Panel Autoregressive 2SLS Model
{p 25 25 2}Since no softwares available till now to estimate generalized spatial panel autoregressive 2SLS models, I designed {cmd:gs2slsar} as a modification of Kapoor-Kelejian-Prucha (2007),
but here I let the estimations deal with Panel 2SLS models, with original constant term.{p_end}

{synopt :{opt stand} Use row-standardized panel weight matrix within each row sum equals 1. Default is Binary spatial panel weight matrix which each element is 0 or 1}{p_end}

{synopt :{opt ord:er(1, 2, 3, 4)} order of lagged independent variables up to maximum 4th order. Default is 1. {bf:order(2,3,4)} works only with: {bf:model({err:{it:gs2sls, gs2slsar}})}}{p_end}

{synopt :{opt gmm(1, 2, 3)} GMM Estimators for {bf:model({err:{it:spgls}})}}{p_end} 
{col 8}{bf:1- Initial GMM Model}
{col 8}{bf:2- Partial Weighted GMM Model}
{col 8}{bf:3- Full Weighted GMM Model}

{col 7}{opt be}  Between Effects     {col 30}(BE)

{col 7}{opt fe}  Fixed-Effects       {col 30}(FE)

{col 7}{opt re}  Random-Effects      {col 30}(RE)

{col 7}{opt ec2sls}{col 20}Baltagi EC2SLS Random-Effects (RE) Model

{col 7}{opt nocons:tant}{col 20}Exclude Constant Term from Equation

{col 7}{opt nosa}{col 20}Baltagi-Chang variance components instead of Swamy-Arora

{col 7}{opt small}{col 20}Use (F and t-tests) instead of (chi-squared and z-tests)}

{col 7}{opt level(#)}{col 20}confidence intervals level. Default is level(95)

{synopt :{opth vce(vcetype)} {opt ols}, {opt r:obust}, {opt cl:uster}, {opt boot:strap}, {opt jack:knife}, {opt hc2}, {opt hc3}}{p_end}

{synopt :{opt aux(varlist)}}add Auxiliary Variables into regression model, i.e., dummy variables. This option dont include these auxiliary variables among spatial lagged variables. Using many dummy variables must be used with caution to avoid multicollinearity problem, that results singular matrix, and lead to abort estimation.{p_end}

{p2colreset}{...}
{marker 03}{bf:{err:{dlgtab:Description}}}

{p 2 2 2} {cmd:gs2slsxt} estimates Spatial Panel econometric regression models.{p_end}

{p 2 4 2}{cmd:gs2slsxt} can generate:{p_end}

    {cmd:- Binary Weight Matrix.}
    {cmd:- Binary Eigenvalues Variable.}

    {cmd:- Row-Standardized Weight Matrix.}
    {cmd:- Row-Standardized Eigenvalues Variable.}

    {cmd:- Spatial lagged variables up to 4th order.}

{p 3 4 2} R2, R2 Adjusted, and F-Test, are obtained from two ways:{p_end} 
{p 5 4 2} 1- squared correlation between predicted (Yh) and observed dependent variable (Y).{p_end}
{p 5 4 2} 2- Ratio of variance between predicted (Yh) and observed dependent variable (Y).{p_end}
{p 5 4 2} 3- R2 Adjusted: R2_a=1-(1-R2)*(N-1)/(N-K-1).{p_end}
{p 5 4 2} 3- F-Test=R2/(1-R2)*(N-K-1)/(K).{p_end}

{p 2 4 2}{help maximize:Other maximization_options} allows the user to specify other maximization options (e.g., difficult, trace, iterate(#), etc.).  
However, you should rarely have to specify them, though they may be helpful if parameters approach boundary values.


{marker 05}{bf:{err:{dlgtab:References}}}

{p 4 8 2}Anselin, L. (2001)
{cmd: "Spatial Econometrics",}
{it:In Baltagi, B. (Ed).: A Companion to Theoretical Econometrics Basil Blackwell: Oxford, UK}.

{p 4 8 2}Anselin, L. (2007)
{cmd: "Spatial Econometrics",}
{it:In T. C. Mills and K. Patterson (Eds).: Palgrave Handbook of Econometrics. Vol 1, Econometric Theory. New York: Palgrave MacMillan}.

{p 4 8 2}Anselin, L. & Kelejian, H. H. (1997)
{cmd: "Testing for Spatial Error Autocorrelation in the Presence of Endogenous Regressors",}
{it:International Regional Science Review, (20)}; 153-182.

{p 4 8 2}Anselin, L. & Florax RJ. (1995)
{cmd: "New Directions in Spatial Econometrics: Introduction. In New Directions in Spatial Econometrics",}
{it:Anselin L, Florax RJ (eds). Berlin, Germany: Springer-Verlag}.

{p 4 8 2}Anselin L., Le Gallo J. & Jayet H (2006)
{cmd: "Spatial Panel Econometrics"}
{it:In: Matyas L, Sevestre P. (eds) The Econometrics of Panel Data, Fundamentals and Recent Developments in Theory and Practice, 3rd edn. Kluwer, Dordrecht}; 901-969.

{p 4 8 2}Baltagi, B.H. (2006)
{cmd: "Random Effects and Spatial Autocorrelation with Equal Weights"}
{it:Econometric Theory 22(5)}; 973-984.

{p 4 8 2}Elhorst, J. Paul (2003)
{cmd: "Specification and Estimation of Spatial Panel Data Models"}
{it:International Regional Science review 26, 3}; 244–268.

{p 4 8 2}Elhorst, J. Paul (2009)
{cmd: "Spatial Panel Data Models"}
{it:in Mandfred M. Fischer and Arthur Getis, eds., Handbook of Applied Spatial Analysis, Berlin: Springer}.

{p 4 8 2}Mudit Kapoor, Harry H. Kelejian & Ingmar R. Prucha (2007)
{cmd: "Panel Data Models with Spatially Correlated Error Components",}
{it:Journal of Econometrics, 140}; 97-130.
{browse "http://econweb.umd.edu/~prucha/Papers/JE140(2007a).pdf"}


{p2colreset}{...}
{marker 06}{bf:{err:{dlgtab:Examples}}}

{p 2 2 2}{bf:Note1:} {helpb spweight} or {helpb spweightxt} module can be used to create Panel Spatial Weight Matrix.{p_end}

{p 2 2 2}{bf:Note2:} You can use the dialog box for {dialog gs2slsxt}.{p_end}
{p 2 2 2}{bf:Note3:} xtset is included automatically in {cmd:gs2slsxt} models.{p_end}

{hline}

  {stata clear all}

  {stata sysuse gs2slsxt.dta, clear}

  {stata db gs2slsxt}

  {stata xtset id t}
{hline}

{bf:{err:* (1) Spatial Panel Autoregressive Feasible Generalized Least Squares}}

  {stata gs2slsxt y x1 x2 , wmfile(SPWxt) wmat(W) eigw(eW) id(7) model(spgls) gmm(1)}

  {stata gs2slsxt y x1 x2 , wmfile(SPWxt) wmat(W) eigw(eW) id(7) model(spgls) gmm(2)}

  {stata gs2slsxt y x1 x2 , wmfile(SPWxt) wmat(W) eigw(eW) id(7) model(spgls) gmm(3)}
{hline}

{bf:{err:* (2) Generalized Spatial Panel 2SLS Models}}

  {stata gs2slsxt y x1 x2, wmfile(SPWxt) wmat(W) eigw(eW) id(7) model(gs2sls) order(1)}

  {stata gs2slsxt y x1 x2, wmfile(SPWxt) wmat(W) eigw(eW) id(7) model(gs2sls) order(2)}

  {stata gs2slsxt y x1 x2, wmfile(SPWxt) wmat(W) eigw(eW) id(7) model(gs2sls) order(3)}

  {stata gs2slsxt y x1 x2, wmfile(SPWxt) wmat(W) eigw(eW) id(7) model(gs2sls) order(4)}

{hline}

{bf:{err:* (3) Generalized Spatial Panel Autoregressive 2SLS Models}}

  {stata gs2slsxt y x1 x2, wmfile(SPWxt) wmat(W) eigw(eW) id(7) model(gs2slsar) order(1) lmi haus}

  {stata gs2slsxt y x1 x2, wmfile(SPWxt) wmat(W) eigw(eW) id(7) model(gs2slsar) order(2) lmi haus}

  {stata gs2slsxt y x1 x2, wmfile(SPWxt) wmat(W) eigw(eW) id(7) model(gs2slsar) order(3) lmi haus}

  {stata gs2slsxt y x1 x2, wmfile(SPWxt) wmat(W) eigw(eW) id(7) model(gs2slsar) order(4) lmi haus}
{hline}

{bf:{err:* (1) Spatial Panel Autoregressive Feasible Generalized Least Squares} (Cont.)}
 This example is taken from Prucha data about Spatial Panel Regression.
 More details can be found in: {browse "http://econweb.umd.edu/~prucha/Research_Prog3.htm"}
 Results of {bf:model({err:{it:spgls}})} with {cmd:gmm(3) option} is identical to:
 {browse "http://econweb.umd.edu/~prucha/STATPROG/PANOLS/PROGRAM3(L3).log"}

  {stata clear all}

  {stata sysuse gs2slsxt1.dta, clear}

  {stata gs2slsxt y x1 , wmfile(SPWxt1) wmat(W) eigw(eW) id(100) model(spgls) gmm(1)}

  {stata gs2slsxt y x1 , wmfile(SPWxt1) wmat(W) eigw(eW) id(100) model(spgls) gmm(2)}

  {stata gs2slsxt y x1 , wmfile(SPWxt1) wmat(W) eigw(eW) id(100) model(spgls) gmm(3)}

{hline}

{p2colreset}{...}
{marker 07}{bf:{err:{dlgtab:Acknowledgments}}}

  I would like to thank professor: Mudit Kapoor, Harry H. Kelejian and Ingmar R. Prucha.

{marker 08}{bf:{err:{dlgtab:Author}}}

  {hi:Emad Abd Elmessih Shehata}
  {hi:Assistant Professor}
  {hi:Agricultural Research Center - Agricultural Economics Research Institute - Egypt}
  {hi:Email:   {browse "mailto:emadstat@hotmail.com":emadstat@hotmail.com}}
  {hi:WebPage:{col 27}{browse "http://emadstat.110mb.com/stata.htm"}}
  {hi:WebPage at IDEAS:{col 27}{browse "http://ideas.repec.org/f/psh494.html"}}
  {hi:WebPage at EconPapers:{col 27}{browse "http://econpapers.repec.org/RAS/psh494.htm"}}

{bf:{err:{dlgtab:gs2slsxt Citation}}}

{phang}Shehata, Emad Abd Elmessih (2011){p_end}
{phang}{cmd:GS2SLSXT: "Stata Module to Estimate GS2SLS Generalized Spatial Panel Autoregressive Two-Stage Least Squares Regression"}{p_end}

{title:Online Help:}

{p 4 12 2}{helpb gs3sls}, {helpb gs2slsxt}, {helpb spregxt}, {helpb spautoreg},
{helpb spmstar}, {helpb spweight}, {helpb spweigcs}, {helpb spweightxt},
{helpb spcs2xt}, {helpb spreg}, {helpb spivreg}, {helpb spatreg},
{helpb spmlreg}. {opt (if installed)}.{p_end}

{psee}
{p_end}

