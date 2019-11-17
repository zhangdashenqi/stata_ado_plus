*! 1.2.1 GML MSP HEJ 09 January 2009
pro def comproc, rclass
    version 10
    syntax varlist(min=2 max=3 numeric) [if] [in],       ///
         [ AUC PAUC(real 0) ROC(real 0) rocinv(real 0)   ///
           noBStrap PVCMeth(string)                      ///
           ADJCov(varlist numeric) ADJModel(string)      ///
           NSamp(integer 1000) noCCSamp noSTSamp TIECorr ///
           CLuster(varlist) Level(cilevel)               ///
           RESfile(string) REPLACE ]
    preserve // observations and non-essential variables are discarded below
    tempvar st_sort_id  //  will sort on this prior to saving observed sample
                        //  for bootstrap sampling
    gen `st_sort_id' = _n
    tokenize `varlist'
    local d "`1'"
    local y1 "`2'"
    local y2 "`3'"
    local nmark = cond("`3'" == "",1,2)
    marksample touse
    markout `touse' `adjcov'

    local paucf = `pauc'
    local rocf = `roc'

    if `nsamp' == 0 {  // specifying noBS or nsamp(0) will be equivalent and each is allowable
        local bstrap nobstrap
    }
    else {
        cap assert `nsamp' > 1
        if _rc~=0 {
                di in red "argument for nsamp() option must be integer > 1"
                exit 198
        }
    }
    qui ta `d' if `touse'
    if r(r)~=2 {
        di in red "disease indicator `d' must take on two values"
        exit 198
    }
    qui sum `d' if `touse',meanonly
    if r(min)~=0 | r(max)~=1 {
        di in red "disease indicator `d' must be 0/1"
        exit 198
    }
    // default to AUC summary statistic if none specified
    if  ("`auc'"=="" & `paucf' == 0 & `rocf' == 0 & `rocinv' == 0) {
        local auc "auc"
    }

    if `paucf'~=0 {
        cap assert `paucf' > 0 & `paucf' < 1.0
        if _rc~=0 {
                di in red "argument for paucf() option must be between 0 & 1"
                exit 198
        }
        local tiecorr tiecorr  // tie correction default if pAUC is included
    }
    if `rocf'~=0 {
        cap assert `rocf' > 0 & `rocf' < 1.0
        if _rc~=0 {
                di in red "argument for roc() option must be between 0 & 1"
                exit 198
        }
    }
    if `rocinv'~=0 {
        cap assert `rocinv' > 0 & `rocinv' < 1.0
        if _rc~=0 {
                di in red "argument for roc() option must be between 0 & 1"
                exit 198
        }
    }

    cap assert inlist("`pvcmeth'","empirical","normal","")
    if _rc ~=0  {
        di in red `"PVCmeth( ) option must be either "empirical" or "normal" "'
        di        "    if specified"
        error 198
    }
    if "`pvcmeth'" == "" local pvcmeth "empirical"  // default

    local adjust = ("`adjcov'" ~= "")  // 0/1 indicator for -getpcv- argument

    // check adjmodel() arguments if adjcov() is specified, and set to default if missing
    if `adjust' {
        if "`adjmodel'" ~= "" {
            local adjmodel = lower(substr("`adjmodel'",1,4))
            if ~inlist("`adjmodel'","stra","line") {
                di in red "argument to adjmodel( ) option, if specified,"
                di `"   must be either "LINEar" or "STRAtified" (minimal abbrev in caps)"'
                exit 198
            }
        }
        else {
            local adjmodel "stra"
        }
        // check strata control number minimums and gen stratum number var
        // only strata with at least 1 case are relevant
        //  tempvars:  casestrat - indicator for case-containing stratum (0/1)
        //                stratn - stratum number (consecutive. case-containing strata only)
        //              instratn - number of controls/stratum (for case-containing strata)
        if "`adjmodel'" == "stra" {
            tempvar stratn instratn casestrat
            qui {
                bys `touse' `adjcov' (`d'): gen `casestrat' = (`d'[_N] == 1) & `touse'
                bys `touse' `adjcov': gen int `stratn' = _n==1 if `casestrat'==1 & `touse'
                replace `stratn' = sum(`stratn') if `casestrat'==1 & `touse'
                bys `stratn': gen `instratn' = sum(`d'==0) if `casestrat'==1 & `touse'
                bys `stratn': replace `instratn' = `instratn'[_N] if `casestrat'==1 & `touse'
                qui sum `stratn', meanonly
                local nstrat = r(max)
                sum `instratn', meanonly
                local control_min = r(min)
            }
            if `control_min' < 2 {
                unab stratvars: `adjcov'
                di in red "fewer than 2 controls in some case-containing strata"
                di in red "   defined by: `stratvars' "
                di in red "need to redefine/broaden adjustment strata specified by adjcov()"
                exit
            }
            else if `control_min' < 10 {
                unab stratvars: `adjcov'
                di in yel "warning:
                di in yel "  fewer than 10 controls in some case-containing strata"
                di in yel "  defined by stratification variables: `stratvars' "
            }
            local getpcvopts "nstrat(`nstrat') stratn(`stratn')"
        }
        local getpcvopts "`getpcvopts' adjmodel(`adjmodel') adjcov(`adjcov')"
        // get adj cov labels for later results display
        local i = 1
        tokenize `adjcov'
        while "``i''" ~= "" {
                local covlbl`i' : var lab ``i''
                if "`covlbl`i''" == "" local covlbl`i' "``i''"
                local i = `i' + 1
        }
    }

    keep `y1' `y2' `d' `touse' `cluster' `adjcov' `stratn' `st_sort_id'
    qui keep if `touse'

    if "`resfile'"=="" tempfile resfile
    else local ressave "yes"

    if "`replace'"!="" local replacm ",`replace'"

    tempfile obsfile
    tempname pfile
    qui count
    local nobs = r(N)
    sort `st_sort_id'
    qui save `obsfile'

    // stratification variables for bootstrap sampling:
    if "`adjmodel'" == "stra" {
        if "`stsamp'" == "" | "`ccsamp'" == "" {
            if "`stsamp'" == "" {
                if "`ccsamp'" == "" {
                    local stratv `d' `adjcov'  // this is the default
                }
                else {
                    local stratv `adjcov'
                }
            }
            else {
                local stratv `d'
            }
        }
    }
    else {  //  i.e. NOT stratified covariate adjustment
        if "`ccsamp'" == "" {     // the default.  otherwise == noccsamp
            local stratv `d'
        }
    }
    if "`stratv'" ~= "" {
        local stratarg strata(`stratv')
        local stratv_bs_file `stratv'  //  this will be passed back for bs result file

        // count bootstrap strata for bootstrap result file
        //   this may be different that # adjustment strata due to cc sampling
        //   and/or option for bs sampling w/o respect to adjustment strata (to stsamp)
        tempvar sflag
        quietly bys `stratv': gen `sflag' = (_n==1)
        quietly count if `sflag'
        // total number of strata
        local nstrat_bs_file = r(N)
    }

    if "`cluster'" ~= ""{
        // count clusters for bootstrap result file (borrowed from -bootstrap-)
        tempvar cflag
        quietly bys `stratv' `cluster': gen `cflag' = (_n==1)
        quietly count if `cflag'
        // total number of clusters
        local nclust_bs_file = r(N)
        local clusterarg cluster(`cluster')
    }

    forvalues i = 1/`nmark' {
        tempvar pv`i'
        getpcv `y`i'' `d' if `touse', pcvar(`pv`i'') adjust(`adjust') pvcmeth(`pvcmeth') ///
               markn(`i') obs(1) `tiecorr' `getpcvopts'
    }

    // do calls to -auc-, -pauc-, and -roct- need to be restricted with `touse' ?

    // AUC
    if "`auc'" ~= "" {
        if `nmark' == 1 {
            tempname auc1
            local postvars "`postvars' auc"
            local postargs "`postargs' (return(auc))"
            local postargsbs "`postargsbs' (`auc1')"
            auc `pv1' `d' `touse'
            return sca auc = r(auc)
        }
        else {
            forvalues i = 1/`nmark' {
                tempname auc`i'
                local postvars "`postvars' auc`i'"
                local postargs "`postargs' (return(auc`i'))"
                local postargsbs "`postargsbs' (`auc`i'')"
                auc `pv`i'' `d' `touse'
                return sca auc`i' = r(auc)
                if `i' == 2 {
                    return sca aucdelta = return(auc2) - return(auc1)
                }
            }
        }
    }
    // pAUC(#)
    if `paucf' ~= 0 {
        if `nmark' == 1 {
            tempname pauc1
            local postvars "`postvars' pauc"
            local postargs "`postargs' (return(pauc))"
            local postargsbs "`postargsbs' (`pauc1')"
            pauc `pv1' `d' `paucf' `touse'
            return sca pauc = r(pauc)
        }
        else {
            forvalues i = 1/`nmark' {
                tempname pauc`i'
                local postvars "`postvars' pauc`i'"
                local postargs "`postargs' (return(pauc`i'))"
                local postargsbs "`postargsbs' (`pauc`i'')"
                pauc `pv`i'' `d' `paucf' `touse'
                return sca pauc`i' = r(pauc)
                if `i' == 2 {
                    return sca paucdelta = return(pauc2) - return(pauc1)
                }
            }
        }
    }
    // ROCt(#)
    if `rocf' ~= 0 {
        if `nmark' == 1 {
            tempname roc1
            local postvars "`postvars' roc"
            local postargs "`postargs' (return(roc))"
            local postargsbs "`postargsbs' (`roc1')"
            roct `pv1' `d' `rocf' `touse'
            return sca roc = r(roc)
        }
        else {
            forvalues i = 1/`nmark' {
                tempname roc`i'
                local postvars "`postvars' roc`i'"
                local postargs "`postargs' (return(roc`i'))"
                local postargsbs "`postargsbs' (`roc`i'')"
                roct `pv`i'' `d' `rocf' `touse'
                return sca roc`i' = r(roc)
                if `i' == 2 {
                    return sca rocdelta = return(roc2) - return(roc1)
                }
            }
        }
    }
    // ROCinv(t)
    if `rocinv' ~= 0 {
        if `nmark' == 1 {
            tempname rocinv1
            local postvars "`postvars' rocinv"
            local postargs "`postargs' (return(rocinv))"
            local postargsbs "`postargsbs' (`rocinv1')"
            rocinvt `pv1' `d' `rocinv' `touse'
            return sca rocinv = r(rocinv)
        }
        else {
            forvalues i = 1/`nmark' {
                tempname rocinv`i'
                local postvars "`postvars' rocinv`i'"
                local postargs "`postargs' (return(rocinv`i'))"
                local postargsbs "`postargsbs' (`rocinv`i'')"
                rocinvt `pv`i'' `d' `rocinv' `touse'
                return sca rocinv`i' = r(rocinv)
                if `i' == 2 {
                    return sca rocinvdelta = return(rocinv2) - return(rocinv1)
                }
            }
        }
    }

    if "`bstrap'" == "" {

        postfile `pfile' `postvars' using `resfile' `replacm'

        // observed sample
        post `pfile' `postargs'

        forvalues i = 1/`nsamp' {
            qui {
                use `obsfile', clear
                bsample, `stratarg' `clusterarg'

                forvalues j = 1/`nmark' {

                    getpcv `y`j'' `d' if `touse', pcvar(`pv`j'') adjust(`adjust') pvcmeth(`pvcmeth') ///
                         markn(`j') obs(0) `tiecorr' `getpcvopts'

                    tempvar pa`j'

                    if "`auc'" ~= "" {
                        auc `pv`j''  `d' `touse'
                        sca `auc`j'' = r(auc)
                    }
                    if `paucf' ~= 0 {
                        pauc `pv`j'' `d' `paucf' `touse'
                        sca `pauc`j'' = r(pauc)
                    }
                    if `rocf' ~= 0 {
                        roct `pv`j'' `d' `rocf' `touse'
                        sca `roc`j'' = r(roc)
                    }
                    if `rocinv' ~= 0 {
                        rocinvt `pv`j'' `d' `rocinv' `touse'
                        sca `rocinv`j'' = r(rocinv)
                    }
                }
           }
           post `pfile' `postargsbs'
        }
        postclose `pfile'
    }

    displres, nmark(`nmark') mlist(`y1' `y2') d(`d') ///
          nsamp(`nsamp') level(`level') `bstrap'         ///
          adjust(`adjust') pvcmeth(`pvcmeth')        ///
          `getpcvopts' `ccsamp' `stsamp' `tiecorr'

    if "`bstrap'" != "" {  // estimates only - no bootstrap results
        if `nmark' == 1 {
            di in g "   statistic    {c |}    test1   "
            di in g "{hline 16}{c +}{hline 12}"
        }
        else {
            di in g "   statistic    {c |}    test1   {c |}    test2   {c |} difference
            di in g "{hline 16}{c +}{hline 12}{c +}{hline 12}{c +}{hline 12}
        }
        if "`auc'" ~= "" {
            if `nmark' == 1 {
                di in g "      AUC       {c |} " as res %9.0g return(auc)
            }
                else {
                di in g "      AUC       {c |} " %9.0g as result return(auc1) as txt "  {c |} " ///
                     as res %9.0g return(auc2) as txt "  {c |} " ///
                     as res %9.0g return(aucdelta)
            }
        }
        if `paucf' ~= 0 {
            local paucfstr: di substr(string(`paucf',"%4.2f"),2,.)
            if `nmark' == 1 {
                di in g "     pAUC(`paucfstr')  {c |} " as res %9.0g return(pauc)
            }
            else {
                di in g "     pAUC(`paucfstr')  {c |} " %9.0g as result return(pauc1) ///
                     as txt "  {c |} " ///
                     as res %9.0g return(pauc2) as txt "  {c |} " ///
                     as res %9.0g return(paucdelta)
            }
        }
        if `rocf' ~= 0 {
            local rocfstr: di substr(string(`rocf',"%4.2f"),2,.)
            if `nmark' == 1 {
                di in g "      ROC(`rocfstr')  {c |} " as res %9.0g return(roc)
            }
            else {
                di in g "      ROC(`rocfstr')  {c |} " %9.0g as result return(roc1) ///
                     as txt "  {c |} " ///
                     as res %9.0g return(roc2) as txt "  {c |} " ///
                     as res %9.0g return(rocdelta)
            }
        }
        if `rocinv' ~= 0 {
            local rocinvstr: di substr(string(`rocinv',"%4.2f"),2,.)
            if `nmark' == 1 {
                di in g "   ROCinv(`rocinvstr')  {c |} " as res %9.0g return(rocinv)
            }
            else {
                di in g "   ROCinv(`rocinvstr')  {c |} " %9.0g as result return(rocinv1) ///
                     as txt "  {c |} " ///
                     as res %9.0g return(rocinv2) as txt "  {c |} " ///
                     as res %9.0g return(rocinvdelta)
            }
        }
    }
    else {  // bootstrap results
        qui use `resfile',clear
        char _dta[bs_version] 3
        char _dta[N_cluster] `nclust_bs_file'
        char _dta[cluster]   `cluster'
        char _dta[strata]    `stratv_bs_file'
        char _dta[N_strata]  `nstrat_bs_file'
        char _dta[N]         `nobs'
        if "`auc'" ~= "" {
            if `nmark' == 1 {
                char     auc[observed] `=auc[1]' /* first obs is from observed data */
            }
            else {
                char     auc1[observed] `=auc1[1]' /* first obs is from observed data */
                char     auc2[observed] `=auc2[1]'
                gen aucdelta = auc2 - auc1
                char aucdelta[observed] `=aucdelta[1]'
            }
        }
        if `paucf' ~= 0 {
            if `nmark' == 1 {
                char     pauc[observed] `=pauc[1]'
            }
            else {
                char     pauc1[observed] `=pauc1[1]'
                char     pauc2[observed] `=pauc2[1]'
                gen paucdelta = pauc2 - pauc1
                char paucdelta[observed] `=paucdelta[1]'
            }
        }
        if `rocf' ~= 0 {
            if `nmark' == 1 {
                char     roc[observed] `=roc[1]'
            }
            else {
                char     roc1[observed] `=roc1[1]'
                char     roc2[observed] `=roc2[1]'
                gen rocdelta = roc2 - roc1
                char rocdelta[observed] `=rocdelta[1]'
            }
        }
        if `rocinv' ~= 0 {
            if `nmark' == 1 {
                char     rocinv[observed] `=rocinv[1]'
            }
            else {
                char     rocinv1[observed] `=rocinv1[1]'
                char     rocinv2[observed] `=rocinv2[1]'
                gen rocinvdelta = rocinv2 - rocinv1
                char rocinvdelta[observed] `=rocinvdelta[1]'
            }
        }
        qui drop in 1
        if "`ressave'" ~= ""{
            erase `resfile'.dta
            qui save `resfile'
        }
        di in g "****************"

        tempname z p
        if "`auc'" ~= "" {
            qui bstat auc*, level(`level')
            if `nmark' == 1 {
                return sca se_auc = _se[auc]
                di in g"  AUC estimate
            }
            else {
                sca `z' = _b[aucdelta]/_se[aucdelta]
                sca `p' = 2*(1-normal(abs(`z')))
                return sca se_auc1 = _se[auc1]
                return sca se_auc2 = _se[auc2]
                return sca se_aucdelta = _se[aucdelta]

                di in g"  AUC estimates and difference,
                di in g"    test 2 - test 1 (aucdelta)"
            }
            estat bootstrap, all
            di
            if `nmark' == 2 {
                di in g "test of Ho: auc1 = auc2"
                di in g "  z =" in yel %8.2g `z' in g "    p =" in y %8.2g `p'
                di
            }
            di in g "****************"
        }
        if `paucf' ~= 0 {
            qui bstat pauc*, level(`level')
            if `nmark' == 1 {
                return sca se_pauc = _se[pauc]
                di in g"  pAUC estimate
            }
            else {
                sca `z' = _b[paucdelta]/_se[paucdelta]
                sca `p' = 2*(1-normal(abs(`z')))
                return sca se_pauc1 = _se[pauc1]
                return sca se_pauc2 = _se[pauc2]
                return sca se_paucdelta = _se[paucdelta]

                di in g" pAUC estimates and difference,
                di in g"   test 2 - test 1 (paucdelta)"
            }
            di
            di in g"  partial AUC for f < {res}`paucf'
            estat bootstrap, all
            di
            if `nmark' == 2 {
                di in g "test of Ho: pauc1 = pauc2"
                di in g "  z =" in yel %8.2g `z' in g "    p =" in y %8.2g `p'
                di
            }
            di in g "****************"
        }
        if `rocf' ~= 0 {
            if `nmark' == 1 {
                qui bstat roc, level(`level')
                return sca se_roc = _se[roc]
                di in g"  ROC estimate
            }
            else {
                qui bstat roc1 roc2 rocdelta, level(`level')
                sca `z' = _b[rocdelta]/_se[rocdelta]
                sca `p' = 2*(1-normal(abs(`z')))
                return sca se_roc1 = _se[roc1]
                return sca se_roc2 = _se[roc2]
                return sca se_rocdelta = _se[rocdelta]

                di in g" ROC estimates and difference,
                di in g"    test 2 - test 1 (rocdelta)"
            }
            di
            di in g"  ROC(f) @ f = {res}`rocf'
            estat bootstrap, all
            di
            if `nmark' == 2 {
                di in g "test of Ho: roc1 = roc2"
                di in g "  z =" in yel %8.2g `z' in g "    p =" in y %8.2g `p'
                di
            }
            di in g "****************"
        }
        if `rocinv' ~= 0 {
            qui bstat rocinv*, level(`level')
            if `nmark' == 1 {
                return sca se_roc = _se[rocinv]
                di in g"  ROC^(-1) estimate
            }
            else {
                sca `z' = _b[rocinvdelta]/_se[rocinvdelta]
                sca `p' = 2*(1-normal(abs(`z')))
                return sca se_rocinv1 = _se[rocinv1]
                return sca se_rocinv2 = _se[rocinv2]
                return sca se_rocinvdelta = _se[rocinvdelta]

                di in g" ROC^(-1)(t) estimates and difference,
                di in g"    test 2 - test 1 (rocinvdelta)"
            }
            di
            di in g"  ROC^(-1)(t) @ t = {res}`rocinv'
            estat bootstrap, all
            di
            if `nmark' == 2 {
                di in g "test of Ho: rocinv1 = rocinv2"
                di in g "  z =" in yel %8.2g `z' in g "    p =" in y %8.2g `p'
                di
            }
        }
        qui bstat *, level(`level')  //  s.t. e-class returned results
                                     // for bootstrap postestimation include
                                     // all requested statistics
    }
end
***********************
pro def getpcv
    /* called by both main prog and -roct- subprog */
    syntax varlist(min=2 max=2 numeric) [if] [in], pcvar(string) [REPLACE] ///
        adjust(integer) pvcmeth(string) markn(int) obs(int)                ///
        [ adjmodel(string) adjcov(varlist) nstrat(integer 0)               ///
          stratn(varname) tiecorr ]

    tokenize `varlist'
    local y "`1'"
    local d "`2'"
    marksample touse
    tempvar pcvhold ytilde
    tempname rmse

    if "`replace'"!=`""' {
         cap drop `pcvar'
    }
    cap confirm new variable `pcvar'
    if _rc~=0 {
        di in red "variable `pcvar' already exists,"
        di in red `"  use "replace" option to replace `pcvar'"'
        error _rc
    }
    if    ("`pvcmeth'" == "normal")  local pcvcall "npcval"
    else                             local pcvcall "pcval"

    if `adjust' {   //  covariate adjustment of pcv's
        if "`adjmodel'" == "stra" {
            qui gen `pcvar' = .
            forvalues j = 1/`nstrat' {
                `pcvcall' `y' `d' if `touse' & `stratn' == `j', pcvar(`pcvhold') `tiecorr' replace
                qui replace `pcvar' = `pcvhold' if `touse' & `stratn' == `j'
            }
        }
        else {  // linear adjustment
            qui regress `y' `adjcov' if `d' == 0 & `touse'
            if `obs' == 1 {
                estimates store ladj`markn'
            }
            scalar `rmse' = e(rmse)
            predict `ytilde' if `touse', resid
            qui replace `ytilde' = `ytilde'/`rmse' if `touse'
            `pcvcall' `ytilde' `d' if `touse', pcvar(`pcvar') `tiecorr'
            qui drop `ytilde'
        }
   }
   else {  //  no covariate adjustment
       `pcvcall' `y' `d' if `touse', pcvar(`pcvar') `tiecorr'
   }
end
***********************
pro def pcval
    // pcval: percentile values rather than placement values
    // based on plcval.ado, but with correction for ties here
    // modified with comproc v1.1.3 :
    //  a) pcv is now P[Y_db < y]  rather than P[Y_db < y] + .5*P[Y_db = y]]
    syntax varlist(min=2 max=2 numeric) [if] [in], pcvar(string) [tiecorr REPLACE]
    tokenize `varlist'
    local y "`1'"
    local d "`2'"
    marksample touse

    if "`replace'"!=`""' {
         cap drop `pcvar'
    }
    cap confirm new variable `pcvar'
      if _rc~=0 {
          di in red "variable `pcvar' already exists,"
          di in red `"  use "replace" option to replace `pcvar'"'
          error _rc
       }
    tempvar sumdb yneg tieadj
    qui count if `d'==0 & `touse'
    local ndb = r(N)
    qui gen `yneg' = -`y'
    qui bys `touse' (`yneg'): gen `sumdb' = sum(`d'==0) if `touse'
    qui bys `touse' `yneg' (`sumdb'): replace `sumdb' = `sumdb'[_N]

    // adjustment for ties:

    if "`tiecorr'" ~= "" {
        qui bys `touse' `y': gen `tieadj' = sum(`d'==0) if `touse'
        qui bys `touse' `y' (`tieadj'): replace `tieadj' = `tieadj'[_N]/2 if `touse'
        qui replace `sumdb' = `sumdb' - `tieadj'
    }
    qui gen `pcvar' = 1 - (`sumdb'/`ndb')
end
***********************
pro def npcval
    // normal distn option for percentile value calculation
    syntax varlist(min=2 max=2 numeric) [if] [in], pcvar(string) [tiecorr REPLACE]
    tokenize `varlist'
    local y "`1'"
    local d "`2'"
    marksample touse
    if "`replace'"!=`""' {
         cap drop `pcvar'
    }
    cap confirm new variable `pcvar'
      if _rc~=0 {
          di in red "variable `pcvar' already exists,"
          di in red `"  use "replace" option to replace `pcvar'"'
          error _rc
       }
    qui sum `y' if `touse' & `d' == 0
    qui gen `pcvar' = normal( (`y' - r(mean))/r(sd) ) if `touse'
end
***********************
pro def cdf
    syntax varname [if] [in], cdfvar(str)
    marksample touse
    confirm new var `cdfvar'
    qui {
        count if `touse'
        local n = r(N)
        bys `touse' (`varlist'): gen `cdfvar' = sum(`touse') if `touse'
        bys `touse' `varlist' (`cdfvar'): replace `cdfvar' = `cdfvar'[_N] if `touse'
        replace `cdfvar' = `cdfvar'/`n'
    }
end
***********************
pro def auc, rclass
    args pv d touse
    qui sum `pv' if `d'==1 & `touse'
    ret scalar auc = r(mean)
end
***********************
pro def pauc, rclass
    args pv d pauct touse
    tempvar pa
    qui gen `pa' = max(`pv' - (1 - `pauct'),0)
    qui sum `pa' if `d' == 1 & `touse', meanonly
    return sca pauc = r(mean)
end
***********************
pro def roct, rclass
    args pv d roct touse
    qui count if `d'==1 & `touse'
    local nd = r(N)
    qui count if `d'==1 & (`pv' >= (1 - `roct')) & `touse'
    return sca roc = r(N)/`nd'
end
***********************
pro def rocinvt, rclass
    //  will base this on section in -roccurve- for now, but
    //     may want to consider a more efficient calculation ?
    //
    //  largest p s.t. the [proportion of cases with plcv <= p] <= t
    // first, need to fill in cplcv's for controls
    args pv d t touse
    tempvar tpf tpfgp plcv cplcv dneg
    qui gen `plcv' = 1 - `pv' if `touse'
    cdf `plcv' if `touse' & `d'==1, cdfvar(`cplcv')
    qui {
        gen `tpf' = `cplcv' if `d' == 1
        gen byte `dneg' = -`d'
        sort `touse' `plcv' `dneg'
        gen `tpfgp' = sum(`d') if `touse' == 1
        bys `touse' `tpfgp' (`d'): replace `tpf' = `tpf'[_N] if `d'==0 & `touse'
        replace `tpf' = 0 if `tpfgp' == 0
        sum `plcv' if `tpf' <= `t', meanonly
    }
    if r(N) != 0 {
        return scalar rocinv = r(max)
    }
    else {
        return scalar rocinv = 0
    }
end
***********************
pro def displres,
    syntax, nmark(int) mlist(varlist) d(varname)        ///
        nsamp(real) level(cilevel)                      ///
        adjust(integer) pvcmeth(string)                 ///
        [ adjmodel(string) adjcov(varlist) nobstrap     ///
          nstrat(integer 0) stratn(varname)             ///
          noCCSamp noSTSamp cluster(varlist)            ///
          tiecorr ]

    // header:

    tokenize `mlist'
    forvalues i = 1/`nmark' {
        local m`i' "``i''"
        if "`:variable label `m`i'''" == "" {
            local m`i'lab "`m`i''"
        }
        else {
            local m`i'lab "`:variable label `m`i'''"
        }
     }
    di
    if `nmark' == 2 {
        di as txt "{ralign 35: Comparison of test measures}"
        di as txt "{ralign 40: test 1:} {res:`m1lab'}"
        di as txt "{ralign 40: test 2:} {res:`m2lab'}"
    }
    else {
        di as txt "{ralign 35: ROC statistics}"
        di as txt "{ralign 40: marker:} {res:`m1lab'}"
    }

    di
    di as txt "{ralign 40: percentile value calculation method:} {res:`pvcmeth'} "
    if "`pvcmeth'" == "empirical" {
        di as txt "{ralign 40: percentile value tie correction:} {res:`=cond("`tiecorr'"=="","no","yes")'} "
    }
    di
    if `adjust' {
        local ncov = wordcount("`adjcov'")
        tokenize `adjcov'
        forvalues i = 1/`ncov' {
            if "`:variable label ``i'''" == "" {
                local cov`i'lab "``i''"
            }
            else {
                local cov`i'lab "`:variable label ``i''' "
            }
        }
        if "`adjmodel'" == "stra" {
            local adjmlab "stratified"
        }
        else if "`adjmodel'" == "line" {
            local adjmlab "linear model"
        }
        di as txt "{ralign 35: Covariate adjustment}"
        di as txt "{ralign 40: method:} {res:`adjmlab'} "
        di as txt "{ralign 40: covariates:} {res:`cov1lab'}
        if `ncov' > 1 {
            forvalues i = 2/`ncov' {
                di as res _col(42) "`cov`i'lab'"
            }
        }
        if "`adjmodel'" == "stra" {
            di as txt "{ralign 40: # of case-containing strata:} {res:`nstrat'}"
            di
            la var `stratn' "stratum"
            ta `stratn' `d'
            di
        }
        else if "`adjmodel'" == "line" {
            forvalues i = 1/`nmark' {
                di
                di as txt "************"
                di
                di as txt " covariate adjustment - linear model, controls only"
                di as txt " model results for marker: {res:`m`i'lab'}"
                di
                estimates replay ladj`i', noheader
                qui estimates drop ladj`i'
            }
        di
        di as txt "************"
        di
        }
    }
    if "`bstrap'" == "" {
        if "`ccsamp'" == "" {
            di in g "  bootstrap samples drawn"
            di in g "   separately from cases and controls"
        }
        else {
            di in g "  bootstrap samples drawn"
            di in g "   w/o respect to case/control status"
        }
        if `adjust' & ("`adjmodel'" == "stra") {
            if "`stsamp'" == "" {
                di in g "   and from within covariate strata"
                }
            else {
                di in g "   and w/o respect to covariate strata"
            }
        }
        di
        di as txt "  # bootstrap samples: {res:`nsamp'}"
        di
    }
    else {
            di in g "  no bootstrap sampling specified.
            di in g "  bootstrap-based se's, CI's, and test statistics will not be calculated."
            di
    }
end
