/* pVARsoc  v1.0 - 22 June 2016*/


capture program drop pvarsoc
program define pvarsoc, sortpreserve rclass //----------------------------
   version 11.0
   #delimit ;
   syntax varlist(min=2 numeric) [if] [in] [, 
      Maxlag(integer 4)
	  EXOG(varlist ts fv)
	  PINSTLag(numlist)
	  PVAROpts(string)
	  ] ;
   #delimit cr

   
   
   // check -xtset-
   cap xtset
     if _rc == 0 {
	   local timevar  = r(timevar)
	   local panelvar = r(panelvar)
	  }
     else {
	   xtset
	  } 
   
   
   
   // check -varlist-
   cap su `varlist' `exog'
     if _rc != 0 {
	   su `varlist' `exog' `if' `in'
	  } 
	

	
   // Run pvar on specified lags and moment conditions
   di as txt "Running panel VAR lag order selection on estimation sample"
   
   local m = wordcount("`varlist'")
   
   foreach var in `varlist' {
     qui su `var', meanonly
     tempvar tss`var' 
	   qui gen double `tss`var'' = (`var' - r(mean))^2
	}   
   
   forval lll = 1/`maxlag' {
	 local j = `maxlag' + 1 - `lll'
	 	 
	 if `j' == `maxlag' {
	   
       local instr
	   if "`pinstlag'" != "" {
	     foreach mmm in `pinstlag' {
		   local m`mmm' = `j'+`mmm'
	       local instr `instr' `m`mmm''
	      }
		 local inst instlag(`instr')
		} 
			   
         qui {
		   pvar `varlist' `if' `in', lags(`j') exog(`exog') `inst' `pvaropts' 
		   tempvar psample
		     gen `psample' = e(sample)
		   tempname detS detE
		     mat `detS' = det(e(Sigma))
		     corr `varlist' if `psample', cov
			 mat `detE' = det(r(C))
			 
		   cap assert chi2tail(`e(J_df)', `e(J)') != .	 
		   if _rc == 0 {
             mat stats = 1-`detS'[1,1]/`detE'[1,1], ///
		       e(J), chi2tail(e(J_df), e(J)), e(J) - e(J_df)*ln(e(N)), ///
	           e(J) - 2*e(J_df), e(J) - 2*e(J_df)*ln(ln(e(N))) 
			}
		   else {
             mat stats = 1-`detS'[1,1]/`detE'[1,1], ., ., ., ., . 
            }
			
		   }
		
		
	  } 

	  
	   else {
	   
       local instr
	   if "`pinstlag'" != "" {
	     foreach mmm in `pinstlag' {
		   local m`mmm' = `j'+`mmm'
	       local instr `instr' `m`mmm''
	      }
		 local inst instlag(`instr')
		} 
			   
         qui {
		   pvar `varlist' if `psample' == 1, lags(`j') `inst' `pvaropts' 
		   tempname detS detE
		     mat `detS' = det(e(Sigma))
		     corr `varlist', cov
			 mat `detE' = det(r(C))
			 
		   cap assert chi2tail(`e(J_df)', `e(J)') != .	 
		   if _rc == 0 {
             mat stats = 1-`detS'[1,1]/`detE'[1,1], ///
		       e(J), chi2tail(e(J_df), e(J)), e(J) - e(J_df)*ln(e(N)), ///
	           e(J) - 2*e(J_df), e(J) - 2*e(J_df)*ln(ln(e(N)))         ///
			   \ stats
			}   
		   else {
             mat stats = 1-`detS'[1,1]/`detE'[1,1], ., ., ., ., . \ stats
            }
			
		   }
		   
         }
		 
		 
	  local rows `rows' `lll'	
	    _dots `lll' 0
	 }
	 
   
	 
   // Format table
   mat colname stats = CD J "J pvalue" MBIC MAIC MQIC 
   mat rowname stats = `rows'
   di _n(2) as txt "{col 2}Selection order criteria"
     di as txt "{col 2}Sample:  " as res e(tmin) " - " e(tmax) ///
	    as txt "{col 52}No. of obs{col 68}= " as res %9.0f e(N)
     di as txt "{col 52}No. of panels{col 68}= " as res %9.0f e(n)
     di as txt "{col 52}Ave. no. of T{col 68}= " as res %9.3f e(tbar)
   matlist stats, twidth(5) border(rows all) rowtitle(lag) left(2) ///
     aligncolnames(center) 
   
   // return   
   return scalar maxlag = `maxlag' 
   return scalar tmin   = e(tmin)
   return scalar tmax   = e(tmax)
   return scalar tbar   = e(tbar)
   return scalar n      = e(n)
   return scalar N      = e(N)
   
   return local  exog   = trim(itrim("`exog'"))
   return local  endog  = trim(itrim("`varlist'"))
   
   return matrix stats  = stats
   
   ereturn clear
   
end //-------------------------------------------------------------


** v1.1 2015/08/12 set J-statistic-based measures to "." if just-identified
** v1.0 2015/07/04 first submission
