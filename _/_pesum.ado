*! version 1.6.2 1/6/01

capture program drop _pesum
program define _pesum, rclass
    version 6.0
    tempvar b tmp
    syntax [fweight aweight pweight] [if] [in][,Median Dummy Two]

* get weight info - if weight not specified in _pesum looks to see if estimation
* was done with weights anyway - this way one can either have _pesum handle the
* weights or let _pesum do it

    local wtis "[`weight'`exp']"
    if "`wtis'"=="" & "`e(wtype)'"!="" {
        local weight "`e(wtype)'"
        local wtis "[`e(wtype)'`e(wexp)']"
    }
    if "`weight'"=="pweight" {
        local wtis "[aweight`e(wexp)']"
        di in r "Warning: " in g "pweights are being treated as aweights to compute SDs"
    }
    if "`weight'"=="iweight" {
        di in r "Error: command is incompatible with iweights."
        exit
    }

* get names of variables
    _perhs
    local nvars = `r(nrhs)' + 1
    local varnms "`e(depvar)' `r(rhsnms)'"
    * get variables in 2nd eq for zip and zinb
    if "`two'"=="two" {
        local nvars = `r(nrhs2)' + 1
        local varnms "`e(depvar)' `r(rhsnms2)'"
    }
    * intreg has two lhs vars; select only 1st one
    if "`e(cmd)'"=="intreg" {
        local nmtoget : word 1 of `varnms'
        local varnms "`nmtoget' `r(rhsnms)'"
    }

* Matrices for results
    tempname Smean Ssd Smin Smax Sdummy Smedian SN
    mat `Smean' = J(1,`nvars',-99999)
    mat colnames `Smean' = `varnms'
    mat `Ssd' = `Smean'
    mat `Smin' = `Smean'
    mat `Smax' = `Smean'
    mat `Sdummy' = `Smean'
    mat `Smedian' = `Smean'

* loop through variables
    local i = 1
    while `i'<=`nvars' {
        local nmtoget : word `i' of `varnms'
        quietly sum `nmtoget' `wtis' `if' `in'
        scalar `SN' = r(N)
        if `SN' == 0 {
        * selection criteria left no observations
            return scalar SN = `SN'
            exit
        }
        mat `Smean'[1,`i'] = r(mean)
        mat `Ssd'[1,`i'] = sqrt(r(Var))
        mat `Smin'[1,`i'] = r(min)
        mat `Smax'[1,`i'] = r(max)
        if "`dummy'"=="dummy" {
            * doesn't need weights. Won't change if is dummy
            _pedum `nmtoget' `if' `in'
            mat `Sdummy'[1,`i'] = r(dummy)
        }
        if "`median'"=="median" {
            quietly _pctile `nmtoget' `if' `in' `wtis'
            mat `Smedian'[1,`i'] = r(r1)
        }
        local i=`i'+1
    }

    return matrix Smean `Smean'
    return matrix Ssd `Ssd'
    return matrix Smin `Smin'
    return matrix Smax `Smax'
    return matrix Sdummy `Sdummy'
    return matrix Smedian `Smedian'
    return scalar SN = `SN'

end
