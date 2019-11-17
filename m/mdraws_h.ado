*! 1.0.0  SP Jenkins 26 January 2006
*! Adaption by SPJ of code by NJC. Called by -mdraws-
*! 
*! 1.0.0 NJ Cox 6 August 2004 (posted on Statalist)
*! http://www.stata.com/statalist/archive/2004-08/msg00222.html
*! shuffle option added by SP Jenkins, December 2005
*! (requires _gclsort by Philippe Van Kerm)

program mdraws_h

	version 8 
	syntax , GENerate(str) [ Q(int 2) N(str) SHuffle ] 

	if "`n'" == "" local n = _N - 1  
	else if (`n' + 1) > _N error 2001 

	confirm new var `generate' 
	local g "`generate'" 
	tempname y x
	local np1 = `n' + 1 

	qui {
		gen double `g' = 0 
	
		forval i = 2/`np1' { 
			scalar `y' = 1/`q' 
			scalar `x' = 1 - `g'[`i' - 1]
			while `x' <= (`y' + 1e-11) {  
				scalar `y' = `y' / `q' 
			}	
			replace `g' = ///
			`g'[`i' - 1] + (`q' + 1) * `y' - 1 in `i' 
		}
		replace `g' = `g'[_n + 1] in 1/`n'   
		replace `g' = . in `np1' 

		if "`shuffle'" != "" {
			tempvar v h
			ge `v' = uniform() in 1/`n'
			egen `h' = clsort(`g' `v') in 1/`n', inplace
			replace `g' = `h'
		}
	} 	
end
