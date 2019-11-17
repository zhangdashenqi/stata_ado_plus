*! version 1.0.0 2014-02-14 | long freese | spost13 release

//  sreturns names of predictions from margins

program define _rm_margins_names, sclass

    version 11.2
    local lhsnm "`e(depvar)'"
    if ("`e(cmd)'"=="zip" | "`e(cmd)'"=="zinb") local iszi = 1
    else local iszi = 0

    * M signifies info as is from margins
    local Mexpression "`r(expression)'"
    local Mpredict_label "`r(predict_label)'"
    local Mderivatives "`r(derivatives)'"

    if "`Mderivatives'"=="dy/dx" local isdydx = 1
    else local isdydx = 0
    local xvars "`r(xvars)'"
    local xvarsN = wordcount("`xvars'")

//  defaults used if not customized below

    local marginstitlenonum "`Mpredict_label', `Mexpression'"
    local marginstitlenum "`marginstitlenonum'"

    local lblnonum "Margin"      //
    local lblnum   "`lblnonum'"
    local LHSnonum "`lblnonum' `lhsnm'"
    local LHSnum   "`lblnonum' `lhsnm'"

    if `isdydx' {
        local estlblnonum "d_`lblnonum'"
        local estlblnum   "d_`lblnum'"
        local estLHSnonum "d_`LHSnonum'"
        local estLHSnum   "d_`LHSnonum'"
    }
    else {
        local estlblnonum "`lblnonum'"
        local estlblnum   "`lblnum'"
        local estLHSnonum "`LHSnonum'"
        local estLHSnum   "`LHSnum'"
    }

// expression: cleaned content of predict

    * remove predict(  )
    local expcleaned : subinstr local Mexpression "predict(" "", all
    local expcleaned = substr("`expcleaned'",1,length("`expcleaned'")-1)
    * no numbers
    local expnonumber = regexr("`expcleaned'","[0-9]+","") // remove 1st #
    local expnonumber = regexr("`expnonumber'","[0-9]+","") // remove 2nd #

// predict title

    local predictnum "`r(predict_label)'"
    * remove =#
    local equalloc = strpos("`predictnum'","=") - 1
    if (`equalloc'==-1) local predictnonum "`predictnum'"
    else { // remove = to end for categorical outcomes (occ=1)
        local predictnonum = substr("`predictnum'",1,`equalloc')
        local predictnonum "`predictnonum')"
    }

//  classify type of prediction and model

    if "`expcleaned'"=="cm" local is_condmean = 1 // cond mean
    else local is_condmean = 0

    if "`expnonumber'"=="pr()" local is_pr = 1 // pr(#)
    else local is_pr = 0

    local ipos = strpos("`predictnonum'", "Predicted incidence rate")
    if `ipos'>0 local is_ir = 1
    else local is_ir = 0

    if "`predictnonum'"=="Linear prediction" ///
        | "`Mexpression'"=="predict(xb)" local is_xb = 1
    else local is_xb = 0

    if "`predictnonum'"=="Predicted number of events" local is_meanN = 1
    else local is_meanN = 0

    if "`expnonumber'"=="pr(,)" local is_prAB = 1 // pr(a,b)
    else local is_prAB = 0

    if "`expnonumber'"=="cpr()" local is_condpr = 1 // cpr()
    else local is_condpr = 0 // conditional pr

    if "`expnonumber'"=="cpr(,)" local is_condprAB = 1 // cpr(A,B)
    else local is_condprAB = 0

    * is model binary? is model categorical like mlogit?
    local iseqeq = strpos("`Mpredict_label'","==") // cat models have ==#
    local isPr = strpos("`Mpredict_label'","Pr(")
    local ispredictonly = "`Mexpression'"=="predict()"
    local ispredictpr = "`Mexpression'"=="predict(pr)"
    local ispredictout = strpos("`Mexpression'","predict(outcome(")
    if `ispredictonly' local ispredictout = 1

    if (`isPr'>0 & (`ispredictonly'|`ispredictpr') & `iseqeq'==0) ///
            local is_binmodel = 1
    else local is_binmodel = 0

    if (`isPr'>0 & `ispredictout' & `iseqeq'>0) local is_catmodel = 1
    else local is_catmodel = 0

    local total = `is_condmean' + `is_pr' + `is_ir' + `is_prAB' ///
        + `is_condpr' + `is_condprAB' + `is_binmodel' + `is_catmodel'
    if (`total' > 1) display "WARNING: logic error with total types = `total'"
    local esttype = -999

//  incidence rate label

    if `is_ir' {
        local esttype 1
        local marginstitlenonum : subinstr local marginstitlenonum ///
            "Predicted incidence rate" "Incidence rate"
        local marginstitlenum "`marginstitlenonum'"
        local lblnonum "rate"
        local lblnum "`lblnonum'"
        local LHSnum "rate `lhsnm'"
        local LHSnonum "rate `lhsnm'"
    }

//  xb label
    else if `is_xb' {
        local esttype 2
        * default marginstitlenonum and marginstitlenonumnonum
        local lblnonum "xb"
        local lblnum "`lblnonum'"
        local LHSnonum `"`lblnonum'"'
        local LHSnum `"`lblnum'"'
    }

//  mean events
    else if `is_meanN' {
        local esttype 3
        local marginstitlenonum "`Mpredict_label', `Mexpression'"
        local marginstitlenonum : ///
        subinstr local marginstitlenonum "events" "`lhsnm'", all
        local marginstitlenum "`marginstitlenonum'"
        local lblnonum "mu" // "mean N"
        local lblnum   "`lblnonum'"
        local LHSnonum "mean `lhsnm'"
        local LHSnum   "`LHSnonum'"
    }

//  conditional mean
    else if `is_condmean' { //"`expcleaned'"=="cm" {
        local esttype 4
        local marginstitlenonum : subinstr local marginstitlenonum ///
            "mean of n >" "mean of `lhsnm' >"
        local marginstitlenum "`marginstitlenonum'"
        local gtval : subinstr local predictnonum ///
            "Conditional mean of n > ll(" ""
        local gtval : subinstr local gtval ")" ""
        local lblnonum "E(y|y>`gtval')"
        local lblnum "`lblnonum'"
        local LHSnonum : subinstr local lblnonum "y" "`lhsnm'", all
        local LHSnum "`LHSnonum'"
    }

//  conditional pr()
    else if `is_condpr' {
        local esttype 5
        * isolate gt value from : Pr(art=1 | art>0)
        local igt = strpos("`Mpredict_label'",">")
        local ilen = strpos("`Mpredict_label'",")") - `igt' - 1
        local gtval = substr("`Mpredict_label'",`igt'+1,`ilen')
        * isolate = number from : Pr(art=1 | art>0)
        local ieq = strpos("`Mpredict_label'","=")
        local ilen = strpos("`Mpredict_label'","|") - `ieq' - 2
        local eqval = substr("`Mpredict_label'",`ieq'+1,`ilen')
        local marginstitlenum "`Mpredict_label', `Mexpression'"
        local predictnonum = regexr("`Mpredict_label'","=[0-9]+","")
        local marginstitlenonum `"`predictnonum', `expnonumber'"'
        local lblnonum "Pr(y|y>`gtval')"
        local lblnum "Pr(y=`eqval'|y>`gtval')"
        local LHSnonum : subinstr local lblnonum "y" "`lhsnm'", all
        local LHSnum : subinstr local lblnum "y" "`lhsnm'", all
    }

//  predict(pr())
    else if `is_pr' {
        local esttype 6
        local marginstitlenum "`Mpredict_label', `Mexpression'"
        local marginstitlenonum ///
            = regexr("`marginstitlenum'","=[0-9]+","") // remove =#
        local marginstitlenonum ///
            = regexr("`marginstitlenonum'","[0-9]+\)",")") // remove #)
       * isolate = number from : Pr(art=1)
        local ieq = strpos("`Mpredict_label'","=")
        local ilen = strpos("`Mpredict_label'",")") - `ieq' - 1
        local eqval = substr("`Mpredict_label'",`ieq'+1,`ilen')
        local lblnonum "Pr(y)"
        local lblnum "Pr(y=`eqval')"
        local LHSnonum : subinstr local lblnonum "y" "`lhsnm'", all
        local LHSnum : subinstr local lblnum "y" "`lhsnm'", all
    }

//  predict(pr(#,#))
    else if `is_prAB' {
        local esttype 7
        * use default marginstitlenonum and marginstitlenonumnonum
        * construct Pr(A<=lhs<=B)
        local temp "`expcleaned'"
        local temp : subinstr local temp "pr" "Pr", all
        local lbllhs : subinstr local temp "," "<=`lhsnm'<=", all
        local lbly : subinstr local temp "," "<=y<=", all
        local lblnonum "`lbly'"
        local lblnum "`lblnonum'"
        local LHSnonum : subinstr local lblnonum "y" "`lhsnm'", all
        local LHSnum : subinstr local lblnum "y" "`lhsnm'", all
    }

//  conditional pr(A,B) | >
    else if `is_condprAB' { // r(predict_label) : "Pr(1<=art<=2 | art>0)"
        local esttype 8
        * use default marginstitlenonum and marginstitlenonumnonum
        * construct Pr(A<=lhs<=B)
        local lblnonum : subinstr local Mpredict_label "`lhsnm'" "y", all
        local lblnonum : subinstr local lblnonum " | " "|"
        local lblnum "`lblnonum'"
        local LHSnonum : subinstr local lblnonum "y" "`lhsnm'", all
        local LHSnum : subinstr local lblnum "y" "`lhsnm'", all
    }

//  pr in binary
    else if `is_binmodel' {
        local esttype 9a
        * use default marginstitlenonum and marginstitlenonumnonum
        local lblnonum "Pr(y)"
        local lblnum "`lblnonum'"
        local LHSnonum : subinstr local lblnonum "y" "`lhsnm'", all
        local LHSnum "`LHSnonum'"
    }

//  pr in cat
    if `is_catmodel' {
        local esttype 9b
        local marginstitlenonum `"`predictnonum', predict(`expnonumber')"'
        local marginstitlenum "`Mpredict_label', `Mexpression'"
        * isolate = number from : predict_label: Pr(warm==3)
        local ieq = strpos("`Mpredict_label'","==")
        local ilen = strpos("`Mpredict_label'",")") - `ieq' - 2
        local eqval = substr("`Mpredict_label'",`ieq'+2,`ilen')
        local lblnonum "Pr(y)"
        local lblnum "Pr(y=`eqval')"
        local LHSnonum : subinstr local lblnonum "y" "`lhsnm'", all
        local LHSnum : subinstr local lblnum "y" "`lhsnm'", all
    }

//  zero inflated models with prob always 0; overwrite what was done above
    else if `iszi' {
        if "`expcleaned'"=="pr" { // pr == always 0
            local esttype 10
            local marginstitlenonum : subinstr local marginstitlenonum ///
                "=0" " = always 0"
            local marginstitlenum "`marginstitlenonum'"
            local lblnonum "PrAll0"
            local lblnum "`lblnonum'"
            local LHSnonum  `"Pr(`lhsnm'=always0)"'
            local LHSnum  `"`LHSnonum'"'
        }
        else if "`expcleaned'"=="pr(0)" { // pr == any 0
            local esttype 11
            local marginstitlenonum "`Mpredict_label', `Mexpression'"
            local marginstitlenonum : subinstr local marginstitlenonum ///
                "=0" " = any 0"
            local marginstitlenum "`marginstitlenonum'"
            local lblnonum "PrAny0"
            local lblnum "`lblnonum'"
            local LHSnonum  `"Pr(`lhsnm'=any0)"'
            local LHSnum  `"`LHSnonum'"'
        }
    }

// returns

    if `isdydx' ///
        local marginstitlenonum "Marginal effect of `marginstitlenonum'"
    local marginstitlenonum = trim("`marginstitlenonum'")
    local marginstitlenonumlen = length("`marginstitlenonum'")

    makelabels `"`lblnonum'"' `"`lblnum'"' `"`LHSnonum'"' `"`LHSnum'"' `isdydx'
    local estlblnonum `"`s(estlblnonum)'"'
    local estlblnum `"`s(estlblnum)'"'
    local estLHSnonum `"`s(estLHSnonum)'"'
    local estLHSnum `"`s(estLHSnum)'"'

    foreach nm in estlblnonum estlblnum estLHSnonum estLHSnum {
        local `nm' = trim("``nm''")
        local `nm'len = length("``nm''")
    }
    sreturn clear
    foreach nm in xvars xvarsN ///
            estlblnonum estlblnonumlen ///
            estlblnum   estlblnumlen ///
            estLHSnonum estLHSnonumlen ///
            estLHSnum   estLHSnumlen ///
            marginstitlenum marginstitlenonum esttype isdydx {
        sreturn local `nm' "``nm''"
    }

    * customize names for variables created by mgen
    foreach nm in num nonum {
        local estvar`nm' = lower("`estlbl`nm''")
        local estvar`nm' : subinstr local estvar`nm' " " "", all
        local estvar`nm' : subinstr local estvar`nm' "(" "", all
        local estvar`nm' : subinstr local estvar`nm' ")" "", all
        local estvar`nm' : subinstr local estvar`nm' "pry" "pr", all
        local estvar`nm' : subinstr local estvar`nm' "meann" "mu", all
        local estvar`nm' : subinstr local estvar`nm' "=" "", all
        local estvar`nm' : subinstr local estvar`nm' "|y>" "GT", all
    }
    sreturn local estvarnonum  "`estvarnonum'"
    sreturn local estvarnum    "`estvarnum'"

end

program define makelabels, sclass
    version 11.2
    args lblnonum lblnum LHSnonum LHSnum isdydx noisily
    local lblnonum `"`lblnonum'"'
    local lblnum `"`lblnum'"'
    local LHSnonum `"`LHSnonum'"'
    local LHSnum `"`LHSnum'"'

    local dydxlblnonum `"d_`lblnonum'"'
    local dydxlblnum `"d_`lblnum'"'
    local dydxLHSnonum `"d_`LHSnonum'"'
    local dydxLHSnum `"d_`LHSnum'"'
    if `isdydx' {
        local estlblnonum `"`dydxlblnonum'"'
        local estlblnum  `"`dydxlblnum'"'
        local estLHSnonum  `"`dydxLHSnonum'"'
        local estLHSnum  `"`dydxLHSnum'"'
    }
    else {
        local estlblnonum `"`lblnonum'"'
        local estlblnum  `"`lblnum'"'
        local estLHSnonum  `"`LHSnonum'"'
        local estLHSnum  `"`LHSnum'"'
    }

    sreturn clear
    sreturn local estlblnonum `"`estlblnonum'"'
    sreturn local estlblnum   `"`estlblnum'"'
    sreturn local estLHSnonum `"`estLHSnonum'"'
    sreturn local estLHSnum   `"`estLHSnum'"'

end
exit

* if single, use num
_rm_margins_names
local marginstitle "`s(marginstitlenum)'" // if single, use #
if "`estname'"=="" local estname `"`s(estlblnum)'"'
local lbl_estimate "`estname'"

* if multiple use nonum
_rm_margins_names
local marginstitle "`s(marginstitlenonum)'"
if ("`estname'"=="") local estname `"`s(estlblnonum)'"'
local lbl_estimate "`estname'"
