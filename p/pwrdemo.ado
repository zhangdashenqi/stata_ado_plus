*! updated 1/24/04 to update to version 8

capture program drop pwrdemo
program define pwrdemo
  version 6.0
  args m1

  if "`m1'"=="" { local m1=1 }
  preserve
  drop _all // mnm changed from clear
  
  local pr = normprob(`m1' - 1.96)
  local pr = string(`pr')

  version 8.2: twoway (function y=normden(x), range(-4 8) xline(1.96)) ///
                      (function y=normden(x-`m1'), range(-4 8)) ///
                      (function y=normden(x-`m1'), range(1.96 8) recast(area) pstyle(p2) bfcolor(erose)), ///
                    xlabel(-3 -2 to 8) ylabel(0 .1 to .4) legend(off) ///
                    title("H0 distribution in blue -- H1 distribution in red") ///
                    caption("H0 mean = 0 -- H1 mean = `m1' -- power = `pr'") 

  restore
end
