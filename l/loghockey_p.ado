program define loghockey_p

  version 8.2
  syntax newvarname [if] [in] [, P XB]
  if "`p'"!="" & "`xb'"!="" { 
	 di in red "may not specify both p and xb options"
	 exit 198
  }

  if "`p'"=="" & "`xb'"=="" {
		di in gr "(option p assumed; predicted probabilities)"
  }
  
  tempvar touse new
  mark `touse' `if' `in'
  
  quietly {
	 local k 1
	 while `k' <= e(k) { 
		local word : word `k' of `e(params)'
		global `word' = _b[`word']
		local k=`k'+1
	 }
  }
  tokenize `e(f_args)'
  local x `1'
  macro shift
  local indeps `*'
  local varcount : word count of `indeps'
  local varcount = `varcount' - 1
  local counter = 1
  while `counter' <= `varcount' {
    local thisvar : word `counter' of `indeps'
	 local xbother `xbother' + \$`thisvar'*`thisvar'
    local counter = `counter' + 1
  }
  
  local x1     = $breakpoint - $eps
  local x2     = $breakpoint + $eps
  local b      = (`x2' * $slope_l - `x1' * $slope_r) / (`x2' - `x1')
  local cc     = ($slope_r - `b') / (2*`x2')
  local a      = $cons + $slope_l*`x1' - `b'*`x1' - `cc'*(`x1'^2)
  local alpha2 = (`a'  + `b'*`x2' + `cc'*(`x2'^2))-$slope_r*`x2'

  gen `new' = .
  replace `new' = $cons  + $slope_l*`x' if `x' < `x1' & `touse'
  replace `new' = `alpha2' + $slope_r*`x' if `x' > `x2' & `touse' 
  replace `new' = `a' + `b'*`x' + `cc'*`x'^2 if `x' >= `x1'  ///
                                              & `x' <= `x2'  ///
                                              & `touse'
  replace `new' = `new' `xbother'
  if "`xb'" == "" {
	 gen `typlist' `varlist' = exp(`new') / (1 + exp(`new'))
  }
  else {
	 gen `typlist' `varlist' = `new'
  }

end
  
