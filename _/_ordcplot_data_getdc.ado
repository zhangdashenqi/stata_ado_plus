*! version 0.4.3 2013-01-24 | long freese | pvalue, dydx
* version 0.4.2 2012-09-09 | long freese | matrix

//  get discrete change information from last model

*  DO: add matrix input of DC

* called by _ordcplot_data

capture program drop _ordcplot_data_getdc
program _ordcplot_data_getdc, sclass

*TRACE di in red _new "      = 1 dc => Entering _ordcplot_data_getdc"

    version 11.2
    * 0.4.3 add dydx and pvalue
    args E_DCbin E_DCrng E_DCsd E_DCone E_DCdydx ///
         E_PVbin E_PVrng E_PVsd E_PVone E_PVdydx ///
        nvars ncats varnms catnms dchange matrixstub

    local error = 0
    local dcmat "_mchange_plot_dc" // computed by mchange
    local dcmatp "_mchange_plot_pvalue" // computed by mchange
    if ("`matrixstub'"!="") local dcmat "`matrixstub'dc"
    if ("`matrixstub'"!="") local dcmatp "`matrixstub'pvalue"

    // mchange_dc has 5 rows for each variable
    // 1 rng; 2 0->1; 3 +1; 4 +sd; 5 partial

    * 0.4.3 add dydx
    foreach m in bin rng sd one dydx {
        matrix `E_DC`m'' = J(`nvars',`ncats',0)
        matrix rownames `E_DC`m'' = `varnms'
        matrix colnames `E_DC`m'' = `catnms'
        * 0.4.3 add pv
        matrix `E_PV`m'' = J(`nvars',`ncats',0)
        matrix rownames `E_PV`m'' = `varnms'
        matrix colnames `E_PV`m'' = `catnms'
    }

    capture local dcncols = colsof(`dcmat')
    if "`dcncols'"=="" {
        display as error ///
        "discrete change matrix is not in memory"
        sreturn local error = 1
        exit
    }
    capture local dcnrows = rowsof(`dcmat')
    local nr = `nvars'*5
    if `dcncols'!=`ncats' | `dcnrows'!=`nr' {
        display as error ///
        "`dcmat' does not have information for all variables"
        sreturn local error = 1
        exit
    }

//  move change information into matrices

    local ivar = 1
    while `ivar' <= `nvars' {
        local icat = 1
        while `icat' <= `ncats' {
            matrix `E_DCrng'[`ivar',`icat'] = `dcmat'[5*`ivar'-4,`icat']
            matrix `E_DCbin'[`ivar',`icat'] = `dcmat'[5*`ivar'-3,`icat']
            matrix `E_DCone'[`ivar',`icat'] = `dcmat'[5*`ivar'-2,`icat']
            matrix `E_DCsd'[`ivar',`icat']  = `dcmat'[5*`ivar'-1,`icat']
            * 0.4.3 add dydx
            matrix `E_DCdydx'[`ivar',`icat']  = `dcmat'[5*`ivar',`icat']
            * 0.4.3 add pv
            matrix `E_PVrng'[`ivar',`icat'] = `dcmatp'[5*`ivar'-4,`icat']
            matrix `E_PVbin'[`ivar',`icat'] = `dcmatp'[5*`ivar'-3,`icat']
            matrix `E_PVone'[`ivar',`icat'] = `dcmatp'[5*`ivar'-2,`icat']
            matrix `E_PVsd'[`ivar',`icat']  = `dcmatp'[5*`ivar'-1,`icat']
            matrix `E_PVdydx'[`ivar',`icat']  = `dcmatp'[5*`ivar',`icat']
            local ++icat
        }
        local ++ivar
    }

    sreturn local error = `error'

*TRACE di in red "       = 2 dc => Leaving _ordcplot_data_getdc"

end

exit

* version 0.1.0 2012-08-05 06.07 pre save as variables
* version 0.1.1 cleanup
* version 0.1.2 2012-08-08 use mchange_dc in order rng 01 1 sd partial
* version 0.1.3 2012-09-03 jsl | rm3 nom chapter | posted
    * find dc from mchange
* version 0.4.1 2012-09-04 jsl | dcp ocp work | posted
* version 0.4.0 2012-09-03 jsl | code clean | posted
