*! version 1.0.0 2014-02-14 | long freese | spost13 release

//  sreturns names of estimates from margins
//
//      s(title):   long name from margins; modified r(predict_label)
//      s(predict): what is predicted without predict( )
//      s(math):    math
//      s(math10):    math
//      s(type):    prob, rate, lin
//      s(matname): name for column of matrix
//      s(math_noequal) : remove =k

program define _rm_marginsnames, sclass

    version 11.2

    * margins returns
    local cmdline "`r(cmdline)'" // margins command
    local marginslabel "`r(predict_label)'"
    local marginsexp "`r(expression)'"
    local marginsdydx "`r(derivatives)'"
    local marginsxvars "`r(xvars)'"

    * model information: won't work if margins post
    local ecmdnm "`e(cmd)'"
    local lhsnm "`e(depvar)'"

    * defaults
    local title ""
    local predict ""
    local math "estimate"
    local math10 "estimate"
    local type ""

    * decod dydx
    local isdydx = 0
    if ("`marginsdydx'"=="dy/dx") local isdydx = 1
    if `isdydx'== 1 {
        local nxvars = wordcount("`marginsxvars'")
        local dydxnms ""
        if `nxvars'>0 {
            foreach nm in `marginsxvars' {
                local first = substr("`nm'",1,1)
                if ("`first'"!="0") local dydxnms "`dydxnms'`nm' "
            }
        }
        local nxvars = wordcount("`dydxnms'")
        if (`nxvars'==1) local dydxnm "`dydxnms'"
        else local dydxnm "x"
    }
    else local dydxnm ""

    * is it margins post
    local ipos : list posof "post" in cmdline // was `post' by mistake
    local ispost = 0
    if (`ipos'>0) local ispost = 1
    local cmdn = r(N)

    * predict: predict command corresponding to margins estiamtes
    local temp : subinstr local marginsexp "predict(" "", all
    local nexp = length("`temp'")-1
    local temp = substr("`temp'",1,`nexp')
    local predict "`temp'" // predict from margins w/o predict()

    * text title of what is estimated
    local title "`r(predict_label)'"
    local title : subinstr local title "Predicted incidence rate" ///
        "Incidence rate", all

    * is there a comma in predict
    local iscomma = strpos("`predict'",",")
    local iscomma = `iscomma'>0

    * is predict a probability
    local work "`predict'"
    local work = regexr("`work'","[0-9]","") // get rid of #'s
    local work = regexr("`work'","[0-9]","")
    local work = regexr("`work'","[0-9]","")
    local work = regexr("`work'","\(","") // get rid of ( and )
    local work = regexr("`work'","\)","")
    local work = substr("`work'",1,2)
    local ispr = 0
    if ("`work'"=="pr") local ispr = 1
    local temp = strpos("`title'","Pr(")
    local temp = `temp'>0
    if (`temp'==1) local ispr=1

    * is it cond prob?
    local iscpr = strpos("`predict'","cpr(")
    local iscpr = `iscpr'>0

// pr(#)

    if `ispr'==1 & `iscomma'==0 {
        local type "prob_a"
        if "`predict'"!="" {
            * construct Pr(lhs=#)
            local temp "`predict'"
            local temp : subinstr local temp "pr" "Pr", all
            local temp : subinstr local temp "Pr(" "Pr(`lhsnm'=", all
            local math "`temp'"
        }
        if "`predict'"=="" { // when Pr() is default predict
            local math "`title'"
        }
        local len = length("`math'")
        if `len'>10 {
            local math10 : subinstr local math "`lhsnm'" "y", all
        }
        else local math10 "`math'"
    }

// pr(#,#)

    if `ispr'==1 & `iscomma'==1 {
        local type "prob_a2b"
        * construct Pr(A<=lhs<=B)
        local temp "`predict'"
        local temp : subinstr local temp "pr" "Pr", all
        local temp : subinstr local temp "," "<=`lhsnm'<=", all
        local math "`temp'"
        local len = length("`math'")
        if `len'>10 {
            local math10 : subinstr local math "`lhsnm'" "y", all
        }
        else local math10 "`math'"
    }

//  pr used in binary models

    if "`predict'"=="pr" {
        local math "`title'" // Pr(a=3)
        local len = length("`math'")
        if `len'>10 {
            local math10 : subinstr local math "`lhsnm'" "y", all
        }
        else local math10 "`math'"
    }

//  zero inflated models with prob always 0; overwrite what was done above

    if "`e(cmd)'"=="zip" | "`e(cmd)'"=="zinb" {

        if "`predict'"=="pr" { // pr is prob of always 0
            local type "prob_a"
            local title "Pr(Always 0)"
            local math "Pr(Always 0)"
            local math10 "Pr(All0)"
        }
        if "`predict'"=="pr(0)" { // prob of any 0
            local type "prob_a"
            local title "Pr(Any 0)"
            local math "Pr(Any 0)"
            local math10 "`math'"
        }
    }

//  xb

    if "`predict'"=="xb" {
        local type "lin_pred"
        local math "xb"
        local math10 "`math'"
    }

//  conditional mean

    if "`predict'"=="cm" {
        local type "mean_cond"
        local gtval "`title'"
        local gtval : subinstr ///
        local gtval "Conditional mean of n > ll(" "", all
        local gtval : subinstr local gtval ")" "", all
        local math "E(`lhsnm'|`lhsnm'>`gtval')"
        local len = length("`math'")
        local math10 : subinstr local math "(" "", all
        local math10 : subinstr local math10 ")" "", all
        local len = length("`math'")
        if `len'>10 {
            local math10 : subinstr local math "`lhsnm'" "y", all
        }
        else local math10 "`math'"
    }

//  ir - rate

    if "`predict'"=="ir" {
        local type "rate"
        local math "E(`lhsnm')"
        local math10 "`math'"
        if length("`math'")>10 {
            local math10 : subinstr local math10 "`lhsnm'" "y", all
        }
    }

//  conditional probability
    if `iscpr'==1 {
        local math : subinstr local title " " "", all
        if `iscomma' == 0 {
            local type "prob_a_cond"
        }
        if `iscomma'==1 {
            local type "prob_a2b_cond"
        }
        local len = length("`math'")
        if `len'>10 {
            local math10 : subinstr local math "`lhsnm'" "y", all
        }
        else local math10 "`math'"
    }

//  categorical outcomes

    forvalues icat = -25(1)25 {
        if "`predict'"=="outcome(`icat')" local math "`title'"
        local len = length("`math'")
        if `len'>10 {
            local math10 : subinstr local math "`lhsnm'" "y", all
        }
        else local math10 "`math'"
    }

//  lrm

    if "`title'"=="Linear prediction" & "`predict'"=="" ///
        & "`type'"=="" & "`math'"=="" {
        local type "lin_pred"
        local math "E(`lhsnm')"
        local len = length("`math'")
        local math10 : subinstr local math "(" "", all
        local math10 : subinstr local math10 ")" "", all
        local len = length("`math'")
        if `len'>10 {
            local math10 : subinstr local math "`lhsnm'" "y", all
        }
        else local math10 "`math'"
    }

//  dydx

    if `isdydx' == 1 {
        local type "dydx_`type'"
        local math "d`math'_d`dydxnm'"
        local len = length("`math'")
        local math10 "`math'"
        if `len'>10 {
            local math10 : subinstr local math10 "`dydxnm'" "x", all
        }
        local len = length("`math10'")
        if `len'>10 {
            local math10 : subinstr local math10 "`lhsnm'" "y", all
        }
    }
    local len = length("`math10'")

//  math_noequal

    local math_noequal "`math'"
    local isparen = strpos("`math_noequal'",")")
    local isequal = strpos("`math_noequal'","=")
    if `isequal'>0 {
        local len = `isequal' - 1
        local math_noequal = substr("`math_noequal'",1,`len')
        if `isparen'>0 local math_noequal "`math_noequal')"
    }

//  returns

    sreturn local title "`title'"
    sreturn local predict "`predict'"
    sreturn local type "`type'"
    sreturn local math "`math'"
    sreturn local math10 "`math10'"
    sreturn local length "`len'"
    sreturn local math_noequal "`math_noequal'"

end
exit
