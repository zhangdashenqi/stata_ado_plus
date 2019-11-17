*! version 1.1.1 19mat07 -- bug fix
*! version 1.1.0 19nov04
*! version 1.0.0 24oct00 -- pbe
program define ztable
  version 6.0
  syntax [, Cum ]
  display
  if "`cum'"=="" {
  display in green "      Areas between 0 & Z of the Standard Normal Distribution"
  display in green "      .00    .01    .02    .03    .04   |  .05    .06    .07    .08    .09"

    local i = 0
    while `i'<=3.5 {
        local p1=`i'+.01
        local p2=`i'+.02
        local p3=`i'+.03
        local p4=`i'+.04
        local p5=`i'+.05
        local p6=`i'+.06
        local p7=`i'+.07
        local p8=`i'+.08
        local p9=`i'+.09
        display in green %3.2f `i' " " in yellow %6.4f (normprob(`i')-.5) " " %6.4f normprob(`p1')-.5 " " /*
       */  %6.4f normprob(`p2')-.5 " "  %6.4f normprob(`p3')-.5 " " /*
       */  %6.4f normprob(`p4')-.5 " | "    %6.4f normprob(`p5')-.5 " "     %6.4f normprob(`p6')-.5  /*
       */ " " %6.4f normprob(`p7')-.5 " "    %6.4f normprob(`p8')-.5 " "     %6.4f normprob(`p9')-.5 
      local i = `i' + .1
       }
     }
    if "`cum'"~="" {
     display in green "      Cumulative Area of the Standard Normal Distribution"
  display in green "       .00    .01    .02    .03    .04   |  .05    .06    .07    .08    .09"

    local i = -3.5
    while `i'<=3.5 {
        if `i'<0 {
          local sgn=-1
        }
        else {
          local sgn=1
        }
        local p1=`i'+ `sgn'*.01
        local p2=`i'+ `sgn'*.02
        local p3=`i'+ `sgn'*.03
        local p4=`i'+ `sgn'*.04
        local p5=`i'+ `sgn'*.05
        local p6=`i'+ `sgn'*.06
        local p7=`i'+ `sgn'*.07
        local p8=`i'+ `sgn'*.08
        local p9=`i'+ `sgn'*.09
        display in green %5.2f `i' " " in yellow %6.4f norm(`i') " " %6.4f norm(`p1') " " /*
       */  %6.4f norm(`p2') " "  %6.4f norm(`p3') " " /*
       */  %6.4f norm(`p4') " | "    %6.4f norm(`p5') " "     %6.4f norm(`p6')  /*
       */ " " %6.4f norm(`p7') " "    %6.4f norm(`p8') " "     %6.4f norm(`p9') 
      local i = `i' + .1
      }
    }
end


