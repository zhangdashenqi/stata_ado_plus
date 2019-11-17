*! revised 1/26/04, plotregion fixed
*! revised 1/24/04, changing clear to drop _all
*! revised 11/03/03
program define tdemo
  version 8.0
  args df tails alpha

  if "`df'" == "" {
    local df = 1
  }
  
  if "`tails'" == "" {
    local tails = 2
  }
  
  if "`alpha'" == "" {
    local alpha = .05
  }
  
  local tval2 = 0
  local xtitle "Critical value of t = "
  
  if `tails' == 2 {
    local tval = invttail(`df',`alpha'/2)
    local tval2 = -`tval'
    local xtitle = "`xtitle'" + "±" + string(round(`tval',.01)) + "  (alpha=`alpha', 2-tail)"
    }
    
   if `tails' == 1 {
    local tval = invttail(`df',`alpha')
    local xtitle = "`xtitle'" + string(round(`tval',.01)) + "  (alpha=`alpha', 1-tail)"
    }

  preserve
  drop _all // mnm changed
  
    quietly {
    drop _all // mnm changed
    range x -5 5 400
    generate y1 = (1/sqrt(2*_pi))*exp(-.5*x^2)
    scalar tg0 = `df' /* $demodf */
    scalar tg1 = (tg0 + 1)/2
    scalar tg2 = tg0/2
    generate y2 = (exp(lngamma(tg1))/(sqrt(tg0*_pi)*exp(lngamma(tg2))))*(1 + x^2/tg0)^(-1*tg2)
  }
  
  graph twoway scatter y1 y2 x, s(i i) c(l l)  /*
        */ xline(0 `tval' `tval2') yline(0, lcolor(gs1)) xlabel(-5(1)5) yscale(noline) /*
        */ ylabel(none) legend(off) ytitle("") xtitle(`xtitle') xscale(noline)         /*
        */ plotregion(margin(zero))                                                    /*
        */ t1("t-dist->red (df = `df')  normal dist->blue")
 

end




