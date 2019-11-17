*! version 3.0.3 xx2015-04-18 | long freese | stat(ci p) allowed
* version 3.0.2 2014-09-15 | long freese | desc with svy; desc only sel vars
* version 3.0.1 2014-07-25 | long freese | scalar _mchangecentered
* version 3.0.0 2014-07-24 | long freese | centered is default

//  discrete change using margins

program define mchange, rclass

    version 11.2

    if _caller() >= 12 {
        local VERSION : display "version " string(_caller()) ":"
    }

    syntax [varlist(default=none fv)] [if] [in] , ///
        [ OUTcome(string) cpr(string) pr(string) /// predict(xxx(*))
        STATS(string asis) STATistics(string asis) ///
        AMount(string) delta(real 0) trim(numlist >-1 integer) UNCENtered ///
        CENTERed ///
        at(string) ATMEANs /// use atmean option for margins
        brief DESCriptives /// descriptive statistics
        MATrix(string) /// name for saving r(table)
        title(string) /// matrix title
        DECimals(numlist >-1 integer) WIDth(numlist >5 integer) ///
        COMMANDs DETails VERBose NOIsily * ]

    tempname predvar predbasemat ATmat ATmatconstant descstats
    tempname blankmat varmat allchanges pwmatall prmat
    tempname prtvec tempvec prtmat amtmat pwmat

    * 3.0.0 make centered the default
    if "`uncentered'"=="uncentered" { // for those used to uncentered option
        display ///
"Note: uncentered is the default; use option centered for centered change."
    }
    local uncentered "uncentered" // default
    if "`centered'"=="centered" {
        local uncentered "" // uncentered change
        scalar _mchangecentered = 1
    }
    else {
        scalar _mchangecentered = 0 // indicate nature of saved matrix
    }

    if "`e(cmd)'"=="margins" {
        display as error ///
        "margins estimates are in memory, not those from a regression model"
        exit
    }
    if "`e(cmd)'"=="" {
        display as error "no regression estimates are in memory"
        exit
    }

    local isover = strpos("`*'","over(")
    if `isover'>0 {
        display as error ///
        "over() option is not allowed with -mchange-"
        exit
    }

    * remove fv syntax: 1.x to x
    if "`varlist'"!="" {
        foreach nm in `varlist' {
             _ms_parse_parts `nm'
             local cleannms "`cleannms'`r(name)' "
        }
        local varlist : list uniq cleannms
    }

    local error = 0
    if (_caller()<13) local pre13 = 1
    else local pre13 = 0 // pre stata 13

    if "`e(cmd)'"=="" | "`e(cmd)'"=="margins" {
        display as error "no estimation command is in memory"
        exit
    }
    estimates store _mc_model // last model estiamted
    local ATbase "`at'" // at specification
    if "`ATbase'"!="" | "`atmeans'"=="atmeans" {
        if "`ATbase'"!="" local atspec "at(`ATbase')"
        if "`atmeans'"=="atmeans" local atspec "`atspec' atmeans"
        local atspec = trim("`atspec'")
        return local atspec "`atspec'"
    }

//  evaluate amount

    local AMTall "bin one sd rng marg" // all types in print order
    local AMTabbrev "`AMTall'"
    local AMTcont "one sd marg" // default for continuous
    foreach amt in `AMTall' {
        local is`amt' = 0
    }
    local amount : subinstr local amount "delta" "sd", all
    if ("`amount'"=="") local amount "`AMTcont'"
    if ("`amount'"=="all") local amount "`AMTall'"
    local isbad = 0
    if "`amount'"!="" { // amounts for continuous variables
        local new ""
        foreach amtnm in `amount' {
            parse_amt, `amtnm'
            local new "`new'`s(amount)' "
            if "`s(isbad)'"=="1" {
                display as error "invalid amount: `amtnm'"
                local isbad = 1
                exit
            }
            else local is`s(amount)' = 1
        }
        local amount "`new'"
    }
    if ("`amount'"!="") local AMTcont "`amount'"

//  evaluate statistics

    local STATall       "change pvalue ll ul z se start end"
    local STATnostrtend "change pvalue ll ul z se"
    local STATdefault   "change pvalue"
    local locb = 1
    local locse = 2
    local locz = 3
    local locp = 4
    local loclb = 5
    local locub = 6
    local locst = 7
    local locen = 8
    if ("`stats'"!="" & "`statistics'"=="") local statistics "`stats'"
    if ("`statistics'"=="") local statistics `STATdefault'
    local statistics : subinstr local statistics "ci" "change ll ul", all
            
    if ("`statistics'"=="ci") local statistics "change ll ul"
    if ("`statistics'"=="all") local statistics `STATall'

    if "`statistics'"!="" { // select statistics
        local new ""
        foreach snm in `statistics' {
            parse_stat, `snm'
            local new "`new'`s(stat)' "
            if "`s(isbad)'"=="1" {
                display as error "invalid statistic `s(stat)'"
                local isbad = 1
                exit
            }
        }
        local statistics "`new'"
    }
    if ("`isbad'"=="1") exit

    local STATprt "`statistics'"
    if ("`STATprt'"=="") local STATprt "`STATdefault'"
    if ("`STATprt'"=="all") local STATprt "`STATall'"
    local ipos : list posof "change" in STATprt // must compute change stat
    if (`ipos'==0) local STATprt "change `statistics'"
    local iposu : list posof "`ul'" in STATprt
    local iposl : list posof "`ll'" in STATprt
    if (`iposu'>0 | `iposl'>0) isci = 1
    else local isci = 0

//  model information

    _rm_modelinfo2
    local varnms `s(rhs_core)'
    if ("`varlist'"!="") local varnms "`varlist'"
    local nvarnms = wordcount("`varnms'")
    local TYPEfac `s(rhs_typefactor)' // which vars are factor vars
    local TYPEvar `s(rhs_typevariable)' // which are c. variables
    local MDLtitle "`r(cmdnm)'"
    local is_svy = `r(cmdsvy)'
    if (`is_svy') local MDLtitle "svy `MDLtitle'"
    local lhscatsN = `r(lhscatn)'
    local lhsnm "`r(lhsnm)'"
    local lhscatnms "`r(lhscatnms)'"
    local lhscatvals "`r(lhscatvals)'"
    local origcatvals `lhscatvals'
    local origcatnms `"`lhscatnms'"'
    local MDLbrm = `r(cmdbin)'
    if `MDLbrm' local lhscatvals "1" // assumes no outcome()
    local MDLcrmmu = `r(cmdcrm)' // count rate
    local MDLcrmpr = 0 // count prob
    if `MDLcrmmu' {
        local lhscatsN = 1
        local lhscatnms "Rate"
        local lhscatvals "1"
    }
    local MDLother "`r(cmdunclassified)'"
    if `MDLother' {
        if "`lhscatsN'"=="0" {
            local lhscatsN = 1
            local lhscatvals "1"
            local lhscatnms "estimate"
        }
        else local MDLother = 0 // multiple outcomes not treated as other
    }

    * matrix column for results
    if (`lhscatsN'==1) local singlecolnum = 1
    else local singlecolnum = 0
    if (`MDLbrm'==1) local singlecolnum = 2 // brm in col 2 of matrices

    _rm_margins_modeltype // binary, discrete, count, other
    local modeltype "`s(modeltype)'"
    if ("`modeltype'"=="discrete" & "`outcome'"=="") local outcome "*"
    if "`outcome'"=="*" | "`outcome'"=="_all" {
        qui levelsof `e(depvar)' if e(sample)==1, local(outcome)
    }
    _rm_margins_parse_predict, modeltype(`modeltype') ///
        outcome(`outcome') cpr(`cpr') pr(`pr') // `options'
    if `s( iserror)' exit
    local predictfirst "`s(predictfirst)'"
    local predictform "`s(predictform)'"
    local outcomes "`s(outcomes)'"
    local outcomesN = wordcount("`outcomes'")
    local ismultiple = `s(ismultiple)'
    local issingle = 1 - `ismultiple'
    if `MDLcrmmu' & "`outcomes'"!="" {
        local ismultiple = 1
        local issingle = 1 - `ismultiple'
        local MDLcrmmu = 0
        local MDLcrmpr = 1 - `MDLcrmmu'
    }
    if "`outcomes'"!="" {
        local lhscatvals "`outcomes'"
        local lhscatsN = wordcount("`lhscatvals'")
        if `MDLcrmpr' local lhscatnms "`lhscatvals'"
        else {
            local lhscatnms ""
            foreach cat in `lhscatvals' {
                local ipos : list posof "`cat'" in origcatvals
                local cnm : word `ipos' of `origcatnms'
                local lhscatnms `"`lhscatnms' "`cnm'" "'
            }
        }
    }

//  decode options & create footnotes

    if ("`decimals'"=="") local decimals = 3
    if ("`width'"=="") local width = 9
    local twid = 12 // width of left margins

    local quicmd "quietly" // listing of command
    if ("`commands'"=="commands") local quicmd "noisily"
    if ("`verbose'"=="verbose") local details "details"
    local quimar "quietly"
    if "`details'" == "details" {
        local quimar "noisily"
        local quicmd "noisily"
    }

    local NOTEsample ""
    if ("`if'"=="") local if "if e(sample)==1"
    else local if "`if' & e(sample)==1"
    if ("`if'"!="") & ("`if'"!="if e(sample)==1") {
        local NOTEsample " Sample selection: `if'"
    }
    if "`in'" !="" {
        if ("`NOTEsample'"=="") local NOTEsample " Sample selection `in'"
        else local NOTEsample "`NOTEsample' `in'"
    }

    if ("`trim'"=="") local trim = 0
    if (`trim'!=0) local NOTEtrim "Range trimmed by `trim' percent."
    else local NOTEtrim ""

    * _mchange label delta
    if `delta' != 0 {
        local isdelta = 1
        local LBLstddev "delta"
        local NOTEdelta "Delta equals `delta'."
    }
    else {
        local isdelta = 0
        local NOTEdelta ""
        local LBLstddev "SD"
    }

//  labels

    if "`uncentered'"=="uncentered" {
        local LBLcntr "unctr"
        * not used: local LBLcntrabbrev "unc"
        return local centering "uncentered"
        local LBLcntr "" // 3.0.0
        local LBLspc ""
    }
    else {
        local LBLcntr "cntr"
        * not used: local LBLcntrabbrev "ctr"
        return local centering "centered"
        local LBLcntr "centered" // 3.0.0
        local LBLspc "_"
    }

    local LBLbin "0_to_1"
    local LBLone "+1`LBLspc'`LBLcntr'"
    local LBLsd "+`LBLstddev'`LBLspc'`LBLcntr'"
    local LBLmarg "Marginal"
    local trimto = 100 - `trim'
    if (`trim'==0) local LBLrng "Range"
    else local LBLrng "`trim'%_to_`trimto'%"

    local LBLchange `"Change"'
    local LBLul `"UL"'
    local LBLll `"LL"'
    local LBLz `"z-value"'
    local LBLse `"Std Err"'
    local LBLpvalue `"p-value"' // P>|z| prints with extra space?!
    local LBLstart `"From"'
    local LBLend `"To"'

    * location in collection matrix
    local ROWchange = 1
    local ROWse = 2
    local ROWz = 3
    local ROWpvalue = 4
    local ROWll = 5
    local ROWul = 6
    local ROWstart = 7
    local ROWend = 8
    local nstattypes = 8

//  margins at 1st outcome: r(at), labels, baseline

    qui `noisily' di "predicttest for labels and at: `predicttest'"
    qui `VERSION' ///
        margins `if' `in', at(`ATbase') `atmeans' `options' `predictfirst'
    local nobsifin = r(N)
    local pr1base = el(r(b),1,1) // used for base predictions
    local lvlis = r(level)
    local NOTEci ""
    if `isci' local NOTEci "`lvlis' percent confidence interval."

    capture matrix list r(at)
    if _rc==0 { // r(at) exists
        if rowsof(r(at))>1 {
            display as error ///
"only one value of variable allowed in at(); e.g., at(male=(0 1)) is invalid"
            exit
        }
        quietly mlistat, saveconstant(`ATmatconstant')
        local ATmatconstantis = `s(isconstant)' // at matrix fixed values
        if `ATmatconstantis'==1 {
            matrix rowna `ATmatconstant' = "at"
            return matrix atconstant = `ATmatconstant', copy
        }
    }
    matrix `ATmat' = r(at)
    local ATnms : colnames `ATmat'

    _rm_margins_names
    if `singlecolnum'>0 | `outcomesN'==1 {
        * if single, use number in name
        local marginstitle "`s(marginstitlenum)'" // if single, use #
        local estname `"`s(estlblnum)'"'
    }
    if `singlecolnum'==0 | `outcomesN'>1 {
        * if multiple, generic name without number
        local marginstitle "`s(marginstitlenonum)'"
        local estname `"`s(estlblnonum)'"'
    }

// predictions at baseline values

    local atsingle "Prediction at base value"
    local atplural "Predictions at base value"
    local ofsingle "Average prediction"
    local ofplural "Average predictions"

    capture drop matrix `predbasemat'
    local basecatnames ""
    if ("`atmeans'"=="atmeans") local baseheader "`atplural'"
    else local baseheader "`ofplural'"

    if `MDLbrm' { // use predictions already made
        local pr0base = 1 - `pr1base'
        matrix `predbasemat' = `pr0base', `pr1base'
        matrix rowna `predbasemat' = `""Pr(y|base)""'
        matrix colna `predbasemat' = `lhscatnms'
    }

    else if `MDLcrmmu' & "`outcomes'"=="" { // uses rate already computed
        if ("`atmeans'"=="atmeans") local baseheader "`atsingle'"
        else local baseheader "`ofsingle'"
        matrix `predbasemat' = `pr1base'
        matrix rowna `predbasemat' = "Rate"
        local basecatnames "nonames"
    }

    else if `MDLother' { // refine as other models used
        if ("`atmeans'"=="atmeans") local baseheader "`atsingle'"
        else local baseheader "`ofsingle'"
        matrix `predbasemat' = `pr1base'
        matrix rowna `predbasemat' = `""`estname""'
        local basecatnames "nonames"
    }

    else { // not binary, count rate, or other
        if !`MDLcrmpr' { // count models allow all values
            local nodif : list outcomes in lhscatvals
            if `nodif'==0 {
                di as error "outcomes `outcomes' are not values of `lhsnm'"
                exit
            }
        }
        foreach catval in `lhscatvals' {
            local predictnow : subinstr local predictform "XX" "`catval'"
            qui `VERSION' ///
                margins `if' `in', at(`ATbase') `atmeans' `options' ///
                `predictnow'
            local pval = el(r(b),1,1)
            matrix `predbasemat' = nullmat(`predbasemat') , `pval'
        }
        matrix rowna `predbasemat' = `""Pr(y|base)""'
        matrix colna `predbasemat' = `lhscatnms'
    } // multiple categories

//  compute effects

    * blank matrix for 1 variable or 1 contrast
    matrix `blankmat' = J(8,`lhscatsN',.z) // 8 stats by # outcomes
    matrix colna `blankmat' = `lhscatnms'
    matrix rowna `blankmat' = `STATall'

    * drop variable if no variation since pwcompare exits with error
    local newvarnms ""
    foreach varnm in `varnms' { // selected variables
        local ipos : list posof "`varnm'" in TYPEfac
        if (`ipos'>0) { // factor
            qui tab `varnm' `if' `in'
            if `r(r)'==1 ///
                di "`varnm' dropped since it has no variation in selected sample"
            else local newvarnms "`newvarnms'`varnm' "
        }
        else local newvarnms "`newvarnms'`varnm' "
    }
    local varnms `newvarnms'

    foreach varnm in `varnms' { // selected variables

        capture matrix drop `varmat'
        local ipos : list posof "`varnm'" in TYPEfac
        if (`ipos'>0) local type fac
        else local type var

        // compute from and to values for discrete changes

        if "`type'" == "var" {

            // descriptives

            if `issd' | `isone' | `isrng' {
                qui sum `varnm' `if' `in'
                local mn = r(mean)
                local sd = r(sd)
                if (`sd'==.) local sd = 0
                local min = r(min)
                local max = r(max)
                if `is_svy' {
                    capture svy : mean  `varnm' `if' `in'
                    if _rc!= 0 {
                        display as error ///
             "cannot compute std dev for factor variables with svy data"
                        exit
                        continue
                    }
                    qui estat sd
                    local mn = el(r(mean),1,1)
                    local sd = el(r(sd),1,1)
                    qui estimates restore _mc_model

                }
                if (`delta'!=0) local sd = `delta'
                local sd2 = `sd'/2
            }
            else { // dummy values if only marg computed
                local sd = 0
                local sd2 = 0
            }

            // atspecs for all amounts of changes

            * at value needed for one sd amounts
            local ipos : list posof "`varnm'" in ATnms
            local ATval = `ATmat'[1,`ipos']
            if (!missing(`ATval')) local ATvarisset = 1
            else local ATvarisset = 0

            * note: start value entered 1st; end value entered last.
            * If ATbase includes value of varnm, the first and last
            * predictions are used.

            local ATbin "at(`varnm'=0 `ATbase' `varnm'=1)"

            if `ATvarisset'==1 {
                if "`uncentered'"=="" {
                    local F1 = `ATval' - .5
                    local T1 = `ATval' + .5
                    local Fsd = `ATval' - `sd2'
                    local Tsd = `ATval' + `sd2'
                }
                else { // uncentered
                    local F1 = `ATval'
                    local T1 = `ATval' + 1
                    local Fsd = `ATval'
                    local Tsd = `ATval' + `sd'
                }
                local ATone "at(`varnm'=`F1' `ATbase' `varnm'=`T1')"
                local ATsd "at(`varnm'=`Fsd' `ATbase' `varnm'=`Tsd')"
            }

            if `ATvarisset'==0 {
                if "`uncentered'"=="" {
                    local vF1 "`varnm'=gen(`varnm'-.5)"
                    local vT1 "`varnm'=gen(`varnm'+.5)"
                    local vFsd "`varnm'=gen(`varnm'-`sd2')"
                    local vTsd "`varnm'=gen(`varnm'+`sd2')"
                }
                else { // uncentered
                    local vF1 "`varnm'=gen(`varnm')"
                    local vT1 "`varnm'=gen(`varnm'+1)"
                    local vFsd "`varnm'=gen(`varnm')"
                    local vTsd "`varnm'=gen(`varnm'+`sd')"
                }
                local ATone "at(`vF1' `ATbase') at(`ATbase' `vT1')"
                local ATsd "at(`vFsd' `ATbase') at(`ATbase' `vTsd')"
                if `pre13' {
                    local ATone "pre13"
                    local ATsd "pre13"
                }
            }

            if `trim'!=0 {
                local trimUB = 100 - `trim'
                qui centile `varnm' `if' `in', centile(`trim' `trimUB')
                local F = r(c_1)
                local T = r(c_2)
            }
            else {
                qui sum `varnm' `if' `in'
                local F = r(min)
                local T = r(max)
            }
            local ATrng "at(`varnm'=`F' `ATbase' `varnm'=`T')"

            // compute predictions

            foreach amt in `AMTcont' {

                matrix `amtmat' = `blankmat'
                * build row label=> varnm:A<amt>C<ctr>S<stat>
                local ipos : list posof "`amt'" in AMTall
                local ais : word `ipos' of `AMTabbrev'
                if ("`ais'"=="sd" & `isdelta') local ais delta
                local rn "`varnm':`ais'_"
                matrix rowna `amtmat' = `rn'change `rn'se `rn'z ///
                    `rn'pvalue `rn'll `rn'ul `rn'start `rn'end

                if "`amt'"=="marg" {
                    local outcol = 0 // outcome column
                    foreach catval in `lhscatvals' { // outcome value
                        local ++outcol
                        local optpred ""
                        *if (`MDLbrm') local outcol = 2 // pr(1) in 2
                        else if (`MDLcrmmu') local outcol = 1 // mu in 1
                        else if (`MDLother' & `lhscatsN'==1) local outcol = 1

                        local predictnow : ///
                            subinstr local predictform "XX" "`catval'"
                        if `MDLbrm' {
                            if `catval'==0 {
                                local outcol = 1
                                local predictnow = "exp(1-`predictform')"
                            }
                            else local outcol = 2
                        }
                        local cmdis "margins `if' `in', dydx(`varnm')"
                        local cmdis "`cmdis' at(`ATbase') `atmeans'"
                        local cmdis "`cmdis' `predictnow' `options'"
                        _rm_margins_clean_cmd `cmdis'
                        local cmdis "`s(cmd)'"
                        `quicmd' display "Command: `cmdis'"
                        `quimar' `VERSION' `cmdis'
                        mat `amtmat'[`locb',`outcol'] = el(r(table),1,1)
                        mat `amtmat'[`locse',`outcol'] = el(r(table),2,1)
                        mat `amtmat'[`locz',`outcol'] = el(r(table),3,1)
                        mat `amtmat'[`locp',`outcol'] = el(r(table),4,1)
                        mat `amtmat'[`loclb',`outcol'] = el(r(table),5,1)
                        mat `amtmat'[`locub',`outcol'] = el(r(table),6,1)
                    } // catval
                    matrix `varmat' = nullmat(`varmat') \ `amtmat'

                } // marg

                else { // dc

                    local outcol = 0 // outcome column
                    foreach catval in `lhscatvals' {
                        local ++outcol
                        local optpred ""
                        if (`MDLbrm') local outcol = 2
                        else if (`MDLcrmmu') local outcol = 1
                        else if (`MDLother' & `lhscatsN'==1) local outcol = 1

                        local predictnow : ///
                        subinstr local predictform "XX" "`catval'"
                        if `MDLbrm' {
                            if `catval'==0 {
                                local outcol = 1
                                local predictnow = "exp(1-`predictform')"
                            }
                            else local outcol = 2
                        }
                        local cmdis "margins `if' `in', `AT`amt'' post"
                        local cmdis "`cmdis' `atmeans' `predictnow' `options'"
                        _rm_margins_clean_cmd `cmdis'
                        local cmdis "`s(cmd)'"

                        if "`AT`amt''"=="pre13" {
                            local NOTEpre13 ///
                            ".m indicates effects requires Stata 13 or later."
                            mat `amtmat'[1,`outcol'] = J(8,1,.m)
                        }
                        else {
                            `quicmd' display "Command: `cmdis'"
                            `quimar' `VERSION' `cmdis'
                            local nat = colsof(r(b))
                            local locT = `nat'
                            `quicmd' display "Command: mlincom `locT' - 1"
                            `quimar' mlincom `locT' - 1
                            mat `amtmat'[`locb',`outcol'] = r(est)
                            mat `amtmat'[`locse',`outcol'] = r(se)
                            mat `amtmat'[`locz',`outcol'] = r(z)
                            mat `amtmat'[`locp',`outcol'] = r(p)
                            mat `amtmat'[`loclb',`outcol'] = r(lb)
                            mat `amtmat'[`locub',`outcol'] = r(ub)
                            mat `amtmat'[`locst',`outcol'] = el(e(b),1,1)
                            mat `amtmat'[`locen',`outcol'] = el(e(b),1,`locT')
                            qui estimates restore _mc_model
                        }
                    } // outcome

                    matrix `varmat' = nullmat(`varmat') \ `amtmat'

                } // dc

            } // amt

            matrix `allchanges' = nullmat(`allchanges') \ `varmat'

        } // type var

        // factor variables

        else if "`type'" == "fac" {

            qui tab `varnm' `if' `in'
            local ncat = r(r)
            local tmpnpw = ((`ncat'*`ncat')-`ncat')/2
            forvalues i = 1/`tmpnpw' {
                tempname pwmat`i'
            }
            local outcol = 0 // outcome column
            foreach catval in `lhscatvals' { // outcome value
                local ++outcol
                local optpred ""
                if (`MDLbrm') local outcol = 2
                else if (`MDLcrmmu') local outcol = 1
                else if (`MDLother' & `lhscatsN'==1) local outcol = 1
                if `MDLbrm' {
                    if `catval'==0 {
                        local outcol = 1
                        local predictnow = "exp(1-`predictform')"
                    }
                    else local outcol = 2
                }
                local predictnow : subinstr local predictform "XX" "`catval'"
                local cmdis "margins `varnm' `if' `in', at(`ATbase')"
                local cmdis "`cmdis' `atmeans' `options' pwcompare `predictnow'"

                `quicmd' display "Command: `cmdis'"
                `quimar' `VERSION' `cmdis'

                matrix `pwmatall' = r(table_vs) // pw contrasts
                local npw = colsof(`pwmatall')
                local npw`varnm' = `npw'
                local pwcolnms : colnames(`pwmatall')

                matrix `prmat' = r(table) // outcome probabiliteis
                local npr = colsof(`prmat')
                local prcolnms : colnames(`prmat')
                * remove all but numbers from column names
                local prcolnums : subinstr local prcolnms ".`varnm'" "", all
                local prcolnums : subinstr local prcolnums "bn" "", all

                forvalues ipw = 1/`npw' {

                    * #'s for contrasts
                    local pwnm : word `ipw' of `pwcolnms'
                    local pwnum : subinstr local pwnm ".`varnm'" "", all
                    local pwnum : subinstr local pwnum "vs" " ", all
                    local pwnum : subinstr local pwnum "bn" "", all

                    * locations in prmat for start & end pred
                    local pwstval : word 2 of `pwnum'
                    local pwstcol : list posof "`pwstval'" in prcolnums
                    local pwenval : word 1 of `pwnum'
                    local pwencol : list posof "`pwenval'" in prcolnums

                    * matrix for pw comparison #ipw
                    capture confirm matrix `pwmat`ipw''
                    if _rc!=0 { // doesn't exist so create
                        * rowname: var1!2vs3:bin_...
                        * THIS FORMAT REQUIRED BY _rm_get_mchange.ado
                        local rn "`varnm'!`pwenval'vs`pwstval':bin_"
                        mat `pwmat`ipw'' = `blankmat'
                        matrix rowna `pwmat`ipw'' = `rn'change `rn'se ///
                            `rn'z `rn'pvalue `rn'll `rn'ul `rn'start `rn'end
                    }
                    mat `pwmat`ipw''[`locst',`outcol'] = `prmat'[1,`pwstcol']
                    mat `pwmat`ipw''[`locen',`outcol'] = `prmat'[1,`pwencol']
                    mat `pwmat`ipw''[`locb',`outcol']  = `pwmatall'[`locb',`ipw']
                    mat `pwmat`ipw''[`locse',`outcol'] = `pwmatall'[`locse',`ipw']
                    mat `pwmat`ipw''[`locz',`outcol']  = `pwmatall'[`locz',`ipw']
                    mat `pwmat`ipw''[`locp',`outcol']  = `pwmatall'[`locp',`ipw']
                    mat `pwmat`ipw''[`loclb',`outcol'] = `pwmatall'[`loclb',`ipw']
                    mat `pwmat`ipw''[`locub',`outcol'] = `pwmatall'[`locub',`ipw']

                } // ipw loop

            } // outcome

            forvalues ipw = 1/`npw' { // results for all contrasts
                matrix `allchanges' = nullmat(`allchanges') \ `pwmat`ipw''
            }

        } // type fac

    } // varnm

    matrix _mchange = `allchanges'
    return matrix changes = `allchanges', copy

//  select results for printing

    capture matrix drop `prtmat'

    //  combine results into table

    if `issingle' {
        * columns are statistics
        local statcolnms ""
        foreach stat in `STATprt' {
            local statcolnms `"`statcolnms'`""`LBL`stat''""' "'
        }

        local rowst = -`nstattypes' // start location in `allchanges'
        foreach varnm in `varnms' {

            local ipos : list posof "`varnm'" in TYPEfac
            if (`ipos'>0) local type fac
            else local type var

            if "`type'"=="var" { // get dc and marg
                foreach amt in `AMTcont' {
                    local rowst = `rowst' + 8
                    local rownm "`varnm':`LBL`amt''"
                    capture matrix drop `prtvec'
                    foreach snm in `STATprt' {
                        local irow = `rowst' + `ROW`snm''
                        local stat = `allchanges'[`irow',`singlecolnum']
                        matrix `prtvec' = nullmat(`prtvec') , `stat'
                    }
                    matrix rowna `prtvec' = `rownm'
                    matrix colna `prtvec' = `statcolnms' // `"`statcolnms'"'
                    matrix `prtmat' = nullmat(`prtmat') \ `prtvec'
                } // amt
            } // type var

            else { // type fac get pw comparisons
                _rm_pwnames, var(`varnm') // names of pw comparisons
                forvalues ipw = 1/`npw`varnm'' { // # of pw comparisons
                    local rowst = `rowst' + `nstattypes'
                    capture matrix drop `prtvec'
                    foreach stat in `STATprt' {
                        local irow = `rowst' + `ROW`stat''
                        mat `tempvec' = `allchanges'[`irow',1...]
                        local stat = `allchanges'[`irow',`singlecolnum']
                        matrix `prtvec' = nullmat(`prtvec') , `stat'
                    }
                    local pwnum "`s(numlabel`ipw')'"
                    local pwlbl "`s(txtlabel`ipw')'" // txt vs txt
                    local pwlbl = abbrev("`pwlbl'",31)
                    local pwnmlen = length(`"`pwlbl'"') // for matlist
                    if (`pwnmlen'>=`twid') local twid = `pwnmlen' + 1
                    local rownm `"`varnm':`pwlbl'"'
                    matrix rowna `prtvec' = `"`rownm'"'
                    matrix colna `prtvec' = `statcolnms' // `"`statcolnms'"'
                    matrix `prtmat' = nullmat(`prtmat') \ `prtvec'
                } // pw comparison
            } // type fac
        } // varnm
    } // single column of output

    // multiple outcomes

    else {
        local prechgnms "" // names before (if any) change row
        local postchgnms "" // names after (if any) change row
        local ischgstat = 0
        foreach stat in `STATprt' {
            if "`stat'"=="change" local ischgstat = 1
            else if `ischgstat'==0 {
                local prechgnms `"`prechgnms'`""`LBL`stat''""' "'
            }
            else local postchgnms `"`postchgnms'`""`LBL`stat''""' "'
        }
        local rowst = -`nstattypes' // start location in `allchanges'
        foreach varnm in `varnms' {
            local ipos : list posof "`varnm'" in TYPEfac
            if (`ipos'>0) local type fac
            else local type var
            capture matrix drop `varmat'
            if "`type'"=="var" { // get dc and marg
                foreach amt in `AMTcont' {
                    local rowst = `rowst' + `nstattypes'
                    capture matrix drop `amtmat'
                    foreach snm in `STATprt' {
                        local irow = `rowst' + `ROW`snm''
                        matrix `prtvec' = `allchanges'[`irow',1...]
                        matrix `amtmat' = nullmat(`amtmat') \ `prtvec'
                    }
                    matrix roweq `amtmat' = `varnm'
                    matrix rowna `amtmat' ///
                        = `prechgnms' `"`LBL`amt''"' `postchgnms'
                    matrix `varmat' = nullmat(`varmat') \ `amtmat'
                } // amt
                qui `noisily' matlist `varmat', nohalf ///
                    format(%9.3f) title(varmat `varnm')
                matrix `prtmat' = nullmat(`prtmat') \ `varmat'
            } // type var

            else { // factor variables
                _rm_pwnames, var(`varnm') // names of pw comparisons
                forvalues ipw = 1/`npw`varnm'' { // # comparison
                    local rowst = `rowst' + `nstattypes'
                    capture matrix drop `pwmatall'
                    foreach snm in `STATprt' {
                        local irow = `rowst' + `ROW`snm''
                        matrix `prtvec' = `allchanges'[`irow',1...]
                        matrix `pwmatall' = nullmat(`pwmatall') \ `prtvec'
                    }
                    matrix roweq `pwmatall' = `varnm'
                    local pweqnm : roweq `prtvec' // varnm!contrastnm
                    local pwnmst = strpos("`pweqnm'","!") + 1
                    local pwnm = substr("`pweqnm'",`pwnmst',.)
                    local pwnum "`s(numlabel`ipw')'" // #vs#
                    local pwlbl "`s(txtlabel`ipw')'" // txt vs txt
                    local pwlbl = abbrev("`pwlbl'",31)
                    local pwnmlen = length(`"`pwlbl'"') // for matlist
                    if (`pwnmlen'>=`twid') local twid = `pwnmlen' + 1
                    local pwnm `""`pwlbl'""'
                    * pre & post allows stats in any order in output
                    matrix rowna `pwmatall' ///
                        = `prechgnms' `"`pwnm'"' `postchgnms'
                    matrix `varmat' = nullmat(`varmat') \ `pwmatall'
                } // pw contrast
                matrix `prtmat' = nullmat(`prtmat') \ `varmat'
                qui `noisily' matlist `varmat', ///
                    format(%9.3f) title(varmat `varnm') nohalf
            } // type fac
        } // varnm

    } // multiple categories

//  print results

    if ("`title'"=="") local titlenm "`MDLtitle': Changes in `estname'"
    else local titlenm "`title'"
    display _new as result "`titlenm' | Number of obs = `nobsifin'"
            *    display _new as text "Expression: `marginstitle'" _new
    display _new as text "Expression: `marginstitle'"

    * marginal effects
    matlist `prtmat', format(%`width'.`decimals'f) lines(oneline) nohalf ///
        underscore twidth(`twid') // title("{bf}`Slbl_`s''{sf}")
    return matrix table = `prtmat'

    * base predictions
    if "`brief'"=="" {
        matlist `predbasemat', noheader format(%`width'.`decimals'f) ///
            `basecatnames' title(`baseheader') nohalf
    }
    return matrix basepred = `predbasemat'

    * at values
    if "`ATmatconstantis'"=="1" & "`brief'"=="" {
        matlist `ATmatconstant', format(%`width'.`decimals'g) ///
            title(Base values of regressors) nohalf
    }

    * descriptives
    if "`descriptives'"=="descriptives" {

        * 3.0.2
        if "`e(prefix)'"!="svy" {
*                qui estat summarize
*                matrix `descstats' = r(stats)
                qui tabstat `varnms', statistics(mean sd min max) save
                mat `descstats' = r(StatTotal) '
                matrix colna `descstats' = Mean `""Std. Dev.""' Min Max
        }
        else {
            tempname esthold mstat
            qui {
                estimates store `esthold'
                svy: mean `varnms'
                estat sd
                mat `descstats' = r(mean) \ r(sd)
                tabstat `varnms', statistics(min max) save
                mat `descstats' = (`descstats' \ r(StatTotal)) '
                matrix colna `descstats' = Mean `""Std. Dev.""' Min Max
                estimates restore `esthold'
            }
        }

        display
        display "Descriptive statistics for estimation sample"
        display
        local fmt "%`width'.`decimals'f"
        _matrix_table `descstats', format(`fmt' `fmt' `fmt' `fmt')
        return matrix stats = `descstats'
        if `lhscatsN'>2 tab `lhsnm' if e(sample)
    }

    * notes
    if  "`brief'"=="" {
        display
        local i = 1
        if "`atmeans'"=="atmeans" {
            display _col(1) "`i': Estimates with margins option atmeans."
            local ++i
        }
        if "`NOTEsample'"!="" {
            display _col(1) "`i':`NOTEsample'"
            local ++i
        }
        if "`NOTEdelta'"!="" {
            display _col(1) "`i': `NOTEdelta'"
            local ++i
        }
        if "`NOTEci'"!="" {
            display _col(1) "`i': `NOTEci'"
            local ++i
        }
        if "`NOTEpre13'"!="" {
            display _col(1) "`i': `NOTEpre13'"
            local ++i
        }
    } // brief

end

program define parse_amt, sclass
    syntax , [ Binary  Marginal dydx PARTial  One 1  Range rng  Sd * ]

    if "`dydx'"!="" | "`partial'"!=""   local marginal marginal
    if "`1'"!=""                        local one one
    if "`rng'"!=""                      local range rng
    if "`range'"!=""                    local range rng
    if "`binary'"!="" local binary bin
    if "`marginal'"!="" local marginal "marg"
    local amt = trim("`binary' `marginal' `one' `range' `sd'")
    local isbad = wordcount("`stat'")>1
    if "`options'"!="" {
        local isbad = 1
        local amt "`options'"
    }
    sreturn local amount "`amt'"
    sreturn local isbad "`isbad'"
end

program define parse_stat, sclass
    syntax , [ ESTimate CHange dydx coef  Se STDerr  Pvalue  Zvalue TValue ///
        Ub ul UPper  Lb ll LOwer  STart from  ENd to * ]

    if "`coef'"!=""                 local estimate estimate
    if "`dydx'"!=""                 local estimate estimate
    if "`change'"!=""               local estimate estimate
    if "`stderr'"!=""               local se se
    if "`tvalue'"!=""               local zvalue zvalue
    if "`ub'"!="" | "`upper'"!=""   local ul ul
    if "`lb'"!="" | "`lower'"!=""   local ll ll
    if "`from'"!=""                 local start start
    if "`to'"!=""                   local end end
    if "`zvalue'"!="" local zvalue "z"
    if "`estimate'"!="" local estimate change
    local stat ///
        = trim("`estimate' `se' `pvalue' `zvalue' `ul' `ll' `start' `end'")
    local isbad = wordcount("`stat'")>1
    if "`options'"!="" {
        local isbad = 1
        local stat "`options'"
    }
    sreturn local stat "`stat'"
    sreturn local isbad "`isbad'"
end
exit

NOTES

2014-05-30 Should we compute pr(0,m)?
2014-05-30 Add average change

* version 2.1.4 2014-05-30 | long freese | sd = . made 0; skip fv if range 0
* version 2.1.3 2014-05-30 | long freese | _caller()
* version 2.1.2 2014-05-16 | long freese | trap no ecommand
* version 2.1.1 2014-05-05 | long freese | trap over
* version 2.1.0 2014-02-15 | long freese | spost13 release
