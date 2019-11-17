*! version 0.4.6 2013-04-25 | long freese | upgrade matrix

//  create variables with coordinate pairs for orplot connecting lines

//  called by:  _ordcplot_data

capture program drop _ordcplot_data_plotpairs
program _ordcplot_data_plotpairs, sclass

    version 11.2

    args  P_varnms E_catnms OPTlinepvalue matrixstub

    local ismatrix = ("`matrixstub'"!="")

    tempname se est z p sig linedata pairsall pairs pairsFT pairsFTall msig

    * variables to plot
    local P_varnms `_ordc[plt_rhsNMS]'
    * names of categories from estimates
    local E_catnms `_ordc[est_catNMS]'

    * range of variable numbers
    qui sum _P_PVvarnumrev
    local vars_start = r(min)
    local vars_end = r(max)

    * category info
    qui sum _P_PVcatnum
    local cat_start = r(min)
    local cat_end = r(max)
    qui tab _P_PVcatnum
    local ncats = r(r) // number of categories

//  setup matrix to hold pairs of information

    * no pairs of dcplot
    if ("`_ordc[_plot_type_]'"=="dcplot") local npairs = 1
    else local npairs = (`cat_end'*(`cat_end'-1))/2

    * hold data to create plot variables
    matrix `pairs' = J(`npairs',11,.)
    matrix colnames `pairs' ///
        = _P_PVcatXfrom  _P_PVcatYfrom   _P_PVcatXto     _P_PVcatYto ///
          _P_PVcatCfrom  _P_PVcatCto     _P_PVcatZvalue  _P_PVcatPvalue ///
          _P_PVcatB      _P_PVcatBcheck  _P_PVcatSig
    * temporary hold from to categories of links
    matrix `pairsFT' = J(`npairs',2,.)

// orplot

    if "`_ordc[_plot_type_]'"=="orplot" {

        // matrix input

        if `ismatrix' {
            matrix `msig' = `matrixstub'pval
            local nrows = rowsof(`msig')
            local ncols = colsof(`msig')
            local dolines = 1
            if (`nrows'==1 & `ncols'==1) local dolines = 0
        }

        // loop over variables

        local ipvalpair = 0
        local ivar  = 0
        forvalues v = `vars_start'(1)`vars_end' {

            local ++ivar
            local ivarnm : word `ivar' of `P_varnms'
            local cat_endm1 = `cat_end'-1
            local irowS = ((`ivar'-1)*`ncats') + 1
            local irowE = `irowS' + `ncats' - 1

            // get info from _plotvariables

            matrix `linedata' = J(`ncats',3,.)
            matrix colnames `linedata' = x y c // x, y, category value

            local imat = 0
            forvalues r = `irowS'(1)`irowE' {

                local ++imat
                * x coordinate for OR
                local xis = _P_PVbeta[`r']
                local xis = string(`xis',"%11.3f")
                matrix `linedata'[`imat',1] = `xis'
                * y coordinate
                local yis = _P_PVvarnumoffset[`r']
                local yis = string(`yis',"%11.3f")
                matrix `linedata'[`imat',2] = `yis'
                * category
                local cis = _P_PVcatnum[`r'] // name?
                matrix `linedata'[`imat',3] = `cis'

            }

            * compute contrasts for pairs of categories
            local ipair = 0
            local irowF = 0
            forvalues cfrom = `cat_start'(1)`cat_endm1' {

                local ++irowF // row with information for from category
                local catnmF : word `irowF' of `E_catnms'
                local irowT = `irowF' - 1 // row for to category

                forvalues cto = `cfrom'(1)`cat_end' { // loop categories
                    local ++irowT
                    local catnmT : word `irowT' of `E_catnms'
                    if `cto'==`cfrom' {
                        continue
                    }
                    local ++ipair
                    local ++ipvalpair

                    if "`e(cmd)'"=="mlogit" & !`ismatrix' {
* di "!! from to: `cfrom' -> `cto'"
                        * compute contrast for from-to cateories
                        qui lincom [`catnmF']`ivarnm' -  [`catnmT']`ivarnm'
                        scalar `se' = r(se)
                        scalar `est' = r(estimate)
                        scalar `z' = `est'/`se'
                        scalar `p' = 2*normprob(-abs(`z'))
                        local siglvl "`OPTlinepvalue'"

                        * different levels of nonsignificance
                        local nsiglvl = wordcount("`siglvl'")
                        * eg: if p<=.05             ==0 no line
                        *     if p>.05 and <=.10    ==1 dash
                        *     if p>.10 and <=.99    ==2 solid
                        local sig = 0 // is sig, no line
                        forvalues ilvl = 1(1)`nsiglvl' {
                            local isig : word `ilvl' of `siglvl'
                            if `p'>`isig' {
                                local sig = `ilvl' // sig at which #; else 0
                            }
                        }
                    }

                    // not mlogit estimation
                    else {

                        *matrix input of mlogit coefficient
                        if `ismatrix' {
                            if `dolines' local p = `msig'[1,`ipvalpair']
                            else local p = 0

                            local siglvl "`OPTlinepvalue'"
                            * different levels of nonsignificance
                            local nsiglvl = wordcount("`siglvl'")
                            * eg: if p<=.05             ==0 no line
                            *     if p>.05 and <=.10    ==1 dash
                            *     if p>.10 and <=.99    ==2 solid
                            local sig = 0 // is sig, no line
                            forvalues ilvl = 1(1)`nsiglvl' {
                                local isig : word `ilvl' of `siglvl'
                                if `p'>`isig' {
                                    local sig = `ilvl' // sig at which #; else 0
                                }
                            }
                        }
                        * not matrix input of mlogit coefficients
                        else {
                            local sig = .
                        }
                        scalar `se' = .
                        scalar `est' = .
                        scalar `z' = .
                    }

                    // save information for pairs of categories
                    matrix `pairs'[`ipair',7] = `z'
                    matrix `pairs'[`ipair',8] = `p'
                    matrix `pairs'[`ipair',9] = `est'
                    matrix `pairs'[`ipair',11] = `sig'
                    matrix `pairsFT'[`ipair',1] = `cfrom'
                    matrix `pairsFT'[`ipair',2] = `cto'
                    * coordinates for lines
                    local xF = `linedata'[`irowF',1]
                    local xT = `linedata'[`irowT',1]
                    local yF = `linedata'[`irowF',2]
                    local yT = `linedata'[`irowT',2]
                    local cF = `linedata'[`irowF',3]
                    local cT = `linedata'[`irowT',3]
                    matrix `pairs'[`ipair',1] = `xF'
                    matrix `pairs'[`ipair',2] = `yF'
                    matrix `pairs'[`ipair',3] = `xT'
                    matrix `pairs'[`ipair',4] = `yT'
                    matrix `pairs'[`ipair',5] = `cF'
                    matrix `pairs'[`ipair',6] = `cT'
                    matrix `pairs'[`ipair',10] = `xF' - `xT'

                } // loop over TO categories

            } // loop over FROM categories

            matrix `pairsall' = (nullmat(`pairsall') \ `pairs')
            matrix `pairsFTall' = (nullmat(`pairsFTall') \ `pairsFT')

        } // loop variables to compute pairs

*di "!!!! pairs"
*mat list `pairsall'
*mat list `pairsFTall'

    } // orplot

//  dcplot - no pair information is used

    else {
        matrix `pairsall' = `pairs'
    }

//  create variables for plotting connecting lines

    svmat `pairsall', names(col)

end

exit

* version 0.1.0 2012-08-05
* version 0.1.1 2012-08-05 rename variables
* version 0.1.2 2012-08-06 add multiple p values for connecting lines
* version 0.4.2 2012-09-09 jsl | matrix | posted
* version 0.4.1 2012-09-04 jsl | dcp ocp work | posted
* version 0.4.0 2012-09-03 jsl | cleanup | posted
* version 0.4.3 2012-09-12 | matrix | posted
* version 0.4.4 2012-09-12 | long freese | remove trace
* version 0.4.5 2013-04-24 | long freese | comments
