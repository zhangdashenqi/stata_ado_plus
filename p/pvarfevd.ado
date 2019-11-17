/* pVARfevd v1.0 - 22 June 2016*/


cap program drop pvarfevd
program define pvarfevd, sortpreserve rclass // ----------------
   version 11.0
   #delimit ;
   syntax [, 
      STep(integer 10) 
	  IMPulse(varlist)
	  RESponse(varlist)
	  POrder(varlist)
	  MC(integer 0)
	  DOTs
	  SAVE(string)
	  NOTABLE
	  ] ;
   #delimit cr

   // Capture pvar arguments
   local maxlag = e(mlag)
   local vars   = e(depvar)
   local varsn  = wordcount(e(depvar))
   local N      = e(N) 
   
   
   // Assert impulse and response variable are in e(depvar)
   if "`impulse' `response'" != " " {
     foreach word in `impulse' `response' {
	   if regexm(" `vars' ", " `word' ") == 0 {
	     di as err "`word' not in e(depvar)"
		 exit 147
		} 
	  }
    }
   
   
   // Order
   if "`porder'" != "" {
     cap assert wordcount("`porder'") == wordcount("`vars'") 
       if _rc != 0 {
		 di as err "porder(varlist) does not match pvar varlist"
	     exit 198
	    }
		
		 else {
           local vars = "`porder'"
		  } 
	} 
	
   tempname shock 
	 mat `shock' = I(`varsn')
	   mat colname `shock' = `vars'
	   mat rowname `shock' = `vars'
	 

   // For IRF simulation
   * For AR(p) estimates simulation
   tempname b b_ P 
     mat `P' = cholesky(e(V))
   
   * For Cholesky decomposition simulation
   tempname C_ C E Pe L D Dp
     mat `C_' = e(Sigma)
     mat `C' = J(`varsn', `varsn', .)
	   mat colname `C' = `vars'
	   mat rowname `C' = `vars'
	 foreach imp in `vars' {
	   foreach res in `vars' {
	     mat `C'[rownumb(`C', "`imp'"), colnumb(`C', "`res'")] ///
		    = `C_'["`imp'", "`res'"]
        }
	  }
     mata: st_matrix("`L'", Lmatrix(`varsn'))
     mata: st_matrix("`D'", Dmatrix(`varsn'))
     mata: st_matrix("`Dp'", pinv(Dmatrix(`varsn')))
	 
	 mat `E'  = `L' * vec(`C')
	 mat `Pe' = cholesky((2/`N') * `Dp' * (`C'#`C') * `Dp'')
   
   // Simulation
   set more off 
     local iter = 0
	 
   while `iter' <= `mc' {
   
     if `iter' == 0 {
       mat `b' = e(b)
      }
	  
	   else {
         mat `b_' = J(1, colsof(e(b)), .)
		 
         local bbb = colsof(`b')
         forval xxx = 1/`bbb' {
           mat `b_'[1,`xxx'] = invnorm(uniform())
          }
		  
         mat `b' = e(b) + (`P' * `b_'')'
	    } 
	 
	 
   // Re-order AR(p) matrix
   forval p = 1/ `maxlag' {
     local coln
       foreach var in `vars' {
	     local coln "`coln' L`p'.`var'"
	    } 
		
	 tempname A`p'	
     mat `A`p'' = J(`varsn', `varsn', .)
       mat rowname `A`p'' = `vars'
       mat colname `A`p'' = `coln'
	   
     foreach vareq in `vars' {
       foreach varex in `vars' {
         mat `A`p''[rownumb(`A`p'',"`vareq'"), colnumb(`A`p'',"L`p'.`varex'")] ///
	       = `b'[1, "`vareq':L`p'.`varex'"]
	    } 
      }	
	  
    }
	
	
   // Estimate IRF	
   * IRF
   tempname irf0
     mat `irf0' = `shock'  
   forval iii = 1/`step' {
     tempname irf`iii' 
     mat `irf`iii'' = J(`varsn', `varsn', 0)
       forval jjj = 1/`maxlag' {
         if `iii' >= `jjj' {
	       local i_j = `iii' - `jjj'
	       tempname irf_`jjj'
	         mat `irf_`jjj'' = `irf`i_j'' * `A`jjj'' 
	         mat `irf`iii''  = `irf`iii'' + `irf_`jjj''
	      } 
        }
      }  
    
	
   * OIRF
   tempname Pc 
 
     if `iter' == 0 {
       mat `Pc' = cholesky(`C')
      }
      else {
		 cap drop mat `C'
	     tempname C_ C
		 
         mat `C_' = J(1, colsof(`Pe'), .)
         local ccc = colsof(`Pe')
         forval xxx = 1/`ccc' {
           mat `C_'[1,`xxx'] = invnorm(uniform())
          }
         mat `C_' = `D'*(`E' + (`Pe' * `C_''))
		 
		 local _s
		 local _t
		 forval xxx = 1/`varsn' {
		   local _s = `_t' + 1
		   local _t = `_s' + `varsn' - 1
		   
		   mat `C' = nullmat(`C'), `C_'[`_s'..`_t', 1]
		  } 
		  
		 mat rowname `C' = `vars'
		 mat colname `C' = `vars'
		 cap mat `Pc' = cholesky(`C') 
		   if _rc == 506 {
	         mat `Pc' = J(`varsn', `varsn', .)
		     local _errcount = `_errcount' + 1
	        }

      }
	  
	  
     forval iii = 0/`step' {
	   mat `irf`iii''  = `irf`iii''  * `Pc'
	  } 
	
	
   * Assemble IRF	
   local steps  
   tempname pirf addenda
     forval ttt = 0/`step' {
	   mat `addenda' = `ttt', `iter'
	     mat colname `addenda' = step iter
		 
       local steps = "`steps' `ttt' " 
         if `ttt' == 0 {
           mat colname `irf0' = `vars'
           mat rowname `irf0' = `vars'
	       mat `pirf' = `addenda', vec(`irf0')'
         }	
           else {
             mat `pirf' = `pirf' \ `addenda', vec(`irf`ttt'')'
	        }
      }
     mat rowname `pirf' = `steps'
	  
	  
   if `iter' == 0 {
     qui {
     tempfile error0 error1
	 preserve
	   clear
	   svmat `pirf', names(eqcol)
	   
	     save `error0', replace
	     save `error1', replace
	 restore	 
	  }
	}

	else {
	  qui {
	  preserve
	    clear
	    svmat `pirf', names(eqcol)
	      append using `error1'
	        save `error1', replace
	  restore	 
	   }
     }	 
	 
   // Dots 
   if "`dots'" != "" & `mc' > 0 {
     if _rc != 0 {
	  _dots `iter' 1
	 }
      else {
	  _dots `iter' 0
	 }
	} 
	 
   // Counter 
   local iter = `iter' + 1
   
    }
   set more on  

   
   // Display non-positive definite error covariance matrix error, if any
   if "`_errcount'" != "" {
     if ("`dots'" != "") & (mod(`mc',50) != 0) { 
	   di _n(1) as err "Warning: at least one simulated error covariance matrix not positive definite"
	  }
	  else {
       di as err "Warning: at least one simulated error covariance matrix not positive definite"
	  } 
	} 

   
   // Return output
   return local     porder "`vars'"
   return scalar    step  = `step'
   return scalar    iter  = `mc'
	
	
   // Assemble forecast-error variance decomposition
   preserve
   qui {
      use `error0', clear
        sort _step
	    foreach res in `vars' {
		  tempvar mse`res' 
		    gen `mse`res'' = 0
		  
	      foreach imp in `vars' {
	        bysort _iter (_step): replace `imp'`res' = sum(`imp'`res'^2) - (`imp'`res'^2)
		    replace `mse`res'' = `mse`res'' + `imp'`res' 
		   }	
	     } 
	    foreach res in `vars' {
	      foreach imp in `vars' {
	        replace `imp'`res' = `imp'`res' / `mse`res''
		   }	
	     } 
		cap drop __* 
      save `error0', replace
	  
      use `error1', clear
        sort _iter _step
	    foreach res in `vars' {
		  tempvar mse`res' 
		    gen `mse`res'' = 0
		  
	      foreach imp in `vars' {
	        bysort _iter (_step): replace `imp'`res' = sum(`imp'`res'^2) - (`imp'`res'^2)
		    replace `mse`res'' = `mse`res'' + `imp'`res' 
		   }	
	     } 
	    foreach res in `vars' {
	      foreach imp in `vars' {
	        replace `imp'`res' = `imp'`res' / `mse`res''
		   }	
	     } 
		cap drop __* 
      save `error1', replace
	  
     }
   
   
   // Tabulate FEVD
   * Identify impulse and response variables for tabulation
   if "`impulse'" == "" {
     local impulse `vars'
	} 
   if "`response'" == "" {
     local response `vars'
	} 

   * Compute standard error and 90% confidence band; Assemble FEVD for table
   foreach imp in `impulse' {
     foreach res in `response' {
	   local p5  "`p5'  p5`imp'`res' =`imp'`res' "
	   local p95 "`p95' p95`imp'`res'=`imp'`res' "
	   local se  "`se'  se`imp'`res'=`imp'`res' "
	  }
	 } 

   qui {
   use `error1', clear
	 collapse (sd) `se' (p5) `p5' (p95) `p95', by(_step)
	   merge 1:1 _step using `error0', nogen
	   
     foreach imp in `impulse' {
       foreach res in `response' {
	     ren `imp'`res'     fevd`imp'_`res' 
	     ren se`imp'`res'   se`imp'_`res' 
	     ren p5`imp'`res'   p5`imp'_`res' 
	     ren p95`imp'`res'  p95`imp'_`res' 
	    }
	  }	

	 reshape long fevd se p5 p95, i(_step) j(vars) string
	   recode se p5 p95 fevd (. = 0) if _step == 0
	 
	 gen impvar = .
	   label val impvar impvar
       foreach imp in `impulse' {
	     local i = `i' + 1
         foreach res in `response' {
		   replace impvar = `i' if vars == "`imp'_`res'"
		     label def impvar `i' "`imp'", modify
	      }
	    }	
	 gen resvar = .
	   label val resvar resvar 
       foreach res in `response' {
	     local j = `j' + 1
         foreach imp in `impulse' {
		   replace resvar = `j' if vars == "`imp'_`res'"
		     label def resvar `j' "`res'", modify
	      }
	    }	
	   
	 }

   * Save IRF file if requested
   label var _step  "Forecast horizon"
   label var resvar "Response variable"
   label var impvar "Impulse variable"
   label var fevd   "Forecast-error variance, share of total"
   label var se     "Forecast-error variance, share of total, standard error"
   label var p5     "Forecast-error variance, share of total, 5th percentile"
   label var p95    "Forecast-error variance, share of total, 95th percentile"
   if "`save'" != "" {
	 order _step resvar impvar fevd se p5 p95 
	 if `mc' > 1 {
       keep  _step resvar impvar fevd se p5 p95 
	   label data "Standard errors and confidence intervals are based on `mc' Monte Carlo simulations"
      }
	   else {
	     keep _step resvar impvar fevd
		} 
     qui save `save'
	} 
	
   * Tabulate FEVD
   if "`notable'" == "" {
     di _n(1) as txt "Forecast-error variance decomposition"
     tabdisp  _step impvar, cellvar(fevd) by(resvar)

	 if `mc' > 1 & "`save'" != "" {
	   tokenize "`save'", parse(",")
	   if regexm("`save'", ".dta") == 0 {
	     local 1 = "`1'.dta"
		}
		
	   di as txt "FEVD standard errors and confidence intervals based" ///
		 _n(1) "on `mc' Monte Carlo simulations are saved in file" /// 
		 _n(1) as res "`1'"
		 
	  }	 

	  
	 if `mc' > 1 & "`save'" == "" {
	   di as txt "FEVD standard errors and confidence intervals are " ///
		 _n(1) "not saved. Use option {bf:save}." 
		 
	  }	 
	  
    }
	
   	 
   restore
   
end //-------------------------------------------------------------
