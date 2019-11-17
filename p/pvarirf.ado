/* pVARirf  v1.0 - 22 June 2016*/


cap program drop pvarirf
program define pvarirf, sortpreserve rclass // ----------------
   version 11.0
   #delimit ;
   syntax [, 
      STep(integer 10) 
	  IMPulse(varlist)
	  RESponse(varlist)
	  POrder(varlist)
	  OIRF
	  DM
	  CUMulative
	  MC(integer 0)
	  TABle 
	  Level(cilevel)
	  DOTS
	  SAVE(string)
	  BYOPtion(string)
	  NODRAW
	  * 
	  ] ;
   #delimit cr

   // Capture pvar arguments
   local maxlag = e(mlag)
   local vars   = e(depvar)
   local varsn  = wordcount(e(depvar))
   local N      = e(N) 
   
   
   // Pass arguments if dynamic multiplier
   if "`dm'" == "dm" {
     pvarirf_dm `*'
	 
	 return local     porder  "."
     return scalar    step  = `step'
     return scalar    iter  = `mc'
	 exit
	} 
   
   // Assert impulse and response variable are in e(depvar)
   if "`impulse' `response'" != " " {
     foreach word in `impulse' `response' {
	   if regexm(" `vars' ", " `word' ") == 0 {
	     di as err "`word' not in e(depvar)"
		 exit 147
		} 
	  }
    }
   
   
   // Assert iterations > 1 with option level
   if "`level'" != "`c(level)'" & `mc' < 2 {
     di as err "{bf:level} can only be specified with {bf:mc}(#)>1"
	 exit 198
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
   if `mc' > 0 {
     mat `P' = cholesky(e(V))
    }
   
   * For Cholesky decomposition simulation
   if "`oirf'" == "oirf" {
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
    }
   
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
   if "`oirf'" == "oirf" {
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
   if "`oirf'" != "" {
     return local     porder  "`vars'"
    }
   else {
     return local     porder  .
	} 
   return scalar    step  = `step'
   return scalar    iter  = `mc'
	
	
   // Cumulative IRF
   preserve
   if "`cumulative'" != "" {
   qui {
      use `error0', clear
        sort _step
	    foreach imp in `vars' {
	      foreach res in `vars' {
	        replace `imp'`res' = sum(`imp'`res')
		   }	
	     } 
      save `error0', replace
	  
      use `error1', clear
        sort _iter _step
	    foreach imp in `vars' {
	      foreach res in `vars' {
	        by _iter: replace `imp'`res' = sum(`imp'`res')
		   }	
	     } 
      save `error1', replace
	  
     }
   }
   
   
   // Graph IRF
   * Identify impulse and response variables for graphing
   if "`impulse'" == "" {
     local impulse `vars'
	} 
   if "`response'" == "" {
     local response `vars'
	} 

   * Compute Gaussian approximation confidence band; Assemble IRF for graph	
   foreach imp in `impulse' {
     foreach res in `response' {
	   local se  "`se'  se`imp'`res' =`imp'`res' "
	  }
	 } 

   qui {
   use `error1', clear
	 collapse (sd) `se', by(_step)
	   merge 1:1 _step using `error0', nogen
	   
     foreach imp in `impulse' {
       foreach res in `response' {
	     ren `imp'`res'     irf`imp'_`res' 
	     ren se`imp'`res'   se`imp'_`res' 
	    }
	  }	
	 
	 reshape long irf se, i(_step) j(vars) string
	 
	 gen impres = .
	   label val impres impres
	 local i = `varsn'^2 + 1 
     foreach res in `response' {
       foreach imp in `impulse' {
	     local i = `i' - 1
		 replace impres = `i' if vars == "`imp'_`res'"
		   label def impres `i' "`imp' : `res'", modify
	    }
	  }	

	gen ul = irf + invnormal(1 - (1 - `level'/100)/2)*se  
	gen ll = irf - invnormal(1 - (1 - `level'/100)/2)*se  
	 }

   * Save IRF file if requested
   if "`save'" != "" {
	 order _step impres irf ll ul
	 label var _step  "Forecast horizon"
	 label var impres "Impulse : Response"
	 label var irf    "Impulse-response, mean"
	 label var se     "Impulse-response, standard error"
	 label var ll     "Impulse-response, `level'% CI, lower bound"
	 label var ul     "Impulse-response, `level'% CI, upper bound"
	 if `mc' > 1 {
       keep  _step impres irf se ll ul
	   label data "Confidence intervals are based on `mc' Monte Carlo simulations"
      }
	   else {
	     keep _step impres irf
		} 
     save `save'
	} 
   	 
   * Draw IRF
   if "`nodraw'" == "" {	 
	 if "`cumulative'" != "" {
	   local cu "Cumulative "
	  }
	 if "`oirf'" != "" {
       local oi "Orthogonalized "
	  } 
	 
     if `mc' == 0 {
         graph twoway ///
	      (line  irf _step, lcolor(dknavy)) ///
		      , by(impres, colfirst note("impulse : response") iscale(*0.8) `byoption') ///
		      xtitle("step") ///
			  ytitle("`cu'`oi'IRF") ylabel(, angle(horizontal)) ///
			  `options'
      }
	   else {
         graph twoway ///
	      (rarea ul ll _step, color(gs10)) ///
	      (line  irf _step, lcolor(dknavy)) ///
		      , by(impres, colfirst note("impulse : response") iscale(*0.8) `byoption') ///
		      xtitle("step") ylabel(, angle(horizontal)) ///
			  legend(order(1 "`level'% CI" 2 "`cu'`oi'IRF"))  ///
			  `options'
	    }		  
    }
	
   
   
   // Tabulate IRF
   if "`table'" != "" {
	 label var _step  "Forecast horizon"
     qui gen impvar = ""
       label var impvar "Impulse variable"
	 qui gen resvar = ""
       label var resvar "Response variable"
	 local i = `varsn'^2 + 1 
     foreach res in `response' {
       foreach imp in `impulse' {
	     local i = `i' - 1
		   qui replace impvar = "`imp'" if impres == `i' 
		   qui replace resvar = "`res'" if impres == `i' 
	    }
	  }	
     di _n(1) as txt "`cu'`oi'IRF"
     tabdisp  _step impvar, cellvar(irf) by(resvar)
     }

   restore
   
end //-------------------------------------------------------------
