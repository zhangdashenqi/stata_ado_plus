*! Confirmatory factor analysis with a single factor: v.2.2
*! Stas Kolenikov, skolenik-gmail-com

program define cfa1, eclass
  version 9.1

  if replay() {
     if ("`e(cmd)'" != "cfa1") error 301
     Replay `0'
  }

  else Estimate `0'
end

program Estimate `0', eclass

  syntax varlist(numeric min=3) [if] [in] [aw pw / ] ///
     , [unitvar FREE POSvar FROM(str) CONSTRaint(numlist) LEVel(int $S_level) ///
       ROBust VCE(string) CLUster(passthru) SVY SEArch(passthru) * ]
  * syntax: cfa1 <list of the effect indicators>
  * untivar is for the identification condition of the unit variance of the latent variable

  unab varlist : `varlist'
  tokenize `varlist'
  local q: word count `varlist'
  marksample touse
  preserve
  qui keep if `touse'
  * weights!
  global CFA1N = _N

/*
  * we'll estimate the means instead
  qui foreach x of varlist `varlist' {
     sum `x', meanonly
     replace `x' = `x'-r(mean)
     * deviations from the mean
  }
*/

  if "`weight'" != "" {
     local mywgt [`weight'=`exp']
  }

  if "`robust'`cluster'`svy'`weight'"~="" {
     local needed 1
  }
  else {
     local needed 0
  }

  Parse `varlist'  , `unitvar'
  local toml `r(toml)'
  if "`from'" == "" {
    local from `r(tostart)', copy
  }

  * identification
  constraint free
  global CFA1constr `r(free)'
  if "`unitvar'" ~= "" {
     * identification by unit variance
     constraint $CFA1constr [phi]_cons = 1
  }
  else if "`free'"=="" {
     * identification by the first variable
     constraint $CFA1constr [`1']_cons = 1
  }
  else {
     * identification imposed by user
     global CFA1constr
  }
  local nconstr : word count `constraint'

  global CFA1PV = ("`posvar'" != "")

  if "`posvar'" ~= "" {
     di as text _n "Fitting the model without restrictions on error variances..."
  }

  * variance estimation
  local vce = trim("`vce'")
  if "`vce'" == "boot" local vce bootstrap
  if "`vce'" == "sbentler" {
     global CFA1SBV = 1
     local vce
  }
  else {
    if index("robustoimopg","`vce'") {
       local vce vce(`vce')
    }
    else {
       di as err "`vce' estimation is not supported"
       if "`vce'" == "bootstrap" | "`vce'" == "boot" {
          di as err "try {help bootstrap} command directly"
       }
       exit 198
    }
  }

  tempname ilog1 ilog2
  Tryit ml model lf cfa1_lf `toml' `mywgt', constraint($CFA1constr `constraint') ///
      init (`from') maximize nooutput `options' `search' ///
      `svy' `cluster' `robust' `vce'
/*
  ml model lf cfa1_lf `toml' `mywgt', ///
      constraint($CFA1constr `constraint') `svy' `robust' `cluster' ///
      maximize
*  ml check
*  ml search, rep(5)
  ml init `from', copy
  cap noi ml maximize , `options'
*/
  mat `ilog1' = e(ilog)

  local nz = 0
  if $CFA1PV {
     * determine if refitting the model is needed
     tempname ll_unr
     scalar `ll_unr' = e(ll)
     forvalues i=1/`q' {
        if [``i''_v]_cons <0 {
           constraint free
           local ccc = `r(free)'
           const define `ccc' [``i''_v]_cons = 0
           local zerolist `zerolist' `ccc'
           local ++nz
        }
     }
     local zerolist = trim("`zerolist'")
     global CFA1constr $CFA1constr `zerolist'
     if "`zerolist'" ~= "" {
        di as text _n "Fitting the model with some error variances set to zero..."
        Tryit ml model lf cfa1_lf `toml' `mywgt' , constraint($CFA1constr `constraint') ///
            init (`from') maximize nooutput `options' `search' ///
            `svy' `robust' `cluster' `vce'
        mat `ilog2' = e(ilog)

     }

     * adjust degrees of freedom!
  }


  * we better have this before Satorra-Bentler
  if "`unitvar'" ~= "" {
    ereturn local normalized Latent Variance
  }
  else if "`free'"=="" {
    ereturn local normalized `1'
  }


  * work out Satorra-Bentler estimates
  if "$CFA1SBV"!="" {
     * repost Satorra-Bentler covariance matrix
     tempname SBVar SBV Delta Gamma
     cap SatorraBentler
     if _rc {
        di as err "Satorra-Bentler standard errors are not supported for this circumstance; revert to vce(oim)"
        global CFA1SBV
     }
     else {
       mat `SBVar' = r(SBVar)
       mat `Delta' = r(Delta)
       mat `Gamma' = r(Gamma)
       mat `SBV'   = r(SBV)
       ereturn repost V = `SBVar'
       ereturn matrix SBGamma = `Gamma', copy
       ereturn matrix SBDelta = `Delta', copy
       ereturn matrix SBV = `SBV', copy
       ereturn local vce SatorraBentler
     }
  }



  * get the covariance matrix and the number of observations!
  ***********************************************************
  tempname lambda vars phi S Sindep Sigma trind eb

  qui mat accum `S' = `varlist', dev nocons
  mat `S' = `S' / $CFA1N

  * implied matrix
  mat `eb' = e(b)
  mat `lambda' = `eb'[1,1..`q']
  mat `vars' = `eb'[1,`q'+1..2*`q']
  scalar `phi' = `eb'[1,3*`q'+1]
  mat `Sigma' = `lambda''*`phi'*`lambda' + diag(`vars')
  mat `Sindep' = diag(vecdiag(`S'))

  * test against independence
  mat `trind' = trace( syminv(`Sindep') * `S' )
  local trind = `trind'[1,1]
  ereturn scalar ll_indep = -0.5 * `q' * $CFA1N * ln(2*_pi) - 0.5 * $CFA1N * ln(det(`Sindep')) - 0.5 * $CFA1N * `trind'
  ereturn scalar lr_indep = 2*(e(ll)-e(ll_indep))
  ereturn scalar df_indep = `q'-`nz'-`nconstr'
  ereturn scalar p_indep  = chi2tail(e(df_indep),e(lr_indep))

  * goodness of fit test
  ereturn scalar ll_u = -0.5 * `q' * $CFA1N * ln(2*_pi) - 0.5 * $CFA1N * ln(det(`S')) - 0.5 * `q' * $CFA1N
  ereturn scalar lr_u = -2*(e(ll)-e(ll_u))
  ereturn scalar df_u = `q'*(`q'+1)*.5 - (2*`q' - `nz' - `nconstr')
  * wrong if there are any extra constraints in -constraint- command!!!
  ereturn scalar p_u  = chi2tail(e(df_u),e(lr_u))
  ereturn matrix ilog1 `ilog1'
  cap ereturn matrix ilog2 `ilog2'

  * Satorra-Bentler corrections
  if "$CFA1SBV"!="" {
     * compute the corrected tests, too
     * Satorra-Bentler 1994
     tempname U trUG2 Tdf
     mat `U' = `SBV' - `SBV'*`Delta'*syminv(`Delta''*`SBV'*`Delta')*`Delta''*`SBV'
     ereturn matrix SBU = `U'
     mat `U' = trace( e(SBU)*`Gamma' )
     ereturn scalar SBc = `U'[1,1]/e(df_u)
     ereturn scalar Tscaled = e(lr_u)/e(SBc)
     ereturn scalar p_Tscaled = chi2tail( e(df_u), e(Tscaled) )

     mat `trUG2' = trace( e(SBU)*`Gamma'*e(SBU)*`Gamma')
     ereturn scalar SBd = `U'[1,1]*`U'[1,1]/`trUG2'[1,1]
     ereturn scalar Tadj = ( e(SBd)/`U'[1,1]) * e(lr_u)
     ereturn scalar p_Tadj = chi2tail( e(SBd), e(Tadj) )

     * Yuan-Bentler 1997
     * weights!
     ereturn scalar T2 = e(lr_u)/(1+e(lr_u)/e(N) )
     ereturn scalar p_T2 = chi2tail( e(df_u), e(T2) )
  }

  if "`posvar'" ~= "" {
     ereturn scalar lr_zerov = 2*(`ll_unr' - e(ll))
     ereturn scalar df_zerov = `nz'
     local replay_opt posvar llu(`ll_unr')
  }
  ereturn local cmd cfa1

  Replay , `replay_opt' level(`level')
  Finish
  restore
  ereturn repost, esample(`touse')

end

program define Tryit

  cap noi `0'
  local rc=_rc
  if `rc' {
     Finish
     exit `rc'
  }

end

program define Finish

  * finishing off
  constraint drop $CFA1constr
  global CFA1S
  global CFA1N
  global CFA1PV
  global CFA1theta
  global CFA1arg
  global CFA1data
  global CFA1constr
  global CFA1vars
  global CFA1SBV

end

program define Replay

  syntax, [posvar llu(str) level(passthru)]

  di _n as text "Log likelihood = " as res e(ll) _col(59) as text "Number of obs = " as res e(N)
  di as text "{hline 13}{c TT}{hline 64}"
  di as text "             {c |}      Coef.   Std. Err.      z    P>|z|     [$S_level% Conf. Interval]"
  di as text "{hline 13}{c +}{hline 64}"

  tempname vce
  mat `vce' = e(V)
  local q = colsof(`vce')
  local q = (`q'-1)/3
  local a : colfullnames(`vce')
  tokenize `a'

  di as text "Lambda{col 14}{c |}"
  forvalues i = 1/`q' {
    gettoken v`i' : `i' , parse(":")
    _diparm `v`i'' , label("`v`i''") prob `level'
  }
  di as text "Var[error]{col 14}{c |}"
  forvalues i = 1/`q' {
    _diparm `v`i''_v , label("`v`i''") prob `level'
  }
  di as text "Means{col 14}{c |}"
  forvalues i = 1/`q' {
    _diparm `v`i''_m , label("`v`i''") prob `level'
  }
  di as text "Var[latent]{col 14}{c |}"
  _diparm phi , label("phi1") prob

  di as text "{hline 13}{c +}{hline 64}"
  di as text "R2{col 14}{c |}"
  forvalues i = 1/`q' {
    di as text %12s "`v`i''" "{col 14}{c |}{col 20}" ///
       as res %6.4f (_b[`v`i'':_cons]^2*_b[phi:_cons]) / ///
              (_b[`v`i'':_cons]^2*_b[phi:_cons] + _b[`v`i''_v:_cons])
  }


  di as text "{hline 13}{c BT}{hline 64}"

  if e(df_u)>0 {
     di as text _n "Goodness of fit test: LR = " as res %6.3f e(lr_u) ///
        as text _col(40) "; Prob[chi2(" as res %2.0f e(df_u) as text ") > LR] = " as res %6.4f e(p_u)
  }
  else {
     di as text "No degrees of freedom to perform the goodness of fit test"
  }
  di as text "Test vs independence: LR = " as res %6.3f e(lr_indep) ///
     as text _col(40) "; Prob[chi2(" as res %2.0f e(df_indep) as text ") > LR] = " as res %6.4f e(p_indep)

  if "`e(vce)'" == "SatorraBentler" & e(df_u)>0 {
     * need to report all those corrected statistics

     di as text _n "Satorra-Bentler Tbar" _col(26) "= " as res %6.3f e(Tscaled) ///
        as text _col(40) "; Prob[chi2(" as res %2.0f e(df_u) as text ") > Tbar] = " as res %6.4f e(p_Tscaled)

     di as text "Satorra-Bentler Tbarbar" _col(26) "= " as res %6.3f e(Tadj) ///
        as text _col(40) "; Prob[chi2(" as res %4.1f e(SBd) as text ") > Tbarbar] = " as res %6.4f e(p_Tadj)

     di as text "Yuan-Bentler T2" _col(26) "= " as res %6.3f e(T2) ///
        as text _col(40) "; Prob[chi2(" as res %2.0f e(df_u) as text ") > T2] = " as res %6.4f e(p_T2)
  }

  if "`posvar'" ~= "" {
     * just estimated?
     if "`llu'" == "" {
        di as err "cannot specify -posvar- option, need to refit the whole model"
     }
     else {
      if e(df_zerov)>0 {
        di as text "Likelihood ratio against negative variances: LR = " as res %6.3f e(lr_zerov)
        di as text "Conservative Prob[chi2(" as res %2.0f e(df_zerov) as text ") > LR] = " ///
           as res %6.4f chi2tail(e(df_zerov),e(lr_zerov))
      }
      else {
        di as text "All variances are non-negative, no need to test against zero variances"
      }
     }
  }

end

program define Parse , rclass
  * takes the list of variables and returns the appropriate ml model statement
  syntax varlist , [unitvar]

  global CFA1arg
  global CFA1theta
  global CFA1vars
  local q : word count `varlist'

  * lambdas
  forvalues i = 1/`q' {
     local toml `toml' (``i'': ``i'' = )
     local tostart `tostart' 1
     global CFA1arg $CFA1arg g_``i''
     global CFA1theta $CFA1theta l_`i'
     global CFA1vars $CFA1vars ``i''
  }

  * variances
  forvalues i = 1/`q' {
     local toml `toml' (``i''_v: )
     local tostart `tostart'  1
     global CFA1arg $CFA1arg g_``i''_v
     global CFA1theta $CFA1theta v_`i'
  }

  * means
  forvalues i = 1/`q' {
     local toml `toml' (``i''_m: )
     qui sum ``i'', mean
     local mean = r(mean)
     local tostart `tostart' `mean'
     global CFA1arg $CFA1arg g_``i''_m
     global CFA1theta $CFA1theta m_`i'
  }

  * variance of the factor
  local toml `toml' (phi: )
  local tostart `tostart' 1
  global CFA1arg $CFA1arg g_Phi
  global CFA1theta $CFA1theta phi

  * done!
  return local toml `toml'
  return local tostart `tostart'

end


**************************** Satorra-Bentler covariance matrix code

program SatorraBentler, rclass
   version 9.1
   syntax [, noisily]
   * assume the maximization completed, the results are in memory as -ereturn data-
   * we shall just return the resulting matrix

   if "`e(normalized)'" == "" {
      di as err "cannot compute Satorra-Bentler variance estimator with arbitrary identification... yet"
      exit 198
   }

   * assume sample is restricted to e(sample)
   * preserve
   * keep if e(sample)

   * get the variable names
   tempname VV bb
   mat `VV' = e(V)
   local q = rowsof(`VV')
   local p = (`q'-1)/3
   local eqlist : coleq `VV'
   tokenize `eqlist'
   forvalues k=1/`p' {
     local varlist `varlist' ``k''
   }

   * compute the implied covariance matrix
   tempname Lambda Theta phi Sigma
   mat `bb' = e(b)
   mat `Lambda' = `bb'[1,1..`p']
   mat `Theta' = `bb'[1,`p'+1..2*`p']
   scalar `phi' = `bb'[1,`q']
   mat `Sigma' = `Lambda''*`phi'*`Lambda' + diag(`Theta')

   * compute the empirical cov matrix
   tempname SampleCov
   qui mat accum `SampleCov' = `varlist' , nocons dev
   * weights!!!
   mat `SampleCov' = `SampleCov' / (r(N)-1)

   * compute the matrix Gamma
   `noisily' di as text "Computing the Gamma matrix of fourth moments..."
   tempname Gamma
   SBGamma `varlist'
   mat `Gamma' = r(Gamma)
   return add

   * compute the duplication matrix
   * Dupl `p'
   * let's call it from within SBV!

   * compute the V matrix
   `noisily' di as text "Computing the V matrix..."
   SBV `SampleCov' `noisily'
   tempname V
   mat `V' = r(SBV)
   return add

   * compute the Delta matrix
   `noisily' di as text "Computing the Delta matrix..."
   tempname Delta
   mata : SBDelta("`bb'","`Delta'")

   *** put the pieces together now

   tempname DeltaId

   * enact the constraints!
   SBconstr `bb'
   mat `DeltaId' = `Delta' * diag( r(Fixed) )

   * those should be in there, but it never hurts to fix!
   if "`e(normalized)'" == "Latent Variance" {
      * make the last column null
      mat `DeltaId' = ( `DeltaId'[1...,1...3*`p'] , J(rowsof(`Delta'), 1, 0)  )
   }
   else if "`e(normalized)'" ~= "" {
      * normalization by first variable
      local idvar `e(normalized)'
      if "`idvar'" ~= "`1'" {
         di as err "cannot figure out the identification variable"
         exit 198
      }
      mat `DeltaId' = ( J(rowsof(`Delta'), 1, 0) , `DeltaId'[1...,2...] )
   }
   local dcnames : colfullnames `bb'
   local drnames : rownames `Gamma'
   mat colnames `DeltaId' = `dcnames'
   mat rownames `DeltaId' = `drnames'
   return matrix Delta = `DeltaId', copy

   tempname VVV
   mat `VVV' = ( `DeltaId'' * `V' * `DeltaId' )
   mat `VVV' = syminv(`VVV')
   mat `VVV' = `VVV' * ( `DeltaId'' * `V' * `Gamma' * `V' * `DeltaId' ) * `VVV'

   * add the covariance matrix for the means, which is just Sigma/_N
   * weights!
   tempname CovM
   mat `CovM' = ( J(2*`p',colsof(`bb'),0) \ J(`p',2*`p',0) , `Sigma', J(`p',1,0) \ J(1, colsof(`bb'), 0) )

   mat `VVV' = (`VVV' + `CovM')/_N
   return matrix SBVar = `VVV'

end
* of satorrabentler

program define SBGamma, rclass
   syntax varlist
   unab varlist : `varlist'
   tokenize `varlist'

   local p: word count `varlist'

   forvalues k=1/`p' {
     * make up the deviations
     * weights!!!
     qui sum ``k'', meanonly
     tempvar d`k'
     qui g double `d`k'' = ``k'' - r(mean)
     local dlist `dlist' `d`k''
   }

   local pstar = `p'*(`p'+1)/2
   forvalues k=1/`pstar' {
      tempvar b`k'
      qui g double `b`k'' = .
      local blist `blist' `b`k''
   }


   * convert into vech (z_i-bar z)(z_i-bar z)'
   mata : SBvechZZtoB("`dlist'","`blist'")

   * blist now should contain the moments around the sample means
   * we need to get their covariance matrix

   tempname Gamma
   qui mat accum `Gamma' = `blist', dev nocons
   * weights!
   mat `Gamma' = `Gamma'/(_N-1)
   mata : Gamma = st_matrix( "`Gamma'" )

   * make nice row and column names
   forvalues i=1/`p' {
     forvalues j=`i'/`p' {
        local namelist `namelist' ``i''_X_``j''
     }
   }
   mat colnames `Gamma' = `namelist'
   mat rownames `Gamma' = `namelist'

   return matrix Gamma = `Gamma'

end
* of computing Gamma

program define SBV, rclass
   args A noisily
   tempname D Ainv V
   local p = rowsof(`A')
   `noisily' di as text "Computing the duplication matrix..."
   mata : Dupl(`p',"`D'")
   mat `Ainv' = syminv(`A')
   mat `V' = .5*`D''* (`Ainv' # `Ainv') * `D'
   return matrix SBV = `V'
end
* of computing V

   * need to figure out whether a constraint has the form parameter = value,
   * and to nullify the corresponding column
program define SBconstr, rclass
   args bb
   tempname Iq
   mat `Iq' = J(1,colsof(`bb'),1)
   tokenize $CFA1constr
   while "`1'" ~= "" {
     constraint get `1'
     local constr `r(contents)'
     gettoken param value  : constr, parse("=")
     * is the RHS indeed a number?
     local value = substr("`value'",2,.)
     confirm number `value'
     * parse the square brackets and turn them into colon
     * replace the opening brackets with nothing, and closing brackets, with :
     local param = subinstr("`param'","["," ",1)
     local param = subinstr("`param'","]",":",1)
     local param = trim("`param'")
     local coln = colnumb(`bb',"`param'" )
     mat `Iq'[1,`coln']=0

     mac shift
   }
   return matrix Fixed = `Iq'
end


cap mata : mata drop SBvechZZtoB()
cap mata : mata drop Dupl()
cap mata : mata drop SBDelta()

mata:
void SBvechZZtoB(string dlist, string blist) {
   // view the deviation variables
   st_view(data=.,.,tokens(dlist))
   // view the moment variables
   // blist=st_local("blist")
   st_view(moments=.,.,tokens(blist))
   // vectorize!
   for(i=1; i<=rows(data); i++) {
     B = data[i,.]'*data[i,.]
     moments[i,.] = vech(B)'
   }
}

void Dupl(scalar p, string Dname) {
   pstar = p*(p+1)/2
   Ipstar = I(pstar)
   D = J(p*p,0,.)
   for(k=1;k<=pstar;k++) {
      D = (D, vec(invvech(Ipstar[.,k])))
   }
   st_matrix(Dname,D)
}

void SBDelta(string bbname, string DeltaName) {
   bb = st_matrix(bbname)
   p = (cols(bb)-1)/3
   Lambda = bb[1,1..p]
   Theta = bb[1,p+1..2*p]
   phi = bb[1,cols(bb)]
   Delta = J(0,cols(bb),.)
   for(i=1;i<=p;i++) {
     for(j=i;j<=p;j++) {
       DeltaRow = J(1,cols(Delta),0)
       for(k=1;k<=p;k++) {
         // derivative wrt lambda_k
         DeltaRow[k] = (k==i)*Lambda[j]*phi + (j==k)*Lambda[i]*phi
         // derivative wrt sigma^2_k
         DeltaRow[p+k] = (i==k)*(j==k)
       }
       DeltaRow[cols(Delta)] = Lambda[i]*Lambda[j]
       Delta = Delta \ DeltaRow
     }
   }
   st_matrix(DeltaName,Delta)
}

end
* of mata piece

***************************** end of Satorra-Bentler covariance matrix code

exit

History:
   v.1.0 -- May 19, 2004: basic operation, method d0
   v.1.1 -- May 19, 2004: identification by -constraint-
                          common -cfa1_ll-
                          from()
   v.1.2 -- May 21, 2004: method -lf-, robust
                          constraint free
   v.1.3 -- unknown
   v.1.4 -- Feb 15, 2005: pweights, arbitrary constraints
   v.2.0 -- Feb 28, 2006: update to version 9 using Mata
   v.2.1 -- Apr 11, 2006: whatever
   v.2.2 -- Apr 13, 2006: Satorra-Bentler standard errors and test corrections
                          -vce- option
            Apr 14, 2006: degrees of freedom corrected for # constraints
            July 5, 2006: minor issue with -from(, copy)-
