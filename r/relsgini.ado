*! version 1.0.0  9/8/94        sg30: STB-23
*Edward Whitehouse  Institute for Fiscal Studies
pr def relsgini
  version 3.1
  set more 1
  local varlist "req ex max(1)"
  local if "opt"
  local in "opt"
  local weight "fweight"
  local options "Delta(string)"
  parse "`*'"
  if "`delta'"=="" {local delta="2"} 
  confirm new var _use _temp _i
  di
  di in green "Donaldson-Weymark relative S-Gini inequality measures of " in yellow "`varlist'"
  di in green _d(78) "-"
  parse "`delta'", parse(" ,")
  quietly { 
    preserve
    gen byte _use = 1 `if' `in'
    keep if _use==1
    su `varlist' [`weight'`exp']
    local mn = _result(3)
    local tot = _result(1)
    local wt : word 2 of `exp'
    sort `varlist'
    if "`wt'"=="" {local wt = 1
                   gen _i = [_n]}
    else gen _i = sum(`wt')
    gen _temp=1
    while "`1'"~="" {
      local dl = real("`1'")
      if `dl'~=. {
        if `dl'~=1 {replace _temp = sum(`wt'*`varlist'*((`tot'-_i+1)^`dl'-(`tot'-_i)^`dl'))
                    local sgini = (`mn' - _temp[_N]/(`tot'^`dl'))/`mn'}
        else local sgini = 0
        noisily di in green "delta = " `dl' _col(40) in yellow `sgini'
        }
      mac shift
      }
    }
  end
