{smcl}
{hline}
{cmd:help: {helpb xtregbem}}{space 55} {cmd:dialog:} {bf:{dialog xtregbem}}
{hline}

{bf:{err:{dlgtab:Title}}}

{bf:xtregbem: Between-Effects Panel Data: Ridge and Weighted Regression}

{marker 00}{bf:{err:{dlgtab:Table of Contents}}}
{p 4 8 2}

{p 5}{helpb xtregbem##01:Syntax}{p_end}
{p 5}{helpb xtregbem##02:Description}{p_end}
{p 5}{helpb xtregbem##03:Options}{p_end}
{p 5}{helpb xtregbem##04:Ridge Options}{p_end}
{p 5}{helpb xtregbem##05:Weight Options}{p_end}
{p 5}{helpb xtregbem##06:Weighted Variable Type Options}{p_end}
{p 5}{helpb xtregbem##07:Other Options}{p_end}
{p 5}{helpb xtregbem##08:Model Selection Diagnostic Criteria}{p_end}
{p 5}{helpb xtregbem##09:Heteroscedasticity Tests}{p_end}
{p 5}{helpb xtregbem##10:Saved Results}{p_end}
{p 5}{helpb xtregbem##11:References}{p_end}

{p 1}*** {helpb xtregbem##12:Examples}{p_end}

{p 5}{helpb xtregbem##13:Author}{p_end}

{p2colreset}{...}
{marker 01}{bf:{err:{dlgtab:Syntax}}}

{p 5 5 6}
{opt xtregbem} {depvar} {indepvars} {ifin} , {bf:{err:id(var)}} {bf:{err:it(var)}}{p_end} 
{p 3 5 6} 
{err: [} {opt rid:ge(orr|grr1|grr2|grr3)} {opt kr(#)}{p_end} 
{p 4 5 6} 
{opt lmh:et} {opt diag} {opt mfx(lin|log)} {opt pred:ict(new_var)} {opt res:id(new_var)}{p_end} 
{p 4 5 6} 
{opt weights(yh|yh2|abse|e2|le2|x|xi|x2|xi2)} {opt wv:ar(varname)} {opt iter(#)} {opt tech(name)} {opt nocons:tant}{p_end} 
{p 4 5 6} 
{opt coll dn tolog} {opt l:evel(#)} {opth vce(vcetype)} {err:]}{p_end}

{p2colreset}{...}
{marker 02}{bf:{err:{dlgtab:Description}}}

{p 2 2 2} {cmd:xtregbem} estimates Between-Effects Panel Data with Ridge and Weighted Regression, and calculate Panel Heteroscedasticity,
 Model Selection Diagnostic Criteria, and Marginal Effects and Elasticities{p_end}

{p 3 4 2} R2, R2 Adjusted, and F-Test, are obtained from 4 ways:{p_end} 
{p 5 4 2} 1- (Buse 1973) R2.{p_end}
{p 5 4 2} 2- Raw Moments R2.{p_end}
{p 5 4 2} 3- squared correlation between predicted (Yh) and observed dependent variable (Y).{p_end}
{p 5 4 2} 4- Ratio of variance between predicted (Yh) and observed dependent variable (Y).{p_end}

{p 5 4 2} - Adjusted R2: R2_a=1-(1-R2)*(N-1)/(N-K-1).{p_end}
{p 5 4 2} - F-Test=R2/(1-R2)*(N-K-1)/(K).{p_end}

{p 5 4 2} - in Adjusted R2: R2_a=1-(1-R2)*(N-1)/(N-K-1).{p_end}

{p2colreset}{...}
{marker 03}{bf:{err:{dlgtab:Options}}}

{col 7}* {cmd: {opt id(var)}{col 20}Cross Sections ID variable name}
{col 7}* {cmd: {opt it(#)}{col 20}Time Series ID variable name}

{p2colreset}{...}
{marker 04}{bf:{err:{dlgtab:Ridge Options}}}

{p 3 6 2} {opt kr(#)} Ridge k value, must be in the range (0 < k < 1).{p_end}

{p 3 6 2}IF {bf:kr(0)} in {opt ridge(orr, grr1, grr2, grr3)}, the model will be normal panel regression.{p_end}

{col 3}{bf:ridge({err:{it:orr}})} : Ordinary Ridge Regression    [Judge,et al(1988,p.878) eq.21.4.2].
{col 3}{bf:ridge({err:{it:grr1}})}: Generalized Ridge Regression [Judge,et al(1988,p.881) eq.21.4.12].
{col 3}{bf:ridge({err:{it:grr2}})}: Iterative Generalized Ridge  [Judge,et al(1988,p.881) eq.21.4.12].
{col 3}{bf:ridge({err:{it:grr3}})}: Adaptive Generalized Ridge   [Strawderman(1978)].

{p 2 4 2}{cmd:xtregbem} estimates Ordinary Ridge regression as a multicollinearity remediation method.{p_end}
{p 2 4 2}General form of Ridge Coefficients and Covariance Matrix are:{p_end}

{p 2 4 2}{cmd:Br = inv[X'X + kI] X'Y}{p_end}

{p 2 4 2}{cmd:Cov=Sig^2 * inv[X'X + kI] (X'X) inv[X'X + kI]}{p_end}

where:
    Br = Ridge Coefficients Vector (k x 1).
   Cov = Ridge Covariance Matrix (k x k).
     Y = Dependent Variable Vector (N x 1).
     X = Independent Variables Matrix (N x k).
     k = Ridge Value (0 < k < 1).
     I = Diagonal Matrix of Cross Product Matrix (Xs'Xs).
    Xs = Standardized Variables Matrix in Deviation from Mean. 
  Sig2 = (Y-X*Br)'(Y-X*Br)/DF

{p2colreset}{...}
{marker 05}{bf:{err:{dlgtab:Weight Options}}}

{synoptset 16}{...}
{synopt:{bf:wvar({err:{it:varname}})}}Weighted Variable Name{p_end}

{col 10}{cmd:xtregbem} not like official Stata command {helpb xtreg} in weight option,
{col 10}{cmd:xtregbem} can use large types of weighted regression options.
{col 10}{bf:wvar( )} {cmd:must be combined with:} {bf:weights(x, xi, x2, xi2)}"

{p2colreset}{...}
{marker 06}{bf:{err:{dlgtab:Weighted Variable Type Options}}}
{synoptset 16}{...}

{synopt:{bf:weights({err:{it:yh}})}}Yh - Predicted Value{p_end}
{synopt:{bf:weights({err:{it:yh2}})}}Yh^2 - Predicted Value Squared{p_end}
{synopt:{bf:weights({err:{it:abse}})}}abs(E) - Absolute Value of Residual{p_end}
{synopt:{bf:weights({err:{it:e2}})}}E^2 - Residual Squared{p_end}
{synopt:{bf:weights({err:{it:le2}})}}log(E^2) - Log Residual Squared{p_end}
{synopt:{bf:weights({err:{it:x}})}}(x) Variable{p_end}
{synopt:{bf:weights({err:{it:xi}})}}(1/x) Inverse Variable{p_end}
{synopt:{bf:weights({err:{it:x2}})}}(x^2) Squared Variable{p_end}
{synopt:{bf:weights({err:{it:xi2}})}}(1/x^2) Inverse Squared Variable{p_end}

{p2colreset}{...}
{marker 07}{bf:{err:{dlgtab:Other Options}}}

{col 7}{opt coll}{col 20}keep collinear variables in {bf:model({err:{it:xttobit}})}}

{col 7}{opt nocons:tant}{col 20}Exclude Constant Term from Equation

{col 20}{cmd:xtregbem} not like official Stata command {helpb xtreg} in constant term option,
{col 20}{cmd:xtregbem} can exclude constant term.
{col 20}{cmd:weights} option also can be used here.

{col 7}{opt dn}{col 20}Use (N) divisor instead of (N-K) for Degrees of Freedom (DF)

{col 7}{opt iter(#)}{col 20}number of iterations; Default is iter(100)

{col 7}{opt level(#)}{col 20}confidence intervals level. Default is level(95)

{col 3}{opt mfx(lin, log)}{col 20}functional form: Linear model {cmd:(lin)}, or Log-Log model {cmd:(log)},
{col 20}to compute Marginal Effects and Elasticities
   - In Linear model: marginal effects are the coefficients (Bm),
        and elasticities are (Es = Bm X/Y).
   - In Log-Log model: elasticities are the coefficients (Es),
        and the marginal effects are (Bm = Es Y/X).
   - {opt mfx(log)} and {opt tolog} options must be combined, to transform linear variables to log form.

{col 7}{opt tolog}{col 20}Convert dependent and independent variables
{col 20}to LOG Form in the memory for Log-Log regression.
{col 20}{opt tolog} Transforms {depvar} and {indepvars}
{col 20}to Log Form without lost the original data variables

{col 7}{opt pred:ict(new_variable)}{col 30}Predicted values variable

{col 7}{opt res:id(new_variable)}{col 30}Residuals values variable
{col 15} computed as Ue=Y-Yh ; that is known as combined residual: [Ue = U_i + E_it]
{col 15} overall error component is computed as: [E_it]
{col 15} see: {help xtreg postestimation##predict}

{col 4}{opth vce(vcetype)} {opt ols}, {opt r:obust}, {opt cl:uster}, {opt boot:strap}, {opt jack:knife}, {opt hc2}, {opt hc3}}

{p2colreset}{...}
{marker 08}{bf:{err:{dlgtab:Model Selection Diagnostic Criteria}}}

{synopt :{opt diag} Model Selection Diagnostic Criteria:}{p_end}
	- Log Likelihood Function       LLF
	- Akaike Final Prediction Error AIC
	- Schwartz Criterion            SC
	- Akaike Information Criterion  ln AIC
	- Schwarz Criterion             ln SC
	- Amemiya Prediction Criterion  FPE
	- Hannan-Quinn Criterion        HQ
	- Rice Criterion                Rice
	- Shibata Criterion             Shibata
	- Craven-Wahba Generalized Cross Validation-GCV

{p2colreset}{...}
{marker 09}{bf:{err:{dlgtab:Groupwise Panel Heteroscedasticity Tests}}}
{synopt :{opt lmh:et} Groupwise Panel Heteroscedasticity Tests:}{p_end}
	* Ho: Panel Homoscedasticity - Ha: Panel Groupwise Heteroscedasticity
	- Lagrange Multiplier LM Test
	- Likelihood Ratio LR Test
	- Wald Test

{p2colreset}{...}
{marker 10}{bf:{err:{dlgtab:Saved Results}}}

{p 2 4 2 }{cmd:xtregbem} saves the following results in {cmd:e()}:

{err:*** Model Selection Diagnostic Criteria:}
{col 4}{cmd:e(N)}{col 20}number of observations
{col 4}{cmd:e(r2bu)}{col 20}R-squared (Buse 1973)
{col 4}{cmd:e(r2bu_a)}{col 20}R-squared Adj (Buse 1973)
{col 4}{cmd:e(r2raw)}{col 20}Raw Moments R2
{col 4}{cmd:e(r2raw_a)}{col 20}Raw Moments R2 Adj
{col 4}{cmd:e(f)}{col 20}F-test
{col 4}{cmd:e(fp)}{col 20}F-test P-Value
{col 4}{cmd:e(wald)}{col 20}Wald-test
{col 4}{cmd:e(waldp)}{col 20}Wald-test P-Value

{col 4}{cmd:e(r2h)}{col 20}R2 Between Predicted (Yh) and Observed DepVar (Y)
{col 4}{cmd:e(r2h_a)}{col 20}Adjusted r2h
{col 4}{cmd:e(fh)}{col 20}F-test due to r2h
{col 4}{cmd:e(fhp)}{col 20}F-test due to r2h P-Value

{col 4}{cmd:e(r2v)}{col 20}R2 Variance Ratio Between Predicted (Yh) and Observed DepVar (Y)
{col 4}{cmd:e(r2v_a)}{col 20}Adjusted r2v
{col 4}{cmd:e(fv)}{col 20}F-test due to r2v
{col 4}{cmd:e(fvp)}{col 20}F-test due to r2v P-Value

{col 4}{cmd:e(sig)}{col 20}Root MSE (Sigma)
{col 4}{cmd:e(llf)}{col 20}Log Likelihood Function
{col 4}{cmd:e(aic)}{col 20}Akaike Final Prediction Error AIC
{col 4}{cmd:e(sc)}{col 20}Schwartz Criterion SC
{col 4}{cmd:e(laic)}{col 20}Akaike Information Criterion ln AIC
{col 4}{cmd:e(lsc)}{col 20}Schwarz Criterion Log SC
{col 4}{cmd:e(fpe)}{col 20}Amemiya Prediction Criterion FPE
{col 4}{cmd:e(hq)}{col 20}Hannan-Quinn Criterion HQ
{col 4}{cmd:e(shibata)}{col 20}Shibata Criterion Shibata
{col 4}{cmd:e(rice)}{col 20}Rice Criterion Rice
{col 4}{cmd:e(gcv)}{col 20}Craven-Wahba Generalized Cross Validation-GCV
{col 4}{cmd:e(df1)}{col 20}DF1
{col 4}{cmd:e(df2)}{col 20}DF2
{col 4}{cmd:e(rmse)}{col 20}Root Mean Squared Error
{col 4}{cmd:e(rss)}{col 20}Residual Sum of Squares

{err:*** Groupwise Heteroscedasticity Tests:}
{col 4}{cmd:e(lmhglm)}{col 20}Lagrange Multiplier LM Test
{col 4}{cmd:e(lmhglmp)}{col 20}Lagrange Multiplier LM Test P-Value
{col 4}{cmd:e(lmhglr)}{col 20}Likelihood Ratio LR Test
{col 4}{cmd:e(lmhglrp)}{col 20}Likelihood Ratio LR Test P-Value
{col 4}{cmd:e(lmhgw)}{col 20}Wald Test
{col 4}{cmd:e(lmhgwp)}{col 20}Wald Test P-Value

{p2colreset}{...}
{marker 11}{bf:{err:{dlgtab:References}}}

{p 4 8 2}Breusch, Trevor & Adrian Pagan (1980)
{cmd: "The Lagrange Multiplier Test and its Applications to Model Specification in Econometrics",}
{it:Review of Economic Studies 47}; 239-253.

{p 4 8 2}Greene, William (2007)
{cmd: "Econometric Analysis",}
{it:6th ed., Macmillan Publishing Company Inc., New York, USA.}.

{p 4 8 2}Judge, Georege, R. Carter Hill, William . E. Griffiths, Helmut Lutkepohl, & Tsoung-Chao Lee (1988)
{cmd: "Introduction To The Theory And Practice Of Econometrics",}
{it:2nd ed., John Wiley & Sons, Inc., New York, USA}.

{p 4 8 2}Judge, Georege, W. E. Griffiths, R. Carter Hill, Helmut Lutkepohl, & Tsoung-Chao Lee(1985)
{cmd: "The Theory and Practice of Econometrics",}
{it:2nd ed., John Wiley & Sons, Inc., New York, USA}.

{p2colreset}{...}
{marker 12}{bf:{err:{dlgtab:Examples}}}

  {stata clear all}

  {stata sysuse xtregbem.dta, clear}

  {stata db xtregbem}

  {stata xtregbem y x1 x2 , id(id) it(t) mfx(lin) diag lmh predict(yh) resid(e)}

  {stata xtregbem y x1 x2 , id(id) it(t) mfx(lin) predict(yh) diag lmh}
 
  {stata xtregbem y x1 x2 , id(id) it(t) mfx(log) tolog predict(yh) diag lmh}
  
  {stata xtregbem y x1 x2 , id(id) it(t) mfx(lin) ridge(orr) kr(0.5)}

  {stata xtregbem y x1 x2 , id(id) it(t) mfx(lin) ridge(grr1)}

  {stata xtregbem y x1 x2 , id(id) it(t) mfx(lin) ridge(grr2)}

  {stata xtregbem y x1 x2 , id(id) it(t) mfx(lin) ridge(grr3)}

  {stata xtregbem y x1 x2 , id(id) it(t) mfx(lin) ridge(grr1) weight(x) wvar(x1) diag lmh}
{hline}

. clear all
. sysuse xtregbem.dta, clear
. xtregbem y x1 x2 , id(id) it(t) mfx(lin) ridge(grr1) weight(x) wvar(x1) diag lmh

==============================================================================
* Between-Effects Panel Data: Ridge and Weighted Regression
==============================================================================
  y = x1 + x2
------------------------------------------------------------------------------
* Weighted Regression Type: (X)     -   Variable: (x1) *
------------------------------------------------------------------------------
  Ridge k Value     =   0.07455     |   Generalized Ridge Regression
------------------------------------------------------------------------------
  Sample Size       =          49   |   Cross Sections Number   =           7
  Wald Test         =    279.8123   |   P-Value > Chi2(2)       =      0.0000
  F-Test            =    139.9062   |   P-Value > F(2 , 40)     =      0.0000
 (Buse 1973) R2     =      0.2789   |   Raw Moments R2          =      0.8668
 (Buse 1973) R2 Adj =      0.1346   |   Raw Moments R2 Adj      =      0.8401
  Root MSE (Sigma)  =     14.8366   |   Log Likelihood Function =   -196.7137
------------------------------------------------------------------------------
- R2h= 0.3591   R2h Adj= 0.2309  F-Test =   12.89 P-Value > F(2 , 40)  0.0000
- R2v= 0.2512   R2v Adj= 0.1014  F-Test =    7.71 P-Value > F(2 , 40)  0.0015
------------------------------------------------------------------------------
           y |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
          x1 |  -.5022847   .0807301    -6.22   0.000    -.6654463    -.339123
          x2 |  -2.006452   .2077228    -9.66   0.000    -2.426276   -1.586629
       _cons |   84.41456     3.2403    26.05   0.000     77.86567    90.96345
------------------------------------------------------------------------------

==============================================================================
* Panel Model Selection Diagnostic Criteria
==============================================================================

- Log Likelihood Function       LLF               =  -196.7137
- Akaike Final Prediction Error AIC               =   399.4273
- Schwartz Criterion            SC                =   405.1028
- Akaike Information Criterion  ln AIC            =     5.3137
- Schwarz Criterion             ln SC             =     5.4295
- Amemiya Prediction Criterion  FPE               =   233.6014
- Hannan-Quinn Criterion        HQ                =   212.2246
- Rice Criterion                Rice              =   204.7668
- Shibata Criterion             Shibata           =   201.6966
- Craven-Wahba Generalized Cross Validation-GCV   =   203.8959
------------------------------------------------------------------------------

==============================================================================
* Panel Groupwise Heteroscedasticity Tests
==============================================================================
  Ho: Panel Homoscedasticity - Ha: Panel Groupwise Heteroscedasticity

- Lagrange Multiplier LM Test     =   7.3373     P-Value > Chi2(6)   0.2908
- Likelihood Ratio LR Test        =   7.1253     P-Value > Chi2(6)   0.3094
- Wald Test                       =  12.4812     P-Value > Chi2(7)   0.0858
------------------------------------------------------------------------------

* Linear: Marginal Effect - Elasticity *

+-----------------------------------------------------------------------------+
|     Variable | Marginal_Effect(B) |     Elasticity(Es) |               Mean |
|--------------+--------------------+--------------------+--------------------|
|           x1 |            -0.5023 |            -0.5496 |            38.4362 |
|           x2 |            -2.0065 |            -0.8211 |            14.3749 |
+-----------------------------------------------------------------------------+
 Mean of Dependent Variable =   35.1288

{p2colreset}{...}
{marker 13}{bf:{err:{dlgtab:Author}}}

  {hi:Emad Abd Elmessih Shehata}
  {hi:Assistant Professor}
  {hi:Agricultural Research Center - Agricultural Economics Research Institute - Egypt}
  {hi:Email:   {browse "mailto:emadstat@hotmail.com":emadstat@hotmail.com}}
  {hi:WebPage:{col 27}{browse "http://emadstat.110mb.com/stata.htm"}}
  {hi:WebPage at IDEAS:{col 27}{browse "http://ideas.repec.org/f/psh494.html"}}
  {hi:WebPage at EconPapers:{col 27}{browse "http://econpapers.repec.org/RAS/psh494.htm"}}

{bf:{err:{dlgtab:xtregbem Citation}}}

{phang}{cmd:Shehata, Emad Abd Elmessih (2012)}{p_end}
{phang}{cmd:XTREGBEM: "Stata Module to Estimate Between-Effects Panel Data: Ridge and Weighted Regression"}{p_end}

{title:Online Help:}

{p 2 2 2} {helpb ghxt}, {helpb lmcovxt}, {helpb lmhlmxt}, {helpb lmhlrxt},
{helpb xtregam}, {helpb xtregbem}, {helpb xtregbn}, {helpb xtregdhp},
{helpb xtregfem}, {helpb xtreghet}, {helpb xtregmle}, {helpb xtregrem},
{helpb xtregsam}, {helpb xtregwem}, {helpb xtregwhm}. {opt (if installed)}.{p_end}

{psee}
{p_end}

