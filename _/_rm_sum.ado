*! version 1.1.0 2014-10-22 | long freese | mean if svy fv
* version 1.0.0 2014-02-14 | long freese | spost13 release

//  compute summary statistics for RHS variables from last model estimated

program define _rm_sum, rclass

    version 11.2

    tempname matmn matsd matmin matmax matdummy matmedian matN m v model

    syntax [fweight aweight pweight] [if] [in] [ , Median Dummy Two ]

    local issvy = 0
    if ("`e(prefix)'"=="svy") local issvy = 1
    if `issvy' { // since svy commands return e()'s
        estimates store `model'
    }

    //  weights: check if wts used with the  estimation command.

    local wtis "[`weight'`exp']"

    if "`wtis'"=="" & "`e(wtype)'"!="" {
        local weight "`e(wtype)'"
        local wtis "[`e(wtype)'`e(wexp)']"
    }

    if "`weight'"=="pweight" {
        local wtis "[aweight`e(wexp)']"
        display "note: pweights are treated as aweights to" ///
            " compute standard deviations"
    }
    if "`weight'"=="iweight" {
        display as error "iweights cannot be used for this command"
        exit
    }

    _rm_modelinfo2
    local nvars = `r(rhsn)' + 1
    local varnms "`r(lhsnm)' `r(rhsnms)'"
    if "`two'"=="two" {
        local nvars = `r(rhsn2)' + 1
        local varnms "`r(lhsnm)' `r(rhsnms2)'"
    }
    * intreg has two lhs vars; select the first
    if "`e(cmd)'"=="intreg" {
        local nmtoget : word 1 of `varnms'
        local varnms "`nmtoget' `r(rhsnms)'"
    }

    matrix `matmn'     = J(1,`nvars',-99999)
    matrix colnames      `matmn' = `varnms'
    matrix `matsd'     = `matmn'
    matrix `matmin'    = `matmn'
    matrix `matmax'    = `matmn'
    matrix `matdummy'  = `matmn'
    matrix `matmedian' = `matmn'

    local ivar = 1
    while `ivar'<=`nvars' {

        local nmtoget : word `ivar' of `varnms'
        qui sum `nmtoget' `wtis' `if' `in'
        scalar `matN' = r(N)
        if `matN' == 0 {
            return scalar matN = `matN'
            display as error "estimation sample size is 0"
            exit
            continue
        }
        * works for svy or non-svy with or without weights
        matrix `matmin'[1,`ivar'] = r(min)
        matrix `matmax'[1,`ivar'] = r(max)

        if `issvy' {

            * if . in name, it is an expanded factor variable
            local isfv = strpos("`nmtoget'",".")>0

            if `isfv' == 0 { // not fv, use svy:mean
                qui capture svy : mean  `nmtoget' `if' `in'
                if _rc!= 0 {
                    display as error ///
                    "cannot compute svy : mean required for results"
                    exit _rc
                    continue
                }
                qui estat sd // sd with svy
                matrix `m' = r(mean)
                scalar `v' = `m'[1,1]
                matrix `matmn'[1,`ivar'] = `v'
                matrix `m' = r(sd)
                scalar `v' = `m'[1,1]
                matrix `matsd'[1,`ivar'] = `v'
            }
            else { // is factor variable, so missing
                matrix `matmn'[1,`ivar'] = .
                matrix `matsd'[1,`ivar'] = .
            }
        }
        else { // not svy use results from sum
            matrix `matmn'[1,`ivar'] = r(mean)
            matrix `matsd'[1,`ivar']   = sqrt(r(Var))
        }

        if "`dummy'"=="dummy" {
            capture assert `nmtoget' == 0 | `nmtoget' == 1 | `nmtoget' == . ///
                `if' `in'
            local isdummy = _rc==0
            matrix `matdummy'[1,`ivar'] = `isdummy'
        }
        if "`median'"=="median" {
            if `issvy' {
                display as error "the median cannot be computed with svy"
                exit
                continue
            }
            _ms_parse_parts `nmtoget'
            if "`r(type)'" != "variable" {
                qui summarize `nmtoget', detail
                matrix `matmedian'[1,`ivar'] = r(p50)
            }
            else {
                qui _pctile `nmtoget' `if' `in' `wtis'
                matrix `matmedian'[1,`ivar'] = r(r1)
            }
        }
        local ++ivar
    } // loop over variables

    return matrix matmn     `matmn'
    return matrix matsd     `matsd'
    return matrix matmin    `matmin'
    return matrix matmax    `matmax'
    return matrix matdummy  `matdummy'
    return matrix matmedian `matmedian'
    return scalar matN = `matN'

    if `issvy' {
        qui estimates restore `model'
    }

end
exit
