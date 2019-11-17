*! version 2.00 94/10/24        STB-27: snp6.2
program define bandw
  version 3.1
*Authors: Salgado-Ugarte, I.H., M. Shimizu, and T. Taniuchi.
*First written: 94/10/24 (version 1.00) ; Last revised 95/03/07
*This program calculates several "optimal" number of bins and
*binwidths-bandwidths for kernel density estimators for univariate
* data according to the following expressions: 
*I Rules for number of bins
*a) Histograms
* 1) Sturges' number of bins rule: k = 1 + log2(n)
* 2) OS number of bins rule: (b - a)/h* >= (b-a)/hOS = (2n)^1/3
*b) Frequency polygons
* 3) FP OS Number of bins rule: (b - a)/h* >= ((147/2)*n)^1/5
*II Rules for histogram bindwidth selection
* 4) Scott's Normal bindwidth reference rule: h = 3.5*sigma*n^-1/3
* 5) Freedman-Diaconis robust binwidth rule: h = 2(IQ)n^-1/3
* 6) Oversmoothed (OS) binwidth: h* <= (b - a)/(2n)^1/3 = hOS
* 7) OS homoscedastic rule: h*<= 3.729*sigma*n^-1/3 = hOS
* 8) OS robust rule: h* <= 2.603(IQ)n^-1/3 = hOS
*III Rules for FP binwidth selection
* 9) FP Gaussian reference rule: h = 2.15*sigma*n^-1/5
* 10) FP OS rule: h <= (23,328/343)^1/5 sigma*n^-1/5 = 2.33*sigma*n^-1/5 = hOS
*IV Rules for kernel bandwidth selection
* 11) Silverman's Normal bandwidth reference rule: ho=0.9 min(sigma,IQ/1.349)n^-1/5
* 12) Haerdle's Better rule of thumb: ho = 1.06 min(sigma, IQ/1.349)n^-1/5
* 13) Scott's (Gaussian) kernel oversmoothed bandwidth: ho>=1.144*sigma*n^-1/5
*Based on the equations included in Fox (1990), Silverman (1986),
*Haerdle (1991) and Scott (1992)

local varlist "req ex min(1) max(1)"
local if "opt"
local in "opt"

parse "`*'"
*parse "`varlist'", parse(" ")

tempvar xvar

quietly {
preserve
gen `xvar'=`1' `if' `in'
drop if `xvar'==.
if `xvar'[1]==. {
   di in red "no observations"
   exit}

summ `xvar', detail
local nuobs= _result(1)
local maxval= _result(6)
local minval= _result(5)
local sigma= sqrt(_result(4))
local iqr= _result(11)-_result(9)
local psigma= `iqr'/1.349
*number of bins histograms
local ks=1 + log(`nuobs')/log(2)
local osb= (2*`nuobs')^(1/3)
*number of bins FP
local fposb=((147/2)*`nuobs')^(1/5)
*binwidth rules histograms
local hs= 3.5*`sigma'*`nuobs'^(-1/3)
local hfd= 2*(`iqr')*`nuobs'^(-1/3)
local osh= (`maxval'-`minval')/((2*`nuobs')^(1/3))
local osuv= 3.729*`sigma'*`nuobs'^(-1/3)
local osr= 2.603*`iqr'*`nuobs'^(-1/3)
*bindwidth rules FP
local fpg= 2.15*`sigma'*`nuobs'^(-1/5)
local fpos=2.33*`sigma'*`nuobs'^(-1/5)
*bandwidth rules Gaussian kernel
local hsv= 0.9*min(`sigma',`psigma')*`nuobs'^(-1/5)
local hh= 1.06*min(`sigma',`psigma')*`nuobs'^(-1/5)
local sgoh=1.144*`sigma'*`nuobs'^(-1/5)
}
display _dup(60) "_"
display "Some practical number of bins and binwidth-bandwidth rules"
display "for univariate density estimation using histograms,"
display "frequency polygons (FP) and kernel estimators"
display _dup(60) "="
display _newline "Sturges' number of bins = " _col(50) %8.4f `ks'
display "Oversmoothed number of bins <= " _col(50)%8.4f `osb'
display _dup(60) "-"
display "FP oversmoothed number of bins <= " _col(50)%8.4f `fposb'
display _dup(60) "="
display _newline "Scott's Gaussian binwidth = " _col(50)%8.4f `hs'
display "Freedman-Diaconis robust binwidth = " _col(50)%8.4f `hfd'
display "Terrell-Scott's oversmoothed binwidth >= " _col(50)%8.4f `osh'
display "Oversmoothed Homoscedastic binwidth >= " _col(50)%8.4f `osuv'
display "Oversmoothed robust binwidth >= " _col(50)%8.4f `osr'
display _dup(60) "-"
display "FP Gaussian binwidth = " _col(50)%8.4f `fpg'
display "FP oversmoothed binwidth >= " _col(50)%8.4f `fpos'
display _dup(60) "="
display _newline "Silverman's Gaussian kernel bandwidth = " _col(50)%8.4f `hsv'
display "Haerdle's 'better' Gaussian kernel bandwidth = " _col(50)%8.4f `hh'
display "Scott's Gaussian kernel oversmoothed bandwidth = " _col(50)%8.4f `sgoh'
display _dup(60) "_"
end
