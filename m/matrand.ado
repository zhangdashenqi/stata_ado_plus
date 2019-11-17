*! 1.1.0  05jan1999  Jeroen Weesie/ICS
program define matrand, rclass
	version 6.0

	gettoken n 0: 0, parse(" ")
	gettoken m 0: 0, parse(" ")   
	gettoken ANS 0: 0, parse(" ,")      
	if "`ANS'" == "" {
		di in re "insufficient arguments."
		exit 198
	}   
	confirm integer number `m'
	confirm integer number `n'

	syntax [, Uniform(str) Normal(str) Const(str) Display Format(passthru)]
	
	* select random number generating expressions

	if "`normal'" != "" {
		tokenize `normal'
		confirm number `1'
		confirm number `2'
		local rnd  "`1' + sqrt(abs(`2'))*invnorm(uniform())" 
	}
	
	else if "`const'" != "" { 
		tokenize `const'
		confirm integer number `1'
		confirm integer number `2'    
		local rnd  "int(`1' + (`2'-`1'+1)*uniform())" 
   }

	else { /* if "`uniform'"!="" */
		tokenize `uniform' 0 1
		confirm integer number `1'
		confirm integer number `2'    
		local rnd  "`1' + (`2'-`1')*uniform()" 
	}

	* di "`random number generating expression: `rnd'"

	* generate random matrix using random number generator `rnd'

	tempname A
	matrix `A' = J(`n',`m',0)
	local i 1
	while `i' <= `n' {
		local j 1
		while `j' <= `m' {
			mat `A'[`i',`j'] = `rnd'
			local j = `j' + 1
		}
		local i = `i' + 1
	}

	* display 
	matrix `ANS' = `A'
	if "`display'" != "" {
		mat list `ANS', `format'
	}
	return matrix randmat `A' 
end

