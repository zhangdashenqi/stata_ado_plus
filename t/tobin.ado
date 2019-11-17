  capture program drop tobin
  program define tobin
     tempvar xb yh
     tempname b sig  
     if "`3'"!=""{
        loc tob = "`3'"
        qui cap drop `tob'
        }
     else {
        tempvar tob
        }
     matrix `b' = `1'[1,"beta:"]
     loc n = colsof(`1')
     matrix score double `xb' = `b'
     sca `sig' = `1'[1,`n']
     sca `sig' = abs(`sig')
     qui {
     gen double `tob' = normprob(-`xb'/`sig') if $yvar<=0
     replace `tob' =    exp( -0.5*(($yvar-`xb')/`sig')^2 )/(sqrt(2*_pi)*`sig') if $yvar>0
*     replace `yh' =    normd(($yvar-`xb')/`sig')/`sig' if $yvar>0
     replace `tob' = ln(max(`tob',1E-20))
     gen double `yh' = sum(`tob')
     }
     sca `2' = `yh'[_N]
   end
