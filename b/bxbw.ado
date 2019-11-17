program define bxbw
  version 6.0
  display
  display "Box Model Program Starting"
  display "(sampling without replacement)"
  syntax using/  [,  Draw(integer 1) Reps(integer 100)]
  tempname bxm match unique
  tempfile bxd

  postfile `bxm' match unique using bxmodel, replace every(10)
  quietly use `using' , clear
  quietly expand n
  tempvar indx
  quietly generate `indx' = .
  local tn = _N 
  quietly save `bxd'

  local  j = 1
  while `j' <= `reps' {
    quietly replace `indx' = uniform() 
    sort `indx'
 /* list in 1/`draw' */
    quietly tabulate value in 1/`draw'
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



