*! version 1.9.4 2012-07-25 bug in mprobit noted; format fix

capture program drop listcoef
program define listcoef, rclass

    version 9 // 2007-06-29
    * 15Jun2005 - new labels used in Stata 9
    if c(stata_version) >= 9 {
        tempname tmpb
        mat `tmpb' = e(b)
        local tmpcut : colnames `tmpb'
        if index("`tmpcut'", "_cut1") != 0 {
            local cut "_"
        }
        else {
            local cut "/"
        }
    }
    else {
        local cut "_"
    }

    version 6.0
    tempname b b1 b12 b2 bnocon bnocon2 bout bs bs2 bsx bsx2 bsy
    tempname bsy2 btmp con2 conp2 contst2 dft eb eb2
    tempname bx ebx ebx2 enf factr lc lnalpha lr nobs nxtrow nxtsdx o
    tempname one outb outb2 outbs outbsx outbsy outcon outeb outeb2 outebx
    tempname outebx2 outmat outp outp2 outpb outpb2 outpbx outpbx2 outsdx
    tempname outse outvx outz outz2 p p2 pb pb2 pbx pbx2 pct pctsd pcutoff
    tempname prntit r2 rec_se resvec sd sd2 sdb sdb2 sdx sdx2 sdy sdyobs
    tempname sdystar se st talpha v vare vi vx vx2 z zval zval2
    tempname mconb mcontz mconp

    local noprint = "yes"  /* keeps track if no results are printed */
    local cmd "`e(cmd)'"

    capture version 7
        if _rc!=0 {
            local vers7 "no"
            local smcl ""
            local dash "-"
            local vline "|"
            local plussgn "+"
            local topt "-"
            local bottomt "-"
        }
        else {
            local vers7 "yes"
            local smcl "in smcl "
            local dash "{c -}"
            local vline "{c |}"
            local plussgn "{c +}"
            local topt "{c TT}"
            local bottomt "{c BT}"
        }
    version 6.0

    if "`cmd'" == "" {
        di _n in y "listcoef "/*
        */ in r "must be run after your regression model is estimated."
        exit
    }

    syntax [varlist(default=none)] /*
    */ [, PValue(real 0) Factor Percent Matrix Help /*
    */ Constant Odds Std Reverse gt lt ADJacent NOLabel EXpand /*
    */ Delta(real 1)]

*-> define characteristics of each model to be listed
*
*   coeftyp: which types of coefficients can be computed
*     - bx  beta x std
*     - by  beta y std
*     - bxy beta xy std
*     - eb  exp(beta)
*     - ebx exp(beta x std)
*     - %b  %
*     - %bx % xstd
*     - byopt
*   modltyp: model class
*     - tdist: use t not z for p-values
*     - count: count model
*     - zero: zero-inflated model
*     - ystar: latent dependent variable
*     - ystd:
*     - special: own loop for calculating odds/std coefs
*     - nosdx: do not report sdx
*     - nocon: do not allow constant option
*   defhead: default header type
*     - std
*     - odds
*     - count

    if "`cmd'" == "regress" {
        local coeftyp "bx by bxy"
        local modltyp "tdist ystd"
        local defhead "std"
    }
    if   "`cmd'" == "logit" | "`cmd'" == "logistic" /*
    */ | "`cmd'" == "ologit" {
        local coeftyp "eb ebx byopt %b %bx bx by bxy"
        local modltyp "ystar ystd reverse"
        local defhead "odds"
    }
    if "`cmd'" == "probit" | "`cmd'" == "oprobit" {
        local coeftyp "bx by bxy"
        local modltyp "ystar ystd"
        local defhead "std"
    }
    if "`cmd'" == "cloglog" {
        local coeftyp "bx"
        local modltyp ""
        local defhead "std"
    }
    if "`cmd'" == "mlogit" {
        local coeftyp "eb ebx byopt %b %bx"
        local modltyp "special nocon"
        local defhead "odds"
    }
    * 28Feb2005
    if "`cmd'" == "mprobit" {
di in red "Note: We are currently fixing a bug with mprobit. Contact"
di in red "jslong@indiana.edu for details."
exit        
        local coeftyp "bx"
        local modltyp "special nocon"
        local defhead "std"
    }
    * 23Mar2005
    if "`cmd'" == "slogit" {
        local coeftyp "eb ebx byopt %b %bx" // no bx??
        local modltyp "nocon"
        local defhead "odds"

        * do not allow if more than 1 dimension
        if e(k_dim) != 1 {
        di as err "listcoef only works for the one dimensional model slogit model"
            exit
        }
        * outcome categories must not have skips
        tempname slcat
        mat `slcat' = e(outcomes)
        local slncat = e(k_out)
        local c1 = `slcat'[1,1]
        foreach i of numlist 2/`slncat'  {
            local c1p1 = `c1' + 1
            local c2 = `slcat'[`i',1]
            if `c2'!=`c1p1' {
            di as err ///
            "listcoef with slogit does not allows skips in outcome categories."
                exit
            }
          local c1 = `c2'
        }
    }

    if "`cmd'" == "clogit" | "`cmd'" == "rologit" {
        local coeftyp "eb byopt %b"
        local modltyp "nosdx nocon reverse"
        local defhead "odds"
    }
    if "`cmd'" == "tobit" | "`cmd'" == "cnreg" /*
    */ | "`cmd'" == "intreg" {
        local coeftyp "bx by bxy"
        local modltyp "tdist ystar ystd"
        local defhead "std"
    }
    *050207 - ztp and ztnb
    *    if "`cmd'" == "poisson" | "`cmd'" == "nbreg" {
    if "`cmd'" == "poisson" | "`cmd'" == "nbreg" ///
        | "`cmd'" == "ztp" | "`cmd'" == "ztnb" {
        local coeftyp "eb ebx byopt %b %bx"
        local modltyp "count"
        local defhead "count"
    }
    if "`cmd'" == "zip" | "`cmd'" == "zinb" {
        local coeftyp "eb ebx byopt %b %bx"
        local modltyp "count zero"
        local defhead "count"
    }

    * exit out of non-supported commands
    if "`coeftyp'" == "" {
        di _n in r "listcoef does not work with models estimated with `e(cmd)'"
        exit
    }

    * 050123 contant in model?
    _penocon
    local isnocon = r(nocon)

*-> unpack coeftyp

    local defopt = "yes"
    local countto : word count `coeftyp'
    local count = 1
    while `count' <= `countto' {
        local token : word `count' of `coeftyp'
        if "`token'" == "bx" { local dobx "`defopt'" }
        if "`token'" == "by" { local doby "`defopt'" }
        if "`token'" == "bxy" { local dobxy "`defopt'" }
        if "`token'" == "%b" { local dopb "`defopt'" }
        if "`token'" == "%bx" { local dopbx "`defopt'" }
        if "`token'" == "eb" { local doeb "`defopt'" }
        if "`token'" == "ebx" { local doebx "`defopt'" }
        if "`token'" == "byopt" { local defopt "option" }
        local count = `count' + 1
    }

*-> parse options and check for errors

    local opterr "no"
    if "`std'" == "std" {
        if "`dobx'"=="option" { local dobx "yes" }
        else if "`dobx'" == "" { local opterr "std" }
        if "`doby'"=="option" { local doby "yes" }
        if "`dobxy'"=="option" { local dobxy "yes" }
        if "`cmd'" == "ologit" { local defhead "std" }
        * if std, don't list these
        local doeb ""
        local doebx ""
        local dopb ""
        local dopbx ""
    }

    if "`percent'" == "percent" & "`factor'" == "factor" {
        di in r "options " in y "percent" in r " and " in y "factor" /*
        */ in r " cannot both be specified together"
        exit 198
    }
    if "`std'" == "std" & "`factor'" == "factor" {
        di in r "options " in y "std" in r " and " in y "factor" /*
        */ in r " cannot both be specified together"
        exit 198
    }
    if "`std'" == "std" & "`percent'" == "percent" {
        di in r "options " in y "std" in r " and " in y "percent" /*
        */ in r " cannot both be specified together"
        exit 198
    }
    if "`percent'" == "percent" {
        if "`dopb'"=="option" {
            local dopb "yes"
            if "`doeb'"=="yes" { local doeb "" }
        }
        else if "`dopb'" == "" { local opterr "percent" }
        if "`dopbx'"=="option" {
            local dopbx "yes"
            if "`doebx'"=="yes" { local doebx "" }
        }
    }
    if "`factor'" == "factor" {
        if "`doeb'"=="option" {
            local doeb "yes"
            if "`dopb'"=="yes" { local dopb "" }
        }
        else if "`doeb'" == "" { local opterr "odds" }
        if "`doebx'"=="option" {
            local doebx "yes"
            if "`dopbx'"=="yes" { local dopbx "" }
        }
    }
    if "`opterr'" != "no" {
        di in r "option " in y "`opterr'" in r " not allowed after " in y "`cmd'"
        exit 198
    }

*-> unpack mldtyp: define what to do for each type of model

    if index("`modltyp'", "tdist") == 0 { local tz "z" }
        else { local tz "t" }
    if index("`modltyp'", "count") == 0 { local iscount "no" }
        else { local iscount "yes" }
    if index("`modltyp'", "zero") == 0 { local iszero "no" }
        else { local iszero "yes" }
    if index("`modltyp'", "ystar") == 0 { local isystar "no" }
        else { local isystar "yes" }
    if index("`modltyp'", "ystd") == 0 { local isystd "no" }
        else { local isystd "yes" }
    if index("`modltyp'", "special") == 0 { local isspec "no" }
        else { local isspec "yes" }
    if index("`modltyp'", "nosdx") == 0 { local isnosdx "no" }
        else { local isnosdx "yes" }
    if index("`modltyp'", "nocon") == 0 { local iscon "yes" }
        else { local iscon "no" }
    if index("`modltyp'", "reverse") == 0 { local isrev "no" }
        else { local isrev "yes" }

    if "`constant'"!="" & "`iscon'"=="no" {
        di in y "constant" in r " option not allowed for this model"
        exit 198
    }
    if "`reverse'"!="" & "`isrev'"=="no" {
        di in y "reverse" in r " option not allowed for this model"
        exit 198
    }

*-> add checks for any special cases

    * zip/zinb only work with logit inflation
    if "`cmd'"=="zip" | "`cmd'"=="zinb" {
        if "`e(inflate)'"!="logit" {
            di _n in y "listcoef " in r "requires " in y "logit " /*
            */ in r "inflation for " in y "`cmd'"
            exit 198
        }
    }

*-> get basic model information

    scalar `nobs' = e(N)
    local lhsnm "`e(depvar)'"
    * -intreg- has two lhs vars; select only 1st one
    if "`cmd'"=="intreg" {
        local lhsnm2 : word 2 of `lhsnm'
        local lhsnm : word 1 of `lhsnm'
    }

    * information on rhs variables
    _perhs
    local rhsnam "`r(rhsnms)'"
    local rhsnum "`r(nrhs)'"

    if "`iszero'"=="yes" {
        local rhsnam2 "`r(rhsnms2)'"
        local rhsnum2 "`r(nrhs2)'"
    }

    * information on outcome categories
    _pecats

    local ncats = r(numcats)
    if "`cmd'"=="logit" | "`e(cmd)'"=="logistic" | "`e(cmd)'"=="clogit" {
        local nm1 : word 2 of `r(catnms8)'
        local nm2 : word 1 of `r(catnms8)'
    }
    * >m & <=m for ologit
    if "`cmd'" == "ologit" {
        local nm1 ">m"
        local nm2 "<=m"
    }

    * 16Jun2005 - ranked ahead and ranked behind for rologit
    if "`cmd'" == "rologit" {
        local nm1 "ranked ahead"
        local nm2 "ranked behind"
    }

    * 05Apr2005 - grab all needed info about slogit
    version 9
    if "`cmd'" == "slogit" {
        * grab information about current model
        tempname slb slV slbeta slphi sltheta slcatnum slthetaV
        local slnvars = e(df_m) // # of rhs variables
        mat `slb' = e(b)
        mat `slV' = e(V)
        local slncat = e(k_out)
        local slncatm1 = e(k_out) - 1
        local slnphi = e(k_out) - 1
        local slntheta = `slnphi'
        local slrefnum = e(i_base) // number of reference category
        local slrefnm `e(out`slrefnum')'
        * which row in e(outcomes)?
        mat `slcatnum' = e(outcomes) // values for categories regardless of base
        mat `slcatnum' = `slcatnum''
        local slrefrow = 0
        foreach i of numlist 1/`slncat'  {
            local cati = `slcatnum'[1,`i']
            if `slrefnum'==`cati' {
                local slrefrow = `i'
            }
        }
        * if 1 is reference then from category is 2
        local slfromnum = 1
        if `slrefnum'==1 {
            local slfromnum = 2
        }
        local slfromnm `e(out`slfromnum')'
        mat `slbeta' = `slb'[1,1..`slnvars']
        mat `slphi' = e(b)
        mat `slphi' = `slphi'[1,`slnvars'+1..`slnvars'+`slncatm1'],(0)
        mat `sltheta' = e(b)
        mat `sltheta' = `sltheta'[1,`slnvars'+`slncatm1'+1..`slnvars'+2*`slncatm1'],(0)
        mat `slthetaV' = `slV'[`slnvars'+`slncatm1'+1..`slnvars'+2*`slncatm1',.]
        mat `slthetaV' = `slthetaV'[.,`slnvars'+`slncatm1'+1..`slnvars'+2*`slncatm1']
        * get theta# and phi#_# names
        local slphinm : coleq `slphi'
        local slthetanm : coleq `sltheta'
        * local slphifull : colfullnames slphi
        * local slphinm : colnames slphi
        * basecategory for which phi=0 and theta=0
        *local nm2 "`slrefnm'"
        local nm1 "`slrefnm'" // 10Aug2005
        * comparison category for beta's
        *local nm1 "`slfromnm'"
        local nm2 "`slfromnm'" // 10Aug2005
    } // getting slogit information
    version 6

    if "`reverse'"!="" {
        local temp "`nm1'"
        local nm1 "`nm2'"
        local nm2 "`temp'"
    }

    * category labels for mlogit, mprobit
    if "`cmd'" == "mlogit" ///
        | "`cmd'" == "mprobit" {
        local catnm  `r(catnms8)' /* names of categories, ref is last name */
        local catnums `r(catvals)'
        * 24Feb2005
        if "`nolabel'"=="nolabel" {
            local catnm `catnums'
        }
        local refcat = r(refval) /* number of reference category */
        local refnm : word `ncats' of `catnm'
    }

    * information about weights
    if "`e(wtype)'"=="iweight" {
        di _n in r "cannot use " in y "listcoef" /*
        */ in r " for models with iweights"
        exit 198
    }
    local wtis ""
    if "`e(wtype)'"!="" {
        local wtis "[`e(wtype)'`e(wexp)']"
    }
    if "`e(wtype)'"=="pweight" {
        local wtis "[aweight`e(wexp)']"
        di in blu "(pweights not compatible with " in y "summarize" /*
        */ in blu "; weights will be treated as aweights)"
    }
    * information about b

    *   v1.8.4 code
    *   if "`e(cmd)'"=="mlogit" {
    *       nobreak {
    *       version 5.0
    *       mat `b' = e(b)
    *       mat `v' = e(V)
    *       }
    *   version 6.0
    *   }

    * 2009-10-07 1.9.0 use ben jann's _get_mlogit_bv
    * for stata 11 return of b and V
    if "`e(cmd)'"=="mlogit" {
        _get_mlogit_bv `b' `v'
     }
    else if "`e(cmd)'"=="mprobit" {
        nobreak {
            * reshape matrix b
            tempname bold vold
            mat `bold' = e(b)
            mat `v' = e(V)
            local rows = e(k_out)-1
            local cells = colsof(`bold')
            local cols = `cells'/`rows'
            mat `b' = J(`rows', `cols', 0)
            local i = 1
            forvalues r = 1(1)`rows' {
                local rownames = "`rownames' y`r'"
                forvalues c = 1(1)`cols' {
                    mat `b'[`r', `c'] = `bold'[1, `i']
                    local i = `i' + 1
                }
            }
            local colnames :  colnames `bold'
            local colnames :  list uniq colnames
            mat rownames `b' = `rownames'
            mat colnames `b' = `colnames'
        } // nobreak
    }
    else {
        mat `b' = e(b)
        local nb = colsof(`b')
        mat `sdb' = e(V)
        mat `sdb' = vecdiag(`sdb')
        mat `bnocon' = `b'[1,1..`rhsnum'] /* trim off _con */
        mat coleq `bnocon' = _
        * 050123 old code: if "`iscon'"=="yes"
        * if model estimated w/o constant, same as iscon==yes
        if "`iscon'"=="yes" & `isnocon'!=1 {
            * get constants
            mat `mconb' = `b'[1,`rhsnum'+1..`rhsnum'+`ncats'-1]
            mat `mcontz' = `mconb'
            mat `mconp' = `mconb'
            local i = 1
            while `i' < `ncats' {
                mat `mcontz'[1,`i'] = `mconb'[1,`i'] / /*
                */ sqrt(`sdb'[1,`rhsnum'+`i'])
                if "`tz'"=="t" {
                    scalar `dft' = `nobs'-e(df_m)-1
                    mat `mconp'[1,`i'] = tprob(`dft',-abs(`mcontz'[1,`i']))
                }
                else { mat `mconp'[1,`i'] = 2*normprob(-abs(`mcontz'[1,`i'])) }
                local i = `i' + 1
            }
        } /* is a constant */
    } /* is not mlogit */

    * coefficients for 2nd equation for -zip- & -zinb-
    if "`iszero'"=="yes" {
        scalar `con2' = `b'[1,`rhsnum'+2+`rhsnum2']
        scalar `contst2' = `con2'/sqrt(`sdb'[1,`rhsnum'+2+`rhsnum2'])
        scalar `conp2' = 2*normprob(-abs(`contst2'))
        mat def `bnocon2' = `b'[1,(`rhsnum'+2)..(`rhsnum'+`rhsnum2'+1)]
        mat coleq `bnocon2' = _
        mat def `sdb2' = `sdb'[1,(`rhsnum'+2)..(`rhsnum'+`rhsnum2'+1)]
        _pesum `wtis' if e(sample)==1,two
        mat `sd2' = r(Ssd)
        mat `sd2' = `sd2'[1,2...] /* trim off lhs variable */
    }

    * sd_x and sdy
    _pesum `wtis' if e(sample) == 1
    mat `sd' = r(Ssd)
    scalar `sdy' = `sd'[1,1]
    scalar `sdyobs' = `sdy'
    mat `sd' = `sd'[1,2...]  /* trim off lhs variable */

*-> parse varlist

    * prnlist is list and order of variables to print
    * prnnums is number of variable in matrices
    if "`varlist'" == "" {
        local prnlist "`rhsnam'"
        local count = 1
        while `count' <= `rhsnum' {
            local prnnums "`prnnums' `count'"
            local count = `count' + 1
        }
        if "`iszero'"=="yes" {
            local prnlis2 "`rhsnam2'"
            local count = 1
            while `count' <= `rhsnum2' {
                local prnnum2 "`prnnum2' `count'"
                local count = `count' + 1
            }
        }
    }
    * if varlist specified, print output in varlist order
    else {
        local count = 1
        local countto : word count `varlist'
        tokenize `varlist'
        while `count' <= `countto' {
            local count2 = 1
            local found = "no"
            while `count2' <= `rhsnum' {
                local rhstmp : word `count2' of `rhsnam'
                if "``count''" == "`rhstmp'" {
                    local prnlist "`prnlist' `rhstmp'"
                    local prnnums "`prnnums' `count2'"
                    local found = "yes"
                }
                local count2 = `count2' + 1
            }
            if "`iszero'"=="yes" {
                local count2 = 1
                while `count2' <= `rhsnum2' {
                    local rhstmp : word `count2' of `rhsnam2'
                    if "``count''" == "`rhstmp'" {
                        local prnlis2 "`prnlis2' `rhstmp'"
                        local prnnum2 "`prnnum2' `count2'"
                        local found = "yes"
                    }
                    local count2 = `count2' + 1
                }
            }
            if "`found'" == "no" {
               di in y "``count'' " in r "is not an independent variable"
               exit 198
            }
        local count = `count' + 1
        }
    } /* if a varlist has been specified */

*-> parse pvalue option

    sca `pcutoff' = `pvalue'
    * allow pcutoff(5) to represent pcutoff(.05)
    if `pcutoff' >= 1 & `pcutoff' <= 100 { sca `pcutoff' = `pcutoff' / 100 }
    if `pcutoff' == 0 { sca `pcutoff' = 1.00 }
    if `pcutoff' < 0 | `pcutoff' > 1 {
        di in y "pvalue()" in r " must be valid nonzero probability"
        exit 198
    }

*** Start if not special case **************************************
    if "`isspec'"=="no" { /* only if not special cases */

*-> compute sd(y*)

        if "`isystar'"=="yes" {
            * get cov(rhs) for computing var(y*)
            quietly mat accum `vx' = `lhsnm' `rhsnam' `wtis' if e(sample)==1/*
                */  `in', deviations noconstant
            mat `vx' = `vx'[2...,2...] /* trim off lhs variable */
            scalar `factr' = 1/(`nobs'-1)  /* 1 over nobs - 1 */
            mat `vx' = `factr' * `vx'
            mat def `sdystar' = `bnocon' * `vx'
            mat `sdystar' = `sdystar' * `bnocon''
            mat `vare' = J(1,1,1) /* default for probit */
            scalar `factr' = 1
* 1.9.2            if "`e(cmd)'"=="logit" | "`e(cmd)'"=="ologit" {
            * 1.9.3
            if "`e(cmd)'"=="logit" | "`e(cmd)'"=="ologit" /*
                */ | "`cmd'" == "logistic" {
                scalar `factr' = (_pi*_pi)/3
            }
            if "`e(cmd)'"=="tobit" | "`e(cmd)'"=="intreg" | "`e(cmd)'"=="cnreg" {
                scalar `factr' = `b'[1,(`rhsnum'+2)]*`b'[1,(`rhsnum'+2)]
            }
            mat `vare' = `factr' * `vare'
            mat `sdystar' = `sdystar' + `vare'
            scalar `sdy' = sqrt(`sdystar'[1,1])
        }

*-> compute standardized coefficients, t's, z's and p's

        local nx = colsof(`sd')
        mat `bsy'  = `bnocon'
        mat `bsx'  = `bnocon'
        mat `bs'   = `bnocon'
        mat `eb'   = `bnocon'
        mat `ebx'  = `bnocon'
        mat `pb'   = `bnocon'
        mat `pbx'  = `bnocon'
        mat `zval' = `bnocon'
        mat `p'    = `bnocon'
        scalar `factr' = 1/`sdy'
        mat `bsy' = `factr' * `bsy' /* y-standardized betas */

        * loop through x's
        local i = 1
        while `i'<=`nx' {
            mat `sdb'[1,`i']  = sqrt(`sdb'[1,`i']) /* sd of b's */
            scalar `sdx' = `sd'[1,`i']
            * 13Apr2005 delta - change by delta, not 1 sd
            if `delta'!=1 {
                scalar `sdx' = `delta'
            }
            mat `bsx'[1,`i']  = `bnocon'[1,`i']*`sdx' /* b*sd_x */
            mat `bs'[1,`i']   = `bsy'[1,`i']*`sdx' /* b*sd_x/sd_y) */
            scalar `b1' = `b'[1,`i']
            * factor change
            mat `eb'[1,`i'] = exp(`b1')
            mat `ebx'[1,`i'] = exp(`b1'*`sdx')
            * percent change
            mat `pb'[1,`i'] = (exp(`b1')-1)*100
            mat `pbx'[1,`i'] = (exp(`b1'*`sdx')-1)*100
            if "`reverse'"!="" {
                * factor change
                mat `eb'[1,`i'] = 1/exp(`b1')
                mat `ebx'[1,`i'] = 1/exp(`b1'*`sdx')
                * percent change
                mat `pb'[1,`i'] = ((1/exp(`b1'))-1)*100
                mat `pbx'[1,`i'] = ((1/exp(`b1'*`sdx'))-1)*100
            }
            * z, t, and p
            mat `zval'[1,`i'] = `bnocon'[1,`i']/`sdb'[1,`i'] /* t/z of b */
            if "`tz'"=="t" {
                scalar `dft' = `nobs'-e(df_m)-1
                mat `p'[1,`i'] = tprob(`dft',-abs(`zval'[1,`i']))
            }
            else { mat `p'[1,`i'] = 2*normprob(-abs(`zval'[1,`i'])) }
            local i=`i'+1
        }

        * coefficients for -zip- and -zinb-
        if "`iszero'"=="yes" {
            mat `zval2' = `bnocon2'
            mat `p2' = `bnocon2'
            mat def `eb2' = `bnocon2'
            mat def `ebx2' = `bnocon2'
            mat def `pb2' = `bnocon2'
            mat def `pbx2' = `bnocon2'
            local nx2 = colsof(`sd2')
            local i = 1
            while `i'<=`nx2' {
                mat `sdb2'[1,`i'] = sqrt(`sdb2'[1,`i']) /* sd of b's */
                mat `zval2'[1,`i'] = `bnocon2'[1,`i']/`sdb2'[1,`i']
                mat `p2'[1,`i'] = 2*normprob(-abs(`zval2'[1,`i']))
                mat `eb2'[1,`i'] = exp(`bnocon2'[1,`i'])
                mat `ebx2'[1,`i'] = exp(`bnocon2'[1,`i']*`sd2'[1,`i'])
                mat `pb2'[1,`i'] = (exp(`bnocon2'[1,`i'])-1)*100
                mat `pbx2'[1,`i'] = (exp(`bnocon2'[1,`i']*`sd2'[1,`i'])-1)*100
                local i=`i'+1
            }
        }

*-> Print Headers

        di _n in g "`cmd' (N=" in y `nobs' in g "): " _c
        * header for std results
        if "`defhead'"=="std" | "`std'"=="std" {
            di in g "Unstandardized and Standardized Estimates " _c
            if `pcutoff' < 1 & `pcutoff' >= .01 {
                di in g "when P>|`tz'| < " in y %3.2f `pcutoff' _c
            }
            else if `pcutoff' < .01 & `pcutoff' > 0 {
                di in g "when P>|`tz'| < " in y `pcutoff' _c
            }
            di
        }
        * header for odds or count outcomes
        else {
            local header "Factor"
            if "`percent'" == "percent" { local header "Percentage" }
            if "`defhead'"=="odds" | "`factor'"=="factor" {
                di in g "`header' Change in Odds " _c
                if `pcutoff' < 1 & `pcutoff' >= .01 {
                    di in g "when P>|`tz'| < " in y %3.2f `pcutoff' _c
                }
                if `pcutoff' < .01 & `pcutoff' > 0 {
                    di in g "when P>|`tz'| < " in y `pcutoff' _c
                }
                di
            }
            else if "`defhead'"=="count" {
                di in g "`header' Change in Expected Count " _c
                if `pcutoff' < 1 & `pcutoff' >= .01 {
                    di in g "when P>|`tz'| < " in y %3.2f `pcutoff' _c
                }
                if `pcutoff' < .01 & `pcutoff' > 0 {
                    di in g "when P>|`tz'| < " in y `pcutoff' _c
                }
                di
            }
        }

        * print lhs exception for intreg
        if "`cmd'"=="intreg" {
            di _n in gr "    LHS vars: " in y "`e(depvar)'" _c
        }

        * list sdy's or contrast for odds
        if ("`defhead'"=="std" | "`std'"=="std") | ("`defhead'"=="count") {
            di _n in gr " Observed SD: " in y `sdyobs'
            if "`isystar'"=="yes" { di in g "   Latent SD: " in y `sdy' }
        }

        * sd of error
        if "`cmd'" == "regress" {
            di in gr " SD of Error: " in y e(rmse)
        }
        if "`cmd'" == "tobit" | "`cmd'" == "cnreg" | "`cmd'" == "intreg" {
            local sde = `b'[1,`rhsnum'+2]
            di in gr " SD of Error: " in y `sde'
        }

        if "`defhead'"=="odds" | "`factor'"=="factor" {
            di _n in g "  Odds of: " in y "`nm1'" in g " vs " in y "`nm2'"
        }

        if "`iszero'"=="yes" {
            local header "Factor"
            if "`percent'" == "percent" { local header "Percentage" }
            di _n in g "Count Equation: `header' Change in Expected " /*
            */ "Count for Those Not Always 0"
        }

*-> Print Header for Columns

        local head2   "      b         `tz'     P>|`tz'|"

        * 13Apr2005
        if `delta'!=1 { // delta option
            if "`dobx'"=="yes"  { local head2 "`head2'   bDeltaX"  }
            if "`doby'"=="yes"  { local head2 "`head2'   bStdY"    }
            if "`dobxy'"=="yes" { local head2 "`head2' bDeltaStdY" }
            if "`doeb'"=="yes"  { local head2 "`head2'    e^b  "   }
            if "`doebx'"=="yes" { local head2 "`head2' e^bDelta"   }
            if "`dopb'"=="yes"  { local head2 "`head2'      %  "   }
            if "`dopbx'"=="yes" { local head2 "`head2'    %StdX"   }
            if "`doby'"=="yes"  { // std coef
                if "`isnosdx'"!="yes" { local head2 "`head2'    Delta" }
            }
            else { // e(b)
                if "`isnosdx'"!="yes" { local head2  "`head2'      Delta" }
            }
        }
        else{ // no delta option
            if "`dobx'"=="yes"    { local head2 "`head2'    bStdX"   }
            if "`doby'"=="yes"    { local head2 "`head2'    bStdY"   }
            if "`dobxy'"=="yes"   { local head2 "`head2'   bStdXY"   }
            if "`doeb'"=="yes"    { local head2 "`head2'    e^b  "   }
            if "`doebx'"=="yes"   { local head2 "`head2'  e^bStdX"   }
            if "`dopb'"=="yes"    { local head2 "`head2'      %  "   }
            if "`dopbx'"=="yes"   { local head2 "`head2'    %StdX"   }
            if "`isnosdx'"!="yes" { local head2 "`head2'      SDofX" }
        }

        local todup = length("`head2'")
        di in g `smcl' _n _dup(13) "`dash'" "`topt'" _dup(`todup') "`dash'"
        *added for stata 7 compatibility
        if "`vers7'"=="yes" { local lhsnm = abbrev("`lhsnm'", 12) }
        * no lhs for for intreg
        if "`cmd'"=="intreg" { di in g _col(14) `smcl' "`vline'`head2'" }
        else { di in g %12s "`lhsnm'" _col(14) `smcl' "`vline'`head2'" }
        di in g `smcl' _dup(13) "`dash'" "`plussgn'" _dup(`todup') "`dash'"

*-> Print Coefficients

        tokenize `prnnums'
        local count = 1
        while "``count''" != "" {
            local indx: word `count' of `prnnums'
            local vname: word `count' of `prnlist'
            *added for stata 7 compatibility
            if "`vers7'"=="yes" { local vname = abbrev("`vname'", 12) }
            if `p'[1, `indx']<`pcutoff' {
                local noprint "no"
                di in g `smcl' %12s "`vname'" in g _col(14) "`vline'" in y /*
                    */ %10.5f `bnocon'[1,`indx']   %9.3f `zval'[1,`indx'] /*
                    */ %8.3f `p'[1,`indx'] _c
                if "`dobx'" == "yes"  { di %9.4f `bsx'[1,`indx'] _c }
                if "`doby'" == "yes"  { di %9.4f `bsy'[1,`indx'] _c }
                if "`dobxy'" == "yes" { di %9.4f `bs'[1,`indx'] _c }
                if "`doeb'" == "yes"  { di %9.4f `eb'[1,`indx'] _c }
                if "`doebx'" == "yes" { di %9.4f `ebx'[1,`indx'] _c }
                if "`dopb'" == "yes"  { di %9.1f `pb'[1,`indx'] _c }
                if "`dopbx'" == "yes" { di %9.1f `pbx'[1,`indx'] _c }

                * 13Apr2005
                if `delta'!=1 {  // delta option
                    if "`isnosdx'"!="yes" {
                        di %11.4f `delta'
                    }
                else {
                    di
                }  /* need to advance to next line if isnosdx */
            }
            else { // no delta option
                if "`isnosdx'"!="yes" {
                    di %11.4f `sd'[1,`indx']
                }
            else {
                di
            }  /* need to advance to next line if isnosdx */
        }

                * enter values in matrices to be returned
                if "`matrix'"!="" {
                    matrix `nxtrow' = `bnocon'[1, `indx']
                    matrix rownames `nxtrow' = `vname'
                    matrix `outb' = (nullmat(`outb') \ `nxtrow')
                    matrix `outz' = (nullmat(`outz') \ `zval'[1,`indx'])
                    matrix `outp' = (nullmat(`outp') \ `p'[1, `indx'])
                    matrix `outsdx' = (nullmat(`outsdx') \ `sd'[1, `indx'])
                    if "`dobx'" == "yes"  {
                        mat `outbsx' = (nullmat(`outbsx') \ `bsx'[1,`indx']) }
                    if "`doby'" == "yes" {
                        mat `outbsy' = (nullmat(`outbsy') \ `bsy'[1,`indx']) }
                    if "`dobxy'" == "yes" {
                        mat `outbs' = (nullmat(`outbs') \ `bs'[1,`indx']) }
                    if "`doeb'" == "yes" {
                        mat `outeb' = (nullmat(`outeb') \ `eb'[1,`indx']) }
                    if "`doebx'" == "yes" {
                        mat `outebx' = (nullmat(`outebx') \ `ebx'[1,`indx']) }
                    if "`dopb'" == "yes" {
                        mat `outpb' = (nullmat(`outpb') \ `pb'[1,`indx']) }
                    if "`dopbx'" == "yes" {
                        mat `outpbx' = (nullmat(`outpbx') \ `pbx'[1,`indx']) }
                }
            } /* if `p'[1, `indx']<`pcutoff' */

            local count = `count' + 1

        } /* loop through varlist: while "``count''" != "" */

        if "`constant'"=="constant" & "`iscon'"=="yes" {
            if `ncats'==2 {
                di in g `smcl' %12s "_cons" in g _col(14) "`vline'" in y %10.5f /*
                */ `mconb'[1,1] %9.3f `mcontz'[1,1] %8.3f `mconp'[1,1]
                if "`matrix'"!="" {
                    return scalar cons = `mconb'[1,1]
                    return scalar cons_z = `mcontz'[1,1]
                    return scalar cons_p = `mconp'[1,1]
                }
            }
            else {
                di in g `smcl' _dup(13) "`dash'" "`plussgn'" _dup(`todup') "`dash'"
                local i = 1
                while `i' < `ncats' {
                    local cnm "`cut'cut"
                    di in g `smcl' %12s "`cnm'`i'" in g _col(14) "`vline'" in y /*
                    */ %10.5f `mconb'[1,`i'] %9.3f `mcontz'[1,`i'] /*
                    */ %8.3f `mconp'[1,`i']
                    local i = `i' + 1
                }
            } /* more than one constant */
        }

        * alpha for neg bin models
        *if "`e(cmd)'"=="nbreg" | "`e(cmd)'"=="zinb" {
        if "`cmd'"=="zinb" | "`cmd'"=="nbreg" ///
                | "`cmd'"=="ztnb" {
            di in g `smcl' _dup(13) "`dash'" "`plussgn'" _dup(`todup') "`dash'"
            sca `lnalpha' = `b'[1,`nb']
            quietly _diparm lnalpha, exp label("alpha") noprob
            di `smcl' in g "    ln alpha" _col(14) "`vline'" /*
            */ in y %10.5f `lnalpha'
            di `smcl' in g "       alpha" _col(14) "`vline'" /*
            */ in y %10.5f r(est) in g "   SE(alpha) = " in y %-9.5f r(se)
        }

        * 3/24/05 - phi and theta for slogit models
        if "`e(cmd)'" == "slogit" {

            * change to -version 9- (slogit introduced with v9)
            version 9
            tempname b V
            mat `b' = e(b)
            mat `V' = e(V)

            * print phis
            di in g `smcl' _dup(13) "`dash'" "`plussgn'" _dup(`todup') "`dash'"
            forvalues num = 1(1)`slnphi' {
                tempname phi Vphi sdphi zphi pphi
                sca `phi' = `b'[1, `i'] // grab phi
                local phinm : word `num' of `slphinm'
                sca `Vphi' = `V'[`i', `i']
                sca `sdphi' = sqrt(`Vphi')
                sca `zphi' = `phi'/`sdphi'
                sca `pphi' = 2*normprob(-abs(`zphi'))
                di as txt %12s "`phinm'" _col(14) "`vline'" as res %10.5f `phi' ///
                    %9.3f `zphi'  %8.3f `pphi'
                local i = `i' + 1
            }

            * print thetas
            di in g `smcl' _dup(13) "`dash'" "`plussgn'" _dup(`todup') "`dash'"
            forvalues num = 1(1)`slntheta' {
                tempname thetamat theta thetaVmat thetaV thetasd thetaz thetap
                local thetanm : word `num' of `slthetanm'
                sca `theta' = `sltheta'[1,`num']
                sca `thetaV' = `slthetaV'[`num',`num']
                sca `thetasd' = sqrt(`thetaV')
                sca `thetaz' = `theta' / `thetasd'
                sca `thetap' = 2*normprob(-abs(`thetaz'))
                di as txt %12s "`thetanm'" _col(14) "`vline'" as res %10.5f `theta' ///
                    %9.3f `thetaz'  %8.3f `thetap'
                local i = `i' + 1
            }
            * change back to -version 6-
            version 6
        } // end slogit - non expanded output

        * bottom border
        di in g `smcl' _dup(13) "`dash'" "`bottomt'" _dup(`todup') "`dash'"

        * LR test: code based on nbreg.ado version 3.3.9 06dec2000
        *050207
        if "`e(cmd)'"=="nbreg" | "`cmd'" == "ztnb" {
            if ((e(chi2_c) > 0.005) & (e(chi2_c)<1e4)) | (ln(e(alpha)) < -20) {
                local fmt "%-8.2f"
            }
            else    local fmt "%-8.2e"
            tempname pval
            scalar `pval' = chiprob(1, e(chi2_c))*0.5
            if ln(e(alpha)) < -20 { scalar `pval'= 1 }
            di in g `smcl' " LR test of alpha=0: " /*
            */ in y `fmt' e(chi2_c) in g " Prob>=LRX2 = " in y %5.3f /*
            */ `pval'
            di in g `smcl' _dup(14) "`dash'" _dup(`todup') "`dash'"
        }
    } /* if "`isspec'"=="no" */
*** End if not special case **************************************


*-> special model--mlogit

    if "`cmd'" == "mlogit" {
        di _n in g "`cmd' (N=" in y `nobs' in g "): " _c
        local pcttext "Factor"
        if "`percent'" == "percent" { local pcttext = "Percentage" }
        di in g "`pcttext' Change in the Odds of " in y "`lhsnm' " _c
        if `pcutoff' < 1 & `pcutoff' >= .01 {
            di in g "when P>|z| < " in y %3.2f `pcutoff' _c
        }
        if `pcutoff' < .01 & `pcutoff' > 0 {
            di in g "when P>|z| < " in y `pcutoff' _c
        }
        di
        tokenize "`prnnums'"
        local count = 1
        while "``count''" != "" {

            local ivar = "``count''"
            scalar `sdx' = `sd'[1,`ivar']
            local vname: word `ivar' of `rhsnam'
            di _n in g "Variable: " in y "`vname' " /*
            * 1.6.7 jsl 1/3/2004
            */ in g "(sd=" in y `sdx' in g ")"
            * 1.6.6: in g "(sd=" in y %8.2g `sdx' in g ")"
            local head2   "      b         z     P>|z|"
            if "`doeb'" == "yes"  { local head2   "`head2'     e^b " }
            else { local head2   "`head2'       % " }
            if "`doebx'" == "yes" { local head2   "`head2'  e^bStdX" }
            else { local head2   "`head2'    %StdX" }
            local todup = length("`head2'")
            * 1.8.0
            di _n in g `smcl' %-18s "Odds comparing" _col(19) "`vline'"
            * 2008-06-15 missing "
            di in g `smcl' %-18s "Alternative 1" _col(19) "`vline'"
            di in g `smcl' %-18s "to Alternative 2" _col(19) "`vline'`head2'"
            di in g `smcl' _dup(18) "`dash'" "`plussgn'" _dup(`todup') "`dash'"
            * loop through all contrasts
            local i1 1
            local i2 1
            while `i1' <= `ncats' {
                local num1 : word `i1' of `catnums'
                local name1 : word `i1' of `catnm'
                while `i2' <= `ncats' {
                    * get betas for i1 and i2, zero if refcat
                    if `i1'==`ncats' { scalar `b1' = 0 }
                    else { scalar `b1' = `b'[`i1',`ivar'] }
                    if `i2'==`ncats' { scalar `b2' = 0 }
                    else { scalar `b2' = `b'[`i2',`ivar'] }
                    scalar `b12' = `b1'-`b2'
                    scalar `eb' = exp(`b12')
                    scalar `ebx' = exp(`b12'*`sdx')
                    scalar `pb' = (`eb'-1)*100
                    scalar `pbx' = (`ebx'-1)*100
                    local l2 = ((`i2'-1)*(`rhsnum'+1))+`ivar'
                    if `i1'!=`ncats' & `i2' == `ncats' {
                        local l1 = ((`i1'-1)*(`rhsnum'+1))+`ivar'
                        scalar `se' = sqrt(`v'[`l1',`l1'])
                    }
                    if `i1'!=`ncats' & `i2' != `ncats' {
                        local l1 = ((`i1'-1)*(`rhsnum'+1))+`ivar'
                        scalar `se' = sqrt(`v'[`l1',`l1'] + /*
                        */ `v'[`l2',`l2'] - 2*`v'[`l1',`l2'])
                    }
                    if `i1'==`ncats' & `i2' != `ncats' {
                        scalar `se' = sqrt(`v'[`l2',`l2'])
                    }

                    scalar `rec_se' = 1/`se'
                    scalar `z' = `rec_se'*`b12'
                    scalar `p' = 2*normprob(-abs(`z'))
                    if `p' <= `pcutoff' {
                        local noprint = "no"
                        * get outcome value of second outcome
                        local num2: word `i2' of `catnums'
                        local name2 : word `i2' of `catnm'
                        if "`matrix'"!="" {
                            matrix `nxtrow' = `b12'
                            matrix rownames `nxtrow' = `vname'
                            matrix `outb' = (nullmat(`outb') \ `nxtrow')
                            matrix `outcon' = (nullmat(`outcon') /*
                            */ \ `num1', `num2')
                            matrix `outsdx' = (nullmat(`outsdx') \ `sdx')
                            matrix `outeb' = (nullmat(`outeb') \ `eb')
                            matrix `outebx' = (nullmat(`outebx') \ `ebx')
                            matrix `outpb' = (nullmat(`outpb') \ `pb')
                            matrix `outpbx' = (nullmat(`outpbx') \ `pbx')
                            matrix `outz' = (nullmat(`outz') \ `z')
                            matrix `outp' = (nullmat(`outp') \ `p')
                            matrix `outse' = (nullmat(`outse') \ `se')
                        } /* matrix */

                        * 050110 jsl gt option & adjacent
                        if ("`gt'"!="gt" & "`lt'"!="lt") /*
                        */ | ("`gt'"=="gt") & (`num1'>`num2') /*
                        */ | ("`lt'"=="lt") & (`num1'<`num2') {
                            local absdif = abs(`num1'-`num2')
                            if ("`adjacent'"=="adjacent" & `absdif'==1) /*
                                */ | "`adjacent'"!="adjacent" {
                                di in g `smcl' "`name1'"   _col(9)   /*
                                */ "-`name2'"   _col(19) "`vline'" in y /*
                                */ %10.5f `b12' %9.3f `z' /*
                                */ %8.3f `p' _c
                                if "`doeb'" == "yes"  { di %9.4f `eb' _c }
                                else { di %9.1f `pb' _c }
                                if "`doebx'" == "yes" { di %9.4f `ebx' }
                                else { di %9.1f `pbx' }
                            } /* adjacent option */
                        } /* gt lt option */
                   } /* `p' <= `pcutoff' */
                local i2 = `i2' + 1
                if `i1' == `i2' { local i2 = `i2' + 1 }
                } /* while `i2' <= `ncats' */
            local i2 1
            local i1 = `i1' + 1
            } /* i1 */

        di in g `smcl' _dup(18) "`dash'" "`bottomt'" _dup(`todup') "`dash'"
        local count = `count' + 1
        } /* while count */

    } /* if "`cmd'" == "mlogit" */

*-> special model--mprobit

    if "`cmd'" == "mprobit" {

        di _n in g "`cmd' (N=" in y `nobs' in g "): " _c

        di in g "Unstandardized and Standardized Estimates for " in y "`lhsnm' " _c
        if `pcutoff' < 1 & `pcutoff' >= .01 {
            di in g "when P>|z| < " in y %3.2f `pcutoff' _c
        }
        if `pcutoff' < .01 & `pcutoff' > 0 {
            di in g "when P>|z| < " in y `pcutoff' _c
        }
        di
        tokenize "`prnnums'"
        local count = 1
        while "``count''" != "" {

            local ivar = "``count''"
            scalar `sdx' = `sd'[1,`ivar']
            local vname: word `ivar' of `rhsnam'
            di _n in g "Variable: " in y "`vname' " /*
            */ in g "(sd=" in y `sdx' in g ")"
            local head2   "      b         z     P>|z|     bStdX"
            local todup = length("`head2'")
            di _n in g `smcl' %18s "Comparing     " _col(19) "`vline'"
            di in g `smcl' %18s "Group 1 vs Group 2" _col(19) "`vline'`head2'"
            di in g `smcl' _dup(18) "`dash'" "`plussgn'" _dup(`todup') "`dash'"

            * loop through all contrasts
            local i1 1
            local i2 1
            while `i1' <= `ncats' {
                local num1 : word `i1' of `catnums'
                local name1 : word `i1' of `catnm'
                while `i2' <= `ncats' {
                    * get betas for i1 and i2, zero if refcat
                    if `i1'==`ncats' { scalar `b1' = 0 }
                    else { scalar `b1' = `b'[`i1',`ivar'] }
                    if `i2'==`ncats' { scalar `b2' = 0 }
                    else { scalar `b2' = `b'[`i2',`ivar'] }

                    scalar `b12' = `b1'-`b2'
                    scalar `bx' = `b12'*`sdx'
                    local l2 = ((`i2'-1)*(`rhsnum'+1))+`ivar'
                    if `i1'!=`ncats' & `i2' == `ncats' {
                        local l1 = ((`i1'-1)*(`rhsnum'+1))+`ivar'
                        scalar `se' = sqrt(`v'[`l1',`l1'])
                    }
                    if `i1'!=`ncats' & `i2' != `ncats' {
                        local l1 = ((`i1'-1)*(`rhsnum'+1))+`ivar'
                        scalar `se' = sqrt(`v'[`l1',`l1'] + /*
                        */ `v'[`l2',`l2'] - 2*`v'[`l1',`l2'])
                    }
                    if `i1'==`ncats' & `i2' != `ncats' {
                        scalar `se' = sqrt(`v'[`l2',`l2'])
                    }

                    scalar `rec_se' = 1/`se'
                    scalar `z' = `rec_se'*`b12'
                    scalar `p' = 2*normprob(-abs(`z'))

                    if `p' <= `pcutoff' {
                        local noprint = "no"
                        * get outcome value of second outcome
                        local num2: word `i2' of `catnums'
                        local name2 : word `i2' of `catnm'
                        if "`matrix'"!="" {
                            matrix `nxtrow' = `b12'
                            matrix rownames `nxtrow' = `vname'
                            matrix `outb' = (nullmat(`outb') \ `nxtrow')
                            matrix `outcon' = (nullmat(`outcon') /*
                            */ \ `num1', `num2')
                            matrix `outsdx' = (nullmat(`outsdx') \ `sdx')
* 2008-06-15 - mprobit does not compute these
*                           matrix `outebx' = (nullmat(`outebx') \ `bx')
*                           matrix `outpb' = (nullmat(`outpb') \ `pb')
*                           matrix `outpbx' = (nullmat(`outpbx') \ `pbx')
* 2008-06-15 add std b coef
                            matrix `outbsx' = (nullmat(`outbsx') \ `bx')
                            matrix `outz' = (nullmat(`outz') \ `z')
                            matrix `outp' = (nullmat(`outp') \ `p')
                            matrix `outse' = (nullmat(`outse') \ `se')
                        } /* matrix */
                        * 050110 jsl gt option & adjacent
                        if ("`gt'"!="gt" & "`lt'"!="lt") /*
                        */ | ("`gt'"=="gt") & (`num1'>`num2') /*
                        */ | ("`lt'"=="lt") & (`num1'<`num2') {
                            local absdif = abs(`num1'-`num2')
                            if ("`adjacent'"=="adjacent" & `absdif'==1) /*
                                */ | "`adjacent'"!="adjacent" {
                                di in g `smcl' "`name1'"   _col(9)   /*
                                */ "-`name2'"   _col(19) "`vline'" in y /*
                                */ %10.5f `b12' %9.3f `z' /*
                                */ %8.3f `p' _c
                                di %10.5f `bx'
                            } /* adjacent option */
                        } /* gt lt option */
                   } /* `p' <= `pcutoff' */
                local i2 = `i2' + 1
                if `i1' == `i2' { local i2 = `i2' + 1 }
                } /* while `i2' <= `ncats' */
            local i2 1
            local i1 = `i1' + 1
            } /* i1 */

        di in g `smcl' _dup(18) "`dash'" "`bottomt'" _dup(`todup') "`dash'"
        local count = `count' + 1
        } /* while count */

    } /* if "`cmd'" == "mprobit" 2008-06-15*/

*-> special model--slogit // print expanded coefficients

    if "`cmd'" == "slogit" & "`expand'"=="expand" {
        version 9
        di _n in g "`cmd' (N=" in y `nobs' in g "): " _c
        local pcttext "Factor"
        if "`percent'" == "percent" {
            local pcttext = "Percentage"
        }
        di in g "`pcttext' Change in the Odds of " in y "`lhsnm' " _c
        if `pcutoff' < 1 & `pcutoff' >= .01 {
            di in g "when P>|z| < " in y %3.2f `pcutoff' _c
        }

        di
        * loop through rhs variables to print
        tokenize "`prnnums'"
        local count = 1
        while "``count''" != "" { // loop through rhs variales

            local ivar = "``count''"
            scalar `sdx' = `sd'[1,`ivar']
            local vname: word `ivar' of `rhsnam'

            * compute (phi_i - phi_j) * beta
            tempname phiBest phiBse estsl est se
            mat `phiBest' = J(`slncat',`slncat',0)
            mat `phiBse' = `phiBest'
            local i = 1
            * # cat - 1 since base is not in coef matrix
            foreach i of numlist 1(1)`slncatm1' { // index for 1st phi
                * get phi # in case different base is used
                local phinm1 : word `i' of `slphinm' // name of ith parameter
                local phirow = substr("`phinm1'",6,.) //
                foreach j of numlist 1(1)`slncatm1' { // index for 2nd phi
                    local phinm2 : word `j' of `slphinm'
                    local phicol = substr("`phinm2'",6,.)
                    * di " `i' (row `phirow') - `j' (col `phicol')"
                    * hold estimates from current model, leaving values in memory
                    _estimates hold `estsl', copy
                    * compute contrasts
                    qui nlcom ([`phinm1']_b[_cons] ///
                        - [`phinm2']_b[_cons])*_b[`vname'], post
                    mat `est' = e(b)
                    mat `se' = e(V)
                    _estimates unhold `estsl'
                    * 12Apr2005
                    mat `phiBest'[`phirow',`phicol'] = -1*`est'[1,1]
                    mat `phiBse'[`phirow',`phicol'] = sqrt(`se'[1,1])
                }
            _estimates hold `estsl', copy
            qui nlcom ([`phinm1']_b[_cons]) * _b[`vname'], post
            mat `est' = e(b)
            mat `se' = e(V)
            _estimates unhold `estsl'
            * 12Apr2005
            mat `phiBest'[`phirow',`slrefrow'] = -1*`est'[1,1]
            mat `phiBse'[`phirow',`slrefrow'] = sqrt(`se'[1,1])
            * 12Apr2005
            mat `phiBest'[`slrefrow',`phirow'] = `est'[1,1]
            mat `phiBse'[`slrefrow',`phirow'] = sqrt(`se'[1,1])
        }

        di _n in g "Variable: " in y "`vname' " /*
        */ in g "(sd=" in y `sdx' in g ")"
        local head2   "      b         z     P>|z|"
        if "`doeb'" == "yes"  {
            local head2   "`head2'     e^b "
        }
        else {
            local head2   "`head2'       % "
        }
        if "`doebx'" == "yes" {
            local head2   "`head2'  e^bStdX"
        }
        else {
            local head2   "`head2'    %StdX"
        }
        local todup = length("`head2'")
        di _n in g `smcl' %18s "Odds comparing" _col(19) "`vline'"
        di in g `smcl' %18s "Group 1 vs Group 2" _col(19) "`vline'`head2'"
        di in g `smcl' _dup(18) "`dash'" "`plussgn'" _dup(`todup') "`dash'"

        * loop through all contrasts
        local i1 1
        local i2 1
        while `i1' <= `slncat' {
            local num1 = `slcatnum'[1,`i1']
            local name1 "`e(out`i1')'"
            while `i2' <= `slncat' {
                scalar `b12' = `phiBest'[`i1',`i2']
                scalar `se' = `phiBse'[`i1',`i2']
                scalar `eb' = exp(`b12')
                scalar `ebx' = exp(`b12'*`sdx')
                scalar `pb' = (`eb'-1)*100
                scalar `pbx' = (`ebx'-1)*100
                scalar `rec_se' = 1/`se'
                scalar `z' = `rec_se'*`b12'
                scalar `p' = 2*normprob(-abs(`z'))
                if `p' <= `pcutoff' {
                    local noprint = "no"
                    * get outcome value of second outcome
                    local num2 = `slcatnum'[1,`i2']
                    local name2 "`e(out`i2')'"
                    if ("`gt'"!="gt" & "`lt'"!="lt") /*
                    */ | ("`gt'"=="gt") & (`num1'>`num2') /*
                    */ | ("`lt'"=="lt") & (`num1'<`num2') {
                        local absdif = abs(`num1'-`num2')
                        if ("`adjacent'"=="adjacent" & `absdif'==1) /*
                            */ | "`adjacent'"!="adjacent" {
                            di in g `smcl' "`name1'"   _col(9)   /*
                            */ "-`name2'"   _col(19) "`vline'" in y /*
                            */ %10.5f `b12' %9.3f `z' /*
                            */ %8.3f `p' _c
                            if "`doeb'" == "yes"  {
                                di %9.4f `eb' _c
                            }
                            else {
                                di %9.1f `pb' _c
                            }
                            if "`doebx'" == "yes" {
                                di %9.4f `ebx'
                            }
                            else {
                                di %9.1f `pbx'
                            }
                        } /* adjacent option */
                    } /* gt lt option */
               } /* `p' <= `pcutoff' */
            local i2 = `i2' + 1
            if `i1' == `i2' {
                local i2 = `i2' + 1
            }
        } /* while `i2' <= `slncats' */
        local i2 1
        local i1 = `i1' + 1
        } /* i1 */

        di in g `smcl' _dup(18) "`dash'" "`bottomt'" _dup(`todup') "`dash'"
        local count = `count' + 1
        } // loop through variables
        version 6.0

    } /* if "`cmd'" == "slogit" expanded */

*-> help

    if "`help'"=="help" {
        di in g "       b = raw coefficient"
        di in g "       `tz' = `tz'-score for test of b=0"
        di in g "   P>|`tz'| = p-value for `tz'-test"
        local std "standardized"
        if "`dobx'" == "yes" { di in g "   bStdX = x-`std' coefficient" }
        if "`doby'" == "yes" { di in g "   bStdY = y-`std' coefficient" }
        if "`dobxy'" == "yes" { di in g "  bStdXY = fully `std' coefficient" }
        if "`doeb'" == "yes"  {
            if "`iscount'"=="yes" {
                di in g "     e^b = exp(b) = factor "/*
                */ "change in expected count for unit increase in X"
            }
            else {
                di in g "     e^b = exp(b) = factor "/*
                */ "change in odds for unit increase in X"
            }
        }
        if "`doebx'" == "yes" {
            if "`iscount'"=="yes" {
                di in g " e^bStdX = exp(b*SD of X) = "/*
                */ "change in expected count for SD increase in X"
            }
            else {
                di in g " e^bStdX = exp(b*SD of X) = "/*
                */ "change in odds for SD increase in X"
            }
        }
        if "`dopb'" == "yes" {
            if "`iscount'"=="yes" { di in g "       % = percent change in"/*
            */ " expected count for unit increase in X" }
            else { di in g "       % = percent change in odds for unit"/*
            */ " increase in X" }
        }
        if "`dopbx'" == "yes" {
            if "`iscount'"=="yes" { di in g "   %StdX = percent change in"/*
            */ " expected count for SD increase in X" }
            else { di in g "   %StdX = percent change in odds for SD"/*
            */ " increase in X" }
        }
        if "`cmd'" != "mlogit" { di in g "   SDofX = standard deviation of X" }
    } /* if "`help'"=="help" */

*-> do binary equation for zip zinb

    if "`iszero'"=="yes" {
        di _n in g "Binary Equation: Factor Change in Odds of Always 0"
        local todupz = length("`head2'")
        di in g `smcl' _n _dup(13) "`dash'" "`topt'" _dup(`todupz') "`dash'"
        di in g `smcl' %12s "Always0" _col(14) "`vline'`head2'"
        di in g `smcl' _dup(13) "`dash'" "`plussgn'" _dup(`todupz') "`dash'"

        tokenize `prnnum2'
        local count = 1
        while "``count''" != "" {
* 1.9.1 add indx and change count to indx in matrices
            local indx: word `count' of `prnnum2' // 1.9.2
            local vname : word `count' of `prnlis2'
            if `p2'[1, `indx'] < `pcutoff' {
                local noprint "no"
                di in g `smcl' %12s "`vname'" in g _col(14) "`vline'" in y /*
                */ %10.5f `bnocon2'[1,`indx']   %9.3f `zval2'[1,`indx'] /*
                */ %8.3f `p2'[1,`indx'] _c
                if "`doeb'" == "yes" {
                    di %9.4f `eb2'[1,`indx'] %9.4f `ebx2'[1,`indx'] _c
                }
                if "`dopb'" == "yes" {
                    di %9.1f `pb2'[1,`indx'] %9.1f `pbx2'[1,`indx'] _c
                }
                 di %11.4f `sd2'[1, `indx']

               if "`matrix'"!="" {
                    matrix `nxtrow' = `bnocon2'[1, `indx']
                    matrix rownames `nxtrow' = `vname'
                    matrix `outb2' = (nullmat(`outb2') \ `nxtrow')
                    matrix `outz2' = (nullmat(`outz2') \ `zval2'[1,`indx'])
                    matrix `outp2' = (nullmat(`outp2') \ `p2'[1,`indx'])

                    if "`doeb'" == "yes" {
                        mat `outeb2' = (nullmat(`outeb2') \ `eb2'[1,`indx'])
                        mat `outebx2' = (nullmat(`outebx2') \ /*
                        */ `ebx2'[1,`indx'])
                    }
                    if "`dopb'" == "yes" {
                        mat `outpb2' = (nullmat(`outpb2') \ `pb2'[1,`indx'])
                        mat `outpbx2' = (nullmat(`outpbx2') \ /*
                        */ `pbx2'[1,`indx'])
                    }
                }
            } /* if `p'[1, `indx'] < `pcutoff' */
/* 1.9.0
            if `p2'[1, `count'] < `pcutoff' {
                local noprint "no"
                di in g `smcl' %12s "`vname'" in g _col(14) "`vline'" in y /*
                */ %10.5f `bnocon2'[1,`count']   %9.3f `zval2'[1,`count'] /*
                */ %8.3f `p2'[1,`count'] _c
                if "`doeb'" == "yes" {
                    di %9.4f `eb2'[1,`count'] %9.4f `ebx2'[1,`count'] _c
                }
                if "`dopb'" == "yes" {
                    di %9.1f `pb2'[1,`count'] %9.1f `pbx2'[1,`count'] _c
                }
                 di %11.4f `sd2'[1, `count']

               if "`matrix'"!="" {
                    matrix `nxtrow' = `bnocon2'[1, `count']
                    matrix rownames `nxtrow' = `vname'
                    matrix `outb2' = (nullmat(`outb2') \ `nxtrow')
                    matrix `outz2' = (nullmat(`outz2') \ `zval2'[1,`count'])
                    matrix `outp2' = (nullmat(`outp2') \ `p2'[1,`count'])

                    if "`doeb'" == "yes" {
                        mat `outeb2' = (nullmat(`outeb2') \ `eb2'[1,`count'])
                        mat `outebx2' = (nullmat(`outebx2') \ /*
                        */ `ebx2'[1,`count'])
                    }
                    if "`dopb'" == "yes" {
                        mat `outpb2' = (nullmat(`outpb2') \ `pb2'[1,`count'])
                        mat `outpbx2' = (nullmat(`outpbx2') \ /*
                        */ `pbx2'[1,`count'])
                    }
                }
            } /* if `p'[1, `count'] < `pcutoff' */
1.9.0 */
            local count = `count' + 1
        } /* while count */

        if "`constant'"=="constant" {
            di in g `smcl' %12s "_cons" in g _col(14) "`vline'" in y /*
            */ %10.5f `con2' %9.3f `contst2' %8.3f `conp2'
            if "`matrix'"!="" {
                return scalar cons2 = `con2'
                return scalar cons2_z = `contst2'
                return scalar cons2_p = `conp2'
            }
        }
        di in g `smcl' _dup(13) "`dash'" "`bottomt'" _dup(`todupz') "`dash'"

* vuong
        if e(vuong)~=. {
            local favor ""
            if e(vuong) > 0 {
                local p = normprob(-e(vuong))
                if e(cmd)=="zip" {
                    if `p'<.10 {local favor "favoring ZIP over PRM."}
                }
                else {
                    if `p'<.10 {local favor "favoring ZINB over NBRM."}
                }
            }
            else {
                local p = normprob(e(vuong))
                if e(cmd)=="zip" {
                    if `p'<.10 {local favor "favoring PRM over ZIP."}
                }
                else {
                    if `p'<.10 {local favor "favoring NBRM over ZINB."}
                }
            }

            di in green "  Vuong Test =" in y %6.2f e(vuong) in green /*
            */ " (p=" in ye %4.3f `p' in g ") `favor'"
            di in g `smcl' _dup(14) "`dash'"  _dup(`todupz') "`dash'"

        } /* vuong */


        if "`help'"=="help" {
            di in g "       b = raw coefficient"
            di in g "       z = z-score for test of b=0"
            di in g "   P>|z| = p-value for z-test"
            if "`doeb'" == "yes"  {
                di in g "     e^b = exp(b) = factor " /*
                */ "change in odds for unit increase in X"
                di in g " e^bStdX = exp(b*SD of X) = "/*
                */ "change in odds for SD increase in X"
            }
            if "`dopb'" == "yes" {
                di in g "       % = percent change in odds for unit"/*
                */ " increase in X"
                di in g "   %StdX = percent change in odds for SD"/*
                */ " increase in X"
            }
            di in g "   SDofX = standard deviation of X"
        } /* if "`help'"=="help" */
    } /* is -zip- or -zinb- */

*-> returns

    return local cmd `cmd'
    return scalar pvalue = `pcutoff'

    if "`noprint'" == "yes" {
        di _n in blu "(No results in which p < " %3.2f `pcutoff' ")"
        exit
    }

    if "`matrix'" == "" { exit }

    local allrows : rownames(`outb')

    if inlist("`e(cmd)'", "mlogit", "mprobit") {                //! changed bj 23jul2008
        mat rownames `outcon' = `allrows'
        mat colnames `outcon' = Group_1 Group_2
        mat `outcon' = `outcon''
        return matrix contrast `outcon'
    }

    mat colnames `outb' = b
    mat `outb' = `outb''
    return matrix b `outb'
    mat rownames `outp' = `allrows'
    mat colnames `outp' = p>|z|
    mat `outp' = `outp''
    return matrix b_p `outp'
    mat rownames `outz' = `allrows'
    mat colnames `outz' = z
    mat `outz' = `outz''
    return matrix b_z `outz'
    if "`isnosdx'"!="yes" {
        mat rownames `outsdx' = `allrows'
        mat colnames `outsdx' = SDofX
        mat `outsdx' = `outsdx''
        return matrix b_sdx `outsdx'
    }
    if "`dobx'"=="yes" {
        mat rownames `outbsx' = `allrows'
        mat colnames `outbsx' = bStdX
        mat `outbsx' = `outbsx''
        return matrix b_xs `outbsx'
    }
    if "`doby'"=="yes" {
        mat rownames `outbsy' = `allrows'
        mat colnames `outbsy' = bStdY
        mat `outbsy' = `outbsy''
        return matrix b_ys `outbsy'
    }
    if "`dobxy'"=="yes" {
        mat rownames `outbs' = `allrows'
        mat colnames `outbs' = bStdXY
        mat `outbs' = `outbs''
        return matrix b_std `outbs'
    }
    if "`doeb'"=="yes" {
        mat rownames `outeb' = `allrows'
        mat colnames `outeb' = e^b
        mat `outeb' = `outeb''
        return matrix b_fact `outeb'
    }
    if "`doebx'"=="yes" {
        mat rownames `outebx' = `allrows'
        mat colnames `outebx' = e^bStdX
        mat `outebx' = `outebx''
        return matrix b_facts `outebx'

    }
    if "`dopb'"=="yes" {
        mat rownames `outpb' = `allrows'
        mat colnames `outpb' = %
        mat `outpb' = `outpb''
        return matrix b_pct `outpb'
    }
    if "`dopbx'"=="yes" {
        mat rownames `outpbx' = `allrows'
        mat colnames `outpbx' = %StdX
        mat `outpbx' = `outpbx''
        return matrix b_pcts `outpbx'
    }

    if "`iszero'"=="yes" {
        capture local allrows : rownames(`outb2')
        if _rc == 111 {
            exit 0
        }
        mat colnames `outb2' = b
        mat `outb2' = `outb2''
        return matrix b2 `outb2'
        mat rownames `outp2' = `allrows'
        mat colnames `outp2' = p>|z|
        mat `outp2' = `outp2''
        return matrix b2_p `outp2'
        mat rownames `outz2' = `allrows'
        mat colnames `outz2' = z
        mat `outz2' = `outz2''
        return matrix b2_z `outz2'
        if "`doeb'"=="yes" {
            mat rownames `outeb2' = `allrows'
            mat colnames `outeb2' = e^b
            mat `outeb2' = `outeb2''
            return matrix b2_fact `outeb2'
        }
        if "`doebx'"=="yes" {
            mat rownames `outebx2' = `allrows'
            mat colnames `outebx2' = e^bStdX
            mat `outebx2' = `outebx2''
            return matrix b2_facts `outebx2'
        }
        if "`dopb'"=="yes" {
            mat rownames `outpb2' = `allrows'
            mat colnames `outpb2' = %
            mat `outpb2' = `outpb2''
            return matrix b2_pct `outpb2'
        }
        if "`dopbx'"=="yes" {
            mat rownames `outpbx2' = `allrows'
            mat colnames `outpbx2' = %StdX
            mat `outpbx2' = `outpbx2''
            return matrix b2_pcts `outpbx2'
        }
    } /* if "`iszero'"=="yes" */
end

exit
* version 1.8.0 09Aug2005 change nominal terminology
* version 1.8.1 10Aug2005 fix label for slogit
* version 1.8.3b estout changes changes bj 23jul2008
* version 1.8.3 2008-06-15 jsl
*  - fix listcoef, matrix with mprobit
* version 1.8.4 2009-03-14
*  - esttab changes with bj 23jul2008
* version 1.8.6 2009-10-07 benn jann
*  - stata11 fix for mlogit
* version 1.9.0 2009-10-07 scott long
*  - stata11 fix for mlogit
* version 1.9.1 2010-06-04 scott long
*  - listcoef with selected vars for zi models
* version 1.9.2 2010-06-05 scott long
*  - listcoef with selected vars for zi models
* version 1.9.3 2010-12-21 jsl fix std after logistic
