*! version 1.0.0 2014-02-14 | long freese | spost13 release

//  return names of pw comparisons from RHS variable of factor type

program define _rm_pwnames, sclass

    syntax , VARnm(string) [ NOISily]
    qui `noisily' pwcompare `varnm'
    tempname pwmat prmat
    matrix `pwmat' = r(table_vs) // pw contrasts
    local npw = colsof(`pwmat')
    matrix `prmat' = r(table)
    local npwcats colsof(`prmat')

    local pwcolnms : colnames(`pwmat')
    forvalues ipw = 1/`npw' {
        _ms_element_info, element(`ipw') matrix(`pwmat') compare
        * pw name using value labels
        sreturn local txtlabel`ipw' `"`r(level)'"'
        * pw name using category #'s
        local pwvalues : word `ipw' of `pwcolnms'
        local pwvalues : subinstr local pwvalues ".`varnm'" "", all
        local pwvalues : subinstr local pwvalues "bn" "", all
        sreturn local numlabel`ipw' "`pwvalues'"
        local tmp : subinstr local pwvalues "vs" " ", all
        * T and F numbers
        local pwFrom : word 2 of `tmp'
        sreturn local from`ipw' = `pwFrom'
        local pwTo : word 1 of `tmp'
        sreturn local to`ipw' = `pwTo'
    } // ipw loop
    sreturn local npw = `npw'
    sreturn local nvarcats = `npwcats'
end
exit
