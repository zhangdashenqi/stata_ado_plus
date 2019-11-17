*! version 1.0 15mar2002  pbe
program define simpower
  version 7
  #delimit ;
  syntax [varlist(default=none)]  ,  
    [ GRoups(integer 2)  N(numlist) S(numlist)
      MU(numlist)  REPS(integer 1000) LEVel(integer 95) 
      SEED(integer -999) ]  ;
  #delimit cr

  preserve

  if "`seed'"!="-999" {
    set seed `seed'
  }

  * display "var is `varlist'"
    local nomp .100 .075 .05 .025 .010

  local nomp0 `nomp'
  local nomp1 `nomp'
  local nomp2 `nomp'

  if "`varlist'" != "" {
    tokenize "`varlist'"
    local dv = "`1'"
    local iv = "`2'"

    quietly anova `dv' `iv'
    local nompx = fprob(`e(df_m)',`e(df_r)',`e(F)')

    quietly tab `iv'
    local groups = `r(r)'
    collapse (count) cnt=`dv' (mean) mu=`dv' (sd) sd=`dv', by(`iv')

    local n = cnt[1]
    local mu = mu[1]
    local s = sd[1]
    local i = 2
    while (`i' <= _N) {

      local t = cnt[`i']
      local n "`n'  `t'"
      
      local t = mu[`i']
      local mu "`mu' `t'"

      local t = sd[`i']
      local s "`s' `t'"

      local i = `i' + 1
    }
    * display "n is `n'"
    * display "s is `s'"
  }
  else {
    if ! ("`groups'"!="" & "`n'"!="" & "`s'"!="") {
      display "if dv iv is omitted, need groups n and s"
      exit 3
    }
  }  

  global TOTN = 0

  tokenize `n'
  local i = 1
  while (`i' <= `groups') {
    if "``i''"=="" {
      display "Not enough values of n"
      exit 2
    }
    global N`i' = ``i''
    global TOTN = $TOTN + ``i''
    local i = `i' + 1
  }

  tokenize `s'
  local i = 1
  while (`i' <= `groups') {
    if "``i''"=="" {
      display "Not enough values of s"
      exit 2
    }
    global S`i' ``i''
    local i = `i' + 1
  }

  tokenize `mu'
  local i = 1
  while (`i' <= `groups') {
    if "``i''"=="" {
      global MU`i' 0
    }
    else {
      global MU`i' ``i''
    }
    local i = `i' + 1
  }

  /*
  display "groups is `groups'"
  display "ns is `n'"
  display "ss is `s'"
  global i = 1
  while ($i <= $NUMALPH) {
    display "${NOMP$i}"
    global i = $i + 1
  }
  */
        
  display
  display in gr "Sample Sizes, Means and Standard Deviations"
  display in gr "-------------------------------------------"
  global GROUPS = `groups'
  global i = 1
  while ($i <= `groups') {
    display in gr "N$i = " in ye ${N$i} in gr _col(15) "MU$i = " in ye ${MU$i} _col(30) in gr "  S$i = " in ye ${S$i}
    global i = $i + 1
  }

  global SIMF YES
  simul simpow_ , reps(`reps') 

  if "`varlist'" != "" {
    tempfile tempx
    qui save "`tempx'"
    restore, preserve

    qui anova `dv' `iv'
    local fp = fprob(`e(df_m)',`e(df_r)',`e(F)')
    di
    display in wh "Results of Standard ANOVA"
    display in gr _dup(70) "-" 
    display in gr "Dependent Variable is " in ye "`dv'" in gr " and Independent Variable is " in ye "`iv'"
    display in gr "F(" in ye %3.0f `e(df_m)' in gr ", " in ye %6.2f `e(df_r)' in gr ") = " in ye %7.3f `e(F)' in gr ", p= " in ye %6.4f `fp'
    display in gr _dup(70) "-" 

    use "`tempx'", clear
  }
  simtable , pval(fp) tests(ANOVA F tests) level(`level') reps(`reps') locnomp(`nomp0')

end

*capture program drop simtable
program define simtable
  syntax , pval(string) tests(string) level(integer) reps(integer) locnomp(string)

  tokenize `locnomp'
  local i = 1
  while ("``i''"!="") {
    global NOMP`i' ``i''
    local i = `i' + 1
  }
  global NUMALPH = `i' - 1

  display
  display in gr " `reps' simulated `tests'"
  display in gr "------------------------------"
  display in gr " Alpha   Simulated "
  display in gr " Level     Power"
  display in gr "------------------------------"
  global i = 1
  while ($i <= $NUMALPH) {
    capture drop sig
    gen sig = (`pval' < ${NOMP$i})
    quietly ci sig, binom level(`level')
    display in ye _col(2) %6.4f ${NOMP$i} _col(11) %6.4f `r(mean)' _col(24) 
    global i = $i + 1
  }
end
