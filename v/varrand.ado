*! 1.0.4  07dec98  Jeroen Weesie/ICS

program define varrand
   version 6
   syntax [, Prefix(str) NVar(int 2) Obs(int 100) clear add /*
     */      Normal c(str) e(str) i(str) n(str) u(str)]

   * normal is short for standand normal n(0,1)
   if "`normal'" != "" { local n "0,1" }   

   * default is u(0,1)
   if "`c'`e'`i'`n'`u'" == "" { local u "0,1" }    
    
   * variables are named predix1, prefix2 etc
   if "`prefix'" == "" { local prefix "x" }

   * check whether data in memory may be dropped
   quiet descr, short
   if (_result(7)==1) & ("`add'"=="") & ("`clear'"=="") { error 4 }             

   * --------------------------------------------------------------------
   * create "rv-generate functions" in local cmd
   *        variable label          in local lab
   * --------------------------------------------------------------------

   if "`c'" != "" {                    /* cauchy distribution */
      tokenize "`c'", p(", ")
      if `"`2'"' == "," { local 2 `3' }
      local loc `1'
      local scale `2'
      confirm number `loc'
      confirm number `scale'

      local N "invnorm(uniform())"
      local cmd "`loc'+sqrt(abs(`scale')) * (`N')/(`N')"
      local lab "Cauchy C(`loc',`scale')"
   }    

   else if "`e'" != "" {               /* exponential distribution */
      confirm number `e'
      local cmd "-`e'*ln(uniform())"
      local lab "Exponential exp(`e')"
   }

   else if "`i'" != "" {               /* uniform-integer distribution */
      tokenize "`i'", p(", ")
      if `"`2'"' == "," { local 2 `3' }
      local low  `1'
      local high `2'
      confirm integer number `low'
      confirm integer number `high'

      local cmd "`low'+int((`high'-`low'+1)*uniform())"
      local lab "IU(`low',`high')"
   }     
   
   else if "`n'" != "" {               /* normal distribution */
      tokenize "`n'", p(", ")
      if `"`2'"' == "," { local 2 `3' }
      local mean `1'
      local var  `2'
      confirm number `mean'
      confirm number `var'

      local cmd "`mean'+sqrt(abs(`var'))*invnorm(uniform())"
      local lab "Normal N(`mean',`var')"
   }    

   else if "`u'" != "" {               /* uniform-real distribution */
      tokenize "`u'", p(", ")
      if `"`2'"' == "," { local 2 `3' }
      local low  `1'
      local high `2'
      confirm number `low'
      confirm number `high'

      local cmd "`low'+(`high'-`low'+1)*uniform()"
      local lab "U(`low',`high')"
   }    
        
   * --------------------------------------------------------------------
   * go ahead -- generate the rv's
   * --------------------------------------------------------------------

   if "`add'" == "" {       
      drop _all 
      label data "random data produced by varrand"
      set obs `obs'
   }

   local iv 1
   while `iv' <= `nvar' {
      gen `prefix'`iv' = `cmd'
      label var `prefix'`iv' "`lab' variate"
      local iv = `iv' + 1
   }
end
exit

* rvcauch varname loc scale (cauchy distribution)
program rvcauch
    gen `1' = `2' + `3' * invnorm(uniform())/invnorm(uniform())
    label var `1' "Cauchy C(`2',`3')"
end

* rvexp varname lambda (exponential distribution)
program rvexp
    gen `1' = - `2' * ln(uniform())
    label var `1' "Exponential exp(`2')"
end

* rvuint varname low high (uniform-integer distribution)
program rvuint
    gen `1' = `2' + int((`3'-`2'+1) * uniform())
    label var `1' "IU(`2',`3')"
end

* rvureal varname low high (uniform-real distribution)
program rvureal
    gen `1' = `2' + (`3'-`2'+1) * uniform()
    label var `1' "U(`2',`3')"
end

* rvnorm varname loc scale (normal distribution)
program rvnorm
    gen `1' = `2' + `3' * invnorm(uniform())
    label var `1' "Normal N(`2',`3')"
end


