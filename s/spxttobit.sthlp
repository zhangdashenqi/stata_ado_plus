{smcl}
{hline}
{cmd:help: {helpb spxttobit}}{space 55} {cmd:dialog:} {bf:{dialog spxttobit}}
{hline}

{bf:{err:{dlgtab:Title}}}

{bf:spxttobit: Tobit Spatial Panel Autoregressive Generalized Least Squares}

{marker 00}{bf:{err:{dlgtab:Table of Contents}}}
{p 4 8 2}

{p 5}{helpb spxttobit##01:Syntax}{p_end}
{p 5}{helpb spxttobit##02:Options}{p_end}
{p 5}{helpb spxttobit##03:Description}{p_end}
{p 5}{helpb spxttobit##05:References}{p_end}

{p 1}*** {helpb spxttobit##06:Examples}{p_end}

{p 5}{helpb spxttobit##07:Acknowledgments}{p_end}
{p 5}{helpb spxttobit##08:Author}{p_end}

{p2colreset}{...}
{marker 01}{bf:{err:{dlgtab:Syntax}}}

{p 5 5 6}
{opt spxttobit} {depvar} {indepvars} {ifin} {weight} , {bf:{err:id(#)}}{p_end} 
{p 3 5 6} 
{err: [} {opt wmf:ile(weight_file)} {opt wm:at(weight_matrix_name_W)} {opt st:and}{p_end} 
{p 5 5 6}
{opt aux(varlist)} {opt gmm(#)} {opt nocons:tant} {opt l:evel(#)} {opth vce(vcetype)} {err:]}{p_end}

{p2colreset}{...}
{marker 02}{bf:{err:{dlgtab:Options}}}
{p 1 1 1}

{synoptset 3 tabbed}{...}
{synoptline}

{synopt :* {cmd: {opt id(#)} Number of Cross Sections in the Model}}{p_end} 
{synopt :{opt wmf:ile(weight_file)} Open CROSS SECTION weight matrix file. {cmd:spxttobit} will convert automatically spatial cross section weight matrix to spatial PANEL weight matrix.}{p_end} 
{synopt :{opt wm:at(weight_matrix_name)} Set name of the new spatial panel weight matrix, it has two types; row-standardized, and binary weight matrix.}{p_end} 

{synopt :{opt st:and} Use row-standardized panel weight matrix within each row sum equals 1. Default is Binary spatial panel weight matrix which each element is 0 or 1}{p_end}

{synopt :{opt gmm(1, 2, 3)} GMM Estimators:} 

{col 8}{bf:1- Initial GMM Model}
{col 8}{bf:2- Partial Weighted GMM Model}
{col 8}{bf:3- Full Weighted GMM Model}

{col 7}{opt nocons:tant}{col 20}Exclude Constant Term from Equation

{col 7}{opt level(#)}{col 20}confidence intervals level. Default is level(95)

{synopt :{opth vce(vcetype)} {opt ols}, {opt r:obust}, {opt cl:uster}, {opt boot:strap}, {opt jack:knife}, {opt hc2}, {opt hc3}}{p_end}

{synopt :{opt aux(varlist)}}add Auxiliary Variables into regression model, i.e., dummy variables. This option dont include these auxiliary variables among spatial lagged variables. Using many dummy variables must be used with caution to avoid multicollinearity problem, that results singular matrix, and lead to abort estimation.{p_end}

{p2colreset}{...}
{marker 03}{bf:{err:{dlgtab:Description}}}

{p 2 2 2} {cmd:spxttobit} estimates Tobit Spatial Panel Autoregressive Generalized Least Squares Model, when panel data model with error components are both spatially and time-wise correlated.
Generalized method of moments (GMM) that suggested in Kelejian-Prucha (1999), and Kapoor-Kelejian-Prucha (2007) are used in the estimation.
Since no softwares available till now to estimate Tobit Spatial Panel Autoregressive Generalized Least Squares Model, I designed {cmd:spxttobit} as a modification of Kapoor-Kelejian-Prucha (2007),
but here I let the estimations deal with Panel 2SLS models, with original constant term.{p_end}

{p 2 4 2}{cmd:spxttobit} can generate:{p_end}

    {cmd:- Binary Weight Matrix.}
    {cmd:- Row-Standardized Weight Matrix.}

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

{p 2 2 2}{bf:Note2:} You can use the dialog box for {dialog spxttobit}.{p_end}
{p 2 2 2}{bf:Note3:} xtset is included automatically in {cmd:spxttobit} models.{p_end}

{hline}

  {stata clear all}

  {stata sysuse spxttobit.dta, clear}

  {stata db spxttobit}

  {stata xtset id t}

  {stata spxttobit ys x1 x2 , wmfile(SPWxt) wmat(W) id(7) gmm(1)}

  {stata spxttobit ys x1 x2 , wmfile(SPWxt) wmat(W) id(7) gmm(2)}

  {stata spxttobit ys x1 x2 , wmfile(SPWxt) wmat(W) id(7) gmm(3)}
  
  {stata spxttobit ys x1 x2 , wmfile(SPWxt) wmat(W) id(7) gmm(1)}

  {stata spxttobit ys x1 x2 , wmfile(SPWxt) wmat(W) id(7) stand}

  {stata spxttobit ys x1 x2 , wmfile(SPWxt) wmat(W) id(7) aux(dcs1 dcs2 dcs3)}

  {stata spxttobit ys x1 x2 , wmfile(SPWxt) wmat(W) id(7) aux(dcs1 dcs2 dcs3) noconstant}
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

{bf:{err:{dlgtab:spxttobit Citation}}}

{phang}Shehata, Emad Abd Elmessih (2012){p_end}
{phang}{cmd:SPXTTOBIT: "Stata Module to Estimate Tobit Spatial Panel Autoregressive Generalized Least Squares Regression"}{p_end}

{title:Online Help:}

{p 4 12 2}{helpb gs3sls}, {helpb gs2slsxt}, {helpb spxttobit}, {helpb spregxt},
{helpb spglsxt}, {helpb spautoreg}, {helpb spmstar}, {helpb spmstarxt},
{helpb spweight}, {helpb spweightxt}, {helpb spweightcs}, {helpb spcs2xt},
{helpb xtidt}. {opt (if installed)}.{p_end}

{psee}
{p_end}
