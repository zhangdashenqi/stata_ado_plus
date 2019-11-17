*! version 1.0.0 2014-02-18 | freese long | spost13 release

//  list at() matrix after margins

program define mlistat, sclass

    version 11.2

    syntax [anything(name=atmatrix)] , ///
        [   ///
        QUIetly /// only compute matrices; no printing
        omit  /// do not drop omitted and 0b columns
        ALLBASElevels /// do not drop omitted and 0b columns
        ///
        ATvars(string asis) /// select and rename r(at) variables
        ///
        COLEQnm(string asis) /// add equation nm to output
        ROWEQnm(string asis) /// add row nm to output
        ///
        DECimals(numlist >-1 integer) /// digits when list matrix
        width(numlist >5 integer) /// column widths
        ///
        NOSplit /// whether constant vs. varying at()
                /// are split out of output or not
        SAVEConstant(string) SAVEVarying(string) ///
        ///
        NOConstant /// suppress printing of constant results
        NOVary /// suppress printing of novary results
        ///
        FVexpand /// list all factor variables
        ]

    tempname marginsret omitmat selectmat atConstant atVarying

//  trap errors

    local cmd = r(cmd)
    if `"`cmd'"'!="margins" & `"`cmd'"'!="pwcompare" {
        if "`quietly'"=="" {
            display as error ///
            "mlistat must be run following margins"
        }
        sreturn local error "nomargins"
        error 999
    }

    local isat = 1
    capture confirm matrix r(at)
    local no_atreturn = _rc // no_atreturn==0 if r(at) is in memory
    if `no_atreturn' { // error if need at
        if "`quietly'"=="" {
            display _new ///
            "r(at) is not in memory to list"
        }
        sreturn local isat = 0
        sreturn local isvarying = 0
        sreturn local isconstant = 0
        sreturn local error "noat"
        error 999
     }

    capture _return drop `marginsret'
    _return hold `marginsret'
    _return restore `marginsret' , hold

//  parse optons

    * any table formatting implies split
    if  "`corder'"!=""    | "`rorder'"!=""   | "`coleqnm'"!="" ///
        | "`roweqnm'"!="" | "`decimals'"!="" | "`width'"!="" ///
        | "`title'"!="" {

        local split "nosplit"
    }

    local nosave = 0 // save matrix when done?
    if "`atmatrix'"=="" {
        local nosave = 1
        local atmatrix "_mlistat"
        capture matrix drop `atmatrix'
    }

    matrix `atmatrix' = r(at)

    if ("`decimals'"=="") local decimals = 3
    if ("`width'"=="") local width = 8 // 9 2013-08-08

    local fmt "%`width'.`decimals'g"

//  select variables to list

    if "`atvars'"!="" {

        local atmat_colNM : colfullnames `atmatrix'
        _rm_matrix_rclist, rclist(`atvars') ///
                rcnames(`atmat_colNM') unab `quietly'

        if `r(error)'!=0 {
            _return restore `marginsret'
            exit
        }

        matrix `selectmat' = r(selectmat)
        _rm_matrix_select `atmatrix' `selectmat' col

    } // atvars() specified

//  change row values to row numbers

    local atmat_rowN = rowsof(`atmatrix')
    local atmat_rowNMS ""

    forvalues i = 1(1)`atmat_rowN' {
        local atmat_rowNMS "`atmat_rowNMS' `i'"
    }
    matrix rownames `atmatrix' = `atmat_rowNMS'

//  display at values

    if "`nosplit'" == "" {

		if "`fvexpand'" == "" {
             _FVContract `atmatrix'
			 mat `atmatrix' = r(contracted)
        }

         _SplitAtMatrix `atmatrix', title(`title')
        local isconstant = 0
        capture confirm matrix r(atConstant)
        if _rc == 0 {

            matrix `atConstant' = r(atConstant)
            local isconstant = 1
            if "`allbaselevels'" == "" {
                _OmitColumns `atConstant'
                matrix `atConstant' = r(Clean)
            }

            if "`coleqnm'"!="" {
                matrix coleq `atConstant' = `coleqnm'
            }
            if "`roweqnm'"!="" {
                matrix roweq `atConstant' = `roweqnm'
            }

            if "`noconstant'" != "noconstant" {
                local titleconstant "{bf}at() values held constant{sf}"
                matlist `atConstant', names(col) ///
                    title("`titleconstant'") format("`fmt'")
            }
        }

        local isvarying = 0
        capture confirm matrix r(atVarying)
        if _rc == 0 {

            local isvarying = 1
            matrix `atVarying' = r(atVarying)
            if "`allbaselevels'" == "" {
                _OmitColumns `atVarying'
                matrix `atVarying' = r(Clean)
            }
            if "`coleqnm'"!="" {
                matrix coleq `atVarying' = `coleqnm'
            }
            if "`roweqnm'"!="" {
                matrix roweq `atVarying' = `roweqnm'
            }
            if "`novary'" != "novary" {
                local titlevary "{bf}at() values vary{sf}"
                matlist `atVarying', rowtitle("_at") twidth(6) ///
                    title("`titlevary'") format("`fmt'")
            }
        }
    }

    //  no split

    else {

        if "`allbaselevels'" == "" {
            _OmitColumns `atmatrix'
            matrix `atmatrix' = r(Clean)
        }
        if "`coleqnm'"!="" {
            matrix coleq `atmatrix' = `coleqnm'
        }
        if "`roweqnm'"!="" {
            matrix roweq `atmatrix' = `roweqnm'
        }
        matlist `atmatrix', rowtitle("_at") twidth(6) ///
            title("`titlevary'") format("`fmt'")
    }

//  save results if requested and returns

    sreturn local isat `isat'
    sreturn local isvarying `isvarying'
    sreturn local isconstant `isconstant'

    capture confirm matrix `atVarying'
    if _rc == 0 & "`savevarying'"!="" {
        matrix `savevarying' = `atVarying'
    }
    capture confirm matrix `atConstant'
    if _rc == 0 & "`saveconstant'"!="" {
        matrix `saveconstant' = `atConstant'
    }

    _return restore `marginsret'
    if `nosave' capture matrix drop `atmatrix'

end

program define _OmitColumns, rclass

    * omit collinear and base columns

    return add

    syntax [anything]

    tempname omitmat
    * remove b. columns from i. variables
    capture matrix drop `omitmat'
    local colnms : colnames `anything'
    foreach icolnm of local colnms {
        local isbdot = 1 - regexm(`"`icolnm'"',"b\.")
        matrix `omitmat' = nullmat(`omitmat') , `isbdot'
    }
    _rm_matrix_select `anything' `omitmat' col
    * omitted columns if any
    local colN = colsof(`anything')
    _ms_omit_info `anything' // find omitted names
    matrix `omitmat' = J(1,`colN',1) - r(omit)
    _rm_matrix_select `anything' `omitmat' col

    return matrix Clean = `anything'

end

program define _SplitAtMatrix, rclass

    return add

    syntax [anything] , [ title(string) ]

    tempname AtMatrix xVector Constant Varying

//  get r(at) and key facts about it

    matrix `AtMatrix' = `anything' // works with syntax specified in command

    local AtVariables : colnames `AtMatrix'
    local AtRowNames  : rownames `AtMatrix'
    local NAtColumns  = colsof(`AtMatrix')
    local NAtRows     = rowsof(`AtMatrix')

//  loop over all at variables

    forvalues i = 1(1)`NAtColumns' {

        * get name of variable and grab vector for that variable

        local xVariable : word `i' of `AtVariables'
        matrix `xVector' = `AtMatrix'[1..., `i']

       * loop over rows 1..k of at()
       * set IsConstant to FALSE if doesn't match row1

        local IsConstant "TRUE"
        forvalues i = 1(1)`NAtRows' {

            if `xVector'[`i',1] != `xVector'[1,1] {
                local IsConstant "FALSE"
            }
        }

//  check if missing and if so exclude

        local IsMissing "FALSE"
        if "`IsConstant'" == "TRUE" {
            if `xVector'[1,1] >= . {
                local IsMissing "TRUE"
            }
        }

//  add variable names / vector to constant or varying information

        if "`IsConstant'" == "TRUE" {
            if "`IsMissing'" == "FALSE" {
                local AtConstant "`xVariable' `AtConstant'"
                matrix `Constant' = (nullmat(`Constant'), `xVector')
            }
        }
        else {
            local AtVaries "`xVariable' `AtVaries'"
            matrix `Varying' = (nullmat(`Varying'), `xVector')
        }

    } // loop over at variables

//  return results

    capture confirm matrix `Constant'
    if _rc == 0 {
        matrix `Constant' = `Constant'[1,1...]
        return matrix atConstant = `Constant'
    }

    capture confirm matrix `Varying'
    if _rc == 0 {
        return matrix atVarying = `Varying'
    }

end // _SplitAtMatrix

program define _FVContract, rclass

    /*
    contracts varying fv in at() matrix to single column
    assumes about at() matrix:

    - only . in variable names are factor variables
    - only letter before . in factor variable name is b or n
    - variable name is after . in all cases
    */

    return add

    syntax [anything] , [optvary optconst]

    tempname Expanded Contracted ContractedOutOfOrder Vector Factor

	* matrix that includes factor variables as expanded
    matrix `Expanded' = `anything'

    local ColumnNames : colnames `Expanded'

	* make separate lists of the factor variables and non-factor variables
		* also make macro orderlist -- which is order of all columns that could
		* be in final matrix, needed to put columns back in order at the end

	foreach var in `ColumnNames' {
        if strpos("`var'", ".") == 0 {
			local notFVlist "`notFVlist' `var'" // list of non-factor variables
		}
		else {
            local dot = strpos("`var'", ".")
            local FVname = substr("`var'", `dot'+1, .)
			local FVlist "`FVlist' `FVname' "
			local orderlist "`orderlist' `FVname' "
		}
		local orderlist "`orderlist' `var' "
	}
	local FVlistuniq : list uniq FVlist // list of factor variables
	local orderlist: list uniq orderlist // order of possible matrix columns

	* make matrix of just the non-factor variables

	tempname notFVMatrix
	foreach var in `notFVlist' {
		matrix `Vector' = `Expanded'[1..., "`var'"]
        matrix `notFVMatrix' = (nullmat(`notFVMatrix'), `Vector')
	}

	* for each factor variable, extract into its own matrix

	foreach fvar in `FVlistuniq' {
		local FVValueList ""
		tempname fv`fvar'
		foreach var in `ColumnNames' {
			if strpos("`var'", ".") != 0 {
				* where is dot separating value from variable name
				local dot = strpos("`var'", ".")
				local FVname = substr("`var'", `dot'+1, .)
				if "`fvar'" == "`FVname'" {
					* make matrix for each factor variable
					matrix `Vector' = `Expanded'[1..., "`var'"]
					matrix `fv`fvar'' = (nullmat(`fv`fvar''), `Vector')
				} // if column is column of key factor variable
			} // if column is column of any factor variable
		} // loop over all column names in matrix
	} // loop over all factor variables


	* for each factor variable, determine whether it can be contracted
		/* note: a factor variable can be extracted if every row contains
			one value of 1 and rest are 0 */

	foreach fvar in `FVlistuniq' {
		tempname KeyMatrix

		mat `KeyMatrix' = `fv`fvar''
		local KeyRows = rowsof(`KeyMatrix')
		local KeyCols = colsof(`KeyMatrix')

		local C`fvar' "yes" // can factor variable be contracted?

		forvalues i = 1(1)`KeyRows' {
			local onescount = 0
			forvalues j = 1(1)`KeyCols' {
				local k = el("`KeyMatrix'", `i', `j')
				if `k' != 0 & `k' != 1 {
					local C`fvar' "no"
				}
				else if `k' == 1 {
					local onescount = `onescount' + 1
				}
			} // each column of particular row
			if `onescount' != 1 { // check whether one 1 in row
					local C`fvar' "no"
			}
		}
	}

	* build factor variable matrix

	tempname FVMatrix
	foreach fvar in `FVlistuniq' {

		* if factor variable cannot be contracted, add all columns
		if "`C`fvar''" == "no" {
			mat `FVMatrix' = (nullmat(`FVMatrix'), `fv`fvar'')
		} // if factor variable cannot be contracted

		* if factor variable can be contracted, make new vector
		else {
			tempname FVColumn
			local FVValueList ""
			mat `KeyMatrix' = `fv`fvar''

			* determine column values
			local KeyColnames : colnames `KeyMatrix'
			foreach name in `KeyColnames' {
				local dot = strpos("`name'", ".")
				local FVValue = substr("`name'", 1, `dot'-1) // could have b
				if strpos("`FVValue'", "b") != 0 {
					local FVValue = subinstr("`FVValue'", "b", "", .)
					local FVValue = subinstr("`FVValue'", "n", "", .)
					local FVBase = "`FVValue'"
				}
				local FVValueList = "`FVValueList' `FVValue'"
			}

			* determine which column has a one and what value should be assigned
			local KeyRows = rowsof(`KeyMatrix')
			local KeyCols = colsof(`KeyMatrix')
			forvalues i = 1(1)`KeyRows' {
				local VectorValue = 0
				forvalues j = 1(1)`KeyCols' {
					if el("`KeyMatrix'", `i', `j') == 1 {
						local VectorValue : word `j' of `FVValueList'
					}
				} // each column of particular row
			mat `FVColumn' = (nullmat(`FVColumn') \ `VectorValue')
			mat colnames `FVColumn' = "`fvar'"
			} // each row

		mat `FVMatrix' = (nullmat(`FVMatrix'), `FVColumn')
		} // if factor variable can be contracted
	}


	* combine non-factor variable and factor variable matrices

	mat `ContractedOutOfOrder' = (nullmat(`FVMatrix'), nullmat(`notFVMatrix'))

	* rearrange matrix so that the rows are in the right order

	foreach name in `orderlist' {
		cap mat drop `Vector'
		cap mat `Vector' = `ContractedOutOfOrder'[1..., "`name'"]
		if _rc == 0 {
			mat `Contracted' = (nullmat(`Contracted'), `Vector')
		}
	}

	* recreate matrix so rows are in the rows of orderlist

	//  return matrix with row numbers as names

    local rows_contracted = rowsof(`Contracted')
    forvalues i = 1(1)`rows_contracted' {
        local names_contracted "`names_contracted' `i'"
    }
    matrix rownames `Contracted' = `names_contracted'

	return matrix contracted = `Contracted'

end
exit
