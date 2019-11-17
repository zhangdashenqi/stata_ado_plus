*! 1.1  07dec98  Jeroen Weesie/ICS
program define varnull, rclass
   version 6.0

   syntax varlist(numeric) [if] [in] [aw fw iw] /*
     */ [, Rank(str) Null(str) Cons Display Format(str)]

   * scratch
   tempname A

   * code for handling constant
   local nv: word count `varlist'
   if "`cons'" != "cons" {
      local nocons "nocons"
   }
   else {
      local cns "+cons"
      local nv = `nv' + 1
   }

   * selection of rows of implied matrix
   marksample touse

   * form A = X'WX
	quiet mat acc `A' = `varlist' if `touse' [`weight'`exp'], `nocons'
	matnull `A', nodisplay

	return scalar rank = r(rank)
	* we use capture to deal with missing r(null)! Ugly, but effective
	capt return matrix null r(null)

	if "`rank'" ~= "" {
		scalar `rank' = r(rank)
	}
	if "`null'" ~= "" {
		capt matrix `null' = r(null)
	}

   * display
   if "`null'" == "" | "`display'" != "" {
      local d = `nv' - return(rank)
      if "`format'" != "" {
         local fmt "format(`format')"
      }
      di _n in gr "Rank of the variables`cns' is " in ye return(rank)
      di in gr "There exist " in ye `d' /*
         */ in gr " linear dependencies between the variables"
      if `d' > 0 {
         di _n in gr "Null space of the variables`cns'"
         mat list return(null), noheader `fmt'
      }
   }
end


