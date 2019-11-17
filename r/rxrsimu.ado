*! Ver.9510 of RXrsimu ...by Bob Obenchain              (STB-28: sg45)
program define rxrsimu
  version 3.1
*    version 4.0
    local varlist "req ex min(3)"
    local if "opt"
    local in "opt"
    local options "Msteps(int 4) Qshape(rea 0) Start(int 12345) Rescale(int 1) Tol(rea 0.01)"
    parse "`*'"
    parse "`varlist'", parse(" ")
    display _n in gr "RXrsimu:  Shrinkage Path has Qshape =" in ye %5.2f `qshape'
    quietly matrix accum XTX = `varlist' `if' `in', deviations noconstant
    local nobs = _result(1)
    matrix given = vecdiag(XTX)
    if `rescale'==1 {
        matrix XTX = corr(XTX)
        local factor = `nobs' - 1
        matrix XTX = XTX*`factor'
        }
    scalar yTy = XTX[1,1]
    matrix XTy = XTX[2...,1]
    matrix XTX = XTX[2...,2...]
    local names : colnames(XTX)
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
        }
    if `Rank' < `p' {
        display _n in gr "RXrsimu requires the regressor matrix to be of full column rank."
        exit 1
        }
    matrix b0 = G*uccom
    matrix b = b0'*XTy
    local df = `nobs' - `p' - 1
    scalar resvar = (yTy-b[1,1])/`df'
    scalar sigma = sqrt(resvar)
    display _n in gr "RXrsimu:  Estimated Sigma =" in ye %10.0g sigma
    display in gr "RXrsimu:  Estimated Uncorrelated Components..."
    matrix c = uccom'
    matrix list c
    *
    capture matrix list rxsigma
    if _rc~=0 {
        display _n in gr "Before invoking rxrsimu, you must define a true value for sigma"
        display in gr "via a Stata command of the form: " in ye ". matrix rxsigma = (#)"
        exit _rc
        }
    capture matrix list rxgamma
    if _rc~=0 {
        display _n in gr "Before invoking rxrsimu, you must define a true components vector"
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
    display _n in gr "RXrsimu:  True Sigma =" in ye %10.0g rxsigma[1,1]
    display in gr "RXrsimu:  True Uncorrelated Components..."
    matrix list rxgamma
    *
    display _n in gr "RXrsimu will now rescale the true sigma and components,"
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
    display _n in gr "RXrsimu:  Rescaled True Sigma =" in ye %10.0g rxsigma[1,1]
    display in gr "RXrsimu:  Rescaled True Uncorrelated Components..."
    matrix list rxgamma
    *
    matrix beta = rxgamma*G'
    matrix b = beta
    local idx = 0
    while `idx'<`p' & `rescale'==1 {
        local idx = `idx'+1
        matrix b[1,`idx'] = b[1,`idx']*sqrt(`nobs'-1)
        local jdx = `idx'+1
        matrix b[1,`idx'] = b[1,`idx']/sqrt(given[1,`jdx'])
        }
    matrix colnames b = `names'
    matrix rownames V = `names'
    matrix colnames V = `names'
    matrix post b V, depn(`1') dof(`df') obs(`nobs')
    global S_E_depv "`1'"
    global S_E_cmd "rxrsimu"
    capture drop yexp
    predict yexp
    quietly summarize yexp
    quietly replace yexp = yexp - _result(3)
    capture drop ysim
    set seed `start'
    generate ysim = yexp + rxsigma[1,1]*invnorm(uniform())
    quietly summarize ysim
    quietly replace ysim = ysim - _result(3)
    * summarize yexp ysim
    *
    quietly matrix accum XTX = ysim `names' `if' `in', deviations noconstant
    if `rescale'==1 {
        matrix XTX = corr(XTX)
        local factor = `nobs' - 1
        matrix XTX = XTX*`factor'
        }
    scalar yTy = XTX[1,1]
    matrix XTy = XTX[2...,1]
    matrix XTX = XTX[2...,2...]
    * matrix symeigen G Lambda = XTX
    matrix pcorr = G'*XTy
    matrix uccom = J(`p',1,0)
    local Rank = 0
    while Lambda[1,`Rank'+1]>`tol' & `Rank'<`p' {
        local Rank = `Rank'+1
        local factor = 1.0/sqrt(Lambda[1,`Rank']*yTy)
        matrix pcorr[`Rank',1] = pcorr[`Rank',1] * `factor'
        local factor = sqrt(yTy/Lambda[1,`Rank'])
        matrix uccom[`Rank',1] = pcorr[`Rank',1] * `factor'
        }
    matrix b0 = G*uccom
    matrix b = b0'*XTy
    scalar resvar = (yTy-b[1,1])/`df'
    scalar simsig = sqrt(resvar)
    display _n in gr "RXrsimu:  Simulated Sigma =" in ye %10.0g simsig
    display in gr "RXrsimu:  Simulated Uncorrelated Components..."
    matrix c = uccom'
    matrix list c
    *
    local maxinc = `p'*`msteps'
    matrix eqm1 = J(1,`p',0)
    matrix delta = J(1,`p',1)
    *
    matrix bstar = c*G'
    matrix rownames bstar = 0
    matrix loss = bstar - beta
    local factor = 1/rxsigma[1,1]
    matrix loss = loss*`factor'
    scalar tinc = 0
    local idx = 0
    while `idx'<`p' {
        local idx = `idx'+1
        scalar qloss = loss[1,`idx']^2
        matrix loss[1,`idx'] = qloss
        scalar tinc = tinc + qloss
        }
    local mobj = 0
    #delim ;
    display in gr "MCAL =" in ye %7.3f `mobj'
            in gr " ... True OLS Summed SSE Loss =" in ye %10.0g tinc ;
    #delim cr

    matrix rownames loss = 0
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
        matrix b = c*Del
        matrix b = b*G'
        * b is now the row vector of simulated ridge coefficients
        matrix rownames b = `mobj'
        local names : colnames(bstar)
        matrix colnames b = `names'
        matrix bstar = bstar\b
        *
        matrix linc = b - beta
        local factor = 1/rxsigma[1,1]
        matrix linc = linc*`factor'
        scalar tinc = 0.0
        local jdx = 0
        while `jdx'<`p' {
            local jdx = `jdx'+1
            scalar qloss = linc[1,`jdx']^2
            matrix linc[1,`jdx'] = qloss
            scalar tinc = tinc + qloss
            }
        #delim ;
        display in gr "MCAL =" in ye %7.3f `mobj'
                in gr " ... True Summed SSE Loss =" in ye %10.0g tinc ;
        #delim cr
        *
        matrix rownames linc = `mobj'
        local names : colnames(loss)
        matrix colnames linc = `names'
        matrix loss = loss\linc
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
    display _n in gr "RXrsimu:  Simulated Shrinkage Coefficients..." ;
    rxrmkdta bstar m ;
    generate mcal=real(m) ;
    drop m ;
    note: RXrsimu TS ...Shrinkage Coefficients, Q-shape= `qshape' ;
    save rxrsimu1, replace ;
    capture graph _all, symbol(....................)
      connect(lllllllllllllllllllll) xlabel ylabel border
      b2(" ") yline(0) title("RXrsimu: Coefficients Trace, Q=`qshape'")
      saving(rxrsimu1, replace) ;
    * ;
    display _n in gr "RXrsimu:  Scaled True Squared Error Losses..." ;
    rxrmkdta loss m ;
    generate mcal=real(m) ;
    drop m ;
    note: RXrsimu TS ...Scaled True Squared Error Losses, Q-shape= `qshape' ;
    save rxrsimu2, replace ;
    capture graph _all, symbol(....................)
      connect(llllllllllllllllllll) xlabel ylabel border
      b2(" ") title("RXrsimu: Scaled Squared Error Loss, Q=`qshape'")
      saving(rxrsimu2, replace) ;
    * ;
    display _n in gr "RXrsimu:  Shrinkage DELTA Factors..." ;
    rxrmkdta dfact m ;
    generate mcal=real(m) ;
    drop m ;
    note: RXrsimu TS ...Shrinkage DELTA Factors, Q-shape= `qshape' ;
    save rxrsimu5, replace ;
    capture graph _all, symbol(....................)
      connect(llllllllllllllllllll) xlabel ylabel border
      b2(" ") title("RXrsimu: Shrinkage Factors, Q=`qshape'")
      saving(rxrsimu5, replace) ;
    #delim cr
end
