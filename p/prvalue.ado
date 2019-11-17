*! version 2.5.4 2010-03-26
*   remove 244 string length restrictions

//  See prvalue_globals.hlp for details on globals created the
//  contain information on current results and that contain
//  details on the -saved- model.

//  TO DO: add error trap if diff with no prior save.

capture program drop prvalue
program define prvalue, rclass

    * 2.2.2
    local caller = _caller()  // which version called prvalue
    version 8
    tempname rpred seystar tobase tobase2 temp values probs xb xb_hi ///
        xb_lo xb_prev xb_dif xb_prev_lo xb_prev_hi xb_prev_lvl ystarhi ///
        ystarlo stdp p0 p1 p0_hi p1_hi p0_lo p1_lo p1_hi p0_dif p1_dif ///
        p0_prev p1_prev p_prev p_dif Cprobs Cp_prev Cp_dif Cmu Cmu_dif
    tempname Cmu_cur Cmu_prev mu mu_hi mu_lo mu_prev mu_prev_hi mu_prev_lo ///
        mu_dif mu_dif_hi mu_dif_lo mucount mucount_lo mucount_hi ///
        mucount_dif mucount_dif_hi mucount_dif_lo all0 all0_lo all0_hi ///
        all0_prev all0_prev_lo all0_prev_hi all0_dif all0_dif_lo ///
        all0_dif_hi

//  #1  CLASSIFY TYPE OF MODEL

    if "`e(cmd)'"=="mprobit"  { // 28Feb2005
        local io = "typical mprobit"
    }
    if "`e(cmd)'"=="ztp"      { // 18Feb2005
        local io = "typical count"
    }
    if "`e(cmd)'"=="ztnb"     {
        local io = "typical count"
    }
    if "`e(cmd)'"=="cloglog"  {
        local io = "typical binary"
    }
    if "`e(cmd)'"=="cnreg"    {
        local io = "typical tobit"
    }
    if "`e(cmd)'"=="fit"      {
        local io = "typical regress"
    }
    if "`e(cmd)'"=="gologit"  {
        local io = "typical mlogit"
    }
    if "`e(cmd)'"=="intreg"   {
        local io = "typical tobit"
    }
    if "`e(cmd)'"=="logistic" {
        local io = "typical binary"
    }
    if "`e(cmd)'"=="logit"    {
        local io = "typical binary"
    }
    if "`e(cmd)'"=="mlogit"   {
        local io = "typical mlogit"
    }
    if "`e(cmd)'"=="nbreg"    {
        local io = "typical count"
    }
    if "`e(cmd)'"=="ologit"   {
        local io = "typical ordered"
    }
    if "`e(cmd)'"=="oprobit"  {
        local io = "typical ordered"
    }
    if "`e(cmd)'"=="poisson"  {
        local io = "typical count"
    }
    if "`e(cmd)'"=="probit"   {
        local io = "typical binary"
    }
    if "`e(cmd)'"=="slogit"   {
        local io = "typical slogit"
    }
    if "`e(cmd)'"=="regress"  {
        local io = "typical regress"
    }
    if "`e(cmd)'"=="tobit"    {
        local io = "typical tobit"
    }
    if "`e(cmd)'"=="zinb"     {
        local io = "twoeq count"
    }
    if "`e(cmd)'"=="zip"      {
        local io = "twoeq count"
    }

    global PEio "`io'" // global with type of model
    local input : word 1 of `io'
    local output : word 2 of `io'

    if "`io'"=="" {
        di in r "prvalue does not work for the last type of model estimated."
        exit
    }

//  #2  PRINTING DEFAULTS

    * output columns for printing values
    local c_cur = 22
    local c_lo = 32
    local c_hi = 44
    * output columns for printing differences
    local c_curD = 22
    local c_savD = 32
    local c_difD = 42
    local c_loD = 51
    local c_hiD = 62
    * columns for dif header
    local c_curDH = 22
    local c_savDH = 34
    local c_difDH = 43
    local c_lvlDH = 52
    * formats
    local yfmt "%7.0g" // for y values
    local pfmt "%7.4f" // for probabilities

//  DECODE OPTIONS & SETUP PRINTING PARAMETERS

    syntax [if] [in] [, x(passthru) Rest(passthru) LEvel(passthru) ///
        MAXcnt(passthru) noLAbel noBAse Brief Save Diff all ///
        YStar ept DELta ///
        BOOTstrap REPs(passthru) SIze(passthru) DOts match ///
        SAving(passthru) NORMal PERCENTile BIAScorrected ///
        test ///
        LABel(string) ] // 2007-02-17 2.0.6

//  #3  LABEL save and diff

    * 2007-02-17 add label
    if "`save'"=="save" {
        if "`label'"!="" {
            global PRVlabsav "`label'"
        }
        else {
            global PRVlabsav ""
        }
    }
    if "`diff'"=="diff" {
        if "`label'"!="" {
            global PRVlabcur "`label'"
        }
        else {
            global PRVlabcur ""
        }
    }

//  #4  DETERMINE METHOD FOR CI & TRAP ERRORS

    local errmethod "method cannot be used with the current model."
    local errystar "ystar cannot be used with the current model."

    * ept invalid except with binary models
    if "`ept'"=="ept" & "`output'"!="binary"  {
      di as error "ept is only valid for binary models."
      exit
    }

    * regress models use ml method
    if ("`output'"=="regress" | "`output'"=="tobit" ) ///
        & "`delta'"=="" & "`bootstrap'"==""  {
        local ystar "ystar"
        local mlci "ml"
    }

    * delta invalid for zip/zinb
    if "`input'"=="twoeq" & "`delta'"=="delta" {
        di as error "the delta `errmethod'"
        exit
    }
    * delta is the default ci method
    if "`ystar'"=="" & "`bootstrap'"=="" & "`ept'"=="" {
        local delta = "delta"
    }

    * default method for zip and zinb is none
    if ("`input'"=="twoeq") & "`bootstrap'"=="" {
        local delta ""
    }

    * no ci for ztp, ztnb, mprobit, slogit
    if "`e(cmd)'"=="ztp" | "`e(cmd)'"=="ztnb" | ///
        "`e(cmd)'"=="mprobit" | "`e(cmd)'"=="slogit" {
        local delta ""
        local bootstrap ""
    }

    * trap boot options with delta, ept and ystar
    foreach method in delta ept ystar {
        if "``method''"=="`method'" {
            local badopt ""
            foreach nm in dots match normal percentile biascorrected {
                if "``nm''"=="`nm'" {
                    local badopt "`nm'"
                }
            }
            if "`badopt'"!="" {
                di as error ///
                    "option `badopt' is incompatable with `method' method."
                exit
                di "ding"
            }
        }
    }
    if "`badopt'"!="" {
        exit
    }

    * determine method and make sure only one method specified
    local cimethod "default" // ci method
    local boottype "" // bootstrap ci type
    local boottype2 "none" // short name
    local ncimethod = 0
    if "`ystar'"=="ystar" {
        local cimethod "ml"
        local ncimethod = 1
    }
    if "`delta'"=="delta" {
        local cimethod "delta"
        local ncimethod = `ncimethod' + 1
    }
    if "`ept'"=="ept" {
        local cimethod "ept"
        local ncimethod = `ncimethod' + 1
    }
    local nboottype = 0
    if "`bootstrap'"=="bootstrap" {
        local cimethod "bootstrap"
        local boottype "percentile method"
        local boottype2 "percentile"
        local ncimethod = `ncimethod' + 1
        if "`percentile'" == "percentile" {
            local nboottype = 1
        }
        if "`normal'" == "normal" {
            local boottype2 "normal"
            local boottype "normal approximation"
            local nboottype = `nboottype' + 1
        }
        if "`biascorrected'" == "biascorrected" {
            local boottype "bias-corrected method"
            local boottype2 "biascorrected"
            local nboottype = `nboottype' + 1
        }
    }

    if "`ncimethod'" > "1" {
        di as error "only one method for computing CIs can be specified."
        exit
    }
    if "`nboottype'" > "1" {
        di as error "only one method of computing " ///
                "bootstrap CIs can be specified."
            exit
    }

    * ept only with binary models
    if "`ept'"!="" & "`output'"!="binary"  {
      di as error "the ept `errmethod'"
      exit
    }

    * ept invalid with diff
    if "`ept'"!="" & "`diff'"=="diff"  {
      di as error "the ept method does not work with the diff option."
      exit
    }
    * ystar invalid with mlogit, count and gologit
    if ("`e(cmd)'"=="mlogit" | "`output'"=="count" ///
            | "`e(cmd)'"=="gologit") ///
            & "`ystar'"=="ystar" {
        di as error "`errystar'"
        exit
    }

    * delta invalid with regress, tobit, intreg, cnreg, zip or zinb
    if ("`output'"=="regress" | "`output'"=="tobit" ///
        | "`input'"=="twoeq") & "`delta'"=="delta" {
        di as error "the delta `errmethod'"
        exit
    }

    * bootstrap does not work with cnreg, intreg, regress or tobit
    if ("`output'"=="regress" | "`output'"=="tobit") ///
        & "`bootstrap'"=="bootstrap" {
        di as error "the bootstrap `errmethod'"
        exit
    }

    * dummy out methods since cis not computed
    if "`e(cmd)'"=="ztp" | "`e(cmd)'"=="ztnb"  {
        global pecimethod ""
        local cimethod ""
    }

    * if diff, methods must match
    if "`diff'" == "diff" {
        local cimethodprior : word 1 of $pecimethod
        * 2.1.8 - no CIs for mprobit - 2009-03-14
        if "`e(cmd)'"=="slogit" | "`e(cmd)'"=="mprobit"{
            local cimethod "`cimethodprior'"
        }

        * 26Jun2006 rule does not apply for regress which only uses ml
        if ("`cimethod'" != "`cimethodprior'") & ("`e(cmd)'"!="regress") {
            di as error "the methods used for save and dif must be the same."
            exit
        }
    }

    * info on outcomes
    if "`output'" != "regress" & "`output'" != "tobit" {
        _pecats
        local ncats = r(numcats)
        local catnms8 `r(catnms8)'
        local catvals `r(catvals)'
        local catnms `r(catnms)'
    }

    * check for errors with diff
    if "`diff'"=="diff" {
        local priorcmd : word 1 of $petype
        if "`priorcmd'" != "`e(cmd)'" {
            di in r "saved results were not estimated with `e(cmd)'"
            exit
        }
        if "$PRVdepv" != "`e(depvar)'" {
            di in r ///
                "the dependent variable has changed from the saved model."
            exit
        }
        if "`output'"=="ordered" | "`output'"=="mlogit" {
            if "`catvals'"!="$PRVvals" {
                di in r "category values for saved and current " /*
                */ "dependent variable do not match"
            exit
            }
        }
    }

//  #5  GET INFO ON OUTCOME AND BASE VALUES

    * info on base values
    _pebase `if' `in' , `x' `rest' `choices' `all'
    mat `tobase' = r(pebase)
    if "`input'"=="twoeq" {
        mat `tobase2' = r(pebase2)
    }
    if "`input'"=="typical" {
        mat PE_in = `tobase'
    }
    if "`input'"=="twoeq" {
        mat PE_in = `tobase'
        mat PE_in2 = `tobase2'
    }

//  #6  COMPUTE PREDICTIONS

    * 2008-07-10 // clear globals to hold se for differences
    global pedifsey = . // clear global that contains ml se of difference
    global pedifsemu = . // clear global that contains ml se of difference
    matrix def pedifsep = J(1,1,.)
    global pesemu = .

    _pepred, `level' `maxcnt'

//  #7  COLLECT INFORMATION AND SAVE TO GLOBALS

    local maxc = r(maxcount)
    local lvl = r(level)

    * Backup information in returns before calling _pecollect
    * since _pecollect destroys current information. Then,
    * after calling _pecollect, restore the original returns.
    *
    * 1) drop stored returns; 2) save returns from pepred
    * 3) restore them after z_pecollect; 4) drop returns
    * 5) save from pepred; 6) restore and keep them saved

    capture _return drop pepred
    _return hold pepred
    _return restore pepred, hold
    global pecimethod "`cimethod' `boottype2'"

    * stores information on current model and differences to globals
    _pecollect, inout("`io'") level(`lvl') maxcount(`maxc') `diff' `reps'

    *_return restore pepred     // changed bj 22jul2008 for use with estout
    *_return drop _all          // changed bj 22jul2008 for use with estout
    *_return hold pepred        // changed bj 22jul2008 for use with estout
    _return restore pepred, hold

//  #8  COMPUTE CONFIDENCE INTERVALS

    global pecimethod "ml none" // by default, use ml method
    if "`input'"=="twoeq" {
        global pecimethod "default"
    }
    if "`ept'" == "ept" {
        local cimethod "end-point transformation"
        * ci's were computed by _pepred
        global pecimethod "ept none"
    }
    if "`delta'" == "delta" {
        local cimethod "delta"
        global pecimethod "delta none"
        * compute ci's using delta method
        * 0.2.1 _pecidelta, `save' `diff'
        _pecidelta, `save' `diff' caller(`caller') // 0.2.2
    }
    if "`bootstrap'"=="bootstrap" {
        local cimethod "bootstrap"
        global pecimethod "bootstrap `boottype2'"
        * compute ci's using bootstrap
        _peciboot, `x' `rest' `all' `save' ///
                `diff' `reps' `size' `dots' `match' `saving'
        matrix peinfo[1,10] = r(Nrepsnomis) // # of completed reps
    }
    * ystar with diff
    if "`ystar'"=="ystar" & "`diff'"=="diff" {
        * ystar only defined for these model types
        if "`output'"=="binary" | "`output'"=="tobit" ///
            | "`output'"=="regress" | "`e(cmd)'"=="ologit" ///
            | "`e(cmd)'"=="oprobit" {

            local cimethod "ystar"
            global pecimethod "ystar none"
            * compute ml ci of difference
            _peciml
            _return restore pepred

        } // if models for ystar
    } // ystar for difference

//  #9   NOT USED

//  #10  OUTPUT HEADER

    local level = peinfo[1,3] // 95 not .95
    local max_i = peinfo[1,2] - 1 // # of categories - 1
    di
    if "`diff'"=="" {
        di in y "`e(cmd)'" in g ": Predictions for " ///
            in y "`e(depvar)'"
    }
    if "`diff'"=="diff" {
        di in y "`e(cmd)'" in g ": Change in Predictions for " ///
                in y "`e(depvar)'"
    }
    if "`brief'"=="" {
        if "`cimethod'" == "ept" {
            di in g _n "Confidence intervals using end-point transformations"
        }
        else if "`cimethod'" == "delta" {
            di in g _n "Confidence intervals by delta method"
        }
        else if "`cimethod'"=="bootstrap" {
            di in g _n "Bootstrap confidence intervals using `boottype'" // 2.1.6
        }
    } // not brief
    if "`cimethod'"=="bootstrap" {
        di in g "(" peinfo[1,10] " of " peinfo[1,9] ///
                " replications completed)"
    }

//  #11  PUT SELECTED METHOD-TYPE OF CI INTO MATRIX TO PRINT

    tempname ciupper cilower
    * by default, this will be percentile with boot
    mat def `ciupper' = peupper
    mat def `cilower' = pelower

    if "`cimethod'"=="bootstrap" {
        * if percentile, already in peupper/lower
        if "`normal'" == "normal" {
            mat def `ciupper' = peupnorm
            mat def `cilower' = pelonorm
            * put selected method into peupper and lower
            mat def peupper = peupnorm
            mat def pelower = pelonorm
        }
        if "`biascorrected'" == "biascorrected" {
            mat def `ciupper' = peupbias
            mat def `cilower' = pelobias
            * put selected method into peupper and lower
            mat def peupper = peupbias
            mat def pelower = pelobias
        }
    }

//
//  PRINT RESULTS
//

//  #12  REGRESS & TOBIT ROUTINES

    if "`output'" == "tobit" | "`output'" == "regress" {

        sca `xb' = pepred[3,1]
        sca `xb_lo' = `cilower'[3,1]
        sca `xb_hi' = `ciupper'[3,1]
        sca `stdp' = peinfo[1,8] // se(xb)
        return scalar xb = `xb'
        return scalar xb_lo = `xb_lo'
        return scalar xb_hi = `xb_hi'
        return local level `level'

        * 2008-06-15 r(pred)
        matrix def `rpred' = J(1,4,.)
        matrix rownames `rpred' = ystar
        matrix colnames `rpred' = ystar LB UB Category
        matrix `rpred'[1,1] = `xb'
        matrix `rpred'[1,2] = `xb_lo'
        matrix `rpred'[1,3] = `xb_hi'

        local out "y"
        local add 0
        if "`output'"=="tobit" {
            local out "y*"
            local add 1
        }

        PRTyciH `c_lo' `level' 1
        PRTy    2 "Predicted `out'" `yfmt' `c_cur' `xb'
        PRTyci  `yfmt' `c_lo' `level' `xb_lo' `c_hi' `xb_hi'

        if "`diff'"=="diff" {

            sca `xb_prev' = pepred[5,1]
            local skip = 8 + `add'
            PRTy   `skip' "Saved" `yfmt' `c_cur' `xb_prev'
            PRTyci `yfmt' `c_lo' `level' _PRVsav[1,3] ///
                `c_hi' _PRVsav[1,4]
            local skip = 3 + `add'
            PRTy `skip' "Difference" `yfmt' `c_cur' `xb'-`xb_prev'
            PRTyci `yfmt' `c_lo' `level' `cilower'[7,1] ///
                `c_hi' `ciupper'[7,1]

            * 2008-07-10 r(pred) for dif
            matrix def `rpred' = J(1,4,.)
            matrix rownames `rpred' = ystar
            matrix colnames `rpred' = Dystar LB UB Category
            matrix `rpred'[1,1] = `xb'-`xb_prev'
            matrix `rpred'[1,2] = `cilower'[7,1]
            matrix `rpred'[1,3] = `ciupper'[7,1]

        } // if diff and regress/tobit

        if "`save'"=="`save'" {
            mat _PRVsav = `xb', `stdp', `xb_lo', `xb_hi', `level'
            mat colnames _PRVsav = xb stdp xb_lo xb_hi level
        }

    } // end of tobit and regress

//  #13  BINARY OUTPUT

    if "`output'" == "binary" {

        sca `stdp' = peinfo[1,8]
        sca `xb' = pepred[3,1]
        sca `xb_lo' = `cilower'[3,1]
        sca `xb_hi' = `ciupper'[3,1]
        foreach c in 0 1 {
            local c1 = `c' + 1
            sca `p`c'' = pepred[2,`c1']
        }
        sca `p0_hi' = `ciupper'[2,1]
        sca `p1_hi' = `ciupper'[2,2]
        sca `p0_lo' = `cilower'[2,1]
        sca `p1_lo' = `cilower'[2,2]

        return scalar xb = `xb'
        return scalar xb_lo = `xb_lo'
        return scalar xb_hi = `xb_hi'
        return local level `level'
        return scalar p0 = `p0'
        return scalar p1 = `p1'
        return scalar p0_hi = `p0_hi'
        return scalar p0_lo = `p0_lo'
        return scalar p1_hi = `p1_hi'
        return scalar p1_lo = `p1_lo'

        if "`save'"=="save" {
            mat _PRVsav = `xb', `stdp', `p1', `xb_lo', `xb_hi', `level'
            mat colnames _PRVsav = xb stdp p1 xb_lo xb_hi level
        }

//  #14 BINARY with ystar option

        if "`ystar'"=="ystar" {

            PRTyciH `c_lo' `level' 1
            PRTy 2 "Predicted y*" `yfmt' `c_cur' `xb'
            PRTyci `yfmt' `c_lo' `level' `xb_lo' ///
                `c_hi' `xb_hi'

            * 2008-06-15 r(pred) for ystar
            matrix def `rpred' = J(1,4,.)
            matrix rownames `rpred' = ystar
            matrix colnames `rpred' = ystar LB UB Category
            matrix `rpred'[1,1] = `xb'
            matrix `rpred'[1,2] = `xb_lo'
            matrix `rpred'[1,3] = `xb_hi'

            if "`diff'"=="diff" {

                sca `xb_dif' = pepred[7,1]
                PRTy 9 "Saved" `yfmt' `c_cur' pepred[5,1]
                PRTyci `yfmt' `c_lo' `level' _PRVsav[1,4] ///
                    `c_hi' _PRVsav[1,5]
                PRTy 4 "Difference" `yfmt' `c_cur' `xb_dif'
                PRTyci `yfmt' `c_lo' `level' `cilower'[7,1] ///
                    `c_hi' `ciupper'[7,1]

                * 2008-07-10 r(pred) for dif
                matrix def `rpred' = J(1,4,.)
                matrix rownames `rpred' = ystar
                matrix colnames `rpred' = Dystar LB UB Category
                matrix `rpred'[1,1] = `xb_dif'
                matrix `rpred'[1,2] = `cilower'[7,1]
                matrix `rpred'[1,3] = `ciupper'[7,1]

            } // diff

        } // binary ystar option

//  #15 BINARY - not ystar

         else { // binary: not ystar

            * labels for outcomes
            if "`label'"!="nolabel" {
                local p0lab : word 1 of `catnms8'
            }
            else {
                local p0lab : word 1 of `catvals'
            }
            if "`label'"!="nolabel" {
                local p1lab : word 2 of `catnms8'
            }
            else {
                local p1lab : word 2 of `catvals'
            }

            * 2008-06-15 r(pred) for probabilities
            matrix def `rpred' = J(2,4,.)
            matrix rownames `rpred' = `catnms'
            matrix colnames `rpred' = Prob LB UB Category
            matrix `rpred'[1,1] = `p0'
            matrix `rpred'[1,2] = `p0_lo'
            matrix `rpred'[1,3] = `p0_hi'
            matrix `rpred'[1,4] = 0
            matrix `rpred'[2,1] = `p1'
            matrix `rpred'[2,2] = `p1_lo'
            matrix `rpred'[2,3] = `p1_hi'
            matrix `rpred'[2,4] = 1

            if "`diff'"=="diff" {

                sca `p1_prev' = pepred[4,2]
                sca `p0_prev' = 1 - `p1_prev'
                sca `p1_dif' = `p1' - `p1_prev'
                sca `p0_dif' = `p0' - `p0_prev'
                local p1diflo = `cilower'[6,2]
                local p1difhi = `ciupper'[6,2]
                local p0diflo = `cilower'[6,1]
                local p0difhi = `ciupper'[6,1]
                * 2.0.7
                PRTdH `c_curDH' `c_savDH' `c_difDH' $PRVlabsav $PRVlabcur
                PRTdciH `c_lvlDH' `level'
                foreach v in 1 0 {
                    PRTd 2 "Pr(y=`p`v'lab'|x)" `pfmt' `c_curD' `p`v'' ///
                        `c_savD' `p`v'_prev' `c_difD' `p`v'_dif'
                    PRTdci `pfmt' `c_loD' `p`v'diflo' ///
                    `c_hiD' `p`v'difhi'
                }

                * 2008-07-10 r(pred) for dif
                matrix def `rpred' = J(2,4,.)
                matrix rownames `rpred' = `catnms'
                matrix colnames `rpred' = DProb LB UB Category         //! changed bj 22jul2008
                matrix `rpred'[1,1] = `p0_dif'
                matrix `rpred'[1,2] = `p0diflo'
                matrix `rpred'[1,3] = `p0difhi'
                matrix `rpred'[1,4] = 0
                matrix `rpred'[2,1] = `p1_dif'
                matrix `rpred'[2,2] = `p1diflo'
                matrix `rpred'[2,3] = `p1difhi'
                matrix `rpred'[2,4] = 1

            } // binary dif in prob

            else { // binary - not difference
                PRTyciH `c_lo' `level' 1
                foreach v in 1 0 {
                    PRTy 2 "Pr(y=`p`v'lab'|x)" `pfmt' `c_cur' `p`v''
                    PRTyci `pfmt' `c_lo' `level' `p`v'_lo' ///
                        `c_hi' `p`v'_hi'
                }
           } // not difference

        } // not ystar

    } // binary

//  #16  ORDINAL OUTCOMES

    if "`output'" == "ordered" {

        *if "`brief'" == "brief" { di }
        sca `xb' = pepred[3,1]
        sca `xb_lo' = `cilower'[3,1]
        sca `xb_hi' = `ciupper'[3,1]
        sca `stdp' = peinfo[1,8]
        return scalar xb = `xb'
        return scalar xb_lo = `xb_lo'
        return scalar xb_hi = `xb_hi'
        return local level `level'

    * 2008-06-15 r(pred) for ystar
    if "`ystar'"=="ystar" {
        matrix def `rpred' = J(1,4,.)
        matrix rownames `rpred' = ystar
        matrix colnames `rpred' = ystar LB UB Category
        matrix `rpred'[1,1] = `xb'
        matrix `rpred'[1,2] = `xb_lo'
        matrix `rpred'[1,3] = `xb_hi'
    }
    * 2008-06-15 r(pred) for prob
    else {
        matrix def `rpred' = J(`ncats',4,.)
        matrix rownames `rpred' = `catnms'
        matrix colnames `rpred' = Prob LB UB Category
    }

        * cycle though categories get probabilities etc.
        local i = 1
        if "`diff'" != "diff" {
            PRTyciH `c_lo' `level' 1
        }

        while `i' <= `ncats' {

            * get labels
            local p`i'val : word `i' of `catvals'
            mat `values' = nullmat(`values') \ `p`i'val'
            local p`i'lab : word `i' of `catnms8'
            local labdisp "`p`i'val'"
            if "`label'"!="nolabel" {
                local labdisp "`p`i'lab'"
            }

            * get probability
            tempname p`i'
            sca `p`i'' = pepred[2,`i']
            mat `probs' = nullmat(`probs') \ `p`i''

            * not diff and prob
            if "`ystar'"=="" & "`diff'"=="" {
                PRTy 5 "Pr(y=`labdisp'|x)" `pfmt' `c_cur' `p`i''
                PRTyci `pfmt' `c_lo' `level' `cilower'[2,`i'] ///
                    `c_hi' `ciupper'[2,`i']
            }

            * 2008-06-15 r(pred) add prob
            if "`ystar'"!="ystar" {
                matrix `rpred'[`i',1] = `p`i''
                matrix `rpred'[`i',2] = `cilower'[2,`i']
                matrix `rpred'[`i',3] = `ciupper'[2,`i']
                matrix `rpred'[`i',4] = `p`i'val'
            }

            * dif and prob
            if "`ystar'"=="" & "`diff'"=="diff" {
                if "`i'" == "1" { // header
                    PRTdH `c_curDH' `c_savDH' `c_difDH'
                    PRTdciH `c_lvlDH' `level'
                }
                PRTd 5 "Pr(y=`labdisp'|x)" `pfmt' `c_curD' `p`i'' ///
                    `c_savD' pepred[4,`i'] `c_difD' pepred[6,`i']
                PRTdci `pfmt' `c_loD' `cilower'[6,`i'] ///
                    `c_hiD' `ciupper'[6,`i']

                * 2008-07-10 r(pred) for dif \\ ord and prob
                matrix colnames `rpred' = DProb LB UB Category
                matrix `rpred'[`i',1] = pepred[6,`i']
                matrix `rpred'[`i',2] = `cilower'[6,`i']
                matrix `rpred'[`i',3] = `ciupper'[6,`i']
                matrix `rpred'[`i',4] = `p`i'val'

            }

            local i = `i' + 1

        } // looping over categories

        * save before return because return destroys matrices
        if "`save'"=="save" {
            mat _PRVsav = `xb', `stdp', `xb_lo', `xb_hi', `level'
            mat colnames _PRVsav = xb stdp xb_lo xb_hi level
            global PRVvals = "`catvals'"
            mat _PRVp = `probs'
        }
        return matrix values `values'
        return matrix probs `probs'

        * ystar, not prob
        if "`ystar'"=="ystar" {

            if "`diff'"=="diff" {
                PRTyciH `c_lo' `level' 1
            }
            PRTy 5 "Predicted y*" `yfmt' `c_cur' `xb'
            PRTyci `yfmt' `c_lo' `level' `xb_lo' ///
                `c_hi' `xb_hi'

            if "`diff'"=="diff" {

                sca `xb_prev' = pepred[5,1]
                PRTy 5 "Saved" `yfmt' `c_cur' `xb_prev'
                PRTyci `yfmt' `c_lo' `level' _PRVsav[1,3] ///
                    `c_hi' _PRVsav[1,4]
                PRTy 5 "Difference" `yfmt' `c_cur' `xb'-`xb_prev'
                PRTyci `yfmt' `c_lo' `level' `cilower'[7,1] ///
                    `c_hi' `ciupper'[7,1]

                * 2008-07-10 r(pred) for dif
                matrix def `rpred' = J(1,4,.)
                matrix rownames `rpred' = ystar
                matrix colnames `rpred' = Dystar LB UB Category
                matrix `rpred'[1,1] = `xb'-`xb_prev'
                matrix `rpred'[1,2] = `cilower'[7,1]
                matrix `rpred'[1,3] = `ciupper'[7,1]

            } // diff for ystar

        } // end of ystar output

    } // ordinal

//  #17  NOMINAL OUTPUT

    if "`output'" == "mlogit" | "`output'" == "mprobit" | "`output'" == "slogit" {

        * 2008-06-15 r(pred)
        matrix def `rpred' = J(`ncats',4,.)
        matrix rownames `rpred' = `catnms'
        matrix colnames `rpred' = Prob LB UB Category

        if "`diff'"=="diff" {

            * 2008-07-10 r(pred) for dif
            matrix colnames `rpred' = DProb LB UB Category
            PRTdH `c_curDH' `c_savDH' `c_difDH'
            * 2.1.8 - no ci for mprobit - 2009-03-14
            if "`output'"!="slogit" & "`output'"!="mprobit" { // no ci for slogit or mprobit
                PRTdciH `c_lvlDH' `level'
            }
            else {
                di
            }
        }
        else {
            if "`output'"=="mlogit" {
                PRTyciH `c_lo' `level' 1
            }
            else {
                di
            }
        }

        * cycle through each category
        local i = 1
        while `i' <= `ncats' {
            * get actual category value
            local p`i'val : word `i' of `catvals'
            mat `values' = nullmat(`values') \ `p`i'val'
            *get label
            local p`i'lab : word `i' of `catnms8'
            local labdisp "`p`i'val'"
            if "`label'"!="nolabel" {
                local labdisp "`p`i'lab'"
            }
            * get probability computed by _pepred and stored in r()
            tempname p`i'
            sca `p`i'' = pepred[2,`i']
            mat `probs' = nullmat(`probs') \ `p`i''

            if "`diff'"=="" {
                PRTy 2 "Pr(y=`labdisp'|x)" `pfmt' `c_cur' `p`i''
                if "`output'"=="mlogit" {
                    PRTyci `pfmt' `c_lo' `level' `cilower'[2,`i'] ///
                        `c_hi' `ciupper'[2,`i']
                }
                else {
                    di
                }

            } // nominal: no diff

            * 2008-06-15 r(pred) add prob
            matrix `rpred'[`i',1] = `p`i''
            matrix `rpred'[`i',2] = `cilower'[2,`i']
            matrix `rpred'[`i',3] = `ciupper'[2,`i']
            matrix `rpred'[`i',4] = `p`i'val'

            if "`diff'"=="diff" {
                PRTd 2 "Pr(y=`labdisp'|x)" `pfmt' `c_curD' `p`i'' ///
                    `c_savD' pepred[4,`i'] `c_difD' pepred[6,`i']

                * 2008-07-10 r(pred) for dif
                matrix `rpred'[`i',1] = pepred[6,`i']
                matrix `rpred'[`i',4] = `p`i'val'
                * 2.1.8 - no ci for mprobit - 2009-03-14
                if "`output'"!="slogit" & "`output'"!="mprobit" { // no ci for slogit or mprobit
                    PRTdci `pfmt' `c_loD' `cilower'[6,`i'] ///
                        `c_hiD' `ciupper'[6,`i']
                    * 2008-07-10 r(pred) for dif
                    matrix `rpred'[`i',2] = `cilower'[6,`i']
                    matrix `rpred'[`i',3] = `ciupper'[6,`i']
                }
                else {
                    di
                }
            } // nominal - diff

            local i = `i' + 1
        }

        if "`save'"=="save" {
            global PRVvals = "`catvals'"
            mat _PRVp = `probs'
        }

        return matrix values `values'
        return matrix probs `probs'

    } // mlogit

//  #18  COUNT - nbreg and poisson

    if "`e(cmd)'"=="poisson" | "`e(cmd)'"=="nbreg" {

        sca `mu' = pepred[3,2]
        sca `stdp' = peinfo[1,8]
        tempname plo_dif phi_dif
        sca `mu_lo' = `cilower'[3,2]
        sca `mu_hi' = `ciupper'[3,2]
        return local level `level'
        return scalar mu = `mu'
        return scalar mu_lo = `mu_lo'
        return scalar mu_hi = `mu_hi'
        return local level `level'

        * 2008-06-15 r(pred) for mu and probs
        local npred = 1 + `max_i' + 1
        matrix def `rpred' = J(`npred',4,.)
        local rnm "mu"
        forvalues i = 0(1)`max_i' {
            local rnm "`rnm' `i'"
        }
        matrix rownames `rpred' = `rnm'
        matrix colnames `rpred' = Predict LB UB Category
        matrix `rpred'[1,1] = `mu'
        matrix `rpred'[1,2] = `mu_lo'
        matrix `rpred'[1,3] = `mu_hi'
        if "`diff'" != "diff"  {
            PRTyciH `c_lo' `level' 1
            PRTy 2 "Rate" `yfmt' `c_cur' `mu'
            PRTyci `yfmt' `c_lo' `level' `mu_lo' ///
                `c_hi' `mu_hi'
        } // not diff

        if "`diff'"=="diff" {
            PRTdH `c_curDH' `c_savDH' `c_difDH'
            PRTdciH `c_lvlDH' `level'
            sca `mu_prev' = _PRVsav[1,1]
            sca `mu_dif' = `mu' - `mu_prev'
            sca `mu_dif_hi' = `ciupper'[7,2]
            sca `mu_dif_lo' = `cilower'[7,2]
            PRTd 2 "Rate" `yfmt' `c_curD' `mu' ///
                `c_savD' `mu_prev'  `c_difD' `mu_dif'
            PRTdci `pfmt' `c_loD' `mu_dif_lo' ///
               `c_hiD' `mu_dif_hi'

            * 2008-07-10 r(pred) for dif
            matrix rownames `rpred' = `rnm'
            matrix colnames `rpred' = DPredict LB UB Category
            matrix `rpred'[1,1] = `mu_dif'
            matrix `rpred'[1,2] = `mu_dif_lo'
            matrix `rpred'[1,3] = `mu_dif_hi'

        } // diff

        *cycle from 0 to maximum desired count
        local i = 0
        local isodd = 0
        while `i' <= `max_i' { // loop through outcome values

            local isodd = abs(`isodd' - 1)
            mat `values' = nullmat(`values') \ `i'
            tempname p`i' p_lo`i' p_hi`i' lo hi
            local i1 = `i' + 1
            sca `p`i'' = pepred[2,`i1']
            sca `p_hi`i'' = `ciupper'[2,`i1']
            sca `p_lo`i'' = `cilower'[2,`i1']

            * 2008-06-15 r(pred)
            local irow = `i' + 2
            matrix `rpred'[`irow',1] = `p`i''
            matrix `rpred'[`irow',2] = `p_lo`i''
            matrix `rpred'[`irow',3] = `p_hi`i''
            matrix `rpred'[`irow',4] = `i'

            mat `probs' = nullmat(`probs') \ `p`i''
            if "`diff'"=="" {
                PRTy 2 "Pr(y=`i'|x)" `pfmt' `c_cur' `p`i''
                PRTyci `pfmt' `c_lo' `level' `p_lo`i'' ///
                    `c_hi' `p_hi`i''
            }

            else { // if differnece
                sca `p_prev' = _PRVp[`i'+1, 1]
                sca `p_dif' = `p`i''-`p_prev'
                sca `p_prev' = pepred[4,`i'+1]
                sca `p_dif' = pepred[6,`i'+1]
                sca `plo_dif' = `cilower'[6,`i'+1]
                sca `phi_dif' = `ciupper'[6,`i'+1]
                PRTd 2 "Pr(y=`i'|x)" `pfmt' `c_curD' `p`i'' ///
                    `c_savD' `p_prev' `c_difD' `p_dif'
                PRTdci `pfmt' `c_loD' `plo_dif' ///
                    `c_hiD' `phi_dif'

                * 2008-06-15 r(pred)
                matrix `rpred'[`irow',1] = `p_dif''
                matrix `rpred'[`irow',2] = `plo_dif'
                matrix `rpred'[`irow',3] = `phi_dif'

            }

            local i = `i' + 1
        } // loop through outcome values

        if "`save'"=="save" {
            mat _PRVsav = `mu', `stdp'
            mat colnames _PRVsav = mu stdp
            mat _PRVp = `probs'
        }

        return matrix values `values'
        return matrix probs `probs'

    } // count output

//  #19  COUNT - zip and zinb

    if "`input'"=="twoeq" {
        sca `mu' = pepred[3,2] // overall rate E(y) - 15Apr2005
        sca `mu_lo' = `cilower'[3,2]
        sca `mu_hi' = `ciupper'[3,2]
        return scalar mu = `mu'
        * mu from count portion of zi models - 15Apr2005
        sca `mucount' = pepred[3,3] // rate in count portion of model E(y|~always0)
        sca `mucount_lo' = `cilower'[3,3] // currently not computed
        sca `mucount_hi' = `ciupper'[3,3] // currently not computed
        sca `stdp' = peinfo[1,8]
        return scalar mucount = `mucount'
        return local level `level'

        * 2008-06-15 r(pred) for mu and probs
        local npred = 2 + `max_i' + 1
        matrix def `rpred' = J(`npred',4,.)

        * 2008-07-10
        local rnm "Ey All0 0|xy"
        forvalues i = 1(1)`max_i' {
            local rnm "`rnm' `i'|x"
        }

        matrix rownames `rpred' = `rnm'
        matrix colnames `rpred' = Predict LB UB Category
        matrix `rpred'[1,1] = `mu'
        matrix `rpred'[1,2] = `mu_lo'
        matrix `rpred'[1,3] = `mu_hi'
        * 2008-07-10 matrix `rpred'[2,1] = `mucount'

        * relabel Rate to Expected y - 15Apr2005
        if "`diff'"!="diff" & "`bootstrap'"=="bootstrap" { // ci with boot
            PRTyciH `c_lo' `level' 1
            PRTy 2 "Expected y" `yfmt' `c_cur' `mu'
            PRTyci `yfmt' `c_lo' `level' `mu_lo' ///
                `c_hi' `mu_hi'
        }
        else if "`diff'"!="diff" & "`bootstrap'"!="bootstrap" {
            di
            PRTy 2 "Expected y" `yfmt' `c_cur' `mu'
            di
        }

        * print E(y)
        if "`diff'"=="diff" {
            sca `mu_prev' = pepred[5,2]
            sca `mu_dif' = pepred[7,2]
                PRTdH `c_curDH' `c_savDH' `c_difDH'

            if "`brief'"=="brief" & "`bootstrap'"!="bootstrap" {
                di
            }

            if "`bootstrap'"=="bootstrap" {
                *PRTdH `c_curDH' `c_savDH' `c_difDH'
                PRTdciH `c_lvlDH' `level'
                sca `mu_dif_hi' = `ciupper'[7,2]
                sca `mu_dif_lo' = `cilower'[7,2]
                PRTd 2 "Expected y" `yfmt' `c_curD' `mu' ///
                    `c_savD' `mu_prev'  `c_difD' `mu_dif'
                PRTdci `pfmt' `c_loD' `mu_dif_lo' ///
                   `c_hiD' `mu_dif_hi'
                * 2008-07-10 r(pred) for dif
                matrix `rpred'[1,2] = `mu_dif_lo'
                matrix `rpred'[1,3] = `mu_dif_hi'
            }
            else {
                di
                PRTd 2 "Expected y" `pfmt' `c_curD' `mu' ///
                `c_savD' `mu_prev'  `c_difD' `mu_dif'
                di
            }

            * 2008-07-10 r(pred) for dif
            matrix colnames `rpred' = DPredict LB UB Category
            matrix `rpred'[1,1] = `mu_dif'

        } // dif for rate

        sca `all0' = pepred[3,4]
        sca `all0_hi' = `ciupper'[3,4]
        sca `all0_lo' = `cilower'[3,4]

        * 2008-07-10 r(pred) for dif
        matrix `rpred'[2,1] = `all0'
        matrix `rpred'[2,2] = `all0_lo'
        matrix `rpred'[2,3] = `all0_hi'

        if "`diff'"=="diff" {
            sca `all0_prev' = pepred[5,4]
            sca `all0_dif' = pepred[7,4]

            * 2008-07-10 r(pred) for dif
            matrix `rpred'[2,1] = `all0_dif'

            if "`bootstrap'"=="bootstrap" {
                sca `all0_dif_hi' = `ciupper'[7,4]
                sca `all0_dif_lo' = `cilower'[7,4]
                PRTd 2 "Pr(Always0|z)" `pfmt' `c_curD' `all0' ///
                    `c_savD' `all0_prev'  `c_difD' `all0_dif'
                PRTdci `pfmt' `c_loD' `all0_dif_lo' ///
                   `c_hiD' `all0_dif_hi'

                * 2008-07-10 r(pred) for dif
                matrix `rpred'[2,2] = `all0_dif_lo'
                matrix `rpred'[2,3] = `all0_dif_hi'

            }
            else {
                PRTd 2 "Pr(Always0|z)" `pfmt' `c_curD' `all0' ///
                    `c_savD' `all0_prev'  `c_difD' `all0_dif'
                di
            }

            * 2008-07-10 r(pred) for dif
            matrix `rpred'[2,1] = `all0_dif'

        }
        if "`diff'"!="diff" & "`bootstrap'"=="bootstrap" {
            PRTy 2 "Pr(Always0|z)" `pfmt' `c_cur' `all0'
            PRTyci `pfmt' `c_lo' `level' `all0_lo' ///
                `c_hi' `all0_hi'
        }
        else if "`diff'"!="diff" { // default, no ci
            PRTy 2 "Pr(Always0|z)" `pfmt' `c_cur' `all0'
            di
        }
        return scalar always0 = `all0'

        * loop from count 0 to maxcount
        local i = 0
        local isodd = 0
        while `i' <= `max_i' {
            local given "x"
            if "`i'" == "0" {
                local given "x,z"
            }
            mat `values' = nullmat(`values') \ `i'
            tempname p`i' p_lo`i' p_hi`i' lo hi
            local i1 = `i' + 1
            sca `p`i'' = pepred[2,`i1']
            mat `probs' = nullmat(`probs') \ `p`i''

            * 2008-06-15 r(pred)
            local irow = `i' + 3
            matrix `rpred'[`irow',1] = `p`i''
            matrix `rpred'[`irow',4] = `i'

            if "`diff'"=="" {
                PRTy 2 "Pr(y=`i'|`given')" `pfmt' `c_cur' `p`i''
                if "`cimethod'"=="bootstrap" {
                    PRTyci `pfmt' `c_lo' `level' `cilower'[2,`i1'] ///
                        `c_hi' `ciupper'[2,`i1']
                }
                else {
                    di
                }
            }
            else { // if differnece
                sca `p_prev' = _PRVp[`i'+1, 1]
                sca `p_dif' = `p`i''-`p_prev'
                sca `p_prev' = pepred[4,`i'+1]
                sca `p_dif' = pepred[6,`i'+1]
                PRTd 2 "Pr(y=`i'|`given')" `pfmt' `c_curD' `p`i'' ///
                    `c_savD' `p_prev' `c_difD' `p_dif'

                * 2008-07-10 r(pred) for dif
                matrix `rpred'[`irow',1] = `p_dif''

                if "`cimethod'"=="bootstrap" {
                    PRTdci `pfmt' `c_loD' `cilower'[6,`i'+1] ///
                         `c_hiD' `ciupper'[6,`i'+1]

                    * 2008-07-10 r(pred) for dif
                    matrix `rpred'[`irow',2] = `cilower'[6,`i'+1]
                    matrix `rpred'[`irow',2] = `ciupper'[6,`i'+1]

                }
                else {
                    di
                }
            }
            local i = `i' + 1
        }
        if "`save'"=="save" {
            mat _PRVsav = `mu', `stdp'
            mat colnames _PRVsav = mu stdp
                mat _PRVsav = `mu', `stdp', `all0'
                mat colnames _PRVsav = mu stdp all0
            mat _PRVp = `probs'
        }

        return matrix values `values'
        return matrix probs `probs'

    } // count zip and zinb

//  #20  COUNT - ztp and ztnb * 18Feb2005

    if "`e(cmd)'"=="ztp" | "`e(cmd)'"=="ztnb" {

        sca `mu' = pepred[3,2]
        return scalar mu = `mu'
        sca `Cmu' = peCpred[3,2]
        return scalar Cmu = `Cmu'
        tempname plo_dif phi_dif
        return local level `level'

        * 2008-06-15 r(pred) for mu and probs
        local npred = 2 + `max_i'
        matrix def `rpred' = J(`npred',5,.)
        local rnm "mu 0"                    // changed bj 24jul2008
        forvalues i = 1(1)`max_i' {
            local rnm "`rnm' `i'"
        }
        matrix rownames `rpred' = `rnm'
        matrix colnames `rpred' = Ucond LB UB Category Cond
        matrix `rpred'[1,1] = `mu'
        matrix `rpred'[1,5] = `Cmu'

        if "`diff'" != "diff"  {
            local C_cur = `c_cur' + 9
            di _n _col(`c_cur') in g " Uncond     Cond"
            PRTy 2 "Rate" `yfmt' `c_cur' `mu'
            di _col(`C_cur') `yfmt' `Cmu'
        } // not diff

        if "`diff'"=="diff" {
             sca `mu_prev' = pepred[5,2]
             sca `mu_dif' = pepred[7,2]
             sca `Cmu_prev' = peCpred[5,2]
             sca `Cmu_dif' = peCpred[7,2]
        di
        di in g ///
            "                  Unconditional:                  Conditional:"
        di in g ///
            "                  Current      Saved    Change    Current     Saved    Change "
        di in g ///
        "  Rate:" _col(19) in y `yfmt' `mu' _col(30) `yfmt' `mu_prev' _col(40) `yfmt' `mu_dif' _cont
        di _col(51) ///
            `yfmt' `Cmu' _col(61) `yfmt' `Cmu_prev' _col(71) `yfmt' `Cmu_dif'

        * 2008-07-10 r(pred) for dif
        matrix `rpred'[1,1] = `mu_dif'
        matrix `rpred'[1,5] = `Cmu_dif'

        } // diff
        *cycle from 0 to maximum desired count
        local i = 0
        local isodd = 0
        while `i' <= `max_i' { // loop through outcome values
            local isodd = abs(`isodd' - 1)
            mat `values' = nullmat(`values') \ `i'
            tempname p`i' Cp`i'
            local i1 = `i' + 1
            sca `p`i'' = pepred[2,`i1']
            sca `Cp`i'' = peCpred[2,`i1']
            mat `probs' = nullmat(`probs') \ `p`i''
            mat `Cprobs' = nullmat(`Cprobs') \ `Cp`i''

            * 2008-06-15 r(pred)
            local irow = `i' + 2
            matrix `rpred'[`irow',1] = `p`i''
            matrix `rpred'[`irow',5] = `Cp`i''
            matrix `rpred'[`irow',4] = `i'

            if "`diff'"=="" {
                PRTy 2 "Pr(y=`i'|x)" `pfmt' `c_cur' `p`i''
                di _col(`C_cur') `pfmt' `Cp`i''
            }
            else { // if differnece
                sca `p_prev' = pepred[4,`i'+1]
                sca `p_dif' = pepred[6,`i'+1]
                sca `Cp_prev' = peCpred[4,`i'+1]
                sca `Cp_dif' = peCpred[6,`i'+1]
                di in g "  Pr(y=`i'|x)" in y ///
                    _col(19) `pfmt' `p`i'' _col(30) `pfmt' `p_prev' ///
                    _col(40) `pfmt' `p_dif' _cont
                di  _col(51) `pfmt' `Cp`i'' _col(61) `pfmt' `Cp_prev' ///
                    _col(71) `pfmt' `Cp_dif'

                * 2008-07-10 r(pred) for dif
                local irow = `i' + 2
                matrix `rpred'[`irow',1] = `p_dif'
                matrix `rpred'[`irow',5] = `Cp_dif'
                matrix `rpred'[`irow',4] = `i'

            }
            local i = `i' + 1

        } // loop through outcome values
        return matrix values `values'
        return matrix probs `probs'
        return matrix Cprobs `Cprobs'

    } // ztp and ztnb


//21  OUTPUT COMMON TO ALL MODELS

    * print base values
    * 2009-03-17 if "`brief'"=="" & "`base'"!="nobase" {
    if "`base'"!="nobase" {

        * 2009-03-17
        if "`input'"=="twoeq" & "`brief'"=="" {
            di _n in g "x values for count equation"
        }
        mat rownames `tobase' = "x="
        if "`diff'"=="" {
            mat _PEtemp = `tobase'
            _peabbv _PEtemp
            * 2009-03-17
            if "`brief'"=="" {
                mat list _PEtemp, noheader
            }
        }
        else {
            local tmp1: colnames `tobase'
            local tmp2: colnames PRVbase
            * 2009-05-10 if "`tmp1'"=="`tmp2'" & length("`tmp1'") < 80 {
            * if "`tmp1'"=="`tmp2'" & length("`tmp1'") < 244 { // 2.5.1 2010-01-07
            *if "`tmp1'"=="`tmp2'" { // 2.5.3 2010-03-25 experimental
if `: list local(tmp1) == local(tmp2) ' {            
                mat _PEtemp = (`tobase' \ PRVbase \ (`tobase' - PRVbase))
                mat rownames _PEtemp = "Current=" "Saved=" "Diff="
                _peabbv _PEtemp
                * 2009-03-17
                if "`brief'"=="" {
                    mat list _PEtemp, noheader
                }
            }
            else {
                mat rownames `tobase' = "Current="
                mat rownames PRVbase =  "  Saved="
                mat _PEtemp = `tobase'
                _peabbv _PEtemp
                * 2009-03-17
                if "`brief'"=="" {
                    mat list _PEtemp, noheader
                }
                mat _PEtemp = PRVbase
                _peabbv _PEtemp
                * 2009-03-17
                if "`brief'"=="" {
                    mat list _PEtemp, noheader
                }
            }
        }

        * print base values of binary equation
        if "`input'"=="twoeq" {
            * 2009-03-17
            if "`brief'"=="" {
                di _n in g "z values for binary equation"
                mat rownames `tobase2' = "z="
            }
            if "`diff'"=="" {
                * 2009-03-15
                mat _PEtemp2 = `tobase2'
                _peabbv _PEtemp2
                * 2009-03-17
                if "`brief'"=="" {
                    mat list _PEtemp2, noheader
                }
            }
            else {
                local tmp1: colnames `tobase2'
                local tmp2: colnames PRVbase2
                
                * 2.5.0: if "`tmp1'"=="`tmp2'"  & length("`tmp1'") < 80 {
                * string comparisons are only valid for certain lengths
                *if "`tmp1'"=="`tmp2'"  & length("`tmp1'") < 244 { // 2.5.1 2010-01-07
                *if "`tmp1'"=="`tmp2'" { // 2.5.3 2010-03-25 experimental
if `: list local(tmp1) == local(tmp2) ' {                 

                    mat `temp' = (`tobase2' \ PRVbase2 \ (`tobase2' - PRVbase2))
                    mat rownames `temp' = "Current=" "Saved=" "Diff="
                    * 2009-03-15
                    mat _PEtemp2 = `temp'
                    _peabbv _PEtemp2
                    * 2009-03-17
                    if "`brief'"=="" {
                        mat list _PEtemp2, noheader
                    }
                }
                else {
                    mat rownames `tobase2' = "Current="
                    mat rownames PRVbase2 = "  Saved="
                    * 2009-03-15
                    mat _PEtemp2 = `tobase2'
                    _peabbv _PEtemp2
                    * 2009-03-17
                    if "`brief'"=="" {
                        mat list _PEtemp2, noheader
                    }
                    mat _PEtemp2 = PRVbase2
                    _peabbv _PEtemp2
                    * 2009-03-17
                    if "`brief'"=="" {
                        mat list _PEtemp2, noheader
                    }
                }
            }
        } /* twoeq */
    }

    if "`save'"=="save" {

    // With the "save" option, the results of the current model
    // are placed in globals to be used with a later prvalue, diff

        * save information needed for later -prvalue, diff-
        global PRVcmd = "`e(cmd)'" // command name
        global PRVdepv = "`e(depvar)'" // dependent variable
        mat PRVbase = `tobase' // base values
        mat rownames PRVbase = "saved="
        if "`input'"=="twoeq" {
            mat PRVbase2 = `tobase2'
            mat rownames PRVbase2 = "saved x"
        }
        mat PRVprob = pepred[2,1...] // probabilities
        mat rownames PRVprob = "saved="
        mat PRVmisc = pepred[3,1...] // other predictions
        mat rownames PRVmisc = "saved="
        mat PRVupper = peupper[2..3,1...] // for pr and misc
        mat PRVlower = pelower[2..3,1...] //
        mat PRVinfo = peinfo[1,1...] // information on saved model
        mat rownames PRVinfo = "saved="
        if ("`e(cmd)'"=="ztp" | "`e(cmd)'"=="ztnb") {
            mat PRVCpred = peCpred[2,1...]
            mat rownames PRVCpred = "saved="
            mat PRVCmisc = peCpred[3,1...]
            mat rownames PRVCmisc = "saved="
        }

    } // if save

    * 2009-03-15 return r(x) as dif in X if diff
    if "`diff'"!="diff" {
        return mat x `tobase'
        if "`input'"=="twoeq" {
            return mat x2 `tobase2'
        }
    }

*mat list _PEtemp
*mat list _PEtemp2

    if "`diff'"=="diff" {
        tempname difx
        * 2009-05-10
        mat `difx' = _PEtemp[3,1...]
        mat rownames `difx' = "DiffX"
        return mat x `difx'
        if "`input'"=="twoeq" {
            mat `difx' = _PEtemp2[3,1...]
            mat rownames `difx' = "DiffX"
            return mat x2 `difx'
        }
    }

    * 2008-07-10 return pred with SE and Zscore
    tempname Xz Xs
    * if ystar or count, need to reconstruct se for difference
    if "`ystar'"=="ystar" { // | "`output'"=="count" {
        * hold SE of pred and z value
        matrix `Xz' = J(1,2,.)
        matrix colnames `Xz' = SE z
        * if not diff, use peinfo
        local se = peinfo[1,8]
        if "`diff'"=="diff" {
             local se = $pedifsey
        }
        matrix `Xz'[1,1] = `se'
        matrix `Xz'[1,2] = `rpred'[1,1]/`se'
    }
    * for probabilities
    else {
        local Npred = rowsof(`rpred')
        * hold SE of pred and z value
        matrix `Xz' = J(`Npred',2,.)
        matrix colnames `Xz' = SE z
        * grab standard errors
        capture mat `Xs' = pedifsep
        * if not computed, dummy up matrix
        if _rc!=0 {
            matrix `Xs' = J(`Npred',1,.)
        }
        local j = 0
        if "`output'"=="count" {
            local j = 1
            if "`diff'"!="diff" {
                matrix `Xz'[1,1] = $pesemu
            }
            else {
                matrix `Xz'[1,1] = $pedifsemu
            }
            matrix `Xz'[1,2] = `rpred'[1,1]/`Xz'[1,1]
        }
        * loop through predictions and compute z's
        local en = `Npred' - `j'
        forvalues  i = 1(1)`en' {
            local i2 = `i' + `j'
            local z = `rpred'[`i2',1]/`Xs'[`i',1]
            matrix `Xz'[`i2',1] = `Xs'[`i',1]
            matrix `Xz'[`i2',2] = `z'
        }
    }

    * add se and z to matrix
    if "`e(cmd)'"=="ztp" | "`e(cmd)'"=="ztnb" {
        * only ztp and ztnb have cond and uncond, so stick cond at end
        matrix `rpred' = `rpred'[1...,1..4],`Xz',`rpred'[1...,5]
    }
    else {
        matrix `rpred' = `rpred',`Xz'
    }
    return mat pred `rpred'
    capture drop pedifsep
    capture drop pedifsey
    capture drop _PEtemp
    * 2009-03-15
    capture matrix drop _PEtemp
    capture matrix drop _PEtemp2

end // prvalue

//
//22 PRINT ROUTINES
//

// PRTy: value w/o ci
// PRTy skip label fmt c_cur value

capture program drop PRTy
program PRTy
    version 8
    args skip label fmt c_cur value
    di in g _skip(`skip') "`label':" ///
       in y `fmt' _col(`c_cur') `value' _continue
end

// PRTyciH: header for ci in difference
// PRTyciH c_lvl level addline

capture program drop PRTyciH
program PRTyciH
    version 8
    args c_lvl level addline
    if `addline' == 1 {
        di
    }
    di _col(`c_lvl') in g " `level'% Conf. Interval"
end

// PRTyci: ci after value
// PRTyci fmt c_lo level value_lo c_hi value_hi
// c_lo column for low; c_hi column for hi

capture program drop PRTyci
program PRTyci
    version 8
    args fmt c_lo level value_lo c_hi value_hi
    di _col(`c_lo') in g "[" ///
        in y `fmt' `value_lo' in g "," ///
        in y `fmt' _col(`c_hi') `value_hi' in g "]"
end

/* this version puts 90% on each line
program PRTyci
    version 8
    args fmt c_lo level value_lo c_hi value_hi
    di _col(`c_lo') in g "`level'% CI (" ///
        in y `fmt' `value_lo' in g "," ///
        in y `fmt' _col(`c_hi') `value_hi' in g ")"
end
*/

// PRTdH: header for difference
// PRTdH c_cur c_sav c_dif

capture program drop PRTdH
program PRTdH
    version 8
    *args c_cur c_sav c_dif
    * 2.0.7
    args c_cur c_sav c_dif nmsave nmcurrent
    di
    * 2.0.6
    if "`nmsave'"!="" | "`nmcurrent'"!="" {
        * 2.0.7
        local lcur : length local nmcurrent
        local lcur = `c_cur' + 7 - `lcur'
        local lsav : length local nmsave
        local lsav = `c_sav' + 5 - `lsav'
        di _col(`lcur') in g "`nmcurrent'" ///
            _col(`lsav') in g "`nmsave'"
    } // 2.0.7
    di _col(`c_cur') in g "Current" ///
       _col(`c_sav') in g "Saved"   ///
       _col(`c_dif') in g "Change" _continue
end

// PRTdciH: header for ci in difference
// PRTdciH c_lvl level

capture program drop PRTdciH
program PRTdciH
    version 8
    args c_lvl level
    di _col(`c_lvl') in g "`level'% CI for Change"
end

// PRTd: print difference
// PRTd skip label fmt c_cur v_cur c_sav v_sav c_dif v_dif

capture program drop PRTd
program PRTd
    version 8
    args skip label fmt c_cur v_cur c_sav v_sav c_dif v_dif
    di _skip(`skip') in g "`label':" ///
        in y `fmt' _col(`c_cur') `v_cur' ///
        in y `fmt' _col(`c_sav') `v_sav' ///
        in y `fmt' _col(`c_dif') `v_dif' _continue
end

// PRTdci: print difference
// PRTdci fmt c_lo v_lo c_hi v_lo

capture program drop PRTdci
program PRTdci
    version 8
    args fmt c_lo v_lo c_hi v_hi
    di  in g _col(`c_lo') "[" ///
        in y `fmt' `v_lo' in g "," ///
        in y `fmt' _col(`c_hi') `v_hi' in g "]"
end
exit

15Apr2005 - correct error for zip and zinb
    : see changes in _pepred, _pecollect, _peciboot
    : E(y) was used incorrectly rather than E(y|~always0).

    _pepred[3|5|7, 2] used to be mu defined as rate in
        count portion of model E(y|not always 0)

    _pepred[3|5|7, 2] now is the overall rate E(y); listed as simply mu.

    _pepred[3|5|7, 3] rate in count portion of model E(y|not always 0);
        listed as mucount.

    To simplify changes in _peciboot, E(y) is referred to as mu;
        E(y|~always0) is mucount.

* version 0.2.2b 050218 jf slogit
* version 2.0.0 07Apr2005
* version 2.0.1 12Apr2005 fix save dif for slogit; no ci in slogit dif
* version 2.0.2 13Apr2005
* version 2.0.3 15Apr2005 fix rate used for zip/zinb (see notes at end)
* version 2.0.4 15Apr2005 fix label for Always 0
* version 2.0.5 24May2006 - fix base values when multiple diffs
* version 2.1.0 2007-03-04 - add labels() & save-dif improvement
* version 2.1.1 2008-06-15
*  - add returns in r()
* version 2.1.2 2008-07-09 r(pred) for dif
* - returns if diff
* version 2.1.3 2008-07-09
*   - return predSE -- standard error
* version 2.1.4 2008-07-10
*   - fix se for ystar
* version 2.1.6 2008-10-23
*   - change bootstrapped to bootstrap
* version 2.1.5bj bj 22jul2008 for use with esttab
* version 2.1.5 2008-07-11
*   - fix typo in tempname
* version 2.1.7 2009-03-14
*   - merge 2.1.6 with changes for estout
* version 2.1.8 2009-03-14
*   - mprobit does not compute CI
* version 2.1.9 2009-03-15
*   - dif returns difference of X's
* version 2.2.0 2009-03-17
*   - fixed bug with brief after diff caused by 2.1.9
*   - estout needed information saved when brief was off, so
*       only block printing in option is brief
* version 2.2.1 2009-05-10
*   - remove if "`tmp1'"=="`tmp2'" & length("`tmp1'") < 80 {
* version 2.2.2 - as of 2009-09-18 
*   - fix for mlogit under stata 11
* version 2.5.0 2009-10-28 jsl
*  - stata 11 update for returns from -mlogit-
* version 2.5.1 2010-01-07 jsl
*  - change limit on long var lists to 244 from 80
* version 2.5.2 2010-01-15 jsl
*  change x_peciboot to _peciboot
* version 2.5.3 2010-03-25 -- never posted
*  explore removing length restrictions
