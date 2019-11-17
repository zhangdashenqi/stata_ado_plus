* spex - version 1.3.1 - fix rologit case2alt bug 25Oct2005
* spex - version 1.3.0 - add asmprobit 08Sep2005
* spex - version 1.2.10 - case2alt modification 11Jul2005
* spex - version 1.2.9 - case2alt 11jul2005
* spex - version 1.2.8 - change directory for spex_data 11Jul2005
* spex - version 1.2.7 - revise misschk 06Jul2005

capture program drop spex
program define spex

    ** USERS: TO HAVE SPEX SEARCH SOMEWHERE OTHER THAN YOUR WORKING DIRECTORY
    ** FOR DATA, ENTER THE PATH IN THE QUOTES BELOW (WINDOWS: USE / AS SEPARATOR)
    *  local userpath "C:/~ToSync/~Projects/stata/spostdata/" // example

    local userpath ""

    syntax namelist(id="dataset or command") [, Web User Jsl *]

    tokenize "`namelist'"

    * unabbreviate command
    capture _optname , `1'
    local cmddta = r(opt)

    if "`cmddta'"=="." {
        local cmddta = "`1'"
    }

    local default = "web"
*local default = "jsl"

    ** SET DIRECTORY WHERE DATA IS STORED

    if "`web'" == "web" | ///
        ("`jsl'"== "" & "`user'" == "" & "`default'" == "web") {

*      local where "http://www.stata-press.com/data/lfr/"

       local where "http://www.indiana.edu/~jslsoc/stata/spex_data/"

    }

    if "`user'" == "user" | ///
        ("`jsl'"== "" & "`web'" == "" & "`default'" == "user") {

        local where "`userpath'"

    }

    if "`jsl'" == "jsl" | ///
        ("`user'"== "" & "`web'" == "" & "`default'" == "jsl") {

        local where "c:\spostdata/"

    }

    ** SPECIFY SYNTAX OF MODEL IF MODEL IS SPECIFIED

    if "`cmddta'" == "asmprobit" {
        local data travel2
        local cmd "asmprobit choice time invc, case(id) alternatives(mode) `options'"
    }

    if "`cmddta'" == "clogit" {
        local data travel2
        local cmd "clogit choice train bus time invc, group(id) `options'"
    }

    if "`cmddta'" == "cloglog" {
        local data binlfp2
        local cmd "cloglog lfp k5 k618 age wc hc lwg inc, `options'"
    }

    if "`cmddta'" == "cnreg" {
        local data nels_censored2
        local cmd "cnreg testscor bymomed bydaded black hispanic, censored(censor) `options'"
    }

    if "`cmddta'" == "intreg" {
        local data nels_censored2
        local cmd "intreg minscor maxscor bymomed bydaded black hispanic, `options'"
    }

    if "`cmddta'" == "logit" {
        local data binlfp2
        local cmd "logit lfp k5 k618 age wc hc lwg inc, `options'"
    }

    if "`cmddta'" == "misschk" {
        local data gsskidvalue2
        *local cmd "misschk year-income91, help"
        local cmd ///
        "misschk age anykids black degree female kidvalue othrrace year income91 income, help gen(m_) dummy"
    }

    if "`cmddta'" == "mlogit" {
        local data nomocc2
        local cmd "mlogit occ white ed exper, `options'"
    }

    if "`cmddta'" == "mprobit" {
        local data nomocc2
        local cmd "mprobit occ white ed exper, `options'"
    }

    if "`cmddta'" == "nbreg" {
        local data couart2
        local cmd "nbreg art fem mar kid5 phd ment, `options'"
    }

    if "`cmddta'" == "ologit" {
        local data ordwarm2
        local cmd "ologit warm yr89 male white age ed prst, `options'"
    }

    if "`cmddta'" == "oprobit" {
        local data ordwarm2
        local cmd "oprobit warm yr89 male white age ed prst, `options'"
    }

    if "`cmddta'" == "poisson" {
        local data couart2
        local cmd "poisson art fem mar kid5 phd ment, `options'"
    }

    if "`cmddta'" == "probit" {
        local data binlfp2
        local cmd "probit lfp k5 k618 age wc hc lwg inc, `options'"
    }

    if "`cmddta'" == "regress" | "`cmddta'" == "reg" {
        local data regjob2
        local cmd "regress job fem phd ment fel art cit, `options'"
    }

    if "`cmddta'" == "rologit" {
        local data wlsrnk
        local precmd1 `"label variable value1 "est""'
        local precmd2 `"label variable value2 "var""'
        local precmd3 `"label variable value3 "aut""'
        local precmd4 `"label variable value4 "sec""'
        local precmd5 "case2alt, yrank(value) case(id) alt(hashi haslo) casevars(fem hn) gen(rank)"
        local cmd "rologit rank est* var* aut* hashi haslo, group(id) reverse"
    }

    if "`cmddta'" == "slogit" {
        local data ordwarm2
        local cmd "slogit warm yr89 male white age ed prst, `options'"
    }

    if "`cmddta'" == "tobit" {
        local data tobjob2
        local cmd "tobit jobcen fem phd ment fel art cit, ll(1)"
    }

    if "`cmddta'" == "zinb" {
        local data couart2
        local cmd "zinb art fem mar kid5 phd ment, inf(fem mar kid5 phd ment) `options'"
    }

    if "`cmddta'" == "zip" {
        local data couart2
        local cmd "zip art fem mar kid5 phd ment, inf(fem mar kid5 phd ment) `options'"
    }

    if "`cmddta'" == "ztnb" {
        local data couart2
        local cmd "ztnb art fem mar kid5 phd ment if art > 0, `options'"
    }

    if "`cmddta'" == "ztp" {
        local data couart2
        local cmd "ztp art fem mar kid5 phd ment if art > 0, `options'"
    }

    if "`cmd'" == "" {
        local data "`cmddta'"
    }

    ** LOAD DATAFILE

    di _n in white `". use "`where'`data'.dta", clear"'
    capture use "`where'`data'", clear

    if _rc != 0 {
         di _n in green "(trying alternate location for file)"
         di _n in white `". sysuse "`data'.dta", clear"'
         capture sysuse `data'.dta, clear
         if _rc != 0 {
              di as err `"program cannot confirm dta file `data' on path `where'"'
              error 999
         }
    }

    ** EXECUTE COMMAND

    * are there commands to be executed before the command?
    local i = 1
    while `"`precmd`i''"' != "" {
        di in white `". `precmd`i''"'
        `precmd`i''
        local i = `i' + 1
    }

    if "`cmd'" != "" {

        if substr("`cmd'", -2, .) == ", " {
            local trim = length("`cmd'") - 2
            local cmd = substr("`cmd'", 1, `trim')
        }

        di _n in white ". `cmd'"
        `cmd'
    }

end

capture program drop _optname
program define _optname, rclass

    version 8

    syntax , [BINlfp2 ORDwarm2 REGress LOGit MLOGit OLOGit NOMocc2]

    foreach d in binlfp2 ordwarm2 regress logit ///
            mlogit ologit nomocc2 {
        if "``d''"=="`d'" {
            local opt = "`d'"
        }
    }
    return local opt "`opt'"

end

