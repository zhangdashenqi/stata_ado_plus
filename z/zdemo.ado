*! revised 1/26/04, plotregion fixed
*! revised 1/24/04, changing clear to drop _all
* version 1.1 revised 11/4/03, 6/21/01
program define zdemo
  version 8.0
  preserve
  drop _all // mnm changed
  quietly range x -4 4 200

  quietly generate y = (1/sqrt(2*_pi))*exp(-.5*x^2)
  
  label variable x "z-scores"
  if "`0'" == "" { 
    local 0  "0" 
  }
  graph twoway scatter y x, s(i) c(l)                          /*
        */ xline(`0') xlabel(-3(1)3) xscale(noline)            /*
        */ yscale(range(0)) yline(0, lcolor(gs1)) ylabel(none) /*
        */ plotregion(margin(zero)) yscale(off)
  restore
end

