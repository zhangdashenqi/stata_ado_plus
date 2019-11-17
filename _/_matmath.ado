*! version 0.2.2 2013-08-04 | long | names1 names2
* version 0.2.1 2013-02-18 | long | _matmath
* version 0.2.0 2012-10-27 | long |

* DO: TEST MATRICES EXIST

** matmath: math operations on matrices

* DO: add percent change
*       return informtaion on output matrix
* do: weave to matrices

capture program drop _help
capture program drop _matmath

program _matmath, sclass

    version 11.2

    args matout eq matL op matR opt1 opt2 opt3 opt4
    local options "`opt1' `opt2' `opt3' `opt4'"

    if "`matout'"=="" {
        _help
        exit
    }
    if "`eq'" == "" {
        matrix list `matout'
        exit
    }
    if "`matL'"=="" {
        display as error ///
        "matmath A = B <op> C: matrix B is not specified"
        exit
    }
    capture matrix list `matL'
    if _rc==0 {
        local nrowsmatL = rowsof(`matL')
        local ncolsmatL = colsof(`matL')
        local rownmsmatL : rownames `matL'
        local colnmsmatL : colnames `matL'
    }
    else {
        display as error ///
        "matrix `matL' does not exist"
        exit
    }
    capture matrix list `matR'
    if _rc==0 {
        local nrowsmatR = rowsof(`matR')
        local ncolsmatR = colsof(`matR')
        local rownmsmatR : rownames `matR'
        local colnmsmatR : colnames `matR'
    }
    else {
        display as error ///
        "matrix `matR' does not exist"
    }


    if "`eq'"!="=" {
        display as error ///
        "matmath A = B <op> C: equal sign is missing"
        exit
    }
    if "`matR'"=="" {
        display as error ///
        "matmath A = B <op> C: matrix C is not specified"
        exit
    }
    if "`op'"=="" {
        display as error ///
        "matmath A = B <op> C: <op> is not specified"
        exit
    }
    local okop = inlist("`op'","+","-","*","/",",","\","%")
    if `okop'!=1 {
        display as error ///
        "invalid operator: operators can be + - * / % , \"
        exit
    }

//  check conformability

/*
    di "`nrowsmatL'"
    di "`ncolsmatL'"
    di "`nrowsmatR'"
    di "`ncolsmatR'"
*/
    if `nrowsmatL'!=`nrowsmatR' | `ncolsmatL'!=`ncolsmatR' {
        display as error ///
        "dimensions of matrices are incompatabile"
        exit
    }

//  execute operations

    mata: matr = st_matrix(st_local("matR"))
    mata: matl = st_matrix(st_local("matL"))

    if "`op'"=="minus" | "`op'"=="-" {
        mata: matout = matr :- matl
        mata: st_matrix(st_local("matout"),matout)
    }
    if "`op'"=="plus" | "`op'"=="+" {
        mata: matout = matr :+ matl
        mata: st_matrix(st_local("matout"),matout)
    }
    if "`op'"=="times" | "`op'"=="*" {
        mata: matout = matr :* matl
        mata: st_matrix(st_local("matout"),matout)
    }
    if "`op'"=="divide" | "`op'"=="/" {
        mata: matout = matr :/ matl
        mata: st_matrix(st_local("matout"),matout)
    }
    if "`op'"=="percent" | "`op'"=="%" {
        mata: matout = 100*(matr :/ matl)
        mata: st_matrix(st_local("matout"),matout)
    }
    if "`op'"=="," {
        matrix `matout' = `matL' , `matR'
    }
    if "`op'"=="\" {
        matrix `matout' = `matL' \ `matR'
    }

*021    matrix rownames `matout' = `rownmsmatL'
*    matrix coleq `matout' = ""

*022
if "`options'"!="" {
    * make list last

    local ipos : list posof "list" in options
    if `ipos'>0 {
        local options : subinstr local options "list" "", all
        local options "`options' list"
    }
*di "opt `opt' options `options'"
    foreach opt in `options' {
        if "`opt'"=="names1" {
            local rnm : rowfullnames `matL'
            local cnm : colfullnames `matL'
            mat rownames `matout' = `rnm'
            mat colnames `matout' = `cnm'
        }
        else if "`opt'"=="names2" {
            local rnm : rowfullnames `matR'
            local cnm : colfullnames `matR'
            mat rownames `matout' = `rnm'
            mat colnames `matout' = `cnm'
        }
        else if "`opt'"=="list" {
            matlist `matout'
        }
    }
}
    sreturn local nrows = rowsof(`matout')
    sreturn local ncols = colsof(`matout')
end

program _help
    display ///
    "syntax: matout = mat1 [ + - / * % , \ ] mat2 , [ list names[1|2] ]"
end

exit

end

exit
