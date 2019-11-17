*! version 2.1.0 2014-02-14 | long | spost13 release

//  get data for plotting

capture program drop _orme_data
program define _orme_data, sclass

    version 11.2
    args noisily

qui `noisily' di _new "    ! entering  _orme_data"

    local error = 0
    local Cplotbase "`_orme[Cplotbase]'"
    local Ccatvalmax "`_orme[Ccatvalmax]'"
    local Cmatrixstub "`_orme[Cmatrixstub]'"
    local CplotvarsN "`_orme[CplotvarsN]'"
    local Cmeffects "`_orme[Cmeffects]'"
    local CcatsN "`_orme[CcatsN]'"
    local Ccatvals "`_orme[Ccatvals]'"
    local Coffsetlist "`_orme[Coffsetlist]'"
    local Coffsetsequence "`_orme[Coffsetsequence]'"
    local Cplottype "`_orme[Cplottype]'"

//  create variables with beta estimates & stats for rhs variables
//
//  variables:  _P_EVsd     SD of rhs variables
//              _P_EVbin    rhs variables binary?
//              _P_EVrng    range of rhs variables
//  matrices    _orme_B     unstd beta
//              _orme_V     variance
//              _orme_Bstd  std coef
//              _orme_Brng  range coef
//              _orme_MEPV
//              _orme_MEB

    if "`Cmatrixstub'"!="" {
        qui `noisily' di _new "    ! going to  _orme_data_getmatrix"
        _orme_data_getmatrix `noisily'
        qui `noisily' di _new "    ! back from _orme_data_getmatrix"
    }

    if "`Cplottype'"=="orplot" & "`Cmatrixstub'"=="" {

        local ipos : list posof "`Cplotbase'" in Ccatvals
        if `ipos' == 0 {
            di as error "specified plot base is not an outcome category"
            sreturn local error = 1
            exit
        }

        qui `noisily' di _new "    ! going to  _orme_data_getor"
        _orme_data_getor `noisily'
        qui `noisily' di _new "    ! back from _orme_data_getor"
        if (`s(error)'==1) exit

        if "`Coffsetlist'"!="" {
            local noffsetlist = wordcount("`Coffsetlist'")
            local nvarcat = `CcatsN'*`CplotvarsN'
            if `noffsetlist'!=`nvarcat' {
                di as error ///
                "offsetlist() needs `nvarcat' elements, one for each" ///
                " variable by category pair"
                sreturn local error = 1
                exit
            }
        }
        else {
            if "`Coffsetsequence'" == "" {
                local Coffsetsequence "1 2 0"
                char _orme[Coffsetsequence] `"`Coffsetsequence'"'
            }
        }
    }

//  get marginal effect; matrix row is variable; column is category

    if "`Cmeffects'"=="meffects" | "`Cplottype'"=="meplot" ///
            & "`Cmatrixstub'"==""{

        qui `noisily' di _new "    ! going to  _orme_data_getme"
        _orme_data_getme `noisily'
        if `s(error)'==1 exit
        qui `noisily' di _new "    ! back from _orme_data_getme"

    }

//  create plot variables

    qui `noisily' di _new "    ! going to  _orme_data_plotvariables"
    _orme_data_plotvariables `noisily'
    qui `noisily' di _new "    ! back from _orme_data_plotvariables"

//  create coordinates for connection lines

    qui `noisily' di _new "    ! going to  _orme_data_plotpairs"
    _orme_data_plotpairs `noisily' // meplot dummies out things here...
    qui `noisily' di _new "    ! back from _orme_data_plotpairs"

//  close up

    sreturn local error = `error'
    qui `noisily' di _new "    ! leaving   _orme_data"

end
exit
