*! version 1.1.0 2014-08-14 | long freese | r(error) for estimable
*  version 1.0.0 2014-02-14 | long freese | spost13 release

//  Select columns/rows by deleting r/c with omitted o. names
//
//  _rm_matrix_noomitted `inputmatrix' row|col "`names'"
//
//      names: optional names of r or c of input matrix

program _rm_matrix_noomitted, sclass

    version 11.2

    args inputmat rowcol names

    tempname omitmat rerror
    matrix `rerror' = r(error) // from margins if not estimable

    * operations below are column based, so transpose for row selectin
    if ("`rowcol'"=="row") matrix `inputmat' = `inputmat''
    else if "`rowcol'"=="col" {
        * hold for now
    }
    else {
        di as error "option -row- or -col- must be specified"
        exit
    }

    * use names in matrix if user doesn't provide names
    if ("`names'"=="") local names : colfullnames `inputmat'
    else {
        local namesN = wordcount("`names'")
        local colsN = colsof(`inputmat')
        if `namesN'!=`colsN' {
            di as error "# of input names must match # rows/cols of matrix"
            exit
        }
    }
    * later restore names on dimension not being select
    local rnames : rowfullnames `inputmat'

    mata: inputmat = st_matrix(st_local("inputmat"))
    local colsN = colsof(`inputmat')

    * create selection matrix; drop o. in stripe unless not estimable
    _ms_omit_info `inputmat'
    matrix `omitmat' = J(1,`colsN',1) - r(omit)
    * initially select if not o. in stripe
    mata: selectmat = st_matrix(st_local("omitmat"))

    * if r(error) in memory, add back in non-estimable functions
    if `rerror'[1,1]!=. {
        mata: rerror = st_matrix(st_local("rerror"))
        mata: selectmat = ((rerror :== 8) :+ selectmat) :>=1
    }
    mata: newmat = select(inputmat,selectmat)
    mata: st_matrix(st_local("inputmat"),newmat)

    * names for selected columns
    local names_sel ""
    local i = 0
    foreach nm of local names {
        local ++i
        local keep = `omitmat'[1,`i']
        if `keep' local names_sel `names_sel' `nm'
    }

    matrix colnames `inputmat' = `names_sel'
    matrix rownames `inputmat' = `rnames'

    if ("`rowcol'"=="row") matrix `inputmat' = `inputmat''

end
exit
