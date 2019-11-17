*! version 0.8.1 - 2009-07-31
*   work around S11 bug in estimates table

*  To do:
*   1) add weights
*   2) use returns rather than scalars

// compare count models

capture program drop countfit
program define countfit, rclass
    version 9.0
    
    * 2009-07-31
    local vwidth = 32 // causes error in Stata 11 
    local vwidth = 30

    syntax varlist [if] [in] ///
    , [Generate(string)  replace ///
      INFlate(string) /// inflation variables
      MAXcount(integer 9) ///
      NOGraph /// suppress graph of differences in predicted probabilities
      NODifferences /// suppress table of differences in predicted probabilities
      NOEstimates /// suppress table of estimated parameters
      NOFit /// suppress table of fit statistics
      Prm Nbreg ZIP ZINb ///
      nodash ///
      NOConstant ///
      NOPRTable ///
      note(string) /// note for graph
      GRAPHexport(string) /// options passed to graph export
      NOIsily ///
      ]

// trap weights

    if "`e(wtype)'"!="" {
        di in r "-countfix- does not work with weights."
        exit
    }

//  define variable lists

    * inflate is same as rhs if not specified
    if "`inflate'"=="" {
        ** better way to do this?
        local nvars : word count `varlist'
        foreach i of numlist 2(1)`nvars' {
            local var : word `i' of `varlist'
            local inflate "`inflate' `var'"
        }
    }

// set up printing

    local f83 "%8.3f"
    local f93 "%9.3f"
    local f93l "%-9.3f"
    local f103 "%10.3f"
    local dash ""
    if "`nodash'"=="" {
        local dash ///
        "--------------------------------------------------------------------------"
    }

// construct information on models being assessed

    * defalult name is CF for variables created
    if "`generate'"=="" local set "CF"
    local set "`generate'" // label for sets of models
    local modellist "" // list of types of models estimated
    local mdlnmlist "" // like modellist but begin with generate prefix _
    local pltsym "" // symbols used in the plot
    local plty "" // y variables to plot
    local pltx "" // x variables to plot
    local mdlnum = 1 // number associated with each model

    * set up information for all models specified
    if "`prm'"=="prm" {
        local mdlnmlist "`mdlnmlist' `set'PRM"
        local modellist "PRM "
        local pltx "`set'PRMval"
        local plty "`set'PRMdif "
        local pltsym "Th "
        local pltleg1 "`set'PRM"
        local mdlnum = `mdlnum' + 1
    }
    if "`nbreg'"=="nbreg" {
        local mdlnmlist "`mdlnmlist' `set'NBRM"
        local modellist "`modellist'NBRM "
        local pltx "`set'NBRMval"
        local plty "`plty' `set'NBRMdif "
        local pltsym "`pltsym' Sh "
        local pltleg`mdlnum' "`set'NBRM"
        local mdlnum = `mdlnum' + 1
    }
    if "`zip'"=="zip" {
        local mdlnmlist "`mdlnmlist' `set'ZIP"
        local modellist "`modellist'ZIP "
        local pltx "`set'ZIPval"
        local plty "`plty' `set'ZIPdif "
        local pltsym "`pltsym' T "
        local pltleg`mdlnum' "`set'ZIP"
        local mdlnum = `mdlnum' + 1
    }
    if "`zinb'"=="zinb" {
        local mdlnmlist "`mdlnmlist' `set'ZINB"
        local modellist "`modellist'ZINB "
        local pltx "`set'ZINBval"
        local plty "`plty' `set'ZINBdif "
        local pltsym "`pltsym' S "
        local pltleg`mdlnum' "`set'ZINB"
        local mdlnum = `mdlnum' + 1
    }
    * if none, then all
    if "`prm'"=="" & "`nbreg'"=="" & "`zip'"=="" & "`zinb'"=="" {
        local pltx "`set'PRMval"
        local plty "`set'PRMdif `set'NBRMdif `set'ZIPdif `set'ZINBdif"
        local pltsym "Th Sh T S"
        local pltleg1 "`set'PRM"
        local pltleg2 "`set'NBRM"
        local pltleg3 "`set'ZIP"
        local pltleg4 "`set'ZINB"
        local mdlnmlist "`set'PRM `set'NBRM `set'ZIP `set'ZINB"
        local modellist "PRM NBRM ZIP ZINB"
        local prm "prm"
        local nbreg "nbreg"
        local zip "zip"
        local zinb "zinb"
        * drop? local alphaopt "drop(lnalpha:_cons)"
    }

// estimate models

    * 2009-07-31
    _count_estimate `varlist' `if' `in' [`fweight' `pweight' `iweight'], ///
        max(`maxcount') gen(`generate') `replace' inflate(`inflate') ///
        `prm' `nbreg' `zip' `zinb' `noconstant' `noisily'

// table of estimates


    if "`noestimates'"=="" {
        estimates table `mdlnmlist', eform ///
            b(%9.3f) t(%7.2f) label varwidth(`vwidth') ///
            stats(alpha N ll bic aic)
    }

// summary table of mean observed - predicted probabilities

    local c1 = 10
    local c2 = 25
    local c3 = 31
    local c4 = 47

    if "`nodifferences'"=="" {

        di in g "Comparison of Mean Observed and Predicted Count"
        di
        di in g "     " _col(`c1') "   Maximum"    ///
            _col(`c2') "  At" ///
            _col(`c3') "    Mean"
        di in g "Model" _col(`c1') " Difference" ///
            _col(`c2') "Value" ///
            _col(`c3') "   |Diff|"
        di in g "---------------------------------------------"
    }

    * loop through models and compute differences
    foreach m in `modellist' {

        local modelnm "`set'`m'"

        * stats on difference
        qui sum `modelnm'dif
        local toplot "`toplot' `modelnm'dif"
        local `m'difsd = r(sd) // sd of obs-pred
        local `m'difmin = r(min) // min
        local `m'difmax = r(max) // max

        * stats on mean absolute difference
        capture drop `modelnm'difabs
        qui gen `modelnm'absdif = abs(`modelnm'dif)
        qui sum `modelnm'absdif
        local `m'absdifmax = r(max) // max
        scalar absdifsd`m' = r(sd) // sd
        scalar absdifmn`m' = r(mean) // mean
        * find values for largest difference
        tempname difval
        qui gen `difval' = (`modelnm'absdif>``m'absdifmax'-.00001)*_n ///
                if `modelnm'absdif!=.
        qui sum `difval'
        local `m'absdifmaxval = r(max) - 1

        * sign of deviation
        tempname maxdif // 0.8.0
        if ``m'absdifmax' == abs(``m'difmin') {
        *local maxdif = ``m'difmin' // 0.8.0
            scalar `maxdif' = ``m'difmin'
        }
        if ``m'absdifmax' == abs(``m'difmax') {
        *local maxdif = ``m'difmax' // 0.8.0
            scalar `maxdif' = ``m'difmax'
        }

        if "`nodifferences'"=="" {
            * print summary of differences from predictions
            di in y "`modelnm'" _col(`c1') in y `f83' `maxdif' ///
                _col(`c2') `f83' "  ``m'absdifmaxval'" ///
                _col(`c3') `f83' absdifmn`m'
        }

    } // loop through models

// TABLES OF OBSERVED AND PREDICTED COUNTS

    if "`noprtable'" == "" {

        foreach t in `mdlnmlist' {

            qui {
                sum `t'absdif
                local max = r(N) - 1 // largest count
                tempname sumde sumpe sumob sumpr // 0.8.0
                scalar `sumde' = r(sum) // sum of abs dif
                sum `t'pearson
                scalar `sumpe' = r(sum) // sum of pearson dif
                sum `t'obeq
                scalar `sumob' = r(sum) // sum of pr observed
                sum `t'preq
                scalar `sumpr' = r(sum) // sum of pr predicted
            } // qui
            local c1 = 7
            local c2 = 19
            local c3 = 30
            local c4 = 40
            local c5 = 50
            di
            di in y "`t'" in g ": Predicted and actual probabilities"
            di
            di in g "Count" _col(`c1') "  Actual" ///
                _col(`c2') "Predicted" ///
                _col(`c3') "  |Diff|" ///
                _col(`c4') " Pearson"

            local dash ""
            if "`nodash'"=="" {
                local dash ///
                "------------------------------------------------"
            }

            di in g "`dash'"

            foreach c of numlist 0(1)`max' {
                local i = `c' + 1
                tempname ob pr de pe // 0.8.0
                scalar `ob' = `t'obeq[`i']
                scalar `pr' = `t'preq[`i']
                scalar `de' = abs(`t'dif[`i'])
                scalar `pe' = `t'pearson[`i']

                di in y "`c'" ///
                    _col(`c1') `f83' `ob' ///
                    _col(`c2') `f83' `pr' ///
                    _col(`c3') `f83' `de' ///
                    _col(`c4') `f83' `pe'

            } // loop through counts

            di in g "`dash'"
            di in y "Sum" ///
                _col(`c1') `f83' `sumob' ///
                _col(`c2') `f83' `sumpr' ///
                _col(`c3') `f83' `sumde' ///
                _col(`c4') `f83' `sumpe'

        } // loop through modellist

    } // print table of predictions

// PLOT DIFFERENCES

    if "`nograph'"=="" {

        twoway (connected `plty' `pltx', ///
            msymbol(`pltsym') ///
            clpat(tight_dot tight_dot tight_dot tight_dot ) ///
            ytitle("Observed-Predicted") ///
            subtitle("Note: positive deviations show underpredictions.",  ///
            pos(11) size(small)) ///
            ylabel(-.10(.05).10, grid gmax gmin) ///
            xlabel(0(1)`maxcount') ///
            note(`note') ///
            ysize(3.5) xsize(4.5) ///
            legend(order(1 "`pltleg1'" 2 "`pltleg2'" ///
            3 "`pltleg3'" 4 "`pltleg4'")) ///
        )

        * export graph
        if "`graphexport'" != "" {
            qui graph export `graphexport'
        }

    }

// COMPARE FIT STATISTICS

    if "`nofit'"=="" {

        local dash ""
        if "`nodash'"=="" {
        local dash ///
    "-------------------------------------------------------------------------"
        }
        local c1 = 16
        local c2 = 32
        local c3 = 48
        local c4 = 56
        local c5 = 62

        di _n in g "Tests and Fit Statistics"
        di
        tempname aicd  // 0.8.0

        * base PRM
        if "`prm'"!="" {
            local mdl1 "`set'PRM"
            local mdl1type "PRM"
            di in y "`mdl1'" ///
                _col(`c1') in g "BIC=" in y `f103' bic`mdl1' ///
                _col(`c2') in g "AIC=" in y `f103' aic`mdl1' ///
                _col(`c3') in g "Prefer" ///
                _col(`c4') in g "Over" ///
                _col(`c5') in g "Evidence"

            * prm vs nbreg
            if "`nbreg'"!="" {
                local mdl2 "`set'NBRM"
                local mdl2type "NBRM"
                global bic1 = bic`mdl1'
                global bic2 = bic`mdl2'
                _count_bic_dif
                local pref = $bicpref
                local nopref = $bicnopref
                di "`dash'"
                * bic
                di in y " " in g " vs " in y "`mdl2'" ///
                    _col(`c1') in g "BIC=" in y `f103' bic`mdl2' ///
                    _col(`c2') in g "dif=" in y `f103' $bicdif ///
                    _col(`c3') in y "`mdl`pref'type'" ///
                    _col(`c4') in y "`mdl`nopref'type'" ///
                    _col(`c5') in y "$bicsup"
                * aic
                scalar `aicd' = aic`mdl1' - aic`mdl2'
                local aicfav "`mdl2type'"
                local aicnofav "`mdl1type'"
                if aic`mdl1' < aic`mdl2' {
                    local aicfav "`mdl1type'"
                    local aicnofav "`mdl2type'"
                }
                di  _col(`c1') in g "AIC=" in y `f103' aic`mdl2' ///
                    _col(`c2') in g "dif=" in y `f103' `aicd' ///
                    _col(`c3') in y "`aicfav'" ///
                    _col(`c4') in y "`aicnofav'"
                * lr test
                local lrfav "`mdl1type'"
                local lrnofav "`mdl2type'"
                if lrnb_prmp < .05 {
                    local lrfav "`mdl2type'"
                    local lrnofav "`mdl1type'"
                }
                di _col(`c1') in g "LRX2=" in y `f93' lrnb_prm ///
                    _col(`c2') in g "prob=" in y `f93' lrnb_prmp in g ///
                    _col(`c3') in y "`lrfav'" ///
                    _col(`c4') in y "`lrnofav'" ///
                    _col(`c5') in y "p=" `f93l' lrnb_prmp
            } // no nbreg vs prm

            * prm vs zip
            if "`zip'"!="" {
                local mdl2 "`set'ZIP"
                local mdl2type "ZIP"
                * bic
                global bic1 = bic`mdl1'
                global bic2 = bic`mdl2'
                _count_bic_dif
                local pref = $bicpref
                local nopref = $bicnopref
                di in g "`dash'"
                di in y " " in g " vs " in y "`mdl2'" ///
                    _col(`c1') in g "BIC=" in y `f103' bic`mdl2' ///
                    _col(`c2') in g "dif=" in y `f103' $bicdif ///
                    _col(`c3') in y "`mdl`pref'type'" ///
                    _col(`c4') in y "`mdl`nopref'type'" ///
                    _col(`c5') in y "$bicsup"
                * aic
                tempname aicd // 0.8.0
                scalar `aicd' = aic`mdl1' - aic`mdl2'
                local aicfav "`mdl2type'"
                local aicnofav "`mdl1type'"
                if aic`mdl1' < aic`mdl2' {
                    local aicfav "`mdl1type'"
                    local aicnofav "`mdl2type'"
                }
                di _col(`c1') in g "AIC=" in y `f103' aic`mdl2' ///
                        _col(`c2') in g "dif=" in y `f103' `aicd' ///
                        _col(`c3') in y "`aicfav'" ///
                        _col(`c4') in y "`aicnofav'"
                * vuong test
                local vufav "`mdl1type'"
                local vunofav "`mdl2type'"
                if vu`mdl2'>0  {
                    local vufav "`mdl2type'"
                    local vunofav "`mdl1type'"
                }
                di _col(`c1') in g "Vuong=" in y `f83' vu`mdl2' ///
                    _col(`c2') in g "prob=" in y `f93' vu`mdl2'p in g ///
                    _col(`c3') in y "`vufav'" ///
                    _col(`c4') in y "`vunofav'" ///
                    _col(`c5') in y "p=" `f93l' vu`mdl2'p
            } // no zip vs prm

            * prm vs zinb
            if "`zinb'"!="" {
                local mdl2 "`set'ZINB"
                local mdl2type "ZINB"
                * bic
                global bic1 = bic`mdl1'
                global bic2 = bic`mdl2'
                _count_bic_dif
                local pref = $bicpref
                local nopref = $bicnopref
                di in g "`dash'"
                di in y " " in g " vs " in y "`mdl2'" ///
                    _col(`c1') in g "BIC=" in y `f103' bic`mdl2' ///
                    _col(`c2') in g "dif=" in y `f103' $bicdif ///
                    _col(`c3') in y "`mdl`pref'type'" ///
                    _col(`c4') in y "`mdl`nopref'type'" ///
                    _col(`c5') in y "$bicsup"
                * aic
                scalar `aicd' = aic`mdl1' - aic`mdl2'
                local aicfav "`mdl2type'"
                local aicnofav "`mdl1type'"

                if aic`mdl1' < aic`mdl2' {
                    local aicfav "`mdl1type'"
                    local aicnofav "`mdl2type'"
                }
                di _col(`c1') in g "AIC=" in y `f103' aic`mdl2' ///
                    _col(`c2') in g "dif=" in y `f103' `aicd' ///
                    _col(`c3') in y "`aicfav'" ///
                    _col(`c4') in y "`aicnofav'"
            } // no zinb vs prm

        } // if no prm

        * base nbreg
        if "`nbreg'"!="" {
            local mdl1 "`set'NBRM"
            local mdl1type "NBRM"
            di in g "`dash'"
            di in y "`mdl1'" ///
                _col(`c1') in g "BIC=" in y `f103' bic`mdl1' ///
                _col(`c2') in g "AIC=" in y `f103' aic`mdl1' ///
                _col(`c3') in g "Prefer" ///
                _col(`c4') in g "Over" ///
                _col(`c5') in g "Evidence"

            * nbreg vs zip
            if "`zip'"!="" {
                local mdl2 "`set'ZIP"
                local mdl2type "ZIP"
                * bic
                global bic1 = bic`mdl1'
                global bic2 = bic`mdl2'
                _count_bic_dif
                local pref = $bicpref
                local nopref = $bicnopref
                di in g "`dash'"
                di in y " " in g " vs " in y "`mdl2'" ///
                    _col(`c1') in g "BIC=" in y `f103' bic`mdl2' ///
                    _col(`c2') in g "dif=" in y `f103' $bicdif ///
                    _col(`c3') in y "`mdl`pref'type'" ///
                    _col(`c4') in y "`mdl`nopref'type'" ///
                    _col(`c5') in y "$bicsup"
                * aic
                scalar `aicd' = aic`mdl1' - aic`mdl2'
                local aicfav "`mdl2type'"
                local aicnofav "`mdl1type'"

                if aic`mdl1' < aic`mdl2' {
                    local aicfav "`mdl1type'"
                    local aicnofav "`mdl2type'"
                }
                di _col(`c1') in g "AIC=" in y `f103' aic`mdl2' ///
                    _col(`c2') in g "dif=" in y `f103' `aicd' ///
                    _col(`c3') in y "`aicfav'" ///
                    _col(`c4') in y "`aicnofav'"
             } // no zip vs nbreg

            * nbreg vs zinb
            if "`zinb'"!="" {
                local mdl2 "`set'ZINB"
                local mdl2type "ZINB"
                * bic
                global bic1 = bic`mdl1'
                global bic2 = bic`mdl2'
                _count_bic_dif
                local pref = $bicpref
                local nopref = $bicnopref
                di in g "`dash'"
                di in y " " in g " vs " in y "`mdl2'" ///
                    _col(`c1') in g "BIC=" in y `f103' bic`mdl2' ///
                    _col(`c2') in g "dif=" in y `f103' $bicdif ///
                    _col(`c3') in y "`mdl`pref'type'" ///
                    _col(`c4') in y "`mdl`nopref'type'" ///
                    _col(`c5') in y "$bicsup"
                * aic
                scalar `aicd' = aic`mdl1' - aic`mdl2'
                local aicfav "`mdl2type'"
                local aicnofav "`mdl1type'"
                if aic`mdl1' < aic`mdl2' {
                    local aicfav "`mdl1type'"
                    local aicnofav "`mdl2type'"
                }
                di _col(`c1') in g "AIC=" in y `f103' aic`mdl2' ///
                    _col(`c2') in g "dif=" in y `f103' `aicd' ///
                    _col(`c3') in y "`aicfav'" ///
                    _col(`c4') in y "`aicnofav'"
                * vuong test
                local vufav "`mdl1type'"
                local vunofav "`mdl2type'"
                if vu`mdl2'>0  {
                    local vufav "`mdl2type'"
                    local vunofav "`mdl1type'"
                }
                di _col(`c1') in g "Vuong=" in y `f83' vu`mdl2' ///
                    _col(`c2') in g "prob=" in y `f93' vu`mdl2'p in g ///
                    _col(`c3') in y "`vufav'" ///
                    _col(`c4') in y "`vunofav'" ///
                    _col(`c5') in y "p=" `f93l' vu`mdl2'p

            } // no zinb vs nbreg

        } // if no nbreg

        if "`zip'"!="" {

            local mdl1 "`set'ZIP"
            local mdl1type "ZIP"
            di in g "`dash'"
            di in y "`mdl1'" ///
                _col(`c1') in g "BIC=" in y `f103' bic`mdl1' ///
                _col(`c2') in g "AIC=" in y `f103' aic`mdl1' ///
                _col(`c3') in g "Prefer" ///
                _col(`c4') in g "Over" ///
                _col(`c5') in g "Evidence"

            * zip vs zinb
            if "`zinb'"!="" {
                local mdl2 "`set'ZINB"
                local mdl2type "ZINB"
                * bic
                global bic1 = bic`mdl1'
                global bic2 = bic`mdl2'
                _count_bic_dif
                local pref = $bicpref
                local nopref = $bicnopref
                di in g "`dash'"
                di in y " " in g " vs " in y "`mdl2'" ///
                    _col(`c1') in g "BIC=" in y `f103' bic`mdl2' ///
                    _col(`c2') in g "dif=" in y `f103' $bicdif ///
                    _col(`c3') in y "`mdl`pref'type'" ///
                    _col(`c4') in y "`mdl`nopref'type'" ///
                    _col(`c5') in y "$bicsup"
                * aic
                scalar `aicd' = aic`mdl1' - aic`mdl2'
                local aicfav "`mdl2type'"
                local aicnofav "`mdl1type'"
                if aic`mdl1' < aic`mdl2' {
                    local aicfav "`mdl1type'"
                    local aicnofav "`mdl2type'"
                }
                di _col(`c1') in g "AIC=" in y `f103' aic`mdl2' ///
                    _col(`c2') in g "dif=" in y `f103' `aicd' ///
                    _col(`c3') in y "`aicfav'" ///
                    _col(`c4') in y "`aicnofav'"
                * lr test
                local lrfav "`mdl1type'"
                local lrnofav "`mdl2type'"
                if lrnb_prmp < .05 {
                    local lrfav "`mdl2type'"
                    local lrnofav "`mdl1type'"
                }
                di _col(`c1') in g "LRX2=" in y `f93' lrzip_zinb ///
                    _col(`c2') in g "prob=" in y `f93' lrzip_zinbp in g ///
                    _col(`c3') in y "`lrfav'" ///
                    _col(`c4') in y "`lrnofav'" ///
                    _col(`c5') in y "p=" `f93l' lrnb_prmp
                di in g "`dash'"

            } // no zinb vs zip

        } // no zip

}  // no fit

end

// compute strength of bic difference?

capture program drop _count_bic_dif
program define _count_bic_dif

    * compute bin diff from model 1 and model 2
    global bicdif = $bic1 - $bic2
    tempname bicdabs // 0.8.0
    scalar `bicdabs' = abs($bicdif)

    * evaluate support based on bic difference
    if `bicdabs'~=. {
        global bicsup "Very strong"
        if `bicdabs'<= .0000000001 {
            global bicsup "no"
            }
        else if `bicdabs' <=2      {
            global bicsup "Weak"
        }
        else if `bicdabs' <=6      {
            global bicsup "Positive"
        }
        else if `bicdabs' <=10     {
            global bicsup "Strong"
        }
        global bicpref = 2
        global bicnopref = 1
        if $bicdif < 0 {
            global bicpref = 1
            global bicnopref = 2
        }
        if `bicdabs'< .0000000001 & `bicdabs'>-.0000000001 {
            global bicpref = 0
        }

    }
end

// ESTIMATE MODELS AND STORE RESULTS

capture program drop _count_estimate
program define _count_estimate, rclass

    syntax varlist [if] [in] [,     ///
      inflate(varlist) ///
      MAXcount(integer 9) Generate(string) replace ///
      Prm Nbreg ZIP ZINb NOConstant ///
      NOIsily ]

// estimate models & create globals with stats

    local set "`generate'"
    tempname n

    local noise ""
    if "`noisily'"=="noisily" {
        local noise "noisily"
    }

// prm

    if "`prm'"!="" {
        qui {
            local modelnm "PRM"
            local fullnm "`set'`modelnm'"
            `noise' poisson `varlist' `if' `in', `noconstant'
            estimates store `fullnm'
            scalar ll`fullnm' = e(ll) // log lik
            fitstat, bic
            scalar bicp`fullnm' = r(bic_p) // bic'
            return scalar bicp`fullnm' = r(bic_p) // 0.8.0
            scalar aic`fullnm' = r(aic) // aic
            scalar x2`fullnm' = r(lrx2) // lrx2 all b=0
            scalar x2p`fullnm' = r(lrx2_p)
            scalar bic`fullnm' =  r(bic) // bic
            if "`replace'"=="replace" {
                capture drop `fullnm'rate
                capture drop `fullnm'prgt
                capture drop `fullnm'val
                capture drop `fullnm'obeq
                capture drop `fullnm'preq
                capture drop `fullnm'prle
                capture drop `fullnm'oble
                capture drop `fullnm'absdif
                capture drop `fullnm'dif
                capture drop `fullnm'pearson
                local i = 0
                while `i'<=`maxcount' {
                    capture drop `fullnm'pr`i'
                    capture drop `fullnm'cu`i'
                    local i = `i' + 1
                }
            }
            prcounts `fullnm', plot max(`maxcount') // predicted counts
            label var `fullnm'preq "`modelnm' predicted" // predicted Pr(y)
            gen `fullnm'dif = `fullnm'obeq - `fullnm'preq // obs - predicted
            label var `fullnm'dif  "`modelnm' obs - pred"
            * 2004-10-29 add CT 5.34
            scalar `n' = e(N) // sample size
            gen `fullnm'pearson = ///
                (`n' * `fullnm'dif * `fullnm'dif) / `fullnm'preq
            label var `fullnm'pearson "`modelnm' contribution to Pearson X2"
            sum `fullnm'pearson
        } // qui
    }

// nbreg

    if "`nbreg'"!="" {
        qui {
            local modelnm "NBRM"
            local fullnm "`set'`modelnm'"
            `noise' nbreg `varlist' `if' `in', `noconstant'
            estimates store `fullnm'
            scalar ll`fullnm' = e(ll) // log lik

            scalar lrnb_prm = e(chi2_c) // lrx2 of nb vs prm
            scalar lrnb_prmp = chiprob(1, e(chi2_c))*0.5

            fitstat, bic
            scalar bicp`fullnm' = r(bic_p) // bic'
            scalar aic`fullnm' = r(aic) // aic
            scalar x2`fullnm' = r(lrx2) // lrx2 all b=0
            scalar x2p`fullnm' = r(lrx2_p)
            scalar bic`fullnm' =  r(bic) // bic

            if "`replace'"=="replace" {
                capture drop `fullnm'rate
                capture drop `fullnm'prgt
                capture drop `fullnm'val
                capture drop `fullnm'obeq
                capture drop `fullnm'preq
                capture drop `fullnm'prle
                capture drop `fullnm'oble
                capture drop `fullnm'dif
                capture drop `fullnm'absdif
                capture drop `fullnm'pearson
                local i = 0
                while `i'<=`maxcount' {
                    capture drop `fullnm'pr`i'
                    capture drop `fullnm'cu`i'
                    local i = `i' + 1
                }
            }

            prcounts `fullnm', plot max(`maxcount') // predicted counts
                label var `fullnm'preq "`modelnm' predicted"
            gen `fullnm'dif = `fullnm'obeq - `fullnm'preq
                label var `fullnm'dif  "`modelnm' obs - pred"
            * 2004-10-29 add CT 5.34
            scalar `n' = e(N) // sample size
            gen `fullnm'pearson = ///
                (`n' * `fullnm'dif * `fullnm'dif) / `fullnm'preq
            label var `fullnm'pearson "`modelnm' contribution to Pearson X2"
            sum `fullnm'pearson
        } // qui
    }

// zip

    if "`zip'"!="" {
        qui {
            local modelnm "ZIP"
            local fullnm "`set'`modelnm'"
            `noise' zip `varlist' `if' `in', ///
                inf(`inflate') vuong `noconstant'
            estimates store `fullnm'
            scalar vu`fullnm' = e(vuong) // vuong vs prm
            scalar vu`fullnm'p = 1-norm(abs(e(vuong)))
            scalar ll`fullnm' = e(ll) // log lik
            fitstat, bic
            scalar bicp`fullnm' = r(bic_p) // bic'
            scalar aic`fullnm' = r(aic) // aic
            scalar x2`fullnm' = r(lrx2) // lrx2 all b=0
            scalar x2p`fullnm' = r(lrx2_p)
            scalar bic`fullnm' =  r(bic) // bic
            if "`replace'"=="replace" {
                capture drop `fullnm'rate
                capture drop `fullnm'prgt
                capture drop `fullnm'val
                capture drop `fullnm'obeq
                capture drop `fullnm'preq
                capture drop `fullnm'prle
                capture drop `fullnm'oble
                capture drop `fullnm'all0
                capture drop `fullnm'dif
                capture drop `fullnm'absdif
                capture drop `fullnm'pearson
                local i = 0
                while `i'<=`maxcount' {
                    capture drop `fullnm'pr`i'
                    capture drop `fullnm'cu`i'
                    local i = `i' + 1
                }
            }

            prcounts `fullnm', plot max(`maxcount') // predicted counts
            label var `fullnm'preq "`modelnm' predicted"
            gen `fullnm'dif = `fullnm'obeq - `fullnm'preq
            label var `fullnm'dif  "`modelnm' obs - pred"
            * 2004-10-29 add CT 5.34
            scalar `n' = e(N) // sample size
            gen `fullnm'pearson = ///
                (`n' * `fullnm'dif * `fullnm'dif) / `fullnm'preq
            label var `fullnm'pearson "`modelnm' contribution to Pearson X2"
            qui sum `fullnm'pearson
        } // qui
    }

// zinb

    if "`zinb'"!="" {
        qui {
            local modelnm "ZINB"
            local fullnm "`set'`modelnm'"
            `noise' zinb `varlist'  `if' `in', ///
                inf(`inflate') vuong zip `noconstant'
            estimates store `fullnm'
            scalar vu`fullnm' = e(vuong) // vuong vs nbreg
            scalar vu`fullnm'p = 1-norm(abs(e(vuong)))
            scalar ll`fullnm' = e(ll) // loglik
            scalar lrzip_zinb = e(chi2_cp) // lrx2 zinb vs zip
            scalar lrzip_zinbp = chiprob(1, e(chi2_cp))*0.5
            fitstat, bic
            scalar bicp`fullnm' = r(bic_p) // bic'
            scalar aic`fullnm' = r(aic) // aic
            scalar x2`fullnm' = r(lrx2) // lrx2 all b=0
            scalar x2p`fullnm' = r(lrx2_p)
            scalar bic`fullnm' =  r(bic) // bic
            if "`replace'"=="replace" {
                capture drop `fullnm'rate
                capture drop `fullnm'prgt
                capture drop `fullnm'val
                capture drop `fullnm'obeq
                capture drop `fullnm'preq
                capture drop `fullnm'prle
                capture drop `fullnm'oble
                capture drop `fullnm'absdif
                capture drop `fullnm'dif
                capture drop `fullnm'all0
                capture drop `fullnm'pearson
                local i = 0
                while `i'<=`maxcount' {
                    capture drop `fullnm'pr`i'
                    capture drop `fullnm'cu`i'
                    local i = `i' + 1
                }
            }

            prcounts `fullnm', plot max(`maxcount') // predicted counts
            label var `fullnm'preq "`modelnm' predicted"
            gen `fullnm'dif = `fullnm'obeq - `fullnm'preq
            label var `fullnm'dif  "`modelnm' obs - pred"
            * 2004-10-29 add CT 5.34
            scalar `n' = e(N) // sample size
            gen `fullnm'pearson = ///
                (`n' * `fullnm'dif * `fullnm'dif) / `fullnm'preq
            label var `fullnm'pearson "`modelnm' contribution to Pearson X2"
            qui sum `fullnm'pearson
        } // qui
    }

end // _count_estimate

exit
* version 0.8.0 fix pr bug
* version 0.2.1 13Apr2005 add replace; trap weights
* version 0.2.0 27Feb2005 first documented version
