*! revised 1/26/04, plotregion fixed
*! revised 1/24/04, changing clear to drop _all
*! version 1.1 revised 11/04/03, 6/21/01
program define chidemo
  version 8.0  
  args df alpha

  if "`df'" == "" {
    local df = 1
  }
  
  if "`alpha'" == "" {
    local alpha = .05
    }
  
  local xsqr =  invchi2tail(`df',`alpha')
  
  local xtitle = "Critical value of chi-square = " + string(round(`xsqr',.01)) + "   (alpha=`alpha')"

  preserve
  drop _all // changed clear to drop _all
  quietly {
    
    range x 0 100 500
    local nu2 = `df'/2
    
    generate chi = (x^(`nu2'-1)*exp(-1*x/2))/((2^(`nu2'))*exp(lngamma(`nu2')))
    
  }
   graph twoway scatter chi x, s(i) c(l)  /*
        */ xline(0, lcolor(gs1)) xscale(noline) xline(`xsqr')                     /* 
        */ yline(0, lcolor(gs1)) ylabel(none) yscale(noline)                      /*
        */ t1("Chi-square Distribution (df=`df')") xtitle(`xtitle') ytitle("")    /*
        */ plotregion(margin(zero))
 
end



