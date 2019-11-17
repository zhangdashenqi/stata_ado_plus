*! called by cidemo 
program define cisamp
  version 6.0
  if "`1'" == "?" {
    global S_1 "m s n"
    exit
  }
  drop _all 
  set obs $Samp_N 
  generate z = invnorm(uniform())*10 + 50
  quietly summarize z
  post `1' r(mean) r(sd) r(N) 
end
