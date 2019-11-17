*! Bollen-Stine bootstrap, v.1.3, Stas Kolenikov
program define bollenstine, eclass

  syntax, [Reps(int 200) SAVing(str) notable noheader nolegend ///
    SAFER CONFAOPTions(str) *]


  * this is a post-estimation command following confa1
  if "`e(cmd)'" ~= "confa1" & "`e(cmd)'" ~= "confa" error 301

  * the low level preserve
  preserve
  tempfile pres
  tempname confares
  est store `confares'
  qui save `pres'

  qui keep if e(sample)
  local T = e(lr_u)

  local safer cap noi

  if "`saving'" == "" {
     tempfile bsres
     local saving `bsres'
  }

  if "`e(cmd)'" == "confa1" {

     local varlist = "`e(depvar)'"
     local p : word count `varlist'

     tempname Sigma bb
     mat `Sigma' = e(Model)
     mat `bb' = e(b)

     mata: CONFA1_BSrotate("`Sigma'","`varlist'")

      `safer' bootstrap _b (T: T = e(lr_u)) (reject: reject = (e(lr_u) > `T') ) , ///
           reps(`reps') saving(`saving') notable noheader nolegend ///
           reject( e(converged) == 0) `options' ///
        : confa1 `varlist' , from(`bb', skip) `confaoptions'
     * may need some other options, too!
     nobreak if "`safer'"~="" & _rc {
        * for whatever reason, the bootstrap broke down
        qui use `pres' , clear
        qui est restore `confares'
        qui est drop `confares'
        error _rc
     }
     * just to display the results
     * the covariance matrix should have been reposted by the -bootstrap-!

     * we still need to trick Stata back into confa1!
     ereturn local cmd confa1

  }

  else if "`e(cmd)'" == "confa" {

      local varlist = "`e(observed)'"
      local p : word count `varlist'

      tempname Sigma bb
      mat `Sigma' = e(Sigma)
      mat `bb' = e(b)

      mata: CONFA1_BSrotate("`Sigma'","`varlist'")

      * set up the call
      local k = 1
      while "`e(factor`k')'" ~= "" {
         local call `call' (`e(factor`k')')
         local ++k
      }

      * the first call and resetting the from vector
      cap confa `call' , from(`bb') `confaoptions'
      if _rc {
         di as err "cannot execute confa with rotated data only"
         restore
         qui est restore `confares'
         cap est drop `confares'
         exit 309
      }
      mat `bb' = e(b)
      if ~strpos("`confaoptions'", "from")  local from from(`bb')

      * correlated errors?
      * unit variance identification?

       `safer' bootstrap _b (T: T = e(lr_u)) (reject: reject = (e(lr_u) > `T') ) , ///
            reps(`reps') saving(`saving') notable noheader nolegend ///
            reject( e(converged) == 0) `options' ///
         : confa `call' , `from' `confaoptions'
      * may need some other options, too!
      nobreak if "`safer'"~="" & _rc {
         * for whatever reason, the bootstrap broke down
         qui use `pres' , clear
         qui est restore `confares'
         cap est drop `confares'
         error _rc
      }
      * the covariance matrix should have been reposted by the -bootstrap-!

      * we still need to trick Stata back into confa!
      ereturn local cmd confa
  }

  else {
      * what on earth was that?
      error 301
  }


  * the bootstrap test on T
  gettoken bsres blah : saving , parse(",")
  * to strip off replace option, if there is any
  qui use `bsres', clear
  sum reject_reject, mean

  local pBS = r(mean)
  local BBS = r(N)

  qui sum T_T, det
  local q05 = r(p5)
  local q95 = r(p95)

  qui use `pres', clear
  qui est restore `confares'
  qui est drop `confares'

  ereturn scalar p_u_BS = `pBS'
  ereturn scalar B_BS = `BBS'
*  ereturn scalar lr_u = `T'
*  ereturn scalar p_u = chi2tail(e(df_u),e(lr_u))

  ereturn scalar T_BS_05 = `q05'
  ereturn scalar T_BS_95 = `q95'
  ereturn local vce BollenStine
  ereturn local vcetype Bollen-Stine

  `e(cmd)'

end

cap mata: mata drop CONFA1_BSrotate()
mata:
void CONFA1_BSrotate(
       string SigmaName, // the parameter matrix name
       string varnames // the variable names
       ) {

   // declarations
   real matrix data  // views of the data
   real matrix Sigma, SS, S2, SS2  // the covariance matrices and temp matrices
   real matrix means // the means -- need modifications for weighted data!!!
   real scalar p, n // dimension, no. obs

   // get the data in
   st_view(data=., ., tokens(varnames) )
   n=rows(data)
   p=cols(data)

   Sigma = st_matrix(SigmaName)

   // probability weights!!!
   means = colsum(data)/n
   SS = (cross(data,data)-n*means'*means)/(n-1)

   S2 = cholesky(Sigma)
   SS2 = cholesky(SS)
   SS2 = solveupper(SS2',I(rows(SS)))

   data[,] = data*SS2*S2'

}

end


exit

History:
v.1.1  -- Jan 9, 2007
v.1.2  -- Mar 26, 2008: confa1 options added; reject() added
v.1.3  -- July 12, 2008: upgraded to confa
