*!version 1.1 1999 Joseph Hilbe
* version 1.0.0 1993 Joseph Hilbe, Walter Linde-Zwirble
* Poisson distribution random number generator with dispersion parameter
* Example: rndpodx mu, s(1.2)   [sigma=1.2]

program define rndpodx
   version 3.1
   set type double
   local varlist "req ex"
   local options "`options' Sigma(real 1.0)"
   parse "`*'"
   parse "`varlist'", parse(" ")
   qui  {
      local xm `1'
      tempvar em t ds sum1 ran1 g ran2 sp   
      gen `sp'=`sigma'
      gen `ran2' = invnorm(uniform())
      gen `g' = exp(-`xm'+(`ran2'*`sp'))
      gen `em'= -1
      gen `t' = 1.0
      gen `ran1' = uniform()
      gen `ds' = 1
      count if `ds'>0
      noi di in gr "( Generating " _c
      while  _result(1)> 0 {
          replace `em' = `em'+ 1 if (`ds'==1)
          replace `t' = `t' * `ran1' if (`ds'==1)
          replace `ds'=0 if (`g' > `t')
          replace `ran1' = uniform()
          noi di in gr "." _c
          count if `ds'>0
     }
      gen xp = int(`em'+0.5)
      noi di in gr " )"
      noi di in bl "Variable " in ye "xp " in bl "created."
      lab var xp "Constructed Poisson random variable with dispersion"
      set type float
  }
end

