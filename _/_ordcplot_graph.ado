   *! version 0.4.10c 2013-07-02 | long freese | gap message
* version 0.4.10b 2013-01-26 | long freese | gap() fix

//  create graph commands

capture program drop _ordcplot_graph
program define _ordcplot_graph, sclass

    version 11.2

*TRACE di in blue _new "= 1 graph => Entering _ordcplot_graph"

    args debug OPTaspect OPTbasecat OPTcaption OPTstd ///
        OPTstdlabelspaces OPTdchange OPTdcplot OPTdecimals OPTdepvar ///
        OPTgap OPTgraph OPTlcolor OPTlinegapfac OPTlinepvalue OPTlwidth ///
        OPTmatrix OPTmax OPTmaxvars OPTmcolor OPTmin OPTmodelok OPTmsize ///
        OPTnosign OPTnote OPTntics OPToffsetfac OPToffsetseq OPToffsetlist ///
        OPTordec OPTpacked OPTrefnm OPTsaving OPTtitle OPTsubtitle ///
        OPTvalues OPTvarlabels OPTvarnms OPTxlines OPTmatrixstub

    * symbols to overwrite value labels
    local OPTsymbols "`_ordc[symbols]'" // 0.4.7
    if "`OPTsymbols'"!="" {
        local OPTsymbols "`OPTsymbols' `OPTsymbols' `OPTsymbols'"
    }

//  x axis information

    * min and max of estimates
    qui sum _P_PVbeta
    local xBmax = r(max)
    local xBmin = r(min)
    if (`OPTmin'==-99999) local OPTmin = `xBmin'
    if (`OPTmax'==99999) local OPTmax = `xBmax'

    * set min max; if too small, reset
    if `OPTmin'>`xBmin' {
        local temp = string(`xBmin',"%11.4f")
        display "Note: min(`OPTmin') reset to min(`temp')"
        local OPTmin = `xBmin'
    }
    if `OPTmax'<`xBmax' {
        local temp = string(`xBmax',"%11.4f")
        display "Note: max(`OPTmax') reset to max(`temp')"
        local OPTmax = `xBmax'
    }
    char _ordc[plt_xticBmax] `xBmax'
    char _ordc[plt_xticBmin] `xBmin'

    * compute tic values
    local xrange = `OPTmax' - `OPTmin'
*    if (`OPTgap'!=0) local spacing = `OPTgap'
*di "gap was:   `OPTgap'"
    if `OPTgap' !=0 & `OPTgap'<. {
*di " `xrange'/`OPTgap' "
*di 1 + int(`xrange'/`OPTgap')
        local OPTntics = 1 + int(`xrange'/`OPTgap')
    }
*di "range:    `xrange'"
*di "gap:      `OPTgap'"
*di "OPTntics: `OPTntics'"

if (`xrange'/`OPTgap')+1 != `OPTntics' {
display ///
"Note: gap(`OPTgap') does not divide evenly into specified or implied values"
display ///
"for min() and max(). Specify min() and max() along with gap()."
}


*    else local spacing = `xrange'/(`OPTntics'-1)
local spacing = `xrange'/(`OPTntics'-1)

    local xBvalues ""
    local xORvalues ""
    forvalues i = 1(1)`OPTntics' {
        local v = `OPTmin' + (`i'-1)*`spacing'
        local vis = string(`v',"%11.`OPTdecimals'f")
        local xBvalues "`xBvalues' `vis'"
        local oris = exp(`v')
        local oris = string(`oris',"%11.`OPTordec'f")
        local xORvalues `" `xORvalues' `vis' "`oris'" "'
    }
    char _ordc[plt_xticBvalues] `xBvalues'
    char _ordc[plt_xticORvalues] `xORvalues'
    char _ordc[plt_xticmax] `OPTmax'
    char _ordc[plt_xticmin] `OPTmin'
    char _ordc[plt_xticsN] `OPTntics'

//  labels for y axis

    local xstdloc = `OPTmin'
    local varnms `_ordc[plt_rhsNMS]'
    local nvars `_ordc[plt_rhsN]'
    local yticmin = .5
    local yticmax = `nvars' + .5
    char _ordc[plt_yticmax] `yticmax'
    char _ordc[plt_yticmin] `yticmin'

    local yticlab ""
    local ystdlab ""
    local itic = 2
    local ivar = 0
    local nspace = `OPTstdlabelspaces' + $ordc_type_spaces
    local spacer ""
    forvalues i = 1(1)`nspace' {
        local spacer "`spacer' "
    }

    forvalues ticvalue = `yticmax'(-.25)`yticmin' {

        local ++itic

        if `itic'== 4 { // label needed every 4th tic

            local ++ivar
            local varnm : word `ivar' of `varnms'
            local ticlabel "`varnm'"
            if ("`OPTvarlabels'"=="varlabels") & ("`OPTmatrixstub'"=="") {
                * remove 1x. from name to get var label
                local varlblnm = regexr("`varnm'","[0-9a-z]*\.","")
                local varlabel : variable label `varlblnm'
                if ("`varlabel'"!="") local ticlabel "`varlabel'"
            }
            if ("`OPTvarlabels'"=="varlabels") & ("`OPTmatrixstub'"!="") {
                local tmp "`OPTmatrixstub'`varnm'"
                local varlabel "$`tmp'"
                if ("`varlabel'"!="") local ticlabel "`varlabel'"
            }

            * labels for std type
            local stdopt = substr("`OPTstd'",`ivar',1)
            if ("`stdopt'"=="u") local stdtype "UnStd Coef"
            if ("`stdopt'"=="r") local stdtype "Range Coef"
            if ("`stdopt'"=="s") local stdtype "Std Coef"
            if ("`stdopt'"=="b") local stdtype "0/1"

            if ("`stdopt'"=="u") local stdtype "UnStd Coef "
            if ("`stdopt'"=="r") local stdtype "Range Coef "
            if ("`stdopt'"=="s") local stdtype "Std Coef "
            if ("`stdopt'"=="b") local stdtype "0->1 "

            * 0.4.7
            * labels for types of changes
            if "`_ordc[stdulabel]'"=="" local stdulabel "Unit change "
            else if "`_ordc[stdulabel]'"=="_none_" local stdulabel ""
            else local stdulabel "`_ordc[stdulabel]' "
            if "`_ordc[stdrlabel]'"=="" local stdrlabel "Range change "
            else if "`_ordc[stdrlabel]'"=="_none_"  local stdrlabel ""
            else local stdrlabel "`_ordc[stdrlabel]' "
            if "`_ordc[stdslabel]'"=="" local stdslabel "SD change "
            else if "`_ordc[stdslabel]'"=="_none_" local stdslabel ""
            else local stdslabel "`_ordc[stdslabel]' "
            if "`_ordc[stdblabel]'"=="" local stdblabel "0 to 1 "
            else if "`_ordc[stdblabel]'"=="_none_" local stdblabel ""
            else local stdblabel "`_ordc[stdblabel]' "
            if "`_ordc[stdplabel]'"=="" local stdplabel "Partial "
            else if "`_ordc[stdplabel]'"=="_none_" local stdplabel ""
            else local stdplabel "`_ordc[stdplabel]' "
            foreach s in u r s b p {
                if ("`stdopt'"=="`s'") local stdtype "`std`s'label'"
            }
            local stdtype "`stdtype'`spacer'"
            local stdyloc = `ticvalue' - .40 // .4 below tic for variable
            local txt `"text(`stdyloc' `xstdloc' "`stdtype'", place(west) "'
            local txt `" `txt' color(black) size(vsmall))"'
            local ystdlab `"`ystdlab' `txt'"'

            local itic = 0
        }
        else {
            local ticlabel " "
        }
        local yticlab `"`yticlab' `ticvalue' "`ticlabel'" "'
    }
    char _ordc[plt_coeftype_text] `ystdlab'
    char _ordc[plt_ytic_labels] `yticlab'

//  y lines

    local ymax = `_ordc[plt_rhsN]' + .5
    local plt_ylinevalues ""
    forvalues y = .5(1)`ymax' { // always start at .5
        local plt_ylinevalues "`plt_ylinevalues' `y'"
    }
    char _ordc[plt_ylinevalues] `"`plt_ylinevalues'"'

//  text boxes for scaled category symbols//markers

    if "`OPTmcolor'"=="" {
        local mcolor "black"
    }
    else {
        local mcolor "`OPTmcolor' `OPTmcolor' `OPTmcolor' `OPTmcolor'"
        local mcolor "`mcolor' `OPTmcolor' `OPTmcolor' `OPTmcolor' `OPTmcolor'"
        local mcolor "`mcolor' `OPTmcolor' `OPTmcolor' `OPTmcolor' `OPTmcolor'"
    }

//  add staggering offsets
* 0.4.8
    * nmlab _P_PV*
    * sum _P_PV*
    * gen P_PVvarnumoffset = _P_PVvarnumoffset
    * gen P_PVbeta =  _P_PVbeta
    * gen P_PVcatstr =  _P_PVcatstr
    * gen P_PVcatnum = _P_PVcatnum

    local stagger `_ordc[stagger]'
    if `stagger'!=0 {

        * matrix to hold plot information for one variable at a time
        local ncats = `_ordc[est_catN]'
        local nrhs = `_ordc[plt_rhsN]'
        tempname matsort
        matrix `matsort' = J(`ncats',4,.)
        matrix colnames `matsort' = beta catnum varnum icat

        * loop through variables
        forvalues ivar = 1(1)`nrhs' {
            forvalues icat = 1(1)`ncats' {
                local irow = ((`ivar'-1)*`ncats') + `icat'
                * get coordinates from plot variables
                local betais = _P_PVbeta[`irow']
                local catnumis = _P_PVcatnum[`irow']
                local varnumoffis = _P_PVvarnumoffset[`irow']
                * matrix with results
                matrix `matsort'[`icat',1] = `betais'
                matrix `matsort'[`icat',2] = `catnumis'
                matrix `matsort'[`icat',3] = `varnumoffis'
                matrix `matsort'[`icat',4] = `icat'
            }
            * sort by size of coefficients
            mata : st_matrix("`matsort'", sort(st_matrix("`matsort'"), 1))
            matrix colnames `matsort' = beta catnum varnum icat
            * add offsets
            local ioff = `stagger'
            forvalues icat = 1(1)`ncats' {
                local offsetis = `matsort'[`icat',3]
                local ioff = `ioff'*-1
                local offsetis = `offsetis' + `ioff'
                matrix `matsort'[`icat',3] = `offsetis'
            }
            * resort in original orders
            mata : st_matrix("`matsort'", sort(st_matrix("`matsort'"), 4))
            matrix colnames `matsort' = beta catnum varnum icat
            * regenerate variable with coordinates
            forvalues icat = 1(1)`ncats' {
                local irow = ((`ivar'-1)*`ncats') + `icat'
                local offsetis = `matsort'[`icat',3]
                qui replace _P_PVvarnumoffset = `offsetis' in `irow'
            }
        }
        *list _P_PVvarnumoffset _P_PVbeta _P_PVcatstr _P_PVcatnum if _P_PVbeta<.
    } // stagger

    qui sum _P_PVvarnum
    local nobs = r(N)
    local txtall ""
    forvalues i = 1(1)`nobs' {

        if "`_ordc[_plot_type_]'"=="dcplot" {
            local xis = _P_PVdc[`i']
        }
        if "`_ordc[_plot_type_]'"=="orplot" {
            local xis = _P_PVbeta[`i']
        }
        local xis = string(`xis',"%11.3f")
        local yis = _P_PVvarnumoffset[`i']
        local yis = string(`yis',"%11.3f")
        local ltris = _P_PVcatstr[`i']
        local ltrnumis =  _P_PVcatnum[`i']

        * 0.4.7 replace first letter of value label for symbols
        if "`OPTsymbols'"!="" { // replace default ltr with symbol()
            local ltris : word `ltrnumis' of `OPTsymbols'
        }

        * add stars
        if "`_ordc[stars]'"=="stars" & "`_ordc[_plot_type_]'"=="dcplot" {
            local pis = _P_PVdcpv[`i']
            if (`pis'>=0 & `pis'<=.01) local ltris "`ltris'`_ordc[star01]'"
            if (`pis'>.01 & `pis'<=.05) local ltris "`ltris'`_ordc[star05]'"
            if (`pis'>.05 & `pis'<=.10) local ltris "`ltris'`_ordc[star10]'"
        }

        local ltrcolor : word `ltrnumis' of `mcolor'
        local dcis = _P_PVdc[`i'] // use only if dc option
        local dcneg = _P_PVdcneg[`i']

        * scale labels by this amount
        local LBLscale = 1
        if "`OPTmsize'" != "" {
            local LBLscale = `OPTmsize' // factor for sizing label
        }

        * orplot: also scale labels by size of DC
        *           .4 empirically determined
        local ORDCscale = (sqrt(_P_PVdcabs[`i'])/.4 )
        * factor ORDC size by overall label size factor
        local ORDCscale = `ORDCscale' * `LBLscale'
        local ORDCscale = string(`ORDCscale',"%11.3f")

        * orplot: no dc option
        if "`OPTdchange'" == "" local sizeis = `LBLscale'
        else local sizeis = `ORDCscale'

        * dcplot: single size for all letters
        if "`_ordc[_plot_type_]'"=="dcplot" {
            local sizeis = `LBLscale'
        }

        local txt `"text(`yis' `xis' "`ltris'", place(c)"'
        local txt `"`txt' size(*`sizeis') color(`ltrcolor'))"'
        local txtall `"`txtall' `txt'"'

        * underline for negative DC's
        if ("`OPTnosign'"=="") & (`dcis'<0) ///
             & ("`_ordc[_plot_type_]'"=="orplot") {
            local txt `"text(`yis' `xis' "_", place(c)"'
            local txt `"`txt' size(*`sizeis') color(`ltrcolor'))"'
            local txtall `"`txtall' `txt'"'
        }
    }
    char _ordc[plt_markers_text] `"`txtall'"'

//  aspect ratios

    if (`OPTaspect'>0) local aspect "aspectratio(`OPTaspect')"

//  axes labels for orplot

    if "`_ordc[_plot_type_]'"=="orplot" {

        * 045
        local basenm : word `_orp[basecategory]' of `_ordc[est_catNMS]'

        local xtitlebot ///
          "Logit Coefficient Scale Relative to Category `basenm'" // `_ordc[plt_baseNM]'"
        local xtitletop ///
          "Odds Ratio Scale Relative to Category `basenm'" // `_ordc[plt_baseNM]'"
        * 0.4.7
        if "`_ordc[titletop]'"!="" local xtitletop "`_ordc[titletop]'"
        if "`_ordc[titlebottom]'"!="" local xtitlebot "`_ordc[titlebottom]'"
        if "`OPTxlines'"!="" local OPTxlines `"xline(`OPTxlines') "'

        local axis2 = 2
        local xlabel1 `"`_ordc[plt_xticBvalues]',axis(1)"'
        local xlabel2 `"`_ordc[plt_xticORvalues]',axis(`axis2')"'
        local xtitle2 `"`xtitletop', axis(`axis2') size(medsmall)"'
        local xtitle1 `"`xtitlebot',size(medsmall) just(left)"'

    }

//  axes labels for dcplot

    if "`_ordc[_plot_type_]'"=="dcplot" {

        local xtitletop "Discrete Change in Outcome Probability"
        local xtitlebot ""
        * 0.4.7
        if "`_ordc[titletop]'"!="" local xtitletop "`_ordc[titletop]'"
        if "`_ordc[titlebottom]'"!="" local xtitlebot "`_ordc[titlebottom]'"
        if "`OPTxlines'"=="" local OPTxlines `"xline(0, lcolor(gs12)) "'

        local axis2 = 1 // don't use second axis
        local xlabel1 `"`_ordc[plt_xticBvalues]',axis(1)"'
        local xtitle1 `""`xtitlebot'",size(medsmall) just(left)"'
        local xlabel2 ""
        local xtitle2 `""`xtitletop'", axis(`axis2') size(medsmall)"'
    }

//  tune OPTlinegapfac

    local linegapfac = `OPTlinegapfac' * 2.75 // determine empirically

// create graph commands from user options

    foreach t in note title subtitle caption {
        if "`OPT`t''"!="" local `t'text `"`t'(`OPT`t'')"'
        else local `t'text ""
    }

// dummy data for creating dummy plot for second axis

    tempvar ydata xdata showline
    qui gen `ydata' = 1 in 1
    qui gen `xdata' = 0 in 1
    qui gen `showline' = .

    * if packed, no connecting lines
    if "`OPTpacked'"=="packed" {
        qui replace `showline' = (0*_P_PVcatSig)
    }
    else {
        qui replace `showline' = _P_PVcatSig
    }
    local lcol1 : word 1 of `OPTlcolor'
    local lcol2 : word 2 of `OPTlcolor'
    local lcol3 : word 3 of `OPTlcolor'
    local lcol4 : word 4 of `OPTlcolor'
    local lcol5 : word 5 of `OPTlcolor'
    local lwidth1 : word 1 of `OPTlwidth'
    local lwidth2 : word 2 of `OPTlwidth'
    local lwidth3 : word 3 of `OPTlwidth'
    local lwidth4 : word 4 of `OPTlwidth'
    local lwidth5 : word 5 of `OPTlwidth'

    //  graph commands

    #delimit ;

      twoway

        // connecting lines for non-significant contrast

        (
         pccapsym _P_PVcatYfrom _P_PVcatXfrom _P_PVcatYto _P_PVcatXto
            if `showline'==1, legend(off)

            // lines connecting markers
            lcol(`lcol1') lwid(`lwid1') lpat(solid)

            // circles whiting out lines near markers
            mcol(white) msymb(circle) msiz(*`linegapfac')

            // user specified graph options
            `OPTgraph'
        )
        (
         pccapsym _P_PVcatYfrom _P_PVcatXfrom _P_PVcatYto _P_PVcatXto
            if `showline'==2, legend(off)

            // lines connecting markers
            lcol(`lcol2') lwid(`lwid2') lpat(solid)

            // circles whiting out lines near markers
            mcol(white) msymb(circle) msiz(*`linegapfac')

            // user specified graph options
            `OPTgraph'
        )
        (
         pccapsym _P_PVcatYfrom _P_PVcatXfrom _P_PVcatYto _P_PVcatXto
            if `showline'==3, legend(off)

            // lines connecting markers
            lcol(`lcol3') lwid(`lwid3') lpat(solid)

            // circles whiting out lines near markers
            mcol(white) msymb(circle) msiz(*`linegapfac')

            // user specified graph options
            `OPTgraph'
        )
        (
         pccapsym _P_PVcatYfrom _P_PVcatXfrom _P_PVcatYto _P_PVcatXto
            if `showline'==4, legend(off)

            // lines connecting markers
            lcol(`lcol4') lwid(`lwid4') lpat(solid)

            // circles whiting out lines near markers
            mcol(white) msymb(circle) msiz(*`linegapfac')

            // user specified graph options
            `OPTgraph'
        )
        (
         pccapsym _P_PVcatYfrom _P_PVcatXfrom _P_PVcatYto _P_PVcatXto
            if `showline'==5, legend(off)

            // lines connecting markers
            lcol(`lcol5') lwid(`lwid5') lpat(solid)

            // circles whiting out lines near markers
            mcol(white) msymb(circle) msiz(*`linegapfac')

            // user specified graph options
            `OPTgraph'
        )

        // plot x axis labels for logit coefficients
        (
         scatter `ydata' `xdata',

            msymbol(none) legend(off) `aspect'
            xlabel(`xlabel1')
            xtitle(`xtitle1')
            ylabel(`_ordc[plt_ytic_labels]', angle(horiz) noticks nogrid)
        )

        // plot category markers and x axis labels for odds ratios
        (
         scatter _P_PVvarnumoffset _P_PVbeta,
            msymbol(none)
            `_ordc[plt_markers_text]'
            `_ordc[plt_coeftype_text]'
            xaxis(`axis2') xlabel(`xlabel2') xtitle(`xtitle2')
            `OPTxlines'
            ytitle("") ytitle(, size(small))
            yline(`_ordc[plt_ylinevalues]',
                lwidth(vthin) lpattern(solid) lcolor(black))
            `titletext' `subtitletext' `notetext' `captiontext'
        )
        ;
        #delimit cr

    sreturn local error = 0

*TRACE di in blue _new "  = 2 graph => Leaving _ordcplot_graph"

end // _ordcplot_graph

exit

* version 0.3.5v2 2012-08-05 prior to moveing stuff from *data.aod
* version 0.3.5 2012-08-03 scott long
* version 0.3.6 2012-08-05 moved graph options from data.ado
* version 0.3.8a 2012-08-06 offsetlist
* version 0.3.8 2012-08-06 multple line colors in connects
* version 0.3.7 debug during examples
* version 0.3.9 working version
* version 0.4.3 2012-09-04 jsl | matrix | posted
* version 0.4.2 2012-09-04 jsl | varlabel with fv | posted
    * var label needs to be for x1 not 1.x1
* version 0.4.1 2012-09-04 jsl | dcp ocp work | NOT posted
* version 0.4.0 2012-09-03 jsl | cleanup | NOT posted
* version 0.4.4 2012-09-11 | long freese | varlabel matrix
* version 0.4.5 2013-01-19 | long freese | change DC names; fix basecatnm
    * fix min max
* version 0.4.6 2013-01-24 | long freese | msizefactor() fix
* version 0.4.7 2013-01-24 | long freese | symbols() std*labels() titletop titlebottom
* version 0.4.8 2013-01-24 | long freese | tweaks; pvalue; dydx; stars
* version 0.4.9 2013-01-25 | long freese | stagger
