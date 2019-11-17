*! Ver.9510 of RXrcrlq ...by Bob Obenchain              (STB-28: sg45)
program define rxrcrlq
  version 3.1
  local varlist "req ex min(3)"
  local if "opt"
  local in "opt"
  local options "QMAX(rea 5) QMIN(rea -5) NQ(int 21) Rescale(int 1) Tol(rea 0.01)"
  parse "`*'"
  parse "`varlist'", parse(" ")
  if `qmax' < 2 {
     `qmax' = 2
      }
  if `qmin' > -2 {
     `qmin' = -2
      }
  if `nq' < 9 {
     `nq' = 9
      }
  quietly matrix accum XTX = `varlist' `if' `in', deviations noconstant
  local nobs = _result(1)
  if `rescale'==1 {
      matrix XTX = corr(XTX)
      local factor = `nobs' - 1
      matrix XTX = XTX*`factor'
      }
  scalar yTy = XTX[1,1]
  matrix XTy = XTX[2...,1]
  matrix XTX = XTX[2...,2...]
  local p = rowsof(XTX)
  matrix symeigen G Lambda = XTX
  matrix pcorr = G'*XTy
  matrix uccom = J(`p',1,0)
  matrix V = J(`p',`p',0)
  local Rank = 0
  local r2 = 0.0
  while Lambda[1,`Rank'+1]>`tol' & `Rank'<`p' {
      local Rank = `Rank'+1
      local factor = 1.0/sqrt(Lambda[1,`Rank']*yTy)
      matrix pcorr[`Rank',1] = pcorr[`Rank',1] * `factor'
      local r2 = `r2'+pcorr[`Rank',1]^2
      local factor = sqrt(yTy/Lambda[1,`Rank'])
      matrix uccom[`Rank',1] = pcorr[`Rank',1] * `factor'
      matrix V[`Rank',`Rank'] = 1/Lambda[1,`Rank']
      }
  matrix b0 = G*uccom
  matrix b = b0'*XTy
  local df = `nobs' - `Rank' - 1
  scalar resvar = (yTy-b[1,1])/`df'
  matrix V = V*resvar
  local names : colnames(V)
  matrix rownames uccom = `names'
  matrix rownames V = `names'
  matrix b = uccom'
  matrix post b V, depname(`1') dof(`df') obs(`nobs')
  global S_E_depv "`1'"
  global S_E_cmd "rxrcrlq"
  scalar sigma = sqrt(resvar)
  #delimit ;
  display _n
      in gr "RXrcrlq:  Estimated Sigma ="
      in ye %10.0g sigma ;
  display _n
      in gr "RXrcrlq:  Uncorrelated Components..."
      _col(56) "Number of obs =" in ye %8.0f _result(1) ;
  #delimit cr
  matrix mlout
  *
  display _n in gr "RXrcrlq: Classical, Normal-Theory, Maximum-Likelihood Choice of Q=>Shape"
  display in gr "and MCAL=>Extent of Shrinkage in Generalized Ridge Regression..."
  display _n in ye _dup(70) "-"
  display in gr "The curlicue function, CRL(Q), is the (non-negative) Correlation"
  display in gr "between the R-vector of absolute values of the principal correlations"
  display in gr "of regressors with the response and the L-vector of regressor spread"
  display in gr "eigenvalues raised to the power (1-Q)/2."
  display in ye _dup(70) "-" _n
  *
  matrix qvec = J(`nq',1,0)
  matrix crlq = J(`nq',1,0)
  matrix mvec = J(`nq',1,0)
  matrix kvec = J(`nq',1,0)
  matrix chisq = J(`nq',1,0)
  local csmin = 10e+99
  local qatmax = 0
  local nqidx = 0
  while `nqidx' < `nq' {
    local nqidx = `nqidx'+1
    local qnow = ((`qmin'-`qmax')*`nqidx'+(`nq'*`qmax')-`qmin')/(`nq'-1)
    * display in gr "Qshape =" in ye %6.2f `qnow'
    matrix qvec[`nqidx',1] = `qnow'
    matrix s1mq = J(`Rank',1,1)
    local sq2 = 0
    local pcs1mq = 0
    local idx = 0
    while `idx' < `Rank' {
      local idx = `idx'+1
      if `qnow' != 1 {
        matrix s1mq[`idx',1] = exp((1-`qnow')*log(sqrt(Lambda[1,`idx'])))
        }
/*
        The next 7 lines were added to work around a compiler bug.
        Added by Sean Becketti, November 6, 1995.
*/
      capture confirm number `sq2'
      if _rc {
                if "`sq2'"!="" {
                        parse "`sq2'", parse(":")
                        local sq2 `1'`3'
                }
      }
      local sq2 = `sq2' + s1mq[`idx',1]^2
      local pcs1mq = `pcs1mq' + abs(pcorr[`idx',1])*s1mq[`idx',1]
      }
    matrix crlq[`nqidx',1] = `pcs1mq'/sqrt(`r2'*`sq2')
    local r2c2 = `r2'*crlq[`nqidx',1]^2
    matrix kvec[`nqidx',1] = `sq2'*(1-`r2c2')/(`nobs'*`r2c2')
    local idx = 0
    while `idx' < `Rank' {
      local idx = `idx'+1
      matrix s1mq[`idx',1] = kvec[`nqidx',1]/s1mq[`idx',1]^2
      matrix mvec[`nqidx',1] = mvec[`nqidx',1] + s1mq[`idx',1]/(1+s1mq[`idx',1])
      }
    matrix chisq[`nqidx',1] = `nobs'*log((1-`r2c2')/(1-`r2'))
    if chisq[`nqidx',1] < `csmin' {
       local csmin = chisq[`nqidx',1]
       local qatmax = `qnow'
       }
    }
  *
  matrix colnames qvec = Qshape
  matrix colnames mvec = MCAL
  matrix qvec = qvec,mvec
  matrix colnames kvec = Konst
  matrix qvec = qvec,kvec
  matrix colnames crlq = CRL(Q)
  matrix qvec = qvec,crlq
  matrix colnames chisq = ChiSq
  matrix qvec = qvec,chisq
  *
  matrix list qvec
  local df2 = `Rank'-2
  #delimit ;
  display _n in gr "The most likely Qshape =" in ye %6.2f `qatmax'
    in gr " achieves Maximum CRL(Q) and Minimum ChiSq." ;
  #delimit cr
  if `df2'>0 {
    #delimit ;
    display in gr "This Min ChiSq has degrees-of-freedom =" in ye %3.0f `df2'
      in gr " and sig.level =" in ye %5.3f 1-chiprob(`csmin',`df2') ;
    #delimit cr
    }
  else {
    display in gr "In 2-regressor models like this, Min ChiSq has 0 degrees-of-freedom."
    }
  display _n in ye _dup(70) "-"
  display in gr "In multiple regression models where the Minumum ChiSq is significantly"
  display in gr "greater than zero, the 2-parameter generalized ridge family is probably"
  display in gr "too restrictive (unlikely to contain the MSE optimal shrinkage factors.)"
  display in ye _dup(70) "-" _n
end
