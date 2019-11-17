*! version 0.4.4 2012-09-09 | long freese | matrix syntax all to string

** interactive dcplot command

program define dcp

    version 11.2

    * syntax all string defauts set when options sent to dcplot

    syntax [varlist(default=none)], [ /// O = orplot  D = dcplot
///
/// first part is same as _ordcplot_syntax
///
/// axis and graph region
    max(string) /// OD max of x axis
    min(string) /// OD min of x axis
    gap(string) /// OD gap between tick marks
    NTics(string) /// OD # of tics on axis; or use gap()
    XLINEs(string) /// OD xline options (size color everything)
///
/// plot region and labeling
    ASPECTratio(string) /// OD aspect ratio for graph
    DECimals(string) /// OD dec digits on axis labels
    ORDECimals(string) /// O  dec digits for the OR scale
///
/// symbols for outcome categories
    BASEcategory(string) /// O  base category for OR plot
    DChange /// O  add DC to or plot
    MColors(string) /// OD color of markers
    MSIZefactor(string) /// OD size of markers; factor only
    nosign /// O  do not underline negative DC's in orplot
    std(string) /// OD Binary Unstd Sstd Rrange  b u s r
    VALues /// OD plot values not letters of value labels
///
/// connecting list
    LINEPvalue(string) /// LINEPvalue(real .1) /// O  line if < less sig
    LColors(string) /// O  colors for connecting lines
    LINEGAPfactor(string) /// O  factor change gap around symbols for lines
    LWidths(string) /// O  width of connecting lines
    PACKed /// O  no offset of markers
    OFFSETLIST(string) /// list of 1 per category per variable ranging from 5 to -5
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
    OFFSETFactor(string) /// O  multiply vertical offsets in OR plot by this
    OFFSETSEQuence(string) /// O  0 1 2 is default for vertical offsets
    STDLABELSPaces(string) /// OD # spaces at end of coef type label; can be <0
///
/// utility and to be added
    debug(string) /// OD
    matrixstub(string) /// OD enter data as matrices not estimation
///
/// second part is to turn off options that are words
/// if arguments, enter new ones
///
/// plot region and labeling
    NOASPECTratio ///
    NODECimals ///
    /// !!OR ONLY NOORDECimals ///
///
/// symbols for outcome categories
    /// !!OR ONLY NOBASEcategory ///
    /// !!OR ONLY NODChange ///
    NOMColors ///
    NOMSIZefactor ///
    /// !!OR ONLY NOnosign ///
    NOstd ///
    NOVALues ///
///
/// connecting list
    /// !!OR ONLY NOLINEPvalue ///
    /// !!OR ONLY NOLColors ///
    /// !!OR ONLY NOLINEGAPfactor ///
    /// !!OR ONLY NOLWidths ///
    /// !!OR ONLY PACKed ///
    /// !!OR ONLY NOOFFSETLIST ///
///
/// labels and notes
    NOCAPtion ///
    NONote ///
    NOPROVenance ///
    NOSUBtitle ///
    NOTItle ///
    NOVARLabels ///
///
/// adjusting defaults
    NOGRAPHoptions ///
    /// !!OR ONLY NOOFFSETFactor ///
    /// !!OR ONLY NOOFFSETSEQuence ///
    NOSTDLABELSPaces ///
    ]

//  options to check

    if "`matrixstub'"!="" local matrix "matrix"

* DO NOT USE FOR DCP        basecategory
    #delimit ;
    * options using ()'s ;
    local optparlist "
        aspectratio        caption        debug             decimals
        gap                graphoptions   lcolors           linegapfactor
        linepvalue         lwidths        max               mcolors
        min                msizefactor    note              ntics
        offsetfactor       offsetlist     offsetsequence    ordecimals
        provenance         std            stdlabelspaces    subtitle
        title              xlines         matrixstub
    ";

    * options using only words ;
    * not dchange always add this;
    local optparword "
        matrix             nosign        packed             values
        varlabels
    ";
    #delimit cr

//  create new command

    local newvarlist "`_dcp[plt_rhsNMS]'"
    if "`varlist'"!="" local newvarlist "`varlist'"
    local newcmd `"`newvarlist', dchange"'

// options that are words only

    foreach opt in `optparword' {

        local newopt ""
        local oldopt "`_dcp[`opt']'" // old option
        if "`oldopt'"=="_none_" local oldopt ""

        * no(option) used, add nothing
        if "`no`opt''"=="no`opt'" {
            local newopt ""
        }

        * not no(option)
        else {

            * option specified
            if "``opt''"!="" {
                local newopt "`opt'"
            }
            * no option specified
            else {
                local newopt "`oldopt'"
            }
        }

        local newcmd `"`newcmd' `newopt'"'
    }

 // options with parameters

    foreach opt in `optparlist' {

        local newopt "``opt''"
        local oldopt "`_dcp[`opt']'"
        if "`oldopt'"=="_none_" local oldopt ""

        * no(option) specified
        if "`no`opt''"=="no`opt'" {
            local newopt ""
        }

        * not no(option)
        else {

            * new option specified
            if "`newopt'"!="" { // new option specified
                local newopt "`opt'(`newopt')"
            }

            * now new option
            else if "`newopt'"=="" {

                * old is none, so add nothing
                if "`oldopt'"=="_none_" {
                    local newopt ""
                }

                * old option is retained
                else {
                    local newopt "`opt'(`oldopt')" // submit old option
                }
            }
        }

        local newcmd `"`newcmd' `newopt'"'
    }


//  send to _ordc_plot_syntax

    _ordcplot_syntax `newcmd'

end

exit

* version 0.4.1 2012-09-04 jsl | dcp ocp work | posted
* version 0.4.2 2012-09-04 jsl | dcp update correction for defaults | posted
* version 0.4.3 2012-09-04 jsl | change syntax all to string |
