*! 0.9.3e 2013-07-09\11 | long freese | outcome() bug again removing Mpredict
*! 0.9.3d 2013-07-09\11 | long freese | drop this version
*! 0.9.3b 2013-07-09\11 | long freese | outcome() bug
* 0.9.2 2013-07-06 | long freese | uses margins, gen in stata 13 even if
*   version control is stata < 13
* 0.9.1 2013-07-03 | long freese | pass Mpredict to predict in stata <13

//  discrete change using margins

* TODO: compute sd if svy if survey variables

* TODO: generalize for any predict() as was done with count?
* TODO1: add outcomes() to specify outcomes to use
* TODO2: average discrete change when categorical
* TODO3: test marginsoptions(); do it with *?
* TODO5: check _mchange_plot_dc for contrast variables
* TODO7: contrasts with only base category
* TODO9: Note a#b not allowed if a!=b

capture program drop xmchange
capture program drop parse_amt
capture program drop parse_stat
program define xmchange, rclass

    version 11.2
    syntax [varlist(default=none fv)] [if] [in] ,  ///
        [                               ///
        MATrix(string) /// name for saving r(table)
        AMount(string) AMOUNTBinary(string) ///
            /// range binary one sd marginal all
        BYSTATistics /// show results in one stat per table
        ATMEANs /// use atmean option for margins
        DECimals(numlist >-1 integer) /// # in output
        DESCriptives /// descriptive statistics
        /// MARGINSoptions(string asis) /// passthrough to margins
        OUTcome(string) /// user can specify outcomes TO BE ADDED
        STATS(string asis) /// synonym for statistics
        STATistics(string asis) /// change ul ll z se p start end
        UNCENtered /// uncentered change
        DETails /// list margins output
        at(string) /// added to end of at()
        brief ///
        delta(real 0) /// delta change instead of sd change
        replace /// replace matrix
        title(string) /// matrix title
        trim(numlist >-1 integer) /// percent to trim from min max
        * ///
        ]

    tempname blankmatrix b se z pvalue ll ul lvl start end atmat mat
    tempname v outmat1var tmp outmatall atmat pbase varinfo iscat betainfo
    tempname atVary atCons atVary2 atCons2 atVary1 atCons1
    tempname tabdc tabend tabstart tabse tabz tabpvalue tabul tabll
    tempname vecis mattab change outmat1varR vecatdesc matatdesc matpw selmat
    local error = 0 // 0824

    if "`e(cmd)'"=="" | "`e(cmd)'"=="margins" {
        display as error "no estimation command is in memory"
        exit
    }
    estimates store _mchange_model // last model estiamted

    local dropmat = 1 // change to 0 to keep working matrices in memory
    local dopreserve "no"
    local matstub "_mtemp"
    local S_all "change pvalue ul ll z se start end"

	* define macro pre13 to indicate whether version before stata 13 being used
	local pre13 "yes"
	if _caller()>=13 {
		local pre13 "no"
	}
	cap if c(stata_version)>=13 {
		local pre13 "no"
	}

    * prevents duplication of effects when mchange i.k5 is entered
    local varlist : subinstr local varlist "i." "", all // 0826
    * syntax converts 2.cat 3.cat etc to i(2 3 etc).cat; this unexpands it
    fvexpand `varlist'
    local varlist `r(varlist)'
    local varlist : subinstr local varlist "b." ".", all

//  synonyms

    local amount : subinstr local amount "delta" "sd", all
    local amountbin "`amountbinary'" // shorten name
    if ("`amount'"=="all") local amount "rng bin one sd marg"
    if ("`stats'"!="" & "`statistics'"=="") local statistics "`stats'"
    if ("`statistics'"=="ci") local statistics "change ll ul"
    if "`statistics'"=="all" {
        local statistics "change ul ll z se pvalue start end"
    }

//  evaluate amount and stat abbreviations

    * amounts for continuous variables
    local isbad = 0
    if "`amount'"!="" {
        local new ""
        foreach opt in `amount' {
            parse_amt `opt'
            local newopt
            local amt "`s(amount)'"
            local new "`new'`amt' "
            if "`s(isbad)'"=="1" {
                display as error "invalid amount specified: `opt'"
                local isbad = 1
                exit
            }
        }
        local amount "`new'"
    }

    * amount for binary variables
    if "`amountbin'"!="" {
        local new ""
        foreach opt in `amountbin' {
            parse_amt `opt'
            local newopt
            local amt "`s(amount)'"
            local new "`new'`amt' "
            if "`s(isbad)'"=="1" {
                display as error "invalid amount specified: `opt'"
                local isbad = 1
                exit
            }
        }
        local amountbin "`new'"
    }

    * selected statistics
    if "`statistics'"!="" {
        local new ""
        foreach opt in `statistics' {
            parse_stat `opt'
            local newopt
            local stat "`s(stat)'"
            local new "`new'`stat' "
            if "`s(isbad)'"=="1" {
                display as error "invalid statistic specified: `opt'"
                local isbad = 1
                exit
            }
        }
        local statistics "`new'"
    }
    if ("`isbad'"=="1") exit

//  information about estimation command and type of predictor variables

    _rm_modelinfo
    * command and lhs information
    local cmdnm "`r(cmdnm)'"
    local cmdttl "`cmdnm'"
    local cmdsvy = `r(cmdsvy)'
    if (`cmdsvy') local cmdttl "svy `cmdttl'"
    local cmdbin = `r(cmdbin)'
    local lhsncats = `r(lhscatn)'
    local lhsnm "`r(lhsnm)'"
    local lhscatnms "`r(lhscatnms)'"
    local cmdcrm = `r(cmdcrm)' // count model
    if ("`cmdcrm'"=="1") local lhsncats = 1
    if ("`cmdcrm'"=="1") local lhscatnms "Rate"
    local lhscatvals "`r(lhscatvals)'"

    * regressor information
    matrix `varinfo' = r(varinfo)
    matrix `betainfo' = r(betainfo)
    local varinfonms : colnames `varinfo'
    local betainfonms : colnames `betainfo'
    * varnms correspond to expanded factor names (e.g., 1.hc)
    local varnms "`r(rhsnms)'"
    * change 1.x to i1.x which margins doesn't like...
    forvalues i = 0(1)9 {
        local varlist : subinstr local varlist "i`i'." "`i'.", all
    }
    if ("`varlist'"!="") local varnms "`varlist'"
    local nvarnms = wordcount("`varnms'")

//  decode options and create footnotes

    local qui "quietly"
    if ("`details'"=="details") local qui "noisily"
    * local if includes esample and any if used in mchange command
    if ("`if'"=="") local if "if e(sample)==1"
    else local if "`if' & e(sample)==1"

    local samplenote ""
    if "`if'"!="" & "`if'"!="if e(sample)==1" {
        local samplenote " Sample selection: `if'"
    }
    if "`in'" !="" {
        if ("`samplenote'"=="") local samplenote " Sample selection `in'"
        else local samplenote "`samplenote' `in'"
    }

    if ("`trim'"=="") local trim = 0
    if (`trim'==0) local trimnote "Range computed without trimming."
    if (`trim'!=0) local trimnote "Range trimmed by `trim' percent."

    local deltanote ""
    if (`delta'!=0) local deltanote "Delta equals `delta'."

    if ("`decimals'"=="") local decimals = 4 // to match pr commands

    if ("`uncentered'"=="uncentered") local cntr_nm "unctr"
    else local cntr_nm "cntr"

    if (`delta'!=0) local sd_nm "delta"
    else local sd_nm "SD"

//  amounts and their labels

    * amount labels for output
    local Clbl_bin "0_to_1"
    local Clbl_one "+1_`cntr_nm'"
    local Clbl_sd "+`sd_nm'_`cntr_nm'"
    local Clbl_marg "Marginal"
    local trimto = 100 - `trim'
    if (`trim'==0) local Clbl_rng "Range"
    else local Clbl_rng "`trim'%_to_`trimto'%" // 0.8.12 .14

    * amount sets
    local Cset_all "bin one sd rng marg" // all types in print order
    local Cset_dc  "bin one sd rng" // all dc types
    local Cset_bin "bin" // default for binary
    if ("`amountbin'"!="") local Cset_bin "`amountbin'"
    local Cset_con "one sd marg" // default for continuous
    if ("`amount'"!="") local Cset_con "`amount'"
    local Cshow_bin "`Cset_bin'"
    local Cshow_con "`Cset_con'"
    local ipos : list posof "rng" in Cshow_con
    local C_isrng = `ipos'>0
    local Cshow_binNOdy = subinword("`Cshow_bin'", "marg", "", .)
    local Cshow_conNOdy = subinword("`Cshow_con'", "marg", "", .)

    * atgen: pre stata 13 can't compute AME of -+1 or -+sd
    * Stata 11 used counterfactual variables. Need to restore dataset.
    foreach chng in `Cshow_con' {
        if ("`chng'"=="one" | "`chng'"=="sd" ) /// only needed for +1 or +sd
         & ("`atmeans'"!="atmeans") /// not needed with atmeans
         & ("`pre13'"=="yes") { // no need in Stata 13
            local dopreserve "yes"
        }
    }
    * amount matrix row offsets for specific amounts
    local Cmat_order "rng bin one sd marg" // row order in matrix
    local mat_off_rng  = 1
    local mat_off_bin  = 2
    local mat_off_one  = 3
    local mat_off_sd   = 4
    local mat_off_marg = 5

    * amount matrix row names in order defined above
    local C_rownms `""`Clbl_rng'" "`Clbl_bin'""'
    local C_rownms `"`C_rownms' "`Clbl_one'" "`Clbl_sd'" "`Clbl_marg'""'
    * _ for space in labels
    local C_rownms_ : subinstr local C_rownms " " "_", all
    local C_rownms_ : subinstr local C_rownms_ `"_""' `" ""', all
    local C_rownms_ : subinstr local C_rownms_ `""_"' `"" "', all

    * for use with range
    local C_rownmsR `""Range" "`Clbl_bin'""'
    local C_rownmsR `"`C_rownmsR' "`Clbl_one'" "`Clbl_sd'" "`Clbl_marg'""'
    local C_rownmsR_ : subinstr local C_rownmsR " " "_", all
    local C_rownmsR_ : subinstr local C_rownmsR_ `"_""' `" ""', all
    local C_rownmsR_ : subinstr local C_rownmsR_ `""_"' `"" "', all

    * offsets for printing each type of change
    local irowbin = 0
    local irowcon = 0
    foreach chng in `Cmat_order' {
        local ipos : list posof "`chng'" in Cshow_bin
        if `ipos'>0 {
            local ++irowbin
            local prtbin_off_`chng' = `irowbin'
        }
        else local prtbin_off_`chng' = 0
        local ipos : list posof "`chng'" in Cshow_con
        if `ipos'>0 {
            local ++irowcon
            local prtcon_off_`chng' = `irowcon'
        }
        else local prtcon_off_`chng' = 0
    }

//  classify beta estimates based on type of variable
//    : i.catvar handled with margins, pwcompare
//    : a#b only processed if it is quadratic

    local badnms ""
    local isbad = 0
    local newvarnms ""
    foreach varnm in `varnms' {
        local ipos : list posof "`varnm'" in betainfonms
        if `ipos'==0 { // not in list of beta names
            local badnms "`badnms'`varnm' "
            local isbad = `isbad' + 1 // 0.8.23
            * add 1. to name and check again
            local tmpnm "1.`varnm'"  // 0.8.23
            local ipos : list posof "`tmpnm'" in betainfonms  // 0.8.23
            if `ipos'!=0 {  // 0.8.23
                * found variable, so one less error
                local isbad = `isbad' - 1
                local varnm "`tmpnm'"
            }
            * did not find 1.var, check 2.
            else { // 0.8.24
                local tmpnm "2.`varnm'"  // 0.8.24
                local ipos : list posof "`tmpnm'" in betainfonms
                if `ipos'!=0 {
                    * found variable, so one less error
                    local isbad = `isbad' - 1
                    local varnm "`tmpnm'"
                }
                else { // try 3.
                    local tmpnm "3.`varnm'"  // 0.8.24
                    local ipos : list posof "`tmpnm'" in betainfonms
                    if `ipos'!=0 {
                        * found variable, so one less error
                        local isbad = `isbad' - 1
                        local varnm "`tmpnm'"
                    }
                }
            }
        } // in list of beta names
        local newvarnms "`newvarnms'`varnm' "  // 0.8.23
    } // foreach varnm
    if `isbad'==1 {
        display as error "`badnms' not in model"
        exit
    }
    local varnms "`newvarnms'"  // 0.8.23

    * types of regressors that determine how changes are computed
    local binvarlist ""         // i.binvar names
    local catvarlist ""         // i.catvar names
    local intanylist ""         // a#b
    local intdroplist ""        // drop a#b if a!=b
    local intquadcorelist ""    //
    local intquadbetalist ""    //
    foreach varnm in `varnms' {
        local nm : subinstr local varnm "." "_", all
        local nm : subinstr local nm "#" "_", all
        local is`nm'bin = 0 // i.binvar
        local is`nm'cat = 0 // i.catvar
        local is`nm'intany = 0 // any a#b
        local is`nm'intdrop = 0 // a#b where a!=b
        local is`nm'intquad = 0 // a#b where a==b and never a!=b (quadratic)
        local ipos : list posof "`varnm'" in betainfonms
        if `ipos'>0 {
            * i.binary
            local Bisbin = `betainfo'[1,`ipos']
            if `Bisbin'==1 {
                local is`nm'bin = 1
                local binvarlist "`binvarlist'`varnm' "
            }
            * i.categorical
            local Biscat = `betainfo'[2,`ipos']
            if `Biscat'==1 {
                local is`nm'cat = 1
                _ms_parse_parts `varnm'
                local catvarlist "`catvarlist'`r(name)' "
            }
            * any interaction
            local Bisintany = `betainfo'[7,`ipos']
            if `Bisintany'==1 {
                local is`nm'intany = 1
                _ms_parse_parts `varnm'
                local intanylist "`intanylist'`r(name)' "
            }
            * interaction only as quadratic
            local Bintquad = `betainfo'[9,`ipos']
            if `Bintquad'==1 {
                local is`nm'intquad = 1
                _ms_parse_parts `varnm'
                local intquadcorelist "`intquadcorelist'`r(name)' `r(name1)'"
                local intquadbetalist "`intquadbetalist'`varnm' "
            }
            * interaction other than quadratic; drop this later
            local Bintdrop = `betainfo'[10,`ipos']
            if `Bintdrop'==1 {
                local is`nm'intdrop = 1
                _ms_parse_parts `varnm'
                local intdroplist "`intdroplist'`r(name)' "
            }
            * see insert A for test code
        }
        local intquadcorelist : list uniq intquadcorelist
    } // var loop

    if "`intdroplist'"!="" {
        local intdropnote "These variables not included because of interactions:"
        local intdropnote2 "  : `intdroplist'"
    }
    * see insert B for test code

if "$test"=="1" {
    display "binvarlist      :  `binvarlist'"
    display "catvarlist      :  `catvarlist'"
    display "intanylist      :  `intanylist'"
    display "intdroplist     :  `intdroplist'"
    display "intquadcorelist :  `intquadcorelist'"
    display "intquadbetalist :  `intquadbetalist'"
}

//  redefine varnms for later processing

    local varnmsmain "" // standard processing
    local betanmscat "" // process with margins, pwcompare
    local varnmscat  "" // process with margins, pwcompare
    local varnmsdrop "" // not processed by mchange
    local varnmsquad ""    // quad terms where only src var kept
    local varnmsquadsrc "" // source vars for quad terms
    foreach varnm in `varnms' { // these names from e(b) columns
        local nm : subinstr local varnm "." "_", all
        local nm : subinstr local nm "#" "_", all
        * is it i.catvar?
        if `is`nm'cat' == 1 {
            local betanmscat "`betanmscat'`varnm' "
            _ms_parse_parts `varnm'
            local varnmscat "`varnmscat'`r(name)' "
        }
        * is it #quadratic
        else if `is`nm'intquad' == 1 {
            _ms_parse_parts `varnm'
            * keep only source variable
            local varnmsmain "`varnmsmain'`r(name1)' "
            local varnmsquadsrc "`varnmsquadsrc'`r(name1)' "
            local varnmsquad "`varnmsquad'`varnm' "
        }
        * other interactions are dropped
        else if (`is`nm'intdrop'==1) local varnmsdrop "`varnmsdrop'`varnm' "
        * keep rest
        else local varnmsmain "`varnmsmain'`varnm' "
    }
    local varnmsmain : list uniq varnmsmain
    local varnmsquadsrc : list uniq varnmsquadsrc
    local varnmscat : list uniq varnmscat
    if "`varnmsquadsrc'"!="" {
        local n = wordcount("`varnmsquadsrc'")
        if `n'==1 {
            local quadnote ///
            "Variable `varnmsquadsrc' has quadratic terms in model."
        }
        else {
            local quadnote ///
            "Variables `varnmsquadsrc' have quadratic terms in model."
        }
    }
    * insert C: see test code at end
    if ("`varnmsmain'"=="") local nomainvars = 1
    else local nomainvars = 0
    if ("`varnmsmain'"!="") local mainvars = 1
    else local mainvars = 0


if "$test"=="1" {
    display "varnmsmain     `varnmsmain'"
    display "betanmscat     `betanmscat'"
    display "varnmscat      `varnmscat'"
    display "varnmsdrop     `varnmsdrop'"
    display "varnmsquad     `varnmsquad'"
    display "varnmsquadsrc  `varnmsquadsrc'"
}

//  assign locations in output and matrix

    local ivar = 0
    local iprtrow = 0
    foreach varnm in `varnmsmain' {
        local ++ivar
        local varn_ : subinstr local varnm "." "_", all // remove . from name
        local varn_ : subinstr local varn_ "#" "_", all // remove #. from name
        * use entire sample to determine if binary
        capture assert `varnm'==0 | `varnm'==1 | `varnm'==.
        local isbin_`varn_' = (_rc==0) // is a binary regressor
        * start location for each type of change
        local varstart = (`ivar'-1)*5 // 5 types of changes
        foreach chng in `Cset_all' {
            *     mat_<chng>_<var> : output mat row# for chng+var pair
            local mat_`chng'_`varn_' = `varstart' + `mat_off_`chng''
        }
        foreach chng in `Cset_all' {
            * locations for binary variables
            if `isbin_`varn_''==1 {
                local ipos : list posof "`chng'" in Cshow_bin
                if `ipos'>0 {
                    local ++iprtrow
                    * prt_<chng>_<var> : print row# for chng+var pair
                    local prt_`chng'_`varn_' = `iprtrow'
                }
                else local prt_`chng'_`varn_' = 0
            }
            * locations for continuous variales
            else {
                local ipos : list posof "`chng'" in Cshow_con
                if `ipos'>0 {
                    local ++iprtrow
                    local prt_`chng'_`varn_' = `iprtrow'
                }
                else local prt_`chng'_`varn_' = 0
            }
            *noi di "`chng'  prt_`chng'_`varn_' = `prt_`chng'_`varn_''"
        }
    } // var loop
    local maxprintrow = `iprtrow'

//  statistics type information

    * labels for output
    local Slbl_change "Change"
    local Slbl_ul "UL"
    local Slbl_ll "LL"
    local Slbl_z "z-value"
    local Slbl_se `"Std. Err."'
    local Slbl_pvalue "P>|z|"
    local Slbl_start "From"
    local Slbl_end "To"

    * sets of stats
    local S_nostrtend "change pvalue ul ll z se"
    local S_default "change pvalue"
    local S_show "`statistics'"
    if ("`S_show'"=="") local S_show "`S_default'"
    if ("`S_show'"=="all") local S_show "`S_all'"
    local ipos : list posof "ul" in S_show
    local S_isul = `ipos'>0
    local ipos : list posof "ll" in S_show
    local S_isll = `ipos'>0

//  matrices to hold results

    * dummy matrices are stacked for each variable to hold results
    * dimension: (5 change types) by ncats
    matrix `outmat1var' = J(5,`lhsncats',.z)
    matrix rownames `outmat1var' = `C_rownms'
    * col is outcome cat or expresssion from margins if only 1 category
    matrix colnames `outmat1var' = `lhscatnms'
    matrix `outmat1varR' = `outmat1var'
    matrix rownames `outmat1varR' = `C_rownmsR' // Range is in label

    * stack matrices for each variable
    * if only i.catvar, this loop is not run; later will need
    * to create outmatall just for catvar
    local isvarnmsmain = 1  // 0821
    if ("`varnmsmain'"=="") local isvarnmsmain = 0
    foreach varnm in `varnmsmain' {
        local nm : subinstr local varnm "." "_", all
        local nm : subinstr local nm "#" "_", all
        * if trim and not binary
        if `trim'!=0 & `isbin_`nm''!=1 {
            local trimUB = 100 - `trim'
            qui centile `varnm' `if' `in', centile(`trim' `trimUB')
            local rng_F = r(c_1)
            local rng_T = r(c_2)
            if "`rng_F'"=="`rng_T'" {
                matrix roweq `outmat1varR' = `varnm'
                matrix `outmatall' = nullmat(`outmatall') \ `outmat1varR'
            }
            else {
                matrix roweq `outmat1var' = `varnm' // name for output
                matrix `outmatall' = nullmat(`outmatall') \ `outmat1var'
            }
        } // trim
        else {
            matrix roweq `outmat1var' = `varnm'
            matrix `outmatall' = nullmat(`outmatall') \ `outmat1var'
        }
    }
    if `dropmat'==1 {
        capture matrix drop `matstub'
        foreach s in `S_all' {
            capture matrix drop `matstub'_`s'
        }
    }
    capture matrix list `matstub'
    if _rc==0 {
        display as error ///
"matrix `matstub' exists; choose another name or delete matrix"
        exit
    }
    else capture matrix drop `matstub'
    foreach s in `S_all' {
        capture matrix list `matstub'_`s'
        if _rc==0 {
            display as error ///
"matrix `matstub'_`s' exists; choose another name or delete matrix"
            exit
        }
        else capture matrix drop `matstub'_`s'
    }
    if `mainvars' {
        foreach stat in end `S_all' {
            matrix `matstub'_`stat' = `outmatall'
            matrix coleq `matstub'_`stat' = `stat'
        }
    }

//  dummy run of margins to get labels for output

    qui {
        * construct test margins command
        local OutcomeName "`e(depvar)'"
        qui sum `OutcomeName'
        local MinOutValue = r(min)
        tempvar TestVariable
        capture quietly predict `TestVariable', outcome(`MinOutValue')
        capture drop `TestVariable'
        if _rc == 0 {
            local MarginPred "predict(outcome(`MinOutValue'))"
        }
        local margcmd ///
            "margins `if' `in', at(`at') `atmeans' `options' `MarginPred'"
        local margcmd : subinstr local margcmd "  " " ", all
        local margcmd : subinstr local margcmd "  " " ", all
        `qui' di ". `margcmd'"
        `qui' margins `if' `in', at(`at') `atmeans' `options' `MarginPred'
        _rm_marginsnames // get names used by margins for predictions
        local Mtitle   `s(title)'
        local Mpredict `s(predict)' // use this with predict for ADC stata 11
*noi di "Mpredict `Mpredict'"
        local Mtype    `s(type)'
        local Mmath    `s(math)'
        local Mmath_noequal    `s(math_noequal)'
        local Mmath10  `s(math10)'
        local Mlength  `s(length)'

        * get name of prediction from count model; say predict(pr(0))
        if ("`cmdcrm'"=="1") {
            local predlabel "`r(predict_label)'"
            if "`predlabel'"=="Predicted number of events" {
                local lhscatnms "Rate"
            }
            else local lhscatnms "`predlabel'"
            if `isvarnmsmain'==1 { // 0821
                matrix colnames `outmatall' = "`lhscatnms'"
            }
            else local error = 0
        }
        local nobsifin = r(N)
        local p1base = el(r(b),1,1) // used for base predictions
    }

//  place at values in matrix atmat

    qui {

        local isat = 0
        capture matrix list r(at)
        if _rc==0 { // r(at) exists
            local nrowsat = rowsof(r(at))
            if `nrowsat'>1 {
                display as error ///
"at() can specify only one value; for example, at(female=(0 1)) is invalid"
                exit
            }
            quietly mlistat, saveconstant(atmat)
            local isat = `s(isconstant)' // at matrix with fixed values
            if `isat'==1 {
                matrix rownames atmat = "at"
                matrix `atmat' = atmat
                capture matrix drop atmat
            }
            local atmatcolnms : colnames `atmat'
        }
    } // quietly

//  compute changes


    local nobs = _N // # of rows in dataset
    local isatopt = 0 // is at() specified in mchange?
    if ("`at'"!="") local isatopt = 1

    if "`dopreserve'"=="yes" { // Stata 13 uses at(x=gen())
        * Stata 11 computes some average DC's by making counterfactual
        * predictions using these variables
        tempvar varsd_F varsd_T varone_F varone_T varone_DC varsd_DC varinsamp
        tempvar origvar predictF predictT predictDC
        preserve // restore data if data changed for counterfactuals
    }

    * desc stats for at variables
    matrix `vecatdesc' = J(4,1,-9999)
    matrix rownames `vecatdesc' = Mean Std_Dev Min Max
    capture matrix drop `matatdesc'
    local ismatatdesc = 0 // is matatdesc populated?

    qui {
        if "`pre13'"=="yes" & "`dopreserve'"=="yes" {
            gen `varinsamp' = 1 `if' `in'
            lab var `varinsamp' "selected observation"
            gen `varsd_DC' = .
            lab var `varsd_DC' "sd DC"
            gen `varsd_F' = .
            lab var `varsd_F' "x - sd/2"
            gen `varsd_T' = .
            lab var `varsd_T' "x + sd/2"
            gen `varone_DC' = .
            lab var `varone_DC' "one DC"
            gen `varone_F' = .
            lab var `varone_F' "x - 1/2"
            gen `varone_T' = .
            lab var `varone_T' "x + 1/2"
            gen `origvar' = .
            label var `origvar' "change var before manipulation for AME"
        }
    }

// loop over vars

    qui {

    local varnum = 0
    foreach varnm in `varnmsmain' {
        local ++varnum

        if "`pre13'"=="yes" & "`dopreserve'"=="yes" {
            replace `origvar' = `varnm' // orig value before counterfactual
        }

        * var name without factor variable symbols
        local varn_ : subinstr local varnm "." "_", all
        local varn_ : subinstr local varn_ "#" "_", all

        * get non-fv name and check if 1. variable; remove i. too
        local varnm_nofv = regexr("`varnm'","[0-9i]+\."," ")
        local isfvbin = `is`varn_'bin'

        * get from to values
        sum `varnm' `if' `in'
        local mn = r(mean)
        local varmax = r(max)
        local varmin = r(min)
        local sd = r(sd)
        local sd2 = r(sd)/2
        if `delta' !=0 {
            local sd2 = `delta'/2
            local sd = `delta'
        }

        * save desc statistics
        matrix `vecatdesc'[1,1] = r(mean)
        matrix `vecatdesc'[2,1] = r(sd)
        matrix `vecatdesc'[3,1] = r(min)
        matrix `vecatdesc'[4,1] = r(max)
        matrix colnames `vecatdesc' = `varnm'
        matrix `matatdesc' = nullmat(`matatdesc') , `vecatdesc'
        local ismatatdesc = 1

        * range
        local error = 0
        if `trim'==0 {
            local rng_F = r(min) // works for svy
            local rng_T = r(max)
        }
        else { // trim
            if `cmdsvy' { // svy estimation
                display as error "trim() cannot be used with svy estimation"
                local error = 1
                continue, break
            }
            if `isbin_`varn_''==1 { // binary regressor
                local rng_F = 0
                local rng_T = 1
            }
            else { // not binary
                local trimUB = 100 - `trim'
                centile `varnm' `if' `in', centile(`trim' `trimUB')
                local rng_F = r(c_1)
                local rng_T = r(c_2)
                if "`rng_F'"=="`rng_T'" {
                    local rng_F = `varmin'
                    local rng_T = `varmax'
                    noisily display ///
"range for trimmed `varnm' is 0 so change from min to max is used"
                }
            }
        } // trim

* TODO: make this more general for svy
*   if can;t compute SD, go to next variable, don't quit.
*   perhaps try to compute other ways. see Isabel Canette's comments

        * svy estimation
        if `cmdsvy' {
            capture svy : mean  `varnm' `if' `in'
            if _rc!= 0 {
                display as error ///
                "cannot compute std dev for factor variables with svy data"
                exit _rc
                continue
            }
            estat sd
            local mn = el(r(mean),1,1)
            local sd = el(r(sd),1,1)
            local sd2 = el(r(sd),1,1)/2
        }

        * at-value for current variable
        local atval = .
        capture matrix list `atmat'
        if _rc==0 { // r(at) exists
            local icol : list posof "`varnm'" in atmatcolnms
            local atval = `atmat'[1,`icol']
        }
        if (`atval'==.) local baseval = `mn' // mean if not specified
        else local baseval = `atval' // at value if specfied

        //  determine F_rom values and T_o values for changes

        * binary
        local bin_F = 0
        local bin_T = 1

        * one and sd
        if "`uncentered'"=="" {
            * for MER used specific values
            local one_F = `baseval' - .5
            local one_T = `baseval' + .5
            local sd_F  = `baseval' - `sd2'
            local sd_T  = `baseval' + `sd2'
            * for ADC use at(x=gen())
            local one_Fgen "`varnm'=gen(`varnm' - .5)"
            local one_Tgen "`varnm'=gen(`varnm' + .5)"
            local sd_Fgen "`varnm'=gen(`varnm' - `sd2')"
            local sd_Tgen "`varnm'=gen(`varnm' + `sd2')"
        }
        else { // uncentered
            local one_F = `baseval'
            local one_T = `baseval' + 1
            local sd_F  = `baseval'
            local sd_T  = `baseval' + `sd'
            local one_Fgen "`varnm'=gen(`varnm')"
            local one_Tgen "`varnm'=gen(`varnm' + 1)"
            local sd_Fgen "`varnm'=gen(`varnm')"
            local sd_Tgen "`varnm'=gen(`varnm' + `sd')"
        }

        * at() values for all dc types
        foreach chng in `Cset_dc' {
            local at_`chng' "``chng'_F' ``chng'_T'"
        }

        //  loop over categories and compute margins

        local catnum = 0
        if (`cmdbin'==1 | `cmdcrm'==1) local lhscatvals "1" // only compute 1
        foreach catval in `lhscatvals' {
          local optpredict "" // default predict for use with margins
          if (`cmdbin'==1) local catnum = 2 // col2 for binary
          else if (`cmdcrm'==1) local catnum = 1 // col1 for count
          else {
              local ++catnum
              local optpredict "predict(outcome(`catval'))"
          }

//  loop through change amounts

          local ichng = 0
          foreach chng in `Cset_all' {

            local isslowmsg = 0
            * if +sd or +1 & not atmeans needat(x=gen) in Stata 12
            * in Stata 12 use counterfactual is used
            local doatgen = 0 // use at(x=gen(x+d))
            if (("`chng'"=="one") | ("`chng'"=="sd")) ///
                  & ("`atmeans'"!="atmeans") {
                local doatgen = 1
            }

            *    print this change      &   change not marg
            if (`prt_`chng'_`varn_''>0) & ("`chng'"!="marg") {
                local ++ichng
                estimates restore _mchange_model

                * at() list w/o factor variables
                local atFromTo "`varnm_nofv'=(`at_`chng'')"
                * can margins be used in Stata 12 and 11
                local domargins12 = 1
                * can't do +-1 or +-sd change
                if (`isfvbin'==1 & "`chng'"=="one") local domargins12 = 0
                if (`isfvbin'==1 & "`chng'"=="sd")  local domargins12 = 0

                * can use margins at(from to)
                if (`domargins12'==1) & (`doatgen'==0) {
                    `qui' margins `if' `in', at(`atFromTo' `at') ///
                        `atmeans' `options' post `optpredict'
                    `qui' lincom _b[2._at] - _b[1._at]
                    _rm_lincom_stats
                    scalar `start'  = _b[1._at]
                    scalar `end'    = _b[2._at]
                    scalar `change' = r(est)
                    scalar `se'     = r(se)
                    scalar `z'      = r(z)
                    scalar `pvalue' = r(p)
                    scalar `ll'     = r(lb)
                    scalar `ul'     = r(ub)
                    scalar `lvl'    = r(level)
                    estimates restore _mchange_model
                } // margins and no loop

                * Stata 13+ use at(x=gen(x+))
                else if "`pre13'"=="no" {
                    local atFrom "``chng'_Fgen'"
                    local atTo "``chng'_Tgen'"
                    qui margins `if' `in', ///
                        at(`atFrom' `at') at(`atTo' `at') ///
                        `atmeans' `options' post `optpredict'
                    qui lincom _b[2._at] - _b[1._at]
                    _rm_lincom_stats
                    scalar `start'  = _b[1._at]
                    scalar `end'    = _b[2._at]
                    scalar `change' = r(est)
                    scalar `se'     = r(se)
                    scalar `z'      = r(z)
                    scalar `pvalue' = r(p)
                    scalar `ll'     = r(lb)
                    scalar `ul'     = r(ub)
                    scalar `lvl'    = r(level)
                    estimates restore _mchange_model
                }

                * pre Stata 13 needs to compute with counterfactural
                else if ("`pre13'"=="yes") /// can't use at(x=gen)
                      & (`domargins12'==1) & (`doatgen'==1) /// use predict
                      & (`isatopt'==0) { // no at() conditions
                    if ("`lhscatvals'"=="1") local predictout ""
                    else local predictout "outcome(`catval')"
                    scalar `se'     = . // can't compute tests
                    scalar `z'      = .
                    scalar `pvalue' = .
                    scalar `ll'     = .
                    scalar `ul'     = .
                    scalar `lvl'    = .
                    scalar `start'  = .
                    scalar `end'    = .
                    if "`uncentered'"=="" {
                        if "`chng'"=="one" {
                            local subtractthis = .5
                            local addthis = .5
                        }
                        if "`chng'"=="sd" {
                            local subtractthis = `sd2'
                            local addthis = `sd2'
                        }
                    }
                    if "`uncentered'"!="" {
                        local subtractthis = 0
                        if ("`chng'"=="one") local addthis = 1
                        if ("`chng'"=="sd")  local addthis = `sd'
                    }
                    * replace observed with counterfactual and predict
                    replace `varnm' = `origvar' - `subtractthis'
                    capture drop `predictF'
                    *093
                    local predictout2 : ///
                    subinstr local predictout "outcome(" "outcome(#", all
                    predict `predictF' if `varinsamp'==1, `predictout2' // `Mpredict'
                    replace `varnm' = `origvar' + `addthis'
                    capture drop `predictT'
                    predict `predictT' if `varinsamp'==1, `predictout2' // `Mpredict'
                    capture drop `predictDC'
                    gen `predictDC' = `predictT' - `predictF'
                    sum `predictDC' if `varinsamp'==1
                    scalar `change' = r(mean)
                    * restore original data
                    replace `varnm' = `origvar'
                } // AME 1 & SD using predict

                * margins loop and at specified
                *   : this code could be much faster by using counterfactual
                *     predictions. have to make certain that at() conditions
                *     were changed for other variables. jsl 2013-07-03
                else if ("`pre13'"=="yes") /// can't use at(x=gen)
                      & (`domargins12'==1) & (`doatgen'==1) ///
                      & (`isatopt'==1) { // can't use counterfactual
                    if "`isatslow'"=="" {
                        local isatslow = 1
                        noisily display ///
"AME with at() for changes of 1 or SD is slow in Stata 12 and 11."
                    }
                    else {
                        noi display "Computations are proceeding normally..."
                    }
                    forvalues iobs = 1(1)`nobs' {
                        local isin = `varinsamp'[`iobs']
                        * only do computation for selected cases
                        if `isin'==1 {
                            local varis = `varnm'[`iobs']
                            if "`uncentered'"=="" {
                                local one_F = `varis' - .5
                                local one_T = `varis' + .5
                                local sd_F  = `varis' - `sd2'
                                local sd_T  = `varis' + `sd2'
                            }
                            else { // uncentered
                                local one_F = `varis'
                                local one_T = `varis' + 1
                                local sd_F  = `varis'
                                local sd_T  = `varis' + `sd'
                            }
                            local atFromTo ///
                                "`varnm_nofv'=(``chng'_F' ``chng'_T')"
                            * margins is slow but use at() and other options
                            `qui' margins in `iobs', at(`atFromTo' `at') ///
                                `atmeans' `options' `optpredict' nose
                            scalar `start' = el(r(b),1,1)
                            scalar `end' = el(r(b),1,2)
                            scalar `change' = `end' - `start'
                            qui replace `var`chng'_F' = `start' in `iobs'
                            qui replace `var`chng'_T' = `end' in `iobs'
                            qui replace `var`chng'_DC' = `change' in `iobs'
                            scalar `se' = .
                            scalar `z' = .
                            scalar `pvalue' = .
                            scalar `ll' = .
                            scalar `ul' = .
                            scalar `lvl' = .
                        } // in sample
                    } // obs loop

                    * compute effect
                    qui sum `var`chng'_DC'
                    scalar `change' = r(mean)
                } // AME sd & one with at()

                * do not compute effect
                else {
                    scalar `start' = .
                    scalar `end' = .
                    scalar `change' = .
                    scalar `se' = .
                    scalar `z' = .
                    scalar `pvalue' = .
                    scalar `ll' = .
                    scalar `ul' = .
                    scalar `lvl' = .
                }

                * save to matrix
                foreach stat in `S_all' {
                    matrix ///
                    `matstub'_`stat'[`mat_`chng'_`varn_'',`catnum'] ///
                          = ``stat''
                }
            } // if print and not marg
          } // foreach chng

//  partial

        if `prt_marg_`varn_''>0 {
            estimates restore _mchange_model
            * fv fix: remove i. 1. etc.
            local varnm_nofv = regexr("`varnm'","[0-9i]+\."," ")
            `qui' margins `if' `in', dydx(`varnm_nofv') ///
                at(`at') `atmeans' post `options' `optpredict'
            scalar `change' = el(r(table),1,1)
            scalar `se'     = el(r(table),2,1)
            scalar `z'      = el(r(table),3,1)
            scalar `pvalue' = el(r(table),4,1)
            scalar `ll'     = el(r(table),5,1)
            scalar `ul'     = el(r(table),6,1)
            scalar `start'  = .
            scalar `end'    = .
            scalar `lvl'    = r(level)
            foreach stat in `S_all' {
                matrix `matstub'_`stat'[`mat_marg_`varn_'',`catnum'] ///
                    = ``stat''
            }
            estimates restore _mchange_model
        } // if partial
        local lvlis = `lvl'
        local CInote "CI computed at `lvlis' percent level."
      } // loop over catval
    } // over varnm

    } // quietly

    if (`error'==1) exit

//  bystat: matrices with results in bystat

    foreach stat in `S_all' {
        foreach varnm in `varnmsmain' {
            local varn_ : subinstr local varnm "." "_", all
            local varn_ : subinstr local varn_ "#" "_", all
            if (`isbin_`varn_''==1) local Cshow_list `Cshow_bin' // 2013-03-14
            else  local Cshow_list `Cshow_con'
            foreach chng in `Cshow_list' {
                if `prt_`chng'_`varn_''>0 {
                    matrix _mchange_`stat' = nullmat(_mchange_`stat') ///
                        \ `matstub'_`stat'[`mat_`chng'_`varn_'',1...]
                }
            } // chng
        } // varnm
    } // stat

    if `cmdbin' & `mainvars' {
        foreach stat in `S_show' {
            matrix coleq _mchange_`stat' = ""
            matrix coln _mchange_`stat' = `""`Slbl_`stat''""'
            * col 2 has pr(1); col 1 has pr(0)
            matrix _mchange_ = nullmat(_mchange_) , _mchange_`stat'[1...,2]
        }
    }

//  byvar: matrices with results in order byvariable

    capture matrix drop `matstub'_byvar
    if `cmdbin' & `mainvars' { // only do if some mainvars in varlist
        matrix `matstub'_byvar = _mchange_
    }
    else if `mainvars' {
        foreach varnm in `varnmsmain' {
            local varn_ : subinstr local varnm "." "_", all
            local varn_ : subinstr local varn_ "#" "_", all
            local Clist `Cshow_con' `Cshow_bin'
            local Clist : list uniq Clist
            * DROP foreach chng in `Cshow_con' `Cshow_bin' {
            foreach chng in `Clist' {
                local chngnm "`Clbl_`chng''"
                foreach stat in `S_show' {
                    local statnm "`stat'"
                    if ("`stat'"=="pvalue") local statnm "pvalue"
                    if `prt_`chng'_`varn_''>0 {
                        matrix `vecis' = ///
                            `matstub'_`stat'[`mat_`chng'_`varn_'',1...]
                        local rowfullnm : rowfullnames `vecis'
                        local roweqnm : roweq `vecis'
                        if "`stat'"=="change" {
                            local rowfullnm "`roweqnm':`chngnm'"
                        }
                        else {
                            local rowfullnm "`roweqnm':`statnm'"
                        }
                        matrix rownames `vecis' = "`rowfullnm'"
                        matrix `matstub'_byvar = nullmat(`matstub'_byvar) ///
                            \ `vecis'
                    }
                    local notfirst = 1
                } // stat
            } // chng
        } // varnm
        matrix coleq `matstub'_byvar = ""
    }

//  process categorical variables: i.catvar

    local varnum = 0
    local cchange = 1
    local cse = 2
    local cz = 3
    local cpvalue = 4
    local cll = 5
    local cul = 6
    qui {
        foreach catvarnm in `varnmscat' {
            local ++varnum
            local catnum = 0
            if (`cmdbin'==1 | `cmdcrm'==1)  local lhscatvals "1"
            foreach catval in `lhscatvals' {
                if `cmdbin'==1 {
                    local catnum = 2 // save pr(1) in col 2
                    local optpredict ""
                }
                else if `cmdcrm'==1 {
                    local catnum = 1 // save mu in col 1
                    local optpredict ""
                }
                else {
                    local ++catnum
                    local optpredict "predict(outcome(`catval'))"
                }
                `qui' margins `catvarnm'  `if' `in', pwcompare ///
                    at(`at') `atmeans' `options' `optpredict'
                matrix pwmat`catval' = r(table_vs)'
            }
            local nrows = colsof(r(table_vs))
            local rownms : colnames r(table_vs)
            local rownms : subinstr local rownms ".`catvarnm'" "", all
            local rownms : subinstr local rownms "vs" "_vs_", all
            forvalues i = 1(1)9 {
                local rownms : subinstr local rownms "`i'bn" "`i'", all
            }
            local S_pwshow = subinword("`S_show'", "start", "", .)
            local S_pwshow = subinword("`S_pwshow'", "end", "", .)
            local S_pwall = subinword("`S_all'", "start", "", .)
            local S_pwall = subinword("`S_pwall'", "end", "", .)
            foreach stat in `S_nostrtend' { // `S_pwshow'
                matrix tempmat = J(`nrows',`catnum',.)
                forvalues irow = 1(1)`nrows' {
                    foreach jcol in `lhscatvals' {
                        local srccol = `c`stat'' // source location
                        scalar stat = pwmat`jcol'[`irow',`srccol']
                        matrix tempmat[`irow',`jcol'] = stat
                    }
                }
                matrix colnames tempmat = `lhscatnms'
                local newnms : subinstr local rownms "vs" "_vs_", all
                local newnms : subinstr local rownms "bn" "", all
                matrix rownames tempmat = `newnms'
                matrix roweq tempmat = `catvarnm'
                matrix pwprt_`stat' = nullmat(pwprt_`stat') \ tempmat
                capture drop tempmat
            }
        } // i.catvars
        capture matrix drop tempmat
    } // qui

    if "`varnmscat'"!="" {
        foreach stat in `S_nostrtend' {
            capture matrix drop `matstub'_pw`stat'
            foreach catvarnm in `varnmscat' {
                matrix `matstub'_pw`stat' = nullmat(`matstub'_pw`stat') ///
                    \ pwprt_`stat'
            }
        }
    }

//  add pwcompare to _mchange_ and _mchange_stat

    if "`varnmscat'"!="" {
        * binary model
        if `cmdbin' {
            capture matrix drop pwprt_
            foreach stat in `S_pwshow' {
                matrix coleq pwprt_`stat' = ""
                matrix coln pwprt_`stat' = `""`Slbl_`stat''""'
                matrix pwprt_ = nullmat(pwprt_) , pwprt_`stat'[1...,1]
                capture matrix drop pwprt_`stat'
            }
            matrix _mchange_ = nullmat(_mchange_) \ pwprt_
        }
        * not binary
        else {
            *foreach stat in `S_show' {
            foreach stat in `S_all' {
                local ipos : list posof "`stat'" in S_pwall
                if `ipos'>0 {
                    matrix _mchange_`stat' = nullmat(_mchange_`stat') ///
                        \ pwprt_`stat'
                }
            }
        } // not binary
    } // i.catvar

    * nonbinary with catvar
    if "`varnmscat'"!="" & !`cmdbin' {
        *dc
        local npwrows = rowsof(pwprt_change)
        forvalues irow = 1(1)`npwrows' {
            local notfirst = 0
            foreach stat in `S_show' {
                local ipos : list posof "`stat'" in S_pwshow
                if `ipos'>0 {
                    matrix `vecis' = pwprt_`stat'[`irow',1...]
                    local rowfullnm : rowfullnames `vecis'
                    local roweqnm : roweq `vecis'
                    if `notfirst'==1 {
                        local rowfullnm "`roweqnm':`stat'"
                    }
                    else {
                        local rowfullnm "`rowfullnm'"
                        local notfirst = 1
                    }
                    matrix rownames `vecis' = "`rowfullnm'"
                    matrix `matpw' = nullmat(`matpw') \ `vecis'
                }
            } // stat
        }
*        matrix `matstub'_byvar = `matstub'_byvar \ `matpw'
        matrix `matstub'_byvar = nullmat(`matstub'_byvar) \ `matpw' // 0821
    } // nonbinary with catvars

//  print results

*    if ("`title'"=="") local titlenm "`cmdttl': Changes for `lhsnm'"
*    else local titlenm "`title'"

    if ("`title'"=="") local titlenm "`cmdttl': Changes in `Mmath_noequal'"
    else local titlenm "`title'"
    display _new "{sf}`titlenm' | N = `nobsifin'" _continue
*display "Changes in `Mtitle'"
*display "Changes in `Mmath'"

//  show results by statistic

    if `cmdbin' {
        matlist _mchange_, format(%9.`decimals'f) ///
            title("{bf}`Slbl_`s''{sf}") lines(oneline) underscore
    }
*matlist `matstub'_byvar, title(test matstub_byvar)
    * not binary
    else {
        * show one statistics per table
        if "`bystatistics'"=="bystatistics" {
            display
            foreach s in `S_show' {
                matrix coleq _mchange_`s' = ""
                matlist _mchange_`s', format(%9.`decimals'f) ///
                    title("{bf}`Slbl_`s''{sf}") lines(oneline) underscore
            }
        } // by stat
        else {
            if ("`cmdcrm'"=="1") matrix colnames `matstub'_byvar = `lhscatnms'
            matlist `matstub'_byvar, format(%9.`decimals'f) ///
                    title("{bf}`Slbl_`s''{sf}") lines(oneline) underscore
        }
    }

//  base values

    if `cmdbin' & "`brief'"=="" {
        local p0base = 1 - `p1base'
        matrix `pbase' = `p0base', `p1base'
        matrix rownames `pbase' = `""Pr(y|base)""'
        matrix colnames `pbase' = `lhscatnms'
        if ("`atmeans'"=="atmeans") di _new "{sf}Predictions at base values"
        else display _new "{sf}Average predictions"
        matrix list `pbase', noheader format(%7.`decimals'f)
    }

    if `isat' & "`brief'"=="" {
        * remove b. columns from i. variables
        capture matrix drop `selmat'
        local colnms : colnames `atmat'
        foreach icolnm of local colnms {
            local isbdot = 1 - regexm(`"`icolnm'"',"b\.")
            matrix `selmat' = nullmat(`selmat') , `isbdot'
        }
        _rm_matrix_select `atmat' `selmat' col
        * remove missing columns
        _rm_matrix_nomiss `atmat' col  // "`colnames'"
        display as text _new "{sf}Base values of regressors{sf}" // _cont
        matrix rownames `atmat' = `"r(at)"'
        matrix list `atmat', noheader format(%7.`decimals'f)
    }
    else {
        local noconnote ///
        "Predictions averaged over the sample."
        *local noconnote "No variables held constant when computing changes."
    }

    if ("`descriptives'"=="descriptives") & `ismatatdesc'==1 {
        matlist `matatdesc', format(%7.4g) underscore border(none) ///
            lines(none) twidth(8) title(Descriptive statistics)
    }
    display

    if  "`brief'"=="" {
        local i = 1
        if "`atmeans'"=="atmeans" {
            display _col(1) "`i': Estimates with margins option atmeans."
            local ++i
        }
        if "`intdroplist'"!="" {
            display _col(1) "`i': `intdropnote'"
            display _col(4) "`intdropnote2'"
            local ++i
        }
        if "`quadnote'"!="" {
            display _col(1) "`i': `quadnote'"
            local ++i
        }
        if "`noconnote'"!="" {
            display _col(1) "`i': `noconnote'"
            local ++i
        }
        if "`deltanote'"!="" {
            display _col(1) "`i': `deltanote'"
            local ++i
        }
        if "`samplenote'"!="" {
            display _col(1) "`i':`samplenote'"
            local ++i
        }
        if `C_isrng'==1 {
            display _col(1) "`i': `trimnote'"
            local ++i
        }
        if `S_isul'==1 | `S_isll'==1 {
            display _col(1) "`i': `CInote'"
            local ++i
        }
    } // brief

//  cleanup

    qui estimates restore _mchange_model
    foreach catval in `lhscatvals' {
        capture matrix drop pwmat`catval'
    }
    * matrices used for plots
    if `mainvars' {
        *dc
        matrix _mchange_plot_dc = `matstub'_change // for orplot and dcplot
        matrix _mchange_plot_pvalue = `matstub'_pvalue // for orplot & dcplot
    }
    foreach stat in `S_all' {
        capture matrix drop pwprt_`stat'
        capture matrix drop `matstub'_pw`stat'
    }

//  returns

    return scalar N = `nobsifin'

    if `cmdbin'  {
        return matrix table = _mchange_
        if "`matrix'"!="" matrix `matrix' = _mchange_

        * if no mainvars, there matrices were not created
        if `mainvars' {
            foreach stat in `S_all' {
                return matrix `stat' = _mchange_`stat'
            }
        }
    }

    * not cmdbin
    if !`cmdbin' & `mainvars' {
        * returns r(statname)
        foreach stat in `S_all' {
            return matrix `stat' = _mchange_`stat'
        }
        return matrix table = `matstub'_byvar
        if "`matrix'"!="" matrix `matrix' = `matstub'_byvar
    }
    * cleanup
    foreach stat in `S_all' {
        capture matrix drop `matstub'_`stat'
        capture matrix drop _mchange_`stat' // 2013-07-02
    }
    capture matrix drop _mtemp_byvar //2013-02-18

end

* decode amount
program define parse_amt, sclass
    local isbad = 1
    local amt "`1'"
    local is = inlist("`amt'","r","ra","ran","rang","range","rng")
    if `is'==1 {
        local amt "rng"
        local isbad = 0
    }
    local is = inlist("`amt'","b","bi","bin","bina","binar","binary")
    if `is'==1 {
        local amt "bin"
        local isbad = 0
    }
    local is = inlist("`amt'","1","o","on","one")
    if `is'==1 {
        local amt "one"
        local isbad = 0
    }
    local is = inlist("`amt'","s","sd")
    if `is'==1 {
        local amt "sd"
        local isbad = 0
    }
    local is = inlist("`amt'","m","ma","mar","marg","margi","margin")
    if `is'==1 {
        local amt "marg"
        local isbad = 0
    }
    else {
        local is = inlist("`amt'","margina","marginal","dydx","partial")
        if `is'==1 {
            local amt "marg"
            local isbad = 0
        }
    }
    sreturn local amount "`amt'"
    sreturn local isbad "`isbad'"
end

program define parse_stat, sclass
    local isbad = 1
    local stat "`1'"
    local is = inlist("`stat'","z","zv","zva","zval","zvalu","zvalue")
    if `is'==1 {
        local stat "z"
        local isbad = 0
    }
    local is = inlist("`stat'","t","tv","tva","tval","tvalu","tvalue")
    if `is'==1 {
        local stat "z"
        local isbad = 0
    }
    local is = inlist("`stat'","from")
    if `is'==1 {
        local stat "start"
        local isbad = 0
    }
    local is = inlist("`stat'","st","sta","star","start")
    if `is'==1 {
        local stat "start"
        local isbad = 0
    }
    local is = inlist("`stat'","to")
    if `is'==1 {
        local stat "end"
        local isbad = 0
    }
    local is = inlist("`stat'","en","end")
    if `is'==1 {
        local stat "end"
        local isbad = 0
    }
    local is = inlist("`stat'","change","first","dydx","estimat","estimate")
    if `is'==1 {
        local stat "change"
        local isbad = 0
    }
    local is = inlist("`stat'","dc","e","es","est","esti","estim","estima")
    if `is'==1 {
        local stat "change"
        local isbad = 0
    }
    local is = inlist("`stat'","upper","ub","ul")
    if `is'==1 {
        local stat "ul"
        local isbad = 0
    }
    local is = inlist("`stat'","lower","lb","ll")
    if `is'==1 {
        local stat "ll"
        local isbad = 0
    }
    local is = inlist("`stat'","p","pv","pva","pval","pvalu","pvalue")
    if `is'==1 {
        local stat "pvalue"
        local isbad = 0
    }
    local is = inlist("`stat'","se","s")
    if `is'==1 {
        local stat "se"
        local isbad = 0
    }
    sreturn local stat "`stat'"
    sreturn local isbad "`isbad'"

end
exit

* 0.6.0 2012-09-30 | long freese | _rm_modelinfo with r() not s()
* 0.6.1 2012-10-01 | long freese | skips i.cat or int
* 0.6.2 | long freese | quadratics work
* 0.6.3 | long freese | i.catvar works - to clean later
* 0.6.4 | long freese | i.catvar output and factor
* 0.6.5 | long freese | varlist i.bin error trapped
* 0.6.6 | long freese | minor; mchange 2.catvar error; see `mainvars'
*       remove matrixsave()
* 0.6.8 | long freese | #: not #.
* 0.6.7 | long freese | respond to JF's ideas
* 0.7.2 | long freese | _mchange_plot_pvalue
* 0.7.1 | long freese | gologit2; std() refinements
* 0.7.0 | long freese | std() and _mchange_std
* 0.8.2 2013-02-01 | long freese | preserve
* 0.8.1 2013-01-31 | long freese | use predict for ame
* 0.8.0 2013-01-31 | long freese | error in AME for one and sd; syntax traps
* 0.7.3 2013-01-24 | long freese | remove _dcdp_ add defaultbin;
* 0.7.3 defaultcon; changesingle; changetypes(all)
* 0.8.9 2013-02-19 | long freese | pw binary fix
* 0.8.8 2013-02-18 | long freese | _ for space in matrix names
* 0.8.7 2013-02-14 | long freese | r(table) clear existing first; _bystat_ to _mchange
* 0.8.6 2013-02-14 | long freese | start end valid names; fix labels
* 0.8.5 2013-02-14 | long freese | dc->chng name missed; print in amount order
* 0.8.4 2013-02-14 | long freese | dc->chng
* 0.8.3 2013-02-13 | long freese | bystat; new names; r(table)
* 0.8.11v2 2013-03-15 | long freese | correction to warning message
* 0.8.11 2013-03-14 | long freese | amount(all)
* 0.8.10 2013-02-22 | long freese | fix label for change; stat(ul ll )
* 0.8.14 2013-03-25 | long freese | range print
* 0.8.13 2013-03-22 | long freese | stat(ci)
* 0.8.12 2013-03-15 | long freese | if trim has no range, no trim
* 0.8.19 2013-04-28 | long freese | details syn for verbose
* 0.8.18 2013-04-11 | long freese | amount(delta)
* 0.8.17 2013-03-28 | long freese | allow if based on variable being changed
* 0.8.16 2013-03-28 | long freese | add nobs to title; return N
* 0.8.15 2013-03-25 | long freese | mchange i.catvar
      * mchange 2.catvar 3.catvar  <= no mainvars so skip some code
* 0.8.22 2013-05-19 | long freese | _rm_marginsnames.ado
* 0.8.21 2013-05-19 | long freese | mchange 1.catvar bug
* 0.8.20 2013-05-11 | long freese | trap at(a=(0 1)) add matrix()
    * trap no e(cmd); fix in message; fix asobs message; fixed labels
    * for predicted probabiliteis
    * a : added comments, cleaned code
    * get name for outcome with predict() in count model
* 0.8.26 2013-07-03 | long freese | strip i. from varlist
* 0.8.25 2013-07-02 | long freese | nose for margins on ame with at()
* 0.8.24b 2013-07-02 | long freese | desc; mchange agecat; delete matrices
* 0.8.24 2013-07-02 | long freese | desc; mchange agecat
* 0.8.23 2013-05-21 | long freese | 1.catvar just catvar

INSERTS
            * insert A here
/*
di "nm: `nm'"
di "              cat[`is`nm'cat']"
di "              bin[`is`nm'bin']"
di "           intany[`is`nm'intany']"
di "          intquad[`is`nm'intquad']"
di "         intdrop[`is`nm'intdrop']"
*/
    * insert B here
/*
di "intdroplist: `intdroplist'"
di "intquadcorelist: `intquadcorelist'"
di "intquadbetalist: `intquadbetalist'"
di "binvarlist: `binvarlist'"
*/
    * insert C here
/*
di "varnmsmain: `varnmsmain'"
di "varnmscat : `varnmscat'"
di "betanmscat: `betanmscat'"
di "varnmsdrop: `varnmsdrop'"
di "varnmsquad: `varnmsquad'"
*/
