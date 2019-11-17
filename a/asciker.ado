*! version 1.0.2 Carlo V. Fiorio, 11 Feb. 2004                 (SJ4-2: st0064)
* PURPOSE: asymptotic confidence intervals for kernel density estimation
* It requires the preliminary installation of ^vkdensity.ado^
* Works both with Stata 7 and Stata 8.


noi disp in yellow "Note: this program requires installation of vkdensity.ado!"
 
    program define asciker
    version 7.0

if _caller()<8 {
    syntax varlist(min==1 max==1) [if] [in] [fw aw] /*
    */ [, Generate(string) noGRaph GR7 AT(string) USMooth(real .25) /*
    */ EPan GAUss SCott HArdle SIlver MBandw(real 0.0) /*
    */ N(integer 50) PERCent(real 5)]
    }

  else {
    version 8.0
        syntax varlist(min==1 max==1) [if] [in] [fw aw] ///
     [, Generate(string) noGRaph GR7 AT(string) USMooth(real .25) ///
     EPan GAUss SCott HArdle SIlver MBandw(real 0.0) ///
     N(integer 50) PERCent(real 5)  ///
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
     BSrepl(integer 99) SEed(int 123456789) ///
     N(integer 50) PERCent(real 5)]
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

version 7.0

local var `"`varlist'"'
local npt `"`n'"'
local seed `"`seed'"'
local perc `"`percent'"'
local at `"`at'"'
noi displ in yellow "significance level: `perc'%"

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
            disp in ye " bandwidth choice (Hardle)= " %9.5f `h'
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
        if "`weight'" == "aweight" {replace `cwei' = `cwei'/r(mean)}
        }

else {  
    tempvar cwei
    qui g double `cwei'=1
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
tempfile origds 
capt drop _merge
qui save `origds', replace
keep  `var' `cwei' `at'

qui sum `var'
local nnobs=r(N)
if r(N)<_N {
        *display in red "Missing values are not considered and will be dropped"
        qui drop if `var'==.
        }

** CREATION OF KERNEL DENSITY + ITS VARIANCE USING 
local gauss `"`gauss'"'

tempname cpt cf cvf cbspt

noi disp " `weight' "

if "`weight'" != "" {
        if "`at'"~="" {
        qui vkdensity `var' [`weight' = `cwei'], `gauss' mbandw(`h') g(`cf' `cvf') at(`at') nograph 
        tempvar cpt
        qui g double `cpt'=`at'
            }
        else {
        qui vkdensity `var' [`weight' = `cwei'], `gauss' mbandw(`h') g(`cpt' `cf' `cvf') n(`npt') nograph 
            }
        }
else    {
        if "`at'"~="" {
        qui vkdensity `var', `gauss' mbandw(`h') g(`cf' `cvf') at(`at') nograph 
        tempvar cpt
        qui g double `cpt'=`at'
            }
        else {
        qui vkdensity `var' , `gauss' mbandw(`h') g(`cpt' `cf' `cvf') n(`npt') nograph  
            }
        }

tempvar pt

    sort `cpt'
    qui g double `pt'=`cpt'
    sort `pt'
    qui g double f=`cf'
    qui g double pt=`pt'


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

         
** COMPUTE CRITICAL VALUES
tempvar tstar
qui scalar tstar=invttail(r(N),(`perc'/100))

** GENERATE CONFIDENCE INTERVALS
tempvar ub lb
qui gen double `ub'=`bf'+tstar*sqrt(`bvf')
qui gen double `lb'=`bf'-tstar*sqrt(`bvf')
qui gen double ub=`ub'
qui gen double lb=`lb'
tempvar f 
qui gen double `f'=`cf'

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
        drop `at'
        rename `pt' `cptl'        
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
        (  line `cfl' `boundl'_u `boundl'_l `cptl',                  ///
            ytitle("")         ///
            xtitle(`"`ixl'"')           ///
            legend(cols(1))             ///
            `options'               ///
        )                 ///
        // blank
    }

if `nsave'~=2 & `nsave'~=3 { 
    drop `cptl' `cfl' `boundl'_u `boundl'_l
}


global S_1 = `"`kernel'"'
global S_2 = `n'
global S_3 = `h'
global S_4 = `perc'

end
