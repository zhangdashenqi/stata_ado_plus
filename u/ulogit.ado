*! version 1.1.0
* Program to calculate univariate logistic regression statistics
* over the array of predictors : optional degrees of freedom up to 3
* Joseph Hilbe 8/15/92

capture program drop ulogit
program define ulogit
version 4.0
  local varlist "req ex min(2)"
  local options "`options' DF(integer 1)"
  local in "opt"
  local if "opt"
  local weight "fweight"
  parse "`*'"
  parse "`varlist'", parse(" ")
  tempvar dpvar llo
  gen `dpvar'=`1' `if' `in'
  mac shift
  local df=`df'
  qui logit `dpvar' `1' `if' `in', or
  gen `llo'=-(_result(6) + (-2*_result(2)))/2 `if' `in'
  noi di in gr _n(1) _col(20) "Univariate Logistic Regression Models"
*  noi di in gr _n _col(28) "`df' Degree of Freedom"
  noi di in gr _n _col(1)  "Intercept LL = " %9.4f `llo'  _col(56) "1 degree of freedom"
  noi di in gr _n(1) _col(1) "Variable" _col(14) "OR"  _col(27) "LL" _col(38) "Chi2" _col(48) "Prob" _col(59) "95 percent CI"     
  noi di in gr "__________________________________________________________________________"
  noi di _n
  
  cap  {
  
  if "`df'" == "2"  {
    while "`1'" != "" {
       qui logit `dpvar' `1' `2', or
       noi di in gr _col(1) "`1'" in ye _col(10) %9.4f _b[`1'] _col(25) %9.4f _se[`1'] _col(40) %9.4f _result(2)  _col(55) %9.4f _result(6)  _col(70) %6.4f chiprob(`df',_result(6)) 
       noi di in gr _col(1) "`2'" in ye _col(10) %9.4f _b[`2'] _col(25) %9.4f _se[`2']         
       mac shift
       mac shift
     }
  }
  if "`df'" == "3"  {
    while "`1'" != "" {
       qui logit `dpvar' `1' `2' `3', or
       noi di in gr _col(1) "`1'" in ye _col(10) %9.4f _b[`1'] _col(25) %9.4f _se[`1'] _col(40) %9.4f _result(2)  _col(55) %9.4f _result(6)  _col(70) %6.4f chiprob(`df',_result(6)) 
       noi di in gr _col(1) "`2'" in ye _col(10) %9.4f _b[`2'] _col(25) %9.4f _se[`2']         
       noi di in gr _col(1) "`3'" in ye _col(10) %9.4f _b[`3'] _col(25) %9.4f _se[`3']                      
       mac shift
       mac shift
       mac shift
    }
  }

  else     { 
        while "`1'" != "" {
        qui logit `dpvar' `1' `if' `in', or
        noi di in gr _col(1) "`1'" in ye _col(9) %9.4f exp(_b[`1']) _col(21) %9.3f _result(2)  _col(35) %9.3f _result(6)  _col(47) %6.4f chiprob(`df',_result(6)) _col(55) %9.4f exp(_b[`1']-1.96 * _se[`1']) _col(66) %9.4f exp(_b[`1']+1.96 * _se[`1'])
        mac shift
          }
  }

}
if _rc~=0 { di in red "Check for perfect prediction" }

end

  
