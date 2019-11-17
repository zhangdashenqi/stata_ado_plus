*! version 1.0.6  14jun2017  Ben Jann

program kmatch, eclass
    version 11
    if replay() {
        Display `0'
        exit
    }
    gettoken subcmd: 0, parse(", ")
    if `"`subcmd'"'== substr("summarize",1,max(2,strlen(`"`subcmd'"'))) {
        Postest summarize `0'
        exit
    }
    if `"`subcmd'"'== substr("density",1,max(4,strlen(`"`subcmd'"'))) {
        Postest density `0'
        exit
    }
    if `"`subcmd'"'== substr("cumul",1,max(3,strlen(`"`subcmd'"'))) {
        Postest cumul `0'
        exit
    }
    if "`subcmd'"=="box" {
        Postest box `0'
        exit
    }
    if `"`subcmd'"'== substr("csummarize",1,max(3,strlen(`"`subcmd'"'))) {
        Postest csummarize `0'
        exit
    }
    if `"`subcmd'"'== substr("cdensity",1,max(5,strlen(`"`subcmd'"'))) {
        Postest cdensity `0'
        exit
    }
    if `"`subcmd'"'== substr("ccumul",1,max(4,strlen(`"`subcmd'"'))) {
        Postest ccumul `0'
        exit
    }
    if "`subcmd'"=="cbox" {
        Postest cbox `0'
        exit
    }
    if `"`subcmd'"'== substr("cvplot",1,max(2,strlen(`"`subcmd'"'))) {
        Postest_cvplot `0'
        exit
    }
    local version : di "version " string(_caller()) ":"
    Parse_hasvceopt `0'
    if `hasvceopt' {
        `version' VCE_Estimate `0' // returns diopts
    }
    else {
        Estimate `0' // returns diopts
    }
    ereturn local cmdline `"kmatch `0'"'
    Display, `diopts'
    if `"`e(generate)'`e(dy)'"'!="" {
        tempname rcurrent
        _return hold `rcurrent'
        di as txt _n "Stored variables" _c
        describe `e(generate)' `e(dy)', fullnames
        _return restore `rcurrent'
    }
end

program Parse_hasvceopt
    _parse comma lhs 0 : 0
    syntax [, vce(passthru) * ]
    if strpos(`"`lhs'"',"(")==0 & `"`vce'"'!="" {
        di as err "outcome variable required if option vce() is specified"
        exit 198
    }
    c_local hasvceopt = `"`vce'"'!=""
end

program VCE_Estimate, eclass
    local version : di "version " string(_caller()) ":"
    gettoken subcmd 0: 0, parse(", ")
    syntax anything(equalok) [if] [in] [pw iw fw] [, vce(str) nn NN2(passthru) ///
        BWidth(str) GENerate GENerate2(passthru) DY DY2(passthru) replace ///
        noHEader noTABle noMTABle Level(passthru) * ]
    local options `nn' `nn2' `level' `options' 
    _get_diopts diopts options, `options'
    c_local diopts `header' `table' `mtable' `diopts'
    local genopts `generate' `generate2' `dy' `dy2' `replace'
    if "`weight'"!="" local wgt [`weight'`exp']
    Parse_vceopt `vce' // returns vcecmd, vcevars, vceopts

    // compute bandwidth and generate variables, if needed
    capt numlist `"`bwidth'"', min(1)
    local getbw = _rc
    if `"`bwidth'"'!="" local bwidth bwidth(`bwidth')
    if `"`nn'`nn2'"'!="" local getbw = 0
    local hasgen = `"`genopts'"'!=""
    if `getbw' | `hasgen' {
        Parse_eq `anything' // returns tvar, xvars, novars, ovars, ovar_#, xvars_#, opts_#
        marksample touse
        markout `touse' `vcevars'
        forv i=1/`novars' {
            markout `touse' `ovar_`i'' `xvars_`i''
        }
        Estimate `subcmd' `tvar' `xvars' if `touse' `wgt', ///
            `bwidth' `genopts' `options'
        local e_generate `"`e(generate)'"'
        local e_dy `"`e(dy)'"'
        if `getbw' {
            display ""
            local e_bw_method `"`e(bw_method)'"'
            if `"`e(pm_quantile)'"'!="" {
                tempname e_pm_quantile
                scalar `e_pm_quantile' = e(pm_quantile)
            }
            if `"`e(pm_factor)'"'!="" {
                tempname e_pm_factor
                scalar `e_pm_factor' = e(pm_factor)
            }
            if `"`e(cv_factor)'"'!="" {
                tempname e_cv_factor
                scalar `e_cv_factor' = e(cv_factor)
            }
            local e_cv_weighted  `"`e(cv_weighted)'"'
            local e_cv_nopenalty `"`e(cv_nopenalty)'"'
            local e_cv_nolimit   `"`e(cv_nolimit)'"'
            local e_cv_outcome   `"`e(cv_outcome)'"'
            local e_cv_exact     `"`e(cv_exact)'"'
            capt confirm matrix e(cv)
            if _rc==0 {
                tempname e_cv
                matrix `e_cv' = e(cv)
            }
            capt confirm matrix e(cv_treated)
            if _rc==0 {
                tempname e_cv_treated
                matrix `e_cv_treated' = e(cv_treated)
            }
            capt confirm matrix e(cv_untreated)
            if _rc==0 {
                tempname e_cv_untreated
                matrix `e_cv_untreated' = e(cv_untreated)
            }
            tempname BW
            mat `BW' = e(bwidth)
            local bwidth
            local c = colsof(`BW')
            forv i = 1/`=rowsof(`BW')' {
                forv j = 1/`c' {
                    local bw = `BW'[`i',`j']
                    local bwidth `bwidth' `bw'
                }
            }
            local bwidth bwidth(`bwidth')
        }
    }
    
    // run vcecmd
    capt noisily `version' ///
        `vcecmd', noheader notable reject(e(k_omit)) `vceopts' `level': ///
        kmatch `subcmd' `anything' `if' `in' `wgt', noheader notable ///
        nomtable `bwidth' `options'
    if _rc {
        if `hasgen' {
            drop `e_generate' `e_dy'
        }
        exit _rc
    }
    if `hasgen' {
        eret local generate `"`e_generate'"'
        eret local dy `"`e_dy'"'
    }
    if `getbw' {
        eret local bw_method `"`e_bw_method'"'
        if "`e_pm_quantile'"!="" {
            eret scalar pm_quantile = `e_pm_quantile'
        }
        if "`e_pm_factor'"!="" {
            eret scalar pm_factor = `e_pm_factor'
        }
        if "`e_cv_factor'"!="" {
            eret scalar cv_factor = `e_cv_factor'
        }
        eret local cv_weighted  `"`e_cv_weighted'"'
        eret local cv_nopenalty `"`e_cv_nopenalty'"'
        eret local cv_nolimit   `"`e_cv_nolimit'"'
        eret local cv_outcome   `"`e_cv_outcome'"'
        eret local cv_exact     `"`e_cv_exact'"'
        if "`e_cv'"!="" {
            eret matrix cv = `e_cv'
        }
        if "`e_cv_treated'"!="" {
            eret matrix cv_treated = `e_cv_treated'
        }
        if "`e_cv_untreated'"!="" {
            eret matrix cv_untreated = `e_cv_untreated'
        }
    }
end

program Parse_vceopt
    _parse comma vcecmd 0 : 0
    if `"`vcecmd'"'== substr("bootstrap",1,max(4,strlen(`"`vcecmd'"'))) {
        c_local vcecmd bootstrap
    }
    else if `"`vcecmd'"'== substr("jackknife",1,max(4,strlen(`"`vcecmd'"'))) {
        c_local vcecmd jackknife
    }
    else {
        di as err `"`vcecmd' not allowed in vce()"'
        exit 198
    }
    syntax [, STRata(varlist) CLuster(varlist) group(varname) JACKknifeopts(str) * ]
    Parse_vceopt_jack, `jackknifeopts'  // returns vcevars
    c_local vcevars `vcevars' `strata' `cluster' `group'
    if "`strata'"!=""  local strata strata(`strata')
    if "`cluster'"!="" local cluster cluster(`cluster')
    if "`group'"!=""   local group group(`group')
    c_local vceopts `strata' `cluster' `group' `jackknifeopts' `options'
end

program Parse_vceopt_jack
    syntax [, CLuster(varlist) * ]
    c_local vcevars `cluster'
end

program Display
    if `"`e(cmd)'"'!="kmatch" {
        di as err "last kmatch results not found"
        exit 301
    }
    syntax [, noHEader noTABle noMTABle * ]
    _get_diopts diopts, `options'
    if `"`header'"'=="" {
        _coef_table_header, nomodeltest
        if `"`e(nn)'"'!="" {
            di as txt _col(49) "Neighbors:" _col(63) "min" _col(67) "= " as res %10.0g e(nn_min)
        }
        else {
            di as txt _col(49) "Kernel" _col(67) "= " as res %10s e(kernel)
        }
        di as txt "Treatment : " e(tvar) " = " as res e(tval) _c
        if `"`e(nn)'"'!="" {
            di as txt _col(63) "max" _col(67) "= " as res %10.0g e(nn_max)
        }
        else if `"`e(ridge)'"'!="" {
            di as txt _col(49) "Ridge parameter" _col(67) "= " as res %10.0g e(ridge)
        }
        else di ""
        if `"`e(subcmd)'"'=="md" {
            di as txt "Metric    : " as res e(metric) _c
            if `"`e(metric)'"'=="matrix" {
                di as txt " (user)"
            }
            else if `"`e(metric_units)'`e(metric_weights)'"'!="" {
                di as txt " (modified)"
            }
            else di ""
        }
        local covars `"`e(xvars)'"'
        if strlen(`"`covars'"')>66 {
            local covars: piece 1 62 of `"`covars'"'
            local covars `"`covars' ..."'
        }
        if `"`covars'"'=="" local covars "(none)"
        di as txt "Covariates: " `"`covars'"'
        if `"`e(ematch)'"'!="" {
            local covars `"`e(ematch)'"'
            if strlen(`"`covars'"')>66 {
                local covars: piece 1 62 of `"`covars'"'
                local covars `"`covars' ..."'
            }
            di as txt "Exact     : " `"`covars'"'
        }
        if `"`e(pscore)'"'!="" {
            di as txt "Pscore    : " e(pscore)
        }
        else if `"`e(pscmd)'"'!="" {
            di as txt "PS model  : " as res e(pscmd) ///
                as txt " (" as res e(pspredict) as txt ")"
            if `"`e(psvars)'"'!="" {
                local covars `"`e(psvars)'"'
                if strlen(`"`covars'"')>66 {
                    local covars: piece 1 62 of `"`covars'"'
                    local covars `"`covars' ..."'
                }
                di as txt "PS covars : " `"`covars'"'
            }
        }
        if `"`e(over)'"'!="" {
            di as txt ""
            forv i = 1/`e(N_over)' {
                local oval: word `i' of `e(over_namelist)'
                local olab: word `i' of `e(over_labels) '
                di as txt %10s "`oval'" ": " e(over) " = " as res "`olab'"
            }
        }
    }
    if `"`mtable'"'=="" {
        tempname N BW
        mat `BW' = e(bwidth)
        forv i=1/`e(N_over)' {
            mat `N' = nullmat(`N') \ `BW'[`i',1...]'
            if `"`e(ate)'"'!="" mat `N' = `N' \ .
        }
        mat coln `N' = "Band-:width_"
        mat `N' = e(_N), `N' 
        di _n as txt "Matching statistics"
        matlist `N', twidth(11) border(top bottom) format(%7.0g) noblank ///
            showcoleq(combined) underscore
    } 
    if `"`table'"'=="" & e(N_ovars) {
        di _n as txt "Treatment-effects estimation"
        eret di, `options'
        if e(N_ovars)==1 {
            if `"`e(avars)'"'!="" {
                local covars `"adjusted for `e(avars)'"'
                if strlen(`"`covars'"')>78 {
                    local covars: piece 1 74 of `"`covars'"'
                    local covars `"`covars' ..."'
                }
                di as txt `"`covars'"'
            }
            exit
        }
        local d 0
        local covars `"`e(avars1)'"'
        forv i = 2/`e(N_ovars)' {
            if `"`e(avars`i')'"'!=`"`covars'"' {
                local d 1
                continue, break
            }
            local covars `"`e(avars`i')'"'
        }
        if `d'==0 {
            local covars `"`e(avars1)'"'
            if `"`covars'"'!="" {
                local covars `"adjusted for `covars'"'
                if strlen(`"`covars'"')>78 {
                    local covars: piece 1 74 of `"`covars'"'
                    local covars `"`covars' ..."'
                }
                di as txt `"`covars'"'
            }
            exit
        }
        forv i = 1/`e(N_ovars)' {
            local covars `"`e(avars`i')'"'
            if `"`covars'"'!="" {
                local covars `"`e(ovar`i')': adjusted for `covars'"'
                if strlen(`"`covars'"')>78 {
                    local covars: piece 1 74 of `"`covars'"'
                    local covars `"`covars' ..."'
                }
                di as txt `"`covars'"'
            }
        }
    }
end

program Postest
    if `"`e(cmd)'"'!="kmatch" {
        di as err "last kmatch results not found"
        exit 301
    }
    if `"`e(generate)'"'=="" {
        di as txt "(refitting the model using the {cmd:generate()} option)"
        tempname ecurrent
        tempvar TREAT NC NM MW PS
        _est hold `ecurrent', restore copy
        Refit_with_generate, generate(`TREAT' `NC' `NM' `MW' `PS')
    }
    gettoken subcmd 0 : 0
    gettoken tmp 0 : 0, parse(", ")
    if "`subcmd'"=="summarize" {
        Postest_summarize `0'
        exit
    }
    if inlist("`subcmd'", "density", "cumul", "box") {
        Postest_graph `subcmd' `0'
        exit
    }
    if "`subcmd'"=="csummarize" {
        Postest_csummarize `0'
        exit
    }
    if inlist("`subcmd'", "cdensity", "ccumul", "cbox") {
        Postest_graph `subcmd' `0'
        exit
    }
end

program Refit_with_generate
    syntax, generate(passthru)
    local cmd `e(subcmd)'
    local cmd `cmd' `e(tvar)'
    local cmd `cmd' `e(xvars)'
    if `"`e(wtype)'"'!="" {
        local cmd `cmd' [`e(wtype)' `e(wexp)']
    }
    local cmd `cmd' if e(sample), `generate'
    if `"`e(ematch)'"'!="" {
        local cmd `cmd' ematch(`e(ematch)')
    }
    if `"`e(over)'"'!="" {
        local cmd `cmd' over(`e(over)')
    }
    if e(tval)!=1 {
        local cmd `cmd' tvalue(`e(tval)')
    }
    local isnn 0
    if `"`e(nn)'"'!="" {
        local isnn 1
        local cmd `cmd' nn(`e(nn)')
    }
    else {
        local cmd `cmd' kernel(`e(kernel)')
        if `"`e(ridge)'"'!="" {
            local cmd `cmd' ridge(`e(ridge)')
        }
    }
    tempname BW 
    mat `BW' = e(bwidth)
    if `isnn'==0 | matmissing(`BW')==0 {
        local bwidth
        local c = colsof(`BW')
        forv i = 1/`=rowsof(`BW')' {
            forv j = 1/`c' {
                local bw = `BW'[`i',`j']
                local bwidth `bwidth' `bw'
            }
        }
        local cmd `cmd' bwidth(`bwidth')
    }
    if `"`e(subcmd)'"'=="md" {
        if `"`e(metric)'"'=="euclidean" {
            local cmd `cmd' metric(euclidean)
        }
        else if `"`e(xvars)'"'!="" {
            tempname S
            mat `S' = e(S)
            local cmd `cmd' metric(matrix `S')
        }
        if `"`e(mdmethod)'"'!="" {
            local cmd `cmd' mdmethod(`e(mdmethod)')
        }
        if `"`e(psvars)'"'!="" {
            local cmd `cmd' psvars(`e(psvars)')
        }
    }
    if `"`e(pscore)'"'!="" {
        local cmd `cmd' pscore(`e(pscore)')
    }
    if `"`e(pscmd)'"'!="" {
        local cmd `cmd' pscmd(`e(pscmd)')
    }
    if `"`e(psopts)'"'!="" {
        local cmd `cmd' psopts(`e(psopts)')
    }
    if `"`e(pspredict)'"'!="" {
        local cmd `cmd' pspredict(`e(pspredict)')
    }
    if e(comsup_lb)<. {
        local comsup `e(comsup_lb)'
        if e(comsup_ub)<. {
            local comsup `comsup' `e(comsup_ub)'
        }
        local cmd `cmd' comsup(`comsup')
    }
    local cmd `cmd' `e(ate)' `e(att)' `e(atc)'
    //di `"`cmd'"'
    quietly Estimate `cmd'
end

program Postest_summarize, rclass
    syntax [ varlist(default=none fv numeric) ] [ , ate att atc ///
        sd meanonly varonly ]
    if "`meanonly'"!="" & "`varonly'"!="" {
        di as err "only one of meanonly and varonly allowed"
        exit 198
    }
    
    // Reference statistic
    _Postest_refstat, `ate' `att' `atc' // returns refstat
    
    // get kmatch variables
    local vlist `"`e(generate)'"'
    gettoken treat vlist : vlist
    gettoken nc vlist : vlist
    gettoken nm vlist : vlist
    gettoken mw vlist : vlist
    gettoken ps vlist : vlist
    
    // set varlist
    if "`varlist'"=="" {
        local varlist "`e(xvars)'"
    }
    fvexpand `varlist' if e(sample)
    local xvars
    foreach v in `r(varlist)' {
        if strpos(`"`v'"', "b.") continue // remove base levels
        if strpos(`"`v'"', "o.") continue // remove omitted
        local xvars `xvars' `v'
    }
    local nvars: list sizeof xvars
    if `nvars'<1 {
        di "(no variables specified; nothing to do)"
        exit
    }

    // sample, variables, weights
    tempname touse
    qui gen byte `touse' = (e(sample)==1)
    local wtype "`e(wtype)'"
    if "`wtype'"!="" {
        tempvar wvar
        qui gen double `wvar' `e(wexp)'
        if "`wtype'"=="pweight" {
            local wgt "[aweight = `wvar']"
        }
        else local wgt "[`wtype' = `wvar']"
        if "`wtype'"=="fweight" {
            tempvar mwvar
            qui gen double `mwvar' = `mw' * `wvar' if `touse'
            local mw `mwvar' 
        }
    }
    if "`refstat'"=="ate" {
        if "`wtype'"!="" {
            local Cwgt "[iweight = `wvar'*(`nc'>0) + `mw']"
            local Twgt "[iweight = `wvar'*(`nc'>0) + `mw']"
        }
        else {
            local Cwgt "[iweight = (`nc'>0) + `mw']"
            local Twgt "[iweight = (`nc'>0) + `mw']"
        }
    }
    else if "`refstat'"=="att" {
        if "`wtype'"!="" {
            local Cwgt "[iweight = `mw']"
            local Twgt "[iweight = `wvar'*(`nc'>0)]"
        }
        else {
            local Cwgt "[iweight = `mw']"
            local Twgt "[iweight = (`nc'>0)]"
        }
    }
    else if "`refstat'"=="atc" {
        if "`wtype'"!="" {
            local Cwgt "[iweight = `wvar'*(`nc'>0)]"
            local Twgt "[iweight = `mw']"
        }
        else {
            local Cwgt "[iweight = (`nc'>0)]"
            local Twgt "[iweight = `mw']"
        }
    }
    else exit 499
    
    // compute results
    tempname M0 M V S
    if `"`e(over)'"'!="" {
        local over `"`e(over)'"'
        local overlevels `"`e(over_namelist)'"'
        local nover: list sizeof overlevels
    }
    else local nover 1
    mat `M0' = J(`nvars',6,.)
    mat rown `M0' = `xvars'
    forv j=1/`nover' {
        local l: word `j' of `overlevels'
        mat roweq `M0' = "`l'"
        mat `M' = nullmat(`M') \ `M0'
    }
    mat `V' = `M'
    mat `S' = `M'[1..., 1]
    forv j=1/`nover' {
        if `"`over'"'!="" {
            local l: word `j' of `overlevels'
            local oif `"& `over'==`l'"'
        }
        else local oif
        local i 0
        foreach v of local xvars {
            local ++i
            local r = (`j'-1)*`nvars' + `i'
            qui su `v' `wgt' if `touse' & `treat'==1 `oif'
            mat `M'[`r', 1] = r(mean)
            mat `V'[`r', 1] = r(Var)
            if "`sd'"!="" mat `V'[`r', 1] = sqrt(`V'[`r', 1])
            mat `S'[`r', 1] = r(Var)
            qui su `v' `wgt' if `touse' & `treat'==0 `oif'
            mat `M'[`r', 2] = r(mean)
            mat `V'[`r', 2] = r(Var)
            if "`sd'"!="" mat `V'[`r', 2] = sqrt(`V'[`r', 2])
            mat `S'[`r', 1] = sqrt((r(Var) + `S'[`r', 1])/2)
            mat `M'[`r', 3] = (`M'[`r', 1]-`M'[`r', 2])/`S'[`r', 1]
            mat `V'[`r', 3] = `V'[`r', 1]/`V'[`r', 2]
            qui su `v' `Twgt' if `touse' & `treat'==1 `oif'
            mat `M'[`r', 4] = r(mean)
            mat `V'[`r', 4] = r(Var)
            if "`sd'"!="" mat `V'[`r', 4] = sqrt(`V'[`r', 4])
            qui su `v' `Cwgt' if `touse' & `treat'==0 `oif'
            mat `M'[`r', 5] = r(mean)
            mat `V'[`r', 5] = r(Var)
            if "`sd'"!="" mat `V'[`r', 5] = sqrt(`V'[`r', 5])
            mat `M'[`r', 6] = (`M'[`r', 4]-`M'[`r', 5])/`S'[`r', 1]
            mat `V'[`r', 6] = `V'[`r', 4]/`V'[`r', 5]
        }
    }
    
    // display
    local mlbl `"Matched (`=strupper("`refstat'")')"'
    local twidth 0
    foreach v of local xvars {
        local twidth = max(`twidth',strlen("`v'"))
    }
    local twidth = max(12, min(`twidth'+1, c(linesize)-63))
    mat coln `M' = "Raw:Treated"    "Raw:Untreated"    "Raw:StdDif" ///
                "`mlbl':Treated" "`mlbl':Untreated" "`mlbl':StdDif"
    if "`varonly'"=="" {
        matlist `M', border(top bottom) format(%8.0g) showcoleq(combined) ///
            rowtitle(Means) twidth(`twidth')
    }
    if "`sd'"=="" local ti "Variances"
    else {
        if `twidth'<14      local ti "Std dev"
        else if `twidth'<19 local ti "Std deviation"
        else                local ti "Standard deviation"
    }
    mat coln `V' = "Raw:Treated"    "Raw:Untreated"    "Raw:Ratio" ///
                "`mlbl':Treated" "`mlbl':Untreated" "`mlbl':Ratio"
    if "`meanonly'"=="" {
        matlist `V', border(top bottom) format(%8.0g) showcoleq(combined) ///
        rowtitle(`ti') twidth(`twidth')
    }
    
    // returns
    ret local refstat "`refstat'"
    ret matrix M = `M'
    if "`sd'"=="" {
        ret matrix V = `V'
    }
    else {
        ret matrix SD = `V'
    }
    ret matrix S = `S'
end

program _Postest_refstat
    syntax [, ate att atc ]
    local refstat `ate' `att' `atc'
    if `:list sizeof refstat'>1 {
        di as err "only one of ate, att, and atc is allowed"
        exit 198
    }
    if "`refstat'"=="" {
        local refstat `e(ate)' `e(att)' `e(atc)'
        if `: list sizeof refstat'>1 {
            gettoken refstat : refstat
        }
        c_local refstat "`refstat'"
        exit
    }
    else if "`refstat'"=="ate" {
        if `"`e(ate)'"'=="" & !(`"`e(att)'"'!="" & `"`e(atc)'"'!="") {
            di as error "ate not allowed in this context"
            exit 198 
        }
    }
    else if "`refstat'"=="att" {
        if `"`e(ate)'`e(att)'"'=="" {
            di as error "att not allowed in this context"
            exit 198 
        }
    }
    else if "`refstat'"=="atc" {
        if `"`e(ate)'`e(atc)'"'=="" {
            di as error "atc not allowed in this context"
            exit 198 
        }
    }
    c_local refstat "`refstat'"
end

program Postest_csummarize, rclass
    syntax [ varlist(default=none fv numeric) ] [ , ate att atc ///
        sd meanonly varonly ]
    if "`meanonly'"!="" & "`varonly'"!="" {
        di as err "only one of meanonly and varonly allowed"
        exit 198
    }
    
    // Reference statistic
    _Postest_refstat, `ate' `att' `atc' // returns refstat
    
    // get kmatch variables
    local vlist `"`e(generate)'"'
    gettoken treat vlist : vlist
    gettoken nc vlist : vlist
    
    // set varlist
    if "`varlist'"=="" {
        local varlist "`e(xvars)'"
    }
    fvexpand `varlist' if e(sample)
    local xvars
    foreach v in `r(varlist)' {
        if strpos(`"`v'"', "b.") continue // remove base levels
        if strpos(`"`v'"', "o.") continue // remove omitted
        local xvars `xvars' `v'
    }
    local nvars: list sizeof xvars
    if `nvars'<1 {
        di "(no variables specified; nothing to do)"
        exit
    }

    // sample, variables, weights
    tempname touse
    qui gen byte `touse' = (e(sample)==1)
    local wtype "`e(wtype)'"
    if "`wtype'"!="" {
        tempvar wvar
        qui gen double `wvar' `e(wexp)'
        if "`wtype'"=="pweight" {
            local wgt "[aweight = `wvar']"
        }
        else local wgt "[`wtype' = `wvar']"
    }
    if "`refstat'"=="ate" {
        // do nothing
    }
    else if "`refstat'"=="att" {
        qui replace `touse' = 0 if `touse' & `treat'==0
    }
    else if "`refstat'"=="atc" {
        qui replace `touse' = 0 if `touse' & `treat'==1
    }
    else exit 499
    
    // compute results
    tempname M0 M V S
    if `"`e(over)'"'!="" {
        local over `"`e(over)'"'
        local overlevels `"`e(over_namelist)'"'
        local nover: list sizeof overlevels
    }
    else local nover 1
    mat `M0' = J(`nvars',6,.)
    mat rown `M0' = `xvars'
    forv j=1/`nover' {
        local l: word `j' of `overlevels'
        mat roweq `M0' = "`l'"
        mat `M' = nullmat(`M') \ `M0'
    }
    mat `V' = `M'
    mat `S' = `M'[1..., 1]
    forv j=1/`nover' {
        if `"`over'"'!="" {
            local l: word `j' of `overlevels'
            local oif `"& `over'==`l'"'
        }
        else local oif
        local i 0
        foreach v of local xvars {
            local ++i
            local r = (`j'-1)*`nvars' + `i'
            qui su `v' `wgt' if `touse' & `nc' `oif'
            mat `S'[`r', 1] = r(sd)
            mat `M'[`r', 1] = r(mean)
            mat `V'[`r', 1] = r(Var)
            if "`sd'"!="" mat `V'[`r', 1] = sqrt(`V'[`r', 1])
            qui su `v' `wgt' if `touse' & `nc'==0 `oif' 
            mat `M'[`r', 2] = r(mean)
            mat `V'[`r', 2] = r(Var)
            if "`sd'"!="" mat `V'[`r', 2] = sqrt(`V'[`r', 2])
            qui su `v' `wgt' if `touse' `oif'
            mat `M'[`r', 3] = r(mean)
            mat `V'[`r', 3] = r(Var)
            if "`sd'"!="" mat `V'[`r', 3] = sqrt(`V'[`r', 3])
            mat `M'[`r', 4] = (`M'[`r', 1]-`M'[`r', 3])/`S'[`r', 1]
            mat `M'[`r', 5] = (`M'[`r', 2]-`M'[`r', 3])/`S'[`r', 1]
            mat `M'[`r', 6] = (`M'[`r', 1]-`M'[`r', 2])/`S'[`r', 1]

            mat `V'[`r', 4] = `V'[`r', 1]/`V'[`r', 3]
            mat `V'[`r', 5] = `V'[`r', 2]/`V'[`r', 3]
            mat `V'[`r', 6] = `V'[`r', 1]/`V'[`r', 2]
        }
    }
    
    // display
    local slbl "Common support"
    if "`refstat'"=="att" local slbl "`slbl' (treated)"
    else if "`refstat'"=="atc" local slbl "`slbl' (untreated)"
    local twidth 0
    foreach v of local xvars {
        local twidth = max(`twidth',strlen("`v'"))
    }
    local twidth = max(12, min(`twidth'+1, c(linesize)-63))
    local sdlb "Standardized difference"
    mat coln `M' = "`slbl':Matched"   "`slbl':Unmatched" "`slbl':Total" ///
                   "`sdlb':(1)-(3)" "`sdlb':(2)-(3)" "`sdlb':(1)-(2)"
    if "`varonly'"=="" {
        matlist `M', border(top bottom) format(%8.0g) showcoleq(combined) ///
            rowtitle(Means) twidth(`twidth')
    }
    if "`sd'"=="" local ti "Variances"
    else {
        if `twidth'<14      local ti "Std dev"
        else if `twidth'<19 local ti "Std deviation"
        else                local ti "Standard deviation"
    }
    mat coln `V' = "`slbl':Matched"   "`slbl':Unmatched" "`slbl':Total" ///
                    "Ratio:(1)/(3)" "Ratio:(2)/(3)"  "Ratio:(1)/(2)"
    if "`meanonly'"=="" {
        matlist `V', border(top bottom) format(%8.0g) showcoleq(combined) ///
        rowtitle(`ti') twidth(`twidth')
    }
    di as txt "(1) matched, (2) unmatched, (3) total"
    
    // returns
    ret local refstat "`refstat'"
    ret matrix M = `M'
    if "`sd'"=="" {
        ret matrix V = `V'
    }
    else {
        ret matrix SD = `V'
    }
    ret matrix S = `S'
end

program Postest_graph, rclass
    gettoken subcmd 0 : 0
    if inlist("`subcmd'", "density", "cdensity") {
        local rc 0
        capt findfile lmoremata.mlib
        if _rc {
            di as error "-moremata- is required; type {stata ssc install moremata}"
            local rc = _rc
        }
        capt findfile lkdens.mlib
        if _rc {
            di as error "-kdens- is required; type {stata ssc install kdens}"
            local rc = _rc
        }
        if `rc' error 499
    }
    syntax [ varlist(default=none numeric) ] [, ate att atc ///
        Overlevels(numlist int >=0) TItles(str asis) ///
        COMBopts(str) name(passthru) nodraw * ]
    
    // Reference population
    _Postest_refstat, `ate' `att' `atc' // returns refstat

    // get kmatch variables
    local vlist `"`e(generate)'"'
    gettoken treat vlist : vlist
    gettoken nc vlist : vlist
    gettoken nm vlist : vlist
    gettoken mw vlist : vlist
    gettoken ps vlist : vlist
    if inlist("`subcmd'", "density", "cdensity") {
        local psname "psname(`ps')"
    }
    
    // set varlist
    if "`varlist'"=="" {
        if `"`e(subcmd)'"'=="ps" {
            local varlist `ps'
            local vnm4note vnm4note(propensity score)
        }
        else {
            di as err "varlist required"
            exit 100
        }
    }
    
    // overlevels
    if `"`overlevels'"'!="" {
        if `"`e(over)'"'=="" {
            di as err "{bf:overlevels()} only allowed if option {bf:over()}" ///
                " has been applied when calling {bf:kmatch `e(subcmd)'}"
            exit 198
        }
        local overlvls `"`e(over_namelist)'"'
        if `: list overlevels in overlvls'==0 {
            di as err "overlevels(): invalid level specified"
            exit 498
        }
    }
    else local overlevels `"`e(over_namelist)'"'
    
    // single graph
    if `:list sizeof varlist'==1 & `:list sizeof overlevels'<=1 {
        preserve
        Postest_`subcmd' `treat' `nc' `mw' `varlist', `psname' `vnm4note' ///
            title(`titles') refstat(`refstat') overlevel(`overlevels') ///
            `options' `name' `draw'
        ret local refstat "`refstat'"
        exit
    }
    
    // no over
    if `"`overlevels'"'=="" {
        preserve
        local grnames
        foreach v of local varlist {
            tempname grname
            local grnames `grnames' `grname'
            gettoken title titles : titles
            Postest_`subcmd' `treat' `nc' `mw' `v', `psname' title(`title') ///
                refstat(`refstat') `options' name(`grname') nodraw
            restore, preserve
        }
        restore, not
        graph combine `grnames', `combopts'
        ret local refstat "`refstat'"
        exit
    }
    
    // over
    preserve
    local grnames
    foreach o of local overlevels {
        foreach v of local varlist {
            tempname grname
            local grnames `grnames' `grname'
            gettoken title titles : titles
            Postest_`subcmd' `treat' `nc' `mw' `v', `psname' title(`title') ///
                refstat(`refstat') overlevel(`o') `options' name(`grname') nodraw
            restore, preserve
        }
    }
    restore, not
    graph combine `grnames', `combopts'
    ret local refstat "`refstat'"
end

program Postest_density
    syntax varlist [, psname(str) vnm4note(str) ///
        TItle(passthru) refstat(str) overlevel(str) ///
        n(int 512) Kernel(passthru) ll(str) ul(str) REFLection lc ///
        BWidth(str) ADJust(passthru) Adaptive Adaptive2(passthru) ///
        LABels(str asis) BYOPTs(str) * ]
    gettoken treat varlist : varlist
    gettoken nc varlist : varlist
    gettoken mw varlist : varlist
    gettoken varlist : varlist
    if `"`vnm4note'"'=="" local vnm4note `"`varlist'"'
    
    // sample, variables, weights
    qui keep if e(sample)==1
    if `"`overlevel'"'!="" {
        qui keep if `e(over)'==`overlevel'
        if `"`title'"'=="" local title title("`e(over)' = `overlevel'")
        local overtag "`e(over)'=`overlevel': "
    }
    qui count if `varlist'>=.
    if r(N)>0 {
        di as txt "(`overtag'`vnm4note' has missing values)"
    }
    if `"`e(wtype)'"'!="" {
        tempvar wvar
        qui gen double `wvar' `e(wexp)'
        local wgt "[aweight = `wvar']"
        if `"`e(wtype)'"'=="fweight" {
            tempvar mwvar
            qui gen double `mwvar' = `mw' * `wvar'
            local mw `mwvar' 
        }
    }
    keep `varlist' `treat' `nc' `mw' `wvar'
    if _N<`n' {
        qui set obs `n'
    }
    
    // evaluation grid
    if "`varlist'"=="`psname'" {
        if `"`ll'`ul'"'=="" {
            su `varlist', meanonly
            if inrange(r(min),0,1) & inrange(r(max),0,1) {
                local ll 0
                local ul 1
                di as txt "(`overtag'applying 0-1 boundary correction" ///
                    " to density estimation of `vnm4note')"
            }
        }
    }
    if `"`ll'"'=="." local ll
    else             local ll ll(`ll')
    if `"`ul'"'=="." local ul
    else             local ul ul(`ul')
    local AT0 1
    local MAT0 1
    local AT1 1
    local MAT1 1
    tempname at0 at1 mat0 mat1
    su `varlist' if `treat'==0, meanonly
    if r(min)==r(max) {
        di as txt "(`overtag'cannot estimate density of `vnm4note' in " ///
            "control group; no variance or not enough observations)"
        qui gen byte `at0' = .
        local AT0 0
        qui gen byte `mat0' = .
        local MAT0 0
    }
    else {
        qui range `at0' `r(min)' `r(max)' `n'
        if "`refstat'"=="ate" {
            su `varlist' if `treat'==0 & (`nc' | `mw'), meanonly
        }
        else if "`refstat'"=="att" {
            su `varlist' if `treat'==0 & `mw', meanonly
        }
        else {
            su `varlist' if `treat'==0 & `nc', meanonly
        }
        if r(min)==r(max) {
            di as txt "(`overtag'cannot estimate density of `vnm4note' in " ///
                "matched control group; no variance or not enough observations)"
            qui gen byte `mat0' = .
            local MAT0 0
        }
        else qui range `mat0' `r(min)' `r(max)' `n'
    }
    su `varlist' if `treat'==1, meanonly
    if r(min)==r(max) {
        di as txt "(`overtag'cannot estimate density of `vnm4note' in " ///
            "treatment group; no variance or not enough observations)"
        qui gen byte `at1' = .
        local AT1 0
        qui gen byte `mat1' = .
        local MAT1 0
    }
    else {
        qui range `at1' `r(min)' `r(max)' `n'
        if "`refstat'"=="ate" {
            su `varlist' if `treat'==1 & (`nc' | `mw'), meanonly
        }
        else if "`refstat'"=="att" {
            su `varlist' if `treat'==1 & `nc', meanonly
        }
        else {
            su `varlist' if `treat'==1 & `mw', meanonly
        }
        if r(min)==r(max) {
            di as txt "(`overtag'cannot estimate density of `vnm4note' in " ///
                "matched treatment group; no variance or not enough observations)"
            qui gen byte `mat1' = .
            local MAT1 0
        }
        else qui range `mat1' `r(min)' `r(max)' `n'
    }
    
    // density estimation
    tempvar d0 d1 md0 md1
    local kopts n(`n') `kernel' `ll' `ul' `reflection' `lc' `adaptive' `adaptive2'
    if `AT0' | `AT1' {  // determine bandwidth
        qui _kdens `varlist' `wgt', gen(`d0') at(`at0') bw(`bwidth') `adjust' `kopts'
        local bwidth = r(width)
        drop `d0'
    }
    else local bwidth .
    local kopts `kopts' bw(`bwidth')
    di as txt "(`overtag'bandwidth for `vnm4note' = " `bwidth' ")"
    if `AT0' {
        qui _kdens `varlist' if `treat'==0 `wgt', gen(`d0') at(`at0') `kopts'
    }
    else qui gen byte `d0' = .
    if `AT1' {
        qui _kdens `varlist' if `treat'==1 `wgt', gen(`d1') at(`at1') `kopts'
    }
    else qui gen byte `d1' = .
    if "`refstat'"=="ate" {
        tempname ww
        if "`wvar'"!="" qui gen double `ww' = `wvar'*(`nc'>0) + `mw'
        else            qui gen double `ww' = (`nc'>0) + `mw'
        if `MAT0' {
            qui _kdens `varlist' if `treat'==0 [aw = `ww'], ///
                gen(`md0') at(`mat0') `kopts'
        }
        else qui gen byte `md0' = .
        if `MAT1' {
            qui _kdens `varlist' if `treat'==1 [aw = `ww'], ///
                gen(`md1') at(`mat1') `kopts'
        }
        else qui gen byte `md1' = .
        drop `ww'
    }
    else if "`refstat'"=="att" {
        if `MAT0' {
            qui _kdens `varlist' if `treat'==0 [aw = `mw'], ///
                gen(`md0') at(`mat0') `kopts'
        }
        else qui gen byte `md0' = .
        if `MAT1' {
            qui _kdens `varlist' if `treat'==1 & `nc' `wgt', ///
                gen(`md1') at(`mat1') `kopts'
        }
        else qui gen byte `md1' = .
    }
    else if "`refstat'"=="atc" {
        if `MAT0' {
            qui _kdens `varlist' if `treat'==0 & `nc' `wgt', ///
                gen(`md0') at(`mat0') `kopts'
        }
        else qui gen byte `md0' = .
        if `MAT1' {
            qui _kdens `varlist' if `treat'==1 [aw = `mw'], ///
                gen(`md1') at(`mat1') `kopts'
        }
        else qui gen byte `md1' = .
    }
    else exit 499
    local xti: var lab `varlist'
    if `"`xti'"'=="" local xti `varlist'
    drop `varlist' `treat' `sup' `wvar'
    qui keep if _n<=`n'
    
    // reshape
    tempname id 
    qui gen double `id'= _n
    qui expand 2
    sort `id' 
    tempname by
    qui by `id': gen byte `by' = _n==2
    qui replace `d0' = `md0' if `by'
    qui replace `at0' = `mat0' if `by'
    qui replace `d1' = `md1' if `by'
    qui replace `at1' = `mat1' if `by'
    drop `md0' `mat0' `md1' `mat1'
    gettoken lbl0 labels : labels
    gettoken lbl1 labels : labels
    if `"`lbl0'"'=="" local lbl0 "Raw"
    if `"`lbl1'"'=="" {
        local lbl1 `"Matched (`=strupper("`refstat'")')"'
    }
    lab def `by' 0 `"`lbl0'"' 1 `"`lbl1'"'
    lab val `by' `by'
    lab var `d0' "Untreated"
    lab var `d1' "Treated"
    
    // graph
    qui drop `id'
    qui gen double `id'= _n
    qui expand 2
    sort `id'
    tempvar at
    qui by `id': gen double `at' = cond(_n==1,`at0',`at1')
    qui by `id': replace `d0' = . if _n==2
    qui by `id': replace `d1' = . if _n==1
    two line `d0' `d1' `at', by(`by', `title' note("") `byopts') ///
        yti("Density") xti(`"`xti'"') `options'
end

program Postest_cdensity
    syntax varlist [, psname(str) vnm4note(str) ///
        TItle(passthru) refstat(str) overlevel(str) ///
        n(int 512) Kernel(passthru) ll(str) ul(str) REFLection lc ///
        BWidth(str) ADJust(passthru) Adaptive Adaptive2(passthru) ///
        NOMatched NOUnmatched NOTOTal * ]
    if "`nomatched'"!="" & "`nounmatched'"!="" & "`nototal'"!="" {
        di as err "nomatched, nounmatched, and nototal not all three allowed"
        exit 198
    }
    gettoken treat varlist : varlist
    gettoken nc varlist : varlist
    gettoken mw varlist : varlist
    gettoken varlist : varlist
    if `"`vnm4note'"'=="" local vnm4note `"`varlist'"'
    
    // sample, variables, weights
    qui keep if e(sample)==1
    if `"`overlevel'"'!="" {
        qui keep if `e(over)'==`overlevel'
        if `"`title'"'=="" local title title("`e(over)' = `overlevel'")
        local overtag "`e(over)'=`overlevel': "
    }
    if "`refstat'"=="ate" {
        // do nothing
    }
    else if "`refstat'"=="att" {
        qui keep if `treat'==1
    }
    else if "`refstat'"=="atc" {
        qui keep if `treat'==0
    }
    else exit 499
    qui count if `varlist'>=.
    if r(N)>0 {
        di as txt "(`overtag'`vnm4note' has missing values)"
    }
    if `"`e(wtype)'"'!="" {
        tempvar wvar
        qui gen double `wvar' `e(wexp)'
        local wgt "[aweight = `wvar']"
    }
    keep `varlist' `nc' `wvar'
    if _N<`n' {
        qui set obs `n'
    }
    
    // evaluation grid
    if "`varlist'"=="`psname'" {
        if `"`ll'`ul'"'=="" {
            su `varlist', meanonly
            if inrange(r(min),0,1) & inrange(r(max),0,1) {
                local ll 0
                local ul 1
                di as txt "(`overtag'applying 0-1 boundary correction" ///
                    " to density estimation of `vnm4note')"
            }
        }
    }
    if `"`ll'"'=="." local ll
    else             local ll ll(`ll')
    if `"`ul'"'=="." local ul
    else             local ul ul(`ul')
    local AT1 1
    local AT2 = ("`nounmatched'"=="")
    local AT3 = ("`nomatched'"=="")
    tempname at1 at2 at3
    su `varlist', meanonly
    if r(min)==r(max) {
        di as txt "(`overtag'cannot estimate density of `vnm4note';" ///
            " no variance or not enough observations)"
        qui gen byte `at1' = .
        local AT1 0
        qui gen byte `at2' = .
        local AT2 0
        qui gen byte `at3' = .
        local AT3 0
    }
    else {
        qui range `at1' `r(min)' `r(max)' `n'
    }
    if `AT2' {
        su `varlist' if `nc'==0, meanonly
        if r(min)==r(max) {
            di as txt "(`overtag'cannot estimate density of `vnm4note' among " ///
                "the unmatched; no variance or not enough observations)"
            qui gen byte `at2' = .
            local AT2 0
        }
        else {
            qui range `at2' `r(min)' `r(max)' `n'
        }
    }
    else {
        qui gen byte `at2' = .
    }
    if `AT3' {
        su `varlist' if `nc', meanonly
        if r(min)==r(max) {
            di as txt "(`overtag'cannot estimate density of `vnm4note' among " ///
                "the matched; no variance or not enough observations)"
            qui gen byte `at3' = .
            local AT3 0
        }
        else {
            qui range `at3' `r(min)' `r(max)' `n'
        }
    }
    else {
        qui gen byte `at3' = .
    }
    
    // density estimation
    tempvar d1 d2 d3
    local kopts n(`n') `kernel' `ll' `ul' `reflection' `lc' `adaptive' `adaptive2'
    if `AT1' {  // determine bandwidth
        qui _kdens `varlist' `wgt', gen(`d1') at(`at1') bw(`bwidth') `adjust' `kopts'
        local bwidth = r(width)
    }
    else {
        qui gen byte `d1' = .
        local bwidth .
    }
    local kopts `kopts' bw(`bwidth')
    di as txt "(`overtag'bandwidth for `vnm4note' = " `bwidth' ")"
    if `AT2' {
        qui _kdens `varlist' if `nc'==0 `wgt', gen(`d2') at(`at2') `kopts'
    }
    else qui gen byte `d2' = .
    if `AT3' {
        qui _kdens `varlist' if `nc' `wgt', gen(`d3') at(`at3') `kopts'
    }
    else qui gen byte `d3' = .
    
    // graph
    qui keep if _n<=`n'
    lab var `d1' "Total"
    lab var `d2' "Unmatched"
    lab var `d3' "Matched"
    tempvar id
    qui gen double `id' = _n
    qui expand 3
    sort `id'
    tempvar at
    qui by `id': gen double `at' = cond(_n==1,`at1',cond(_n==2,`at2',`at3'))
    qui by `id': replace `d1' = . if _n!=1
    qui by `id': replace `d2' = . if _n!=2
    qui by `id': replace `d3' = . if _n!=3
    local yvars
    if "`nototal'"==""     local yvars `yvars' `d1'
    if "`nounmatched'"=="" local yvars `yvars' `d2'
    if "`nomatched'"==""   local yvars `yvars' `d3'
    local ti "Density"
    if "`refstat'"=="att"       local ti "`ti' (treated)"
    else if "`refstat'"=="atc"  local ti "`ti' (untreated)"
    local xti: var lab `varlist'
    if `"`xti'"'=="" local xti `varlist'
    two line `yvars' `at', `title' yti("`ti'") ///
        xti(`"`xti'"') `options'
end

program Postest_cumul
    syntax varlist [, vnm4note(str) TItle(passthru) refstat(str) ///
        overlevel(str) LABels(str asis) BYOPTs(str) * ]
    gettoken treat varlist : varlist
    gettoken nc varlist : varlist
    gettoken mw varlist : varlist
    gettoken varlist : varlist
    if `"`vnm4note'"'=="" local vnm4note `"`varlist'"'
    
    // sample, variables, weights
    qui keep if e(sample)==1
    if `"`overlevel'"'!="" {
        qui keep if `e(over)'==`overlevel'
        if `"`title'"'=="" local title title("`e(over)' = `overlevel'")
        local overtag "`e(over)'=`overlevel': "
    }
    qui count if `varlist'>=.
    if r(N)>0 {
        di as txt "(`overtag'`vnm4note' has missing values)"
    }
    tempvar wvar
    if `"`e(wtype)'"'!="" {
        qui gen double `wvar' `e(wexp)'
        if `"`e(wtype)'"'=="fweight" {
            tempvar mwvar
            qui gen double `mwvar' = `mw' * `wvar'
            local mw `mwvar' 
        }
    }
    else qui gen byte `wvar' = 1
    keep `varlist' `treat' `nc' `mw' `wvar'

    // reshape
    tempname id 
    qui gen double `id'= _n
    qui expand 2
    sort `id'
    tempname by
    qui by `id': gen byte `by' = _n==2
    drop `id'
    gettoken lbl0 labels : labels
    gettoken lbl1 labels : labels
    if `"`lbl0'"'=="" local lbl0 "Raw"
    if `"`lbl1'"'=="" {
        local lbl1 `"Matched (`=strupper("`refstat'")')"'
    }
    lab def `by' 0 `"`lbl0'"' 1 `"`lbl1'"'
    lab val `by' `by'
    if "`refstat'"=="ate" {
        qui replace `wvar' = `wvar'*(`nc'>0) + `mw' if `by'==1
    }
    else if "`refstat'"=="att" {
        qui replace `wvar' = `wvar'*(`nc'>0) if `by'==1 & `treat'==1
        qui replace `wvar' = `mw' if `by'==1 & `treat'==0
    }
    else if "`refstat'"=="atc" {
        qui replace `wvar' = `wvar'*(`nc'>0) if `by'==1 & `treat'==0
        qui replace `wvar' = `mw' if `by'==1 & `treat'==1
    }
    else exit 499
    drop `nc' `mw'
    
    // compute cumulatives
    qui keep if `varlist'<. & `wvar'<. & `wvar'>0
    sort `by' `treat' `varlist'
    qui by `by' `treat': replace `wvar' = sum(`wvar')
    qui by `by' `treat' `varlist': keep if _n==_N
    qui by `by' `treat': replace `wvar' = `wvar'/`wvar'[_N]
    
    // graph
    tempvar wvar0 wvar1
    qui gen double `wvar0' = `wvar' if `treat'==0
    qui gen double `wvar1' = `wvar' if `treat'==1
    two line `wvar0' `wvar1' `varlist', connect(J J) ///
        legend(label(1 "Untreated") label(2 "Treated")) ///
        by(`by', `title' note("") `byopts') ///
        yti("Cumulative probability") `options'
end

program Postest_ccumul
    syntax varlist [, vnm4note(str) TItle(passthru) refstat(str) ///
        overlevel(str) NOMatched NOUnmatched NOTOTal * ]
    if "`nomatched'"!="" & "`nounmatched'"!="" & "`nototal'"!="" {
        di as err "nomatched, nounmatched, and nototal not all three allowed"
        exit 198
    }
    gettoken treat varlist : varlist
    gettoken nc varlist : varlist
    gettoken mw varlist : varlist
    gettoken varlist : varlist
    if `"`vnm4note'"'=="" local vnm4note `"`varlist'"'
    
    // sample, variables, weights
    qui keep if e(sample)==1
    if `"`overlevel'"'!="" {
        qui keep if `e(over)'==`overlevel'
        if `"`title'"'=="" local title title("`e(over)' = `overlevel'")
        local overtag "`e(over)'=`overlevel': "
    }
    if "`refstat'"=="ate" {
        // do nothing
    }
    else if "`refstat'"=="att" {
        qui keep if `treat'==1
    }
    else if "`refstat'"=="atc" {
        qui keep if `treat'==0
    }
    else exit 499
    qui count if `varlist'>=.
    if r(N)>0 {
        di as txt "(`overtag'`vnm4note' has missing values)"
    }
    tempvar wvar
    if `"`e(wtype)'"'!="" qui gen double `wvar' `e(wexp)'
    else                  qui gen byte   `wvar' = 1
    keep `varlist' `nc' `wvar'

    // reshape
    tempname id 
    qui gen double `id'= _n
    qui expand 2
    sort `id'
    tempname by
    qui by `id': gen byte `by' = _n==2
    drop `id'
    
    // compute cumulatives
    qui replace `nc' = cond(`by'==0, 0, `nc'>0)
    qui keep if `varlist'<. & `wvar'<.
    sort `by' `nc' `varlist'
    qui by `by' `nc': replace `wvar' = sum(`wvar')
    qui by `by' `nc' `varlist': keep if _n==_N
    qui by `by' `nc': replace `wvar' = `wvar'/`wvar'[_N]
    
    // graph
    local yvars
    if "`nototal'"=="" {
        tempvar yvar
        qui gen double `yvar' = `wvar' if `by'==0
        lab var `yvar' "Total"
        local yvars `yvars' `yvar'
    }
    if "`nounmatched'"=="" {
        tempvar yvar
        qui gen double `yvar' = `wvar' if `by'==1 & `nc'==0
        lab var `yvar' "Unmatched"
        local yvars `yvars' `yvar'
    }
    if "`nomatched'"=="" {
        tempvar yvar
        qui gen double `yvar' = `wvar' if `by'==1 & `nc'==1
        lab var `yvar' "Matched"
        local yvars `yvars' `yvar'
    }
    local ti "Cumulative probability"
    if "`refstat'"=="att"       local ti "`ti' (treated)"
    else if "`refstat'"=="atc"  local ti "`ti' (untreated)"
    two line `yvars' `varlist', connect(J ..) `title' yti("`ti'") `options'
end

program Postest_box
    syntax varlist [, vnm4note(str) ///
        TItle(passthru) refstat(str) overlevel(str) ///
        LABels(str asis) BYOPTs(str) * ]
    gettoken treat varlist : varlist
    gettoken nc varlist : varlist
    gettoken mw varlist : varlist
    gettoken varlist : varlist
    if `"`vnm4note'"'=="" local vnm4note `"`varlist'"'

    // sample, variables, weights
    qui keep if e(sample)==1
    if `"`overlevel'"'!="" {
        qui keep if `e(over)'==`overlevel'
        if `"`title'"'=="" local title title("`e(over)' = `overlevel'")
        local overtag "`e(over)'=`overlevel': "
    }
    qui count if `varlist'>=.
    if r(N)>0 {
        di as txt "(`overtag'`vnm4note' has missing values)"
    }
    tempvar wvar
    if `"`e(wtype)'"'!="" {
        qui gen double `wvar' `e(wexp)'
        if `"`e(wtype)'"'=="fweight" {
            tempvar mwvar
            qui gen double `mwvar' = `mw' * `wvar'
            local mw `mwvar' 
        }
    }
    else qui gen byte `wvar' = 1
    keep `varlist' `treat' `nc' `mw' `wvar'
    
    // prepare data
    tempname treatlbl
    lab def `treatlbl' 0 "Untreated" 1 "Treated"
    lab val `treat' `treatlbl'
    tempname id 
    qui gen double `id'= _n
    qui expand 2
    sort `id' `treat'
    tempname by
    qui by `id' `treat': gen byte `by' = _n==2
    gettoken lbl0 labels : labels
    gettoken lbl1 labels : labels
    if `"`lbl0'"'=="" local lbl0 "Raw"
    if `"`lbl1'"'=="" {
        local lbl1 `"Matched (`=strupper("`refstat'")')"'
    }
    lab def `by' 0 `"`lbl0'"' 1 `"`lbl1'"'
    lab val `by' `by'
    if "`refstat'"=="ate" {
        qui replace `wvar' = `wvar'*(`nc'>0) + `mw' if `by'==1
    }
    else if "`refstat'"=="att" {
        qui replace `wvar' = `wvar'*(`nc'>0) if `by'==1 & `treat'==1
        qui replace `wvar' = `mw' if `by'==1 & `treat'==0 
    }
    else if "`refstat'"=="atc" {
        qui replace `wvar' = `wvar'*(`nc'>0) if `by'==1 & `treat'==0
        qui replace `wvar' = `mw' if `by'==1 & `treat'==1
    }
    else exit 499
    
    // graph
    graph box `varlist' [aw = `wvar'], over(`treat') asyvars ///
        by(`by', `title' note("") `byopts') `options'
end

program Postest_cbox
    syntax varlist [, vnm4note(str) ///
        TItle(passthru) refstat(str) overlevel(str) ///
        NOMatched NOUnmatched NOTOTal * ]
    if "`nomatched'"!="" & "`nounmatched'"!="" & "`nototal'"!="" {
        di as err "nomatched, nounmatched, and nototal not all three allowed"
        exit 198
    }
    gettoken treat varlist : varlist
    gettoken nc varlist : varlist
    gettoken mw varlist : varlist
    gettoken varlist : varlist
    if `"`vnm4note'"'=="" local vnm4note `"`varlist'"'

    // sample, variables, weights
    qui keep if e(sample)==1
    if `"`overlevel'"'!="" {
        qui keep if `e(over)'==`overlevel'
        if `"`title'"'=="" local title title("`e(over)' = `overlevel'")
        local overtag "`e(over)'=`overlevel': "
    }
    if "`refstat'"=="ate" {
        // do nothing
    }
    else if "`refstat'"=="att" {
        qui keep if `treat'==1
    }
    else if "`refstat'"=="atc" {
        qui keep if `treat'==0
    }
    else exit 499
    qui count if `varlist'>=.
    if r(N)>0 {
        di as txt "(`overtag'`vnm4note' has missing values)"
    }
    tempvar wvar
    if `"`e(wtype)'"'!="" qui gen double `wvar' `e(wexp)'
    else                  qui gen double `wvar' = 1
    keep `varlist' `nc' `wvar'
    
    // prepare data
    tempname id 
    qui gen double `id'= _n
    qui expand 2
    sort `id'
    tempname over
    qui by `id': gen byte `over' = 1 + (_n==2) + (_n==2 & `nc')
    drop `id'
    tempname overlbl
    lab def `overlbl' 1 "Total" 2 "Unmatched" 3 "Matched"
    lab val `over' `overlbl'
    if "`nototal'"!=""      qui drop if `over'==1
    if "`nounmatched'"!=""  qui drop if `over'==2
    if "`nomatched'"!=""    qui drop if `over'==3
    
    // graph
    local yti: var lab `varlist'
    if `"`yti'"'=="" local yti `varlist'
    if "`refstat'"=="att"       local ti `"`ti' (treated)"'
    else if "`refstat'"=="atc"  local ti `"`ti' (untreated)"'
    graph box `varlist' [aw = `wvar'], over(`over') asyvars `title' ///
        yti(`"`yti'"') `options'
end

program Postest_cvplot, rclass
    gettoken subcmd 0 : 0, parse(", ")
    if `"`e(cmd)'"'!="kmatch" {
        di as err "last kmatch results not found"
        exit 301
    }
    capt confirm matrix e(cv)
    if _rc {
        di as err "no cross-validation results found"
        exit 499
    }
    syntax [anything] [, NOTreated NOUntreated ///
        TItles(str asis) COMBopts(str) name(passthru) nodraw * ]
    if "`notreated'"!="" & "`nountreated'"!="" {
        di as err "only one of notreated and nountreated allowed"
        exit 198
    }
    
    // overlevels
    numlist `"`anything'"', int min(0) range(>=0)
    local overlevels = "`r(numlist)'"
    if `"`overlevels'"'!="" {
        if `"`e(over)'"'=="" {
            di as err "numlist only allowed if option {bf:over()}" ///
                " has been applied when calling {bf:kmatch `e(subcmd)'}"
            exit 198
        }
        local overlvls `"`e(over_namelist)'"'
        if `: list overlevels in overlvls'==0 {
            di as err "invalid over level specified"
            exit 498
        }
    }
    else local overlevels `"`e(over_namelist)'"'
    
    // preserve data
    preserve
    
    // single graph
    if `:list sizeof overlevels'<=1 {
        _Postest_cvplot, `notreated' `nountreated' title(`titles') ///
            overlevel(`overlevels') `options' `name' `draw'
        exit
    }

    // over
    local grnames
    foreach o of local overlevels {
        tempname grname
        local grnames `grnames' `grname'
        gettoken title titles : titles
        _Postest_cvplot, `notreated' `nountreated' title(`title') ///
            overlevel(`o') `options' name(`grname') nodraw
    }
    graph combine `grnames', `combopts'
end

program _Postest_cvplot
    syntax [, NOTreated NOUntreated Index ///
        Range(numlist max=2 ascending missingok) ///
        TItle(passthru) overlevel(str) sort * ]
    
    // read results
    if `"`overlevel'"'!="" {
        if `"`title'"'=="" local title title("`e(over)' = `overlevel'")
    }
    local N 0
    tempname ATT ATC
    mat `ATT' = e(cv)
    local nres: roweq `ATT'
    local nres: list uniq nres
    local nres: list sizeof nres
    if `nres'>1 {
        if "`nountreated'"=="" {
            if `"`overlevel'"'!="" {
                mat `ATC' = `ATT'["untreated:", "`overlevel':"]
            }
            else {
                mat `ATC' = `ATT'["untreated:", 1...]
            }
            local N = rowsof(`ATC')
        }
        else local ATC
        if "`notreated'"=="" {
            if `"`overlevel'"'!="" {
                mat `ATT' = `ATT'["treated:", "`overlevel':"]
            }
            else {
                mat `ATT' = `ATT'["treated:", 1...]
            }
            local N = rowsof(`ATT')
        }
        else local ATT
    }
    else {
        local ATC
        if `"`overlevel'"'!="" {
            mat `ATT' = `ATT'[1...,"`overlevel':"]
        }
        local N = rowsof(`ATT')
    }
    
    // write data
    drop _all
    qui set obs `N'
    tempname id
    qui gen double `id' = _n
    if "`ATT'"!="" {
        tempvar grid_att mise_att
        mat coln `ATT' = `grid_att' `mise_att'
        quietly svmat double `ATT', names(col)
        if `nres'>1 lab var `mise_att' "Treated"
    }
    if "`ATC'"!="" {
        tempvar grid_atc mise_atc
        mat coln `ATC' = `grid_atc' `mise_atc'
        quietly svmat double `ATC', names(col)
        lab var `mise_atc' "Untreated"
    }
    
    // reshape
    if "`ATT'"!="" & "`ATC'"!="" {
        tempname grid by
        qui expand 2
        sort `id'
        qui by `id': gen byte `by' = _n
        sort `by' `id'
        qui gen double `grid' = cond(`by'==1,`grid_att',`grid_atc')
        qui replace `mise_att' = . if `by'==2
        qui replace `mise_atc' = . if `by'==1
    }
    else if "`ATT'"!="" local grid `grid_att'
    else if "`ATC'"!="" local grid `grid_atc'
    
    // index
    if "`index'"!="" {
        if "`ATT'"!="" & "`ATC'"!="" {
            tempvar tindex cindex
            qui by `by': gen double `tindex' = _n if `by'==1
            qui by `by': gen double `cindex' = _n if `by'==2
            local mlabel mlabel(`tindex' `cindex')
        }
        else local mlabel mlabel(`id')
    }
    
    // select
    local cmissing
    if `"`range'"'!="" {
        local lb: word 1 of `range'
        local ub: word 2 of `range'
        if "`ub'"=="" local ub .
        if "`ATT'"!="" {
            qui replace `mise_att' = . if !inrange(`grid', `lb', `ub')
            local cmissing `cmissing' n
        }
        if "`ATC'"!="" {
            qui replace `mise_atc' = . if !inrange(`grid', `lb', `ub')
            local cmissing `cmissing' n
        }
        qui replace `grid' = . if !inrange(`grid', `lb', `ub')
        local cmissing cmissing(`cmissing')
    }
    
    // sort
    if "`sort'"!="" {
        qui keep if `grid'<.
        sort `by' `grid'
    }
    
    // graph
    local xti "Bandwidth"
    if `"`e(cv_outcome)'"'!="" {
        if `"`e(cv_weighted)'"'!="" local yti "Weighted MISE"
        else                        local yti "MISE"
    }
    else                            local yti "MSE"
    two connected `mise_att' `mise_atc' `grid', `mlabel' `cmissing' ///
        xti("Bandwidth") ytitle("`yti'") `title' `options'
end


program Estimate, eclass sortpreserve
    // subcommand
    gettoken subcmd 0: 0, parse(", ")
    if "`subcmd'"=="ps" {
        local options
    }
    else if "`subcmd'"=="md" {
        local options Metric(str asis) mdmethod(numlist int >=0 <=2 max=1) ///
             PSVars(varlist numeric fv) PSWeight(numlist >0 max=1) 
    }
    else {
        di as err `"invalid subcommand: `subcmd'"'
        exit 198
    }
    
    // syntax
    syntax anything(equalok id="tvar") [if] [in] [pw iw fw] [,                ///
        over(varname numeric) TVALue(int 1) ate att atc nate po               ///
        Kernel(str) BWidth(str) SHaredbwidth                                  ///
        ridge RIDGE2(numlist max=1 >=0) nn NN2(int 0)                         ///
        ematch(varlist numeric) GENerate GENerate2(str) DY DY2(str) replace   ///
        pscore(varname numeric) pscmd(str) PSOPTs(str) PSPRedict(str)         ///
        comsup(numlist ascending max=2 missingok) `options' NOIsily           ///
        noHEader noTABle noMTABle * ///
        ]
    
    // nnmatch
    if `nn2'>0 {
        local nn nn
    }
    else if `nn2'<0 {
        di as err "nn() must be a positive integer"
        exit 198
    }
    else if "`nn'"!="" {
        local nn2 1
    }
    if `nn2' {
        if `"`kernel'"'!="" {
            di as err "nn() and kernel() not both allowed"
            exit 198
        }
        if `"`ridge'`ridge2'"'!="" {
            di as err "nn() and ridge() not both allowed"
            exit 198
        }
    }
    
    // target statistic
    if "`att'`atc'"=="" local ate ate // the default
    
    // display options
    _get_diopts diopts options, `options'
    OptNotAllowed, `options'
    c_local diopts `header' `table' `mtable' `diopts'
    
    // parse equations
    Parse_eq `anything' // returns tvar, xvars, novars, ovars, ovar_#, xvars_#, opts_#
    if "`subcmd'"=="ps" {
        if "`pscore'"!="" & `"`xvars'"'!="" {
            di as txt "(propensity score provided by user; covariates will be ignored)"
            local xvars
        }
    }
    else if `"`psvars'"'!="" & `"`pscore'"'!="" {
        di as err "only one of psvars() and pscore() allowed"
        exit 198
    }
    if "`subcmd'"=="ps" | `"`pscore'`psvars'"'!="" local ps ps
    else local ps
    
    // generate: construct names check whether variables already exist
    if "`generate'"!="" local generate _KM_
    if `"`generate2'"'!="" {
        if `: list sizeof generate2'==1 & substr(`"`generate2'"',-1,.)=="*" {
            local generate = substr(`"`generate2'"',1,strlen(`"`generate2'"')-1)
            capt confirm name `generate'
            if _rc {
                di as error "generate(): invalid name"
                exit 198
            }
            local generate2
        }
        else {
            capt confirm names `generate2'
            if _rc {
                di as error "generate(): invalid names"
                exit 198
            }
            local generate _KM_
        }
    }
    if "`generate'"!="" & "`replace'"=="" {
        local i 0
        foreach v in treat nc nm mw `ps' {
            local ++i
            local vname: word `i' of `generate2'
            if `"`vname'"'=="" local vname `generate'`v'
            confirm new variable `vname'
        }
    }
    if "`dy'"!="" local dy _DY_
    if `"`dy2'"'!="" {
        if `: list sizeof dy2'==1 & substr(`"`dy2'"',-1,.)=="*" {
            local dy = substr(`"`dy2'"',1,strlen(`"`dy2'"')-1)
            capt confirm name `dy'
            if _rc {
                di as error "dy(): invalid name"
                exit 198
            }
            local dy2
        }
        else {
            capt confirm names `dy2'
            if _rc {
                di as error "dy(): invalid names"
                exit 198
            }
            local dy _DY_
        }
    }
    if "`dy'"!="" & "`replace'"=="" {
        local i 0
        foreach v of local ovars {
            local ++i
            local vname: word `i' of `dy2'
            if `"`vname'"'=="" local vname `dy'`v'
            confirm new variable `vname'
        }
    }
    
    // parse bwidth()
    capt numlist `"`bwidth'"', min(1)
    if _rc==0 {
        capt n numlist `"`bwidth'"', min(1) range(>0)
        if _rc {
            di as err "invalid numlist in bwidth()"
            exit _rc
        }
        local bwidth "`r(numlist)'"
    }
    else if `nn2' {
        if `"`bwidth'"'!="" {
            di as err "bwidth() may only contain numlist if nn() is specified"
            exit 198
        }
    }
    else if `"`xvars'`psvars'`pscore'"'=="" {
        if `"`bwidth'"'!="" {
            di as txt "(skipping bandwidth estimation due to lack of covariates)"
        }
        local bwidth = smallestdouble()
    }
    else {
        _parse comma bw_method bw_opts : bwidth
        gettoken bw_method bw_rest : bw_method
        if `"`bw_method'"'=="" local bw_method pm
        if !inlist(`"`bw_method'"', "pm", "cv") {
            di as err `"bwidth(): `bw_method' not allowed"'
            exit 198
        }
        if "`bw_method'"=="pm" { // pair-matching method
            Parse_bw_pm `subcmd' `bw_rest' `bw_opts'
        }
        else {  // cross-validation
            Parse_bw_cv `subcmd' `bw_rest' `bw_opts'
        }
        local bwidth
    }
    
    // mark sample
    marksample touse
    markout `touse' `tvar' `xvars' `over' `ematch' `psvars' `pscore' `cv_outcome'
    forv i=1/`novars' {
        markout `touse' `ovar_`i'' `xvars_`i''
        // can there be variables in opts_# that might need to be taken into account?
    }
    qui count if `touse'
    if (r(N)==0) error 2000
    
    // weights
    if "`weight'"!="" {
        tempvar wvar
        qui gen double `wvar' `exp' if `touse'
        local wexp `"[`weight' = `wvar']"'
        local swexp `"`wexp'"'
        if "`weight'"=="pweight" | "`weight'"=="iweight" {
            local swexp `"[aweight = `wvar']"'
        }
    }
    else local wvar 1
    
    // treatment group
    capt assert (`tvar'>=0 & (`tvar'==trunc(`tvar'))) if `touse'
    if _rc {
        di as err "treatment variable must contain nonnegative integers"
        exit 459
    }
    tempvar treat control
    qui gen byte `treat' = (`tvar'==`tvalue') if `touse'
    qui gen byte `control' = (1-`treat') if `touse'
    
    // prepare over
    if "`over'"!="" {
        capt assert (`over'>=0 & (`over'==trunc(`over'))) if `touse'
        if _rc {
            di as err "over() variable must contain nonnegative integers"
            exit 459
        }
        qui levelsof `over' if `touse'
        local overlevels `r(levels)'
        local nover: list sizeof overlevels
    }
    else local nover 1
    
    // prepare main output tempvars
    tempvar nc nm mw
    foreach v in nc nm mw {
        tempvar `v'
        qui gen double ``v'' = .
    }
    
    // estimate propensity score
    if "`ps'"!="" {
        tempname PS
        if "`pscore'"=="" {
            if "`subcmd'"=="ps"    local psvars `xvars'
            if `"`pscmd'"'==""     local pscmd logit    // the default
            if `"`pspredict'"'=="" local pspredict pr   // the default
            if `"`over'"'!="" {
                qui gen double `PS' = .
                tempvar PStmp
                foreach l of local overlevels {
                    su `treat' if `touse' & (`over'==`l'), meanonly
                    if r(min)==r(max) {
                        di as txt "(`over'=`l': treatment does not vary;" ///
                            " propensity score set to missing)"
                        qui gen double `PStmp' = .
                    }
                    else {
                        qui `noisily' di as txt _n ///
                            "Propensity score estimation for `over'=`l'"
                        capture `noisily' `pscmd' `treat' `psvars' `wexp' ///
                            if `touse' & (`over'==`l'), `psopts'
                        if _rc {
                            di as err "`over'=`l': propensity score" ///
                                " estimation failed"
                            exit 198
                        }
                        quietly predict double `PStmp' if e(sample), `pspredict'
                    }
                    quietly replace `PS' = `PStmp' if `touse' & (`over'==`l')
                    drop `PStmp'
                }
            }
            else {
                su `treat' if `touse', meanonly
                if r(min)==r(max) {
                    di as txt "(treatment does not vary;" ///
                        " propensity score set to missing)"
                    qui gen double `PS' = .
                }
                else {
                    qui `noisily' di as txt _n "Propensity score estimation"
                    capture `noisily' `pscmd' `treat' `psvars' `wexp' ///
                        if `touse', `psopts'
                    if _rc {
                        di as err "propensity score estimation failed"
                        exit 198
                    }
                    quietly predict double `PS' if e(sample), `pspredict'
                }
            }
            qui count if `PS'>=. & `touse'
            if (r(N)) {
                quietly `noisily' di ""
                di as txt "(propensity score has " as res r(N) ///
                    as txt " missing values)"
            }
        }
        else {
            local pscmd
            local psprecict
            local psopts
            qui gen double `PS' = `pscore' if `touse'
        }
        // common support
        if `"`comsup'"'!="" {
            tempname PS2
            local comsup_lb: word 1 of `comsup'
            qui count if `touse' & `PS'<`comsup_lb'
            local comsup_lb_n = r(N)
            quietly gen double `PS2' = `PS' if `touse' & `PS'>=`comsup_lb'
            local comsup_ub: word 2 of `comsup'
            if `"`comsup_ub'"'=="" local comsup_ub "."
            local comsup_ub_n = 0
            if `comsup_ub'<. {
                qui count if `touse' & `PS'>`comsup_ub' & `PS'<.
                local comsup_ub_n = r(N)
                quietly replace `PS2' = . if `touse' & `PS2'>`comsup_ub' & `PS2'<.
            }
            di as txt "(comsup: {res:`comsup_lb_n'} obs with PS < `comsup_lb'" _c
            if `comsup_ub'<. di ", {res:`comsup_ub_n'} obs with PS > `comsup_ub'" _c
            di ")"
        }
        else local PS2 `PS'
    }
    
    // md: determine scaling matrix
    if "`subcmd'"=="md" {
        // - expand factor variables
        fvexpand `xvars' if `touse'
        local xxvars
        foreach v in `r(varlist)' {
            if strpos(`"`v'"', "b.") continue // remove base levels
            if strpos(`"`v'"', "o.") continue // remove omitted
            local xxvars `xxvars' `v'
        }
        // - generate temvars for expanded factor variables
        local txvars
        foreach v of local xxvars {
            capt confirm variable `v', exact
            if _rc {
                tempvar V
                qui gen double `V' = `v' if `touse'
                qui compress `V'
                local txvars `txvars' `V'
                continue
            }
            local txvars `txvars' `v'
        }
        // - add propensity score
        if "`pscore'"!=""  local xxvars `xxvars' `pscore'
        else if "`PS'"!="" local xxvars `xxvars' _PS_
        local txvars `txvars' `PS2'
        local PS2
        // - compute scaling matrix
        tempname S
        Parse_metric `S' `"`metric'"' `"`xxvars'"' "`ps'" "`psweight'" `"`overlevels'"'
    }
    
    // kernel and bandwidth
    tempname BW
    if "`ate'"!="" | ("`att'"!="" & "`atc'"!="") {
        mat `BW' = J(`nover', 2, .)
        mat coln `BW' = "att" "atc"
    }
    else if "`att'"!="" {
        mat `BW' = J(`nover', 1, .)
        mat coln `BW' = "att"
        local sharedbwidth
    } 
    else if "`atc'"!="" {
        mat `BW' = J(`nover', 1, .)
        mat coln `BW' = "atc"
        local sharedbwidth
    } 
    if "`over'"!="" {
         mat rown `BW' = `overlevels'
    }
    else {
        mat rown `BW' = "bwidth"
    }
    if `"`bwidth'"'!="" {
        local bwidth0 `bwidth'
        forv i=1/`nover' {
            forv j=1/`=colsof(`BW')' {
                gettoken bwidthi bwidth0: bwidth0
                mat `BW'[`i',`j'] = `bwidthi'
                if `"`bwidth0'"'=="" {
                    local bwidth0 `bwidth'
                }
                if "`sharedbwidth'"!="" {
                    mat `BW'[`i',colsof(`BW')] = `BW'[`i',1]
                    continue, break
                }
            }
        }
    }
    else if `nn2'==0 {
        tempname cv_att cv_atc
    }
    Parse_kernel, `kernel' // returns kernel
    if `nn2'==0 {
        if "`ridge2'"!="" local ridge `ridge2'
        else if "`ridge'"!="" {
            if "`kernel'"=="epan"           local ridge = 5/16
            //else if "`kernel'"=="gaussian"  local ridge = 2^-1.5
            else if "`kernel'"=="rectangle" local ridge = 1/4
            else if "`kernel'"=="triangle"  local ridge = 3/8
            else if "`kernel'"=="biweight"  local ridge = 21/64
            else if "`kernel'"=="triweight" local ridge = 429/1280
            else if "`kernel'"=="cosine"    local ridge = 1/3
            else if "`kernel'"=="parzen"    local ridge = 105/302
            else error 499
        }
    }
    
    // prepare DY tempvars
    local dyvars
    if "`dy'"!="" {
        forv i=1/`novars' {
            tempvar dy_`i'
            qui gen double `dy_`i'' = .
            local dyvars `dyvars' `dy_`i''
        }
    }
    
    // run Kmatch()
    local sortvars `touse' `over' `ematch' `treat' `txvars' `PS2'
    if "`weight'"!="" {
        local sortvars `sortvars' `wvar'
    }
    sort `sortvars' `cv_outcome' `_sortindex'
    tempvar byindex
    by `touse' `over' `ematch': gen byte `byindex' = _n==1
    qui by `touse' `over': replace `byindex' = sum(`byindex')
    mata: Kmatch("`subcmd'", &Kmatch_`kernel'())
    qui compress `nc' `nm'
    
    // number of observations, common support
    tempname _N
    if "`over'"=="" {
        Count_obs "`ate'" "`att'" "`atc'" `treat' `nc' `nm' `touse' ///
            "`weight'" "`wvar'"
        mat `_N' = r(_N)
        local N = r(N)
    }
    else {
        local N 0
        foreach l of local overlevels {
            Count_obs "`ate'" "`att'" "`atc'" `treat' `nc' `nm' `touse' ///
                "`weight'" "`wvar'" `over' `l'
            mat `_N' = nullmat(`_N') \ r(_N)
            local N = `N' + r(N)
        }
    }
    if `nn2' {
        su `nc' if `touse' & `nc'>0, meanonly
        local nn_min = r(min)
        local nn_max = r(max)
    }
    
    // treatment effects
    if `novars' {
        tempname b b0
    }
    forv i=1/`nover' {
        local l: word `i' of `overlevels'
        forv j=1/`novars' {
            Estimate_teffect "`ate'" "`att'" "`atc'" "`nate'" "`po'" ///
                `touse' `treat' `control' `nc' `nm' `mw' `novars' `ovar_`j'' ///
                "`dy_`j''" "`xvars_`j''" `"`swexp'"' "`weight'" "`wvar'" ///
                "`over'" "`l'" "`noisily'"
            mat `b' = nullmat(`b'), r(b)
        }
    }
    local k_omit 0
    if `novars' {
        mata: st_local("k_omit", strofreal(FlagOmitted("`b'")))
    }
    
    // potential outcome differences
    if "`dy'"!="" & ("`ate'"!="" | "`atc'"!="") {
        forv j=1/`novars' {
            qui replace `dy_`j'' = `dy_`j'' - `ovar_`j'' if `touse' & `control'
        }
    }
    if "`dy'"!="" & ("`ate'"!="" | "`att'"!="") {
        forv j=1/`novars' {
            qui replace `dy_`j'' = `ovar_`j'' - `dy_`j''  if `touse' & `treat'
        }
    }

    // post results
    if `novars' {
        eret post `b', obs(`N') esample(`touse')
    }
    else {
        eret post, obs(`N') esample(`touse')
    }
    eret local cmd              "kmatch"
    eret local subcmd           "`subcmd'"
    if "`subcmd'"=="ps"         local title "Propensity-score"
    else                        local title "Multivariate-distance"
    if `nn2'                    local title "`title' nearest-neighbor"
    else if `"`ridge'"'==""     local title "`title' kernel"
    else                        local title "`title' ridge"
    eret local title            "`title' matching"
    eret local tvar             "`tvar'"
    eret scalar tval            = `tvalue'
    eret local xvars            "`xvars'"
    eret local ematch           "`ematch'"
    if `nn2' {
        eret scalar nn          = `nn2'
        eret scalar nn_min      = `nn_min'
        eret scalar nn_max      = `nn_max'
    }
    else {
        eret local kernel       "`kernel'"
        if "`ridge'"!="" {
            eret scalar ridge   = `ridge'
        }
    }
    eret matrix bwidth          = `BW'
    if `"`bwidth'"'=="" & `nn2'==0 {
        eret local bw_method    "`bw_method'"
        if "`bw_method'"=="pm" {
            eret scalar pm_quantile = `pm_quantile'
            eret scalar pm_factor   = `pm_factor'
        }
        else {
            eret local cv_nolimit "`cv_nolimit'"
            if "`cv_grid'`cv_range'"=="" {
                eret scalar pm_quantile = `pm_quantile'
                eret scalar pm_factor   = `pm_factor'
                eret scalar cv_factor   = `cv_factor'
            }
            if "`cv_outcome'"!="" {
                eret local cv_weighted  "`cv_weighted'"
                eret local cv_nopenalty "`cv_nopenalty'"
                eret local cv_outcome   "`cv_outcome'"
            }
            else if "`ridge'"!="" {
                eret local cv_exact     "`cv_exact'"
            }
            if "`sharedbwidth'"!="" {
                eret matrix cv = `cv_att'
            }
            else if ("`ate'"!="" | ("`att'"!="" & "`atc'"!="")) {
                mat roweq `cv_att' = "treated"
                mat roweq `cv_atc' = "untreated"
                mat `cv_att' = `cv_att' \ `cv_atc'
                eret matrix cv = `cv_att'
            }
            else if `"`att'"'!="" {
                eret matrix cv = `cv_att'
            }
            else if `"`atc'"'!="" {
                eret matrix cv = `cv_atc'
            }
        }
    }
    if "`ps'"!="" {
        eret local pscore       "`pscore'"
        eret local pscmd        "`pscmd'"
        eret local pspredict    "`pspredict'"
        eret local psopts       `"`psopts'"'
        if `"`comsup'"'!="" {
            eret scalar comsup_lb   = `comsup_lb'
            eret scalar comsup_ub   = `comsup_ub'
            eret scalar comsup_lb_n = `comsup_lb_n'
            eret scalar comsup_ub_n = `comsup_ub_n'
        }
    }
    if "`subcmd'"=="md" {
        eret local metric       `"`metric'"'
        if "`metric'"!="euclidean" & `"`xvars'"'!="" {
            eret matrix S       = `S'
        }
        eret local mdmethod     "`mdmethod'"
        eret local metric_units   `metric_units'
        eret local metric_weights `metric_weights'
        eret local psvars       "`psvars'"
    }
    eret local ate              "`ate'"
    eret local att              "`att'"
    eret local atc              "`atc'"
    eret scalar N_over          = `nover'
    if "`over'"!="" {
        eret local over          "`over'"
        eret local over_labels   `"`overlevels'"'
        eret local over_namelist `"`overlevels'"'
    }
    eret scalar N_ovars         = `novars'
    if `novars'==1 {
        eret local depvar       "`ovars'"
    }
    forv i=1/`novars' {
        local ii `i'
        if `novars'==1 local ii
        eret local ovar`ii'     "`ovar_`i''"
        eret local avars`ii'    "`xvars_`i''"
    }
    eret local wtype            "`weight'"
    eret local wexp             `"`exp'"'
    eret scalar k_omit          = `k_omit'
    eret matrix _N              = `_N'
    
    // return variables
    if "`generate'"!="" {
        local genvars
        local i 0
        foreach v in treat nc nm mw `ps' {
            local ++i
            local vname: word `i' of `generate2'
            if `"`vname'"'=="" local vname `generate'`v'
            capt confirm new variable `vname'
            if _rc drop `vname'
            if "`v'"=="ps" local v PS
            rename ``v'' `vname'
            local lbl: word `i' of ///
                "Treatment indicator" ///
                "Number of matched controls" ///
                "Number of times used as a match" ///
                "Matching weight" ///
                "Propensity score"
            lab var `vname' "`lbl'"
            local genvars `genvars' `vname'
        }
        eret local generate `genvars'
    }
    if "`dy'"!="" {
        local genvars
        local i 0
        foreach v of local ovars {
            local ++i
            local vname: word `i' of `dy2'
            if `"`vname'"'=="" local vname `dy'`v'
            capt confirm new variable `vname'
            if _rc drop `vname'
            rename `dy_`i'' `vname'
            lab var `vname' "Matched difference in `v'"
            local genvars `genvars' `vname'
        }
        eret local dy `genvars'
    }
    Return_clear 
end
program Return_clear, rclass
    local x
end
program OptNotAllowed
    syntax [, someoption ]
    if `"`someoption'"'!="" {
        di as err `"{bf:`someoption'} not allowed"'
        exit 198
    }
end

program Parse_eq
    // main equation: treatment variables and covariates
    gettoken tvar rest : 0, parse("(")
    gettoken 0 xvars : tvar
    capt n syntax varname(numeric)
    if _rc {
        di as err "invalid treatment variable specification"
        exit _rc
    }
    c_local tvar `varlist'
    local 0 `"`xvars'"'
    capt n syntax [varlist(numeric fv default=none)]
    if _rc {
        di as err "invalid control variables specification"
        exit _rc
    }
    c_local xvars `varlist'
    // outcome equations
    local i 0
    local ovars
    while (`"`rest'"'!="") {
        gettoken eq rest : rest, match(par)
        if `"`par'"'!="(" {
            di as err "invalid outcome equation specification"
            exit 198
        }
        _parse comma eq opts: eq
        gettoken 0 eq : eq, parse("=")
        gettoken eqsign xvars : eq, parse("=")
        if `"`eqsign'"'!="" {
            if `"`eqsign'"'!="=" {
                di as err "invalid outcome equation specification"
                exit 198
            }
        }
        capt n syntax varlist(numeric)
        if _rc {
            di as err "invalid outcome variable specification"
            exit _rc
        }
        local ovarsi `varlist'
        local 0 `"`xvars'"'
        capt n syntax [varlist(numeric fv default=none)]
        if _rc {
            di as err "invalid adjustment variables specification"
            exit _rc
        }
        local xvars `varlist'
        foreach v of local ovarsi {
            local ++i
            local ovars `ovars' `v'
            c_local ovar_`i' `v'
            c_local xvars_`i' `xvars'
            c_local opts_`i' `opts'
        }
    }
    local dups: list dups ovars
    if `"`dups'"'!="" {
        gettoken dups : dups
        di as err `"`dups' not allowed"'
        di as err `"outcome variables must be unique"'
        exit 198
    }
    c_local novars `i'
    c_local ovars `ovars'
end

program Parse_bw_pm
    gettoken subcmd 0 : 0
    syntax [anything] [, QUIetly ]
    capt n numlist `"`anything'"', min(0) max(2) range(>0)
    if _rc {
        di as err "invalid bwidth()"
        exit _rc
    }
    local quantile: word 1 of `r(numlist)'
    local factor: word 2 of `r(numlist)'
    if "`quantile'"=="" local quantile .90
    if `quantile'>1 {
        di as err "invalid bwidth(): quantile outside of allowed range"
        exit 125
    }
    if "`factor'"=="" {
        if "`subcmd'"=="md" local factor 1.5
        else                local factor 1.5
    }
    c_local pm_quantile `quantile'
    c_local pm_factor   `factor'
    c_local bw_quietly  `quietly'
end

program Parse_bw_cv
    gettoken subcmd 0 : 0
    syntax [varname(numeric default=none)] [, ///
        Quantile(numlist >0 <=1 max=1) Factor(numlist >0 max=1) ///
        n(numlist int >0 max=1) SFactor(numlist >0 max=1) ///
        Range(numlist >0 min=2 max=2 ascending) ///
        Grid(numlist >0) Weighted NOPenalty NOLimit exact QUIetly ]
    if "`n'"=="" local n 15
    if "`quantile'"=="" local quantile .90
    if "`factor'"=="" {
        if "`subcmd'"=="md" local factor 1.5
        else                local factor 1.5
    }
    if "`sfactor'"==""  local sfactor 1.5
    c_local cv_outcome   `varlist'
    c_local pm_quantile  `quantile'
    c_local pm_factor    `factor'
    c_local cv_n         `n'
    c_local cv_factor    `sfactor'
    c_local cv_range     `range'
    c_local cv_grid      `grid'
    c_local cv_weighted  `weighted'
    c_local cv_nopenalty `nopenalty'
    c_local cv_nolimit   `nolimit'
    c_local cv_exact     `exact'
    c_local bw_quietly   `quietly'
end

program Parse_metric
    // settings
    args S metric xvars ps psweight overlevels
    local nxvars: list sizeof xvars
    local nover: list sizeof overlevels
    
    // parse metric
    if `"`metric'"'=="" local metric mahalanobis
    gettoken metric mspec: metric, parse(", ")
    mata: st_local("mspec", strtrim(st_local("mspec")))
    local tmp = strlen(`"`metric'"')
    if `"`metric'"'==substr("mahalanobis",1,max(4,`tmp')) {
        local metric mahalanobis
    }
    else if `"`metric'"'==substr("ivariance",1,max(4,`tmp')) {
        local metric ivariance
    }
    else if `"`metric'"'==substr("euclidean",1,max(4,`tmp')) {
        local metric euclidean
    }
    else if `"`metric'"'== substr("matrix",1,max(3,strlen(`"`metric'"'))) {
        local metric matrix
    }
    else {
        di as err `"metric(): `metric' not allowed"'
        exit 198
    }
    c_local metric `metric'
    
    // no xvars
    if `"`xvars'"'=="" exit
    
    // euclidean
    if "`metric'"=="euclidean" {
        if `"`mspec'"'!="" {
            di as err `"metric(`metric'): `mspec' not allowed"'
            exit 198
        }
        exit
    }
    
    // matrix
    if "`metric'"=="matrix" {
        gettoken mspec tmp: mspec
        if `"`tmp'"'!="" {
            di as err `"metric(`metric'): `tmp' not allowed"'
            exit 198
        }
        confirm matrix `mspec'
        if colsof(`mspec')!=`nxvars' {
            di as err `"metric(`metric'): `mspec' has wrong dimension"'
            exit 498
        }
        if `nover' {
            if !inlist(rowsof(`mspec'), `nxvars', `nxvars'*`nover') {
                di as err `"metric(`metric'): `mspec' has wrong dimension"'
                exit 498
            }
            tempname S0
            forv j = 1/`nover' {
                if rowsof(`mspec')>=(`nxvars'*`j') {
                    mat `S0' = `mspec'[`nxvars'*(`j'-1)+1..`nxvars'*`j', 1...]
                    mat coleq `S0' = ""
                    mat coln  `S0' = `xvars'
                    mat rown  `S0' = `xvars'
                }
                local l: word `j' of `overlevels'
                mat roweq `S0' = `l'
                mat `S' = nullmat(`S') \ `S0'
            }
            exit
        }
        if rowsof(`mspec')!=`nxvars' {
            di as err `"metric(`metric'): `mspec' has wrong dimension"'
            exit 498
        }
        mat `S' = `mspec'
        mat coleq `S' = ""
        mat coln  `S' = `xvars'
        mat roweq `S' = ""
        mat rown  `S' = `xvars'
        exit
    }
    
    // mahalanobis / ivariance: set up empty matrix
    if `nover' {
        tempname S0
        mat `S0' = J(`nxvars',`nxvars',.)
        mat coln `S0' = `xvars'
        mat rown `S0' = `xvars'
        forv j = 1/`nover' {
            local l: word `j' of `overlevels'
            mat roweq `S0' = `l'
            mat `S' = nullmat(`S') \ `S0'
        }
    }
    else {
        mat `S' = J(`nxvars',`nxvars',.)
        mat coln  `S' = `xvars'
        mat rown  `S' = `xvars'
    }
    
    // mahalanobis / ivariance: collect units and weights
    Parse_metric_mspec `mspec'
    if `"`units'"'!="" {
        if `:list sizeof units'!=`nxvars' {
            di as err `"metric(`metric'): numlist has wrong number of elements"'
            exit 198
        }
    }
    if `"`weights'"'!="" {
        if "`ps'"!="" {
            if "`psweight'"=="" local weights `weights' 1
            else                local weights `weights' `psweight'
        }
        if `:list sizeof weights'!=`nxvars' {
            di as err `"metric(`metric'): weights() has wrong number of elements"'
            exit 198
        }
    }
    else if "`ps'"!="" & "`psweight'"!="" {
        forv i = 1/`=`nxvars'-1' {
            local weights `weights' 1
        }
        local weights `weights' `psweight'
    }
    c_local metric_units `units'
    c_local metric_weights `weights'
end

program Parse_metric_mspec
    syntax [anything] [, Weights(numlist >0) ]
    numlist `"`anything'"', min(0) range(>0)
    c_local units `r(numlist)'
    c_local weights `weights'
end

program Parse_kernel
    syntax [, Epan Rectangle Uniform Triangle Biweight TRIWeight Cosine Parzen ]
    local kernel `epan' `rectangle' `uniform' `triangle' `biweight' ///
        `triweight' `cosine' `parzen'
    if `: list sizeof kernel'>1 {
        di as err "kernel(): only one kernel allowed"
        exit 198
    }
    if "`kernel'"=="uniform"      local kernel rectangle
    if "`kernel'"==""             local kernel epan
    c_local kernel `kernel'
end

program Count_obs, rclass
    args ate att atc treat nc nm touse weight wvar over l
    local fw = "`weight'"=="fweight"
    if `"`ate'"'!="" local r 3
    else if `"`att'"'!="" & `"`atc'"'!="" local r 2
    else local r 1
    tempname N
    mat `N' = J(`r',6,0)
    if (`r'==3)             mat rown `N' = Treated Untreated Combined
    else if (`r'==2)        mat rown `N' = Treated Untreated
    else if `"`att'"'!=""   mat rown `N' = Treated
    else                    mat rown `N' = Untreated
    mat coln `N' = Matched:Yes Matched:No Matched:Total ///
                   Controls:Used Controls:Unused Controls:Total
    if `"`over'"'!="" {
        mat roweq `N' = `l'
        local overif "`over'==`l' & "
    }
    if (`r'>=2)             local G 1 0
    else if `"`att'"'!=""   local G 1
    else                    local G 0
    local j = 0
    foreach g of local G {
        local ++j
        Count_obs_i `touse' "`overif'`treat'==`g' & `nc'" `fw' `wvar'
        mat `N'[`j', 1] = r(N)
        Count_obs_i `touse' "`overif'`treat'==`g' & `nc'==0" `fw' `wvar'
        mat `N'[`j', 2] = r(N)
        mat `N'[`j', 3] = `N'[`j', 1] + `N'[`j', 2]
        Count_obs_i `touse' "`overif'`treat'==(1-`g') & `nm'" `fw' `wvar'
        mat `N'[`j', 4] = r(N)
        Count_obs_i `touse' "`overif'`treat'==(1-`g') & `nm'==0" `fw' `wvar'
        mat `N'[`j', 5] = r(N)
        mat `N'[`j', 6] = `N'[`j', 4] + `N'[`j', 5]
    }
    if (`r'==3) {
        forv i = 1/6 {
            mat `N'[3, `i'] = `N'[1, `i'] + `N'[2, `i']
        }
    }
    return scalar N  = `N'[1, 3] + `N'[1, 6]
    return matrix _N = `N'
end
program Count_obs_i
    args touse iff fw wvar 
    if `fw' {
        su `touse' [fw = `wvar'] if `touse' & `iff', meanonly
    }
    else {
        qui count if `touse' & `iff'
    }
end

program Estimate_teffect, rclass
    args ate att atc nate po touse treat control nc nm mw novars ovar ///
        dyvar xvars swexp wtype wvar over l noi
    if "`over'"!="" local touse "`touse' & (`over'==`l')"
    local po = "`po'"!=""
    if `"`xvars'"'=="" local noi // suppress display if no covariates
    if "`wtype'"=="fweight" {
        tempvar mwvar
        qui generate double `mwvar' = `mw' * `wvar' if `touse'
        local mw `mwvar' 
    }
    // prepare b0
    tempname b b0
    if `po'            mat `b0' = J(1, 3, .)
    else               mat `b0' = J(1, 1, .)
    if "`over'"!="" {
        if `novars'>1  mat coleq `b0' = `l'_`ovar'
        else           mat coleq `b0' = `l'
    }
    else if `novars'>1 mat coleq `b0' = `ovar'
    // regression adjustment
    tempname Y1 Y0 R
    if "`ate'"!="" | "`atc'"!="" {
        qui count if `touse' & `treat' & `nm'
        if r(N)==0 { // no controls
            qui generate double `Y1' = .
        }
        else {
            if "`over'"!="" qui `noi' di as txt _n "`over'==`l': " _c
            else            qui `noi' di as txt _n "" _c
            qui `noi' di "Y1 regression-adjustment equation" _c
            if `novars'>1 qui `noi' di " for `ovar'"
            else          qui `noi' di ""
            qui `noi' regress `ovar' `xvars' [iw=`mw'] ///
                if `touse' & `treat' & `nm', noheader
            // qui `noi' Regress `ovar' `xvars' [iw=`mw'] ///
            //     if `touse' & `treat' & `nm'
            qui predict double `Y1' if `touse' & `control' & `nc'
            if "`dyvar'"!="" & "`xvars'"!="" {  // update potential outcomes
                qui regress `dyvar' `xvars' `swexp' if `touse' & `control' & `nc'
                qui predict double `R' if `touse' & `control' & `nc', residuals
                qui replace `dyvar' = `Y1' + `R' if `touse' & `control' & `nc'
                drop `R'
            }
        }
        qui replace `Y1' = `ovar' if `touse' & `treat' & `nc' & `nc'<.
    }
    else {
        qui generate double `Y1' = `ovar' if `touse' & `treat' & `nc' & `nc'<.
    }
    if "`ate'"!="" | "`att'"!="" {
        qui count if `touse' & `control' & `nm'
        if r(N)==0 { // no controls
            qui generate double `Y0' = .
        }
        else {
            if "`over'"!="" qui `noi' di as txt _n "`over'==`l': " _c
            else            qui `noi' di as txt _n "" _c
            qui `noi' di as txt "Y0 regression-adjustment equation" _c
            if `novars'>1 qui `noi' di " for `ovar'"
            else          qui `noi' di ""
            qui `noi' regress `ovar' `xvars' [iw=`mw'] ///
                if `touse' & `control' & `nm', noheader
            // qui `noi' Regress `ovar' `xvars' [iw=`mw'] ///
            //     if `touse' & `control' & `nm'
            qui predict double `Y0' if `touse' & `treat' & `nc'
            if "`dyvar'"!="" & "`xvars'"!="" {  // update potential outcomes
                qui regress `dyvar' `xvars' `swexp' if `touse' & `treat' & `nc'
                qui predict double `R' if `touse' & `treat' & `nc', residuals
                qui replace `dyvar' = `Y0' + `R' if `touse' & `treat' & `nc'
                drop `R'
            }
        }
        qui replace `Y0' = `ovar' if `touse' & `control' & `nc' & `nc'<.
    }
    else {
        qui generate double `Y0' = `ovar' if `touse' & `control' & `nc' & `nc'<.
    }
    // ATE
    if "`ate'"!="" {
        su `Y1' `swexp', meanonly
        mat `b0'[1,1] = r(mean)
        if `po' mat `b0'[1,2] = r(mean)
        su `Y0' `swexp', meanonly
        mat `b0'[1,1] = `b0'[1,1] - r(mean)
        if `po' mat `b0'[1,3] = r(mean)
        local coln ATE
        if `po' {
            if "`att'`atc'`nate'"=="" local coln `coln' Y1 Y0
            else                      local coln `coln' Y1(ATE) Y0(ATE)
        }
        mat coln `b0' = `coln'
        mat `b' = nullmat(`b'), `b0'
    }
    // ATT
    if "`att'"!="" {
        su `Y1' `swexp' if `treat', meanonly
        mat `b0'[1,1] = r(mean)
        if `po' mat `b0'[1,2] = r(mean)
        su `Y0' `swexp' if `treat', meanonly
        mat `b0'[1,1] = `b0'[1,1] - r(mean)
        if `po' mat `b0'[1,3] = r(mean)
        local coln ATT
        if `po' {
            if "`ate'`atc'`nate'"=="" local coln `coln' Y1 Y0
            else                      local coln `coln' Y1(ATT) Y0(ATT)
        }
        mat coln `b0' = `coln'
        mat `b' = nullmat(`b'), `b0'
    }
    // ATC
    if "`atc'"!="" {
        su `Y1' `swexp' if `control', meanonly
        mat `b0'[1,1] = r(mean)
        if `po' mat `b0'[1,2] = r(mean)
        su `Y0' `swexp' if `control', meanonly
        mat `b0'[1,1] = `b0'[1,1] - r(mean)
        if `po' mat `b0'[1,3] = r(mean)
        local coln ATC
        if `po' {
            if "`ate'`att'`nate'"=="" local coln `coln' Y1 Y0
            else                      local coln `coln' Y1(ATC) Y0(ATC)
        }
        mat coln `b0' = `coln'
        mat `b' = nullmat(`b'), `b0'
    }
    // NATE
    if "`nate'"!="" {
        su `ovar' `swexp' if `touse' & `treat', meanonly
        mat `b0'[1,1] = r(mean)
        if `po' mat `b0'[1,2] = r(mean)
        su `ovar' `swexp' if `touse' & `control', meanonly
        mat `b0'[1,1] = `b0'[1,1] - r(mean)
        if `po' mat `b0'[1,3] = r(mean)
        local coln NATE
        if `po' {
            if "`ate'`att'`nate'"=="" local coln `coln' Y1 Y0
            else                      local coln `coln' Y1(NATE) Y0(NATE)
        }
        mat coln `b0' = `coln'
        mat `b' = nullmat(`b'), `b0'
    }
    // done
    return matrix b = `b'
end

/*
program Regress, eclass
    syntax varlist(fv) [if] [iw/]
    marksample touse
    gettoken depvar xvars : varlist
    fvexpand `xvars'
    local xvars `"`r(varlist)'"'
    tempname b
                        local DEPV `"st_data(., "`depvar'", "`touse'")"'
    if `"`weight'"'=="" local WGT  1
    else                local WGT  `"st_data(., "`exp'", "`touse'")"'
    if `"`xvars'"'==""  local XVARS "J(0,0,.)"
    else                local XVARS `"st_data(., tokens(st_local("xvars")), "`touse'")"'
    mata: st_matrix(st_local("b"), Kmatch_regress(`DEPV', `WGT', `XVARS')')
    mat coln `b' = `xvars' _cons
    eret post `b', esample(`touse') depname("`depvar'")
    eret di
end
*/

version 11
mata:
mata set matastrict on

real scalar FlagOmitted(string scalar bname)
{
    real scalar k
    real matrix b
    string matrix cstripe
    
    b = st_matrix(bname)
    k = missing(b)
    if (k==0) return(k)
    cstripe = st_matrixcolstripe(bname)
    cstripe[,2] = (b':>=.):*"o." + cstripe[,2]
    st_matrixcolstripe(bname, cstripe)
    st_replacematrix(bname, editmissing(b,0))
    return(k)
}

struct KmatchSet {
    // matching functions
    pointer scalar match    // matching function
    pointer scalar mindist  // minimum distance function
    pointer scalar cvomatch // outcome cross-validation function
    // target statistics
    real scalar    att      // match treated
    real scalar    atc      // match controls
    // sample
    real scalar    touse    // index of sample indicator
    real scalar    treat    // index of treatment group indicator
    real scalar    control  // index of control group indicator
    // weights
    real scalar    w        // whether has weights (2 = fweights)
    real scalar    wvar     // index of weights variable
    // over
    string scalar  oname    // name of over variable
    real scalar    over     // index of over variable
    real matrix    O        // indices of over groups
    // exact matching
    real scalar    ematch   // index of ematch variable 
    // kernel
    pointer scalar K        // kernel function
    real scalar    r        // ridge parameter
    real scalar    nn       // nearest-neighbor matching
    // bandwidth
    real matrix    h        // bandwidths
    real scalar    sharedbw // use same bw for both matching directions
    real scalar    bw       // whether to use bandwidth search algorithm
    real scalar    bwnoi    // whether to display progress dots
    real scalar    pmq      // pair-matching reference quantile
    real scalar    pmf      // pair-matching scaling factor
    real scalar    cv       // whether to use cross-validation
    real scalar    cvs      // change S.match() to cross-validation mode
    real scalar    cvsexact // use exact algorithm for ridge matching
    real scalar    cvn      // number of CV evaluation points
    real scalar    cvf      // CV step size
    real rowvector grid     // CV search grid
    real scalar    weighted // whether to apply weighting
    real scalar    penalty  // whether to apply penalty for loss of observations
    real scalar    limit    // whether to apply penalty for large bandwidths
    real scalar    Zvar     // index of cross-validation target variable
    real scalar    sdPS     // SD of propensity-score
    real matrix    tgrid    // CV grid (ATT)
    real matrix    tmise    // CV MISE (ATT)
    real matrix    cgrid    // CV grid (ATC)
    real matrix    cmise    // CV MISE (ATC)
    // PS matching
    real scalar    ps       // index of PS variable
    // MD matching
    real scalar    md       // MD matching
    string scalar  metric   // metric
    real scalar    mdmethod // method to compute MD (0=full, 1=ortho, 2=part)
    real rowvector xvars    // indices of covariates
    string colvector xnames // names of covariates
    real matrix    V        // scaling matrix
    real matrix    Vinv     // inverted scaling matrix (current over-group only)
    real rowvector mweights // weights for scaling matrix
    real rowvector munits   // units for scaling matrix
    // outcomes
    real scalar    Y        // whether has Y variables
    real rowvector yvars    // indices of Y variables
    real rowvector dyvars   // indices of dY output variables
    // output variables
    real scalar    nc       // number of matches
    real scalar    mw       // matching weights
    real scalar    nm       // number of times used as a match
}

struct KmatchG {
    // input
    real colvector p        // data index
    real colvector pe       // data expansion permutation vector
    real scalar    n        // number of observations (rows)
    real scalar    h        // bandwidth
    real scalar    h2       // search window (MD only)
    real colvector S        // propensity score (PS) or sum score (MD)
    real matrix    X        // covariates (MD only)
    real matrix    XWX      // transformed covariates (mdmethod=2)
    real colvector E        // ematch variable
    real colvector w        // weights (from data)
    real colvector fw       // frequency weights / number of ties
    real matrix    Y        // outcome variables
    // output
    real matrix    Yc       // potential outcomes
    real colvector nc       // number of matches (with weight > 0)
    real colvector mw       // matching weights
    real colvector nm       // number of times used as a match
    // bandwidth search
    real colvector Z        // outcome variable for cross-validation
    real rowvector grid     // search grid 
    real rowvector mise     // cross-validation MISE
    pointer scalar Xs       // normalized X for cross-validation
    real matrix    C1       // container for auxiliary results
    real colvector C2       // container for auxiliary results
}

void Kmatch(string scalar cmd, pointer scalar K)
{
    real scalar             i
    real rowvector          xvars
    real matrix             L, cvatt, cvatc
    string matrix           cstripe
    struct KmatchSet scalar S
    pragma unset            L
    
    // settings
    // - target statistics
    S.att = (st_local("ate")!="") | (st_local("att")!="")
    S.atc = (st_local("ate")!="") | (st_local("atc")!="")
    // - sample
    S.touse   = st_varindex(st_local("touse"))
    S.treat   = st_varindex(st_local("treat"))
    S.control = st_varindex(st_local("control"))
    // - weights
    S.w = st_local("weight")!=""
    if (S.w) S.w = S.w + (st_local("weight")=="fweight")
    if (S.w) S.wvar = st_varindex(st_local("wvar"))
    // - over
    S.oname = st_local("over")
    if (S.oname!="") S.over = st_varindex(st_local("over"))
    // - exact matching
    if (st_local("ematch")!="") S.ematch = st_varindex(st_local("byindex"))
    // - kernel
    S.K = K
    S.r = strtoreal(st_local("ridge"))
    S.nn = strtoreal(st_local("nn2"))
    // - bandwidth
    S.h = st_matrix(st_local("BW"))
    S.sharedbw = st_local("sharedbwidth")!="" & S.att & S.atc
    S.bw = st_local("bw_method")!=""
    S.cv = 0
    S.cvs = 0
    if (S.bw) {
        S.bwnoi = st_local("bw_quietly")==""
        S.pmq = strtoreal(st_local("pm_quantile"))
        S.pmf = strtoreal(st_local("pm_factor"))
        S.cv = st_local("bw_method")=="cv"
        if (S.cv) {
            if (st_local("cv_grid")!="") {
                S.grid = strtoreal(tokens(st_local("cv_grid")))
                S.cvn = cols(S.grid)
            }
            else {
                S.cvn = strtoreal(st_local("cv_n"))
                if (st_local("cv_range")!="") {
                    S.grid = strtoreal(tokens(st_local("cv_range")))
                    S.grid = rangen(S.grid[1], S.grid[2], S.cvn)'
                }
                else S.cvf = strtoreal(st_local("cv_factor"))
            }
            S.weighted = st_local("cv_weighted")!=""
            S.penalty  = st_local("cv_nopenalty")==""
            S.limit    = st_local("cv_nolimit")==""
            if (st_local("cv_outcome")!="") {
                S.Zvar = st_varindex(st_local("cv_outcome"))
            }
            S.cvsexact = st_local("cv_exact")!="" & S.r<.
        }
    }
    // - PS matching
    if (cmd=="ps") {
        S.md = 0
        if (S.nn) S.match = &Kmatch_i_PS_nn()
        else {
            S.match = &Kmatch_i_PS()
            S.mindist = &Kmatch_mindist_i_PS()
            S.cvomatch = &Kmatch_cvo_i_PS()
        }
        S.ps = st_varindex(st_local("PS2"))
    }
    // - MD matching
    else {
        S.md = 1
        if (S.nn) S.match = &Kmatch_i_MD_nn()
        else {
            S.match = &Kmatch_i_MD()
            S.mindist = &Kmatch_mindist_i_MD()
            S.cvomatch = &Kmatch_cvo_i_MD()
        }
        S.metric = st_local("metric")
        S.mdmethod = strtoreal(st_local("mdmethod"))
        if (S.mdmethod>=.) S.mdmethod = 0
        if (S.metric=="euclidean") S.mdmethod = 1                   // !!!
        S.xvars = xvars = st_varindex(tokens(st_local("txvars")))
        if (S.metric!="euclidean") {
            S.xnames = tokens(st_local("xxvars"))'
            S.V = st_matrix(st_local("S"))
        }
        if (S.metric!="euclidean" & (S.metric!="matrix")) {
            S.mweights = strtoreal(tokens(st_local("metric_weights")))
            S.munits = strtoreal(tokens(st_local("metric_units")))
        }
    }
    // - outcomes
    S.Y = (st_local("ovars")!="") & (st_local("dy")!="")
    if (S.Y) {
        S.yvars = st_varindex(tokens(st_local("ovars")))
        S.dyvars = st_varindex(tokens(st_local("dyvars")))
    }
    // - output variables
    S.nc = st_varindex(st_local("nc"))
    S.mw = st_varindex(st_local("mw"))
    S.nm = st_varindex(st_local("nm"))
    
    // get indices of over groups
    Kmatch_o_index(S)
    
    // prepare containers for cross-validation bandwidth search
    if (S.cv) {
        if (S.att) S.tgrid = S.tmise = J(rows(S.O), S.cvn, .)
        if (S.atc & S.sharedbw==0) S.cgrid = S.cmise = J(rows(S.O), S.cvn, .)
    }
    
    // apply matching to each over group
    for (i=1;i<=rows(S.O);i++) {
        if (S.md & S.metric!="euclidean") xvars = Kmatch_get_L(L, S, i)
        Kmatch_o(S, i, xvars, L)
    }
    
    // update Scaling matrix info
    if (S.md & S.metric!="euclidean") {
        st_replacematrix(st_local("S"), S.V)
    }
    
    // update bandwidth info
    if (S.bw) st_replacematrix(st_local("BW"), S.h)
    if (S.cv) {
        if (S.att) cvatt = J(rows(S.O)*2, S.cvn, .)
        if (S.atc & S.sharedbw==0) cvatc = J(rows(S.O)*2, S.cvn, .)
        cstripe = J(rows(S.O), 1, ("", "h")\("","MISE"))
        for (i=1;i<=rows(S.O);i++) {
            if (S.over<.) cstripe[|i*2-1,1 \ i*2,1|] = J(2,1,strofreal(S.O[i,1]))
            if (S.att) cvatt[|i*2-1,1 \ i*2,.|] = S.tgrid[i,] \ S.tmise[i,]
            if (S.atc & S.sharedbw==0) cvatc[|i*2-1,1 \ i*2,.|] = S.cgrid[i,] \ S.cmise[i,]
        }
        if (S.att) {
            st_matrix(st_local("cv_att"), cvatt')
            st_matrixcolstripe(st_local("cv_att"), cstripe)
        }
        if (S.atc & S.sharedbw==0) {
            st_matrix(st_local("cv_atc"), cvatc')
            st_matrixcolstripe(st_local("cv_atc"), cstripe)
        }
    }
}

void Kmatch_o_index(struct KmatchSet scalar S)
{
    real scalar i, i0, o0
    real matrix O
    
    O = (1::st_nobs())
    if (S.over<.) {
        O = st_data(., S.over), O
        O = select(O, st_data(., S.touse):==1)
        O = O[,1], J(rows(O), 1, .), O[,2]
        i0 = 1; o0 = O[1,1]
        for (i=2;i<=rows(O);i++) {
            if (O[i,1]==o0) continue
            O[i-1,2] = O[i0,3]
            i0 = i; o0 = O[i,1]
        }
        O[rows(O),2] = O[i0,3]
        S.O = select(O, O[,2]:<.)
    }
    else {
        O = select(O, st_data(., S.touse):==1)
        S.O = (., O[1], O[rows(O)])
    }
}

real rowvector Kmatch_get_L(real matrix L, struct KmatchSet scalar S, 
    real scalar o)
{
    real scalar      n, i
    real colvector   p, F
    real matrix      Vinv
    string colvector omit
    
    n = cols(S.xvars)
    if (n<1) return(S.xvars)
    if (S.metric=="mahalanobis" | S.metric=="ivariance") {
        if (S.metric=="mahalanobis") {
            Vinv = Kmatch_get_V(S, S.O[o,(2,3)])
        }
        else if (S.metric=="ivariance") {
            if (cols(S.munits)==0) Vinv = Kmatch_get_Vdiag(S, S.O[o,(2,3)])
            else                   Vinv = I(n)
        }
        if (cols(S.munits)>0) {
            F = S.munits' :/ sqrt(diagonal(Vinv))
            Vinv = Vinv :* F :* F'
        }
        if (cols(S.mweights)>0) {
            F = 1 :/ S.mweights'
            Vinv = Vinv :* F :* F'
        }
        if (S.over>=.) S.V = Vinv
        else           S.V[|n*(o-1)+1,1 \ n*o,.|] = Vinv
    }
    else {
        if (S.over>=.) Vinv = S.V
        else           Vinv = S.V[|n*(o-1)+1,1 \ n*o,.|]
    }
    Vinv = invsym(Vinv)
    p = select(1::n, diagonal(Vinv):!=0)
    if (length(p)==n) {
        swap(S.Vinv, Vinv)
        L = cholesky(S.Vinv)
        return(S.xvars)
    }
    omit = select(S.xnames, diagonal(Vinv):==0)
    for (i=1;i<=rows(omit); i++) {
        if (S.over<.) 
            printf("{txt}(%s=%g: %s dropped because of collinearity)\n", 
            S.oname, S.O[o,1], omit[i])
        else printf("{txt}(%s dropped because of collinearity)\n", omit[i])
    }
    if (length(p)==0) {
        L = J(0,0,.)
        return(J(1,0,.))
    }
    S.Vinv = Vinv[p,p]
    L = cholesky(S.Vinv)
    return(S.xvars[p])
}

real matrix Kmatch_get_V(struct KmatchSet scalar S, real rowvector r)
{
    real colvector w
    
    if (S.w) {
        w = st_data(r, S.wvar)
        if (S.w==1) w = w * rows(w) / quadsum(w)
    }
    else w = 1
    return(quadvariance(st_data(r, S.xvars), w))
}

real matrix Kmatch_get_Vdiag(struct KmatchSet scalar S, real rowvector r)
{
    real scalar    i, c
    real colvector w
    real matrix    V
    
    if (S.w) {
        w = st_data(r, S.wvar)
        if (S.w==1) w = w * rows(w) / quadsum(w)
    }
    else w = 1
    c = cols(S.xvars)
    V = J(c, c, 0)
    for (i=1; i<=c; i++) V[i,i] = quadvariance(st_data(r, S.xvars[i]), w)
    return(V)
}

void Kmatch_o(struct KmatchSet scalar S, real scalar o, 
    real rowvector xvars, real matrix L)
{
    real scalar             i
    real rowvector          r
    real matrix             E
    struct KmatchG scalar   T, C
    
    // get data
    r = S.O[o,(2,3)]
    Kmatch_o_get_data(r, S.treat, T, S, xvars, L)
    Kmatch_o_get_data(r, S.control, C, S, xvars, L)
    
    // compress data
    Kmatch_compress(T, S)
    Kmatch_compress(C, S)
    
    // get indices of exact matching groups (and exclude missing S)
    E = Kmatch_e_index(T, C, S)
    
    // bandwidth selection
    if (S.bw) {
        if (S.cv & S.md==0 & S.limit) S.sdPS = Kmatch_o_sdPS(T, C, S)
        if (S.att) {
            if (S.bwnoi) {
                printf("{txt}(")
                if (S.over<.) printf("%s=%g: ", S.oname, S.O[o,1])
                printf("computing bandwidth ")
                if (S.atc & S.sharedbw==0) printf("for treated ")
                displayflush()
            }
            Kmatch_bw(T, C, E, S)
            S.h[o,1] = T.h
            if (S.sharedbw) S.h[o,2] = T.h
            if (S.cv) {
                S.tgrid[o,] = T.grid
                S.tmise[o,] = T.mise
            }
        }
        if (S.atc & S.sharedbw==0) {
            if (S.bwnoi) {
                printf("{txt}(")
                if (S.over<.) printf("%s=%g: ", S.oname, S.O[o,1])
                printf("computing bandwidth ")
                if (S.att) printf("for untreated ")
                displayflush()
            }
            Kmatch_bw(C, T, E[,(3,4,1,2)], S)
            S.h[o,1+S.att] = C.h
            if (S.cv) {
                S.cgrid[o,] = C.grid
                S.cmise[o,] = C.mise
            }
        }
    }
    if (S.att) T.h = S.h[o,1]
    if (S.atc) C.h = S.h[o,1+S.att]
    
    // apply matching to each ematch group
    if (S.md & S.nn==0) { // MD search window
        if (S.att) T.h2 = Kmatch_MD_h2(T.h, cols(T.X))
        if (S.atc) C.h2 = Kmatch_MD_h2(C.h, cols(C.X))
    }
    if (S.att) {
        if (S.Y) T.Yc = J(T.n, cols(T.Y), .)
        T.nc = J(T.n, 1, 0)
        C.mw = C.nm = J(C.n, 1, 0)
    }
    if (S.atc) {
        if (S.Y) C.Yc = J(C.n, cols(C.Y), .)
        C.nc = J(C.n, 1, 0)
        T.mw = T.nm = J(T.n, 1, 0)
    }
    for (i=1; i<=rows(E); i++) {
        if (S.att) Kmatch_e(T, E[i,1], E[i,2], C, E[i,3], E[i,4], S)
        if (S.atc) Kmatch_e(C, E[i,3], E[i,4], T, E[i,1], E[i,2], S)
    }
    if (S.att) {
        if (S.Y) st_store(T.p, S.dyvars, T.Yc[T.pe,])
        st_store(T.p, S.nc, T.nc[T.pe])
        st_store(C.p, S.mw, C.mw[C.pe])
        st_store(C.p, S.nm, C.nm[C.pe])
    }
    if (S.atc) {
        if (S.Y) st_store(C.p, S.dyvars, C.Yc[C.pe,])
        st_store(C.p, S.nc, C.nc[C.pe])
        st_store(T.p, S.mw, T.mw[T.pe])
        st_store(T.p, S.nm, T.nm[T.pe])
    }
}

real scalar Kmatch_o_sdPS(struct KmatchG scalar T, struct KmatchG scalar C,
    struct KmatchSet scalar S)
{
    real scalar n
    real colvector w
   
    w = T.fw \ C.fw
    if (S.w==1) {
        n = sum(w)
        w = w :* (T.w \ C.w)
        w = w * (n/quadsum(w))
    }
    return(sqrt(variance(T.S \ C.S, w)))
}

void Kmatch_o_get_data(real rowvector r, real scalar g, 
    struct KmatchG scalar G, struct KmatchSet scalar S, 
    real rowvector xvars, real matrix L)
{
    if (S.ematch<.) G.E = st_data(r, S.ematch, g)
    if (S.md) {
        if (cols(xvars)<1) { // (no xvars)
            G.p = select(r[1]::r[2], st_data(r, g):==1)
            G.X = G.S = J(rows(G.p), 1, 0)
            if (S.mdmethod==0) S.Vinv = 1
            else if (S.mdmethod==2) {
                S.Vinv = 1
                G.XWX = G.X
            }
        }
        else {
            G.X = st_data(r, xvars, g)
            if (length(L)>0) {
                if (S.mdmethod==0) {
                    G.S = rowsum(G.X * L, 1)
                }
                else if (S.mdmethod==1) {
                    G.X = G.X * L
                    G.S = rowsum(G.X, 1)
                }
                else if (S.mdmethod==2) {
                    G.XWX = rowsum((G.X * S.Vinv) :* G.X, 1)
                    G.S = rowsum(G.X * L, 1)
                }
            }
            else G.S = rowsum(G.X, 1)
            if (S.ematch<.) G.p = order((G.E, G.S, (1::rows(G.S))), (1,2,3))
            else            G.p = order((G.S, (1::rows(G.S))), (1,2))
            _collate(G.X, G.p); _collate(G.S, G.p)
            if (rows(G.XWX)>0) _collate(G.XWX, G.p)
            G.p = select(r[1]::r[2], st_data(r, g):==1)[G.p]
            if (S.cv & S.Zvar>=.) {
                if (length(L)>0) {
                    if (S.mdmethod==1) G.Xs = &G.X
                    else               G.Xs = &(G.X * L)
                }
                else G.Xs = &G.X
            }
        }
    }
    else {
        G.p = select(r[1]::r[2], st_data(r, g):==1)
        G.S = st_data(G.p, S.ps)
    }
    G.n = rows(G.p)
    if (S.w) G.w = st_data(G.p, S.wvar)
    if (S.Y) G.Y  = st_data(G.p, S.yvars)
    if (S.Zvar<.) G.Z = st_data(G.p, S.Zvar)
}

void Kmatch_compress(struct KmatchG scalar G, struct KmatchSet scalar S)
{
    real scalar    i, j, a, b
    real colvector s
    real rowvector Xa, Xb
    
    // find ties
    G.fw = G.pe = s = J(G.n,1,.)
    i = j = a = b = 1
    Xa = (S.ematch<. ? G.E[i]  : J(1,0,.)),
         (S.md       ? G.X[i,] : G.S[i]), 
         (S.w==1     ? G.w[i]  : J(1,0,.))
    for (i=2;i<=G.n;i++) {
        Xb = (S.ematch<. ? G.E[i]  : J(1,0,.)),
             (S.md       ? G.X[i,] : G.S[i]),
             (S.w==1     ? G.w[i]  : J(1,0,.))
        if (Xb!=Xa) {
            Kmatch_compress_update(j, a, b, s, G, S)
            a = b = i; j++
            swap(Xa,Xb)
        }
        else b = i
    }
    Kmatch_compress_update(j, a, b, s, G, S)
    // select data
    G.n = j
    s = s[|1 \ j|]
    G.fw = G.fw[s]
    G.S = G.S[s]
    if (S.w)            G.w = G.w[s]
    if (cols(G.X)>0)    G.X = G.X[s,]
    if (cols(G.XWX)>0)  G.XWX = G.XWX[s,]
    if (G.Xs!=NULL) {
        if (G.Xs!=(&G.X)) {
            if (cols(*G.Xs)>0) G.Xs = &((*G.Xs)[s,])
        }
    }
    if (S.ematch<.)     G.E = G.E[s]
    if (S.Y)            G.Y = G.Y[s,]
    if (S.Zvar<.)       G.Z = G.Z[s]
}

void Kmatch_compress_update(real scalar j, real scalar a, real scalar b, 
    real colvector s, struct KmatchG scalar G, struct KmatchSet scalar S)
{
    s[j] = a
    G.pe[|a \ b|] = J(b-a+1, 1, j)
    if (cols(G.Y)>0) 
        G.Y[a,] = mean(G.Y[|a,1 \ b,.|], (S.w ? G.w[|a \ b|] : 1))
    if (S.Zvar<.)
        G.Z[a] = mean(G.Z[|a \ b|], (S.w ? G.w[|a \ b|] : 1))
    if (S.w==2) G.fw[a] = sum(G.w[|a \ b|])
    else        G.fw[a] = b-a+1
}

real matrix Kmatch_e_index(struct KmatchG scalar T, struct KmatchG scalar C,
    struct KmatchSet scalar S)
{
    real scalar i, i1, j, j1, k, e
    real matrix E
    
    // no ematch: eliminate obs with missing S
    if (S.ematch>=.) {
        for (i=1; i<=T.n; i++) {
            if (T.S[i]>=.) break
        }
        if ((i-1)==0) return(J(0,4,.))
        for (j=1; j<=C.n; j++) {
            if (C.S[j]>=.) break
        }
        if ((j-1)==0) return(J(0,4,.))
        return((1, i-1, 1, j-1))
    }
    
    // ematch: build dictionary
    E = J(min((T.n, C.n)), 4, .)
    k = 0; j = 1
    for (i=1; i<=T.n; i++) {
        if (T.S[i]>=.) continue
        e = T.E[i]
        for (i1=i; i1<T.n; i1++) {
            if (T.E[i1+1]>e) break
            if (T.S[i1+1]>=.) break
        }
        for (; j<=C.n; j++) {
            if (C.E[j]>=e & C.S[j]<.) break
        }
        if (j>C.n) break
        if (C.E[j]>e) {
            i = i1; continue
        }
        for (j1=j; j1<C.n; j1++) {
            if (C.E[j1+1]>e) break
            if (C.S[j1+1]>=.) break
        }
        E[++k,] = (i, i1, j, j1)
        i = i1
    }
    return(E[|1,1 \ k, .|])
}

void Kmatch_e(struct KmatchG scalar T, real scalar t0, real scalar t1, 
    struct KmatchG scalar C, real scalar c0, real scalar c1, 
    struct KmatchSet scalar S)
{
    real scalar i, a, b

    a = b = c0
    for (i=t0;i<=t1;i++) {
        (*S.match)(T, C, i, a, b, t1, c0, c1, S)
        if (a>c1) break
    }
}

void Kmatch_i_PS(struct KmatchG scalar T, struct KmatchG scalar C, real scalar i,
    real scalar a, real scalar b, real scalar t1, real scalar c0, real scalar c1, 
    struct KmatchSet scalar S)
{
    real scalar    c
    real colvector w, fw
    pragma unused  c0
    
    // determine lower bound index of kernel window
    c = T.S[i]
    for (;a<=c1;a++) {
        if ((c-C.S[a])<T.h) break
    }
    if (a>c1) { // no controls left; skip remaining treatment cases
        i = t1; return
    }
    // check whether any controls are within kernel window
    if ((C.S[a]-c)>=T.h) {
        if (S.w==1) { // skip ties
            while (i<t1) {
                if (T.S[i+1]==c) i++
                else break
            }
        }
        return
    }
    // determine upper bound index of kernel window
    if (a>=b) b = a + 1
    for (;b<=c1;b++) {
        if ((C.S[b]-c)>=T.h) {
            b--; break
        }
    }
    if (b>c1) b = c1
    // compute kernel weights
    w = (*S.K)((C.S[|a\b|]:-c)/T.h)
    if (S.w==1) w = w :* C.w[|a\b|]
    fw = C.fw[|a\b|]
    // cross-validation
    if (S.cvs) {
        Kmatch_i_PS_cvs(T, C, i, a, b, t1, w, fw, c, S)
        return
    }
    // number of observations within kernel window
    T.nc[i] = sum(fw)
    // ridge matching
    if (S.r<.) w = Kmatch_Ridge(w, fw, c, C.S[|a\b|], T.h, S.r)
    else       w = w / quadsum(w:*fw)
    // update control group info (using mean updating for sum of weights)
    Kmatch_i_PS_info(T, C, i, a, b, t1, c, w, fw, S)
}

void Kmatch_i_PS_cvs(struct KmatchG scalar T, struct KmatchG scalar C, 
    real scalar i, real scalar a, real scalar b, real scalar t1, 
    real colvector w, real colvector fw, real scalar c, 
    struct KmatchSet scalar S)
{
    real scalar     j, r
    real colvector  d, w1, P
    
    // potential outcome including control j
    P = C.S[|a\b|]
    if (S.r<.) w1 = Kmatch_Ridge(w, fw, c, P, T.h, S.r)
    else       w1 = w / quadsum(w:*fw)
    T.C1[i] = mean(P, w1:*fw)
    // compute contribution of control j
    r = b - a + 1
    if (r==1&fw[1]==1) { // only one control: adjust denominator
        C.C2[a] = C.C2[a] + (S.w==1 ? T.w[i]*T.fw[i] : T.fw[i])
        d = P
    }
    else if (S.cvsexact) { // ridge matching: use exact computation (slow)
        d = J(r,1,.)
        for (j=1;j<=r;j++) {
            fw[j] = fw[j] - 1
            w1 = Kmatch_Ridge(w, fw, c, P, T.h, S.r)
            d[j] = T.C1[i] - mean(P, w1:*fw)
            fw[j] = fw[j] + 1
        }
    }
    else if (any(abs(1:-w1):<1e-8)) {
        // use slow computation to avoid precision problem if w close to 1
        d = J(r,1,.)
        for (j=1;j<=r;j++) {
            fw[j] = fw[j] - 1
            d[j] = T.C1[i] - mean(P, w1:*fw)
            fw[j] = fw[j] + 1
        }
    }
    else d = w1 :* (P :- T.C1[i]) :/ (1 :- w1)
    if (S.w==1) C.C1[|a\b|] = C.C1[|a\b|] + d * (T.w[i] * T.fw[i])
    else        C.C1[|a\b|] = C.C1[|a\b|] + d * T.fw[i]
    // skip ties
    if (S.w==1) {
        while (i<t1) {
            if (T.S[i+1]==c) {
                T.C1[i+1] = T.C1[i]
                i++
                if (r==1&fw[1]==1)
                    C.C2[a] = C.C2[a] + (S.w==1 ? T.w[i]*T.fw[i] : T.fw[i])
                if (S.w==1) C.C1[|a\b|] = C.C1[|a\b|] + d * (T.w[i] * T.fw[i])
                else        C.C1[|a\b|] = C.C1[|a\b|] + d * T.fw[i]
            }
            else break
        }
    }
}

void Kmatch_i_PS_info(struct KmatchG scalar T, struct KmatchG scalar C,
    real scalar i, real scalar a, real scalar b, real scalar t1, 
    real scalar c, real colvector w, real colvector fw, 
    struct KmatchSet scalar S)
{
    real scalar    nm
    real colvector mw
    
    // potential outcomes
    if (S.Y) T.Yc[i,.] = mean(C.Y[|a,1 \ b,.|], w:*fw)
    // number of matches/matching weights
    if (S.w==1) {
        nm = T.fw[i]
        mw = w * (T.w[i] * T.fw[i])
        // skip ties
        while (i<t1) {
            if (T.S[i+1]==c) {
                T.nc[i+1] = T.nc[i]
                if (S.Y) T.Yc[i+1,.] = T.Yc[i,.]
                i++
                nm = nm + T.fw[i]
                mw = mw + w * (T.w[i] * T.fw[i])
            }
            else break
        }
        C.nm[|a\b|] = C.nm[|a\b|] :+ nm
        C.mw[|a\b|] = C.mw[|a\b|] + mw
    }
    else {
        C.nm[|a\b|] = C.nm[|a\b|] :+ T.fw[i]
        C.mw[|a\b|] = C.mw[|a\b|] + (w * T.fw[i])
    }
}

void Kmatch_i_PS_nn(struct KmatchG scalar T, struct KmatchG scalar C,
    real scalar i, real scalar a0, real scalar b0, real scalar t1, 
    real scalar c0, real scalar c1, struct KmatchSet scalar S)
{
    real scalar    c, ca, cb, a, b, n
    real colvector w, fw
    
    // determine lower nearest neighbor
    c = T.S[i]
    for (;a0<c1;a0++) {
        if (C.S[a0+1]>c) break
    }
    // determine upper nearest neighbor
    for (b0=(a0+1);b0<=c1;b0++) {
        if (C.S[b0]>=c) break
    }
    if (b0>c1) b0 = c1
    // select minimum and get ties
    if (b0==a0) { // can happen at end of data
        b  = a0
        ca = C.S[a0]
        for (a=a0;a>c0;a--) {
            if (C.S[a-1]<ca) break
        }
    }
    else if ((ca=C.S[a0])>c) { // can happen at beginning of data
        a = a0
        for (b=a;b<c1;b++) {
            if (C.S[b+1]>ca) break
        }
    }
    else {
        cb = C.S[b0]
        if ((c-ca)<(cb-c)) {
            for (a=a0;a>c0;a--) {
                if (C.S[a-1]<ca) break
            }
            b = a0
        }
        else if ((cb-c)<(c-ca)) {
            for (b=b0;b<c1;b++) {
                if (C.S[b+1]>cb) break
            }
            a = b0
        }
        else {
            for (a=a0;a>c0;a--) {
                if (C.S[a-1]<ca) break
            }
            for (b=b0;b<c1;b++) {
                if (C.S[b+1]>cb) break
            }
        }
    }
    // get matches
    if (!(abs(C.S[a]-c)<=T.h)) {
        while (i<t1) { // skip ties
            if (T.S[i+1]==c) i++
            else break
        }
        return
    }
    fw = C.fw[|a\b|]
    n = sum(fw)
    while (n < S.nn) {
        if (a>c0 & b<c1) {
            ca = C.S[a-1]; cb = C.S[b+1]
            if (!(((c-ca)<=T.h) | ((cb-c)<=T.h))) break
            if ((c-ca)<(cb-c)) {
                for (a=a-1;a>c0;a--) {
                    if (C.S[a-1]<ca) break
                }
            }
            else if ((cb-c)<(c-ca)) {
                for (b=b+1;b<c1;b++) {
                    if (C.S[b+1]>cb) break
                }
            }
            else {
                for (a=a-1;a>c0;a--) {
                    if (C.S[a-1]<ca) break
                }
                for (b=b+1;b<c1;b++) {
                    if (C.S[b+1]>cb) break
                }
            }
        }
        else if (a>c0) {
            ca = C.S[a-1]
            if (!((c-ca)<=T.h)) break
            for (a=a-1;a>c0;a--) {
                if (C.S[a-1]<ca) break
            }
        }
        else if (b<c1) {
            cb = C.S[b+1]
            if (!((cb-c)<=T.h)) break
            for (b=b+1;b<c1;b++) {
                if (C.S[b+1]>cb) break
            }
        }
        else break
        fw = C.fw[|a\b|]
        n = sum(fw)
    }
    if (n < S.nn) { // exclude if less than nn() neighbors
        if (S.w==1) { // skip ties
            while (i<t1) {
                if (T.S[i+1]==c) i++
                else break
            }
        }
        return
    }
    T.nc[i] = n
    // weights
    if (S.w==1) {
        w = C.w[|a\b|]
        w = w / quadsum(w:*fw)
    }
    else w = J(b-a+1,1,1/n)
    // update control group info
    Kmatch_i_PS_info(T, C, i, a, b, t1, c, w, fw, S)
}

void Kmatch_i_MD(struct KmatchG scalar T, struct KmatchG scalar C, real scalar i,
    real scalar a, real scalar b, real scalar t1, real scalar c0, real scalar c1,
    struct KmatchSet scalar S)
{
    real scalar    c
    real colvector p, w, fw, MD
    pragma unused  c0
    
    // determine minimum lower bound index of kernel window
    c = T.S[i]
    for (;a<=c1;a++) {
        if ((c-C.S[a])<T.h2) break
    }
    if (a>c1) { // no controls left; skip remaining treatment cases
        i = t1; return
    }
    // check whether any controls are within kernel window
    if ((C.S[a]-c)>=T.h2) {
        while (i<t1) { // skip ties
            if (T.S[i+1]==c) i++
            else break
        }
        return
    }
    // determine maximum upper bound index of kernel window
    if (a>=b) b = a + 1
    for (;b<=c1;b++) {
        if ((C.S[b]-c)>=T.h2) {
            b--; break
        }
    }
    if (b>c1) b = c1
    // compute multivariate distance
    MD = Kmatch_MD2(T, i, C, (a,1 \ b,.), S)
    // select controls within kernel window
    p = selectindex(MD:<max((T.h^2,smallestdouble())))
    MD = MD[p]
    p = (a::b)[p]
    if (length(p)==0) {
        if (S.w==1) { // skip ties
            while (i<t1) { // skip ties
                if (T.X[i+1,]==T.X[i,]) i++
                else break
            }
        }
        return
    }
    // compute kernel weights
    MD = sqrt(MD)
    w = (*S.K)(MD/T.h)
    if (S.w==1) w = w :* C.w[p]
    fw = C.fw[p]
    // cross-validation
    if (S.cvs) {
        Kmatch_i_MD_cvs(T, C, i, p, t1, w, fw, MD, S)
        return
    }
    // number of observations within kernel window
    T.nc[i] = sum(fw)
    // ridge matching
    if (S.r<.) w = Kmatch_Ridge(w, fw, 0, MD, T.h, S.r)
    else       w = w / quadsum(w:*fw)
    // update control group info (using mean updating for sum of weights)
    Kmatch_i_MD_info(T, C, i, p, t1, w, fw, S)
}

void Kmatch_i_MD_cvs(struct KmatchG scalar T, struct KmatchG scalar C, 
    real scalar i, real colvector p, real scalar t1, real colvector w, 
    real colvector fw, real colvector MD, struct KmatchSet scalar S)
{
    real scalar     j, r
    real colvector  w1
    real matrix     d, P
    
    // potential outcome including control j
    P = (*C.Xs)[p,]
    if (S.r<.) w1 = Kmatch_Ridge(w, fw, 0, MD, T.h, S.r)
    else       w1 = w / quadsum(w:*fw)
    T.C1[i,] = mean(P, w1:*fw)
    // compute contribution of control j
    r = rows(p)
    if (r==1&fw[1]==1) { // only one control: adjust denominator
        C.C2[p] = C.C2[p] + (S.w==1 ? T.w[i]*T.fw[i] : T.fw[i]) 
        d = P
    }
    else if (S.cvsexact) { // ridge matching: use exact computation (slow)
        d = J(r,cols(P),.)
        for (j=1;j<=r;j++) {
            fw[j] = fw[j] - 1
            w1 = Kmatch_Ridge(w, fw, 0, MD, T.h, S.r)
            d[j,] = T.C1[i,] - mean(P, w1:*fw)
            fw[j] = fw[j] + 1
        }
    }
    else if (any(abs(1:-w1):<1e-8)) {
        // use slow computation to avoid precision problem if w close to 1
        d = J(r,cols(P),.)
        for (j=1;j<=r;j++) {
            fw[j] = fw[j] - 1
            d[j,] = T.C1[i,] - mean(P, w1:*fw)
            fw[j] = fw[j] + 1
        }
    }
    else d = w1 :* (P :- T.C1[i,]) :/ (1 :- w1)
    if (S.w==1) C.C1[p,] = C.C1[p,] + d * (T.w[i] * T.fw[i])
    else        C.C1[p,] = C.C1[p,] + d * T.fw[i]
    // skip ties
    if (S.w==1) {
        while (i<t1) {
            if (T.X[i+1,]==T.X[i,]) {
                T.C1[i+1,] = T.C1[i,]
                i++
                if (r==1&fw[1]==1) 
                    C.C2[p] = C.C2[p] + (S.w==1 ? T.w[i]*T.fw[i] : T.fw[i]) 
                if (S.w==1) C.C1[p,] = C.C1[p,] + d * (T.w[i] * T.fw[i])
                else        C.C1[p,] = C.C1[p,] + d * T.fw[i]
            }
            else break
        }
    }
}

void Kmatch_i_MD_info(struct KmatchG scalar T, struct KmatchG scalar C,
    real scalar i, real colvector p, real scalar t1, real colvector w, 
    real colvector fw,  struct KmatchSet scalar S)
{
    real scalar    nm
    real colvector mw
    
    // potential outcomes
    if (S.Y) T.Yc[i,.] = mean(C.Y[p,], w:*fw)
    // number of matches/matching weights
    if (S.w==1) {
        nm = T.fw[i]
        mw = w * (T.w[i] * T.fw[i])
        // skip ties
        while (i<t1) {
            if (T.X[i+1,]==T.X[i,]) {
                T.nc[i+1] = T.nc[i]
                if (S.Y) T.Yc[i+1,.] = T.Yc[i,.]
                i++
                nm = nm + T.fw[i]
                mw = mw + w * (T.w[i] * T.fw[i])
            }
            else break
        }
        C.nm[p] = C.nm[p] :+ nm
        C.mw[p] = C.mw[p] + mw
    }
    else {
        C.nm[p] = C.nm[p] :+ T.fw[i]
        C.mw[p] = C.mw[p] + (w * T.fw[i])
    }
}

void Kmatch_i_MD_nn(struct KmatchG scalar T, struct KmatchG scalar C,
    real scalar i, real scalar a0, real scalar b0, real scalar t1, 
    real scalar c0, real scalar c1, struct KmatchSet scalar S)
{
    real scalar    c, a, aa, b, bb, h, n, j
    real colvector p, w, fw, MD
    real matrix    I
    pragma unset   p
    pragma unset   I
    
    // determine lower nearest neighbor in sum score
    c = T.S[i]
    for (;a0<c1;a0++) {
        if (C.S[a0+1]>c) break
    }
    // determine upper nearest neighbor in sum score
    for (b0=(a0+1);b0<=c1;b0++) {
        if (C.S[b0]>=c) break
    }
    if (b0>c1) b0 = c1
    // initial search window
    a = max((c0, a0-5*ceil(ln(C.n))))   // increase in initial search window
    b = min((c1, b0+5*ceil(ln(C.n))))   // improves speed; could be optimized
    n = sum(C.fw[|a\b|])
    while (n<S.nn) { // increase until large enough
        if (a>c0) {
            a--
            n = n + C.fw[a]
        }
        if (b<c1) {
            b++
            n = n + C.fw[b]
        }
        if (a==c0 & b==c1) break
    }
    MD = Kmatch_MD2(T, i, C, (a,1 \ b,.), S)
    minindex(MD, S.nn, p, I)
    n = 0
    for (j=1; j<length(p); j++) {
        n = n + C.fw[a+p[j]-1]
        if (n>=S.nn) break
    }
    h = sqrt(MD[p[j]])
    if (T.h<h) h = T.h
    h = Kmatch_MD_h2(h, cols(T.X))
    for (aa=a;aa>c0;aa--) {
        if ((c-C.S[aa-1])>h) break
    }
    if (aa<a) MD = Kmatch_MD2(T, i, C, (aa,1 \ a-1,.), S) \ MD
    for (bb=b;bb<c1;bb++) {
        if ((C.S[bb+1]-c)>h) break
    }
    if (bb>b) MD = MD \ Kmatch_MD2(T, i, C, (b+1,1 \ bb,.), S)
    // select minima
    minindex(MD, S.nn, p, I)
    fw = C.fw[|aa \ bb|]
    n = 0
    for (j=1; j<=rows(I); j++) {
        n = n + sum(fw[p[|I[j,1] \ I[j,1]+I[j,2]-1|]])
        if (n>=S.nn) break
    }
    if (j>rows(I)) j = rows(I)
    p = p[|1 \ I[j,1]+I[j,2]-1|]
    if (T.h<.) {
        MD = MD[p]
        p = select(p, MD:<max((T.h^2,smallestdouble())))
        fw = fw[p]
        n = sum(fw)
    }
    else fw = fw[p]
    if (n<S.nn) { // exclude if less than nn() neighbors
        if (S.w==1) { // skip ties
            while (i<t1) {
                if (T.X[i+1,]==T.X[i,]) i++
                else break
            }
        }
        return
    }
    p = (aa-1) :+ p
    T.nc[i] = n
    // weights
    if (S.w==1) {
        w = C.w[p]
        w = w / quadsum(w:*fw)
    }
    else w = J(length(p),1,1/n)
    // update control group info
    Kmatch_i_MD_info(T, C, i, p, t1, w, fw, S)
}

real colvector Kmatch_Ridge(real colvector w, real colvector fw, 
    real scalar pi, real colvector pj, real scalar h, real scalar r)
{
    real scalar    W, P, S, d, c
    real colvector wfw, D
    
    if (rows(pj)==1) { // just one row, w evaluates to 1/fw
        return(1/fw)
    }
    if (diag0cnt(invsym(variance(pj)))) { // check for collinearity
        return(w / quadsum(w:*fw))
    }
    wfw = w :* fw
    W = quadsum(wfw)
    P = quadsum(pj :* wfw) / W
    D = pj:-P
    S = quadsum(D:^2 :* wfw)
    d = pi-P
    c = r * h * abs(d)
    return(w / W + w :* D * (d / (S + c)))
}

void Kmatch_bw(struct KmatchG scalar T, struct KmatchG scalar C,
    real matrix E, struct KmatchSet scalar S)
{
    real scalar    i
    real colvector p

    // pair-marching
    if (S.cv==0 | cols(S.grid)<1) {
        if (S.bwnoi) {
            if (S.cv==0) printf("...")
            else         printf(".")
            displayflush()
        }
        T.C1 = J(T.n, 1, .)
        for (i=1; i<=rows(E); i++) {
            Kmatch_mindist_e(T, E[i,1], E[i,2], C, E[i,3], E[i,4], S)
        }
        if (S.sharedbw) {
            C.C1 = J(C.n, 1, .)
            for (i=1; i<=rows(E); i++) {
                Kmatch_mindist_e(C, E[i,3], E[i,4], T, E[i,1], E[i,2], S)
            }
            if (S.pmq==1) T.h = max((T.C1 \ C.C1)) * S.pmf
            else {
                // only use nonzero (and non-missing) distances
                p = selectindex(((T.C1 \ C.C1):<.):&((T.C1 \ C.C1):>0))
                if (length(p)==0) T.h = 0
                else T.h = Kmatch_quantile((T.C1 \ C.C1)[p], 
                    (S.w==1 ? (T.w \ C.w)[p]:*(T.fw \ C.fw)[p] : 
                    (T.fw \ C.fw)[p]), S.pmq) * S.pmf
            }
            C.C1 = J(0,0,.)
        }
        else {
            if (S.pmq==1) T.h = max(T.C1) * S.pmf
            else {
                // only use nonzero (and non-missing) distances
                p = selectindex((T.C1:<.):&(T.C1:>0)) 
                if (length(p)==0) T.h = 0
                else T.h = Kmatch_quantile(T.C1[p], 
                    (S.w==1 ? T.w[p]:*T.fw[p] : T.fw[p]), S.pmq) * S.pmf
            }
        }
        T.C1 = J(0,0,.)
        T.h = T.h + epsilon(T.h) + smallestdouble() // slight increase; avoid 0
        if (S.bwnoi) {
            if (S.cv==0) {
                printf(" done)\n")
                displayflush()
            }
        }
        if (S.cv==0) return
    }
    
    // cross-validation
    Kmatch_cv(T, C, E, S)
    T.C1 = C.C1 = J(0,0,.)
    T.C2 = C.C2 = J(0,1,.)
}

void Kmatch_mindist_e(struct KmatchG scalar T, real scalar t0, real scalar t1, 
    struct KmatchG scalar C, real scalar c0, real scalar c1, 
    struct KmatchSet scalar S)
{
    real scalar i, a

    a = c0
    for (i=t0;i<=t1;i++) {
        (*S.mindist)(T, C, i, a, t1, c0, c1, S)
    }
}

void Kmatch_mindist_i_PS(struct KmatchG scalar T, struct KmatchG scalar C, 
    real scalar i, real scalar a, real scalar t1, real scalar c0, real scalar c1,
    struct KmatchSet scalar S)
{
    real scalar b, c
    pragma unused c0
    pragma unused S
    
    // determine lower nearest neighbor
    c = T.S[i]
    for (;a<c1;a++) {
        if (C.S[a+1]>c) break
    }
    // determine upper nearest neighbor
    for (b=(a+1);b<=c1;b++) {
        if (C.S[b]>=c) break
    }
    if (b>c1) b = c1
    // minimum distance
    T.C1[i] = min(abs(C.S[(a\b)]:-c))
    // skip ties
    if (S.w==1) {
        while (i<t1) {
            if (T.S[i+1]==c) {
                T.C1[i+1] = T.C1[i]
                i++
            }
            else break
        }
    }
}

void Kmatch_mindist_i_MD(struct KmatchG scalar T, struct KmatchG scalar C, 
    real scalar i, real scalar a, real scalar t1, real scalar c0, real scalar c1,
    struct KmatchSet scalar S)
{
    real scalar c, aa, aaa, b, bb, r, h, min
    
    // determine lower nearest neighbor in sum score
    c = T.S[i]
    for (;a<c1;a++) {
        if (C.S[a+1]>c) break
    }
    // determine upper nearest neighbor in sum score
    for (b=(a+1);b<=c1;b++) {
        if (C.S[b]>=c) break
    }
    if (b>c1) b = c1
    // find nearest neighbor in euclidean distances
    r = cols(T.X)
    aa = max((c0, a-5*ceil(ln(C.n))))   // increase in initial search window 
    b  = min((c1, b+5*ceil(ln(C.n))))   // improves speed; could be optimized
    min = min(Kmatch_MD2(T, i, C, (aa,1 \ b,.), S))
    h = sqrt(min/r)*r
    for (aaa=aa;aaa>c0;aaa--) {
        if ((c-C.S[aaa-1])>h) break
    }
    if (aaa<aa) {
        min = min((min \ Kmatch_MD2(T, i, C, (aaa,1 \ aa,.), S)))
        h = sqrt(min/r)*r
    }
    for (bb=b;bb<c1;bb++) {
        if ((C.S[bb+1]-c)>h) break
    }
    if (bb>b) min = min((min \ Kmatch_MD2(T, i, C, (b,1 \ bb,.), S)))
    // minimum distance
    T.C1[i] = sqrt(min)
    // skip ties
    if (S.w==1) {
        while (i<t1) {
            if (T.X[i+1,]==T.X[i,]) {
                T.C1[i+1] = T.C1[i]
                i++
            }
            else break
        }
    }
}

void Kmatch_cv(struct KmatchG scalar T, struct KmatchG scalar C,
    real matrix E, struct KmatchSet scalar S)
{
    struct KmatchG scalar T2, C2
    real matrix           M0, E2
    
    // cvs: overall means
    if (S.Zvar>=.) {
        S.cvs = 1
        if (S.md) M0 = mean(*T.Xs, (S.w==1 ? T.w:*T.fw : T.fw))
        else      M0 = mean(T.S, (S.w==1 ? T.w:*T.fw : T.fw))
        if (S.sharedbw) {
            if (S.md) M0 = M0 \ mean(*C.Xs, (S.w==1 ? C.w:*C.fw : C.fw))
            else      M0 = M0 \ mean(C.S, (S.w==1 ? C.w:*C.fw : C.fw))
        }
    }
    // cvo: expand (and recompress) data
    else {
        E2 = J(rows(E),0,.)
        Kmatch_cvo_expand(C, E[,(3,4)], C2, E2, S)
        if (S.sharedbw) Kmatch_cvo_expand(T, E[,(1,2)], T2, E2, S)
    }
    
    // run cross-validation
    T.mise = J(1, S.cvn, .)
    if (cols(S.grid)<1) {
        T.grid = J(1, S.cvn, .)
        T.grid[1] = T.h
        Kmatch_cv_search(T, T2, C, C2, E, E2, M0, S)
    }
    else {
        T.grid = S.grid
        Kmatch_cv_grid(T, T2, C, C2, E, E2, M0, S)
    }
    if (S.bwnoi) {
        printf(" done)\n")
        displayflush()
    }
    S.cvs = 0
    
    // select minimum
    if (missing(T.mise)) {
        if (missing(T.mise)==cols(T.mise)) {
            printf("{txt}(MISE missing for all values of search grid;")
            printf(" bandwidth set to largest value)\n")
            T.h = max(T.grid)
            return
        }
        display("{txt}(MISE missing for some values of search grid)")
    }
    T.h = sort((T.grid',T.mise'),(2,1))[1,1]
}

void Kmatch_cv_search(struct KmatchG scalar T, struct KmatchG scalar T2, 
    struct KmatchG scalar C, struct KmatchG scalar C2,
    real matrix E, real matrix E2, real matrix M0, struct KmatchSet scalar S)
{
    real scalar i, up, min, l, ll
    
    up = 1
    for (i=1; i<=S.cvn; i++) {
        if (i==1)      T.h = C.h = T.grid[i]
        else if (i==2) T.h = C.h = T.grid[i] = T.grid[i-1] * S.cvf
        else if (up==1) {
            if (T.mise[i-1]<T.mise[i-2]) {
                T.h = C.h = T.grid[i] = T.grid[i-1] * S.cvf
            }
            else if (i==3) {
                ll = 1
                T.h = C.h = T.grid[i] = T.grid[i-2] / S.cvf
                up = 0
            }
            else {
                up = .
                min = i-2; l = i-1; ll = i-3
                T.h = C.h = T.grid[i] = (T.grid[min] + T.grid[l]) / 2
            }
        }
        else if (up==0) {
            if (T.mise[i-1]<T.mise[i-2]) {
                T.h = C.h = T.grid[i] = T.grid[i-1] / S.cvf
            }
            else {
                up = .
                if (ll==1)  ll = 1
                else        ll = i-3
                min = i-2; l = i-1
                T.h = C.h = T.grid[i] = (T.grid[min] + T.grid[l]) / 2
            }
        }
        else {
            if (T.mise[i-1]<T.mise[min]) {
                ll = l; l = min; min = i-1
            }
            else {
                l = ll; ll = i-1
            }
            T.h = C.h = T.grid[i] = (T.grid[min] + T.grid[l]) / 2
        }
        T.grid[i] = max((T.grid[i], smallestdouble()))
        if (S.md) T.h2 = C.h2 = Kmatch_MD_h2(T.h, cols(T.X))
        if (S.cvs) T.mise[i] = Kmatch_cvs(T, C, E, S, M0)
        else       T.mise[i] = Kmatch_cvo(T, T2, C, C2, E, E2, S)
        if (S.limit) {
            if (S.md) T.mise[i] = T.mise[i] * max((1,(T.h/sqrt(cols(T.X)))^.015))
            else      T.mise[i] = T.mise[i] * max((1,(T.h/S.sdPS)^.015))
        }
        if (S.bwnoi) {
            printf(".")
            displayflush()
        }
    }
}

void Kmatch_cv_grid(struct KmatchG scalar T, struct KmatchG scalar T2, 
    struct KmatchG scalar C, struct KmatchG scalar C2,
    real matrix E, real matrix E2, real matrix M0, struct KmatchSet scalar S)
{
    real scalar i
    
    for (i=1; i<=S.cvn; i++) {
        T.h = C.h = T.grid[i]
        if (S.md) T.h2 = C.h2 = Kmatch_MD_h2(T.h, cols(T.X))
        if (S.cvs) T.mise[i] = Kmatch_cvs(T, C, E, S, M0)
        else       T.mise[i] = Kmatch_cvo(T, T2, C, C2, E, E2, S)
        if (S.limit) {
            if (S.md) T.mise[i] = T.mise[i] * max((1,(T.h/sqrt(cols(T.X)))^.015))
            else      T.mise[i] = T.mise[i] * max((1,(T.h/S.sdPS)^.015))
        }
        if (S.bwnoi) {
            printf(".")
            displayflush()
        }
    }
}

real scalar Kmatch_cvs(struct KmatchG scalar T, struct KmatchG scalar C,
    real matrix E, struct KmatchSet scalar S, real matrix M0)
{
    real matrix M1, M2
    
    M1 = _Kmatch_cvs(T, C, E, S)
    if (S.sharedbw) {
        M2 = _Kmatch_cvs(C, T, E[,(3,4,1,2)], S)
        return(sum(mean(
            mean((M0[1,] :- M1):^2, C.fw) \ mean((M0[2,] :- M2):^2, T.fw), 
            (S.w==1 ? sum(T.w:*T.fw) \ sum(C.w:*C.fw) : sum(T.fw) \ sum(C.fw)))))
    }
    return(sum(mean((M0 :- M1):^2, C.fw)))
}

real matrix _Kmatch_cvs(struct KmatchG scalar T, struct KmatchG scalar C,
    real matrix E, struct KmatchSet scalar S)
{
    real scalar i
    
    if (S.md) {
        T.C1 = J(T.n,cols(*T.Xs),.)
        C.C1 = J(C.n,cols(*C.Xs),0)
    }
    else {
        T.C1 = J(T.n,1,.)
        C.C1 = J(C.n,1,0)
    }
    C.C2 = J(C.n,1,0)
    for (i=1; i<=rows(E); i++) {
        Kmatch_e(T, E[i,1], E[i,2], C, E[i,3], E[i,4], S)
    }
    return(
        ((S.w==1 ? colsum(T.C1:*(T.w:*T.fw)) : colsum(T.C1:*T.fw)) :- C.C1) :/ 
        ((S.w==1 ? colsum((T.C1:<.):*(T.w:*T.fw)) : colsum((T.C1:<.):*T.fw)) 
            :- J(1,cols(T.C1),C.C2)))
}

void Kmatch_cvo_expand(struct KmatchG scalar G, real matrix E,
    struct KmatchG scalar G2, real matrix E2, struct KmatchSet scalar S)
{
    real scalar    i, a, b
    real colvector eI
    
    // exact matching index
    eI = J(G.n,1,.)
    for (i=1; i<=rows(E); i++) {
        a = E[i,1]; b = E[i,2]
        eI[|a \ b|] = J(b-a+1, 1, i) 
    }
    
    // expand data
    G2 = G; G2.Y = J(0,0,.)
    G2.Z = st_data(G2.p, S.Zvar)
    G2.n = rows(G2.Z)
    G2.S = G2.S[G2.pe]
    if (S.w==2)         G2.w = st_data(G2.p, S.wvar)
    else if (S.w)       G2.w = G2.w[G2.pe]
    if (cols(G2.X)>0)   G2.X = G2.X[G2.pe,]
    if (cols(G2.XWX)>0) G2.XWX = G2.XWX[G2.pe,]
    if (S.ematch<.)     G2.E = G2.E[G2.pe]
    eI = eI[G2.pe]
    
    // recompress
    E2 = E2, Kmatch_cvo_compress(G2, J(rows(E2),2,.), eI, S)
}

real matrix Kmatch_cvo_compress(struct KmatchG scalar G, real matrix E, 
    real colvector eI, struct KmatchSet scalar S)
{
    real scalar    i, j, k, a, b
    real colvector s
    real rowvector Xa, Xb
    
    // find ties
    G.fw = s = J(G.n,1,.)
    i = j = a = b = 1
    Xa = (S.ematch<. ? G.E[i]  : J(1,0,.)),
         (S.md       ? G.X[i,] : G.S[i]), 
         (S.w==1     ? G.w[i]  : J(1,0,.)), G.Z[i]
    for (i=2;i<=G.n;i++) {
        Xb = (S.ematch<. ? G.E[i]  : J(1,0,.)),
             (S.md       ? G.X[i,] : G.S[i]),
             (S.w==1     ? G.w[i]  : J(1,0,.)), G.Z[i]
        if (Xb!=Xa) {
            if ((k = eI[a])<.) {
                if (E[k,1]>=.) E[k,1] = j
                E[k,2] = j
            }
            s[j] = a
            if (S.w==2) G.fw[a] = sum(G.w[|a \ b|])
            else        G.fw[a] = b-a+1
            a = b = i; j++
            swap(Xa,Xb)
        }
        else b = i
    }
    if ((k = eI[a])<.) {
        if (E[k,1]>=.) E[k,1] = j
        E[k,2] = j
    }
    s[j] = a
    if (S.w==2) G.fw[a] = sum(G.w[|a \ b|])
    else        G.fw[a] = b-a+1
    // select data
    G.n = j
    s = s[|1 \ j|]
    G.fw = G.fw[s]
    G.S = G.S[s]
    G.Z = G.Z[s]
    if (S.w)            G.w = G.w[s]
    if (cols(G.X)>0)    G.X = G.X[s,]
    if (cols(G.XWX)>0)  G.XWX = G.XWX[s,]
    if (S.ematch<.)     G.E = G.E[s]
    swap(G.pe, s)
    return(E)
}

real scalar Kmatch_cvo(struct KmatchG scalar T, struct KmatchG scalar T2, 
    struct KmatchG scalar C, struct KmatchG scalar C2,
    real matrix E, real matrix E2, struct KmatchSet scalar S)
{
    if (S.sharedbw) {
        return(mean(_Kmatch_cvo(C2, E2[,(1,2)], T, C, E, S) \ 
                    _Kmatch_cvo(T2, E2[,(3,4)], C, T, E[,(3,4,1,2)], S), 
            S.w==1 ? sum(T.w:*T.fw) \ sum(C.w:*C.fw) : sum(T.fw) \ sum(C.fw)))
    }
    return(_Kmatch_cvo(C2, E2, T, C, E, S))
}

real scalar _Kmatch_cvo(struct KmatchG scalar C2, real matrix E2, 
    struct KmatchG scalar T, struct KmatchG scalar C,
    real matrix E, struct KmatchSet scalar S)
{
    real scalar i, Y, mise
    
    if (S.weighted) {
        Y = S.Y; S.Y = 0
        T.nc = J(T.n, 1, 0)
        C.mw = C.nm = J(C.n, 1, 0)
        for (i=1; i<=rows(E); i++) {
            Kmatch_e(T, E[i,1], E[i,2], C, E[i,3], E[i,4], S)
        }
        C2.nm = (C.nm[C.pe])[C2.pe]
        C2.mw = (C.mw[C.pe])[C2.pe]
    }
    C2.C1 = C2.C2 = J(C2.n,1,0)
    C2.h = C.h; C2.h2 = C.h2
    for (i=1; i<=rows(E); i++) {
        Kmatch_cvo_e(C2, E2[i,1], E2[i,2], C, E[i,3], E[i,4], S)
    }
    if (S.weighted) {
        mise = mean(C2.C1, C2.fw:*C2.mw:*(C2.C2:>0))
        if (S.penalty) mise = mise * (sum(T.fw) / sum(T.fw:*(T.nc:>0)))
        S.Y = Y
    }
    else {
        mise = mean(C2.C1, C2.C2)
        if (S.penalty) mise = mise * (sum(C2.fw) / sum(C2.fw:*(C2.C2:>0)))
    }
    return(mise)
}

void Kmatch_cvo_e(struct KmatchG scalar T, real scalar t0, real scalar t1, 
    struct KmatchG scalar C, real scalar c0, real scalar c1, 
    struct KmatchSet scalar S)
{
    real scalar i, a, b

    a = b = c0
    for (i=t0;i<=t1;i++) {
        if (S.weighted) {
            if (T.nm[i]==0) continue // skip if not used as a match
        }
        (*S.cvomatch)(T, C, i, a, b, t1, c1, S)
    }
}

void Kmatch_cvo_i_PS(struct KmatchG scalar T, struct KmatchG scalar C, 
    real scalar i, real scalar a, real scalar b, real scalar t1, 
    real scalar c1, struct KmatchSet scalar S)
{
    real scalar    c, Z, W, wi
    real colvector w, fw, rw
    
    // determine lower bound index of kernel window
    c = T.S[i]
    for (;a<=c1;a++) {
        if ((c-C.S[a])<T.h) break
    }
    // determine upper bound index of kernel window
    if (a>=b) b = a + 1
    for (;b<=c1;b++) {
        if ((C.S[b]-c)>=T.h) {
            b--; break
        }
    }
    if (b>c1) b = c1
    // check whether at least one additional obs in window
    if ((b-a)<1) {
        if (C.fw[a]==1) return
    }
    // compute kernel weights
    w = (*S.K)((C.S[|a\b|]:-c)/T.h)
    if (S.w==1) w = w :* C.w[|a\b|]
    fw = C.fw[|a\b|]
    // compute counterfactuals
    wi = (*S.K)(0)
    if (S.w==1) {
        wi = wi * T.w[i]
        T.C2[i] = T.w[i] :* T.fw[i]
    }
    else T.C2[i] = T.fw[i]
    if (S.r<.) {
        rw = Kmatch_cvo_Ridge(w \ wi, fw \ -1, c, C.S[|a\b|] \ c, T.h, S.r)
        T.C1[i] = (T.Z[i] - mean(C.Z[|a\b|] \ T.Z[i], rw))^2
    }
    else {
        Z = quadsum(C.Z[|a\b|]:*w:*fw)
        W = quadsum(w:*fw)
        T.C1[i] = (T.Z[i] - (Z-wi*T.Z[i])/(W-wi))^2
    }
    // skip ties
    while (i<t1) {
        if (T.S[i+1]==c) {
            i++
            if (S.w==1) {
                wi = (*S.K)(0) * T.w[i]
                T.C2[i] = T.w[i] :* T.fw[i]
            }
            else T.C2[i] = T.fw[i]
            if (S.r<.) {
                if (S.w==1) rw = Kmatch_cvo_Ridge(w \ wi, fw \ -1, c, 
                    C.S[|a\b|] \ c, T.h, S.r)
                T.C1[i] = (T.Z[i] - mean(C.Z[|a\b|] \ T.Z[i], rw))^2
            }
            else T.C1[i] = (T.Z[i] - (Z-wi*T.Z[i])/(W-wi))^2
        }
        else break
    }
}

void Kmatch_cvo_i_MD(struct KmatchG scalar T, struct KmatchG scalar C, 
    real scalar i, real scalar a, real scalar b, real scalar t1, 
    real scalar c1, struct KmatchSet scalar S)
{
    real scalar    c, Z, W, wi
    real colvector p, w, fw, MD, rw
    
    // determine lower bound index of kernel window
    c = T.S[i]
    for (;a<=c1;a++) {
        if ((c-C.S[a])<T.h2) break
    }
    // determine upper bound index of kernel window
    if (a>=b) b = a + 1
    for (;b<=c1;b++) {
        if ((C.S[b]-c)>=T.h2) {
            b--; break
        }
    }
    if (b>c1) b = c1
    // compute multivariate distance
    MD = Kmatch_MD2(T, i, C, (a,1 \ b,.), S)
    // select controls within kernel window
    p = selectindex(MD:<max((T.h^2,smallestdouble())))
    MD = MD[p]
    p = (a::b)[p]
    // check whether at least one additional obs in window
    if (length(p)==1) {
        if (C.fw[p]==1) return
    }
    // compute kernel weights
    MD = sqrt(MD)
    w = (*S.K)(MD/T.h)
    if (S.w==1) w = w :* C.w[p]
    fw = C.fw[p]
    // compute counterfactuals
    wi = (*S.K)(0)
    if (S.w==1) {
        wi = wi * T.w[i]
        T.C2[i] = T.w[i] :* T.fw[i]
    }
    else T.C2[i] = T.fw[i]
    if (S.r<.) {
        rw = Kmatch_cvo_Ridge(w \ wi, fw \ -1, 0, MD \ 0, T.h, S.r)
        T.C1[i] = (T.Z[i] - mean(C.Z[p] \ T.Z[i], rw))^2
    }
    else {
        Z = quadsum(C.Z[p]:*w:*fw)
        W = quadsum(w:*fw)
        T.C1[i] = (T.Z[i] - (Z-wi*T.Z[i])/(W-wi))^2
    }
    // skip ties
    while (i<t1) {
        if (T.X[i+1,]==T.X[i,]) {
            i++
            if (S.w==1) {
                wi = (*S.K)(0) * T.w[i]
                T.C2[i] = T.w[i] :* T.fw[i]
            }
            else T.C2[i] = T.fw[i]
            if (S.r<.) {
                if (S.w==1) rw = Kmatch_cvo_Ridge(w \ wi, fw \ -1, 0, MD \ 0,
                    T.h, S.r)
                T.C1[i] = (T.Z[i] - mean(C.Z[p] \ T.Z[i], rw))^2
            }
            else T.C1[i] = (T.Z[i] - (Z-wi*T.Z[i])/(W-wi))^2
        }
        else break
    }
}

real colvector Kmatch_cvo_Ridge(real colvector w, real colvector fw, 
    real scalar pi, real colvector pj, real scalar h, real scalar r)
{
    real scalar    W, P, S, d, c
    real colvector wfw, D
    
    wfw = w :* fw
    if (diag0cnt(invsym(variance(pj)))) { // check for collinearity
        return(wfw / quadsum(w:*fw))
    }
    W = quadsum(wfw)
    P = quadsum(pj :* wfw) / W
    D = pj:-P
    S = quadsum(D:^2 :* wfw)
    d = pi-P
    c = r * h * abs(d)
    return(wfw / W + wfw :* D * (d / (S + c)))
}

real scalar Kmatch_MD_h2(real scalar h0, real scalar r)
{
    real scalar h
    
    h = sqrt(h0^2 / r) * r
    h = h + epsilon(h) // take account of roundoff error
    if (h>=. | h<=0) h = smallestdouble()
    return(h)
}

real colvector Kmatch_MD2(struct KmatchG scalar T, real scalar i, 
    struct KmatchG scalar C, real matrix r, struct KmatchSet scalar S) 
{
    real matrix Xm
    
    if (S.mdmethod==0) {
        Xm = C.X[|r|]:-T.X[i,]
        return(rowsum((Xm * S.Vinv) :* Xm, 1))
    }
    if (S.mdmethod==1) {
        return(rowsum((C.X[|r|]:-T.X[i,]):^2, 1))
    }
    if (S.mdmethod==2) {
        return(C.XWX[|r|] - 2 * C.X[|r|] * (S.Vinv * T.X[i,]') :+ T.XWX[i,])
    }
}

real matrix Kmatch_epan(real matrix x)
{
    return((.75:-.75*x:^2):*(abs(x):<1))
}

real matrix Kmatch_rectangle(real matrix x)
{
    return(.5*(abs(x):<1))
    //return(.5*(round(abs(x),1e-8):<1)) // as in kdensity.ado, v2.3.6 26jun2000 (Stata 7)
} 

real matrix Kmatch_triangle(real matrix x)
{
    return((1:-abs(x)):*(abs(x):<1))
}
real matrix Kmatch_biweight(real matrix x)
{
    return(.9375*(1:-x:^2):^2:*(abs(x):<1))
}

real matrix Kmatch_triweight(real matrix x)
{
    return(1.09375*(1:-x:^2):^3:*(abs(x):<1))
}

real matrix Kmatch_cosine(real matrix x)
{
    return(.5*(1:+cos(pi()*x)):*(abs(x):<1))
} // rescaled to (-1,1)

real matrix Kmatch_parzen(real matrix x)
{
    return(((4/3:-8*x:^2+8*abs(x):^3):*(abs(x):<=.5)) +
        ((8*(1:-abs(x)):^3/3):*(abs(x):>.5:&abs(x):<1)))
}

/*
real colvector Kmatch_regress(real colvector y, real colvector w, real matrix X)
{
    real scalar     ymean, intercept
    real colvector  ybar, p, Xy, beta, b
    real rowvector  means
    real matrix     Xbar, XX, S
    
    // 0. no covariates
    
    if (cols(X)==0) return(mean(y, w))
    
    // Bill Gould, 22.9.2015:
    //
    // Here's what -regress- does:
    //
    // First, -regress- uses separate code for models with an intercept and
    // those without.  I will discuss only models with an intercept.  There's
    // not as much one can do to calculate models without an intercept
    // accurately.
    //
    // Let matrix X and vector y be the data, excluding missing values.
    //
    // Our goal is to calculate b = invsym(X'X)*(X'y) and s^2*(X'X), but to do
    // so accurately.
    //
    // There are two things we are going to do to obtain accurate results:
    //
    //     1.  Use X and y in mean-deviated form.
    //
    //     2.  Use LU decomposition (backsolver) to obtain beta from
    //         X'X and X'y.
    //
    // We will then have to patch things up to add an extra parameter (the
    // intercept) to the coefficient vector and variance matrix.
    //
    // Using mean-deviated form causes an extra problem at the outset, too.
    // Somehow, we have to detect the collinear variables and remove them
    // because LU decomposition requires X'X be full rank..
    //
    // The solution to that problem is to calculate invsym(X'X) (X deviated), and
    // then examine the result to determine which variables were omitted.
    // invsym() handles collinearity by omitting variables (columns), so we can
    // identify the collinear variables, temporarily remove them
    // to do the bulk of the calculation, and put everything back together
    // when we are finished.
    //
    //
    // Regress proceeds as follows:
    //
    // First, X has p-1 columns, not p.  We DO NOT add a columns of 1s (_cons)
    // as an extra last column to X.
    //
    // Our first problem is to omit the collinear variables from the calcuation:
    //
    //     1.  Calculate mean-removed XX = X'X.
    //
    //         1.1  First get accurate column means of X, use quadsum().
    //
    //         1.2  Form Xbar = X :- means.  There is no gain to be had from
    //              doing this calculation in quad precision.
    //
    //         1.3  Don't bother to form mean removed ybar = y yet.
    //
    //         1.4  Obtain XX = Xbar'Xbar using quadcross().
    
    means = mean(X, w) // mean() uses quad precision
    Xbar = X :- means
    XX = quadcross(Xbar, w, Xbar)
    
    //     2.  Calculate S = invsym(XX).  We will NOT use S to obtain beta.
    //         We will use S to detect to remove collinear variables, and we
    //         will use S as an ingredient to obtaining the variance matrix
    //         of beta, and hence the SEs.
    
    S = invsym(XX)
    
    //     3.  Remove collinear variables; S[i,i]==0 for collinear variables.
    //
    //         3.1  Drop columns from Xbar for which S[i,i]==0.
    //
    //         3.2  Drop rows and columns from XX for which S[i,i]==0.
    //
    //         3.3  Drop rows and columns for S for which S[i,i]==0.
    
    p = select(1::cols(X), diagonal(S):!=0)
    if (length(p)>0) {
        Xbar = Xbar[,p]
        XX = XX[p,p]
        means = means[p]
        //S = S[p,p]
    }
    
    //     4.  Form Xy = mean removed X'y.
    //
    //         4.1  We already have X with means removed.
    //
    //         4.2  Form ybar = mean removed y.  Do that the standard way
    //              quadsum(y), divide by rows(X), and ybar = y :- ymean.
    //
    //         4.3  Form Xy = mean removed X'y.  We already have Xbar and ybar.
    //              Use quadcross().
    
    ymean = mean(y, w) 
    ybar = y :- ymean
    Xy = quadcross(Xbar, w, ybar)
    
    //     5.  Form beta.  Use lusolve() on XX and Xy.
    //         At this point, beta is whoppingly accurate.
    
    beta = lusolve(XX, Xy)
    
    //     6.  Form the mean-removed predictions yhat = X*beta.  This may be done
    //         ion double precision.
    //
    //     7.  Calculate the intercept.
    //         Quad precision, please.

    intercept = ymean - quadcross(means', beta)
    
    //     8.  Calculate error sum of squares (ESS), which is sum of (y-yhat)^2.
    //         Quad precision, please.
    //
    //     9.  Calculate s^2, the variance of the residual.
    //
    //    10.  Add a row and column to S containing covaraiances and variance
    //         of the intercept.  I've forgotten the formulas.
    //         At this point (s^2)*S is
    //         the variance matrix excluding the intercept.  We just need to
    //         add another row and column.
    //
    //    11.  Finally, you have to insert the 0s into the coefficient vector
    //         and 0 rows and columns into S to account for the omitted variables.
    
    b = J(cols(X), 1, 0)
    b[p] = beta
    return((b \ intercept))
}
*/

// renamed copy of mm_quantile() from -moremata-
real matrix Kmatch_quantile(real matrix X, | real colvector w,
 real matrix P, real scalar altdef)
{
    real rowvector result
    real scalar c, cX, cP, r, i

    if (args()<2) w = 1
    if (args()<3) P = (0, .25, .50, .75, 1)'
    if (args()<4) altdef = 0
    if (cols(X)==1 & cols(P)!=1 & rows(P)==1)
     return(Kmatch_quantile(X, w, P', altdef)')
    if (missing(P) | missing(X) | missing(w)) _error(3351)
    if (rows(w)!=1 & rows(w)!=rows(X)) _error(3200)
    r = rows(P)
    c = max(((cX=cols(X)), (cP=cols(P))))
    if (cX!=1 & cX<c) _error(3200)
    if (cP!=1 & cP<c) _error(3200)
    if (rows(X)==0 | r==0 | c==0) return(J(r,c,.))
    if (c==1) return(_Kmatch_quantile(X, w, P, altdef))
    result = J(r, c, .)
    if (cP==1) for (i=1; i<=c; i++)
     result[,i] = _Kmatch_quantile(X[,i], w, P, altdef)
    else if (cX==1) for (i=1; i<=c; i++)
     result[,i] = _Kmatch_quantile(X, w, P[,i], altdef)
    else for (i=1; i<=c; i++)
     result[,i] = _Kmatch_quantile(X[,i], w, P[,i], altdef)
    return(result)
}

real colvector _Kmatch_quantile(
 real colvector X,
 real colvector w,
 real colvector P,
 real scalar altdef)
{
    real colvector g, j, j1, p
    real scalar N

    if (w!=1) return(_Kmatch_quantilew(X, w, P, altdef))
    N = rows(X)
    p = order(X,1)
    if (altdef) g = P*N + P
    else g = P*N
    j = floor(g)
    if (altdef) g = g - j
    else g = 0.5 :+ 0.5*((g - j):>0)
    j1 = j:+1
    j = j :* (j:>=1)
    _editvalue(j, 0, 1)
    j = j :* (j:<=N)
    _editvalue(j, 0, N)
    j1 = j1 :* (j1:>=1)
    _editvalue(j1, 0, 1)
    j1 = j1 :* (j1:<=N)
    _editvalue(j1, 0, N)
    return((1:-g):*X[p[j]] + g:*X[p[j1]])
}

real colvector _Kmatch_quantilew(
 real colvector X,
 real colvector w,
 real colvector P,
 real scalar altdef)
{
    real colvector Q, pi, pj
    real scalar i, I, j, jj, J, rsum, W
    pointer scalar ww

    I  = rows(X)
    ww = (rows(w)==1 ? &J(I,1,w) : &w)
    if (altdef) return(_Kmatch_quantilewalt(X, *ww, P))
    W  = quadsum(*ww)
    pi = order(X, 1)
    if (anyof(*ww, 0)) {
        pi = select(pi,(*ww)[pi]:!=0)
        I = rows(pi)
    }
    pj = order(P, 1)
    J  = rows(P)
    Q  = J(J, 1, .)
    j  = 1
    jj = pj[1]
    rsum = 0
    for (i=1; i<=I; i++) {
        rsum = rsum + (*ww)[pi[i]]
        if (i<I) {
            if (rsum<P[jj]*W) continue
            if (X[pi[i]]==X[pi[i+1]]) continue
        }
        while (1) {
            if (rsum>P[jj]*W | i==I) Q[jj] = X[pi[i]]
            else Q[jj] = (X[pi[i]] + X[pi[i+1]])/2
            j++
            if (j>J) break
            jj = pj[j]
            if (i<I & rsum<P[jj]*W) break
        }
        if (j>J) break
    }
    return(Q)
}

real colvector _Kmatch_quantilewalt(
 real colvector X,
 real colvector w,
 real colvector P)
{
    real colvector Q, pi, pj
    real scalar i, I, j, jj, J, rsum, rsum0, W, ub, g

    W  = quadsum(w) + 1
    pi = order(X, 1)
    if (anyof(w, 0)) pi = select(pi, w[pi]:!=0)
    I  = rows(pi)
    pj = order(P, 1)
    J  = rows(P)
    Q  = J(J, 1, .)
    rsum = w[pi[1]]
    for (j=1; j<=J; j++) {
        jj = pj[j]
        if (P[jj]*W <= rsum) Q[jj] = X[pi[1]]
        else break
    }
    for (i=2; i<=I; i++) {
        rsum0 = rsum
        rsum = rsum + w[pi[i]]
        if (i<I & rsum < P[jj]*W) continue
        while (1) {
            ub = rsum0+1
            if (P[jj]*W>=ub | X[pi[i]]==X[pi[i-1]]) Q[jj] = X[pi[i]]
            else {
                g = (ub - P[jj]*W) / (ub - rsum0)
                Q[jj] = X[pi[i-1]]*g + X[pi[i]]*(1-g)
            }
            j++
            if (j>J) break
            jj = pj[j]
            if (i<I & rsum < P[jj]*W) break
        }
        if (j>J) break
    }
    return(Q)
}

end
exit


