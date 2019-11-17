
capture program drop stthreg
program stthreg,properties(ml_score or svyb svyj svyr swml)
  version 9.0
  if `"`0'"'=="" {
    if (`"`e(cmd)'"'!="stthreg") error 301
    Replay `0'

  }
  else Estimate `0'
          
end





capture program drop Estimate
program Estimate, eclass sortpreserve
  version 9.0


   st_is 2 analysis

   syntax [if] [in]                 ///
              ,     ///
              [lny0(varlist)]                 ///
              [Mu(varlist)]                 ///specify covariates for mu
	      [noCONStant noLOg]                  /// -ml model- options
              [init(string)]                ///
	      [Level(cilevel)]                   ///
              [DEbug]                                  ///
              [*  ]                               /// -mlopts- options






   if("`debug'"==""){  
     *di "not debug"
   }
   else{
     di as result "debug mode"
   }

   local studytime "_t"


   
   global time_combination "#ML_y1"


	 if("`debug'"!=""){
			di "test:`test'"
		  di "equation:`equation' "
	 }   
   
   
   global time_combination = subinstr(subinstr("$time_combination","%","\`",.),"#","\$",.)
   if("`debug'"!=""){
    macro list time_combination
   }




	  marksample touse
	  mlopts mlopts, `options'
	  local cns `s(constraints)'



	  if "`mu'"!="" {
			  local varlist_mu `mu'
	  }
	  if "`lny0'"!="" {
			  local varlist_lny0 `lny0'
	  }
	  if "`studytime'"!="" {
			  local studytime `studytime'
	  }
          local failure _d

	  if "`init'"!="" {
			  local init_command `init'
	  } 	 
 

  




	  st_show `show'

      if("`debug'"!=""){
	  `qui' di as txt _n "Fitting full model:"
	  }
	

 

          ml model lf stthreg_lf (lny0: `studytime' `failure' `time_names' = `varlist_lny0',`constant') ///
                               (mu: `varlist_mu', `constant')                  ///
			    if `touse',                     ///
			   maximize                     ///
			   init(`init_command') waldtest(-2) `mlopts' `log' 
			   
			   ml query 

          
          
	  ereturn local title "Threshold Regression Estimates"
	  
	  ereturn local cmd stthreg

          ereturn local stthreg_para "`0'"
	  Replay , level(`level') 
	  

if("`debug'"!=""){	  
mat li e(b)
}




end


capture program drop Replay
program Replay

      syntax [, Level(cilevel)]
      ml display, level(`level')
end


