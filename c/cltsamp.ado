program define cltsamp
  version 6.0
  if "`1'" == "?" {
    global S_1 "sum mean"
    exit
  }
  drop _all 
  set obs $Samp_N 

  if "`2'" == "Binomial" {
    gen x = cond(uniform()<`3',1,0)
  }
  else if "`2'" == "Exponential" {
    gen x = -1*ln(uniform())
  }
  else if "`2'" == "ExpNormal" {
    gen x = -1*ln(invnorm(uniform()))
  }
  else if "`2'" == "Log" {
    gen x = exp(uniform())
  }
  else if "`2'" == "LogNormal" {
    gen x = exp(invnorm(uniform()))
  }
  else if "`2'" == "Uniform" {
    generate x = uniform()
  }
  else if "`2'" == "Bimodal" {
    generate x = invnorm(uniform())
    replace x = x + cond(uniform()<.5,-3,+3)
  }
  else {
    generate x = invnorm(uniform())
  } 

  quietly summarize x
  post `1' r(sum) r(mean)
end
