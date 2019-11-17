program define bx1s
  version 6.0
  syntax using/ [ , draw(integer 1) reps(integer 100) ]
    display
  display "Box Model Program Starting"
  display "(sampling without replacement)"
  tempname bxm 
  tempfile bxd
  tempvar ran
  postfile `bxm' sum mean sd using bxmodel, replace every(10)
  use `using', clear
  quietly expand n
  if `draw'>_N {
    display in red "sample size must not be greater than the number of observations"
    exit 498
  }
  quietly save `bxd'
  local i=1
  while `i' <= `reps' {
    gen `ran'=uniform()
    sort `ran'
    drop `ran'
    quietly keep in 1/`draw'
    quietly summarize value
    post `bxm' r(sum) r(mean) r(sd)
    local i = `i'+1
    use `bxd', clear
  }
  postclose `bxm'
  use bxmodel, clear
  display "Box Model Program Finished"
end
