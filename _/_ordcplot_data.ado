*! version 0.4.6 2013-04-25 | long freese | comments added

//  create variables with coordinates to plot symbols
//      see _ordcplot_data_plotpairs.ado for plotting significance links

//  called by: _ordcplot_syntax.ado

capture program drop _ordcplot_data
program define _ordcplot_data, sclass

    version 11.2

    args debug OPTaspect OPTbasecat OPTcaption OPTcoeftypes ///
        OPTcoeftypespaces OPTdchange OPTdcplot ///
        OPTdecimals OPTdepvar OPTgap OPTgraph OPTlcolor OPTlinegapfac ///
        OPTlinepvalue OPTlwidth OPTmatrix OPTmax OPTmaxvars ///
        OPTmcolor OPTmin OPTmodelok OPTmsize OPTnosign OPTnote OPTntics ///
        OPToffsetfac OPToffsetseq OPToffsetlist OPTordec OPTpacked ///
        OPTrefnm OPTsaving OPTtitle OPTsubtitle OPTvalues OPTvarlabels ///
        OPTvarnms OPTxlines OPTmatrixstub

*TRACE di _new in blue "= 1 data  => Call _ordcplot_data"

    tempname Bunstd Bstd Brange Bivar tmpsd // working scalars
    tempname E_Bunstd E_Vunstd E_Bstd E_Brange // estimates
    tempname E_DCbin E_DCone E_DCsd E_DCrng E_DCdydx
    tempname E_PVbin E_PVone E_PVsd E_PVrng E_PVdydx
    tempname P_beta P_dc P_voffset // plot info
    tempname P_varnum P_cat P_stdtype
    tempname M_sd // matrix information

//  error checking

    local error = 0
    local P_nvars = wordcount("`OPTvarnms'")
    if `P_nvars' >= `OPTmaxvars' {
        di as error ///
        "only `OPTmaxvars' variables can be plotted in one graph"
        local error = 1
        sreturn local error = 1
    }

    local ncoeftypes = length("`OPTcoeftypes'")
    if `P_nvars'!=`ncoeftypes' {
        di as error ///
        "# of variables to plot differs from # of std()'s"
        local error = 1
        sreturn local error = 1
    }

    if `error'==1 exit

//  create variables with beta estimates & stats for rhs variables
//
//  variables:  _P_EVsd   SD of rhs variables
//              _P_EVbin  are rhs variables binary
//              _P_EVrng  range of rhs variables

    _ordcplot_data_getstats ///
        `E_Bunstd' `E_Vunstd' `E_Bstd' `E_Brange' /// created matrices
        "`OPTmatrix'" "`OPTvalues'" "`debug'" "`OPTmatrixstub'" // program options

*TRACE di in blue "        = 3 stats  => Back from _ordcplot_data_getstats"

    if (`s(error)'==1) exit

    local E_varnms "`s(varnms)'"
    local E_nvars = `s(nvars)'
    local E_nvarsp1 = `E_nvars' + 1
    local E_catnms  "`s(catnms)'"
    local E_catvals "`s(catvals)'"
    local E_catrefnum = `s(catrefnum)'
    local E_ncats = `s(ncats)'
    local maxplotrows = 3*`E_nvars' // allows each var to be plotted 3 times

    if "`OPToffsetlist'"!="" {
        local noffsetlist = wordcount("`OPToffsetlist'")
        local nvarcat = `E_ncats'*`E_nvars'
        if `noffsetlist'!=`nvarcat' {
            di as error ///
                "offsetlist() needs `nvarcat' elements, one for each" ///
                " variable by category pair"
            sreturn local error = 1
            exit
        }
    }
    else {
        if "`OPToffsetseq'"=="" local OPToffsetseq "0 1 2"
    }

    if `OPTbasecat' > `E_ncats' {
        di as error "specified base category exceeds number of categories"
        sreturn local error = 1
        exit
    }

//  get discrete change; matrix row is variable; column is category
//
//  E_DCbin     binary DC
//  E_DCrng     range
//  E_DCsd      sd
//  E_DCone     0->1
//  E_DCdydx partial
    if "`OPTdchange'"=="dchange" | "`_ordc[_plot_type_]'"=="dcplot" {

        _ordcplot_data_getdc /// 0.4.5 E_DCdydx and PV
            `E_DCbin' `E_DCrng' `E_DCsd' `E_DCone' `E_DCdydx' ///
            `E_PVbin' `E_PVrng' `E_PVsd' `E_PVone' `E_PVdydx' ///
            "`E_nvars'" "`E_ncats'" "`E_varnms'" "`E_catnms'" ///
            "`OPTdchange'" "`OPTmatrixstub'" // program options

*TRACE di in blue "        = 3 dc => Back from _ordcplot_data_getdc"

    }

    else {
        foreach m in bin rng sd one dydx { // 0.4.5 dydx
            matrix `E_DC`m'' = J(`E_nvars',`E_ncats',1)
            matrix rownames `E_DC`m'' = `E_varnms'
            matrix colnames `E_DC`m'' = `E_catnms'
            * 0.4.5 pv
            matrix `E_PV`m'' = J(`E_nvars',`E_ncats',1)
            matrix rownames `E_PV`m'' = `E_varnms'
            matrix colnames `E_PV`m'' = `E_catnms'
        }
    }

// create plot variables
//
//  _P_PVbin   binary indicator of plot variables
//  _P_PVnums  variable # of plot variable
//  _P_PVtype  coefficient type of plot variable

    _ordcplot_data_plotvarinfo ///
            "`E_varnms'" "`maxplotrows'" "`OPTvarnms'" "`OPTcoeftypes'"
    if `s(error)'==1 exit

//  create plot variables
//
//   _P_PVdc            discrete change
//   _P_PVcoeftype      1=unstd 2=0/1 3=std 4=range 5=partial
//   _P_PVvarnum        RHS variable number
//   _P_PVvoffset       vertical offset for plot symbol
//   _P_PVcatnum        category # associated with beta
//   _P_PVvarnumrev     _P_PVvarnum in reverse order
//   _P_PVdcabs         absolute value of discrete change
//   _P_PVdcneg         discrete change is negative?
//   _P_PVdcscaled      DC values to have max of 1
//   _P_PVvarnumoffset  Variable number with offset added
//   _P_PVcatstr        category string associated with beta

    _ordcplot_data_plotvariables ///
        "`E_ncats'"   "`E_catnms'"   "`E_catrefnum'"  "`E_catvals'" ///
        "`E_varnms'" "`OPTbasecat'" "`OPToffsetseq'" "`OPTpacked'" ///
        "`P_nvars'"  "`OPToffsetfac'" "`OPToffsetlist'" ///
        `E_Brange' `E_Bstd' `E_Bunstd' ///
        `E_DCbin' `E_DCone' `E_DCsd' `E_DCdydx' `E_DCrng' ///
        `E_PVbin' `E_PVone' `E_PVsd' `E_PVdydx' `E_PVrng'

    char _ordc[est_lhsNM] `"`depvar'"'
    char _ordc[est_catNMS] `"`E_catnms'"'
    char _ordc[est_catNUM] `"`E_catvals'"'
    char _ordc[est_catN] `"`E_ncats'"'
    char _ordc[est_baseNUM] `"`E_catrefnum'"'
    local basecatnm : word `_ordc[est_baseNUM]' of `_ordc[est_catNMS]'
    char _ordc[plt_baseNM] `"`basecatnm'"'
    char _ordc[est_rhsNMS] `"`E_varnms'"'
    char _ordc[est_rhsN] `"`E_nvars'"'
    char _ordc[plt_rhsNMS] `"`OPTvarnms'"'
    char _ordc[plt_rhsN] `"`P_nvars'"'

* di "in _ordcplot_data.ado"
* list _P_PVvarnum _P_PVcatnum _P_PVcatstr _P_PVbeta if _P_PVvarnum<. , ///
    ab(12) clean

//  create coordinates for connection lines

    _ordcplot_data_plotpairs ///
        "`P_varnms'" "`E_catnms'" "`OPTlinepvalue'" "`OPTmatrixstub'"

    sreturn local error = `error'

*TRACE di _new in blue "  = 2 data  => Leaving _ordcplot_data"

end

exit

* version 0.3.5a 2012-08-04 10.08 scott long
* version 0.3.6  2012-08-05 09.29 pairs
* version 0.3.6d 2012-08-05 09.03 moving plot to graph.ado
* version 0.3.6cV2 2012-08-05 routine _plotvariables added
* version 0.3.6c 2012-08-05 routine _plotvariables added
* version 0.3.6b 2012-08-05 routine _plotvarinfo added
* version 0.3.7  2012-08-05 debug
* version 0.3.8a 2012-08-06 offsetlist
* version 0.3.9 2012-09-03 jsl | debug for nom chapter | posted
* version 0.4.0 2012-09-03 jsl | clean code | posted
* version 0.4.1 2012-09-04 jsl | dcp ocp work | posted
* version 0.4.2 2012-09-04 jsl | fv work | posted
* version 0.4.3 2012-09-04 | long freese | matrix
* version 0.4.4 2013-01-19 | long freese | fix base name
* version 0.4.5 2013-01-24 | long freese | add dydx and pvalue
