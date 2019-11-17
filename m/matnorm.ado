*! 1.1.1  24mar2000  Jeroen Weesie/ICS
program define matnorm, rclass
	version 6.0

	* scratch
	tempname A B

	* parse input
	gettoken A0 0 : 0, parse(",")
	mat `A' = `A0' /* may trigger error msg */
	local nc = colsof(`A')
	local nr = rowsof(`A')

	syntax [, Display Norm(str) Format(str) ]

	if `nr' > `nc' {
		mat `B' = `A'' * `A'
	}
	else mat `B' = `A'  * `A''
	return scalar norm = sqrt(trace(`B'))

	if "`display'" != "" | "`norm'" == "" {
		if "`format'" == "" {
			local format "%10.2g"
		}
		di in gr "L2-norm of `A0' [`nc',`nr'] = " in ye `format' return(norm)
	}

	if "`norm'" != "" {
		scalar `norm' = return(norm)
   }
end
exit

Returns the norm of a matrix expression.

currently, we only implement a 2-norm
   = square-root of the sum of the squares of the elements
later version should add
  * true L-x norms.
  * operator norms
  * ...

