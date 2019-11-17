*! version 1.1.3 2014-08-14 | long freese | non-estimable allowed
 * version 1.1.2 2014-08-12 | long freese | make drop exact
 * version 1.1.1 2014-07-29 | long freese | meanpred isatconstant
 * version 1.1.0 2014-07-29 | long freese | r(table)

//  generate variables from margins

program define mgen, rclass

    version 11.2

    if _caller() >= 12 {
        local VERSION : display "version " string(_caller()) ":"
    }

    syntax [name] [if] [in] , [ ///
        replace /// replace if variables exist
        DETAILs VERBose COMMANDs brief ///
        ALLSTats NOCI MEANPred force /// for count on non-integer
        STATS(string) STATistics(string) ///
        ATVars(string asis) /// select r(at) variables
        OUTcome(string) cpr(string) pr(string) /// predict(xxx(*))
        stub(string asis) /// stub used for names of variables
        VALUELength(numlist >0 integer) /// length of value label stub
        PREDName(string asis) /// allow override of margin name
        PREDLabel(string asis) /// label for naming margin
        NOLabel * ] // passthru to margins

    tempvar Pred
    tempname atconstant

    if "`e(cmd)'"=="" {
        display as error "no regression estimates are in memory"
        exit
    }
    else if "`e(cmd)'"=="ztnb" | "`e(cmd)'"=="ztp" {
        display as error "use tpoisson or tnbreg instead of ztp or ztnb"
        exit
    }

//  process options

    if ("`stats'"=="" & "`statistics'"!="") local stats "`statistics'"

    local quicmd "quietly" // listing of command
    if ("`commands'"=="commands") local quicmd "noisily"
    if ("`verbose'"=="verbose") local details "details"
    local quimar "quietly"
    if "`details'" == "details" {
        local quimar "noisily"
        local quicmd "noisily"
    }
    if ("`replace'"=="replace") local isreplace = 1
    else local isreplace = 0
    if ("`nolabel'"=="") local uselabels = 1
    else local uselabels = 0
    if ("`stub'"=="") local stub "_"

    if ("`stats'"=="all") local allstats "allstats" // allow stats(all)
    if ("`stats'"=="noci") local noci "noci" // allow stats(noci)
    if ("`allstats'"!="" & "`noci'"!="") {
        display as error "allstats and noci cannot be used together"
        exit
    }
    local ismeanpred = "`meanpred'"=="meanpred"
    local isatspec = strpos("`options'","at(") > 0
    local isover = strpos("`options'","over(") > 0
    if !`isatspec' & !`ismeanpred' & !`isover' {
        display as error "either at(), over(), or meanpred must be specified"
        exit
    }

//  model and margins information

    _rm_margins_modeltype // binary, discrete, count, other
    local modeltype "`s(modeltype)'"
    if ("`modeltype'"=="discrete" & "`outcome'"=="") local outcome "*"
    if "`outcome'"=="*" | "`outcome'"=="_all" {
        qui levelsof `e(depvar)' if e(sample)==1, local(outcome)
    }

    _rm_margins_parse_options, `options' `post'
    local isMpred = `s(predictused)'
    local isMexp = `s(expressionused)'
    local Moptions "`s(marginsoptions)'"

    if ("`noci'"=="noci") local Moptions "`Moptions' nose"
    local isnose = strpos("`Moptions'","nose")>0
    if `isnose'==1 {
        if "`noci'"=="" | "`allstats'"=="allstats" {
            display "note: with nose option, only estimates can be computed"
        }
        local noci "noci"
        local allstats ""
    }

    * if exp() or predict(), this dominates what is computed
    if `isMexp' | `isMpred' {
        local iscpr = 0
        local ispr = 0
    }
    * without exp() or predict(), check margins options
    else {
        _rm_margins_parse_predict, `options' modeltype(`modeltype') ///
            outcome(`outcome') cpr(`cpr') pr(`pr')
        if `s( iserror)' exit
        local outcomes "`s(outcomes)'"
        local iscpr = `s(iscpr)'
        local ispr = `s(ispr)'
        local predictform `"`s(predictform)'"'
        * allow meanpred for brm
        if ("`modeltype'"=="binary" & "`outcomes'"=="") local outcomes "1"
    }
    local _MGenOpts "statoptions(`noci'`allstats') predlabel(`predlabel')"

//  if outcome() not specified, then only execute once

    if "`outcomes'" == "" { // no outcomes selected
        local Mcmd "margins `if' `in', `Moptions'"
        _rm_margins_clean_cmd `Mcmd'
        local Mcmd `"`s(cmd)'"'
        `quicmd' display _new "Command: `Mcmd'"
        `quimar' `VERSION' `Mcmd'

        capture qui mlistat, saveconstant(`atconstant') // 1.0.4
        local isatconstant = `s(isconstant)'
        if ("`isatconstant'"=="") local isatconstant = 0 // 1.0.5

        local AtVarlist "`atvars'"
        if "`atvars'" == "" {
            capture _GetVaryingAtList
            local atvars_togen "`s(varyingat)'"
        }
        _MGen, stub(`stub') atvars(`atvars_togen') genatvars(1) ///
            `_MGenOpts' predname(`predname') `replace'
        local estlhsnum `"`s(estlhsnum)'"'
        local estname "`s(estname)'"
        if "`predlabel'" == "" {
            label var `stub'`estname' "`estlhsnum' from margins"
        }
        else label var `stub'`estname' "`predlabel'"
        local newvarnms "`newvarnms'`s(genvarnms_fv)' "
    }

//  at() used

    else if `isatspec' | `isover' {

        local docdf = 1
        if ("`modeltype'"=="binary") local docdf = 0
        if ("`modeltype'"=="discrete") local docdf = 1
        if "`modeltype'"=="count" { // must be sequential
            local ncounts: word count `outcomes'
            local maxcount: word `ncounts' of `outcomes'
            local mincount: word 1 of `outcomes'
            if (`ncounts'!=(`maxcount'-`mincount')+1) local docdf = 0
        }

        local firsttime = 1
        local newvarnms ""
        local newprvarnms "" // used for cum prob
        foreach outval of numlist `outcomes' {

            local predict : subinstr local predictform "XX" "`outval'"
            if ("`modeltype'"=="binary") & (`outval'==0) {
                local predict = "exp(1-`predictform')"
            }

            local Mcmd "margins `if' `in', `Moptions' `predict'"
            _rm_margins_clean_cmd `Mcmd'
            local Mcmd `"`s(cmd)'"'
            `quicmd' display _new "Command: `Mcmd'"
            `quimar' `VERSION' `Mcmd'

            capture qui mlistat, saveconstant(`atconstant') // 1.0.4
            local isatconstant = `s(isconstant)'
            if ("`isatconstant'"=="") local isatconstant = 0 // 1.0.5

            local atvars_togen "`atvars'"
            if "`atvars'" == "" {
                capture _GetVaryingAtList
                local atvars_togen "`s(varyingat)'"
            }
            local vallabelnm : value label `e(depvar)'
            local outlabel ""
            if "`vallabelnm'" != "" {
                local outlabel : label `vallabelnm' `outval' `valuelength'
            }
            else local outlabel `outval'

            _MGen, stub(`stub') `_MGenOpts' predname(`predname') ///
                    atvars(`atvars_togen') genatvars(`firsttime') ///
                    outvalue(`outval') outlabel(`outlabel') ///
                    uselabels(`uselabels') `replace'
            local estname "`s(estname)'"
            local newvarnms "`newvarnms'`s(genvarnms_fv)' "
            local firsttime = 0

            if `docdf' { // generate cumulative probabilities
                local newprvarnm "`stub'`estname'`outval'"
                local newprvarnms "`newprvarnms'`newprvarnm' "
                local newCvarnm "`stub'C`estname'`outval'"
                if `isreplace' capture drop `newCvarnm'
                qui egen `newCvarnm' = rsum(`newprvarnms') if `newprvarnm' < .
                local newvarnms "`newvarnms'`newCvarnm' "

                if `firsttime' label var `newCvarnm' "pr(y=`outval')"
                else label var `newCvarnm' "pr(y<=`outval')"
                if "`outlabel'"!="" & `uselabels' {
                    if `firsttime' label var `newCvarnm' "pr(y=`outlabel')"
                    else label var `newCvarnm' "pr(y<=`outlabel')"
                }
            }
            local icatnm "`outval'"
            if ("`outlabel'"!="" & `uselabels') local icatnm `outlabel'
            if "`predlabel'" == "" {
                label var `stub'`estname'`outval' ///
                    "`estname'(y=`icatnm') from margins"
            }
            else label var `stub'`estname'`outval' "`predlabel'"
        } // over variables
    } // atmatrix exists

//  mean predictions

    if "`meanpred'" != "" {

        if `ismeanpred' local isatconstant = 0 // 1.1.0
        qui {
            local prstub "pr"
            local prlbl "Pr(y=#)"
            if `iscpr' {
                local pr "cpr"
                local prlbl "Pr(y=#|y>0)"
            }
            if `isreplace' {
                capture drop `stub'val
                capture drop `stub'obeq
                capture drop `stub'oble
                capture drop `stub'`prstub'eq
                capture drop `stub'`prstub'le
                capture drop `stub'ob_`prstub'
                capture drop `stub'`prstub'eq
                capture drop `stub'`prstub'le
            }
            gen `stub'val = .
            label var `stub'val "`e(depvar)'"
            gen `stub'obeq = .
            label var `stub'obeq "Observed proportion"
            gen `stub'oble = .
            label var `stub'oble "Observed cum. proportion"
            gen `stub'`prstub'eq = .
            label var `stub'`prstub'eq "Avg predicted `prlbl'"
            gen `stub'`prstub'le = .
            label var `stub'`prstub'le "Avg predicted cum. `prlbl'"
            gen `stub'ob_pr = .
            label var `stub'ob_`prstub' "Observed - Avg `prlbl'"
            local newvarnms "`newvarnms' `stub'val `stub'obeq `stub'oble "
            local newvarnms "`newvarnms' `stub'`prstub'eq `stub'`prstub'le"
            local newvarnms "`newvarnms' `stub'ob_`prstub' "
        }

        local lhsvarlab : variable label `e(depvar)'
        if (`uselabels' & "`lhsvarlab'"!="") label var `stub'val "`lhsvarlab'"

        local Row = 0
        foreach outval of numlist `outcomes' {
            local ++Row
            if `Row'>`c(N)' {
                display as error ///
                "set obs # must equal or exceed the number of outcome values"
                exit
            }
            qui replace `stub'val = `outval' in `Row'
            qui count if `e(depvar)'==`outval' & e(sample)==1
            local ObsFreq = r(N)
            qui count if e(sample)==1
            local TotalN = r(N)
            local ObsProb = `ObsFreq'/`TotalN'
            qui replace `stub'obeq = `ObsProb' in `Row'

            qui sum `stub'obeq // missing in rows for higher counts
            qui replace `stub'oble = r(sum) in `Row'

            local predict : subinstr local predictform "predict(" ""
            local predict : subinstr local predict "XX" "`outval'"
            local predict : subinstr local predict ")" ""
            qui {
                predict `Pred' if e(sample), `predict'
                sum `Pred'
                replace `stub'`prstub'eq = r(mean) in `Row'
                sum `stub'`prstub'eq
                replace `stub'`prstub'le = r(sum) in `Row'
                replace `stub'ob_`prstub' = `stub'obeq - `stub'`prstub'eq
            }
            drop `Pred'
        } // close loop outcomes

    } // if plot option

//  close up and summarize

    local newvarnms : list uniq newvarnms
    if "`brief'"=="" {

        local Mcmd2 = regexr("`Mcmd'","outcome\([0-9]*\)","outcome()")
        display _new "Predictions from: `Mcmd2'"
        if ("`if'"!="" | "`in'"!="") ///
            display _new "Sample selection: `if' `in'"
        codebook `newvarnms', compact

        if (`isatconstant'!=0) matlist `atconstant', ///
            title("Specified values of covariates") names(col)
    }

    * r(table) with predictions
    tempvar nmiss
    tempname table
    local newvarsN = wordcount("`newvarnms'")
    egen `nmiss' = rowmiss(`newvarnms')
    * if all rows missing, don't add to matrix
    mkmat `newvarnms' if `nmiss'!=`newvarsN' , matrix(`table')

    return matrix table `table'
    return local newvars "`newvarnms'"

end

program define _GetVaryingAtList, sclass

    version 11.2
    tempname VaryingMatrix
    qui mlistat, savevarying(`VaryingMatrix')
    capture _return drop _temporary
    _return hold _temporary
    capture confirm matrix `VaryingMatrix'
    if (_rc==0) local ColumnNames : colnames `VaryingMatrix'
    _return restore _temporary
    sreturn local varyingat "`ColumnNames'"

end

program define _MGen, sclass

    version 11.2
    syntax , stub(string) [ replace statoptions(string) ///
        ATvars(string) genatvars(string) ///
        outvalue(string ) outlabel(string ) uselabels(string ) ///
        predname(string ) predlabel(string ) ]
    tempname table matgen matatgen atsrc keepvec

    if ("`genatvars'"!="1") local atvars "_none"
    local level = r(level)

    * atvars to generate
    local atoutnms ""
    capture confirm matrix r(at)
    if _rc==0 & "`atvars'"!="_none" {
        local isat = 1
        matrix `atsrc' = r(at)
    }
    else local isat = 0
    * stats #'s are columns in r(table)
    matrix `table' = r(table)' // margins estiamtes

    local isse = 0
    local isz = 0
    local isp = 0
    local isci = 0
    if "`statoptions'" == "" {
        local stats "1 5 6" // est ll ul
        local isci = 1
    }
    if ("`statoptions'"=="noci") local stats "1" // est
    if "`statoptions'"=="allstats" {
        local stats "1 2 3 4 5 6"
        local isse = 1
        local isz = 1
        local isp = 1
        local isci = 1
    }
    _rm_margins_names
    local isdydx = `s(isdydx)'
    local nm1 `"`s(estvarnonum)'"'
    local nm1 : subinstr local nm1 "any0" "any", all
    if (`"`predname'"'!="") local nm1 `"`predname'"'
    local nm2 "se"
    local nm3 "z"
    local nm4 "pval"
    local nm5 "ll"
    local nm6 "ul"

    _rm_matrix_noomitted `table' row // remove omitted variables

    * drop 0b. variables from dydx; after o. dropped
    if `isdydx' {
        local rnms : rowfullnames `table'
        local irow = 0
        foreach rnm in `rnms' {
            local ++irow
            local keepest = (strpos("`rnm'","0b.")==0)
            if `keepest' matrix `keepvec' = nullmat(`keepvec') \ `irow'
        }
        _rm_matrix_index `table' `keepvec' row
    }

    * select statistics from table
    foreach i in `stats' {
        matrix `keepvec' = `table'[1...,`i']
        matrix `matgen' = nullmat(`matgen') , `keepvec'
        local genvarnms `"`genvarnms' `stub'`nm`i''`outvalue'"'
    }

    if `isat' {
        if ("`atvars'"=="" | "`atvars'"=="_all") matrix `matatgen' = `atsrc'
        else { // select atvars
            local atnms : colnames `atsrc'
            foreach atnm of local atvars {
                local atloc : list posof "`atnm'" in atnms
                * check for factor variables
                if `atloc' == 0 {
                    qui levelsof `atnm', local(fvlevels)
                    foreach val in `fvlevels' {
                        local nob : list posof "`val'.`atnm'" in atnms
                        local b : list posof "`val'b.`atnm'" in atnms
                        local atloc = max(`nob',`b')
                        if `atloc'>0 {
                            matrix `keepvec' = `atsrc'[1..., `atloc']
                            matrix `matatgen' = nullmat(`matatgen'), `keepvec'
                        }
                        else {
                            display as error "`atnm' not in r(at) matrix"
                            exit
                        }
                    }
                }
                else {
                    matrix `keepvec' = `atsrc'[1...,`atloc']
                    matrix `matatgen' = nullmat(`matatgen') , `keepvec'
                }
            }
        }
        local atnms : colnames `matatgen'
        * names for generated variables
        foreach nm in `atnms' {
            local atoutnms "`atoutnms'`stub'`nm' "
        }
        local atoutnms : subinstr local atoutnms "." "_", all
        local genvarnms `"`genvarnms' `atoutnms'"'
        matrix `matgen' = `matgen' , `matatgen'

    }

//  create variables

    matrix colnames `matgen' = `genvarnms'
    if "`replace'"=="replace" {
        foreach varnm in `genvarnms' {
            capture drop `varnm'
        }
    }

    svmat `matgen', names(col)

//  label vars

    if `isci' {
        label var `stub'ul`outvalue' "`level'% upper limit"
        label var `stub'll`outvalue' "`level'% lower limit"
    }
    if `isse' label var `stub'se`outvalue' "std error of `nm1'"
    if `isp'  label var `stub'pval`outvalue' "p-value for test `nm1'=0"
    if `isz'  label var `stub'z`outvalue' "z-value for test `nm1'=0"

    if ("`predlabel'"!="") local estlbl "`predlabel'"
    else local estlbl "`nm1'"
    if ("`outvalue'"=="") label var `stub'`nm1' "`estlbl'"

    foreach atnm in `atnms' {
        if "`atnm'" != "_cons" {
            if strpos("`atnm'",".") == 0 { // not factor variable
                local atvarlabel : variable label `atnm'
                if ("`atvarlabel'"=="") label var `stub'`atnm' "`atnm'"
                else label var `stub'`atnm' "`atvarlabel'"
            }
        }
    }

//  convert factor variables 1.x 2.x to x containing integers

    local genvarnms_fv "`genvarnms'"
    foreach atnm in `atnms' {

        local DotSpot = strpos("`atnm'", ".")
        if `DotSpot' != 0 { // factor variable

            local fvVarName = substr("`atnm'", `DotSpot'+1, .)
            local fvValue = substr("`atnm'", 1, `DotSpot'-1)
            local fvValue = subinstr("`fvValue'", "b", "", .)
            local fvValue = subinstr("`fvValue'", "n", "", .) // 089

            if "`create`fvVarName''" == "" { // only gen variable once

                * drop x will drop xb too, so confirm name is exact match
                confirm new variable `stub'`fvVarName', exact
                if (_rc!=0) & ("`replace'"=="replace") {
                    capture drop `stub'`fvVarName'
                }
                qui gen `stub'`fvVarName' = .
                local create`fvVarName' "no"
                local genvarnms_fv "`genvarnms_fv' `stub'`fvVarName'"
                local atvarlabel : variable label `fvVarName'
                if "`atvarlabel'" == "" {
                    label var `stub'`fvVarName' "`fvVarName'"
                }
                else label var `stub'`fvVarName' "`atvarlabel'"
            }
            local atnm = subinstr("`atnm'", ".", "_", .)
            qui replace `stub'`fvVarName' = `fvValue' if `stub'`atnm' == 1
            drop `stub'`atnm'
            local genvarnms_fv : subinstr local genvarnms_fv "`stub'`atnm'" ""
        }
    } // atnms
    sreturn local estname "`nm1'"
    sreturn local estlhsnum `"`s(estLHSnum)'"'
    sreturn local genvarnms "`genvarnms'"
    sreturn local genvarnms_fv "`genvarnms_fv'"

end
exit

NOTES:

use _rm_margins_names for better labels of generated vars
verify that _GetVaryingAtList can be dropped
 * version 1.0.5 2014-07-29 | long freese | isatconstant if not atmeans
 * version 1.0.4 2014-07-26 | long freese | suspend non-estimable; list fixed
 * version 1.0.3 2014-06-28 | long freese | non-estimable margins functions
 * version 1.0.2 2014-05-30 | long freese | _caller()
 * version 1.0.1 2014-05-16 | long freese | trap no ecommand
 * version 1.0.0 2014-02-18 | long freese | spost13 release
