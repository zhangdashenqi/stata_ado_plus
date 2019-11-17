*! xtscc, version 1.1.4, Daniel Hoechle, 27feb2007
*
* This program largely is a translation of Driscoll and Kraay's procedure for GAUSS.
* Differences between Driscoll and Kraay's GAUSS-program and -xtscc-:
*
* 1) -xtscc- is able to handle missing values and unbalanced panels. 
* 2) -xtscc- can estimate fixed effects (within) regression models.
* 3) -xtscc- can estimate pooled OLS models with analytic weights 
*    (i.e. pooled WLS models).
* 4) -xtscc- does not offer the opportunity to estimate two stage least squares (2SLS)
*    regression models as does Driscoll and Kraay's original GAUSS program.
*
*
* Syntax:
* =======
*
*   xtscc depvar [indepvar] [if] [in] [aweight=exp] [, FE POOLed LAG(nlags) Level(cilevel)]
*   xtscc is byable.
*   Weighted estimation does not work with option FE.
*
* Notes:
* ======
*
* (1) The dataset has to be tsset.
* (2) The procedure uses functions from Ben Jann's -moremata- package.
*
* ==============================================================
* Daniel Hoechle, 27. February 2007
* ==============================================================
  capture program drop xtscc
  capture mata: mata drop driscoll()
  capture mata: mata drop distinct()
  capture mata: mata drop _mm_panels()
  capture mata: mata drop _mm_colrunsum()
  capture mata: mata drop mm_colrunsum() 
  capture mata: mata drop mm_npanels()


program define xtscc , eclass sortpreserve byable(recall) prop(sw)
  version 9.2

  if !replay() {
      tempname b V
      tempvar cons TransVar2
      ereturn clear
      syntax varlist(numeric) [if] [in] [aweight/] [, LAG(integer 9999) Level(cilevel) FE POOLed]
      marksample touse
      
      * Check if the dataset is tsset:
        qui tsset
        local panelvar "`r(panelvar)'"
        local timevar  "`r(timevar)'"

        local lag = abs(`lag')
        gen double `cons'=1    // constant

      * Split varlist into dependent and independent variables:
        tokenize `varlist'
        local lhsvar "`1'"
        macro shift 1
        local rhsvars "`*'"

      * Estimate the consistent covariance matrix as described in Driscoll and Kraay (1998):
        if "`fe'"=="" {
          if "`weight'"==""   gen double `TransVar2' = 1          // perform pooled OLS
          else                gen double `TransVar2' = `exp'      // perform pooled WLS
          * WLS-transform:
          qui foreach var of local varlist {
              tempvar w`var'
              local tname "`w`var''"
              gen double `w`var'' = sqrt(`TransVar2') * `var' if `touse'
              if "`var'"=="`lhsvar'"    local lvar "`tname'"
              else                      local rvar "`rvar' `tname'"
          }
          qui replace `cons' = sqrt(`TransVar2') * `cons'
          }
        else {
          if "`weight'"!=""  {
            di as err "weights are not allowed with option fe"
            exit 101
          }
          * Within-transformation of the data (improved version as proposed by Bill Gould and David Drukker):
            sort `panelvar' `timevar'
            tempname TotMean
            tempvar  tmp ti
            by `panelvar': gen double `ti' = sum(`touse')
            qui by `panelvar': replace `ti' = `ti'[_N]
            qui foreach var of local varlist {
                tempvar w`var'
                local tname "`w`var''"
                by `panelvar': gen double `tmp' = sum(cond(`touse', `var', 0))
                by `panelvar': replace `tmp' = `tmp'[_N]/`ti' if `touse'
                sum `var' if `touse', meanonly
                scalar `TotMean' = r(mean)
                gen double `w`var'' = `var' - `tmp' + `TotMean' if `touse'
                if "`var'"=="`lhsvar'"    local lvar "`tname'"
                else                      local rvar "`rvar' `tname'"
                drop `tmp'
            }
        }
      
      * Before we produce the Driscoll-Kraay standard errors, we estimate a simple
      * OLS regression and save the R-squared and the rmse as they do not change with the 
      * method of obtaining the standard error:
        qui reg `lvar' `rvar' if `touse'
        scalar r2_xtscc = e(r2)
        scalar rmse_xtscc = e(rmse)
        ereturn clear
      
      * Sort the dataset for use in mata:
        sort `timevar' `panelvar'
      * Perform the estimation:
        mata: driscoll("`lvar'", "`rvar' `cons'", "`touse'", "`panelvar'", "`timevar'", `lag')

      * Next, we have to attach row and column names to the produced matrices:
        foreach Vector in "Beta" "se_beta" "t_beta" {
                matrix rownames `Vector' = `rhsvars' _cons
                matrix colnames `Vector' = y1
                }
        matrix rownames VCV = `rhsvars' _cons
        matrix colnames VCV = `rhsvars' _cons

      * Then we prepare the matrices for upload into e() ...
        matrix `b' = Beta'
        matrix `V' = VCV
        matrix se_beta = se_beta'
        matrix t_beta = t_beta'

      * ... post the results in e():
        ereturn post `b' `V', esample(`touse') depname("`lhsvar'")
        ereturn scalar N = nObs
        ereturn scalar N_g = nGroups
        ereturn scalar df_m = nVars - 1
        ereturn scalar df_r = nGroups - 1

        qui if "`rhsvars'"!=""  test `rhsvars', min   // Perform the F-Test
        ereturn scalar F = r(F)

        * Post the R-squared and the RMSE from the ordinary OLS-regression:
          if "`fe'"=="" ereturn scalar r2 = r2_xtscc
          else          ereturn scalar r2_w = r2_xtscc
          
          if "`fe'"=="" ereturn scalar rmse = rmse_xtscc

        ereturn scalar lag = lag_f
        ereturn matrix se_beta = se_beta
        ereturn matrix t = t_beta
        ereturn local groupvar "`panelvar'"
        ereturn local title "Regression with Driscoll-Kraay standard errors"
        ereturn local vcetype "Drisc/Kraay"
        ereturn local depvar "`lhsvar'"
        if "`fe'"=="" ereturn local method "Pooled OLS"
        else          ereturn local method "Fixed-effects regression"
        ereturn local predict "xtscc_p"
        ereturn local cmd "xtscc"
  }
  else {      // Replay of the estimation results
        if "`e(cmd)'"!="xtscc" error 301
        syntax [, Level(cilevel)]
  }
  
  * Display the results
        if "`e(method)'"!="Fixed-effects regression" {
            local R2text "R-squared         =    "
            local R2ret "e(r2)"
            local RMSE1 "_col(50) in green"
            local RMSE2 "Root MSE          =  "
            local RMSE3 "in yellow %8.4f e(rmse) _n"
        }
        else {
            local R2text "within R-squared  =    "
            local R2ret "e(r2_w)"
        }
              
      * Header
        #delimit ;
        disp _n
          in green `"`e(title)'"'
          _col(50) in green `"Number of obs     ="' in yellow %10.0f e(N) _n
          in green `"Method: "' in yellow "`e(method)'"
          _col(50) in green `"Number of groups  ="' in yellow %10.0f e(N_g) _n
          in green `"Group variable (i): "' in yellow abbrev(`"`e(groupvar)'"',16)
          _col(50) in green `"F("' in yellow %3.0f e(df_m) in green `","' in yellow %6.0f e(df_r)
          in green `")"' _col(68) `"="' in yellow %10.2f e(F) _n
          in green `"maximum lag: "' in yellow e(lag)   
          _col(50) in green `"Prob > F          =    "' 
          in yellow %6.4f fprob(e(df_m),e(df_r),e(F)) _n 
          _col(50) in green `"`R2text'"' in yellow %5.4f `R2ret' _n
          `RMSE1' `"`RMSE2'"' `RMSE3'
          ;
        #delimit cr
        
      * Estimation results
        ereturn display, level(`level')
        disp ""
        
end



* ==============================================================
* This function performs the Driscoll and Kraay analysis
* ==============================================================
mata void driscoll(string scalar depvar,            ///
                   string scalar indepvar,          ///
                   string scalar touse,             ///
                   string scalar panvar,            ///
                   string scalar tvar,              ///
                   real scalar lag)
{
        // Declarations:
           real matrix    y, X, Panelmat
           real scalar    nObs, nVars
           real matrix    beta, resid, vcv, se_beta, t_beta
           real scalar    t, j, T
           real matrix    Nt, h, Omegaj, Shat
           
        
        // Build views to the data:
           pragma unset y
           st_view(y, ., depvar, touse)
           st_view(X=., ., tokens(indepvar), touse)
           st_view(Panelmat=., .,(tvar, panvar), touse)
           
        // Get the number of panels per time unit and the number of time periods:
           Nt = _mm_panels(Panelmat[.,1])
           T  = rows(Nt)
           if (lag==9999)   lag = floor(4*(T/100)^(2/9))    
           
        // Determine the start row of each time period (note that there is one row more
        // in t_start than in T. However, this is row required for the loops below to 
        // work!):
           t_start = (1 \ (mm_colrunsum(Nt):+1) )
           
        // Extract the total number of observations and the number of right hand side
        // variables (including the intercept):
           nVars = cols(X)
           nObs = rows(X)
           nGroups = distinct(Panelmat[.,2])
        
        // Obtain the OLS estimator beta and the estimated residuals resid:
           beta = invsym(cross(X,X))*cross(X,y)
           resid = y - X*beta
 
        // Next, we form the TxnVars matrix h. The rows of matrix h are 1xnVars vectors
        // of cross-sectional averages of the moment conditions evaluated at
        // beta, ht(beta).
           h = J(T,nVars,.)
           for (t=1; t<=T; t++) {
                h[t,.] = (cross(X[(t_start[t]..(t_start[t+1]-1)),.],                    ///
                                      resid[(t_start[t]..(t_start[t+1]-1))]))'
           }
        // Next, Shat is constructed.
           Shat =  cross(h,h):/((nObs:^2):/T)    // Up to now: Shat = Omega0.
           for (j=1; j<=lag; j++) {
                Omegaj = cross(h[((j+1)..T),.],h[(1..(T-j)),.]):/((nObs:^2):/T)
                Shat = Shat + (1 - j/(lag+1)) * (Omegaj + Omegaj')
           }

        // Computation of the panel robust covariance matrix:
           // vcv = invsym(cross(X,X):/nObs)*Shat*invsym(cross(X,X):/nObs):/T
           vcv = invsym(cross(X,X))*Shat*invsym(cross(X,X)):*((nObs:^2):/T)
        
        // Compute additional statistics:
           se_beta =  (diagonal(vcv)):^0.5
           t_beta  =  beta :/ se_beta
        
        // Return the results to the xtscc.ado program
           st_numscalar("nVars", nVars)
           st_numscalar("nObs", nObs)
           st_numscalar("nGroups",nGroups)
           st_numscalar("lag_f", lag)
           st_matrix("Beta", beta)
           st_matrix("VCV", vcv)
           st_matrix("se_beta", se_beta)
           st_matrix("t_beta", t_beta)

}


* ==============================================================
* This function returns the number of distinct values in a vector.
* Note that -distinct- is slow because Stata's -select- function does not yet exist.
* ==============================================================
mata real scalar distinct(real vector x)
{
    real vector    y1, y2
    
    y1 = sort(x,1)
    y2 = _mm_panels(y1)
    return(rows(y2))
}


* ==============================================================
* These functions are taken from Ben Jann's -moremata- package.
* ==============================================================

mata real colvector _mm_panels(transmorphic vector X, | real scalar np)
{
        real scalar i, j, n
        real colvector res

        if (args()<2) np = mm_npanels(X)
        if (length(X)==0) return(J(0,1,.))
        res = J(np, 1, .)
        n = j = 1
        for (i=2; i<=length(X); i++) {
                if (X[i]!=X[i-1]) {
                        res[j++] = n
                        n = 1
                }
                else n++
        }
        res[j] = n
        return(res)
}

mata numeric matrix mm_colrunsum(numeric matrix A)
{
        numeric matrix B

        if (isfleeting(A)) {
                _mm_colrunsum(A)
                return(A)
        }
        _mm_colrunsum(B=A)
        return(B)
}

mata void _mm_colrunsum(numeric matrix Z)
{
        real scalar i

        _editmissing(Z, 0)
        for (i=2; i<=rows(Z); i++) Z[i,] = Z[i-1,] + Z[i,]
}

mata real scalar mm_npanels(vector X)
{
        real scalar i, np

        if (length(X)==0) return(0)
        np = 1
        for (i=2; i<=length(X); i++) {
                if (X[i]!=X[i-1]) np++
        }
        return(np)
}
