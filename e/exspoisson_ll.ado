*! Alfonso Miranda Caso Luengo                                 (SJ4-1: st0057)
*! Version 2.0 June 26 2003

program define exspoisson_ll
 
 args todo b f 

 tempname lnsigma
 tempvar xb zb

 local y "$ML_y1"
 local d "$S_edum"

 mleval `xb' = `b', eq(1)
 mleval `zb' = `b', eq(2)
 mleval `lnsigma' = `b', eq(3)
 
 scalar `lnsigma' = cond(`lnsigma'<-20,-20,`lnsigma')

 tempname sma u  
 scalar `sma' = exp(`lnsigma')  

 tempvar F p r1 r2 r3 r4
 
 qui { 
	gen double `F' = . if  $ML_samp

	gen double `p' = 0 if $ML_samp
	gen double `r1' = 0 if $ML_samp
	gen double `r2' = 0 if $ML_samp 
	gen double `r3' = 0 if $ML_samp
	gen double `r4' = 0 if $ML_samp
		
	local m = 1
        while `m' <= $S_quad {
	                       scalar `u' = sqrt(2)*`sma'*scalar(x`m')
                               replace `r1' = `xb' +  `u' if $ML_samp 
			       replace `r2' = exp(`r1')^(`y')*exp(-exp(`r1')) if $ML_samp
			       replace `r3' = `r2'/exp(lngamma(`y'+1)) if $ML_samp
			       replace `r4' = `d'*norm(`zb') + (1-`d')*norm(-`zb')
			       replace `F' = `r3'*`r4' if $ML_samp
			       replace `p' = `p' + scalar(w`m')*`F' if $ML_samp
			       local m = `m' + 1
                 	      }
	replace `p'= (1/sqrt(_pi))*`p' if $ML_samp
        replace `F' = log(`p') if $ML_samp
	mlsum `f' = `F' if $ML_samp
	}
end
exit

	                

	                
	     
	     	     	     
                          
  	 
