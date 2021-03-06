*! Generate random draws from truncated standard normal distribution.
*! by Hung-Jen Wang, Version 1.0.0, 3Dec99.

program define gentrun
   version 6
   syntax newvarlist [if] [in] [, Left(string) Right(string)]

   tempvar tem1
   tempname mltrn mrtrn

   if "`left'" != "" & "`right'" != "" {
      if `left' >= `right' {
         di in red /*
    */ "The left truncation point cannot be >= the right truncation point."
         exit 198
      }
   }

     if "`left'" == ""{
         scalar `mltrn' = 0
     }
     else {
         scalar `mltrn' = normprob(`left')
     }

     if "`right'" == ""{
         scalar `mrtrn' = 1
     }
     else {
         scalar `mrtrn' = normprob(`right')
     }

    tokenize `varlist'

    while "`1'" ~= ""{
        quie gen double `tem1' = (`mrtrn'-`mltrn')*uniform() + `mltrn' `if'
`in'
        quie gen `typlist' `1' = invnorm(`tem1') `if' `in'
        drop `tem1'
        mac shift
    }

end
exit
