*! version 1.0.0 2014-02-14 | long freese | spost13 release

//  parse margins, predict() options from m* commands

program define _rm_margins_parse_predict, sclass

    version 11.2
    syntax , modeltype(string) [ outcome(string) cpr(string) pr(string) ///
        PRedict(string asis) EXPression(string asis) * ]

    * predict, expression and * are passthroughs to margins.
    * if expr() or predict() were used, they are evaluated below

    tempname testpred
    local iserror = 0
    foreach predtype in outcome pr cpr {
        if ("``predtype''"!="") local is`predtype' = 1
        else local is`predtype' = 0
        if `is`predtype'' {
            numlist "``predtype''", sort
            local `predtype' "`r(numlist)'"
            local outcomes "`r(numlist)'" // generic for loop over outcomes
            local firstout : word 1 of ``predtype''
            capture drop `testpred'
            * binary used default predict
            if "`modeltype'"!="binary" {
                capture predict `testpred', `predtype'(`firstout')
                if _rc!=0 {
                    display as error ///
                    "`predtype'() is not allowed with `e(cmd)'"
                    local iserror = 1
                    continue
                }
            }
        }
    }
    local isoutprcpr = `isoutcome' + `ispr' + `iscpr'

    if `isoutprcpr'>1 {
        display as error "outcome(), pr() and cpr() cannot be used together"
        local iserror = 1
    }

    if ("`predict'"!="") local ispredict = 1
    else local ispredict = 0
    if ("`expression'"!="") local isexpression = 1
    else local isexpression = 0
    if (`ispredict' | `isexpression') & `isoutprcpr' {
        display as error ///
        "predict() or expression() not allowed with outcome(), pr() or cpr()"
        exit
        local iserror = 1
    }

    local predictform ""
    local predictfirst ""
    if "`modeltype'"=="binary" {
        local predictform "predict(pr)"
        local predictfirst "predict(pr)"
    }
    else if "`modeltype'"=="discrete" {
        local predictform "predict(outcome(XX))"
        local out1 : word 1 of `outcome'
        local predictfirst "predict(outcome(`out1'))"
    }
    else if `iscpr' {
        local predictform "predict(cpr(XX))"
        local out1 : word 1 of `cpr'
        local predictfirst "predict(cpr(`out1'))"
    }
    else if `ispr' {
        local predictform "predict(pr(XX))"
        local out1 : word 1 of `pr'
        local predictfirst "predict(pr(`out1'))"
    }

    if ("`outcomes'"!="") local ismultiple = 1
    else local ismultiple = 0

    sreturn local iserror = `iserror'
    sreturn local outcomes "`outcomes'"
    sreturn local ismultiple = `ismultiple'
    sreturn local ispredict = `isoutprcpr'
    sreturn local isoutcome = `isoutcome'
    sreturn local iscpr = `iscpr'
    sreturn local ispr = `ispr'
    sreturn local predictform `"`predictform'"'
    sreturn local predictfirst `"`predictfirst'"'

end
exit

* `options' has passthru options for margins
_rm_margins_parse_predict, outcome(`outcome') cpr(`cpr') pr(`pr') ///
    `options' modeltype(`modeltype')
local iserror `s( iserror)'
local outcomes "`s(outcomes)'"
local ismultiple = `s(ismultiple)'
local ispredict = `s(isoutprcpr)'
local isoutcome = `s(isoutcome)'
local iscpr = `s(iscpr)'
local ispr = `s(ispr)'
local predictform `"`s(predictform)'"'
local predictfirst `"`s(predictfirst)'"'
