*! mnm updated, 1/24/04, changed clear to drop _all
capture program drop grlog
program define grlog
  version 6.0
  
  capture _grlogw1

  local opts = ""

  * depdent as
  if $DB_dep == 1 {
     global dep="py"
  }
  if $DB_dep == 2 {
     global dep="logity"
  }
  if $DB_dep == 3 {
     global dep="oddsy"
  }

  * input as
  if $DB_inp == 1 {
     global inp="or"
  }
  if $DB_inp == 2 {
     global inp="b"
  }

  * if db_xpt , then show point (xpt option)
  global xpt=$DB_xpt

  _grlogw2

end

capture program drop _grlogw1
program define _grlogw1
  version 6.0
  syntax [, xpt logit]

  window manage forward dialog

  global test0 "Make a logistic regression graph betweeen X and Y..."
  window control static test0 10 1 190 10

  global test1 "Showing the Predicted Value of Y as..."
  window control static test1 10 10 120 10
  global z1 "Probability Y=1"
  global DB_dep 1
  window control radbegin "Probability Y=1" 15 20 80 10 DB_dep
  window control radend   "Logit of Y (Log Odds Y=1)" 15 30 90 10 DB_dep
  * window control radio    "Odds Y=1" 15 30 80 10 DB_dep

  global DB_inp 2
 *  global test2 "Show Predicted Value of Y as a function of..."
 * window control static test2 10 60 150 10
 * window control radbegin "The Odds Ratio" 15 70 80 10 DB_inp
 * window control radend   "The Logistic Regression Coefficient" 15 80 120 10 DB_inp
  
  global DB_xpt 0
  window control check "Show point for Yhat given X" 15 45 120 10 DB_xpt

  global DB_done "quietly exit 3000"
  window control button "Continue" 40 60 40 10 DB_done default

  window dialog "Graph Logistic Regression" . .  180 90

end

capture program drop _grlogw2
program define _grlogw2
  version 6.0

  preserve

  _reset

  global xunits 31

  if "$dep"=="py" {
    global options "ylabel(0 .1 to 1) xlabel(-10 -9 to 10)"
  }
  if "$dep"=="oddsy" {
    global options "ylabel(0 1 to 10) xlabel(-10 -9 to 10)"
  }
  if "$dep"=="logity" {
    global options "ylabel(-30 -25 to 30) xlabel(-10 -9 to 10)"
  }

  _logreca

  _logdia

end

capture program drop _logdia
program define _logdia
  version 6.0
  window manage forward dialog

  *window control static eq1 10 1 180 10
  *window control static eq2 10 12 180 10
  if $xpt == 1 {
    *window control static eq3 10 22 180 10
  }

  window control static ais 10 10 20 10

  global DB_amin "_amin"
  window control button "a-.1" 35 10 15 10 DB_amin

  global DB_aplus "_aplus"
  window control button "a+.1" 55 10 15 10 DB_aplus


  window control static bis 10 25 20 10

  global DB_bmin "_bmin"
  window control button "b-.1" 35 25 15 10 DB_bmin

  global DB_bplus "_bplus"
  window control button "b+.1" 55 25 15 10 DB_bplus


  if $xpt == 1 {
    window control static xis 10 40 15 10

    global DB_xmin "_xmin"
    window control button "X-1" 35 40 15 10 DB_xmin

    global DB_xplus "_xplus"
    window control button "X+1" 55 40 15 10 DB_xplus

    window control static eq3 10 55 100 10 
  }

  global DB_amov "_amov"
  window control button "Show Movie Varying a" 10 70 90 10 DB_amov

  global DB_bmov "_bmov"
  window control button "Show Movie Varying b" 10 85 90 10 DB_bmov

  global DB_xxx = "Movie Delay="
  window control static DB_xxx      10 100 50 10 

  global DB_slpL 0,.1,.2,.3,.4,.5,.6.,.7,.8,.9,1
  global DB_slp = .1
  window control scombo DB_slpL     60 100 35 40 DB_slp parse(,)



  global DB_done "quietly exit 3000"
  window control button "Done" 5 120 25 10 DB_done escape

  global DB_reset "quietly _reset"
  window control button "Reset" 40 120 25 10 DB_reset 

  global DB_help "quietly whelp grlog"
  window control button "Help" 75 120 25 10 DB_help 


  window dialog "Graph Logis. Regression" . .  110 150
  window dialog update

end

capture program drop _logreca
program define _logreca

  global DB_a2 = string($DB_a,"%3.1f")
  global DB_b2 = string($DB_b,"%3.1f")
  global DB_yhat = string($DB_a + $DB_x * $DB_b,"%4.2f")
  global tempx "Yhat given X = $DB_x is $DB_yhat"

  global ais="a=$DB_a2"
  global bis="b=$DB_b2"
  global xis="x=$DB_x"

  if "$dep"=="py" { 
    global eq1 "Phat(y=1)= 1 - 1 / exp( a + b * X) " 
    global eq2 "Phat(y=1) = 1 - 1 / (1 + exp($DB_a2 + $DB_b2 * $DB_x))" 
    global temppy1 "1 - 1 / (1 + exp($DB_a2 + $DB_b2 * $DB_x))"
    global temppy2 = string($temppy1,"%3.2f")
    * global eq3 "$temppy2 = 1 - 1 / (1 + exp($DB_a2 + $DB_b2 * $DB_x))"
    global eq3 "Predicted P(Y=1) is $temppy2"
  }
  if "$dep"=="logity" { 
    global eq1 "Logit(Y) = a + b * X" 
    global eq2 "Logit(Y) = $DB_a2 + $DB_b2 * X" 
    global temppy1 = $DB_a2 + $DB_b2 * $DB_x
    global temppy2 = string($temppy1,"%3.2f")
    * global eq3 "$temppy2 = $DB_a2 + $DB_b2 * $DB_x"
    global eq3 "Predicted Logit(Y=1) is $temppy2"
  }
  if "$dep"=="oddsy" { 
    global eq1 "Odds(y=1)= exp( a + b * X) " 
    global eq2 "Odds(y=1) = exp($DB_a2 + $DB_b2 * $DB_x))" 
    global temppy1 "exp($DB_a2 + $DB_b2 * $DB_x)"
    global temppy2 = string($temppy1,"%3.2f")
    * global eq3 "$temppy2 = exp($DB_a2 + $DB_b2 * $DB_x))"
    global eq3 "Predicted Odds(Y=1) is $temppy2"
  }

  if $xpt == 1 {
    quietly _grlog , a($DB_a) b($DB_b) dep($dep) xpt($DB_x) $options
  } 
  else {
    quietly _grlog , a($DB_a) b($DB_b) dep($dep) $options
  } 

end

capture program drop _aplus
program define _aplus
  global DB_a = $DB_a + .1
  _logreca
  window manage forward dialog
end

capture program drop _amin
program define _amin
  global DB_a = $DB_a - .1
  _logreca
  window manage forward dialog
end

capture program drop _bplus
program define _bplus
  global DB_b = $DB_b + .1
  _logreca
  window manage forward dialog
end

capture program drop _bmin
program define _bmin
  global DB_b = $DB_b - .1
  _logreca
  window manage forward dialog
end

capture program drop _xplus
program define _xplus
  global DB_x = $DB_x + 1
  _logreca
  window manage forward dialog
end

capture program drop _xmin
program define _xmin
  global DB_x = $DB_x - 1
  _logreca
  window manage forward dialog
end

capture program drop _reset
program define _reset
  global DB_a = 0
  global DB_b = 1
  global DB_x = 0
  _logreca
  window manage forward dialog
end

capture program drop _help
program define _help
  whelp grlog
end

capture program drop _amov
program define _amov
  local slp = $DB_slp*100
  global DB_a = -1
  while $DB_a <= 1 {
    global DB_a = $DB_a + .01
    _logreca
    sleep `slp'
    window manage forward dialog
  }
end

capture program drop _bmov
program define _bmov
  local slp = $DB_slp * 100
  global DB_b = -1
  while $DB_b <= 1 {
    global DB_b = $DB_b + .01
    _logreca
    sleep `slp'
    window manage forward dialog
  }
end

capture program drop _grlog
program define _grlog

  version 6.0

  syntax [,a(real 0) b(real 1) or dep(string) xunits(integer 21) xpt(real 999) l1(string) l2(string) l2(string) b2(string) *]

  preserve
  drop _all

  if "`or'"!="" {
    local b = ln(`b')
    local b = string(`b',"%3.2f")
  }

  if "`dep'"=="" {
    local dep "py"
  }

  local or = exp(`b')
  local or = string(`or',"%3.1f")

  quietly set obs `xunits'
  generate x = _n - int(`xunits'/2) - 1

  gen logity = `a' + x * `b'
  gen pgty = 1 - 1/(1 + exp(logity))
  
  if "`dep'"=="logity" {
    gen y = logity
  }
  if "`dep'"=="py" {
    gen y = pgty
  }
  if "`dep'"=="oddsy" {
    gen y = pgty / (1-pgty)
  }

  if "`l1'" == "" {
    local l1 = "."
  }
  if "`l2'" == "" {
    if "`dep'"=="logity" {
      local l2 = "Predicted Logit (Log Odds) Y=1"
    }
    if "`dep'"=="py" {
      local l2 = "Predicted Probability Y=1"
    }
    if "`dep'"=="oddsy" {
      local l2 = "Odds Y=1"
    }
  }
  if "`b2'" == "" {
    local b2 = "Value of Predictor (e.g. x)"
  }
  if "`t2'" == "" {
    if "`dep'"=="logity" {
      local t2 = "Predicted Logit(Y=1) by x, where a=`a' and b=`b' (OR=`or')"
    }
    if "`dep'"=="oddsy" {
      local t2 = "Odds Y=1 by x, where a=`a' and b=`b' (OR=`or')"
    }
    if "`dep'"=="py" {
      local t2 = "Predicted P(Y=1) by x, where a=`a' and b=`b' (OR=`or')"
    }
  }
  if `xpt' != 999 {
    local xobs = `xunits'+1
    set obs `xobs'
    replace x = `xpt' in `xobs'
    gen logity2 = `a' + x * `b' in `xobs'
    gen pgty2 = 1 - 1 / (1 + exp(logity2)) in `xobs'
    gen oddsy2 = pgty2 / (1-pgty2)
    if "`dep'"=="logity" {
      gen y2 = logity2
    }
    if "`dep'"=="py" {
      gen y2 = pgty2
    }
    if "`dep'"=="oddsy" {
      gen y2 = oddsy2
    }
    graph y y2 x, c(l.) s(.S) l1("`l1'") l2("`l2'") b2("`b2'") t2("`t2'") `options'
  }
  else {
    graph y x, c(l) s(.) l1("`l1'") l2("`l2'") b2("`b2'") t2("`t2'") `options'
  }
  restore

end


