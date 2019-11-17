*! lmcovxt V1.0 15jan2012
*! Emad Abd Elmessih Shehata
*! Assistant Professor
*! Agricultural Research Center - Agricultural Economics Research Institute - Egypt
*! Email: emadstat@hotmail.com
*! WebPage: http://emadstat.110mb.com/stata.htm

program lmcovxt, rclass
version 10
syntax varlist [if] [in] [aw fw iw pw] , Id(str) [ NOCONStant vce(passthru) level(passthru)]
marksample touse
tempvar `varlist'
gettoken yvar xvar : varlist
markout `touse' `xvar'
tempvar  TM NT NC U LMCov E Ms N E1 Em Ti U1 Uu tm idv itv Time
tempname TM NT NC U LMCov E Ms N E1 Em Ti U1 Uu
 gettoken yvar xvar : varlist
 local both : list yvar & xvar
 if "`both'" != "" {
di
di as err " {bf:{cmd:`both'} included in both LHS & RHS Variables}"
di as res " LHS: `yvar'"
di as res " RHS:`xvar'"
 exit
 } 
marksample touse
qui gen `Time'=_n if `touse'
qui summ `Time' if `touse'
local NT = r(N)
local S = `id'
local T = `NT'/`id'
scalar S = `S'
scalar T = `T'
scalar NT = `NT'
qui cap drop `idv'
qui cap drop `itv'
qui gen `idv'=0 if `touse'
qui gen `itv'=0 if `touse'
qui forvalues i = 1/`id' {
qui summ `Time' if `touse' , meanonly
local min=int(`T'*`i'-`T'+1)
local max=int(`T'*`i')
 replace `idv'= `i' in `min'/`max'
 replace `itv'= `Time'-`min'+1 in `min'/`max'
 }
 qui summ `idv' if `touse'
 scalar Tidv=r(max)
 qui summ `itv' if `touse'
 scalar Titv=r(max)
 if `NT' != Titv*Tidv {
 di 
 di as err " Number of obs  = " `NT'
 di as err " Cross Sections = " Tidv
 di as err " Time           = " Titv
 di as res " Product of (Time x Cross Sections) must be Equal Sample Size"
 di as err " {bf:id(`S')} {cmd:Wrong Number, Check Correct Number Units of Cross Sections.}"
 exit
 }
 local id `idv'
 qui tab `id' if `touse'
qui set matsize `NT'
qui regress `yvar' `xvar' if `touse' `wgt' , `noconstant' `vce' `level'
qui predict double `E' if `touse' , resid
qui mkmat `E' if `touse' , matrix(`E')
qui levels `id' , local(levels)
qui foreach i of local levels {
qui summ `Time' if `id' == `i'
scalar min=r(min)
scalar max=r(max)
local min min
local max max
matrix `E'`i'=`E'[`min'..`max', 1..1]
qui svmat `E'`i' , name(`E'`i')
qui svmat `E'`i' , name(`Uu'`i')
 }
qui levels `id' , local(levels)
qui foreach i of local levels {
qui foreach j of local levels {
qui gen `U'`i'`j' = `E'`i'*`E'`j' if `touse' 
qui summ `U'`i'`j' if `touse' 
scalar s`i'`j'=r(sum)
 }
 }
scalar M=0
qui gen `Ms'=0 if `touse' 
qui levels `id' , local(levels)
qui foreach i of local levels {
qui foreach j of local levels {
 replace `Ms'=s`i'`j'^2/(s`i'`i'*s`j'`j') if `touse'
 summ `Ms' if `i' < `j'
scalar M`i'`j'=M+ r(mean)
 gen `LMCov'`i'`j'=M`i'`j' if `touse' 
 }
 }
qui egen `LMCov'=rowtotal(`LMCov'*) in 1/1
local lmcov=`LMCov'*T
local lmcovdf = S*(S-1)/2
local lmcovp = chiprob(`lmcovdf', abs(`lmcov'))
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Breusch-Pagan LM Diagonal Covariance Matrix Test}}"
di _dup(78) "{bf:{err:=}}"
di as res _col(5) "Ho: Run OLS Regression  -  Ha: Run Panel Regression"
di
di as txt _col(5) "Lagrange Multiplier Test" _col(30) " = " as res %10.5f `lmcov'
di as txt _col(5) "Degrees of Freedom" _col(30) " = " as res %10.1f `lmcovdf'
di as txt _col(5) "P-Value > Chi2(" `lmcovdf' ")" _col(30) " = " as res %10.5f `lmcovp'
di _dup(78) "{bf:{err:=}}"
qui `cmd'
return scalar lmcov = `lmcov'
return scalar lmcovp= `lmcovp'
return scalar lmcovdf= `lmcovdf'
end
