  capture program drop myols
  program define myols
     tempvar e
     if "`3'"!=""{
        loc sse = "`3'"
        qui cap drop `sse'
        }
     else {
        tempvar sse
        }
     matrix score double `e' = `1'
     qui replace `e' = ($yvar - `e')*($yvar - `e')
     qui egen double `sse' = sum(`e')
     sca `2' = -`sse'
         * the minus because amoeba MAXimizes
   end

