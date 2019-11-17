*! version 1.1 -- 28oct05, 3oct01
program define daoneway, eclass
  version 7.0
  syntax varlist [if] [in] , by(varname numeric) [ Gen(string) ]
  marksample touse
  markout `touse' `by' 
  tempvar grp
  egen `grp' = group(`by') `if' `in', label
   
  /* quietly tabulate `by' if `touse' */
  quietly tabulate `grp' if `touse'
  
  tempname bign t3 t4 t5 eigen wlambda chisqr cancorr
  
  local k = r(r)
  scalar `bign' = r(N)
  local p : word count `varlist'
  local q = `k' - 1
  scalar `t3' = min(`p', `q')
  scalar `t4' = (abs(`p'-`q') - 1)/2
  scalar `t5' = (`bign' -`p' - `q' - 2)/2
  local t6 = `bign' - `p' - 1
  
  mat matw = J(`p', `p', 0)
  
  /* get sscp matrices */
  local i = 1
  while `i' <= `k' {
    quietly mat acc mats = `varlist' if `grp'==`i' & `touse' , dev nocon
    mat matw = matw + mats
    local i = `i' + 1
  }
  quietly mat acc matt = `varlist' if `touse', dev nocon means(cons)
  
  mat matb = matt - matw
  mat matc = matw/(`bign'-`k')

  
  /* Cholesky decomposition */
  mat matl = cholesky(matw)         
  mat matu = matl'
  mat mata = inv(matl) * matb * inv(matu)  /* mata is symmetric */
  mat symeigen evec eval = mata            /* eval - eigenvalues of W-1B */
  mat evec = inv(matu)*evec                /* evec - eigenvectors of W-1B */
  
  local trim = `t3'
  mat eval = eval[1,1..`trim']
  mat evec = evec[1...,1..`trim']
  local fname ""
  forv i=1/`trim' { local fname = "`fname'" + "func`i' "  }
  local rname ""
  forv i=1/`k' { local rname = "`rname'" + "`by'-`i' " }
  
  mat diagw = diag(vecdiag(matw))
  mat diagc = diag(vecdiag(evec'*matc*evec))
  forv i=1/`p' { mat diagw[`i',`i']=sqrt(diagw[`i',`i']) }
  forv i=1/`trim' {mat diagc[`i',`i']=sqrt(diagc[`i',`i']) }
  mat stcoef  = diagw*evec
  mat rawcoef = evec*syminv(diagc)
  mat cons = -1*cons*rawcoef

 
  
  mat temp1 = evec'*matw*evec
  mat temp2 = diag(vecdiag(temp1))
  forv i=1/`trim' { mat temp2[`i',`i']=sqrt(temp2[`i',`i']) }
  mat temp2 = syminv(temp2)
  mat strmat = syminv(diagw)*matw*evec*temp2
  mat colnames stcoef = `fname'
  mat colnames strmat = `fname'
  mat colnames rawcoef = `fname'
  mat rawcoef = rawcoef \ cons
  local vname : rownames(rawcoef)
  mat means = J(`k',`p'+1,1)
  forv i=1/`k' {
    quietly mat accum temp1 = `varlist' if `grp'==`i', dev nocon means(cons)
    mat means[`i',1] = cons
  }
  mat means = means*rawcoef
  mat rownames means = `rname'
  
  /* debugging code remember to remove 
  mat list matw
  mat list matb
  mat list matu
  mat list matl
  mat list mata
  mat list eval
  mat list evec
  end of debugging code */
  
  display
  display as txt "                    One-way Discriminant Function Analysis"
  display
  display as txt "Observations = " as res `bign'
  display as txt "Variables    = " as res `p'
  display as txt "Groups       = " as res `k'
  display
  display as txt "                 Pct of   Cum  Canonical  After  Wilks'"
  display as txt " Fcn Eigenvalue Variance  Pct     Corr      Fcn  Lambda  Chi-square  df  P-value"
  scalar `wlambda' = 1
  local   toteig   = 0
  
  forv i=1/`trim' {
    scalar `wlambda' = `wlambda' * 1/(1 + el(eval,1,`i'))
    local toteig = `toteig' + el(eval,1,`i') 
  }

  scalar `chisqr' = -(`bign'-1-(`p'+`k')/2)*log(`wlambda')
  local chidf = `p'*`q'
  local pvalue = chi2tail(`chidf',`chisqr')

  
  display as res "                                         |   0 " /*
  */ %8.5f `wlambda' %10.3f `chisqr' %6.0f `chidf' %9.4f `pvalue'
  
  local fcn = 1
  local cumpct = 0
  local p1 = `p'-1
  local q1 = `q'-1
  while `p1'~=0 & `q1'~=0 {
    scalar `eigen' = eval[1,`fcn']
    local pctvar = 100*`eigen'/`toteig'
    local cumpct = `cumpct' + `pctvar'
    scalar `cancorr' = sqrt(`eigen'/(1+`eigen'))
    local start = `fcn'+1
    scalar `wlambda' = 1
    forv i=`start'/`trim' { scalar `wlambda' = `wlambda' * 1/(1 + el(eval,1,`i')) }
    scalar `chisqr' = -(`bign'-1-(`p'+`k')/2)*log(`wlambda')
    local chidf = `p1'*`q1'
    local pvalue = chi2tail(`chidf',`chisqr')
    display as res %4.0f `fcn' %10.4f `eigen' /*
    */  %8.2f `pctvar' %7.2f `cumpct' %10.4f `cancorr' "  |" %4.0f `fcn' /*
    */ %9.5f `wlambda' %10.3f `chisqr' %6.0f `chidf' %9.4f `pvalue'
    local p1 = `p1'-1
    local q1 = `q1'-1
    local fcn = `fcn'+1
   }
   scalar `eigen' = eval[1,`fcn']
   local pctvar = 100*`eigen'/`toteig'
   local cumpct = `cumpct' + `pctvar'
   scalar `cancorr' = sqrt(`eigen'/(1+`eigen'))
   display as res %4.0f `fcn' %10.4f `eigen' /*
   */  %8.2f `pctvar' %7.2f `cumpct' %10.4f `cancorr' "  |" 
  

  display
  display as txt "Unstandardized canonical discriminant function coefficients"
  mat list rawcoef, noheader format(%12.4f)
  display
  display as txt "Standardized canonical discriminant function coefficients"
  mat list stcoef, noheader format(%12.4f)
  display
  display as txt "Canonical discriminant structure matrix"
  mat list strmat, noheader format(%12.4f)
  display
  display as txt "Group means on canonical discriminant functions"
  mat list means, noheader format(%12.4f)

  /* funny stuff goes here */
  if `"`gen'"' ~= "" {
    mat matb = rawcoef[1...,1]
    mat b = matb'
    mat V = I(`p'+1)
    mat rownames V = `vname'
    mat colnames b = `vname'
    mat colnames V = `vname'
    estimates post b V
    _predict double `gen'1 ,xb
    forv i=2/`trim' {
      mat matb = rawcoef[1...,`i']
      mat b = matb'
      mat colnames b = `vname'
      estimates repost b=b
      _predict double `gen'`i', xb
    } 
  }
  estimates clear
  est local depvar "`varlist'"
  est local group "`by'"
  est local cmd "daoneway"
  est scalar N = `bign'
  mat drop matw matt mats matb matu matl mata eval evec stcoef rawcoef
  mat drop temp1 temp2 strmat diagw diagc matc cons means
 end 
