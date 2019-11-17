/* pVAR v1.0 - 22 June 2016*/


capture program drop pvar
program define pvar, sortpreserve eclass // --------------------
   version 11.0
   #delimit ;
   syntax varlist(min=2 numeric) [if] [in] [, 
      LAgs(integer 1) 
	  EXog(varlist ts)
	  FOD 
	  FD
	  TD
	  INSTLags(string)
	  GMMStyle 
	  GMMOpts(string)
      VCE(string)
	  OVERID
	  Level(cilevel)
	  NOPrint
	  ] ;
   #delimit cr

   
   // marksample
   marksample touse 

   
   // check -xtset-
   cap xtset
     if _rc == 0 {
	   local timevar  = r(timevar)
	   local panelvar = r(panelvar)
	   local tdelta   = r(tdelta)
	   
	   if ("`panelvar'" == ".") |  ("`timevar'" == ".") {
	     di as err "panel variable not set; use {bf:xtset} {it:varname} ..."
	     exit 459
	     }
	  }
	  
     else {
	   xtset
	  } 
   
   
   
   // check -varlist-
   cap su `varlist' `exog'
     if _rc != 0 {
	   su `varlist' `exog' `if' `in'
	  } 
	
	
   // check -instlags-
   if "`instlags'" != "" {
     cap numlist "`instlags'"
	 if _rc != 0 {
	   di as err "invalid numlist; {bf:instlags()} incorrectly specified."
	   exit 121
	  }
 	}  


	
   // check -gmmstyle-
   if "`gmmstyle'" != "" {
     if "`instlags'" == "" {
       di as err "{bf:gmmstyle} may only be specified with {bf:instlags()}"
	   exit 198
	  }
	}  

	
   // copy -varlist- -lags- ; -exog- 
   foreach var in `varlist' {
	 
	 tempvar y`var'
	   qui gen double `y`var'' = `var' 
		 
	 local yvar `yvar' `y`var''
	 
     forval t = 1/`lags' {
	   tempvar yl`t'`var'
	     qui gen double `yl`t'`var'' = L`t'.`var' 
		 
	   local ylvar `ylvar' `yl`t'`var''
	  }

	} 
	
   foreach var in `exog' {
	 
	 local var_ = regexr("`var'", "\.", "_")
	 tempvar x`var_'
	   qui gen double `x`var_'' = `var' 
		 
	 local xvar `xvar' `x`var_''
	} 
	
	
	
   // remove cross-sectional mean
   if "`td'" == "td" {
   
	 foreach var in `yvar' `ylvar' `xvar' {
	   tempvar tm`var'
	     qui bysort `timevar': egen double `tm`var'' = mean(`var') 
		 
	   qui replace `var' = `var' - `tm`var'' 
      }
	  
	} 
   
   
   
   // assert fd or fod
   if ("`fd'" == "fd") & ("`fod'" == "fod") error 198 

   
   
   // first difference
   if ("`fd'" == "fd") {
     qui xtset `panelvar' `timevar', delta(`tdelta')
   
	 foreach var in `yvar' {
	   tempvar y`var'
	     qui gen double `y`var'' = d.`var' 
		 
	   local yyvar `yyvar' `y`var''	 
	  }

	 foreach var in `ylvar' {
	   tempvar yl`var'
	     qui gen double `yl`var'' = d.`var' 
		 
	   local yylvar `yylvar' `yl`var''	 
	  }

	 foreach var in `xvar' {
	   tempvar x`var'
	     qui gen double `x`var'' = d.`var' 
		 
	   local xxvar `xxvar' `x`var''	 
	  }
	  
	} 
   

   
   // forward orthogonal deviation (default)
   if ("`fod'" == "fod") | (("`fd'" == "") & ("`fod'" == "")) {
     qui {

	   gsort `panelvar' -`timevar'     
	   
	   qui reg `yvar' `ylvar' `xvar'
	   tempvar one n w
	     gen `one' = e(sample)
		 by `panelvar' : gen double `n'   = sum(`one') - 1 
		   replace `n' = . if `n' <= 0
		 gen double `w'   = sqrt(`n' / (`n' + 1))
	   
	   foreach var in `yvar' {
	     tempvar sum fom y`var'
 	       by `panelvar' : gen double `sum' = sum(`var') - `var' if `one' == 1
		   gen double `fom' = `sum' / `n'
		   gen double `y`var'' = `w' * (`var' - `fom') 
		   
	     local yyvar `yyvar' `y`var''	 
	    }
		
	   foreach var in `ylvar' {
	     tempvar sum fom yl`var'
 	       by `panelvar' : gen double `sum' = sum(`var') - `var' if `one' == 1
		   gen double `fom' = `sum' / `n'
		   gen double `yl`var'' = `w' * (`var' - `fom') 
		   
	     local yylvar `yylvar' `yl`var''	 
	    }
		
	   foreach var in `xvar' {
	     tempvar sum fom x`var'
 	       by `panelvar' : gen double `sum' = sum(`var') - `var' if `one' == 1
		   gen double `fom' = `sum' / `n'
		   gen double `x`var'' = `w' * (`var' - `fom')
		   
	     local xxvar `xxvar' `x`var''	 
	    }
		
       xtset `panelvar' `timevar', delta(`tdelta')
	  }
    }

	

   // format system GMM equations
   local sgmm 
   foreach var in `varlist' {
	 local sgmm `sgmm' (`var' : `y`y`var''' - {`var': `yylvar' `xxvar'}) 
	}


	
   // set first derivatives
   local derivs
   foreach var in `varlist' {
	 local derivs `derivs' deriv(`var'/`var' = -1)
	}

	
	
   // set instruments
   tempvar odata
	 qui gen byte `odata' = 1
	 
   if "`gmmstyle'" != "" {
	 qui {
	 
	 numlist "`instlags'"
	 local l0 = 0
	 foreach l in `r(numlist)' {
	   if `l' > `l0' {
	     local lmax = `l'
		}
		 local l0 = `l'
	  }
	  
	 xtset
	 preserve
	   clear
	   local newN = r(tmax) - r(tmin) + 1 + `lmax'
	   set obs `newN'
	     gen `r(timevar)' = r(tmin) + ((_n - 1)*`tdelta') - `lmax'
		 gen `r(panelvar)' = r(imax) + 100
		 tempvar temp
		   gen `temp' = 1
	     tempfile gmmvars
	       save `gmmvars', replace
	 restore  
	 
	 append using `gmmvars'
	 
	 xtset
     cap tsfill, full
	   if _rc == 451 {
	     drop if `temp' == 1
	     di as error "timevar (`timevar') may not contain missing values when option {bf: gmmstyle} is specified"
		 exit 451  
	    }
	   drop if `temp' == 1
	   recode `yvar'  (. = 0) 

	  } 
    }
	
   if "`instlags'" != "" {
     local instr l(`instlags').(`yvar') `exog'
	 local instrll "`instlags'"
	}
	
	else {
	
	  if "`fd'" == "fd" {
	    local fdmin = `lags' + 1
	    local fdmax = `fdmin' + `lags' - 1
        local instr l(`fdmin'/`fdmax').(`yvar') `exog'
		local instrll "`fdmin'/`fdmax'"
	   }
	
	  else {
        local instr l(1/`lags').(`yvar') `exog'
		local instrll "1/`lags'"
	   }
	 }

	 

   // set vce
   if "`vce'" == "" {
     local vce unadjusted
	}


	 
   // estimate system GMM equations
   if ("`gmmopts'" == "") {
       qui gmm `sgmm' if `touse', /// 
	      inst(`varlist' : `instr', nocons) `derivs' ///
		  winitial(identity) wmatrix(robust) twostep vce(`vce') 
      }
	  
	 else {
       qui gmm `sgmm' if `touse', nolog /// 
	      inst(`varlist' : `instr', nocons) `derivs' `gmmopts'
      }	 
	  
   qui keep if `odata' == 1
   tempvar touse_f
     mark `touse_f' if e(sample)
	 
	 
   // format and print output table, capture ereturn
   local name 
   foreach eqn in `varlist' {
   
     foreach var in `varlist' {
       forval t = 1/`lags' {
	     local name `name' `eqn':L`t'.`var'
		}
	  }
	 
	 if "`exog'" != "" {
       foreach var_ in `exog' {
	     local name `name' `eqn':`var_'
	    }
	  }	
	
	}  
   
   mat b = e(b)
     mat coleq b = `name' 
   mat V = e(V)
     mat coleq V = `name' 
	 mat roweq V = `name' 

 
   foreach e in N_clust Q J J_df rank ic converged clustvar {
     local _`e' = e(`e')
	} 
	
	
   foreach e in init W {
     tempname `e'_
       mat ``e'_' = e(`e')
       cap mat coleq ``e'_' = `name'	 
	} 
       cap mat roweq `W_' = `name'	 

	   
   qui xtsum `timevar' if e(sample)
     foreach e in N n Tbar min max {
       local _`e' = r(`e')
	  } 
	  
   
   
   if "`noprint'" == "" {
   
     di _n(1) as txt "Panel vector autoregresssion"
	   di as txt _n(3) "GMM Estimation"
	   di as txt _n(1) "Final GMM Criterion Q(b) = " as res %9.3g e(Q)
	   di as txt "Initial weight matrix:{col 24}" as res proper(e(winit))
	   di as txt "GMM weight matrix:{col 24}" as res proper(e(wmatrix))
       di as txt "{col 52}No. of obs{col 68}= " as res %9.0f e(N)
       di as txt "{col 52}No. of panels{col 68}= " as res %9.0f r(n)
       di as txt "{col 52}Ave. no. of T{col 68}= " as res %9.3f r(Tbar)
     di _n(1)
   
     eret post b V, esample(`touse_f') obs(`_N')
       eret dis, level(`level')
	   di as txt "Instruments : " as res "l(`instrll').(`varlist') `exog'"
	}
	 else {
       qui eret post b V, esample(`touse_f') obs(`_N')
	  }
   
	
   // error covariance matrix
   preserve
   local _e 
   foreach var in `varlist' {
     tempvar _ue`var' _u`var' _e`var'
	 qui {
	 
	   if "`td'" != "" {
	     tempvar tm`var'
	       bysort `timevar': egen double `tm`var'' = mean(`var') 
		 replace `var' = `var' - `tm`var''
		} 
	
       xtset	
	     predict `_ue`var'' if e(sample), eq(`var') xb
	     replace `_ue`var'' = `var' - `_ue`var''  
	   bysort `panelvar': egen `_u`var'' = mean(`_ue`var'') if e(sample) 
	   gen `_e`var'' = `_ue`var'' - `_u`var''
	  } 
	 local _e `_e' `_e`var''
	}   
   qui corr `_e' if e(sample), cov	
     tempname Sigma
     mat `Sigma' = r(C)
	   mat rowname `Sigma' = `varlist'
	   mat colname `Sigma' = `varlist'
   restore  
   
   pvarclear	 

	 
   // ereturn
   eret scalar n           = `_n'
   eret scalar tmin        = `_min'
   eret scalar tmax        = `_max'
   eret scalar tbar        = `_Tbar'
   eret scalar mlag        = `lags'
   eret scalar N_clust     = `_N_clust'
   eret scalar Q           = `_Q'
   eret scalar J           = `_J'
   eret scalar J_df        = `_J_df'
   eret scalar J_pval      = chi2tail(`_J_df', `_J') 
   eret scalar rank        = `_rank'
   eret scalar ic          = `_ic'
   eret scalar converged   = `_converged'

   eret local panelvar     = "`panelvar'"
   eret local timevar      = "`timevar'"
   eret local eqnames      = "`varlist'"
   eret local instr        = "(`instrll').(`varlist') `exog'"	 
   eret local clustvar     = "`_clustvar'"
   eret local exog         = "`exog'"
   eret local depvar       = "`varlist'"
   eret local cmdline      = "pvar `*'"
   eret local cmd          = "pvar"
   
   eret matrix Sigma       = `Sigma'
   eret matrix W           = `W_'
   eret matrix init        = `init_'
    
   
   // print over-identification test, if called
   if "`overid'" == "overid" {
     di _n(2)
     di as txt "Test of overidentifying restriction: "
     di as txt "  Hansen's J chi2(" as res e(J_df) as txt ") = " ///
	    as res e(J) as txt " (p = " ///
		as res %5.3f 1 - chi2(e(J_df), e(J)) ///
		as txt ")" 
	}  

end 


capture program drop pvarclear
program pvarclear, rclass
    return clear
end


** v1.1 2015/08/12 corrected FOD transformation in response to Tom Doan's comment
** v1.0 2015/07/04 first submission
