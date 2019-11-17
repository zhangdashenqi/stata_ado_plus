*! version 1.0.1 Carlo V. Fiorio, 11 Feb. 2004
** PURPOSE: kernel density + 
** 1 computes the variance of fixed-bandwidth kernel density estimation 
** 2 allows undersmoothing for CI calculation as in Horowitz 1999
** 3 allows choice of different bandkwidth (silverman/hardle/scott)




program define vkdensity
    version 7.0
    syntax varlist(min==1 max==1) [if] [in] [fw aw] [, N(integer 50) /*
        */ EPan GAUss SCott HArdle SIlver MBandw(real 0.0) /*
        */ USMooth(real .2) Generate(string) AT(string) NOGRaph]

tempvar pt f vf
local var `"`varlist'"'             /* local for target variable*/
local varl: variable label `var'    /* local for target variable label */
if `"`varl'"'==""{local varl "`var'" }

marksample use                      /* local for sample used */
qui count if `use'
local nuobs=r(N)
if r(N)==0 {
        dis in red "no obs defined"
        exit 2000
        }

local gen `"`generate'"'
tokenize `gen'
local wc: word count `gen'

    if `wc'==0 {
            noi disp in yellow `"No new variable generated"'
            local nsave = 0     
                }
    if `wc'==1 {
            if `"`at'"'==`""' {noi disp in red `"Number of var. generated incorrect"'
            exit 198    
                    }
    else {  
            noi disp in ye `"1 new var. generated: kdensity"'
            confirm new var `1'
            local fl `"`1'"'
            local ptl `"`at'"'
            local nsave = 1 
                    }
                }
    else if `wc'==2 {
        if `"`at'"'==`""' { 
            noi disp in ye "2 new var. generated: Points of estim. + kdensity"
            confirm new var `1'
            confirm new var `2'
            local ptl `"`1'"'
            local fl `"`2'"'
            local nsave = 2 
                }
        else { 
            confirm new var `1'
            confirm new var `2'
            local ptl `"`at'"'
            local fl `"`1'"'
            local vfl `"`2'"'
            local nsave = 2 
                }
            }
    else if `wc' == 3 {
        if `"`at'"'~=`""' { 
            noi disp in red `"too many vars generated given "at" command"'
            exit 198 
                }
        else {  
            noi disp in ye `"3 new var. gen.td: Points of estim. + kdensity + var. kdensity"'
            confirm new var `1'
            confirm new var `2'
            confirm new var `3'
            local ptl `"`1'"'
            local fl `"`2'"'
            local vfl `"`3'"'
            local nsave = 3 
                }
            }
    if `wc'>3 {
            disp in red `"you cannot specify more than 3 new vars"'
            exit 198
                }



*** SELECTION OF KERNEL FUNCTION
    local kflag = ( (`"`epan'"' != `""') + (`"`gauss'"' != `""') )
    if `kflag' > 1 {
        di in red `"only one kernel may be specified"'
        exit 198
        }

    if `"`gauss'"'  != `""' {
       local kernel=`"Gaussian"'
        }
    else { 
       local kernel=`"Epanechnikov"' 
        }

*** SELECTION OF THE BANDWIDTH COMMAND (taken from bandw2.ado)
qui summ `var' [`weight' `exp'] if `use', detail
local nuobs=r(N)
local sigma= sqrt(r(Var))
local iqr= r(p75)-r(p25)
local psigma= `iqr'/1.349

    tempname hhm
    scalar `hhm' = `mbandw'
        if `hhm'<=0.0 {
        if   ("`hardle'"~=""  )  {
            local h= 1.06*min(`sigma',`psigma')*`nuobs'^(-`usmooth')
            disp in ye " bandwidth choice (Hardle)= " `h'
                    }
        else if ("`scott'"~="" ) {
            local h=1.144*`sigma'*`nuobs'^(-`usmooth')
            disp in ye "bandwidth choice (Scott)= "  `h'
                    }
        else {
            local h= 0.9*min(`sigma',`psigma')*`nuobs'^(-`usmooth')   /* Silverman opt. bandwidth */
             disp in ye "bandwidth choice (Silverman)= "  `h'
                    }
            }
        else { 
            local h=`hhm'
            disp in ye "manual bandwidth choice= "  `h'
                    }

** WEIGHTS
if "`weight'" ~="" {
    tempvar wei
    qui g double `wei' `exp' if `use'
    qui sum `wei', meanonly
    if "`weight'" == "aweight" { 
        qui replace `wei' = `wei'/r(mean)
    }
}
else { 
    local wei=1
    }


*** GENERATE N EQUIDISTANT POINTS ON WHICH COMPUTE THE KERNEL
qui g double  `pt'=.
if `"`at'"'~=`""' {
    confirm var `at'
    qui count if `at'~=.
    local npt = r(N)
    qui replace `pt'=`at'
}
else {
    if `"`n'"'~=`""' {
        if `n' <= 1 { 
            local n=50
        }
        if `n' > _N {
            set obs `n'
            local npt=`n'
            noi disp in red "Caution: #points > #obs. Dataset has been enlarged!"   
        }
    }   
    else { 
            local n=50
    }
qui summ `var' if `use', detail
qui scalar interv=(r(max)-r(min)+2*`h')/(`n'-1)   /* INTERVALS ARE N, POINTS ARE N+1 */
qui replace `pt'=r(min)-`h'+(_n-1)*interv in 1/`n'
local npt=`n'
}
label var `pt' "estimation points"

if "`at'"!="" & `n'!=50 {
    di in red "you cannot specify both the at() and n() options"
    exit 198
    }

** COMPUTE THE DENSITY, f
qui g double  `f'=.             /* density estimate vector */
local i=1
sort `pt'

tempvar t kappa1 kappa2
qui gen double `t'=.
qui gen double `kappa1'=.
qui gen double `kappa2'=.
while `i'<=`npt' {
    qui replace  `t'=(`pt'[`i']-`var')/(`h') if `use'
    if `"`gauss'"'~=`""'     {   
            qui replace `kappa1'=(`wei')*exp(-0.5*(`t'^2))/sqrt(_pi*2) if `use' 
    }
    else {   
            qui replace `kappa1'=0 if abs(`t')>=sqrt(5) & `use'
            qui replace `kappa1'=(`wei')*3*(1-(`t'^2)/5)/(4*sqrt(5)) if abs(`t')<sqrt(5) & `use' 
    }

    sum `kappa1' if `use', meanonly
    qui replace `f'=r(sum)/(r(N)*`h') in `i'
    local i=`i'+1
    *noi disp "." _c
}


*** COMPUTE THE VARIANCE OF THE DENSITY, fv
if (`wc' == 2 & `"`at'"'~=`""') |  (`wc'==3) {
    qui g double  `vf'=.                /* density estimate vector */
    local i=1
    noi disp in ye "Variance of kernel estimation. Please, be patient"
    sort `pt'

    while `i'<=`npt' {
        qui replace  `t'=(`pt'[`i']-`var')/(`h') if `use'
        if `"`gauss'"'~=`""'    {   
            qui replace `kappa2'=(`wei')*(exp(-0.5*(`t'^2))/sqrt(_pi*2))^2  if `use'
            }
        else {   
            qui replace `kappa2'=0 if abs(`t')>=sqrt(5) & `use'
            qui replace `kappa2'=(`wei')*(3*(1-(`t'^2)/5)/(4*sqrt(5)))^2 if abs(`t')<sqrt(5) & `use' 
            }
    sum `kappa2' if `use', meanonly
    qui replace `vf'=r(sum)/((r(N)*`h')^2) in `i'
    qui replace `vf'=`vf'-((`f'^2)/`nuobs') in `i'      /* sample variance of f_{n}(x) */
    local i=`i'+1
        }
    }



* SAVING RESULTS
if `nsave' == 0 { gr `f' `pt', c(l) s(.) sort
    }
if `nsave' == 1 {
    label var `f'  "density: `fl'"
    rename `f' `fl' 
    }
if `nsave' == 2 {
        if `"`at'"'==`""' {
            label var `pt'  `"points: `ptl'"'
            label var `f' `"density: `fl'"'
            rename `pt' `ptl'
            rename `f' `fl'
            }
        else {  
            label var `pt'  `"points: `ptl'"'
            label var `f'  `"density: `fl' "'
            label var `vf' `"variance of kernel den.: `vfl'"'
            rename `f' `fl'
            rename `vf' `vfl'
            }
    }

    

if `nsave' == 3 {
        label var `pt'  `"points: `ptl'"'
        label var `f'  `"density: `fl' "'
        label var `vf' `"variance of kernel den.: `vfl'"'
        rename `pt' `ptl'
        rename `f' `fl'
        rename `vf' `vfl'
    }
    
if `"`nograph'"'==`""' & `nsave'~=0 {
        gr `fl' `ptl', c(l) s(.) sort
        }

global S_1 = `"`kernel'"'
global S_2 = `n'
global S_3 = `h'


end
