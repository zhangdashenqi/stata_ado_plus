*! version 0.2.3 13Apr2005
*  version 0.2.2 03Mar2005 cloglog
*  version 0.2.1 19Feb2005 zt
*  version 0.2.0 03Feb2005

//  simply check if last command was valid for spost

capture program drop _pecmdcheck
program define _pecmdcheck, rclass
    version 8
    args spostcmd
    local io ""
    * 03Mar2005 zt models added
    if "`e(cmd)'"=="ztp"  {
        local io "typical count"
    }
    if "`e(cmd)'"=="ztnb"  {
        local io "typical count"
    }
    if "`e(cmd)'"=="cloglog"  {
        local io "typical binary"
    }
    if "`e(cmd)'"=="cnreg"    {
        local io "typical tobit"
    }
    if "`e(cmd)'"=="fit"      {
        local io "typical regress"
    }
    if "`e(cmd)'"=="gologit"  {
        local io "typical ordered"
    }
    if "`e(cmd)'"=="intreg"   {
        local io "typical tobit"
    }
    if "`e(cmd)'"=="logistic" {
        local io "typical binary"
    }
    if "`e(cmd)'"=="logit"    {
        local io "typical binary"
    }
    if "`e(cmd)'"=="mlogit"   {
        local io "typical nominal"
    }
    if "`e(cmd)'"=="nbreg"    {
        local io "typical count"
    }
    if "`e(cmd)'"=="ologit"   {
        local io "typical ordered"
    }
    if "`e(cmd)'"=="oprobit"  {
        local io "typical ordered"
    }
    if "`e(cmd)'"=="poisson"  {
        local io "typical count"
    }
    if "`e(cmd)'"=="probit"   {
        local io "typical binary"
    }
    if "`e(cmd)'"=="regress"  {
        local io "typical regress"
    }
    if "`e(cmd)'"=="tobit"    {
        local io "typical tobit"
    }
    if "`e(cmd)'"=="zinb"     {
        local io "twoeq count"
    }
    if "`e(cmd)'"=="zip"      {
        local io "twoeq count"
    }
    if "`io'"=="" {
        di as error _new ///
            "`spostcmd' does not work for the last type of model estimated."
    }
    return local io = "`io'"

end
