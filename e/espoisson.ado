*! version 1.0 Alfonso Miranda-Caso-Luengo, November 26 2002    (SJ4-1: st0057)
*! FIML endogenous-switch Poisson Regression

program define espoisson, eclass 
	version 6
	if replay() { 
		if "`e(cmd)'" != "espoisson" { error 301 }
		else espDisplay `0'
 		}
	else espEstimate `0'	
end

program define espEstimate, eclass
	syntax varlist [if] [in] , EDummy(varname) /*
	*/ [Switch(varlist) Quadrature(integer 6) /*
	*/ SIGMA0(real 1) RHO0(real 0.1) /*
        */ EXS *] 
	
	/* Obtaining dependent variable and explanatory variables */  

	gettoken endgv exogv : varlist, parse("")

	/* Selecting sample */  

	marksample touse
	markout `touse' `varlist'

	/* defining some globals */ 
	  	
   	 global S_quad   "`quadrature'"
	 global S_edum "`edummy'"


	/* Diverting to exsp if EXS option active */
	
	if "`exs'"!="" {
			#delimit ;
			exspoisson `endgv' `exogv' `if' `in', edummy(`edummy') 
			s(`switch') q(`quadrature') 
			sigma0(`sigma0') ;
			#delimit cr
			exit
			}
	
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
				   local j = `j' - 1 
				  }
	

	/* GETTING INITIAL VALUES */ 
	
	 di _skip(3)
	 qui probit `edummy' `switch' if `touse'  

	 tempname b b1 b2 ch cr b0 bi
	 
	 mat `b'=e(b)
	 xcolnames `b', head(switch)
	 
	 di as txt "Getting Initial Values:"
	 qui poisson  `endgv' `exogv' if `touse'
	
	 mat `b1' = e(b)
	 mat `b2' = (`b1',`b')
	 matrix `ch' = ln(`sigma0') 
	 matrix colnames `ch' = lnsigma:_cons
	 matrix `cr' = `rho0'
	 matrix colnames `cr' = rho:_cons
	 matrix `b0' = (`b2',`ch',`cr')

	 ml model d0 espoisson_ll ("`endgv'": `endgv' = `exogv') /* 
	 */ (switch:`switch')(lnsigma:)(rho:) /* 
         */ if `touse', init(`b0')

	 qui ml search rho: 14 -14
	 mat `cr' = ML_b[1,"rho:_cons"]
	 mat `bi' = (`b2',`ch',`cr')
	 
         /* FITTING FULL MODEL */ 
	
	 di _skip(3)
	 di in gr "Fitting Full model:"
	 
	 ml model d0 espoisson_ll ("`endgv'": `endgv' = `exogv') /* 
	 */ (switch:`switch')(lnsigma:)(rho:)/* 
         */ if `touse', init(`bi', skip) max `options' search(off)  

	 estimates local cmd "espoisson"
	 estimates local edummy "`edummy'"
	 est local predict "espoisson_p"
	 est local quad "`quadrature'"
	  	
	/* Display Results */

	espDisplay 
end
	
	
program define espDisplay 

      	di _skip(12)
	di _n as txt /*
	*/ "Endogenous-Switch Poisson Regression"
	di as text "(`e(quad)' quadrature points)"  
   	
	ml di, neq(2)plus
	_diparm lnsigma, exp pr label("sigma")
      _diparm rho, f((exp(2*@)-1)/(exp(2*@)+1)) /*       
      */ d(4*exp(2*@)/(exp(2*@)+1)^2) label("rho") pr
	di in gre in smcl "{hline 13}{c BT}{hline 64}" 
end



	
