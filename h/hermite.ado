*! version 2.0, October 2002                                   (SJ4-1: st0057)

program define hermite  
      version 7.0
	tokenize `0'
	
      local n "`1'"
      local x "`2'"
      local w "`3'"
      local last = `n' + 2
      tempvar p
      tempname i
      qui gen double `p' = . 
      scalar `i' = 1
          while `i' <= 10 {
          qui replace `p' = 0 in 1
          qui replace `p' = _pi^(-0.25) in 2
          qui replace `p' = `x'*sqrt(2/(_n-2))*`p'[_n-1] /*
          */	- sqrt((_n-3)/(_n-2))*`p'[_n-2] in 3/`last'
          scalar `w' = sqrt(2*`n')*`p'[`last'-1]
          scalar `x' = `x' - `p'[`last']/`w'
          if abs(`p'[`last']/`w') < 3e-14 {
          scalar `w' = 2/(`w'*`w')
          exit
          }
      scalar `i' = `i' + 1
      }
 di in red "hermite did not converge"
 exit 499
end
exit

