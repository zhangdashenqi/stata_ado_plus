/* pVARstable v1.0 - 22 June 2016*/


cap program drop pvarstable
program define pvarstable, sortpreserve rclass
   version 11.0
   syntax [, ESTimates(string) GRAph NOGRId] 
  
  
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
     di as err "pvarstable can only be run after {help pvar}"
	 exit 198
    }

   
   // check -nogrid-
   if ("`nogrid'" != "") & ("`graph'" == "") {
     di as err "{bf:nogrid} may only be specified with option {bf:graph}
	 exit 198
	} 
   
   // create companion matrix 
   local varsn = wordcount("`e(eqnames)'")
   tempname b A
     mat `b' = e(b)

   forval p = 1/ `e(mlag)' {
     local coln
       foreach var in `e(eqnames)' {
	     local coln "`coln' L`p'.`var'"
		 local zzz = `zzz' + 1
	       local rcol `rcol' c`zzz'
	    } 
		
	 tempname A`p'	
     mat `A`p'' = J(`varsn', `varsn', .)
       mat rowname `A`p'' = `e(eqnames)'
       mat colname `A`p'' = `coln'
	   
     foreach vareq in `e(eqnames)' {
       foreach varex in `e(eqnames)' {
         mat `A`p''[rownumb(`A`p'',"`vareq'"), colnumb(`A`p'',"L`p'.`varex'")] ///
	       = `b'[1, "`vareq':L`p'.`varex'"]
	    } 
      }	
	  
	 mat `A' = nullmat(`A'), `A`p'' 
	}
    
	if e(mlag) > 1 {
	  mat `A' = `A' \ I((e(mlag)-1)*`varsn'), J((e(mlag)-1)*`varsn', `varsn', 0)
	 }
	

	// compute characteristic roots
	tempname m r c mod
    mat eigenvalue `r' `c' = `A'
    mat `mod' = vecdiag(cholesky(diag(diag(`r')*`r'' + diag(`c')*`c'')))
    mat `m' = `r'', `c'', `mod''
	  mata : st_matrix("`m'", sort(st_matrix("`m'"), -3))
	  foreach v in mod r c {
	    mat colname ``v'' = `rcol'
	    mat rowname ``v'' = r1
       }	
	   
	   
	// display
	set more off
	preserve
	clear
	  mat colname `m' = r c m
	  qui svmat `m', names(col)
      qui su m
	  
	mat colname `m' = "Eigenvalue: Real" "Eigenvalue: Imaginary" ".:Modulus"
    di _n(1) _skip(3) as txt "Eigenvalue stability condition"
	matlist `m', twidth(5) border(all) left(2) showcoleq(combined) ///
       aligncolnames(center) names(columns)
	if r(max) < 1 {   
	  di _n(1) _skip(3) as txt "All the eigenvalues lie inside the unit circle." ///
	     _n(1) _skip(3) as txt "pVAR satisfies stability condition."
	  }
	  else {   
	    di _skip(3) as txt "At least one eigenvalue lie outside the unit circle." ///
	       _n(1) _skip(3) as txt "pVAR does not satisfy stability condition."
	   }
	
	// graph
	if "`graph'" != "" {
	    foreach var in r c {
	      qui su `var'
		  local `var'_min = -1
		  local `var'_max =  1
		  if r(min) < -1 {
		    local `var'_min = r(min)
		   }	
		  if r(max) >  1 {
		    local `var'_max = r(max)
		   }	
		 }
		local aspect = (`c_max'-`c_min') / (`r_max'-`r_min')
		 
	    local max (function y =  sqrt(`r(max)'^2 - (x)^2), range(-`r(max)' `r(max)') lc(white)) 
	    local max `max' (function y =  -sqrt(`r(max)'^2 - (x)^2), range(-`r(max)' `r(max)') lc(white)) 
	
	  * Draw polar grids
	  if "`nogrid'" == "" {
	  forval xxx = 0.1(0.1)0.8 {
        local innergph `innergph' (function y =  sqrt(`xxx'^2 - (x)^2), range(-`xxx' `xxx') lc(gs14))
	    local innergph `innergph' (function y = -sqrt(`xxx'^2 - (x)^2), range(-`xxx' `xxx') lc(gs14)) 
       }
	    local innergrph9 (function y = sqrt(0.9^2 - (x)^2), range(-0.9 0.9) lc(gs12)) ///
	     (function y = -sqrt(0.9^2 - (x)^2), range(-0.9 0.9) lc(gs12)) 
	  }
	  
	  graph twoway ///
	     `max' ///
	     (function y = sqrt(1 - (x)^2), range(-1 1) lc(gs0)) ///
	     (function y = -sqrt(1 - (x)^2), range(-1 1) lc(gs0)) ///
		 `innergph' `innergrph9' ///
		 (scatter c r, mc(dknavy)) ///
		    , aspect(`aspect') legend(off) xtitle("Real") ytitle("Imaginary") ///
			subtitle("Roots of the companion matrix") ylabel(, nogrid)
	restore
	set more on
	}
	
	
   // return output
   return matrix Modulus = `mod'
   return matrix Im = `c'
   return matrix Re = `r'

end   
