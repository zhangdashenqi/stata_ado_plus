*! Version .92
*! Took out use `using'
*! Took out pwd
*! Took out clear option
*! Version .91
*! changed -99999999 to -9999
capture program drop stata2mplus
program define stata2mplus
  version 7
  syntax [varlist] using/ , [ missing(int -9999) use(varlist) replace ]

  preserve 
  
  * use "`using'" , `clear'

  if ("`varlist'" != "") {
    keep `varlist'
  }

  if ("`varlist'" == "") {
    unab varlist : *
  }

  * convert char to numeric
  foreach var of local varlist {
    local vartype : type `var' 
    if (substr("`vartype'",1,3)=="str") {
      display "encoding `var'"
      tempvar tempenc
      encode `var', generate(`tempenc')
      drop `var'
      rename `tempenc' `var'
    }
  }

  foreach var of local varlist {
    quietly replace `var' = `missing' if `var' >= .
  }

  outsheet using `using'.dat , comma nonames nolabel `replace'

  tempvar out
  capture file close `out'

  quietly file open `out' using "`using'.inp", write text `replace'

  file write `out' "Title: " _newline
  file write `out' "  Stata2Mplus conversion for `using'.dta" _newline

  file write `out' "  List of variables converted shown below" _newline
  file write `out' _newline

  quietly count
  local ncases = `r(N)'
  foreach var of local varlist {
    makelab `var' `out' `ncases'
  }

  file write `out' " " _newline
  file write `out' "Data:" _newline
  file write `out' "  File is `using'.dat ;" _newline

  file write `out' "Variable:" _newline 
  file write `out' "  Names are " _newline "    " 
  local len = 0
  unab varlist : *
  foreach varname of local varlist {
    if `len' > 65 {
      file write `out' _newline "    " 
      local len = 0
    }
    local len = `len' + length(" `varname'") 
    file write `out' " `varname'" 
  }
  file write `out' ";" _newline
  

  file write `out' "  Missing are all (`missing') ; " _newline

  if "`use'" != "" {
    file write `out' "  Usevariables are" _newline "    "
    local len = 0
    unab usevarlist : `use'
    foreach varname of local usevarlist {
      if `len' > 65 {
        file write `out' _newline "    " 
        local len = 0
      }
      local len = `len' + length(" `varname'") 
      file write `out' " `varname'" 
    }
    file write `out' ";" _newline
  }

  file write `out' "Analysis: " _newline
  file write `out' "  Type = basic ;" _newline


  file close `out'

  display as text "Looks like this was a success."
  display as text "To convert the file to mplus, start mplus and run"
  display as text "the file `using'.inp"

  restore

end

capture program drop makelab
program define makelab
  version 7
  * variable name, variable number, n of cases, file handle
  args var myout n

  * display "args `var' `myout' `n'"
  local varl : var label `var'
  file write `myout' `"  `var' : `varl'"' _newline

  local vl : value label `var'
  if "`vl'" == "" {
    exit 0
  }

  tempvar lvar
  tempvar first
  decode `var', gen(`lvar')

  sort `var'
  by `var' : gen `first' = (_n == 1) & `lvar' != ""
 
  local casenum = 1
  while (`casenum' <= `n') {
    if `first'[`casenum'] {
      local v1 = `var'[`casenum']
      local v2 = `lvar'[`casenum']
      file write `myout' `"    `v1': `v2'"' _newline
    }
    local casenum = `casenum' + 1
  } 
end
  
