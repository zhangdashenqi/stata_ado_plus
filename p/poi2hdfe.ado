*! version 1.3
* Estimates Poisson regression with two fixed effects
* Author: Paulo Guimaraes
* Date: October 17, 2014
*
program poi2hdfe, eclass
version 12

if replay() {
    if ("`e(cmd)'"!="poi2hdfe") error 301
    Display
}
else Estimate `0'
end

program define Estimate, eclass
************************************************************************************
syntax varlist [if] [in],           ///
        ID1(varname)                ///
        ID2(varname)                ///
        [tol1(real 1.000e-09)       /// convergence criteria for coefficients
        tol2(real 1.000e-09)        /// convergence criteria for s.e.s
        exposure(varname)           /// exposure variable
        cluster(varname)            /// cluster variable
        fe1(str)                    /// fixed effect for id1
        fe2(str)                    /// fixed effect for id2
        MAXiter(integer 100)        /// Max # iterations for intermediate Poisson Regressions
        op0(integer 2)              /// convergence for betas
        op1(integer 2)              /// convergence for f1
        op2(integer 2)              /// convergence for f2
        ever0(integer 3)            /// accelerate betas every # iterations
        ever1(integer 3)            /// accelerate f1 every # iterations 
        ever2(integer 3)            /// accelerate f2 every # iterations
        ROBust                      /// robust s.e.s
        VERBose                     /// clustered s.e.s
        STARTval                    /// use "reghdfe" for starting values
        POISSON                     /// use poisson instead of glm for intermediary regressions
        SAMPLE(str)                 /// new variable to capture sample used in estimation
        ]

************************************************************
* COLLECT LIST OF VARIABLES
************************************************************
tokenize `varlist'
local lhs `1'
mac shift
local rhs `*'
unab rhs: `*'
*********************************************************************
* CHECK SYNTAX
*********************************************************************
if "`cluster'"!="" {
local vtype: type `cluster'
if substr("`vtype'",1,3)=="str" {
di in red "Error: Cluster variable must be numeric! "
error 198
}
}

if ("`fe1'"!=""&"`fe2'"=="")|("`fe2'"!=""&"`fe1'"=="") {
di in red "Error: You must specify both options fe1 and fe2"
error 198
}

if `"`fe1'"'!=`""' confirm new var `fe1' 
if `"`fe2'"'!=`""' confirm new var `fe2'
if `"`sample'"'!=`""' confirm new var `sample'

************************************************************
* TEMP VARS 
************************************************************
tempvar touse uid1 uid2 sumy1 sumy2 off temp xb ///
sumx order ffe1_0 ffe2_0  ffe1_1 ffe2_1 ffe1_2 ffe2_2 NN logy
tempname v1 b bb b0 b1 b2
************************************************************
* RESTRICT SAMPLE 
************************************************************
gen long `order'=_n
qui count
local BigN=r(N)
preserve
mark `touse' `if' `in'
markout `touse' `lhs' `rhs' `id1' `id2' `exposure' `cluster'
qui keep if `touse'

* Check fixed effects which have zero variation

qui gengroup `id1' `uid1'
qui gengroup `id2' `uid2'

qui gen `sumy1'=.
mata: fastsum("`lhs'","`sumy1'","`uid1'")

qui sum `sumy1', meanonly
if r(min)==0 {
di
di "Dropping `id1' groups for which `lhs' is always zeros"
qui drop if `sumy1'==0
}

qui gen `sumy2'=.
mata: fastsum("`lhs'","`sumy2'","`uid2'")
qui sum `sumy2', meanonly
if r(min)==0 {
di
di "Dropping `id2' groups for which `lhs' is always zeros"
qui drop if `sumy2'==0
}

local c1=1
local c2=2

while `c1'>0|`c2'>0 {
bys `uid1': gen long `NN'=_N
qui count if `NN'==1
local c1=r(N)
if `c1'>0 {
di
di "Dropping `c1' groups for `id1' with a single observation"
qui drop if `NN'==1
}
drop `NN'
bys `uid2': gen long `NN'=_N
qui count if `NN'==1
local c2=r(N)
if `c2'>0 {
di
di "Dropping `c2' groups for `id2' with a single observation"
qui drop if `NN'==1
}
drop `NN'
}
qui count
di
di "Total Number of observations used in the regression -> " r(N)

if r(N)<`BigN' {
drop `uid1' `uid2'
qui gengroup `id1' `uid1'
qui gengroup `id2' `uid2'
}

mata: fastsum("`lhs'","`sumy1'","`uid1'")
mata: fastsum("`lhs'","`sumy2'","`uid2'")

foreach var of varlist `rhs' {
qui sum `var'
qui gen double _s_`var'=(`var'-r(mean))/r(sd)
local srhs "`srhs' _s_`var'"
}

****************************************************************************
* MAIN
****************************************************************************

*****************
* Starting values
*****************

if "`startval'"!="" { 
qui gen double `logy'=log(`lhs'+0.000000000000001)
qui reghdfe `logy' `srhs', absorb(`ffe1_2'=`id1' `ffe2_2'=`id2')
matrix `b2'=e(b)
}
else {
qui gen double `ffe1_2'=0
qui gen double `ffe2_2'=0
matrix `b2'=J(1,`col'+2,0)
}

gen double `off'=0
gen double `temp'=0
gen double `ffe1_0'=0
gen double `ffe2_0'=0
gen double `ffe1_1'=0
gen double `ffe2_1'=0
local off1 "offset(`off')"
local ll1=0
local dif=1
local i=0
local col: word count `rhs'
matrix `b0'=J(1,`col'+2,0)
matrix `b1'=J(1,`col'+2,0)
di
di "Starting Estimation of coefficients"
while abs(`dif')>`tol1' {
quietly {
if "`poisson'"!="" {
poisson `lhs' `rhs' `ffe1_2' `ffe2_2', `off1' from(`b2', skip) nocons iterate(`maxiter')
}
else {
glm `lhs' `srhs' `ffe1_2' `ffe2_2', nocons family(poisson) `off1' from(`b2', skip) iterate(`maxiter')
}
if e(converged)==0 {
di in red "Intermediary regression did not converge"
di in red "You may want to increase the value of maxiter"
}
matrix `b0'=`b1'
matrix `b1'=`b2'
matrix `b2'=e(b)
local ll2=`ll1'
local ll1=e(ll)
capture drop `xb'
predict double `xb', xb
replace `temp'=exp(`xb'-_b[`ffe1_2']*`ffe1_2'), nopromote
cap gen `sumx'=.
mata: fastsum("`temp'","`sumx'","`uid1'")
replace `ffe1_0'=`ffe1_1'
replace `ffe1_1'=`ffe1_2'
replace `ffe1_2'=log(`sumy1'/`sumx'), nopromote
if ((mod(`i',`ever1')==0)&`i'>3) {
acceliter `ffe1_0' `ffe1_1' `ffe1_2' `op1'
}
replace `temp'=exp(`xb'-_b[`ffe2_2']*`ffe2_2'), nopromote
mata: fastsum("`temp'","`sumx'","`uid2'")
replace `ffe2_0'=`ffe1_1'
replace `ffe2_1'=`ffe1_2'
replace `ffe2_2'=log(`sumy2'/`sumx'), nopromote
if ((mod(`i',`ever2')==0)&`i'>3) {
acceliter `ffe2_0' `ffe2_1' `ffe2_2' `op2'
}
if "`exposure'"!="" {
replace `off'=log(`exposure'), nopromote
}
if ((mod(`i',`ever0')==0)&`i'>3) {
mata: accelbeta(`op0',"`b0'","`b1'","`b2'")
}
local dif=`ll2'-`ll1'
} // quietly
if "`verbose'"!="" {
di "Iteration # `i' : Dif --> `dif' "
}
local ++i
}
di
di "Done with estimation of coefficients"
*
if "`exposure'"!="" {
qui poisson `lhs' `rhs' `ffe1_2' `ffe2_2', `st' exposure(`exposure') iterate(`maxiter')
}
else {
qui poisson `lhs' `rhs' `ffe1_2' `ffe2_2', `st' iterate(`maxiter')
}
if e(converged)==0 {
di in red "Intermediary Poisson regression is not converging!"
di in red "You may want to increase the value of maxiter"
}
di
di "Coefficients converged after `i' iterations "
di
di "Now estimating standard errors:"
* Capture relevant estimation results
matrix `b'=e(b) 
matrix `bb'=`b'[1,1..colsof(`b')-3]
local ll=e(ll)
local ll0=e(ll_0)
capture drop `xb'
predict double `xb', xb
qui replace `temp'=sqrt(exp(`xb'))
drop _s_*
foreach var of varlist `rhs' {
gen double _s_`var'=`var'*`temp'
di
di "calculating s.e. of `var'"
expurg2ef _s_`var', id1(`uid1') id2(`uid2') lam(`temp') tol(`tol2') `verbose' 
drop _s_`var'
rename _res _r_`var'
}
qui _regress `lhs' _r_*, nocons
local s2=e(rmse)*e(rmse)
matrix `v1'=e(V)/`s2'
local N=e(N)
* Prepare estimation results
ereturn clear
if ("`robust'"!="")|("`cluster'"!="") {
qui replace `off'=(`lhs'-`temp'*`temp')/`temp'
}
if "`robust'"=="robust" {
_robust `off', v(`v1')
}
if "`cluster'"!="" {
_robust `off', v(`v1') cluster(`cluster')
}
matrix rownames `v1' = `rhs' 
matrix rownames `v1' = `lhs':
matrix colnames `v1' = `rhs'
matrix colnames `v1' = `lhs':
ereturn post `bb' `v1', depname(`lhs') obs(`N') 
ereturn scalar ll=`ll'
ereturn scalar ll_0=`ll0'
ereturn local cmdline "poi2hdfe `0'"
ereturn local cmd "poi2hdfe"
ereturn local crittype "log likelihood"
if "`exposure'"!="" {
ereturn local offset "ln(`exposure')"
}
if "`robust'"=="robust" {
ereturn local vcetype "Robust"
ereturn local vce "robust"
ereturn local crittype "log pseudolikelihood"
}
if "`cluster'"!="" {
ereturn local vcetype "Robust"
ereturn local vce "cluster"
ereturn local clustvar "`cluster'"
ereturn local crittype "log pseudolikelihood"
sort `cluster'
qui count if `cluster'!=`cluster'[_n-1]
ereturn scalar N_clust=r(N)
}
Display
if (`"`fe1'"'!=`""' & `"`fe2'"'!=`""')|("`sample'"!="") { 
tempfile fes
capture rename `ffe1_2' `fe1'
capture rename `ffe2_2' `fe2'
capture gen byte `sample'=1
keep `order' `fe1' `fe2' `sample'
sort `order'
qui save `fes', replace
restore
sort `order'
qui merge `order' using `fes'
capture replace `sample'=0 if `sample'==. 
sort `order'
drop _m 
}
drop `order' 
end

************************************************************************
* SUMVARBY 
************************************************************************
program define sumvarby
* var - variable to be summed
* id - by variable
* newvar (default returns summed variable)
args var id newvar
capture drop `newvar'
quietly {
sort `id'
capture drop `newvar'
by `id': g double `newvar' = sum(`var')
by `id': replace `newvar' = `newvar'[_N]
}
end

************************************************************************
* DISPLAY 
************************************************************************
program define Display
_coef_table_header, title( ******* Poisson Regression with Two High-Dimensional Fixed Effects ********** )
_coef_table, level(95)
end

************************************************************************
* EXPURG2EF 
************************************************************************
program define expurg2ef
    syntax varname,                 ///
        ID1(varname)                 ///
        ID2(varname)                 ///
        LAM(varname)                 ///
        [tol(real 0.00000001)         /// convergence criteria
        VERBose                       ///
        ]
gettoken lhs rhs: varlist
tempvar sumxy1 sumxy2 sumx21 sumx22 off1 off2 temp res1 res2
gen double `temp'=`lam'*`lam'
gen double `off1'=0
gen double `off2'=0
gen double `res1'=0
gen double `res2'=0
gen double `sumxy1'=0
gen double `sumxy2'=0
gen double `sumx21'=0
gen double `sumx22'=0
mata: fastsum("`temp'","`sumx21'","`id1'")
mata: fastsum("`temp'","`sumx22'","`id2'")
local dif=1
local i=0
while abs(`dif')>`tol' {
quietly {
qui replace `res1'=`lhs'-`off1'*`lam'-`off2'*`lam'
qui replace `lhs'=`lhs'-`off2'*`lam'
qui replace `temp'=`lhs'*`lam'
mata: fastsum("`temp'","`sumxy1'","`id1'")
qui replace `off1'=`sumxy1'/`sumx21'
qui replace `lhs'=`lhs'-`off1'*`lam'+`off2'*`lam'
qui replace `temp'=`lhs'*`lam'
mata: fastsum("`temp'","`sumxy2'","`id2'")
replace `off2'=`sumxy2'/`sumx22'
replace `lhs'=`lhs'+`off1'*`lam'
replace `res2'=`lhs'-`off1'*`lam'-`off2'*`lam'
replace `temp'=sum(reldif(`res2',`res1')), nopromote
local dif=`temp'[_N]/_N
local ++i
}
if "`verbose'"!="" {
di "Iteration # `i' : Dif --> `dif' "
}
}
gen double _res=`res2'
end

program define acceliter
* v0 - variable at t0
* v1 - variable at t1
* v2 - variable at t2
args v0 v1 v2 op2
tempvar dum
local c1 "(`v2'>`v1'&`v1'>`v0'&((`v2'+`v0')<(2*`v1')))"
local c2 "(`v2'<`v1'&`v1'<`v0'&((`v2'+`v0')>(2*`v1')))"
gen double `dum'=`v1'+((`v2'-`v1')*(`v1'-`v0')/(2*`v1'-`v0'-`v2'))*(1-[(`v2'-`v1')/(`v1'-`v0')]^`op2')
qui replace `v2'=`dum' if (`c1'|`c2')&(`dum'<.), nopromote
end

mata:
void function accelbeta(numeric scalar op2,string scalar mb0,string scalar mb1,string scalar mb2)
{
b0=st_matrix(mb0)
b1=st_matrix(mb1)
b2=st_matrix(mb2)
one=J(1,cols(b0),1)
c1=(b2:>b1):*(b1:>b0):*((b2+b0):<(2*b1))
c2=(b2:<b1):*(b1:<b0):*((b2+b0):>(2*b1))
cond=(c1:>0)+(c2:>0)
dum1=editmissing(b1+(((b2-b1):*(b1-b0)):/(2*b1-b0-b2)):*(one-((b2-b1):/(b1-b0)):^op2),0)
b=dum1:*cond+(one-cond):*b2
st_replacematrix(mb2,b)
}
end

program define gengroup
args v1 v2
local vtype: type `v1'
sort `v1'
gen long `v2'=.
if substr("`vtype'",1,3)=="str" {
replace `v2'=1 in 1 if `v1'!="" 
replace `v2'=`v2'[_n-1]+(`v1'!=`v1'[_n-1]) if (`v1'!=""&_n>1)
}
else {
replace `v2'=1 in 1 if `v1'<. 
replace `v2'=`v2'[_n-1]+(`v1'!=`v1'[_n-1]) if (`v1'<.&_n>1)
}
end

mata:
mata set matastrict on
function fastmean(string scalar varname, string scalar meanvar, string scalar groupid)
{
	real colvector Var, Newvar, ID // Nx1
	real colvector Mean, Count // Gx1
	real scalar G, N, i, k
	st_view(Var=., ., varname)
	st_view(ID=., ., groupid)
	G = max(ID)
	N = rows(Var)
	Mean = J(G,1, 0)
	Count = J(G,1, 0)
	Newvar = J(N,1, .)
	assert(G<N)
	for (i=1; i<=N; i++) {
		k = ID[i]
		Count[k] = Count[k] + 1
		Mean[k] = Mean[k] + (Var[i])
	}
	Mean = Mean :/ Count
	for (i=1; i<=N; i++) {
		k = ID[i]
		Newvar[i] = Mean[k]
	}
	st_store(., meanvar, Newvar)
}
end

mata:
mata set matastrict on
function fastsum(string scalar varname, string scalar sumvar, string scalar groupid)
{
	real colvector Var, Newvar, ID
	real colvector Summ
	real scalar G, N, i, k
	st_view(Var=., ., varname)
	st_view(ID=., ., groupid)
	G = max(ID)
	N = rows(Var)
	Summ = J(G,1, 0)
	Newvar = J(N,1, .)
	assert(G<N)
	for (i=1; i<=N; i++) {
		k = ID[i]
		Summ[k] = Summ[k] + (Var[i])
	}
	for (i=1; i<=N; i++) {
		k = ID[i]
		Newvar[i] = Summ[k]
	}
	st_store(.,sumvar, Newvar)
}
end
