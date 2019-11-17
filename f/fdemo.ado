*! revised 1/26/04, plotregion fixed
*! revised 1/24/04, changing clear to drop _all
*! revised 11/04/03, 6/21/01
program define fdemo
  version 8.0 
  args df1 df2 alpha

  if "`df1'" == "" {
    local df1 = 1
    local df2 = 1
    }
  
  if "`alpha'" == "" {
    local alpha = .05
    }
    
  local fval = invFtail(`df1',`df2',`alpha')
  
  local xtitle = "Critical value F = " + string(round(`fval',.01)) + "  (alpha=`alpha')"

  global demodf =  `df1'
  global demodf2 = `df2'
 
  preserve
  drop _all // mnm change
  quietly {
    drop _all // mnm change
    tempname con1
    range x 0 10 500
    local mu2 = `df1' / 2
    local nu2 = `df2' / 2
    local mnu2 = (`df1' + `df2') / 2
    scalar `con1' = (exp(lngamma(`mnu2')) * `df1'^`mu2' * `df2'^`nu2') / (exp(lngamma(`mu2'))*exp(lngamma(`nu2')))
    generate f= `con1'*((x^(`mu2' - 1))/((`df1' * x + `df2')^(`mnu2')))
   }
   graph twoway scatter f x, s(i) c(l)  /*
        */ xline(0, lcolor(gs1)) xline(`fval')  xscale(noline) xtitle(`xtitle')  /* 
        */ yline(0, lcolor(gs1)) yscale(noline) ylabel(none) ytitle("") /*
        */ t1("F-distribution (df = `df1' , `df2')") plotregion(margin(zero))
  

end

