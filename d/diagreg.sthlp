{smcl}
{hline}
{cmd:help: {helpb diagreg}}{space 55} {cmd:dialog:} {bf:{dialog diagreg}}
{hline}


{bf:{err:{dlgtab:Title}}}

{bf: diagreg: Model Selection Diagnostic Criteria}


{bf:{err:{dlgtab:Syntax}}}

{p 8 16 2}
{opt diagreg} {depvar} {indepvars} {ifin} {weight} , [ {opt nocons:tant} {opth vce(vcetype)} ]{p_end} 

{bf:{err:{dlgtab:Options}}}
{synoptset 20 tabbed}{...}

{synopt :{opt nocons:tant}}suppress constant term{p_end}

{syntab:SE/Robust}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt ols},
   {opt r:obust}, {opt cl:uster} {it:clustvar}, {opt boot:strap}, 
   {opt jack:knife}, {opt hc2}, or {opt hc3}{p_end}

{bf:{err:{dlgtab:Description}}}

{p 2 2 2}{cmd:diagreg} computes model selection diagnostic criteria, after OLS {helpb regress} regression.{p_end} 

{bf:{err:{dlgtab:Saved Results}}}

{pstd}
{cmd:diagreg} saves the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 10 10 2: Scalars}{p_end}

{synopt:{cmd:r(sse)}}Sum of Squares Errors{p_end}
{synopt:{cmd:r(ssr)}}Sum of Squares Regression{p_end}
{synopt:{cmd:r(sst)}}Sum of Squares Total{p_end}
{synopt:{cmd:r(n)}}Number of observations{p_end}
{synopt:{cmd:r(k)}}Number of Parameters{p_end}
{synopt:{cmd:r(sig2)}}Variance of Estimate{p_end}
{synopt:{cmd:r(sig2n)}}Variance of Estimate{p_end}
{synopt:{cmd:r(r2)}}R-squared{p_end}
{synopt:{cmd:r(r2ad)}}Adj R-squared{p_end}
{synopt:{cmd:r(f)}}F Test{p_end}
{synopt:{cmd:r(aic1)}}AKAIKE (1969) Final Prediction Error{p_end}
{synopt:{cmd:r(aic2)}}AKAIKE (1969) Final Prediction Error{p_end}
{synopt:{cmd:r(laic)}}Akaike (1973) InFormation Criterion{p_end}
{synopt:{cmd:r(fpe)}}Amemiya Prediction Criterion{p_end}
{synopt:{cmd:r(sc1)}}Schwartz (1978) Criterion{p_end}
{synopt:{cmd:r(sc2)}}Schwartz (1978) Criterion{p_end}
{synopt:{cmd:r(lsc)}}Schwarz(1978) Criterion{p_end}
{synopt:{cmd:r(hq1)}}Hannan-Quinn(1979) Criterion{p_end}
{synopt:{cmd:r(hq2)}}Hannan-Quinn(1979) Criterion{p_end}
{synopt:{cmd:r(rice)}}Rice (1984) Criterion Rice{p_end}
{synopt:{cmd:r(shibata)}}Shibata (1981) Criterion Shibata{p_end}
{synopt:{cmd:r(llf)}}Log Likelihood Function{p_end}
{synopt:{cmd:r(gcv)}}Craven-Wahba(1979) Generalized Cross Validation{p_end}


{bf:{err:{dlgtab:Examples}}}

	{stata clear all}

	{stata db diagreg}

	{stata sysuse diagreg.dta, clear}

	{stata diagreg y x1 x2}

	{stata return list}


  =================================================
  * ModeL Selection Diagnostic Criteria           *
  =================================================
  * Sum of Squares Errors     SSE   =  433.3130
  * Sum of Squares Regression SSR   = 8460.9371
  * Sum of Squares Total      SST   = 8894.2502
  * Number of observations    N     =   17.0000
  * Number of Parameters      K     =    3.0000
  * Variance of Estimate      Sig2  =   30.9509
  * Variance of Estimate      Sig2n =   25.4890
  * R-squared                 R2    =    0.9513
  * Adj R-squared             R2ad  =    0.9443
  * F Test                    F    =  136.6831
  * AKAIKE (1969) Final Prediction Error AIC1    =   36.2772
  * AKAIKE (1969) Final Prediction Error AIC2    =    6.4291
  * Akaike (1973) InFormation Criterion  ln AIC  =    3.5912
  * Amemiya Prediction Criterion         FPE     =   36.4129
  * Schwartz (1978) Criterion            SC1     =   42.0234
  * Schwartz (1978) Criterion            SC2     =    6.5761
  * Schwarz(1978) Criterion              ln SC   =    3.7382
  * Hannan-Quinn(1979) Criterion         HQ1     =   36.8113
  * Hannan-Quinn(1979) Criterion         HQ2     =    6.4437
  * Rice    (1984) Criterion             Rice    =   39.3921
  * Shibata (1981) Criterion             Shibata =   34.4851
  * Log Likelihood Function              LLF     =  -51.6471
  * Craven-Wahba(1979) Generalized Cross Validation-GCV =   37.5833


{bf:{err:{dlgtab:References}}}

{p 4 8 2}Judge, Georege, R. Carter Hill, William . E. Griffiths, Helmut Lutkepohl, & Tsoung-Chao Lee (1988)
{cmd: "Introduction To The Theory And Practice Of Econometrics",}
{it:2nd ed., John Wiley & Sons, Inc., New York, USA}.

{p 4 8 2}Judge, Georege, W. E. Griffiths, R. Carter Hill, Helmut Lutkepohl, & Tsoung-Chao Lee(1985)
{cmd: "The Theory and Practice of Econometrics",}
{it:2nd ed., John Wiley & Sons, Inc., New York, USA}; 242.


{bf:{err:{dlgtab:Author}}}

  {hi:Emad Abd Elmessih Shehata}
  {hi:Assistant Professor}
  {hi:Agricultural Research Center - Agricultural Economics Research Institute - Egypt}
  {hi:Email:   {browse "mailto:emadstat@hotmail.com":emadstat@hotmail.com}}
  {hi:WebPage:{col 27}{browse "http://emadstat.110mb.com/stata.htm"}}
  {hi:WebPage at IDEAS:{col 27}{browse "http://ideas.repec.org/f/psh494.html"}}
  {hi:WebPage at EconPapers:{col 27}{browse "http://econpapers.repec.org/RAS/psh494.htm"}}


{bf:{err:{dlgtab:diagreg Citation}}}

{phang}Shehata, Emad Abd Elmessih (2011){p_end}
{phang}{cmd: "diagreg: Stata Module to Compute Model Selection Diagnostic Criteria"}{p_end}

{psee}
{p_end}

