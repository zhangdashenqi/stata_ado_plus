program proptrim, rclass byable(onecall)

version 8.2

syntax varlist [if] [in], [Keep(namelist min=1 max=1) ///
                           Pctiles(numlist >0 <100) ]

	local by "`_byvars'"

	tokenize `varlist'
	local treat `1'
	macro shift
	local prop `1'

	local byprefix
	if "`by'" != "" {
		local byprefix by `by': 
	}

if "`keep'" == "" {
  local keep keep
}

if "`pctiles'" == "" {
  local pctiles 1 5
}

marksample touse

tempname p0 p100
local botv `p0'
local topv `p100'

foreach num in `pctiles' {
  local newnum : subinstr local num "." "_", all
  local newp `newp' `newnum'
}

local tot : word count `pctiles'
local i 1
while `i' <= `tot' {
  local p : word `i' of `pctiles'
  local pn : word `i' of `newp'
  tempname p`pn'
  local botv `botv' `p`pn''
		qui `byprefix' egen `p`pn'' = pctile(`prop') if `treat' == 1 & `touse', p(`p')
  local t = 100 - `p'
  local tn : subinstr local t "." "_"
  tempname p`tn'
  local topv `topv' `p`tn''
  qui `byprefix' egen `p`tn'' = pctile(`prop') if `treat' == 0 & `touse', p(`t')
  local i = `i' + 1
}

	qui `byprefix' egen `p0'   = min(`prop') if `treat' == 1 & `touse'
	qui `byprefix' egen `p100' = max(`prop') if `treat' == 0 & `touse'
	gsort `by' - `touse' `treat'
	foreach var of varlist `topv' {
		qui `byprefix' replace `var' = `var'[1] if `var' == .
	}

	gsort `by' - `touse' - `treat'
	foreach var of varlist `botv' {
		qui `byprefix' replace `var' = `var'[1] if `var' == .
	}

	local pctiles 0 `newp'
	local i = 1
	local tot : word count `topv'
	while `i' <= `tot' {
		local bot : word `i' of `botv'
		local top : word `i' of `topv'
		local suffix : word `i' of `pctiles'
		capture drop `keep'_`suffix'
		qui gen byte `keep'_`suffix' = `prop' <= `top' & `prop' >= `bot' if `touse' 
		local i = `i' + 1
  }

end
