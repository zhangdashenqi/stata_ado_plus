*! version 1.0 -- pbe -- 11/30/06
program define tablabel 
  version 8.2
  syntax varlist [if/] [in]
  
  if "`if'"~="" {
      local if = " & `if'"
  }
  
  foreach variable of varlist `varlist' {
    local val : value label `variable'
    quietly label list `val'
    local min=r(min)
    local max=r(max)
    local varl : variable label `variable'
    display
    display as txt "Variable: `variable' -- `varl'"
    display
    display as txt "Value   Freq   Label"
    forvalues i=`min'/`max' {
       quietly count if `variable'==`i' `if' `in'
       local vl : label (`variable') `i'
       display as res %5.0f `i' "  " %5.0fc r(N) "   `vl'"  
    }
    display
    quietly count if missing(`variable') `if'
    local nmiss = r(N)
    if `nmiss'>0 {
    display as txt "Missing observations: `nmiss'"
    } 
    quietly count if `variable'<`min' `if' `in'
    local bc = r(N) 
    quietly count if `variable'>`max' & `variable'~=. `if' `in'
    local bc = `bc' + r(N) 
    if `bc'>0 {
      display as txt "Nonmissing values with no value labels: `bc'"
    }
  }
end

