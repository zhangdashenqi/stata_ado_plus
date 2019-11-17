*! version 3.3.0 2014-02-15 | long freese | spost13 release

//  list coefficients from last model - for Stata 11 and prior

capture program drop listcoef11
program define listcoef11, rclass

    version 11.2
    tempname coefs tempmat b bvec b1 b12 b2 bnocon bnocon2
    tempname bstd bstdx bstdy con2 conp2 conz2
    tempname expb expbstd expb2 expbstd2 pctb pctb2 pctbstd pctbstd2
    tempname dft factr lnalpha nobs nxtrow
    tempname outb outb2 outbstd outbstdx outbstdy outcon
    tempname outexpb outexpb2 outexpbstd outexpbstd2 outpval outpval2
    tempname outpctb outpctb2 outpctbstd outpctbstd2 outsdx
    tempname outse outz outz2 p p2 pcutoff
    tempname sd sd2 sdb sdb2 sdx sdy sdyobs
    tempname sdystar se vare vx z zval zval2
    tempname matconb matconz matconp slcat v noomit pval
    tempname tabrow tabout tab2row tab2out

    * used for r(table) and r(table2)
    local tabrownms ""
    local tabcolnms ""
    local tab2rownms ""
    local tab2colnms ""

    syntax [varlist(default=none fv)] ///
        [, PValue(real 0) Factor Percent Help Matrix ///
           Constant Odds Std Reverse gt lt ADJacent NOLabel EXpand ///
           Delta(real 1) debug(integer 0) ///
        ]

    local cmd "`e(cmd)'"
    if "`cmd'" == "" {
        di _n in r "listcoef must be run after a model is estimated"
        exit
    }

    local fvops = "`s(fvops)'"=="true" | _caller() >= 11
    if `fvops' {
        local eqns = 1 + cond("`iszero'"=="yes",1,0)
        forvalues i = 1/`eqns' {
            if `eqns' == 1 {
                _ms_extract_varlist `varlist' // , noomit
            }
            else {
                _ms_extract_varlist `varlist', noomit eq(#`i') nofatal
            }
            local list `list' `r(varlist)'
        }
        local varlist `list'
    }

    local noprint = "yes"
    local smcl "in smcl "
    local dash "{c -}"
    local vlin "{c |}"
    local plus "{c +}"
    local topT "{c TT}"
    local botT "{c BT}"

*   characteristics of each model
*
*   coeftyp: which types of coefficients can be computed
*     - bstdx  beta x-std          : bstdx
*     - bstdy  beta y-std          : bstdy
*     - bstd beta xy-std         : bstd
*     - expb  exp(beta)         : expb
*     - expbstd exp(beta x-std) : expstd
*     - pctb  %                   : pct
*     - pctbstd % xstd              : pctstd
*     - byopt

*   modltyp: model class
*     - tdist: use t not z for p-values
*     - count: count model
*     - zero:  zero-inflated model
*     - ystar: latent dependent variable
*     - ystd:
*     - special: own loop for calculating odds/std coefs
*     - nosdx: do not report sdx
*     - nocon: do not allow constant option

*   defhead: default header type
*     - std         - odds          - count

    if "`cmd'" == "regress" {
        local coeftyp "bstdx bstdy bstd"
        local modltyp "tdist ystd"
        local defhead "std"
    }
    if "`cmd'" == "logit" | "`cmd'" == "logistic" | "`cmd'" == "ologit" {
        local coeftyp "expb expbstd byopt pctb pctbstd bstdx bstdy bstd"
        local modltyp "ystar ystd reverse"
        local defhead "odds"
    }
    if "`cmd'" == "probit" | "`cmd'" == "oprobit" {
        local coeftyp "bstdx bstdy bstd"
        local modltyp "ystar ystd"
        local defhead "std"
    }
    if "`cmd'" == "cloglog" {
        local coeftyp "bstdx"
        local modltyp ""
        local defhead "std"
    }
    if "`cmd'" == "mlogit" {
        local coeftyp "expb expbstd byopt pctb pctbstd"
        local modltyp "special nocon"
        local defhead "odds"
    }
    if "`cmd'" == "mprobit" {
        local coeftyp "bstdx"
        local modltyp "special nocon"
        local defhead "std"
    }
    if "`cmd'" == "slogit" {
        local coeftyp "expb expbstd byopt pctb pctbstd"
        local modltyp "nocon"
        local defhead "odds"
        if e(k_dim) != 1 {
            di as err "listcoef only works for slogit ..., dim(1)"
            exit
        }
        * outcome categories must not have skips
        matrix `slcat' = e(outcomes)
        local slncats = e(k_out)
        local c1 = `slcat'[1,1]
        foreach i of numlist 2/`slncats'  {
            local c1p1 = `c1' + 1
            local c2 = `slcat'[`i',1]
            if `c2'!=`c1p1' {
                di as err ///
            "listcoef with slogit does not allows skips in outcome categories"
                exit
            }
            local c1 = `c2'
        }
    }
    if "`cmd'" == "clogit" | "`cmd'" == "rologit" {
        local coeftyp "expb byopt pctb"
        local modltyp "nosdx nocon reverse"
        local defhead "odds"
    }
    if "`cmd'" == "tobit" | "`cmd'" == "cnreg" | "`cmd'" == "intreg" {
        local coeftyp "bstdx bstdy bstd"
        local modltyp "tdist ystar ystd"
        local defhead "std"
    }
    if "`cmd'" == "poisson" | "`cmd'" == "nbreg" ///
        | "`cmd'" == "ztp" | "`cmd'" == "ztnb" {
        local coeftyp "expb expbstd byopt pctb pctbstd"
        local modltyp "count"
        local defhead "count"
    }
    if "`cmd'" == "zip" | "`cmd'" == "zinb" {
        local coeftyp "expb expbstd byopt pctb pctbstd"
        local modltyp "count zero"
        local defhead "count"
    }
    if "`coeftyp'" == "" {
        display as error "listcoef does not work with `e(cmd)'"
        exit
    }

//  unpack coeftyp

    local defopt = "yes"
    local ncoeftyps : word count `coeftyp'
    local count = 1
    while `count' <= `ncoeftyps' {
        local type : word `count' of `coeftyp'
        if ("`type'"=="bstdx") local dobstdx "`defopt'"
        if ("`type'"=="bstdy") local dobstdy "`defopt'"
        if ("`type'"=="bstd") local dobstd "`defopt'"
        if ("`type'"=="pctb") local dopctb "`defopt'"
        if ("`type'"=="pctbstd") local dopctbstd "`defopt'"
        if ("`type'"=="expb") local doexpb "`defopt'"
        if ("`type'"=="expbstd") local doexpbstd "`defopt'"
        if ("`type'"=="byopt") local defopt "option"
        local ++count
    }

//  parse options and check for errors

    local opterr "no"
    if "`std'" == "std" {
        if ("`dobstdx'"=="option") local dobstdx "yes"
        else if ("`dobstdx'"=="") local opterr "std"
        if ("`dobstdy'"=="option") local dobstdy "yes"
        if ("`dobstd'"=="option") local dobstd "yes"
        if ("`cmd'"=="ologit") local defhead "std"
        * if std, don't list these
        local doexpb ""
        local doexpbstd ""
        local dopctb ""
        local dopctbstd ""
    }
    if "`percent'"=="percent" & "`factor'"=="factor" {
        di in r "options percent and factor cannot both be used together"
        exit 198
    }
    if "`std'"=="std" & "`factor'"=="factor" {
        di in r "options std and factor cannot both be used together"
        exit 198
    }
    if "`std'" == "std" & "`percent'" == "percent" {
        di in r "options std and percent cannot both be used together"
        exit 198
    }
    if "`percent'" == "percent" {
        if "`dopctb'"=="option" {
            local dopctb "yes"
            if ("`doexpb'"=="yes") local doexpb ""
        }
        else if ("`dopctb'"=="") local opterr "percent"
        if "`dopctbstd'"=="option" {
            local dopctbstd "yes"
            if ("`doexpbstd'"=="yes") local doexpbstd ""
        }
    }
    if "`factor'" == "factor" {
        if "`doexpb'"=="option" {
            local doexpb "yes"
            if ("`dopctb'"=="yes") local dopctb ""
        }
        else if ("`doexpb'"=="") local opterr "odds"
        if "`doexpbstd'"=="option" {
            local doebstdx "yes"
            if ("`dopctbstd'"=="yes") local dopctbstd ""
        }
    }
    if "`opterr'" != "no" {
        di in r "option `opterr' not allowed after `cmd'"
        exit 198
    }

//  unpack mldtyp: define what to do for each type of model

    if (index("`modltyp'","tdist")==0) local tORz "z"
    else local tORz "t"
    if (index("`modltyp'","count")==0) local iscount "no"
    else local iscount "yes"
    if (index("`modltyp'","zero")==0) local iszero "no"
    else local iszero "yes"
    if (index("`modltyp'","ystar")==0) local isystar "no"
    else local isystar "yes"
    if (index("`modltyp'","ystd")==0) local isystd "no"
    else local isystd "yes"
    if (index("`modltyp'","special")==0) local isspec "no"
    else local isspec "yes"
    if (index("`modltyp'","nosdx")==0) local isnosdx "no"
    else local isnosdx "yes"
    if (index("`modltyp'","nocon")==0) local iscon "yes"
    else local iscon "no"
    if (index("`modltyp'","reverse")==0) local isrev "no"
    else local isrev "yes"

    if "`constant'"!="" & "`iscon'"=="no" {
        di in r "constant option not allowed for this model"
        exit 198
    }
    if "`reverse'"!="" & "`isrev'"=="no" {
        di in r "reverse option not allowed for this model"
        exit 198
    }

    * zip/zinb only work with logit inflation
    if ("`iszero'"=="yes") & ("`e(inflate)'"!="logit") {
       display as error ///
       "listcoef requires logit inflation for `cmd'"
        exit 198
    }

//  get model information

    scalar `nobs' = e(N)
    _rm_modelinfo2
    local rhsnms "`r(rhsnms)'"
    local nrhs "`r(rhsn)'"
    local rhsnmsbase "`r(rhs_betanmsbase)'"
    local rhsnms2 "`r(rhsnms2)'"
    local nrhs2 "`r(rhsn2)'"
    local lhsnam2 "`r(rhs2_cmdnms)'"
    local lhsnm "`r(lhsnm)'"
    local ncats `r(lhscatn)'

    if "`e(cmd)'"=="tobit"   | "`e(cmd)'"=="intreg"  | "`e(cmd)'"=="cnreg" ///
     | "`e(cmd)'"=="regress" | "`e(cmd)'"=="poisson" | "`e(cmd)'"=="nbreg" ///
     | "`e(cmd)'"=="ztp"     | "`e(cmd)'"=="ztnb"    | "`e(cmd)'"=="zip" ///
     | "`e(cmd)'"=="zinb" {
        local ncats = 2
    }
    local lhscatnms "`r(lhscatnms)'"
    local lhscatvals "`r(lhscatvals)'"
    local refcat "`r(lhsbaseval)'"
    if "`cmd'"=="mprobit" & `ncats'==2 {
        display as error ///
        "use probit instead of mprobit with binary outputs"
        exit
    }
    * labels for describing odds
    if "`cmd'"=="logit" | "`e(cmd)'"=="logistic" | "`e(cmd)'"=="clogit" {
        local nmFrom : word 2 of `lhscatnms'
        local nmTo   : word 1 of `lhscatnms'
    }
    if "`cmd'" == "ologit" {
        local nmFrom ">m"
        local nmTo   "<=m"
    }
    if "`cmd'" == "rologit" {
        local nmFrom "ranked ahead"
        local nmTo   "ranked behind"
    }
    if "`reverse'"!="" {
        local temp   "`nmFrom'"
        local nmFrom "`nmTo'"
        local nmTo   "`temp'"
    }

    * category labels for mlogit, mprobit
    if "`cmd'" == "mlogit" | "`cmd'" == "mprobit" {
        *        local catnms `lhscatnms'
        local catnms "`lhscatnms'" // 037
        local catnums `lhscatvals'
        if ("`nolabel'"=="nolabel") local catnms `catnums'
    }

    * information about weights
    if "`e(wtype)'"=="iweight" {
        di _n in r "listcoef does not work with iweights"
        exit 198
    }
    local wtis ""
    if ("`e(wtype)'"!="") local wtis "[`e(wtype)'`e(wexp)']"
    if "`e(wtype)'"=="pweight" {
        local wtis "[aweight`e(wexp)']"
        di in blu "(pweights not compatible with summarize;" ///
           in blu " weights will be treated as aweights)"
    }

    * check for constrained estimation
    if "`e(cmd)'"=="mlogit" | "`e(cmd)'"=="slogit" | "`e(cmd)'"=="mprobit" {
        local cmdline `e(cmdline)'
        local isconstraint = regexm("`cmdline'","[(a-zA-Z)]* c[a-z]*\(")
        if `isconstraint'==1 {
            display in red ///
            "listcoef does not allow constrained estimation for this model"
            exit
        }
    }

    * process e(b) and e(V)
    if "`e(cmd)'"=="mlogit" {
        local cmdline `e(cmdline)'
        local isconstraint = regexm("`cmdline'","[(a-zA-Z)]* c[a-z]*\(")
        if `isconstraint'==1 {
            display in red ///
            "listcoef does not allow constrained estimation for this model"
            exit
        }
        _rm_mlogitbv `b' `v'
        matrix `bvec' = vec(`b'')'
     }
    else if "`e(cmd)'"=="mprobit" {
        _rm_mlogitbv `b' `v'
        matrix `bvec' = vec(`b'')'
    }
    else { // not mlogit or mprobit
        matrix `b' = e(b)
        matrix `v' = e(V)
        local coln : colfullnames `b'
        local cols = colsof(`b')
        * get names of o. columns
        _ms_omit_info `b'
        matrix `noomit' = J(1,`cols',1) - r(omit)
        * take columns out of matrices
        mata: noomit = st_matrix(st_local("noomit"))
        mata: newb = select(st_matrix(st_local("b")), noomit)
        mata: st_matrix(st_local("b"),newb)
        mata: newv = select(select(st_matrix(st_local("v")), noomit), noomit')
        mata: st_matrix(st_local("v"),newv)
        * reassign column names to b
        foreach var of local coln {
            _ms_parse_parts `var'
            if (!`r(omit)') local coln2 `coln2' `var'
        }
        matrix colnames `b' = `coln2'
        matrix colnames `v' = `coln2'
        matrix rownames `v' = `coln2'
        matrix `sdb' = vecdiag(`v')
        local nb = colsof(`b')
        matrix `bnocon' = `b'[1,1..`nrhs'] // trim _con
        matrix coleq `bnocon' = _
        * recheck number of vars in case v(b)=0 removed

        * is there a constant
        local bnms : colnames(e(b))
        local conpos : list posof "_cons" in bnms
        if "`iscon'"=="yes" & `conpos'!=0 {
            * get constants
            matrix `matconb' = `b'[1,`nrhs'+1..`nrhs'+`ncats'-1]
            matrix `matconz' = `matconb'
            matrix `matconp' = `matconb'
            local i = 1
            while `i' < `ncats' {
                matrix `matconz'[1,`i'] ///
                    = `matconb'[1,`i'] / sqrt(`sdb'[1,`nrhs'+`i'])
                if "`tORz'"=="t" {
                    scalar `dft' = `nobs'-e(df_m)-1
                    matrix `matconp'[1,`i'] = tprob(`dft',-abs(`matconz'[1,`i']))
                }
                else {
                    matrix `matconp'[1,`i'] = 2*normprob(-abs(`matconz'[1,`i']))
                }
                local ++i
            }
        }
    } // not mlogit or mprobit

//  slogit coefficients

    if "`cmd'" == "slogit" {
        tempname slb slV slbeta slphi sltheta slcatnum slthetaV
        local slnvars = e(df_m) // # of rhs variables
        matrix `slb' = e(b)
        matrix `slV' = e(V)
        matrix `slb' = `b' // after omit
        matrix `slV' = `v' // after omit
        local slncats   = e(k_out)
        local slncatsm1 = e(k_out) - 1
        local slnphi   = e(k_out) - 1
        local slntheta = `slnphi'
        local slrefnum = e(i_base) // number of reference category
        local slrefnm `e(out`slrefnum')'
        * which row in e(outcomes)?
        matrix `slcatnum' = e(outcomes) // values for cats regardless of base
        matrix `slcatnum' = `slcatnum''
        local slrefrow = 0
        foreach i of numlist 1/`slncats'  {
            local cati = `slcatnum'[1,`i']
            if (`slrefnum'==`cati') local slrefrow = `i'
        }
        * if 1 is reference, from category is 2
        local slfromnum = 1
        if `slrefnum'==1 local slfromnum = 2
        local slfromnm `e(out`slfromnum')'
        matrix `slbeta' = `slb'[1,1..`slnvars']
        matrix `slphi' = `b' // after omit
        matrix `slphi' = `slphi'[1,`slnvars'+1..`slnvars'+`slncatsm1'],(0)
        matrix `sltheta' = `b' // after omit
        matrix `sltheta' = ///
          `sltheta'[1,`slnvars'+`slncatsm1'+1..`slnvars'+2*`slncatsm1'],(0)
        matrix `slthetaV' = ///
          `slV'[`slnvars'+`slncatsm1'+1..`slnvars'+2*`slncatsm1',.]
        matrix `slthetaV' = ///
           `slthetaV'[.,`slnvars'+`slncatsm1'+1..`slnvars'+2*`slncatsm1']
        * get theta# and phi#_# names
        local slphinm   : coleq `slphi'
        local slthetanm : coleq `sltheta'
        local nmFrom "`slrefnm'"
        * comparison category for beta's
        local nmTo "`slfromnm'"
    } // slogit

    * coefficients for 2nd equation for zip and zinb
    if "`iszero'"=="yes" {
        scalar `con2' = `b'[1,`nrhs'+2+`nrhs2']
        scalar `conz2' = `con2'/sqrt(`sdb'[1,`nrhs'+2+`nrhs2'])
        scalar `conp2' = 2*normprob(-abs(`conz2'))
        matrix `bnocon2' = `b'[1,(`nrhs'+2)..(`nrhs'+`nrhs2'+1)]
        matrix coleq `bnocon2' = _
        matrix `sdb2' = `sdb'[1,(`nrhs'+2)..(`nrhs'+`nrhs2'+1)]
        _rm_sum `wtis' if e(sample)==1, two
        matrix `sd2' = r(matsd)
        matrix `sd2' = `sd2'[1,2...] // trim off lhs variable
    }

    * sd_x and sdy
    _rm_sum `wtis' if e(sample) == 1
    matrix `sd' = r(matsd)
    scalar `sdy' = `sd'[1,1]
    scalar `sdyobs' = `sdy'
    matrix `sd' = `sd'[1,2...]  /* trim off lhs variable */

//  parse varlist

    * prnlist: list and order of variables to print
    * prnnums: numbers of variable in matrices
    if "`varlist'" == "" {
        local prnlist "`rhsnms'"
        local count = 1
        while `count' <= `nrhs' {
            local prnnums "`prnnums' `count'"
            local ++count
        }
        if "`iszero'"=="yes" {
            local prnlis2 "`rhsnms2'"
            local count = 1
            while `count' <= `nrhs2' {
                local prnnum2 "`prnnum2' `count'"
                local ++count
            }
        }
    }
    * if varlist specified, print output in varlist order
    else {
        _ms_extract_varlist `rhsnms', eq(#1)
        local rhsnms `r(varlist)'
        if "`iszero'"=="yes" {
            _ms_extract_varlist `rhsnms2', eq(#2)
            local rhsnms2 `r(varlist)'
        }
        local count = 1
        local countto : word count `varlist'
        tokenize `varlist'
        while `count' <= `countto' {
            local count2 = 1
            local found = "no"
            while `count2' <= `nrhs' {
                local rhstmp : word `count2' of `rhsnms'
                if "``count''" == "`rhstmp'" {
                    local prnlist "`prnlist' `rhstmp'"
                    local prnnums "`prnnums' `count2'"
                    local found = "yes"
                }
                local ++count2
            }
            if "`iszero'"=="yes" {
                local count2 = 1
                while `count2' <= `nrhs2' {
                    local rhstmp : word `count2' of `rhsnms2'
                    if "``count''" == "`rhstmp'" {
                        local prnlis2 "`prnlis2' `rhstmp'"
                        local prnnum2 "`prnnum2' `count2'"
                        local found = "yes"
                    }
                    local ++count2
                }
            }
            if "`found'" == "no" {
               di in r "``count'' is not an independent variable"
               exit 198
            }
            local ++count
        }
    } // if a varlist has been specified

//  parse pvalue option

    scalar `pcutoff' = `pvalue'
    * allow pcutoff(5) to represent pcutoff(.05)
    if (`pcutoff'>=1 & `pcutoff'<= 100) scalar `pcutoff' = `pcutoff' / 100
    if (`pcutoff'==0) scalar `pcutoff' = 1.00
    if `pcutoff' < 0 | `pcutoff' > 1 {
        di in r "pvalue() must be valid nonzero probability"
        exit 198
    }

//  model is not special case

    if "`isspec'"=="no" {

        * compute sd(y*)
        if "`isystar'"=="yes" {
            * get cov(rhs) for computing var(y*)
            * 321 fix accmu with i.catvar 2013-09-01
            quietly matrix accum `vx' = `lhsnm' `rhsnmsbase' `wtis' ///
                if e(sample)==1 `in', deviations noconstant
            * removed omitted variables from cross product matrix
            _ms_omit_info `vx'
            local cols = colsof(`vx')
            matrix `noomit' = J(1,`cols',1) - r(omit)
            mata: noomit = st_matrix(st_local("noomit"))
            mata: newvx = select(select(st_matrix(st_local("vx")), noomit), noomit')
            mata: st_matrix(st_local("vx"),newvx)
            matrix `vx' = `vx'[2...,2...] // trim off lhs variable
            scalar `factr' = 1/(`nobs'-1) // 1 over nobs - 1
            matrix `vx' = `factr' * `vx'
            matrix `sdystar' = `bnocon' * `vx'
            matrix `sdystar' = `sdystar' * `bnocon''
            matrix `vare' = J(1,1,1) // default for probit
            scalar `factr' = 1
            if "`e(cmd)'"=="logit" | "`e(cmd)'"=="ologit" {
                scalar `factr' = (_pi*_pi)/3
            }
            if "`e(cmd)'"=="tobit" | "`e(cmd)'"=="intreg" | ///
                "`e(cmd)'"=="cnreg" {
                scalar `factr' = `b'[1,(`nrhs'+2)]*`b'[1,(`nrhs'+2)]
            }
            matrix `vare' = `factr' * `vare'
            matrix `sdystar' = `sdystar' + `vare'
            scalar `sdy' = sqrt(`sdystar'[1,1])
        }

        * compute standardized coefficients, t's, z's and p's
        local nx = colsof(`sd')
        matrix `bstdy' = `bnocon'
        matrix `bstdx' = `bnocon'
        matrix `bstd' = `bnocon'
        matrix `expb' = `bnocon'
        matrix `expbstd' = `bnocon'
        matrix `pctb' = `bnocon'
        matrix `pctbstd' = `bnocon'
        matrix `zval' = `bnocon'
        matrix `p' = `bnocon'
        scalar `factr' = 1/`sdy'
        matrix `bstdy' = `factr' * `bstdy' // y-standardized betas

        * loop through x's
        local i = 1
        while `i'<=`nx' {
            matrix `sdb'[1,`i']  = sqrt(`sdb'[1,`i']) // sd of b's
            scalar `sdx' = `sd'[1,`i']
            * change by delta, not 1 sd
            if (`delta'!=1) scalar `sdx' = `delta'
            matrix `bstdx'[1,`i']  = `bnocon'[1,`i']*`sdx' // b*sd_x
            matrix `bstd'[1,`i']   = `bstdy'[1,`i']*`sdx' // b*sd_x/sd_y)
            scalar `b1' = `b'[1,`i']
            * factor change
            matrix `expb'[1,`i'] = exp(`b1')
            matrix `expbstd'[1,`i'] = exp(`b1'*`sdx')
            * percent change
            matrix `pctb'[1,`i'] = (exp(`b1')-1)*100
            matrix `pctbstd'[1,`i'] = (exp(`b1'*`sdx')-1)*100
            if "`reverse'"!="" {
                * factor change
                matrix `expb'[1,`i'] = 1/exp(`b1')
                matrix `expbstd'[1,`i'] = 1/exp(`b1'*`sdx')
                * percent change
                matrix `pctb'[1,`i'] = ((1/exp(`b1'))-1)*100
                matrix `pctbstd'[1,`i'] = ((1/exp(`b1'*`sdx'))-1)*100
            }
            * z, t, and p
            matrix `zval'[1,`i'] = `bnocon'[1,`i']/`sdb'[1,`i'] // t/z of b
            if "`tORz'"=="t" {
                scalar `dft' = `nobs'-e(df_m)-1
                matrix `p'[1,`i'] = tprob(`dft',-abs(`zval'[1,`i']))
            }
            else {
                matrix `p'[1,`i'] = 2*normprob(-abs(`zval'[1,`i']))
            }
            local ++i
        }

        * coefficients for zip and zinb
        if "`iszero'"=="yes" {
            matrix `zval2' = `bnocon2'
            matrix `p2' = `bnocon2'
            matrix `expb2' = `bnocon2'
            matrix `expbstd2' = `bnocon2'
            matrix `pctb2' = `bnocon2'
            matrix `pctbstd2' = `bnocon2'
            local nx2 = colsof(`sd2')
            local i = 1
            while `i'<=`nx2' {
                matrix `sdb2'[1,`i'] = sqrt(`sdb2'[1,`i']) // sd of b's
                matrix `zval2'[1,`i'] = `bnocon2'[1,`i']/`sdb2'[1,`i']
                matrix `p2'[1,`i'] = 2*normprob(-abs(`zval2'[1,`i']))
                matrix `expb2'[1,`i'] = exp(`bnocon2'[1,`i'])
                matrix `expbstd2'[1,`i'] = exp(`bnocon2'[1,`i']*`sd2'[1,`i'])
                matrix `pctb2'[1,`i'] = (exp(`bnocon2'[1,`i'])-1)*100
                matrix `pctbstd2'[1,`i'] ///
                    = (exp(`bnocon2'[1,`i']*`sd2'[1,`i'])-1)*100
                local ++i
            }
        }

//  print headers

        di _n in g "`cmd' (N=" in y `nobs' in g "): " _c
        if "`defhead'"=="std" | "`std'"=="std" {
            di in g "Unstandardized and Standardized Estimates " _c
            if `pcutoff' < 1 & `pcutoff' >= .01 {
                di in g "when P>|`tORz'| < " in y %3.2f `pcutoff' _c
            }
            else if `pcutoff' < .01 & `pcutoff' > 0 {
                di in g "when P>|`tORz'| < " in y `pcutoff' _c
            }
            di
        }
        else {
            local header "Factor"
            if ("`percent'"=="percent") local header "Percentage"
            if "`defhead'"=="odds" | "`factor'"=="factor" {
                di in g "`header' Change in Odds " _c
                if `pcutoff' < 1 & `pcutoff' >= .01 {
                    di in g "when P>|`tORz'| < " in y %3.2f `pcutoff' _c
                }
                if `pcutoff' < .01 & `pcutoff' > 0 {
                    di in g "when P>|`tORz'| < " in y `pcutoff' _c
                }
                di
            }
            else if "`defhead'"=="count" {
                di in g "`header' Change in Expected Count " _c
                if `pcutoff' < 1 & `pcutoff' >= .01 {
                    di in g "when P>|`tORz'| < " in y %3.2f `pcutoff' _c
                }
                if `pcutoff' < .01 & `pcutoff' > 0 {
                    di in g "when P>|`tORz'| < " in y `pcutoff' _c
                }
                di
            }
        }

        if "`cmd'"=="intreg" {
            di _n in gr "    LHS vars: " in y "`e(depvar)'" _c
        }

        if ("`defhead'"=="std" | "`std'"=="std") | ("`defhead'"=="count") {
            di _n in gr " Observed SD: " in y `sdyobs'
            if "`isystar'"=="yes" {
                di in g "   Latent SD: " in y `sdy'
            }
        }

        if ("`cmd'"=="regress") di in gr " SD of Error: " in y e(rmse)
        if "`cmd'" == "tobit" | "`cmd'" == "cnreg" | "`cmd'" == "intreg" {
            local sde = `b'[1,`nrhs'+2]
            di in gr " SD of Error: " in y `sde'
        }

        if "`defhead'"=="odds" | "`factor'"=="factor" {
            di _n in g "  Odds of: " in y "`nmFrom'" in g " vs " in y "`nmTo'"
        }

        if "`iszero'"=="yes" {
            local header "Factor"
            if ("`percent'"=="percent") local header "Percentage"
            di _n in g "Count Equation: `header' Change in Expected " ///
                "Count for Those Not Always 0"
        }

//  header for columns

        local head2   "      b         `tORz'     P>|`tORz'|"

        if `delta'!=1 { // delta option
            if ("`dobstdx'"=="yes") local head2 "`head2'   bDeltaX"
            if ("`dobstdy'"=="yes") local head2 "`head2'   bStdY"
            if ("`dobstd'"=="yes") local head2 "`head2' bDeltaStdY"
            if ("`doexpb'"=="yes") local head2 "`head2'    e^b  "
            if ("`doexpbstd'"=="yes") local head2 "`head2' e^bDelta"
            if ("`dopctb'"=="yes") local head2 "`head2'      %  "
            if ("`dopctbstd'"=="yes") local head2 "`head2'    %StdX"
            if "`dobstdy'"=="yes" { // std coef
                if ("`isnosdx'"!="yes") local head2 "`head2'    Delta"
            }
            else { // e(b)
                if ("`isnosdx'"!="yes") local head2  "`head2'      Delta"
            }
        }
        else{ // no delta option
            if ("`dobstdx'"=="yes") local head2 "`head2'    bStdX"
            if ("`dobstdy'"=="yes") local head2 "`head2'    bStdY"
            if ("`dobstd'"=="yes") local head2 "`head2'   bStdXY"
            if ("`doexpb'"=="yes") local head2 "`head2'    e^b  "
            if ("`doexpbstd'"=="yes") local head2 "`head2'  e^bStdX"
            if ("`dopctb'"=="yes") local head2 "`head2'      %  "
            if ("`dopctbstd'"=="yes") local head2 "`head2'    %StdX"
            if ("`isnosdx'"!="yes") local head2 "`head2'      SDofX"
        }
        local todup = length("`head2'")
        di in g `smcl' _n _dup(13) "`dash'" "`topT'" _dup(`todup') "`dash'"
        local lhsnm = abbrev("`lhsnm'", 12)
        * no lhs for for intreg
        if ("`cmd'"=="intreg") di in g _col(14) `smcl' "`vlin'`head2'"
        else di in g %12s "`lhsnm'" _col(14) `smcl' "`vlin'`head2'"
        di in g `smcl' _dup(13) "`dash'" "`plus'" _dup(`todup') "`dash'"

//  print coefficients

        tokenize `prnnums'
        local count = 1
        while "``count''" != "" {
            local indx: word `count' of `prnnums'
            local vname: word `count' of `prnlist'
            local vname2 "`vname'"
            local vname = abbrev("`vname'", 12)
            if `p'[1, `indx'] < `pcutoff' {
                local noprint "no"
                di in g `smcl' %12s "`vname'" in g _col(14) "`vlin'" in y ///
                    %10.5f `bnocon'[1,`indx']   %9.3f `zval'[1,`indx'] ///
                    %8.3f `p'[1,`indx'] _c
                matrix `tabrow' ///
                  = `bnocon'[1,`indx'], `zval'[1,`indx'], `p'[1,`indx']
                local tabcolnms "b z pvalue"
                if "`dobstdx'"=="yes" {
                    di %9.4f `bstdx'[1,`indx'] _c
                    matrix `tabrow' = `tabrow', `bstdx'[1,`indx']
                    local tabcolnms "`tabcolnms' bstdx"
                }
                if "`dobstdy'"=="yes" {
                    di %9.4f `bstdy'[1,`indx'] _c
                    matrix `tabrow' = `tabrow', `bstdy'[1,`indx']
                    local tabcolnms "`tabcolnms' bstdy"
                }
                if "`dobstd'"=="yes" {
                    di %9.4f `bstd'[1,`indx'] _c
                    matrix `tabrow' = `tabrow', `bstd'[1,`indx']
                    local tabcolnms "`tabcolnms' bstd"
                }
                if "`doexpb'"=="yes" {
                    di %9.4f `expb'[1,`indx'] _c
                    matrix `tabrow' = `tabrow', `expb'[1,`indx']
                    local tabcolnms "`tabcolnms' expb"
                }
                if "`doexpbstd'"=="yes" {
                    di %9.4f `expbstd'[1,`indx'] _c
                    matrix `tabrow' = `tabrow', `expbstd'[1,`indx']
                    local tabcolnms "`tabcolnms' expbstd"
                }
                if "`dopctb'"=="yes" {
                    di %9.1f `pctb'[1,`indx'] _c
                    matrix `tabrow' = `tabrow', `pctb'[1,`indx']
                    local tabcolnms "`tabcolnms' pctb"
                }
                if "`dopctbstd'"=="yes" {
                    di %9.1f `pctbstd'[1,`indx'] _c
                    matrix `tabrow' = `tabrow', `pctbstd'[1,`indx']
                    local tabcolnms "`tabcolnms' pctbstd"
                }

                if `delta'!=1 {  // delta option
                    if ("`isnosdx'"!="yes") {
                        di %11.4f `delta'
                        matrix `tabrow' = `tabrow', `delta'
                        local tabcolnms "`tabcolnms' delta"
                    }
                    else di
                }
                else {
                    if ("`isnosdx'"!="yes") {
                        di %11.4f `sd'[1,`indx']
                        matrix `tabrow' = `tabrow', `sd'[1,`indx']
                        local tabcolnms "`tabcolnms' sdx"
                    }
                    else di
                }

                * enter values in matrices to be returned
                if "`matrix'"!="" {
                    matrix `nxtrow' = `bnocon'[1, `indx']
                    matrix rownames `nxtrow' = `vname2'
                    matrix `outb' = (nullmat(`outb') \ `nxtrow')
                    matrix `outz' = (nullmat(`outz') \ `zval'[1,`indx'])
                    matrix `outpval' = (nullmat(`outpval') \ `p'[1, `indx'])
                    matrix `outsdx' = (nullmat(`outsdx') \ `sd'[1, `indx'])
                    if "`dobstdx'" == "yes"  {
                        matrix `outbstdx' = (nullmat(`outbstdx') \ `bstdx'[1,`indx'])
                    }
                    if "`dobstdy'" == "yes" {
                        matrix `outbstdy' = (nullmat(`outbstdy') \ `bstdy'[1,`indx'])
                    }
                    if "`dobstd'" == "yes" {
                        matrix `outbstd' = (nullmat(`outbstd') \ `bstd'[1,`indx'])
                    }
                    if "`doexpb'" == "yes" {
                        matrix `outexpb' = (nullmat(`outexpb') \ `expb'[1,`indx'])
                    }
                    if "`doexpbstd'" == "yes" {
                        matrix `outexpbstd' = (nullmat(`outexpbstd') \ `expbstd'[1,`indx'])
                    }
                    if "`dopctb'" == "yes" {
                        matrix `outpctb' = (nullmat(`outpctb') \ `pctb'[1,`indx'])
                    }
                    if "`dopctbstd'" == "yes" {
                        matrix `outpctbstd' = (nullmat(`outpctbstd') \ `pctbstd'[1,`indx'])
                    }
                } // matrix
                local tabrownms "`tabrownms' `vname'"
                matrix `tabout' = nullmat(`tabout') \ `tabrow'
                local tabncols = colsof(`tabrow')
            } // if `p'[1, `indx']<`pcutoff'

            local count = `count' + 1

        } // loop through varlist

        if "`constant'"=="constant" & "`iscon'"=="yes" {
            if `ncats'==2 {
                di in g `smcl' %12s "_cons" in g _col(14) "`vlin'" ///
                    in y %10.5f `matconb'[1,1] %9.3f `matconz'[1,1] ///
                    %8.3f `matconp'[1,1]
                matrix `tabrow' = J(1,`tabncols',.)
                matrix `tabrow'[1,1] = `matconb'[1,1]
                matrix `tabrow'[1,2] = `matconz'[1,1]
                matrix `tabrow'[1,3] = `matconp'[1,1]
                local tabrownms "`tabrownms' constant"
                matrix `tabout' = nullmat(`tabout') \ `tabrow'
                if "`matrix'"!="" {
                    return scalar cons = `matconb'[1,1]
                    return scalar cons_z = `matconz'[1,1]
                    return scalar cons_p = `matconp'[1,1]
                }
            }
            else {
                di in g `smcl' _dup(13) "`dash'" "`plus'" _dup(`todup') "`dash'"
                local i = 1
                while `i' < `ncats' {
                    di in g `smcl' %12s "_cut`i'" in g _col(14) "`vlin'" ///
                        in y %10.5f `matconb'[1,`i'] %9.3f `matconz'[1,`i'] ///
                        %8.3f `matconp'[1,`i']
                    matrix `tabrow' = J(1,`tabncols',.)
                    matrix `tabrow'[1,1] = `matconb'[1,`i']
                    matrix `tabrow'[1,2] = `matconz'[1,`i']
                    matrix `tabrow'[1,3] = `matconp'[1,`i']
                    local tabrownms "`tabrownms' constant`i'"
                    matrix `tabout' = nullmat(`tabout') \ `tabrow'
                    local i = `i' + 1
                }
            } // more than one constant
        }

        * alpha for neg bin models
        if "`cmd'"=="zinb" | "`cmd'"=="nbreg" ///
                | "`cmd'"=="ztnb" {
            di in g `smcl' _dup(13) "`dash'" "`plus'" _dup(`todup') "`dash'"

            scalar `lnalpha' = `b'[1,`nb']
            quietly _diparm lnalpha, exp label("alpha") noprob
            di `smcl' in g "    ln alpha" _col(14) "`vlin'" ///
                in y %10.5f `lnalpha'
            di `smcl' in g "       alpha" _col(14) "`vlin'" ///
                in y %10.5f r(est) in g "   SE(alpha) = " in y %-9.5f r(se)
        }

        * phi and theta for slogit models
        if "`e(cmd)'" == "slogit" {

            tempname b V
            matrix `b' = e(b)
            matrix `V' = e(V)

            * print phis
            di in g `smcl' _dup(13) "`dash'" "`plus'" _dup(`todup') "`dash'"
            forvalues num = 1(1)`slnphi' {
                tempname phi Vphi sdphi zphi pphi
                scalar `phi' = `b'[1, `i'] // grab phi
                local phinm : word `num' of `slphinm'
                scalar `Vphi' = `V'[`i', `i']
                scalar `sdphi' = sqrt(`Vphi')
                scalar `zphi' = `phi'/`sdphi'
                scalar `pphi' = 2*normprob(-abs(`zphi'))
                di as txt %12s "`phinm'" _col(14) "`vlin'" as res %10.5f `phi' ///
                    %9.3f `zphi'  %8.3f `pphi'
                local i = `i' + 1
            }

            * print thetas
            di in g `smcl' _dup(13) "`dash'" "`plus'" _dup(`todup') "`dash'"
            forvalues num = 1(1)`slntheta' {
                tempname thetamat theta thetaVmat thetaV thetasd thetaz thetap
                local thetanm : word `num' of `slthetanm'
                scalar `theta' = `sltheta'[1,`num']
                scalar `thetaV' = `slthetaV'[`num',`num']
                scalar `thetasd' = sqrt(`thetaV')
                scalar `thetaz' = `theta' / `thetasd'
                scalar `thetap' = 2*normprob(-abs(`thetaz'))
                di as txt %12s "`thetanm'" _col(14) "`vlin'" as res %10.5f `theta' ///
                    %9.3f `thetaz'  %8.3f `thetap'
                local i = `i' + 1
            }
        } // end slogit - non expanded output

        * bottom border
        di in g `smcl' _dup(13) "`dash'" "`botT'" _dup(`todup') "`dash'"

        * LR test: code based on nbreg.ado version 3.3.9 06dec2000
        if "`e(cmd)'"=="nbreg" | "`cmd'" == "ztnb" {
            if ((e(chi2_c)>0.005) & (e(chi2_c)<1e4)) | (ln(e(alpha))<-20) {
                local fmt "%-8.2f"
            }
            else local fmt "%-8.2e"
            scalar `pval' = chiprob(1, e(chi2_c))*0.5
            if (ln(e(alpha))<-20) scalar `pval'= 1
            di in g `smcl' " LR test of alpha=0: " ///
                in y `fmt' e(chi2_c) in g " Prob>=LRX2 = " in y %5.3f ///
                `pval'
            di in g `smcl' _dup(14) "`dash'" _dup(`todup') "`dash'"
        }
        matrix rownames `tabout' = `tabrownms'
        matrix colnames `tabout' = `tabcolnms'
        return matrix table = `tabout'
    } // if "`isspec'"=="no"

//  printing of non-standard models follows

//  mlogit : special model

* for mloigt and mprobit, e(b) and e(V) have this structure:
*   varorder: v1 v2 ... _con
*   catorder: c1 c2 c3 ...
*   blkc#: c#1_v1 c#_v2 ... c#_con
*   bvec: blkc1 blkc2 blkc3  [1X(nvar+1)*(ncat-1)]
*   v = blkc1Xblkc1
*       blkc2Xblkc1 blkc2Xblkc2
*       blkc3Xblkc1 blkc3Xblkc2 blkc3Xblkc3

    if "`cmd'" == "mlogit" {
        display _n in g "`cmd' (N=" in y `nobs' in g "): " _c
        local pcttext "Factor"
        if ("`percent'"=="percent") local pcttext = "Percentage"
        display in g "`pcttext' Change in the Odds of " in y "`lhsnm' " _c
        if `pcutoff' < 1 & `pcutoff' >= .01 {
            display in g "when P>|z| < " in y %3.2f `pcutoff' _c
        }
        if `pcutoff' < .01 & `pcutoff' > 0 {
            display in g "when P>|z| < " in y `pcutoff' _c
        }
        display
        tokenize "`prnnums'"
        local count = 1

        * max length of category labels
        local icat = 1
        local maxlen_catnm = 0
        while `icat' <= `ncats' {
            local catnum  : word `icat' of `catnums'
            local lcatnum = length("`catnum'")
            local catnm   : word `icat' of `catnms'
            local lcatnm = length("`catnm'")
            if (`lcatnum'>`maxlen_catnm') local maxlen_catnm = `lcatnum'
            if (`lcatnm'>`maxlen_catnm') local maxlen_catnm = `lcatnm'
            local ++icat
        }
        if (`maxlen_catnm'>15) local maxlen_catnm = 15 // to limit to 80 cols
        if (`maxlen_catnm'<11) local maxlen_catnm = 11
        local COLvbar = (`maxlen_catnm'*2 + 5)
        local COLvbar_1 = `COLvbar' - 1
        local COLcolon = `maxlen_catnm' + 2
        while "``count''" != "" {
          local ivar = "``count''"
          scalar `sdx' = `sd'[1,`ivar']
          local vname: word `ivar' of `rhsnms'
          _ms_parse_parts `vname'
          if !`r(omit)' {
            di _n in g "Variable: " in y "`vname' " ///
                in g "(sd=" in y `sdx' in g ")"
            local head2   "      b         z     P>|z|"
            if ("`doexpb'"=="yes") local head2   "`head2'     e^b "
            else local head2 "`head2'       % "
            if ("`doexpbstd'"=="yes") local head2   "`head2'  e^bStdX"
            else local head2 "`head2'    %StdX"
            local todup = length("`head2'")
            di in g `smcl' _new "Category 1" _col(`COLcolon')  ///
                ": Category 2" _col(`COLvbar') "`vlin'`head2'"
            di in g `smcl' _dup(`COLvbar_1') "`dash'" "`plus'" ///
                _dup(`todup') "`dash'"

            // loop through categories

            local b1cat 1 // 1...#cats but not necessarily the value of
                          // the category : see b1catnum for that
            local b2cat 0
            local b1block 0
            while `b1cat' <= `ncats' {
              local b1catnum  : word `b1cat' of `catnums'
              local b1catnm   : word `b1cat' of `catnms'
              * truncate long names
              local lnm = length("`b1catnm'")
              if `lnm'>`maxlen_catnm' {
                local b1catnm = substr("`b1catnm'",1,`maxlen_catnm')
              }
              * if not refcat, use next block of coefficients
              if (`b1catnum'!=`refcat') local ++b1block
              * the category # of the variable
              local b2block 0

              while `b2cat' < `ncats' {
                local ++b2cat
                local b2catnum  : word `b2cat' of `catnums'
                local b2catnm : word `b2cat' of `catnms'
                * truncate long names
                local lnm = length("`b2catnm'")
                if (`lnm'>`maxlen_catnm') {
                    local b2catnm = substr("`b2catnm'",1,`maxlen_catnm')
                }

                * if not refcat, use next block of coefficients
                if (`b2catnum'!=`refcat') local ++b2block
                local b1indx = `ivar' + ((`b1block'-1)*(`nrhs'+1))
                local b2indx = `ivar' + ((`b2block'-1)*(`nrhs'+1))
                * if both reference category, don't proccess
                if (`b1catnum'==`refcat') & (`b2catnum'==`refcat') {
                    continue
                }

                * get b for b1cat and b2cat
                if (`b1catnum'==`refcat') scalar `b1' = 0
                else scalar `b1' = `bvec'[1,`b1indx']
                if (`b2catnum'==`refcat') scalar `b2' = 0
                else scalar `b2' = `bvec'[1,`b2indx']

                * compute statistics for b1cat b1cat contrast
                scalar `b12' = `b1'-`b2'
                scalar `expb'  = exp(`b12')
                scalar `expbstd' = exp(`b12'*`sdx')
                scalar `pctb'  = (`expb'-1)*100
                scalar `pctbstd' = (`expbstd'-1)*100

                * standard error of contrast
                if `b1cat'!=`refcat' & `b2cat'==`refcat' {
                    scalar `se' = sqrt(`v'[`b1indx',`b1indx'])
                }
                if `b1catnum'==`refcat' & `b2catnum'!=`refcat' {
                    scalar `se' = sqrt(`v'[`b2indx',`b2indx'])
                }
                if `b1catnum'!=`refcat' & `b2catnum'!=`refcat' {
                    scalar `se' = sqrt(`v'[`b1indx',`b1indx'] ///
                        + `v'[`b2indx',`b2indx'] ///
                        - 2*`v'[`b1indx',`b2indx'])
                }
                scalar `z' = `b12'/`se'
                scalar `p' = 2*normprob(-abs(`z'))

                if `p' <= `pcutoff' {
                  local noprint = "no"
                  if "`matrix'"!="" {
                    matrix `nxtrow' = `b12'
                    matrix rownames `nxtrow' = `vname'
                    matrix `outb' = (nullmat(`outb') \ `nxtrow')
                    matrix `outcon' = ///
                        (nullmat(`outcon') \ `b1catnum', `b2catnum')
                    matrix `outsdx' = (nullmat(`outsdx') \ `sdx')
                    matrix `outexpb' = (nullmat(`outexpb') \ `expb')
                    matrix `outexpbstd' = (nullmat(`outexpbstd') \ `expbstd')
                    matrix `outpctb' = (nullmat(`outpctb') \ `pctb')
                    matrix `outpctbstd' = (nullmat(`outpctbstd') \ `pctbstd')
                    matrix `outz' = (nullmat(`outz') \ `z')
                    matrix `outpval' = (nullmat(`outpval') \ `p')
                    matrix `outse' = (nullmat(`outse') \ `se')
                  }
                  if ("`gt'"!="gt" & "`lt'"!="lt") ///
                        | ("`gt'"=="gt") & (`b1catnum'>`b2catnum') ///
                        | ("`lt'"=="lt") & (`b1catnum'<`b2catnum') {
                    local absdif = abs(`b1catnum'-`b2catnum')
                    if ("`adjacent'"=="adjacent" & `absdif'==1) ///
                        | "`adjacent'"!="adjacent" {
                      capture drop `tabrow'
                      * print categories
                      di in g `smcl' "`b1catnm'"   _col(`COLcolon') ///
                          ": `b2catnm'"   _col(`COLvbar') "`vlin'" in y ///
                          %10.5f `b12' %9.3f `z' %8.3f `p' _c
                      matrix `tabrow' = `b1catnum', `b2catnum', `b12', `z', `p'
                      local tabcolnms "Cat1 Cat2 b z pvalue"
                      if "`doexpb'"=="yes" {
                        di %9.4f `expb' _c
                        matrix `tabrow' = `tabrow', `expb'
                        local tabcolnms "`tabcolnms' expb"
                      }
                      else {
                        di %9.1f `pctb' _c
                        matrix `tabrow' = `tabrow', `pctb'
                        local tabcolnms "`tabcolnms' pctb"
                      }
                      if "`doexpbstd'"=="yes" {
                        di %9.4f `expbstd'
                        matrix `tabrow' = `tabrow', `expbstd'
                        local tabcolnms "`tabcolnms' expbstd"
                      }
                      else {
                        di %9.1f `pctbstd'
                        matrix `tabrow' = `tabrow', `pctbstd'
                        local tabcolnms "`tabcolnms' pctbstd"
                      }
                      matrix `tabrow' = `tabrow', `sdx'
                      local tabcolnms "`tabcolnms' sdx"
                      local tabrownms "`tabrownms' `vname'"
                      matrix `tabout' = nullmat(`tabout') \ `tabrow'
                    } // adjacent option
                  } // gt lt option
                } // `p' <= `pcutoff'
              } // while `b2cat' <= `ncats'
              local b2cat 0
              local ++b1cat
            } // b1cat
            di in g `smcl' _dup(`COLvbar_1') "`dash'" "`botT'" _dup(`todup') "`dash'"
          }
          local ++count
        } // while count
        matrix rownames `tabout' = `tabrownms'
        matrix colnames `tabout' = `tabcolnms'
        return matrix table = `tabout'
    } // if "`cmd'" == "mlogit"

//  mprobit: special model

    if "`cmd'" == "mprobit" {
        di _n in g "`cmd' (N=" in y `nobs' in g "): " _c
        di in g "Unstandardized and Standardized Estimates for " in y "`lhsnm' " _c
        if `pcutoff' < 1 & `pcutoff' >= .01 {
            di in g "when P>|z| < " in y %3.2f `pcutoff' _c
        }
        if `pcutoff' < .01 & `pcutoff' > 0 {
            di in g "when P>|z| < " in y `pcutoff' _c
        }
        display
        tokenize "`prnnums'"
        local count = 1
        while "``count''" != "" {
            local ivar = "``count''"
            scalar `sdx' = `sd'[1,`ivar']
            local vname: word `ivar' of `rhsnms'
            _ms_parse_parts `vname'
            if !`r(omit)' {
                di _n in g "Variable: " in y "`vname' " /*
                */ in g "(sd=" in y `sdx' in g ")"
                local head2   "      b         z     P>|z|     bStdX"
                local todup = length("`head2'")
                di _n in g `smcl' %18s "Comparing     " _col(19) "`vlin'"
                di in g `smcl' %18s "Group 1 vs Group 2" ///
                    _col(19) "`vlin'`head2'"
                di in g `smcl' _dup(18) "`dash'" "`plus'" ///
                    _dup(`todup') "`dash'"

                local b1cat 1 // 1...#cats but not necessarily the value of
                              // the category : see b1catnum for that
                local b2cat 0
                local b1block 0
                while `b1cat' <= `ncats' {
                    local b1catnum  : word `b1cat' of `catnums'
                    local b1catnm   : word `b1cat' of `catnms'
                    * if not refcat, use next block of coefficients
                    if `b1catnum'!=`refcat' {
                        local ++b1block
                    }
                    local b2block 0

                    while `b2cat' < `ncats' {
                        local ++b2cat
                        local b2catnum  : word `b2cat' of `catnums'
                        local b2catnm : word `b2cat' of `catnms'
                        * if not refcat, use next block of coefficients* 3.1.4
                        if `b2catnum'!=`refcat' {
                            local ++b2block
                        }
                        local b1indx = `ivar' + ((`b1block'-1)*(`nrhs'+1))
                        local b2indx = `ivar' + ((`b2block'-1)*(`nrhs'+1))
                        * if both reference category, don't proccess
                        if (`b1catnum'==`refcat') & (`b2catnum'==`refcat') {
                            continue
                        }

                        * get b for b1cat and b2cat
                        if (`b1catnum'==`refcat') scalar `b1' = 0
                        else scalar `b1' = `bvec'[1,`b1indx']
                        if (`b2catnum'==`refcat') scalar `b2' = 0
                        else scalar `b2' = `bvec'[1,`b2indx']

                        * compute statistics for b1cat b1cat contrast
                        scalar `b12' = `b1'-`b2'
                        scalar `bstdx' = `b12'*`sdx'
                        * standard error of contrast
                        if `b1catnum'!=`refcat' & `b2catnum'==`refcat' {
                            scalar `se' = sqrt(`v'[`b1indx',`b1indx'])
                        }
                        if `b1catnum'==`refcat' & `b2catnum'!=`refcat' {
                            scalar `se' = sqrt(`v'[`b2indx',`b2indx'])
                        }
                        if `b1catnum'!=`refcat' & `b2catnum'!=`refcat' {
                            scalar `se' = sqrt(`v'[`b1indx',`b1indx'] ///
                                + `v'[`b2indx',`b2indx'] ///
                                - 2*`v'[`b1indx',`b2indx'])
                        }
                        scalar `z' = `b12'/`se'
                        scalar `p' = 2*normprob(-abs(`z'))

                        if `p' <= `pcutoff' {
                            local noprint = "no"
                            if "`matrix'"!="" {
                                matrix `nxtrow' = `b12'
                                matrix rownames `nxtrow' = `vname'
                                matrix `outb' = (nullmat(`outb') \ `nxtrow')
                                matrix `outcon' = ///
                                    (nullmat(`outcon') \ `b1catnum', `b2catnum')
                                matrix `outsdx' = (nullmat(`outsdx') \ `sdx')
                                matrix `outbstdx' = (nullmat(`outbstdx') \ `bstdx')
                                matrix `outz' = (nullmat(`outz') \ `z')
                                matrix `outpval' = (nullmat(`outpval') \ `p')
                                matrix `outse' = (nullmat(`outse') \ `se')
                            }
                            if ("`gt'"!="gt" & "`lt'"!="lt") ///
                               | ("`gt'"=="gt") & (`b1catnum'>`b2catnum') ///
                               | ("`lt'"=="lt") & (`b1catnum'<`b2catnum') {
                                local absdif = abs(`b1catnum'-`b2catnum')
                                if ("`adjacent'"=="adjacent" & `absdif'==1) ///
                                    | "`adjacent'"!="adjacent" {
                                    capture drop `tabrow'
                                    di in g `smcl' "`b1catnm'"   _col(9) ///
                                      ": `b2catnm'"   _col(19) "`vlin'" in y ///
                                      %10.5f `b12' %9.3f `z' %8.3f `p' _c
                                    di %10.5f `bstdx'
                                    matrix `tabrow' ///
                                    = `b1catnum', `b2catnum', `b12', `z', `p', `bstdx'
                                    local tabcolnms "Cat1 Cat2 b z pvalue bstd"
                                    matrix `tabrow' = `tabrow', `sdx'
                                    local tabcolnms "`tabcolnms' sdx"
                                    local tabrownms "`tabrownms' `vname'"
                                    matrix `tabout' ///
                                        = nullmat(`tabout') \ `tabrow'
                               } // adjacent option
                            } // gt lt option
                        } // `p' <= `pcutoff'
                    } // while `b2cat' <= `ncats'
                    local b2cat 0
                    local ++b1cat
                } // b1cat
                di in g `smcl' _dup(18) "`dash'" "`botT'" _dup(`todup') "`dash'"
            }
            local ++count
        } // while count
        matrix rownames `tabout' = `tabrownms'
        matrix colnames `tabout' = `tabcolnms'
        return matrix table = `tabout'
    } // if mprobit

//  special model--slogit // print expanded coefficients

    if "`cmd'" == "slogit" & "`expand'"=="expand" {
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
            local vname: word `ivar' of `rhsnms'

            * compute (phi_i - phi_j) * beta
            tempname phiBest phiBse estsl est se
            matrix `phiBest' = J(`slncats',`slncats',0)
            matrix `phiBse' = `phiBest'
            local i = 1
            * # cat - 1 since base is not in coef matrix
            foreach i of numlist 1(1)`slncatsm1' { // index for 1st phi
                * get phi # in case different base is used
                local phinm1 : word `i' of `slphinm' // name of ith parameter
                local phirow = substr("`phinm1'",6,.) //
                foreach j of numlist 1(1)`slncatsm1' { // index for 2nd phi
                    local phinm2 : word `j' of `slphinm'
                    local phicol = substr("`phinm2'",6,.)
                    * hold estimates from current model, leaving values in memory
                    _estimates hold `estsl', copy
                    * compute contrasts
                    qui nlcom ([`phinm1']_b[_cons] ///
                        - [`phinm2']_b[_cons])*_b[`vname'], post
                    matrix `est' = e(b)
                    matrix `se' = e(V)
                    _estimates unhold `estsl'
                    * 12Apr2005
                    matrix `phiBest'[`phirow',`phicol'] = -1*`est'[1,1]
                    matrix `phiBse'[`phirow',`phicol'] = sqrt(`se'[1,1])
                }
            _estimates hold `estsl', copy
            qui nlcom ([`phinm1']_b[_cons]) * _b[`vname'], post
            matrix `est' = e(b)
            matrix `se' = e(V)
            _estimates unhold `estsl'
            * 12Apr2005
            matrix `phiBest'[`phirow',`slrefrow'] = -1*`est'[1,1]
            matrix `phiBse'[`phirow',`slrefrow'] = sqrt(`se'[1,1])
            * 12Apr2005
            matrix `phiBest'[`slrefrow',`phirow'] = `est'[1,1]
            matrix `phiBse'[`slrefrow',`phirow'] = sqrt(`se'[1,1])
        }

        di _n in g "Variable: " in y "`vname' " /*
        */ in g "(sd=" in y `sdx' in g ")"
        local head2   "      b         z     P>|z|"
        if ("`doexpb'"=="yes") local head2   "`head2'     e^b "
        else local head2 "`head2'       % "
        if ("`doexpbstd'"=="yes") local head2   "`head2'  e^bStdX"
        else local head2 "`head2'    %StdX"
        local todup = length("`head2'")
        di _n in g `smcl' %18s "Odds comparing" _col(19) "`vlin'"
        di in g `smcl' %18s "Group 1 vs Group 2" _col(19) "`vlin'`head2'"
        di in g `smcl' _dup(18) "`dash'" "`plus'" _dup(`todup') "`dash'"

        * loop through all contrasts
        local i1 1
        local i2 1
        while `i1' <= `slncats' {
            local b1catnum = `slcatnum'[1,`i1']
            local b1catnm "`e(out`i1')'"
            while `i2' <= `slncats' {
                scalar `b12' = `phiBest'[`i1',`i2']
                scalar `se' = `phiBse'[`i1',`i2']
                scalar `expb' = exp(`b12')
                scalar `expbstd' = exp(`b12'*`sdx')
                scalar `pctb' = (`expb'-1)*100
                scalar `pctbstd' = (`expbstd'-1)*100
                scalar `z' = `b12'/`se'
                scalar `p' = 2*normprob(-abs(`z'))
                if `p' <= `pcutoff' {
                    local noprint = "no"
                    * get outcome value of second outcome
                    local num2 = `slcatnum'[1,`i2']
                    local b2catnm "`e(out`i2')'"
                    if ("`gt'"!="gt" & "`lt'"!="lt") ///
                        | ("`gt'"=="gt") & (`b1catnum'>`num2') ///
                        | ("`lt'"=="lt") & (`b1catnum'<`num2') {
                        local absdif = abs(`b1catnum'-`num2')
                        if ("`adjacent'"=="adjacent" & `absdif'==1) ///
                            | "`adjacent'"!="adjacent" {
                            di in g `smcl' "`b1catnm'"   _col(9) ///
                                ": `b2catnm'"   _col(19) "`vlin'" in y ///
                                %10.5f `b12' %9.3f `z' %8.3f `p' _c
                            if ("`doexpb'"=="yes") {
                                di %9.4f `expb' _c
                            }
                            else {
                                di %9.1f `pctb' _c
                            }
                            if ("`doexpbstd'"=="yes") {
                                di %9.4f `expbstd'
                            }
                            else {
                                di %9.1f `pctbstd'
                            }
                        } // adjacent option
                    } // gt lt option
               } // `p' <= `pcutoff'
            local ++i2
            if `i1' == `i2' {
                local ++i2
            }
        } // while `i2' <= `slncats'
        local i2 1
        local ++i1
        } // i1

        di in g `smcl' _dup(18) "`dash'" "`botT'" _dup(`todup') "`dash'"
        local count = `count' + 1
        } // loop through variables

    } /* if "`cmd'" == "slogit" expanded */

//  help for first equation (zip and zinb printed below)

    if "`help'"=="help" {
        di in g "       b = raw coefficient"
        di in g "       `tORz' = `tORz'-score for test of b=0"
        di in g "   P>|`tORz'| = p-value for `tORz'-test"
        local std "standardized"
        if ("`dobstdx'"=="yes") di in g "   bStdX = x-`std' coefficient"
        if ("`dobstdy'"=="yes") di in g "   bStdY = y-`std' coefficient"
        if ("`dobstd'"=="yes") di in g "  bStdXY = fully `std' coefficient"
        if "`doexpb'" == "yes"  {
            if "`iscount'"=="yes" {
                di in g "     e^b = exp(b) = factor " ///
                    "change in expected count for unit increase in X"
            }
            else {
                di in g "     e^b = exp(b) = factor " ///
                    "change in odds for unit increase in X"
            }
        }
        if "`doexpbstd'" == "yes" {
            if "`iscount'"=="yes" {
                di in g " e^bStdX = exp(b*SD of X) = " ///
                    "change in expected count for SD increase in X"
            }
            else {
                di in g " e^bStdX = exp(b*SD of X) = " ///
                    "change in odds for SD increase in X"
            }
        }
        if "`dopctb'" == "yes" {
            if "`iscount'"=="yes" {
                di in g "       % = percent change in" ///
                    " expected count for unit increase in X"
            }
            else {
            di in g "       % = percent change in odds for unit increase in X"
             }
        }
        if "`dopctbstd'" == "yes" {
            if "`iscount'"=="yes" {
                di in g "   %StdX = percent change in" ///
                    " expected count for SD increase in X"
            }
            else {
            di in g "   %StdX = percent change in odds for SD increase in X"
            }
        }
        if ("`cmd'"!="mlogit") di in g "   SDofX = standard deviation of X"
    } /* if "`help'"=="help" */

//  binary equation for zip zinb

    if "`iszero'"=="yes" {
        di _n in g "Binary Equation: Factor Change in Odds of Always 0"
        local todupz = length("`head2'")
        di in g `smcl' _n _dup(13) "`dash'" "`topT'" _dup(`todupz') "`dash'"
        di in g `smcl' %12s "Always0" _col(14) "`vlin'`head2'"
        di in g `smcl' _dup(13) "`dash'" "`plus'" _dup(`todupz') "`dash'"

        tokenize `prnnum2'
        local count = 1
        while "``count''" != "" {
            local indx: word `count' of `prnnum2'
            local vname: word `count' of `prnlis2'
            local vname2 "`vname'"
            if `p2'[1, `indx'] < `pcutoff' {
                local noprint "no"
                di in g `smcl' %12s "`vname'" in g _col(14) "`vlin'" in y /*
                */ %10.5f `bnocon2'[1,`indx']   %9.3f `zval2'[1,`indx'] /*
                */ %8.3f `p2'[1,`indx'] _c
                matrix `tab2row' ///
                = `bnocon2'[1,`indx'], `zval2'[1,`indx'], `p2'[1,`indx']
                local tab2colnms "b z pvalue"
                if "`doexpb'" == "yes" {
                    di %9.4f `expb2'[1,`indx'] %9.4f `expbstd2'[1,`indx'] _c
                    matrix `tab2row' ///
                    = `tab2row', `expb2'[1,`indx'], `expbstd2'[1,`indx']
                    local tab2colnms "`tab2colnms' expb expbstd"
                }
                if "`dopctb'" == "yes" {
                    di %9.1f `pctb2'[1,`indx'] %9.1f `pctbstd2'[1,`indx'] _c
                    matrix `tab2row' ///
                    = `tab2row', `pctb2'[1,`indx'], `pctbstd2'[1,`indx']
                    local tab2colnms "`tab2colnms' pctb pctbstd"
                }
                di %11.4f `sd2'[1, `indx']
                matrix `tab2row' = `tab2row', `sd2'[1,`indx']
                local tab2colnms "`tab2colnms' sdx"

                if "`matrix'"!="" {
                    matrix `nxtrow' = `bnocon2'[1, `indx']
                    matrix rownames `nxtrow' = `vname2'
                    matrix `outb2' = (nullmat(`outb2') \ `nxtrow')
                    matrix `outz2' = (nullmat(`outz2') \ `zval2'[1,`indx'])
                    matrix `outpval2' = (nullmat(`outpval2') \ `p2'[1,`indx'])
                    if "`doexpb'" == "yes" {
                        matrix `outexpb2' = (nullmat(`outexpb2') \ `expb2'[1,`indx'])
                        matrix `outexpbstd2' = (nullmat(`outexpbstd2') \ /*
                        */ `expbstd2'[1,`indx'])
                    }
                    if "`dopctb'" == "yes" {
                        matrix `outpctb2' = (nullmat(`outpctb2') \ `pctb2'[1,`indx'])
                        matrix `outpctbstd2' = (nullmat(`outpctbstd2') \ /*
                        */ `pctbstd2'[1,`indx'])
                    }
                }
                local tab2rownms "`tab2rownms' `vname'"
                matrix `tab2out' = nullmat(`tab2out') \ `tab2row'
                local tab2ncols = colsof(`tab2row')
            } // if `p'[1, `count'] < `pcutoff'

            local ++count

        } // while count

        if "`constant'"=="constant" {
            di in g `smcl' %12s "_cons" in g _col(14) "`vlin'" in y /*
            */ %10.5f `con2' %9.3f `conz2' %8.3f `conp2'
            matrix `tab2row' = J(1,`tab2ncols',.)
            matrix `tab2row'[1,1] = `con2'
            matrix `tab2row'[1,2] = `conz2'
            matrix `tab2row'[1,3] = `conp2'
            local tabrownms "`tabrownms' constant"
            matrix `tab2out' = nullmat(`tab2out') \ `tab2row'

            if "`matrix'"!="" {
                return scalar cons2 = `con2'
                return scalar cons2_z = `conz2'
                return scalar cons2_p = `conp2'
            }
        }
        di in g `smcl' _dup(13) "`dash'" "`botT'" _dup(`todupz') "`dash'"
        matrix rownames `tab2out' = `tab2rownms'
        matrix colnames `tab2out' = `tab2colnms'
        return matrix table2 = `tab2out'

//  vuong

        if e(vuong)~=. {
            local favor ""
            if e(vuong) > 0 {
                local p = normprob(-e(vuong))
                if e(cmd)=="zip" {
                    if (`p'<.10) local favor "favoring ZIP over PRM."
                }
                else {
                    if (`p'<.10) local favor "favoring ZINB over NBRM."
                }
            }
            else {
                local p = normprob(e(vuong))
                if e(cmd)=="zip" {
                    if (`p'<.10) local favor "favoring PRM over ZIP."
                }
                else {
                    if (`p'<.10) local favor "favoring NBRM over ZINB."
                }
            }

            di in green "  Vuong Test =" in y %6.2f e(vuong) in green ///
                " (p=" in ye %4.3f `p' in g ") `favor'"
            di in g `smcl' _dup(14) "`dash'"  _dup(`todupz') "`dash'"

        } /* vuong */


        if "`help'"=="help" {
            di in g "       b = raw coefficient"
            di in g "       z = z-score for test of b=0"
            di in g "   P>|z| = p-value for z-test"
            if "`doexpb'" == "yes"  {
                di in g "     e^b = exp(b) = factor " /*
                */ "change in odds for unit increase in X"
                di in g " e^bStdX = exp(b*SD of X) = "/*
                */ "change in odds for SD increase in X"
            }
            if "`dopctb'" == "yes" {
                di in g "       % = percent change in odds for unit"/*
                */ " increase in X"
                di in g "   %StdX = percent change in odds for SD"/*
                */ " increase in X"
            }
            di in g "   SDofX = standard deviation of X"
        } /* if "`help'"=="help" */
    } /* is -zip- or -zinb- */

//  returns

    return local cmd `cmd'
    return scalar pvalue = `pcutoff'

    if "`noprint'" == "yes" {
        di _n in blu "(No results in which p < " %3.2f `pcutoff' ")"
        exit
    }
    if "`matrix'" == "" {
        exit
    }
    local allrows : rownames(`outb')
    if inlist("`e(cmd)'", "mlogit", "mprobit") { // bj 23jul2008
        matrix rownames `outcon' = `allrows'
        matrix colnames `outcon' = Group_1 Group_2
        matrix `outcon' = `outcon''
        return matrix contrast `outcon'
    }

    * b
    matrix colnames `outb' = b
    matrix `outb' = `outb''
    return matrix b `outb'

    matrix rownames `outpval' = `allrows'
    matrix colnames `outpval' = p>|z|
    matrix `outpval' = `outpval''
    return matrix b_p `outpval'

    matrix rownames `outz' = `allrows'
    matrix colnames `outz' = z
    matrix `outz' = `outz''
    return matrix b_z `outz'

    if "`isnosdx'"!="yes" {
        matrix rownames `outsdx' = `allrows'
        matrix colnames `outsdx' = SDofX
        matrix `outsdx' = `outsdx''
        return matrix sdx `outsdx'
    }

    if "`dobstdx'"=="yes" {
        matrix rownames `outbstdx' = `allrows'
        matrix colnames `outbstdx' = bStdX
        matrix `outbstdx' = `outbstdx''
        return matrix b_xs `outbstdx'
    }

    if "`dobstdy'"=="yes" {
        matrix rownames `outbstdy' = `allrows'
        matrix colnames `outbstdy' = bStdY
        matrix `outbstdy' = `outbstdy''
        return matrix b_ys `outbstdy'
    }

    if "`dobstd'"=="yes" {
        matrix rownames `outbstd' = `allrows'
        matrix colnames `outbstd' = bStdXY
        matrix `outbstd' = `outbstd''
        return matrix b_std `outbstd'
    }

    if "`doexpb'"=="yes" {
        matrix rownames `outexpb' = `allrows'
        matrix colnames `outexpb' = e^b
        matrix `outexpb' = `outexpb''
        return matrix b_fact `outexpb'
    }

    if "`doexpbstd'"=="yes" {
        matrix rownames `outexpbstd' = `allrows'
        matrix colnames `outexpbstd' = e^bStdX
        matrix `outexpbstd' = `outexpbstd''
        return matrix b_facts `outexpbstd'
    }

    if "`dopctb'"=="yes" {
        matrix rownames `outpctb' = `allrows'
        matrix colnames `outpctb' = %
        matrix `outpctb' = `outpctb''
        return matrix b_pct `outpctb'
    }

    if "`dopctbstd'"=="yes" {
        matrix rownames `outpctbstd' = `allrows'
        matrix colnames `outpctbstd' = %StdX
        matrix `outpctbstd' = `outpctbstd''
        return matrix b_pcts `outpctbstd'
    }
    if "`iszero'"=="yes" {
        capture local allrows : rownames(`outb2')
        if _rc == 111 {
            exit 0
        }
        matrix colnames `outb2' = b
        matrix `outb2' = `outb2''
        return matrix b2 `outb2'

        matrix rownames `outpval2' = `allrows'
        matrix colnames `outpval2' = p>|z|
        matrix `outpval2' = `outpval2''
        return matrix b2_p `outpval2'

        matrix rownames `outz2' = `allrows'
        matrix colnames `outz2' = z
        matrix `outz2' = `outz2''
        return matrix b2_z `outz2'

        if "`doexpb'"=="yes" {
            matrix rownames `outexpb2' = `allrows'
            matrix colnames `outexpb2' = e^b
            matrix `outexpb2' = `outexpb2''
            return matrix b2_fact `outexpb2'
        }

        if "`doexpbstd'"=="yes" {
            matrix rownames `outexpbstd2' = `allrows'
            matrix colnames `outexpbstd2' = e^bStdX
            matrix `outexpbstd2' = `outexpbstd2''
            return matrix b2_facts `outexpbstd2'
        }

        if "`dopctb'"=="yes" {
            matrix rownames `outpctb2' = `allrows'
            matrix colnames `outpctb2' = %
            matrix `outpctb2' = `outpctb2''
            return matrix b2_pct `outpctb2'
        }

        if "`dopctbstd'"=="yes" {
            matrix rownames `outpctbstd2' = `allrows'
            matrix colnames `outpctbstd2' = %StdX
            matrix `outpctbstd2' = `outpctbstd2''
            return matrix b2_pcts `outpctbstd2'
        }
    } // iszero

end
exit
