*! 1.1.0  07dec98  Jeroen Weesie/ICS
program define varrank, rclass
   version 6.0

   syntax varlist(numeric) [if] [in] [aw fw iw] [, Rank(str) Cons Display Tol(str)]

   * scratch
   tempname A r

   * selection of rows of implied matrix
   marksample touse

   * handling the constant        
   if "`cons'" != "cons" { 
      local nocons "nocons" 
   } 
   else local cns "+cons"

   * form X*Diag(W)*X, and obtain its rank
   quiet mat acc `A' = `varlist' if `touse' [`weight'`exp'], `nocons'
   matrank `A', rank(`r')

   * display results
   if "`rank'" == "" | "`display'" != "" {     
      quiet count if `touse' > 0
      di in gr "rank of data [" in ye r(N) in gr " obs, " /*
         */ in ye colsof(`A') in gr " vars`cns'] = " in ye `r' 
   }
   if "`rank'" != "" { 
      scalar `rank' = `r' 
   }
	ret scalar rank = `r'
end
