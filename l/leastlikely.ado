*! 1.0.2 - 9/28/02 - Jeremy Freese
capture program drop leastlikely
program define leastlikely
    version 7.0

    syntax [varlist(default=none)] [if] [in] [, n(integer 5) Generate(string) *]

    if "`e(cmd)'"=="clogit" | "`e(cmd)'"=="nlogit" | "`e(cmd)'"=="xtlogit" | /*
    */ "`e(cmd)'"=="blogit" | "`e(cmd)'"=="bprobit" | "`e(cmd)'"=="glogit" | /*
    */ "`e(cmd)'"=="gprobit" {
        di _n as err "leastlikely not intended for use after `e(cmd)'"
        exit 198
    }

    local erase "no"
    tempname values prob touse
    local depvar = "`e(depvar)'"
    local depvarlabel : value label `depvar'
    if "`generate'"=="" {
        local generate "Prob"
        local erase "yes"
    }
    quietly {
        gen `touse' = e(sample) `if' `in'
        gen `prob' = .
        tabulate `depvar' if e(sample)==1, matrow(`values')
        local temp : rownames `values'
        local numcats : word count `temp'
        forvalues i = 1(1)`numcats' {
            local value`i' = `values'[`i', 1]
        }
        local isbin "no"
        if `numcats'==2 & `value1'==0 & `value2'==1 { local isbin "yes" }
        if "`isbin'" == "yes" {
            tempname temp
            predict `temp', p
            replace `prob' = `temp' if `depvar'==1 & `touse'==1
            replace `prob' = (1-`temp') if `depvar'==0 & `touse'==1
        }
        if "`isbin'" == "no" {
            forvalues i = 1(1)`numcats' {
                tempname temp
                predict `temp', outcome(`value`i'')
                replace `prob' = `temp' if `depvar'==`value`i'' & `touse'==1
            }
        }
        gen `generate' = `prob'
    }

    forvalues i = 1(1)`numcats' {
        local vallabel ""
        if "`depvarlabel'"!="" {
            local vallabel : label `depvarlabel' `value`i''
            if "`vallabel'"!="" { local vallabel = "(`vallabel')" }
        }
        di _n as txt "Outcome: " as res `value`i'' " `vallabel'"

        tempname temp
        quietly egen `temp' = rank(`generate') if `depvar'==`value`i'' & `touse'==1, track
        list `generate' `varlist' if `temp'<=`n' , `options'
    }

    if "`erase'"=="yes" { drop `generate' }

end

