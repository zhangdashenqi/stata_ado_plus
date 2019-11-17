*************************************************************************
* PROGRAM "ddid"
*************************************************************************
*! ddid v5 GCerulli 17oct2017
capture program drop ddid
program ddid, eclass sortpreserve
version 14
#delimit;     
syntax varlist [if] [in] [aweight fweight pweight] ,
model(string)
pre(numlist max=1 integer)
post(numlist max=1 integer)
[
vce(string)
save_graph(string)
graph
];
#delimit cr
********************************************************************************
marksample touse
tokenize `varlist'
local y `1'  // outcome
local D `2'  // treatment
macro shift
macro shift
local xvars `*'
********************************************************************************
* Labels
********************************************************************************
la var `D' "Binary treatment variable"
la var `y' "Outcome variable"
********************************************************************************
* Warning 1
********************************************************************************
qui count if `D'==1 & `touse'
local N1=r(N)
qui count if `touse'
local N=r(N)
qui sum `D' if `touse'
if r(mean)!=(`N1'/`N'){
di as text in red  ""
di as text in red  ""
di as text in red  "{hline}"
di as text in red  "{bf:******************************************************************************}"
di as text in red  "{bf:********* WARNING: The treatment variable must be binary 0/1 *****************}"
di as text in red  "{bf:******************************************************************************}"
exit
}
********************************************************************************
* Warning 2
********************************************************************************
if "`model'"==""{
break
di _newline(2)
di as result in red "********************************************************"
di as result in red "Warning: at least one of the following models must be   "
di as result in red "declared into the option 'model()': ct-ols, ct-iv"
di as result in red "********************************************************"
}
********************************************************************************
* Generation of lags and leads of the binary treatment 
********************************************************************************
local lag `post' 
local lead `pre'  
* 1. LAGS:
local lags
forvalues i=1/`lag'{
cap drop _D_L`i'
gen _D_L`i'=L`i'.`D'
local lags "`lags' _D_L`i'"
}
*sum `lags'
* 2. LEADS:
local leads
forvalues i=`lead'(-1)1{
cap drop _D_F`i'
gen _D_F`i'=F`i'.`D'
local leads "`leads' _D_F`i'" 
}
*sum `leads'
*di "`xvars'"
********************************************************************************
* Baseline regression - Overall sample (fixed effects)
******************************************************************************** 
else if "`model'"=="ols"{
reg `y' `leads' `D' `lags' `xvars' [`weight' `exp'] if `touse' , vce(`vce')  // ols
di "CIAO"
ereturn scalar ate=_b[`D']
qui count if `touse'
ereturn scalar N=r(N)
qui count if `D'==1 & `touse'
ereturn scalar N1=r(N)
qui count if `D'==0 & `touse'
ereturn scalar N0=r(N)
}
else if "`model'"=="fe"{
xtreg `y' `leads' `D' `lags' `xvars' [`weight' `exp'] if `touse' , vce(`vce') fe  // fixed effects
ereturn scalar ate=_b[`D']
qui count if `touse'
ereturn scalar N=r(N)
qui count if `D'==1 & `touse'
ereturn scalar N1=r(N)
qui count if `D'==0 & `touse'
ereturn scalar N0=r(N)
}
tempname B C
mat `B' = e(b)
mat `C' = `B''
local M=`lag'+`lead'+1
mat `C' =`C'[1..`M',1...]
*mat list `C'
cap drop `C'1
svmat `C'
tempvar id2
gen `id2'=_n
* Labels for lags
local sum_lags
forvalues i=1/`lag'{
local sum_lags `sum_lags' _D_L`i'=t+`i'
}
*di "`sum_lags'"
* Labels for leads
local sum_leads
forvalues i=`lead'(-1)1{
local sum_leads `sum_leads' _D_F`i' = t-`i'
}
local myD "`D'=t"
********************************************************************************
* TESTS
********************************************************************************
di as text ""
di as text ""
di as text "{hline}"
di as text "{bf:******************************************************************************}"
di as text "{bf:****************** Test for 'parallel trend' & 'balancing' *******************}"
di as text "{bf:******************************************************************************}"
test `leads'
if r(p)>=0.05{
di as text ""
di as result "RESULT: 'Parallel-trend' & 'Balancing' assumptions joinly passed"
}
else{
di as result "RESULT: 'Parallel-trend' & 'Balancing' assumptions joinly not passed"
}
di as text ""
di as text "{bf:******************************************************************************}"
di as text ""
di as text "{hline}"
di as text "{bf:******************************************************************************}"
di as text "{bf:****************** Test for 'parallel trend' *********************************}"
di as text "{bf:******************************************************************************}"
gettoken first leads2 : leads  
local leadstest "`first'"
foreach x of local leads2{
local leadstest "`leadstest'" "=`x'"
}
test "`leadstest'"
if r(p)>=0.05{
di as text ""
di as result "RESULT: 'Parallel-trend' assumption passed"
}
else{
di as result "RESULT: 'Parallel-trend' assumption not passed"
}
di as text ""
di as text "{bf:******************************************************************************}"
di as text ""
di as text "{hline}"
********************************************************************************
* GRAPH
********************************************************************************
if "`graph'"!="" & "`save_graph'"!=""{
coefplot . , vertical drop(_cons) yline(0) msymbol(d) mcolor(white) ///
title("" , size(medium))  ///
levels(99 95 90 80 70) ciopts(lwidth(3 ..) lcolor(*.2 *.4 *.6 *.8 *1)) addplot(line `C'1 `id2') keep(`leads' `D' `lags') ///
legend(order(1 "99" 2 "95" 3 "90" 4 "80" 5 "70") row(1)) ///
coeflabels(`sum_leads' `myD' `sum_lags')
graph save `save_graph' , replace
}
else if "`graph'"!="" & "`save_graph'"==""{
coefplot . , vertical drop(_cons) yline(0) msymbol(d) mcolor(white) ///
title("" , size(medium))  ///
levels(99 95 90 80 70) ciopts(lwidth(3 ..) lcolor(*.2 *.4 *.6 *.8 *1)) addplot(line `C'1 `id2') keep(`leads' `D' `lags') ///
legend(order(1 "99" 2 "95" 3 "90" 4 "80" 5 "70") row(1)) ///
coeflabels(`sum_leads' `myD' `sum_lags')
}
********************************************************************************
end
********************************************************************************
* END of "ddid"
********************************************************************************
