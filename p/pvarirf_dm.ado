/* pVARirf_dm  v1.0 - 22 June 2016*/


cap program drop pvarirf_dm
program define pvarirf_dm, sortpreserve rclass // ----------------
   version 11.0
   #delimit ;
   syntax [, 
      DM
      STep(integer 10) 
	  IMPulse(varlist)
	  RESponse(varlist)
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
   local exog   = e(exog)
   local N      = e(N) 
   
   // Assert exogenous variable
   if "`e(exog)'" == "" {
     di as err "exogenous variables not found"
	 exit 198
    }
   
   
   // Assert impulse and response variable are in e(exog) and e(depvar)
   if "`impulse' `response'" != " " {
     foreach word in `impulse' {
	   if regexm("`e(exog)'", "`word'") == 0 {
	     di as err "`word' not in e(exog)"
		 exit 147
		} 
	  }
	  
     foreach word in `response' {
	   if regexm(" `vars' ", " `word' ") == 0 {
	     di as err "`word' not in e(depvar)"
		 exit 147
		} 
	  }
    }
   
   
   // Parse exogenous variables
   local maxl  = 0
   local elist
   foreach word in `exog' {
     if regexm("`word'", "\.") {
	 
	   tokenize "`word'", pars("\.")
	   
	   if !regexm("`elist'", "`3'") {
	     local elist `elist' `3'
	    }
		
	   if regexm("`1'", "^[L]([0-9]*)") {
	     if regexs(1)=="" {
	       if `maxl' < 1 {
	         local maxl = 1
	        }
		  }	
         else {		 
	       local new = regexs(1)
	       if `maxl' < `new' {
	         local maxl = regexs(1)
	        } 
		  } 
		  
	    }
		
	  }
	  
	  
     if !regexm("`word'", "\.") {
	   if !regexm("`elist'", "`word'") {
	     local elist `elist' `word'
	    }
	  }
	  
    }

   local exogn = wordcount("`elist'")

   
   
   // Assert iterations > 1 with option level
   if "`level'" != "`c(level)'" & `mc' < 2 {
     di as err "{bf:level} can only be specified with {bf:mc}(#)>1"
	 exit 198
    } 
   
   
   // For DM simulation
   * For AR(p) estimates simulation
   tempname b b_ P 
   if `mc' > 0 {
     mat `P' = cholesky(e(V))
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
	
	
   // Re-order exogenous variables 
   forval s = 0/ `maxl' {
     local ecoln
       foreach var in `elist' {
	     local ecoln "`ecoln' L`s'.`var'"
	    } 
		
	 tempname B`s'	
     mat `B`s'' = J(`varsn', `exogn', 0)
       mat rowname `B`s'' = `vars'
       mat colname `B`s'' = `elist'

     foreach vareq in `vars' {
       foreach varex in `elist' {
         capture ///
		 mat `B`s''[rownumb(`B`s'',"`vareq'"), colnumb(`B`s'',"L`s'.`varex'")] ///
	       = `b'[1, "`vareq':L`s'.`varex'"]
	    } 
      }	
    }
   
   // Estimate Dynamic Multipliers  // <<<< ongoing-----------------------------
   * Generate Matrices
   tempname M
     forval p = 1/`maxlag' {
       mat `M' = nullmat(`M'), `A`p''
	  } 
  	 if `maxlag' > 1 {
	   mat `M' = `M' \ I(`varsn'*(`maxlag'-1)), J(`varsn'*(`maxlag'-1), `varsn', 0)
	  } 
	  
   tempname A_x B_h I_t N_t
     mat `A_x' = `M'
     if `maxl' > 0 {	 
	   forval s = 1/`maxl' {
	     mat `B_h' = nullmat(`B_h'), `B`s''
		}
	   if `maxlag' > 1 {
	     mat `B_h' = `B_h' \ J(`varsn'*(`maxlag'-1), `exogn'*`maxl', 0)
	    }
		
	   if `maxl' == 1 {
	     mat `I_t' = J(`exogn', `exogn', 0)
		} 
	   if `maxl' >  1 {
	     mat `I_t' = J(`exogn', `exogn'*`maxl', 0) ///
		    \ I(`exogn'*(`maxl'-1)), J(`exogn'*(`maxl'-1), `exogn', 0)
		} 
	   
	   mat `N_t' = J(`exogn'*`maxl', `varsn'*`maxlag', 0)
	   mat `A_x' = `M', `B_h' \ `N_t', `I_t'
      }	

   tempname J_x 
     if `varsn'*(`maxlag' - 1) + `exogn'*`maxl' > 0 {
	   mat `J_x' = I(`varsn'), J(`varsn', `varsn'*(`maxlag' - 1) + `exogn'*`maxl', 0)
	  } 

   tempname B_xp I_c
     mat `B_xp' = `B0''
	 if `maxlag' > 1 {
	   mat `B_xp' = `B_xp', J(`exogn', `varsn'*(`maxlag'-1), 0) 
	  } 
	 if `maxl' == 1 {
	   mat `B_xp' = `B_xp', I(`exogn')
	  } 
	 if `maxl' >  1 {
	   mat `B_xp' = `B_xp', I(`exogn'), J(`exogn', `exogn'*(`maxl'-1), 0)
	  } 
	  
   tempname A_xiii	 
   forval iii = 0/`step' {
   
     if `iii' == 0 {
	   mat `A_xiii' = I(rowsof(`A_x'))
	  } 
     if `iii' == 1 {
	   mat `A_xiii' = `A_x'
	  } 
	 if `iii' >  1 {
	   mat `A_xiii' = `A_xiii' * `A_x'
	  }
	 
	 tempname dm`iii'
       mat `dm`iii'' = `A_xiii' * `B_xp''
       if `varsn'*(`maxlag' - 1) + `exogn'*`maxl' > 0 {
	     mat `dm`iii'' = `J_x' * `dm`iii''
	    } 
	   mat colname `dm`iii'' = `elist' 
	   mat rowname `dm`iii'' = `vars'
    }  
    
   * Assemble Dynamic Multipliers
   local steps  
   tempname dm addenda
     forval ttt = 0/`step' {
	   mat `addenda' = `ttt', `iter'
	     mat colname `addenda' = step iter
	
       local steps = "`steps' `ttt' " 
	   mat `dm' = nullmat(`dm') \ `addenda', vec(`dm`ttt'')'
      }
     mat rowname `dm' = `steps'
	  
	  
   if `iter' == 0 {
     qui {
     tempfile error0 error1
	 preserve
	   clear
	   mat list `dm'
	   svmat `dm', names(eqcol)
	   
	     save `error0', replace
	     save `error1', replace
	 restore	 
	  }
	}

	else {
	  qui {
	  preserve
	    clear
	    svmat `dm', names(eqcol)
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

   
   
   // Cumulative DM
   preserve
   if "`cumulative'" != "" {
   qui {
      use `error0', clear
        sort _step
	    foreach imp in `elist' {
	      foreach res in `vars' {
	        replace `imp'`res' = sum(`imp'`res')
		   }	
	     } 
      save `error0', replace
	  
      use `error1', clear
        sort _iter _step
	    foreach imp in `elist' {
	      foreach res in `vars' {
	        by _iter: replace `imp'`res' = sum(`imp'`res')
		   }	
	     } 
      save `error1', replace
	  
     }
   }
   
   
   // Graph DM
   * Identify impulse and response variables for graphing
   if "`impulse'" == "" {
     local impulse `elist'
	} 
   if "`response'" == "" {
     local response `vars'
	} 

   * Compute Gaussian approximation confidence band; Assemble DM for graph	
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
	     ren `imp'`res'     dm`imp'_`res' 
	     ren se`imp'`res'   se`imp'_`res' 
	    }
	  }	
	 
	 reshape long dm se, i(_step) j(vars) string
	 
	 gen impres = .
	   label val impres impres
	 local i = `varsn'*`exogn' + 1 
     foreach res in `response' {
       foreach imp in `impulse' {
	     local i = `i' - 1
		 replace impres = `i' if vars == "`imp'_`res'"
		   label def impres `i' "`imp' : `res'", modify
	    }
	  }	

	gen ul = dm + invnormal(1 - (1 - `level'/100)/2)*se  
	gen ll = dm - invnormal(1 - (1 - `level'/100)/2)*se  
	 }

   * Save DM file if requested
   if "`save'" != "" {
	 order _step impres dm ll ul
	 label var _step  "Forecast horizon"
	 label var impres "Impulse : Response"
	 label var dm     "Impulse-response, mean"
	 label var se     "Impulse-response, standard error"
	 label var ll     "Impulse-response, `level'% CI, lower bound"
	 label var ul     "Impulse-response, `level'% CI, upper bound"
	 if `mc' > 1 {
       keep  _step impres dm se ll ul
	   label data "Confidence intervals are based on `mc' Monte Carlo simulations"
      }
	   else {
	     keep _step impres dm
		} 
     save `save'
	} 
   	 
   * Draw DM
   if "`nodraw'" == "" {	 
	 if "`cumulative'" != "" {
	   local cu "Cumulative "
	  }
	 
     if `mc' == 0 {
         graph twoway ///
	      (line  dm _step, lcolor(dknavy)) ///
		      , by(impres, colfirst note("impulse : response") iscale(*0.8) `byoption') ///
		      xtitle("step") ///
			  ytitle("`cu'Dynamic Multipliers") ylabel(, angle(horizontal)) ///
			  `options'
      }
	   else {
         graph twoway ///
	      (rarea ul ll _step, color(gs10)) ///
	      (line  dm _step, lcolor(dknavy)) ///
		      , by(impres, colfirst note("impulse : response") iscale(*0.8) `byoption') ///
		      xtitle("step") ylabel(, angle(horizontal)) ///
			  legend(order(1 "`level'% CI" 2 "`cu'Dynamic Multipliers"))  ///
			  `options'
	    }		  
    }
	
   
   
   // Tabulate Dynamic Multiplier
   if "`table'" != "" {
	 label var _step  "Forecast horizon"
     qui gen impvar = ""
       label var impvar "Exogenous variable"
	 qui gen resvar = ""
       label var resvar "Response variable"
	 local i = `varsn'*`exogn' + 1 
     foreach res in `response' {
       foreach imp in `impulse' {
	     local i = `i' - 1
		   qui replace impvar = "`imp'" if impres == `i' 
		   qui replace resvar = "`res'" if impres == `i' 
	    }
	  }	
     di _n(1) as txt "`cu'Dynamic Multipliers"
     tabdisp  _step impvar, cellvar(dm) by(resvar)
     }

   restore
   
end //-------------------------------------------------------------
