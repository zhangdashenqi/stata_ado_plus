*! version 0.4.5 2013-04-25 | long freese | reorder DC to match change base category
* version 0.4.4 2013-04-25 | long freese | make output rows sequential by category
* version 0.4.3 2013-04-24 | long freese | fix _P_PVcatnum

//  create variables to be plotted with graph
//      called by _ordcplot_data

capture program drop _ordcplot_data_plotvariables
program _ordcplot_data_plotvariables, sclass

    version 11.2

    args E_ncats E_catnms E_catrefnum E_catvals E_varnms ///
        OPTbasecat OPToffsetseq OPTpacked P_nvars OPToffsetfac ///
        OPToffsetlist E_Brange E_Bstd E_Bunstd ///
        E_DCbin E_DCone E_DCsd E_DCdydx E_DCrng ///
        E_PVbin E_PVone E_PVsd E_PVdydx E_PVrng

    tempname B_ivar brng bstd bunstd tmpoffset ///
        P_beta P_dc P_dcpv P_coeftype P_varnum P_voffset P_catnum

    local tmp = `P_nvars' * `E_ncats' // # coefs to plot
    matrix `P_beta' = J(`tmp',1,.)    // betas to plot
    matrix `P_dc' = `P_beta'          // values of discrete change
    matrix `P_dcpv' = `P_beta'          // p-values of discrete change
    matrix `P_voffset' = `P_beta'     // vertical offset
    matrix `P_varnum' = `P_beta'      // variable number
    matrix `P_catnum' = `P_beta'      // category number
    matrix `P_coeftype' = `P_beta'    // type of standardization

//  baserow is rows in E_B* with coefs for plot basecategory

    local baserow = 0 // 0 if base is same as mlogit , base()
    if (`OPTbasecat'!=`E_catrefnum') & (`OPTbasecat'!=-1) {
        local baserow = `OPTbasecat'
        if (`OPTbasecat'>`E_catrefnum') local baserow = `baserow' - 1
    }

//  compute coefficients to plot

    local isor = 0
    local isdc = 0
    if ("`_ordc[_plot_type_]'"=="orplot") local isor = 1
    if ("`_ordc[_plot_type_]'"=="dcplot") local isdc = 1

    local ivar = 1 // 044 local iloc = 1

//  loop through variables to plot

    while `ivar' <= `P_nvars' {

        * start row in output matrix for this variable; 044
        * then offset this row by the category being computed
        local MATstartrow = (`ivar'-1)*`E_ncats'

        local varnum = _P_PVnums[`ivar']
        local varnm : word `ivar' of `E_varnms'

        * coefficient for base category
        if `baserow' != 0 {
            scalar `bunstd' = `E_Bunstd'[`baserow',`varnum']
            scalar `bstd' = `E_Bstd'[`baserow',`varnum']
            scalar `brng' = `E_Brange'[`baserow',`varnum']
        }
        else { // baserow
            scalar `bunstd' = 0
            scalar `bstd' = 0
            scalar `brng' = 0
        }

        local icat = 1
        local iPVcatnum = 0 // cat # for _P_PVcatnum 044

        while `icat' <= `E_ncats' {

            * if ebasecat adjust the category # 044
            local ++iPVcatnum

            * if cat is ebase, add 1
            if (`icat'==`E_catrefnum') local iPVcatnum = `iPVcatnum' + 1

            * if cat is last category use estimation base
            if (`icat'==`E_ncats') local iPVcatnum = `E_catrefnum'

            * write ORs in cat order 1 2 3 4 regardless of mlogit base 044
            local iloc = `MATstartrow' + `iPVcatnum'

            local catnm : word `icat' of `E_catnms'
            if `icat' < `E_ncats' { // if not mlogit base category
                matrix `P_beta'[`iloc',1] ///
                    = `E_Bunstd'[`icat',`varnum'] - `bunstd'
            }
            else {
                matrix `P_beta'[`iloc',1] ///
                    = 0  - `bunstd' // base category
            }

            * grab DCs and std betas
            if _P_PVtype[`ivar'] == 1 { // 1 unit change
                matrix `P_coeftype'[`iloc',1] = 1
                matrix `P_dc'[`iloc',1] = `E_DCone'[`varnum',`iPVcatnum'] // 045
                matrix `P_dcpv'[`iloc',1] = `E_PVone'[`varnum',`iPVcatnum'] // 045
            }
            else if _P_PVtype[`ivar'] == 2 { // 2 0-1 change
                matrix `P_coeftype'[`iloc',1] = 2
*di "iloc: `iloc'  icat: `icat'  iPVcatnum: `iPVcatnum'"
                matrix `P_dc'[`iloc',1] = `E_DCbin'[`varnum',`iPVcatnum'] // 045
                matrix `P_dcpv'[`iloc',1] = `E_PVbin'[`varnum',`iPVcatnum'] // 045
            }
            else if _P_PVtype[`ivar'] == 3 { // 3 sd change
                matrix `P_coeftype'[`iloc',1] = 3
                matrix `P_dc'[`iloc',1] = `E_DCsd'[`varnum',`iPVcatnum'] // 045
                matrix `P_dcpv'[`iloc',1] = `E_PVsd'[`varnum',`iPVcatnum'] // 045
                if `icat' < `E_ncats' {
                    matrix `P_beta'[`iloc',1] ///
                        = `E_Bstd'[`icat',`varnum'] - `bstd'
                }
                else { // base category
                    matrix `P_beta'[`iloc',1] = 0 - `bstd'
                }
            }
            if _P_PVtype[`ivar'] == 4 { // 4 range
                matrix `P_coeftype'[`iloc',1] = 4
                matrix `P_dc'[`iloc',1] = `E_DCrng'[`varnum',`iPVcatnum'] // 045
                matrix `P_dcpv'[`iloc',1] = `E_PVrng'[`varnum',`iPVcatnum'] // 045
                if `icat' < `E_ncats' {
                    matrix `P_beta'[`iloc',1] ///
                        = `E_Brange'[`icat',`varnum'] - `brng'
                }
                else {
                    matrix `P_beta'[`iloc',1] = 0 - `brng'
                }
            }
            if _P_PVtype[`ivar'] == 5 { // 5 dydx
              matrix `P_coeftype'[`iloc',1] = 5
              matrix `P_dc'[`iloc',1] = `E_DCdydx'[`varnum',`iPVcatnum'] // 045
              matrix `P_dcpv'[`iloc',1] = `E_PVdydx'[`varnum',`iPVcatnum'] // 045
            }
            matrix `P_varnum'[`iloc',1] = `ivar' // var# for given coef
            * pre043 matrix `P_catnum'[`iloc',1] = `icat'

            matrix `P_catnum'[`iloc',1] = `iPVcatnum' // cat# for given coef 043
            local ++icat // pre 044 local ++iloc
        }

        local ++ivar

    } // compute coefs to plot

    * if dcplot, P_beta will have DC's not OR's
    if "`_ordc[_plot_type_]'"=="dcplot" {
        matrix `P_beta' = `P_dc'
    }

//  vertical offsets for symbols within variable

    if "`OPTpacked'" != "packed" {

        if "`OPToffsetlist'"=="" {
            local iloc = 1
            local ivar = 1
            local offseq "`OPToffsetseq' "
            forvalues i = 1(1)10 {
                local offseq "`offseq' `offseq'"
            }
            while `ivar' <= `P_nvars' {
                local ioff = 0
                local varnum = _P_PVnums[`ivar']
                * betas variable ivar
                local istrt = ((`ivar'-1)*`E_ncats') + 1
                local iend  = `istrt' + `E_ncats' - 1
                matrix `B_ivar' = `P_beta'[`istrt'..`iend',1]

                forvalues icat = 1(1)`E_ncats' {
                    local current_min = 987654321
                    forvalues icat2 = 1(1)`E_ncats' {
                        if `B_ivar'[`icat2',1] < `current_min' {
                            local current_min = `B_ivar'[`icat2',1]
                            local minloc = `icat2'
                        }
                    }
                    * change to big values so isn't selected again
                    matrix `B_ivar'[`minloc',1] = 987654321
                    local current_min = 987654321
                    local ++ioff
                    local offset : word `ioff' of `offseq'
                    local ichng = `istrt' + `minloc' - 1
                    if "`OPTpacked'" != "packed" {
                        matrix `P_voffset'[`ichng',1] = `offset'
                    }
                    else {
                        matrix `P_voffset'[`ichng',1] = 0
                    }
                    local ++iloc
                } // cats
                local ++ivar
            } // vars
        } // offset list

//  OPToffsetlist given

        else {
            local iloc = 0
            local ivar = 1
            while `ivar' <= `P_nvars' {
                forvalues icat = 1(1)`E_ncats' {
                    local ++iloc
                    local offset : word `iloc' of `OPToffsetlist'
                    if "`OPTpacked'" != "packed" {
                        * add 5 so -5 to 5 become 0 to 10
                        * divide by 10 so it is from 0 to 1
                        local offset = (`offset'+5)/10
                        matrix `P_voffset'[`iloc',1] = `offset'
                    }
                    else {
                        matrix `P_voffset'[`iloc',1] = 0
                    }
                } // cats
                local ++ivar
            } // vars
        } // offset list
    } // not packed

//  create variables from the matrices

    foreach d in beta dc dcpv coeftype varnum voffset catnum {
        matrix colnames `P_`d'' = _P_PV`d'
        svmat           `P_`d'', names(col)
    }
    label var _P_PVbeta     "beta (or dc) to plot"
    label var _P_PVcatnum   "category # associated with beta"
    label var _P_PVdc       "discrete or partial change"
    label var _P_PVdcpv     "pvalue for discrete or parial change"
    label var _P_PVcoeftype "1=unstd 2=0/1 3=std 4=range 5=partial"
    label var _P_PVvarnum   "RHS variable number"
    label var _P_PVvoffset  "vertical offset for plot symbol"

    * reverse code _P_PVvarnum
    qui sum _P_PVvarnum
    local ymax = r(max)
    qui gen _P_PVvarnumrev = (`ymax' + 1) - _P_PVvarnum
    lab var _P_PVvarnumrev "_P_PVvarnum in reverse order"

// information on discrete changes

    qui gen _P_PVdcabs = abs(_P_PVdc)
    lab var _P_PVdcabs "absolute value of discrete change"
    qui gen _P_PVdcneg = _P_PVdc < 0
    lab var _P_PVdcneg "discrete change is negative?"
    qui sum _P_PVdcabs
    local maxdc = r(max)
    qui gen _P_PVdcscaled = _P_PVdcabs / `maxdc'
    lab var _P_PVdcscaled "DC values to have max of 1"

// offsets for vertical axis

    if "`OPTpacked'" != "packed" {

        qui sum _P_PVvoffset
        local offmax = r(max)
        local offmin = r(min)
        local offrng = r(max) - r(min)
        local offmean = r(mean)
        local offrange = .5 //

        if "`OPToffsetlist'"=="" {
            qui gen `tmpoffset' = ///
                ( ( (_P_PVvoffset-`offrng') / `offrng') + .5 ) ///
                    * `offrange'     /// default spread
                    * `OPToffsetfac' // user adjustment
        }
        * if sequence, don't rescale
        else {
            qui gen `tmpoffset' = _P_PVvoffset - .5 // for
        }
    }
    else { // packed
        qui gen `tmpoffset' = 0
    }
    qui gen _P_PVvarnumoffset = (_P_PVvarnumrev + `tmpoffset')
    label var _P_PVvarnumoffset "Variable number with offset added"

//  create variable with first letter of category name

    *! DO: make changes here to allow two or more letters

    if "`OPTmatrix'"!="matrix" {
        qui generate str1 _P_PVcatstr = ""
        label var _P_PVcatstr   "category string associated with beta"
        local icat = 1
        while `icat' <= `E_ncats' {
            local ltr : word `icat' of `E_catnms'
            local ltr = substr("`ltr'",1,1) // was upper()
            qui replace _P_PVcatstr = "`ltr'" if _P_PVcatnum==`icat'
            local ++icat
        }
    }
    if "`OPTmatrix'"=="matrix" {
        *! DO: add matrix input
    } // matrix

end

exit

* version 0.1.0 2012-08-05
* version 0.2.0 2012-08-05 new vars moved from data.ado
* version 0.2.1 2012-08-05 minor fixes; no est of std if not mlogit
* version 0.2.1a 2012-08-05 offsetlist
* version 0.2.2 2012-09-03 jsl | debug nom chapter | posted
* version 0.4.0 2012-09-03 jsl | cleanup | posted
* version 0.4.2 2013-01-24 | long freese | dydx and pvalues
* version 0.4.1 2012-09-04 | long freese | dcp ocp work
