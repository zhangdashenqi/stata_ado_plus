*! Alfonso Miranda-Caso-Luengo                                 (SJ4-1: st0057)
*! FIML exogenous sitching Poisson 
*! version 2.0 June 26 2003

program define exspoisson, eclass 
	version 6
	if replay() { 
		if "`e(cmd)'" != "exspoisson" { error 301 }
		else exspDisplay `0'
 		}
	else exsEstimate `0'	
end

program define exsEstimate, eclass
	syntax varlist [if] [in] , EDummy(varname) /*
	*/ [Switch(varlist) Quadrature(integer 6) /*
	*/ SIGMA0(real 1) *]
	
	/* Obtaining dependent variable and explanatory variables */  

	gettoken endgv exogv : varlist, parse("")

	/* Selecting sample */  

	marksample touse
	markout `touse' `varlist'
	
	/* defining some globals */ 
	  	
   	 global S_quad   "`quadrature'"
	 global S_edum "`edummy'"

	/* Get points and weights for Gaussian-Hermite quadrature. */

	tempvar  x w
	qui gen double `x' = 0 
	qui gen double `w' = 0 
  	ghquad `x' `w', n(`quadrature')
	local j = `quadrature'
	while `j' >0 { 
				    scalar x`j' = `x'[`j']
				    local j = `j' -1
				  }
	local j = `quadrature'
	while `j' >0 {
				   scalar w`j' = `w'[`j']
				   local j = `j' - 1 }
	

   
	/* GETTING INITIAL VALUES */ 
	
	 di _skip(3)
	 qui probit `edummy' `switch' if `touse'  

	
	 tempname b b1 b2 bi ch
	 
	 mat `b'=e(b)
	 xcolnames `b', head(switch)
	 di as txt "Getting Initial Values:"
	 qui poisson  `endgv' `exogv' if `touse'
	
	 mat `b1' = e(b)
	 mat `b2' = (`b1',`b')
	 matrix `ch' = ln(`sigma0') 
	 matrix colnames `ch' = lnsigma:_cons
	 matrix `bi' = (`b2',`ch')

	/* FITTING FULL MODEL */ 
	
	 di _skip(3)
	 di in gr "Fitting Full model:"
	 	 
 	 ml model d0 exspoisson_ll ("`endgv'": `endgv' = `exogv') /* 
	 */ (switch:`switch')(lnsigma:) /* 
         */ if `touse', init(`bi', skip) max difficult search(off) `options' 

	 estimates local cmd "exspoisson"
	 est local predict "exspoisson_p"
	 est local quad "`quadrature'"
	  	
	/* Display Results */

	exspDisplay

end
	
program define exspDisplay
	
	di _skip(12)
     	di _n as txt /*
     	*/ "Exogenous-Switch Poisson Regression"
	di as text "(`e(quad)' quadrature points)"  
   	
	ml di, neq(2)plus
	_diparm lnsigma, exp pr label("sigma")
	di in gre in smcl "{hline 13}{c BT}{hline 64}" 

end
exit


	
