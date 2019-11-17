*! version 1.0.0 2014-02-14 | long freese | spost13 release

//  Select columns/rows by deleting r/c with all missing
//
//      _rm_matrix_nomiss `inputmatrix' row|col "`names'"
//
//      names: optional names of r or c of input matrix

program _rm_matrix_nomiss, sclass

    version 11.2

    args inputmat rowcol names

    local rnames : rownames `inputmat'
    local cnames : colnames `inputmat'

    * operations below are column based, so transpose for row selectin
    if "`rowcol'"=="col" {
        local selectnms `cnames'
        local keepnms   `rnames'
        matrix `inputmat' = `inputmat''
    }
    else if "`rowcol'"=="row" {
        local selectnms `rnames'
        local keepnms   `cnames'
    }
    else {
        di as error "option -row- or -col- must be specified"
        exit
    }

    if "`names'"=="" {
        * use rnames and cnames
    }
    else {
        local nnames = wordcount("`names'")
        local selectnms `names'
        local ncols = colsof(`inputmat')
        if `nnames'!=`ncols' {
            di as error "# of input names must match # rows/cols of matrix"
            exit
        }
    }

    * create selection matrix
    mata: inputmat = st_matrix(st_local("inputmat"))
    mata: nomiss = (colsum(inputmat' :==.):!=rows(inputmat'))'

    * select columns
    mata: newmat = select(inputmat, nomiss)
    mata: st_matrix(st_local("inputmat"),newmat)
    mata: st_matrix("nomiss",nomiss)

    * names for selected columns
    local names_sel ""
    local i = 0
    foreach nm of local selectnms {
        local ++i
        local keep = nomiss[`i',1]
        if `keep' local names_sel `names_sel' `nm'
    }
    matrix rownames `inputmat' = `names_sel'
    matrix colnames `inputmat' = `keepnms'
    if "`rowcol'"=="col" {
        matrix `inputmat' = `inputmat''
    }
    capture matrix drop nomiss

end
exit

EXAMPLES

tempname inputC inputCmiss inputR inputRmiss
mat `inputR' = J(3,5,1)
mat `inputRmiss' = J(3,5,.)
mat `inputR' = `inputR' \ `inputRmiss' \ `inputR'
mat `inputC ' = J(3,5,1)

mat `inputCmiss ' = J(3,5,.)
mat `inputC' = `inputC' \ `inputCmiss' \ `inputC'
mat inputC = `inputC''

mat list inputC
_rm_matrix_nomiss inputC col  // "`colnames'"
mat list inputC
set trace off

mat list `inputR'
_rm_matrix_nomiss `inputR' row  // "`colnames'"
mat list `inputR'
