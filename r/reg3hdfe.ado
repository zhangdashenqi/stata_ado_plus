*! version 0.95 3may2010
* Estimates linear regression model with three high dimensional fixed effects 
/*---------------------------------------------------------*/
/* Guimaraes & Portugal Algorithm */
/* Author: Paulo Guimaraes */
/*---------------------------------------------------------*/
* NOTE: Preliminary version - Use at your own risk!
* Things to do:
* Need to implement reading data with two fixed effects - improve option        
* Degrees of Freedom may not always be correct
* Make sure saved cluster variable is same as regression cluster variable
* Add r2a with cluster option
* Any questions/problems please contact guimaraes@moore.sc.edu

program reg3hdfe, eclass
version 9.1
if replay() {
    if ("`e(cmd)'"!="reg3hdfe") error 301
    Display `0'
}
else Estimate `0'
end

program define Estimate, eclass
syntax namelist [if] [in], id1(str) id2(str) id3(str)  ///
[TOLerance(str) MAXiter(integer 0) REST(integer 0)  ///
CHECK NODOTS simple fe1(str) fe2(str) fe3(str) cluster(str) ///
INdata(string) OUTdata(string) IMProve(str) VERBose accel2 accel3]

*********************************************************************
* Checking syntax
*********************************************************************
tokenize `namelist'
local lhs `1'
mac shift
local rhs `*'

if "`indata'"!=""&"`outdata'"!="" {
		di in red "Error: Indata option not valid with outdata option"
		error 198
}

if "`indata'"!=""&"`improve'"!="" {
		di in red "Error: Indata option not valid with improve option"
		error 198
}
if "`outdata'"!=""&"`improve'"!="" {
		di in red "Error: Outdata option not valid with improve option"
		error 198
}
if "`improve'"!=""&"`rhs'"!="" {
		di in red "Error: Improve option can only be used with a single variable"
		error 198
}

if `"`fe1'"'!=`""' confirm new var `fe1' 
if `"`fe2'"'!=`""' confirm new var `fe2'
if `"`fe3'"'!=`""' confirm new var `fe3'

capture drop __uid

**********************************************************************
* Define Initial Variables
**********************************************************************
tempvar clustervar
di in ye "=============================================================="
if "`tolerance'"=="" local tolerance = epsfloat()
local dots `=cond("`nodots'"=="",1,0)'
***********************************************************************
* Do Main Loop
***********************************************************************
if "`indata'"==""&"`improve'"=="" {
    if "`rhs'"!="" {
        unab rhs: `rhs'
}	

************ Mark usable sample and store all data
mark __touse `if' `in'

if "`cluster'"!="" {
    gen double `clustervar'=`cluster'
    markout __touse `lhs' `rhs' `id1' `id2' `id3' `clustervar'    
}
else {
    markout __touse `lhs' `rhs' `id1' `id2' `id3'
}


tempfile origdata
if "`verbose'"!="" {
    di in yellow "Saving original file"
}

gen long __uid = _n
sort __uid
qui save `origdata'

* Restrict data to usable sample
qui keep if __touse

if "`cluster'"!="" {
keep __uid `id1' `id2' `id3' `lhs' `rhs' `clustervar' 
}
else {
keep __uid `id1' `id2' `id3' `lhs' `rhs'
}
*************************
sum `lhs', meanonly
tempvar yy sy
gen double `yy'=(`lhs'-r(mean))^2
gen double `sy'=sum(`yy')
local tss=`sy'[_N]
drop `yy' `sy'
***************************
if "`outdata'"!="" {
    preserve
    keep __uid `id1' `id2' `id3'
    order __uid `id1' `id2' `id3'
    if "`verbose'"!="" {
        di in yellow "Saving fixed effects variables"
    }    
    qui save `outdata'_ids
    restore
        if "`cluster'"!="" {
            if "`verbose'"!="" {
                di in yellow "Saving cluster variable "
            }
            preserve
            keep __uid `clustervar'
            rename `clustervar' __clustervar
            qui save `outdata'_clustervar
            restore
        }        
    }
       
di in ye "Tolerance Level for Iterations: `tolerance'"
tempvar start2 start3
tempname dum1 dum2
gen double `start2'=0
gen double `start3'=0
foreach var of varlist `namelist' {
        di
        di in ye "Transforming variable: `var'" 
        gen __o_`var'=`var'
        iteralg "`var'" "`id1'" "`id2'" "`id3'" "`start2'" "`start3'" "`tolerance'" "`maxiter'" "`simple'" "`accel2'" "`accel3'" "`verbose'" "`dots'" "`dum1'" "`dum2'"
        outvars "__o_`var'" "`var'" "`dum1'" "`dum2'" "`id1'" "`outdata'" "`check'"
        drop __o_`var'
    drop `dum1'
    drop `dum2'
    }
    drop `start2'
    drop `start3'
}


if "`indata'"!="" {
    tempfile tmp1 tmp2 tmp3 readdata
    quietly {
        if "`verbose'"!="" {        
        noisily di "Reading `indata'_ids"
        }
        use `indata'_ids, clear
        sort __uid
        qui save `tmp1', replace
        if "`cluster'"!="" {
            noisily di in yellow "The clustering variable must be the same used with the outdata option!!! "
            if "`verbose'"!="" {        
            noisily di in yellow "Adding `indata'_clustervar"
            }
        merge __uid using `indata'_clustervar
        sum _merge, meanonly
        if r(min)<r(max) { 
            di "There was an error merging `indata'_ids with `indata'_clustervar "
            di "Data sets do not match"
            error 198
        }
        drop _merge
        sort __uid
        rename __clustervar `clustervar'
        qui save `tmp1', replace
        }
        * Now read the other variables
    foreach var in `namelist' {
        if "`verbose'"!="" {        
        noisily di "Adding original `indata'_`var'"
        }
        merge __uid using `indata'_`var'
        sum _merge, meanonly
        if r(min)<r(max) { 
            di "There was an error merging `indata'_ids with `indata'_`var' "
            di "Data sets do not match"
            error 198
        }
        drop _merge
        drop __fe*
        drop __t_*
        sort __uid
        qui save `tmp2', replace
        }
    foreach var in `lhs' `rhs' {
    rename __o_`var' `var'
    }
    sum `lhs', meanonly
    tempvar yy sy
    gen double `yy'=(`lhs'-r(mean))^2
    gen double `sy'=sum(`yy')
    local tss=`sy'[_N]
    drop `yy' `sy'
    qui save `readdata'
    use `tmp1', clear
    foreach var in `namelist' {
        if "`verbose'"!="" {        
        noisily di "Adding transformed `indata'_`var'"
        }
        merge __uid using `indata'_`var'
        sum _merge, meanonly
        if r(min)<r(max) { 
            di "There was an error merging `indata'_ids with `indata'_`var' "
            di "Data sets do not match"
            error 198
        }
        drop _merge
        drop __fe*
        drop __o_*
        sort __uid
        qui save `tmp3', replace
        }    
    foreach var in `lhs' `rhs' {
    rename __t_`var' `var'
    }
    if "`verbose'"!="" {
        noisily di "Done reading data"
    }
    }
}

if "`improve'"!="" {
    tempvar varfe2 varfe3
    tempfile tmp1 tmp2
    quietly {
        if "`verbose'"!="" {        
            noisily di "Reading `improve'_ids"
        }
        use `improve'_ids, clear
        sort __uid
        qui save `tmp1', replace
        merge __uid using `improve'_`lhs'
        sum _merge, meanonly
        if r(min)<r(max) { 
            di "There was an error merging `improve'_ids with `improve'_`lhs'"
            di "Data sets do not match"
            error 198
        }
        drop _merge
        gen double `lhs'=__o_`lhs'
        }
        * Now we try to improve convergence
        di in ye "Improving Convergence for Variable: `lhs'" 
        * case 2 - previous estimation of lhs was with 2 fixed effects
        * case 3 - previous estimation of lhs was with 2 fixed effects
        capture confirm numeric variable __fe3_
        if _rc {
            gen double __fe3_`lhs'=0
            }
        if "`switch'"=="" {
        iteralg "`lhs'" "`id1'" "`id2'" "`id3'" "__fe2_`lhs'" "__fe3_`lhs'" "`tolerance'" "`maxiter'" "`simple'" "`accel2'" "`accel3'" "`verbose'" "`dots'" "`varfe2'" "`varfe3'"
        outvars "__o_`lhs'" "`lhs'" "`varfe2'" "`varfe3'" "`id1'" "`improve'" "`check'"
        }
clear
}

*******************
if "`verbose'"!="" {        
            di "Calculating degrees of freedom ... "
}
*******************
if "`improve'"=="" {
* Calculate Degrees of Freedom
qui count
local N = r(N)
local k : word count `rhs'
sort `id1'
qui count if `id1'!=`id1'[_n-1]
local G1 = r(N)
sort `id2'
qui count if `id2'!=`id2'[_n-1]
local G2 = r(N)
sort `id3'
qui count if `id3'!=`id3'[_n-1]
local G3 = r(N)

if `rest'==0 {
if "`verbose'"!="" {
noisily group3hdfe `id1' `id2' `id3'
}
else {
qui group3hdfe `id1' `id2' `id3'
}
local M=r(rest)
}
else {
local M=`rest'
}
local kk = `k' + `G1' + `G2' + `G3' - `M'
local dof = `N' - `kk'	

if `dof'<1 {
    di in red "Error: Regression has no degrees of freedom"
    error 198
}

* Estimate the model
if "`verbose'"!="" {        
            di "Estimating Regression ... "
}
tempname name1 name2
if "`cluster'"=="" {
    di
	// Estimate Regression		
	qui _regress `lhs' `rhs' , nocons dof(`dof')
    estimates store `name2'
    local r=1-e(rss)/`tss'
    ereturn scalar df_m = `kk'-1
    ereturn scalar rest=`M'
    ereturn scalar mss=`tss'-e(rss)
    ereturn scalar r2=`r'
    ereturn scalar r2_a=1-(e(rss)/e(df_r))/(`tss'/(e(N)-1))
    ereturn scalar F=(`r'/(1-`r'))*(e(df_r)/(`kk'-1))
    ereturn local cmdline "reg3hdfe `0'"
    ereturn local cmd "reg3hdfe"
    ereturn local predict ""
    ereturn local estat_cmd ""
    estimates store `name1'
}
else {
    sort `clustervar'
    qui count if `clustervar'!=`clustervar'[_n-1]
    local Nclust = r(N)
    qui _regress `lhs' `rhs', nocons mse1
    estimates store `name2'
    tempname b V
    matrix `V'=e(V)
    matrix `b'=e(b)
    local rss=e(rss)
    local r=1-`rss'/`tss'
    local nobs=e(N)
    tempvar res
    predict double `res', residual
    _robust `res', v(`V') minus(`kk') cluster(`clustervar')
    ereturn post `b' `V', depname(`lhs') obs(`nobs') dof(`kk')
    ereturn local eclustvar "`cluster'"
    ereturn local vce "cluster"
    ereturn local vcetype "Robust"
    ereturn local cmdline "reg3hdfe `0'"
    ereturn local depvar "y"
    ereturn local cmd "reg3hdfe"
    ereturn scalar N_clust=`Nclust'
    ereturn scalar rest=`M'
    ereturn scalar r2=`r'
    ereturn scalar rss=`rss'
    ereturn scalar mss=`tss'-`rss'
    estimates store `name1'
    di
}

if "`verbose'"!="" {        
            di "Done with estimation ... "
}

if "`indata'"!="" {
use `readdata', clear
}
else {
use `origdata', clear
keep if __touse==1
drop __touse
}

* Compute Fixed Effects

if `"`fe1'"'!=`""' & `"`fe2'"'!=`""' & `"`fe3'"'!=`""' { 
	di in ye "Calculating Fixed Effects"
    tempvar dum1 dum2 dum3 dum4
    estimates restore `name2'
	qui predict `dum1', res
    qui gen double `dum2'=`dum1'     
    *di in ye "Tolerance Level for Iterations: `tolerance'"
	local dots `=cond("`nodots'"=="",1,0)'
    tempvar start2 start3
    gen `start2'=0
    gen `start3'=0
    iteralg "`dum1'" "`id1'" "`id2'" "`id3'" "`start2'" "`start3'" "`tolerance'" "`maxiter'" "`simple'" "`accel2'" "`accel3'" "`verbose'" "`dots'" "`dum3'" "`dum4'"
    drop `start2'
    drop `start3'
    qui replace `dum2'=`dum2'-`dum3'-`dum4', nopromote 
    sort `id1'
    qui by `id1': g double `fe1' = sum(`dum2')/_n
    qui by `id1': replace `fe1' = `fe1'[_N], nopromote
    rename `dum3' `fe2'
    rename `dum4' `fe3'
    di in ye "Done!!! "
    Display `name1'
    local nodisp nodisp
    * Test Final Model 
    if "`check'"=="check" {
    qui _regress `lhs' `rhs' `fe1' `fe2' `fe3' 
    di
    di in yellow "Checking if final model converged - Coefficients for fixed effects should equal 1"
    di in yellow "Coefficient for `id1' --> "_b[`fe1']
    di in yellow "Coefficient for `id2' --> "_b[`fe2']
    di in yellow "Coefficient for `id3' --> "_b[`fe3']
    }
}

if "`indata'"=="" {
tempfile addvars
qui describe
if r(k)> 1 {
keep __uid `fe1' `fe2' `fe3' `groupid'
sort __uid
qui save `addvars', replace 
use `origdata', clear
drop __touse
sort __uid
merge __uid using `addvars'
drop _merge
}
else {
use `origdata', clear
drop __touse
}
}
capture drop __uid
di

if "`nodisp'"!="nodisp" {
Display `name1'
}
}
end

program Display
args name
qui estimates restore `name'
_coef_table_header, title( ********** Linear Regression with 3 High-Dimensional Fixed Effects ********** )
_coef_table
end

program define iteralg
args var id1 id2 id3 start2 start3 tolerance maxiter simple accel2 accel3 verbose dots outfe2 outfe3 
recast double `var'
tempvar fe1 fe2 fe3 fe2l1 fe2l2 fe3l1 fe3l2 mean1 mean mfe2 mfe3 dum
*************************************************************
* Initialize variables
*************************************************************
gen double `dum'=0
gen double `fe2'=`start2'
gen double `fe3'=`start3'
gen double `mfe2'=0
gen double `mfe3'=0
if "`simple'"=="" {
gen double `fe2l1'=0
gen double `fe2l2'=0
gen double `fe3l1'=0
gen double `fe3l2'=0
}
*
* Initialize macros
local iter=1
local dif=1
local rss1=-1
local cond21 "(`fe2'>`fe2l1'&`fe2l1'>`fe2l2'&((`fe2'+`fe2l2')<(2*`fe2l1')))"
local cond22 "(`fe2'<`fe2l1'&`fe2l1'<`fe2l2'&((`fe2'+`fe2l2')>(2*`fe2l1')))"
local cond31 "(`fe3'>`fe3l1'&`fe3l1'>`fe3l2'&((`fe3'+`fe3l2')<(2*`fe3l1')))"
local cond32 "(`fe3'<`fe3l1'&`fe3l1'<`fe3l2'&((`fe3'+`fe3l2')>(2*`fe3l1')))"
sort `id1'
by `id1': g double `mean' = sum(`var')/_n
by `id1': gen double `mean1'=`mean'[_N]
qui by `id1': replace `var' = `var' - `mean1', nopromote
while abs(`dif')>`tolerance' & `iter'!=`maxiter' {
    capture drop `mean'
    sort `id1'
    by `id1': g double `mean' = sum(`fe2')/_n
    qui by `id1': replace `mean'=`mean'[_N], nopromote
    qui replace `mfe2'=`fe2'-`mean', nopromote
    capture drop `mean'
    by `id1': g double `mean' = sum(`fe3')/_n
    qui by `id1': replace `mean'=`mean'[_N], nopromote
    qui replace `mfe3'=`fe3'-`mean', nopromote
    capture drop `mean'
    qui _regress `var' `mfe2' `mfe3'
    local rss2=`rss1'
    local rss1=e(rss)
    local dif=`rss2'-`rss1'
    qui replace `dum'=`var'-_b[`mfe2']*`mfe2'-_b[`mfe3']*`mfe3'+_b[`mfe2']*`fe2', nopromote
    if "`simple'"=="" {
        capture drop `fe2l2'
        rename `fe2l1' `fe2l2'
        rename `fe2' `fe2l1'
    }
    else {
    drop `fe2'
    }
    sort `id2'
    by `id2': gen double `mean' = sum(`dum')/_n
    by `id2': gen double `fe2'=`mean'[_N]
    if `iter'>3&"`simple'"=="" {								
        qui replace `fe2'=`fe2'+(`fe2'-`fe2l1')^2/(`fe2l1'-`fe2l2') if `cond21'|`cond22', nopromote 
        }
    capture drop `mean'
********************************************************************
    if "`accel2'"!=""|"`accel3'"!="" {
    sort `id1'
    by `id1': g double `mean' = sum(`fe2')/_n
    qui by `id1': replace `mean'=`mean'[_N], nopromote
    qui replace `mfe2'=`fe2'-`mean', nopromote
    capture drop `mean'
    }
    if "`accel3'"!="" {
        qui _regress `var' `mfe2' `mfe3'
    }
    
********************************************************************
    qui replace `dum'=`var'-_b[`mfe3']*`mfe3'-_b[`mfe2']*`mfe2'+_b[`mfe3']*`fe3', nopromote

    if "`simple'"=="" {
    capture drop `fe3l2'
    rename `fe3l1' `fe3l2'
    rename `fe3' `fe3l1'
    }
    else {
    drop `fe3'
    }
    capture drop `mean'
    sort `id3'
    by `id3': gen double `mean' = sum(`dum')/_n
    by `id3': gen double `fe3'=`mean'[_N]
    if `iter'>3&"`simple'"=="" {								
        qui replace `fe3'=`fe3'+(`fe3'-`fe3l1')^2/(`fe3l1'-`fe3l2') if `cond31'|`cond32', nopromote 
        }
	if `dots' {
        if `iter'==1 {
        _dots 0, title(Iterations) reps(`maxiter')
        }
		_dots `iter' 0
    }
    if "`verbose'"!="" {
	   noisily di " `iter' - Dif --> " `dif'
    } 
    local iter=`iter'+1
}
if `iter'==`maxiter' {
    di
    di in red "Maximum number of iterations reached"
    di in red "Algorithm did not converge for variable `var'"
    di in red "Last improvement: `dif'"
}			
else {			
    di
    di in yellow "Variable `var' converged after `iter' Iterations"
}

if "`outfe2'"!="" {
    gen double `outfe2'=`fe2'
}
if "`outfe3'"!="" {
    gen double `outfe3'=`fe3'
}
qui replace `var'=`var'+`mean1'-`fe2'-`fe3', nopromote
sort `id1'
qui by `id1': g double `fe1' = sum(`var')/_n
qui by `id1': replace `fe1' = `fe1'[_N]
qui replace `var'=`var'-`fe1', nopromote
end

program define outvars
args orig var fe2 fe3 id1 outdata check
if "`outdata'"!="" {
    preserve
    sort __uid
    keep __uid `orig' `var' `fe2' `fe3' 
    rename `var' __t_`var'
    rename `fe2' __fe2_`var'
    rename `fe3' __fe3_`var'
    qui save `outdata'_`var', replace
    di in yellow " `var' was saved "
    restore
}       
if "`check'"=="check" {
    tempvar fe1 dum2
    gen double `dum2'=`orig'-`fe2'-`fe3'
    sort `id1'
	by `id1': g double `fe1' = sum(`dum2')/_n
	qui by `touse' `id1': replace `fe1' = `fe1'[_N], nopromote
    qui _regress `orig' `fe1' `fe2' `fe3', nocons 
    di in yellow "Checking if model converged - Coefficients for fixed effects should equal 1"
    di in yellow "Coefficient for id1 --> "_b[`fe1']
    di in yellow "Coefficient for id2 --> "_b[`fe2']
    di in yellow "Coefficient for id3 --> "_b[`fe3']
}
end

*********************************************
* Routine to compute degrees of freedom
*********************************************
program define group3hdfe, rclass
args ggi ggj ggk
* Need to make sure that gi gj gk are groups
tempvar gi gj gk ij ik jk Nij Nik Njk
preserve
egen long `gi'=group(`ggi')
egen long `gj'=group(`ggj')
egen long `gk'=group(`ggk')
contract `gi' `gj' `gk'
drop _freq
* Counting restrictions
local rest=0
count_rows `gi' `gj' `gk'
local stop=r(itsover)
local case=r(case)

* begin{Major_Loop}
while `stop'==0 {

* begin{Are there any ones?}  nmiss==2

if `case'==1 {

*di "case 1 - i"
qui docase1 `gi'
*di "case 1 - j"
qui docase1 `gj'
*di "case 1 - k"
qui docase1 `gk'

}

* end{Are there any ones?}

* Are there any twos?

if `case'==2 {
*di "doing Case 2"
quietly {
gen_N_case2 i j `gi' `gj'
local maxNij=r(maxN12)
local maxNji=r(maxN21)
gen_N_case2 i k `gi' `gk'
local maxNik=r(maxN12)
local maxNki=r(maxN21)
gen_N_case2 j k `gj' `gk'
local maxNjk=r(maxN12)
local maxNkj=r(maxN21)

local maxNii=max(`maxNij',`maxNik')
local maxNjj=max(`maxNji',`maxNjk')
local maxNkk=max(`maxNki',`maxNkj')

local var1 i

if `maxNjj'>`maxNii' {
local var1 j
}

if `maxNkk'>`maxNjj'{
local var1 k
}


if "`var1'"=="i" {
local var2 j
if `maxNik'>`maxNij' {
local var2 k
}
}

if "`var1'"=="j" {
local var2 i
if `maxNjk'>`maxNji' {
local var2 k
}
}

if "`var1'"=="k" {
local var2 i
if `maxNkj'>`maxNki' {
local var2 j
}
}

sum `g`var1'' if N`var1'`var2'==`maxN`var1'`var2'', meanonly
local vali=r(max)
replace `g`var1''=. if `g`var1''==`vali' 
*noisily di "Restriction `g`var1'' --> `vali'"
}
local rest=`rest'+1
di "Restrictions are --> " `rest'

drop Nij Nik Nji Njk Nki Nkj

}

* begin{Are there any threes?}

if `case'==3 {
*di "doing Case 3"
quietly {
egen long `ij'=group(`gi' `gj') if nmiss==0
egen long `ik'=group(`gi' `gk') if nmiss==0
egen long `jk'=group(`gj' `gk') if nmiss==0
bys `ij': gen `Nij'=_N
sum `Nij', meanonly
local maxNij=r(max)
bys `ik': gen `Nik'=_N
sum `Nik', meanonly
local maxNik=r(max)
bys `jk': gen `Njk'=_N
sum `Njk', meanonly
local maxNjk=r(max)
local var ij
if `maxNik'>max(`maxNij',`maxNjk') {
local var ik
}
if `maxNjk'>max(`maxNij',`maxNik') {
local var jk
}

if "`var'"=="ij" {
sum `ij' if `Nij'==`maxNij', meanonly
local maxij=r(max)
sum `gi' if (`ij'==`maxij')&(`Nij'==`maxNij'), meanonly
local vali=r(mean)
replace `gi'=. if `gi'==`vali' 
*noisily di "Restriction `gi' --> `vali'"
sum `gj' if (`ij'==`maxij')&(`Nij'==`maxNij'), meanonly
local valj=r(mean)
replace `gj'=. if `gj'==`valj' 
*noisily di "Restriction `gj' --> `valj'"
}

if "`var'"=="ik" {
sum `ik' if `Nik'==`maxNik', meanonly
local maxik=r(max)
sum `gi' if (`ik'==`maxik')&(`Nik'==`maxNik'), meanonly
local vali=r(mean)
replace `gi'=. if `gi'==`vali'
*noisily di "Restriction `gi' --> `vali'" 
sum `gk' if (`ik'==`maxik')&(`Nik'==`maxNik'), meanonly
local valk=r(mean)
replace `gk'=. if `gk'==`valk' 
*noisily di "Restriction `gk' --> `valk'"
}

if "`var'"=="jk" {
sum `jk' if `Njk'==`maxNjk', meanonly
local maxjk=r(max)
sum `gj' if (`jk'==`maxjk')&(`Njk'==`maxNjk'), meanonly
local valj=r(mean)
replace `gj'=. if `gj'==`valj' 
*noisily di "Restriction `gj' --> `valj'"
sum `gk' if (`jk'==`maxjk')&(`Njk'==`maxNjk'), meanonly
local valk=r(mean)
replace `gk'=. if `gk'==`valk' 
*noisily di "Restriction `gk' --> `valk'"
}

drop `ij' `ik' `jk'
drop `Nij' `Nik' `Njk'
}
local rest=`rest'+2
di "Restrictions are --> " `rest'
}

* end{Are there any threes?}

count_rows `gi' `gj' `gk'
local stop=r(itsover)
local case=r(case)

} /*Main loop */ 

return scalar rest=`rest'
restore
end

program define count_rows, rclass
args i j k
quietly {
capture drop nmiss
tempvar dum1
gen nmiss=missing(`i')+missing(`j')+missing(`k')
sum nmiss, meanonly
noisily di "Cases to work --> " r(N)
return scalar itsover=(r(max)==3)*(r(min)==3)
drop if nmiss==3
local case=3
count if nmiss==2
local Ncase1=r(N)
count if nmiss==1
local Ncase2=r(N)
}
if (`Ncase1'==0)&(`Ncase2'>0) {
local case=2
}
if `Ncase1'>0 {
local case=1
}
return scalar case=`case'
end

program define gen_N_case2, rclass
args v1 v2 g1 g2
tempvar var1 var2 dum nn NN N12 N21
gen `var1'=`g1' if nmiss==1&`g1'<.&`g2'<.
gen `var2'=`g2' if nmiss==1&`g1'<.&`g2'<.
sort `var1' `var2'
by `var1': gen `nn'=_n if `var1'<.
gen `dum'=1 if `nn'==1
by `var1': replace `dum'=`dum'[_n-1]+(`var2'>`var2'[_n-1]) if `nn'>1
egen N`v1'`v2'=max(`dum'), by(`var1')
sum N`v1'`v2', meanonly
if r(N)>0 {
local maxN12=r(max)
}
else {
local maxN12=0
}
drop `nn' `dum'
sort `var2' `var1'
by `var2': gen `nn'=_n if `var1'<.
gen `dum'=1 if `nn'==1
by `var2': replace `dum'=`dum'[_n-1]+(`var1'>`var1'[_n-1]) if `nn'>1
egen N`v2'`v1'=max(`dum'), by(`var2')
sum N`v2'`v1', meanonly
if r(N)>0 {
local maxN21=r(max)
}
else {
local maxN21=0
}
return scalar maxN12=`maxN12'
return scalar maxN21=`maxN21'
end

program define docase1
args var
tempvar dum1 dum2
tempfile lixo
gen `dum1'=`var' if nmiss==2
qui sum `dum1', meanonly
if r(N)>0 {
bys `dum1': gen `dum2'=_n
replace `dum1'=. if `dum2'!=1
sort `dum1'
if r(N)>1 {
preserve
keep `dum1'
drop if `dum1'==.
rename `dum1' `var'
save `lixo', replace
restore
sort `var'
merge `var' using `lixo'
replace `var'=. if _merge==3
drop _merge
}
else {
local i=1
local val=`dum1'[`i']
while `val'<. {
replace `var'=. if `var'==`val'
local i=`i'+1
local val=`dum1'[`i']
}
}
}
end

