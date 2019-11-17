*! version 0.4.2 2013-01-24 | long freese | dydx and
* version 0.4.1 2012-09-04 | long freese | dcp ocp work

//  information about plot variables

capture program drop _ordcplot_data_plotvarinfo
program _ordcplot_data_plotvarinfo, sclass

    version 11.2

    args E_varnms maxplotrows OPTvarnms OPTstd

    tempname P_varnums P_varbin P_vartype

    matrix `P_varnums' = J(`maxplotrows',1,.)   // # of var to plot
    matrix `P_varbin'  = `P_varnums'            // 1 if dummy var
    matrix `P_vartype' = `P_varnums'            // coef type

    local i = 0
    foreach nm in `OPTvarnms' {

        local ++i

        * position of plot var among RHS variables
        local varpos : list posof "`nm'" in E_varnms
        if `varpos'==0 {
            display as error ///
            "`nm' is not a variable in your model"
            local error = 1
            sreturn local error = 1
            continue, break
        }
        matrix `P_varnums'[`i',1] = `varpos'

        * is the plot variable binary
        matrix `P_varbin'[`i',1] = _P_EVbin[`varpos']

        * std type
        local itype = substr("`OPTstd'",`i',1)
        * 0.4.2 dydx
        local ok = strpos("srubp","`itype'") // valid types
        if `ok'==0 {
            display as error ///
            "std() must be s, r, u, b, or p"
            local error = 1
            sreturn local error = 1
            continue, break
        }
        matrix `P_vartype'[`i',1] = 1 // 1unstd
        if ("`itype'"=="s") matrix `P_vartype'[`i',1] = 3 // 3sd
        if ("`itype'"=="r") matrix `P_vartype'[`i',1] = 4 // 4rng
        * 0.4.2 dydx
        if ("`itype'"=="p") matrix `P_vartype'[`i',1] = 5 // 5dydx
        if ("`itype'"=="b") { // bin
             if `P_varbin'[`i',1]!=1 {
                display as error ///
                "variable specified as std(b) is not binary"
                local error = 1
                sreturn local error = 1
                continue, break
             }
             matrix `P_vartype'[`i',1] = 2 // 2bin
        }

        * check if dummy var is specified as binary type
        if `P_varbin'[`i',1]==1 & `P_vartype'[`i',1]!=2 {
            local varnum = `P_varnums'[`i',1]
            local varnm : word `varnum' of `E_varnms'
            display ///
            "Warning: `varnm' is binary, but std(b) was not used"
        }
    }

    //  create variables

    matrix temp = `P_varbin'
    matrix colname temp = _P_PVbin
    svmat temp, names(col)
    label var _P_PVbin "Binary indicator of plot variables"

    matrix temp = `P_varnums'
    matrix colname temp = _P_PVnums
    svmat temp, names(col)
    label var _P_PVnums "RHS variable # of plot variable"

    matrix temp = `P_vartype'
    matrix colname temp = _P_PVtype
    svmat temp, names(col)
    label var _P_PVtype "Coefficient type of plot variable"

    matrix drop temp

end

exit

* version 0.1.0 2012-08-05
* version 0.1.1 2012-08-06
* version 0.4.0 2012-09-03 jsl | cleanup | posted
