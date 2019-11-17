*! version 2.5.0 2009-10-28 jsl
*  - stata 11 update for returns from -mlogit-

capture program drop prtab
program define prtab, rclass
    version 6
    tempname tobase tobase2 addbase replval temp
    tempvar added cell

**  #1 classify each valid type of model

    * zt 18Feb2005
    local iszt = 0
    if ("`e(cmd)'"=="ztp" | "`e(cmd)'"=="ztnb") {
        local iszt = 1
    }

    * zt 19Feb2005
    if "`e(cmd)'"=="ztp"  { local io = "typical count"   }
    if "`e(cmd)'"=="ztnb"  {    local io = "typical count"     }
    if "`e(cmd)'"=="cloglog"  { local io = "typical binary" }
    if "`e(cmd)'"=="cnreg"    { local io = "typical tobit" }
    if "`e(cmd)'"=="fit"      { local io = "typical regress" }
    if "`e(cmd)'"=="gologit"  { local io = "typical mlogit" }
    if "`e(cmd)'"=="intreg"   { local io = "typical tobit" }
    if "`e(cmd)'"=="logistic" { local io = "typical binary" }
    if "`e(cmd)'"=="logit"    { local io = "typical binary" }
    if "`e(cmd)'"=="mlogit"   { local io = "typical mlogit" }
    if "`e(cmd)'"=="nbreg"    { local io = "typical count" }
    if "`e(cmd)'"=="ologit"   { local io = "typical ordered" }
    if "`e(cmd)'"=="oprobit"  { local io = "typical ordered" }
    if "`e(cmd)'"=="poisson"  { local io = "typical count" }
    if "`e(cmd)'"=="probit"   { local io = "typical binary" }
    if "`e(cmd)'"=="regress"  { local io = "typical regress" }
    if "`e(cmd)'"=="slogit"  { local io = "typical ordered" }
    if "`e(cmd)'"=="tobit"    { local io = "typical tobit" }
    if "`e(cmd)'"=="zinb"     { local io = "twoeq count" }
    if "`e(cmd)'"=="zip"      { local io = "twoeq count" }
    if "`io'"=="" {
        di
        di in r "prtab does not work for the last type of model estimated."
        exit
    }
    local input : word 1 of `io'   /* input routine to _pepred */
    local output : word 2 of `io'  /* output routine */

**  #2 get info about variables

    _perhs
    local nrhs = `r(nrhs)'
    local rhsnms "`r(rhsnms)'"
    if "`input'"=="twoeq" {
        local nrhs2 = `r(nrhs2)'
        local rhsnms2 "`r(rhsnms2)'"
    }
    if "`output'" != "regress" & "`output'" != "tobit" {
        _pecats
        local ncats = r(numcats)
        local catnms8 `r(catnms8)'
        local catvals `r(catvals)'
        local catnms `r(catnms)'
    }

**  #3 decode specified input

    syntax varlist(min=1 max=3 numeric) [if] [in] /*
    */ [, x(passthru) Rest(passthru) Outcome(string) /*
    */ by(varlist numeric max=1) /*
    */ noBAse Brief NOLabel NOVARlbl all /*
    */ CONditional ]

    * zt 19Feb2005
    if `iszt'==1 & "`conditional'"=="conditional" ///
        & "`outcome'"=="0" {
        di _n in r "conditional probabilities for outcome 0 are undefined."
        exit
    }

    *convert input into tobase
    _pebase `if' `in', `x' `rest' `choices' `all'
    mat `tobase' = r(pebase)
    if "`input'"=="twoeq" { mat `tobase2' = r(pebase2) }

    *fix if to take e(sample) and if conditions into account
    _peife `if', `all'
    local if "`r(if)'"

    * handle outcome option for ordered mlogit and ordered models
    if "`outcome'"!="" {
        if "`output'"=="ordered" | "`output'"=="mlogit" {
            local found "no"
            local i = 1
            while `i' <= `ncats' {
                local valchk : word `i' of `catvals'
                local nmchk : word `i' of `catnms'
                if ("`outcome'"=="`valchk'") | ("`outcome'"=="`nmchk'") {
                    local found "yes"
                    local outcmv = "`valchk'"
                    if "`valchk'"!="`nmchk'" { local outcmnm "(`nmchk')" }
                    local outcome = `i'
                    local i = `ncats'
                }
                local i = `i' + 1
            } /* while `i' <= `ncats' */
            if "`found'"=="no" {
                di in r "`outcome' not category of `e(depvar)'"
                exit 198
            }
        } /* "`output'"=="ordered" | "`output'"=="mlogit" { */
        else if "`output'"=="count" {
            confirm integer number `outcome'
            if `outcome' < 0 { exit 198 }
            local outcmv "`outcome'"
        }
        else {
            di in r "outcome() not allowed for prtab after `e(cmd)'"
            exit 198
        }
    } /* if "`outcome'"!="" */

    *if by option has been specified, put this variable into the end
    *of `varlist'
    local varnoby = "`varlist'" /* needed for tabdisp at end */
    if "`by'"!="" { local varlist "`varlist' `by'" }

**  #4 build PE_in matrix

    local nvars : word count `varlist'
    *cycle through varlist (as many as four variables)
    local i = 1
    while `i' <= 4 {
        *if varlist shorter than i, set ncats# to 1 and varnum# to -1
        if `nvars' < `i' {
            local ncats`i' = 1
            local varnum`i' = -1
            if "`input'"=="twoeq" { local varnm2`i' = -1 }
        }
        else {
            local var`i' : word `i' of `varlist'
            _pecats `var`i'' `if'
            local ncats`i' = r(numcats)
            local nms`i' "`r(catnms)'"
            local nms8`i' "`r(catnms8)'"
            local vals`i' "`r(catvals)'"
            * find variable position in base matrix
            * assign varnum and varnm2 accordingly
            * varnum == -1 if not in main equation
            * varnum2 == -1 if zip/zinb but variable not in inflate equation
            local found "no"
            local varnum`i' -1
            local i2 = 1
            local i2_to : word count `rhsnms'
            while `i2' <= `i2_to' {
                local varchk : word `i2' of `rhsnms'
                unab varchk: `varchk', max(1)
                if "`var`i''"=="`varchk'" {
                    local found "yes"
                    local varnum`i' = `i2'
                    local i2 = `i2_to'
                }
                local i2 = `i2' + 1
            }
            *if zip/zinb model
            if "`input'"=="twoeq" {
                local varnm2`i' -1
                local i3 = 1
                local i3_to : word count `rhsnms2'
                while `i3' <= `i3_to' {
                    local varchk : word `i3' of `rhsnms2'
                    unab varchk: `varchk', max(1)
                    if "`var`i''"=="`varchk'" {
                        local found "yes"
                        local varnm2`i' = `i3'
                        local i3 = `i3_to'
                    }
                    local i3 = `i3' + 1
                }
            }
            if "`found'"=="no" {
                di in r "`var`i'' not rhs variable"
                exit 198
            }
        } /* else */
        local i = `i' + 1
    } /* while `i' <= `nvars' */

    capture matrix drop PE_in
    capture matrix drop PE_in2
    *build PE_in matrix
    local i1 = 1
    while `i1' <= `ncats1' {
        local i2 = 1
        while `i2' <= `ncats2' {
            local i3 = 1
            while `i3' <= `ncats3' {
                local i4 = 1
                while `i4' <= `ncats4' {
                    *make new row of x's for main equation
                    mat `addbase' = `tobase'
                    if `varnum1' ~= -1 {
                        local addval : word `i1' of `vals1'
                        mat `addbase'[1, `varnum1'] = `addval'
                    }
                    if `varnum2' ~= -1 {
                        local addval : word `i2' of `vals2'
                        mat `addbase'[1, `varnum2'] = `addval'
                    }
                    if `varnum3' ~= -1 {
                        local addval : word `i3' of `vals3'
                        mat `addbase'[1, `varnum3'] = `addval'
                    }
                    if `varnum4' ~= -1 {
                        local addval : word `i4' of `vals4'
                        mat `addbase'[1, `varnum4'] = `addval'
                    }
                    *add row of x's to PE_in
                    mat PE_in = nullmat(PE_in) \ `addbase'
                    *second equation (binary eq for count models)
                    if "`input'"=="twoeq" {
                        mat `addbase' = `tobase2'
                        if `varnm21' ~= -1 {
                            local addval : word `i1' of `vals1'
                            mat `addbase'[1, `varnm21'] = `addval'
                        }
                        if `varnm22' ~= -1 {
                            local addval : word `i2' of `vals2'
                            mat `addbase'[1, `varnm22'] = `addval'
                        }
                        if `varnm23' ~= -1 {
                            local addval : word `i3' of `vals3'
                            mat `addbase'[1, `varnm23'] = `addval'
                        }
                        if `varnm24' ~= -1 {
                            local addval : word `i4' of `vals4'
                            mat `addbase'[1, `varnm24'] = `addval'
                        }
                        *add row of x's to PE_in
                        mat PE_in2 = nullmat(PE_in2) \ `addbase'
                    } /* if "`input'"=="twoeq" */
                    local i4 = `i4' + 1
                } /* while `i4' <= `ncats4' */
                local i3 = `i3' + 1
            } /* while `i3' <= `ncats3' */
            local i2 = `i2' + 1
        } /* while `i2' <= `ncats2' */
        local i1 = `i1' + 1
    } /* while `i1' <= `ncats1' */
    if "`output'"=="count" {
        if "`outcome'"!="" { local maxcnt "maxcnt(`outcome')" }
        else { local maxcnt "maxcnt(0)" }
    }

    _pepred, `maxcnt'
    *note: the way the command is now: it requires -two- preserves
    *one here and one in _pepred. This could be improved...
    preserve
    qui gen `added' = 0
    local newobs = rowsof(PE_in)
    local oldn = _N
    local newn = `oldn'+`newobs'
    qui set obs `newn'
    qui replace `added' = 1 if `added' == .
    local i = 1
    while `i' <= `nrhs' {
        local varname : word `i' of `rhsnms'
        local i2 = 1
        while `i2' <= `newobs' {
            local to_rep = `oldn' + `i2'
            sca `replval' = PE_in[`i2',`i']
            qui replace `varname' = `replval' in `to_rep'
            local i2 = `i2' + 1
        }
        local i = `i' + 1
    }

    if "`nrhs2'"!="" {
        local i = 1
        while `i' <= `nrhs2' {
            local varname : word `i' of `rhsnms2'
            local i2 = 1
            while `i2' <= `newobs' {
                local to_rep = `oldn' + `i2'
                sca `replval' = PE_in2[`i2',`i']
                qui replace `varname' = `replval' in `to_rep'
                local i2 = `i2' + 1
            }
            local i = `i' + 1
        }
    }

    di _n in y "`e(cmd)'" in g ": Predicted " _c
    if "`output'"=="binary" {
        local r_toget "p1"
        local fmt "%6.4f"
        if "`brief'"=="" { di in g "probabilities of positive outcome" _c }
    }
    if "`output'"=="regress" {
        local r_toget "xb"
        local fmt "%8.0g"
        if "`brief'"=="" { di in g "values" _c }
    }
    if "`output'"=="tobit" {
        local r_toget "xb"
        local fmt "%8.0g"
        if "`brief'"=="" { di in g "values of y*" _c }
    }
    if "`output'"=="count" & (`iszt'!=1) {
        if "`outcome'"=="" {
            local r_toget "mu"
            local fmt "%8.4f"
            if "`brief'"=="" { di in g "rates" _c }
        }
        if "`outcome'"!="" {
            local r_toget "p`outcome'"
            local fmt "%6.4f"
            if "`brief'"=="" {
                di in g "probabilities of count = `outcome'" _c
            }
        }
    }

    * zero truncated models 19Feb2005
    if `iszt'==1 {
            if "`conditional'"=="" {
                local type "unconditional"
            }
            else {
                local type "conditional"
            }
        if "`outcome'"=="" {
            if "`conditional'"=="" {
                local r_toget "mu"
            }
            else {
                local r_toget "Cmu"
            }
            local fmt "%8.4f"
            if "`brief'"=="" { di in g "`type' rates" _c }
        }
        if "`outcome'"!="" {
            local r_toget "p`outcome'"
            if "`conditional'"=="" {
                local r_toget "p`outcome'"
            }
            else {
                local r_toget "Cp`outcome'"
            }
            local fmt "%6.4f"
            if "`brief'"=="" {
                di in g "`type' probabilities of count = `outcome'" _c
            }
        }
    }

    if "`output'"=="ordered" | "`output'"=="mlogit" {
        local fmt "%6.4f"
        if "`outcome'"=="" {
            local do_all "yes"
            local do_allc = 1
            if "`brief'"=="" { di in g "probabilities" _c }
        }
        else {
            if "`brief'"=="" {
                di in g "probabilities of outcome `outcmv' `outcmnm'" _c
            }
            local r_toget "p`outcome'"
        }
    }

    di in g " for " in y "`e(depvar)'"

**  #5 TRANSLATE EVERYTHING INTO TEMPORARY VARIABLES

    tempvar tmpvar1 tmpvar2 tmpvar3 tmpvar4
    local count = 1
    while `count' <= `nvars' {
        qui gen `tmpvar`count'' = `var`count'' if `added' == 1
        label variable `tmpvar`count'' "`var`count''"
        if "`nolabel'"!="nolabel" {
            local lblnam1 : value label `var`count''
            if "`lblnam1'"!="" { label values `tmpvar`count'' `lblnam1' }
        }
        if "`novarlbl'"!="novarlbl" {
            local lblnam2 : variable label `var`count''
            if "`lblnam2'"!="" { label variable `tmpvar`count'' "`lblnam2'" }
        }
        local count = `count' + 1
    }

    *make lists of temporary variables for tabdisp
    local count = 1
    local countto : word count `varnoby'
    while `count' <= `countto' {
        local tmpxxx = "`tmpvar`count''"
        local tmpnoby = "`tmpnoby'`tmpxxx' "
        local count = `count' + 1
    }
    if "`by'" != "" {
        local tmpby = "`tmpvar`nvars''"
    }

**  #6 DISPLAY OUTPUT
    *doneyet needed if tables needed for multiple categories (e.g. oprobit)
    local doneyet "no"
    while "`doneyet'"=="no" {
        if "`do_all'"=="yes" {
            local r_toget = "p`do_allc'"
            local outcmv : word `do_allc' of `catvals'
            local outcmnm : word `do_allc' of `catnms'
            if "`outcmnm'"!="`outcmv'" {
                di _n in gr "Predicted probability of outcome " /*
                */ "`outcmv' (`outcmnm')"
            }
            else { di _n in gr "Predicted probability of outcome `outcmv'" }
        }
        qui gen `cell' = .
        mat `temp' = r(`r_toget')
        local i = 1
        while `i' <= `newobs' {
            local to_rep = `oldn' + `i'
            sca `replval' = `temp'[`i', 1]
            qui replace `cell' = `replval' in `to_rep'
            local i = `i' + 1
        }
        if "`by'" != "" { local by4 "by(`tmpby')" }
        label variable `cell' "Prediction"
        tabdisp `tmpnoby' if `added'==1, c(`cell') `by4' f(`fmt')
        if "`do_all'"=="yes" {
            local do_allc = `do_allc' + 1
            if `do_allc' > `ncats' { local doneyet "yes" }
            else { drop `cell' }
        }
        else { local doneyet "yes" }

    } /* while "`doneyet'" = "no" */

    *print base values if desired
    if "`brief'"=="" & "`base'"!="nobase" {
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
*  version 1.6.0 1/11/01
*  version 1.6.1 19Feb2005 zt
*  version 1.6.2 27Mar2005 slogit
*  version 1.6.3 13Apr2005
