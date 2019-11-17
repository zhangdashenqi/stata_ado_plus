*! version 1.1.0 2009-12-22 
*   - add extended missing values - s. rohrman

capture program drop misschk
program define misschk
    version 9.0 // 2009-12-22
    syntax [varlist] [if] [in] ///
            ,   [GENerate(string)]  /// stub for indicator variables
                [dummy]             /// dummy indicator variables
                [replace]           /// replace variables if they exist
                [NONUMber]          /// . in table for missing, not #
                [NOSort]            /// Don't sort pattern list
                [help]              /// explain what is going on
                [SPace]             /// blank rather than _ if not missing
                [EXTmiss]           //  show extended missing // 1.1.0

    tempvar ifin
    mark `ifin' `if' `in'

    local notmissstr "_"
    if ("`space'"=="space") {
        local notmissstr " "
        }
    else if "`nonumber'"=="nonumber" | "`extmiss'"=="extmiss" { // 1.1.0
        local notmissstr "-"
    }
    local sort "sort"
    if "`nosort'"=="nosort" {
        local sort ""
    }

//  using extmiss and nonumber options together = error // 1.1.0
    
    if "`nonumber'"=="nonumber" & "`extmiss'"=="extmiss" {
        di in red "Error: cannot use nonumber and extmiss options together."
        exit
    }

//  if dummy variable option

    if "`dummy'"~="" {
        if "`generate'"=="" {
            di in red "Error: dummy options requires use of generate option."
            exit
        }
        capture label def lmisschk 0 NotMissing 1 Missing
    }
    local gennm = "`generate'"

//  information on individual variables

    di _n in g "Variables examined for missing values"
    if "`if'" ~="" | "`in'"~="" {
        di in g "For sample defined by: " in y "`if' `in'"
    }

//  strip off string variables

    parse "`varlist'", parse(" ")
    local vars
    while "`1'" != ""  { // loop through variables
        capture confirm numeric variable `1'
        if _rc==0 {
            local vars "`vars' `1'"
        }
        mac shift
    }

    local varlist "`vars'"
    parse "`varlist'", parse(" ")

    local nvar = 0

    di _n in g "   #  Variable        # Missing   % Missing"
    di    in g "--------------------------------------------"

    quietly tab `ifin'
    local total = r(N)

    while "`1'" != ""  { // loop through variables
        local ++nvar
        qui count if `1'>=. & `ifin' // count missing; changed == 1.1.0
        * create binary variables indicating if observation is missing
        if "`dummy'"~="" {
            if "`replace'"=="replace" {
                capture drop `gennm'`1'
            }
            quietly gen `gennm'`1' = (`1'>=.) if `ifin' // changed == 1.1.0
                label var `gennm'`1' "Missing value for `1'?"
                label val `gennm'`1' lmisschk
        }
        * list # and percent missing
        di in y %3.0f "   `nvar' " _col(7) "`1'" ///
            _col(23) %7.0f r(N) _col(36) %6.1f 100*r(N)/`total'
        mac shift

    } // loop through list of variables

    parse "`varlist'", parse(" ")

//  loop through all variables and count missing

    tempvar ismissn ismissw missw missn
    quietly gen `missn' = 0 if `ifin'
    label var `missn' "Missing for how many variables?"
    quietly gen str1 `missw' = "" if `ifin'
    label var `missw' "Missing for which variables?"

    local nvar = 0
    local i = 0
    local ext "a b c d e f g h i j k l m n o p q r s t u v w x y z" // 1.1.0
    while "`1'" != ""  {
        local ++nvar
        * ones has only one's digit of variable number
        local ones = mod(`nvar',10)

        * drop tempvars from last loop
        capture drop `ismissn' `ismissw'

        * 1 if mssing, else 0; . if not in if in
        capture quietly gen `ismissn' = (`1'>=.) if `ifin' // changed == 1.1.0

        * string with indicator of missing status. Space if no missing;
        * then if missing, either . or digit number.
        capture quietly gen str1 `ismissw' = "`notmissstr'"
        if "`nonumber'"=="nonumber" & "`extmiss'"=="" { // 1.1.0
            quietly replace `ismissw' = "." if `1'>=.  & `ifin' // changed == 1.1.0
        }
        else if "`extmiss'"=="extmiss" & "`nonumber'"=="" { // changed == 1.1.0
            quietly replace `ismissw' = "." if `1'==. & `ifin'
            foreach ltr in `ext' {
                quietly replace `ismissw' = "`ltr'" if `1'==.`ltr' & `ifin'
            }
        }
        else if "`nonumber'"=="" & "`extmiss'"=="" {
            quietly replace `ismissw' = "`ones'" if `1'>=.  & `ifin' // changed == 1.1.0
        }

        * add blank every 5th variable
        if mod(`nvar'-1,5) == 0 {
            quietly replace `missw' = `missw' + " "
        }

        * build string with pattern of missing data
        quietly replace `missw' = `missw' + `ismissw'
        * count total number of missing for given case
        quietly replace `missn' = `missn' + `ismissn'
        mac shift
    }
    capture drop `ismissn' `ismissw'

//  List results

    * patterns of missing data
    if "`extmiss'"=="" { // 1.1.0
        di _n in y "Warning: " in g ///
        "this output does not differentiate among extended missing."
        di in g ///
        "To generate patterns for extended missing, use extmiss option."
    }
    if "`help'"=="help" {
        di in g _n ///
        "The columns in the table below correspond to the # in the table above."
        di in g ///
        "If a column is blank, there were no missing cases for that variable."
    }
    if "`help'"=="help" & "`extmiss'"=="extmiss" { //1.1.0
        di _n
        di _n in g ///
        "Letters in each column refer to the extended missing for the"
        di in g ///
        "corresponding variable"
    }
    tab `missw' if `ifin', `nosort'

    * number missing for given observations
    if "`help'"=="help" {
        di _n in g ///
        "Table indicates the number of variables for which an observation"
        di in g ///
        "has missing data."
    }
    tab `missn' if `ifin'

//  create variables with pattern and number of missing cases

    if "`generate'" != "" {

        if "`replace'"=="replace" {
            capture drop `gennm'pattern
            capture drop `gennm'number
        }

        clonevar `gennm'pattern = `missw'
        clonevar `gennm'number = `missn'
        if "`help'"=="help" {
        di _n in g "Variables created:" // added end quote 1.1.0
        di in y "   `gennm'pattern" in g ///
            " is a string variable showing the pattern of missing data."
        di in y "   `gennm'number" in g ///
            " is the number of variables for which a case has missing data."
        di in y "   `gennm'<varnm>" in g ///
            " is a binary variable indicating missing data for <varnm>."

        }
    }

end
exit
* version 1.0.1 06Jul2005
* version 1.0.0 13Apr2005
