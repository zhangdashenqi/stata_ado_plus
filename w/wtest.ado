capture program drop wtest
program define wtest, rclass

  version 6.0
  syntax varlist(min=2 max=2 numeric)

  preserve

  tokenize `varlist'

  local dv = "`1'"
  local iv = "`2'"

  qui summarize `dv'
  local n = `r(N)'

  qui collapse (mean) xbarj=`dv' (sd) sdj=`dv' (count) nj=`dv' , by(`iv')
  qui generate varj = sdj^2
  qui generate wj = (nj/varj)
  gen u = sum(wj)
  local u = u[_N]
  gen wxsum = sum(wj*xbarj)
  local xtilde = wxsum[_N] / `u'
  gen a1 = sum(wj*((xbarj-`xtilde')^2))
  local a = a1[_N] / (_N-1)

  local b0 = (2*(_N-2)/(_N^2-1)) 
  gen b1 = sum( ((1-wj/`u')^2)   / (nj-1)  )
  local b = 1 + (`b0' * b1[_N])

  local wstat = `a' / `b'

  local df1 = _N - 1
  local df2 = 1 / ( (3/(_N^2-1))*b1[_N] )

  local wstatp = fprob(`df1',`df2',`wstat')

  display
  display in gr _dup(70) "-" 
  display in gr "Dependent Variable is " in ye "`dv'" in gr " and Independent Variable is " in ye "`iv'"
  display in gr "WStat(" in ye %3.0f `df1' in gr ", " in ye %6.2f `df2' in gr ") = " in ye %7.3f `wstat' in gr ", p= " in ye %6.4f `wstatp'
  display in gr _dup(70) "-" 

  return scalar wstat  = `wstat'
  return scalar wstatp = `wstatp'

end
