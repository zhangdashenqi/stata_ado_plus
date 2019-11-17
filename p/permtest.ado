!* Version 2.3, DGC Jan 2003
program define permtest
  version 7.0
  syntax [varlist (default=none)] [fw aw pw iw], /*
    */ PROGram(string) PERMute(varname) /*
    */ TEsts(string) [ NUMber(integer 1000) WIthin(varlist) CLUSter(varlist) /*
    */ NOIsily SAVing(string) REPlace DOTS EVery(integer 10) * ]
  local progwt 
  if "`weight'"!="" {
    local progwt "[`weight'`exp']"
  }
  return clear
  preserve
  foreach test of local tests {
    scalar N_`test'=0
  }
  if "`options'"!="" {
    local options ", `options'"
  }
  quietly {
    `noisily' `program' `varlist' `progwt' `options'
    foreach test of local tests {
      local value  = r(`test')
      if `value'==. {
        di in red "No return value for {bf:`test'}"
        exit
      }
      scalar V_`test'=`value'
    }
    if "`saving'"!="" {
      tempname pname
      postfile `pname' `tests' using `saving', `replace'
    }
    local rpopt
    if "`within'"!="" {
      local rpopt "`rpopt' by(`within')"
    }
    if "`cluster'"!="" {
      local rpopt "`rpopt' cluster(`cluster')"
    }
    forvalues i = 1/`number' {
      rperm `permute', `rpopt'
      `noisily' `program' `varlist' `progwt' `options'
      local res
      foreach test of local tests {
        local value = r(`test')
        if `value' >= V_`test' {
          scalar N_`test' = N_`test' + 1
        }
        if "`saving'"!="" {
          local res "`res' (`value')"
        }
      }
      if "`saving'"!="" {
        post `pname' `res'
      }
      if "`dots'" != "" {
        if mod(`i', `every')==0 {
          noi di "." _continue
        }
      }
      
    }
  }
  if "`saving'"!="" {
    postclose `pname'
  }
  di
  di "--------------------------------------------------------------"
  di _column(16) %15s = "Realised" _column(21) %30s = "Values >= Realised"
  di %15s = "Test" %15s = "Value" %15s = "Number" %15s = "Percent"
  di "--------------------------------------------------------------"
  foreach test of local tests {
    di %15s = "`test'" _skip(2) %13.5g = V_`test' %15.0f = N_`test' /*
              */ %15.3f = 100*N_`test'/`number'
  }
  di "--------------------------------------------------------------"
  restore
  end


