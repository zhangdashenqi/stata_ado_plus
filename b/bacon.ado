******************************************
**            Sylvain Weber             **
**         University of Geneva         **
**        Department of Economics       **
**     mail: sylvain.weber@unige.ch     **
**     This version: March 22, 2010     **
******************************************

*! version 1.0.1 Sylvain Weber 22mar2010
program bacon, rclass sortpreserve
version 9.0

********************************************************************************************
*** Program implementing the BACON algorithm proposed by Billor, Hadi & Velleman (2000)  ***
********************************************************************************************

syntax varlist [if] [in], GENerate(string) [REPLACE] [Percentile(real .15)] [Version(integer 1)] [C(integer 4)]

/*
Syntax explanations:
- generate(newvar1 [newvar2]) is not optional; it identifies the new variable(s) to be created.
  Whether you specify two variables or one, however, is optional. newvar2, if specified, 
  will contain the distances (not the distances squared) from the final basic subset. 
  That is, specifying gen(out) creates the variable out containing 1 if the observation is 
  an outlier and 0 otherwise. Specifying gen(out dist) also creates variable dist 
  containing the distances.
- replace specifies that newvar1 and newvar2 should be replaced if they already exist.
- version(1 or 2) indicates which version of the BACON algoritm should be used for identifying 
  the initial basic subset in the multivariate data. Verson 1 uses Mahalanobis distances.
  Version 2 uses medians. By default, version(1) is used.
- c(integer) is used to define the size of the initial subset = c * number of variables. 
  By default c(4) is used.
- percentile(#) specifies the percentile of the chi square distribution that will be used
  to identify outliers. It must be 0 < # < 1. The default is p(.05). Larger numbers 
  identify a larger proportion of the sample as outliers. If # is specified greater than 1, 
  it is interpreted as a percent. Thus, p(5) is the same as p(.05).
*/


*******************************************
*** Tests on the validity of parameters ***
*******************************************

tokenize `generate'
if `"`3'"'!="" {
	error 198
}
local marker `1'
local Dvar `2'		/* may be null */
if `"`replace'"'=="replace" {
	capture drop `marker'
	capture drop `Dvar'
}
confirm new var `marker' `Dvar'

if `version'!=1 & `version'!=2 {
	di as error "Version is either 1 or 2."
	error 198
}
confirm integer number `c'

if (`percentile'>=1) {
	local percentile=`percentile'/100
}
if (`percentile'<=0 | `percentile'>=1) { 
	di in red "percentile() invalid"
	exit 198
}

marksample touse 		/* mark observations for inclusion */
tokenize `varlist' 	/* divide strings into tokens `1', `2', ... */

local i 1
while `"``i''"'!="" {
	local ++i
}
local nvar = `i'-1	/* nvar = number of variables (p) */
quietly: count
local tobs = r(N)		/* tobs = total number of observations */
quietly: count if `touse'
local nobs = r(N)		/* nobs = number of observations used (n) */

local base = `c'*`nvar'	/* Size of the initial basic subset */

tempvar out
quietly: gen `out' = 0 if `touse'
label var `out' `"BACON outlier (p=`percentile')"' 

tempvar distance
quietly: gen `distance' = .


**************************************************
*** Identification of the initial basic subset ***
**************************************************

if `version'==1 {		/* Version 1: initial subset selected based on Mahalanobis distances */
	mata: mahalanobis("`varlist'","`touse'","`distance'")		 /* See file mahalanobis.do that creates mahalanobis.mo */
}
if `version'==2 {		/* Version 2: initial subset selected based on distances from the medians */
	mata: mediandist("`varlist'","`touse'","`distance'")		 /* See file mediandist.do that creates mediandist.mo */
}
sort `distance'
quietly: replace `out' = 1 if _n>`base' & !mi(`distance')


*************************
*** Identify outliers ***
*************************

local iter 0
local stop 0
while !`stop' {
	local ++iter
	tempvar base out0
	gen `base' = !`out'
	quietly: gen `out0' = `out'
	mata: mahalanobis("`varlist'","`touse'","`distance'","`base'")

	local h = (`nobs'+`nvar'+1)/2
	quietly: count if !`out'
	local r = r(N)
	local corr = 1 + (`nvar'+1)/(`nobs'-`nvar') + 1/(`nobs'-`h'-`nvar') + max(0,(`h'-`r')/(`h'+`r'))
	local chi2 = invchi2(`nvar',1-`percentile')
	local corrchi2 = `corr' * `chi2'
	quietly: replace `out' = 0 if `distance' < `corrchi2'

	mata: st_view(X0=.,.,"`out0'")
	mata: st_view(X1=.,.,"`out'")
	mata: st_numscalar("stop1", allof(X1==X0,1))
	local stop stop1
}
scalar drop stop1


**************************
*** Create variable(s) ***
**************************

rename `out' `marker'

if `"`Dvar'"'!="" {
	quietly: gen `Dvar' = `distance'
	la var `Dvar' `"Distance from basic subset"'
}


**************************
*** Print some results ***
**************************

di _n(1) as txt "Total number of observations:" _col (30) as res %12.0g `nobs'
quietly: count if `marker' & `touse'
di as txt _col(4) "BACON outliers (p = " %03.2f `percentile' "):" _col (30) as res %12.0g `r(N)'
quietly: count if !`marker' & `touse'
di as txt _col(7) "Non-outliers remaining:" _col (30) as res %12.0g `r(N)'

return scalar chi2 = `chi2'
return scalar corr = `corr'
return scalar iter = `iter'
quietly: count if `marker' & `touse'
return scalar outlier = `r(N)'

end
