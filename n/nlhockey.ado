program define nlhockey 

{
  version 8.2

  syntax anything [,right0 left0]

  if "`right0'" != "" & "`left0'" != "" {
	 noi di as error "You cannot specify both right0 and left0"
    exit 1
  }
  tokenize `anything'
  local first `1'
  macro shift
  local second `1'
  macro shift
  local others `*'
//  local others =  substr("`others'", 1, index("`others'", ","))
//  local others : subinstr local others "," ""
  local varcount 0
  if "`others'" ~= "" {
	 local varcount	 : word count `others'
  }
  local counter = 1
  while `counter' <= `varcount' {
    local thisvar : word `counter' of `others'
	 local xbother `xbother' + \$`thisvar'*`thisvar'
    local counter = `counter' + 1
  }
  if "`first'" == "?" {
    
	 global S_1 breakpoint
	 if "`left0'" == "" {
		global S_1 $S_1 slope_l
	 }
	 if "`right0'" == "" {
		global S_1 $S_1 slope_r
	 }
	 global S_1 $S_1 `others' cons 
	 tempvar min max
	 egen `min' = min(`second')
	 egen `max' = max(`second')
	 global breakpoint    = (`max' + `min') / 2
    regress `e(depvar)' `second' if `second' < $breakpoint
	 matrix b = e(b)
	 global cons = b[1,2]
    if "`left0'" == "" {
		global slope_l  = b[1,1]
	 }
	 else {
		global slope_l = 0
	 }
    if "`right0'" == "" {
		regress `depvar' `second' if `second' > $breakpoint
		matrix b = e(b)
		global slope_r  = b[1,1]
	 }
	 else {
		global slope_r = 0
	 }
    if "$eps" == "" {
		global eps    = (`max' - `min') / 100
	 }
	 local counter = 1
	 while `counter' <= `varcount' {
		local thisvar : word `counter' of `others'
		global `thisvar' = 1
      local counter = `counter' + 1
	 }
	 exit
  }
  local x1     = $breakpoint - $eps
  local x2     = $breakpoint + $eps
  local b      = (`x2' * $slope_l - `x1' * $slope_r) / (`x2' - `x1')
  local cc     = ($slope_r - `b') / (2*`x2')
  local a      = $cons + $slope_l*`x1' - `b'*`x1' - `cc'*(`x1'^2)
  local alpha2 = (`a'  + `b'*`x2' + `cc'*(`x2'^2))-$slope_r*`x2'

  replace `first' = $cons  + $slope_l*`second' if `second' < `x1'
  replace `first' = `alpha2' + $slope_r*`second' if `second' > `x2'
  replace `first' = `a' + `b'*`second' + `cc'*`second'^2  ///
                     if `second' >= `x1' & `second' <= `x2'
  replace `first' = `first' `xbother'

}
end
