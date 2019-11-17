*! version 1.1.0 2014-02-14 | long freese | spost13 release

//  names and number of rhs variables in eq 1 and 2 of model
//
//      _rm_rhsnames rhsNMS1 rhsN1 rhsNMS2 rhsN2

program define _rm_rhsnames

    version 11.2
    args rhsNMS1 rhsN1 rhsNMS2 rhsN2

    local cmd "`e(cmd)'"
    local RHSnmsALL : colnames e(b)
    local RHSnmsALL : subinstr local RHSnmsALL "_cons" " ", all // ologit etc

    if "`cmd'"=="mlogit" | "`cmd'"=="mprobit" {
        local RHSnmsALL : subinstr local RHSnmsALL "o. " "", all // mlogit
        if (e(ibaseout)==1 | e(i_base)==1) local enum 2 // mlogit
        else local enum 1
        _ms_extract_varlist `RHSnmsALL', noomit eq(#`enum') nofatal
        local RHSnms1 "`r(varlist)'"
        local RHSn2 = 0
        local RHSnms2 ""
        local RHSn1 : word count `RHSnms1'
    }
    else {
        * zip and zinb have two equations
        local eqns = 1 + cond("`cmd'"=="zip" | "`cmd'"=="zinb",1,0)
        forvalues i = 1/`eqns' {
            if `eqns' == 1 _ms_extract_varlist `RHSnmsALL', noomit
            else  _ms_extract_varlist `RHSnmsALL', noomit eq(#`i') nofatal
            local RHSnms`i' `r(varlist)'
              local RHSn`i' : word count `RHSnms`i''
        }
    } // not mlogit

    c_local `rhsNMS1'    "`RHSnms1'"
    c_local `rhsN1'      `RHSn1'
    c_local `rhsNMS2'    "`RHSnms2'"
    c_local `rhsN2'      `RHSn2'

end
exit
