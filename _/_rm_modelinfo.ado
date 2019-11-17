*! version 1.1.12 2013-06-12 | long freese | space lin labels
* version 1.1.11 2013-01-18 | long freese | cloglog ncats
* version 1.1.10 2013-01-16 | long freese | use sizeof for large models
* version 1.1.9 2012-10-26 | long freese | catnms8
* version 1.1.8 2012-10-02 | long freese | int refinements

//  sreturns with information about the last estimation command

capture program drop _rm_modelinfo
program define _rm_modelinfo, rclass

    version 11.2

    local cmdnm "`e(cmd)'"
    if "`cmdnm'"=="" {
        display as error "estimation results are not in memory"
        exit
    }
    local cmdn = e(N)

    * e(b) parameter names
    tempname varinfo betainfo betas
    matrix `betas' = e(b)
    local betanms : colnames `betas'
    local nbetanms = wordcount("`betanms'")
    local betanms : subinstr local betanms "o._cons" " ", all // for ologit etc
    local betanms : subinstr local betanms "_cons" " ", all // for ologit etc
    *local nbetanms = wordcount("`betanms'")
    local nbetanms : list sizeof betanms
    matrix `betainfo' = J(13,`nbetanms',.)
    matrix rownames `betainfo' = ///
    /// 1      2    3     4       5        6    7     8
        1isbin 2iscat 3Ncats 4catbase 5Nomitted 6isfv 7isint 8intself ///
    /// 9           10          11       12     13
        9intselfonly 10intother 11factor 12omit 13level
    matrix colnames `betainfo' = `betanms'

    local cmdbin = 0
*    if ("`cmdnm'"=="logit" | "`cmdnm'"=="probit") local cmdbin = 1
    if ("`cmdnm'"=="logit" | "`cmdnm'"=="probit" | "`cmdnm'"=="cloglog") ///
        local cmdbin = 1

    local cmdnrm = 0
    if ("`cmdnm'"=="mlogit" | "`cmdnm'"=="mprobit" ///
      | "`cmdnm'"=="slogit")  local cmdnrm = 1

    local cmdcrm = 0
    if ("`cmdnm'"=="poisson"  | "`cmdnm'"=="nbreg" | "`cmdnm'"=="zip" ///
      | "`cmdnm'"=="zinb"     | "`cmdnm'"=="ztp"   | "`cmdnm'"=="ztnb" ///
      | "`cmdnm'"=="tpoisson" | "`cmdnm'"=="tnbreg") local cmdcrm = 1

    local cmdsvy = 0
    if ("`e(prefix)'"=="svy") local cmdsvy = 1

    local lhsnm "`e(depvar)'"
    if "`e(cmd)'"=="intreg" {
        local lhsnm2 : word 2 of `lhsnm'
        local lhsnm  : word 1 of `lhsnm'
    }

    local lhsbaseval = .
    if ("`e(cmd)'"=="mlogit") local lhsbaseval = e(baseout)
    if ("`e(cmd)'"=="mprobit") local lhsbaseval = e(i_base)

    _rm_rhsnames rhsnms rhsn rhsnms2 rhsn2
    local lhscatn = e(k_cat)
    if `cmdnrm' local lhscatn = e(k_out)
    if `cmdbin' local lhscatn = 2
    qui tab `lhsnm' if e(sample)
    local lhsvalues = r(r)
    if `lhscatn'==. {
        local lhscatn = 0
        local lhscatnms ""
        local lhscatvals ""
        local lhscatnms8 ""
    }
    else {
        qui sum `lhsnm' if e(sample)
        local lmin = r(min)
        _labels2names `lhsnm' if e(sample), indexfrom(`lmin')
        local lhscatnms "`s(labels)'"

        _labels2names `lhsnm' if e(sample), indexfrom(`lmin') nolabel
        local lhscatvals "`s(labels)'"
        local ln = s(n_cat)
        if `lhscatn'!=`ln' {
            di as error "_rm_modelinfo error: e(k_cat)!=s(n_cat)"
            exit
        }
        local lhscatnms8 ""
        foreach cnm in `lhscatnms' {
            local cnm = substr("`cnm'",1,8)
            *            local lhscatnms8 "`lhscatnms8'`cnm' "
            local lhscatnms8 "`lhscatnms8' `"`cnm'"' " // 1.1.12
        }
    }
/*
di "lhscatn:    `lhscatn'"
di "lhscatnms8: `lhscatnms8'"
di "lhscatnms:  `lhscatnms'"
di "lhscatvals: `lhscatvals'"
*/
//  fv types

    _rm_fvtype , rhs_beta(`rhsnms')
    foreach fv in rhs_fvbin rhs_fvcat rhs_core rhs_notfv ///
            rhs_fv rhs_fvint rhs_fvintself ///
            rhs_fvintother fvintselfonly {
        local `fv' "`s(`fv')'"
        local `fv' = ltrim("``fv''")
*di "!! `fv'" _col(25) "``fv''"
    }

    if "`rhsnms2'"!="" {
        _rm_fvtype , rhs_beta(`rhsnms2')
        foreach fv in fvbin fvcat notfv fv core fvint fvintself ///
            fvintother fvintselfonly {
            local rhs2_`fv' "`s(rhs_`fv')'"
            local rhs2_`fv' = ltrim("`rhs2_`fv''")
        }
    }
    local nrhs_core = wordcount("`rhs_core'")
    matrix `varinfo' = J(10,`nrhs_core',.)
    matrix rownames `varinfo' = ///
    /// 1      2    3     4       5        6    7     8
        1isbin 2iscat 3Ncats 4catbase 5Nomitted 6isfv 7isint 8intself ///
    /// 9           10
        9intselfonly 10intother
    matrix colnames `varinfo' = `rhs_core'

    * is it categorical?
    foreach nm in `s(rhs_fvcat)' {
        local ipos : list posof "`nm'" in rhs_core
        if `ipos'>0 matrix `varinfo'[2,`ipos'] = 1
    }
    * is it a factor variable?
    foreach nm in `s(rhs_fv)' {
        local ipos : list posof "`nm'" in rhs_core
        if `ipos'>0 matrix `varinfo'[6,`ipos'] = 1
    }
    foreach nm in `s(rhs_notfv)' {
        local ipos : list posof "`nm'" in rhs_core
        if `ipos'>0 matrix `varinfo'[6,`ipos'] = 0
    }
    * interaction # with this variable?
    foreach nm in `s(rhs_fvint)' {
        local ipos : list posof "`nm'" in rhs_core
        if `ipos'>0 matrix `varinfo'[7,`ipos'] = 1
    }
    * interacts with self (polynomial)?
    foreach nm in `s(rhs_fvintself)' {
        local ipos : list posof "`nm'" in rhs_core
        if `ipos'>0 matrix `varinfo'[8,`ipos'] = 1
    }
    * only with self?
    foreach nm in `s(rhs_fvintselfonly)' {
        local ipos : list posof "`nm'" in rhs_core
        if `ipos'>0 matrix `varinfo'[9,`ipos'] = 1
    }
    * int with others?
    foreach nm in `s(rhs_fvintother)' {
        local ipos : list posof "`nm'" in rhs_core
        if `ipos'>0 matrix `varinfo'[10,`ipos'] = 1
    }

    * determine # categores in rhs variables
    local icore = 0
    foreach corenm in `rhs_core' {
        local ++icore
        * remove #b. from #b.name but not if #b.name#
        local new = regexr("`betanms'","[0-9]+b\.`corenm'[^#]","`corenm'")
        local old "`new'"
        local new ""
        local done = 0
        local ncats = 1
        while !`done' {
            * remove #.
            local new = regexr("`old'","[0-9]\.`corenm'[^#]","`corenm'")
            if ("`new'"=="`old'") local done = 1
            else {
                local old "`new'"
                local ++ncats
            }
        }
        * 1 if not factor; 2 if binary; 3...
        matrix `varinfo'[3,`icore'] = `ncats'
        if (`ncats'==2) matrix `varinfo'[1,`icore'] = 1
    }

    * information on parameters in e(b)
    local ibnm = 0
    foreach bnm in `betanms' {

        local ++ibnm
        _ms_parse_parts `bnm'
        local corenm `r(name)'
        local inttype "`r(type)'"
        if "`inttype'"=="interaction" {
            matrix `betainfo'[7,`ibnm'] = 1
            forvalues i = 1(1)6 {
                local deg`i' = 0
                if "`r(name`i')'"!="" local deg`i' = 1
            }
            if `deg6'==1 {
                display as error ///
                "fifth order interactions & higher not supported"
                exit
            }
            if `deg5'==1 {
                if "`r(name1)'"=="`r(name2)'" & "`r(name1)'"=="`r(name3)'" ///
                 & "`r(name1)'"=="`r(name4)'" & "`r(name1)'"=="`r(name5)'" {
                    matrix `betainfo'[8,`ibnm'] = 1 // self
                    matrix `betainfo'[9,`ibnm'] = 1 // self only
                    matrix `betainfo'[10,`ibnm'] = 0 // intother
                }
                else {
                    matrix `betainfo'[8,`ibnm'] = 0 // self
                    matrix `betainfo'[9,`ibnm'] = 0 // self only
                    matrix `betainfo'[10,`ibnm'] = 1 // intother
                }
            }
            if `deg4'==1 {
                if "`r(name1)'"=="`r(name2)'" & "`r(name1)'"=="`r(name3)'" ///
                 & "`r(name1)'"=="`r(name4)'" {
                    matrix `betainfo'[8,`ibnm'] = 1 // self
                    matrix `betainfo'[9,`ibnm'] = 1 // self only
                    matrix `betainfo'[10,`ibnm'] = 0 // intother
                }
                else {
                    matrix `betainfo'[8,`ibnm'] = 0 // self
                    matrix `betainfo'[9,`ibnm'] = 0 // self only
                    matrix `betainfo'[10,`ibnm'] = 1 // intother
                }
            }
            if `deg3'==1 {
                if "`r(name1)'"=="`r(name2)'" & "`r(name1)'"=="`r(name3)'" {
                    matrix `betainfo'[8,`ibnm'] = 1 // self
                    matrix `betainfo'[9,`ibnm'] = 1 // self only
                    matrix `betainfo'[10,`ibnm'] = 0 // intother
                }
                else {
                    matrix `betainfo'[8,`ibnm'] = 0 // self
                    matrix `betainfo'[9,`ibnm'] = 0 // self only
                    matrix `betainfo'[10,`ibnm'] = 1 // intother
                }

            }
            else if `deg2'==1 {
                if "`r(name1)'"=="`r(name2)'" {
                    matrix `betainfo'[8,`ibnm'] = 1 // self
                    matrix `betainfo'[9,`ibnm'] = 1 // self only
                    matrix `betainfo'[10,`ibnm'] = 0 // intother
                }
                else {
                    matrix `betainfo'[8,`ibnm'] = 0 // self
                    matrix `betainfo'[9,`ibnm'] = 0 // self only
                    matrix `betainfo'[10,`ibnm'] = 1 // intother
                }
            }
*r(name2) : "age"
*r(op2) : "c"
*r(name1) : "age"
*r(op1) : "c"
        } // interaction

        * is it omitted? base level?
        if "`corenm'"!="" {
            local ipos : list posof "`corenm'" in rhs_core
            if `ipos'>0 {
              * count omitted categories in variable
                local nomit = `varinfo'[5,`ipos']
                if ("`nomit'"==".") local nomit = 0
                local isomit `r(omit)'
                if "`isomit'"!="" {
                    if (`isomit'!=0) matrix `varinfo'[5,`ipos'] = `nomit'+1
                }
              * base category
                local isbase `r(base)'
                local islevel `r(level)'
                if "`isbase'"!="" {
                    if (`isbase'==1) matrix `varinfo'[4,`ipos'] = `islevel'
                }
                forvalues i = 1(1)10 {
                    matrix `betainfo'[`i',`ibnm'] = `varinfo'[`i',`ipos']
                }
            }
        }

        * labeled as variable?
        *local isvariable = 0
        *if ("`r(type)'"=="variable") local isvariable = 1
        * labeled as factor?
        local isfactor = 0
        if ("`r(type)'"=="factor") local isfactor = 1
        local isomit = r(omit)
        local ilevel = r(level)
        matrix `betainfo'[11,`ibnm'] = `isfactor'
        matrix `betainfo'[12,`ibnm'] = `isomit'
        matrix `betainfo'[13,`ibnm'] = `ilevel'

    } // columns of e(b)

//  returns

    return matrix betainfo = `betainfo'
    return matrix varinfo = `varinfo'

    return local cmdnm         "`cmdnm'"
    return local cmdbin        "`cmdbin'"
    return local cmdnrm        "`cmdnrm'"
    return local cmdcrm        "`cmdcrm'"
    return local cmdsvy        "`cmdsvy'"
    return local cmdn          "`cmdn'"
    return local lhsnm         "`lhsnm'"
    return local lhsnm2        "`lhsnm2'" // for intreg
    return local lhsbaseval    `lhsbaseval'
    return local lhsvalues     "`lhsvalues'"
    return local lhscatn       "`lhscatn'"
    return local lhscatnms     "`lhscatnms'"
    return local lhscatnms8     "`lhscatnms8'"
    return local lhscatvals    "`lhscatvals'"
    return local rhsnms        "`rhsnms'"
    return local rhsn          `rhsn'
    return local rhsnms2       "`rhsnms2'"
    return local rhsn2         `rhsn2'
    return local rhs_core      "`rhs_core'"
    return local rhs_fvbin     "`rhs_fvbin'"
    return local rhs_fvcat     "`rhs_fvcat'"
    return local rhs_notfv     "`rhs_notfv'"
    return local rhs_fv        "`rhs_fv'"
    return local rhs_fvint     "`rhs_fvint'"
    return local rhs_fvintself "`rhs_fvintself'"
    return local rhs_fvintselfonly   "`rhs_fvintselfonly'"
    return local rhs_fvintother  "`rhs_fvintother'"
    return local rhs2_core       "`rhs2_core'"
    return local rhs2_fvbin      "`rhs2_fvbin'"
    return local rhs2_fvcat      "`rhs2_fvcat'"
    return local rhs2_fv         "`rhs2_fv'"
    return local rhs2_notfv      "`rhs2_notfv'"
    return local rhs2_fvint      "`rhs2_fvint'"
    return local rhs2_fvintself  "`rhs2_fvintself'"
    return local rhs2_fvintselfonly   "`rhs2_fvintselfonly'"
    return local rhs2_fvintother "`rhs2_fvintother'"

end
exit

_rm_modelinfo
return list
foreach s in cmdnm cmdbin cmdnrm cmdsvy cmdn lhsnm lhsvalues lhscatn ///
        lhscatnms lhscatvals rhsnms rhsn rhsnms2 rhsn2 ///
        rhsfvtypes rhsfvtypes2 {
    di "`s': " _col(20) "`r(`s')'"
}

* version 1.0.0 2012-08-08 scott long
* version 1.1.0 2012-08-26 jsl | add fv type | sclass fv types
* version 1.1.1 2012-09-03 jsl | slogit like mlogit | posted
* version 1.1.5 2012-09-19 | long freese | e(N)
* version 1.1.4 2012-09-18 | long freese | intereg lhsnm2
* version 1.1.3 2012-09-16 | long freese | cmdcrm
* version 1.1.2 2012-09-04 | long freese | remove 0b.
* version 1.1.6 2012-09-19 | long freese | i.catvar, rclass varinfo matrix
* version 1.1.7 2012-09-19 | long freese | int info

