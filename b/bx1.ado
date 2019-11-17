program define bx1
  version 6.0
  display
  display "Box Model Program Starting"
  display "(sampling with replacement)"
  syntax using/  [,  Draw(integer 1) Reps(integer 100)]
  tempname bxm 
  tempfile bxd

  postfile `bxm' sum mean sd using bxmodel, replace every(10)

 quietly use `using' , clear
 quietly expand n


  local tn = _N 
  local c1= `tn' + 1
  local nn = `tn' + `draw'
  quietly set obs `nn'
  quietly save `bxd'

  local  j = 1
  while `j' <= `reps' {
    tempvar s
    quietly generate double `s' = int(uniform() * `tn' + 1)
    quietly replace value = value[ `s' ] in `c1'/l
    quietly summarize value in `c1'/l
    post `bxm'  r(sum) r(mean) r(sd)
    local j = `j' + 1
    use `bxd', clear
 }
  postclose `bxm'
  use bxmodel.dta, clear
  display "Box Model Program Finished"
end




