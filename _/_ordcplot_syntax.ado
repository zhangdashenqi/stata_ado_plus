*! version 0.4.11 2013-04-26 | long freese | 1.x 1.x remove i1. in parssed name

//  syntax decoding for orplot and dcplot

//  called by:

capture program drop _ordcplot_syntax
program define _ordcplot_syntax, sclass

    version 11.2

    if _N<10 quietly set obs 50

*TODO: use global till final constant chosen; then hard code spaces

    global ordc_type_spaces = 6 // use global till final value chosen

*TRACE di in blue _new "====> Entering _ordcplot_syntax"

    syntax [varlist(fv default=none)], [ /// O = orplot  D = dcplot
///
/// matrix
    MATRIXstub(string) /// OD enter data as matrices not estimation
///
/// 2013-01 new additions
    STAGger(real 0) /// vertically stagger plot symbols from left to right
    SYMbols(string) /// symbols for marking outcomes
    TITLETop(string) TITLEBottom(string) ///
    STDULABel(string) /// Unit change
    STRRLABel(string) /// Range change
    STDSLABel(string) /// SD change
    STDBLABel(string) /// 0 to 1
    STDPLABel(string) /// Partial
    stars /// show stars for sig levels in DC plots
    star10(string) star05(string) star01(string) ///
///
/// axis and graph region
    max(real 99999) /// OD max of x axis
    min(real -99999) /// OD min of x axis
    gap(real 0) /// OD gap between tick marks
    NTics(integer 5) /// OD # of tics on axis; or use gap()
    XLINEs(string) /// OD xline options (size color everything)
///
/// plot region and labeling
    ASPECTratio(real 0) /// OD aspect ratio for graph
    DECimals(integer 2) /// OD dec digits on axis labels
    ORDECimals(integer 2) /// O  dec digits for the OR scale
///
/// symbols for outcome categories
    BASEcategory(integer -1) /// O  base category for OR plot
    DChange /// O  add DC to or plot
    MColors(string) /// OD color of markers
    MSIZefactor(string) /// OD size of markers; factor only
    nosign /// O  do not underline negative DC's in orplot
    std(string) /// OD Binary Unstd Sstd Rrange  b u s r p *0.4.8
    VALues /// OD plot values not letters of value labels
///
/// connecting list
    LINEPvalue(string) /// LINEPvalue(real .1) /// O  line if < less sig
    LColors(string) /// O  colors for connecting lines
    LINEGAPfactor(real 1) /// O  factor change gap around symbols for lines
    LWidths(string) /// O  width of connecting lines
    PACKed /// O  no offset of markers
    OFFSETLIST(string) /// list of 1 per category per variable ranging from 5 to -5
                       /// order: var1 cat1 cat2 cat3... var2 cat1 cat2... etc
///
/// labels and notes
    CAPtion(string) /// OD text for provenance
    Note(string) /// OD text with options for graph note() option
    PROVenance(string) /// caption with formatting (No OPTprovenance)
    SUBtitle(string) /// OD text with options for subtitle() option
    TItle(string) /// OD text with options for graph title() option
    VARLabels /// OD use variable labels to label variables
///
/// adjusting defaults
    GRAPHoptions(string) /// OD pass through options to plot commands; TO TEST
    OFFSETFactor(real 1) /// O  multiply vertical offsets in OR plot by this
    OFFSETSEQuence(string) /// O  0 1 2 is default for vertical offsets
    STDLABELSPaces(integer 0) /// OD # spaces at end of coef type label; can be <0
///
/// utility and to be added
    debug(integer 0) /// OD
    ]

    if "`matrixstub'"!="" {
        local varlist $`matrixstub'rhsnms
    }
    if ("`star10'"=="_none_") local star10 ""
    else if ("`star10'"=="") local star10 "*"
    if ("`star05'"=="_none_") local star05 ""
    else if ("`star05'"=="") local star05 "**"
    if ("`star01'"=="_none_") local star01 ""
    else if ("`star01'"=="") local star01 "***"
    if ("`stars'"=="") local  stars "_none_"

    * change i1. to 1.
    forvalues j = 0(1)10 {
        *local varlist = regexr("`varlist'","i`j'.","`j'.") // only does 1st
        local varlist : subinstr local varlist "i`j'." "`j'.", all
    }

//  syntax and error checking

    if `basecategory'==-1 { // 046
        if ("`e(cmd)'"=="mlogit") local basecategory = e(baseout) // 048
    }

    if "`offsetsequence'"!="" & "`offsetlist'"!="" {
        display as error ///
        "offsetlist() and offsetsequence() cannot be used together"
        sreturn local error = 1
        exit
    }

    if "`mcolors'"=="rainbow" {
        local mcolors "red orange green blue purple"
    }

    if `min'>=`max' {
        display as error ///
        "the minimum is larger than the maximum"
        sreturn local error = 1
        exit
    }

    local std : subinstr local std " " "", all

    if "`linepvalue'"=="" local linepvalue = .1
    if "`linepvalue'"!="" {
        local tnosort : list retoken linepvalue
        local tnosort : list uniq linepvalue
        local linepvalue : list sort tnosort
        local issorted = 0
        if "`linepvalue'"!="`tnosort'" {
            local issorted = 1
            display ///
            "Note: options sorted to linepvalue(`tsort')"
        }
        local npvalue = wordcount("`linepvalue'")
        if `npvalue'>5 {
            display as error ///
            "linepvalue() can only have 5 values psecified"
            sreturn local error = 1
            exit
            contine
        }
        foreach p in `linepvalue' {
            capture confirm number `p'
            if _rc {
                display as error ///
                "linepvalue() must contain numbers; `p' is invalid"
                sreturn local error = 1
                exit
                contine
            }
        }
        if "`lcolor'"=="" local lcolor black
        if "`lwidth'"=="" local lwidth thin
        local xlcolor "`lcolor' `lcolor' `lcolor' `lcolor' `lcolor'"
        local xlwidth "`lwidth' `lwidth' `lwidth' `lwidth' `lwidth'"
        local lcolor ""
        local lwidth ""
        forvalues i = 1(1)`npvalue' {
            local s : word `i' of `xlcolor'
            local lcolor "`lcolor' `s'"
            local s : word `i' of `xlwidth'
            local lwidth "`lwidth' `s'"
        }
    }

    if "`caption'"!="" & "`provenance'"!="" {
        display as error ///
        "caption() and provenance() cannot both be used"
        sreturn local error = 1
        exit
    }

    if "`provenance'"!="" {
        local provopts " size(tiny)" // size(vsmall)"
        local caption "Source: `provenance', `provopts'"
        local provenance ""
    }

    if "`e(cmd)'"=="mlogit" {
        local plottype "or"
    }

    * supported commands for dcplot
    else if "`e(cmd)'"=="oprobit" | "`e(cmd)'"=="slogit" ///
        | "`e(cmd)'"=="ologit" | "`e(cmd)'"=="mprobit" {
        local plottype "dc"
    }
    else if "`matrixstub'"=="" {
        display as error ///
        "`_ordc[_plot_type_]' does not work with `e(cmd)'"
        sreturn local error = 1
        exit
    }
    if "`_ordc[_plot_type_]'"=="orplot" & "`plottype'"=="dc" {
        display as error ///
        "`_ordc[_plot_type_]' cannot be run with `e(cmd)'"
        sreturn local error = 1
        exit
    }

    char _ordc[symbols] "`symbols'"
    char _ordc[titletop] "`titletop'"
    char _ordc[titlebottom] "`titlebottom'"
    char _ordc[stdulabel] "`stdulabel'"
    char _ordc[strrlabel] "`strrlabel'"
    char _ordc[stdslabel] "`stdslabel'"
    char _ordc[stdblabel] "`stdblabel'"
    char _ordc[stdplabel] "`stdplabel'"
    * 0.4.8
    char _ordc[stars] "`stars'"
    char _ordc[star01] "`star01'"
    char _ordc[star05] "`star05'"
    char _ordc[star10] "`star10'"
    if "`stagger'"=="" local stagger "0"
    char _ordc[stagger] "`stagger'"

//  characteristics with all options for dcp and orp

    capture qui gen _orp = .
    label var _orp "Variable holds orplot command as characteristics"
    capture qui gen _dcp = .
    label var _dcp "Variable holds dcplot command as characteristics"

    #delimit ;
    * options using ()'s ;
    local optparlist "
        xlines          title           subtitle        stdlabelspaces
        std             provenance      ordecimals      offsetsequence
        offsetlist      offsetfactor    ntics           note
        msizefactor     min             mcolors         max
        lwidths         linepvalue      linegapfactor   lcolors
        graphoptions    gap             decimals        debug
        caption         basecategory    aspectratio
        matrixstub
    ";

    * options using only words ;
    local optparword "
        varlabels       values          packed          nosign
        matrix          dchange
    ";
    #delimit cr

    if ("`_ordc[_plot_type_]'"=="orplot") local charvar "_orp"
    if ("`_ordc[_plot_type_]'"=="dcplot") local charvar "_dcp"

    foreach opt in `optparlist' `optparword' {
        local optsave = ltrim("``opt''")
        if "``opt''"=="" local optsave "_none_"
        char `charvar'[`opt'] "`optsave'"
    }

// which variables to plot

    local OPTmatrix "`matrixstub'"
    local OPTvarnms `varlist'
    if "`OPTvarnms'"=="" & "`OPTmatrix'"!="matrix" {
        _rm_rhsnames OPTvarnms rhsN1 rhsNMS2 rhsN2
    }
    if "`matrixstub'"!="" {
        local OPTvarnms "$`matrixstub'rhsnms"
    }

//  set up plotting options

    if ("`_ordc[_plot_type_]'"=="dcplot") local packed packed
    local OPTmaxvars = 7
    if ("`packed'"=="packed") local OPTmaxvars = 11

    //  default std() if user did not set them
    if "`std'"=="" & "`matrixstub'"=="" {
        foreach varnm in `OPTvarnms' {
            capture assert `varnm' == 0 | `varnm' == 1 | `varnm' == . ///
                `if' `in'
            local isbin = _rc==0
            if (`isbin'==1) local std "`std'b"
            else local std "`std's"
        }
    }

    if "`matrixstub'"!="" & "`std'"=="" {
        display as error ///
        "you must specify std() when using the matrixstub() option"
        sreturn local error = 1
        exit
    }

//  information for args in other _ordcplot programs

    local debug = `debug'
    local OPTaspect = `aspectratio'
    local OPTbasecat = `basecategory'
    local OPTcaption `"`caption'"'
    local OPTstd "`std'"
    local OPTstdlabelspaces = `stdlabelspaces'
    local OPTdchange "`dchange'"
    local OPTdcplot "`dcplot'"
    local OPTdecimals = `decimals'
    local OPTdepvar "`depvar'"
    local OPTgap = `gap'
    local OPTgraph `"`graphoptions'"'
    local OPTlcolor `"`lcolors'"'
    local OPTlinegapfac = `linegapfactor'
    local OPTlinepvalue "`linepvalue'"
    local OPTlwidth "`lwidths'"
    local OPTmatrix "`matrixstub'"
    local OPTmax = `max'
    local OPTmaxvars "`OPTmaxvars'"
    local OPTmcolor `mcolors'
    local OPTmin = `min'
    local OPTmsize `msizefactor'
    local OPTnosign "`nosign'"
    local OPTnote `"`note'"'
    local OPTntics = `ntics'
    local OPToffsetfac = `offsetfactor'
    local OPToffsetseq "`offsetsequence'"
    local OPToffsetlist "`offsetlist'"
    local OPTordec = `ordecimals'
    local OPTpacked "`packed'"
    local OPTrefnm "`refnm'"
    local OPTsaving "`saving'"
    local OPTtitle `"`title'"'
    local OPTsubtitle `"`subtitle'"'
    local OPTvalues "`values'"
    local OPTvarlabels "`varlabels'"
    local OPTvarnms "`OPTvarnms'"
    local OPTxlines "`xlines'"
    local OPTmatrixstub "`matrixstub'"

    #delimit ;
    local OPTall `"
    "`debug'"               "`OPTaspect'"           "`OPTbasecat'"
    "`OPTcaption'"          "`OPTstd'"              "`OPTstdlabelspaces'"
    "`OPTdchange'"          "`OPTdcplot'"           "`OPTdecimals'"
    "`OPTdepvar'"           "`OPTgap'"              "`OPTgraph'"
    "`OPTlcolor'"           "`OPTlinegapfac'"       "`OPTlinepvalue'"
    "`OPTlwidth'"           "`OPTmatrix'"           "`OPTmax'"
    "`OPTmaxvars'"          "`OPTmcolor'"           "`OPTmin'"
    "`OPTmodelok'"          "`OPTmsize'"            "`OPTnosign'"
    "`OPTnote'"             "`OPTntics'"            "`OPToffsetfac'"
    "`OPToffsetseq'"        "`OPToffsetlist'"       "`OPTordec'"
    "`OPTpacked'"           "`OPTrefnm'"            "`OPTsaving'"
    "`OPTtitle'"            "`OPTsubtitle'"         "`OPTvalues'"
    "`OPTvarlabels'"        "`OPTvarnms'"           "`OPTxlines'"
    "`OPTmatrixstub'"
    "' ;
    #delimit cr

//  get data to be plotted

    _ordcplot_data `OPTall'

*TRACE di in blue _new "    = 3 data  => Back from _ordcplot_data"

    if `s(error)'==1 {
        sreturn local error = 1
        exit
    }

//  submit graph command

    _ordcplot_graph `OPTall'

*TRACE di in blue _new "    = 3 graph => Back from _ordcplot_graph"

    if `s(error)'==1 {
        sreturn local error = 1
        exit
    }
    capture drop _P_*
    sreturn local error = 0

*TRACE di in blue _new "<==== Leaving _ordcplot_syntax"

end

exit

* version 0.0.1
* version 3.0.3a 2012-08-02 10.01 major refactoring
* version 0.3.5 2012-08-03 scott long
* version 0.3.6c 2012-08-06 offsetlist
* version 0.3.6b 2012-08-06 multiple line colors
* version 0.3.6a 2012-08-06 title2 to subtitle
* version 0.3.7 working version
* version 0.3.8 2012-09-03 jsl | work on nom chapter | posted
    * std() instead of coeftypes()
* version 0.4.3 2012-09-08 jsl | matrix | posted
* version 0.4.2 2012-09-05 jsl | remove rm3_pedum | posted
    * rainbow for colors
* version 0.4.1 2012-09-04 jsl | dcp ocp work | posted
* version 0.4.0 2012-09-03 jsl | code clean | posted
    * drop coeftypes for std; coeftypespace to stdlabelspace; drop saving()
* version 0.4.4 2012-09-11 jsl | matrix | posted
* version 0.4.10 2013-01-25 | long freese | stagger
* version 0.4.8 2013-01-24 | long freese | dydx, pvalue, stars
* version 0.4.8 2013-01-24 | long freese | tweak basecat
* version 0.4.7 2013-01-24 | long freese | symbols() titletop() titlebottom()
* version 0.4.6 2013-01-23 | long freese | if no base() use mlogit basecat
* version 0.4.5 2012-09-12 | long freese | mprobit
