  capture program drop powell
  program define powell
     tempvar e
     tempname b  
     if "`3'"!=""{
        loc sse = "`3'"
        qui cap drop `sad'
        }
     else {
        tempvar sad
        }
     matrix `b' = `1'
     matrix score `e' = `1'
     qui replace `e' = abs($yvar - max(`e',0))
     qui egen `sad' = sum(`e')
     sca `2' = -`sad'
         * the minus because amoeba MAXimizes
     gl fvals = $fvals + 1
   end
