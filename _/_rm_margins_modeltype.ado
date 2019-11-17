*! version 1.0.0 2014-02-14 | long freese | spost13 release

//  type of model to determine what margins will compute
//
//  the options allowed by -predict- are used to classify the type of model
//
//      predict allows      model type      examples
//      ------------------  --------------  -----------
//      outcome()           discrete        mlogit
//      pr()                count           poisson
//      outcome() & pr      binary          logit
//                          other

program define _rm_margins_modeltype, sclass

    syntax , [ force ]
    tempname TestPredict DefaultPredict

    qui predict `DefaultPredict'

    qui sum `e(depvar)'
    local MinValue = r(min)
    capture qui predict `TestPredict', outcome(`MinValue')

    if (_rc==0) local modeltype "discrete" // outcome(#) allowed

    else {
        capture qui predict `TestPredict', pr(`MinValue')
        if (_rc==0) local modeltype "count" // pr(#) allowed
        * in case non integer count
        if (_rc==198 & "`force'"=="force") local modeltype "count"
    }

    if "`modeltype'" == "" {
        capture qui predict `TestPredict', pr
        if _rc == 0 { // allows pr and pr is matches default
            if (`TestPredict'==`DefaultPredict') local modeltype "binary"
        }
    }

    if "`modeltype'"=="" local modeltype "other"
    sreturn clear
    sreturn local modeltype "`modeltype'"

end
exit

_rm_margins_modeltype
local modeltype "`s(modeltype)'"
