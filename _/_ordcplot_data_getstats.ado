*! version 0.4.7 2013-04-25 | long freese | upgrade matrix option

//  get estimates statistics from last model
//  called by:

capture program drop _ordcplot_data_getstats
program _ordcplot_data_getstats, sclass

*TRACE di in blue _new "      = 1 stats  => Entering _ordcplot_data_getstats"

    version 11.2

    args E_Bunstd E_Vunstd E_Bstd E_Brange matrix values debug matrixstub

    tempname sd rng
    local error = 0

    if "`matrixstub'"=="" {

        * create variables with stats on RHS variables
        _rm_sum, dummy
        matrix temp = r(matsd)'
        matrix temp = temp[2...,1]
        matrix colname temp = _P_EVsd
        qui svmat temp, names(col)
        label var _P_EVsd "SD of rhs variables"

        matrix temp = r(matdummy)'
        matrix temp = temp[2...,1]
        matrix colname temp = _P_EVbin
        qui svmat temp, names(col)
        label var _P_EVbin "Binary indicator of rhs variables"

        matrix temp = r(matmax)' - r(matmin)'
        matrix temp = temp[2...,1]
        matrix colname temp = _P_EVrng
        qui svmat temp, names(col)
        label var _P_EVrng "Range of rhs variables"

        matrix drop temp

        * information on categories
        _rm_modelinfo // 046 r-returns not s-returns
        local catnms  "`r(lhscatnms)'"
        local catvals "`r(lhscatvals)'"
        if ("`values'"=="values") local catnms "`catvals'"
        local ncats = r(lhscatn)
        local catrefnum = e(baseout)
        if (`catrefnum'==0) local catrefnum = 1
        if (`catrefnum'==.) local catrefnum = 1 // for non mlogit

        * model coefficients
        if "`e(cmd)'"=="mlogit" {

            _rm_mlogitbv `E_Bunstd' `E_Vunstd'
            local varnms : colnames(`E_Bunstd') // including _cons
            local varnms = subinstr("`varnms'","_cons","",1)
            local nvars = wordcount("`varnms'")
            matrix `E_Bstd'   = `E_Bunstd' // to hold std betas
            matrix `E_Brange' = `E_Bunstd' // to hold range std betas

            local ivar = 1
            while `ivar' < `nvars'+1 {
                scalar `sd' = _P_EVsd[`ivar']
                scalar `rng' = _P_EVrng[`ivar']
                local icat = 1
                while `icat' < `ncats' {
                    matrix `E_Bstd'[`icat',`ivar'] ///
                        = `E_Bunstd'[`icat',`ivar'] * `sd'
                    matrix `E_Brange'[`icat',`ivar'] ///
                        = `E_Bunstd'[`icat',`ivar'] * `rng'
                    local ++icat
                }
                local ++ivar
            }
        } // mlogit

        else { // not mlogit
            _rm_modelinfo // * 046 r-returns not s-returns
            local varnms "`r(rhsnms)'"
            local nvars = wordcount("`varnms'")
            matrix `E_Bunstd' = e(b)
            matrix `E_Vunstd' = e(V)
            matrix `E_Bstd' = e(b)*0
            matrix `E_Brange' = e(b)*0
        }

    } // not matrix

//  matrix input: NVARS==#vars; NCATS=#categories

    else {

        * 1 x NVARS with SDs: mat Xsd = (1,2,3)
        matrix temp = `matrixstub'sd
        matrix temp = temp'
        matrix colname temp = _P_EVsd
        qui svmat temp, names(col)
        label var _P_EVsd "SD of rhs variables"

        * 1 x NVARS with is it dummy var: mat Xdummy = (1,0,1)
        matrix temp = `matrixstub'dummy
        matrix temp = temp'
        matrix colname temp = _P_EVbin
        qui svmat temp, names(col)
        label var _P_EVbin "Binary indicator of rhs variables"

        * 1 x NVARS with range: mat Xrange = (1,4,12.1)
        matrix temp = `matrixstub'range
        matrix temp = temp'
        matrix colname temp = _P_EVrng
        qui svmat temp, names(col)
        label var _P_EVrng "Range of rhs variables"
        matrix drop temp

        * NCATS names of categories in order 1st cat, 2nd, 3rd,...
        local catnms  "$`matrixstub'catnms"

        * NCATS values of categories
        local catvals "$`matrixstub'catvals"
        if ("`values'"=="values") local catnms "`catvals'"
        local ncats = wordcount("`catnms'")

        * global with base category from mlogit.
        local catrefnum $`matrixstub'basecat
        if "`catrefnum'"=="" {
            di as error "the global <matrixstub>basecat must be specified."
            exit // is ignored?!
        }
        if (`catrefnum'==0) local catrefnum = 1 //
        if (`catrefnum'==.) local catrefnum = 1 // for non mlogit

        * NVARS names of predictors
        local varnms "$`matrixstub'rhsnms"
        local nvars = wordcount("`varnms'")

        * name of estimation command for input coefficients
        if "$`matrixstub'cmd"=="mlogit" {

            * estimates in order: NCATS rows; NVAR columns
            * row 1 is 1st non base cat VS basecat
            * row 2 is 2nd non base cat VS basecat, etc
            matrix `E_Bunstd' = `matrixstub'beta
            matrix `E_Bstd'   = `E_Bunstd' // to hold std betas
            matrix `E_Brange' = `E_Bunstd' // to hold range std betas

            * create standardized and range adjusted coefficients
            local ivar = 1
            while `ivar' < `nvars'+1 {
                scalar `sd' = _P_EVsd[`ivar']
                scalar `rng' = _P_EVrng[`ivar']
                local icat = 1
                while `icat' < `ncats' {
                    matrix `E_Bstd'[`icat',`ivar'] ///
                        = `E_Bunstd'[`icat',`ivar'] * `sd'
                    matrix `E_Brange'[`icat',`ivar'] ///
                        = `E_Bunstd'[`icat',`ivar'] * `rng'
                    local ++icat
                }
                local ++ivar
            }
        } // mlogit

        else { // not mlogit
            matrix `E_Bunstd' = `matrixstub'beta
            matrix `E_Bstd' = `E_Bunstd'*0
            matrix `E_Brange' = `E_Bunstd'*0
        }
        local error = 0

    } // matrix

    sreturn local varnms "`varnms'"
    sreturn local nvars = `nvars'
    sreturn local catnms "`catnms'"
    sreturn local ncats = `ncats'
    sreturn local catvals "`varnms'"
    sreturn local catrefnum = `catrefnum'
    sreturn local error = `error'

*TRACE di in blue "       = 2 stats  => Leaving _ordcplot_data_getstats"

end

exit

* version 0.1.1 2012-08-05 05.29
* version 0.1.2 2012-08-05 06.02 save as variables
* version 0.1.3 2012-08-05 cleanup
* version 0.4.1 2012-09-04 jsl | dcp ocp work | posted
* version 0.4.0 2012-09-03 jsl | cleanup | posted
* version 0.4.2 2012-09-04 jsl | fv work | posted
* version 0.4.3 2012-09-08 jsl | matrix | posted
* version 0.4.4 2012-09-08 | long freese | qui svmat
* version 0.4.5 2012-09-18 | long freese | _rm_mlogitbv
* version 0.4.6 2012-10-01 | long freese | _rm_modelinfor r-returns

TEST CODE

codebook _P_EVsd _P_EVbin _P_EVrng, compact
di "catnms: `catnms'"
di "catvals: `catvals'"
di "ncats: `ncats'"
di "catrefnum: `catrefnum'"
di "varnms: `varnms'"
di "nvars: `nvars'"
di "E_Bunstd"
mat list `E_Bunstd'
di "E_Bstd"
mat list `E_Bstd'
di "E_Bunstd"
mat list `E_Brange'

