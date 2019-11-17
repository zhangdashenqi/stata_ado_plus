*! version 1.0.0 2014-02-14 | long freese | spost13 release

//  Select columns/rows from at matrix and returns matrix
//
//  _rm_matrix_select `inputmatrix' `selectmatrix'  row|col "`names'"
//
//      names: optional names of r or c of input matrix

//  DO: _rm_matrix_select does not restore equation names to matrices

program _rm_matrix_select, sclass

    version 11.2

    args inputmat selectmat rowcol names

    * operations below are column based, so transpose for row selectin
    if "`rowcol'"=="row" {
        matrix `inputmat' = `inputmat''
    }
    else if "`rowcol'"=="col" {
        * hold for now
    }
    else {
        di as error "option -row- or -col- must be specified"
        exit
    }

    * use names in matrix if user doesn't provide names
    if "`names'"=="" {
        local names : colnames `inputmat'
    }
    else {
        local nnames = wordcount("`names'")
        local ncols = colsof(`inputmat')
        if `nnames'!=`ncols' {
            di as error "# of input names must match # rows/cols of matrix"
            exit
        }
    }
    * later restore names on dimension not being select
    local rnames : rownames `inputmat'

    * make sure selection vector is Kx1
    local scols = colsof(`selectmat')
    if `scols'==1  {
        matrix `selectmat' = `selectmat''
    }

    * select columns
    mata: selectmat = st_matrix(st_local("selectmat"))
    mata: newmat    = select(st_matrix(st_local("inputmat")), selectmat)
    mata: st_matrix(st_local("inputmat"),newmat)

    * names for selected columns
    local names_sel ""
    local i = 0
    foreach nm of local names {
        local ++i
        local keep = `selectmat'[1,`i']
        if `keep' local names_sel `names_sel' `nm'
    }

    matrix colnames `inputmat' = `names_sel'
    matrix rownames `inputmat' = `rnames'

    if "`rowcol'"=="row" {
        matrix `inputmat' = `inputmat''
    }

end
exit

EXAMPLES

tempname inputC inputR selectR selectC
mat `inputC' = J(3,5,1)
mat `inputR ' = J(3,5,1)
mat `selectC' = J(5,1,1)
mat `selectC'[1,1] = 0
mat `selectC'[2,1] = 0
mat `selectR' = J(3,1,1)
mat `selectR'[2,1] = 0

* select col 3 4 5
mat list `inputC'
_rm_matrix_select `inputC' `selectC' col  // "`colnames'" "`rowcol'"
mat list `inputC'

* select row 1 3
mat list `inputR'
_rm_matrix_select `inputR' `selectR' row  // "`colnames'" "`rowcol'"
mat list `inputR'

//  user names

mat `inputC' = J(3,5,1)
mat `inputR ' = J(3,5,1)
mat `selectC' = J(5,1,1)
mat `selectC'[1,1] = 0
mat `selectC'[2,1] = 0
mat `selectR' = J(3,1,1)
mat `selectR'[2,1] = 0
local colnames "a b c d e"
local rownames "ra rb rc rd re"

* select col 3 4 5
_rm_matrix_select `inputC' `selectC' col  "`colnames'"
mat list `inputC'

* select row 1 3
_rm_matrix_select `inputR' `selectR' row  "`rownames'"
mat list `inputR'
