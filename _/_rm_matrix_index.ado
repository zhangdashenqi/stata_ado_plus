*! version 1.0.0 2014-02-14 | long freese | spost13 release

//  Select columns/rows from at matrix and returns matrix by index #
//
//  _rm_matrix_index `inputmatrix' `indexmatrix' row|col "`names'"
//      inputmatrix: the matrix to be selected from
//      indexmatrix: matrix with indices to be selected; e.g. 1, 2, 5
//
//      names: optional names of r or c of input matrix
//
//  Unlike _rm_matrix_select which uses select(), this allows reordering
//  of rows and columns. _select keeps original order

program _rm_matrix_index, sclass

    version 11.2

    args inputmat indexmat rowcol names

    * operations below are column based, so transpose for row input
    if "`rowcol'"=="row" {
        matrix `inputmat' = `inputmat''
    }
    else if "`rowcol'"=="col" {
        * hold for later additions
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

    * later restore names on dimension not being selected
    local rnames : rownames `inputmat'

    * make sure index vector is 1xK
    local scols = colsof(`indexmat')
    if `scols'==1  {
        matrix `indexmat' = `indexmat''
    }

    mata: indexmat = st_matrix(st_local("indexmat"))
    mata: newmat    = st_matrix(st_local("inputmat"))
    mata: newmat = newmat[.,indexmat]
    mata: st_matrix(st_local("inputmat"),newmat)

    * names for selected columns
    local names_sel ""
    local ncols = colsof(`indexmat')
    forvalues i = 1(1)`ncols' {
        local isel = `indexmat'[1,`i']
        local nm : word `isel' of `names'
        local names_sel `names_sel' `nm'
    }

    matrix colnames `inputmat' = `names_sel'
    matrix rownames `inputmat' = `rnames'

    if "`rowcol'"=="row" {
        matrix `inputmat' = `inputmat''
    }

end
exit
