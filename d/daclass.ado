*! version 1.3 -- 14/nov05, 02nov05, 31oct05
program define daclass
  version 8.0
  syntax varlist [, Priors ]
  if e(cmd)~="daoneway" {
    error 301
  }
  tempname matc matm vec bigx xx xc
  tempvar grp
  local grpvar = e(group)
  quietly egen `grp' = group(`grpvar') if ~missing(`grpvar') 
  mkmat `varlist', matrix(`bigx')
  local nfunc = colsof(`bigx')
  local bign  = rowsof(`bigx')
  quietly tab `grpvar'
  local ngrp = r(r)
  mat `xx' = J(`bign',`ngrp',0)
  forvalues i = 1/`ngrp' {
    quietly count if `grp'==`i'
    local gnum = r(N)
    quietly mat accum `matc' = `varlist' if `grp'==`i', ///
            nocons deviation mean(`matm')
    mat `matc' = `matc'/(`gnum'-1)
    local lndet = ln(det(`matc'))
    mat `matc' = syminv(`matc')
    forvalues j = 1/`bign' {
      mat `vec' = `bigx'[`j',1..`nfunc']
      mat `vec' = `vec' - `matm'
      mat `xc'  = `vec'*`matc'*`vec'' + `lndet'
      if "`priors'" ~= "" {
        mat `xc' = `xc' + ln(`gnum'/`bign')
      }
      mat `xx'[`j',`i'] = `xc'[1,1]
    }
  }
 
  svmat `xx', names(__da)
  egen __rm = rmin(__da*)
  quietly gen _daclass = .
  forvalues i = 1/`ngrp' {
    quietly replace _daclass = `i' if __rm == __da`i'
  } 
  drop __da* __rm
 
end
