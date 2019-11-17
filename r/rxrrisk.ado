*! Ver.9510 of RXrrisk ...by Bob Obenchain              (STB-28: sg45)
program define rxrrisk
  version 3.1
*    version 4.0
    local varlist "req ex min(3)"
    local if "opt"
    local in "opt"
    local options "Msteps(int 4) Qshape(rea 0) Rescale(int 1) Tol(rea 0.01)"
    parse "`*'"
    parse "`varlist'", parse(" ")
    display _n in gr "RXrrisk:  Shrinkage Path has Qshape =" in ye %5.2f `qshape'
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
    while Lambda[1,`Rank'+1]>`tol' & `Rank'<`p' {
        local Rank = `Rank'+1
        local factor = 1.0/sqrt(Lambda[1,`Rank']*yTy)
        matrix pcorr[`Rank',1] = pcorr[`Rank',1] * `factor'
        local factor = sqrt(yTy/Lambda[1,`Rank'])
        matrix uccom[`Rank',1] = pcorr[`Rank',1] * `factor'
        matrix V[`Rank',`Rank'] = 1/Lambda[1,`Rank']
        }
    if `Rank' < `p' {
        display _n in gr "RXrrisk requires the regressor matrix to be of full column rank."
        exit 1
        }
    matrix eiginv = V
    matrix smse = G*eiginv
    matrix smse = smse*G'
    matrix b0 = G*uccom
    matrix b = b0'*XTy
    local df = `nobs' - `p' - 1
    scalar resvar = (yTy-b[1,1])/`df'
    matrix V = V*resvar
    local names : colnames(V)
    matrix rownames uccom = `names'
    matrix rownames V = `names'
    matrix b = uccom'
    matrix post b V, depn(`1') dof(`df') obs(`nobs')
    global S_E_depv "`1'"
    global S_E_cmd "rxrrisk"
    scalar sigma = sqrt(resvar)
    display _n in gr "RXrrisk:  Estimated Sigma =" in ye %10.0g sigma
    display in gr "RXrrisk:  Estimated Uncorrelated Components..."
    matrix c = uccom'
    matrix list c
    *
    capture matrix list rxsigma
    if _rc~=0 {
        display _n in gr "Before invoking rxrrisk, you must define a true value for sigma"
        display in gr "via a Stata command of the form: " in ye ". matrix rxsigma = (#)"
        exit _rc
        }
    capture matrix list rxgamma
    if _rc~=0 {
        display _n in gr "Before invoking rxrrisk, you must define a true components vector"
        display in gr "via a Stata command of the form: " in ye ". matrix rxgamma = (#,...,#)"
        exit _rc
        }
    local p1 = rowsof(rxgamma)
    local p2 = colsof(rxgamma)
    if `p1'~=1 | `p2'~=`p' {
        #delim ;
        display _n
          in gr "The true components vector, rxgamma, must consist of 1 row and "
          in ye %2.0f `p';
        display
          in gr "columns.  Use a Stata command of the form:"
          in ye ". matrix rxgamma = (#,...,#)" ;
        #delim cr
        exit
        }
    display _n in gr "RXrrisk:  True Sigma =" in ye %10.0g rxsigma[1,1]
    display in gr "RXrrisk:  True Uncorrelated Components..."
    matrix list rxgamma
    *
    display _n in gr "RXrrisk will now rescale the true sigma and components,"
    display in gr "preserving all signal/noise ratios, so as to equate the"
    display in gr "expected response sum-of-squares to yTy =" in ye %10.0g yTy
    *
    local expyTy = 0
    local idx = 0
    while `idx'<`p' {
        local idx = `idx'+1
        local expyTy = `expyTy' + rxgamma[1,`idx']^2*Lambda[1,`idx']
        }
    local expyTy = `expyTy'+ (`nobs'-1)*rxsigma[1,1]^2
    local factor = sqrt(yTy/`expyTy')
    matrix rxsigma[1,1] = rxsigma[1,1]*`factor'
    matrix rxgamma = rxgamma*`factor'
    display _n in gr "RXrrisk:  Rescaled True Sigma =" in ye %10.0g rxsigma[1,1]
    display in gr "RXrrisk:  Rescaled True Uncorrelated Components..."
    matrix list rxgamma
    *
    local mobj = 0
    scalar tinc = trace(smse)
    #delim ;
    display in gr "MCAL =" in ye %7.3f `mobj'
            in gr " ... True  OLS Summed SMSE =" in ye %10.0g tinc ;
    #delim cr
    *
    local maxinc = `p'*`msteps'
    matrix eqm1 = J(1,`p',0)
    matrix delta = J(1,`p',1)
    matrix cold = J(1,`p',1)
    *
    matrix bstar = rxgamma*G'
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
    local idx = 1
    while `idx'<=`p' {
        if `qshape'==1 {
            matrix eqm1[1,`idx'] = 1.0
            }
        else {
            matrix eqm1[1,`idx'] = exp((`qshape'-1) * log(Lambda[1,`idx']))
            }
        local idx = `idx'+1
        }
    local mcal = 0.0
    local konst = 0.0
    local kinc = 0.0
    local idx = 1
    while `idx'<=`maxinc' {
        local mobj = `idx'/`msteps'
        *
        if `mobj'>=`p' {
            matrix delta = J(1,`p',0)
            matrix Del = J(`p',`p',0)
            local kinc = 9999.9
            }
        else {
           local funs = `mobj'-`p'
           if `qshape'==1 {
               local kinc = -1*`mobj'/`funs'
               }
           else {
               while abs(`funs')>`tol'^2 {
                   local funs = 0
                   local derivs = 0
                   local jdx = 1
                   while `jdx'<=`p' {
                       local funs = `funs'+1/(1+`kinc'*eqm1[1,`jdx'])
                       local derivs = `derivs'+eqm1[1,`jdx']/(1+`kinc'*eqm1[1,`jdx'])^2
                       local jdx = `jdx'+1
                       }
                   local funs = `funs'+`mobj'-`p'
                   local kinc = `kinc' + `funs'/`derivs'
                   }
               }
           local jdx = 1
           while `jdx'<=`p' {
               matrix delta[1,`jdx']=1/(1+`kinc'*eqm1[1,`jdx'])
               local jdx = `jdx'+1
               }
           matrix Del = diag(delta)
           }
        matrix b = rxgamma*Del
        matrix b = b*G'
        * b is now the row vector of expected ridge coefficients
        matrix rownames b = `mobj'
        local names : colnames(bstar)
        matrix colnames b = `names'
        matrix bstar = bstar\b
        *
        matrix vecr = I(`p')
        matrix vecr = vecr-Del
        matrix vecr = rxgamma*vecr
        local factor = 1/rxsigma[1,1]
        matrix vecr = vecr*`factor'
        * vecr is now the vector of ridge bias terms
        matrix compr = vecr'*vecr
        matrix vecr = Del*Del
        matrix vecr = vecr*eiginv
        matrix compr = compr+vecr
        * compr is matrix of expected component risks (bias*bias'+diag.var)
        matrix smse = G*compr
        matrix smse = smse*G'
        matrix rinc = vecdiag(smse)
        scalar tinc = 0.0
        local jdx = 0
        while `jdx'<`p' {
          local jdx = `jdx'+1
          scalar tinc = tinc+rinc[1,`jdx']
          }
        #delim ;
        display in gr "MCAL =" in ye %7.3f `mobj'
                in gr " ... True Summed SMSE Risk =" in ye %10.0g tinc ;
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
*            matrix cinc = -cinc        changed per BobO's instructions
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
        *
        local idx = `idx'+1
        }
    preserve
    *
    #delim ;
    display _n in gr "RXrrisk:  Expected Coefficients..." ;
    rxrmkdta bstar m ;
    generate mcal=real(m) ;
    drop m ;
    note: RXrrisk TS ...Expected Coefficients, Q-shape= `qshape' ;
    save rxrrisk1, replace ;
    capture graph _all, symbol(....................)
      connect(llllllllllllllllllll) xlabel ylabel border
      b2(" ") yline(0) title("RXrrisk: Expected Coefficient Trace, Q=`qshape'")
      saving(rxrrisk1, replace) ;
    * ;
    display _n in gr "RXrrisk:  True Scaled MSE Risk..." ;
    rxrmkdta risk m ;
    generate mcal=real(m) ;
    drop m ;
    note: RXrrisk TS ...True Scaled MSE Risk, Q-shape= `qshape' ;
    save rxrrisk2, replace ;
    capture graph _all, symbol(....................)
      connect(llllllllllllllllllll) xlabel ylabel border
      b2(" ") title("RXrrisk: True Scaled MSE Risk, Q=`qshape'")
      saving(rxrrisk2, replace) ;
    * ;
    display _n in gr "RXrrisk:  True Excess Eigenvalues..." ;
    rxrmkdta exev m ;
    generate mcal=real(m) ;
    drop m ;
    note: RXrrisk TS ...True Excess Eigenvalues, Q-shape= `qshape' ;
    save rxrrisk3, replace ;
    capture graph _all, symbol(....................)
      connect(llllllllllllllllllll) xlabel ylabel border
      b2(" ") title("RXrrisk: True Excess Eigenvalues, Q=`qshape'")
      saving(rxrrisk3, replace) ;
    * ;
    display _n in gr "RXrrisk:  True Inferior Direction Cosines..." ;
    rxrmkdta infd m ;
    generate mcal=real(m) ;
    drop m ;
    note: RXrrisk TS ...True Inferior Direction Cosines, Q-shape= `qshape' ;
    save rxrrisk4, replace ;
    capture graph _all, symbol(....................)
      connect(llllllllllllllllllll) xlabel ylabel border
      b2(" ") title("RXrrisk: True Inferior Direction, Q=`qshape'") yline(0)
      saving(rxrrisk4, replace) ;
    * ;
    display _n in gr "RXrrisk:  Shrinkage DELTA Factors..." ;
    rxrmkdta dfact m ;
    generate mcal=real(m) ;
    drop m ;
    note: RXrrisk TS ...Shrinkage DELTA Factors, Q-shape= `qshape' ;
    save rxrrisk5, replace ;
    capture graph _all, symbol(....................)
      connect(llllllllllllllllllll) xlabel ylabel border
      b2(" ") title("RXrrisk: Shrinkage Factors, Q=`qshape'")
      saving(rxrrisk5, replace) ;
    #delim cr
end
