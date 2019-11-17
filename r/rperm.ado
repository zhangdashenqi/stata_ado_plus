*! Version 2.1, Jan 2004 David Clayton
program define rperm
  version 7.0
  syntax varname [, BY(varlist) ORDer CLuster(varlist) GENerate(string)]
  if "`generate'"!="" {
    capture confirm new var `generate'
    if _rc!=0 {
      di in red "Invalid variable name in generate() option"
      exit
    }
  }
  tempvar u r w o i 
  if "`order'" != "" {
    gen `o' = _n
  }
  if "`cluster'"!="" {
    sort `cluster'
    quietly {
      by `cluster': gen byte `w' = (`varlist'!=`varlist'[1])
      foreach var of local by {
        by `cluster': replace `w' = 1 if `var'!=`var'[1]
      }
      count if `w'
      if r(N) > 0 {
        noi di in red "Perm variable and {bf: by} variables must be " _continue
        noi di in red "constant within clusters"
        exit
      }
      quietly {
        drop `w'
        by `cluster': gen int `i' = _n
      }
    }
  }
  else {
    gen byte `i' = 1
  }
  quietly gen `u' = uniform() if `i'==1
  if "`by'" == "" {
    sort `i'
    gen `r' = _n
    sort `i' `u' 
    quietly gen `w' = `varlist'[`r'] if `i'==1
  }
  else {
    sort `by' `i'
    by `by': gen `r' = _n
    sort `by' `i' `u' 
    quietly { 
      by `by': gen `w' = `varlist'[`r'] if `i'==1
    }
  }
  if "`cluster'"!="" {
    sort `cluster' `i'
    quietly by `cluster': replace `w' = `w'[1]
  }
  if "`order'" != "" {
    sort `o'
  }
  if "`generate'"=="" {
    drop `varlist'
    rename `w' `varlist'
  }
  else {
    rename `w' `generate'
  }
  end
