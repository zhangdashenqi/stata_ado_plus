*! version 1.0.1 2014-09-19 | long freese | remove space
* version 1.0.0 2014-02-14 | long freese | spost13 release

//  parses predict() expression() post `options' from m* commands
//
//  sreturn local expressionused : is exp() used
//  sreturn local predictused    : is predict() used
//  sreturn local marginsoptions : options for margins

program define _rm_margins_parse_options, sclass

    syntax , [ post PRedict(string asis) EXPression(string asis) * ]

    if "`predict'" != "" {
        local predict_opt "predict(`predict')"
        local predictused = 1
    }
    else local predictused = 0

    if "`expression'" != "" {
        local expression_opt "expression(`expression')"
        local expressionused = 1
    }
    else local expressionused = 0

    sreturn clear
    sreturn local expressionused "`expressionused'"
    sreturn local predictused "`predictused'"
    local marginsoptions ///
        "`options' `predict_opt' `expression_opt' `post'"
    local marginsoptions : subinstr local marginsoptions " )" ")", all
    sreturn local marginsoptions `marginsoptions'
end
exit
