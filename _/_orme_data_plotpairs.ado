*! version 2.2.0 2016-09-14 | long | t-dist for svy
* version 2.1.0 2014-02-14 | long | spost13 release

//  create variables with coordinate pairs for orplot connecting lines

program _orme_data_plotpairs, sclass

    qui `noisily' di _new "    > entering  _orme_data_plotpairs"
    version 11.2
    args noisily
    local Clinepvalues "`_orme[Clinepvalues]'"
    local Cmatrixstub "`_orme[Cmatrixstub]'"
    local Ccatnms `_orme[Ccatnms]'
    local CcatsN `_orme[CcatsN]'
    local Ccatvals `_orme[Ccatvals]'
    local Cplotexpand `_orme[Cplotexpand]' // names of e(b)'s
    local CplotvarsN `"`_orme[CplotvarsN]'"'

    tempname se est z p sig linedata pairsall pairs pairsFT pairsFTall msig df

//  setup matrix to hold pairs of information : dummy info for meplot

    if ("`_orme[Cplottype]'"=="meplot") local npairs = 1
    else local npairs = (`CcatsN'*(`CcatsN'-1))/2
    matrix `pairs' = J(`npairs',11,.)
    matrix colnames `pairs' ///
        = _PLT_catXfrom _PLT_catYfrom  _PLT_catXto    _PLT_catYto ///
          _PLT_catCfrom _PLT_catCto    _PLT_catZvalue _PLT_catPvalue ///
          _PLT_catB     _PLT_catBcheck _PLT_catSig
    matrix `pairsFT' = J(`npairs',2,.) // hold from from - to locations

// orplot

    if "`_orme[Cplottype]'"=="orplot" {

        if "`Cmatrixstub'"!="" {
            matrix `msig' = `matrixstub'pval
            local nrows = rowsof(`msig')
            local ncols = colsof(`msig')
            local dolines = 1
            if (`nrows'==1 & `ncols'==1) local dolines = 0
        }

        local ipairtotal = 0
        forvalues iplotvar = 1/`CplotvarsN' {

            local iplotvarnm : word `iplotvar' of `Cplotexpand'

            * locations in _PLT_..[] for this variable
            local irowS = ((`iplotvar'-1)*`CcatsN') + 1
            local irowE = `irowS' + `CcatsN' - 1

            matrix `linedata' = J(`CcatsN',4,.)
            matrix colna `linedata' = xcoord ycoord catval catloc

            * loop through coefficients for this plotvar
            local ilinedatrow = 0
            forvalues r = `irowS'/`irowE' {
                local ++ilinedatrow

                local xis = _PLT_beta[`r'] // xcoord for OR
                local xis = string(`xis',"%11.3f")
                matrix `linedata'[`ilinedatrow',1] = `xis'

                local yis = _PLT_betanumoffset[`r'] // ycoord for OR
                local yis = string(`yis',"%11.3f")
                matrix `linedata'[`ilinedatrow',2] = `yis'

                local catnum = _PLT_catnum[`r'] // category
                matrix `linedata'[`ilinedatrow',3] = `catnum'

                local catloc = _PLT_catloc[`r'] // location of category
                matrix `linedata'[`ilinedatrow',4] = `catloc'
            }

            * compute contrasts F to T
            local catsNm1 = `CcatsN' - 1
            local ipairvar = 0
            local irowF = 0
            forvalues catlocF = 1/`catsNm1' {

                local catnmF : word `catlocF' of `Ccatnms'
                local catvalF : word `catlocF' of `Ccatvals'

                local ++irowF // row for FROM category
                local irowT = `irowF' - 1 // row for TO category

                forvalues catlocT = `catlocF'/`CcatsN' { // loop categories

                    local ++irowT

                    local catnmT : word `catlocT' of `Ccatnms'
                    local catvalT : word `catlocT' of `Ccatvals'

                    if (`catlocT'==`catlocF') continue

                    local ++ipairvar
                    local ++ipairtotal

                    if "`Cmatrixstub'"=="" {

                        * contrasts F to T
                    qui lincom [`catvalF']`iplotvarnm' - [`catvalT']`iplotvarnm'
                        scalar `se' = r(se)
                        scalar `est' = r(estimate)
                        scalar `z' = `est'/`se'

// 2016-09-14
scalar `df' = r(df)
if `df' < . {
    scalar `p' = 2*(1-t(`df',abs(`z'))) // pvalue 2 tailed
}
else {
    scalar `p' = 2*(1-normal(abs(`z'))) // pvalue 2 tailed
}

                        local siglvl "`Clinepvalues'"

                        * different levels of nonsignificance
                        local nsiglvl = wordcount("`siglvl'")
                        * eg: if p<=.05             ==0 no line
                        *     if p>.05 and <=.10    ==1 dash
                        *     if p>.10 and <=.99    ==2 solid
                        local sig = 0 // is sig, no line
                        forvalues ilvl = 1/`nsiglvl' {
                            local isig : word `ilvl' of `siglvl'
                            if (`p'>`isig') local sig = `ilvl'
                        }
                    }

                    else { // matrix input

                        if "`Cmatrixstub'"!="" {
                            if `dolines' local p = `msig'[1,`ipairtotal']
                            else local p = 0
                            local siglvl "`Clinepvalues'"
                            local nsiglvl = wordcount("`siglvl'")
                            local sig = 0 // is sig, no line
                            forvalues ilvl = 1/`nsiglvl' {
                                local isig : word `ilvl' of `siglvl'
                                if (`p'>`isig') local sig = `ilvl'
                            }
                        }
                        else local sig = .
                        scalar `se' = .
                        scalar `est' = .
                        scalar `z' = .
                    }

                    matrix `pairs'[`ipairvar',7] = `z'
                    matrix `pairs'[`ipairvar',8] = `p'
                    matrix `pairs'[`ipairvar',9] = `est'
                    matrix `pairs'[`ipairvar',11] = `sig'
                    matrix `pairsFT'[`ipairvar',1] = `catlocF'
                    matrix `pairsFT'[`ipairvar',2] = `catlocT'

                    * coordinates for lines
                    local xF = `linedata'[`irowF',1]
                    local xT = `linedata'[`irowT',1]
                    local yF = `linedata'[`irowF',2]
                    local yT = `linedata'[`irowT',2]
                    local cF = `linedata'[`irowF',3]
                    local cT = `linedata'[`irowT',3]
                    matrix `pairs'[`ipairvar',1] = `xF'
                    matrix `pairs'[`ipairvar',2] = `yF'
                    matrix `pairs'[`ipairvar',3] = `xT'
                    matrix `pairs'[`ipairvar',4] = `yT'
                    matrix `pairs'[`ipairvar',5] = `cF'
                    matrix `pairs'[`ipairvar',6] = `cT'
                    matrix `pairs'[`ipairvar',10] = `xF' - `xT'

                } // loop over TO categories

            } // loop over FROM categories

            matrix `pairsall' = (nullmat(`pairsall') \ `pairs')
            matrix `pairsFTall' = (nullmat(`pairsFTall') \ `pairsFT')

        } // loop variables to compute pairs

    } // orplot

//  meplot - no pair information is used

    else matrix `pairsall' = `pairs'

//  variables for plotting connecting lines

    svmat `pairsall', names(col)

    label var _PLT_catXfrom "pair x from coordinate"
    label var _PLT_catYfrom "pair y from coordinate"
    label var _PLT_catXto "pair x to coordinate"
    label var _PLT_catYto "pair y to coordinate"
    label var _PLT_catCfrom "from category"
    label var _PLT_catCto "to category"
    label var _PLT_catZvalue "z-value for contrast"
    label var _PLT_catPvalue "p-value"
    label var _PLT_catB "contrast estiamte"
    label var _PLT_catBcheck "pair x from - x to"
    label var _PLT_catSig "sig level"
    note _PLT_catXfrom: _orme_data_plotpairs
    note _PLT_catYfrom: _orme_data_plotpairs
    note _PLT_catXto: _orme_data_plotpairs
    note _PLT_catYto: _orme_data_plotpairs
    note _PLT_catCfrom: _orme_data_plotpairs
    note _PLT_catCto: _orme_data_plotpairs
    note _PLT_catZvalue: _orme_data_plotpairs
    note _PLT_catPvalue: _orme_data_plotpairs
    note _PLT_catB: _orme_data_plotpairs
    note _PLT_catBcheck: _orme_data_plotpairs
    note _PLT_catSig: _orme_data_plotpairs

    qui `noisily' di _new "    ! leaving   _orme_data_plotpairs"

end
exit

