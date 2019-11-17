*!  version 1.7.2 2Nov2005 ztp ztnb
*  version 1.7.1 13Apr2005
*  version 1.7.0 27Mar2004 slogit
*  version 1.6.4 27Apr2001 change to work with forvalues
*  version 1.6.3 17Mar2001

capture program drop praccum
program define praccum
    version 6
    tempname newmat
*=> classify each valid type of model
    if "`e(cmd)'"=="cloglog"  { local io = "typical binary" }
    if "`e(cmd)'"=="cnreg"    { local io = "typical regress" }
    if "`e(cmd)'"=="fit"      { local io = "typical regress" }
    if "`e(cmd)'"=="gologit"  { local io = "typical mlogit" }
    if "`e(cmd)'"=="intreg"   { local io = "typical regress" }
    if "`e(cmd)'"=="logistic" { local io = "typical none" }
    if "`e(cmd)'"=="logit"    { local io = "typical binary" }
    if "`e(cmd)'"=="mlogit"   { local io = "typical mlogit" }
    if "`e(cmd)'"=="nbreg"    { local io = "typical count" }
    if "`e(cmd)'"=="ologit"   { local io = "typical ordered" }
    if "`e(cmd)'"=="oprobit"  { local io = "typical ordered" }
    if "`e(cmd)'"=="poisson"  { local io = "typical count" }
    if "`e(cmd)'"=="probit"   { local io = "typical binary" }
    if "`e(cmd)'"=="regress"  { local io = "typical regress" }
    if "`e(cmd)'"=="slogit"  { local io = "typical ordered" }
    if "`e(cmd)'"=="tobit"    { local io = "typical regress" }
    if "`e(cmd)'"=="zinb"     { local io = "twoeq count" }
    if "`e(cmd)'"=="zip"      { local io = "twoeq count" }
    if "`e(cmd)'"=="ztp"  { local io = "typical count" }
    if "`e(cmd)'"=="ztnb"  { local io = "typical count" }

    if "`io'"=="" {
        di
        di in y "praccum" in r /*
        */ " does not work for the last type of model estimated."
        exit
    }
    local input : word 1 of `io'   /* input routine to _pepred */
    local output : word 2 of `io'  /* output routine */

*=> decode specified input
    syntax [, Saving(string) Using(string) GENerate(string) XIS(string)]

*truncate generate root if more than five characters
    if "`generate'" ~= "" {
        local gen = substr("`generate'",1,29)
        cap version 7
        if _rc != 0 { local gen = substr("`gen'",1,5) }
        version 6.0
    }


    if "`output'" == "ordered" | "`output'" == "mlogit" {
        tempname values
        mat `values' = r(values)
        local outcms = rowsof(r(probs))
        local count = 1
        while `count' <= `outcms' {
            local k`count' = `values'[`count',1]
            if `k`count'' < -9 | `k`count'' > 99 | int(`k`count'')!=`k`count'' {
                di in red "category values must be integers between -9 and 99"
                exit 198
            }
            if `k`count'' < 0 {
                local k`count' = abs(`k`count'')
                local k`count' = "_`k`count''"
            }
            local count = `count' + 1
        }
    }


    if "`xis'"!="" {
        tempname results
        if "`output'" == "regress" {
            matrix `results' = ( `xis' , r(xb) )
        }
        if "`output'" == "binary" {
            * grab output from binary model
            matrix `results' = ( `xis' , r(p0) , r(p1) )
        }
        if "`output'" == "ordered" | "`output'" == "mlogit" {
            tempname probs newprob
            mat `probs' = r(probs)
            local outcms = rowsof(r(probs))
            matrix `results' = `xis'
            local count = 1
            while `count' <= `outcms' {
                matrix `newprob' = `probs'[`count', 1]
                matrix `results' = `results' , `newprob'
                local count = `count' + 1
            }
        }
        if "`output'" == "count" {
            tempname probs newprob values
            mat `values' = r(values)
            mat `probs' = r(probs)
            local outcms = rowsof(r(probs))
            local rmu = r(mu)
            matrix `results' = `xis', `rmu'
            local count = 1
            while `count' <= `outcms' {
                matrix `newprob' = `probs'[`count', 1]
                matrix `results' = `results' , `newprob'
                local count = `count' + 1
            }

        }
        if "`input'" == "twoeq" & "`output'"=="count" {
            tempname az
            matrix `az' = r(always0)
            matrix `results' = `results' , `az'
        }

    *=> saving is the initial run
        if "`saving'" ~= "" { mat `saving' = `results' }
        if "`using'" ~= "" {
            cap mat list `using'
            if _rc ~= 0 {
                mat `using' = `results'
    * OLD SYNTAX: error if `using' matrix does not already exist
    *           di in r "matrix `using' does not exist"
    *           exit 111
            }
            else { mat `using' = (`using') \ (`results') }
        }
    }

*=> generates creates the new variables
    if "`gen'" ~= "" {
        if "`output'" == "regress" {
            local columns = "`gen'x `gen'xb"
        }
        if "`output'" == "binary" {
            local columns = "`gen'x `gen'p0 `gen'p1"
        }
        if "`output'" == "ordered" | "`output'" == "mlogit" {
            local columns "`gen'x"
            local outcms = rowsof(r(probs))
            local count = 1
            while `count' <= `outcms' {
                local columns "`columns' `gen'p`k`count''"
                local count = `count' + 1
            }
        }
        if "`output'" == "count" {
            local columns "`gen'x `gen'mu"
            local outcms = rowsof(r(probs))
            local count = 0
            while `count' <= (`outcms'-1) {
                local columns "`columns' `gen'p`count'"
                local count = `count' + 1
            }
            if "`input'"=="twoeq" {
                local columns "`columns' `gen'inf"
            }
        }
        * create new variables
        matrix colnames `using' = `columns'
        svmat `using', names(col)

    *=> label variables
        label variable `gen'x "value of x"
        if "`output'" == "regress" {
            label variable `gen'xb "value of xb"
        }
        if "`output'" == "binary" {
            label variable `gen'p0 "Pr(0)"
            label variable `gen'p1 "Pr(1)"
        }
        if "`output'" == "ordered" {
            tempname values
            mat `values' = r(values)
            local outcms = rowsof(r(probs))
            local count = 1
            while `count' <= `outcms' {
                local count2 = `count'
                label variable `gen'p`k`count'' "Pr(`k`count'')"
                local count = `count' + 1
            }
        }
        if "`output'" == "mlogit" {
            tempname values
            mat `values' = r(values)
            local outcms = rowsof(r(probs))
            local count = 1
            while `count' <= `outcms' {
                local value = `values'[`count', 1]
                local count2 = `count'
                label variable `gen'p`k`count'' "Pr(`k`count'')"
                local count = `count' + 1
            }
        }
        if "`output'" == "count" {
            tempname values
            mat `values' = r(values)
            local outcms = rowsof(r(probs))
            local count = 1
            while `count' <= `outcms' {
                local value = `values'[`count', 1]
                label variable `gen'p`value' "Pr(`value')"
                local count = `count' + 1
            }
            if "`input'"=="twoeq" {
                label variable `gen'inf "Pr(always0)"
            }
        }

*=> for ordered and count variables, generate cumulative counts
        if "`output'" == "ordered" {
            local outcms = rowsof(r(probs))
            local count = 1
            while `count' <= `outcms' {
                qui egen `gen's`k`count'' = rsum(`gen'p`k1'-`gen'p`k`count'') if `gen'p`k1'~=.
                local cumul = "`cumul'`gen's`k`count'' "
                label variable `gen's`k`count'' "Pr(<=`k`count'')"
                local count = `count' + 1
            }
        }
        if "`output'" == "count" {
            local outcms = rowsof(r(probs))
            local count = 0
            while `count' <= (`outcms'-1) {
                qui egen `gen's`count' = rsum(`gen'p0-`gen'p`count') if `gen'p0~=.
                local cumul = "`cumul'`gen's`count' "
                label variable `gen's`count' "Pr(<=`count')"
                local count = `count' + 1
            }
        }

*=> display new variables
        di _n in g "New variables created by" in w " praccum" in y ":"
        sum `columns' `cumul'
    } /* generate */
end

