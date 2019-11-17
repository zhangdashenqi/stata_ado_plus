*! version 0.2.4.2 2013-08-08 | scott long | code clean , bug
*! version 0.2.4.1 2013-07-30 | scott long | code clean
* version 0.2.4 2013-07-30 | scott long | exp log sqrt sq
* version 0.2.3 2013-07-14 | scott long | allow row names with blanks
* version 0.2.2 2012-11-09 | scott long | name
* version 0.2.1a 2012-10-28 | scott long | cleanup
* version 0.2.0 2012-10-28 | scott long

** operations on rows or columns of a matrix

* todo: add sd
* todo: add coleq and rowed
* add: logit , odds, inverse,
* add: blank -- null row
* bug: names. Drop and use mat rownames?

capture program drop _matrc
capture program drop _closeup

program _matrc

    version 11.2

    local unitary = 0
    local rc "`1'"
    local matin "`2'"
    local moreargs = 1 // continue processing args
    local list ""
    if "`rc'"=="row" local concat " \ "
    else local concat " , "
    * is a matrix specified?
    if "`matin'"=="" {
        display "Syntax for mat`rc':"
        display
        display "   mat`rc' <matrix> `rc'#out = `rc'#L [ + - / * %] `rc'#R"
        display "   mat`rc' <matrix> `rc'#out = [ exp sqrt sq log] `rc'#L "
        display "                   `rc'#out name <`rc' name>"
        display "                   keep <`rc' #s to keep>"
        display "                   drop <`rc' #s to drop>"
        display "                   number : add #'s to `rc' names"
        display "                   names <`rc' names>"
        display ///
        "                   [sum mean sd] <= add `rc' with statistics"
        exit
    }

//  does matin exist?

    capture matrix list `matin'

    if _rc==0 { // matrix exists
        local nrows = rowsof(`matin')
        local ncols = colsof(`matin')
        local rownms : rownames `matin'
        local colnms : colnames `matin'
    }
    else {
        display as error "error 1: matrix `matin' does not exist"
        exit
    }

    local isnum "`3'" // 3rd should be number
    local nextarg = 4

//  matrow matin => list matrix

    if "`isnum'"=="" {
        matlist `matin'
        exit
    }

//  matrow matin names rcnm1 rcnm2... => new r/c names

    if "`isnum'"=="names" {
        local rcnms ""
        local i = `nextarg'
        while "``i''"!="" { // loop throut all names
            local rcnms "`rcnms'``i'' "
            local ++i
        }
        local operator "names"
        local moreargs = 0 // no more args to process
    }

//  matrow matin # ... -or-  matrow matin <word>-

    capture confirm integer number `isnum'
    if (_rc==0) local nextisnumber = 1
    else local nextisnumber = 0

//  matrow matin <word>

    if `nextisnumber'!=1 & `moreargs' { // not a number
        local operator "`isnum'"
        local okop = /// valid wors
        inlist("`operator'","drop","names","keep","number","sum","mean","sd")
        if `okop'!=1 {
            display as error "error 2: invalid operation `operator'"
            exit
        }
        * rest of syntax decoded below as each operation is executed
    }

//  matrow matin #

    else if `nextisnumber'==1 & `moreargs' {

        local out_index = `isnum'
        local isit_equal "``nextarg''"
        local ++nextarg

        if "`isit_equal'"=="" {
            display as error "error 3: invalid syntax"
            exit
        }

//  matrow matin # name

        if "`isit_equal'"=="name" {
            local operator "name"
            local rcnm "``nextarg''"
            local ++nextarg
            if "`rcnm'"=="" {
                display as error ///
                "error 4: mat`rc' <matnm> name must have `rc' name specified."
                exit
            }
            local argis"``nextarg''"
            if ("`argis'"=="list") local list "list"
            local moreargs = 0 // no more args to process
        }

//  matrow matin # =

        else if "`isit_equal'"=="=" {

            local LEFTnum "``nextarg''"
            local ++nextarg
            local operator "``nextarg''"
            local ++nextarg
            local RIGHTnum "``nextarg''"
            local ++nextarg

            if "`LEFTnum'"=="" | "`operator'"==""  {
                display as error ///
                "error 5: invalid syntax, incomplete command"
                exit
            }
        } // equal

        * at this point, LEFTnum and operator defined

//  matrow matin # = <unitary> #

        if "`RIGHTnum'"=="" { // no right number, could be unitary
            * list of valid unitary operators
            local unitary ///
                = inlist("`LEFTnum'","exp","log","ln","sqrt","sq")
            if `unitary' {
                local RIGHTnum = `operator'
                local operator "`LEFTnum'"
            }
            else {
                display as error "error 6: invalid syntax"
                exit
            }
        }

//  matrow matin # = # <binary> #

        if !`unitary' {
            local okop ///
                = inlist("`operator'","+","-","*","/","%")
            if `okop'!=1 {
                display as error ///
                    "error 7: invalid `rc' operator `operator'"
                exit
            }

            * is L number valid?
            capture confirm integer number `LEFTnum'
            if _rc != 0 {
                display as error "error 6: `isnum' must be a number"
                exit
            }
            if `LEFTnum'>`n`rc's' {
                display as error ///
                "error 8: `rc' number `LEFTnum' exceeds matrix dimensions"
                exit
            }

            * is R number valid?
            capture confirm integer number `RIGHTnum'
            if _rc != 0 {
                display as error "error 9: `isnum' must be a number"
                exit
            }
            if `LEFTnum'>`n`rc's' {
                display as error ///
                "error 10: `rc' number `RIGHTnum' exceeds matrix dimensions"
                exit
            }

            local nextoption "``nextarg''"

            * list option at end of command
            if "`nextoption'" == "list" {
                local list "list"
            }
            else {
                * perhaps other end options will be added
            }
            local moreargs = 0 // no more args to process
        } // not unitary

    } // matin # = syntax

/*
    else {
        display as error "error 11: incorrect syntax"
        exit
    }
*/

/*
di "matin:     `matin'"
di "out_index: `out_index'"
di "LEFTnum:   `LEFTnum'"
di "op:        `operator'"
di "RIGHTnum:  `RIGHTnum'"
di "rcnm:      `rcnm'"
di "names:     `rcnms'"
di "nextarg:   `nextarg'"
di "moreargs:  `moreargs'"
*/

//  execute operations

    capture matrix drop matout

//  matrow matin drop | matrow matin keep

    if "`operator'"=="drop" | "`operator'"=="keep" {
        local rclist ""
        local i = `nextarg'
        while "``i''"!="" {
            local rclist "`rclist'``i'' "
            local ++i
        }
    }

    if "`operator'"=="drop" {
        local newrcnms ""
        forvalues i = 1(1)`n`rc's' {
            if "`rc'"=="row" {
                matrix ivec = `matin'[`i',1...]
            }
            else  {
                matrix ivec = `matin'[1...,`i']
            }
            local ipos : list posof "`i'" in rclist
            if `ipos'== 0 {
                local inm : word `i' of ``rc'nms'
                local newrcnms "`newrcnms'`inm' "
                matrix matout = nullmat(matout) `concat' ivec
            }
        }
    }

    if "`operator'"=="keep" {
        local newrcnms ""
        foreach i in `rclist' {
            if `i'<=`n`rc's' {
                if "`rc'"=="row" {
                    matrix ivec = `matin'[`i',1...]
                }
                else  {
                    matrix ivec = `matin'[1...,`i']
                }
                local inm : word `i' of ``rc'nms'
                local newrcnms "`newrcnms'`inm' "
                matrix matout = nullmat(matout) `concat' ivec
            }
            else {
                display "`rc' `i' is not in matrix"
            }
        }
    }

//  number row/col names

    if "`operator'"=="number" {
        matrix matout = `matin'
        local newnms ""
        local i = 0
        foreach nm in ``rc'nms' {
            local ++i
            local newnms "`newnms' `i'_`nm'"
        }
        matrix `rc'names matout = `newnms'
    }

//  sum mean sd

    if "`operator'"=="sum" | "`operator'"=="mean" | "`operator'"=="sd" {

        local argis "``nextarg''"
        if ("`argis'"=="list") local list "list"

        matrix matout = `matin'
        if ("`rc'"=="col") matrix matout = matout'
        mata: matout = st_matrix("matout")

        if "`operator'"=="sum" {
            mata: vecout = colsum(matout)
        }
        if "`operator'"=="mean" {
            mata: vecout = mean(matout)
        }
        if "`operator'"=="sd" {
            display "option sd needs to be completed..."
        }

        mata: st_matrix("vecout",vecout)
        matrix rownames vecout = `operator'
        matrix colnames vecout = `rc'nms

        * add new information on margin
        if "`rc'"=="row" {
            matrix matout = `matin' \ vecout
        }
        if "`rc'"=="col" {
            matrix vecout = vecout'
            matrix matout = `matin' , vecout
        }
    }

//  add row/col names for all rows/columns

    if "`operator'"=="names" {
        local nrcnms = wordcount("`rcnms'")
        if `nrcnms' != `n`rc's' {
            display as error ///
            "error 12: # of names does not match number of `rc's"
            exit
        }
        matrix matout = `matin'
        matrix `rc'names matout = `rcnms'
    }

//  name for single row/column

    if "`operator'"=="name" {
        local oldnms : `rc'names `matin'
        local noldnms = wordcount("`oldnms'")
        local newnms ""
        forvalues i=1(1)`noldnms' {
            local addnm : word `i' of `oldnms'
            if (`i'!=`out_index') local newnms "`newnms'`addnm' "
            else local newnms "`newnms'`rcnm' "
        }
        matrix matout = `matin'
        matrix `rc'names matout = `newnms'
    }

//  math

    local binary = inlist("`operator'","+","-","*","/","%")
    if `binary' | `unitary' {

        if `binary' { // binary operation, get two vectors
            if "`rc'"=="row" {
                matrix vecL = `matin'[`LEFTnum',1...]
                matrix vecR = `matin'[`RIGHTnum',1...]
            }
            else {
                matrix vecL = `matin'[1...,`LEFTnum']
                matrix vecR = `matin'[1...,`RIGHTnum']
            }
            mata: vL = st_matrix("vecL")
            mata: vR = st_matrix("vecR")
        }
        else { // unitary, get one vector
            if "`rc'"=="row" {
                matrix vecR = `matin'[`RIGHTnum',1...]
            }
            else {
                matrix vecR = `matin'[1...,`RIGHTnum']
            }
            mata: vR = st_matrix("vecR")
        }

        if "`operator'"=="exp" {
            mata: vecout = exp(vR)
        }
        if "`operator'"=="log" {
            mata: vecout = log(vR)
        }
        if "`operator'"=="sqrt" {
            mata: vecout = sqrt(vR)
        }
        if "`operator'"=="sq" {
            mata: vecout = vR :* vR
        }
        if "`operator'"=="-" {
            mata: vecout = vL :- vR
        }
        if "`operator'"=="+" {
            mata: vecout = vL :+ vR
        }
        if "`operator'"=="*" {
            mata: vecout = vL :* vR
        }
        if "`operator'"=="/" {
            mata: vecout = vL :/ vR
        }
        if "`operator'"=="%" {
            mata: vecout = 100*(vR :/ vL)
        }
        mata: st_matrix("vecout",vecout)

*! start here
        * null vector if new vector exceeds dimensions
        local addvec = 0
        if `out_index'>`n`rc's' {
            local addvec = 1
            if "`rc'"=="row" {
                matrix vecnull = J(1,`ncols',.z)
                matrix rownames vecnull = _
                matrix colnames vecnull = `colnms'
            }
            else {
                * matrix vecnull = J(`nrows',1,.z)
                matrix vecnull = `matin', J(`nrows',1,.z)
                * grab names from source matrix that can include spaces
                local tmp = colsof(vecnull)
                * keeps names, not content
                matrix vecnull = vecnull[1...,`tmp']
                matrix colnames vecnull = _
                * matrix rownames vecnull = `rownms'
            }
        }
        * build new matrix
        local newvecnm "`LEFTnum'_`operator'_`RIGHTnum'"
        if `unitary' local newvecnm "`operator'_`RIGHTnum'"
*di "newvecnm: `newvecnm'"
        forvalues ivec = 1(1)`n`rc's' {
            local vecnm : word `ivec' of ``rc'nms'
            if "`rc'"=="row" {
                matrix vecis = `matin'[`ivec',1...]
            }
            else {
                matrix vecis = `matin'[1...,`ivec']
            }
            * in ivec is output location, add to matrix
            if `ivec'==`out_index' {
                * name rowcol with operation
                matrix `rc'name vecout = `newvecnm'
*mat list vecout
                matrix matout = nullmat(matout) `concat' vecout
            }
            else {
                matrix matout = nullmat(matout) `concat' vecis
            }
        }
        if `addvec' {
            local nplus1 = `n`rc's' + 1
*di "addvec: `addvec'  outnum: `out_index' nplus1 `nplus1' "
            forvalues ivec = `nplus1'(1)`out_index' {
                if `ivec'==`out_index' {
                    matrix `rc'name vecout = `newvecnm'
                    matrix matout = nullmat(matout) `concat' vecout
                }
                else {
                    matrix matout = nullmat(matout) `concat' vecnull
                }
            }
        }
    } // math operators

//  done with math operators

    matrix `matin' = matout
    _closeup `matin' `list'

end

program _closeup

    args mat list
    capture matrix drop matout
    capture matrix drop vecout
    capture matrix drop vecnull
    capture matrix drop vecR
    capture matrix drop vecL
    capture matrix drop ivec

    if "`list'"=="list" {
        matlist `mat'
    }
end

exit
