*! version 0.1.0 2013-07-26 | scott long |

capture program drop materet
capture program drop _help
program materet

    version 11.2
    local input "`*'"
    local input = subinstr("`input'","="," ",.)

    args matout rout cout retnm rret cret

    *foreach n in matout rout cout retnm rret cret {
    *    di "`n': |``n''|"
    *}

    if "`matout'"=="" {
        help materet
        exit
    }
    if "`retnm'"=="" {
        display as error ///
        "materet matout row col = ereturn [ row col ]: ereturn not listed"
        exit
    }
    capture matrix list `matout'
    if _rc==0 {
        local nrowsmatout = rowsof(`matout')
        local ncolsmatout = colsof(`matout')
        local rownmsmatout : rownames `matout'
        local colnmsmatout : colnames `matout'
    }
    else { // could have it auto create matrix
        display as error ///
        "matrix `matout' does not exist"
        exit
    }

    // check return

    local isok = 0
    local isscalar = 0
    local islocal = 0
    local ismatrix = 0
    capture confirm scalar e(`retnm')
    if _rc==0 {
        local isscalar = 1
        local isok = 1
    }
    if !`isok' {
        capture confirm matrix e(`retnm')
        if _rc==0 {
            local ismatrix = 1
            local isok = 1
        }
    }
    if !`isok' {
        capture confirm number `e(`retnm')'
        if _rc==0 {
            local islocal = 1
            local isok = 1
        }
    }
    if `isok'==0 {
        display as error ///
        "e-return is either non-numeric or not a valid return name"
        exit
    }

    // matout row and column

    tempname vecis

    if "`rout'"=="n" | "`rout'"=="next" {
        local rout = `nrowsmatout' + 1
        * add row to matrix
        matrix `vecis' = J(1,`ncolsmatout',.)
        matrix rownames `vecis' = r`rout'
        matrix `matout' = `matout' \ `vecis'
        local ++nrowsmatout
    }
    else if "`rout'"=="l" | "`rout'"=="last" {
        local rout = `nrowsmatout'
    }
    if "`cout'"=="n" | "`cout'"=="next" {
        local cout = `ncolsmatout' + 1
        * add col to matrix
        matrix `vecis' = J(`nrowsmatout',1,.)
        matrix colnames `vecis' = c`cout'
        matrix `matout' = `matout' , `vecis'
        local ++ncolsmatout
    }
    else if "`cout'"=="l" | "`cout'"=="last" {
        local cout = `ncolsmatout'
    }
    * non integer matrix indicex
    capture confirm integer number `rout'
    if _rc!=0 {
        display as error ///
        "matrix `matout' row number `rout' is invalid"
        exit
    }
    capture confirm integer number `cout'
    if _rc!=0 {
        display as error ///
        "matrix `matout' column number `cout' is invalid"
        exit
    }
    * index too large
    if `cout'>`ncolsmatout' | `rout'>`nrowsmatout' {
        display as error ///
        "matrix indices (`rout',`cout') exceed matrix" ///
        "dimension [`nrowsmatout',`ncolsmatout']"
        exit
    }

    tempname putvalue

    // get matrix element
    if `ismatrix' {
        tempname matret
        matrix `matret' = e(`retnm')
        local nrowsmatret = rowsof(`matret')
        local ncolsmatret = colsof(`matret')
        if `cret'>`ncolsmatret' | `rret'>`nrowsmatret' {
            display as error ///
            "matrix indices (`rret',`cret') exceed matrix" ///
            "dimension [`nrowsmatret',`ncolsmatret']"
            exit
        }
        else {
            scalar `putvalue' = `matret'[`rret',`cret']
*di "putvalue: " `putvalue'
        }
    }
    if `isscalar' {
        scalar `putvalue' = e(`retnm')
    }
    if `islocal' {
        scalar `putvalue' = `e(`retnm')'
    }
*di "putvalue: " `putvalue'

    // populate matrix

*matlist `matout'
*di "`rout'"
*di "`cout'"

    matrix `matout'[`rout',`cout'] = `putvalue'
set trace off
end
exit

