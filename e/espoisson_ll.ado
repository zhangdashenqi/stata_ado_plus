*! Alfonso Miranda Caso Luengo                                  (SJ4-1: st0057)
*! Version 1.0 November 21 2002

program define espoisson_ll
 
 args todo b f

 tempname lnsigma kappa delta 
 tempvar xb zb 

 local y "$ML_y1"
 local d "$S_edum"
 
 mleval `xb' = `b', eq(1)
 mleval `zb' = `b', eq(2)
 mleval `lnsigma' = `b', eq(3) scalar
 mleval `kappa' = `b', eq(4) scalar

 
 scalar `lnsigma' = cond(`lnsigma'<-20,-20,`lnsigma')

 if `kappa' <-14 { 
			scalar `kappa' = -14
			}
 if `kappa' > 14 { 
			scalar `kappa' = 14 
			}
 
 tempname sma u rho
 
 scalar `sma' = exp(`lnsigma')  
 scalar `rho' = (exp(2*`kappa')-1)/(exp(2*`kappa')+1)

 tempvar F p r1 r2 r3 r4 r5 r6
 
 qui { 
	gen double `F' = . if  $ML_samp

	gen double `p' = 0 if $ML_samp
	gen double `r1' = 0 if $ML_samp
	gen double `r2' = 0 if $ML_samp 
	gen double `r3' = 0 if $ML_samp
	gen double `r4' = 0 if $ML_samp
	gen double `r5' = 0 if $ML_samp
	gen double `r6' = 0 if $ML_samp

	local m = 1
        while `m' <= $S_quad {
	                       scalar `u' = sqrt(2)*`sma'*scalar(x`m')
                               replace `r1' = `xb' +  `u' if $ML_samp 
			       replace `r2' = exp(`r1')^(`y')*exp(-exp(`r1')) if $ML_samp
			       replace `r3' = `r2'/exp(lngamma(`y'+1)) if $ML_samp
			       replace `r4' = `zb' + sqrt(2)*`rho'*scalar(x`m') if $ML_samp
			       replace `r5' = `r4'/(sqrt(1-`rho'^2)) if $ML_samp
			       replace `r6' = `d'*norm(`r5') + /*
				 */ (1-`d')*norm(-`r5') if $ML_samp
			       replace `F' = `r3'*`r6' if $ML_samp
			       replace `p' = `p' + scalar(w`m')*`F' if $ML_samp
			       local m = `m' + 1
                 	      }
	replace `p'= (1/sqrt(_pi))*`p' if $ML_samp
        replace `F' = log(`p') if $ML_samp
	mlsum `f' = `F' if $ML_samp
	}
end
exit

	                

	                
	     
	     	     	     
                          
  	 
