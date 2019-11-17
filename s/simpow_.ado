*capture program drop simpow_
program define simpow_
  version 6.0
  if "`1'" == "?" {
    global S_1 "f fp"
    exit
  }

  drop _all
  generate y = .
  generate group = .
  set obs $TOTN

  global i = 1
  local curobs = 0
  while ($i <= $GROUPS) {
    local curobs1 = `curobs'+1
    local totobs = `curobs' + ${N$i}
    replace  y = ${MU$i} + invnorm(uniform())*${S$i} in `curobs1'/`totobs'
    replace group = $i in `curobs1'/`totobs'
    global i = $i + 1
    local curobs = `totobs'
  }

  * sort group
  * by group: summarize y

  if "$SIMF"!="" {
    anova y group
    scalar f  = `e(F)'
    scalar fp = fprob(`e(df_m)',`e(df_r)',`e(F)')
  }
  else {
    scalar f  = .
    scalar fp = .
  }

  post `1' f fp 

end
