*! version 1.0.0 2014-02-14 | long freese | spost13 release

//  sreturns with information about the last margins command

program define _rm_marginsinfo, sclass

	version 11.2

	local cmdnm "`r(cmd)'"
	local ecmdnm "`e(cmd)'"
    local cmdline "`r(cmdline)'"
    local ipos : list posof "`post'" in cmdline
    local cmdpost = 0
    if `ipos'>0 local cmdpost = 1
	local cmdn = r(N)

    local explabel "`r(predict_label)'"
    local expression "`r(expression)'"
    local expwork : subinstr local expression "predict(" "", all
    local nexp = length("`expwork'")-1
    local expwork = substr("`expwork'",1,`nexp')

    local expdydx "`r(derivatives)'"
    local expdydxsource "`expdydx'"
    if "`expdydx'"!="" local expdydx : subinstr local expdydx "/" "", all

    local iscpr = 0
    if "`expwork'"=="pr" {
        local expshort "pr"
        local explong "pr0"
    }
    else if "`expwork'"=="ir" {
        local expshort "ir"
        local explong "inrate"
    }
    else if "`expwork'"=="cm" {
        local expshort "cm"
        local explong "condmn"
    }
    else if "`expwork'"=="xb" {
        local expshort "xb"
        local explong "linpred"
    }
    else {
        local iscpr = strpos("`expwork'","cpr(")
        local iscpr = `iscpr'>0
        local ispr = strpos("`expwork'","pr(")
        local ispr = `ispr'>0
        if `iscpr' local ispr = 0
        local iscomma = strpos("`expwork'",",")
        local iscomma = `iscomma'>0
        if `ispr' & `iscomma'==0 {
            local expshort "pr"
            local explong "pr"
        }
        if `ispr' & `iscomma' {
            local expshort "prij"
            local explong "pr_ij"
        }
        if `iscpr' & `iscomma'==0 {
            local expshort "cpr"
            local explong "condpr"
        }
        if `iscpr' & `iscomma' {
            local expshort "cprij"
            local explong "cpr_ij"
        }
    }

    if "`expshort'"=="" {
        local ispr = strpos("`explabel'","Pr(")
        local ispr = `ispr'>0
        if `ispr' {
            local expshort "pr"
            local explong "pr"
        }
        local islp = strpos("`explabel'","Linear prediction")
        local islp = `islp'>0
        if `islp' {
            local expshort "xb"
            local explong "linpred"
        }
        local islp = strpos("`explabel'","Predicted number of events")
        local islp = `islp'>0
        if `islp' {
            local expshort "mu"
            local explong "mu"
        }
     }

    local expname "`explong'"
    if ("`expdydx'"!="") local expname "`expdydx'"
    if (`iscpr') local expname "`expshort'"

//  get rid of numbers

    local expression = regexr("`expression'","[0-9]","")
    local explabel = regexr("`explabel'","[0-9]","")

//  expand dydx

    local expdydxlong ""
    if "`expdydx'"!= "" {
        local nm "`explabel'"
        local expdydxlong : subinstr local expdydxsource "dy" "d_`nm'", all
        local expdydxlong : subinstr local expdydxlong "dx" "d_x", all
    }

//  returns

    sreturn local expression "`expression'"
	sreturn local explabel "`explabel'"
    sreturn local expshort "`expshort'"
    sreturn local explong "`explong'"
    sreturn local expdydx "`expdydx'"
    sreturn local expdydxlong "`expdydxlong'"
    sreturn local expname "`expname'"

    foreach o in exp explabel expshort explong expdydx expdydxlong expname {
*        di "`o': " _col(15) "``o''"
    }

end
exit

local expression "`s(expression)'"
local explabel "`s(expshort)'"
local expshort "`s(expshort)'"
local explong "`s(explong)'"
local expdydx "`s(expdydx)'"
local expdydx "`s(expname)'"

