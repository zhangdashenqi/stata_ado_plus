*! version 1.0.1 2014-09-26 | scott long | _all, localnm i.wc 
* version 1.0.0 2014-09-20 | scott long |

//  decode at(atpsec) and classify types of variables
//
//  returns:
//
//      atall*:     all variables
//      atvary*:    vary within r(at)
//      atfixed*:   fixed in r(at)
//      noat*:      not in r(at) matrix
//      local*:     optional for computing local means
//      globals*:   global means
//
//  *: nms for names of variables; names are from e(b)
//  *: stats is type of information

program define _rm_parse_atspec, sclass

    syntax , [  at(string) localnms(string) ] *
    tempname atmatrix atfixed atmin atmax

    * determine how margins is decoding at(atspec)
    _ms_at_parse `at'
    local statlist "`r(statlist)'"
    mat `atmatrix' = r(at)
    local atvaryvaluesN = rowsof(`atmatrix')
    local atmatrixnms : colnames `atmatrix'

    * indicate if colum in r(at) is fixed; get min max
    *   - matrix columns are columns from r(at)
    mata : st_matrix("`atfixed'",colmin(st_matrix("`atmatrix'")) ///
        :== colmax(st_matrix("`atmatrix'")) )
    mata : st_matrix("`atmin'",colmin(st_matrix("`atmatrix'")) )
    mata : st_matrix("`atmax'",colmax(st_matrix("`atmatrix'")) )

    local atnms "`r(atvars)'" // variables in atspec
    local atnmsN = wordcount("`atnms'")
    local atstats ""
    foreach nm in `atnms' {
        local atstats `atstats' atvar // all atvars have statistic "atvar"
    }

    * all atvar variables
    local atallnms "`atmatrixnms'"
    local atallstats "`statlist'"

    * do variables in at() vary or are they fixed?
    local atvarynms ""
    local atvarystats ""
    local atfixednms ""
    local atfixedstats ""
    local atfixedspec ""

    local icol = 0
    foreach nm in `atallnms' {

        local ++icol
        * find column # of variable in r(at)
        local iatmatcol : list posof "`nm'" in atnms

        * determine column for variable in r(at)
        if `iatmatcol'==0 {
            local iat = 0
            foreach atnm in `atnms' {
                local ++iat
                local pos = strpos("`nm'",".`atnm'")
                if (`pos'>0) local iatmatcol = `iat'
            }
        }

        if `iatmatcol'>0 { // only check atvars

            local isatfixed = `atfixed'[1,`icol']

            if `isatfixed'==1 {
                local atfixednms   "`atfixednms' `nm'"
                local atfixedstats "`atfixedstats' atfixed"
                local atfixedvalue = `atmin'[1,`icol'] 
                * atspec for use in margins
                local atfixedspec "`atfixedspec' `nm'=`atfixedvalue'"
            }
            * values of at variable vary
            else {
                local atvarynms "`atvarynms' `nm'"
                local atvarystats "`atvarystats' atvary"
                local atvarystart = `atmin'[1,`icol']
                local atvaryend = `atmax'[1,`icol']
                local atvarydelta ///
                    = (`atvaryend'-`atvarystart') / (`atvaryvaluesN'-1)
            }
        }
    }
    local atvarynmsN = wordcount("`atvarynms'")

    //  variables not in at()

    local noatnms : list atallnms - atvarynms
    local noatnms : list noatnms - atfixednms
    local noatstats ""
    foreach nm in `noatnms' {
        local ipos : list posof "`nm'" in atallnms
        local type : word `ipos' of `atallstats'
        local noatstats `noatstats' `type'
    }

    //  variables that use local means

    if ("`localnms'"=="_all") local localnms "`noatnms'"
    * at variables can't be localized
    local localnms : list localnms - atfixednms
    local localnms : list localnms - atvarynms

*di "localnms: `localnms'"
*di " "
*di "localnms: `localnms'"   
*di in red "****************************************************"
*di "change wc to fvexpand i.wc here"

* is local name in e(b), if not fvexpand i.name and check
local iserror = 0
local ebnms : colnames e(b)
local newlocalnms ""
foreach lnm in `localnms' {
    local ipos : list posof "`lnm'" in ebnms
    if `ipos' == 0 {
        fvexpand i.`lnm'
        local lnms2 `r(varlist)'
        foreach lnm2 in `lnms2' {
            local ipos : list posof "`lnm2'" in ebnms
            if `ipos' == 0 {
                local iserror = 1
                di "`lnm2' is not in e(b); if i.var you need to enter 1.var, etc."
            }
            else local newlocalnms "`newlocalnms' `lnm2'"
        }
    }
    else local newlocalnms "`newlocalnms' `lnm'"
}
local localnms `newlocalnms'

*di "original: `localnms'"
*di "revised : `newlocalnms'"

if `iserror'==0 { // no error decoding local variables

    * set stat type for localvrs
    local localstats ""
    foreach nm in `localnms' {
        local ipos : list posof "`nm'" in atallnms
        local type : word `ipos' of `atallstats'
        local localstats `localstats' `type'
    }

    //  variables using global means

    local globalnms : list noatnms - localnms
    local globalstats ""
    foreach nm in `globalnms' {
        local ipos : list posof "`nm'" in atallnms
        local type : word `ipos' of `atallstats'
        local globalstats `globalstats' `type'
    }
}
    // returns

    foreach class in atall at atvary atfixed noat local global {
        sreturn local `class'nms   ``class'nms'
        sreturn local `class'stats ``class'stats'
    }
    sreturn local atspec        "`at'"
    sreturn local atfixedspec   "`atfixedspec'"
    sreturn local atvarynmsN    `atvarynmsN'
    sreturn local atvaryvaluesN `atvaryvaluesN'
    sreturn local atvarystart   `atvarystart'
    sreturn local atvaryend     `atvaryend'
    sreturn local atvarydelta   `atvarydelta'
    sreturn local iserror `iserror'

end
