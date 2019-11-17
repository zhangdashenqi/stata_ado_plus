program define sumsum
  version 6.0 
  syntax varlist [,Detail Varname]

  if "`varname'" == "varname" {
    unab allvar : `varlist'
    display "Compute sums of variables: `allvar'"
  }
  tokenize `varlist' 
  scalar sumsum = 0
  while "`1'" != "" {  
    quietly summarize `1'
    scalar sumsum = sumsum + r(sum)
    if "`detail'" != "" {
      display "sum of `1' is " in green, _col(20) %15.2gc r(sum) in yellow
    }
    macro shift
  }
  if "`detail'"!="" {
    display "------------------------------------" in yellow
  }
  display "sum of sums is " in green, _col(20) %15.2gc sumsum in yellow
end
