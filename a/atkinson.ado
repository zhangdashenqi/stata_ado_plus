*! version 1.0.0  9/8/94        sg30: STB-23
* Edward Whitehouse  Institute for Fiscal Studies
pr def atkinson 
  version 3.1
  set more 1
  local varlist "req ex max(1)"
  local if "opt"
  local in "opt"
  local weight "fweight"
  local options "Epsilon(string)"
  parse "`*'"
  if "`epsilon'"=="" {local epsilon="1"} 
  confirm new var _use _temp 
  di
  di in green "Atkinson inequality measures of " in yellow "`varlist'"
  di in green _d(78) "-"
  parse "`epsilon'", parse(" ,")
  quietly { 
    preserve
    gen byte _use = 1 `if' `in'
    keep if _use==1
    su `varlist' [`weight'`exp']
    local mn = _result(3)
    local tot = _result(1)
    local wt : word 2 of `exp'
    if "`wt'"=="" {local wt = 1}
    gen _temp=1
    while "`1'"~="" {
      local eps = real("`1'")
      if "`1'"=="1" {replace _temp = exp(sum((`wt'*log((`varlist'/`mn')^(1/`tot')))))
                     local atkin = 1-_temp[_N]
                     noisily di in green "epsilon = 1" _col(40) in yellow `atkin'
      }
      if (`eps'~=.&`eps'~=1) {replace _temp = sum(`wt'*((`varlist'/`mn')^(1-`eps')))
                              local atkin = 1-(_temp[_N]/`tot')^(1/(1-`1'))
                              noisily di in green "epsilon = " `eps' _col(40) in yellow `atkin'
      }
      mac shift
    }
    }
  end
