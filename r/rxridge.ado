*! Ver.9510 of RXridge ...by Bob Obenchain              (STB-28: sg45)
program define rxridge
  version 3.1
*    version 4.0
    local varlist "req ex min(3)"
    local if "opt"
    local in "opt"
    local options "Msteps(int 4) Qshape(rea 0) Rescale(int 1) Tol(rea 0.01)"
    parse "`*'"
    parse "`varlist'", parse(" ")
    quietly matrix accum XTX = `varlist' `if' `in', deviations noconstant
    local nobs = _result(1)
    if `rescale'==1 {
        matrix XTX = corr(XTX)
        local factor = `nobs' - 1
        matrix XTX = XTX*`factor'
        }
    display _newline in gr "RXridge:  Shrinkage Path has Qshape =" in ye %5.2f `qshape'
    scalar yTy = XTX[1,1]
    display in gr "RXridge:  Adjusted response sum-of-squares =" in ye %10.0g yTy
    matrix XTy = XTX[2...,1]
    matrix XTX = XTX[2...,2...]
    local p = rowsof(XTX)
    matrix symeigen G Lambda = XTX
    matrix pcorr = G'*XTy
    matrix uccom = J(`p',1,0)
    matrix V = J(`p',`p',0)
    matrix srat = I(`p')
    local Rank = 0
    while Lambda[1,`Rank'+1]>`tol' & `Rank'<`p' {
        local Rank = `Rank'+1
        local factor = 1.0/sqrt(Lambda[1,`Rank']*yTy)
        matrix pcorr[`Rank',1] = pcorr[`Rank',1] * `factor'
        local factor = sqrt(yTy/Lambda[1,`Rank'])
        matrix uccom[`Rank',1] = pcorr[`Rank',1] * `factor'
        matrix V[`Rank',`Rank'] = 1/Lambda[1,`Rank']
        local factor = 1.0/sqrt(Lambda[1,`Rank'])
        matrix srat[`Rank',`Rank'] = `factor'
        }
    matrix b0 = G*uccom
    matrix b = b0'*XTy
    local df = `nobs' - `Rank' - 1
    scalar resvar = (yTy-b[1,1])/`df'
    display in gr "RXridge:  OLS Residual Variance =" in ye %10.0g resvar
    scalar vpcorr = resvar/yTy
    display in gr "RXridge:  Variance of Principal Correlations =" in ye %10.0g vpcorr
    local factor = 1.0/sqrt(vpcorr)
    matrix tstat = pcorr*`factor'
    matrix srat = srat*tstat
    matrix eiginv = V
    matrix smse = G*eiginv
    matrix smse = smse*G'
    *
    local mobj = 0
    scalar tinc = trace(smse)
    #delim ;
    display in gr "MCAL =" in ye %7.3f `mobj'
            in gr " ... True  OLS Summed SMSE =" in ye %10.0g tinc ;
    #delim cr
    matrix V = V*resvar
    local names : colnames(V)
    matrix rownames uccom = `names'
    matrix rownames V = `names'
    matrix b = uccom'
    matrix post b V, depn(`1') dof(`df') obs(`nobs')
    global S_E_depv "`1'"
    global S_E_cmd "rxridge"
    *
    local maxinc = `Rank'*`msteps'
    matrix eqm1 = J(1,`p',0)
    matrix delta = J(1,`p',1)
    matrix cold = J(1,`p',1)
    if `Rank'<`p' {
        local idx = `Rank'
        while `idx'<`p' {
            local idx = `idx'+1
            matrix delta[1,`idx']=0
            }
        }
    *
    matrix bstar = b0'
    matrix rownames bstar = 0
    matrix risk = vecdiag(smse)
    matrix rownames risk = 0
    matrix exev = J(1,`p',0)
    matrix rownames exev = 0
    matrix infd = J(1,`p',0)
    matrix rownames infd = 0
    matrix dfact = delta
    matrix rownames dfact = 0
    *
    local idx = 0
    while `idx'<`Rank' {
        local idx = `idx'+1
        if `qshape'==1 {
            matrix eqm1[1,`idx'] = 1.0
            }
        else {
            matrix eqm1[1,`idx'] = exp((`qshape'-1) * log(Lambda[1,`idx']))
            }
        }
    local mcal = 0.0
    local konst = 0.0
    local kinc = 0.0
    local const = (`nobs'-`Rank'-3)/(`nobs'-`Rank'-1)
    local idx = 0
    while `idx'<`maxinc' {
        local idx = `idx'+1
        local mobj = `idx'/`msteps'
        *
        if `mobj'>=`Rank' {
            matrix delta = J(1,`p',0)
            matrix Del = J(`p',`p',0)
            local kinc = 9999.9
            }
        else {
           local funs = `mobj'-`Rank'
           if `qshape'==1 {
               local kinc = -1*`mobj'/`funs'
               }
           else {
               while abs(`funs')>0.0001 {
                   local funs = 0
                   local derivs = 0
                   local jdx = 1
                   while `jdx'<=`Rank' {
                       local funs = `funs'+1/(1+`kinc'*eqm1[1,`jdx'])
                       local derivs = `derivs'+eqm1[1,`jdx']/(1+`kinc'*eqm1[1,`jdx'])^2
                       local jdx = `jdx'+1
                       }
                   local funs = `funs'+`mobj'-`Rank'
                   local kinc = `kinc' + `funs'/`derivs'
                   }
               }
           local jdx = 0
           while `jdx'<`Rank' {
               local jdx = `jdx'+1
               matrix delta[1,`jdx']=1/(1+`kinc'*eqm1[1,`jdx'])
               }
           matrix Del = diag(delta)
           }
        matrix b = Del*uccom
        matrix b = G*b
        matrix b = b'
        matrix rownames b = `mobj'
        local names : colnames(bstar)
        matrix colnames b = `names'
        matrix bstar = bstar\b
        *
        matrix vecr = I(`p')
        matrix vecr = vecr-Del
        matrix vecr = vecr*srat
        matrix compr = vecr*vecr'
        matrix compr = compr*`const'
        matrix vecr = I(`p')
        matrix vecr = Del-vecr
        matrix vecr = Del+vecr
        matrix vecr = vecr*eiginv
        matrix compr = compr+vecr
        matrix diagc = vecdiag(compr)
        matrix diagc = diag(diagc)
        matrix lowr = eiginv*Del
        matrix lowr = lowr*Del
        matrix maxc = diagc
        local jdx = 0
        while `jdx'<`p' {
          local jdx = `jdx'+1
          if diagc[`jdx',`jdx'] < lowr[`jdx',`jdx'] {
             matrix maxc[`jdx',`jdx'] = lowr[`jdx',`jdx']
              }
          }
        matrix compr = compr-diagc
        matrix compr = compr+maxc
        matrix smse = G*compr
        matrix smse = smse*G'
        matrix rinc = vecdiag(smse)
        matrix lowb = G*lowr
        matrix lowb = lowb*G'
        scalar tinc = 0.0
        local jdx = 0
        while `jdx'<`p' {
          local jdx = `jdx'+1
          if rinc[1,`jdx'] < lowb[`jdx',`jdx'] {
             matrix rinc[1,`jdx'] = lowb[`jdx',`jdx']
             }
          scalar tinc = tinc+rinc[1,`jdx']
          }
        #delim ;
        display in gr "MCAL =" in ye %7.3f `mobj'
                in gr " ... Estimated Summed SMSE =" in ye %10.0g tinc ;
        #delim cr
        matrix emse = eiginv-compr
        matrix symeigen emvec emval = emse
        matrix cinc = J(1,`p',0)
        if emval[1,`p'] < `tol'*-1 {
          matrix emvec = G*emvec
          matrix cinc = emvec[1...,`p']
          matrix cosang = cold*cinc
          matrix cinc = cinc'
          if cosang[1,1] < 0.0 {
            matrix cinc = cinc*-1
            }
          matrix cold = cinc
          }
        *
        matrix rownames rinc = `mobj'
        local names : colnames(risk)
        matrix colnames rinc = `names'
        matrix risk = risk\rinc
        *
        matrix rownames emval = `mobj'
        local names : colnames(exev)
        matrix colnames emval = `names'
        matrix exev = exev\emval
        *
        matrix rownames cinc = `mobj'
        local names : colnames(infd)
        matrix colnames cinc = `names'
        matrix infd = infd\cinc
        *
        matrix rownames delta = `mobj'
        local names : colnames(dfact)
        matrix colnames delta = `names'
        matrix dfact = dfact\delta
        }
    preserve
    *
    #delim ;
    display _n in gr "RXridge:  Shrinkage Coefficients..." ;
    rxrmkdta bstar m ;
    generate mcal=real(m) ;
    drop m ;
    note: RXridge TS ...Shrinkage Coefficients, Q-shape= `qshape' ;
    save rxridge1, replace ;
    capture graph _all, symbol(....................)
      connect(llllllllllllllllllll) xlabel ylabel border
      b2(" ") yline(0) title("RXridge: Coefficients Trace, Q=`qshape'")
      saving(rxridge1, replace) ;
    * ;
    display _n in gr "RXridge:  Scaled MSE Risk Estimates..." ;
    rxrmkdta risk m ;
    generate mcal=real(m) ;
    drop m ;
    note: RXridge TS ...Scaled MSE Risk Estimates, Q-shape= `qshape' ;
    save rxridge2, replace ;
    capture graph _all, symbol(....................)
      connect(llllllllllllllllllll) xlabel ylabel border
      b2(" ") title("RXridge: Scaled MSE Risk, Q=`qshape'")
      saving(rxridge2, replace) ;
    * ;
    display _n in gr "RXridge:  Excess Eigenvalue Estimates..." ;
    rxrmkdta exev m ;
    generate mcal=real(m) ;
    drop m ;
    note: RXridge TS ...Excess Eigenvalue Estimates, Q-shape= `qshape' ;
    save rxridge3, replace ;
    capture graph _all, symbol(....................)
      connect(llllllllllllllllllll) xlabel ylabel border
      b2(" ") title("RXridge: Excess Eigenvalues, Q=`qshape'")
      saving(rxridge3, replace) ;
    * ;
    display _n in gr "RXridge:  Inferior Direction Cosine Estimates..." ;
    rxrmkdta infd m ;
    generate mcal=real(m) ;
    drop m ;
    note: RXridge TS ...Inferior Direction Cosines, Q-shape= `qshape' ;
    save rxridge4, replace ;
    capture graph _all, symbol(....................)
      connect(llllllllllllllllllll) xlabel ylabel border
      b2(" ") title("RXridge: Inferior Direction, Q=`qshape'") yline(0)
      saving(rxridge4, replace) ;
    * ;
    display _n in gr "RXridge:  Shrinkage DELTA Factors..." ;
    rxrmkdta dfact m ;
    generate mcal=real(m) ;
    drop m ;
    note: RXridge TS ...Shrinkage DELTA Factors, Q-shape= `qshape' ;
    save rxridge5, replace ;
    capture graph _all, symbol(....................)
      connect(llllllllllllllllllll) xlabel ylabel border
      b2(" ") title("RXridge: Shrinkage Factors, Q=`qshape'")
      saving(rxridge5, replace) ;
    #delim cr
    *
    scalar sigma = sqrt(resvar)
    #delimit ;
    display _n
        in gr "RXridge:  Estimated Sigma ="
        in ye %10.0g sigma ;
    display _n
        in gr "RXridge:  Uncorrelated Components..."
        _col(56) "Number of obs =" in ye %8.0f _result(1) ;
    #delimit cr
    matrix mlout
end


