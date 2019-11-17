*! version 1.1 revised 11/5/03, 30oct00
program define ftable
  version 7.0

  syntax [anything] [, alpha(real .05) ]
  
  if "`anything'" ~= "" { 
     tokenize `anything'
     display
     display in green %4.0f  "Critical value of F(`1', `2', `alpha') = " in yellow %6.2f invfprob(`1', `2' , `alpha') 
     }
   else  {
   display
   display in green "                      Critical values of F for alpha = `alpha'"
   display in green "        1      2      3      4      5    |    6      7      8      9     10"

    local i = 1
    while `i'<=25 {
        display in green %4.0f `i' " " in yellow %6.2f invfprob(1, `i' , `alpha') " " %6.2f invfprob(2,`i',`alpha') " " /*
       */  %6.2f invfprob(3,`i',`alpha')  " "  %6.2f invfprob(4,`i',`alpha') " " /*
       */  %6.2f invfprob(5,`i',`alpha') "  | "    %6.2f invfprob(6,`i',`alpha') " "     %6.2f invfprob(7,`i',`alpha')  /*
       */ " " %6.2f invfprob(8,`i',`alpha') " "    %6.2f invfprob(9,`i',`alpha') " "     %6.2f invfprob(10,`i',`alpha') 
      local i = `i' + 1 
    }
    
    local i = 30
    while `i'<=100 {
        display in green %4.0f `i' " " in yellow %6.2f invfprob(1, `i' , `alpha') " " %6.2f invfprob(2,`i',`alpha') " " /*
       */  %6.2f invfprob(3,`i',`alpha')  " "  %6.2f invfprob(4,`i',`alpha') " " /*
       */  %6.2f invfprob(5,`i',`alpha') "  | "    %6.2f invfprob(6,`i',`alpha') " "     %6.2f invfprob(7,`i',`alpha')  /*
       */ " " %6.2f invfprob(8,`i',`alpha') " "    %6.2f invfprob(9,`i',`alpha') " "     %6.2f invfprob(10,`i',`alpha') 
      local i = `i' + 5 
    }
    
    local i = 125
    while `i'<=300 {
        display in green %4.0f `i' " " in yellow %6.2f invfprob(1, `i' , `alpha') " " %6.2f invfprob(2,`i',`alpha') " " /*
       */  %6.2f invfprob(3,`i',`alpha')  " "  %6.2f invfprob(4,`i',`alpha') " " /*
       */  %6.2f invfprob(5,`i',`alpha') "  | "    %6.2f invfprob(6,`i',`alpha') " "     %6.2f invfprob(7,`i',`alpha')  /*
       */ " " %6.2f invfprob(8,`i',`alpha') " "    %6.2f invfprob(9,`i',`alpha') " "     %6.2f invfprob(10,`i',`alpha') 
      local i = `i' + 25 
    }
    
    local i = 400
    while `i'<=1000 {
        display in green %4.0f `i' " " in yellow %6.2f invfprob(1, `i' , `alpha') " " %6.2f invfprob(2,`i',`alpha') " " /*
       */  %6.2f invfprob(3,`i',`alpha')  " "  %6.2f invfprob(4,`i',`alpha') " " /*
       */  %6.2f invfprob(5,`i',`alpha') "  | "    %6.2f invfprob(6,`i',`alpha') " "     %6.2f invfprob(7,`i',`alpha')  /*
       */ " " %6.2f invfprob(8,`i',`alpha') " "    %6.2f invfprob(9,`i',`alpha') " "     %6.2f invfprob(10,`i',`alpha') 
      local i = `i' + 100 
    }
    }
end


