*! version 1.4, rewritten 3/12/12
*! version 1.3, revised 1/24/04 updated to version 8.2
*! version 1.2, revised 10/4/01

program define heads
  version 8.2
  syntax [, flips(integer 100) coins(integer 1) prob(real .5) ci ]
  tempvar trials heads sumheads avgheads ucl lcl
  local plural ""
  if `coins'>1 {
    local plural "s"
  }
  preserve
  drop _all
  quietly set obs `flips'
  quietly generate `trials' = _n
  quietly generate `heads' = 0
  local coinnum = 1
  while (`coinnum' <= `coins') {
    quietly replace `heads' = `heads' + (uniform()<`prob')
    local coinnum = `coinnum' + 1
  }
  generate `sumheads'=sum(`heads')
  generate `avgheads'=`sumheads'/`trials'
  local mu = `coins' * `prob'
  local step = `coins' / 10
  note: `coins' coins tossed with p(head) = `prob'
  
  label variable `heads'    "# heads out of `coins' tossed"
  label variable `sumheads' "Sum of # of heads"
  label variable `trials'   "Number of Trials"
  label variable `avgheads' "Average # of heads"
  
  if "`ci'"!="ci" {    
    line `avgheads' `trials', ///
      ylabel(0(`step')`coins' `mu', angle(0)) yline(`mu', lcolor(gold) lwidth(thick)) ///
      title("Average number of heads" "from trial 1 to `flips' of `coins' coin`plural' with p(head)=`prob'", size(medlarge)) 
  }
  else {
    local binom = ""
    if (`coins' == 1) {
      local binom = ", binomial"
    }
    local n = 10
    quietly generate `ucl' = .
    quietly generate `lcl' = .
    while (`n' <= _N) {
      quietly   ci `heads' in 1/`n' `binom'
      quietly   replace `ucl' = `r(ub)' in `n'
      quietly   replace `lcl' = `r(lb)' in `n'
      local n = `n' + 1
    }
  
  twoway (line `avgheads' `trials') (rline `ucl' `lcl' `trials'), ///
      ylabel(0(`step')`coins' `mu', angle(0)) yline(`mu', lcolor(gold) lwidth(thick)) ///
      title("Average number of heads with Confidence Bands" "from trial 1 to `flips' of `coins' coin`plural' with p(head)=`prob'", size(medlarge)) ///
      legend(off)
  }
end

/*
program define _mkgr
  version 6.0
  * clear
  drop _all // mnm changed to drop _all

  quietly set obs $DB_flips
  quietly generate trials = _n
  quietly generate heads = 0
  local coinnum = 1
  while (`coinnum' <= $DB_coins) {
    quietly replace heads = heads + (uniform()<$DB_prob)
    local coinnum = `coinnum' + 1
  } 
  generate sumheads=sum(heads)
  generate avgheads=sumheads/trials
  label variable heads    "# heads out of $DB_coins tossed"
  label variable sumheads "Sum of # of heads"
  label variable trials   "Number of Trials"
  label variable avgheads "Average # of heads"
  local mu = $DB_coins * $DB_prob
  local step = $DB_coins / 10
  note: $DB_coins coins tossed with p(head)=$DB_prob

  if ! $DB_ci {    
    version 8.2: line avgheads trials, ///
      ylabel(0(`step')$DB_coins `mu', angle(0)) yline(`mu', lcolor(gold) lwidth(thick)) ///
      title("Average number of heads" "from trial 1 to $DB_flips of $DB_coins coin(s) with p(head)=$DB_prob", size(medlarge)) 
  }
  else {
    local binom = ""
    if ($DB_coins == 1) {
      local binom = ", binomial"
    }
    local n = 10
    quietly generate ucl = .
    quietly generate lcl = .
    while (`n' <= _N) {
      quietly   ci heads in 1/`n' `binom'
      quietly   replace ucl = `r(ub)' in `n'
      quietly   replace lcl = `r(lb)' in `n'
      local n = `n' + 1
    }
    version 8.2: twoway (line avgheads trials) (rline ucl lcl trials), ///
      ylabel(0(`step')$DB_coins `mu', angle(0)) yline(`mu', lcolor(gold) lwidth(thick)) ///
      title("Average number of heads with Confidence Bands" "from trial 1 to $DB_flips of $DB_coins coin(s) with p(head)=$DB_prob", size(medlarge)) ///
      legend(off)
  }
end
*/


