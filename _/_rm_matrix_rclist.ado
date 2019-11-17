*! version 1.0.0 2014-02-14 | long freese | spost13 release

//  _rm_matrix_rclist: evaluate list of rows/cols; create selection vector;
//      create vector of new names based on labels for selected r/c's
//
//  Input
//      rclist:     names or numlist of rows/columns
//                  does not allow mixing names and numbers
//      rcnames:    r/c names of matrix rows/colums
//      rclabels:   labels corresponding to list
//                  labels used to create new names for rows/columns
//      quietly:    suppress printing of error message
//      unab        unabbreviate names before evaluating
//
//  Output
//      local error "`r(error)'"
//      matrix selectmat = r(selectmat)  // r|c to select
//             // one element for each r|c in source; 1 if select; else 0
//      matrix indexmat = r(indexmat)  // dimension is number of selected r|cs
//             // elements are r|c #s in source matrix to select
//             // allows selection with rearranging
//      local isnumlist = `r(isnumlist)' // 1 if numlist used; else 0
//      local newnames "`r(newnames)'"   // names for selectdd columns
//

program define _rm_matrix_rclist, rclass

    syntax , ///
            rclist(string)   /// selection names or numlist for matrix
            rcnames(string)  /// row/col names in matrix
          [ rclabels(string) /// labels corresponding to rcnames
                             ///     for reassigning names
            quietly unab ]

    tempname selectmat indexmat null null2
    local error = 0
    local rcnamesN = wordcount("`rcnames'")
    matrix `null' = J(1,1,.)
    matrix `null2' = J(1,1,.)
    matrix `selectmat' = J(1,`rcnamesN',0)
    matrix colnames `selectmat' = `rcnames'

    * labels are used in output; if no labels, use list
    if ("`rclabels'"=="") local rclabels "`rclist'"

//  does it mix names and numbers?

    local templist "`rclist'"
    * remove 1. style stuff
    local templist = regexr("`templist'","[0-9].","")
    local isanyalpha = regexm("`templist'","[a-zA-Z]")
    local isanynum   = regexm("`templist'","[0-9]")
    local isletnum   = regexm("`templist'","[a-z]+[0-9]+")

    if `isanyalpha' & `isanynum' & !`isletnum'{
        di "list (`rclist') cannot include both names and numbers"
        local error = 1
        exit
    }

//  is list a numlist?

    capture numlist "`rclist'"
    if _rc==0 {

        local isnumlist = 1
        * is it a valid numlist for the matrix dimensions
        capture numlist "`rclist'", integer range(>=1 <=`rcnamesN')
        local colnums `r(numlist)'

        if _rc!=0 {
            if "`quietly'"=="" {
                di as error "invalid numlist `rclist'"
                return local error = 1
                return matrix selectmat `null'
                return matrix indexmat  `null2'
                return local isnumlist `isnumlist'
                exit
            }
        }

        else {
            local newnames ""
            local isnumlist = 1
            foreach icol in `colnums' {
                local nm : word `icol' of `rclabels'
                local newnames "`newnames' `nm'"
                matrix `selectmat'[1,`icol'] = 1 // 1 if keep
                matrix `indexmat' = nullmat(`indexmat') , `icol'
            }
        }

    } // numlist

//  name list

    else {
        local isnumlist = 0
        if "`unab'"=="unab" {
            * this assume that it is based on a variable in memory
            capture fvexpand `rclist'

            if _rc>0 {
                di as error ///
                "invalid name in `rclist' when decoded by fvexpand"
                return local error = 1
                return matrix selectmat `null'
                return matrix indexmat  `null2'
                return local isnumlist `isnumlist'
                exit
            }
            local rclist_unab "`r(varlist)'"
        }
        else local rclist_unab "`rclist'"

        local ilist = 0
        local newnames ""
        foreach varnm in `rclist_unab' {

            local ++ilist
            local lbl : word `ilist' of `rclabels'
            local icol : list posof "`varnm'" in rcnames

            if `icol'==0 {
                if "`quietly'"=="" {
                    di as error "invalid name `varnm' in rclist()"
                    local error = 1
                    continue, break
                }
            }
            else {
                local newnames "`newnames' `lbl'"
                matrix `selectmat'[1,`icol'] = 1 // 1 if keep
                matrix `indexmat' = nullmat(`indexmat') , `icol'
            }
        }

        if `error' {
            return local error = 1
            return matrix indexmat  `null'
            return matrix selectmat `null2'
            return local isnumlist `isnumlist'
            return local newnames ""
            exit
        }

    } // name list

    return local  error `error'
    return local  isnumlist `isnumlist'
    return matrix selectmat `selectmat'
    return local  newnames "`newnames'"
    return matrix indexmat `indexmat'

end
exit

EXAMPLE

sysuse binlfp4, clear
logit lfp k5 k618 i.agecat i.wc hc lwg inc, nolog
margins, at(agecat=(1 2 3) wc=(0 1))
matrix decode = r(at)
local rcnames : colnames(decode)

* bad name
_rm_matrix_rclist, rclist(dog) rclabels(cat) rcnames(`rcnames')
    mat list r(selectmat)
    di "isnumlist: `r(isnumlist)'"
    di "error:     `r(error)'"
    di "selected names: `r(newnames)'"
    mat list r(indexmat)
* agecat and wc  not fv's
_rm_matrix_rclist, rclist(agecat wc) rcnames(`rcnames')
    mat list r(selectmat)
    di "isnumlist: `r(isnumlist)'"
    di "error:     `r(error)'"
    mat list r(indexmat)

* agecat and wc  not fv's
_rm_matrix_rclist, rclist(2.agecat 3.agecat 1.agecat 1.wc) rcnames(`rcnames')
    mat list r(selectmat)
    di "isnumlist: `r(isnumlist)'"
    di "error:     `r(error)'"
    mat list r(indexmat)
