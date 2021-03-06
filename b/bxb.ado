program define bxb
  version 6.0
  display
  display "Box Model Program Starting"
  display "(sampling with replacement)"
  syntax using/  [,  Draw(integer 1) Reps(integer 100)]
  tempname bxm match unique
  tempfile bxd

  postfile `bxm' match unique using bxmodel, replace every(10)
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
    quietly tabulate value in `c1'/l
    scalar match = r(N)>r(r)
    scalar unique = r(r)
    post `bxm'  match unique
    local j = `j' + 1
    use `bxd', clear
 }
  postclose `bxm'
  scalar drop match unique
  use bxmodel.dta, clear
  display "Box Model Program Finished"
end



