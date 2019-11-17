*! version 1.08 05apr2011
* Estimates linear regression model with two high dimensional fixed effects 
/*---------------------------------------------------------*/
/* Guimaraes & Portugal Algorithm */
/* Author: Paulo Guimaraes */
/*---------------------------------------------------------*/
*
* To do:
* 
* Permitir descascar apenas variaveis (option noregress)
* Permitir acrescentar vars a um dataset (guardar dados com unique id por observ)
* Mudar todas vars para double
*
program reg2hdfe, eclass
version 9.1
if replay() {
    if ("`e(cmd)'"!="reg2hdfe") error 301
    Display `0'
}
else Estimate `0'
end

program define Estimate, eclass
syntax namelist [if] [in], id1(str) id2(str)  ///
[TOLerance(str) MAXiter(integer 0) ///
CHECK NODOTS simple fe1(str) fe2(str) cluster(str) GROUPid(str)  ///
INdata(string) OUTdata(string) IMProve(str) VERBose]

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
if `"`groupid'"'!=`""' confirm new var `groupid'

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
    markout __touse `lhs' `rhs' `id1' `id2' `clustervar'
}
else {
    markout __touse `lhs' `rhs' `id1' `id2'
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
    keep __uid `id1' `id2' `lhs' `rhs' `clustervar' 
}
else {
    keep __uid `id1' `id2' `lhs' `rhs' 
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
    keep __uid `id1' `id2'
    order __uid `id1' `id2'
    if "`verbose'"!="" {
        di in yellow "Saving fixed effects variables... "
    }
    qui save `outdata'_ids
    restore
        if "`cluster'"!="" {
            if "`verbose'"!="" {
                di in yellow "Saving cluster variable... "
            }
            preserve
            keep __uid `clustervar'
            rename `clustervar' __clustervar
            qui save `outdata'_clustervar
            restore
        }        
    }
    
di in ye "Tolerance Level for Iterations: `tolerance' "
tempvar start2
tempname dum1
gen double `start2'=0
foreach var of varlist `namelist' {
        di
        di in ye "Transforming variable: `var' " 
        gen double __o_`var' = `var'
        iteralg "`var'" "`id1'" "`id2'" "`start2'" "`tolerance'" "`maxiter'" "`simple'" "`verbose'" "`dots'" "`dum1'"
        outvars "__o_`var'" "`var'" "`dum1'" "`id1'" "`outdata'" "`check'"
        drop __o_`var'
    drop `dum1'
    }
    drop `start2'
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
            noisily di in yellow "The clustering variable is the one used when the data was created!!! "
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
        * Now read the original variables
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
            drop __fe2*
            drop __t_*
            sort __uid
*           qui save `tmp2', replace
            qui save tmp2, replace
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
            drop __fe2*
            drop __o_*
            sort __uid
*            qui save `tmp3', replace
            qui save tmp3, replace
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
    tempvar varfe2
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
        rename __t_`lhs' `lhs'
        }
        * Now we try to improve convergence
        di in ye "Improving Convergence for Variable: `lhs'" 
        di in red "Improve may not work if fixed effects are not specified in the same order as saved"
        iteralg "`lhs'" "`id1'" "`id2'" "__fe2_`lhs'" "`tolerance'" "`maxiter'" "`simple'" "`verbose'" "`dots'" "`varfe2'"
        outvars "__o_`lhs'" "`lhs'" "`varfe2'" "`id1'" "`improve'" "check"
clear
}

*******************
if "`verbose'"!="" {        
            di "Calculating degrees of freedom ... "
}
*******************

if "`improve'"=="" {
// Calculate Degrees of Freedom	
qui count
local N = r(N)
local k : word count `rhs'
sort `id1'
qui count if `id1'!=`id1'[_n-1]
local G1 = r(N)
sort `id2'
qui count if `id2'!=`id2'[_n-1]
local G2 = r(N)
tempvar group
qui __makegps, id1(`id1') id2(`id2') groupid(`group')
sort `group'
qui count if `group'!=`group'[_n-1]
local M = r(N)
local kk = `k' + `G1' + `G2' - `M'
local dof = `N' - `kk'	

* Estimate the model
if "`verbose'"!="" {        
            di "Estimating Regression ... "
}


tempname name1 name2
if "`cluster'"=="" {
    di
	// Estimate Regression		
	qui _regress `lhs' `rhs', nocons dof(`dof')
    estimates store `name2'
    local r=1-e(rss)/`tss'
    ereturn scalar df_m = `kk'-1
    ereturn scalar mss=`tss'-e(rss)
    ereturn scalar r2=`r'
    ereturn scalar r2_a=1-(e(rss)/e(df_r))/(`tss'/(e(N)-1))
    ereturn scalar F=(`r'/(1-`r'))*(e(df_r)/(`kk'-1))
    ereturn local cmdline "reg2hdfe `0'"
    ereturn local cmd "reg2hdfe"
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
    ereturn scalar Mgroups = `M'
    ereturn post `b' `V', depname(`lhs') obs(`nobs') dof(`kk')
    ereturn local eclustvar "`cluster'"
    ereturn local vce "cluster"
    ereturn local vcetype "Robust"
    ereturn local cmdline "reg2hdfe `0'"
    ereturn local depvar "y"
    ereturn local cmd "reg2hdfe"
    ereturn scalar N_clust=`Nclust'
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

if `"`fe1'"'!=`""' & `"`fe2'"'!=`""' { 
	di in ye "Calculating Fixed Effects"
    tempvar dum1 dum2 dum3
    estimates restore `name2'
	qui predict `dum1', res
    qui gen double `dum2'=`dum1'     
    *di in ye "Tolerance Level for Iterations: `tolerance'"
	local dots `=cond("`nodots'"=="",1,0)'
    tempvar start2
    gen double `start2'=0
    iteralg "`dum1'" "`id1'" "`id2'" "`start2'" "`tolerance'" "`maxiter'" "`simple'" "`verbose'" "`dots'" "`dum3'"
    drop `start2'
    qui replace `dum2'=`dum2'-`dum3', nopromote 
    sort `id1' 
    qui by `id1': g double `fe1' = sum(`dum2')/_n
    qui by `id1': replace `fe1' = `fe1'[_N], nopromote
    rename `dum3' `fe2'		
    di in ye "Done!!! "
    Display `name1'
    local nodisp nodisp
    * Test Final Model 
    if "`check'"=="check" {
    qui _regress `lhs' `rhs' `fe1' `fe2' 
    di
    di in yellow "Checking if final model converged - Coefficients for fixed effects should equal 1"
    di in yellow "Coefficient for `id1' --> "_b[`fe1']
    di in yellow "Coefficient for `id2' --> "_b[`fe2']
    }
}
        
if `"`groupid'"'!=`""' {
    qui __makegps, id1(`id1') id2(`id2') groupid(`groupid')
    label var `groupid' "Unique identifier for mobility groups"
}


if "`indata'"=="" {
tempfile addvars
qui describe
if r(k)> 1 {
keep __uid `fe1' `fe2' `groupid'
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
_coef_table_header, title( ********** Linear Regression with 2 High-Dimensional Fixed Effects ********** )
_coef_table
end

program define iteralg
args var id1 id2 start2 tolerance maxiter simple verbose dots jfe 
recast double `var'
tempvar temp fe2 dif1 dif0 old0 old1 mean
gen double `temp'=0
gen double `fe2'=`start2'
qui sum `fe2', meanonly
if r(min)!=r(max) {
qui replace `var' = `var' + `fe2', nopromote
}
gen double `old1'=0
gen double `old0'=0
local iter=1
local dif=1
local cond1 "(`fe2'>`old1'&`old1'>`old0'&((`fe2'+`old0')<(2*`old1')))"
local cond2 "(`fe2'<`old1'&`old1'<`old0'&((`fe2'+`old0')>(2*`old1')))"
capture drop `mean'
sort `id1'
by `id1': g double `mean' = sum(`var')/_n
qui by `id1': replace `var' = `var' - `mean'[_N], nopromote	
while abs(`dif')>`tolerance' & `iter'!=`maxiter'{
    capture drop `mean'
    sort `id1'
	by `id1': g double `mean' = sum(`fe2')/_n
	qui by `id1': replace `mean' = `mean'[_N], nopromote				
    capture drop `old0'
    rename `old1' `old0'
    rename `fe2' `old1'
    sort `id2'
    by `id2': g double `fe2' = sum(`var'+`mean')/_n 
    qui by `id2': replace `fe2' = `fe2'[_N], nopromote
    if `iter'>3&"`simple'"=="" {								
        qui replace `fe2'=`fe2'+(`fe2'-`old1')^2/(`old1'-`old0') if `cond1'|`cond2', nopromote 
        }
    qui replace `temp'=sum(reldif(`fe2',`old1')), nopromote
	local dif=`temp'[_N]/_N
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
qui replace `var' = `var' - `fe2' + `mean', nopromote
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
if "`jfe'"!="" {
    gen double `jfe'=`fe2'
}	
end

program define outvars
args orig var fe2 id1 outdata check
if "`outdata'"!="" {
    preserve
    sort __uid
    keep __uid `orig' `var' `fe2' 
    rename `var' __t_`var'
    rename `fe2' __fe2_`var'
    qui save `outdata'_`var', replace
    di in yellow " `var' was saved "
    restore
}       
if "`check'"=="check" {
    tempvar fe1 dum2
    gen double `dum2'=`orig'-`fe2'
    sort `id1' 
	by `id1': g double `fe1' = sum(`dum2')/_n
	qui by `id1': replace `fe1' = `fe1'[_N], nopromote
    qui _regress `orig' `fe1' `fe2' 
    di in yellow "Checking if model converged - Coefficients for fixed effects should equal 1"
    di in yellow "Coefficient for id1 --> "_b[`fe1']
    di in yellow "Coefficient for id2 --> "_b[`fe2']
}
end


/* This routine is from Amine Quazad's a2reg program */
/* It establishes the connected groups in the data */

#delimit ;
*Find connected groups for normalization;
capture program drop __makegps;
program define __makegps;
 version 9.2;
 syntax [if] [in], id1(varname) id2(varname) groupid(name);

 marksample touse;
 markout `touse' `id1' `id2';
 confirm new variable `groupid';

sort `id1' `id2';
preserve;

   *Work with a subset of the data consisting of all id1-id2 combinations;
    keep if `touse';
    collapse (sum) `touse', by(`id1' `id2');
    sort `id1' `id2';
   *Start by assigning the first id1 value to group 1, then iterate to fill this out;
    tempvar group newgroup1 newgroup2;
    gen double `group'=`id1';
    local finished=0;
    local iter=1;
    while `finished'==0 {;
     	quietly {;
       bysort `id2': egen double `newgroup1'=min(`group');
       bysort `id1': egen double `newgroup2'=min(`newgroup1');
       qui count if `newgroup2'~=`group';
       local nchange=r(N);
       local finished=(`nchange'==0);
       replace `group'=`newgroup2';
       drop `newgroup1' `newgroup2';
       };
      di in yellow "On iteration `iter', changed `nchange' assignments";
      local iter=`iter'+1;
      };
    sort `group' `id1' `id2';
    tempvar nobs complement;
    by `group': egen double `nobs'=sum(`touse');
    replace `nobs'= -1*`nobs';
    egen double `groupid'=group(`nobs' `group');
    keep `id1' `id2' `groupid';
    sort `id1' `id2';
    tempfile gps;
    save `gps';

    restore;
    tempvar mrg2group;
    merge `id1' `id2' using `gps', uniqusing _merge(`mrg2group');
    assert `mrg2group'~=2;
    assert `groupid'<. if `mrg2group'==3;
    assert `groupid'==. if `mrg2group'==1;
    drop `mrg2group';
end;
#delimit  

