*! version 1.0.3 Carlo V. Fiorio, 11 Feb. 2004                  (SJ4-2: st0000)
* PURPOSE: bootstrap confidence intervals for kernel density estimation
* For reason of calculation time it needs to save same variable on disk rather 
* than generate temporary variables.
* It requires the preliminary installation of ^vkdensity.ado^
* Works both with Stata 7 and Stata 8.


noi disp in yellow "Note: this program requires installation of vkdensity.ado!"
 
    program define bsciker
    version 7.0

if _caller()<8 {
    syntax varlist(min==1 max==1) [if] [in] [fw aw] /*
    */ [, Generate(string) noGRaph GR7 AT(string) USMooth(real .25) /*
    */ EPan GAUss SCott HArdle SIlver MBandw(real 0.0) /*
    */ BSrepl(integer 99) SEed(int 0) /*
    */ N(integer 50) BSPpts(integer 100) UP(real 97.5) LP(real 2.5) PERcent(real 95)]
}

else {
    version 8.0
    syntax varlist(min==1 max==1) [if] [in] [fw aw] ///
     [, Generate(string) noGRaph GR7 AT(string) USMooth(real .25) ///
     EPan GAUss SCott HArdle SIlver MBandw(real 0.0) ///
     BSrepl(integer 99) SEed(int 0) ///
     N(integer 50) BSPpts(integer 100) UP(real 97.5) LP(real 2.5) PERcent(real 95)  ///
     *  ///
     ]


    if `"`graph'"' != "" & `"`gr7'"'!="" {
    dis in red "You cannot select both "nograph" and "gr7" options"
        exit 2000
        }

    if `"`graph'"' != "" {
        _get_gropts , graphopts(`options')
        syntax varlist(min==1 max==1) [if] [in] [fw aw] ///
     [, Generate(string) noGRaph GR7 AT(string) USMooth(real .25) ///
     EPan GAUss SCott HArdle SIlver MBandw(real 0.0) ///
     BSrepl(integer 99) SEed(int 0) ///
     N(integer 50) BSPpts(integer 100) UP(real 97.5) LP(real 2.5) PERcent(real 95)]
      }

    _get_gropts , graphopts(`options')  ///
        getallowed(stopts NORMOPTS plot)
    local options `"`s(graphopts)'"'
    local normopts `"`s(normopts)'"'
    local stopts `"`s(stopts)'"'
    _check4gropts normopts, opt(`normopts')
    _check4gropts stopts, opt(`stopts')
    if `"`normopts'"' != "" {
        local normal normal
    }
   // end of addendum for version 8.0
}

local var `"`varlist'"'
local nrepl `"`bsrepl'"'
local npt `"`n'"'
local seed `"`seed'"'
local bsppt `"`bsppts'"'    /* percentage of points for BS estimate */
local up `"`up'"'
local lp `"`lp'"'

if `percent'~=95 {
    local perc `"`percent'"'
    local lp=(100-`perc')/2
    local up=`perc'+`lp'
}


local at `"`at'"'
noi displ in yellow "Lower percentile:`lp'%"
noi displ in yellow "Upper percentile:`up'%"

** LABEL VARIABLE
    local varl `"`varlist'"'
    tokenize `varl'
    local varc: word count `varl'

    local ix `"`varlist'"'
    local ixl: variable label `ix'
    if `"`ixl'"'=="" { 
        local ixl "`ix'"
    }

marksample use                      /* local for sample used */
qui count if `use'
local nuobs=r(N)
if r(N)==0 {
    dis in red "no obs defined"
    exit 2000
    }

** BANDWIDTH SELECTION for density

qui summ `var' [`weight' `exp'] if `use', detail
local nuobs=r(N)
local sigma= sqrt(r(Var))
local iqr= r(p75)-r(p25)
local psigma= `iqr'/1.349

    tempname hhm
    scalar `hhm' = `mbandw'
        if `hhm'<=0.0 {
            if   ("`hardle'"~=""  )  {
                local h= 1.06*min(`sigma',`psigma')*`nuobs'^(-0.2)
                disp in ye " Bandwidth choice (Hardle)= " %9.5f `h'
            }
            else if ("`scott'"~="" ) {
                local h=1.144*`sigma'*`nuobs'^(-0.2)
                disp in ye "bandwidth choice (Scott)= " %9.5f `h'
            }
            else {
                local h= 0.9*min(`sigma',`psigma')*`nuobs'^(-0.2)   /* Silverman opt. bandwidth */
                disp in ye "bandwidth choice (Silverman)= " %9.5f `h'
            }
        }
        else { 
            local h=`hhm'
            disp in ye "manual bandwidth choice= " %9.5f `h'
        }

** BANDWIDTH SELECTION for CI
qui summ `var' [`weight' `exp'] if `use', detail
local nuobs=r(N)
local sigma= sqrt(r(Var))
local iqr= r(p75)-r(p25)
local psigma= `iqr'/1.349

    tempname hhm
    scalar `hhm' = `mbandw'
        if `hhm'<=0.0 {
            if   ("`hardle'"~=""  )  {
                    local bh= 1.06*min(`sigma',`psigma')*`nuobs'^(-`usmooth')
                    disp in ye " (oversmoothed) bandwidth choice (Hardle)= " %9.5f `bh'
            }
            else if ("`scott'"~="" ) {
                    local bh=1.144*`sigma'*`nuobs'^(-`usmooth')
                    disp in ye "(oversmoothed) bandwidth choice (Scott)= " %9.5f `bh'
            }
            else {
                local bh= 0.9*min(`sigma',`psigma')*`nuobs'^(-`usmooth')   /* Silverman opt. bandwidth */
                disp in ye "(oversmoothed) bandwidth choice (Silverman)= " %9.5f `bh'
            }
        }
        else { 
            local bh=`hhm'
            disp in ye "manual bandwidth choice= " %9.5f `bh'
        }

** WEIGHTS
if "`weight'" ~="" {
            tempvar cwei
            qui g double `cwei' `exp' if `use'
            qui sum `cwei', meanonly 
            if "`weight'" == "aweight" {
                qui replace `cwei' = `cwei'/r(mean)
            }
            else if "`weight'" == "fweight" {
                qui replace `cwei' = `cwei'
            }

}
else { 
    tempvar cwei
    qui g `cwei'=1
}        

** GENERATE NEW VARIABLES
    local gen `"`generate'"'
    tokenize `gen'
    local wc: word count `gen'
        
    if `wc' == 2 {
            if "`at'" == "" {
                error 198
            }
            confirm new var `1'
            confirm new var `2'
            local cfl      `"`1'"'
            local boundl  `"`2'"'
            local cptl `"`at'"'
            local nsave 2       
    }
    else if `wc' == 3 {
            confirm new var `1'
            confirm new var `2'
            confirm new var `3'
            local cptl      "`1'"
            local cfl      "`2'"
            local boundl  "`3'"
            local nsave 3       
    }
    else if `wc' == 0 {
            noi displ "No new variable generated"
            local nsave 0
    }
    else {  
            noi displ in red "you specified either too few or to many new variables"
            error 198 
    }

** GENERATE DATASETS
tempfile origds dataset bsdatas
capt drop _merge
qui save `origds', replace
keep  `var' `cwei' `at'
qui save `dataset', replace

qui sum `var'
local nnobs=r(N)
if r(N)<_N {
    *display in red "Missing values are not considered and will be dropped"
    qui drop if `var'==.
}

** CREATE UNDERSMOOTHED KERNEL VARIANCE 
tempvar bpt bf bvf
if "`weight'" != "" {
        if "`at'"~="" {
        qui vkdensity `var' [`weight' = `cwei'], `gauss' mbandw(`bh') g(`bf' `bvf') at(`at') nograph 
            }
        else {
        qui vkdensity `var' [`weight' = `cwei'], `gauss' mbandw(`bh') g(`bpt' `bf' `bvf') n(`npt') nograph 
            }
        }
else    {
        if "`at'"~="" {
        qui vkdensity `var', `gauss' mbandw(`bh') g(`bf' `bvf') at(`at') nograph 
            }
        else {
        qui vkdensity `var' , `gauss' mbandw(`bh') g(`bpt' `bf' `bvf') n(`npt') nograph 
            }
       }

** CREATION OF KERNEL DENSITY + ITS VARIANCE USING
local gauss `"`gauss'"'

tempfile kdh pt
tempname cpt cf cvf cbspt
*noi disp "`weight'"
if "`weight'" != "" {
        if "`at'"~="" {
            qui vkdensity `var' [`weight' = `cwei'], `gauss' mbandw(`h') g(`cf' `cvf') at(`at') nograph 
        }
        else {
            qui vkdensity `var' [`weight' = `cwei'], `gauss' mbandw(`h') g(`cpt' `cf' `cvf') n(`npt') nograph 
        }
}
else    {
        if "`at'"~="" {
            qui vkdensity `var', `gauss' mbandw(`h') g(`cf' `cvf') at(`at') nograph 
        }
        else {
            qui vkdensity `var' , `gauss' mbandw(`h') g(`cpt' `cf' `cvf') n(`npt') nograph 
        }
}

tempvar pt
if "`at'" ~= "" {
    qui g double `pt'=`at'
    if `pt'[1]==`pt'[2] {
        replace `pt'=. in 2/`nuobs'
    }  
    sort `pt'
    qui save `kdh', replace
    
    qui g fden=`cf'
    qui g cpt=`pt'
}
else {
    sort `cpt'
    qui g double `pt'=`cpt'
    sort `pt'
    qui save `kdh', replace
    qui g fden=`cf'
    qui g cpt=`pt'
}

       
***** SELECT POINTS FOR BOOTSTRAP ESTIMATION
keep `pt'
sort `pt'
if `bsppt' ~= 100 {
    qui sum `pt', meanonly
    qui scalar j=r(N)-int(r(N)*(`bsppt'/100))      /* percentage of pt for bootstrap */
    noi disp "Number of estimation points = " r(N)
    noi disp "Number of estimation points used for BS CI = " `bsppt' "%"
    qui g double `bspt'=.
    local i=1
    while `i'<=r(N) { 
        qui replace `bspt'=`pt' in `i'
        local i=`i'+j
    }   
    qui drop `pt'
}
else {
    tempvar bspt
    qui g double `bspt'=`pt'
    qui drop `pt'
}

qui g pt=`bspt'

sort `bspt'
qui save `pt',replace

**************************************************************
********** generate bootstrap samples
**************************************************************
if "`weight'" ~= "" {
    qui use `dataset', clear
    qui keep `var' `cwei'
    qui sum `cwei'
    qui replace `cwei'=`cwei'/r(min)  /* renormalize weight so that the smallest value is 1 */
    tempvar pwint
    qui gen `pwint'=round(`cwei',1)  /* make a rounded-to-integer version of `pw' */
    qui expand `pwint'              /* expand dataset using `pwint'*/
    qui save `bsdatas', replace
}
else {
    qui use `dataset', clear
    qui save `bsdatas', replace
}

noi disp in ye "Bootstrap samples are being generated"

if `seed' ~= 0 {
    noi disp "User set seed at "`seed'
    set seed `seed'      /* set seed for reproducibility */
}

tempname pino gino

local i=1
while `i'<=`nrepl' {
    qui use `bsdatas', clear
    qui keep `var'
    qui drop if `var'==.
    bsample `nnobs'
    rename `var' `pino'`i'
    capt drop _merge
    merge using `pt'.dta
    drop _merge
    qui save "`pino'`i'.dta",replace
    noi disp in bl  "." _c
    local i=`i' +1
}
noi disp " "

** CREATE KERNEL DENSITY + ITS VARIANCE ON BOOTSTRAP SAMPLES 
sort `bspt'
noi disp in ye "vkdensity on bootstrap samples being computed: be patient, please"
local i=1
while `i'<=`nrepl' {
    qui use "`pino'`i'.dta", clear
    qui vkdensity (`pino'`i'), `gauss' mb(`bh')  g(bf`i' bvf`i') at(`bspt') nograph 
    sort `bspt'
    qui save `gino'`i', replace
    erase `pino'`i'.dta
    local i=`i'+1 
    noi disp in bl "." _c 
}
noi disp " "

** MERGE ALL KERNEL DENSITIES ON BOOTSTRAPPED SAMPLES
noi disp in ye "Merging all vkdensity on bootstrapped samples" 
local j=1
local i=2

qui use `gino'`j'.dta, clear
while `i'<=`nrepl' {
    capt drop _merge
    merge `bspt' using `gino'`i'
    qui drop _merge
    sort `bspt'
    qui save `gino'`j'.dta, replace
    erase "`gino'`i'.dta"
    noi disp in bl "." _c
    local i=`i'+1
    }
capt erase "`gino'.dta"
capt erase "`gino'1.dta"
capt erase "`pt'.dta"
   
noi disp " "
capture drop _merge
rename `bspt' `pt'
sort `pt'
merge `pt' using `kdh'

capt drop _merge

qui drop if `pt'[_n]==. & _n>`nrepl'
sort `pt'
qui save "`gino'.dta", replace

*********** generate statistic tstar

tempfile ts tts
noi disp in ye "Generating statistic tstar"
local i=1
while `i'<=`nrepl' {
    qui gen double ts`i'=((bf`i')-`bf')/sqrt(bvf`i')   /* statistic tstar */
    qui drop bf`i' bvf`i' `pino'`i'
    local i=`i'+1
}
sort `pt'
qui save `ts', replace

** TRANSPOSE MATRIX FOR CRITICAL VALUES TO BE USED IN CI
qui drop if _n>`npt'
qui xpose, clear 
qui save `tts', replace

** COMPUTE CRITICAL VALUES
tempvar cup clp
noi disp in ye "Computing percentiles for cstar"
if `nrepl'> _N {
    set obs `nrepl'
}
if `npt'> _N {
    set obs `npt'
}
qui gen double `cup'=.
qui gen double `clp'=.
qui gen nord=_n

local i=1
while `i'<=`npt' & `i'<=_N {
    if v`i'[1] ~= . {
        _pctile v`i' , percentiles(`lp',`up')   
        qui replace `clp'=r(r1)  in `i'
        qui replace `cup'=r(r2)  in `i'
        noi disp in bl "." _c
        local i=`i'+1
    }
    else {
        local i=`i'+1
    }
}

tempfile bsci
qui save `bsci', replace

** GENERATE CONFIDENCE INTERVALS
tempvar ub lb
capt drop _merge
merge using `ts'
qui drop _merge
sort `pt'
qui save `bsci', replace

/*
qui gen double `ub'=`bf'-`clp'*sqrt(`cvf')
qui gen double `lb'=`bf'-`cup'*sqrt(`cvf')
qui gen cf=`cf'
qui gen clp=`clp'
qui gen ub=`ub'
qui gen lb=`lb'

tempvar f 
qui gen double `f'=`cf'
*/

qui gen double `ub'=`bf'-`clp'*sqrt(`bvf')
qui gen double `lb'=`bf'-`cup'*sqrt(`bvf')
qui gen cf=`cf'
qui gen clp=`clp'
qui gen ub=`ub'
qui gen lb=`lb'

tempvar f 
qui gen double `f'=`cf'

capture drop _merge
merge `pt' using `kdh'
capture drop _merge
sort `pt'

label var `ub' "upper bound"
label var `lb' "lower bound"
label var `f' "density estimation"

keep `ub' `f' `lb' `pt' 
capt drop _merge
merge using `origds'
capt drop _merge


** RETAIN SAVED VARIABLES
    if `nsave' == 2 {
        label var `f' "density"
        label var `ub' "upper bnd"
        label var `lb' "lower bnd"                
        rename `f' `cfl'
        rename `ub' `boundl'_u
        rename `lb' `boundl'_l
    }
    else if `nsave' == 3 {
        label var `f' "density"
        label var `ub' "upper bound"
        label var `lb' "lower bound"                
        rename `pt' `cptl'        
        rename `f' `cfl'
        rename `ub' `boundl'_u
        rename `lb' `boundl'_l
    }
    else  {
        local cptl "points"
        local cfl "density"
        local boundl "bound"
        capt drop points density u_bound l_bound
        rename `pt' `cptl'        
        rename `f' `cfl'
        rename `ub' `boundl'_u
        rename `lb' `boundl'_l
    }

** CREATE GRAPHS
    if _caller() < 8 & `"`graph'"' == "" {
        if `"`symbol'"'  == `""' {
            local symbol `"o"'
        }
        if `"`connect'"' == `""' {
            local connect `"l"' 
        }
        if `"`title'"'   == `""' {
            local title `"Kernel Density Estimate"'
        }
        
        graph  `cfl' `boundl'_u `boundl'_l `cptl' , s(`symbol'ii) c(`connect'l[-]l[-]) /*
        */ title(`"`title'"') `options' sort
    }
    else if _caller() >=  8 & `"`gr7'"' ~= "" & `"`graph'"' == "" {
        if `"`symbol'"'  == `""' {
            local symbol `"o"'
        }
        if `"`connect'"' == `""' {
            local connect `"l"' 
        }
        if `"`title'"'   == `""' {
            local title `"Kernel Density Estimate"'
        }
        
        gr7  `cfl' `boundl'_u `boundl'_l `cptl' , s(`symbol'ii) c(`connect'l[-]l[-]) /*
        */ title(`"`title'"') `options' sort
    }

    else if `"`graph'"' == "" {
      version 8.0      
        graph twoway                    ///
        (line `cfl' `boundl'_u `boundl'_l `cptl',                  ///
            ytitle("")         ///
            xtitle(`"`ixl'"')           ///
            legend(cols(1))             ///
            `options'               ///
        )                 ///
        // blank
    }

global S_1 = `"`kernel'"'
global S_2 = `n'
global S_3 = `h'
global S_4 = `nrepl'
global S_5 = `npt'
global S_6 = `seed'
global S_7 = `bsppt'
global S_8 = `up'
global S_9 = `lp'

end
