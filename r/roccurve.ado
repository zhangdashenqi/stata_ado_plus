*! 1.4.6 GML MSP HEJ 09 January 2009
pro def roccurve, rclass
    version 10
    syntax varlist(min=2 numeric) [if] [in],                  ///
         [ roc(real -1) rocinv(real -1)                       ///
           NSamp(integer 1000) noGRaph                        ///
           noCCSamp CLuster(varlist) noSTSamp TIECorr         ///
           PVCMeth(string)                                    ///
           ROCMeth(string) LInk(name)                         ///
           INTerval(numlist min=3 max=3)                      ///
           Level(cilevel) offset(real .006)                   ///
           LPattern(passthru) LColor(passthru)                ///
           LWidth(passthru)                                   ///
           XSIZe(passthru) YSIZe(passthru)                    ///
           ADJCov(varlist numeric) ADJModel(string)           ///
           GENRocvars GENPcv REPLACE  * ]
    gettoken d mlist : varlist
    tokenize `mlist'
    local y1 "`1'"
    local i = 2
    local nmark = 1
    marksample touse, nov   // don't markout missing values for marker variables
    markout `touse' `d' `adjcov'

    while "``i''" ~= "" {    // when there are 2+ marker variable arguments
        local ++nmark
        local y`nmark' "``i''"
        local ++i
        // may need to generate separate touse`i' for each marker variable ?
        //  alternatively - take care of this in subprog calls ?
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
    cap assert inlist("`pvcmeth'","empirical","normal","")
    if _rc ~= 0  {
        di in red `"PVCmeth( ) option must be either "empirical" or "normal" "'
        di        "    if specified"
        error 198
    }
    if "`pvcmeth'" == "" local pvcmeth "empirical"  // default

    cap assert inlist("`rocmeth'","nonparametric","parametric","")
    if _rc ~= 0  {
        di in red `"rocmeth( ) option must be either "nonparametric" or "parametric" "'
        di        "    if specified"
        error 198
    }

    cap assert inlist("`link'","probit","logit","")
    if _rc ~= 0  {
        di in red `"LInk( ) option must be either "probit" or "logit" "'
        di        "    if specified"
        error 198
    }
    if "`link'" == "" local link "probit"  // default

    // check roc() and rocinv() syntax, and set ci and inverse flags

    cap assert  !(`roc'~=-1 & `rocinv'~=-1)
    if _rc ~= 0  {
        di in red `"only one of roc(f) and rocinv(t) options can be specified"'
        error 198
    }
    if `roc' ~= -1 {
        local ci ci
        cap assert (`roc' > 0 & `roc' < 1)
        if _rc ~= 0  {
            di in red `"roc(f) option must be 0 < f < 1, if specified"'
            error 198
        }
    }
    if `rocinv' ~= -1 {
        local ci ci
        local inverse inverse
        cap assert (`rocinv' > 0 & `rocinv' < 1)
        if _rc ~= 0  {
            di in red `"rocinv(t) must be option must be 0 < t < 1, if specified"'
            error 198
        }
    }
    if "`ci'" ~= "" {
        cap assert inrange(`offset',0,.02)
        if _rc ~= 0 {
            di in red `"offset(#) argument must be between 0 and .02 if specified"
            error 198
        }
        cap assert `nsamp' > 1
        if _rc ~= 0 {
            di in red `"nsamp(#) argument must be > 1 if specified"
            error 198
        }
    }

    // check interval() option arguments if specified, otherwise assign defaults
    if "`rocmeth'" == "parametric" {
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
        else {  // default interval and number of points when rocmeth is parametric
            local a  = 0
            local b  = 1
            local np = 10
        }
        local xlb_arg "xlb(`a')"
        local xub_arg "xub(`b')"
    }
    else {
        // sham arguments for -displres- & -rocbs-
        local a = 1
        local b = 1
        local np = 1
        if "`rocmeth'" == "" local rocmeth "nonparametric"  // default
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

    forvalues i = 1/`nmark' {
        tempvar plcv`i'
        getpcv `y`i'' `d' if `touse', pcvar(`plcv`i'') adjust(`adjust') pvcmeth(`pvcmeth') ///
               markn(`i') obs(1) `tiecorr' `getpcvopts'
        qui replace `plcv`i'' = 1 - `plcv`i''
        local xlist "`xlist' `plcv`i''"
    }

    if "`rocmeth'" == "parametric" {
        // need to generate a 2x`nmark' matrix to hold alpha_0 and alpha_1
        tempname BNmat
        getbnparm if `touse', nmark(`nmark') plcv(`xlist') bnmatr(`BNmat') ///
                link(`link') d(`d') b(`b') a(`a') np(`np')
        local bnmat_arg "bnmat(`BNmat')"
    }
    else  {  // i.e.  "`rocmeth'" == "nonparametric"
        forvalues i = 1/`nmark' {
            tempvar cplcv`i'
            cdf `plcv`i'' if `touse' & `d'==1, cdfvar(`cplcv`i'')
            local ylist "`ylist' `cplcv`i''"
        }
    }

    // bootstrap CI's:

    if "`ci'" ~= "" {

        tempname CImat     //  matrix to hold CI estimates
        mat `CImat' = J(`nmark',3,.)

        if "`cluster'" ~= "" {
            local cluster "cluster(`cluster')"
        }
        forvalues i = 1/`nmark' {
            rocbs `y`i'' `d' if `touse', t(`roc') v(`rocinv')              ///
                  nsamp(`nsamp') `ccsamp' `inverse'                        ///
                  adjust(`adjust') pvcmeth(`pvcmeth')                      ///
                  rocmeth(`rocmeth') link(`link') b(`b') a(`a') np(`np')   ///
                  `stsamp' `tiecorr' `getpcvopts'                          ///
                  level(`level') `cluster'

            mat `CImat'[`i',1] = r(roctv)
            mat `CImat'[`i',2] = r(roctv_lb)
            mat `CImat'[`i',3] = r(roctv_ub)
            local cimat_arg "cimat(`CImat')"
        }
    }

    local xlist_arg "x(`xlist')"
    local ylist_arg "y(`ylist')"

    if "`graph'" == "" {     // the default.  otherwise == nograph
        rocplt `mlist' if `touse', nmark(`nmark')                ///
             rocmeth(`rocmeth') link(`link')                     ///
             `xlist_arg' `ylist_arg' `ci' t(`roc') v(`rocinv')   ///
             `inverse' offset(`offset')                          ///
             `lpattern' `lcolor' `lwidth' `xsize' `ysize'        ///
             `cimat_arg' `bnmat_arg'                             ///
             `xlb_arg' `xub_arg' `bw' `options'
    }

    if "`genrocvars'" != "" {  save roc coordinate variables
        genrocv if `touse', nmark(`nmark') d(`d') `xlist_arg' `ylist_arg'  ///
              rocmeth(`rocmeth') link(`link') `bnmat_arg' `replace'
    }
    if "`genpcv'" != "" {  save percentile value variables
        genpcv, nmark(`nmark') `xlist_arg' `replace'
    }

    displres, nmark(`nmark') mlist(`mlist') d(`d')       ///
          rocmeth(`rocmeth') link(`link')                ///
          a(`a') b(`b') np(`np')                         ///
          roct(`roc') rocv(`rocinv') `inverse'           ///
          nsamp(`nsamp') level(`level')                  ///
          adjust(`adjust') pvcmeth(`pvcmeth')            ///
          `getpcvopts' `ci' `ccsamp' `stsamp' `tiecorr'  ///
          `cimat_arg' `bnmat_arg'

    if "`rocmeth'" == "parametric" {
        forvalues i = 1/`nmark' {
            local rownames "`rownames'`y`i'' "
        }
        matrix rownames `BNmat' = `rownames'
        matrix colnames `BNmat' = alpha_0 alpha_1
        return matrix BNParm = `BNmat'
    }
    if "`ci'" ~= "" {
        if "`rocmeth'" ~= "parametric" {
            forvalues i = 1/`nmark' {
                local rownames "`rownames'`y`i'' "
            }
        }
        matrix rownames `CImat' = `rownames'
        if "`inverse'" == "" {
            matrix colnames `CImat' = roc_f roc_lb roc_ub
        }
        else {
            matrix colnames `CImat' = rocinv_t rocinv_lb rocinv_ub
        }
        return matrix ROC_ci = `CImat'
    }
end
***********************
pro def getpcv
    /* called by both main prog and -roct- subprog */
    syntax varlist(min=2 max=2 numeric) [if] [in], pcvar(string) [REPLACE] ///
        adjust(integer) pvcmeth(string) markn(int) obs(int)                ///
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
pro def getbnparm
    /* get parameter estimates for parametric curve */
    syntax [if] [in], nmark(int) plcv(varlist numeric min=1) bnmatr(string) ///
           d(varname) link(name) b(real) a(real) np(integer)
    marksample touse
    preserve
    tempvar uid f x k
    qui {
        mat `bnmatr' = J(`nmark',2,.)
        gen `uid' = _n
        expand `np' if `d'==1 & `touse'
        bys `uid': gen `k' = _n if `d'==1 & `touse'
        gen `f' = `a' + `k'*((`b'-`a')/(`np' + 1))
        gen `x' = cond("`link'" == "probit",invnorm(`f'),logit(`f'))
        tokenize `plcv'
        forvalues i = 1/`nmark' {
            local plcv`i' "``i''"    // not strictly necessary
            tempvar u
            gen `u' = ( (`plcv`i'')<= `f') if ~missing(`f',`plcv`i'')
            `link' `u' `x'
            mat `bnmatr'[`i',1] = _b[_cons]
            mat `bnmatr'[`i',2] = _b[`x']
            drop `u'
        }
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
pro def rocbs, rclass
    // -bootstrap- won't recognize subprogram called with :command argument, so
    //    will have to do lower level bootstrap
    // get bootstrap CI's for ROC(t), specified t argument
    //   or ROC_inverse(v) if inverse option is specified
    syntax varlist(min=2 max=2) [if] [in], t(real) v(real) nsamp(real) ///
        adjust(integer) pvcmeth(string)                                ///
        rocmeth(string) link(name) a(real) b(real) np(integer)         ///
        [ adjmodel(string) adjcov(varlist) nstrat(integer 0) stratn(varname)  ///
          inverse tiecorr noCCSamp noSTSamp cluster(varlist) ] level(cilevel)
    preserve //  will need to drop unused obs and vars for bootstrap
    tokenize `varlist'
    local m "`1'"
    local d "`2'"
    marksample touse
    qui keep if `touse'
    qui keep `m' `d' `adjcov' `stratn' `cluster'
    tempfile obsfile resfile
    tempname pfile

    qui save `obsfile'
    if "`adjmodel'" == "stra" {
        if "`stsamp'" == "" | "`ccsamp'" == "" {
            if "`stsamp'" == "" {
                if "`ccsamp'" == "" {
                    local stratarg "strata(`d' `adjcov')"  // this is the default
                }
                else {
                    local stratarg "strata(`adjcov')"
                }
            }
            else {
                local stratarg "strata(`d')"
            }
        }
    }
    else {  //  i.e. NOT stratified covariate adjustment
        if "`ccsamp'" == "" {     // the default.  otherwise == noccsamp
            local stratarg "strata(`d')"
        }
    }
    if "`cluster'" ~= ""{
        local cluster "cluster(`cluster')"
    }
    if `adjust' == 1 {
        local getpcvopts "adjmodel(`adjmodel') adjcov(`adjcov')"
    }
    if "`adjmodel'" == "stra" {
        local getpcvopts "`getpcvopts' nstrat(`nstrat') stratn(`stratn')"
    }

    postfile `pfile' roctv using `resfile'

    // observed sample
    roct `m' `d', t(`t') v(`v') `inverse' adjust(`adjust')       ///
          pvcmeth(`pvcmeth') `getpcvopts' `tiecorr'              ///
          rocmeth(`rocmeth') link(`link') b(`b') a(`a') np(`np')

    post `pfile' (`r(roctv)')

    forvalues i = 1/`nsamp' {
        qui {
            use `obsfile', clear
            bsample, `stratarg' `cluster'
            roct `m' `d', t(`t') v(`v') `inverse' adjust(`adjust')        ///
                  pvcmeth(`pvcmeth') `getpcvopts' `tiecorr'               ///
                  rocmeth(`rocmeth') link(`link') b(`b') a(`a') np(`np')
            post `pfile' (`r(roctv)')
        }
    }
    postclose `pfile'
    qui use `resfile',clear
    local x = roctv[1]       /* first obs is from observed data */
    char roctv[bstrap] `x'
    qui drop in 1
    qui save `resfile', replace
    qui bstat using `resfile', level(`level')
    ret sca roctv = _b[roctv]
    tempname PCCI
    matrix `PCCI' = e(ci_percentile)
    ret sca roctv_lb = `PCCI'[1,1]
    ret sca roctv_ub = `PCCI'[2,1]
end
***********************
pro def roct, rclass
    // program to obtain roc(t) or roc_inverse(v) for a single sample
    //  should a trimmed down version if this subprog be written
    //  for more efficient execution when called by -rocbs-, as
    //  if, in, and touse restrictions are unnecessary in this case
    syntax varlist(min=2 max=2) [if] [in], t(real) v(real)      ///
        rocmeth(string) link(name) a(real) b(real) np(integer)  ///
        adjust(integer) pvcmeth(string) [ inverse tiecorr *]

    tokenize `varlist'
    local m "`1'"
    local d "`2'"
    marksample touse
    tempvar plcv cplcv

    getpcv `m' `d' if `touse', pcvar(`plcv') adjust(`adjust') pvcmeth(`pvcmeth') ///
               obs(0) markn(1) `tiecorr' `options'
    qui replace `plcv' = 1 - `plcv'

    if "`rocmeth'" == "parametric" {
        // need to generate a 2x`nmark' matrix to hold alpha_0 and alpha_1
        tempname BNmat
        getbnparm if `touse', nmark(1) plcv(`plcv') bnmatr(`BNmat') ///
                link(`link') d(`d') b(`b') a(`a') np(`np')

        if "`inverse'" == "" {
            if "`link'" == "probit" {
                return scalar roctv = normal(`=`BNmat'[1,1]' + `=`BNmat'[1,2]' * invnorm(`t'))
            }
            else {   // i.e. link is logit
                return scalar roctv = invlogit(`=`BNmat'[1,1]' + `=`BNmat'[1,2]' * logit(`t'))
            }
        }
        else {   // i.e. inverse ROC(v)
            if "`link'" == "probit" {
                return scalar roctv = normal((invnorm(`v') - `=`BNmat'[1,1]')/`=`BNmat'[1,2]')
            }
            else {   // i.e. link is logit
                return scalar roctv = invlogit((logit(`v') - `=`BNmat'[1,1]')/`=`BNmat'[1,2]')
            }
        }
    }
    else  {  // i.e.  "`rocmeth'" == "nonparametric"
        tempvar cplcv`i'
        cdf `plcv' if `touse' & `d'==1, cdfvar(`cplcv')
        if "`inverse'" == "" {
            qui sum `cplcv' if `touse' & `plcv' <= `t', meanonly
            if r(N) != 0 {
                return scalar roctv = r(max)
            }
            else {   // true when more than t*100 % of controls have largest marker values
                return scalar roctv = 0
            }
        }
        else {   // i.e. inverse ROC, ROC^(-1)(v)  (defn changed with vers 1.4.1)
            //  smallest p s.t. the [proportion of cases with plcv <= p] >= v
            //   (no longer need to fill in cplcv's for controls with v 1.4.1)
            qui sum `plcv' if `cplcv' >= `v' & `cplcv' ~=. & `touse', meanonly
            if r(N) != 0 {
                return scalar roctv = r(min)
            }
            else {
                return scalar roctv = 1
            }
        }
    }
end
***********************
pro def genrocv
    // generate new variables to hold ROC coordinate variables
    syntax [if], nmark(int) d(varname numeric)        ///
            rocmeth(string) link(name) x(varlist numeric)        ///
            [ bnmat(string)                           ///
              y(varlist numeric) REPLACE]
    marksample touse
    if "`replace'" ~= "" {
        forvalues i = 1/`nmark' {
            cap drop tpr`i' fpr`i'
        }
    }
    forvalues i = 1/`nmark' {
        cap confirm new variable tpr`i' fpr`i'
        if _rc~=0 {
            di in red "variable tpr`i' or fpr`i' already exists,"
            di in red `"  use "replace" option to replace existing variables "'
            error _rc
        }
    }
    tokenize `x'

    if "`rocmeth'" == "parametric" {
        forvalues i = 1/`nmark' {
            qui gen fpr`i' = ``i'' if `touse'
            if "`link'" == "probit" {
                qui gen tpr`i' = normal(`bnmat'[`i',1] + `bnmat'[`i',2] * invnorm(fpr`i')) if `touse'
            }
            else {   // i.e. link is logit
                qui gen tpr`i' = invlogit(`bnmat'[`i',1] + `bnmat'[`i',2] * logit(fpr`i')) if `touse'
            }
        }
    }
    else {
        tempvar tpfgp
        forvalues i = 1/`nmark' {
            qui gen fpr`i' = ``i'' if `touse'
        }
        tokenize `y'
        forvalues i = 1/`nmark' {
            qui {
                gen tpr`i' = ``i'' if `d' == 1
                gsort `touse' fpr`i' -`d'
                gen `tpfgp' = sum(`d') if `touse' == 1
                bys `touse' `tpfgp' (`d'): replace tpr`i' = tpr`i'[_N] if `d'==0 & `touse'
                replace tpr`i' = 0 if `tpfgp' == 0
                drop `tpfgp'
            }
        }
    }
end
***********************
pro def genpcv
    // generate new variables to hold percentile values
    syntax, nmark(int) x(varlist numeric min=1) [REPLACE]

    if "`replace'" ~= "" {
        forvalues i = 1/`nmark' {
            cap drop pcv`i'
        }
    }
    forvalues i = 1/`nmark' {
        cap confirm new variable pcv`i'
        if _rc~=0 {
            di in red "variable pcv`i' already exists,"
            di in red `"  use "replace" option to replace existing variables "'
            error _rc
        }
    }
    tokenize `x'
    forvalues i = 1/`nmark' {
        gen pcv`i' = 1 - ``i''
    }
end
***********************
pro def rocplt, rclass
    /*  should plot commands for each (x,y) pair be restricted to distinct pairs?
         - i.e. will this make for faster graph execution with large
         datasets? - enough to outweigh cost of generating a restriction (touse) variable
         for each pair of vars? */

    syntax varlist(min=1 numeric) [if] [in],     ///
           rocmeth(string) link(name) t(real)    ///
           v(real) nmark(int) offset(real)       ///
           [ x(varlist numeric min=1)            ///
             y(varlist numeric min=1)            ///
             CI cimat(string) inverse            ///
             xlb(real 0) xub(real 1)             ///
             lpattern(namelist) lcolor(namelist) ///
             lwidth(namelist)                    ///
             xsize(real 0) ysize(real 0)         ///
             bnmat(string) * ]
    preserve // since we are adding records to the dataset
    marksample touse, nov
    tempvar zero1rec
    local mlist "`varlist'"

    * add records for origin (0,0) & (1,1)
    qui gen byte expn = _n==1
    qui expand 3 if expn
    sort expn
    qui by expn : gen `zero1rec' = (_n-1) if expn==1 & _n<3
    qui replace `touse' = 1 if ~missing(`zero1rec')

    local fxn_lb = cond(`xlb'==0,1e-7,`xlb')
    local fxn_ub = cond(`xub'==1,1-1e-7,`xub')

    // generate label list and labels from markers for title and legend, respectively:
    tokenize `mlist'

    forvalues i = 1/`nmark' {
        local m`i' "``i''"
        if "`:variable label `m`i'''" == "" {
            local m`i'lab "`m`i''"
        }
        else {
            local m`i'lab "`:variable label `m`i'''"
        }
        local lgndlbl: di `"`lgndlbl' lab(`i' "`m`i'lab'")"'
        local lgndordr "`lgndordr' `i'"

        if `i' == 1 {  // is there a more elegant way to avoid an initial comma?
            local mlablist "`m`i'lab'"
        }
        else {
            local mlablist "`mlablist', `m`i'lab'"
        }
    }

    // tokenize lcolor() and lpattern() options, so that these can be included in
    //     each of the twoway component -line- commands
    //  may wish to add other connect options later?

    if "`lpattern'" ~= "" {
        local i = 1
        tokenize `lpattern'
        while "``i''" ~= "" {
            local lp`i' "lp(``i'')"
            local ++i
        }
    }
    if "`lcolor'" ~= "" {
        local i = 1
        tokenize `lcolor'
        while "``i''" ~= "" {
            local lc`i' "lc(``i'')"
            local ++i
        }
    }
    if "`lwidth'" ~= "" {
        local i = 1
        tokenize `lwidth'
        while "``i''" ~= "" {
            local lw`i' "lw(``i'')"
            local ++i
        }
    }

    // If only one of xsize() and ysize() are specified, calculate the other
    //     s.t. 7x5 graph region aspect ratio is maintained.
    // If neither is specified, defaults are xsize(7) and ysize(5).
    // Override of both is allowed.

    if `xsize' == 0 {
        if `ysize' == 0 {
            local xsize = 7
            local ysize = 5
        }
        else {
            local xsize = (7/5) * `ysize'
        }
    }
    else {
        if `ysize' == 0 {
            local ysize = (5/7) * `xsize'
        }
    }

    if "`rocmeth'" == "nonparametric" {
        tokenize `y'
        forvalues i = 1/`nmark' {
            local y`i' "``i''"
            qui replace `y`i'' = `zero1rec' if ~missing(`zero1rec')
        }
        tokenize `x'
        forvalues i = 1/`nmark' {
            local x`i' "``i''"
            qui replace `x`i'' = `zero1rec' if ~missing(`zero1rec')
            if `i' == 1 {
                local sep ""
            }
            else {
                local sep "||"
            }

            local line`i' `sep' line `y`i'' `x`i'' if `touse', `lc`i'' `lp`i'' ///
                  lw(medthick) `lw`i'' c(J) sort(`x`i'' `y`i'')

            local lines `lines' `line`i''
        }
    }
    else {   // parametric ROC option

        forvalues i = 1/`nmark' {
            local a0_`i' = `bnmat'[`i',1]
            local a1_`i' = `bnmat'[`i',2]
            if `i' == 1 {
                local sep ""
            }
            else {
                local sep "||"
            }

            if "`link'" == "probit" {
                local line`i' `sep' function y = normal(`a0_`i'' + `a1_`i''*invnorm(x)), ///
                   range(`fxn_lb' `fxn_ub') lw(medthick) `lw`i'' `lc`i'' `lp`i''
            }
            else { // i.e. logit link
                local line`i' `sep' function y = invlogit(`a0_`i'' + `a1_`i''*logit(x)), ///
                   range(`fxn_lb' `fxn_ub') lw(medthick) `lw`i'' `lc`i'' `lp`i''
            }

            local lines `lines' `line`i''
        }
    }

    if "`ci'" ~= ""  {
        local cicolor "gs6"
        foreach vname in roc_lb roc_ub roc_tv roc_est {
            tempname `vname'
            qui gen ``vname'' = .
        }
        forvalues i = 1/`nmark' {
            qui {
                replace `roc_tv'  = cond("`inverse'"=="",`t',`v') + `offset'*int(`i'/2)*(-1)^`i' in `i'
                replace `roc_lb'  = `cimat'[`i',2] in `i'
                replace `roc_ub'  = `cimat'[`i',3] in `i'
                replace `roc_est' = `cimat'[`i',1] in `i'
            }
        }
        if "`inverse'" == "" {
            local roc_ci "|| rcap `roc_ub' `roc_lb' `roc_tv', lc(`cicolor') lw(.04) msiz(1.3)"
            local roc_pt "|| scatter `roc_est' `roc_tv', connect(none) ms(o) msize(1) mlc(`cicolor')"
        }
        else {
            local roc_ci "|| rcap `roc_ub' `roc_lb' `roc_tv', horizontal lc(`cicolor') lw(.04) msiz(1.3)"
            local roc_pt "|| scatter `roc_tv' `roc_est', connect(none) ms(o) msize(1) mlc(`cicolor')"
        }
    }

    if `nmark' == 1 {
            local mrkstr: display "marker: `mlablist'"
    }
    else {
        local mrkstr: display "markers: `mlablist'"
    }
    // forty-five:
    // tempvar forty5
    // qui bys `touse' (`x1'): gen `forty5' = `x1' if (_n==1 | _n==_N) & `touse'
    local lines "`lines' || line `zero1rec' `zero1rec', lcolor(gs12) clw(medium) lp(solid) "

    #delimit ;
    local legend `"
        legend(ring(1) position(3)
              title("marker", size(4) margin(b=2))
              order(`lgndordr')
              `lgndlbl'
              symx(*.6)
              cols(1) bmargin(l=7)
              keygap(3)
              rowgap(1.3)
              size(2.8)
              region(lstyle(none) margin(l=3 r=3)) ) "'
    ;

twoway  `lines'
        `roc_ci' `roc_pt'
        xlab(0 1) ylab(0 1, angle(horizontal))
        xline(0(.2)1,lstyle(grid) lw(.02) lcolor(gs13))
        yline(0(.2)1,lstyle(grid) lw(.02) lcolor(gs13))
        ytitle(TPR, size(4) justification(center) orientation(horizontal))
        yscale(titlegap(1.5))
        xtitle(FPR, size(4) justification(center) margin(b=0))
        xscale(r(0 1) titlegap(1.5))
        title("`mrkstr'", margin(t=2 b=5) size(4.7) justification(center) bexpand)
        `legend'
        xsize(`xsize') ysize(`ysize')
        aspectratio(1)
        plotregion(margin(l=2 r=2 t=2 b=2) )
        graphregion(/* margin(l=4 b=0) */ )
        /* name(`gfile', replace) */
        `options'
    ;
    #delimit cr
end
*******************
pro def displres,
    syntax, nmark(int) mlist(varlist) d(varname)         ///
        rocmeth(string) link(name)                       ///
        a(real) b(real) np(integer)                      ///
        roct(real) rocv(real) nsamp(real) level(cilevel) ///
        adjust(integer) pvcmeth(string)                  ///
        [ adjmodel(string) adjcov(varlist)               ///
          nstrat(integer 0) stratn(varname)              ///
          CI inverse noCCSamp noSTSamp cluster(varlist)  ///
          cimat(string) bnmat(string) tiecorr]

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
    if "`ci'" == "" {  // list markers, otherwise displayed with roc(t) CI results
        di as txt "{ralign 40:ROC calculation for markers:} {res:`m1lab'} "
        if `nmark' > 1 {
            forvalues i = 2/`nmark' {
                di as res _col(42) "`m`i'lab'"
            }
        }
    }

    if "`rocmeth'" == "nonparametric" {
        local methlbl "non-parametric (Empirical ROC)"
    }
    else {
        local methlbl "parametric"
        if "`link'" == "probit" {
            local linklbl "probit - binormal ROC"
        }
        else {
            local linklbl "logit - bilogistic ROC"
        }
    }

    di
    di as txt "{ralign 40: ROC method:} {res:`methlbl'} "
    if "`rocmeth'" == "parametric" {
        di
        di as txt "{ralign 38: GLM fit} "
        di as txt "{ralign 40: link function:} {res:`linklbl'} "
        di as txt "{ralign 40: number of points:} {res:`np'}"
        di as txt "{ralign 40: on FPR interval:} ({res:`a'},{res:`b'})"
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
        }
    }
    if "`ci'" ~= "" {  // display roc(t) CI results
        di
        di as txt "************"
        di
        if "`inverse'" == "" {  // i.e. roc(f)
            di in text "                      {c |}      ROC     {c |}  "%3.0f `level' "% Confidence"
            di in text "           Marker     {c |}  @ f =" %5.2f `roct' "  {c |}      Interval"
        }
        else {  // ROC_inverse at t
            di in text "                      {c |}    ROC^(-1)  {c |}  "%3.0f `level' "% Confidence"
            di in text "           Marker     {c |}  @ t =" %5.2f `rocv' "  {c |}      Interval"
        }
        di in text "  {hline 20 }{c +}{hline 14}{c +}{hline 19}"
        forvalues i = 1/`nmark' {
           di as txt _col(3) %19s abbrev("`m`i'lab'",19) " {c |} "     ///
              as res _col(29) %4.3f `=`cimat'[`i',1]' as txt "    {c |}  "      ///
              as res _col(41) "( " %4.3f `=`cimat'[`i',2]'             ///
              ", " %4.3f `=`cimat'[`i',3]' " )"
        }
        di
        di
        if "`ccsamp'" == "" {
            di in g "  bootstrap percentile CI's based on sampling"
            di in g "   separately from cases and controls"
        }
        else {
            di in g "  bootstrap percentile CI's based on sampling"
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
    }
end
