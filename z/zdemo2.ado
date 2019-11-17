*! revised 1/26/04, plotregion fixed
*! revised 1/24/04, changing to drop _all
*! revised 11/4/03, 8/2/02
program define zdemo2
  version 8.0
  args m1 sd1 m2 sd2
  preserve
  drop _all // mnm changed

  local min1 = `m1'- 4*`sd1'
  local max1 = `m1'+ 4*`sd1'
  local min2 = `m2'- 4*`sd2'
  local max2 = `m2'+ 4*`sd2'
  local min = min(`min1',`min2')
  local max = max(`max1',`max2')
 
  quietly range x `min' `max' 400
  local var1 = `sd1'^2
  local var2 = `sd2'^2

  quietly generate y1 = (1/sqrt(2*_pi*`var1'))*exp(-1*(x-`m1')^2/(2*`var1'))
  quietly generate y2 = (1/sqrt(2*_pi*`var2'))*exp(-1*(x-`m2')^2/(2*`var2'))
  
  graph twoway scatter y1 y2 x, s(i i) c(l l) xline(`m1' `m2') yline(0, lcolor(gs1))          /* 
         */ xlab(`min' `m1' `m2' `max') plotregion(margin(zero))                              /*
         */ ytitle("") yscale(off) legend(off) xscale(noline)  t1("Two Normal Distributions")

end

