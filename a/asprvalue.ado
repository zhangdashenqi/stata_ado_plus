*! 0.3.2 2009-03-14 | long freese | fix mean calculation

** predictions for asmprobit

capture program drop asprvalue
capture program drop _Prvasmp
program define asprvalue, rclass

version 9

    if e(cmd) == "asmprobit" {
        _Prvasmp `0' // local program just for asmprobit -- see below
        return add
        exit
    }

    preserve

    syntax [, x(passthru) Cat(string) Base(string) Save Diff Rest(string) BRief Full]

    * need to sort to calculate means below so accurate for unbalanced panels
    local idvar "`e(group)'"
    tempname recordnum
    sort `idvar', stable
    by `idvar' : gen `recordnum' = _n

    tempname b
    mat `b' = e(b)
    local allnames : colnames `b'

    * check if there are any interactions, so that otherwise warning message can be specified
    local anyX "no"

    * make list of case-specific variables
    foreach var of local allnames {
        local i = index("`var'", "X")
        if `i' != 0 {
            local anyX "yes"
        * is it an alternativeXcase-specific-variable interaction?
            local temppreX = substr("`var'", 1, `i'-1)
            local temppostX = substr("`var'", `i'+1, .)
            * assume that preX are all cats -- TO DO: insert check?
            local catslist "`catslist' `temppreX'"
            local isAxA "no"
            foreach var2 of local allnames {
                if "`temppostX'"=="`var2'" | "`temppostX'"=="`base'" {
                    local isAxA "yes"
                    local aXalist "`aXalist' `var'"
                }
            }
        * is it an alternativeXalternative interaction?
            if "`isAxA'" == "no" {
                local aXclist "`aXclist' `var'"
                local csvlist "`csvlist' `temppostX'"
            }
        }
    }


    * if cat is specified, that is the list of categories
    if "`cat'"!= "" {
        local catslist = "`cat'"
    }

    * make sure either cat() or interactions specified
    if "`cat'"=="" & "`anyX'"=="no" {
        di as err "cat() must be specified if no interactions in model"
        error 999
    }

    local catslist : list uniq catslist
    local ncatsmin1 : word count `catslist'
    local numcats = `ncatsmin1' + 1
    local csvlist : list uniq csvlist

    local asvlist : list allnames - aXclist
    local asvlist : list asvlist - catslist
    local asvlist : list asvlist - aXalist

    /*
    di "altXasv interactions: `aXalist'"
    di "altXcase interactions: `aXclist'"
    di "alternatives: `catslist'"
    di "altspec vars: `asvlist'"
    di "casespec vars: `csvlist'"
    di "number of alternatives `ncatsmin1'"
    */

    * decode x() values
    tokenize `x', parse("()")
    local x "`3'"
    local x : subinstr local x "=" " ", all
    tokenize `x', parse(" ")
    while "`1'" != "" & "`2'" != "" {

        capture confirm number `3'
        if _rc == 0 {
            * TO DO: check that `1' is alternative-specific variables
            forvalues i = 1(1)`numcats' {
                local iplus1 = `i' + 1
                confirm number ``iplus1''
                local V`1'V`i' = ``iplus1''
            }
            macro shift `iplus1'
        }

        else {
            local V`1' = `2'
            macro shift 2
        }
    }

    * HANDLE REST OPTION

    * rest() = mean by default
    if "`rest'" == "" {
        local rest "mean"
    }
    *check that rest option includes an allowable option
    if "`rest'" != "mean" & "`rest'" != "asmean" {
        di as err "rest(`rest') not allowed"
        error 999
    }

    foreach var of local csvlist {
        if "`V`var''" == "" {
            if "`rest'" == "mean" | "`rest'" == "asmean" {
*                qui su `var' if e(sample) == 1 & `recordnum' == 1
                qui su `var' if e(sample) == 1 // FIX TO MEAN CALCULATION 9/2012
                local V`var' = r(mean)
            }
        }
    }

    foreach var of local asvlist {
        if "`V`var''" == "" & "`V`var'V1'" == "" {
            if "`rest'" == "mean" {
*                qui su `var' if e(sample) == 1 & `recordnum' == 1
                qui su `var' if e(sample) == 1 // FIX TO MEAN CALCULATION 9/2012
                forvalues i = 1(1)`numcats' {
                    local V`var'V`i' = r(mean)
                }
            }
            if "`rest'" == "asmean" {
                tempname refdum
                * this variable will equal 1 for only those cases that indicate base
                qui gen `refdum' = 1 if e(sample) == 1
                local i = 1
                foreach catname of local catslist {
                    qui su `var' if `catname' == 1 & e(sample) == 1
                    local V`var'V`i' = r(mean)
                    * turn off refdum for variables indicating category
                    qui replace `refdum' = 0 if `catname' == 1 & e(sample) == 1
                    local i = `i' + 1
                }
                * use refdum to get mean for reference category
                qui su `var' if `refdum' == 1 & e(sample) == 1
                local V`var'V`i' = r(mean)
            }
        }
    }

    * add observations to bottom of dataset

    local N = _N
    local firstobs = `N' + 1 // firstobs is the reference number of the first added obs
    local lastobs = `firstobs'+`ncatsmin1'

    qui set obs `lastobs'
    capture drop _addedobs
    qui gen _addedobs = 1 if _n >= `firstobs'

    * find unique value for new observations
    local unique "no"
    local i = 1234567
    while "`unique'" == "no" {
        qui count if `idvar' == `i'
        if r(N) == 0 {
            local unique "yes"
        }
        local i = `i' + 1234567
    }
    qui replace `idvar' = `i' in `firstobs'/`lastobs'
    qui replace `idvar' = `i' in `firstobs'/`lastobs'

    foreach cat of local catslist {
        local obs = `firstobs'
        foreach cat2 of local catslist {

            * set dummy variables indicating which row is which alternative
            qui replace `cat' = 1 in `obs' if "`cat'" == "`cat2'"
            qui replace `cat' = 0 in `obs' if "`cat'" != "`cat2'"

            * set values for aXc interactions
            foreach csvar of local csvlist {
                qui replace `cat'X`csvar' = `V`csvar'' in `obs' if "`cat'" == "`cat2'"
                qui replace `cat'X`csvar' = 0 in `obs' if "`cat'" != "`cat2'"
            }

            local obs = `obs' + 1
        }

        * set all alternative dummies to zero for row indicating reference category
        qui replace `cat' = 0 in `obs'

        * set all aXc to zero for row corresponding to reference category
        foreach csvar of local csvlist {
            qui replace `cat'X`csvar' = 0 in `obs'
        }

    }

    * set values for alternative-specific variables
        foreach alt of local asvlist {
            if "`V`alt''" != "" {
                qui replace `alt' = `V`alt'' in `firstobs'/`lastobs'
            }
            else {
                forvalues i = 1(1)`numcats' {
                    local obs = `firstobs' + `i' - 1
                    qui replace `alt' = `V`alt'V`i'' in `obs'
                }
            }
        }

    * set values for aXa interactions
        foreach var of local aXalist {
            local i = index("`var'", "X")
            local temppreX = substr("`var'", 1, `i'-1)
            local temppostX = substr("`var'", `i'+1, .)
            qui replace `var' = `temppreX'*`temppostX' if _addedobs == 1
        }

    * generate predicted probabilities
        tempname prob

    * 5/26/06 WORKAROUND FOR STATA BUG (?!) WHERE PREDICT RESORTS DATA
        tempname order
        gen `order' = _n
        qui predict `prob' if _addedobs == 1
        sort `order'

        * reference category name
        if "`base'" == "" {
            local base = "base"
        }

* DISPLAY RESULTS
* heading

        local ecmd "`e(cmd)'"
        local edepvar "`e(depvar)'"
        di _n as res "`ecmd'" as txt ": Predictions for " as res "`edepvar'"

* display predicted probabilities

    local obs = `firstobs'
    capture mat drop asprvres
    tempname tmpprob

    foreach cat of local catslist {
        sca `tmpprob' = `prob'[`obs']

        mat asprvres = (nullmat(asprvres) \ `tmpprob')

        local obs = `obs' + 1
    }
    sca `tmpprob' = `prob'[`obs']
    mat asprvres = (nullmat(asprvres) \ `tmpprob')

    mat rownames asprvres = `catslist' `base'
    mat colnames asprvres = prob

    if "`diff'" != "" {
        mat changesav = asprvres - _ASPRVsav
        tempname display
        mat `display' = (asprvres, _ASPRVsav, changesav)
        mat colnames `display' = Current Saved Diff
        mat list `display', noh
    }
    else {
        mat list asprvres, noh
    }

* display base values for case-specific variables

    if "`csvlist'" != "" {
        capture mat drop csvals
        foreach var of local csvlist {
            mat csvals = (nullmat(csvals) , `V`var'')
        }
        mat colnames csvals = `csvlist'
        mat rownames csvals = x=

        if "`brief'" == "" {
            di _n as txt "case-specific variables"

            if "`diff'" != "" {
                mat changecsv = csvals - _ASPRVcsv
                tempname displaycsv
                mat `displaycsv' = (csvals \ _ASPRVcsv \ changecsv)
                mat rownames `displaycsv' = Current Saved Diff
                mat list `displaycsv', noh
            }
            else {
                mat list csvals, noh
            }
        }

    }

* display base values for alternative-specific variables

    if "`asvlist'" != "" {
        capture mat drop asvals
        foreach alt of local asvlist {
        capture mat drop _tmp
            if "`V`alt''" != "" {
                mat _tmp = J(1, `numcats', `V`alt'')
            }
            else {
                forvalues i = 1(1)`numcats' {
                    mat _tmp = (nullmat(_tmp) , `V`alt'V`i'')
                }
            }
            mat asvals = (nullmat(asvals) \ _tmp)
        }
        mat rownames asvals = `asvlist'
        mat colnames asvals = `catslist' `base'

        if "`brief'" == "" {
            di _n as txt "alternative-specific variables"

            if "`diff'" != "" {

                tempname curasv
                mat `curasv' = asvals

                tempname savedasv
                mat `savedasv' = _ASPRVasv
                mat changeasv = asvals - `savedasv'

                mat roweq `curasv' = Current
                mat roweq `savedasv' = Saved
                mat roweq changeasv = Dif

                tempname displayasv
                mat `displayasv' = (`curasv' \ `savedasv' \ changeasv)
                mat list `displayasv', noh
            }
            else {
                mat list asvals, noh
            }
        }
    }

* display all added observations and values if desired

    if "`full'" != "" {
        list `allnames' if _addedobs == 1, noobs
    }

    if "`save'" != "" {
        mat _ASPRVsav = asprvres
        if "`csvlist'" != "" {
            mat _ASPRVcsv = csvals
        }
        if "`asvlist'" != "" {
            mat _ASPRVasv = asvals
        }
    }

* return results
    if "`diff'" != "" {                                             //! added bj 24jul2008
        capture return matrix p = changesav, copy                   //!
        capture return matrix csv = changecsv, copy                 //!
        capture return matrix asv = changeasv, copy                 //!
    }                                                               //!
    else {                                                          //!
        capture return matrix p = asprvres, copy
        capture return matrix csv = csvals, copy
        capture return matrix asv = asvals, copy
    }                                                               //!

restore

end

program define _Prvasmp, rclass

version 9

preserve

    syntax [, x(passthru) Cat(string) Base(string) Save Diff Rest(string) BRief Full]

    if "`cat'" != "" {
        di as err "(note: cat() ignored when using asprvalue with asmprobit)"
    }
    if "`base'" != "" {
        di as err "(note: base() ignored when using asprvalue with asmprobit)"
    }

    local altvar = e(altvar)

    local numcats = e(k_alt)
    local asvlist "`e(indvars)'"
    local csvlist "`e(ind2vars)'"
    if "`csvlist'" == "" {
        local csvlist "`e(casevars)'"
    }
    local idvar "`e(casevar)'"
    if "`idvar'" == "" {
        local idvar "`e(case)'"
    }

    * need to sort to calculate means below so accurate for unbalanced panels
    tempname recordnum
    sort `idvar', stable
    by `idvar' : gen `recordnum' = _n


    * add values to bottom of dataset

    local N = _N
    local firstobs = `N' + 1
    local lastobs = `firstobs' + `numcats' - 1

    qui set obs `lastobs'
    capture drop _addedobs
    qui gen _addedobs = 1 if _n >= `firstobs'

    * find unique value for new observations
    local unique "no"
    local i = 1234567
    while "`unique'" == "no" {
        qui count if `idvar' == `i'
        if r(N) == 0 {
            local unique "yes"
        }
        local i = `i' + 1234567
    }
    qui replace `idvar' = `i' in `firstobs'/`lastobs'

    * write values for alternative variable with values of alternatives
    _pecats `altvar' if e(sample)

    local catvals "`r(catvals)'"
    forvalues i = 1(1)`numcats' {
        local cat`i' : word `i' of `catvals'
        local catslist "`catslist' `e(alt`i')'"

        local obsnum = `firstobs' + `i' - 1
        qui replace `altvar' = `cat`i'' in `obsnum'
    }

    * decode x() values
    tokenize `x', parse("()")
    local x "`3'"
    local x : subinstr local x "=" " ", all
    tokenize `x', parse(" ")
    while "`1'" != "" & "`2'" != "" {

        * if `3' exists and is a number, alternative-specific variables being specified
        capture confirm number `3'
        if _rc == 0 {
            * TO DO: check that `1' is alternative-specific variable
            forvalues i = 1(1)`numcats' {
                local iplus1 = `i' + 1
                confirm number ``iplus1''
                local V`1'V`i' = ``iplus1''
            }
            macro shift `iplus1'
        }

        else {
            local V`1' = `2'
            macro shift 2
        }
    }

    * HANDLE REST OPTION

    * rest() = mean by default
    if "`rest'" == "" {
        local rest "mean"
    }
    *check that rest option includes an allowable option
    if "`rest'" != "mean" & "`rest'" != "asmean" {
        di as err "rest(`rest') not allowed"
        error 999
    }

    foreach var of local csvlist {
        if "`V`var''" == "" {
            if "`rest'" == "mean" | "`rest'" == "asmean" {
*                qui su `var' if e(sample) == 1 & `recordnum' == 1
                qui su `var' if e(sample) == 1 // FIX TO MEAN CALCULATION 9/2012
                local V`var' = r(mean)
            }
        }
    }

    foreach var of local asvlist {
        if "`V`var''" == "" & "`V`var'V1'" == "" {
            if "`rest'" == "mean" {
*                qui su `var' if e(sample) == 1 & `recordnum' == 1
                qui su `var' if e(sample) == 1 // FIX TO MEAN CALCULATION 9/2012
                forvalues i = 1(1)`numcats' {
                    local V`var'V`i' = r(mean)
                }
            }
            if "`rest'" == "asmean" {
                forvalues i = 1(1)`numcats' {
                    qui su `var' if `altvar' == `cat`i'' & e(sample) == 1
                    local V`var'V`i' = r(mean)
                }
            }
        }
    }

    * set values for alternative-specific variables
    foreach alt of local asvlist {
        if "`V`alt''" != "" {
            qui replace `alt' = `V`alt'' in `firstobs'/`lastobs'
        }
        else {
            forvalues i = 1(1)`numcats' {
                local obs = `firstobs' + `i' - 1
                qui replace `alt' = `V`alt'V`i'' in `obs'
            }
        }
    }

    * set values for case-specific variables
    foreach var of local csvlist {
        qui replace `var' = `V`var'' in `firstobs'/`lastobs'
    }

    * generate predicted probabilities
    tempname prob

** 5/26/06 WORKAROUND FOR STATA BUG (?!) WHERE PREDICT RESORTS DATA
    tempname order
    gen `order' = _n
    * 2008-06-15 list `order' if _addedobs == 1
    qui predict `prob' if _addedobs == 1
    sort `order'

* DISPLAY RESULTS -- whole routine almost the same as asprvalue but not quite

* heading

    local ecmd "`e(cmd)'"
    local edepvar "`e(depvar)'"
    di _n as res "`ecmd'" as txt ": Predictions for " as res "`edepvar'"

* display predicted probabilities

    local obs = `firstobs'
    capture mat drop asprvres
    tempname tmpprob
    foreach cat of local catslist {
        sca `tmpprob' = `prob'[`obs']

        mat asprvres = (nullmat(asprvres) \ `tmpprob')

        local obs = `obs' + 1
    }

    mat rownames asprvres = `catslist'
    mat colnames asprvres = prob

    if "`diff'" != "" {
        mat changesav = asprvres - _ASPRVsav
        tempname display
        mat `display' = (asprvres, _ASPRVsav, changesav)
        mat colnames `display' = Current Saved Diff
        mat list `display', noh
    }
    else {
        mat list asprvres, noh
    }

* display base values for case-specific variables

    if "`csvlist'" != "" {
        capture mat drop csvals
        foreach var of local csvlist {
            mat csvals = (nullmat(csvals) , `V`var'')
        }
        mat colnames csvals = `csvlist'
        mat rownames csvals = x=

        if "`brief'" == "" {
            di _n as txt "case-specific variables"

            if "`diff'" != "" {
                mat changecsv = csvals - _ASPRVcsv
                tempname displaycsv
                mat `displaycsv' = (csvals \ _ASPRVcsv \ changecsv)
                mat rownames `displaycsv' = Current Saved Diff
                mat list `displaycsv', noh
            }
            else {
                mat list csvals, noh
            }
        }
    }

* display base values for alternative-specific variables

    if "`asvlist'" != "" {
        capture mat drop asvals
        foreach alt of local asvlist {
        capture mat drop _tmp
            if "`V`alt''" != "" {
                mat _tmp = J(1, `numcats', `V`alt'')
            }
            else {
                forvalues i = 1(1)`numcats' {
                    mat _tmp = (nullmat(_tmp) , `V`alt'V`i'')
                }
            }
            mat asvals = (nullmat(asvals) \ _tmp)
        }
        mat rownames asvals = `asvlist'
        mat colnames asvals = `catslist'

        if "`brief'" == "" {
            di _n as txt "alternative-specific variables"

            if "`diff'" != "" {

                tempname curasv
                mat `curasv' = asvals

                tempname savedasv
                mat `savedasv' = _ASPRVasv
                mat changeasv = asvals - `savedasv'

                mat roweq `curasv' = Current
                mat roweq `savedasv' = Saved
                mat roweq changeasv = Dif

                tempname displayasv
                mat `displayasv' = (`curasv' \ `savedasv' \ changeasv)
                mat list `displayasv', noh
            }
            else {
                mat list asvals, noh
            }
        }
    }

* display all added observations and values if desired

    if "`full'" != "" {
        list `allnames' if _addedobs == 1, noobs
    }

    if "`save'" != "" {
        mat _ASPRVsav = asprvres
        if "`csvlist'" != "" {
            mat _ASPRVcsv = csvals
        }
        if "`asvlist'" != "" {
            mat _ASPRVasv = asvals
        }
    }

* return results
capture return matrix p = asprvres, copy
capture return matrix csv = csvals, copy
capture return matrix asv = asvals, copy

restore

end

exit

* 0.2.0 - jf - 5/26/06 - workaround for bug in Stata where predict resorts
* 0.1.9 - jf - 12/19/05 - add returns
* 0.1.8 - jf - 9/8/05 - warning but not error with cat() or base() with asmprobit
* 0.1.7 - jf - 7/24/05 - fix asmean for asmprobit bug
* 0.1.6 - jf - 7/19/05 - add heading to output
* 0.1.5 - jf - 7/18/05 - bug fix
* 0.1.4 - jf - 7/15/05 - add asmprobit (kludgy) - jf
* 0.1.3 - jf - 7/15/05 - fix to allow = in x()
* 0.1.2 - jf - 7/11/05 - bug fix
* 0.1.1 - jf - 6/15/05 - change refcat() to base()
* 0.1.0 - jf - 6/11/05
* 0.2.1 - jf - 7/2/07 - fix for changes in stata 7 asmprobit routine
* 0.3.0a - bj 24jul2008 for work with estout
* 0.3.0 2008-06-15 jsl
* 0.3.1 2009-03-14
