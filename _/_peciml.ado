*! version 0.2.2 2008-07-09
*   - global pedifsey std error of dif in y

// ci for difference in y or y* based on ML Wald computation

capture program drop _peciml
program define _peciml, rclass

    version 8
    tempname xb_dif xb_dif_var xb_dif_sd xb_dif_lo xb_dif_up
    tempname x_cur x_sav x_dif z b b_var

    // retrieve global data

    local nocon = peinfo[1,6] // 1 if no constant
    local output : word 3 of $petype // what is the output type?
    scalar `z' = peinfo[1,4] // width of confidence interval
    local nrhs = peinfo[1,1] // # of RHS variables
    sca `xb_dif'= pepred[7,1] // difference in xb from saved to current
    matrix `x_cur' = pebase[1,1...] // current base values
    matrix `x_sav' = pebase[2,1...] // saved base values
    mat `b_var' = e(V)
    mat `b' = e(b)

    // select and augment matrices to match model type

    * ologit, oprobit // nocon option not allowed
    if "`output'"=="ordered"   {
        mat `b_var' = `b_var'[1..`nrhs',1..`nrhs']
    }

    * tobit, cnreg, intreg
    if "`output'"=="tobit" {
        if `nocon' != 1 {
            mat `x_cur' = `x_cur', 1, 0
            mat `x_sav' = `x_sav', 1, 0
        }
        else {
            mat `x_cur' = `x_cur', 0
            mat `x_sav' = `x_sav', 0
        }
    }

    * regress, fit, logit, probit
    if "`output'"=="regress" | "`output'"=="binary"   {
        if `nocon' != 1 {
            mat `x_cur' = `x_cur', 1
            mat `x_sav' = `x_sav', 1
        }
    }

    mat `x_dif' = `x_cur' - `x_sav'
    * variance of difference
    mat `xb_dif_var' = (`x_dif')*`b_var'*(`x_dif')'
    sca `xb_dif_sd' = sqrt(`xb_dif_var'[1,1])

    * 2008-07-09
    global pedifsey = `xb_dif_sd'

    * compute and store upper and lower limits
    sca `xb_dif_lo' = `xb_dif' - `z'*`xb_dif_sd'
    sca `xb_dif_up' = `xb_dif' + `z'*`xb_dif_sd'

    mat peupper[7,1] = `xb_dif_up'
    mat pelower[7,1] = `xb_dif_lo'

end

* version 0.2.1 13Apr2005
* version 0.2.0 2005-02-03
