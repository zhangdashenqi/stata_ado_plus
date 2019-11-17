*! 1.7.0  27Aug997  Jeroen Weesie/ICS  STB-42 sg77
*     --  added from(), score()

program define regh
    version 5.0

    local options "Level(int $S_level)"
    if "`1'" ~= "" & substr("`1'",1,1) ~= "," {

    /* begin */ quietly {

      * parse off equations 

        parse "`*'", parse(" ,")
        if "`2'" == "" {  
            noi di in re "2 equations should be specified"
            exit 198
        }
        local meq `1'             /* equation for mean */
        local veq `2'             /* equation for (log-)variance */      
        mac shift 2               /* keep rest of command line in -cmdrest- */
        local cmdrest "`*'"

        eq ? `meq'                /* check that -meq- is valid equation */
        unabbrev $S_1, min(1)
        parse "$S_1", parse(" ")
        local yvar `1'
        mac shift
        local xvar "`*'"

        eq ? `veq'                /* check that -veq- is valid equation */
        if "$S_1" ~= "" {
            unabbrev $S_1
            local zvar "$S_1"
        }
        
      * parse cmdrest
        
        local in "opt"
        local if "opt"
        #del ;
        local options "`options' Acc(real 1E-4) Cluster(str) Iter(int 100) 
                       noLOg Robust Score(str) TRace TWostage From(str)" ;
        #del cr
        parse "`cmdrest'"
    
      * scratch

        tempname b0 b1 bv bm db dbv ndb Tbv Tdbv Vbm Vbv V vfac
        tempvar ivar lf lnvar mn resy sc_m sc_lv touse 
        
      * sample selection and missing values

        mark `touse' `if' `in' 
        markout `touse' `yvar' `xvar' `zvar' 

      * setup for clustered observations
      
        if "`cluster'" ~= "" {
            confirm var `cluster'
            markout `touse' `cluster', strok
            local clopt "cluster(`cluster')"
        }
        
      * output options for iterative computations 
      
        if "`trace'" ~= "" { local log }
        if "`log'" ~= "" { local log "quietly" }
        else { local log "noisily" }    

      * initialization of estimates

        if "`from'" == "" {
            * initialization of estimates of b-mean
            reg `yvar' `xvar' if `touse'
            predict `mn' if `touse' 
            mat `bm' = get(_b)
            mat coleq `bm' = `meq'

            * initialization of estimates of b-var
            gen double `resy' = 2*ln(abs(`yvar'-`mn')) if `touse'
            regress `resy' `zvar' if `touse' 
            mat `bv' = get(_b)
            mat coleq `bv' = `veq'

            * add 1.2704 to veq:_cons; see Harvey (1976: 463) 
            local ncons = colnumb(`bv', "`veq':_cons")
            mat `bv'[1,`ncons'] = `bv'[1,`ncons'] + 1.2704
        
            * compute ivar = exp(-Z*g) = 1/variance   
            mat score double `lnvar' = `bv' if `touse'
            gen double `ivar' = exp(-`lnvar') if `touse'

        }
        else {
            * extract components from "from"
            mat `bm' = `from'[1,"`meq':"]
            mat `bv' = `from'[1,"`veq':"]
            mat score `mn' = `bm' if `touse'
            mat score `lnvar' = `bv' if `touse'
            gen `ivar' = exp(-`lnvar') if `touse'                       
        }
                    
        * log-likelihood (ll) of model M1
        gen double `lf' = `ivar'*(`yvar'-`mn')^2 + `lnvar' + ln(2*_pi) if `touse'
        summ `lf' if `touse', meanonly
        local ll = -0.5 * _result(18)        

        * combine bm and bv into b0
        mat `b0' = `bm',`bv'
                 
      * scoring algorithm (Greene 1993: 407) with step-halving for bv
    
        if "`twostage'" == "" {    
            if "`trace'" ~= "" {  
                noi di _n in gr "Initialization with two-stage estimator"
                noi mat list `b0', noheader nonames noblank
            }
            else `log' display

            local it 1
            scalar `ndb' = 1                                    
            while `it' <= `iter' & `ndb' > `acc' {
                * update bm
                regress `yvar' `xvar' if `touse' [iw=`ivar']
                drop `mn'
                predict `mn' if `touse'
                mat `bm' = get(_b)
                mat coleq `bm' = `meq'
                                 
                * update direction for bv
                capt drop `resy'
                gen double `resy' = ((`yvar'-`mn')^2)*`ivar' - 1 if `touse'
                regress `resy' `zvar' if `touse' 
                mat `dbv' = get(_b)
                
                * step-halving for bv in direction dbv
                local step 1
                local mstep
                while `step' > .01 {
                    mat `Tdbv' = `step' * `dbv'    
                    mat `Tbv' = `bv' + `Tdbv'
                    mat coleq `Tbv' = `veq'
                
                    * compute ivar = exp(-Z*g) = 1/variance   
                    drop `lnvar' `ivar'
                    mat score double `lnvar' = `Tbv' if `touse'
                    gen double `ivar' = exp(-`lnvar') if `touse'
                    
                    * log-likelihood Tll in (bm,Tbv)
                    drop `lf'
                    gen double `lf' = `ivar'*(`yvar'-`mn')^2 + `lnvar' + ln(2*_pi) if `touse'
                    summ `lf' if `touse', meanonly
                    local Tll = -0.5 * _result(18)        
                                                        
                    if `ll' > `Tll' { 
                        local step = 0.5 * `step' 
                        local mstep "[step half]"
                    }
                    else {
                        local step = -1
                        local ll `Tll'
                    }
                } /* while */
                                           
                if `step' == -1 {
                    * stephalving succesfull    
                    mat `bv' = `Tbv'
                    mat `b1' = `bm' , `bv'
                    mat `db' = `b1' - `b0'    
                    mat `b0' = `b1'
                    
                    * converge criterion in terms of L2-norm of db
                    mat `ndb' = `db' * `db''
                    scalar `ndb' = sqrt(`ndb'[1,1])

                    * report iteration information
                    `log' di in gr "iteration `it':" /*
                        */ in gr "  Log-likelihood = " in ye %9.4g `ll' /*
                        */ in gr "  |delta-b| " in ye %9.4g scalar(`ndb') /*
                        */ in gr " `mstep'"                      
                    if "`trace'" ~= "" {  
                        noi mat list `b0', noheader nonames noblank
                    }
                }
                else {
                    di in bl "step-halving failed, iteration terminated"        
                    di in bl "all results below are probably senseless"
                    scalar `ndb' = 0                        
                } /* if step */
                
                local it = `it' + 1
            } /* while it */
            
            if `ndb' > `acc' {
                noi di in bl "Convergence not achieved"
            }
            
            * asymptotic factor for ml-estimator (Harley 1976:463)
            scalar `vfac' = 2
        }
        else {
            * asymptotic factor for two-stage estimator under normality
            * see Harvey (1976:463)
            scalar `vfac' = 4.9348 
        }   
        
      * asymptotic standard errors

        * note the use of parentheses to allow empty varlists
        mat acc `Vbm' = (`xvar') if `touse' [iw=`ivar']
        mat `Vbm' = syminv(`Vbm')
        mat acc `Vbv' = (`zvar') if `touse' 
        local nobs = _result(1)
        mat `Vbv' = syminv(`Vbv')
        mat `Vbv' = `vfac' * `Vbv'
                    
        * create properly named matrix  
        *      V = [ Vbm    0  ]
        *          [  0    Vbv ]

        local nV = rowsof(`Vbm') + rowsof(`Vbv')             
        mat `V' = J(`nV',`nV',0)
        mat subst `V'[1,1] = `Vbm'
        local nIns = 1 + rowsof(`Vbm')             
        mat subst `V'[`nIns',`nIns'] = `Vbv'
    
        local cnb0 : colnames(`b0')
        mat rownames `V' = `cnb0'
        mat colnames `V' = `cnb0'
        local eqb0 : coleq(`b0')
        mat roweq `V' = `eqb0'
        mat coleq `V' = `eqb0'    

      * post information
      
        mat post `b0' `V', depname(`yvar') 

        global S_E_cmd  "regh"
        global S_E_meq  "`meq'"
        global S_E_veq  "`veq'" 
        global S_E_depv "`yvar'"
        global S_E_rhsm "`xvar'"
        global S_E_rhsv "`zvar'"
        global S_E_if   "`if'"
        global S_E_in   "`in'"
        global S_E_nobs `nobs'

        * estimator type
        if "`twostage'" == "" { global S_E_estt "mle" }
        else { global S_E_estt "2sls" }

        * log-likelihood (l0) of baseline model M0: constant mean and var           
        * log-likelihood (ll) of model M1
        
        summ `yvar' if `touse'
        global S_E_l0   = -0.5 * `nobs' * (1 + ln(2*_pi) + /* 
                             */ ln((`nobs'-1)/`nobs'*_result(4)))       
        global S_E_ll   = `ll'
        global S_E_chi2 = 2 * ($S_E_ll-$S_E_l0) 
        global S_E_pr2  = 1 - ($S_E_ll/$S_E_l0)

        * count model degrees of freedom as the rank of VCE - 2
        
        Getmdf

        * define R2 as the R2 in variance weighted regression. This can simply 
        * be obtain as the square of the weighted correlation between yvar and 
        * prediction-y. note that -corr- does not distinguish -iw- and -aw-.  

        corr `yvar' `mn' [aw=`ivar']
        global S_E_R2 = _result(4)^2    /* result(4) == corr */

      * adjustment for robust & clustered standard errors

        if "`robust'" ~= "" | "`cluster'" ~= "" | "`score'" ~= "" {           
            * sc_m = dl(i) / d(x(i)'b)
            gen double `sc_m'  = `ivar'*(`yvar'-`mn') if `touse'
            * sc_lv = dl(i)/d(z(i)'g)
            gen double `sc_lv' = 0.5 * `ivar'*(`yvar'-`mn')^2 - 1 if `touse' 
            if "`score'" ~= "" {
                xxx
            }
            if "`robust'" ~= "" | "`cluster'" ~= "" {
                _robust `sc_m' `sc_lv' if `touse', `clopt'
            }                    
        }
    /* end quiet */ } 
    }       
    else {
        if ("$S_E_cmd" ~= "regh") { error 301 }
        parse "`*'"
    }

  * output of regh

    if (`level' < 10 | `level' > 99) { local level 95 }
    #delimit ;
    di in gr _n "Multiplicative heteroscedastic regression " 
             _col(55) "Number of obs  =" in ye %8.0f $S_E_nobs ;
    di in gr "Estimator: " in ye "$S_E_estt" in gr
             _col(55) "Model chi2(" in ye $S_E_mdf in gr ")" 
             _col(70) "=" in ye %8.3f $S_E_chi2 ; 
    di in gr _col(55) "Prob > chi2" 
             _col(70) "=" in ye %8.3f chiprob($S_E_mdf,$S_E_chi2) ;
    di in gr "Log Likelihood" _col(29) "=" in ye %10.3f $S_E_ll 
             _col(55) in gr "Pseudo R2" 
             _col(70) "=" in ye %8.4f $S_E_pr2  ;
    di in gr _col(55) in gr "VWLS R2"   
             _col(70) "=" in ye %8.4f $S_E_R2 ;
    #del cr

    matrix mlout, level(`level')
end
                
program define Getmdf
        * count model degrees of freedom as the rank of VCE - 2
        tempname V        
        mat `V' = get(VCE)
        local i 1
        local mdf 0
        while `i' <= colsof(`V') {
            if `V'[`i',`i'] > 0 { local mdf = `mdf' + 1 }
            local i = `i'+1
        }
        global S_E_mdf = `mdf' - 2    /* #pars(M1) - #par(M0) */
end
