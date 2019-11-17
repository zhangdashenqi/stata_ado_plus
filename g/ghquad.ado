*! Version 2.0, October 2002.                                   (SJ4-1: st0057)

program define ghquad 
 version 7.0
 syntax [varlist(min=2 max=2)] [, N(integer 10)]
 tokenize `varlist'
 local x "`1'"
 local w "`2'"
 if `n' + 2 > _N  {
  di in red  /*
  */ "`n' + 2 observations needed to compute quadrature points"
  exit 2001
 }
 tempname xx ww

 local i 1
 local m = int((`n' + 1)/2)
 while `i' <= `m' {
  if `i' == 1 {
   scalar `xx' = sqrt(2*`n'+1)-1.85575*(2*`n'+1)^(-1/6)
  }
  else if `i' == 2 { scalar `xx' = `xx'-1.14*`n'^0.426/`xx' }
  else if `i' == 3 { scalar `xx' = 1.86*`xx'-0.86*`x'[1] }
  else if `i' == 4 { scalar `xx' = 1.91*`xx'-0.91*`x'[2] }
  else { scalar `xx' = 2*`xx'-`x'[`i'-2] }
  hermite `n' `xx' `ww'
  qui replace `x' = `xx' in `i'
  qui replace `w' = `ww' in `i'
  local i = `i' + 1
 }
 if mod(`n', 2) == 1 { qui replace `x' = 0 in `m' }
 qui replace `x' = -`x'[`n'+1-_n] in `i'/`n'
 qui replace `w' =  `w'[`n'+1-_n] in `i'/`n'
end
exit



