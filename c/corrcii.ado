*! 1.0.0 NJC 20 August 2008 
* ideas from z_rcii 1.1.1 02Feb96 JRG 
program corrcii, rclass
	version 8 

	gettoken n 0 : 0 
   	confirm integer number `n'
	if `n' < 5 error 2001 

	gettoken r 0 : 0, parse(" ,") 
	confirm number `r'
	if `r' <= -1 | `r' >= 1 { 
		di as err "invalid correlation" 
		error 499 
	} 

   	syntax [, Level(real `c(level)') FOrmat(str) FIsher Jeffreys lee] 
        if `level' <= 0 | `level' >= 100 { 
		di as err "invalid confidence level"
		error 499
	}

	if "`fisher'" != "" & "`jeffreys'" != "" { 
		di as err "must choose between Fisher and Jeffreys" 
		exit 498 
	} 

	/// checking format with -confirm- not introduced until Stata 10 
	if "`format'" != "" { 
		capture di `format' 0.12345 
		if _rc error 120 
	} 
	else local format %9.3f 

	tempname z d lb ub 
	scalar `z' = atanh(`r')
	if "`jeffreys'`lee'" != "" scalar `z' = `z' - (5 * `r') / (2 * `n') 
	if "`fisher'" != "" scalar `z' = `z' - 2 * `r' / (`n' - 1)
	
	if "`jeffreys'" != "" { 
		scalar `d' = invnorm(.5 + `level'/200) / sqrt(`n')
	}
	else if "`lee'" != "" { 
		scalar `d' = invnorm(.5 + `level'/200) / ///
			(`n' - (3/2) + (5/2) * (1 - (`r')^2)) 
	} 	
	else scalar `d' = invnorm(.5 + `level'/200) / sqrt(`n' - 3)

	scalar `lb' = tanh(`z' - `d') 
	scalar `ub' = tanh(`z' + `d') 

	di _n as txt ///
	_col(8)  "n"  _col(16) "r" _col(23) `level' "% confidence limits" ///
	_n as res %8.0f `n' ///
	_col(11) `format' `r'  _col(22) `format' `lb' _col(32) `format' `ub'

	return scalar z = `z' 
	return scalar ub = `ub' 
	return scalar lb = `lb' 
	return scalar corr = `r' 
end

