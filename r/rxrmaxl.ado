*! Ver.9510 of RXrmaxl ...by Bob Obenchain              (STB-28: sg45)
program define rxrmaxl
    version 3.1
    local varlist "req ex min(3)"
    local if "opt"
    local in "opt"
    local options "Msteps(int 4) Qshape(rea 0) OMDmin(rea 10e-13) Rescale(int 1) Tol(rea 0.01)"
    parse "`*'"
    parse "`varlist'", parse(" ")
    quietly matrix accum XTX = `varlist' `if' `in', deviations noconstant
    local nobs = _result(1)
    if `rescale'==1 {
        matrix XTX = corr(XTX)
        local factor = `nobs' - 1
        matrix XTX = XTX*`factor'
        }
    display _n in gr "RXrmaxl:  Shrinkage Path has Qshape =" in ye %5.2f `qshape'
    scalar yTy = XTX[1,1]
    matrix XTy = XTX[2...,1]
    matrix XTX = XTX[2...,2...]
    local p = rowsof(XTX)
    matrix symeigen G Lambda = XTX
    matrix pcorr = G'*XTy
    matrix uccom = J(`p',1,0)
    matrix V = J(`p',`p',0)
    matrix srat = I(`p')
    matrix eiginv = I(`p')
    local r2 = 0.0
    local Rank = 0
    while Lambda[1,`Rank'+1]>`tol' & `Rank'<`p' {
        local Rank = `Rank'+1
        local factor = 1.0/sqrt(Lambda[1,`Rank']*yTy)
        matrix pcorr[`Rank',1] = pcorr[`Rank',1] * `factor'
        local r2 = `r2'+pcorr[`Rank',1]^2
        local factor = sqrt(yTy/Lambda[1,`Rank'])
        matrix uccom[`Rank',1] = pcorr[`Rank',1] * `factor'
        matrix V[`Rank',`Rank'] = 1/Lambda[1,`Rank']
        local factor = 1.0/sqrt(Lambda[1,`Rank'])
        matrix srat[`Rank',`Rank'] = `factor'
        local factor = 1.0/Lambda[1,`Rank']
        matrix eiginv[`Rank',`Rank'] = `factor'
        }
    matrix b0 = G*uccom
    matrix b = b0'*XTy
    local df = `nobs' - `Rank' - 1
    scalar resvar = (yTy-b[1,1])/`df'
    scalar vpcorr = resvar/yTy
    local factor = 1.0/sqrt(vpcorr)
    matrix tstat = pcorr*`factor'
    matrix srat = srat*tstat
    matrix smse = G*eiginv
    matrix smse = smse*G'
    *
    matrix V = V*resvar
    local names : colnames(V)
    matrix rownames uccom = `names'
    matrix rownames V = `names'
    matrix b = uccom'
    matrix post b V, depn(`1') dof(`df') obs(`nobs')
    global S_E_depv "`1'"
    global S_E_cmd "rxrmaxl"
    scalar sigma = sqrt(resvar)
    #delimit ;
    display _n
        in gr "RXrmaxl:  Estimated Sigma ="
        in ye %10.0g sigma ;
    display _n
        in gr "RXrmaxl:  Uncorrelated Components..."
        _col(56) "Number of obs =" in ye %8.0f _result(1) ;
    #delimit cr
    matrix mlout
    display _n in gr "RXrmaxl:  3 Normal, Maximum-Likelihood Shrinkage Criteria..."
    display in gr "(Classical, Empirical Bayes, and Random Coefficients)"
    if `r2' >= 1 {
      display _n in gr "Maximum likelihood shrinkage cannot be applied when R2>=1."
      exit
      }
    *
    local maxinc = `Rank'*`msteps'
    matrix eqm1 = J(1,`p',0)
    matrix delta = J(1,`p',1)
    if `Rank'<`p' {
        local idx = `Rank'
        while `idx'<`p' {
            local idx = `idx'+1
            matrix delta[1,`idx']=0
            }
        }
    matrix omd  = J(1,`p',`omdmin')
    matrix ddomd = J(1,`p',1)
    matrix bstar = b0'
    matrix rownames bstar = 0
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
    matrix CLIK = J(1,1,10e+99)
    matrix rownames CLIK = 0
    matrix colnames CLIK = CLIK
    matrix EBAY = J(1,1,10e+99)
    matrix rownames EBAY = 0
    matrix colnames EBAY = EBAY
    matrix RCOF = J(1,1,10e+99)
    matrix rownames RCOF = 0
    matrix colnames RCOF = RCOF
    local idx = 0
    while `idx'<`maxinc' {
        local idx = `idx'+1
        local mobj = `idx'/`msteps'
        display in gr "MCAL =" in ye %7.3f `mobj'
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
        local rxi = 0
        local sumdd = 0
        local jdx = 1
        while `jdx'<=`Rank' {
            matrix omd[1,`jdx'] = 1-delta[1,`jdx']
            if omd[1,`jdx'] < `omdmin' {
               matrix omd[1,`jdx'] = `omdmin'
               }
            matrix ddomd[1,`jdx'] = delta[1,`jdx']/omd[1,`jdx']
            local sumdd = `sumdd' + ddomd[1,`jdx']
            local rxi = `rxi' + abs(pcorr[`jdx',1])*sqrt(ddomd[1,`jdx'])
            local jdx = `jdx'+1
            }
        scalar slik = 2 / ( `rxi' + sqrt( 4*`nobs' + `rxi'^2 ) )
        scalar clik = 2*`nobs'*log(slik)+`sumdd'-(`rxi'/slik)
        scalar clik = clik -`nobs'*log((1-`r2')/`nobs')
        scalar ebay = 0
        scalar rcof = 0
        local sr2d = 0
        local jdx = 0
        while `jdx'<`Rank' {
            local jdx = `jdx'+1
            scalar ebay = ebay+tstat[`jdx',1]^2*omd[1,`jdx']-log(omd[1,`jdx'])
            scalar rcof = rcof - log(omd[1,`jdx'])
            local sr2d = `sr2d'+pcorr[`jdx',1]^2*delta[1,`jdx']
            }
        scalar rcof = rcof + `nobs'*log((1-`sr2d')/(1-`r2'))
        matrix b = J(1,1,0)
        *
        matrix b[1,1] = clik
        matrix rownames b = `mobj'
        matrix colnames b = CLIK
        matrix CLIK = CLIK\b
        *
        matrix b[1,1] = ebay
        matrix rownames b = `mobj'
        matrix colnames b = EBAY
        matrix EBAY = EBAY\b
        *
        matrix b[1,1] = rcof
        matrix rownames b = `mobj'
        matrix colnames b = RCOF
        matrix RCOF = RCOF\b
        }
    *
    matrix CLIK = CLIK,EBAY
    matrix CLIK = CLIK,RCOF
    display _n in gr "RXrmaxl:  Listings of Three Minus-2-Log-Likelihood Ratios..."
    matrix list CLIK
    display _n in ye _dup(70) "-"
    display in gr "The Maximum Likelihood choices for MCAL=>Extent of Shrinkage are"
    display in gr "the ones that Minimize the CLIK, EBAY or RCOF criteria, above."
    display in ye _dup(70) "-" _n
    *
end

