*! 1.0.1 - allow either y() or choice(); yrank() or rank()
* 1.0.0 - revise option names: case->casevar; id->case
* 0.2.4 - small text formatting error
* 0.2.3 - change _optnum to altnum and add as option
* 0.2.2 - allow id() to specify new variable instead of using _id - 15Jul2005
* 0.2.1 - change specification of csv from varlist to case() - 11Jul2005

program define case2alt

    version 9

    syntax , [y(varname numeric) YRank(name) case(name) ///
        Generate(name) REplace CASEVars(namelist) Alt(namelist) noNames altnum(name) ///
        Choice(name) Rank(name)] // allow choice() and rank() to sub for y() and yrank()

    ** CHANGE 9/8/05: allow choice() instead of y() and allow rank() instead of yrank()
    if "`choice'" != "" {
        local y "`choice'"
        local choice ""
    }

    if "`rank'" != "" {
        local yrank "`rank'"
        local rank ""
    }


    * either y() or yrank() must be specified
    if "`y'" == "" & "`yrank'" == "" {
        di as err "option y() or yrank() must be specified"
        exit 198
    }

    * figure out if rankdata is being specified
    local rankdata "yes"
    if "`y'" != "" {
        local rankdata "no"
    }

    if "`rankdata'" == "no" & "`generate'" == "" & "`replace'" == "" {
        di as txt "(note: " as res "choice " as txt "used for outcome since no variable specified by gen())"
        confirm new variable choice
        local generate "choice"
    }
    local choice "`generate'"

    if "`case'" == "" {
        di as txt "(note: variable " as res "_id" as txt " used since case() not specified)"
        confirm new variable _id
        gen _id = _n
        local case "_id"
    }

    if "`altnum'" == "" {
        di as txt "(note: variable " as res "_altnum" as txt " used since altnum() not specified)"
        confirm new variable _altnum
        local altnum "_altnum"
    }

    capture confirm variable `case'
    if _rc != 0 {
        gen `case' = _n
    }


    if "`rankdata'" == "no" {
        _pecats `y'

        local catval = r(catvals)
        local catnms = r(catnms)
        local numcats = r(numcats)

        forvalues i = 1(1)`numcats' {
            local y`i' : word `i' of `catval'
            local ynm`i' : word `i' of `catnms'
            confirm integer number `y`i''
            gen _ytemp`y`i'' = 1
        }

        local ytemp "_ytemp"
    }

    if "`rankdata'" == "yes" {
        capture label drop `altnum'
        foreach rvar of varlist `yrank'* {
            local rvarnum = subinstr("`rvar'", "`yrank'", "", 1)
            local rvarnumchk = real("`rvarnum'")
            if "`rvarnum'" == "`rvarnumchk'" {
                local rvarlabel : variable label `rvar'
                label define `altnum' `rvarnum' "`rvarlabel'", modify
            }
        }
    }

    qui reshape long `ytemp' `yrank' `alt', i(`case') j(`altnum')

    capture drop _ytemp

    if "`rankdata'" == "no" {

        tempvar ychosen
        gen `ychosen' = `y'

        if "`replace'" == "replace" {
            drop `y'
            local choice "`y'"
        }

        gen `choice' = (`altnum' == `ychosen') if `altnum' < .

    }

    if "`rankdata'" == "yes" {
        label define `altnum', modify
        label values `altnum' `altnum'
        _pecats `altnum'

        local catval = r(catvals)
        local catnms = r(catnms)
        local numcats = r(numcats)

        forvalues i = 1(1)`numcats' {
            local y`i' : word `i' of `catval'
            local ynm`i' : word `i' of `catnms'
            confirm integer number `y`i''
        }

        * if generate option specified, rename stub to that
        if "`generate'" != "" {
            rename `yrank' `generate'
            local yrank "`generate'"
        }

    }

    forvalues i = 1(1)`numcats' {
        local name = "y`y`i''"
            if "`names'" != "nonames" & "`ynm`i''" != "`y`i''" {
                local name "`ynm`i''"
            }
        qui gen ytemp`y`i'' = (`altnum' == `y`i'') if `altnum' < .
        label variable ytemp`y`i'' "`ynm`i''"
        if "`casevars'" != "" {
            foreach var of varlist `casevars' {
                qui gen `name'X`var' = `var' * ytemp`y`i''
            }
        }
        local ylist "`ylist' `name'*"
        clonevar `name' = ytemp`y`i''
        drop ytemp`y`i''
    }

    * output

    if "`rankdata'" == "no" {
        di _n as txt "choice indicated by:" as res " `choice'"
    }
    if "`rankdata'" == "yes" {
        di _n as txt "ranks indicated by:" as res " `yrank'"
    }
    di as txt "case identifier:" as res " `case'"
    di as txt "case-specific interactions:" as res "`ylist'"
    if "`alt'" != "" {
        di as txt "alternative-specific variables:" as res " `alt'"
    }

end
