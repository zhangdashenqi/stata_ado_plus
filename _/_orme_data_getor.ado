*! version 2.1.0 2014-02-14 | long | spost13 release

//  get estimates estimates from mlogit; create matrices with coefs to plot

capture program drop _orme_data_getor
program _orme_data_getor, sclass

    version 11.2
    args noisily
    qui `noisily' di _new "    > entering  _orme_data_getor"

    local CcatsN "`_orme[CcatsN]'"
    local Camountfull "`_orme[Camountfull]'"
    local Cplotexpand "`_orme[Cplotexpand]'"
    local CplotvarsN  "`_orme[CplotvarsN]'"
    local Conelabel `"`_orme[Conelabel]'"'
    local Cbinlabel `"`_orme[Cbinlabel]'"'
    local Crnglabel `"`_orme[Crnglabel]'"'
    local Csdlabel `"`_orme[Csdlabel]'"'
    local Cmarglabel `"`_orme[Cmarglabel]'"'
    local Cebaseout "`_orme[Cebaseout]'"
    local Ccatvals `"`_orme[Ccatvals]'"'
    local catvalsnobase : list Ccatvals - Cebaseout
    local error = 0

    tempname matsd matrange

    _rm_sum if e(sample)
    matrix `matsd' = r(matsd)
    matrix `matrange' = r(matmax) - r(matmin)
    matrix `matsd' = `matsd'[1,2...]
    matrix `matrange' = `matrange'[1,2...]
    _rm_mlogitbv _orme_B _orme_V

    local betanms : colnames(_orme_B) // including _cons
    local betanmsN = wordcount("`betanms'")
    local betanms : subinstr local betanms "n." ".", all
    local betanms : subinstr local betanms "b." ".", all
    matrix _orme_Ball = _orme_B // matrix of all estimates
    local nrows = `CcatsN' - 1
    matrix _orme_B = J(`nrows',`CplotvarsN',.) // unstd to plot
    matrix _orme_Bstd = _orme_B // std betas to plot
    matrix _orme_Brng = _orme_B // rng betas to plot

    local colnm ""
    local iplotrow = 0
    foreach plotvarnm in `Cplotexpand' { // loop through plot vars

        * find plot name in list of beta names
        local ibeta : list posof "`plotvarnm'" in betanms
        local betanm "`plotvarnm'"
        local colnm `"`colnm'`betanm' "'
        * if me's are used, some of this is replaced with _data_getme
        local ++iplotrow
        char _orme[PLbetacol`iplotrow'] `"`ibeta'"'
        char _orme[PLbetanm`iplotrow'] `"`betanm'"'
        char _orme[PLbetanum`iplotrow'] `"`iplotrow'"'
        _ms_parse_parts `betanm'
        local level `r(level)'
        char _orme[PLvarnm`iplotrow'] `"`r(name)'"'
        local varnm "`r(name)'"
        local varlbl : var lab `varnm'
        char _orme[PLvarlabel`iplotrow'] `"`varlbl'"'
        char _orme[PLcorenm`iplotrow'] `"`varnm'"'
        char _orme[PLlevel`iplotrow'] `"`r(level)'"'
        char _orme[PLtype`iplotrow'] `"`r(type)'"' // factor or variable

        if "`r(type)'"=="factor" {
            _rm_get_base `r(name)'
            local pwnum "`level'vs`r(base)'"
            _rm_pwnames, var(`varnm')
            forvalues i = 1/`s(npw)' {
                local numlabel "`s(numlabel`i')'"
                if "`numlabel'"=="`pwnum'" {
                    local pwnum "`numlabel'"
                    local pwtxt `"`s(txtlabel`i')'"'
                    continue, break
                }
            }
            char _orme[PLpwnum`iplotrow'] `"`pwnum'"'
            char _orme[PLpwtxt`iplotrow'] `"`pwtxt'"'
            char _orme[PLamountlabel`iplotrow'] `"`pwtxt'"'
            char _orme[PLamount`iplotrow'] "bin"
        }
        else {
            local amountis : word `iplotrow' of `Camountfull'
            char _orme[PLamount`iplotrow'] `amountis'
            char _orme[PLamountlabel`iplotrow'] `"`C`amountis'label'"'
        }
        local sd = `matsd'[1,`ibeta']
        local rng = `matrange'[1,`ibeta']
        local ncatm1 = `CcatsN' - 1
        forvalues icat = 1/`ncatm1' {
            mat _orme_B[`icat',`iplotrow'] = _orme_Ball[`icat',`ibeta']
            mat _orme_Bstd[`icat',`iplotrow'] = _orme_B[`icat',`iplotrow']*`sd'
            mat _orme_Brng[`icat',`iplotrow'] = _orme_B[`icat',`iplotrow']*`rng'
        }


    } // vars being plotted

    matrix rowna _orme_B = `catvalsnobase'
    matrix colna _orme_B = `colnm'
    matrix rowna _orme_Bstd = `catvalsnobase'
    matrix colna _orme_Bstd = `colnm'
    matrix rowna _orme_Brng = `catvalsnobase'
    matrix colna _orme_Brng = `colnm'
    sreturn local error = `error'
    qui `noisily' di _new "    ! leaving   _orme_data_getor"

end

exit
qui `noisily' matlist _orme_B, title(_orme_B)
qui `noisily' matlist _orme_V, title(_orme_V)
qui `noisily' matlist _orme_Bstd, title(_orme_Bstd)
qui `noisily' matlist _orme_Brng, title(_orme_Brng)
