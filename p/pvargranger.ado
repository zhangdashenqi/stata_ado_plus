/* pvargranger  v1.0 -  22 June 2016*/


capture program drop pvargranger
program define pvargranger, sortpreserve rclass
   version 11.0
   syntax [, ESTimates(string)] 

   
   // load estimates
   if "`estimates'" != "" {
     qui {
		tempname ppp
		  estimates store `ppp'
		estimates restore `estimates'    
	  }
	}  

	
   // check e(cmd)	
   if "`e(cmd)'" != "pvar" {
     di as err "pvargranger only works with estimates from {help pvar}"
	 exit 198
	}
	
   
   // capture pvar arguments
   local maxlag = e(mlag)
   local vars   = e(depvar)
   local varsn  = wordcount(e(depvar))
   
   
   // Granger causality Wald test
   foreach res in `vars' {

   
     foreach imp in `vars' {
	 
	   if "`imp'" != "`res'" {
	     forval lll = 1/`maxlag' {
           local `res'_`imp' ``res'_`imp'' _b[`res':L`lll'.`imp']=
		  }
         local `res'_ ``res'_' ``res'_`imp''
	     
	     qui test ``res'_`imp''  0
		 
		 local name `name' `res':`imp'
		 if "`i'" == "" {
		   tempname granger
		     mat `granger' = r(chi2), r(df), r(p)
		  }
		   else {
		     mat `granger' = `granger' \ r(chi2), r(df), r(p)
		    }
			
		local i = `i' + 1	
	     }
	   }	
	  
	   local name `name' `res':ALL
	   qui test ``res'_'  0
		 mat `granger' = `granger' \ r(chi2), r(df), r(p)
		 
		 local i = `i' + 1	
	 }

   forval bbb = 1/`varsn' {
	 if `bbb' == 1 {
	   local rline &
	  }
	  else {
	    if `bbb' != `varsn' {
	      local rline `rline'&
	   	 }
		 else {
		   local rline `rline'-
		  }
	   }
	 }  
	 
   forval bbb = 1/`varsn' {
     local rline_ `rline_'`rline'
	} 
	 
   mat rowname `granger' = `name'		
   mat colname `granger' = "chi2" "df" "Prob > chi2"
   di ///
      _n(1) _skip(2) as txt "panel VAR-Granger causality Wald test" ///
      _n(1) _skip(4) as txt "Ho: " as txt "Excluded variable does not Granger-cause Equation variable"  ///
      _n(1) _skip(4) as txt "Ha: " as txt "Excluded variable Granger-causes Equation variable" 

   matlist `granger', border(rows all) rowtitle("Equation \ Excluded") ///
     aligncolnames(center) tindent(3) ///
	 cspec(o2 | %20s | %10.3f & %3.0f & %11.3f o2|) rspec(--`rline_')

   // return   
   return matrix pgstats = `granger' 

   
   // reload estimates in memory
   if "`estimates'" != "" {
     qui {
		estimates restore `ppp'    
	  }
	}  
   
end //-------------------------------------------------------------
