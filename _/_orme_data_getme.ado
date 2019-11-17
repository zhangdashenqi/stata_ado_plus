*! version 2.1.1 2014-07-28 | long | amount error and typos
 * version 2.1.0 2014-02-14 | long | spost13 release

//  get marginal effect information from last model

capture program drop _orme_data_getme
program _orme_data_getme, sclass

    version 11.2
    args noisily
    qui `noisily' di _new "    ! entering  _orme_data_getme"
    local Cmatrixstub "`_orme[Cmatrixstub]'"
    local Cplottype "`_orme[Cplottype]'"
    local Cplotcore "`_orme[Cplotcore]'"
    * 1 amount for each row segment of graph
    local Camountfull "`_orme[Camountfull]'"
    local Cplotvartypes `_orme[Cplotvartypes]'
    local Conelabel `"`_orme[Conelabel]'"'
    local Cbinlabel `"`_orme[Cbinlabel]'"'
    local Crnglabel `"`_orme[Crnglabel]'"'
    local Csdlabel `"`_orme[Csdlabel]'"'
    local Cdeltalabel `"`_orme[Csdlabel]'"'
    local Cmarglabel `"`_orme[Cmarglabel]'"'
    local isorplot = "`Cplottype'"=="orplot"
    local error = 0
    capture matrix drop _orme_ME
    capture matrix drop _orme_MEPV

    local memat "_mchange" // computed by mchange
    capture local mematncols = colsof(`memat')
    if "`mematncols'"=="" {
        display as error "marginal effects matrix is not in memory"
        local error = 1
        sreturn local error = `error'
        exit
    }

    local isdelta `_orme[Camountdelta]'

    * determine change amounts in _mchange
    local stripe : rownames _mchange
    local computedamounts ""

    foreach amt in bin one sd marg rng delta {
        local ipos = strpos("`stripe'","`amt'_")
        if (`ipos'>0) local computedamounts "`computedamounts'`amt' "
    }

    //  grab results computed by mchange

    local inum = 0 // number of variable in order of plots
    local corechecked ""
    foreach varnm in `Cplotcore' {

        gettoken coreis Cplotcore : Cplotcore
        gettoken amountis Camountfull : Camountfull
        * delta amount is labeled as delta not sd
        if (`isdelta' & "`amountis'"=="sd") local amountis "delta"
        gettoken typeis Cplotvartypes : Cplotvartypes
        local varlbl : var lab `varnm'
        if "`typeis'"=="variable" {
            local ipos : list posof "`amountis'" in computedamounts
            if `ipos'<1 {
                display as err "amount `amountis' not computed by mchange"
                display as err "note amount(sd) is assumed if amount() not specified"
                local error = 1
                continue, break
            }
            if `ipos'>0 { // amount was computed
                local ++inum
                char _orme[PLvarlabel`inum'] `"`varlbl'"'
                char _orme[PLamountlabel`inum'] `"`C`amountis'label'"'
                char _orme[PLcorenm`inum'] `"`varnm'"'
                char _orme[PLamount`inum'] `"`amountis'"'
                char _orme[PLtype`inum'] `"`typeis'"'
                char _orme[PLpwlabel`inum'] `"none"'
                char _orme[PLpwnum`inum'] `"none"'
                _rm_get_mchange, var(`varnm') st(ch) am(`amountis')
                local ismiss = matmissing(_mchange_vec)
                if `ismiss' {
                    display as err ///
"missing values found in marginal effects; run matlist _mchange for details."
                    local error = 1
                    continue, break
                }
                matrix _orme_ME = nullmat(_orme_ME) \ _mchange_vec
                _rm_get_mchange, var(`varnm') st(p) am(`amountis')
                matrix _orme_MEPV = nullmat(_orme_MEPV) \ _mchange_vec
            }
            local corechecked "`corechecked'`varnm' "
        }

        else { // type factor
            local icoreloc : list posof "`varnm'" in corechecked
            * only process each core variable once
            if `icoreloc'==0 {
                * if orplot, only keep pw with base category
                if `isorplot' { // find base category
                    _rm_get_base `varnm'
                    local base "vs`r(base)'"
                }
                _rm_pwnames, var(`varnm') // names of pw comparisons
                local npw = `s(npw)'
                * locals to hold name for each comparison used later
                forvalues ipw = 1/`npw' {
                    local pwnum`ipw' "`s(numlabel`ipw')'" // #vs#
                    local pwlabel`ipw' "`s(txtlabel`ipw')'" // txt vs txt
                }
                forvalues ipw = 1/`npw' {
                    * if orplot, don't get if base is not included
                    local hasbase = strpos("`pwnum`ipw''","`base'")
                    if !(`hasbase'==0 & `isorplot') {
                        local ++inum
                        char _orme[PLvarlabel`inum'] `"`varlbl'"'
                        char _orme[PLvarnm`inum'] `"`varnm'"'
                        char _orme[PLamount`inum'] `"`amountis'"'
                        char _orme[PLpwlabel`inum'] `"`pwlabel`ipw''"'
                        char _orme[PLpwnum`inum'] `"`pwnum`ipw''"'
                        char _orme[PLtype`inum'] `"`typeis'"'
                        char _orme[PLamountlabel`inum'] `"`pwlabel`ipw''"'
                        _rm_get_mchange, var(`varnm') st(ch) pw(`pwnum`ipw'')
                        matrix _orme_ME = nullmat(_orme_ME) \ _mchange_vec
                        _rm_get_mchange, var(`varnm') st(p) pw(`pwnum`ipw'')
                        matrix _orme_MEPV = nullmat(_orme_MEPV) \ _mchange_vec
                    }
                }
                local corechecked "`corechecked'`varnm' "
            } // is corevar new?
        } // is factor vars
    } // varnm

    sreturn local error = `error'
    qui `noisily' di _new "    ! leaving   _orme_data_getme"
end
exit
