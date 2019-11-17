*! diagreg V1.0 20oct2011
*! Emad Abd Elmessih Shehata
*! Assistant Professor
*! Agricultural Research Center - Agricultural Economics Research Institute - Egypt
*! Email: emadstat@hotmail.com
*! WebPage: http://emadstat.110mb.com/stata.htm

program define diagreg , rclass 
version 10.1
syntax varlist [if] [in] [aw fw iw pw] , [noCONStant vce(passthru) level(passthru)]
marksample touse
tempvar `varlist'
gettoken yvar xvar : varlist
 if "`weight'" != "" {
 local wgt "[`weight'`exp']"
 if "`weight'" == "pweight" {
 local awgt "[aw`exp']"
 }
 else local awgt "`wgt'"
 }
di
di as txt "{bf:{err:=================================================}}"
di as txt "{bf:{err:* Model Selection Diagnostic Criteria           *}}"
di as txt "{bf:{err:=================================================}}"
tempvar time
gen `time'=_n if `touse'
qui tsset `time'
regress `yvar' `xvar' if `touse' `wgt' , `constant' `vce' `level'
scalar SSE=e(rss)
scalar K=e(df_m)+1
scalar N=e(N)
scalar Sig2=SSE/(N-K)
scalar Sig2n=(SSE/N)
scalar SSE=e(rss)
scalar SSR=e(mss)
scalar SST=e(mss)+e(rss)
scalar R2=1-SSE/SST
scalar R2ad=1-(1-R2)*((N-1)/(N-K))
scalar F=R2/(1-R2)*(N-K)/(K-1)
scalar AIC1=Sig2n*exp(2*K/N)
scalar AIC2=(-2*e(ll)/N)+(2*K/N)
scalar LAIC=ln(Sig2n)+2*K/N
scalar FPE=Sig2*(1+K/N)
scalar SC1=Sig2n*N^(K/N)
scalar SC2=(-2*e(ll)/N)+(K*ln(N)/N)
scalar LSC=ln(Sig2n)+K*ln(N)/N
scalar HQ1=Sig2n*ln(N)^(2*K/N)
scalar HQ2=(-2*e(ll)/N)+(2*K*ln(ln(N))/N)
scalar Rice=Sig2n/(1-2*K/N)
scalar Shibata=Sig2n*(N+2*K)/N
scalar GCV=Sig2n*(1-K/N)^(-2)
scalar LLF=-(N/2)*ln(2*_pi*Sig2n)-(N/2)
di
di _dup(60) "-"
di as txt "* Sum of Squares Errors     SSE   = " %10.4f SSE
di as txt "* Sum of Squares Regression SSR   = " %10.4f SSR
di as txt "* Sum of Squares Total      SST   = " %10.4f SST
di as txt "* Number of observations    N     = " %10.4f N
di as txt "* Number of Parameters      K     = " %10.4f K
di as txt "* Variance of Estimate      Sig2  = " %10.4f Sig2
di as txt "* Variance of Estimate      Sig2n = " %10.4f Sig2n
di as txt "* R-squared                 R2    = " %10.4f R2
di as txt "* Adj R-squared             R2ad  = " %10.4f R2ad
di as txt "* F Test                    F     = " %10.4f F
di _dup(60) "-"
di as txt "* AKAIKE (1969) Final Prediction Error AIC1    = " %10.4f AIC1
di as txt "* AKAIKE (1969) Final Prediction Error AIC2    = " %10.4f AIC2
di as txt "* Akaike (1973) InFormation Criterion  ln AIC  = " %10.4f LAIC
di as txt "* Amemiya Prediction Criterion         FPE     = " %10.4f FPE
di as txt "* Schwartz (1978) Criterion            SC1     = " %10.4f SC1
di as txt "* Schwartz (1978) Criterion            SC2     = " %10.4f SC2
di as txt "* Schwarz(1978) Criterion              ln SC   = " %10.4f LSC
di as txt "* Hannan-Quinn(1979) Criterion         HQ1     = " %10.4f HQ1
di as txt "* Hannan-Quinn(1979) Criterion         HQ2     = " %10.4f HQ2
di as txt "* Rice    (1984) Criterion             Rice    = " %10.4f Rice
di as txt "* Shibata (1981) Criterion             Shibata = " %10.4f Shibata
di as txt "* Log Likelihood Function              LLF     = " %10.4f LLF
di as txt "* Craven-Wahba(1979) Generalized Cross Validation-GCV = " %10.4f GCV
di _dup(60) "-"
return scalar sse = SSE
return scalar ssr = SSR
return scalar sst = SST
return scalar n = N
return scalar k = K
return scalar sig2 = Sig2
return scalar sig2n = Sig2n
return scalar r2 = R2
return scalar r2ad = R2ad
return scalar f = F
return scalar aic1 = AIC1
return scalar aic2 = AIC2
return scalar laic = LAIC
return scalar fpe = FPE
return scalar sc1 = SC1
return scalar sc2 = SC2
return scalar lsc = LSC
return scalar hq1 = HQ1
return scalar hq2 = HQ2
return scalar rice = Rice
return scalar shibata = Shibata
return scalar llf = LLF
return scalar gcv = GCV
end

