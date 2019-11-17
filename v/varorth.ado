*! 1.1.0  07dec98  Jeroen Weesie/ICS
program define varorth
	version 6

   syntax varlist(numeric) [if] [in] [aw fw iw] [, /*
     */ Cons Eps(real 1E-6) Norm Prefix(str)]

   * scratch
   tempvar one wght t
   tempname normi

   * selection of rows of implied matrix
   marksample touse

   * names of output variables
   if "`prefix'" != "" {
      tokenize `varlist'
      local i 1    
      while "``i''" != "" {   
         confirm new var `prefix'``i''
         local vlist "`vlist' `prefix'``i''"
         qui gen double `prefix'``i'' = ``i''  if `touse'
         local i = `i'+1
      }    
      local varlist "`vlist'"
   }

   * gramm-schmidt orthogonalization
   quietly {
      if "`weight'" != "" {
         gen double `wght' `exp' if `touse' 

         * scale weights wght to #cases-touse
         if "`weight'" == "aweight" & "`norm'" != "" { 
            summ `wght' if `touse', meanonly
            replace `wght' = `wght' / r(sum) if `touse' 
         }
         * tricky: use text substitution 
         local wexp "* `wght'"
      }

      if "`cons'" != "" {
         gen double `one' = 1
         local varlist "`one' `varlist'"
      }

      tokenize `varlist'
      local nv : word count `varlist'
      local nzero 0
      local i 1
      gen double `t' = 0

      while `i' <= `nv' {
         * normalize variable i 
         replace `t' = ``i''^2 `wexp' if `touse'
         summ `t' if `touse'
         scalar `normi' = r(sum)
         if `normi' > `eps' {
            * normalize variable i 
            if "`norm'" != "" { 
               replace ``i'' = ``i''/sqrt(`normi') if `touse'
               scalar `normi' = 1
            }
            local j = `i'+1
            while `j' <= `nv' {
               * make j orthogonal to i 
               replace `t' = ``i'' * ``j'' `wexp' if `touse'
               summ `t' if `touse', meanonly
               replace ``j'' = ``j'' /*
                  */ - (r(sum)/`normi')*``i'' if `touse'
               local j = `j'+1
            }
         }
         else {
            local nzero = `nzero'+1
            replace ``i'' = 0 if `touse'
         }
         local i = `i' + 1
      }
   } /* quietly */

   if `nzero' > 0 {
      di in bl "warning: variables seems to be linear dependent"
      di in bl "`nzero' variables are set to 0"
      di in bl "use -varrank- to verify the rank of the variables"    
   }
end
