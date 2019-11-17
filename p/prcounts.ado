*! version 1.6.8 13Apr2005
*  version 1.6.7 18Feb2005 ztp and ztnb
*  version 1.6.6 8/20/03
*  version 1.6.5 1/10/01

capture program drop prcounts
program define prcounts
    version 6.0
    tempname b alpha ai gai mu
    syntax newvarname [if] [in] [, Max(integer 9) Plot]

*=> classify each valid type of model
    local cmd = e(cmd)
    *zt 18Feb2005
    if "`cmd'"=="nbreg" | "`cmd'"=="poisson" | /*
    */ "`cmd'"=="zinb"  | "`cmd'"=="zip"     | /*
    */ "`cmd'"=="ztp"   | "`cmd'"=="ztnb"    {
    }
    else {
        di
        di in r "prcounts does not work for the last type of model estimated."
        exit
    }
    if `max' > 99 | `max' < 0 {
        di in r "max() must be in range from 0 to 99"
        exit 198
    }
    local stem "`varlist'"
    local stem = substr("`stem'", 1, 28)
    cap version 7
        if _rc!=0 { local stem = substr("`stem'", 1, 4) }
    version 6.0
    local modelis "from `cmd'"

*-> GENERATE PREDICTED RATE
    quietly predict `stem'rate `if' `in', n
    label variable `stem'rate "Predicted rate `modelis'"
    gen `mu' = `stem'rate

    *18Feb2005
    * compute conditional mu
    if  "`cmd'"=="ztp"   | "`cmd'"=="ztnb"  {
        quietly predict `stem'Crate `if' `in', cm
        label variable `stem'Crate "Predicted conditional rate `modelis'"
    }

*-> GENERATE PREDICTED FREQUENCY OF ALWAYS ZERO
    if "`cmd'"=="zip" | "`cmd'"=="zinb" {
        quietly predict `stem'all0 `if' `in', p
        label variable `stem'all0 "Pr(always 0) `modelis'"
        * predict n, n computes: exp(x*beta)*(1-all0).
        * The last term needs to be removed.
        quietly replace `mu' = `mu'/(1-`stem'all0) `if' `in'
    }

*-> TAKE CARE OF ALPHA
    *18Feb2005
    if "`cmd'"=="nbreg" | "`cmd'"=="ztnb" {
        sca `alpha' = e(alpha)
    }
    if "`cmd'"=="zinb" {
        mat `b' = e(b)
        local temp = colsof(`b')
        sca `alpha' = `b'[1, `temp']
        sca `alpha' = exp(`alpha')
    }
    *18Feb2005
    if "`cmd'"=="nbreg" | "`cmd'"=="zinb" | "`cmd'"=="ztnb" {
        sca `ai' = 1/`alpha'
        sca `gai' = exp(lngamma(`ai'))
        if `gai'==. {
            di in r "problem with alpha prevents" /*
            */ " estimation of predicted probabilities."
            exit 198
        }
    }

*-> GENERATE PREDICTED PROBABILITIES
    local i 0
    while `i' <= `max' {
        local newvar "`stem'pr`i'"
        *18Feb2005
        if "`cmd'"=="poisson" | "`cmd'"=="ztp" {
            quietly gen `newvar' = /*
            */ ((exp(-`mu'))*(`mu'^`i'))/(round(exp(lnfact(`i'))), 1) /*
            */ `if' `in'
        }
        *18Feb2005
        if "`cmd'"=="nbreg" | "`cmd'"=="ztnb" {
            quietly gen `newvar' = /*
            */ (exp(lngamma(`i'+`ai')) / /*
            */ (round(exp(lnfact(`i')),1) * exp(lngamma(`ai')))) /*
            */ * ((`ai'/(`ai'+`mu'))^`ai') * ((`mu'/(`ai'+`mu'))^`i') /*
            */ `if' `in'
        }
        if "`cmd'"=="zip" {
            quietly gen `newvar' = (1-`stem'all0)*((exp(-`mu')) /*
            */ * (`mu'^`i'))/(round(exp(lnfact(`i'))), 1) `if' `in'
            if `i'==0 {
                quietly replace `newvar' = `newvar' + `stem'all0 `if' `in'
            }
        }
        if "`cmd'"=="zinb" {
            quietly gen `newvar' = (1-`stem'all0)*(exp(lngamma(`i'+`ai')) /*
            */ / ( round(exp(lnfact(`i')),1) * exp(lngamma(`ai')) )  ) /*
            */ * ((`ai'/(`ai'+`mu'))^`ai') * ((`mu'/(`ai'+`mu'))^`i') /*
            */ `if' `in'
            if `i'==0 {
                quietly replace `newvar' = `newvar' + `stem'all0 `if' `in'
            }
        }
        label variable `newvar' "Pr(y=`i') `modelis'"
        local i = `i' + 1
    }

*spost9 zt needs to compute conditional probabilities 19feb2005
*-> GENERATE CONDITIONAL PREDICTED PROBABILITIES
if "`cmd'"=="ztp" | "`cmd'"=="ztnb" {
    local i 1
    while `i' <= `max' {
        local newvar "`stem'Cpr`i'"
        quietly gen `newvar' = `stem'pr`i'/(1-`stem'pr0)
        label variable `newvar' "Pr(y=`i'|y>0) `modelis'"
        local i = `i' + 1
    }
} /// zt

*-> GENERATE CUMULATIVE PROBABILITIES
    quietly gen `stem'cu0=`stem'pr0
    label variable `stem'cu0 "Pr(y=0) `modelis'"
    local i 1
    while `i' <= `max' {
        quietly egen `stem'cu`i' = rsum(`stem'pr0-`stem'pr`i') if `mu'~=.
        label variable `stem'cu`i' "Pr(y<=`i') `modelis'"
*spost9 zt cumulative probabilities 18Feb2005
        if "`cmd'"=="ztp" | "`cmd'"=="ztnb" {
            quietly egen `stem'Ccu`i' = rsum(`stem'Cpr1-`stem'Cpr`i') if `mu'~=.
            label variable `stem'Ccu`i' "Pr(y<=`i'|y<0) `modelis'"
        }
        local i = `i' + 1
    }

*-> GENERATE GREATER THAN VARIABLE
    quietly gen `stem'prgt = 1-`stem'cu`max' if `mu'~=.
    label variable `stem'prgt "Pr(y>`max') `modelis'"
    *18Feb2005
    if "`cmd'"=="ztp" | "`cmd'"=="ztnb" {
        quietly gen `stem'Cprgt = 1-`stem'Ccu`max' if `mu'~=.
        label variable `stem'Cprgt "Pr(y>`max'|y>0) `modelis'"
    }

*-> IF PLOT OPTION SPECIFIED
    if "`plot'"=="plot" {
        quietly gen `stem'val = .
            label variable `stem'val "Count"
        quietly gen `stem'obeq = .
            label variable `stem'obeq "Observed Pr(y=k) `modelis'"
        quietly gen `stem'preq = .
            label variable `stem'preq "Predicted Pr(y=k) `modelis'"
        quietly gen `stem'oble = .
            label variable `stem'oble "Observed Pr(y<=k) `modelis'"
        quietly gen `stem'prle = .
            label variable `stem'prle "Predicted Pr(y<=k) `modelis'"
    *18Feb2005
        if "`cmd'"=="ztp" | "`cmd'"=="ztnb" {
            quietly gen `stem'Cpreq = .
            label variable `stem'Cpreq "Predicted Pr(y=k|y>0) `modelis'"
            quietly gen `stem'Cprle = .
            label variable `stem'Cprle "Predicted Pr(y<=k|y>0) `modelis'"
        }
        ** bug fix -- makes sure observed probabilities are
        **      computed on estimation sample
        if "`if'" == "" {
            local if "if e(sample)==1"
        }
        else {
            local if "`if' & e(sample)==1"
        }

        local i 0
        while `i' <= `max' {
            quietly {
                local obs = `i' + 1
                replace `stem'val = `i' in `obs'
                tempvar count1 count2
                * 1 if outcomes equal to i
                gen `count1' = (`e(depvar)'==`i') `if' `in'
                sum `count1' `if' `in'
                replace `stem'obeq = r(mean) in `obs'
                * 1 if outcome lt i
                gen `count2' = (`e(depvar)'<=`i') `if' `in'
                sum `count2' `if' `in'
                replace `stem'oble = r(mean) in `obs'
                * compute average predicted prob
                sum `stem'pr`i' `if' `in'
                replace `stem'preq = r(mean) in `obs'
                * compute average cumulative predicted prob
                sum `stem'cu`i' `if' `in'
                replace `stem'prle = r(mean) in `obs'

                *zt only compute if count > 0 18Feb2005*ZT
                if ("`cmd'"=="ztp" | "`cmd'"=="ztnb") & `i'>0 {
                    sum `stem'Cpr`i' `if' `in'
                    replace `stem'Cpreq = r(mean) in `obs'
                    sum `stem'Ccu`i' `if' `in'
                    replace `stem'Cprle = r(mean) in `obs'
                }
            }
            local i = `i' + 1
        }
    }

end
