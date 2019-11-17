*! version 2.3.0 2014-07-28 | long | spacing for labels; graph options; small range
 * version 2.2.0 2014-02-14 | long | spost13 release

//  create and submit graph command

program define _orme_graph, sclass

    version 11.2
    qui `noisily' di _new "    ! entering  _orme_graph"
    args noisily

    #delimit ;
        foreach opt in
            Caspectratio    Cplotbase      Cplotbaseloc     Ccaption
            Cdecimals
            Cgap            Cgraphoptions   Clcolors        Clinegapfactor
            Clwidths        Cmatrixstub     Cmax
            Cmcolors        Cmeffects       Cmin            Cmsizefactor
            Cnosign         Cnote           Cntics          Cordecimals
            Cpacked         Cplottype       Cstagger        Csubtitle
            Csymbols        Ctitle          Ctitlebottom    Ctitletop
            Cvarlabels      Cxlines         Cplotexpand     CplotvarsN
            Cstars          Cstar10         Cstar05         Cstar01
            Ctype_spaces    CcatsN          CplotvarsN      Ccatnms
            Cleftmargin     Cgraphregion
            Cxtitle			Cxsize			Cysize
            Cscale          Cname           Cplotregion

            { ;

            local `opt' "`_orme[`opt']'" ;

        } ;
    #delimit cr

	if ("`Cysize'"!="") local ysize ysize(`Cysize')
    if ("`Cxsize'"!="") local xsize xsize(`Cxsize')
    if ("`Cscale'"!="") local scale scale(`Cscale')
    if ("`Cname'"!="") local name name(`Cname')
    if ("`Cplotregion'"!="") local plotregion plotregion(`Cplotregion')
    if ("`Cxtitle'"!="") local xtitle `"xtitle(`Cxtitle')"'
    if ("`Cgraphregion'"!="") local graphregion "graphregion(`Cgraphregion')"
    else if `Cleftmargin'!=0 {
        local graphregion "graphregion(margin(l+`Cleftmargin'))"
    }

    if ("`Csymbols'"!="") local Csymbols "`Csymbols' `Csymbols' `Csymbols'"
    if (`Caspectratio'>0) local aspect "aspectratio(`Caspectratio')"
    local linegapfac = `Clinegapfactor' * 2.75 // determine empirically

//  min & max

    qui sum _PLT_beta
    local xBmax = r(max) // B is mlogit beta or me coef
    local xBmin = r(min)

    * round to how labels are displayed before making computations
    local RxBmax = string(`xBmax',"%11.`Cdecimals'f")
    local RxBmin = string(`xBmin',"%11.`Cdecimals'f")

    * rounding makes rounded min larger than minimum, reround a larger number
    if `RxBmin'>`xBmin' {
        local xBmin = `xBmin' - 1e-`Cdecimals'
        local xBmin = string(`xBmin',"%11.`Cdecimals'f")
    }
    else local xBmin = `RxBmin'
    * ditto for max
    if `RxBmax'<`xBmax' {
        local xBmax = `xBmax' + 1e-`Cdecimals'
        local xBmax = string(`xBmax',"%11.`Cdecimals'f")
    }
    else local xBmax = `RxBmax'

    if (`Cmin'==-99999) local Cmin = `xBmin'
    if (`Cmax'==99999) local Cmax = `xBmax'
    if `Cmin'>`xBmin' { // if min() doesn't match coef range
        local temp = string(`xBmin',"%11.`Cdecimals'f")
        display "Note: min(`Cmin') reset to min(`temp')"
        local Cmin = `xBmin'
    }
    if `Cmax'<`xBmax' {
        local temp = string(`xBmax',"%11.`Cdecimals'f")
        display "Note: max(`Cmax') reset to max(`temp')"
        local Cmax = `xBmax'
    }
    * check gap for given range
    local badgap = 0
    local xrange = `Cmax' - `Cmin'
    if `Cgap'!=0 & `Cgap'<. {
        local step1 = int(round(`xrange'/`Cgap'),.1)
        local Cntics = 1 + `step1'
        local checkntics = round((`xrange'/`Cgap'),.1) + 1
        if `checkntics'!=`Cntics' local badgap = 1
    }
    if `badgap' {
        display ///
"Note: gap(`Cgap') does not divide evenly into range; default values used."
    }
    local spacing = `xrange'/(`Cntics'-1)

//  tic values

    forvalues i = 1/`Cntics' {
        local v = `Cmin' + (`i'-1)*`spacing'
        local vis = string(`v',"%11.`Cdecimals'f")
        local xBticvalues "`xBticvalues'`vis' "
        local oris = exp(`v')
        local oris = string(`oris',"%11.`Cordecimals'f")
        local xORticvalues `" `xORticvalues' `vis' "`oris'" "'
    }

//  labels for y-axis holding variable names and or labels

    local amtxloc = `Cmin'
    local yticmin = .5
    local yticmax = `CplotvarsN' + .5
    char _orme[plt_yticmax] `yticmax'
    char _orme[plt_yticmin] `yticmin'

    local yvarnamelabel ""
    local yamountlabel ""
    local itic = 2
    local nspace = `Cstdlabelspaces' + `Ctype_spaces'
    local spacer ""
    forvalues i = 1/`nspace' {
        local spacer "`spacer' "
    }

    local ivar = 0
    forvalues ticvalue = `yticmax'(-.25)`yticmin' {

        local ++itic
        if `itic'== 4 { // label every 4th tic

            local ++ivar
            local varnm : word `ivar' of `Cplotexpand'
            local ticvarlabel "`varnm'"

            * label tics with variable labels
            if "`Cvarlabels'" == "varlabels" {
                if "`Cmatrixstub'" == "" {
                    local varlabel `_orme[PLvarlabel`ivar']'
                    local ticvarlabel "`varlabel'"
                }
                else {
                    local tmp "`Cmatrixstub'`varnm'"
                    local varlabel "$`tmp'"
                }
                if ("`varlabel'"!="") local ticvarlabel "`varlabel'"
            }

            local amtlabel `_orme[PLamountlabel`ivar']'
            local amtlabel "`amtlabel'`spacer'"
            local amtyloc = `ticvalue' - .40 // .4 below tic for variable
            local txt `"text(`amtyloc' `amtxloc' "`amtlabel'", place(west) "'
            local txt `" `txt' color(black) size(vsmall))"'
            local yamountlabel `"`yamountlabel' `txt'"'

            local itic = 0
        }
        else local ticvarlabel " "
        local yvarnamelabel `"`yvarnamelabel' `ticvalue' "`ticvarlabel'" "'
    }

//  y horizontal lines

    local ymax = `_orme[plt_rhsN]' + .5
    local ylinevalues ""
    forvalues y = .5/`CplotvarsN' { // always start at .5
        local ylinevalues "`ylinevalues' `y'"
    }

//  text boxes for scaled category symbols/markers

    if ("`Cmcolors'"=="") local mcolor "black"
    else {
        local mcolor "`Cmcolors' `Cmcolors' `Cmcolors' `Cmcolors'"
        local mcolor "`mcolor' `mcolors' `mcolors' `mcolors' `mcolors'"
    }

//  add staggering offsets

    if `Cstagger'!=0 {

        * matrix to hold plot information for one variable at a time
        tempname matsort
        matrix `matsort' = J(`CcatsN',4,.)
        matrix colnames `matsort' = beta catnum varnum icat

        forvalues ivar = 1/`CplotvarsN' {
            forvalues icat = 1/`CcatsN' {
                local irow = ((`ivar'-1)*`CcatsN') + `icat'
                * get coordinates from plot variables
                local betais = _PLT_beta[`irow']
                local catnumis = _PLT_catnum[`irow']
                local betanumoffis = _PLT_betanumoffset[`irow']
                matrix `matsort'[`icat',1] = `betais'
                matrix `matsort'[`icat',2] = `catnumis'
                matrix `matsort'[`icat',3] = `betanumoffis'
                matrix `matsort'[`icat',4] = `icat'
            }
            * sort by size of coefficients
            mata : st_matrix("`matsort'", sort(st_matrix("`matsort'"), 1))
            matrix colnames `matsort' = beta catnum varnum icat
            * add offsets
            local ioff = `Cstagger'
            forvalues icat = 1/`CcatsN' {
                local offsetis = `matsort'[`icat',3]
                local ioff = `ioff'*-1
                local offsetis = `offsetis' + `ioff'
                matrix `matsort'[`icat',3] = `offsetis'
            }
            * resort in original orders
            mata : st_matrix("`matsort'", sort(st_matrix("`matsort'"), 4))
            matrix colnames `matsort' = beta catnum varnum icat
            * regenerate variable with coordinates
            forvalues icat = 1/`CcatsN' {
                local irow = ((`ivar'-1)*`CcatsN') + `icat'
                local offsetis = `matsort'[`icat',3]
                qui replace _PLT_betanumoffset = `offsetis' in `irow'
            }
        }
    } // stagger

    qui sum _PLT_betanum
    local nobs = r(N)
    local txtall ""
    forvalues iobs = 1/`nobs' {

        if ("`Cplottype'"=="meplot") local xis = _PLT_me[`iobs']
        if ("`Cplottype'"=="orplot") local xis = _PLT_beta[`iobs']
        local xis = string(`xis',"%11.3f")
        local yis = _PLT_betanumoffset[`iobs']
        local yis = string(`yis',"%11.3f")
        local ltris = _PLT_catstr[`iobs']
        local ltrnumis =  _PLT_catnum[`iobs']
        local ltrlocis =  _PLT_catloc[`iobs'] // allow's 0 values

        if ("`Csymbols'"!="") local ltris : word `ltrlocis' of `Csymbols'
        if "`Cstars'"!="" & "`Cplottype'"=="meplot" {
            local pvis = _PLT_mepv[`iobs']
            if (`pvis'>=0  & `pvis'<=`Cstars') local ltris "`ltris'*"
        }
        /* to allow multiple levels of stars; did not work well so dropped
            if "`Cstars'"=="stars" & "`Cplottype'"=="meplot" {
                local pvis = _PLT_mepv[`iobs']
                if (`pvis'>=0  & `pvis'<=.01) local ltris "`ltris'`Cstar01'"
                if (`pvis'>.01 & `pvis'<=.05) local ltris "`ltris'`Cstar05'"
                if (`pvis'>.05 & `pvis'<=.10) local ltris "`ltris'`Cstar10'"
            }
        */
        local ltrcolor : word `ltrlocis' of `mcolor'
        local meis = _PLT_me[`iobs'] // use only if me option
        local meneg = _PLT_meneg[`iobs']

        * orplot: meffect scale factor by size of ME
        local rescaleby = .25 // empirically determined, tried: .4, .3
        local mbase = .00 // emprically determed, tried: .005
        local mesizefactor = ///
            (sqrt((`mbase'+_PLT_meabs[`iobs']))/`rescaleby')* `Cmsizefactor'
        local mesizefactor = string(`mesizefactor',"%11.3f")

        if  "`Cmeffects'" =="" { // no meffect in orplot
            local sizeis = `Cmsizefactor'
        }
        else local sizeis = `mesizefactor' // meffects in plot
        * meplot: single size for all letters
        if ("`Cplottype'"=="meplot") local sizeis = `Cmsizefactor'

        * text box holding string marking categories
        local txt `"text(`yis' `xis' "`ltris'", place(c)"'
        local txt `"`txt' size(*`sizeis') color(`ltrcolor'))"'
        local txtall `"`txtall' `txt'"'

        * underline for negative ME's
        if ("`Cnosign'"=="") & (`meis'<0) & ("`Cplottype'"=="orplot") {
            local txt `"text(`yis' `xis' "_", place(c)"'
            local txt `"`txt' size(*`sizeis') color(`ltrcolor'))"'
            local txtall `"`txtall' `txt'"'
        }
    } // loop over all stats to be plotted
    local markerstext `"`txtall'"'

//  axes labels for orplot and xlines for orplot

    if "`Cplottype'"=="orplot" {

        * top and bottom labels
        local basenm : word `Cplotbaseloc' of `Ccatnms'
        local xtitlebot ///
            "Logit Coefficient Scale Relative to Category `basenm'"
        local xtitletop ///
            "Odds Ratio Scale Relative to Category `basenm'"
        if ("`Ctitletop'"!="") local xtitletop "`Ctitletop'"
        if ("`Ctitlebottom'"!="") local xtitlebot "`Ctitlebottom'"
        if ("`Cxlines'"!="") local Cxlines `"xline(`Cxlines') "'

        * axes labels
        local axis2 = 2
        local xlabel1 `"`xBticvalues', axis(1)"'
        local xlabel2 `"`xORticvalues', axis(`axis2')"'
        local xtitle2 `"`xtitletop', axis(`axis2') size(medsmall)"'
        local xtitle1 `"`xtitlebot', size(medsmall) just(left)"'
    }

//  axes labels for meplot

    if "`Cplottype'"=="meplot" {

        local xtitletop "Marginal Effect on Outcome Probability"
        local xtitlebot ""
        if ("`Ctitletop'"!="") local xtitletop "`Ctitlebottom'"
        if ("`Ctitlebottom'"!="") local xtitlebot "`Ctitletop'"
        if ("`Cxlines'"=="") local Cxlines `"xline(0, lcolor(gs12)) "'

        local axis2 = 1 // don't use second axis
        local xlabel1 `"`xBticvalues', axis(1)"'
        local xtitle1 `""`xtitlebot'", size(medsmall) just(left)"'
        local xlabel2 ""
        local xtitle2 `""`xtitletop'", axis(`axis2') size(medsmall)"'
    }

// create graph commands from user options

    if ("`Cnote'"!="") local notetext `"note(`Cnote')"'
    else local notetext ""
    if ("`Ctitle'"!="") local titletext `"title(`Ctitle')"'
    else local titletext ""
    if ("`Csubtitle'"!="") local subtitletext `"subtitle(`Csubtitle')"'
    else local subtitletext ""
    if ("`Ccaption'"!="") local captiontext `"caption(`Ccaption')"'
    else local captiontext ""

// dummy data for creating dummy plot for second axis

    tempvar ydata xdata showline
    qui gen `ydata' = 1 in 1
    qui gen `xdata' = 0 in 1
    qui gen `showline' = .

    * if packed, no connecting lines
    if ("`Cpacked'"=="packed") qui replace `showline' = (0*_PLT_catSig)
    else qui replace `showline' = _PLT_catSig

    local lcol1 : word 1 of `Clcolors'
    local lcol2 : word 2 of `Clcolors'
    local lcol3 : word 3 of `Clcolors'
    local lcol4 : word 4 of `Clcolors'
    local lcol5 : word 5 of `Clcolors'
    local lwidth1 : word 1 of `Clwidths'
    local lwidth2 : word 2 of `Clwidths'
    local lwidth3 : word 3 of `Clwidths'
    local lwidth4 : word 4 of `Clwidths'
    local lwidth5 : word 5 of `Clwidths'

    //  graph commands

if "`Cplottype'"=="orplot" {

    #delimit ;

      twoway

        // connecting lines for non-significant contrast
        (
         pccapsym _PLT_catYfrom _PLT_catXfrom _PLT_catYto _PLT_catXto
            if `showline'==1, legend(off)

            // lines connecting markers
            lcol(`lcol1') lwid(`lwid1') lpat(solid)

            // circles whiting out lines near markers
            mcol(white) msymb(circle) msiz(*`linegapfac')

            // user specified graph options
            `Cgraphoptions' // graphregion(margin(l+`Cleftmargin'))
            `xtitle'
        )
        // 2nd set of connecting lines for level two signifcance
        (
         pccapsym _PLT_catYfrom _PLT_catXfrom _PLT_catYto _PLT_catXto
            if `showline'==2, legend(off)

            // lines connecting markers
            lcol(`lcol2') lwid(`lwid2') lpat(solid)

            // circles whiting out lines near markers
            mcol(white) msymb(circle) msiz(*`linegapfac')

            // user specified graph options
            `Cgraphoptions' // graphregion(margin(l+`Cleftmargin'))
            `xtitle'
        )
        // 3rd set of connecting lines for level 3 signifcance
        (
         pccapsym _PLT_catYfrom _PLT_catXfrom _PLT_catYto _PLT_catXto
            if `showline'==3, legend(off)

            // lines connecting markers
            lcol(`lcol3') lwid(`lwid3') lpat(solid)

            // circles whiting out lines near markers
            mcol(white) msymb(circle) msiz(*`linegapfac')

            // user specified graph options
            `Cgraphoptions' // graphregion(margin(l+`Cleftmargin'))
            `xtitle'
        )
        // 4th set of connecting lines for level 4 signifcance
        (
         pccapsym _PLT_catYfrom _PLT_catXfrom _PLT_catYto _PLT_catXto
            if `showline'==4, legend(off)

            // lines connecting m   arkers
            lcol(`lcol4') lwid(`lwid4') lpat(solid)

            // circles whiting out lines near markers
            mcol(white) msymb(circle) msiz(*`linegapfac')

            // user specified graph options
            `Cgraphoptions' // graphregion(margin(l+`Cleftmargin'))
            `xtitle'
        )
        // 5th set of connecting lines for level 5 signifcance
        (
         pccapsym _PLT_catYfrom _PLT_catXfrom _PLT_catYto _PLT_catXto
            if `showline'==5, legend(off)

            // lines connecting markers
            lcol(`lcol5') lwid(`lwid5') lpat(solid)

            // circles whiting out lines near markers
            mcol(white) msymb(circle) msiz(*`linegapfac')

            // user specified graph options
            `Cgraphoptions' // graphregion(margin(l+`Cleftmargin'))
        )

        // bottom x-axis labels and ylabels for variable names/labels
        (
         scatter `ydata' `xdata',
            msymbol(none) legend(off) `aspect'
            xlabel(`xlabel1') xtitle(`xtitle1')
            ylabel(`yvarnamelabel', angle(horiz) noticks nogrid)
        )

        // plot category markers and x axis labels for odds ratios
        (
         scatter _PLT_betanumoffset _PLT_beta,
            msymbol(none) `markerstext' `yamountlabel'
            xaxis(`axis2') xlabel(`xlabel2') xtitle(`xtitle2') `Cxlines'
            ytitle("") ytitle(, size(small))
            yline(`ylinevalues',lwidth(vthin) lpattern(solid) lcolor(black))
            `titletext' `subtitletext' `notetext' `captiontext'

        ) ,
        `xsize' `ysize' `scale' `name' `graphregion' `xtitle' `plotregion'
        ;
        #delimit cr
}

if "`Cplottype'"=="meplot" {
    #delimit ;

      twoway

        // bottom x-axis labels and ylabels for variable names/labels
        (
         scatter `ydata' `xdata',
            msymbol(none) legend(off) `aspect'
            xlabel(`xlabel1') xtitle(`xtitle1')
            ylabel(`yvarnamelabel', angle(horiz) noticks nogrid)
            `Cgraphoptions'
        )
        // plot category markers and x axis labels for odds ratios
        (
         scatter _PLT_betanumoffset _PLT_beta,
            msymbol(none) `markerstext' `yamountlabel'
            xaxis(`axis2') xlabel(`xlabel2') xtitle(`xtitle2') `Cxlines'
            ytitle("") ytitle(, size(small))
            yline(`ylinevalues',lwidth(vthin) lpattern(solid) lcolor(black))
            `titletext' `subtitletext' `notetext' `captiontext'
            `Cgraphoptions'
        ) ,
        `xsize' `ysize' `name' `scale' `xtitle' `graphregion' `plotregion'
        ;
        #delimit cr
}

    sreturn local error = 0
    qui `noisily' di _new "    ! leaving   _orme_graph"

end // _orme_graph
exit
