*! version 2.2.3 2014-07-30 | long | mlogitplot wo mchange
 * version 2.2.2 2014-07-28 | long | labels, graph options
 * version 2.2.1 2014-07-25 | long | update fork to latest code
 * version 2.2.0 2014-07-25 | long | derek wagnor fork
 * version 2.1.1 2014-03-28 | long | typo
 * version 2.1.0 2014-02-14 | long | spost13 release

//  syntax decoding for orplot and meplot

* DO amount if matrix input
* DO save matrices plotted as returns; add gen() option for plot variables

capture program drop _orme_syntax
program define _orme_syntax, sclass

    version 11.2
    qui `noisily' di _new "    ! entering  _orme_syntax"
    capture drop _PV_OR*
    capture drop _PV_ME*
    capture drop _PLT_*
    local Cplottype "`_orme[Cplottype]'"
    local amountdefault "sd" // if amount not set for type variable
    char _orme[Ctype_spaces] `"6"' // tweak as needed

    syntax [varlist(fv default=none)] , ///
        [ NOISily /// OR orplot only  ME meplotone
        XTItle(string) ///
        GRAPHRegion(string) /// passthrough graph
        LEFTMargin(real 0) ///
        MSHADEs /// shade by # of categories
        mshadesmin(real .25) /// basesline for lightest color
        LSHADEs /// # of shades to create for color
        lshadesmin(real .25) ///
    /// matrix input
        MATRIXstub(string) /// a enter data in matrix and globals
    /// orplot options
        BASEcategory(integer -99) /// OR base category for odds ratios
        MEffects /// OR add marginal effects to or plot
        MChange /// synonym for meffects
        LINEPvalues(string) /// OR line if pvalue of or < less pvalue
        LColors(string) /// OR colors for connecting lines
        LINEGAPfactor(real 1) /// OR factor change in gap around symbols
        LWidths(string) /// OR width of connecting lines
        PACKed /// OR vetical no offset within variable
        OFFSETLIST(string) /// vertical offsets
                /// 1 per cat per var in range [5 to -5]
                /// order: var1 cat1 cat2 cat3... var2 cat1 cat2... etc
        OFFSETFactor(real 1) /// OR multiply vertical offsets by this factor
        OFFSETSEQuence(string) /// OR 0 1 2 is default for vertical offsets
    /// meplot options
        SIGnificance(string)  /// show stars for sig levels in ME plots
    /// amount
        AMount(string) /// a bin one sd rng|range marg|marginal
        ONELABel(string) /// label for unit change _none_ for blank
        RANGELABel(string) /// Range change _none_ for blank
        SDLABel(string) /// SD change _none_ for blank
        BINLABel(string) /// 0 to 1 _none_ for blank
        MARGINALLABabel(string) /// maringal _none_ for blank
    /// axis and graph region
        max(real 99999) /// max of x axis
        min(real -99999) /// min of x axis
        gap(real 0) /// gap between tick marks
        ormax(real 99999) /// max of x axis
        ormin(real -99999) /// min of x axis
    /// orgap(real 0) /// gap between tick marks
        ntics(integer 5) /// # of tics on axis; or use gap()
        XLINEs(string) /// xline options (size color everything)
    /// plot region and labeling
        ASPECTratio(real 0) /// aspect ratio for graph
        DECimals(integer 2) /// dec digits on axis labels
        ORDECimals(integer 2) /// OR dec digits for the OR scale
    /// symbols for outcome categories
        STAGger(real 0) /// vertically stagger symbols
        SYMbols(string) /// symbols for outcome markers
        MColors(string) /// colors of markers
        MSIZefactor(string) /// size of markers; factor only
        nosign /// OR do not underline negative ME's in orplot
        VALues /// plot values not letters of value labels
    /// labels and notes
        TITLETop(string) TITLEBottom(string) /// overwrite default titles
        TItle(string) /// text with options for graph title() option
        SUBtitle(string) /// text with options for subtitle() option
        Note(string) /// text with options for graph note() option
        CAPtion(string) /// caption with formatting (No Cprovenance)
        PROVenance(string) /// caption with formatting (No Cprovenance)
        VARLabels /// use variable labels to label variables
    /// adjusting defaults
        GRAPHoptions(string) /// pass through options to plot commands
        AMOUNTLABELSPaces(integer 0) /// # spaces at end of coef type label; can be <0
        xsize(string) ysize(string) ///
        scale(string) name(string) PLOTRegion(string) ///
         ]

    if (`ormin'!=-99999) local min = ln(`ormin')
    if (`ormax'!=99999) local max = ln(`ormax')

    if ("`mchange'"=="mchange") local meffects "meffects"

    local stars "`significance'"
    if `leftmargin'!=0 & "`graphregion'"!="" {
        display as error "leftmargin() and graphregion() cannot be used together"
        sreturn local error = 1
        exit
    }

    local plotbase "`basecategory'"
    if "`Cplottype'"=="orplot" & "`matrixstub'"=="" ///
        & "`e(cmd)'"!="mlogit" {
        display as error "`Cplottype' cannot be run with `e(cmd)'"
        sreturn local error = 1
        exit
    }

    capture local mematncols = colsof(_mchange)
    if "`mematncols'"=="" & "`meffects'"=="meffects" {
        display as error "option meffects requires that mchange was run"
        local error = 1
        sreturn local error = `error'
        exit
    }
    if "`mematncols'"=="" & "`Cplottype'"=="meplot" {
        display as error "mchangeplot requires that mchange was run"
        local error = 1
        sreturn local error = `error'
        exit
    }

    local isdelta = 0
    * only check _mchange if meplot or meffects in orplot
    if "`Cplottype'"=="meplot" | "`meffects'"=="meffects" {
        * is delta used in mchange?
        local stripe : rownames _mchange
        local ipos = strpos("`stripe'","delta_")
        if (`ipos'>0) local isdelta=1
    }
    char _orme[Camountdelta] `isdelta'

    if ("`msizefactor'"=="") local msizefactor = 1

    if (_N<10) quietly set obs 50
    if ("`stagger'"=="") local stagger "0"
    if ("`mcolors'"=="rainbow") local mcolors "red orange green blue purple"
    if ("`Cplottype'"=="meplot") local packed packed
    if ("`lcolors'"=="rainbow") local lcolors "red orange green blue purple"

    * number of variables per graph
    local maxvarsunpacked = 7
    local maxvarsunpacked = 8
    * with more allowed, error with too many options
    local maxvarspacked = 11
    local maxvars = `maxvarsunpacked'
    if ("`packed'"=="packed") local maxvars = `maxvarspacked'

    fvexpand `varlist'
    local varlist `r(varlist)'

//  if meplot, and no varlist, use vars names in _mchange

    if "`Cplottype'"=="meplot" {

        * vars in _mchange matrix
        local mchangevars : roweq _mchange
        * for factor vars
        local mchangevars : subinstr local mchangevars "!1vs0" "", all

        * remove !#vs# from labels
        local cleannms ""
        foreach nm in `mchangevars' {
            local expos = strpos("`nm'","!") - 1
            if (`expos'>1) local nm = substr("`nm'",1,`expos') // remove !...
            local cleannms "`cleannms'`nm' "
        }
        local mchangevars "`cleannms'"

        local mchangevars : list uniq mchangevars
        if ("`varlist'"=="") local varlist "`mchangevars'"

    }

//  varlist specified

    if "`varlist'"!="" {
        local cleannms ""
        foreach nm in `varlist' { // change i. to 1.
            _ms_parse_parts `nm'
            if ("`r(op)'"=="") local cleannms "`cleannms'`r(name)' "
            * 2013-09-23 for do not allow selection of contrasts
            else if (r(omit)==0) local cleannms "`cleannms'`r(name)' "
        }
        local varlist : list uniq cleannms
    }

    local isvarlist = 0 // variables automatically selected
    if "`matrixstub'" != "" { // matrix input
        local varlist $`matrixstub'rhsnms
        local betanms "`varlist'"
        local corenms "`varlist'"'
        local isvarlist = 1
    }
    else if ("`varlist'"!="") local isvarlist = 1

    if `plotbase'==-99 & "`e(cmd)'"=="mlogit" {
        local plotbase = e(baseout)
    }

    if "`offsetsequence'"!="" & "`offsetlist'"!="" {
        display as error ///
        "offsetlist() and offsetsequence() cannot be used together"
        sreturn local error = 1
        exit
    }

    * significant markings
    if "`stars'"!="" {
        capture confirm number `stars'
        if _rc {
            display as error ///
            "stars() must contain a number; `stars' is invalid"
            sreturn local error = 1
            exit
            contine
        }
        if `stars'<.01 | `stars'>.99 {
            display as error ///
            "stars() must contain a number between .01 and .90"
            sreturn local error = 1
            exit
            contine
        }
    }
        /* did not work well; dropped
            if ("`star10'"=="_none_") local star10 ""
            else if ("`star10'"=="")  local star10 "*"
            if ("`star05'"=="_none_") local star05 ""
            else if ("`star05'"=="")  local star05 "**"
            if ("`star01'"=="_none_") local star01 ""
            else if ("`star01'"=="")  local star01 "***"
            if ("`stars'"=="")        local stars "_none_"
        */

    if ("`linepvalues'"=="") local linepvalues = .05
    else {
        local unsorted "`linepvalues'"
        local linepvalues : list retoken linepvalues
        local linepvalues : list uniq linepvalues
        local linepvalues : list sort linepvalues
        local issorted = 0
        if "`linepvalues'"!="`unsorted'" {
            local issorted = 1
            display "Note: option sorted to linepvalues(`linepvalues')"
        }
        local npvalue = wordcount("`linepvalues'")
        if `npvalue'>5 {
            display as error "linepvalues() can only have 5 values"
            sreturn local error = 1
            exit
            contine
        }
        foreach p in `linepvalues' {
            capture confirm number `p'
            if _rc {
                display as error ///
                "linepvalues() must contain numbers; `p' is invalid"
                sreturn local error = 1
                exit
                contine
            }
        }

        * line options
        if ("`lcolors'"=="") local lcolors black
        if ("`lwidths'"=="") local lwidths thin
        local xlcolors "`lcolors' `lcolors' `lcolors' `lcolors' `lcolors'"
        local xlwidths "`lwidths' `lwidths' `lwidths' `lwidths' `lwidths'"

        * widths for each pconnect line
        local lwidths ""
        forvalues i = 1/`npvalue' {
            local s : word `i' of `xlwidths'
            local lwidths "`lwidths'`s' "
        }
        * colors for plineslines
        if "`lshades'"=="" {
            local newcolors ""
            forvalues i = 1/`npvalue' {
                local s : word `i' of `xlcolors'
                local newcolors "`newcolors'`s' "
            }
            local lcolors "`newcolors'"
        }
    } // if multiple plines

    * graph option checks
    if `min'>=`max' {
        display as error "the minimum is larger than the maximum"
        sreturn local error = 1
        exit
    }
    if "`provenance'"!="" & "`caption'"!="" {
        display as error "provenance() and caption() cannot be used together"
        sreturn local error = 1
        exit
    }
    if "`provenance'"!="" local caption "Source: `provenance', size(vsmall)"

//  determine variables to plot if not matrix input

    if "`matrixstub'"=="" { // not matrix input

        _rm_modelinfo2
        local catnms `"`r(lhscatnms)'"'
        local catvals "`r(lhscatvals)'"
        local catvalsmax

        if "`Cplottype'"=="orplot" {
            local ipos : list posof "`plotbase'" in catvals
            if `ipos'==0 {
                display as error ///
                    "basecategory(`plotbase') is not an outcome category"
                sreturn local error = 1
                exit
            }
            * position of base in set of categories | allows base(0) base(-1)
            local plotbaseloc = `ipos'
        }

        if ("`values'"=="values") local catnms `"`catvals'"'
        local catsN = wordcount("`catvals'")
        local catvalmax : word `catsN' of `catvals'
        local ebaseout = e(baseout)
        local lhsnm "`r(lhsnm)'"
        local rhsnms "`r(rhsnms)'" // from e(b)
        local rhs_fv "`r(rhs_fv)'"
        local rhs_notfv "`r(rhs_notfv)'"
        local rhs_typevariable "`r(rhs_typevariable)'"
        local rhs_typefactor "`r(rhs_typefactor)'"
        local rhs_core "`r(rhs_core)'"
        if ("`varlist'"=="") local checkvars "`rhs_core'"
        else local checkvars "`varlist'"
        forvalues j = 0/30 { // change #.varnm to varnm
            local checkvars : subinstr local checkvars "`j'." "", all
        }
        local checkvars : subinstr local checkvars "i." "", all
        *201: allow same var mult times in varlist
        local plotvars "" // names of vars being plotted
        local plotexpand "" // expanded name x.AvsB etc
        local plotfv "" // core names of type factor variables
        local plotnonfv "" // core names of type variable variables
        local plotcore "" // core names associated with me
        local plotvartypes "" // factor or variable
        * determine non-base eq number to be checked in mlogit
        if "`e(baseout)'"!="" {
            foreach c in `catvals' {
                if (`c'!=`e(baseout)') local eqbase "eq(`c')"
            }
        }

        * create shades for markers
        if "`mshades'"=="mshades" {
            local newcolor ""
            local mshadesN `catsN'
            local mcolorsN = wordcount("`mcolors'")
            if `mcolorsN'==1 {
                local smin = `mshadesmin' // .2
                local smax = (1/`smin') * 1.2
                * since higher colors differentiate less
                local smin = log(`smin')
                local smax = log(`smax')
                local sgap = (`smax'-`smin')/`mshadesN'
                forvalues i = `smin'(`sgap')`smax' {
                    local iis = exp(`i')
                    local newcolor "`newcolor'`mcolors'*`iis' "
                }
                local mcolors "`newcolor'"
            }
        }

        * create shades for pvalue lines
        if "`linepvalues'"!="" & "`lshades'"=="lshades" {
            local newcolor ""
            local lshadesN = wordcount("`linepvalues'")
            local lcolorsN = wordcount("`lcolors'")
            if `lcolorsN'==1 {
                local smin = `lshadesmin' // .2
                local smax = (1/`smin') * 1.2
                * since higher colors differentiate less
                local smin = log(`smin')
                local smax = log(`smax')
                local sgap = (`smax'-`smin')/`lshadesN'
                forvalues i = `smin'(`sgap')`smax' {
                    local iis = exp(`i')
                    local newcolor "`newcolor'`lcolors'*`iis' "
                }
                local lcolors "`newcolor'"
            }
        }

        if "`Cplottype'"=="meplot" {
            local corechecked ""
            foreach checknm in `checkvars' {
                * is name valid? check var i.var 0.var 1.var....
                local checknm2 "`checknm' i.`checknm' "
                local maxfactorlevel 32
                * nofatal: ok if name not found
                * noomitted: do not check omitted coefficients
                capture _ms_extract_varlist `checknm2', `eqbase' nofatal noomitted
                local extracted "`r(varlist)'"
                if "`extracted'"=="" {
                    display as error "`checknm' is not in model"
                    local error = 1
                    sreturn local error = 1
                    continue, break
                }
                local nextracted = wordcount("`extracted'")
                * determine if expanded names should be dropped;
                local checkit : word 1 of `r(varlist)'
                _ms_parse_parts `checkit'
                local typeis "`r(type)'" // variable or factor
                local corenm "`r(name)'"
                local levelis "`r(level)'" // level is # in #.name
                _rm_get_base `corenm' // base level of factor RHS var
                local baseis = `r(base)'
                local baseok = 1
                if ("`baseis'"=="`levelis'") local baseok = 0
                local icoreloc = 0
                * if base ok and not already checked
                if `icoreloc'==0 & `baseok'==1 {
                    local corechecked "`corechecked'`corenm' "
                    if "`typeis'"!="factor" {
                        local plotvartypes "`plotvartypes'variable "
                        local plotvars "`plotvars'`checknm' "
                        local plotexpand "`plotexpand'`checknm' "
                        local plotnonfv "`plotnonfv'`checknm' "
                        local plotcore "`plotcore'`checknm' "
                    }
                    else { // factor var
                        _rm_pwnames, var(`corenm') // get all pw conparisons
                        local npw = `s(npw)'
                        forvalues ipw = 1/`npw' {
                            local plotvars "`plotvars'`corenm' "
                            local varnmexp "`corenm'.`s(numlabel`ipw')'" // AvsB
                            local plotexpand "`plotexpand'`varnmexp' "
                            local plotfv "`plotfv'`corenm' "
                            local plotcore "`plotcore'`corenm' "
                            local plotvartypes "`plotvartypes'factor "
                        }
                    }
                }
            } // checknm
            local plotvarsN = wordcount("`plotvars'")
        } // meplot

        * orplot: collect names of betas
        else {
            foreach checknm in `checkvars' {
                * is name valid?
                * need to check var i.var 0.var 1.var....
                local checknm2 "`checknm' i.`checknm' "
                local maxfactorlevel 32
                *201: i.x is all that is needed
                *   nofatal: ok if name not found
                *   noomitted: do not check omitted coefficients
                capture _ms_extract_varlist `checknm2', `eqbase' nofatal noomitted
                local extracted "`r(varlist)'"
                if "`extracted'"=="" {
                    display as error "`checknm' is not in model"
                    local error = 1
                    sreturn local error = 1
                    continue, break
                }
                local nextracted = wordcount("`extracted'")
                forvalues i=1/`nextracted' {
                    gettoken nm extracted : extracted
                    _ms_parse_parts `nm'
                    if "`r(type)'"=="variable" {
                        local plotvartypes "`plotvartypes'variable "
                        local addnm "`r(name)'"
                        local plotnonfv "`plotnonfv'`addnm' "
                        local plotvars "`plotvars'`addnm' "
                        local plotcore "`plotcore'`addnm' "
                    }
                    else { // factor so add prefix #.
                        local plotvartypes "`plotvartypes'factor "
                        local prefix ""
                        if ("`r(level)'"!="") local prefix "`r(level)'."
                        local addnm "`prefix'`r(name)'"
                        local plotvars "`plotvars'`addnm' "
                        local plotfv "`plotfv'`r(name)' "
                        local plotcore "`plotcore'`r(name)' "
                    }
                }
            } // checknm
        } // orplot

        local plotvarsN = wordcount("`plotvars'")
        local plotexpand "`plotvars'"

    } // not matrix

    if "`error'"=="1" exit
    char _orme[Cxtitle] `"`xtitle'"'
    char _orme[Cgraphregion] `"`graphregion'"'
    char _orme[Cplotvars] `"`plotvars'"'
    char _orme[CplotvarsN] `"`plotvarsN'"'
    char _orme[Cplotcore] `"`plotcore'"'
    char _orme[Cplotexpand] `"`plotexpand'"'
    char _orme[Cplotfv] `"`plotfv'"'
    char _orme[Cplotnonfv] `"`plotnonfv'"'
    char _orme[Cplotvartypes] `"`plotvartypes'"'

    if `plotvarsN'>`maxvars' {
        display as error ///
        "maximum number of variables for this type of graph is `maxvars'"
        sreturn local error = 1
        exit
    }

//  determine amount of change to plot

    if "`matrixstub'"!="" {
        if "`amount'"=="" {
            display as error ///
            "must specify amount() when using the matrixstub()"
            sreturn local error = 1
            exit
        }
        else {
            display "TO DO TEST AMOUNTS FOR MATRIX INPUT"
            sreturn local error = 1
            exit
        }
    }

    * from amount() option
    char _orme[Camount] `"`amount'"'
    local amountN = wordcount("`amount'")

    if `amountN'==1 {
        local isok = inlist("`amount'","bin","one","sd","rng","marg","delta")
        if `isok'==0 {
            display as error ///
"invalid amount `amt'; valid amount() options are bin one rng sd marg"
             sreturn local error = 1
            continue, break
            exit
        }
        local amountdefault "`amount'"
        local amount ""
    }

//  construct amountfull with one amount change for each row of plot

    * if no amount(), use amountdefault for non-fv and bin for fv's
    if "`amount'"=="" & "`matrixstub'"=="" {
        local amountfull ""
        foreach varnm in `plotcore' {
            local isfv : list posof "`varnm'" in plotfv
            if (`isfv'>0) local amountfull "`amountfull'bin " // all fv are bin
            else local amountfull "`amountfull'`amountdefault' "
        }
    }
    * amount() specified
    else if "`matrixstub'"=="" {
        local amount : subinstr local amount "range" "rng", all
        local amount : subinstr local amount "marginal" "marg", all
        local amountN = wordcount("`amount'")
        local plotnonfvN = wordcount("`plotnonfv'")

        if `amountN'!=`plotnonfvN' {
            display as error ///
"amount() can have one amount to use for all non-factor variable or"
            display as error ///
"can have an amount for each of the `plotnonfvN' non-factor variables"
            sreturn local error = 1
            exit
        }
        foreach amt in `amount' {
            local isok = inlist("`amt'","bin","one","sd","rng","marg","delta")
            if `isok'==0 {
                display as error ///
"invalid amount(`amt'): valid options are bin delta one rng sd marg"
                sreturn local error = 1
                continue, break
                exit
            }
        }
        local amountfull ""
        foreach varnm in `plotcore' {
            local isfv : list posof "`varnm'" in plotfv
            if `isfv'>0 local amountfull "`amountfull'bin "
            else {
                gettoken amtis amount : amount
                local amountfull "`amountfull'`amtis' "
            }
        }
        local amountfull : subinstr local amountfull "  " " ", all
    }
    char _orme[Camountfull] `"`amountfull'"'

//  amount labels
/* 2.2.1
    local rnglabel `"`rangelabel'"'
    local marglabel `"`marginallabel'"'
    if "`onelabel'"=="" local onelabel "Unit change "
    if "`rnglabel'"=="" local rnglabel "Range change "
    if "`sdlabel'"=="" {
        if `isdelta' local sdlabel "Delta change "
        else local sdlabel "SD change "
    }
    if "`binlabel'"=="" local binlabel "0 to 1 "
    if "`marglabel'"=="" local marglabel "Marginal "
*/

    * 2.2.2
    capture confirm scalar _mchangecentered
    if _rc & "`meffects'"=="meffects" {
        di as error "complete results from mchange are not in memory"
        exit
    }
    if _rc & "`meffects'"!="meffects" { // 2.2.3
        * temporary for setting labels below, then drop
        scalar _mchangecentered = .
    }

    * 2.2.2
    if _mchangecentered==1 { // centered change
        if "`onelabel'"=="" local onelabel `""Unit centered    ""'
        if "`rnglabel'"=="" local rnglabel "Range change "
        if "`sdlabel'"=="" {
            if `isdelta' local sdlabel `""Delta centered    ""'
            else local sdlabel `""SD centered    ""'
        }
    }
    else { // uncentered
        if "`onelabel'"=="" local onelabel "Unit increase "
        if "`rnglabel'"=="" local rnglabel "Range change "
        if "`sdlabel'"=="" {
            if `isdelta' local sdlabel "Delta increase "
            else local sdlabel "SD increase "
        }
    }
    if (_mchangecentered==.) scalar drop _mchangecentered // 2.2.3

//  create char information

    char _orme[Cvarnms]  "see corenms & betanms"
    #delimit ;
    foreach cnm in
        leftmargin
        amountlabelspaces
        aspectratio
        betanms
        binlabel
        caption
        catnms catsN catvals catvalmax
        corenms
        decimals
        depvar
        ebaseout
        fvnms
        gap
        graphoptions
        lcolors
        lhsnm
        linegapfactor
        linepvalues
        lwidths
        marginallabel marglabel
        matrixstub
        max
        mcolors
        meffects
        min
        msizefactor
        nonfvnms
        nosign
        note
        ntics
        offsetfactor offsetlist offsetsequence
        onelabel
        ordecimals
        packed
        plotbase plotbaseloc plotvars
        rangelabel
        rhs_fv rhs_notfv rhs_core
        rhsnms
        rnglabel
        sdlabel
        stagger
        star01 star05 star10 stars
        subtitle
        symbols
        title
        titlebottom titletop
        values
        varlabels
        varlist
        xlines
		xsize
		ysize
        scale
        name
        plotregion

    { ;
        char _orme[C`cnm'] `"``cnm''"';
    } ;
    #delimit cr

//  get data to plot

    qui `noisily' di _new "    ! going to  _orme_data"
    _orme_data `noisily'
    qui `noisily' di _new "    ! back from _orme_data"

    if `s(error)'==1 {
        sreturn local error = 1
        exit
    }

//  submit graph command

    qui `noisily' di _new "    ! going to  _orme_graph"
    _orme_graph `noisily'
    qui `noisily' di _new "    ! back from _orme_graph"

    if `s(error)'==1 {
        sreturn local error = 1
        exit
    }

//  clean up and leave

    capture drop _P_*
    sreturn local error = 0
    qui `noisily' di _new "    ! leaving   _orme_syntax"

end
exit
