*! 1.1.5 GML MSP HEJ 09 January 2009
pro def rocreg, eclass
    version 10
    if !replay() {
        syntax varlist(min=2 numeric) [if] [in],             ///
             [ LInk(name) noBStrap                           ///
               REGCov(varlist numeric)                       ///
               SREGCov(varlist numeric)                      ///
               NSamp(integer 1000)                           ///
               noCCSamp CLuster(varlist) noSTSamp TIECorr    ///
               PVCMeth(string)                               ///
               INTerval(numlist min=3 max=3)                 ///
               level(cilevel)                                ///
               ADJCov(varlist numeric) ADJModel(string)      ///
               RESfile(string) REPLACE ]

        preserve
        tempvar st_sort_id  //  will sort on this prior to saving observed sample
                            //  for bootstrap sampling
        gen `st_sort_id' = _n
        gettoken d mlist : varlist
        tokenize `mlist'
        local y1 "`1'"
        local i = 2
        local nmark = 1
        marksample touse, nov   // don't markout missing values for marker variables
        markout `touse' `d' `adjcov'
        // markout missing regression covariate observations for cases only:
        local nregcov = wordcount("`regcov'")
        if `nregcov' ~= 0 {
            foreach var of varlist `regcov' {
                qui replace `touse' = 0 if missing(`var') & `d'==1
            }
        }
        local nsregcov = wordcount("`sregcov'")
        if `nsregcov' ~= 0 {
            foreach var of varlist `sregcov' {
                qui replace `touse' = 0 if missing(`var') & `d'==1
            }
        }
        while "``i''" ~= "" {    // when there are 2+ marker variable arguments
            local ++nmark
            local y`nmark' "``i''"
            local ++i
            // may need to generate separate touse`i' for each marker variable ?
            //  alternatively - take care of this in subprog calls ?
        }

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
        if r(r) ~= 2 {
            di in red "`d' must take on two values"
            exit 198
        }
        qui sum `d' if `touse', meanonly
        if r(min) ~= 0 | r(max) ~= 1 {
            di in red "`d' must be 0/1"
            exit 198
        }
        // if this mix of bracketed and unbracketed if statements works
        //    consider changing -comproc- to have an identical check

        cap assert inlist("`link'","probit","logit","")
        if _rc ~= 0  {
            di in red `"LInk( ) option must be either "probit" or "logit" "'
            di        "    if specified"
            error 198
        }

        if "`link'" == "" local link "probit"  // default

        cap assert inlist("`pvcmeth'","empirical","normal","")
        if _rc ~= 0  {
            di in red `"PVCmeth( ) option must be either "empirical" or "normal" "'
            di        "    if specified"
            error 198
        }
        if "`pvcmeth'" == "" local pvcmeth "empirical"  // default

        // check interval() option arguments if specified, otherwise assign defaults
        if "`interval'" ~= "" {
            local a  = word("`interval'", 1)
            local b  = word("`interval'", 2)
            local np = word("`interval'", 3)
            if ~( inrange(`a',0,1) & inrange(`b',0,1) ) {
                di "{err} first 2 interval arguments, a & b, must be between 0 & 1 "
                exit 198
            }
            if `b' <= `a' {
                di "{err} interval arguments must satisfy a < b "
                exit 198
            }
            cap confirm integer number `np'
            if ~(_rc==0 & `np' > 0) {
                di "{err} 3rd interval argument, np, must be a positive integer"
                exit 198
            }
            //  should add a positive upper bound to np here ?
        }
        else {  // default interval and number of points when rocmeth is binormal
            local a  = 0
            local b  = 1
            local np = 10
        }
        local adjust = ("`adjcov'" ~= "")  // 0/1 indicator for -getpcv- argument

        tempvar stratn instratn casestrat
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
                    di in red "fewer than 2 controls in some case-containing strata"
                    di in red "   defined by: `adjcov' "
                    di in red "need to redefine/broaden adjustment strata specified by adjcov()"
                    exit
                }
                else if `control_min' < 10 {
                    di in yel "warning:
                    di in yel "  fewer than 10 controls in some case-containing strata"
                    di in yel "  defined by stratification variables: `adjcov' "
                }
                local getpcvopts "nstrat(`nstrat') stratn(`stratn')"
            }
            local getpcvopts "`getpcvopts' adjmodel(`adjmodel') adjcov(`adjcov')"
        }

        local xlist ""
        local ylist ""
        local mlablist ""

        // bootstrap ROC GLM se's:

        local betas ""
        tokenize `regcov'
        forvalues i = 1/`nregcov' {
            local betas "`betas' ``i''"
        }
        local sbetas ""
        tokenize `sregcov'
        forvalues i = 1/`nsregcov' {
            local sbetas "`sbetas' s_``i''"
        }

        if "`resfile'"!="" local ressave yes
        if "`replace'"!="" local replacm ",`replace'"

        forvalues i = 1/`nmark' {
            tempname pf`i'
            local pflist "`pflist' `pf`i''"
            if "`resfile'"=="" {
                tempfile resfile`i'
            }
            else {
                if `nmark' == 1 {
                    local resfile`i' `resfile'
                }
                else {
                    local resfile`i' `resfile'`i'
                }
            }
            postfile `pf`i'' alpha_0 alpha_1 `betas' `sbetas' using `resfile`i'' `replacm'
        }
        if "`regcov'" != "" {
            local regcovarg "regcov(`regcov')"
        }
        if "`sregcov'" != "" {
            local sregcovarg "sregcov(`sregcov')"
        }
        if "`cluster'" ~= "" {
            local clusterarg cluster(`cluster')
        }

        glmbs if `touse', nmark(`nmark') mlist(`mlist') d(`d')  ///
              nsamp(`nsamp') `ccsamp' pflist(`pflist') `bstrap' ///
              adjust(`adjust') pvcmeth(`pvcmeth')               ///
              st_sort_id(`st_sort_id')                          ///
              b(`b') a(`a') np(`np') link(`link')               ///
              nregcov(`nregcov') `regcovarg'                    ///
              nsregcov(`nsregcov') `sregcovarg'                 ///
              `stsamp' `tiecorr' `getpcvopts'                   ///
              level(`level') `clusterarg'

        local nclust `r(nclust)'   // don't use expression assgn., this may not exist,
        local nstratbs  `r(nstrat)'
        local stratvbs `r(stratv)'
        local nobs `r(nobs)'

        displres, nmark(`nmark') mlist(`mlist') d(`d')       ///
              a(`a') b(`b') np(`np') link(`link')            ///
              nsamp(`nsamp') level(`level') `bstrap'         ///
              adjust(`adjust') pvcmeth(`pvcmeth')            ///
              `getpcvopts' `ccsamp' `stsamp' `tiecorr'       ///
              nregcov(`nregcov') `regcovarg'                 ///
              nsregcov(`nsregcov') `sregcovarg'

        forvalues i = 1/`nmark' {
            if "`:variable label `y`i'''" == "" {
                local m`i'lab "`y`i''"
            }
            else {
                local m`i'lab "`:variable label `y`i'''"
            }
            local rownames "`rownames'`y`i'' "
        }
        local colnames "alpha_0 alpha_1 `betas' `sbetas'"
        local ncol = wordcount("`colnames'")
        tempname GLMparm
        mat `GLMparm' = J(`nmark',`ncol',.)
        matrix rownames `GLMparm' = `rownames'
        matrix colnames `GLMparm' = `colnames'

        forvalues i = 1/`nmark' {
            postclose `pf`i''

            if "`bstrap'" == ""{
                qui use `resfile`i'', clear
                char _dta[bs_version] 3
                char _dta[N_cluster] `nclust'
                char _dta[cluster]   `cluster'
                char _dta[strata]    `stratvbs'
                char _dta[N_strata]  `nstratbs'
                char _dta[N]         `nobs'

                local j = 1
                foreach var of varlist * {
                    char `var'[observed] "`=`var'[1]'"
                    matr `GLMparm'[`i',`j'] == `var'[1]
                    local ++j
                }
                qui drop in 1
                la data "-rocreg- ROC GLM bootstrap results for marker: `m`i'lab'"
                qui save `resfile`i'', replace
            }

            di
            di as txt "******************************
            di as txt " model results for marker: {res:`m`i'lab'}"
            di
            if `adjust' & ("`adjmodel'" == "line") {
                di as txt "   covariate adjustment - linear model, controls only"
                di
                estimates replay ladj`i', noheader
                qui estimates drop ladj`i'
                di
                di as txt "************"
                di
            }

            di as txt "   ROC-GLM model"
            if "`bstrap'" == "" {
                qui bstat using `resfile`i'', level(`level')
                estat bootstrap, all
                di
                ereturn local cmd "rocreg"
                ereturn local test_varname "`m`i'lab'"
                // ereturn repost  - unneccessary, results from estat bootstrap are
                //                   already posted.
                if `nmark' > 1 {
                    estimates store rocreg_m`i'
                }
            }
            else {  // i.e. nobstrap specified
                ereturn clear     // so that results from last -rocglm- call are not returned
                                  // and mistaken for returned -bstat- results
                qui use `resfile`i'', clear
                di
                di in g "            model term  {c |}  coefficient   "
                di in g "{hline 24}{c +}{hline 13}"
                local j = 1
                foreach var of varlist * {
                    di as res "{ralign 22:`=substr("`var'",1,20)'}" _col(25) as txt "{c |}" ///
                    as res "   " %9.0g `var'[1]
                    matr `GLMparm'[`i',`j'] == `var'[1]
                    local ++j
                }
                di
                ereturn local cmd "rocreg_no_bs"
            }
        }
        ereturn matrix GLMparm = `GLMparm'
    }
    else {  // replay bootstrap estimation results
        if "`e(cmd)'" == "rocreg_no_bs" {
            di as error "no bootstrap results to replay, "
            di as error "   nobstrap option was specified with last run of -rocreg-"
            error 301
        }
        else if "`e(cmd)'" != "rocreg" {
            error 301
        }
        syntax [, Level(cilevel)]
        ereturn display, level(`level')
    }
end
***********************
pro def glmbs, rclass
    // -bootstrap- won't recognize subprogram called with :command argument, so
    //    will have to do lower level bootstrap
    // get bootstrap CI's for ROC(t), specified t argument
    syntax [if] [in], nmark(int) mlist(varlist) d(varname)                    ///
        nsamp(real) pflist(string) nregcov(integer) nsregcov(integer)         ///
        adjust(integer) pvcmeth(string) st_sort_id(varname)                   ///
        a(real) b(real) np(integer) link(name)                                ///
        [ adjmodel(string) adjcov(varlist) nstrat(integer 0) stratn(varname)  ///
          tiecorr noCCSamp noSTSamp cluster(varlist) regcov(varlist numeric)  ///
          sregcov(varlist numeric) nobstrap ]  level(cilevel)

    preserve //  will need to drop unused obs and vars for bootstrap
    marksample touse
    qui keep if `touse'
    qui keep `mlist' `d' `adjcov' `stratn' `cluster' `regcov' `sregcov' `st_sort_id'
    tempfile obsfile resfile
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
        return local stratv `stratv'  //  this will be passed back for bs result file

        // count bootstrap strata for bootstrap result file
        //   this may be different that # adjustment strata due to cc sampling
        //   and/or option for bs sampling w/o respect to adjustment strata (to stsamp)
        tempvar sflag
        quietly bys `stratv': gen `sflag' = (_n==1)
        quietly count if `sflag'
        // total number of strata
        return local nstrat = r(N)
    }
    if "`cluster'" ~= ""{
        // count clusters for bootstrap result file (borrowed from -bootstrap-)
        tempvar cflag
        quietly bys `stratv' `cluster': gen `cflag' = (_n==1)
        quietly count if `cflag'
        // total number of clusters
        return local nclust = r(N)
        local clusterarg cluster(`cluster')
    }
    if `adjust' == 1 {
        local getpcvopts "adjmodel(`adjmodel') adjcov(`adjcov')"
    }
    if "`adjmodel'" == "stra" {
        local getpcvopts "`getpcvopts' nstrat(`nstrat') stratn(`stratn')"
    }
    if "`regcov'" != "" {
        local regcovarg "regcov(`regcov')"
    }
    if "`sregcov'" != "" {
        local sregcovarg "sregcov(`sregcov')"
    }

    qui count
    return local nobs = r(N)

    // observed sample:
    doasamp, d(`d') mlist(`mlist') nmark(`nmark') adjust(`adjust') link(`link') ///
           pvcmeth(`pvcmeth') `getpcvopts' b(`b') a(`a') np(`np') `tiecorr'     ///
          nregcov(`nregcov') `regcovarg' nsregcov(`nsregcov') `sregcovarg'      ///
          pflist(`pflist') obs(1)

    // bootstrap samples:
    if "`bstrap'" == "" {
        forvalues i = 1/`nsamp' {
            qui {
                use `obsfile', clear
                bsample, `stratarg' `clusterarg'
                doasamp, d(`d') mlist(`mlist') nmark(`nmark') adjust(`adjust')     ///
                  link(`link') pvcmeth(`pvcmeth') `getpcvopts'                     ///
                  b(`b') a(`a') np(`np') `tiecorr'                                 ///
                  nregcov(`nregcov') `regcovarg' nsregcov(`nsregcov') `sregcovarg' ///
                  pflist(`pflist') obs(0)
                }
        }
    }
end
***********************
pro def doasamp, rclass
    //  if, in, and touse unnecessary?
    syntax [if] [in], d(varname) mlist(varlist) nmark(integer)  ///
        a(real) b(real) np(integer) pflist(string) link(name)   ///
        nregcov(integer)  nsregcov(integer)                     ///
        adjust(integer) pvcmeth(string) obs(int)                ///
        [adjmodel(string) adjcov(varlist) nstrat(integer 0) stratn(varname) ///
         regcov(varlist) sregcov(varlist) tiecorr *]

    marksample touse
    tokenize `mlist'

    if "`regcov'" != "" {
        local regcovarg "regcov(`regcov')"
    }
    if "`sregcov'" != "" {
        local sregcovarg "sregcov(`sregcov')"
    }
    if `adjust' == 1 {
        local getpcvopts "adjmodel(`adjmodel') adjcov(`adjcov')"
    }
    if "`adjmodel'" == "stra" {
        local getpcvopts "`getpcvopts' nstrat(`nstrat') stratn(`stratn')"
    }

    forvalues i = 1/`nmark' {
        tempvar plcv`i'
        getpcv ``i'' `d' if `touse', pcvar(`plcv`i'') adjust(`adjust') pvcmeth(`pvcmeth') ///
               `tiecorr' `getpcvopts' markn(`i') obs(`obs')
        qui replace `plcv`i'' = 1 - `plcv`i''
        local xlist "`xlist' `plcv`i''"
    }
    rocglm if `touse', nmark(`nmark') plcv(`xlist')       ///
           d(`d') b(`b') a(`a') np(`np') link(`link')     ///
           nregcov(`nregcov') `regcovarg'                 ///
           nsregcov(`nsregcov') `sregcovarg'              ///
           pflist(`pflist') obs(`obs')
end
***********************
pro def rocglm
    /* get parameter estimates for binormal curve */
    syntax [if] [in], nmark(int) plcv(varlist numeric min=1)     ///
           d(varname) b(real) a(real) np(integer) pflist(string) ///
           nregcov(integer) nsregcov(integer) link(name)         ///
           obs(int)                                              ///
           [regcov(varlist numeric) sregcov(varlist numeric)]
    marksample touse
    tempname B

    forvalues i = 1/`nregcov' {
        local z `=word("`regcov'",`i')'
        local rcpostargs `macval(rcpostargs)' (\`=`B'[1,colnumb(`B',"`z'")]')
        // local postargs `"`postargs' (\`=cond(missing(_b[`z']),.,_b[`z'])')"'
        // local postargs `"`postargs' (_b[`=word("`regcov'",`i')'])"'
    }
    tempvar uid f x k
    qui {
        gen `uid' = _n
        expand `np' if `d'==1 & `touse'
        bys `uid': gen `k' = _n if `d'==1 & `touse'
        gen `f' = `a' + `k'*((`b'-`a')/(`np' + 1))
        gen `x' = cond("`link'" == "probit",invnorm(`f'),logit(`f'))
        tokenize `sregcov'  //  tokenizing empty macro is okay
        forvalues i = 1/`nsregcov' {
            tempvar x`i'
            gen `x`i'' = `x' * ``i''
            local slpterms "`slpterms' `x`i''"
            local srcpostargs `macval(srcpostargs)' (\`=`B'[1,colnumb(`B',"`x`i''")]')
            // local postargs `"`postargs' (_b[`x`i''])"'
        }
        tokenize `plcv'
        forvalues i = 1/`nmark' {
            local plcv`i' "``i''"    // not strictly necessary
            local pf`i' = word("`pflist'",`i')
            tempvar u
            gen `u' = ( (`plcv`i'')<= `f') if ~missing(`f',`plcv`i'')
            cap `link' `u' `x' `regcov' `slpterms', asis
            if _rc~= 0 {
                if `obs' == 1 {
                    di in red `" error in `link' fit with observed sample, subp -rocglm- "'
                    error _rc
                }
                else {  // error in bootstrap sample - add a record w/missing values
                    local missargs "(.) (.) "
                    forvalues j = 1/`nregcov' {
                        local missargs "`missargs' (.) "
                    }
                    forvalues j = 1/`nsregcov' {
                        local missargs "`missargs' (.) "
                    }
                    post `pf`i'' `missargs'
                }
            }
            else {
                matrix `B' =  e(b)
                // if there are dropped terms in the observed sample,
                //    exit with an error and identify the terms in
                //    the error message.
                if `obs' == 1 {
                   if strpos("`rcpostargs'","(.)") > 0 {
                       tokenize `rcpostargs'
                       forvalues j = 1/`nregcov' {
                           if "``j''" == "(.)" {
                               local dropterm = "`dropterm' " + word("`regcov'",`j')
                           }
                       }
                       di in red " error in glm fit for observed sample"
                       di in red "   dropped term(s) for collinearity (?), `dropterm',
                       di in red "   in regression covariate list, regcov(varlist)"
                       error 499
                   }
                   if strpos("`srcpostargs'","(.)") > 0 {
                       tokenize `srcpostargs'
                       forvalues j = 1/`nsregcov' {
                           if "``j''" == "(.)" {
                               local dropterm = "`dropterm' " + word("`sregcov'",`j')
                           }
                       }
                       di in red " error in glm fit for observed sample"
                       di in red "   dropped term(s) for collinearity (?), `dropterm',
                       di in red "   in regression covariate list sregov(varlist)"
                       error 499
                   }
                }
                post `pf`i'' (_b[_cons]) (`=`B'[1,colnumb(`B',"`x'")]') `rcpostargs' `srcpostargs'
            }
            drop `u'
        }
    }
end
***********************
pro def getpcv
    /* called by both main prog and -roct- subprog */
    syntax varlist(min=2 max=2 numeric) [if] [in], pcvar(string) [REPLACE] ///
        adjust(integer) pvcmeth(string) obs(int) markn(int)                ///
       [adjmodel(string) adjcov(varlist) nstrat(integer 0) stratn(varname) ///
        tiecorr ]
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
            qui predict `ytilde' if `touse', resid
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
    // modified with roccurve v 1.2.1 :
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
    syntax varlist(min=2 max=2 numeric) [if] [in], pcvar(string) [REPLACE tiecorr]
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
pro def displres,
    syntax, nmark(int) mlist(varlist) d(varname)        ///
        a(real) b(real) np(integer) link(name)          ///
        nsamp(real) level(cilevel)                      ///
        nregcov(int) nsregcov(int)                      ///
        adjust(integer) pvcmeth(string)                 ///
        [ nobstrap adjmodel(string) adjcov(varlist)     ///
          nstrat(integer 0) stratn(varname)             ///
          noCCSamp noSTSamp cluster(varlist)            ///
          regcov(varlist) sregcov(varlist) tiecorr]

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
    di as txt "{ralign 40:ROC regression for markers:} {res:`m1lab'} "
    if `nmark' > 1 {
        forvalues i = 2/`nmark' {
            di as res _col(42) "`m`i'lab'"
        }
    }
    if `nregcov' ~= 0 {
        tokenize `regcov'
        forvalues i = 1/`nregcov' {
            local rc`i' "``i''"
            if "`:variable label `rc`i'''" == "" {
                local rc`i'lab "`rc`i''"
            }
            else {
                local rc`i'lab "`:variable label `rc`i'''"
            }
         }
     }
    if `nsregcov' ~= 0 {
        tokenize `sregcov'
        forvalues i = 1/`nsregcov' {
            local src`i' "``i''"
            if "`:variable label `src`i'''" == "" {
                local src`i'lab "`src`i''"
            }
            else {
                local src`i'lab "`:variable label `src`i'''"
            }
         }
     }
    if `nregcov'==0 & `nsregcov'==0 {
        di as txt "{ralign 40:regression model covariates:} {res:none} "
    }
    else {
        if `nregcov'>0  {
            di as txt "{ralign 40:model intercept term covariates:} {res:`rc1lab'} "
            if `nregcov' > 1 {
                forvalues i = 2/`nregcov' {
                    di as res _col(42) "`rc`i'lab'"
                }
            }
        }
        if `nsregcov' > 0 {
            di as txt "{ralign 40:model slope term covariates:} {res:`src1lab'} "
            if `nsregcov' > 1 {
                forvalues i = 2/`nsregcov' {
                    di as res _col(42) "`src`i'lab'"
                }
            }
        }
    }
    di
    di as txt "{ralign 38: percentile value calculation}"
    di as txt "{ralign 40: method:} {res:`pvcmeth'} "
    if "`pvcmeth'" == "empirical" {
        di as txt "{ralign 40: tie correction:} {res:`=cond("`tiecorr'"=="","no","yes")'} "
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
        di as txt "{ralign 45: Covariate adjustment for p.v. calculation:}"
        di as txt "{ralign 40: method:} {res:`adjmlab'} "
        di as txt "{ralign 40: covariates:} {res:`cov1lab'}
        if `ncov' > 1 {
            forvalues i = 2/`ncov' {
                di as res _col(42) "`cov`i'lab'"
            }
        }
        di
        if "`adjmodel'" == "stra" {
            di as txt "{ralign 40: # of case-containing strata:} {res:`nstrat'}"
            di
            lab var `stratn' "stratum"
            ta `stratn' `d'
            di
        }
    }
    local curvlbl = cond("`link'" == "probit","binormal","bilogistic")

    di as txt "{ralign 38: GLM fit of `curvlbl' curve}"
    di as txt "{ralign 40: number of points:} {res:`np'}"
    di as txt "{ralign 40: on FPR interval:} ({res:`a'},{res:`b'})"
    di as txt "{ralign 40: link function:} {res:`link'}"

    if "`bstrap'" == ""  {
        di
        if "`ccsamp'" == "" {
            di in g "  model coefficient bootstrap se's and CI's based on sampling"
            di in g "   separately from cases and controls"
        }
        else {
            di in g "  model coefficient bootstrap se's and CI's based on sampling"
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
        di as txt "{ralign 40: number of bootstrap samples:} {res:`nsamp'}"
    }
    else {
            di
            di in g "  no bootstrap sampling specified.
            di in g "  bootstrap-based se's and CI's for model coefficients will not be calculated."
    }
end
