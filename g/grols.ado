*! mnm updated, 1/24/04, changed clear to drop _all
capture program drop grols
program define grols
  version 6.0
  
  * capture _grolsw1

  _grolsw2 , xpt

end

capture program drop _grolsw1
program define _grolsw1
  version 6.0
  window manage forward dialog

  global test0 "Show OLS regression line betweeen X and Y."
  window control static test0 10 10 190 10

  global DB_xpt 0
  window control check "Show point at X and pred. value of Y" 10 20 150 10 DB_xpt

  global DB_done "quietly exit 3000"
  window control button "Continue" 10 40 30 10 DB_done default

  window dialog "Graph OLS Regression" . .  170 80

end

capture program drop _grolsw2
program define _grolsw2
  version 6.0
  syntax [, xpt]

  preserve

  global xpt `xpt'

  global xunits 11
  global options "ylabel(-10 -8 to 30) xlabel(1 2 to 10)"

  _reset
  _olsreca
  _olsdia

end

capture program drop _olsdia
program define _olsdia
  version 6.0
  window manage forward dialog

  window control static eq1 10 1 80 10
  window control static eq2 10 12 80 10
  if "$xpt" != "" {
    window control static eq3 10 22 80 10
  }

  global DB_aplus "_aplus"
  window control button "a+1" 10 40 15 10 DB_aplus

  global DB_amin "_amin"
  window control button "a-1" 10 55 15 10 DB_amin

  global DB_bplus "_bplus"
  window control button "b+.1" 35 40 15 10 DB_bplus

  global DB_bmin "_bmin"
  window control button "b-.1" 35 55 15 10 DB_bmin

  if "$xpt" != "" {
    global DB_xplus "_xplus"
    window control button "X+1" 60 40 15 10 DB_xplus

    global DB_xmin "_xmin"
    window control button "X-1" 60 55 15 10 DB_xmin
  }

  global DB_done "quietly exit 3000"
  window control button "Done" 5 70 25 10 DB_done escape

  global DB_reset "quietly _reset"
  window control button "Reset" 40 70 25 10 DB_reset 

  global DB_help "quietly whelp grols"
  window control button "Help" 75 70 25 10 DB_help 


  window dialog "Graph OLS Regression" . .  110 110
  window dialog update

end

capture program drop _olsreca
program define _olsreca
  global DB_a2 = string($DB_a,"%6.2f")
  global DB_b2 = string($DB_b,"%6.2f")
  global DB_yhat = string($DB_a + $DB_x * $DB_b,"%6.2f")
  global tempx "Yhat given X = $DB_x is $DB_yhat"

  global eq1 "Yhat = a + b * X" 
  global eq2 "Yhat = $DB_a2 + $DB_b2 * X" 
  global eq3 "$DB_yhat = $DB_a2 + $DB_b2 * $DB_x" 

  if "$xpt" != "" {
    quietly _grols , a($DB_a) b($DB_b) xunits($xunits) xpt($DB_x) $options
  } 
  else {
    quietly _grols , a($DB_a) b($DB_b) xunits($xunits) $options
  } 

end

capture program drop _aplus
program define _aplus
  global DB_a = $DB_a + 1
  _olsreca
  window manage forward dialog
end

capture program drop _amin
program define _amin
  global DB_a = $DB_a - 1
  _olsreca
  window manage forward dialog
end

capture program drop _bplus
program define _bplus
  global DB_b = $DB_b + .1
  _olsreca
  window manage forward dialog
end

capture program drop _bmin
program define _bmin
  global DB_b = $DB_b - .1
  _olsreca
  window manage forward dialog
end

capture program drop _xplus
program define _xplus
  global DB_x = $DB_x + 1
  _olsreca
  window manage forward dialog
end

capture program drop _xmin
program define _xmin
  global DB_x = $DB_x - 1
  _olsreca
  window manage forward dialog
end

capture program drop _reset
program define _reset
  global DB_a = 0
  global DB_b = 1
  global DB_x = 0
  _olsreca
  window manage forward dialog
end

capture program drop _grols
program define _grols

  version 6.0

  syntax [,a(real 0) b(real .1) xunits(integer 10) xpt(real 999) l1(string) l2(string) t2(string) b2(string) *]

  preserve
  drop _all // mnm changed

  set obs `xunits'
  generate x = _n-1
  gen yhat = `a' + x * `b'


  if "`l1'" == "" {
    local l1 = "."
  }
  if "`l2'" == "" {
    local l2 = "Predicted Value of Y"
  }
  if "`b2'" == "" {
    local b2 = "Value of Predictor (e.g. x)"
  }
  if "`t2'" == "" {
    local t2 = "Graph of Predicted Value of Y by X, where a=`a' and b=`b'"
  }

  if `xpt' != 999 {
    local xobs = `xunits'+1
    set obs `xobs'
    replace x = `xpt' in `xobs'
    gen y2 = `a' + x * `b' in `xobs'
    graph yhat y2 x, c(l.) s(.S) l1("`l1'") l2("`l2'") b2("`b2'") t2("`t2'") `options'
  }
  else {
    graph yhat x, c(l) s(.) l1("`l1'") l2("`l2'") b2("`b2'") t2("`t2'") `options'
  }
  * restore

end

