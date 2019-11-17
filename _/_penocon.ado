*! version 0.2.3 13Apr2005
*  version 0.2.2 2005-03-29 stata 9 bug for aux parameters
*  version 0.2.1 2005-03-25 fixed long varlist bug
*  version 0.2.0 2005-02-03

*   determine if model has a constant in it

capture program drop _penocon
program define _penocon, rclass
    version 9.0
    tempname beta
    matrix `beta' = e(b)
    local nbeta = colsof(`beta')
    local names : colnames `beta'
    local tmpnms : subinstr local names `"_cons"' `"dog"', all count(local count)
    local isnocon = 1 - `count'

// binary

    if "`e(cmd)'"=="cloglog"  {
        local isnocon = `isnocon'
    }
    if "`e(cmd)'"=="logistic" {
        local isnocon = `isnocon'
    }
    if "`e(cmd)'"=="logit"    {
        local isnocon = `isnocon'
    }
    if "`e(cmd)'"=="probit"   {
        local isnocon = `isnocon'
    }

// ordered : nocon not allowed

    if "`e(cmd)'"=="ologit"   {
        local isnocon = 0
    }
    if "`e(cmd)'"=="oprobit"  {
        local isnocon = 0
    }
    if "`e(cmd)'"=="gologit"  {
        local isnocon = 0
    }

// count

    if "`e(cmd)'"=="poisson"  {
        local isnocon = `isnocon'
    }
    if "`e(cmd)'"=="nbreg"    {
        local nrhs = e(df_m)
        local nbeta = `nbeta' - 1 // subtract alpha
        local isnocon = (`nrhs'==`nbeta')
    }

    if "`e(cmd)'"=="zinb"     {
        local tmpnms : subinstr local names `"_cons"' `"dog"', all count(local count)
        local isnocon = (`count'<3)
    }
    if "`e(cmd)'"=="zip"      {
        local tmpnms : subinstr local names `"_cons"' `"dog"', all count(local count)
        local isnocon = (`count'<2)
    }

// regression models

    if "`e(cmd)'"=="regress" | "`e(cmd)'"=="fit" {
        local isnocon = `isnocon'
    }
    if "`e(cmd)'"=="tobit"    {
        * stata 9 includes auxillary parameters as a second equation
        local isnocon = (`count'==1)
    }
    if "`e(cmd)'"=="cnreg"    {
        local isnocon = (`count'==1)
    }
    if "`e(cmd)'"=="intreg"   {
        local isnocon = (`count'==1)
    }

//  nominal

    if "`e(cmd)'"=="mlogit"   {
        _perhs
        local nrhs = r(nrhs)
        local ncatm1 = e(k_cat) - 1
        local isnocon = (`nrhs'*`ncatm1'==`nbeta')
    }

//  return results

    return local nocon  "`isnocon'"

end
