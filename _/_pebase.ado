*! version 1.6.5 2007-02-08 - rest(zero)

capture program drop _pebase
program define _pebase, rclass
    version 6.0
    tempvar tmp input tmp2 peb2 xmin xmax chtest mark
    tempname tobase tobase2 b min max mean median min2 max2 mean2 median2 prev prev2

    if "`e(cmd)'"=="ztp"        { local flags "none" }
    if "`e(cmd)'"=="ztnb"       { local flags "none" }
    if "`e(cmd)'"=="logit"      { local flags "none" }
    if "`e(cmd)'"=="logistic"   { local flags "none" }
    if "`e(cmd)'"=="probit"     { local flags "none" }
    if "`e(cmd)'"=="cloglog"    { local flags "none" }
    if "`e(cmd)'"=="ologit"     { local flags "none" }
    if "`e(cmd)'"=="oprobit"    { local flags "none" }
    if "`e(cmd)'"=="gologit"    { local flags "noupper" }
    if "`e(cmd)'"=="mlogit"     { local flags "noupper" }
    if "`e(cmd)'"=="mprobit"    { local flags "noupper" }
    if "`e(cmd)'"=="slogit"     { local flags "noupper" }
    if "`e(cmd)'"=="clogit"     { local flags "noupper" }
    if "`e(cmd)'"=="poisson"    { local flags "none" }
    if "`e(cmd)'"=="nbreg"      { local flags "none" }
    if "`e(cmd)'"=="zip"        { local flags "twoeq noupper" }
    if "`e(cmd)'"=="zinb"       { local flags "twoeq noupper" }
    if "`e(cmd)'"=="tobit"      { local flags "none" }
    if "`e(cmd)'"=="intreg"     { local flags "none" }
    if "`e(cmd)'"=="cnreg"      { local flags "none" }
    if "`e(cmd)'"=="fit"        { local flags "none" }
    if "`e(cmd)'"=="regress"    { local flags "none" }
    if "`flags'"=="" {
        di in r "_pebase does not work with `e(cmd)'"
        exit 198
    }

*-> unpack flags: define relevant special features of different models

    *flag twoeq -- 2 equation model like zip or zinb
    if index("`flags'", "twoeq") == 0 { local twoeq "no" }
    else { local twoeq "yes" }
    *flag noupper -- do not allow upper and lower for rest()
    if index("`flags'", "noupper") == 0 { local noupper "no" }
    else { local noupper "yes" }

* options:
*   x: specified x variable values
*   rest: what to set remaining values to
*   choices: choices after clogit
*   all

    syntax [if] [in] [, x(passthru) rest(string) choices(varlist) all]

    *set flag because so many if zip | zinb statements
    local twoeq "no"
    if "`e(cmd)'"=="zip" | "`e(cmd)'"=="zinb" {
        local twoeq "yes"
    }

    * get names of rhs variables in models
    _perhs
    local rhsnms "`r(rhsnms)'"
    local nrhs = `r(nrhs)'
    if "`twoeq'"=="yes" {
        local rhsnms2 "`r(rhsnms2)'"
        local nrhs2 = `r(nrhs2)'
    }

    *go to _peife to see if you need to restrict the sample
    _peife `if', `all'
    local if "`r(if)'"

    * get summary statistics for models (both if zip/zinb)
    quietly _pesum `if' `in', median
    mat `min' = r(Smin)
    mat `min' = `min'[1, 2...]
    mat `max' = r(Smax)
    mat `max' = `max'[1, 2...]
    mat `mean' = r(Smean)
    mat `mean' = `mean'[1, 2...]
    mat `median' = r(Smedian)
    mat `median' = `median'[1, 2...]
*! version 1.6.5 2007-02-08 - rest(zero)
tempname zero
mat `zero' = 0*`mean'
    if "`twoeq'"=="yes" {
        quietly _pesum `if' `in', median two
        mat `min2' = r(Smin)
        mat `min2' = `min2'[1, 2...]
        mat `max2' = r(Smax)
        mat `max2' = `max2'[1, 2...]
        mat `mean2' = r(Smean)
        mat `mean2' = `mean2'[1, 2...]
*! version 1.6.5 2007-02-08 - rest(zero)
tempname zero2
mat `zero2' = 0*`mean2'
        mat `median2' = r(Smedian)
        mat `median2' = `median2'[1, 2...]
    }

    * get matrix of previous values if it exists
    local oldpe = "yes"
    local pematch = "yes"
    capture mat `prev' = PE_base
    if _rc != 0 { local oldpe "no" }
    else {
        local test1 : colnames(`prev')
        local test2 : colnames(`mean')
        if "`test1'" != "`test2'" {
            local pematch "no"
        }
        if "`twoeq'"=="yes" {
            capture mat `prev2' = PE_base2
            if _rc != 0 { local oldpe "no" }
            else {
                local test1 : colnames(`prev2')
                local test2 : colnames(`mean2')
                if "`test1'" != "`test2'" {
                    local pematch "no"
                }
            } /* else */
        } /* if "`twoeq'"=="yes" */
    } /* else */
    if "`oldpe'"=="no" { local pematch = "no" }

*=> decode x()
*   tokenize `x', parse(" =")
    tokenize `x', parse("()")
    local x "`3'"
    tokenize `x', parse(" =")

    local allnums = "yes"
    local xchngs = 0   /* number of x changes proposed */
    while "`1'" != "" {
        while "`2'"=="=" | "`2'"=="==" {
            local temp1 "`1'"
            macro shift
            local 1 "`temp1'"
        }
        if "`2'"=="" {
            di _newline in red "Odd number of arguments in x()"
            error 198
        }
        local xchngs = `xchngs' + 1
        local cvar`xchngs' "`1'"
        *make sure variable is rhs variable
        local found "no"
        local i2 = 1
        while `i2' <= `nrhs' {
            local rhschk : word `i2' of `rhsnms'
            unab 1 : `1', max(1)
            if "`1'"=="`rhschk'" {
                local found "yes"
                local cvno`xchngs' `i2'
                local i2 = `nrhs'
            }
            local i2 = `i2' + 1
        }
        *check in binary equation if zip/zinb
        if "`twoeq'"=="yes" {
            local i3 = 1
            while `i3' <= `nrhs2' {
                local rhschk : word `i3' of `rhsnms2'
                if "`1'"=="`rhschk'" {
                    local found "yes"
                    local cvn2`xchngs' `i3'
                    local i3 = `nrhs2'
                }
                local i3 = `i3' + 1
            }
        }
        if "`found'"=="no" {
            di in r "`1' not rhs variable"
            error 198
        }
        *make sure value is legal
        local cval`xchngs' "`2'"
        if "`2'"=="mean" | "`2'"=="median" | "`2'"=="min" | /*
        */  "`2'"=="max" | "`2'"=="grmean" | "`2'"=="grmedian" | /*
        */  "`2'"=="grmin" | "`2'"=="grmax" | "`2'"=="upper" | /*
        */  "`2'"=="lower" | "`2'"=="previous" | "`2'"=="old" {
            local allnums = "no"
        }
        else {
            confirm number `2'
            local cexp`xchngs' "`cvar`xchngs'' == `cval`xchngs''"
        }
        macro shift 2
    } /* while `1' != "" { */

    *set matrix to 'rest' values
    *rest default is mean
    if "`rest'" == "" { 
        local rest = "mean" 
    }

    if "`rest'"=="previous" | "`rest'"=="old" {
        mat `tobase' = `prev'
        if "`twoeq'"=="yes" { 
            mat `tobase2' = `prev' 
        }
    }

*! version 1.6.5 2007-02-08 - rest(zero)
    else if "`rest'"=="mean" | "`rest'"=="max" | "`rest'"=="min" | ///
          "`rest'"=="median" | "`rest'"=="zero" {
        mat `tobase' = ``rest''
        if "`twoeq'"=="yes" { 
            mat `tobase2' = ``rest'2' 
        }
    }


    else if "`rest'"=="grmean" | "`rest'"=="grmax" | "`rest'"=="grmin" | "`rest'"=="grmedian" {
        if "`allnums'"!="yes" {
            di in r "`rest' not allowed if x() values not all real numbers"
            exit 198
        } /* if "`allnums'"!="yes" */
        qui gen `mark' = 1 `if'
        local i = 1
        while `i' <= `xchngs' {
            qui replace `mark' = . if ~(`cexp`i'')
            local i = `i' + 1
        } /* while i <= `xchngs' */

        _pesum if `mark' == 1, median
        if "`rest'"=="grmean"   { mat `tobase' = r(Smean)   }
        if "`rest'"=="grmax"    { mat `tobase' = r(Smax)    }
        if "`rest'"=="grmin"    { mat `tobase' = r(Smin)    }
        if "`rest'"=="grmedian" { mat `tobase' = r(Smedian) }
        mat `tobase' = `tobase'[1, 2...]
        if "`twoeq'"=="yes" {
            _pesum if `mark' == 1, median two
            if "`rest'"=="grmean"   { mat `tobase2' = r(Smean)   }
            if "`rest'"=="grmax"    { mat `tobase2' = r(Smax)    }
            if "`rest'"=="grmin"    { mat `tobase2' = r(Smin)    }
            if "`rest'"=="grmedian" { mat `tobase2' = r(Smedian) }
            mat `tobase2' = `tobase2'[1, 2...]
        } /* if "`twoeq'"=="yes" */
    } /* else if "`rest'"=="grmean"... */

    else if "`rest'"=="upper" | "`rest'"=="lower" {
        if "`noupper'"=="yes" {
            di in r "rest(`rest') not permitted after `e(cmd)'"
            exit 198
        } /* if "`noupper'"=="yes" */
        capture matrix `b' = e(b)
        mat `tobase' = r(Smax)
        mat `tobase' = `tobase'[1, 2...]
        mat `xmin' = r(Smin)
        mat `xmin' = `xmin'[1, 2...]
        local nvars = colsof(`tobase')
        local i = 1
        while `i' <= `nvars' {
            if "`rest'"=="upper" & `b'[1,`i']<0 {
                mat `tobase'[1, `i'] == `xmin'[1, `i']
            }
            if "`rest'"=="lower" & `b'[1,`i']>0 {
                mat `tobase'[1, `i'] == `xmin'[1, `i']
            }
            local i = `i' + 1
        } /* while `i' <= `nvars' */

    }
    else {
        di in red "rest(`rest') not allowed"
        error 999
    }

    * set specific values of tobase and tobase2...
    local i = 1
    while `i' <= `xchngs' {
        if "`cvno`i''"!="" {
            if "`cval`i''"=="mean" | "`cval`i''"=="median" | /*
            */ "`cval`i''"=="min" | "`cval`i''"=="max" {
                mat `tobase'[1, `cvno`i''] = ``cval`i'''[1, `cvno`i'']
            }
            else if "`cval`i''"=="previous" {
                mat `tobase'[1, `cvno`i''] = `prev'[1, `cvno`i'']
            }
            else if "`cval`i''"=="upper" | "`cval`i''"=="lower" {
                if "`noupper'"=="yes" {
                    di in r "`rest' not permitted in x() after `e(cmd)'"
                    exit 198
                } /* if "`noupper'"=="yes" */
                capture matrix `b' = e(b)
                if "`cval`i''"=="upper" {
                    if `b'[1,`cvno`i'']<0 {
                        mat `tobase'[1, `cvno`i''] == `min'[1, `cvno`i'']
                    }
                    else {
                        mat `tobase'[1, `cvno`i''] == `max'[1, `cvno`i'']
                    }
                }
                if "`cval`i''"=="lower" {
                    if `b'[1,`cvno`i'']>0 {
                        mat `tobase'[1, `cvno`i''] == `min'[1, `cvno`i'']
                    }
                    else {
                        mat `tobase'[1, `cvno`i''] == `max'[1, `cvno`i'']
                    }
                }
            } /* if "`cval`i''"=="upper" | "`cval`i''"=="lower" */
            else { mat `tobase'[1, `cvno`i''] = `cval`i'' }
        } /* if "`cvno`i'"!="" */

        if "`cvn2`i''"!="" {
            if "`cval`i''"=="mean" | "`cval`i''"=="median" /*
            */ | "`cval`i''"=="min" | "`cval`i''"=="max" {
                mat `tobase2'[1, `cvn2`i''] = ``cval`i'''[1, `cvn2`i'']
            }
            else if "`cval`i''"=="previous" {
                mat `tobase2'[1, `cvn2`i''] = `prev'[1, `cvn2`i'']
            }
            else { mat `tobase2'[1, `cvn2`i''] = `cval`i'' }
        } /* if "`cvn2`i'"!="" */

    local i = `i' + 1
    } /* while i <= `xchngs' */

    if "`choices'"!="" { return local choices `choices' }
    mat rownames `tobase' = x
    mat PE_base = `tobase'
    return matrix pebase `tobase'
    return local nrhs "`nrhs'"
    return local rhsnms "`rhsnms'"
    if "`twoeq'"=="yes" {
        mat rownames `tobase2' = x_eq2
        mat PE_base2 = `tobase2'
        return matrix pebase2 `tobase2'
        return local nrhs2 "`nrhs2'"
        return local rhsnms2 "`rhsnms2'"
    }
end

exit

*History
* version 1.6.4 13Apr2005
* version 1.6.3 27Mar2005 slogit
* version 1.6.2 28Feb2005 mprobit
* version 1.6.1 18Feb2005 ztp & ztnb
* version 1.6.0 3/29/01
