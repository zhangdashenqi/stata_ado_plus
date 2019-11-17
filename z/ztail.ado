*! revised 1/26/04, plotregion fix
*! revised 1/24/04, changing clear to drop _all
*! version 1.2 revised 11/5/03, 11/13/00
capture program drop _all
program define ztail
  version 8.2
  args alpha tail
 
  if "`alpha'"=="" {
    local alpha = 0.05
  }
  if "`tail'"=="" {
    local tail = 2
  }

  if `tail'==1 {
    local z = invnorm(1.0 - `alpha')
    local title1 = "z = " + string(round(`z',.001))


    twoway (function y=normden(x), range(`z' 4) bcolor(erose) recast(area)) ///
           (function y=normden(x), range(-4 4) pstyle(p2)), ///
           yscale(off) xscale(line) legend(off) xlabel(-4(1)4) ylabel( , nogrid) xtitle("Z-score") ///
           plotregion(margin(zero)) title(`title1') 
  }
  else {
    local z = invnorm(1.0 - (`alpha'/2))
    local title1 = "z = ±" + string(round(`z',.001))
    
    twoway (function y=normden(x), range(-4 -`z') bcolor(erose) recast(area)) ///
           (function y=normden(x), range(`z' 4) bcolor(erose) recast(area)) ///
           (function y=normden(x), range(-4 4) pstyle(p2)), ///
           yscale(off) xscale(line) legend(off) xlabel(-4(1)4) ylabel( , nogrid) xtitle("Z-score") ///
           plotregion(margin(zero))  title(`title1') 
  }
end


