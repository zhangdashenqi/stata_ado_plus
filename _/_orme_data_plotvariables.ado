*! version 2.1.0 2014-02-14 | long | spost13 release

//  create variables to be plotted with graph

program _orme_data_plotvariables, sclass

    version 11.2
    args noisily
    qui `noisily' di _new "    ! entering  _orme_data_plotvariables"

    local Camountfull `_orme[Camountfull]'
    local Ccatnms `"`_orme[Ccatnms]'"'
    local CcatsN `"`_orme[CcatsN]'"'
    local Ccatvals `"`_orme[Ccatvals]'"'
    local Cebaseout `"`_orme[Cebaseout]'"'
    local Cmatrixstub `"`_orme[Cmatrixstub]'"'
    local Cmeffects `"`_orme[Cmeffects]'"'
    local Coffsetfactor `"`_orme[Coffsetfactor]'"'
    local Coffsetlist `"`_orme[Coffsetlist]'"'
    local Coffsetsequence `"`_orme[Coffsetsequence]'"'
    local Cpacked `"`_orme[Cpacked]'"'
    local Cplotbase `"`_orme[Cplotbase]'"'
    local Cplotcore `_orme[Cplotcore]'
    local CplotvarsN `"`_orme[CplotvarsN]'"'
    local Cplotvartypes `_orme[Cplotvartypes]'

    * remove ebase from catvals
    local catvalsnobase : list Ccatvals - Cebaseout
    local pbaserow : list posof "`Cplotbase'" in catvalsnobase

    tempname pbase_rng pbase_std pbase_unstd Mamount Mamtnum
    tempvar tmpoffset
    tempname Mtmpbetas Mbeta Mme Mmepv Mbetanum Mvoffset Mcatnum Mcatloc

    * used to collect results before creating variables
    local ncoef = `CplotvarsN' * `CcatsN' // # coefs to plot
    matrix `Mbeta' = J(`ncoef',1,.) // betas to plot
    matrix `Mme' = `Mbeta' // me's to plot
    matrix `Mmepv' = `Mbeta' // pvalues for me's
    matrix `Mvoffset' = `Mbeta' // vertical offset
    matrix `Mbetanum' = `Mbeta' // variable number
    matrix `Mcatnum' = `Mbeta' // category number
    matrix `Mamtnum' = `Mbeta' // type of standardization
    matrix `Mcatloc' = `Mbeta' // loc of cat in catnms

//  compute e(b) coefficients to plot and retrieve me's

    if "`_orme[Cplottype]'"=="orplot" {

        forvalues iplotvar = 1/`CplotvarsN' {

            * for this var, start row in plot matrices is (catsN * #prior vars)
            * then offset this row by the category being computed
            local rowoffset = ((`iplotvar'-1)*`CcatsN')
            local betanum "`_orme[PLbetanum`iplotvar']'" // in e(b) matrix

            * coefficients for pbase category
            if `pbaserow' != 0 {
                scalar `pbase_unstd' = _orme_B[`pbaserow',`betanum']
                scalar `pbase_std' = _orme_Bstd[`pbaserow',`betanum']
                scalar `pbase_rng' = _orme_Brng[`pbaserow',`betanum']
            }
            * if pbase==ebase, use 0 = B_ebase|ebase
            else { // e(b) for pbaserow
                scalar `pbase_unstd' = 0
                scalar `pbase_std' = 0
                scalar `pbase_rng' = 0
            }

            * category index, NOT values
            forvalues icatindx = 1/`CcatsN' {

                local icatval : word `icatindx' of `Ccatvals'
                * location in beta matrix for this category
                local ibeta = rownumb(_orme_B,"`icatval'")
                local imatrow = `rowoffset' + `icatindx'

                if `ibeta'==. { // ebase category
                    matrix `Mbeta'[`imatrow',1] = 0 - `pbase_unstd'
                }
                else { // not ebase cateogry
                    matrix `Mbeta'[`imatrow',1] ///
                    = _orme_B[`ibeta',`betanum'] - `pbase_unstd'
                }
                local amtis "`_orme[PLamount`iplotvar']'"
                if "`amtis'"=="marg" matrix `Mamtnum'[`imatrow',1] = 5
                else if ("`amtis'"=="one") matrix `Mamtnum'[`imatrow',1] = 1
                else if ("`amtis'"=="bin") matrix `Mamtnum'[`imatrow',1] = 2
                else if ("`amtis'"=="sd") {
                    matrix `Mamtnum'[`imatrow',1] = 3
                    if `ibeta'==. {
                        matrix `Mbeta'[`imatrow',1] = 0 - `pbase_std'
                    }
                    else {
                        matrix `Mbeta'[`imatrow',1] ///
                            = _orme_Bstd[`ibeta',`betanum'] - `pbase_std'
                    }
                }
                else if "`amtis'"=="rng" {
                    matrix `Mamtnum'[`imatrow',1] = 4
                    if `ibeta'==. {
                        matrix `Mbeta'[`imatrow',1] = 0 - `pbase_rng'
                    }
                    else {
                        matrix `Mbeta'[`imatrow',1] ///
                            = _orme_Brng[`ibeta',`betanum'] - `pbase_rng'
                    }
                }
                matrix `Mbetanum'[`imatrow',1] = `iplotvar' // beta# of coef
                matrix `Mcatnum'[`imatrow',1] =  `icatval' // cat# for coef

                * local of category in Ccatvals or Ccatnms
                matrix `Mcatloc'[`imatrow',1] = `icatindx'

                * grab MEs and betas corresponding to each plot symbol
                if "`Cmeffects'"=="meffects" {
                    matrix `Mme'[`imatrow',1] ///
                        = _orme_ME[`iplotvar',`icatindx']
                    matrix `Mmepv'[`imatrow',1] ///
                        = _orme_MEPV[`iplotvar',`icatindx']
                }
                else {
                    matrix `Mme'[`imatrow',1] = 1
                    matrix `Mmepv'[`imatrow',1] = 0
                }
            }
        } // compute coefs to plot
    } // orplot

//  me plot

    if "`_orme[Cplottype]'"=="meplot" {

        local imatrow = 0
        forvalues iplotvar = 1/`CplotvarsN' {

            gettoken amtis Camountfull : Camountfull

            forvalues icatindx = 1/`CcatsN' {

                local ++imatrow

                local icatval : word `icatindx' of `Ccatvals'
                matrix `Mcatnum'[`imatrow',1] = `icatval' // cat# for coef
                matrix `Mcatloc'[`imatrow',1] = `icatindx'
                matrix `Mbetanum'[`imatrow',1] = `iplotvar' // var# for coef

                matrix `Mme'[`imatrow',1] = _orme_ME[`iplotvar',`icatindx']
                matrix `Mmepv'[`imatrow',1] = _orme_MEPV[`iplotvar',`icatindx']

                if "`amtis'"=="one" matrix `Mamtnum'[`imatrow',1] = 1
                else if "`amtis'"=="bin" matrix `Mamtnum'[`imatrow',1] = 2
                else if "`amtis'"=="sd" matrix `Mamtnum'[`imatrow',1] = 3
                else if "`amtis'"=="rng" matrix `Mamtnum'[`imatrow',1] = 4
                else if "`amtis'"=="marg" matrix `Mamtnum'[`imatrow',1] = 5

            }
        } // compute coefs to plot

        matrix `Mbeta' = `Mme'
    }

//  vertical offsets for symbols within variable

    if "`Coffsetlist'"!="" { // offset list entered as plot option
        local iloc = 0
        forvalues iplotvar = 1/`CplotvarsN' {
            forvalues icat = 1/`CcatsN' {
                local ++iloc
                local offset : word `iloc' of `Coffsetlist'
                * +5 changes -5/5 to 0/10; /10 for 0 to 1 range
                local offset = (`offset'+5)/10
                if "`Cpacked'"!="packed" matrix `Mvoffset'[`iloc',1] = `offset'
                else matrix `Mvoffset'[`iloc',1] = 0
            }
        }
    }

    if "`Coffsetlist'"=="" { // compute offsets
        local offseq "`Coffsetsequence' "
        forvalues i = 1/10 { // duplicate sequnce
            local offseq "`offseq' `offseq' "
        }

        * each variable uses this as the basis for offsets
        local sourceoffseq ""
        forvalues icat = 1/`CcatsN' {
            gettoken offis offseq : offseq
            local sourceoffseq "`sourceoffseq'`offis' "
        }

        forvalues iplotvar = 1/`CplotvarsN' {

            local offseq "`sourceoffseq'" // start each var with same sequence
            * get beta's for current variable
            local istrt = ((`iplotvar'-1)*`CcatsN') + 1
            local iend  = `istrt' + `CcatsN' - 1
            matrix `Mtmpbetas' = `Mbeta'[`istrt'..`iend',1] // iplotvar's betas

            * 2014-01-01 same offsets used for all variables
            forvalues icat = 1/`CcatsN' {
                gettoken offis offseq : offseq
                local ichng = `istrt' + `icat' - 1
                if ("`Cpacked'"!="packed") matrix `Mvoffset'[`ichng',1] = `offis'
                else matrix `Mvoffset'[`ichng',1] = 0
            } // categories

        } // plotvars
    } // no offset list

//  create variables from the matrices

    foreach matnm in beta me mepv amtnum betanum voffset catnum catloc {
        matrix colnames `M`matnm'' = _PLT_`matnm'
        svmat           `M`matnm'', names(col)
    }
    label var _PLT_beta "beta (or me) to plot"
    label var _PLT_catnum "category # associated with beta"
    label var _PLT_catloc "category location in Ccatnms Ccatvals"
    label var _PLT_me "marginal effect"
    label var _PLT_mepv "pvalue for marginal effect"
    label var _PLT_amtnum "1=one 2=bin 3=sd 4=rng 5=marg"
    label var _PLT_betanum "beta number of coefficients"
    label var _PLT_voffset "vertical offset for plot symbol"

    qui {
        gen str8 _PLT_amount = ""
        label var _PLT_amount "one bin sd rng marg"
        replace _PLT_amount = "one" if _PLT_amtnum==1
        replace _PLT_amount = "bin" if _PLT_amtnum==2
        replace _PLT_amount = "sd" if _PLT_amtnum==3
        replace _PLT_amount = "rng" if _PLT_amtnum==4
        replace _PLT_amount = "marg" if _PLT_amtnum==5
    }
    note _PLT_beta: "_orme_data_plotvariables"
    note _PLT_catnum: "_orme_data_plotvariables"
    note _PLT_catloc: "_orme_data_plotvariables"
    note _PLT_me: "_orme_data_plotvariables"
    note _PLT_mepv: "_orme_data_plotvariables"
    note _PLT_amtnum: "_orme_data_plotvariables"
    note _PLT_amount: "_orme_data_plotvariables"
    note _PLT_betanum: "_orme_data_plotvariables"
    note _PLT_voffset: "_orme_data_plotvariables"

    qui sum _PLT_betanum
    local ymax = r(max)
    qui gen _PLT_betanumrev = (`ymax' + 1) - _PLT_betanum
    label var _PLT_betanumrev "_PLT_betanum in reverse order"

    * information on marginal effects
    qui gen _PLT_meabs = abs(_PLT_me)
    lab var _PLT_meabs "absolute value of marginal effect"
    note _PLT_meabs: "_orme_data_plotvariables"

    qui gen _PLT_meneg = _PLT_me < 0
    lab var _PLT_meneg "marginal effect is negative?"
    note _PLT_meneg: "_orme_data_plotvariables"

    qui sum _PLT_meabs
    local maxme = r(max)
    qui gen _PLT_mescaled = _PLT_meabs / `maxme'
    lab var _PLT_mescaled "ME values scaled to have max of 1"
    note _PLT_mescaled: "_orme_data_plotvariables"

// offsets for vertical axis

    if "`Cpacked'" != "packed" {

        qui sum _PLT_voffset
        local offmax = r(max)
        local offmin = r(min)
        local offrng = r(max) - r(min)
        local offmean = r(mean)
        local offrange = .5 // ??

        if "`Coffsetlist'"=="" {
            qui gen `tmpoffset' = ///
                ( ( (_PLT_voffset-`offrng') / `offrng') + .5 ) ///
                    * `offrange'     /// default spread
                    * `Coffsetfactor' // user adjustment
        }
        * if sequence input as option, don't rescale
        else qui gen `tmpoffset' = _PLT_voffset - .5
    }
    else qui gen `tmpoffset' = 0 // packed

    qui gen _PLT_betanumoffset = (_PLT_betanumrev + `tmpoffset')
    label var _PLT_betanumoffset "Variable number with offset added"
    note _PLT_betanumoffset: "_orme_data_plotvariables"

//  variable with first letter of category name used as plot symbol

    if "`Cmatrixstub'"=="" {

        qui generate str1 _PLT_catstr = ""
        note _PLT_catstr: "_orme_data_plotvariables"
        label var _PLT_catstr "category string for beta"
        forvalues icat = 1/`CcatsN' {
            local ltr : word `icat' of `Ccatnms'
            local val : word `icat' of `Ccatvals'
            *DO: make changes here to allow two or more letters
            local ltr = substr("`ltr'",1,1)
            qui replace _PLT_catstr = "`ltr'" if _PLT_catnum==`val'
        }
    }
    if "`Cmatrixstub'"!="" {

        *DO: add matrix input

    } // matrix

qui `noisily' di _new "    ! leaving   _orme_data_plotvariables"

end
exit
