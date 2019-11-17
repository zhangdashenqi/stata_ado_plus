*! version 2.1.0  9/8/94        sg30: STB-23
*Edward Whitehouse  Institute for Fiscal Studies
pr def inequal
  version 3.1
  set more 1
  local varlist "req ex max(1)"
  local if "opt"
  local in "opt"
  local weight "fweight"
  parse "`*'"
  confirm new var _use _i _temp 
  di
  di in green "inequality measures of " in yellow "`varlist'"
  di in green _d(78) "-"
  quietly { 
    preserve
    gen byte _use = 1 `if' `in'
    keep if _use==1
    su `varlist' [`weight'`exp']
    local mn = _result(3)
    local tot = _result(1)
    local vari = _result(4)
    sort `varlist'
    local wt : word 2 of `exp'
    if "`wt'"=="" {gen _i = [_n]
                   local wt = 1}
    else gen _i = sum(`wt')
* relative mean deviation
    gen _temp = sum(`wt'*abs(`varlist'-`mn')) 
    local rmd = _temp[_N]/(2*`mn'*`tot')
* coefficient of variation
    local cov = `vari'^0.5/`mn'
* standard deviation of logs
    replace _temp = log(`varlist')
    su _temp [`weight'`exp']
    local sdl = (_result(4))^0.5
* gini
    replace _temp = sum(`wt'*_i*(`varlist'-`mn'))
    local gini = (2*_temp[_N])/(`tot'^2*`mn')
* mehran 
    replace _temp = sum(`wt'*_i*(2*`tot'+1 -_i)*(`varlist' - `mn'))
    local mehran = (3*_temp[_N])/(`tot'^3*`mn')
* piesch
    replace _temp = sum(`wt'*_i*(_i-1)*(`varlist'-`mn'))
    local piesch = 3*_temp[_N]/(2*`tot'^3*`mn')
* kakwani
    replace _temp = sum(`wt'*((`varlist'^2+`mn'^2)^0.5))
    local kakwani = (1/(2-2^0.5))*((_temp[_N]/(`tot'*`mn')-2^0.5))
* theil 
    replace _temp = sum(`wt'*((`varlist'/`mn')*(log(`varlist'/`mn'))))
    local theil = _temp[_N]/`tot'
* mean log deviation
    replace _temp = sum(`wt'*(log(`mn'/`varlist')))
    local mld = _temp[_N]/`tot'
    }
    di in green "relative mean deviation " _col(40) in yellow `rmd'
    di in green "coefficient of variation" _col(40) in yellow `cov'
    di in green "standard deviation of logs" _col(40) in yellow `sdl'
    di in green "Gini coefficient" _col(40) in yellow `gini'
    di in green "Mehran measure" _col(40) in yellow `mehran'
    di in green "Piesch measure" _col(40) in yellow `piesch'
    di in green "Kakwani measure" _col(40) in yellow `kakwani'
    di in green "Theil entropy measure" _col(40) in yellow `theil'
    di in green "Theil mean log deviation measure" _col(40) in yellow `mld'
    di in green _d(78) "-"
  end
