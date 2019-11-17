*! version 1.1.0 2016-09-14 | long freese | t-value for svy
* version 1.0.0 2014-02-14 | long freese | spost13 release

//  compute statistics from lincom returns

program define _rm_lincom_stats, rclass

    tempname estval seval levelval levelpval cifactorval ///
        zval pval lbval ubval df

    scalar `df' = r(df) // 2016-09-14
    scalar `estval'     = r(estimate) // lincom estimate
    scalar `seval'      = r(se) // lincom std err
    scalar `zval'       = `estval'/`seval' // zvalue

    if `df' < . { // 2016-09-14

        scalar `pval'       = 2*(1-t(`df',abs(`zval'))) // pvalue 2 tailed
        scalar `levelval'   = $S_level // level for CI
        scalar `levelpval'  = ( 1 - (`levelval'/100) )/2 // pval for ci
        scalar `cifactorval' = abs(invt(`df',`levelpval')) // +- ci multiplier

    }
    else {

        scalar `pval'       = 2*(1-normal(abs(`zval'))) // pvalue 2 tailed
        scalar `levelval'   = $S_level // level for CI
        scalar `levelpval'  = ( 1 - (`levelval'/100) )/2 // pval for ci
        scalar `cifactorval' = abs(invnormal(`levelpval')) // +- multiplier for ci

    }

    scalar `lbval'      = `estval' - (`cifactorval'*`seval') // lb
    scalar `ubval'      = `estval' + (`cifactorval'*`seval') // ub

    return scalar est   = `estval'
    return scalar se    = `seval'
    return scalar z     = `zval'
    return scalar p     = `pval'
    return scalar lb    = `lbval'
    return scalar ub    = `ubval'
    return scalar level = `levelval'

end
exit


    * 0.1.1
    scalar `estval'     = r(estimate) // lincom estimate
    scalar `seval'      = r(se) // lincom std err
    scalar `zval'       = `estval'/`seval' // zvalue
    scalar `pval'       = 2*(1-normal(abs(`zval'))) // pvalue 2 tailed
    scalar `levelval'   = $S_level // level for CI
    scalar `levelpval'  = ( 1 - (`levelval'/100) )/2 // pval for ci
    scalar `cifactorval' = abs(invnormal(`levelpval')) // +- multiplier for ci
    scalar `lbval'      = `estval' - (`cifactorval'*`seval') // lb
    scalar `ubval'      = `estval' + (`cifactorval'*`seval') // ub
