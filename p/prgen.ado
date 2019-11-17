*! version 2.5.0 2009-10-28 jsl
*  - stata 11 update for returns from -mlogit-

//  generate predictions and ci's to plot

capture program drop prgen
program define prgen, rclass
    version 8
    tempname temp inc xval addbase tobase tobase2

    * check if prgen works with last model
    _pecmdcheck prgen
    local io = r(io)
    if "`io'"=="." {
        exit
    }
    local input : word 1 of `io'   /* input routine to _pepred */
    local output : word 2 of `io'  /* output routine */

//  decode options

    syntax [varlist(numeric min=1 max=1)] [if] [in] ///
        , Generate(string) [x(passthru) Rest(passthru) ///
        Level(passthru) MAXcnt(passthru) all ///
        Brief noBAse Ncases(integer 11) ///
        From(real -867.5309) To(real 867.5309) ///
        /// new options
        MARginal NOIsily CI gap(real 0.0) ///
        /// new options passed to prchange2 follow
        noLAbel noBAse Brief ///
        YStar ept DELta BOOTstrap REPs(passthru) SIze(passthru) ///
        DOts match NORMal PERCENTile BIAScorrected ///
        CONditional ]

        * zt 19Feb2005
        local iszt = 0
        if ("`e(cmd)'"=="ztp" | "`e(cmd)'"=="ztnb") {
            local iszt = 1
            local cond ""
            local condnm "Unconditional"
            local condnmlc "unconditional "
            if "`conditional'"=="conditional" {
                local cond "C"
                local condnm "Conditional"
                local condnmlc "conditional "
            }
        }

    * marginals not available for these models
    if "`e(cmd)'"=="gologit" | "`input'"=="twoeq" ///
            | "`output'" == "tobit" ///
            | "`output'" == "regress" ///
            | `iszt'==0 {
        if "`marginal'"=="marginal" {
            di _n in red "Note: Marginals not available for current model."
        }
        local marginal ""
    }

    * zt no ci's available 19Feb2005
    if "`ci'"=="ci" & `iszt'==1 {
        local ci ""
        di _n in red "Note: ci's not available for current model."
    }

    * options to pass to prvalue
    local pr2input "`level' `maxcnt' `nolabel' `nobase' `brief'"
    local pr2input "`pr2input' `ystar' `ept' `delta' `bootstrap'"
    local pr2input "`pr2input' `reps' `size' `dots' `match'"
    local pr2input "`pr2input' `normal' `percentile' `biascorrected'"

    * print results from prvalue
    local quietly "quietly "
    if "`noisily'"=="noisily" {
        local quietly ""
        di "Results from prvalue called by prgen"
        di
    }

//  get information needed to create plot values

    local max_i = r(maxcount)
    _perhs
    local nrhs = `r(nrhs)'
    local rhsnms "`r(rhsnms)'"
    if "`input'"=="twoeq" {
        local nrhs2 = `r(nrhs2)'
        local rhsnms2 "`r(rhsnms2)'"
    }

    * get info from pecats if depvar not continuous
    if "`output'" != "regress" & "`output'" != "tobit" {
        _pecats
        local ncats = r(numcats)
        local catnms8 `r(catnms8)'
        local catvals `r(catvals)'
        local catnms `r(catnms)'
    }

    *get root() for generating new variables
    local root = substr("`generate'",1,29)
    if _rc != 0 {
        local root = substr("`generate'",1,5)
    }

    * convert input into base values
    _pebase `if' `in', `x' `rest' `choices' `all'
    mat `tobase' = r(pebase)
    if "`input'"=="twoeq" {
        mat `tobase2' = r(pebase2)
    }
    
    * create if to take e(sample) and if conditions into account
    _peife `if', `all'
    local if "`r(if)'"

    * set from and to to min and max of chngvar if unspecified
    qui sum `varlist' `if'
    if `from' == -867.5309 {
        local from = r(min)
    }
    if `to' == 867.5309 {
        local to = r(max)
    }

//  set up and test range to be plotted

    * check from and to
    if `from'>=`to' {
        di in r "from() must be < to()"
        exit
     }

    * turn gap into increments
    if `gap' != 0 {
        if `gap'<=0 {
            di in r "gap must be a positive value."
        }
        tempname range ngaps
        sca `range' = `to' - `from'
        sca `ngaps' = `range'/`gap'
        if  int(`ngaps')==`ngaps' {
            local ncases = `ngaps' + 1
        }
        else {
          di in r "gap does not divide evenly into from to interval."
        exit 198
        }
    }

    * verify valid number of plot points
    if `ncases' < 3 {
        di in r "ncases() must be greater than 3"
        exit 198
    }
    if `ncases' > _N {
        set obs `ncases'
    }
    sca `inc' = (`to'-`from')/(`ncases'-1)

//  find variables among those in model

    * locate specified variable among rhs variables
    local found "no"
    local varnum -1

    *look in main equation, if not there: varnum == -1
    local i2 = 1
    local i2_to : word count `rhsnms'
    while `i2' <= `i2_to' {
        local varchk : word `i2' of `rhsnms'
        unab varchk : `varchk', max(1)
        if "`varlist'"=="`varchk'" {
            local found "yes"
            local varnum = `i2'
            local i2 = `i2_to'
        }
        local i2 = `i2' + 1
    }

    * if zip,zinb look in inflate equation, if not there: varnum2 == -1
    if "`input'"=="twoeq" {
        local i3 = 1
        local i3_to : word count `rhsnms2'
        local varnum2 -1
        while `i3' <= `i3_to' {
            local varchk : word `i3' of `rhsnms2'
            unab varchk : `varchk', max(1)
            if "`varlist'"=="`varchk'" {
                local found "yes"
                local varnum2 = `i3'
                local i3 = `i3_to'
            }
            local i3 = `i3' + 1
        }
    }

    if "`found'"=="no" {
        di in r "`var' not rhs variable"
        exit 198
    }

//  insert from value into base values for initial call of prvalue

    mat PE_in = `tobase'
    * from to variable begins at from
    if `varnum' != -1 {
        mat PE_in[1, `varnum']=`from'
    }
    * for zip and zinb
    if "`input'"=="twoeq" {
        mat PE_in2 = `tobase2'
        if `varnum2' != -1 {
            mat PE_in2[1, `varnum2']=`from'
            }
    }

//  make x() string and compute predictions

    _pexstring
    local xis "`r(xis)'"
    `quietly' prvalue , x(`xis') `pr2input'

//  get marginal

    if "`marginal'"=="marginal" {
        tempname  marg tempmarg
        _pemarg
        mat `tempmarg' = r(marginal)
        if "`output'"=="nominal" | "`output'"=="ordered" {
            mat `tempmarg' = `tempmarg''
        }
        mat `marg' = `tempmarg'[1...,`varnum']'
    }

//  create matrices to be converted to variables

    tempname x_pred pr_pred mu_pred all0_pred xb_pred catvals nextbase
    tempname pr_upper mu_upper all0_upper xb_upper
    tempname pr_lower mu_lower all0_lower xb_lower

    mat def `catvals' = pepred[1,1...]
    mat def `x_pred' = `from'

    local predset "pred"
    if "`ci'" == "ci" {
        local predset "`predset' upper lower"
    }

    foreach nm in `predset' {

        * zt 19Feb2005
        mat def `pr_`nm'' = pe`cond'`nm'[2,1...]
        mat def `mu_`nm'' = pe`cond'`nm'[3,2]
        mat def `xb_`nm'' = pe`cond'`nm'[3,1]
        mat def `all0_`nm'' = pe`cond'`nm'[3,4]
    }

//  loop from from value to to value

    local i = 2
    local i_to = `ncases'
    while `i' <= `i_to' {
        sca `xval' = `from' + (`inc'*(`i'-1))
        * change from variable value
        mat `nextbase' = `tobase'
        if `varnum' != -1 {
            mat `nextbase'[1, `varnum']=`xval'
        }
        mat PE_in = `nextbase'

        * create x() string
        _pexstring
        local xis "`r(xis)'"

        * 0.2.2 050203 `quietly' prvalue , x(`xis') `rest' `pr2input'
        `quietly' prvalue , x(`xis') `pr2input'

        * get marginal effect
        if "`marginal'"=="marginal" {
            _pemarg
            mat `tempmarg' = r(marginal)
            * some marginal matrices need to be transposed first
            if "`output'"=="nominal" | "`output'"=="ordered" {
                mat `tempmarg' = `tempmarg''
            }
            mat def `marg' = `marg' \ `tempmarg'[1...,`varnum']'
        }

        * stack new values in matrices
        mat def `x_pred' = `x_pred' \ `xval'
        foreach nm in `predset' {
            mat def `pr_`nm'' = `pr_`nm'' \ pe`cond'`nm'[2,1...]
            mat def `mu_`nm'' = `mu_`nm'' \ pe`cond'`nm'[3,2]
            mat def `xb_`nm'' =`xb_`nm'' \ pe`cond'`nm'[3,1]
            if "`input'"=="twoeq" {
                mat def `all0_`nm'' =`all0_`nm'' \ pe`nm'[3,4]
            }
        }
        local i = `i' + 1
    }

//  create plot variables

    * x variable
    svmat `x_pred', n(`root'x)
    rename `root'x1 `root'x
    * 23May2005
    local tmplabel : variable label `varlist'
    label variable `root'x "`tmplabel'"
    * label variable `root'x "Changing value of `varlist'"

    * marginal effects
    if "`marginal'"=="marginal" {
        local margnm : word `varnum' of `rhsnms'
        svmat `marg', n(`root'me_`margnm')
    }

//  binary, ordered, nominal or count

    if "`output'"=="binary" ///
        | "`output'"=="nominal" ///
        | "`output'"=="ordered" ///
        | "`output'"=="count" {

        * predictions and bounds
        svmat `pr_pred', n(temp)
        if "`ci'"=="ci" {
            svmat `pr_lower', n(templb)
            svmat `pr_upper', n(tempub)
        }

        * process each outcome probability
        local ncats = peinfo[1,2]
        foreach i of numlist  1/`ncats'  {

            * get # assigned to first category
            local value = `catvals'[1,`i']
            local k`i' = `value'

            * if value are too large or small
            if `value' < -9 | `value' > 99 | int(`value')!=`value' {
                di in red "category values must be integers between -9 and 99"
                exit 198
            }

            * if negative create name using _
            if `value' < 0 {
                local k`i' = abs(`k`i'')
                local k`i' = "_`k`i''"
            }

            * rename and label probability
            rename temp`i' `root'p`k`i''
            local lbl: word `i' of `catnms8'

            * get information to label variables
            if "`lbl'"=="`value'" {
                local fvalue "" // same, so only use 1
            }
            else {
                local fvalue "=Pr(`value')"
            }
            if "`lbl'"=="" {
                local lbl "`value'"
                local fvalue ""
            }
            if "`nolabel'"!="nolabel" {
                * zt 19Feb2005
                label variable `root'p`k`i'' ///
                    "`condnmlc'pr(`lbl')`fvalue'"
            }
            else {
                * zt 19Feb2005
                label variable `root'p`k`i'' ///
                    "`condnmlc'pr(`value')"
            }

            * process upper and lower bounds
            if "`ci'"=="ci" {
                rename tempub`i' `root'p`k`i''ub
                if "label'"!="nolabel" {
                    label variable `root'p`k`i''ub "UB pr(`lbl')`fvalue'"
                }
                else {
                    label variable `root'p`k`i'' "UB pr(`value')"
                }
                rename templb`i' `root'p`k`i''lb
                if "label'"!="nolabel" {
                    label variable `root'p`k`i''lb "LB pr(`lbl')`fvalue'"
                }
                else {
                    label variable `root'p`k`i'' "LB pr(`value')"
                }
            }

            * create variables summing prob of being <= k
            if `ncats'>2 {
                if `i' == 1 {
                    qui gen `root's`k1' = `root'p`k1'
                }
                else {
                    local i_min1 = `i' - 1
                    qui gen `root's`k`i'' = `root'p`k`i'' + `root's`k`i_min1''
                }
                label variable `root's`k`i'' "pr(y<=`value')"
            }

            * marginals
            if "`marginal'"=="marginal" & ///
                    "`output'"!="count" {  // no marg pr# for count
                rename `root'me_`margnm'`i' `root'Dp`k`i''D`margnm'
                label variable `root'Dp`k`i''D`margnm' ///
                    "Marginal dp`k'`i'/d`margnm'"
            }

        } // end of loop through categories

    } // binary, ordered, nominal or count

//  REGRESS/TOBIT MODELS

    if "`output'"=="regress" | "`output'"=="tobit" {

        svmat `xb_pred', n(`root'xb)
        rename `root'xb1 `root'xb

        if "`ci'" == "ci" {
            svmat `xb_lower', n(`root'xblb)
            rename `root'xblb1 `root'xblb
            svmat `xb_upper', n(`root'xbub)
            rename `root'xbub1 `root'xbub
        }

        if "`output'"=="regress" {
            label variable `root'xb "y-hat"
            if "`ci'" == "ci" {
                label variable `root'xblb "UB y-hat"
                label variable `root'xbub "LB y-hat"
            }
        }

        if "`output'"=="tobit" {
            label variable `root'xb "y*-hat"
            if "`ci'" == "ci" {
                label variable `root'xblb "UB y*-hat"
                label variable `root'xbub "LB y*-hat"
            }
        }
    } // regress/tobit

//  for count models, process mu and prall0

    if "`output'"=="count" {

        * marginals
        if "`marginal'"=="marginal" {
            mat list `marg'
            drop `root'me_`margnm'1
            rename `root'me_`margnm'2 `root'DmuD`margnm'
            label var `root'DmuD`margnm' "Marginal dmu/d`margnm'"
        }

        * mu
        svmat `mu_pred', n(`root'mu)
        rename `root'mu1 `root'mu
        * zt 19Feb2005
        label variable `root'mu "predicted `condnmlc'rate mu"

        * upper and lower bounds
        if "`ci'"=="ci" {
            svmat `mu_lower', n(`root'mulb)
            rename `root'mulb1 `root'mulb
            label variable `root'mulb "LB predicted rate mu"
            svmat `mu_upper', n(`root'muub)
            rename `root'muub1 `root'muub
            label variable `root'muub "UB predicted rate mu"
        }

        if "`input'"=="twoeq" {
            svmat `all0_pred', n(`root'all0)
            rename `root'all01 `root'all0
            label variable `root'all0 "pr(Always-0)"
            if "`ci'"=="ci" {
                svmat `all0_lower', n(`root'all0lb)
                rename `root'all0lb1 `root'all0lb
                label variable `root'all0lb "LB pr(Always-0)"
                svmat `all0_upper', n(`root'all0ub)
                rename `root'all0ub1 `root'all0ub
                label variable `root'all0ub "UB pr(Always-0)"
            }
        }

    } // mu and prob always 0

//  COMMON OUTPUT

    if "`brief'"=="" & "`base'"!="nobase" {
        di _n in y "`e(cmd)'" in g ": Predicted values as " /*
        */ in y "`varlist'" in g /*
        */ " varies from " in y "`from'" in g " to " /*
        */ in y "`to'" in g "."

        *print base values
        if "`input'"=="twoeq" {
            di _n in g "base x values for count equation: "
        }
        mat rownames `tobase' = "x="
        mat _PEtemp = `tobase'
        _peabbv _PEtemp
        mat list _PEtemp, noheader
        if "`input'"=="twoeq" {
            di _n in g "base z values for binary equation: "
            mat rownames `tobase2' = "z="
            mat _PEtemp = `tobase2'
            _peabbv _PEtemp
            mat list _PEtemp, noheader
        }
    }

end
exit
* version 2.0.2 23May2005 : use label of varlist variable not changing...
* version 2.0.3 20Jun2005 : _pexstring bug fix
* version 2.0.4 23Jun2005 : _pexstring bug fix (2)
